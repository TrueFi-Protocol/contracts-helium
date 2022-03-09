// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC721Receiver} from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import {IFlexiblePortfolio} from "./interfaces/IFlexiblePortfolio.sol";
import {IDebtInstrument} from "./interfaces/IDebtInstrument.sol";
import {IBasePortfolio} from "./interfaces/IBasePortfolio.sol";
import {IProtocolConfig} from "./interfaces/IProtocolConfig.sol";
import {IValuationStrategy} from "./interfaces/IValuationStrategy.sol";

import {BasePortfolio} from "./BasePortfolio.sol";

contract FlexiblePortfolio is IFlexiblePortfolio, BasePortfolio {
    uint256 private constant PRECISION = 1e30;

    using SafeERC20 for IERC20;
    using Address for address;

    mapping(IDebtInstrument => bool) public isInstrumentAllowed;

    uint256 public maxValue;
    IValuationStrategy public valuationStrategy;

    uint256 public cumulativeInterestPerShare;
    mapping(address => uint256) public previousCumulatedInterestPerShare;
    mapping(address => uint256) public claimableInterest;
    mapping(address => uint256) public claimedInterest;
    uint256 totalUnclaimedInterest;

    event InstrumentAdded(IDebtInstrument instrument, uint256 instrumentId);
    event InstrumentFunded(IDebtInstrument instrument, uint256 instrumentId);
    event InstrumentUpdated(IDebtInstrument instrument);
    event AllowedInstrumentChanged(IDebtInstrument instrument, bool isAllowed);
    event ValuationStrategyChanged(IValuationStrategy strategy);
    event InstrumentRepaid(IDebtInstrument instrument, uint256 instrumentId, uint256 amount);
    event ManagerFeeChanged(uint256 newManagerFee);
    event InterestClaimed(address lender, uint256 amount);

    function initialize(
        IProtocolConfig _protocolConfig,
        uint256 _duration,
        IERC20 _underlyingToken,
        address _manager,
        uint256 _maxValue,
        address _depositStrategy,
        address _withdrawStrategy,
        address _transferStrategy,
        IValuationStrategy _valuationStrategy,
        IDebtInstrument[] calldata _allowedInstruments,
        uint256 _managerFee
    ) external initializer {
        __BasePortfolio_init(_protocolConfig, _duration, _underlyingToken, _manager, _managerFee);
        __ERC20_init("FlexiblePortfolio", "FLEX");
        maxValue = _maxValue;
        addStrategy(DEPOSIT_ROLE, depositStrategies, _depositStrategy);
        addStrategy(WITHDRAW_ROLE, withdrawStrategies, _withdrawStrategy);
        transferStrategy = _transferStrategy;
        valuationStrategy = _valuationStrategy;

        for (uint256 i; i < _allowedInstruments.length; i++) {
            isInstrumentAllowed[_allowedInstruments[i]] = true;
        }
    }

    function allowInstrument(IDebtInstrument instrument, bool isAllowed) external onlyManager {
        isInstrumentAllowed[instrument] = isAllowed;

        emit AllowedInstrumentChanged(instrument, isAllowed);
    }

    function addInstrument(IDebtInstrument instrument, bytes calldata issueInstrumentCalldata) external onlyManager returns (uint256) {
        require(isInstrumentAllowed[instrument], "FlexiblePortfolio: Instrument is not allowed");
        require(instrument.issueInstrumentSelector() == bytes4(issueInstrumentCalldata), "FlexiblePortfolio: Invalid function call");

        bytes memory result = address(instrument).functionCall(issueInstrumentCalldata);

        uint256 instrumentId = abi.decode(result, (uint256));
        require(
            instrument.underlyingToken(instrumentId) == underlyingToken,
            "FlexiblePortfolio: Cannot add instrument with different underlying token"
        );
        emit InstrumentAdded(instrument, instrumentId);

        return instrumentId;
    }

    function fundInstrument(IDebtInstrument instrument, uint256 instrumentId) public onlyManager {
        address borrower = instrument.recipient(instrumentId);
        uint256 principalAmount = instrument.principal(instrumentId);
        instrument.start(instrumentId);
        valuationStrategy.onInstrumentFunded(this, instrument, instrumentId);
        underlyingToken.safeTransfer(borrower, principalAmount);
        emit InstrumentFunded(instrument, instrumentId);
    }

    function updateInstrument(IDebtInstrument instrument, bytes calldata updateInstrumentCalldata) external onlyManager {
        require(isInstrumentAllowed[instrument], "FlexiblePortfolio: Instrument is not allowed");
        require(instrument.updateInstrumentSelector() == bytes4(updateInstrumentCalldata), "FlexiblePortfolio: Invalid function call");

        address(instrument).functionCall(updateInstrumentCalldata);
        emit InstrumentUpdated(instrument);
    }

    function deposit(uint256 amount, address sender) public override(IBasePortfolio, BasePortfolio) {
        require(amount + value() <= maxValue, "FlexiblePortfolio: Portfolio is full");
        _updateClaimableInterest(sender);

        uint256 managersPart = (amount * managerFee) / 10000;
        uint256 protocolsPart = (amount * protocolConfig.protocolFee()) / 10000;
        uint256 amountToDeposit = amount - managersPart - protocolsPart;
        underlyingToken.safeTransferFrom(sender, manager, managersPart);
        underlyingToken.safeTransferFrom(sender, protocolConfig.protocolAddress(), protocolsPart);
        super.deposit(amountToDeposit, sender);
    }

    function withdraw(uint256 shares, address sender) public override(IBasePortfolio, BasePortfolio) {
        _updateClaimableInterest(sender);
        _claimInterest(sender);
        super.withdraw(shares, sender);
    }

    function claimInterest() external {
        _claimInterest(msg.sender);
    }

    function _claimInterest(address lender) internal {
        uint256 amount = withdrawableInterest(lender);
        if (amount == 0) {
            return;
        }
        claimedInterest[lender] += amount;
        totalUnclaimedInterest -= amount;
        underlyingToken.safeTransfer(lender, amount);
        emit InterestClaimed(lender, amount);
    }

    function repay(
        IDebtInstrument instrument,
        uint256 instrumentId,
        uint256 amount
    ) external {
        require(instrument.recipient(instrumentId) == msg.sender, "FlexiblePortfolio: Not an instrument recipient");
        (, uint256 interestRepaid) = instrument.repay(instrumentId, amount);
        valuationStrategy.onInstrumentUpdated(this, instrument, instrumentId);

        _updateCumulativeInterest(interestRepaid);
        instrument.underlyingToken(instrumentId).safeTransferFrom(msg.sender, address(this), amount);
        emit InstrumentRepaid(instrument, instrumentId, amount);
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }

    function setValuationStrategy(IValuationStrategy _valuationStrategy) external onlyManager {
        valuationStrategy = _valuationStrategy;
        emit ValuationStrategyChanged(_valuationStrategy);
    }

    function withdrawableInterest(address lender) public view returns (uint256) {
        return
            claimableInterest[lender] +
            (balanceOf(lender) * (cumulativeInterestPerShare - previousCumulatedInterestPerShare[lender])) /
            PRECISION -
            claimedInterest[lender];
    }

    function value() public view override(BasePortfolio, IBasePortfolio) returns (uint256) {
        if (address(valuationStrategy) == address(0)) {
            return 0;
        }
        return valuationStrategy.calculateValue(this) - totalUnclaimedInterest;
    }

    function setManagerFee(uint256 newManagerFee) external onlyManager {
        managerFee = newManagerFee;
        emit ManagerFeeChanged(newManagerFee);
    }

    function cancelInstrument(IDebtInstrument instrument, uint256 instrumentId) external onlyManager {
        instrument.cancel(instrumentId);
        valuationStrategy.onInstrumentUpdated(this, instrument, instrumentId);
    }

    function markInstrumentAsDefaulted(IDebtInstrument instrument, uint256 instrumentId) external onlyManager {
        return instrument.markAsDefaulted(instrumentId);
    }

    function _updateCumulativeInterest(uint256 interestRepaid) internal {
        totalUnclaimedInterest += interestRepaid;
        if (interestRepaid > 0 && totalSupply() > 0) {
            cumulativeInterestPerShare += (interestRepaid * PRECISION) / totalSupply();
        }
    }

    function _updateClaimableInterest(address lender) internal {
        claimableInterest[lender] = withdrawableInterest(lender);
        previousCumulatedInterestPerShare[lender] = cumulativeInterestPerShare;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC721Receiver} from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import {IFlexiblePortfolio} from "./interfaces/IFlexiblePortfolio.sol";
import {IBulletLoans} from "./interfaces/IBulletLoans.sol";
import {IDebtInstrument} from "./interfaces/IDebtInstrument.sol";
import {IPeriodicLoans} from "./interfaces/IPeriodicLoans.sol";
import {IBasePortfolio} from "./interfaces/IBasePortfolio.sol";
import {IProtocolConfig} from "./interfaces/IProtocolConfig.sol";
import {IValuationStrategy} from "./interfaces/IValuationStrategy.sol";

import {BasePortfolio} from "./BasePortfolio.sol";

contract FlexiblePortfolio is IFlexiblePortfolio, BasePortfolio {
    using SafeERC20 for IERC20;
    using Address for address;

    mapping(IDebtInstrument => bool) public isInstrumentAllowed;

    uint256 public maxValue;
    address public valuationStrategy;

    event InstrumentAdded(IDebtInstrument instrument, uint256 instrumentId);
    event InstrumentFunded(IDebtInstrument instrument, uint256 instrumentId);
    event AllowedInstrumentChanged(IDebtInstrument instrument, bool isAllowed);
    event ValuationStrategyChanged(address strategy);
    event InstrumentRepaid(IDebtInstrument instrument, uint256 instrumentId, uint256 amount);
    event ManagerFeeChanged(uint256 newManagerFee);

    function initialize(
        IProtocolConfig _protocolConfig,
        uint256 _duration,
        IERC20 _underlyingToken,
        address _manager,
        uint256 _maxValue,
        address _depositStrategy,
        address _withdrawStrategy,
        address _transferStrategy,
        address _valuationStrategy,
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
        instrument.startLoan(instrumentId);
        underlyingToken.safeTransfer(borrower, principalAmount);
        emit InstrumentFunded(instrument, instrumentId);
    }

    function deposit(uint256 amount, address sender) public override(IBasePortfolio, BasePortfolio) {
        require(amount + value() <= maxValue, "FlexiblePortfolio: Portfolio is full");
        uint256 managersPart = (amount * managerFee) / 10000;
        uint256 protocolsPart = (amount * protocolConfig.protocolFee()) / 10000;
        uint256 amountToDeposit = amount - managersPart - protocolsPart;
        underlyingToken.safeTransferFrom(sender, manager, managersPart);
        underlyingToken.safeTransferFrom(sender, protocolConfig.protocolAddress(), protocolsPart);
        super.deposit(amountToDeposit, sender);
    }

    function repay(
        IDebtInstrument instrument,
        uint256 instrumentId,
        uint256 amount
    ) external {
        require(instrument.recipient(instrumentId) == msg.sender, "FlexiblePortfolio: Not an instrument recipient");
        instrument.repay(instrumentId, amount);
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

    function setValuationStrategy(address _valuationStrategy) external onlyManager {
        valuationStrategy = _valuationStrategy;
        emit ValuationStrategyChanged(_valuationStrategy);
    }

    function value() public view override(BasePortfolio, IBasePortfolio) returns (uint256) {
        if (valuationStrategy == address(0)) {
            return 0;
        }
        return IValuationStrategy(valuationStrategy).calculateValue(underlyingToken, address(this));
    }

    function setManagerFee(uint256 newManagerFee) external onlyManager {
        managerFee = newManagerFee;
        emit ManagerFeeChanged(newManagerFee);
    }
}

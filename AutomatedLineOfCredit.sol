// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {IAutomatedLineOfCredit, AutomatedLineOfCreditStatus} from "./interfaces/IAutomatedLineOfCredit.sol";
import {IProtocolConfig} from "./interfaces/IProtocolConfig.sol";
import {BasePortfolio} from "./BasePortfolio.sol";

contract AutomatedLineOfCredit is IAutomatedLineOfCredit, BasePortfolio {
    using SafeERC20 for IERC20;

    uint256 internal constant YEAR = 365 days;

    uint256 public maxSize;
    uint256 public borrowedAmount;
    address public borrower;
    InterestRateParameters public interestRateParameters;
    uint256 private lastUtilizationUpdateTime;
    uint256 public claimableProtocolFees;

    event Borrowed(uint256 amount);

    event Repaid(uint256 amount);

    function initialize(
        IProtocolConfig _protocolConfig,
        uint256 _duration,
        IERC20 _underlyingToken,
        address _borrower,
        uint256 _maxSize,
        InterestRateParameters memory _interestRateParameters,
        address _depositStrategy,
        address _withdrawStrategy,
        address _transferStrategy,
        string memory name,
        string memory symbol
    ) public initializer {
        require(
            _interestRateParameters.minInterestRateUtilizationThreshold <= _interestRateParameters.optimumUtilization &&
                _interestRateParameters.optimumUtilization <= _interestRateParameters.maxInterestRateUtilizationThreshold,
            "AutomatedLineOfCredit: Min. Util. <= Optimum Util. <= Max. Util. constraint not met"
        );
        __BasePortfolio_init(_protocolConfig, _duration, _underlyingToken, _borrower, 0);
        __ERC20_init(name, symbol);
        borrower = _borrower;
        managerFee = 0;
        interestRateParameters = _interestRateParameters;
        maxSize = _maxSize;

        addStrategy(DEPOSIT_ROLE, depositStrategies, _depositStrategy);
        addStrategy(WITHDRAW_ROLE, withdrawStrategies, _withdrawStrategy);
        setTransferStrategy(_transferStrategy);
    }

    function borrow(uint256 amount) public {
        require(msg.sender == borrower, "AutomatedLineOfCredit: Unauthorized borrower");
        require(block.timestamp < endDate, "AutomatedLineOfCredit: Pool end date has elapsed");

        borrowedAmount += amount + unincludedInterest();
        lastUtilizationUpdateTime = block.timestamp;

        underlyingToken.safeTransfer(borrower, amount);

        emit Borrowed(amount);
    }

    function value() public view override returns (uint256) {
        return _value(borrowedAmount + unincludedInterest());
    }

    function repay(uint256 amount) public {
        borrowedAmount = borrowedAmount + unincludedInterest() - amount;
        lastUtilizationUpdateTime = block.timestamp;

        underlyingToken.safeTransferFrom(borrower, address(this), amount);

        emit Repaid(amount);
    }

    function repayInFull() external {
        uint256 totalDebt = borrowedAmount + unincludedInterest();
        borrowedAmount = 0;
        lastUtilizationUpdateTime = block.timestamp;

        underlyingToken.safeTransferFrom(borrower, address(this), totalDebt);
    }

    function deposit(uint256 amount, address sender) public override {
        require(block.timestamp < endDate, "AutomatedLineOfCredit: Pool end date has elapsed");
        require((value() + amount) <= maxSize, "AutomatedLineOfCredit: Deposit would cause pool to exceed max size");
        updateBorrowedAmount();
        super.deposit(amount, sender);
    }

    function withdraw(uint256 shares, address sender) public override {
        updateBorrowedAmount();
        uint256 feeAmount = calculateFeeAmount(shares);
        super.withdraw(shares, sender);
        claimableProtocolFees += feeAmount;
    }

    function unincludedInterest() internal view returns (uint256) {
        return (interestRate() * borrowedAmount * (block.timestamp - lastUtilizationUpdateTime)) / YEAR / 10000;
    }

    function interestRate() public view returns (uint256) {
        uint256 currentUtilization = _utilization(borrowedAmount);
        (
            uint32 minInterestRate,
            uint32 minInterestRateUtilizationThreshold,
            uint32 optimumInterestRate,
            uint32 optimumUtilization,
            uint32 maxInterestRate,
            uint32 maxInterestRateUtilizationThreshold
        ) = getInterestRateParameters();
        if (currentUtilization <= minInterestRateUtilizationThreshold) {
            return minInterestRate;
        }
        if (currentUtilization <= optimumUtilization) {
            return
                solveLinear(
                    currentUtilization,
                    minInterestRateUtilizationThreshold,
                    minInterestRate,
                    optimumUtilization,
                    optimumInterestRate
                );
        }
        if (currentUtilization <= maxInterestRateUtilizationThreshold) {
            return
                solveLinear(
                    currentUtilization,
                    optimumUtilization,
                    optimumInterestRate,
                    maxInterestRateUtilizationThreshold,
                    maxInterestRate
                );
        }
        return maxInterestRate;
    }

    function setMaxSize(uint256 _maxSize) external {
        require(msg.sender == manager, "AutomatedLineOfCredit: Only manager can update max size");
        maxSize = _maxSize;
    }

    function utilization() external view returns (uint256) {
        return _utilization(borrowedAmount + unincludedInterest());
    }

    function calculateAmountToWithdraw(uint256 sharesAmount) public view virtual override returns (uint256) {
        return (sharesValue(sharesAmount) * (10000 - totalFee())) / 10000;
    }

    function calculateFeeAmount(uint256 sharesAmount) public view virtual returns (uint256) {
        return (sharesValue(sharesAmount) * totalFee()) / 10000;
    }

    function sharesValue(uint256 sharesAmount) public view virtual returns (uint256) {
        return (sharesAmount * value()) / totalSupply();
    }

    function totalFee() internal view virtual returns (uint256) {
        return protocolConfig.protocolFee() + managerFee;
    }

    function solveLinear(
        uint256 x,
        uint256 x1,
        uint256 y1,
        uint256 x2,
        uint256 y2
    ) internal pure returns (uint256) {
        return (y1 * (x2 - x) + y2 * (x - x1)) / (x2 - x1);
    }

    function getInterestRateParameters()
        public
        view
        returns (
            uint32,
            uint32,
            uint32,
            uint32,
            uint32,
            uint32
        )
    {
        InterestRateParameters memory _interestRateParameters = interestRateParameters;
        return (
            _interestRateParameters.minInterestRate,
            _interestRateParameters.minInterestRateUtilizationThreshold,
            _interestRateParameters.optimumInterestRate,
            _interestRateParameters.optimumUtilization,
            _interestRateParameters.maxInterestRate,
            _interestRateParameters.maxInterestRateUtilizationThreshold
        );
    }

    function claimProtocolFees() public {
        uint256 amountToTransfer = claimableProtocolFees;
        claimableProtocolFees = 0;
        underlyingToken.safeTransfer(protocolConfig.protocolAddress(), amountToTransfer);
    }

    function getStatus() external view returns (AutomatedLineOfCreditStatus) {
        if (block.timestamp >= endDate) {
            return AutomatedLineOfCreditStatus.Closed;
        }
        if (value() >= maxSize) {
            return AutomatedLineOfCreditStatus.Full;
        }
        return AutomatedLineOfCreditStatus.Open;
    }

    function updateBorrowedAmount() internal {
        borrowedAmount += unincludedInterest();
        lastUtilizationUpdateTime = block.timestamp;
    }

    function _value(uint256 debt) internal view returns (uint256) {
        return underlyingToken.balanceOf(address(this)) + debt - claimableProtocolFees;
    }

    function _utilization(uint256 debt) internal view returns (uint256) {
        if (debt == 0) {
            return 0;
        }
        return (debt * 10000) / _value(debt);
    }
}

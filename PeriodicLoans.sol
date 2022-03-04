// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ERC721Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import {InitializableManageable} from "./access/InitializableManageable.sol";
import {IPeriodicLoans, PeriodicLoanStatus} from "./interfaces/IPeriodicLoans.sol";

contract PeriodicLoans is ERC721Upgradeable, InitializableManageable, IPeriodicLoans {
    LoanMetadata[] public loans;

    event LoanIssued(uint256 instrumentId);
    event LoanStatusChanged(uint256 instrumentId, PeriodicLoanStatus newStatus);
    event Repaid(uint256 instrumentId, uint256 amount);

    modifier onlyLoanOwner(uint256 instrumentId) {
        require(msg.sender == ownerOf(instrumentId), "PeriodicLoans: Not a loan owner");
        _;
    }

    modifier onlyLoanStatus(uint256 instrumentId, PeriodicLoanStatus _status) {
        require(loans[instrumentId].status == _status, "PeriodicLoans: Unexpected loan status");
        _;
    }

    constructor() InitializableManageable(msg.sender) {}

    function initialize() external initializer {
        InitializableManageable.initialize(msg.sender);
        __ERC721_init("PeriodicLoans", "PL");
    }

    function principal(uint256 instrumentId) external view returns (uint256) {
        return loans[instrumentId].principal;
    }

    function underlyingToken(uint256 instrumentId) external view returns (IERC20) {
        return loans[instrumentId].underlyingToken;
    }

    function recipient(uint256 instrumentId) external view returns (address) {
        return loans[instrumentId].recipient;
    }

    function status(uint256 instrumentId) external view returns (PeriodicLoanStatus) {
        return loans[instrumentId].status;
    }

    function endDate(uint256 instrumentId) external view returns (uint256) {
        return loans[instrumentId].endDate;
    }

    function totalDebt(uint256 instrumentId) external view returns (uint256) {
        return loans[instrumentId].totalDebt;
    }

    function gracePeriod(uint256 instrumentId) external view returns (uint256) {
        return loans[instrumentId].gracePeriod;
    }

    function issueInstrumentSelector() external pure returns (bytes4) {
        return this.issueLoan.selector;
    }

    function currentPeriodEndDate(uint256 instrumentId) external view returns (uint40) {
        return loans[instrumentId].currentPeriodEndDate;
    }

    function periodsRepaid(uint256 instrumentId) external view returns (uint256) {
        return loans[instrumentId].periodsRepaid;
    }

    function issueLoan(
        IERC20 _underlyingToken,
        uint256 _principal,
        uint16 _periodCount,
        uint256 _periodPayment,
        uint32 _periodDuration,
        address _recipient,
        uint32 _gracePeriod
    ) external returns (uint256) {
        require(_recipient != address(0), "PeriodicLoans: recipient cannot be the zero address");

        uint32 loanDuration = _periodCount * _periodDuration;
        require(loanDuration > 0, "PeriodicLoans: Loan duration must be greater than 0");

        uint256 _totalInterest = _periodCount * _periodPayment;
        require(_totalInterest > 0, "PeriodicLoans: Total interest must be greater than 0");

        uint256 id = loans.length;
        loans.push(
            LoanMetadata(
                _principal,
                _totalInterest + _principal, // totalDebt
                _periodPayment,
                PeriodicLoanStatus.Created,
                _periodCount,
                _periodDuration,
                0, // currentPeriodEndDate
                _recipient,
                0, // periodsRepaid
                _gracePeriod,
                0, // endDate,
                _underlyingToken
            )
        );

        _safeMint(msg.sender, id);

        emit LoanIssued(id);
        return id;
    }

    function acceptLoan(uint256 instrumentId) external onlyLoanStatus(instrumentId, PeriodicLoanStatus.Created) {
        require(msg.sender == loans[instrumentId].recipient, "PeriodicLoans: Not a borrower");
        _changeLoanStatus(instrumentId, PeriodicLoanStatus.Accepted);
    }

    function startLoan(uint256 instrumentId)
        external
        onlyLoanOwner(instrumentId)
        onlyLoanStatus(instrumentId, PeriodicLoanStatus.Accepted)
    {
        LoanMetadata storage loan = loans[instrumentId];
        _changeLoanStatus(instrumentId, PeriodicLoanStatus.Started);

        uint32 periodDuration = loan.periodDuration;
        uint40 loanDuration = loan.periodCount * periodDuration;
        loan.endDate = uint40(block.timestamp) + loanDuration;
        loan.currentPeriodEndDate = uint40(block.timestamp + periodDuration);
    }

    function _changeLoanStatus(uint256 instrumentId, PeriodicLoanStatus _status) private {
        loans[instrumentId].status = _status;
        emit LoanStatusChanged(instrumentId, _status);
    }

    function repay(uint256 instrumentId, uint256 amount)
        external
        onlyLoanOwner(instrumentId)
        returns (uint256 principalRepaid, uint256 interestRepaid)
    {
        LoanMetadata storage loan = loans[instrumentId];
        uint16 _periodsRepaid = loan.periodsRepaid;
        uint16 _periodCount = loan.periodCount;
        require(_periodsRepaid < _periodCount, "PeriodicLoans: Loan is already repaid");

        interestRepaid = loan.periodPayment;
        if (_periodsRepaid == _periodCount - 1) {
            principalRepaid = loan.principal;
            _changeLoanStatus(instrumentId, PeriodicLoanStatus.Repaid);
        }
        require(amount == interestRepaid + principalRepaid, "PeriodicLoans: Unexpected repayment amount");

        loan.periodsRepaid = _periodsRepaid + 1;
        loan.currentPeriodEndDate += loan.periodDuration;

        emit Repaid(instrumentId, amount);

        return (principalRepaid, interestRepaid);
    }

    function expectedRepaymentAmount(uint256 instrumentId) external view returns (uint256) {
        LoanMetadata storage loan = loans[instrumentId];
        uint256 amount = loan.periodPayment;
        if (loan.periodsRepaid == loan.periodCount - 1) {
            amount += loan.principal;
        }
        return amount;
    }
}

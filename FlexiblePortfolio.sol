// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC721Receiver} from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import {IFlexiblePortfolio} from "./interfaces/IFlexiblePortfolio.sol";

import {BasePortfolio} from "./BasePortfolio.sol";
import {IBulletLoans} from "./interfaces/IBulletLoans.sol";
import {IDebtInstrument} from "./interfaces/IDebtInstrument.sol";
import {IPeriodicLoans} from "./interfaces/IPeriodicLoans.sol";

contract FlexiblePortfolio is IFlexiblePortfolio, BasePortfolio {
    using SafeERC20 for IERC20;

    function initialize(
        uint256 _duration,
        IERC20 _underlyingToken,
        address _manager
    ) external initializer {
        __BasePortfolio_init(_duration, _underlyingToken, _manager);
        __ERC20_init("FlexiblePortfolio", "FLEX");
    }

    function addBulletLoan(
        IBulletLoans bulletLoans,
        uint64 loanDuration,
        address borrower,
        uint256 principalAmount,
        uint256 repaymentAmount
    ) public returns (uint256 instrumentId) {
        instrumentId = bulletLoans.createLoan(underlyingToken, principalAmount, repaymentAmount, loanDuration, borrower);
        emit InstrumentAdded(bulletLoans, instrumentId);
    }

    function addPeriodicLoan(
        IPeriodicLoans periodicLoans,
        uint64 periodDuration,
        address borrower,
        uint256 principalAmount,
        uint256 periodicPaymentAmount,
        uint32 periodCount,
        uint32 gracePeriod
    ) public returns (uint256 instrumentId) {
        instrumentId = periodicLoans.issueLoan(
            underlyingToken,
            principalAmount,
            periodCount,
            periodicPaymentAmount,
            periodDuration,
            borrower,
            gracePeriod
        );
        emit InstrumentAdded(periodicLoans, instrumentId);
    }

    function fundInstrument(IDebtInstrument loans, uint256 instrumentId) public {
        address borrower = loans.recipient(instrumentId);
        uint256 principalAmount = loans.principal(instrumentId);
        loans.startLoan(instrumentId);
        underlyingToken.safeTransfer(borrower, principalAmount);
        emit InstrumentFunded(loans, instrumentId);
    }

    function addAndFundBulletLoan(
        IBulletLoans bulletLoans,
        uint64 loanDuration,
        address borrower,
        uint256 principalAmount,
        uint256 repaymentAmount
    ) external returns (uint256 instrumentId) {
        instrumentId = addBulletLoan(bulletLoans, loanDuration, borrower, principalAmount, repaymentAmount);
        fundInstrument(bulletLoans, instrumentId);
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }
}

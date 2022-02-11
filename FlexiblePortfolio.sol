// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC721Receiver} from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import {IFlexiblePortfolio} from "./interfaces/IFlexiblePortfolio.sol";

import {BasePortfolio} from "./BasePortfolio.sol";
import {BulletLoans} from "./BulletLoans.sol";

contract FlexiblePortfolio is IFlexiblePortfolio, BasePortfolio {
    using SafeERC20 for IERC20;

    BulletLoans public bulletLoans;

    function initialize(
        uint256 _duration,
        IERC20 _underlyingToken,
        BulletLoans _bulletLoans
    ) external initializer {
        BasePortfolio.initialize(_duration, _underlyingToken);
        bulletLoans = _bulletLoans;
    }

    function initialize(uint256, IERC20) public pure override {
        revert("FlexiblePortfolio: Invalid initialize call");
    }

    function addInstrument(
        uint64 loanDuration,
        address borrower,
        uint256 principalAmount,
        uint256 repaymentAmount
    ) public override returns (uint256 instrumentId) {
        instrumentId = bulletLoans.createLoan(underlyingToken, principalAmount, repaymentAmount, loanDuration, borrower);
        emit InstrumentAdded(instrumentId);
    }

    function fundInstrument(uint256 instrumentId) public override {
        (, , , , address borrower, uint256 principalAmount, , ) = bulletLoans.loans(instrumentId);
        bulletLoans.startLoan(instrumentId);
        underlyingToken.safeTransfer(borrower, principalAmount);
        emit InstrumentFunded(instrumentId);
    }

    function addAndFundInstrument(
        uint64 loanDuration,
        address borrower,
        uint256 principalAmount,
        uint256 repaymentAmount
    ) external override returns (uint256 instrumentId) {
        instrumentId = addInstrument(loanDuration, borrower, principalAmount, repaymentAmount);
        fundInstrument(instrumentId);
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

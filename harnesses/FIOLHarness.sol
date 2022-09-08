// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../FixedInterestOnlyLoans.sol";

contract FIOLHarness is FixedInterestOnlyLoans {
    using SafeERC20 for IERC20;

    // Sanity assumptions for functions

    function acceptLoan(uint256 instrumentId) public override {
        require(msg.sender != address(0));
        super.acceptLoan(instrumentId);
    }

    function issueLoan(
        IERC20 _underlyingToken,
        uint256 _principal,
        uint16 _periodCount,
        uint256 _periodPayment,
        uint32 _periodDuration,
        address _recipient,
        uint32 _gracePeriod,
        bool _canBeRepaidAfterDefault
    ) public override returns (uint256) {
        require(msg.sender != address(0));
        require(loans.length < 2**254);
        return
            super.issueLoan(
                _underlyingToken,
                _principal,
                _periodCount,
                _periodPayment,
                _periodDuration,
                _recipient,
                _gracePeriod,
                _canBeRepaidAfterDefault
            );
    }

    function repay(uint256 instrumentId, uint256 amount) public virtual override returns (uint256, uint256) {
        require(loans.length < 2**254);
        return super.repay(instrumentId, amount);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(_data.length < 256);
        super.safeTransferFrom(from, to, tokenId, _data);
    }

    // Access to internal functions/storage

    function canBeRepaid(uint256 instrumentId) public returns (bool) {
        return _canBeRepaid(instrumentId);
    }

    function statusNonReverting(uint256 instrumentId) public returns (FixedInterestOnlyLoanStatus) {
        if (instrumentId < loans.length) {
            return loans[instrumentId].status;
        }
        return FixedInterestOnlyLoanStatus.Created;
    }

    // Access to other contracts' functions
}

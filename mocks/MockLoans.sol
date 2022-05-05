// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ERC721Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import {IDebtInstrument} from "../interfaces/IDebtInstrument.sol";

contract MockLoans is ERC721Upgradeable, IDebtInstrument {
    uint256 public returnedRepaidInterest;
    IERC20 _underlyingToken;
    address borrower;

    constructor(IERC20 __underlyingToken, address _borrower) {
        _underlyingToken = __underlyingToken;
        borrower = _borrower;
    }

    function setReturnedRepaidInterest(uint256 _returnedRepaidInterest) external {
        returnedRepaidInterest = _returnedRepaidInterest;
    }

    function issueInstrument() external pure returns (uint256) {
        return 0;
    }

    function updateInstrument() external pure {}

    function endDate(uint256) external pure returns (uint256) {
        return 0;
    }

    function repay(uint256, uint256) external view returns (uint256 principalRepaid, uint256 interestRepaid) {
        return (0, returnedRepaidInterest);
    }

    function start(uint256) external pure {}

    function cancel(uint256) external pure {}

    function markAsDefaulted(uint256) external pure {}

    function updateInstrumentSelector() external pure returns (bytes4) {
        return this.updateInstrument.selector;
    }

    function issueInstrumentSelector() external pure returns (bytes4) {
        return this.issueInstrument.selector;
    }

    function principal(uint256) external pure returns (uint256) {
        return 0;
    }

    function underlyingToken(uint256) external view returns (IERC20) {
        return _underlyingToken;
    }

    function recipient(uint256) external view returns (address) {
        return borrower;
    }
}

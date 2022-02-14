// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {BasePortfolio} from "./BasePortfolio.sol";

contract AutoAdjustablePortfolio is BasePortfolio {
    using SafeERC20 for IERC20;

    uint256 internal constant YEAR = 365 days;

    uint256 public borrowedAmount;
    address public borrower;
    uint256 public interestRate;

    uint256 private lastInterestUpdateTime;

    function initialize(uint256 _duration, IERC20 _underlyingToken) public initializer {
        __BasePortfolio_init(_duration, _underlyingToken, msg.sender);
        borrower = msg.sender;
        interestRate = 1000; // 10%
    }

    function borrow(uint256 amount) public {
        require(msg.sender == borrower, "AutoAdjustablePortfolio: Unauthorized borrower");

        borrowedAmount += amount + unincludedInterest();
        lastInterestUpdateTime = block.timestamp;

        underlyingToken.safeTransfer(borrower, amount);
    }

    function value() public view override returns (uint256) {
        return underlyingToken.balanceOf(address(this)) + borrowedAmount + unincludedInterest();
    }

    function repay(uint256 amount) public {
        borrowedAmount = borrowedAmount + unincludedInterest() - amount;
        lastInterestUpdateTime = block.timestamp;

        underlyingToken.safeTransferFrom(borrower, address(this), amount);
    }

    function deposit(uint256 amount, address sender) public override {
        updateBorrowedAmount();
        super.deposit(amount, sender);
    }

    function withdraw(uint256 shares, address sender) public override {
        updateBorrowedAmount();
        super.withdraw(shares, sender);
    }

    function unincludedInterest() internal view returns (uint256) {
        return (interestRate * borrowedAmount * (block.timestamp - lastInterestUpdateTime)) / YEAR / 10000;
    }

    function updateBorrowedAmount() internal {
        borrowedAmount += unincludedInterest();
        lastInterestUpdateTime = block.timestamp;
    }
}

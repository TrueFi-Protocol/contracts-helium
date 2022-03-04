// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import {IBasePortfolio} from "../interfaces/IBasePortfolio.sol";

contract WithdrawStrategy {
    function withdraw(IBasePortfolio portfolio, uint256 amount) public {
        portfolio.withdraw(amount, msg.sender);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {BasePortfolio} from "../BasePortfolio.sol";

contract BasePortfolioImplementation is BasePortfolio {
    function initialize(uint256 _duration, IERC20 _underlyingToken) external initializer {
        __BasePortfolio_init(_duration, _underlyingToken, msg.sender);
        __ERC20_init("BasePortfolio", "BP");
    }
}

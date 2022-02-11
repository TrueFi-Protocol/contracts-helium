// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import {IBasePortfolio} from "./IBasePortfolio.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IAutoAdjustablePortfolio is IBasePortfolio {
    function initialize(uint256 _duration, IERC20 _underlyingToken) external;

    function borrow(uint256 amount) external;

    function value() external view override returns (uint256);

    function repay(uint256 amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IManageable} from "../access/interfaces/IManageable.sol";

interface IBasePortfolio is IManageable {
    function endDate() external view returns (uint256);

    function underlyingToken() external view returns (IERC20);

    function deposit(uint256 amount, address sender) external;

    function withdraw(uint256 amount, address sender) external;

    function value() external view returns (uint256);
}

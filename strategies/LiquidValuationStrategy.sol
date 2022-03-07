// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IValuationStrategy} from "../interfaces/IValuationStrategy.sol";
import {IDebtInstrument} from "../interfaces/IDebtInstrument.sol";
import {IBasePortfolio} from "../interfaces/IBasePortfolio.sol";

contract LiquidValuationStrategy is IValuationStrategy {
    function onInstrumentFunded(
        IBasePortfolio,
        IDebtInstrument,
        uint256
    ) external {}

    function onInstrumentUpdated(
        IBasePortfolio,
        IDebtInstrument,
        uint256
    ) external {}

    function calculateValue(IBasePortfolio portfolio) external view returns (uint256) {
        IERC20 token = portfolio.underlyingToken();
        return token.balanceOf(address(portfolio));
    }
}

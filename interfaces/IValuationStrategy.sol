// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IDebtInstrument} from "./IDebtInstrument.sol";

interface IValuationStrategy {
    function onInstrumentIssued(IDebtInstrument implementation, uint256 instrumentId) external;

    function onInstrumentUpdated(IDebtInstrument implementation, uint256 instrumentId) external;

    function calculateValue(IERC20 token, address portfolio) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import {IBasePortfolio} from "./IBasePortfolio.sol";
import {IDebtInstrument} from "./IDebtInstrument.sol";

interface IFlexiblePortfolio is IBasePortfolio {
    event InstrumentAdded(IDebtInstrument loans, uint256 instrumentId);
    event InstrumentFunded(IDebtInstrument loans, uint256 instrumentId);

    function fundInstrument(IDebtInstrument loans, uint256 instrumentId) external;
}

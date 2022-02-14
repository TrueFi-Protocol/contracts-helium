// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IBasePortfolio} from "./IBasePortfolio.sol";
import {IDebtInstrument} from "./IDebtInstrument.sol";

interface IFlexiblePortfolio is IBasePortfolio {
    event InstrumentAdded(IDebtInstrument loans, uint256 instrumentId);
    event InstrumentFunded(IDebtInstrument loans, uint256 instrumentId);

    function initialize(
        uint256 _duration,
        IERC20 _underlyingToken,
        address _manager
    ) external;

    function fundInstrument(IDebtInstrument loans, uint256 instrumentId) external;
}

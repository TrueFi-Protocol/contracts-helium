// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IBasePortfolio} from "./IBasePortfolio.sol";
import {IProtocolConfig} from "./IProtocolConfig.sol";
import {IDebtInstrument} from "./IDebtInstrument.sol";

interface IFlexiblePortfolio is IBasePortfolio {
    function initialize(
        IProtocolConfig _protocolConfig,
        uint256 _duration,
        IERC20 _underlyingToken,
        address _manager,
        uint256 _maxValue,
        address _depositStrategy,
        address _withdrawStrategy,
        address _transferStrategy,
        address _valuationStrategy,
        IDebtInstrument[] calldata _allowedInstruments,
        uint256 _managerFee
    ) external;

    function fundInstrument(IDebtInstrument loans, uint256 instrumentId) external;

    function repay(
        IDebtInstrument loans,
        uint256 instrumentId,
        uint256 amount
    ) external;
}

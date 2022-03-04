// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import {IFlexiblePortfolio} from "./interfaces/IFlexiblePortfolio.sol";
import {IERC20WithDecimals} from "./interfaces/IERC20WithDecimals.sol";
import {IDebtInstrument} from "./interfaces/IDebtInstrument.sol";
import {BasePortfolioFactory} from "./BasePortfolioFactory.sol";

contract FlexiblePortfolioFactory is BasePortfolioFactory {
    function createPortfolio(
        IERC20WithDecimals _underlyingToken,
        uint256 _duration,
        uint256 _maxValue,
        address _depositStrategy,
        address _withdrawStrategy,
        address _transferStrategy,
        address _valuationStrategy,
        IDebtInstrument[] calldata _allowedInstruments,
        uint256 _managerFee
    ) external onlyWhitelisted {
        bytes memory initCalldata = abi.encodeWithSelector(
            IFlexiblePortfolio.initialize.selector,
            protocolConfig,
            _duration,
            _underlyingToken,
            msg.sender,
            _maxValue,
            _depositStrategy,
            _withdrawStrategy,
            _transferStrategy,
            _valuationStrategy,
            _allowedInstruments,
            _managerFee
        );
        _deployPortfolio(initCalldata);
    }
}

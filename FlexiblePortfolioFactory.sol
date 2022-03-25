// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import {IFlexiblePortfolio} from "./interfaces/IFlexiblePortfolio.sol";
import {IERC20WithDecimals} from "./interfaces/IERC20WithDecimals.sol";
import {IDebtInstrument} from "./interfaces/IDebtInstrument.sol";
import {IValuationStrategy} from "./interfaces/IValuationStrategy.sol";
import {BasePortfolioFactory} from "./BasePortfolioFactory.sol";

contract FlexiblePortfolioFactory is BasePortfolioFactory {
    struct ERC20Metatdata {
        string name;
        string symbol;
    }

    function createPortfolio(
        IERC20WithDecimals _underlyingToken,
        uint256 _duration,
        uint256 _maxValue,
        address _depositStrategy,
        address _withdrawStrategy,
        address _transferStrategy,
        IValuationStrategy _valuationStrategy,
        IDebtInstrument[] calldata _allowedInstruments,
        uint256 _managerFee,
        ERC20Metatdata calldata tokenMetadata
    ) external onlyWhitelisted {
        IFlexiblePortfolio.Strategies memory strategies = IFlexiblePortfolio.Strategies(
            _depositStrategy,
            _withdrawStrategy,
            _transferStrategy,
            _valuationStrategy
        );
        bytes memory initCalldata = abi.encodeWithSelector(
            IFlexiblePortfolio.initialize.selector,
            protocolConfig,
            _duration,
            _underlyingToken,
            msg.sender,
            _maxValue,
            strategies,
            _allowedInstruments,
            _managerFee,
            tokenMetadata.name,
            tokenMetadata.symbol
        );
        _deployPortfolio(initCalldata);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import {IERC20WithDecimals} from "./interfaces/IERC20WithDecimals.sol";
import {IAutoAdjustablePortfolio} from "./interfaces/IAutoAdjustablePortfolio.sol";
import {BasePortfolioFactory} from "./BasePortfolioFactory.sol";

contract AutoAdjustablePortfolioFactory is BasePortfolioFactory {
    function createPortfolio(
        uint256 _duration,
        IERC20WithDecimals _underlyingToken,
        uint256 _managerFee,
        uint256 _maxSize,
        IAutoAdjustablePortfolio.InterestRateParameters memory _interestRateParameters,
        address _depositStrategy,
        address _withdrawStrategy,
        address _transferStrategy,
        string calldata name,
        string calldata symbol
    ) external onlyWhitelisted {
        bytes memory initCalldata = abi.encodeWithSelector(
            IAutoAdjustablePortfolio.initialize.selector,
            protocolConfig,
            _duration,
            _underlyingToken,
            msg.sender,
            _managerFee,
            _maxSize,
            _interestRateParameters,
            _depositStrategy,
            _withdrawStrategy,
            _transferStrategy,
            name,
            symbol
        );
        _deployPortfolio(initCalldata);
    }
}

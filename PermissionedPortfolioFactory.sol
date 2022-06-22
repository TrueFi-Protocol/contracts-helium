// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {IFlexiblePortfolio} from "./interfaces/IFlexiblePortfolio.sol";
import {IPermissionedPortfolio} from "./interfaces/IPermissionedPortfolio.sol";
import {IERC20WithDecimals} from "./interfaces/IERC20WithDecimals.sol";
import {IDebtInstrument} from "./interfaces/IDebtInstrument.sol";
import {IValuationStrategy} from "./interfaces/IValuationStrategy.sol";
import {BasePortfolioFactory} from "./BasePortfolioFactory.sol";

contract PermissionedPortfolioFactory is BasePortfolioFactory {
    function createPortfolio(
        IERC20WithDecimals _underlyingToken,
        uint256 _duration,
        uint256 _maxValue,
        IFlexiblePortfolio.Strategies calldata strategies,
        IDebtInstrument[] calldata _allowedInstruments,
        uint256 _managerFee,
        IFlexiblePortfolio.ERC20Metadata calldata _tokenMetadata,
        address _controller
    ) external onlyRole(MANAGER_ROLE) {
        bytes memory initCalldata = abi.encodeWithSelector(
            IPermissionedPortfolio.initialize.selector,
            protocolConfig,
            _duration,
            _underlyingToken,
            msg.sender,
            _maxValue,
            strategies,
            _allowedInstruments,
            _managerFee,
            _tokenMetadata,
            _controller
        );
        _deployPortfolio(initCalldata);
    }
}

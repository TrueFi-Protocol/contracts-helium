// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "./IFlexiblePortfolio.sol";

interface IPermissionedPortfolio is IFlexiblePortfolio {
    function initialize(
        IProtocolConfig _protocolConfig,
        uint256 _duration,
        IERC20 _underlyingToken,
        address _manager,
        uint256 _maxValue,
        Strategies calldata _strategies,
        IDebtInstrument[] calldata _allowedInstruments,
        uint256 _managerFee,
        ERC20Metadata calldata _tokenMetadata,
        address _controller
    ) external;
}

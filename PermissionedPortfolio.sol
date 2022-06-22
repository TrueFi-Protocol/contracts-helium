// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;
import "./FlexiblePortfolio.sol";
import {ERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";

contract PermissionedPortfolio is FlexiblePortfolio {
    bytes32 public constant CONTROLLER_ROLE = keccak256("CONTROLLER_ROLE");

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
    ) external initializer {
        require(_controller != address(0), "PermissionedPortfolio: controller cannot be the zero address");
        __FlexiblePortfolio_init(
            _protocolConfig,
            _duration,
            _underlyingToken,
            _manager,
            _maxValue,
            _strategies,
            _allowedInstruments,
            _managerFee,
            _tokenMetadata
        );
        _grantRole(CONTROLLER_ROLE, _controller);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import {IProtocolConfig} from "./interfaces/IProtocolConfig.sol";
import {InitializableManageable} from "./access/InitializableManageable.sol";

contract ProtocolConfig is InitializableManageable, IProtocolConfig {
    uint256 public protocolFee;
    address public protocolAddress;
    uint256 public automatedLineOfCreditPremiumFee;

    event ProtocolFeeChanged(uint256 newProtocolFee);
    event ProtocolAddressChanged(address newProtocolAddress);

    constructor() InitializableManageable(msg.sender) {}

    function initialize(
        uint256 _protocolFee,
        address _protocolAddress,
        uint256 _automatedLineOfCreditPremiumFee
    ) external initializer {
        InitializableManageable.initialize(msg.sender);
        protocolFee = _protocolFee;
        protocolAddress = _protocolAddress;
        automatedLineOfCreditPremiumFee = _automatedLineOfCreditPremiumFee;
    }

    function setProtocolFee(uint256 newFee) external onlyManager {
        protocolFee = newFee;
        emit ProtocolFeeChanged(newFee);
    }

    function setProtocolAddress(address newProtocolAddress) external onlyManager {
        protocolAddress = newProtocolAddress;
        emit ProtocolAddressChanged(newProtocolAddress);
    }

    function setAutomatedLineOfCreditPremiumFee(uint256 newFee) external onlyManager {
        automatedLineOfCreditPremiumFee = newFee;
    }
}

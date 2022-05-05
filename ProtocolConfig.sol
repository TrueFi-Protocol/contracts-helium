// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {IProtocolConfig} from "./interfaces/IProtocolConfig.sol";
import {Upgradeable} from "./access/Upgradeable.sol";

contract ProtocolConfig is Upgradeable, IProtocolConfig {
    uint256 public protocolFee;
    address public protocolAddress;
    uint256 public automatedLineOfCreditPremiumFee;

    event ProtocolFeeChanged(uint256 newProtocolFee);
    event ProtocolAddressChanged(address indexed newProtocolAddress);
    event AutomatedLineOfCreditPremiumFeeChanged(uint256 newFee);

    function initialize(
        uint256 _protocolFee,
        address _protocolAddress,
        uint256 _automatedLineOfCreditPremiumFee
    ) external initializer {
        __Upgradeable_init(msg.sender);
        protocolFee = _protocolFee;
        protocolAddress = _protocolAddress;
        automatedLineOfCreditPremiumFee = _automatedLineOfCreditPremiumFee;
    }

    function setProtocolFee(uint256 newFee) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(newFee != protocolFee, "ProtocolConfig: New fee needs to be different");
        protocolFee = newFee;
        emit ProtocolFeeChanged(newFee);
    }

    function setProtocolAddress(address newProtocolAddress) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(newProtocolAddress != protocolAddress, "ProtocolConfig: New protocol address needs to be different");
        protocolAddress = newProtocolAddress;
        emit ProtocolAddressChanged(newProtocolAddress);
    }

    function setAutomatedLineOfCreditPremiumFee(uint256 newFee) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(newFee != automatedLineOfCreditPremiumFee, "ProtocolConfig: New fee needs to be different");
        automatedLineOfCreditPremiumFee = newFee;
        emit AutomatedLineOfCreditPremiumFeeChanged(newFee);
    }
}

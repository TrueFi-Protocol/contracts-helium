// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import {IProtocolConfig} from "./interfaces/IProtocolConfig.sol";
import {Upgradeable} from "./access/Upgradeable.sol";

contract ProtocolConfig is Upgradeable, IProtocolConfig {
    uint256 public protocolFee;
    address public protocolAddress;
    uint256 public automatedLineOfCreditPremiumFee;

    event ProtocolFeeChanged(uint256 newProtocolFee);
    event ProtocolAddressChanged(address newProtocolAddress);
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

    function setProtocolFee(uint256 newFee) external onlyAdministration {
        protocolFee = newFee;
        emit ProtocolFeeChanged(newFee);
    }

    function setProtocolAddress(address newProtocolAddress) external onlyAdministration {
        protocolAddress = newProtocolAddress;
        emit ProtocolAddressChanged(newProtocolAddress);
    }

    function setAutomatedLineOfCreditPremiumFee(uint256 newFee) external onlyAdministration {
        automatedLineOfCreditPremiumFee = newFee;
        emit AutomatedLineOfCreditPremiumFeeChanged(newFee);
    }
}

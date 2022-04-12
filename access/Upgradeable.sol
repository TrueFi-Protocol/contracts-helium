// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts/proxy/utils/UUPSUpgradeable.sol";

abstract contract Upgradeable is UUPSUpgradeable, Initializable {
    address public administration;
    address public pendingAdministration;

    event AdministrationTransferred(address oldAdministration, address newAdministration);

    constructor() initializer {}

    function __Upgradeable_init(address _administration) internal onlyInitializing {
        _setAdministration(_administration);
    }

    modifier onlyAdministration() {
        require(administration == msg.sender, "Upgradeable: Caller is not the administration");
        _;
    }

    function transferAdministration(address newAdministration) external onlyAdministration {
        pendingAdministration = newAdministration;
    }

    function claimAdministration() external {
        require(pendingAdministration == msg.sender, "Upgradeable: Caller is not the pending administration");
        _setAdministration(pendingAdministration);
        pendingAdministration = address(0);
    }

    function _setAdministration(address newAdministration) internal {
        address oldAdministration = administration;
        administration = newAdministration;
        emit AdministrationTransferred(oldAdministration, newAdministration);
    }

    function _authorizeUpgrade(address) internal override onlyAdministration {}
}

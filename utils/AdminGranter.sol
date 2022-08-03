// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;
import {AccessControlUpgradeable} from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";

contract AdminGranter {
    mapping(address => bool) public isOwner;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    constructor() {
        isOwner[msg.sender] = true;
    }

    function grantAdmin(address[] calldata contracts, address[] calldata admins) public {
        require(isOwner[msg.sender], "Caller is not owner");

        for (uint256 i = 0; i < admins.length; i++) {
            isOwner[admins[i]] = true;
        }

        for (uint256 i = 0; i < contracts.length; i++) {
            for (uint256 j = 0; j < admins.length; j++) {
                AccessControlUpgradeable(contracts[i]).grantRole(DEFAULT_ADMIN_ROLE, admins[j]);
            }
            AccessControlUpgradeable(contracts[i]).revokeRole(DEFAULT_ADMIN_ROLE, address(this));
        }
    }
}

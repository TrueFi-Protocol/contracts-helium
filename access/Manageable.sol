// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import {IManageable} from "./interfaces/IManageable.sol";

abstract contract Manageable is IManageable {
    address public manager;
    address public pendingManager;

    event ManagementTransferred(address indexed oldManager, address indexed newManager);

    modifier onlyManager() {
        require(manager == msg.sender, "Manageable: Caller is not the manager");
        _;
    }

    function __Manageable_init(address _manager) internal {
        manager = _manager;
    }

    function transferManagement(address newManager) external onlyManager {
        pendingManager = newManager;
    }

    function claimManagement() external {
        require(pendingManager == msg.sender, "Manageable: Caller is not the pending manager");
        _setManager(pendingManager);
        pendingManager = address(0);
    }

    function _setManager(address newManager) internal {
        address oldManager = manager;
        manager = newManager;
        emit ManagementTransferred(oldManager, newManager);
    }
}

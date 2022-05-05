// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {ITransferStrategy} from "../interfaces/ITransferStrategy.sol";
import {DSRegistryServiceInterface} from "../interfaces/DSRegistryServiceInterface.sol";

contract TransferAgentWhitelistTransferStrategy is ITransferStrategy {
    DSRegistryServiceInterface public registryService;

    constructor(DSRegistryServiceInterface _registryService) {
        registryService = _registryService;
    }

    function canTransfer(
        address from,
        address to,
        uint256
    ) external view returns (bool) {
        return _isValidInvestor(from) && _isValidInvestor(to);
    }

    function _isValidInvestor(address _address) private view returns (bool) {
        return registryService.isInvestor(registryService.getInvestor(_address));
    }
}

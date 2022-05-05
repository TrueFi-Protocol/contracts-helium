// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {IBasePortfolio} from "../interfaces/IBasePortfolio.sol";
import {DSRegistryServiceInterface} from "../interfaces/DSRegistryServiceInterface.sol";

contract TransferAgentWhitelistDepositStrategy {
    DSRegistryServiceInterface public registryService;

    constructor(DSRegistryServiceInterface _registryService) {
        registryService = _registryService;
    }

    function deposit(IBasePortfolio portfolio, uint256 amount) public {
        require(
            _isValidInvestor(msg.sender),
            "TransferAgentWhitelistDepositStrategy: Deposit wallet not associated with a valid investor"
        );
        portfolio.deposit(amount, msg.sender);
    }

    function _isValidInvestor(address _address) private view returns (bool) {
        return registryService.isInvestor(registryService.getInvestor(_address));
    }
}

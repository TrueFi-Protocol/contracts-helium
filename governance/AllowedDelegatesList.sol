// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {Upgradeable} from "../access/Upgradeable.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract AllowedDelegatesList is Upgradeable {
    ERC20 public tru;
    mapping(address => bool) public isAllowed;

    event AllowedListChanged(address account, bool isAllowed);

    function initialize(address pauser, ERC20 _tru) external initializer {
        __Upgradeable_init(msg.sender, pauser);
        tru = _tru;
    }

    function join() external {
        require(isAllowed[msg.sender] == false, "AllowedDelegatesList: Sender is already in the list");
        isAllowed[msg.sender] = true;
        tru.transferFrom(msg.sender, address(this), 10**tru.decimals());
        emit AllowedListChanged(msg.sender, true);
    }

    function leave() external {
        require(isAllowed[msg.sender] == true, "AllowedDelegatesList: Sender is not in the list");
        isAllowed[msg.sender] = false;
        tru.transfer(msg.sender, 10**tru.decimals());
        emit AllowedListChanged(msg.sender, false);
    }
}

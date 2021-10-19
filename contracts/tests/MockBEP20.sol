// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "../library/BEP20.sol";

contract MockBEP20 is BEP20 {
    constructor(
        string memory name,
        string memory symbol,
        uint256 supply
    ) public BEP20(name, symbol) {
        _mint(msg.sender, supply);
        _mint(address(this), 1000);
    }

    function mint(address account) public {
        _mint(account, 1000);
    }

    function mint(address account, uint amount) public {
        _mint(account, amount);
    }
}
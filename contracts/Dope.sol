// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "./interfaces/IBEP20.sol";
import "./library/BEP20.sol";
import "./library/SafeBEP20.sol";

contract ISO is BEP20("ISO", "ISO") {
    using SafeBEP20 for IBEP20;

    address public admin;
    address public controller;
    address public factory;
    address public lock;
    mapping(address => bool) public isMinter;

    event NewAdmin(address newAdmin);
    event NewController(address newController);
    event NewMinter(address newMinter);
    event NewFactory(address newFactory);
    event NewLock(address newLock);

    constructor(address _admin) public {
        admin = _admin;
    }

    function setAdmin(address newAdmin) public {
        require(msg.sender == admin, "admin");
        admin = newAdmin;

        emit NewAdmin(newAdmin);
    }

    function setController(address newController) public {
        require(msg.sender == admin, "admin");
        controller = newController;

        emit NewController(newController);
    }

    function setFactory(address newFactory) public {
        require(msg.sender == admin, "admin");
        factory = newFactory;

        emit NewFactory(newFactory);
    }

    function setLock(address newLock) public {
        require(msg.sender == admin, "admin");
        lock = newLock;

        emit NewLock(newLock);
    }

    function addMinter(address newMinter) public {
        require(msg.sender == admin, "admin");
        isMinter[newMinter] = true;

        emit NewMinter(newMinter);
    }

    function mint(address account, uint amount) public {
        require(isMinter[msg.sender], "minter");
        _mint(account, amount);
    }

    function burn(uint amount) public {
        _burn(msg.sender, amount);
    }
}
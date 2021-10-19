// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "./library/SafeMath.sol";
import "./library/SafeBEP20.sol";
import "./interfaces/ISOInterface.sol";

contract Lock {
    using SafeMath for uint;
    using SafeBEP20 for IBEP20;

    ISOInterface public iso;

    address public lockUpAsset;
    uint public minLockUpPeriod;
    uint private max32 = 2**32;

    bool public started;

    struct LockInfo {
        uint32 unlockBlock;
        uint224 unlockAmount;
        address asset;
    }

    mapping(address => LockInfo) public isLocked;
    uint public minLockUpAmount;

    event Locked(
        address indexed account,
        address indexed asset,
        uint currentBlock,
        uint endBlock,
        uint amount
    );
    event Unlocked(
        address indexed account,
        address indexed asset,
        uint currentBlock,
        uint amount
    );
    event NewLockUpAsset(address newLockUpAsset);
    event NewMinLockUpAmount(uint newMinLockUpAmount);
    event NewMinLockUpPeriod(uint newMinLockUpPeriod);

    constructor(
        address _iso
    ) public {
        iso = ISOInterface(_iso);
        started = false;
    }

    function setLockUpAsset(address newLockUpAsset) public {
        checkAdmin();
        lockUpAsset = newLockUpAsset;

        emit NewLockUpAsset(lockUpAsset);
    }

    function setMinLockUpAmount(uint newMinLockUpAmount) public {
        checkAdmin();
        require(newMinLockUpAmount < 2**224, "!u224");
        minLockUpAmount = newMinLockUpAmount;

        emit NewMinLockUpAmount(minLockUpAmount);
    }

    function setMinLockUpPeriod(uint newMinLockUpPeriod) public {
        checkAdmin();
        minLockUpPeriod = newMinLockUpPeriod;

        emit NewMinLockUpPeriod(minLockUpPeriod);
    }

    function lock() public {
        require(isLocked[msg.sender].unlockBlock == 0, "locked");
        IBEP20(lockUpAsset).safeTransferFrom(msg.sender, address(this), minLockUpAmount);
        uint currentBlock = block.number;

        uint unlockBlock = minLockUpPeriod.add(currentBlock);
        require(unlockBlock < max32, "!u32");

        isLocked[msg.sender] = LockInfo(
            uint32(unlockBlock),
            uint224(minLockUpAmount),
            lockUpAsset);

        emit Locked(
            msg.sender,
            lockUpAsset,
            currentBlock,
            isLocked[msg.sender].unlockBlock,
            minLockUpAmount);
    }

    function unlock() public {
        LockInfo memory currentLock = isLocked[msg.sender];
        require(currentLock.unlockBlock <= block.number, "!locked");

        IBEP20(currentLock.asset).safeTransfer(msg.sender, currentLock.unlockAmount);
        isLocked[msg.sender] = LockInfo(0,0,address(0));

        emit Unlocked(
            msg.sender,
            currentLock.asset,
            block.number,
            currentLock.unlockAmount);
    }

    function userLocked(address account) public view returns (bool) {
        return started ? isLocked[account].unlockBlock > 0 : true;
    }

    function checkAdmin() internal view {
        require(msg.sender == iso.admin(), "!admin");
    }
}
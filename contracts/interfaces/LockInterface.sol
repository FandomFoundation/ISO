// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

interface LockInterface {
    function userLocked(address account) external view returns (bool);
}
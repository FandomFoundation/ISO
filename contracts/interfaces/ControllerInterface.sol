// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

interface ControllerInterface {
    function isBaseAsset(address) external view returns (uint);
    function whitelists(address) external view returns (address[] memory);
    function isWhitelisted(address, address) external view returns (bool);
    function baseAssets(uint) external view returns (address);
    function IDOs(uint) external view returns (address);
}
// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

interface ISOInterface {
    function admin() external view returns (address);
    function controller() external view returns (address);
    function factory() external view returns (address);
    function lock() external view returns (address);
    function isMinter(address) external view returns (bool);
    function mint(address account, uint amount) external;
    function burn(uint amount) external;
}
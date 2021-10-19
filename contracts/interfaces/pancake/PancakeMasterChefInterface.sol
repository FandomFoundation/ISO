// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0;

interface PancakeMasterChefInterface {
    function poolInfo(uint idx) external view returns (address, uint, uint, uint);
    function userInfo(uint idx, address account) external view returns (uint, uint);
    function poolLength() external view returns (uint256);
    function pendingCake(uint256 _pid, address _user) external view returns (uint256);
    function deposit(uint256 _pid, uint256 _amount) external;
    function withdraw(uint256 _pid, uint256 _amount) external;
    function enterStaking(uint256 _amount) external;
    function leaveStaking(uint256 _amount) external;
}

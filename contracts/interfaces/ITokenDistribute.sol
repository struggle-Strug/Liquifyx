// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface ITokenDistribute{
    function tokenDistribute(address _investor, uint256 _agreementId) external;
}
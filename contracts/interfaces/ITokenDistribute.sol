// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface ITokenDistribute{
    //Function to distribute token
    function tokenDistribute(address _investor, uint256 _agreementId) external;
    //Function to withdraw investment
     function withdraw(address _investor,address _agent, uint256 _agreementId) external;
}
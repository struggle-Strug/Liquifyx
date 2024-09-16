// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IERC20{
    //Function to mint tokens
    function mintTokens(address to, uint256 amount) external;
    //Function to burn tokens
    function burnTokens(address from, uint256 amount) external;
    //Function to get the totalsupply
    function getTotalSupply() external view returns (uint256);
    //Function to get the balance of the account
    function getBalanceOf(address account) external view returns (uint256);
    //Function to transferFrom
    function transferTokensOnBehalf(address from, address to, uint256 amount) external;
}
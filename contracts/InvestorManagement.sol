// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";

contract InvestorManagement is Ownable{
    //struct investor details
    struct investorDetail {
        address walletAddress;
        string name;
        bool KYCApproved;
        bool AMLApproved;
        uint256 lastInteractionTimestamp;
        uint256 totalInvestments;
    }

    //mapping for all investors
    mapping(address => investorDetail) public investors;
    //addresses for kyc and aml provider
    address kycProvider;
    address amlProvider;
    //events
    event InvestorRegistered(address indexed investor, string name);
    event KycStatusUpdated(address indexed investor, bool status);
    event AmlStatusUpdated(address indexed investor, bool status);
    event InvestorInteraction(address indexed investor);

    constructor(address _kycProvider, address _amlProvider) Ownable(msg.sender){
        kycProvider = _kycProvider;
        amlProvider = _amlProvider;
    }



}
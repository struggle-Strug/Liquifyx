// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";

contract InvestorManagement is Ownable{
    //struct investor details
    struct InvestorDetail {
        address walletAddress;
        string name;
        bool KYCApproved;
        bool AMLApproved;
        uint256 lastInteractionTimestamp;
        uint256 totalInvestments;
    }

    //mapping for all investors
    mapping(address => InvestorDetail) public investors;
    //mapping to check wonder the investor is registered
    mapping(address => bool) public investorRegistered;
    //events
    event InvestorRegistered(address indexed investor, string name);
    event KycStatusUpdated(address indexed investor, bool status);
    event AmlStatusUpdated(address indexed investor, bool status);
    event InvestorInteraction(address indexed investor, uint256 timestamp);

    constructor() Ownable(msg.sender){
    }

    ///@notice function to create initial investor details
    ///@param _name the name of the investor
    function registerInvestor(string calldata _name) external {
        require(msg.sender != address(0), "Invalid address");
        require(!investorRegistered[msg.sender], "Investor is already registered");

        investors[msg.sender] = InvestorDetail({
            walletAddress: msg.sender,
            name: _name,
            KYCApproved: false,
            AMLApproved: false,
            lastInteractionTimestamp: block.timestamp,
            totalInvestments: 0
        });

        investorRegistered[msg.sender] = true;

        emit InvestorRegistered(msg.sender, _name);
    }

    ///@notice Function to track the interaction with platform
    function recordInteraction() external {
        require(investorRegistered[msg.sender], "Investor not registered");
        investors[msg.sender].lastInteractionTimestamp = block.timestamp;
        emit InvestorInteraction(msg.sender, block.timestamp);
    }

    ///@notice Function to update KYC status
    ///@param _walletAddress the address of the investor
    ///@param _status the updated KYC status of the investor
    function updateKYCStatus(address _walletAddress, bool _status) external onlyOwner{
        require(investorRegistered[_walletAddress], "Investor is not registered");
        InvestorDetail memory investorDetail = investors[_walletAddress];
        investorDetail.KYCApproved = _status;

        emit KycStatusUpdated(_walletAddress, _status);
    }

    ///@notice Function to update AML status
    ///@param _walletAddress the address of the investor
    ///@param _status the updated AML status of the investor
    function updateAMLStatus(address _walletAddress, bool _status) external onlyOwner{
        require(investorRegistered[_walletAddress], "Investor is not registered");

        InvestorDetail memory investorDetail = investors[_walletAddress];
        investorDetail.AMLApproved = _status;

        emit AmlStatusUpdated(_walletAddress, _status);
    }
}
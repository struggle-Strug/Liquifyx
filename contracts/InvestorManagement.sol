// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "./interfaces/IPaymentProcess.sol";

contract InvestorManagement is Ownable,ReentrancyGuard{
    //struct investor details
    struct InvestorDetail {
        address walletAddress;
        string name;
        bool KYCApproved;
        bool AMLApproved;
        uint256 lastInteractionTimestamp;
        uint256 totalInvestments;
    }

    //address of the agent
    address public agent;

    //PaymentProcess contract
    IPaymentProcess public paymentProcess;

    //mapping for all investors
    mapping(address => InvestorDetail) public investors;
    //mapping to check wonder the investor is registered
    mapping(address => bool) public investorRegistered;
    //events
    event InvestorRegistered(address indexed investor, string name);
    event KycStatusUpdated(address indexed investor, bool status);
    event AmlStatusUpdated(address indexed investor, bool status);
    event InvestorInteraction(address indexed investor,string interactionType, uint256 timestamp);
    event makeInvest(address indexed investor, uint amount);
    event requestWithdrawn(address indexed investor, uint agreementId);

    //modifier
    modifier onlyKYCApprover(){
        require(investors[msg.sender].KYCApproved, "The investor is not approved By KYC");
        _;
    }
    modifier onlyAMLApprover(){
        require(investors[msg.sender].AMLApproved, "The investor is not approved By AML");
        _;
    }

    constructor(address _agent) Ownable(msg.sender){
        agent = _agent;
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

    ///@notice Function to investor only KYC,AML Approver
    function invest() external payable nonReentrant onlyAMLApprover onlyKYCApprover {
        paymentProcess.makeInvestment(msg.sender, agent);

        emit makeInvest(msg.sender, msg.value);
    }

    ///@notice Function to request withdraw
    function requestWithdraw(uint256 _agreementId) external onlyAMLApprover onlyKYCApprover {
        paymentProcess.requestWithdraw(_agreementId);

        emit requestWithdrawn(msg.sender, _agreementId);
    }

    ///@notice Function to track the interaction with platform
    function recordInteraction(string calldata _interactionType) external {
        require(investorRegistered[msg.sender], "Investor not registered");
        investors[msg.sender].lastInteractionTimestamp = block.timestamp;
        emit InvestorInteraction(msg.sender, _interactionType, block.timestamp);
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

    ///@notice Function to upadte the address of the agent
    ///@param _newAddress the new address of the agent
    function updateAgentAddress(address _newAddress) external onlyOwner{
        agent = _newAddress;
    }

    ///@notice Function to set the PaymentProcess Contract Address
    ///@param _paymentProcess the address of the PaymentProcess
    function setPaymentProcessAddress(address _paymentProcess) public onlyOwner{
        IPaymentProcess(_paymentProcess);
    }
}
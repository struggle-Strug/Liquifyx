// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IInvestorManagement.sol";

contract InvestorGovernance is Ownable {
    IInvestorManagement public investorManagement;

    uint256 public proposalId;
    // period of the votin
    uint256 public immutable votingPeriod;

    struct Proposal {
        uint id;
        address proposer;
        string description;
        uint startTime;
        uint endTime;
        uint agrees;
        uint disagrees;
        bool executed;
    }

    // Mapping proposalId to the Proposal
    mapping(uint => Proposal) public proposals;

    //events
    event ProposalCreated(uint indexed proposalId, address proposer, string description);
    event Voted(uint indexed proposalId, address voter);
    event ProposalExecuted(uint indexed proposalId);

    //modifier
    modifier onlyRegistered(){
        require(investorManagement.isInvestorRegistered(msg.sender), "Investor is not registered");
        _;
    }

    modifier onlyKYCApproved(){
        require(investorManagement.getInvestorDetail(msg.sender).KYCApproved, "Investor isnot Approved by KYC");
        _;
    }

    modifier onlyAMLApproved(){
        require(investorManagement.getInvestorDetail(msg.sender).AMLApproved, "Investor isnot Approved by AML");
        _;
    }

    // constructor
    constructor(uint256 _votingPeriod) Ownable(msg.sender){
        votingPeriod = _votingPeriod;
    }

    ///@notice Function to create proposal
    ///@param _description The description of the proposal
    function createProposal(string calldata _description) external onlyRegistered onlyKYCApproved onlyAMLApproved{
        uint256 _id = proposalId++;

        proposals[_id] = Proposal({
            id: _id,
            proposer: msg.sender,
            description: _description,
            startTime: block.timestamp,
            endTime: block.timestamp + votingPeriod,
            agrees: 0,
            disagrees: 0,
            executed: false
        });

        emit ProposalCreated(_id, msg.sender, _description);
    }

    ///@notice Function to vote
    ///@param _proposalId The ID of the proposal
    ///@param _status The agree or disagree of the Proposer
    function vote(uint _proposalId, bool _status) external onlyRegistered onlyKYCApproved onlyAMLApproved{
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.endTime >= block.timestamp && proposal.startTime <= block.timestamp, "The Vote is already finished");

        uint votes = investorManagement.getInvestorDetail(msg.sender).totalInvestments;
        require(votes > 0, "No voting power");

        if(_status){
            proposal.agrees += votes;
        }else{
            proposal.disagrees += votes;
        }

        emit Voted(_proposalId, msg.sender);
    }

    ///@notice Function to execute the proposal
    ///@param _proposalId The ID of the proposal
    function executeProposal(uint _proposalId) external onlyOwner onlyRegistered onlyKYCApproved onlyAMLApproved{
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.endTime >= block.timestamp && proposal.startTime <= block.timestamp, "The Vote is already finished");
        require(proposal.agrees > proposal.disagrees, "The Proposal did not pass");

        proposal.executed = true;

        emit ProposalExecuted(_proposalId);
    }

    ///@notice Function to get the Proposal Details
    ///@param _proposalId The ID of the proposal
    function getProposalDetails(uint256 _proposalId) external view returns (
        address proposer,
        string memory description,
        uint256 forVotes,
        uint256 againstVotes,
        uint256 startTime,
        uint256 endTime,
        bool executed
    ) {
        Proposal memory proposal = proposals[_proposalId];
        return (
            proposal.proposer,
            proposal.description,
            proposal.agrees,
            proposal.disagrees,
            proposal.startTime,
            proposal.endTime,
            proposal.executed
        );
    }

    ///@notice Function to get the status that proposal is executed
    ///@param _proposalId The Id of the Proposal
    function isExecuted(uint256 _proposalId) external view returns (bool) {
        return proposals[_proposalId].executed;
    }

    ///@notice Function to set the InvestorManagement Contract Address
    ///@param _investorManagementAddress the address of the PaymentProcess
    function setInvestorManagementAddress(address _investorManagementAddress) public onlyOwner{
        IInvestorManagement(_investorManagementAddress);
    }
}
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./interfaces/IInvestorEscrow.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";


contract PaymentProcess is ReentrancyGuard,AccessControl {
    // Reference to the MultiEscrow contract
    IInvestorEscrow public escrowContract;

    // Struct to represent an individual investment
    struct Investment {
        uint256 amount;       // Amount invested
        uint256 timestamp;    // Time of investment
        bool isCreated;     // Whether the investment has been created
        bool canceled;        // Whether the investment has been canceled
    }

    // Mapping to store investments for each investor
    mapping(address => mapping(uint256 => Investment)) public investorInvestment;
    // Mapping to store investment agreementIds 
    mapping(address => uint256[]) public investorAgreementIds;
    // Mapping to track total invested amount for each investor
    mapping(address => uint256) public totalInvestedAmount;
    // Mapping to track number of completed investments for each investor
    mapping(address => uint256) public completedInvestments;

    //Role
    bytes32 public constant APPROVER_ROLE = keccak256("APPROVED_ROLE");

    //events
    event InvestmentMade(address indexed investor, uint agreementId, uint amount);
    event InvestmentApproved(address indexed requester, uint agreementId);
    event InvestmentCreated(address indexed investor, uint agreementId);
    event InvestmentWithdrawn(address indexed investor, uint256 indexed agreementId, uint256 amount);
    event EscrowContractUpdated(address newEscrowContract);

    // Constructor to set the address of the MultiEscrow contract
    constructor(address _escrowContractAddress){
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(APPROVER_ROLE, msg.sender);
        escrowContract = IInvestorEscrow(_escrowContractAddress);
    }

    ///@notice Function to make investment
    ///@param _seller address of the seller
    ///@param _agent address of the agent
    function makeInvestment(address _seller, address _agent) external payable nonReentrant {
        require(msg.value > 0, "Investment value must be greater than 0");
        require(_seller != address(0) && _agent != address(0), "Invalid seller or agent address");

        uint256 agreementId = escrowContract.createAgreement(msg.sender, _seller, _agent);

        escrowContract.deposit{value: msg.value}(agreementId);

        (,,,uint amount,,,,,,,,,) = escrowContract.agreementDetails(agreementId);
        require(amount == msg.value, "Deposit failed");

        Investment memory newInvestment = Investment({
            amount: msg.value,
            timestamp: block.timestamp,
            isCreated: false,
            canceled: false
        });

        investorInvestment[msg.sender][agreementId] = newInvestment;
        investorAgreementIds[msg.sender].push(agreementId);
        totalInvestedAmount[msg.sender] += msg.value;

        emit InvestmentMade(msg.sender, agreementId, msg.value);
    }

    ///@notice Function to approve investment
    ///@param _agreementId agreementID of the investment
    function approveInvestment(uint256 _agreementId) external {
        require(_agreementId != 0, "Invalid agreementID");
        escrowContract.approve(_agreementId);
        
        bool state = escrowContract.checkApproval(msg.sender, _agreementId);
        require(state == true, "Approval failed");

        (,,,,,,,uint8 contractStatus,,,,,) = escrowContract.agreementDetails(_agreementId);
        require(contractStatus == 3, "AgreementApproval failed");
        _updateInvestmentStatus(msg.sender, _agreementId);
    }

    ///@notice Function to update investment status
    ///@param _investor address of the investor
    ///@param _agreementId agreementID of the investment
    function _updateInvestmentStatus(address _investor, uint256 _agreementId) internal {
                (,,,,bool fundsDisbursed,,,,,,,,) = escrowContract.agreementDetails(_agreementId);
                if(fundsDisbursed){
                    investorInvestment[_investor][_agreementId].isCreated = true;
                    completedInvestments[_investor]++;
                    emit InvestmentCreated(_investor, _agreementId);
                }
    }

    ///@notice Function to get All investments for a specific investor
    ///@param _investor address of the investor
    ///@return Details of the investment
    function getInvestorInvestments(address _investor) external view returns(uint256, uint256, uint256){
        uint256 total = investorAgreementIds[_investor].length;
        uint256 completed = completedInvestments[_investor];
        uint256 active = total - completed;
        return (total, active, completed);
    }

    ///@notice Function to request to withdraw investment
    ///@param _agreementId ID of the agreementID
    function requestWithdraw(uint256 _agreementId) external onlyRole(APPROVER_ROLE) {
        address investor = _getInvestorByAgreementId(_agreementId);
        require(investor == msg.sender, "Only Investor can request to cancel Agreement");
        Investment memory investment = investorInvestment[msg.sender][_agreementId];
        require(!investment.canceled, "Investment already canceled");

        escrowContract.requestCancel(_agreementId);
    }

    ///@notice Function to withdraw investment
    ///@param _agreementId ID of the agreementID
    function withdraw(uint256 _agreementId) external nonReentrant {
        (address buyer,,address agent,uint256 amount,,,uint8 contractStatus,,,,,,) = escrowContract.agreementDetails(_agreementId);
        require(msg.sender == agent, "Only Agent of the Agreement can cancel the Agreement");
        require(contractStatus == 5, "Approve doesn't canceled");

        totalInvestedAmount[buyer] -= amount;
        investorInvestment[buyer][_agreementId].canceled = true;

        emit InvestmentWithdrawn(buyer, _agreementId, amount);
    }

    ///@notice Function to get details about a certain investment
    ///@param _investor address of the investor
    ///@param _agreementId The ID of the agreement
    function getInvestmentDetail(address _investor, uint256 _agreementId) external view returns(Investment memory){
        return investorInvestment[_investor][_agreementId];
    }

    ///@notice Function to get the address of the investor by agreementId
    ///@param _agreementId The ID of the agreement
    function _getInvestorByAgreementId(uint256 _agreementId) internal view returns(address investor) {
        require(_agreementId != 0, "Invalid agreementID");

        (investor,,,,,,,,,,,,) = escrowContract.agreementDetails(_agreementId);
        return investor;
    }

    ///@notice Function for owner to update the address of the escrow contract
    ///@param _newEscrowContract the address of the new Contract address
    function updateEscrowContract(address _newEscrowContract) external onlyRole(DEFAULT_ADMIN_ROLE) {
        escrowContract = IInvestorEscrow(_newEscrowContract);
    }

    // Fallback function to receive Ether
    receive() external payable {
        revert("Direct payments not accepted");
    }
}
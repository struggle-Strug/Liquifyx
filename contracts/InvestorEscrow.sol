// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "./interfaces/IPaymentProcess.sol";
import "hardhat/console.sol";

/// @title Investor Escrow Contract
/// @notice This contract holds funds in escrow until certain predefined conditions are met.
contract InvestorEscrow is ReentrancyGuard,Ownable {
    //PaymentProcess contract
    IPaymentProcess public paymentProcess;

    // Enum to represent the status of the buyer and the contract
    enum BuyerStatus { AwaitingDeposit, Deposited, Approved, Refunded }
    enum ContractStatus { Created, Funded, Approved, Completed, Refunded, Expired, Disputed }
    enum DisputeStatus { NoDispute, DisputeRaised, DisputeResolved }

     // Struct to hold all data for a single escrow agreement
    struct EscrowAgreement {
        address buyer;
        address seller;
        address agent;
        uint256 amount;
        bool fundsDisbursed;
        bool sellerApproved;
        BuyerStatus buyerStatus;
        ContractStatus contractStatus;
        DisputeStatus disputeStatus;
        bool buyerRequestedCancel;
        bool buyerRequestedComplete;
        uint256 expirationTime;
        string disputeReason;
    }

    //Mapping to store multiple escrow agreements
    mapping(uint256 => EscrowAgreement) public agreements;

    //Nested mapping to track approvals for each agreements
    mapping(uint256 => mapping(address => bool)) public approvals;

    //Counter for generating unique agreements IDs
    uint256 public nextAgreementId;

    //Events to log important logs
    event AgreementCreated(uint256 indexed agreementId, address buyer, address seller, address agent);
    event Deposited(uint256 indexed agreementId, uint256 amount);
    event AgreementApproved(uint256 indexed agreementId, address approver);
    event AgreementCanceled(uint256 indexed agreementId);
    event AgreementCompleted(uint256 indexed agreementId);
    event AgreementExpired(uint256 indexed agreementId);
    event DisputeRaised(uint256 indexed agreementId, address raiser, string reason);
    event DisputeResolved(uint256 indexed agreementId, bool buyerFavored);
    // Event for unexpected Ether received
    event EtherReceived(address sender, uint256 amount);

     // Modifier to restrict access to the buyer of an agreement
     /// @param _agreementId The ID of the agreement
    modifier onlyBuyer(uint256 _agreementId){
        require(msg.sender == agreements[_agreementId].buyer, "Only buyer can call this function");
        _;
    }

    // Modifier to restrict access to the agent of an agreement
    /// @param _agreementId The ID of the agreement
    modifier onlyAgent(uint256 _agreementId){
        require(msg.sender == agreements[_agreementId].agent, "Only buyer can call this function");
        _;
    }

    // Modifier to restrict access to the buyer or seller of an agreement
    /// @param _agreementId The ID of the agreement
    modifier onlyBuyerOrSeller(uint256 _agreementId){
        require(
            msg.sender == agreements[_agreementId].buyer || msg.sender == agreements[_agreementId].seller,
            "Only Buyer or Seller can call this function"
        );
        _;
    }

    // Modifier to check the Agreement Expiration
    ///@param _agreementId The ID of the agreement
    modifier notExpired(uint256 _agreementId){
        require(block.timestamp <= agreements[_agreementId].expirationTime, "Agreement have already Expired");
        _;
    }

    //constructor
    constructor() Ownable(msg.sender) {
    }

    /// @notice Create a new escrow agreement
    /// @param _seller The address of the seller
    /// @param _agent The address of the agent
    /// @return The ID of the newly created agreement
    function createAgreement(address _seller, address _agent) external returns(uint256) {
        uint256 agreementId = nextAgreementId++;
        agreements[agreementId] = EscrowAgreement({
            buyer: msg.sender,
            seller: _seller,
            agent: _agent,
            amount: 0,
            fundsDisbursed: false,
            sellerApproved: false,
            buyerStatus: BuyerStatus.AwaitingDeposit,
            contractStatus: ContractStatus.Created,
            buyerRequestedCancel: false,
            buyerRequestedComplete: false,
            expirationTime: 0,
            disputeStatus: DisputeStatus.NoDispute,
            disputeReason: ""
        });

        emit AgreementCreated(agreementId, msg.sender, _seller, _agent);
        return agreementId;
    }

    /// @notice Deposit funds into the escrow
    /// @param _agreementId The ID of the agreement
    function deposit(uint256 _agreementId) external payable nonReentrant onlyBuyer(_agreementId) {
        EscrowAgreement memory agreement = agreements[_agreementId];
        require(agreement.amount == 0, "Deposit already made");
        agreement.amount = msg.value;
        agreement.buyerStatus = BuyerStatus.Deposited;
        agreement.contractStatus = ContractStatus.Funded;

        (bool success,) = agreement.agent.call{value: msg.value}("");
        console.log("success",success);
        console.log("amount",agreement.amount);
        console.log("_agreementId",_agreementId);
        console.log("Reached here!!!!!!!!!");
        if(!success) revert();

        emit Deposited(_agreementId, msg.value);
    }

    /// @notice Approve the agreement
    /// @param _agreementId The ID of the agreement
    /// @param _duration The Duration of the agreement avaliable
    function approve(uint256 _agreementId, uint256 _duration) external onlyBuyerOrSeller(_agreementId) {
        EscrowAgreement storage agreement = agreements[_agreementId];
        require(agreement.contractStatus == ContractStatus.Funded, "Contract not funded");

        approvals[_agreementId][msg.sender] = true;
        if(msg.sender == agreement.buyer){
            agreement.buyerStatus = BuyerStatus.Approved;
        } else if(msg.sender == agreement.seller){
            agreement.sellerApproved = true;
        }

        if(agreement.buyerStatus == BuyerStatus.Approved && agreement.sellerApproved){
            agreement.contractStatus = ContractStatus.Approved;
            agreement.expirationTime = block.timestamp + _duration;

            emit AgreementApproved(_agreementId, msg.sender);
        }
    }

    /// @notice Request cancellation of the agreement by the buyer
    /// @param _agreementId The ID of the agreement
    function requestCancel(uint256 _agreementId) external onlyBuyer(_agreementId) notExpired(_agreementId) {
        EscrowAgreement storage agreement = agreements[_agreementId];
        require(
            agreement.contractStatus == ContractStatus.Approved || agreement.contractStatus == ContractStatus.Funded,
            "Invalid contract status"
            );
        agreement.buyerRequestedCancel = true;
    }

    /// @notice Cancel the agreement by the agent
    /// @param _agreementId The ID of the agreement
    function requestComplete(uint256 _agreementId) external onlyBuyerOrSeller(_agreementId) notExpired(_agreementId) {
        EscrowAgreement storage agreement = agreements[_agreementId];
        require(
            agreement.contractStatus == ContractStatus.Approved || agreement.contractStatus == ContractStatus.Funded,
            "Invalid contract status"
        );
        agreement.buyerRequestedComplete = true;
    }

    //Function for the agent to cancel the agreement
    function agentCancel(uint256 _agreementId) external payable nonReentrant onlyAgent(_agreementId) notExpired(_agreementId) {
        EscrowAgreement storage agreement = agreements[_agreementId];
        require(agreement.buyerRequestedCancel, "Buyer must request the cancellation");
        require(!agreement.fundsDisbursed, "The Fund already Disbursed");
        require(
            agreement.contractStatus == ContractStatus.Approved || agreement.contractStatus == ContractStatus.Funded,
            "Invalid contract status"
        );
        payable(agreement.buyer).transfer(agreement.amount);
        (bool success,) = agreement.buyer.call{value: agreement.amount}("");
        if(!success) revert();

        agreement.fundsDisbursed = true;
        agreement.buyerStatus = BuyerStatus.Refunded;
        agreement.contractStatus = ContractStatus.Refunded;

        paymentProcess.withdraw(_agreementId);

        emit AgreementCanceled(_agreementId);
    }

    /// @notice Complete the agreement by the agent
    /// @param _agreementId The ID of the agreement
    function agentComplete(uint256 _agreementId) external payable nonReentrant onlyAgent(_agreementId) notExpired(_agreementId) {
        EscrowAgreement storage agreement = agreements[_agreementId];
        require(msg.sender == agreement.agent, "Only agent can complete the agreement");
        require(agreement.buyerRequestedComplete, "Buyer must request the complete");
        require(!agreement.fundsDisbursed, "The Fund already Disbursed");
        require(
            agreement.contractStatus == ContractStatus.Approved || agreement.contractStatus == ContractStatus.Funded,
            "Invalid contract status"
        );
        payable(agreement.seller).transfer(agreement.amount);
        (bool success,) = agreement.seller.call{value: agreement.amount}("");
        if(!success) revert();

        agreement.fundsDisbursed = true;
        agreement.contractStatus = ContractStatus.Completed;

        emit AgreementCompleted(_agreementId);
    }

    ///@notice function to check the agreement expired
    ///@param _agreementId The ID of the agreement
    function checkAndHandleExpiration(uint256 _agreementId) external onlyAgent(_agreementId){
        EscrowAgreement memory agreement = agreements[_agreementId];
        require(block.timestamp > agreement.expirationTime, "Agreement haven't expired yet");
        require(
            agreement.contractStatus != ContractStatus.Completed && agreement.contractStatus != ContractStatus.Refunded,
            "Agreement already finalized"
        );

        agreement.contractStatus = ContractStatus.Expired;
        if (!agreement.fundsDisbursed && agreement.amount > 0) {
            agreement.fundsDisbursed = true;
            payable(agreement.buyer).transfer(agreement.amount);
        }

        emit AgreementExpired(_agreementId);
    }

    /// @notice Raise a dispute for an agreement
    /// @param _agreementId The ID of the agreement
    /// @param _reason The reason for raising the dispute
    function raiseDispute(uint256 _agreementId, string memory _reason) external notExpired(_agreementId) onlyBuyerOrSeller(_agreementId) {
        EscrowAgreement storage agreement = agreements[_agreementId];
        require(agreement.disputeStatus == DisputeStatus.NoDispute, "Dispute already raised");
        require(agreement.contractStatus != ContractStatus.Completed && agreement.contractStatus != ContractStatus.Refunded, "Agreement already finalized");

        agreement.disputeStatus = DisputeStatus.DisputeRaised;
        agreement.disputeReason = _reason;
        agreement.contractStatus = ContractStatus.Disputed;

        emit DisputeRaised(_agreementId, msg.sender, _reason);
    }

    /// @notice Resolve a dispute for an agreement
    /// @param _agreementId The ID of the agreement
    /// @param _buyerFavored Whether the resolution favors the buyer
    function resolveDispute(uint256 _agreementId, bool _buyerFavored) external onlyAgent(_agreementId) {
        EscrowAgreement storage agreement = agreements[_agreementId];
        require(agreement.disputeStatus == DisputeStatus.DisputeRaised, "No active dispute");

        agreement.disputeStatus = DisputeStatus.DisputeResolved;

        if (_buyerFavored) {
            agreement.contractStatus = ContractStatus.Refunded;
            payable(agreement.buyer).transfer(agreement.amount);
        } else {
            agreement.contractStatus = ContractStatus.Completed;
            payable(agreement.seller).transfer(agreement.amount);
        }

        agreement.fundsDisbursed = true;
        emit DisputeResolved(_agreementId, _buyerFavored);
    }

    /// @notice Get the details of an agreement
    /// @param _agreementId The ID of the agreement
    /// @return buyer The address of the buyer
    /// @return seller The address of the seller
    /// @return agent The address of the agent
    /// @return amount The amount of the agreement
    /// @return fundsDisbursed A boolean indicating if funds have been disbursed
    /// @return sellerApproved A boolean indicating if the seller has approved
    /// @return buyerStatus The status of the buyer
    /// @return contractStatus The status of the contract
    /// @return buyerRequestedCancel A boolean indicating if the buyer requested cancellation
    /// @return buyerRequestedComplete A boolean indicating if the buyer requested completion
    function agreementDetails(uint256 _agreementId) external view returns(
        address buyer,
        address seller,
        address agent,
        uint amount,
        bool fundsDisbursed,
        bool sellerApproved,
        BuyerStatus buyerStatus,
        ContractStatus contractStatus,
        bool buyerRequestedCancel,
        bool buyerRequestedComplete,
        uint expirationTime
    ) {
        EscrowAgreement storage agreement = agreements[_agreementId];
        return (
            agreement.buyer,
            agreement.seller,
            agreement.agent,
            agreement.amount,
            agreement.fundsDisbursed,
            agreement.sellerApproved,
            agreement.buyerStatus,
            agreement.contractStatus,
            agreement.buyerRequestedCancel,
            agreement.buyerRequestedComplete,
            agreement.expirationTime
        );
    }

    ///@notice Function to check the approve state
    ///@param _member the address of the investor
    ///@param _agreementId the ID of the agreement
    function checkApproval(address _member, uint256 _agreementId) external view returns(bool) {
        bool state = approvals[_agreementId][_member];

        return state;
    }

    ///@notice Function to set the PaymentProcess Contract Address
    ///@param _paymentProcess the address of the PaymentProcess
    function setPaymentProcessAddress(address _paymentProcess) public onlyOwner{
        IPaymentProcess(_paymentProcess);
    }

    ///@notice receive functon
    receive() external payable{
        emit EtherReceived(msg.sender, msg.value);
    }

    ///@notice fallback function
    fallback() external payable {
        emit EtherReceived(msg.sender, msg.value);
    }

}
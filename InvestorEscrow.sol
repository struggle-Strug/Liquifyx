// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract InvestorEscrow {
    // Struct to hold all data for a single escrow agreement
    struct EscrowAgreement {
        address buyer;
        address seller;
        address arbiter;
        uint amount;
        bool fundsDisbursed;
        BuyerStatus buyerStatus;
        ContractStatus contractStatus;
        bool buyerRequestedCancel;
        bool buyerRequestedComplete;
    }

    // Enums to represent the status of the buyer and the contract
    enum BuyerStatus { AwaitingDeposit, DepositMade, Approved, Refunded }
    enum ContractStatus { Created, Funded, Approved, Completed, Refunded, Cancelled }

    // Mapping to store multiple escrow agreements
    mapping(uint256 => EscrowAgreement) public agreements;
    // Nested mapping to track approvals for each agreement
    mapping(uint256 => mapping(address => bool)) public approvals;

    // Counter for generating unique agreement IDs
    uint256 public nextAgreementId;

    // Events to log important actions
    event AgreementCreated(uint256 indexed agreementId, address buyer, address seller, address arbiter);
    event DepositMade(uint256 indexed agreementId, uint amount);
    event AgreementApproved(uint256 indexed agreementId, address approver);
    event AgreementCompleted(uint256 indexed agreementId);
    event AgreementCancelled(uint256 indexed agreementId);

    // Function to create a new escrow agreement
    function createAgreement(address _buyer, address _seller, address _arbiter) external returns (uint256) {
        uint256 agreementId = nextAgreementId++;
        
        agreements[agreementId] = EscrowAgreement({
            buyer: _buyer,
            seller: _seller,
            arbiter: _arbiter,
            amount: 0,
            fundsDisbursed: false,
            buyerStatus: BuyerStatus.AwaitingDeposit,
            contractStatus: ContractStatus.Created,
            buyerRequestedCancel: false,
            buyerRequestedComplete: false
        });

        emit AgreementCreated(agreementId, _buyer, _seller, _arbiter);
        return agreementId;
    }

    // Function for the buyer to deposit funds
    function deposit(uint256 _agreementId) external payable {
        EscrowAgreement storage agreement = agreements[_agreementId];
        require(msg.sender == agreement.buyer, "Only buyer can deposit");
        require(agreement.amount == 0, "Deposit already made");
        
        agreement.amount = msg.value;
        agreement.buyerStatus = BuyerStatus.DepositMade;
        agreement.contractStatus = ContractStatus.Funded;

        emit DepositMade(_agreementId, msg.value);
    }

    // Function for parties to approve the agreement
    function approve(uint256 _agreementId) external {
        EscrowAgreement storage agreement = agreements[_agreementId];
        require(msg.sender == agreement.buyer || msg.sender == agreement.seller || msg.sender == agreement.arbiter, "Not authorized");
        require(agreement.contractStatus == ContractStatus.Funded, "Contract not funded");
        
        approvals[_agreementId][msg.sender] = true;
        
        if (msg.sender == agreement.buyer) {
            agreement.buyerStatus = BuyerStatus.Approved;
        }

        emit AgreementApproved(_agreementId, msg.sender);

        // If both buyer and seller approve, or if arbiter approves, complete the agreement
        if ((approvals[_agreementId][agreement.buyer] && approvals[_agreementId][agreement.seller]) || approvals[_agreementId][agreement.arbiter]) {
            payable(agreement.seller).transfer(agreement.amount);
            agreement.fundsDisbursed = true;
            agreement.contractStatus = ContractStatus.Completed;
            emit AgreementCompleted(_agreementId);
        } else {
            agreement.contractStatus = ContractStatus.Approved;
        }
    }

    // Function for the buyer to request cancellation
    function requestCancel(uint256 _agreementId) external {
        EscrowAgreement storage agreement = agreements[_agreementId];
        require(msg.sender == agreement.buyer, "Only buyer can request cancellation");
        require(agreement.contractStatus == ContractStatus.Funded || agreement.contractStatus == ContractStatus.Approved, "Invalid contract status for cancellation request");
        agreement.buyerRequestedCancel = true;
    }

    // Function for the buyer to request completion
    function requestComplete(uint256 _agreementId) external {
        EscrowAgreement storage agreement = agreements[_agreementId];
        require(msg.sender == agreement.buyer, "Only buyer can request completion");
        require(agreement.contractStatus == ContractStatus.Funded || agreement.contractStatus == ContractStatus.Approved, "Invalid contract status for completion request");
        agreement.buyerRequestedComplete = true;
    }

    // Function for the arbiter to cancel the agreement
    function arbiterCancel(uint256 _agreementId) external {
        EscrowAgreement storage agreement = agreements[_agreementId];
        require(msg.sender == agreement.arbiter, "Only arbiter can cancel");
        require(agreement.buyerRequestedCancel, "Buyer has not requested cancellation");
        require(!agreement.fundsDisbursed, "Funds already disbursed");
        require(agreement.contractStatus == ContractStatus.Funded || agreement.contractStatus == ContractStatus.Approved, "Invalid contract status for cancellation");
        
        payable(agreement.buyer).transfer(agreement.amount);
        agreement.fundsDisbursed = true;
        agreement.buyerStatus = BuyerStatus.Refunded;
        agreement.contractStatus = ContractStatus.Cancelled;

        emit AgreementCancelled(_agreementId);
    }

    // Function for the arbiter to complete the agreement
    function arbiterComplete(uint256 _agreementId) external {
        EscrowAgreement storage agreement = agreements[_agreementId];
        require(msg.sender == agreement.arbiter, "Only arbiter can complete");
        require(agreement.buyerRequestedComplete, "Buyer has not requested completion");
        require(!agreement.fundsDisbursed, "Funds already disbursed");
        require(agreement.contractStatus == ContractStatus.Funded || agreement.contractStatus == ContractStatus.Approved, "Invalid contract status for completion");
        
        payable(agreement.seller).transfer(agreement.amount);
        agreement.fundsDisbursed = true;
        agreement.contractStatus = ContractStatus.Completed;

        emit AgreementCompleted(_agreementId);
    }

    // Function to get all details of a specific agreement
    function getAgreementDetails(uint256 _agreementId) external view returns (
        address buyer,
        address seller,
        address arbiter,
        uint amount,
        bool fundsDisbursed,
        BuyerStatus buyerStatus,
        ContractStatus contractStatus,
        bool buyerRequestedCancel,
        bool buyerRequestedComplete
    ) {
        EscrowAgreement storage agreement = agreements[_agreementId];
        return (
            agreement.buyer,
            agreement.seller,
            agreement.arbiter,
            agreement.amount,
            agreement.fundsDisbursed,
            agreement.buyerStatus,
            agreement.contractStatus,
            agreement.buyerRequestedCancel,
            agreement.buyerRequestedComplete
        );
    }
}
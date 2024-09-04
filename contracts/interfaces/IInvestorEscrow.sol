// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IInvestorEscrow {
    function createAgreement(address _buyer, address _seller, address _agent) external returns(uint256);
    function deposit(uint256 _agreementId) external payable;
    function approve(uint256 _agreementId) external;
    function requestCancel(uint256 _agreementId) external;
    function agreementDetails(uint256 _agreementId) external view returns(
        address buyer,
        address seller,
        address agent,
        uint amount,
        bool fundsDisbursed,
        bool sellerApproved,
        uint8 buyerStatus,
        uint8 contractStatus,
        uint8 disputeStatus,
        bool buyerRequestedCancel,
        bool buyerRequestedComplete,
        uint256 expirationTime,
        string memory disputeReason
    );
    function checkApproval(address _member, uint256 _agreementId) external view returns(bool);
}
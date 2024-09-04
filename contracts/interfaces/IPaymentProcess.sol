// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;


interface IPaymentProcess {
    //struct Investment Details
    struct Investment {
        uint256 agreementId;
        uint256 amount;
        uint256 timestamp;
        bool isCompleted;
    }
    //Function to createAgreemtn
    function makeInvestment(address _seller, address _agent) external payable;
    //Function to approve the agreement
    function approveInvestment(uint256 _agreementId) external;
    //Function to get the Investment Detail
    function getInvestmentDetail(address _investor, uint256 _agreementId) external view returns(Investment memory);
    //Function to withdraw
    function withdraw(uint256 _agreementId) external;
}
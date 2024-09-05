// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./interfaces/IPaymentProcess.sol";
import "./interfaces/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


contract TokenDistribute is Ownable{
    IPaymentProcess public paymentProcess;
    IERC20 public token;
    address agent;
    address owner;
    uint256 tokenPerEther;

    //mapping to get the tokenbalance of the agreement
    mapping(uint256 => uint256) tokenBalance;
    //event for token mint and distribute
    event TokenDistributed(address indexed _investor, uint256 _tokenAmount);
    //event for withdraw token
    event TokenWithdrawn(address indexed _investor, uint256 _agreementId, uint256 _tokenAmount);

    constructor(address _paymentProcess, address _token, address _agent, uint256 _tokenPerEther, address _owner) Ownable(_owner){
        paymentProcess = IPaymentProcess(_paymentProcess);
        token = IERC20(_token);
        agent = _agent;
        owner = _owner;
        tokenPerEther = _tokenPerEther;
    }

    ///@notice Function to token mint and distribute
    ///@param _investor addresss of the investor
    ///@param _agreementId the ID of the agreement
    function tokenDistribute(address _investor, uint256 _agreementId) external onlyOwner {
        IPaymentProcess.Investment memory investment = paymentProcess.getInvestmentDetail(_investor, _agreementId);
        require(investment.isCreated == true, "The Investment is not created");

        uint256 etherAmount = investment.amount;
        uint256 tokenAmount = (etherAmount * tokenPerEther) / 1 ether;

        tokenBalance[_agreementId] = tokenAmount;

        token.mintTokens(_investor, tokenAmount);

        emit TokenDistributed(_investor, tokenAmount);
    }
    
    ///@notice Function to withdraw
    ///@param _investor the address of the investor
    ///@param _agreementId the ID of the agreement
    function withdraw(address _investor, uint256 _agreementId) external {
        IPaymentProcess.Investment memory investment = paymentProcess.getInvestmentDetail(_investor, _agreementId);
        require(investment.canceled, "Agreement hasn't canceled yet");
        require(msg.sender == agent, "Only agent can call this function");

        uint256 withdrawTokenAmount = tokenBalance[_agreementId];

        token.burnTokens(_investor, withdrawTokenAmount);

        emit TokenWithdrawn(_investor, _agreementId, withdrawTokenAmount);
    }

    ///@notice Function to update the paymentProcess contract address
    ///@param _newAddress the new paymentProcessAddress
    function updatePaymentProcessAddress(address _newAddress) external onlyOwner {
        paymentProcess = IPaymentProcess(_newAddress);
    }

    ///@notice Functon to update the token address
    ///@param _newAddress the newTokenAddress
    function updateTokenAddress(address _newAddress) external onlyOwner {
        token = IERC20(_newAddress);
    }

    ///@notice Function to update agent address
    ///@param _newAddress the address of the new agent
    function updateAgentAddress(address _newAddress) external onlyOwner{
        agent = _newAddress;
    }

}
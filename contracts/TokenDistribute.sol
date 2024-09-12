// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./interfaces/IPaymentProcess.sol";
import "./interfaces/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


contract TokenDistribute is Ownable{
    IPaymentProcess public paymentProcess;
    IERC20 public token;
    uint256 tokenPerEther;

    //mapping to get the tokenbalance of the agreement
    mapping(uint256 => uint256) tokenBalance;
    //event for token mint and distribute
    event TokenDistributed(address indexed _investor, uint256 _tokenAmount);
    //event for withdraw token
    event TokenWithdrawn(address indexed _investor, uint256 _agreementId, uint256 _tokenAmount);

    constructor(address _token, uint256 _tokenPerEther, address _owner) Ownable(_owner){
        token = IERC20(_token);
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
    ///@param _agent the address of the agent
    ///@param _agreementId the ID of the agreement
    function withdraw(address _investor,address _agent, uint256 _agreementId) external {
        IPaymentProcess.Investment memory investment = paymentProcess.getInvestmentDetail(_investor, _agreementId);
        require(investment.canceled, "Agreement hasn't canceled yet");
        require(msg.sender == _agent, "Only agent can call this function");

        uint256 withdrawTokenAmount = tokenBalance[_agreementId];

        token.burnTokens(_investor, withdrawTokenAmount);

        emit TokenWithdrawn(_investor, _agreementId, withdrawTokenAmount);
    }

    ///@notice Functon to update the token address
    ///@param _newAddress the newTokenAddress
    function updateTokenAddress(address _newAddress) external onlyOwner {
        token = IERC20(_newAddress);
    }

    ///@notice Function to set the PaymentProcess Contract Address
    ///@param _paymentProcess the address of the PaymentProcess
    function setPaymentProcessAddress(address _paymentProcess) public onlyOwner{
        IPaymentProcess(_paymentProcess);
    }
}
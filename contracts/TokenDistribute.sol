// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./interfaces/IPaymentProcess.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";


contract TokenDistribute is Ownable{
    IPaymentProcess public paymentProcess;
    IERC20 public token;
    address agent;
    uint256 tokenPerEther;

    //event for token mint and distribute
    event TokenDistributed(address indexed _investor, uint256 _tokenAmount);

    constructor(address _paymentProcess, address _token, address _agent, uint256 _tokenPerEther) Ownable(msg.sender){
        paymentProcess = IPaymentProcess(_paymentProcess);
        token = IERC20(_token);
        agent = _agent;
        tokenPerEther = _tokenPerEther;
    }

    //Function to token mint and distribute
    function tokenDistribute(uint256 _agreementId) external onlyOwner {
        IPaymentProcess.Investment memory investment = paymentProcess.getInvestmentDetail(msg.sender, _agreementId);
        require(investment.isCompleted == true, "The Investment is not completed");

        uint256 etherAmount = investment.amount;
        uint256 tokenAmount = (etherAmount * tokenPerEther) / 1 ether;

        uint256 totalSupply = token.totalSupply();
        uint256 investorBalance = token.balanceOf(msg.sender);
        
        totalSupply += tokenAmount;
        investorBalance += tokenAmount;

        emit TokenDistributed(msg.sender, tokenAmount);
    }

    //Function to update the paymentProcess contract address
    function updatePaymentProcessAddress(address _newAddress) external onlyOwner {
        paymentProcess = IPaymentProcess(_newAddress);
    }

    //Functon to update the token address
    function updateTokenAddress(address _newAddress) external onlyOwner {
        token = IERC20(_newAddress);
    }

}
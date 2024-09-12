// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "./interfaces/IInvestorEscrow.sol";
import "./interfaces/ITokenDistribute.sol";

contract FundDistribution is Ownable,ReentrancyGuard {
   // Reference to the Investor Escrow contract
    IInvestorEscrow public escrowContract;
    // Reference to the Token Distribute contract
    ITokenDistribute public tokenDistribute;

    // Struct to represent a fund distribution
    struct FundDistributionDetail {
        address investor;
        uint256 amount;
        bool distributed;
    }

    // Mapping to store fund distributions for each investor
    mapping(address => FundDistributionDetail[]) public fundDistributions;

    // Events
    event FundDistributed(address indexed investor, uint256 amount);
    event FundDistributionUpdated(address indexed investor, uint256 amount);

    // Constructor to set the addresses of the contracts
    constructor() Ownable(msg.sender){
    }

    /// @notice Function to distribute funds to investors
    /// @param _investor The address of the investor
    /// @param _amount The amount to distribute
    function distributeFunds(address _investor,uint _agreementId, uint256 _amount) external onlyOwner nonReentrant {
        require(_amount > 0, "Amount must be greater than zero");
        require(escrowContract.checkApproval(_investor,_agreementId), "Investor not approved");

        // Create a new fund distribution entry
        fundDistributions[_investor].push(FundDistributionDetail({
            investor: _investor,
            amount: _amount,
            distributed: false
        }));

        // Transfer the funds to the investor
        (bool success,) = _investor.call{value: _amount}('');
        require(success, "Transfer failed");

        emit FundDistributed(_investor, _amount);
    }

    /// @notice Function to update fund distribution for an investor
    /// @param _investor The address of the investor
    /// @param _amount The new amount to distribute
    function updateFundDistribution(address _investor, uint256 _amount) external onlyOwner nonReentrant {
        require(fundDistributions[_investor].length > 0, "No distributions found for this investor");

        // Update the last distribution amount
        FundDistributionDetail storage lastDistribution = fundDistributions[_investor][fundDistributions[_investor].length - 1];
        lastDistribution.amount = _amount;

        emit FundDistributionUpdated(_investor, _amount);
    }

    /// @notice Function to get fund distribution details for an investor
    /// @param _investor The address of the investor
    /// @return details The fund distribution details
    function getFundDistributionDetails(address _investor) external view returns (FundDistributionDetail[] memory) {
        return fundDistributions[_investor];
    }

    /// @notice Function to set the addresses of the escrow and token distribute contracts
    /// @param _escrowContract The address of the new escrow contract
    /// @param _tokenDistribute The address of the new token distribute contract
    function setContractAddresses(address _escrowContract, address _tokenDistribute) external onlyOwner {
        escrowContract = IInvestorEscrow(_escrowContract);
        tokenDistribute = ITokenDistribute(_tokenDistribute);
    }

    // Fallback function to receive Ether
    receive() external payable {
        // Accept Ether for fund distribution
    }
}
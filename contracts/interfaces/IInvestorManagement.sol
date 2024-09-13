// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IInvestorManagement {
    struct InvestorDetail {
        address walletAddress;
        string name;
        bool KYCApproved;
        bool AMLApproved;
        uint256 lastInteractionTimestamp;
        uint256 totalInvestments;
    }

    // Function to get that investor is registered
    function isInvestorRegistered(address _investor) external view returns (bool);

    // Function to get the investor detail
    function getInvestorDetail(address _investor) external view returns (InvestorDetail memory);
}
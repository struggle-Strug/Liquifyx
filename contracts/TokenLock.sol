// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./interfaces/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "./interfaces/IInvestorManagement.sol";

contract TokenLock is Ownable {
    using Math for uint256;

    IERC20 public token;
    IInvestorManagement public investorManagement;
    struct Lock{
        uint256 amount;
        uint256 startTime;
        uint256 duration;
        bool released;
    }

    mapping(address => mapping(uint => Lock)) public locks;
    mapping(address => uint) public lockTimes;

    //events
    event TokensLocked(address indexed investor, uint256 amount, uint256 duration);
    event TokensReleased(address indexed investor, uint256 amount);

    constructor(address _token) Ownable(msg.sender) {
        token = IERC20(_token);
    }

    ///@notice Function to lock Tokens
    ///@param _investor The address of the investor
    ///@param _amount The Token amount
    ///@param _duration The lock duration
    function lockTokens(address _investor, uint256 _amount, uint256 _duration) external onlyOwner{
        require(investorManagement.isInvestorRegistered(_investor), "Investor not registered");
        require(_amount > 0, "The amount must be greater than 0");
        require(_duration > 0, "The duration must be greater than 0");
        token.transferTokensOnBehalf(_investor, address(this), _amount);

        uint256 times = lockTimes[_investor];
        locks[_investor][times + 1] = Lock({
            amount: _amount,
            startTime: block.timestamp,
            duration: _duration,
            released: false
        });

        emit TokensLocked(_investor, _amount, _duration);
    }

    ///@notice Function to release tokens
    ///@param _investor The address of the requested investor
    ///@param _time The locking Time of the investor
    function releaseToken(address _investor, uint256 _time) external onlyOwner{
        Lock storage lock = locks[_investor][_time];
        uint256 endTime = lock.startTime + lock.duration;
        require(lock.amount > 0, "No locked Tokens");
        require(endTime >= block.timestamp, "The releasing is not allowed");
        token.transferTokensOnBehalf(address(this), _investor, lock.amount);

        locks[_investor][_time].released = true;
        emit TokensReleased(_investor, locks[_investor][_time].amount);
    }

    ///@notice Function to get Lock Details
    ///@param _investor The address of the investor
    ///@param _time The locking time of the investor
    function getLockDetails(address _investor, uint _time) external view returns(uint256 amount, uint256 startTime, uint256 duration){
        Lock memory lock = locks[_investor][_time];
        return (lock.amount, lock.startTime, lock.duration);
    }

    ///@notice Function to set the InvestorManagement Contract Address
    ///@param _investorManagementAddress the address of the PaymentProcess
    function setInvestorManagementAddress(address _investorManagementAddress) public onlyOwner{
        IInvestorManagement(_investorManagementAddress);
    }
}
const { loadFixture } = require("@nomicfoundation/hardhat-toolbox/network-helpers"); 
const { expect } = require("chai");
const { ethers } = require("hardhat");


describe("test InvestorEscrow Contract", function() {
    let buyer;
    let agent;
    let seller;
    let owner;
    let add1;
    let add2;
    let investorEscrow;
    let paymentProcess;
    let tokenDistribute;
    let investorManagement;
    let investorEscrowAddress;
    let paymentProcessAddress;
    let tokenDistributeAddress;
    let investorManagementAddress;
   beforeEach (async function() {
        [owner, add1, add2, buyer, seller, agent] = await ethers.getSigners();
        //--------------InvestorEscrow-----------------//
        const InvestorEscrow =await ethers.getContractFactory("InvestorEscrow");
        investorEscrow = await InvestorEscrow.deploy();

        await investorEscrow.waitForDeployment();
        //---------------PaymentProcess-----------------//
        const PaymentProcess = await ethers.getContractFactory("PaymentProcess");
        paymentProcess = await PaymentProcess.deploy();

        await paymentProcess.waitForDeployment();
        //---------------TokenDistribute----------------//
        const tokenAddress = "0x48c1Bf095AF51fc89971Aca490Fb4AA49c687167";
        const tokenPerEther = 10000000000;

        const TokenDistribute = await ethers.getContractFactory("TokenDistribute");
        tokenDistribute = await TokenDistribute.deploy(tokenAddress,tokenPerEther,owner);

        await tokenDistribute.waitForDeployment();
        //----------------InvestorManagement------------//
        const InvestorManagement = await ethers.getContractFactory("InvestorManagement");
        investorManagement = await InvestorManagement.deploy(agent);

        await investorManagement.waitForDeployment();
        //Addresses
        investorEscrowAddress = await investorEscrow.getAddress();
        paymentProcessAddress = await paymentProcess.getAddress();
        tokenDistributeAddress = await tokenDistribute.getAddress();
        investorManagementAddress = await investorManagement.getAddress();
    })

    describe("Functions Test", function () {
        it("CreateAgreement and deposit", async function(){
            await investorEscrow.connect(buyer).createAgreement(seller, agent);
            const agreement = await investorEscrow.agreements(0)
            expect(agreement.buyer).to.equal(buyer);

            const depositAmount = ethers.parseEther("10");
            await investorEscrow.connect(buyer).deposit(0, {value: depositAmount});
            console.log("----------------",agreement);
            
            expect(agreement.amount).to.equal(depositAmount);
        })
    })
})
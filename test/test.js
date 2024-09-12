const { loadFixture } = require("@nomicfoundation/hardhat-toolbox/network-helpers"); 
const { expect } = require("chai");
const { ethers } = require("hardhat");


describe("test Contracts", function() {
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

    describe("InvestorEscrow", function () {
        it("CreateAgreement,deposit,approve,requestCancel,requestComplete,AgentCancel,AgentComplete,checkAndHandleExpiration,raiseDispute,resolveDispute", async function(){           
            //------------------createAgreement-------------------------//
            await investorEscrow.connect(buyer).createAgreement(seller, agent);
            const agreement = await investorEscrow.agreements(0)
            expect(agreement.buyer).to.equal(buyer);
            expect(agreement.contractStatus).to.equal(0);
            //------------------deposit-------------------------//
            const depositAmount = ethers.parseEther("10");
            await investorEscrow.connect(buyer).deposit(0, {value: depositAmount});
            const agreementAfterDeposit = await investorEscrow.agreements(0);
            expect(agreementAfterDeposit.amount).to.equal(depositAmount);
            expect(agreementAfterDeposit.contractStatus).to.equal(1);
            //------------------approve-------------------------//
            await investorEscrow.connect(buyer).approve(0,100000);
            const agreementAfterApprovedBuyer = await investorEscrow.agreements(0);
            expect(agreementAfterApprovedBuyer.contractStatus).to.equal(1);
            await investorEscrow.connect(seller).approve(0,100000);
            const agreementAfterApprovedBoth= await investorEscrow.agreements(0);
            expect(agreementAfterApprovedBoth.contractStatus).to.equal(2);
            //------------------requestCancel-------------------------//
            await investorEscrow.connect(buyer).requestCancel(0);
            const agreementRequestCancel= await investorEscrow.agreements(0);
            expect(agreementRequestCancel.buyerRequestedCancel).to.equal(true);
            await investorEscrow.connect(buyer).createAgreement(seller, agent);
            await investorEscrow.connect(buyer).deposit(1, {value: depositAmount});
            await investorEscrow.connect(buyer).approve(1,0);
            await investorEscrow.connect(seller).approve(1,0);
            await expect(investorEscrow.connect(buyer).requestCancel(1)).to.be.revertedWith("Agreement have already Expired");
            //-------------------requestComplete----------------------//
            await investorEscrow.connect(buyer).requestComplete(0);
            await investorEscrow.connect(seller).requestComplete(0);
            const agreementComplete_buyer = await investorEscrow.agreements(0);
            expect(agreementComplete_buyer.buyerRequestedComplete && agreementComplete_buyer.sellerRequestedComplete).to.equal(true);
            //-------------------agentCancel--------------------------//
            // await investorEscrow.connect(agent).agentCancel(0);
            // const agreementAgentCancel = await investorEscrow.agreements(0);
            // expect(agreementAgentCancel.amount).to.equal(0);
        })

    })
})
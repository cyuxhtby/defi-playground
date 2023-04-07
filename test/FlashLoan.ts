const { describe } = require('mocha');
import '@nomiclabs/hardhat-ethers'
import {ethers} from 'hardhat';
const { expect } = require('chai');
import { FlashLoan } from '../typechain-types/contracts/Flashloan.sol';
import { BigNumber } from 'ethers';


describe('FlashLoan', function () {
  let flashLoan: FlashLoan;

  beforeEach(async () => {
    const FlashLoan = await ethers.getContractFactory('FlashLoan');
    const provider = new ethers.providers.JsonRpcProvider();
    const addressProvider = '<address provider address goes here>'; // replace with actual address
    const owner = (await provider.listAccounts())[0];
    flashLoan = await FlashLoan.deploy(addressProvider);
    await flashLoan.deployed();
    await flashLoan.deployTransaction.wait();
  });

  it('should return the correct balance', async function () {
    const daiTokenAddress = '<Dai token address goes here>'; // replace with actual address
    const balance = await flashLoan.getBalance(daiTokenAddress);
    expect(BigNumber.isBigNumber(balance)).to.be.true;
  });
});

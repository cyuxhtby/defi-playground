// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {IACLManager} from '@aave/core-v3/contracts/interfaces/IACLManager.sol';
import {IPoolAddressesProvider} from '@aave/core-v3/contracts/interfaces/IPoolAddressesProvider.sol';
import {PercentageMath} from '@aave/core-v3/contracts/protocol/libraries/math/PercentageMath.sol';
import {IERC3156FlashBorrower} from '@openzeppelin/contracts/interfaces/IERC3156FlashBorrower.sol';
import {IERC3156FlashLender} from '@openzeppelin/contracts/interfaces/IERC3156FlashLender.sol';
import {IGhoToken} from './interfaces/IGhoToken.sol';
import {IGhoFacilitator} from './interfaces/IGhoFacilitator.sol';
import {IGhoFlashMinter} from './interfaces/IGhoFlashMinter.sol';

// This contract is designed to handle gho flashmint requests and manage the lending and repayment of funds, 
// A version of this contract has already been deployed by Aave and will be used by our FlashMint contract

contract GhoFlashMinter is IGhoFlashMinter {
    // integer values will represent basis points (a value of 10000 results in 100.00%)
    using PercentageMath for uint256;

    // a successful flashloan will return the hash of 'ERC3156FlashBorrower.onFlashLoan' 
    bytes32 public constant CALLBACK_SUCCESS = keccak256('ERC3156FlashBorrower.onFlashLoan');

    // the fee is set via governance but cant be more that 100% (1e4 = 10000 = 100%)
    uint256 public constant MAX_FEE = 1e4;

    // IPoolAddressesProvider contract provides the addresses of various other contracts in the Aave protocol
    // By passing in addressesProvider to the constructor we are essentially specifying what chain and set of contracts to use
    IPoolAddressesProvider public immutable override ADDRESSES_PROVIDER;

    IGhoToken public immutable GHO_TOKEN;

    // Access Control List Manager, aave's registry of system roles and privileges
    IACLManager private immutable ACL_MANAGER;

    // flashmint fee
    uint256 private _fee;

    // recipent of fee
    address private _ghoTreasury;

    modifier onlyPoolAdmin() {
        require(ACL_MANAGER.isPoolAdmin(msg.sender), "CALLER_NOT_POOL_ADMIN");
        _;
    }

    /**
   * @dev Constructor
   * @param ghoToken The address of the GHO token contract
   * @param ghoTreasury The address of the GHO treasury
   * @param fee The percentage of the flash-mint amount that needs to be repaid, on top of the principal (in bps)
   * @param addressesProvider The address of the Aave PoolAddressesProvider
   */
    constructor(address ghoToken, address ghoTreasury, uint256 fee, address addressesProvider) {
        require(fee <= MAX_FEE, 'FlashMinter: Fee out of range');
        GHO_TOKEN = IGhoToken(ghoToken);
        _updateGhoTreasury(ghoTreasury);
        _updateFee(fee);
        ADDRESSES_PROVIDER = IPoolAddressesProvider(addressesProvider);
        ACL_MANAGER = IACLManager(IPoolAddressesProvider(addressesProvider).getACLManager());
    }

    function flashLoan(
    IERC3156FlashBorrower receiver,
    address token,
    uint256 amount,
    bytes calldata data
    ) external override returns (bool){
        require(token == address(GHO_TOKEN), 'FlashMinter: Unsupported currency'); // Aave flashmints only support GHO
        uint256 fee = ACL_MANAGER.isFlashBorrower(msg.sender) ? 0 : _flashFee(amount); // calculates the fee for the flash loan, unless the borrower is whitelisted for a fee waiver
        GHO_TOKEN.mint(address(receiver), amount);

        // make sure our flashloan returns a success
        require(
            receiver.onFlashLoan(msg.sender, address(GHO_TOKEN), amount, fee, data) == CALLBACK_SUCCESS, 'FlashMint: Callback failed'
        );

        // the repayment of the flashloan plus the calculated fee 
        GHO_TOKEN.transferFrom(address(receiver), address(this), amount + fee);
        // burn minted GHO after flashloan, essential for the health of peg
        GHO_TOKEN.burn(amount);
        emit FlashMint(address(receiver), msg.sender, address(GHO_TOKEN), amount, fee);
        return true;
    }
    
    // the generated fees remain in this contract untill they are ready to be transfered
    function distributeFeesToTreasury() external override {
        uint256 balance = GHO_TOKEN.balanceOf(address(this));
        GHO_TOKEN.transfer(_ghoTreasury, balance);
        emit FeesDistributedToTreasury(_ghoTreasury, address(GHO_TOKEN), balance);
    }

    function updateFee(uint256 newFee) external override onlyPoolAdmin {
    _updateFee(newFee);
    }

    function updateGhoTreasury(address newGhoTreasury) external override onlyPoolAdmin {
        _updateGhoTreasury(newGhoTreasury);
    }

    // determine how much GHO can be minted based on facilitator bucket
    function maxFlashLoan(address token) external view override returns (uint256) {
        if(token != address(GHO_TOKEN)){
            return 0;
        } else {
            (uint256 capacity, uint256 level) = GHO_TOKEN.getFacilitatorBucket(address(this));
            return capacity > level ? capacity - level : 0;
        }
    }

    function flashFee(address token, uint256 amount) external view override returns (uint256) {
        require(token == address(GHO_TOKEN), 'FlashMinter: Unsupported currency');
        return ACL_MANAGER.isFlashBorrower(msg.sender) ? 0 : _flashFee(amount);
    } 

    function getFee() external view override returns (uint256) {
        return _fee;
    }

    function getGhoTreasury() external view override returns (address) {
        return _ghoTreasury;
    }

    function _flashFee(uint256 amount) internal view returns (uint256){
        // amount: amount of the flashloan for which the fee is being calculated
        // percentMul: multiplies amount by _fee and divides by 10000
        return amount.percentMul(_fee);
    }

    function _updateFee(uint256 newFee) internal {
        require(newFee <= MAX_FEE, 'FlashMinter: fee out of range');
        uint256 oldFee = _fee;
        _fee = newFee;
        emit FeeUpdated(oldFee, newFee);
    }

    function _updateGhoTreasury(address newGhoTreasury) internal {
        address oldGhoTreasury = _ghoTreasury;
        _ghoTreasury = newGhoTreasury;
        emit GhoTreasuryUpdated(oldGhoTreasury, newGhoTreasury);
    }

}
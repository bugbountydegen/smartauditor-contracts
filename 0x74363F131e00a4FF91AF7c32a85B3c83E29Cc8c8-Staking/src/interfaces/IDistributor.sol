// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {IStaking} from 'interfaces/IStaking.sol';
import {IERC20} from 'openzeppelin/token/ERC20/IERC20.sol';

/**
 * @title Distributor Contract
 * @author Wonderland (https://defi.sucks)
 * @notice Distributes tokens to users based on a merkle root and a signature
 */
interface IDistributor {
  /*///////////////////////////////////////////////////////////////
                            EVENTS
  ///////////////////////////////////////////////////////////////*/

  /**
   * @notice Emitted when a user claims their tokens
   * @param _account The account that claimed the tokens
   * @param _amount The amount of tokens claimed
   */
  event Claimed(address indexed _account, uint256 _amount);

  /**
   * @notice Emitted when a user claims and stakes their tokens
   * @param _account The account that claimed and staked the tokens
   * @param _amount The amount of tokens claimed and staked
   * @param _lockupPeriod The lockup period for the deposit
   * @param _timestamp The timestamp at which the tokens were claimed and staked
   */
  event ClaimedAndStaked(address indexed _account, uint256 _amount, uint256 _lockupPeriod, uint256 _timestamp);

  /**
   * @notice Emitted when the owner withdraws tokens from the contract
   * @param _owner The owner that withdrew the tokens
   * @param _amount The amount of tokens withdrawn
   */
  event EmergencyWithdrawn(address indexed _owner, uint256 _amount);

  /**
   * @notice Emitted when the signer is updated by the owner
   * @param _oldSigner The old signer address
   * @param _newSigner The new signer address
   */
  event SignerUpdated(address indexed _oldSigner, address indexed _newSigner);

  /**
   * @notice Emitted when the owner collects dust tokens from the contract
   * @param _owner The owner that collected the dust tokens
   * @param _token The token address
   * @param _amount The amount of tokens collected
   */
  event DustCollected(address indexed _owner, IERC20 indexed _token, uint256 _amount);

  /*///////////////////////////////////////////////////////////////
                            ERRORS
  ///////////////////////////////////////////////////////////////*/

  /**
   * @notice Throws if the input amount is zero
   */
  error ZeroAmount();

  /**
   * @notice Throws if the user has already claimed their tokens
   */
  error AlreadyClaimed();

  /**
   * @notice Throws if the recovered signer is different from the expected signer
   */
  error InvalidSigner();

  /**
   * @notice Throws if the merkle verification fails
   */
  error InvalidProof();

  /**
   * @notice Throws if the new signer address is invalid
   */
  error InvalidNewSigner();

  /**
   * @notice Throws if the input token is invalid
   */
  error InvalidToken();

  /*///////////////////////////////////////////////////////////////
                            LOGIC
  ///////////////////////////////////////////////////////////////*/

  /**
   * @notice Verifies eligibility and transfers the tokens to the caller
   * @param _amount The amount of tokens to claim
   * @param _merkleProof The merkle proof of the claim
   * @param _signature The signature provided by the UI
   */
  function claim(uint256 _amount, bytes32[] calldata _merkleProof, bytes calldata _signature) external;

  /**
   * @notice Verifies eligibility and stakes the claimed tokens in the contract
   * @param _amount The amount of tokens to claim
   * @param _merkleProof The merkle proof for the claim
   * @param _signature The signature for verification of the claim data
   * @param _lockupPeriod The period of time to lock the tokens for
   */
  function claimAndStake(
    uint256 _amount,
    bytes32[] calldata _merkleProof,
    bytes calldata _signature,
    uint32 _lockupPeriod
  ) external;

  /**
   * @notice Sends any remaining tokens to the owner
   * @dev Only callable by the owner
   * @dev If the specified amount exceeds the available balance, the entire balance is withdrawn
   * @param _amount The amount of tokens to withdraw
   */
  function emergencyWithdraw(uint256 _amount) external;

  /**
   * @notice Updates the signer address
   * @dev Only callable by the owner
   * @param _newSigner The new signer address
   */
  function updateSigner(address _newSigner) external;

  /**
   * @notice Collects dust tokens from the contract
   * @dev Only the owner can call this function
   * @param _token The token to collect
   * @param _amount The amount of tokens to collect
   */
  function collectDust(IERC20 _token, uint256 _amount) external;

  /*///////////////////////////////////////////////////////////////
                            VARIABLES
  ///////////////////////////////////////////////////////////////*/

  /**
   * @notice The root of the merkle tree
   * @return _merkleRoot The root of the merkle tree
   */
  // solhint-disable-next-line func-name-mixedcase
  function MERKLE_ROOT() external view returns (bytes32 _merkleRoot);

  /**
   * @notice The token being distributed
   * @return _token The address of the token
   */
  // solhint-disable-next-line func-name-mixedcase
  function TOKEN() external view returns (IERC20 _token);

  /**
   * @notice The address of the staking contract
   * @return _staking The staking contract
   */
  // solhint-disable-next-line func-name-mixedcase
  function STAKING() external view returns (IStaking _staking);

  /**
   * @notice The address of the signer
   * @return _signer The address of the signer
   */
  function signer() external view returns (address _signer);

  /**
   * @notice Returns whether the user has claimed their tokens
   * @param _user The address of the user
   * @return _claimed Whether the user has claimed their tokens
   */
  function hasClaimed(address _user) external view returns (bool _claimed);
}

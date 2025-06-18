// File: @chainlink/contracts/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol


pragma solidity ^0.8.4;

// End consumer library.
library VRFV2PlusClient {
  // extraArgs will evolve to support new features
  bytes4 public constant EXTRA_ARGS_V1_TAG = bytes4(keccak256("VRF ExtraArgsV1"));
  struct ExtraArgsV1 {
    bool nativePayment;
  }

  struct RandomWordsRequest {
    bytes32 keyHash;
    uint256 subId;
    uint16 requestConfirmations;
    uint32 callbackGasLimit;
    uint32 numWords;
    bytes extraArgs;
  }

  function _argsToBytes(ExtraArgsV1 memory extraArgs) internal pure returns (bytes memory bts) {
    return abi.encodeWithSelector(EXTRA_ARGS_V1_TAG, extraArgs);
  }
}

// File: @chainlink/contracts/src/v0.8/vrf/dev/interfaces/IVRFSubscriptionV2Plus.sol


pragma solidity ^0.8.0;

/// @notice The IVRFSubscriptionV2Plus interface defines the subscription
/// @notice related methods implemented by the V2Plus coordinator.
interface IVRFSubscriptionV2Plus {
  /**
   * @notice Add a consumer to a VRF subscription.
   * @param subId - ID of the subscription
   * @param consumer - New consumer which can use the subscription
   */
  function addConsumer(uint256 subId, address consumer) external;

  /**
   * @notice Remove a consumer from a VRF subscription.
   * @param subId - ID of the subscription
   * @param consumer - Consumer to remove from the subscription
   */
  function removeConsumer(uint256 subId, address consumer) external;

  /**
   * @notice Cancel a subscription
   * @param subId - ID of the subscription
   * @param to - Where to send the remaining LINK to
   */
  function cancelSubscription(uint256 subId, address to) external;

  /**
   * @notice Accept subscription owner transfer.
   * @param subId - ID of the subscription
   * @dev will revert if original owner of subId has
   * not requested that msg.sender become the new owner.
   */
  function acceptSubscriptionOwnerTransfer(uint256 subId) external;

  /**
   * @notice Request subscription owner transfer.
   * @param subId - ID of the subscription
   * @param newOwner - proposed new owner of the subscription
   */
  function requestSubscriptionOwnerTransfer(uint256 subId, address newOwner) external;

  /**
   * @notice Create a VRF subscription.
   * @return subId - A unique subscription id.
   * @dev You can manage the consumer set dynamically with addConsumer/removeConsumer.
   * @dev Note to fund the subscription with LINK, use transferAndCall. For example
   * @dev  LINKTOKEN.transferAndCall(
   * @dev    address(COORDINATOR),
   * @dev    amount,
   * @dev    abi.encode(subId));
   * @dev Note to fund the subscription with Native, use fundSubscriptionWithNative. Be sure
   * @dev  to send Native with the call, for example:
   * @dev COORDINATOR.fundSubscriptionWithNative{value: amount}(subId);
   */
  function createSubscription() external returns (uint256 subId);

  /**
   * @notice Get a VRF subscription.
   * @param subId - ID of the subscription
   * @return balance - LINK balance of the subscription in juels.
   * @return nativeBalance - native balance of the subscription in wei.
   * @return reqCount - Requests count of subscription.
   * @return owner - owner of the subscription.
   * @return consumers - list of consumer address which are able to use this subscription.
   */
  function getSubscription(
    uint256 subId
  )
    external
    view
    returns (uint96 balance, uint96 nativeBalance, uint64 reqCount, address owner, address[] memory consumers);

  /*
   * @notice Check to see if there exists a request commitment consumers
   * for all consumers and keyhashes for a given sub.
   * @param subId - ID of the subscription
   * @return true if there exists at least one unfulfilled request for the subscription, false
   * otherwise.
   */
  function pendingRequestExists(uint256 subId) external view returns (bool);

  /**
   * @notice Paginate through all active VRF subscriptions.
   * @param startIndex index of the subscription to start from
   * @param maxCount maximum number of subscriptions to return, 0 to return all
   * @dev the order of IDs in the list is **not guaranteed**, therefore, if making successive calls, one
   * @dev should consider keeping the blockheight constant to ensure a holistic picture of the contract state
   */
  function getActiveSubscriptionIds(uint256 startIndex, uint256 maxCount) external view returns (uint256[] memory);

  /**
   * @notice Fund a subscription with native.
   * @param subId - ID of the subscription
   * @notice This method expects msg.value to be greater than or equal to 0.
   */
  function fundSubscriptionWithNative(uint256 subId) external payable;
}

// File: @chainlink/contracts/src/v0.8/vrf/dev/interfaces/IVRFCoordinatorV2Plus.sol


pragma solidity ^0.8.0;



// Interface that enables consumers of VRFCoordinatorV2Plus to be future-proof for upgrades
// This interface is supported by subsequent versions of VRFCoordinatorV2Plus
interface IVRFCoordinatorV2Plus is IVRFSubscriptionV2Plus {
  /**
   * @notice Request a set of random words.
   * @param req - a struct containing following fields for randomness request:
   * keyHash - Corresponds to a particular oracle job which uses
   * that key for generating the VRF proof. Different keyHash's have different gas price
   * ceilings, so you can select a specific one to bound your maximum per request cost.
   * subId  - The ID of the VRF subscription. Must be funded
   * with the minimum subscription balance required for the selected keyHash.
   * requestConfirmations - How many blocks you'd like the
   * oracle to wait before responding to the request. See SECURITY CONSIDERATIONS
   * for why you may want to request more. The acceptable range is
   * [minimumRequestBlockConfirmations, 200].
   * callbackGasLimit - How much gas you'd like to receive in your
   * fulfillRandomWords callback. Note that gasleft() inside fulfillRandomWords
   * may be slightly less than this amount because of gas used calling the function
   * (argument decoding etc.), so you may need to request slightly more than you expect
   * to have inside fulfillRandomWords. The acceptable range is
   * [0, maxGasLimit]
   * numWords - The number of uint256 random values you'd like to receive
   * in your fulfillRandomWords callback. Note these numbers are expanded in a
   * secure way by the VRFCoordinator from a single random value supplied by the oracle.
   * extraArgs - abi-encoded extra args
   * @return requestId - A unique identifier of the request. Can be used to match
   * a request to a response in fulfillRandomWords.
   */
  function requestRandomWords(VRFV2PlusClient.RandomWordsRequest calldata req) external returns (uint256 requestId);
}

// File: @chainlink/contracts/src/v0.8/vrf/dev/interfaces/IVRFMigratableConsumerV2Plus.sol


pragma solidity ^0.8.0;

/// @notice The IVRFMigratableConsumerV2Plus interface defines the
/// @notice method required to be implemented by all V2Plus consumers.
/// @dev This interface is designed to be used in VRFConsumerBaseV2Plus.
interface IVRFMigratableConsumerV2Plus {
  event CoordinatorSet(address vrfCoordinator);

  /// @notice Sets the VRF Coordinator address
  /// @notice This method should only be callable by the coordinator or contract owner
  function setCoordinator(address vrfCoordinator) external;
}

// File: @chainlink/contracts/src/v0.8/shared/interfaces/IOwnable.sol


pragma solidity ^0.8.0;

interface IOwnable {
  function owner() external returns (address);

  function transferOwnership(address recipient) external;

  function acceptOwnership() external;
}

// File: @chainlink/contracts/src/v0.8/shared/access/ConfirmedOwnerWithProposal.sol


pragma solidity ^0.8.0;


/// @title The ConfirmedOwner contract
/// @notice A contract with helpers for basic contract ownership.
contract ConfirmedOwnerWithProposal is IOwnable {
  address private s_owner;
  address private s_pendingOwner;

  event OwnershipTransferRequested(address indexed from, address indexed to);
  event OwnershipTransferred(address indexed from, address indexed to);

  constructor(address newOwner, address pendingOwner) {
    // solhint-disable-next-line gas-custom-errors
    require(newOwner != address(0), "Cannot set owner to zero");

    s_owner = newOwner;
    if (pendingOwner != address(0)) {
      _transferOwnership(pendingOwner);
    }
  }

  /// @notice Allows an owner to begin transferring ownership to a new address.
  function transferOwnership(address to) public override onlyOwner {
    _transferOwnership(to);
  }

  /// @notice Allows an ownership transfer to be completed by the recipient.
  function acceptOwnership() external override {
    // solhint-disable-next-line gas-custom-errors
    require(msg.sender == s_pendingOwner, "Must be proposed owner");

    address oldOwner = s_owner;
    s_owner = msg.sender;
    s_pendingOwner = address(0);

    emit OwnershipTransferred(oldOwner, msg.sender);
  }

  /// @notice Get the current owner
  function owner() public view override returns (address) {
    return s_owner;
  }

  /// @notice validate, transfer ownership, and emit relevant events
  function _transferOwnership(address to) private {
    // solhint-disable-next-line gas-custom-errors
    require(to != msg.sender, "Cannot transfer to self");

    s_pendingOwner = to;

    emit OwnershipTransferRequested(s_owner, to);
  }

  /// @notice validate access
  function _validateOwnership() internal view {
    // solhint-disable-next-line gas-custom-errors
    require(msg.sender == s_owner, "Only callable by owner");
  }

  /// @notice Reverts if called by anyone other than the contract owner.
  modifier onlyOwner() {
    _validateOwnership();
    _;
  }
}

// File: @chainlink/contracts/src/v0.8/shared/access/ConfirmedOwner.sol


pragma solidity ^0.8.0;


/// @title The ConfirmedOwner contract
/// @notice A contract with helpers for basic contract ownership.
contract ConfirmedOwner is ConfirmedOwnerWithProposal {
  constructor(address newOwner) ConfirmedOwnerWithProposal(newOwner, address(0)) {}
}

// File: @chainlink/contracts/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol


pragma solidity ^0.8.4;




/** ****************************************************************************
 * @notice Interface for contracts using VRF randomness
 * *****************************************************************************
 * @dev PURPOSE
 *
 * @dev Reggie the Random Oracle (not his real job) wants to provide randomness
 * @dev to Vera the verifier in such a way that Vera can be sure he's not
 * @dev making his output up to suit himself. Reggie provides Vera a public key
 * @dev to which he knows the secret key. Each time Vera provides a seed to
 * @dev Reggie, he gives back a value which is computed completely
 * @dev deterministically from the seed and the secret key.
 *
 * @dev Reggie provides a proof by which Vera can verify that the output was
 * @dev correctly computed once Reggie tells it to her, but without that proof,
 * @dev the output is indistinguishable to her from a uniform random sample
 * @dev from the output space.
 *
 * @dev The purpose of this contract is to make it easy for unrelated contracts
 * @dev to talk to Vera the verifier about the work Reggie is doing, to provide
 * @dev simple access to a verifiable source of randomness. It ensures 2 things:
 * @dev 1. The fulfillment came from the VRFCoordinatorV2Plus.
 * @dev 2. The consumer contract implements fulfillRandomWords.
 * *****************************************************************************
 * @dev USAGE
 *
 * @dev Calling contracts must inherit from VRFConsumerBaseV2Plus, and can
 * @dev initialize VRFConsumerBaseV2Plus's attributes in their constructor as
 * @dev shown:
 *
 * @dev   contract VRFConsumerV2Plus is VRFConsumerBaseV2Plus {
 * @dev     constructor(<other arguments>, address _vrfCoordinator, address _subOwner)
 * @dev       VRFConsumerBaseV2Plus(_vrfCoordinator, _subOwner) public {
 * @dev         <initialization with other arguments goes here>
 * @dev       }
 * @dev   }
 *
 * @dev The oracle will have given you an ID for the VRF keypair they have
 * @dev committed to (let's call it keyHash). Create a subscription, fund it
 * @dev and your consumer contract as a consumer of it (see VRFCoordinatorInterface
 * @dev subscription management functions).
 * @dev Call requestRandomWords(keyHash, subId, minimumRequestConfirmations,
 * @dev callbackGasLimit, numWords, extraArgs),
 * @dev see (IVRFCoordinatorV2Plus for a description of the arguments).
 *
 * @dev Once the VRFCoordinatorV2Plus has received and validated the oracle's response
 * @dev to your request, it will call your contract's fulfillRandomWords method.
 *
 * @dev The randomness argument to fulfillRandomWords is a set of random words
 * @dev generated from your requestId and the blockHash of the request.
 *
 * @dev If your contract could have concurrent requests open, you can use the
 * @dev requestId returned from requestRandomWords to track which response is associated
 * @dev with which randomness request.
 * @dev See "SECURITY CONSIDERATIONS" for principles to keep in mind,
 * @dev if your contract could have multiple requests in flight simultaneously.
 *
 * @dev Colliding `requestId`s are cryptographically impossible as long as seeds
 * @dev differ.
 *
 * *****************************************************************************
 * @dev SECURITY CONSIDERATIONS
 *
 * @dev A method with the ability to call your fulfillRandomness method directly
 * @dev could spoof a VRF response with any random value, so it's critical that
 * @dev it cannot be directly called by anything other than this base contract
 * @dev (specifically, by the VRFConsumerBaseV2Plus.rawFulfillRandomness method).
 *
 * @dev For your users to trust that your contract's random behavior is free
 * @dev from malicious interference, it's best if you can write it so that all
 * @dev behaviors implied by a VRF response are executed *during* your
 * @dev fulfillRandomness method. If your contract must store the response (or
 * @dev anything derived from it) and use it later, you must ensure that any
 * @dev user-significant behavior which depends on that stored value cannot be
 * @dev manipulated by a subsequent VRF request.
 *
 * @dev Similarly, both miners and the VRF oracle itself have some influence
 * @dev over the order in which VRF responses appear on the blockchain, so if
 * @dev your contract could have multiple VRF requests in flight simultaneously,
 * @dev you must ensure that the order in which the VRF responses arrive cannot
 * @dev be used to manipulate your contract's user-significant behavior.
 *
 * @dev Since the block hash of the block which contains the requestRandomness
 * @dev call is mixed into the input to the VRF *last*, a sufficiently powerful
 * @dev miner could, in principle, fork the blockchain to evict the block
 * @dev containing the request, forcing the request to be included in a
 * @dev different block with a different hash, and therefore a different input
 * @dev to the VRF. However, such an attack would incur a substantial economic
 * @dev cost. This cost scales with the number of blocks the VRF oracle waits
 * @dev until it calls responds to a request. It is for this reason that
 * @dev that you can signal to an oracle you'd like them to wait longer before
 * @dev responding to the request (however this is not enforced in the contract
 * @dev and so remains effective only in the case of unmodified oracle software).
 */
abstract contract VRFConsumerBaseV2Plus is IVRFMigratableConsumerV2Plus, ConfirmedOwner {
  error OnlyCoordinatorCanFulfill(address have, address want);
  error OnlyOwnerOrCoordinator(address have, address owner, address coordinator);
  error ZeroAddress();

  // s_vrfCoordinator should be used by consumers to make requests to vrfCoordinator
  // so that coordinator reference is updated after migration
  IVRFCoordinatorV2Plus public s_vrfCoordinator;

  /**
   * @param _vrfCoordinator address of VRFCoordinator contract
   */
  constructor(address _vrfCoordinator) ConfirmedOwner(msg.sender) {
    if (_vrfCoordinator == address(0)) {
      revert ZeroAddress();
    }
    s_vrfCoordinator = IVRFCoordinatorV2Plus(_vrfCoordinator);
  }

  /**
   * @notice fulfillRandomness handles the VRF response. Your contract must
   * @notice implement it. See "SECURITY CONSIDERATIONS" above for important
   * @notice principles to keep in mind when implementing your fulfillRandomness
   * @notice method.
   *
   * @dev VRFConsumerBaseV2Plus expects its subcontracts to have a method with this
   * @dev signature, and will call it once it has verified the proof
   * @dev associated with the randomness. (It is triggered via a call to
   * @dev rawFulfillRandomness, below.)
   *
   * @param requestId The Id initially returned by requestRandomness
   * @param randomWords the VRF output expanded to the requested number of words
   */
  // solhint-disable-next-line chainlink-solidity/prefix-internal-functions-with-underscore
  function fulfillRandomWords(uint256 requestId, uint256[] calldata randomWords) internal virtual;

  // rawFulfillRandomness is called by VRFCoordinator when it receives a valid VRF
  // proof. rawFulfillRandomness then calls fulfillRandomness, after validating
  // the origin of the call
  function rawFulfillRandomWords(uint256 requestId, uint256[] calldata randomWords) external {
    if (msg.sender != address(s_vrfCoordinator)) {
      revert OnlyCoordinatorCanFulfill(msg.sender, address(s_vrfCoordinator));
    }
    fulfillRandomWords(requestId, randomWords);
  }

  /**
   * @inheritdoc IVRFMigratableConsumerV2Plus
   */
  function setCoordinator(address _vrfCoordinator) external override onlyOwnerOrCoordinator {
    if (_vrfCoordinator == address(0)) {
      revert ZeroAddress();
    }
    s_vrfCoordinator = IVRFCoordinatorV2Plus(_vrfCoordinator);

    emit CoordinatorSet(_vrfCoordinator);
  }

  modifier onlyOwnerOrCoordinator() {
    if (msg.sender != owner() && msg.sender != address(s_vrfCoordinator)) {
      revert OnlyOwnerOrCoordinator(msg.sender, owner(), address(s_vrfCoordinator));
    }
    _;
  }
}

// File: tests/randomNumber.sol


pragma solidity ^0.8.19;



contract RandomNumber is VRFConsumerBaseV2Plus {
    error RandomNumber__RequestNotFound(uint256 requestId);
    error RandomNumber__RequestAlreadyFulfilled(uint256 requestId);
    error RandomNumber__RequestPending(uint256 requestId);
    error RandomNumber__InvalidCoordinator(address coordinator);
    error RandomNumber__InvalidSubscriptionId(uint64 subId);
    error RandomNumber__InvalidCallbackGasLimit(uint32 gasLimit);
    error RandomNumber__ZeroAddress();
    error RandomNumber__NotWhitelisted(address caller);
    error RandomNumber__PeriodNoNotFound(string periodNo); 
    error RandomNumber__PeriodNoAlreadyExists(string periodNo); 

    struct RandomRequest {
        uint96 roundId;           // 减小到 uint96 节省 gas
        uint256[] randomNumbers;  // 存储随机数数组
        // 使用范围表示连续期号
        string basePrefix;        // 基础前缀（如 "PERIOD-"）
        uint64 startIndex;        // 连续序列的起始索引
        uint64 endIndex;          // 连续序列的结束索引
        string[] extraPeriodNos;  // 存储额外的非连续期号
    }

    // 新增结构体用于表示期号范围或单个期号
    struct PeriodRange {
        string basePrefix;     // 期号前缀
        uint64 startIndex;     // 起始索引
        uint64 endIndex;       // 结束索引
    }

    address immutable vrfCoordinator = 0x5FE58960F730153eb5A84a47C51BD4E58302E1c8; 
    bytes32 immutable s_keyHash = 0x8e7a847ba0757d1c302a3f0fde7b868ef8cf4acc32e48505f1a1d53693a10a19; 

    uint64 public s_subscriptionId; // 使用 uint64 匹配 VRF 类型

    mapping(uint256 => RandomRequest) private s_randomRequests;
    mapping(string => uint256) private s_periodNoToRequestId; // 通过期号查找 requestId
    mapping(address => bool) private s_whitelist;
    uint96 private s_currentRound;

    event RequestedRandomness(
        uint256 indexed requestId,
        uint96 indexed roundId
    );

    event RandomnessFulfilled(
        uint256 indexed requestId,
        uint96 indexed roundId,
        uint256[] randomNumbers
    );

    event WhitelistUpdated(address indexed account, bool isWhitelisted);

    modifier onlyWhitelisted() {
        // 允许 owner 调用，或者检查白名单
        if (!s_whitelist[msg.sender] && msg.sender != owner())
            revert RandomNumber__NotWhitelisted(msg.sender);
        _;
    }

    // 构造函数，传入订阅 ID 和初始 owner
    constructor(uint256 subscriptionId) VRFConsumerBaseV2Plus(vrfCoordinator){
         if (subscriptionId == 0) revert RandomNumber__InvalidSubscriptionId(uint64(subscriptionId));
        s_subscriptionId = uint64(subscriptionId);
    }

    // 更新白名单 (只有 owner 可以调用)
    function updateWhitelist(address account, bool status) external onlyOwner {
        if (account == address(0)) revert RandomNumber__ZeroAddress();
        s_whitelist[account] = status;
        emit WhitelistUpdated(account, status);
    }

    // 修改后的请求随机数函数，使用范围表示法
    function requestRandomWords(
        uint32 numWords,
        uint32 callbackGasLimit,
        uint16 requestConfirmations,
        PeriodRange calldata periodRange,   // 连续期号范围
        string[] calldata extraPeriods      // 额外的非连续期号
    ) public onlyWhitelisted returns (uint256 s_requestId) {
        if (callbackGasLimit == 0) revert RandomNumber__InvalidCallbackGasLimit(callbackGasLimit);

        unchecked {
            s_currentRound++;
        }

        // 请求 VRF 随机数
        s_requestId = s_vrfCoordinator.requestRandomWords(
            VRFV2PlusClient.RandomWordsRequest({
                keyHash: s_keyHash,
                subId: s_subscriptionId,
                requestConfirmations: requestConfirmations,
                callbackGasLimit: callbackGasLimit,
                numWords: numWords,
                extraArgs: VRFV2PlusClient._argsToBytes(
                    VRFV2PlusClient.ExtraArgsV1({nativePayment: false})
                )
            })
        );

        // 存储请求信息
        s_randomRequests[s_requestId] = RandomRequest({
            roundId: s_currentRound,
            randomNumbers: new uint256[](0), // 初始化为空数组
            basePrefix: periodRange.basePrefix,
            startIndex: periodRange.startIndex,
            endIndex: periodRange.endIndex,
            extraPeriodNos: extraPeriods
        });

        // 检查并注册连续期号
        unchecked {
            for (uint64 i = periodRange.startIndex; i <= periodRange.endIndex; i++) {
                string memory periodNo = string(abi.encodePacked(periodRange.basePrefix, _uint64ToString(i)));
                if (s_periodNoToRequestId[periodNo] != 0) {
                    revert RandomNumber__PeriodNoAlreadyExists(periodNo);
                }
                s_periodNoToRequestId[periodNo] = s_requestId;
            }
        }

        // 检查并注册额外的非连续期号
        unchecked {
            for (uint i = 0; i < extraPeriods.length; i++) {
                if (s_periodNoToRequestId[extraPeriods[i]] != 0) {
                    revert RandomNumber__PeriodNoAlreadyExists(extraPeriods[i]);
                }
                s_periodNoToRequestId[extraPeriods[i]] = s_requestId;
            }
        }

        emit RequestedRandomness(
            s_requestId,
            s_currentRound
        );
        
        return s_requestId;
    }


    // 辅助函数：将 uint64 转换为字符串
    function _uint64ToString(uint64 value) internal pure returns (string memory) {
        if (value == 0) return "0";
        
        uint64 temp = value;
        uint length = 0;
        while (temp != 0) {
            length++;
            temp /= 10;
        }
        
        bytes memory buffer = new bytes(length);
        unchecked {
            while (value != 0) {
                length -= 1;
                buffer[length] = bytes1(uint8(48 + value % 10));
                value /= 10;
            }
        }
        
        return string(buffer);
    }

    // VRF 回调函数 (由 VRF Coordinator 调用)
    function fulfillRandomWords(
        uint256 requestId,
        uint256[] calldata randomWords
    ) internal override {
        RandomRequest storage request = s_randomRequests[requestId];

        // 验证请求是否存在且未完成
        if (request.roundId == 0) revert RandomNumber__RequestNotFound(requestId);
        if (request.randomNumbers.length > 0) revert RandomNumber__RequestAlreadyFulfilled(requestId);

        // 更新请求状态
        request.randomNumbers = randomWords;

        emit RandomnessFulfilled(
            requestId,
            request.roundId,
            randomWords
        );
    }

    // 修改通过 requestId 获取随机数和期号数组的函数
    function getRandomRequest(
        uint256 requestId
    ) external view returns (uint256[] memory randomNumbers, string[] memory periodNos) {
        RandomRequest storage request = s_randomRequests[requestId];
        // 验证请求是否存在
        if (request.roundId == 0) revert RandomNumber__RequestNotFound(requestId);
        
        // 计算总的期号数量
        uint256 rangeCount = 0;
        uint256 totalPeriods = 0;
        unchecked {
            if (request.endIndex >= request.startIndex) {
                rangeCount = request.endIndex - request.startIndex + 1;
            }
            totalPeriods = rangeCount + request.extraPeriodNos.length;
            periodNos = new string[](totalPeriods);
        
            // 填充连续期号
            uint256 currentIndex = 0;
            for (uint64 i = request.startIndex; i <= request.endIndex; i++) {
                periodNos[currentIndex] = string(abi.encodePacked(request.basePrefix, _uint64ToString(i)));
                currentIndex++;
            }
        
            // 填充额外期号
            for (uint i = 0; i < request.extraPeriodNos.length; i++) {
                periodNos[currentIndex] = request.extraPeriodNos[i];
                currentIndex++;
            }
        }
        
        return (request.randomNumbers, periodNos);
    }

    // 通过单个期号获取 requestId 和随机数数组 (只有完成的请求才能获取)
    function getRequestByPeriodNo(
        string calldata periodNo
    ) external view returns (uint256 requestId, uint256[] memory randomNumbers) {
        requestId = s_periodNoToRequestId[periodNo];
        // 检查期号是否存在对应的 requestId
        if (requestId == 0) revert RandomNumber__PeriodNoNotFound(periodNo);

        RandomRequest storage request = s_randomRequests[requestId];
        // 确保请求已完成才能获取随机数
        if (request.randomNumbers.length == 0) revert RandomNumber__RequestPending(requestId);

        return (requestId, request.randomNumbers);
    }

    // 查看地址是否在白名单中
    function isWhitelisted(address account) external view returns (bool) {
        return s_whitelist[account];
    }

    // 获取当前的 VRF Coordinator 地址
    function getVRFCoordinator() external view returns (address) {
        return address(s_vrfCoordinator);
    }

}
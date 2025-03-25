// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.26;
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

interface IV2SwapRouter {
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function getAmountsOut(uint256 amountIn, address[] calldata path) external view returns (uint256[] memory amounts);
}

interface IStakePool {
    function mint(uint mintAmount) external;
    function redeem(uint redeemTokens) external;
    function redeemUnderlying(uint redeemAmount) external;
}

contract AiDatify is Initializable, AccessControlUpgradeable, UUPSUpgradeable {
    using SafeERC20 for IERC20;
    using EnumerableSet for EnumerableSet.UintSet;
    uint256 public constant CHAIN_ID = 56;
    address public constant USDT = 0x55d398326f99059fF775485246999027B3197955;
    address public constant AID = 0xAA9f209c295437c31Bde75EeE1Aa8453f2ACABCD;
    address public constant AID_SENDER = 0x9937555285c8FBFc30d4813B382E7f75ceAdDE9E;
    address public constant STAKE_POOL = 0x72Da44DC9c297fa5dc2Ce55A27E46a07715B4aF4;
    address public constant FEE_RECEIVER = 0xa839f083668F2eEa80E7A8fC657Dc8d61950f5D0;
    IV2SwapRouter public constant ROUTER = IV2SwapRouter(0x10ED43C718714eb63d5aA57B78B54704E256024E);
    address[] public receivers;
    uint256[] public receiveRates;
    address public aidReceiver;
    address public aidStake;
    address public signer;

    struct Member {
        address inviter;
        uint256 bindTimestamp;
    }

    struct StakeRecord {
        uint256 amount;
        address owner;
        bool status;
    }

    mapping(address => Member) public members;
    mapping(uint256 => StakeRecord) public stakeRecords;
    mapping(uint256 => bool) public orderIds;
    uint256 private _stakeId;
    mapping(uint256 => bool) public swapIds;
    mapping(address => EnumerableSet.UintSet) stakeIds;
    mapping(uint256 => bool) public stakeOrderIds;
    mapping(uint256 => bool) public nonces;

    // MultiSig
    address[] public owners;
    mapping(address => bool) public isOwner;
    uint256 public ownerCount;
    uint256 public threshold;
    uint256 public nonce;
    bytes32 private nameHash;
    bytes32 private versionHash;
    mapping(bytes32 => uint256) public lastOperationTime;

    event BindMember(address indexed member, address indexed inviter, uint256 timestamp, uint256 source);
    event Deposit(address indexed member, address indexed token, uint256 indexed amount, uint256 timestamp);
    event Withdraw(address indexed member, uint256 indexed orderId, uint256 indexed amount, uint256 timestamp);
    event StakeLog(address indexed member, uint256 indexed amount, uint256 stakeId, uint256 operation, uint256 timestamp);
    event Swap(address indexed member, uint256 indexed orderId, uint256 amountIn, uint256 amountOut, uint256 timestamp);
    event receiversUpdate(address[] receivers, uint256[] receiveRates, address[] newReceivers, uint256[] newReceiveRates);
    event aidReceiverUpdate(address aidReceiver, address newAidReceiver);
    event signerUpdate(address signer, address newSigner);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function _authorizeUpgrade(address newImplementation) internal override {}

    function initialize() public initializer {
        __UUPSUpgradeable_init();

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);

        members[address(this)].bindTimestamp = block.timestamp;
        require(IERC20(USDT).approve(address(ROUTER), type(uint256).max), "approve failed");
        require(IERC20(AID).approve(address(ROUTER), type(uint256).max), "approve failed");
    }

    function setupMultiSig(address[] calldata _owners, uint256 _threshold) external onlyRole(DEFAULT_ADMIN_ROLE) {
        nameHash = keccak256(bytes("AiDatify"));
        versionHash = keccak256(bytes("V1.0"));
        _setupOwners(_owners, _threshold);
    }

    function setupTimeLock() external onlyRole(DEFAULT_ADMIN_ROLE) {
        lastOperationTime[keccak256(abi.encodePacked("upgradeToAndCall"))] = block.timestamp;
        lastOperationTime[keccak256(abi.encodePacked("setReceivers"))] = block.timestamp;
        lastOperationTime[keccak256(abi.encodePacked("setAidReceiver"))] = block.timestamp;
        lastOperationTime[keccak256(abi.encodePacked("setSigner"))] = block.timestamp;
    }

    function DOMAIN_SEPARATOR() public view returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    // keccak256('EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)')
                    0x8b73c3c69bb8fe3d512ecc4cf759cc79239f7b179b0ffacaa9a75d522b39400f,
                    nameHash,
                    versionHash,
                    CHAIN_ID,
                    address(this)
                )
            );
    }

    function _setupOwners(address[] calldata _owners, uint256 _threshold) internal {
        require(threshold == 0, "duplicate operation limited");
        require(_threshold <= _owners.length, "invalid threshold");
        require(_threshold >= 1, "invalid threshold");
        require(_threshold > _owners.length / 2, "invalid threshold");
        for (uint256 i = 0; i < _owners.length; i++) {
            address owner = _owners[i];
            require(owner != address(0) && owner != address(this) && !isOwner[owner], "duplicate owner");
            owners.push(owner);
            isOwner[owner] = true;
        }
        ownerCount = _owners.length;
        threshold = _threshold;
    }

    function checkSignatures(bytes32 messageHash, bytes calldata signatures) internal returns (bool valid) {
        require(signatures.length >= threshold * 65, "invalid signatures");
        address lastSigner = address(0);
        address currentSigner;
        uint256 validCount;
        for (uint256 i = 0; i < signatures.length / 65; i++) {
            bytes memory signature = signatures[i * 65:(i + 1) * 65];
            currentSigner = ECDSA.recover(messageHash, signature);
            if (isOwner[currentSigner] && currentSigner > lastSigner) {
                validCount++;
                lastSigner = currentSigner;
            }
        }
        require(validCount >= threshold, "invalid signatures");
        nonce++;
        return true;
    }

    function checkTimeLock(string memory operation, uint256 minInterval) internal returns (bool) {
        bytes32 operationHash = keccak256(abi.encodePacked(operation));
        require(block.timestamp > lastOperationTime[operationHash] + minInterval, "operation limited");
        lastOperationTime[operationHash] = block.timestamp;
        return true;
    }

    // MultiSig for upgradeToAndCall
    function upgradeToAndCall(address newImplementation, bytes memory data) public payable override {
        revert("forbidden operation");
    }
    function upgradeToAndCall(bytes calldata signatures, address newImplementation, bytes memory data) external {
        // require(checkTimeLock("upgradeToAndCall", 2 days), "operation limited");
        bytes32 methodHash = keccak256(abi.encode(DOMAIN_SEPARATOR(), "upgradeToAndCall", nonce, newImplementation, data));
        bytes32 messageHash = MessageHashUtils.toEthSignedMessageHash(methodHash);
        require(checkSignatures(messageHash, signatures), "invalid signatures");
        super.upgradeToAndCall(newImplementation, data);
    }

    function setReceivers(bytes calldata signatures, address[] calldata _receivers, uint256[] calldata _receiveRates) external {
        require(checkTimeLock("setReceivers", 2 days), "operation limited");
        bytes32 methodHash = keccak256(abi.encode(DOMAIN_SEPARATOR(), "setReceivers", nonce, _receivers, _receiveRates));
        bytes32 messageHash = MessageHashUtils.toEthSignedMessageHash(methodHash);
        require(checkSignatures(messageHash, signatures), "invalid signatures");
        require(_receivers.length == _receiveRates.length, "invalid data");
        require(_receivers.length > 0 && _receivers.length <= 10, "invalid length");
        uint256 totalRate;
        for (uint256 i = 0; i < _receiveRates.length; i++) {
            require(_receivers[i] != address(0), "invalid receiver");
            totalRate += _receiveRates[i];
        }
        require(totalRate == 100, "invalid rates");
        emit receiversUpdate(receivers, receiveRates, _receivers, _receiveRates);
        receivers = _receivers;
        receiveRates = _receiveRates;
    }
    function setAidReceiver(bytes calldata signatures, address _aidReceiver) external {
        require(checkTimeLock("setAidReceiver", 2 days), "operation limited");
        bytes32 methodHash = keccak256(abi.encode(DOMAIN_SEPARATOR(), "setAidReceiver", nonce, _aidReceiver));
        bytes32 messageHash = MessageHashUtils.toEthSignedMessageHash(methodHash);
        require(checkSignatures(messageHash, signatures), "invalid signatures");
        emit aidReceiverUpdate(aidReceiver, _aidReceiver);
        aidReceiver = _aidReceiver;
    }
    function setSigner(bytes calldata signatures, address _signer) external {
        require(checkTimeLock("setSigner", 2 days), "operation limited");
        bytes32 methodHash = keccak256(abi.encode(DOMAIN_SEPARATOR(), "setSigner", nonce, _signer));
        bytes32 messageHash = MessageHashUtils.toEthSignedMessageHash(methodHash);
        require(checkSignatures(messageHash, signatures), "invalid signatures");
        emit signerUpdate(signer, _signer);
        signer = _signer;
    }

    function bindInviter(address _inviter) external {
        Member storage member = members[msg.sender];
        require(member.bindTimestamp == 0, "duplicate bind");
        member.bindTimestamp = block.timestamp;
        member.inviter = _inviter;
        emit BindMember(msg.sender, _inviter, block.timestamp, members[_inviter].bindTimestamp > 0 ? 1 : 0);
    }

    function stake(uint256 amount) external {
        require(members[msg.sender].bindTimestamp > 0, "invalid member");
        require(amount >= 100 ether, "invalid amount");
        IERC20(USDT).safeTransferFrom(msg.sender, address(this), amount);
        allocUSDT(amount);
        uint256 stakeId = ++_stakeId;
        require(stakeIds[msg.sender].add(stakeId), "duplicate stakeId");
        stakeRecords[stakeId] = StakeRecord({amount: amount, owner: msg.sender, status: false});
        emit StakeLog(msg.sender, amount, stakeId, 0, block.timestamp);
    }

    function allocUSDT(uint256 amount) internal {
        for (uint256 i = 0; i < receivers.length; i++) {
            IERC20(USDT).safeTransfer(receivers[i], (amount * receiveRates[i]) / 100);
        }
    }

    function unstake(bytes calldata signature, uint256 stakeId, uint256 _amount, uint256 deadline) external {
        StakeRecord storage record = stakeRecords[stakeId];
        require(record.owner == msg.sender, "invalid owner");
        require(!record.status, "already unstake");
        require(block.timestamp < deadline, "deadline limited");
        require(signer != address(0), "signer not set");
        bytes32 hash = keccak256(abi.encodePacked(DOMAIN_SEPARATOR(), "unstake", stakeId, _amount, deadline));
        bytes32 message = MessageHashUtils.toEthSignedMessageHash(hash);
        address _signer = ECDSA.recover(message, signature);
        require(signer == _signer, "invalid signature");

        uint256 amount = record.amount;
        require(_amount == amount || amount >= _amount + 100 ether, "invalid amount");
        record.amount -= _amount;
        if (_amount == amount) {
            record.status = true;
            require(stakeIds[msg.sender].remove(stakeId), "remove stakeId failed");
        }
        IStakePool(STAKE_POOL).redeemUnderlying(_amount);
        uint256 fee = (_amount * 5) / 100;
        IERC20(USDT).safeTransfer(STAKE_POOL, fee);
        IERC20(USDT).safeTransfer(msg.sender, _amount - fee);
        emit StakeLog(msg.sender, _amount, stakeId, _amount == amount ? 1 : 2, block.timestamp);
    }

    function getAmountsOut(uint256 amountIn) external view returns (uint256 amountOut) {
        address[] memory path = new address[](2);
        path[0] = USDT;
        path[1] = AID;
        return ROUTER.getAmountsOut(amountIn, path)[1];
    }

    function getAmountsOut(uint256 amountIn, address[] memory path) public view returns (uint256) {
        return ROUTER.getAmountsOut(amountIn, path)[1];
    }

    function deposit(address token, uint256 amount) external {
        require(amount > 0, "invalid amount");
        require(token == AID || token == USDT, "invalid token");
        IERC20(token).transferFrom(msg.sender, aidReceiver, amount);
        emit Deposit(msg.sender, token, amount, block.timestamp);
    }

    function withdraw(bytes calldata signatures, address token, address to, uint256 amount, uint256 orderId, uint256 deadline) external {
        require(!orderIds[orderId], "duplicate withdraw");
        require(token == AID || token == USDT, "invalid token");
        require(tx.origin == msg.sender, "only EOA can call");
        orderIds[orderId] = true;
        require(block.timestamp < deadline, "deadline limited");

        bytes32 methodHash = keccak256(abi.encode(DOMAIN_SEPARATOR(), "withdraw", token, to, amount, orderId, deadline));
        bytes32 messageHash = MessageHashUtils.toEthSignedMessageHash(methodHash);
        require(checkSignatures(messageHash, signatures), "invalid signatures");

        if (token == AID) {
            IERC20(AID).safeTransferFrom(AID_SENDER, to, amount);
        } else if (token == USDT) {
            IStakePool(STAKE_POOL).redeemUnderlying(amount);
            IERC20(USDT).safeTransfer(to, amount);
        }
        emit Withdraw(msg.sender, orderId, amount, block.timestamp);
    }

    function swap(bytes calldata signature, address srcToken, uint256 srcAmount, uint256 orderId, uint256 deadline) external {
        require(tx.origin == msg.sender, "only EOA can call");
        require(srcToken == AID || srcToken == USDT, "invalid token");
        if (srcToken == AID) {
            require(signer != address(0), "signer not set");
            require(!swapIds[orderId], "duplicate order");
            swapIds[orderId] = true;
            require(block.timestamp < deadline, "deadline limited");
            bytes32 hash = keccak256(abi.encodePacked(DOMAIN_SEPARATOR(), "swap", msg.sender, srcToken, srcAmount, orderId, deadline));
            bytes32 message = MessageHashUtils.toEthSignedMessageHash(hash);
            address _signer = ECDSA.recover(message, signature);
            require(signer == _signer, "invalid signature");
            address[] memory path = new address[](2);
            path[0] = AID;
            path[1] = USDT;
            uint256 swapOut = getAmountsOut((srcAmount * 970) / 1000, path);
            IERC20(AID).safeTransferFrom(AID_SENDER, address(this), srcAmount);
            ROUTER.swapExactTokensForTokensSupportingFeeOnTransferTokens(srcAmount, (swapOut * 90) / 100, path, msg.sender, block.timestamp);
            emit Swap(msg.sender, orderId, srcAmount, swapOut, block.timestamp);
        } else if (srcToken == USDT) {
            IERC20(USDT).safeTransferFrom(msg.sender, address(this), srcAmount);
            address[] memory path = new address[](2);
            path[0] = USDT;
            path[1] = AID;
            uint256 swapOut = getAmountsOut(srcAmount, path);
            uint256 amountOut = ROUTER.swapExactTokensForTokens(srcAmount, (swapOut * 90) / 100, path, aidReceiver, block.timestamp)[1];
            swapOut = (amountOut * 940) / 1000;
            emit Swap(msg.sender, 0, srcAmount, swapOut, block.timestamp);
        }
    }

    function stakeUSDT(bytes calldata signatures, address addr, uint256 amount, uint256 orderId) external {
        require(members[addr].bindTimestamp > 0, "invalid member");
        require(amount >= 100 ether, "invalid amount");
        require(!stakeOrderIds[orderId], "duplicate order");
        stakeOrderIds[orderId] = true;
        bytes32 methodHash = keccak256(abi.encode(DOMAIN_SEPARATOR(), "stakeUSDT", nonce, addr, amount, orderId));
        bytes32 messageHash = MessageHashUtils.toEthSignedMessageHash(methodHash);
        require(checkSignatures(messageHash, signatures), "invalid signatures");

        IStakePool(STAKE_POOL).redeemUnderlying(amount);
        allocUSDT(amount);

        uint256 stakeId = ++_stakeId;
        stakeRecords[stakeId] = StakeRecord({amount: amount, owner: addr, status: false});
        require(stakeIds[addr].add(stakeId), "duplicate stakeId");
        emit StakeLog(addr, amount, stakeId, 0, orderId);
    }
}

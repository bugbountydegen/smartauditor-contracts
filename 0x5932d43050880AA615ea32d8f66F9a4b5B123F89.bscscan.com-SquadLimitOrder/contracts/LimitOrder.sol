// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./interfaces/INonfungiblePositionManager.sol";
import "./interfaces/ISquadV3Factory.sol";
import "./interfaces/ISquadV3Pool.sol";
import "./interfaces/IERC20.sol";
import "./libraries/LibLimitOrder.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract SquadLimitOrder is Ownable, Pausable {
    mapping(bytes32 => LimitOrder) public orderInfo;
    INonfungiblePositionManager public immutable position;
    ISquadV3Factory public immutable factory;
    IERC721 public immutable nftContract;

    address public operator;
    uint public operationalFee = 0.0002 ether;

    mapping(address => uint) public deposits;
    mapping(address => bool) public pairWhitelist;
    event UpdateLimitOrderStatus(
        bytes32 indexed orderHash,
        address indexed owner,
        address indexed pairAddress,
        address token0,
        address token1,
        uint24 fee,
        int24 tickLower,
        int24 tickUpper,
        uint256 amount0,
        uint256 amount1,
        uint256 tokenId,
        uint8 status
    );

    event EmergencyWithdrawLP(
        bytes32 indexed orderHash,
        uint256 tokenId,
        address indexed owner
    );
    event UpdateUserBalance(
        address indexed sender,
        uint8 actionType, //0: Don't spend, 1: Deposit, 2: Withdraw 3: Spend
        uint256 updateAmount,
        uint256 latestBalance
    );

    modifier pairWhitelisted(address pair) {
        require(pairWhitelist[pair], "Pair not whitelisted");
        _;
    }

    constructor(
        address _nftPositionAddress,
        address _factoryAddress,
        address _operator
    ) {
        position = INonfungiblePositionManager(_nftPositionAddress);
        factory = ISquadV3Factory(_factoryAddress);
        nftContract = IERC721(_nftPositionAddress);
        operator = _operator;
    }

    function deposit() external payable {
        require(msg.value > 0, "Invalid amount");
        deposits[msg.sender] += msg.value;
        emit UpdateUserBalance(msg.sender, 1, msg.value, deposits[msg.sender]);
    }

    function makeLimitOrder(
        address pairAddress,
        int24 _tickLower,
        int24 _tickUpper,
        uint _amount,
        bool zeroForOne
    ) external pairWhitelisted(pairAddress) whenNotPaused {
        require(_amount != 0, "Invalid amount");
        address token0 = ISquadV3Pool(pairAddress).token0();
        address token1 = ISquadV3Pool(pairAddress).token1();
        uint24 fee = ISquadV3Pool(pairAddress).fee();
        handleTokenTransfersAndApproval(token0, token1, _amount, zeroForOne);
        (uint256 tokenId, uint128 liquidity) = mintPosition(
            token0,
            token1,
            fee,
            _tickLower,
            _tickUpper,
            _amount,
            zeroForOne
        );
        bytes32 orderHash = createOrder(
            token0,
            token1,
            fee,
            _tickLower,
            _tickUpper,
            tokenId,
            liquidity,
            zeroForOne
        );

        uint amount0;
        uint amount1;
        if (zeroForOne) {
            amount0 = _amount;
        } else {
            amount1 = _amount;
        }

        emit UpdateLimitOrderStatus(
            orderHash,
            msg.sender,
            pairAddress,
            token0,
            token1,
            fee,
            _tickLower,
            _tickUpper,
            amount0,
            amount1,
            tokenId,
            1
        );
    }

    function makeSpreadOrder(
        address pairAddress,
        int24[] calldata _tickLower,
        int24[] calldata _tickUpper,
        uint[] calldata _amountForStep,
        bool zeroForOne
    ) external pairWhitelisted(pairAddress) whenNotPaused {
        address token0 = ISquadV3Pool(pairAddress).token0();
        address token1 = ISquadV3Pool(pairAddress).token1();
        uint24 fee = ISquadV3Pool(pairAddress).fee();
        uint tickLowerCount = _tickLower.length;
        require(
            tickLowerCount == _tickUpper.length,
            "Invalid tick range count"
        );
        require(
            tickLowerCount == _amountForStep.length,
            "Invalid amount count"
        );
        require(tickLowerCount > 0, "Invalid tick range count");
        uint totalAmount;
        for (uint i = 0; i < tickLowerCount; i++) {
            require(_amountForStep[i] != 0, "Invalid amount");
            totalAmount += _amountForStep[i];
        }
        handleTokenTransfersAndApproval(
            token0,
            token1,
            totalAmount,
            zeroForOne
        );
        uint amount0;
        uint amount1;
        for (uint i = 0; i < tickLowerCount; i++) {
            (uint256 tokenId, uint128 liquidity) = mintPosition(
                token0,
                token1,
                fee,
                _tickLower[i],
                _tickUpper[i],
                _amountForStep[i],
                zeroForOne
            );
            bytes32 orderHash = createOrder(
                token0,
                token1,
                fee,
                _tickLower[i],
                _tickUpper[i],
                tokenId,
                liquidity,
                zeroForOne
            );

            if (zeroForOne) {
                amount0 = _amountForStep[i];
            } else {
                amount1 = _amountForStep[i];
            }

            emit UpdateLimitOrderStatus(
                orderHash,
                msg.sender,
                pairAddress,
                token0,
                token1,
                fee,
                _tickLower[i],
                _tickUpper[i],
                amount0,
                amount1,
                tokenId,
                1
            );
        }
    }

    function executeLimitOrder(bytes32 orderHash, bool spendFeeBalance) public {
        require(msg.sender == operator, "Unauthorized execution");

        LimitOrder memory order = orderInfo[orderHash];
        address orderOwner = order.owner;
        uint256 gasAtStart = gasleft(); // Gas miktarını fonksiyon başında al

        (uint256 amount0, uint256 amount1) = reduceLiquidityAndCollect(
            orderHash,
            order.owner
        );

        emit UpdateLimitOrderStatus(
            orderHash,
            order.owner,
            address(0),
            order.token0,
            order.token1,
            order.fee,
            order.tickLower,
            order.tickUpper,
            amount0,
            amount1,
            order.tokenId,
            2
        );
        delete orderInfo[orderHash];

        if (spendFeeBalance) {
            uint256 gasUsed = gasAtStart - gasleft(); // Kullanılan gas miktarını hesapla
            uint256 gasPrice = tx.gasprice; // İşlemi gönderenin gas fiyatını al
            uint256 gasCost = gasUsed * gasPrice; // Toplam maliyeti hesapla

            uint256 depositAmount = deposits[orderOwner];
            require(
                depositAmount >= gasCost,
                "Insufficient deposit to cover gas cost"
            );
            uint spendAmount = gasCost + operationalFee;
            deposits[orderOwner] = depositAmount - spendAmount;

            emit UpdateUserBalance(
                orderOwner,
                3,
                spendAmount,
                deposits[orderOwner]
            );
        } else {
            uint256 gasUsed = gasAtStart - gasleft(); // Kullanılan gas miktarını hesapla
            uint256 gasPrice = tx.gasprice; // İşlemi gönderenin gas fiyatını al
            uint256 gasCost = gasUsed * gasPrice; // Toplam maliyeti hesapla

            uint256 depositAmount = deposits[orderOwner];
            uint spendAmount = gasCost + operationalFee;

            emit UpdateUserBalance(orderOwner, 0, spendAmount, depositAmount);
        }
    }

    function cancelLimitOrder(bytes32 orderHash) public {
        require(isAuthorized(orderHash), "Unauthorized execution");
        LimitOrder memory order = orderInfo[orderHash];

        (uint256 amount0, uint256 amount1) = reduceLiquidityAndCollect(
            orderHash,
            order.owner
        );

        emit UpdateLimitOrderStatus(
            orderHash,
            order.owner,
            address(0),
            order.token0,
            order.token1,
            order.fee,
            order.tickLower,
            order.tickUpper,
            amount0,
            amount1,
            order.tokenId,
            3 //cancellled
        );
        delete orderInfo[orderHash];
    }

    function cancelBatch(bytes32[] calldata orderHashes) external {
        uint length = orderHashes.length;
        for (uint i = 0; i < length; i++) {
            cancelLimitOrder(orderHashes[i]);
        }
    }

    function executeOrderTrade(
        LimitOrder memory order,
        uint256 amount0,
        uint256 amount1
    ) private {
        address sellTokenAddress = order.zeroForOne
            ? order.token0
            : order.token1;
        address buyTokenAddress = order.zeroForOne
            ? order.token1
            : order.token0;
        uint256 sellTokenAmount = order.zeroForOne ? amount0 : amount1;
        uint256 buyTokenAmount = order.zeroForOne ? amount1 : amount0;

        IERC20(sellTokenAddress).approve(address(position), sellTokenAmount);
        IERC20(buyTokenAddress).transfer(order.owner, buyTokenAmount);
    }

    function emergencyWithdrawLP(bytes32 orderHash) external {
        require(isOwnerOrOrderOwner(orderHash), "Unauthorized access");
        _withdrawToken(orderHash);
    }

    function setOperator(address _newOperator) external onlyOwner {
        operator = _newOperator;
    }

    function handleTokenTransfersAndApproval(
        address _token0,
        address _token1,
        uint _amount,
        bool zeroForOne
    ) internal {
        address tokenAddress = zeroForOne ? _token0 : _token1;
        IERC20(tokenAddress).transferFrom(msg.sender, address(this), _amount);
        IERC20(tokenAddress).approve(address(position), _amount);
    }

    function mintPosition(
        address _token0,
        address _token1,
        uint24 _fee,
        int24 _tickLower,
        int24 _tickUpper,
        uint _amount,
        bool zeroForOne
    ) internal returns (uint256 tokenId, uint128 liquidity) {
        uint _amount0Desired = zeroForOne ? _amount : 0;
        uint _amount1Desied = zeroForOne ? 0 : _amount;
        INonfungiblePositionManager.MintParams
            memory params = INonfungiblePositionManager.MintParams({
                token0: _token0,
                token1: _token1,
                fee: _fee,
                tickLower: _tickLower,
                tickUpper: _tickUpper,
                amount0Desired: _amount0Desired,
                amount1Desired: _amount1Desied,
                amount0Min: 0,
                amount1Min: 0,
                recipient: address(this),
                deadline: block.timestamp + 2592000
            });
        (tokenId, liquidity, , ) = position.mint(params);
        return (tokenId, liquidity);
    }

    function createOrder(
        address _token0,
        address _token1,
        uint24 _fee,
        int24 _tickLower,
        int24 _tickUpper,
        uint256 tokenId,
        uint128 liquidity,
        bool zeroForOne
    ) internal returns (bytes32) {
        LimitOrder memory order = LimitOrder({
            owner: msg.sender,
            token0: _token0,
            token1: _token1,
            fee: _fee,
            tickLower: _tickLower,
            tickUpper: _tickUpper,
            amount0: 0,
            amount1: 0,
            tokenId: tokenId,
            liquidity: liquidity,
            zeroForOne: zeroForOne
        });
        bytes32 orderHash = LibLimitOrder.hash(order);
        orderInfo[orderHash] = order;
        return orderHash;
    }

    function isAuthorized(bytes32 orderHash) internal view returns (bool) {
        LimitOrder memory order = orderInfo[orderHash];
        return
            msg.sender == operator ||
            msg.sender == order.owner ||
            msg.sender == address(this);
    }

    function isOwnerOrOrderOwner(
        bytes32 orderHash
    ) internal view returns (bool) {
        LimitOrder memory order = orderInfo[orderHash];
        return msg.sender == owner() || msg.sender == order.owner;
    }

    function canBeExecuted(
        bytes32 _orderHash
    ) public view returns (bool execType) {
        execType = false;
        LimitOrder memory order = orderInfo[_orderHash];
        address poolAddress = factory.getPool(
            order.token0,
            order.token1,
            order.fee
        );
        ISquadV3Pool pool = ISquadV3Pool(poolAddress);
        (, int24 tick, , , , , ) = pool.slot0();

        if (
            (!order.zeroForOne && tick < order.tickLower) ||
            (order.zeroForOne && tick > order.tickUpper)
        ) {
            execType = true;
        }

        return execType;
    }

    function getOrderExecutionTick(
        bytes32 _orderHash
    ) public view returns (int24 execTick) {
        LimitOrder memory order = orderInfo[_orderHash];
        if (order.zeroForOne) {
            execTick = order.tickUpper;
        } else {
            execTick = order.tickLower;
        }
    }

    function _withdrawToken(bytes32 orderHash) internal {
        LimitOrder memory order = orderInfo[orderHash];
        nftContract.transferFrom(address(this), order.owner, order.tokenId);
        emit UpdateLimitOrderStatus(
            orderHash,
            order.owner,
            address(0),
            order.token0,
            order.token1,
            order.fee,
            order.tickLower,
            order.tickUpper,
            0,
            0,
            order.tokenId,
            3
        );
        delete orderInfo[orderHash];
        emit EmergencyWithdrawLP(orderHash, order.tokenId, order.owner);
    }

    function reduceLiquidityAndCollect(
        bytes32 orderHash,
        address recipient
    ) internal returns (uint256 amount0, uint256 amount1) {
        LimitOrder memory order = orderInfo[orderHash];
        INonfungiblePositionManager.DecreaseLiquidityParams
            memory decreaseParams = INonfungiblePositionManager
                .DecreaseLiquidityParams({
                    tokenId: order.tokenId,
                    liquidity: order.liquidity,
                    amount0Min: 0,
                    amount1Min: 0,
                    deadline: block.timestamp + 200
                });
        (amount0, amount1) = position.decreaseLiquidity(decreaseParams);
        INonfungiblePositionManager.CollectParams
            memory collectParams = INonfungiblePositionManager.CollectParams({
                tokenId: order.tokenId,
                recipient: recipient,
                amount0Max: uint128(amount0),
                amount1Max: uint128(amount1)
            });
        position.collect(collectParams);
        return (amount0, amount1);
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function setOperationalFee(uint _fee) external onlyOwner {
        operationalFee = _fee;
    }

    function userWithdrawFeeBalance() external {
        uint256 depositAmount = deposits[msg.sender];
        require(depositAmount > 0, "No balance to withdraw");
        deposits[msg.sender] = 0;
        payable(msg.sender).transfer(depositAmount);
        emit UpdateUserBalance(msg.sender, 2, depositAmount, 0);
    }

    function withdrawToken(address _tokenAddress) external onlyOwner {
        IERC20 token = IERC20(_tokenAddress);
        uint256 balance = token.balanceOf(address(this));
        token.transfer(owner(), balance);
    }

    function withdrawETH() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(owner()).transfer(balance);
    }

    function updatePairWhitelist(
        address pairAddress,
        bool status
    ) external onlyOwner {
        pairWhitelist[pairAddress] = status;
    }

    function updateOwner(address _newOwner) external onlyOwner {
        transferOwnership(_newOwner);
    }

    function viewOrder(
        bytes32 orderHash
    ) external view returns (LimitOrder memory) {
        return orderInfo[orderHash];
    }

    function viewUserBalance(address user) external view returns (uint256) {
        return deposits[user];
    }

    function viewOrderOwner(
        bytes32 orderHash
    ) external view returns (address owner) {
        return orderInfo[orderHash].owner;
    }

    function viewOperator() external view returns (address) {
        return operator;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.6;

import "../interfaces/IBEP20.sol";
import "../interfaces/IAggregatorV3.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

import "./ShieldOracle.sol";

contract SSVault {
    using SafeMath for uint256;

    uint256 internal constant MULTIPLIER = 1e18;
    uint256 internal constant SECONDS_IN_YEAR = 365 days;

    bytes4 internal constant SELECTOR_TRANSFER_FROM =
        bytes4(keccak256(bytes("transferFrom(address,address,uint256)")));
    bytes4 internal constant SELECTOR_TRANSFER =
        bytes4(keccak256(bytes("transfer(address,uint256)")));

    IBEP20 public baseToken;

    address public publisher;
    address private governance;

    address public tokenAggregator;

    uint256 public strikePrice;

    uint256 public strikeAPY;
    uint256 public unstrikeAPY;

    uint256 public maxVolume;
    uint256 public maxDeposit;
    uint256 public minDeposit;

    uint256 public totalDeposit;

    uint256 private baseMargin;
    uint256 private sldMargin;

    uint256 private totalUnstrikeMargin;
    uint256 private totalStrikeMargin;

    uint256 public startTime;
    uint256 public endTime;

    uint256 public closedTime;

    bool public isStriked;
    bool public shouldSettle = true;

    uint256 public settledAmount;

    uint256 public settledPrice;

    ShieldOracle private oracle;

    uint256 public dexType; // 0 V2, 1 V3

    mapping(address => UserInfo) public userInfo;
    mapping(address => bool) private charged;

    bool public marginWithdrawn;
    bool public terminated;

    Order[] public orders;

    uint256 private feeRatio;
    uint256 private gasPrice = 6 gwei; // 6 gWei
    uint256 private sldPriceForRewardsNumerator = 15; // SLD price, mean 0.15U
    uint256 private sldPriceForRewardsDenominator = 100;
    uint256 private feebackNumerator = 150;
    uint256 private feebackDenominator = 100;

    address private sldToken;
    // Chainlink price feeder
    IAggregatorV3 private GasAggregator;

    struct UserInfo {
        uint256 totalDeposit;
        uint256 totalDepositUSD;
        uint256 unstrikeProfit;
        uint256 strikeProfit;
    }

    struct Order {
        address holder;
        uint256 amount;
        uint256 startTime;
        bool settled;
    }

    event Deposited(
        address indexed user,
        address indexed token,
        uint256 amount,
        uint256 timestamp
    );

    event Withdrawn(
        address indexed user,
        address indexed token,
        uint256 amount,
        uint256 timestamp
    );

    event Settlement(
        address indexed user,
        uint256 settlePrice,
        uint8 settleType,
        uint256 settleTime
    );

    event SetFeeRatio(uint256 oldValue, uint256 newValue);

    event SetGasPrice(uint256 oldValue, uint256 newValue);

    event SetSLDPrice(
        uint256 oldValue0,
        uint256 oldValue1,
        uint256 newValue0,
        uint256 newValue1
    );

    event SetParameters(
        uint256 oldValue0,
        uint256 oldValue1,
        uint256 newValue0,
        uint256 newValue1
    );

    event SetOracle(address oldValue, address newValue);

    event Terminated(uint256 timestamp);

    modifier notTerminated() {
        require(!terminated, "terminated");
        _;
    }

    constructor(
        address _token,
        address _publisher,
        address _tokenAggregator,
        uint256 _strikePrice,
        uint256 _strikeAPY,
        uint256 _unstrikeAPY,
        uint256 _maxVolume,
        uint256 _maxDeposit,
        uint256 _minDeposit,
        uint256 _startTime,
        uint256 _endTime
    ) {
        require(
            block.timestamp < _endTime && _startTime < _endTime,
            "Invalid period"
        );

        baseToken = IBEP20(_token);

        publisher = _publisher;
        governance = msg.sender;

        tokenAggregator = _tokenAggregator;

        strikePrice = _strikePrice;

        strikeAPY = _strikeAPY;
        unstrikeAPY = _unstrikeAPY;

        maxVolume = _maxVolume;
        maxDeposit = _maxDeposit;
        minDeposit = _minDeposit;

        startTime = _startTime;
        endTime = _endTime;
    }

    function deposit(uint256 _amount) public notTerminated {
        require(_amount >= minDeposit, "deposit amount too small");
        require(block.timestamp < endTime, "vault ended");
        require(totalDeposit.add(_amount) <= maxVolume, "exceed vault volume");

        UserInfo storage info = userInfo[msg.sender];

        require(
            info.totalDeposit.add(_amount) <= maxDeposit,
            "exceed individual deposit"
        );

        uint256 _before = baseToken.balanceOf(address(this));
        _safeTransferFrom(
            address(baseToken),
            msg.sender,
            address(this),
            _amount
        );
        uint256 _after = baseToken.balanceOf(address(this));
        // Additional check for deflationary tokens
        _amount = _after.sub(_before);

        emit Deposited(
            msg.sender,
            address(baseToken),
            _amount,
            block.timestamp
        );

        uint256 sTime = block.timestamp < startTime
            ? startTime
            : block.timestamp;

        uint256 interests = calUnstrikeInterets(_amount, sTime);

        info.unstrikeProfit = info.unstrikeProfit.add(interests);
        info.totalDeposit = info.totalDeposit.add(_amount);
        info.totalDepositUSD = info.totalDepositUSD.add(getTokenValue(_amount));

        totalUnstrikeMargin = totalUnstrikeMargin.add(interests).sub(_amount);

        orders.push(Order(msg.sender, _amount, sTime, false));

        totalDeposit = totalDeposit.add(_amount);
    }

    function depositAll() public {
        uint256 max = baseToken.balanceOf(msg.sender);
        deposit(max);
    }

    function withdraw(uint256 _amount) public {
        require(block.timestamp > endTime, "not end");

        if (shouldSettle) {
            require(isAllSettled(), "not settled");
        } else {
            require(!isStriked, "should not be striked");
        }

        UserInfo storage info = userInfo[msg.sender];

        uint256 fee;

        if (isStriked) {
            require(info.strikeProfit >= _amount, "exceed");

            info.strikeProfit = info.strikeProfit.sub(_amount);
        } else {
            require(info.unstrikeProfit >= _amount, "exceed");

            if (!charged[msg.sender]) {
                fee = info
                    .unstrikeProfit
                    .sub(info.totalDeposit)
                    .mul(feeRatio)
                    .div(MULTIPLIER);
            }

            info.unstrikeProfit = info.unstrikeProfit.sub(_amount);
        }

        if (fee > 0) {
            _safeTransfer(address(baseToken), msg.sender, _amount.sub(fee));
            _safeTransfer(address(baseToken), governance, fee);

            charged[msg.sender] = true;
        } else {
            _safeTransfer(address(baseToken), msg.sender, _amount);
        }

        emit Withdrawn(
            msg.sender,
            address(baseToken),
            _amount,
            block.timestamp
        );
    }

    function withdrawAll() public {
        UserInfo memory info = userInfo[msg.sender];

        if (isStriked) {
            withdraw(info.strikeProfit);
        } else {
            withdraw(info.unstrikeProfit);
        }
    }

    function payMargin(uint256 _amount) public {
        uint256 _before = baseToken.balanceOf(address(this));
        _safeTransferFrom(
            address(baseToken),
            msg.sender,
            address(this),
            _amount
        );

        uint256 _after = baseToken.balanceOf(address(this));
        // Additional check for deflationary tokens
        _amount = _after.sub(_before);

        baseMargin = baseMargin.add(_amount);
    }

    function paySLDMargin(uint256 _amount) public {
        _safeTransferFrom(sldToken, msg.sender, address(this), _amount);

        sldMargin = sldMargin.add(_amount);
    }

    function withdrawMargin() public {
        require(msg.sender == publisher, "not publisher");
        require(!marginWithdrawn, "withdrawn");

        require(block.timestamp > endTime, "not end");

        if (shouldSettle) {
            require(isAllSettled() || totalDeposit == 0, "not settled");

            _safeTransfer(
                address(baseToken),
                publisher,
                baseMargin.add(totalDeposit).sub(totalStrikeMargin)
            );
        } else {
            require(!isStriked || totalDeposit == 0, "should not be striked");

            _safeTransfer(
                address(baseToken),
                publisher,
                baseMargin.sub(totalUnstrikeMargin)
            );
        }

        _safeTransfer(sldToken, publisher, sldMargin);

        marginWithdrawn = true;
    }

    function queryMargin()
        public
        view
        returns (uint256 baseMarginBalance, uint256 sldMarginBalance)
    {
        if (marginWithdrawn) {
            return (0, 0);
        }
        if (shouldSettle && isAllSettled()) {
            baseMarginBalance = baseMargin.add(totalDeposit).sub(
                totalStrikeMargin
            );
            sldMarginBalance = sldMargin;
        } else if (!shouldSettle && !isStriked) {
            baseMarginBalance = baseMargin.sub(totalUnstrikeMargin);
            sldMarginBalance = sldMargin;
        } else {
            baseMarginBalance = baseMargin;
            sldMarginBalance = sldMargin;
        }
    }

    function settleAll() public {
        uint256 gasUsed;

        require(!isAllSettled() && totalDeposit != 0, "all settled");
        require(isStriked, "not strike");
        require(settledPrice > 0, "need settle price");

        for (uint256 i = 0; i < orders.length; i++) {
            gasUsed = gasUsed + settleOrder(i);
        }

        if (gasUsed > 0) {
            sendSettleRewards(gasUsed);
        }
    }

    function settleOrders(uint256[] memory orderIDs) public {
        uint256 gasUsed;

        require(isStriked, "not strike");
        require(settledPrice > 0, "need settle price");
        require(!isAllSettled(), "all settled");

        for (uint256 i = 0; i < orderIDs.length; i++) {
            gasUsed = gasUsed + settleOrder(orderIDs[i]);
        }

        if (gasUsed > 0) {
            sendSettleRewards(gasUsed);
        }
    }

    function sendSettleRewards(uint256 _gasUsed) internal {
        uint256 gasFeeUsed = _gasUsed
            .mul(gasPrice)
            .mul(getBNBPrice())
            .mul(feebackNumerator)
            .div(feebackDenominator)
            .div(MULTIPLIER);

        uint256 rewards = gasFeeUsed.mul(sldPriceForRewardsDenominator).div(
            sldPriceForRewardsNumerator
        );

        if (rewards > 0) {
            sldMargin = sldMargin.sub(rewards);
            _safeTransfer(address(sldToken), msg.sender, rewards);
        }
    }

    function getBNBPrice() public view returns (uint256) {
        uint8 decimals = GasAggregator.decimals();
        (, int256 price, , , ) = GasAggregator.latestRoundData();

        return (uint256(price) * MULTIPLIER) / (10**uint256(decimals));
    }

    function settleOrder(uint256 id)
        internal
        notTerminated
        returns (uint256 gasUsed)
    {
        uint256 beforeGas = gasleft();

        Order storage order = orders[id];

        if (order.settled) {
            return 0;
        }

        UserInfo storage info = userInfo[order.holder];

        uint256 interests = calStrikeInterets(order.amount, order.startTime);

        info.strikeProfit = info.strikeProfit.add(interests);

        order.settled = true;

        totalStrikeMargin = totalStrikeMargin.add(interests);
        settledAmount = settledAmount + 1;

        if (isAllSettled()) {
            emit Settlement(msg.sender, settledPrice, 1, block.timestamp);
            closedTime = block.timestamp;
        }

        return beforeGas - gasleft();
    }

    function getTokenValue(uint256 _amount)
        internal
        view
        returns (uint256 value)
    {
        uint256 price = oracle.consult(address(baseToken), 60);

        value = _amount.mul(price).div(1e18);
    }

    function calStrikeInterets(uint256 _amount, uint256 _startTime)
        internal
        view
        returns (uint256 interests)
    {
        uint256 value = _amount.mul(strikePrice);

        interests = value
            .mul(strikeAPY)
            .mul(endTime.sub(_startTime))
            .div(SECONDS_IN_YEAR)
            .div(MULTIPLIER)
            .add(value)
            .div(settledPrice);
    }

    function calUnstrikeInterets(uint256 _amount, uint256 _startTime)
        internal
        view
        returns (uint256 interests)
    {
        interests = _amount
            .mul(unstrikeAPY)
            .mul(endTime.sub(_startTime))
            .div(SECONDS_IN_YEAR)
            .div(MULTIPLIER)
            .add(_amount);
    }

    function updatePrice() public notTerminated {
        uint256 beforeGas = gasleft();

        require(settledPrice == 0, "settled.");

        if (dexType == 0) {
            oracle.update();
        } else {
            require(dexType == 1 || dexType == 2, "wrong dex type");
            require(block.timestamp > endTime, "not end");
        }

        if (block.timestamp > endTime) {
            settledPrice = oracle.consult(address(baseToken), 30 * 60);

            if (oracle.router() != address(0)) {
                settledPrice = settledPrice
                    .mul(getRouterPrice(oracle.router()))
                    .div(MULTIPLIER);
            }

            if (settledPrice >= strikePrice) {
                isStriked = true;
                if (totalDeposit == 0) {
                    emit Settlement(
                        msg.sender,
                        settledPrice,
                        1,
                        block.timestamp
                    );
                    closedTime = block.timestamp;
                }
            } else {
                shouldSettle = false;
                emit Settlement(msg.sender, settledPrice, 0, block.timestamp);
                closedTime = block.timestamp;
            }
        }

        sendSettleRewards(beforeGas - gasleft());
    }

    function isAllSettled() public view returns (bool settled) {
        if (block.timestamp <= endTime) {
            settled = false;
        } else {
            settled = orders.length == settledAmount && orders.length != 0;
        }
    }

    function getRouterPrice(address _router)
        public
        view
        returns (uint256 price)
    {
        IAggregatorV3 aggregator = IAggregatorV3(_router);

        uint8 decimals = aggregator.decimals();
        (, int256 p, , , ) = aggregator.latestRoundData();

        return (uint256(p) * MULTIPLIER) / (10**uint256(decimals));
    }

    function initRewardParameter(address _sldToken, address _GasAggregator)
        external
    {
        require(msg.sender == governance);

        sldToken = _sldToken;
        GasAggregator = IAggregatorV3(_GasAggregator);
    }

    function terminate() public {
        require(msg.sender == publisher);
        require(totalDeposit == 0, "already deposit");

        terminated = true;
        emit Terminated(block.timestamp);
    }

    function setFeeRatio(uint256 _ratio) public {
        require(msg.sender == governance);

        emit SetFeeRatio(feeRatio, _ratio);
        feeRatio = _ratio;
    }

    function setGasPrice(uint256 _gasPrice) public {
        require(msg.sender == governance);

        emit SetGasPrice(gasPrice, _gasPrice);
        gasPrice = _gasPrice;
    }

    function setSLDPrice(uint256 _numerator, uint256 _denominator) public {
        require(msg.sender == governance);

        emit SetSLDPrice(
            sldPriceForRewardsNumerator,
            sldPriceForRewardsDenominator,
            _numerator,
            _denominator
        );
        sldPriceForRewardsNumerator = _numerator;
        sldPriceForRewardsDenominator = _denominator;
    }

    function setParameters(
        uint256 _feebackNumerator,
        uint256 _feebackDenominator
    ) public {
        require(msg.sender == governance);

        emit SetParameters(
            feebackNumerator,
            feebackDenominator,
            _feebackNumerator,
            _feebackDenominator
        );
        feebackNumerator = _feebackNumerator;
        feebackDenominator = _feebackDenominator;
    }

    function setOracle(address _oracle, uint8 _dexType) public {
        require(msg.sender == governance);

        emit SetOracle(address(oracle), _oracle);
        oracle = ShieldOracle(_oracle);
        dexType = _dexType;
    }

    function _safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(SELECTOR_TRANSFER_FROM, from, to, value)
        );
        require(success && (data.length == 0 || abi.decode(data, (bool))));
    }

    function _safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(SELECTOR_TRANSFER, to, value)
        );
        require(success && (data.length == 0 || abi.decode(data, (bool))));
    }
}

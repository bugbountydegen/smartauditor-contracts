// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

//import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
//import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
//import { AggregatorV3Interface } from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

// Manual imports to get verified on testnet
library SafeERC20 {
    using Address for address;
    error SafeERC20FailedOperation(address token);
    error SafeERC20FailedDecreaseAllowance(address spender, uint256 currentAllowance, uint256 requestedDecrease);
    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeCall(token.transfer, (to, value)));
    }
    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeCall(token.transferFrom, (from, to, value)));
    }
    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 oldAllowance = token.allowance(address(this), spender);
        forceApprove(token, spender, oldAllowance + value);
    }
    function safeDecreaseAllowance(IERC20 token, address spender, uint256 requestedDecrease) internal {
        unchecked {
            uint256 currentAllowance = token.allowance(address(this), spender);
            if (currentAllowance < requestedDecrease) {
                revert SafeERC20FailedDecreaseAllowance(spender, currentAllowance, requestedDecrease);
            }
            forceApprove(token, spender, currentAllowance - requestedDecrease);
        }
    }
    function forceApprove(IERC20 token, address spender, uint256 value) internal {
        bytes memory approvalCall = abi.encodeCall(token.approve, (spender, value));

        if (!_callOptionalReturnBool(token, approvalCall)) {
            _callOptionalReturn(token, abi.encodeCall(token.approve, (spender, 0)));
            _callOptionalReturn(token, approvalCall);
        }
    }
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        bytes memory returndata = address(token).functionCall(data);
        if (returndata.length != 0 && !abi.decode(returndata, (bool))) {
            revert SafeERC20FailedOperation(address(token));
        }
    }
    function _callOptionalReturnBool(IERC20 token, bytes memory data) private returns (bool) {
        (bool success, bytes memory returndata) = address(token).call(data);
        return success && (returndata.length == 0 || abi.decode(returndata, (bool))) && address(token).code.length > 0;
    }
}
library Address {
    error AddressInsufficientBalance(address account);
    error AddressEmptyCode(address target);
    error FailedInnerCall();
    function sendValue(address payable recipient, uint256 amount) internal {
        if (address(this).balance < amount) {
            revert AddressInsufficientBalance(address(this));
        }

        (bool success, ) = recipient.call{value: amount}("");
        if (!success) {
            revert FailedInnerCall();
        }
    }
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0);
    }
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        if (address(this).balance < value) {
            revert AddressInsufficientBalance(address(this));
        }
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata);
    }
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata);
    }
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata);
    }
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata
    ) internal view returns (bytes memory) {
        if (!success) {
            _revert(returndata);
        } else {
            if (returndata.length == 0 && target.code.length == 0) {
                revert AddressEmptyCode(target);
            }
            return returndata;
        }
    }
    function verifyCallResult(bool success, bytes memory returndata) internal pure returns (bytes memory) {
        if (!success) {
            _revert(returndata);
        } else {
            return returndata;
        }
    }
    function _revert(bytes memory returndata) private pure {
        if (returndata.length > 0) {
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert FailedInnerCall();
        }
    }
}
interface IERC20Permit {
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
    function nonces(address owner) external view returns (uint256);
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}
interface IERC20 {

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 value) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
}
interface AggregatorV3Interface {
    function decimals() external view returns (uint8);

    function description() external view returns (string memory);

    function version() external view returns (uint256);

    function getRoundData(uint80 _roundId)
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );

    function latestRoundData()
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );
}

contract BuboVault {
    using SafeERC20 for IERC20;
    IERC20 public immutable buboToken;
    IERC20 public immutable usdtToken;
    address payable public immutable owner;
    uint256 public immutable tokenPriceInUSDT = 15e4;
    // uint256 public immutable tokenPriceInUSD = 15e16;
    uint256 public immutable tokenPriceInForReceiveFunction = 15e14;
    uint256 public immutable ethPriceFeedDecimals = 8;
    AggregatorV3Interface internal immutable priceFeed;

    address immutable BUBO_TOKEN_ADDRESS =
        0xCCbf21ba6EF00802AB06637896B799f7101F54A2; // CORRECT ADDRESS: 0xCCbf21ba6EF00802AB06637896B799f7101F54A2
    address immutable USDT_TOKEN_ADDRESS =
        0xdAC17F958D2ee523a2206206994597C13D831ec7; // @dev OFFICIAL ADDRESS: 0xdAC17F958D2ee523a2206206994597C13D831ec7

    event TokensPurchased(
        address buyer,
        uint256 amountPaid,
        uint256 amountOfTokens
    );
    event TokensTransferred(address recipient, uint256 amountOfTokens);
    event BuboTokensReceived(address indexed sender, uint256 amount);
    event EtherSentByOwner(
        address indexed sender,
        address indexed recipient,
        uint256 amount
    );
    event UsdtWithdrawn(
        address indexed owner,
        address indexed recipient,
        uint256 amount
    );

    constructor() {
        buboToken = IERC20(BUBO_TOKEN_ADDRESS);
        usdtToken = IERC20(USDT_TOKEN_ADDRESS);
        owner = payable(msg.sender);
        priceFeed = AggregatorV3Interface(
            0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419 // @dev CHANGE THIS TO THE MAINNET PRICE FEED ADDRESS -> mainnet address: 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419
        );
    }

    receive() external payable {
        // Handle ETH sent to the contract
        if (msg.sender != owner) {
            // Get the latest ETH/USD price from the price feed
            int256 latestEthPrice = int256(getLatestEthPrice());

            // Calculate the amount of Bubo Tokens based on the amount of ETH sent
            uint256 amountOfTokens = (msg.value *
                uint256(latestEthPrice) *
                (10 ** ethPriceFeedDecimals)) / tokenPriceInForReceiveFunction;

            // Ensure that the contract has enough Bubo Tokens to fulfill the transfer
            require(
                buboToken.balanceOf(address(this)) >= amountOfTokens,
                "Insufficient Bubo Tokens in the contract"
            );

            // Emit event
            emit TokensPurchased(msg.sender, msg.value, amountOfTokens);

            // Transfer Bubo Tokens to the sender
            buboToken.safeTransfer(msg.sender, amountOfTokens);
        }
    }

    function getBuboBalance() external view returns (uint256) {
        return buboToken.balanceOf(address(this));
    }

    function withdrawEth() external {
        require(msg.sender == owner, "Only owner can withdraw ETH");
        owner.transfer(address(this).balance);
    }

    function getLatestEthPrice() public view returns (int256) {
        (, int256 price, , , ) = priceFeed.latestRoundData();
        return price;
    }

    function withdrawTokens(uint256 _amount) external {
        require(msg.sender == owner, "Only owner can withdraw tokens");
        buboToken.safeTransfer(owner, _amount);
    }

    function sendEther() external payable {
        require(msg.sender == owner, "Only owner can send Ether");
    }

    function transferTokensTo(
        address _recipient,
        uint256 _usdtAmount
    ) external {
        // Calculate the amount of Bubo Tokens based on the USDT amount and the Bubo price of 0.15 USDT
        // For mainnet
        // uint256 amountOfTokens = (_usdtAmount * (10**18)) / tokenPriceInUSDT; // Bubo price is 0.15 USDT
        // For Testnet
        uint256 amountOfTokens = (_usdtAmount * (10 ** 18)) /
            (tokenPriceInUSDT);
        // Ensure that the contract has enough Bubo Tokens to fulfill the transfer
        require(
            buboToken.balanceOf(address(this)) >= amountOfTokens,
            "Insufficient Bubo Tokens in the contract"
        );

        // Emit event
        emit TokensTransferred(_recipient, amountOfTokens);

        // Contract should receive USDT.
        usdtToken.safeTransferFrom(msg.sender, address(this), _usdtAmount);

        // Transfer Bubo tokens to the specified recipient
        buboToken.safeTransfer(_recipient, amountOfTokens);
    }

    function ownerSendEtherTo(
        address payable _recipient,
        uint256 _amount
    ) external {
        require(msg.sender == owner, "Only owner can send Ether");
        require(_recipient != address(0), "Invalid recipient address");

        emit EtherSentByOwner(msg.sender, _recipient, _amount);

        _recipient.transfer(_amount);
    }

    function withdrawUsdt(address _recipient, uint256 _amount) external {
        require(msg.sender == owner, "Only owner can withdraw USDT");
        require(_recipient != address(0), "Invalid recipient address");

        emit UsdtWithdrawn(msg.sender, _recipient, _amount);

        usdtToken.safeTransfer(_recipient, _amount);
    }

    function getUsdtBalance() external view returns (uint256) {
        return usdtToken.balanceOf(address(this));
    }

    fallback() external payable {
        if (msg.sender != BUBO_TOKEN_ADDRESS && msg.sender != owner) {
            revert(
                "Unsupported operation: sending tokens directly to this contract is not allowed"
            );
        }
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }
}
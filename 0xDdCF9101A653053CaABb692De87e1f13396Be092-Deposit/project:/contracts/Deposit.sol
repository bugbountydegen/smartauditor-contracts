// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract Deposit is Context, Ownable{
    using SafeERC20 for IERC20;
    IERC20[] public tokens;

    address[] private beneficiaries;
    mapping(uint256 => uint256) public totalDeposited;
    uint256 public allOrderId;

    struct Order {
        address owner;
        address beneficiaryAddr;
        uint256 orderId;
        uint256 orderDate; //timestamp
        uint256 amount;
        uint256 tokenType;
        string account;
    }

    mapping(uint256 => Order) public allOrders;

    event DepositToken(
        address owner,
        uint256 orderId,
        uint256 amount,
        uint256 tokenType,
        string account
    );

    constructor() Ownable(msg.sender){
    }

    function addTokensType(address _token) public onlyOwner {
        require(_token != address(0), "Invalid token");
        tokens.push(IERC20(_token));
    }

    function getTokensType(
        uint256 index
    ) public view returns (IERC20) {
        return tokens[index];
    }

    function addBeneficiary(address _beneficiary) public onlyOwner {
        require(_beneficiary != address(0), "Invalid Beneficiary");
        beneficiaries.push(_beneficiary);
    }

    function getBeneficiaries()
        public
        view
        onlyOwner
        returns (address[] memory)
    {
        return beneficiaries;
    }

    //==============================
    //            MAIN
    //==============================
    function deposit(
        uint256 _amt,
        string memory _account,
        uint256 _tokenType
    ) public {
        require(_amt > 0, "Amount cannot be empty");
        require(beneficiaries.length > 0, "Beneficiary empty");
        require(_tokenType < tokens.length, "Token type not found");
        allOrderId++; //starts with 1

        uint256 beneficiaryIndex = (allOrderId - 1) % beneficiaries.length;
        address beneficiaryAddr = beneficiaries[beneficiaryIndex];

        //add new order
        Order memory newOrder;
        newOrder.owner = msg.sender;
        newOrder.beneficiaryAddr = beneficiaryAddr;
        newOrder.orderDate = block.timestamp;
        newOrder.amount = _amt;
        newOrder.orderId = allOrderId;
        newOrder.tokenType = _tokenType;
        newOrder.account = _account;
        allOrders[allOrderId] = newOrder; //order struct new order

        totalDeposited[_tokenType] += _amt;

        tokens[_tokenType].safeTransferFrom(msg.sender, beneficiaryAddr, _amt);

        emit DepositToken(msg.sender, allOrderId, _amt, _tokenType, _account);
    }
}

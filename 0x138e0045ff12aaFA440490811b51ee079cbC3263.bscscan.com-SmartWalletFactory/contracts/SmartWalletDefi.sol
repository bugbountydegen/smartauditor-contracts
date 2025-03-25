pragma solidity 0.8.18;

import "@openzeppelin/contracts@4.2.0/access/Ownable.sol";
import "@openzeppelin/contracts@4.2.0/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts@4.2.0/token/ERC20/ERC20.sol";


contract Receiver {

    address immutable owner;

    constructor() {
        owner = msg.sender;
    }

    receive() payable external { }

    function call(address _target, uint value, bytes memory callData) external
    {
        require(msg.sender == owner);
        
        _target.call { value: value }(callData);
    }
}


contract SmartWallet is Ownable {

    error NotEnoughFundsInSelection();

    constructor() {

    }

    function getAddress(bytes1 prefix, uint _salt) public view returns (address) {
        bytes32 hash = keccak256(
            abi.encodePacked(
                prefix, address(this), _salt, keccak256(getBytecode())
            )
        );
        return address(uint160(uint(hash)));
    }

     // get the ByteCode of the contract DeployWithCreate2
    function getBytecode() private pure returns (bytes memory) {
        bytes memory bytecode = type(Receiver).creationCode;
        return abi.encodePacked(bytecode);
    }

    function createIfNeeded(uint index) private {
        if (accounts[index] != address(0)) return;
        bytes32 salt = bytes32(index);
        accounts[index] = address(new Receiver{ salt: salt }());
    }

    mapping(uint => address) private accounts;

    function send(uint account, address _token, address recipient, uint value) private {
        Receiver receiver = Receiver(payable(accounts[account]));

        if(_token == address(0x0)) {
            receiver.call(recipient, value, "");
            return;
        }
        
        receiver.call(_token, 0, abi.encodeWithSelector(0xa9059cbb, recipient, value));
    }

    function sendToken(uint account, address _token, address recipient, uint value) public onlyOwner {
        createIfNeeded(account);
        send(account, _token, recipient, value);
    }

    function calls(uint[] memory _accounts, address[] memory _targets, uint[] memory _values, bytes[] memory _callDatas) external onlyOwner {

        uint length = _accounts.length;

        for (uint i=0; i < length; ) {

            createIfNeeded(_accounts[i]);

            Receiver(payable(accounts[_accounts[i]])).call(_targets[i], _values[i], _callDatas[i]);

            unchecked {
                i++;
            }
        }
  
    }

    function sendTokenFromMany(uint[] memory _accounts, address _token, address recipient, uint value) external onlyOwner {
        
        uint length = _accounts.length;


        for (uint i=0; i < length; ) {
            createIfNeeded(_accounts[i]);

            address account = accounts[_accounts[i]];
            uint balance = _token == address(0) ? account.balance : IERC20(_token).balanceOf(account);

            if (balance > value)
                return send(_accounts[i], _token, recipient, value);
                
        
            value -= balance;
            send(_accounts[i], _token, recipient, balance);

            unchecked {
                i++;
            }
        }

        if (value > 0) revert NotEnoughFundsInSelection();
    }

}


contract SmartWalletFactory {

    function getSalt(address owner) public pure returns (bytes32) {
        return bytes32(uint256(uint160(owner)) << 96);
    }

    function createInternal(address owner) public returns(SmartWallet) {
        bytes32 salt = getSalt(owner);
        return new SmartWallet{ salt: salt }();        
    }

    function create() external {
        SmartWallet wallet = createInternal(msg.sender);
        wallet.transferOwnership(msg.sender);
    }

    function calls(uint[] memory _accounts, address[] memory _targets, uint[] memory _values, bytes[] memory _callDatas) external {
        SmartWallet wallet = createInternal(msg.sender);
        wallet.calls(_accounts, _targets, _values, _callDatas);
        wallet.transferOwnership(msg.sender);
    }

    function sendToken(uint account, address _token, address recipient, uint value) external {
        SmartWallet wallet = createInternal(msg.sender);
        wallet.sendToken(account, _token, recipient, value);
        wallet.transferOwnership(msg.sender);
    }

    function sendTokenFromMany(uint[] memory _accounts, address _token, address recipient, uint value) external {
        SmartWallet wallet = createInternal(msg.sender);
        wallet.sendTokenFromMany(_accounts, _token, recipient, value);
        wallet.transferOwnership(msg.sender);
    }

    function getWalletAddress(bytes1 prefix, address ownerAddress) public view returns (address) {
        bytes32 hash = keccak256(
            abi.encodePacked(
                prefix, address(this), getSalt(ownerAddress), keccak256(getWalletBytecode())
            )
        );
        return address(uint160(uint(hash)));
    }

     // get the ByteCode of the contract DeployWithCreate2
    function getWalletBytecode() private pure returns (bytes memory) {
        bytes memory bytecode = type(SmartWallet).creationCode;
        return abi.encodePacked(bytecode);
    }

    function getAddress(bytes1 prefix, address ownerAddress, uint _salt) public view returns (address) {
        bytes32 hash = keccak256(
            abi.encodePacked(
                prefix, getWalletAddress(prefix, ownerAddress), _salt, keccak256(getBytecode())
            )
        );
        return address(uint160(uint(hash)));
    }

     // get the ByteCode of the contract DeployWithCreate2
    function getBytecode() private pure returns (bytes memory) {
        bytes memory bytecode = type(Receiver).creationCode;
        return abi.encodePacked(bytecode);
    }



}


/*

contract Token is ERC20, Ownable { 

    constructor() ERC20("Test", "TTT") {
    }

    function mint(address target, uint value) public onlyOwner {
        _mint(target, value);
    }
}


contract SmartWalletTest { 
    

    constructor() {

        uint fullvalue = 10000 ether;
        uint minvalue = 10;
        uint resultvalue = fullvalue - minvalue;
        address user = 0xc2f6C9eAF3076df062e7C2F0cC52c3eC0641BDd0;


        Token token = new Token();

        SmartWallet wallet = new SmartWallet();

        token.mint(address(this), fullvalue);

        require(token.balanceOf(address(this)) == fullvalue);
        
        token.transfer(wallet.getAddress(0xff, 1), 1 ether);
        token.transfer(wallet.getAddress(0xff, 2), 5 ether);

        
        uint[] memory _accounts = new uint[](2);
        _accounts[0] = 1;
        _accounts[1] = 2;
        
        wallet.sendTokenFromMany( _accounts, address(token), user, 6 ether);

        require(token.balanceOf(user) == 6 ether);

    }

    
    function testUSDT() public {

        
        address user = 0xc2f6C9eAF3076df062e7C2F0cC52c3eC0641BDd0;

        address token = 0x5e17b14ADd6c386305A32928F985b29bbA34Eff5; 

        SmartWallet wallet = new SmartWallet();

        require(IERC20(token).balanceOf(address(this)) == 6000000);
        
        token.call(abi.encodeWithSelector(0xa9059cbb, wallet.getAddress(0xff, 1), 1000000));
        token.call(abi.encodeWithSelector(0xa9059cbb, wallet.getAddress(0xff, 2), 5000000));

        
        uint[] memory _accounts = new uint[](2);
        _accounts[0] = 1;
        _accounts[1] = 2;
        
        wallet.sendTokenFromMany( _accounts, address(token), user, 6000000);

        require(IERC20(token).balanceOf(user) == 6000000);

    }
    

    
    function testEther() payable public {
        require(msg.value == 6 ether);
        address user = 0xc2f6C9eAF3076df062e7C2F0cC52c3eC0641BDd0;

        SmartWallet wallet = new SmartWallet();

        payable(wallet.getAddress(0xff, 1)).transfer(1 ether);
        payable(wallet.getAddress(0xff, 2)).transfer(5 ether);
        
        uint[] memory _accounts = new uint[](2);
        _accounts[0] = 1;
        _accounts[1] = 2;
        
        uint before = user.balance;

        wallet.sendTokenFromMany( _accounts, address(0x0), user, 6 ether);

        require(user.balance - before == 6 ether);
    } 
    


    function testEtherFactory() payable public {
        
        require(msg.value == 6 ether);
        address user = 0xc2f6C9eAF3076df062e7C2F0cC52c3eC0641BDd0;

        SmartWalletFactory factory = new SmartWalletFactory();

        payable(factory.getAddress(0xff, address(this), 1)).transfer(1 ether);
        payable(factory.getAddress(0xff, address(this), 2)).transfer(5 ether);
        
        uint[] memory _accounts = new uint[](2);
        _accounts[0] = 1;
        _accounts[1] = 2;
        
        uint before = user.balance;

        factory.sendTokenFromMany( _accounts, address(0x0), user, 6 ether);

        require(user.balance - before == 6 ether);

    }

}


*/
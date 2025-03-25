pragma solidity >=0.6.6;

contract ShieldOracle {
    address public immutable pair;

    address private factory;
    address public router;

    constructor(address _aggregator, address _router) {
        factory = msg.sender;
        pair = _aggregator;
        router = _router;
    }

    function consult(address tokenIn, uint32 secondsAgo)
        public
        view
        virtual
        returns (uint256 amountOut)
    {}

    function update() external virtual {}
}

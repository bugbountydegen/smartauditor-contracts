// contracts/ChroniumDistilleryV1.sol
// SPDX-License-Identifier: MIT
pragma solidity = 0.8.8;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import './interfaces/IChronium.sol';

/*
 *      ChroniumDistilleryV1: Chronium faucet.
 *
 *          - Distill time into Chronium.
 *
 */
contract ChroniumDistilleryV1 is Initializable,OwnableUpgradeable {
    using AddressUpgradeable for address;

    IChronium                            _chronium;
    uint256                      public defaultEmissionRate;

    function __ChroniumDistilleryV1_Init(    
        address chronium, 
        uint256 defaultEmissionRate_,
        address governance
        ) 
        public initializer 
    {
        __Ownable_init_unchained();
        _chronium = IChronium(chronium);
        defaultEmissionRate = defaultEmissionRate_;
        transferOwnership(governance);
    }

    // RATE ------------------------------------------------------------

    event LogSetDefaultEmissionRate(address sender, uint256 rate);
    function setDefaultEmissionRate(uint256 rate_)
    onlyOwner
    external returns(bool)
    {
        defaultEmissionRate = rate_;
        emit LogSetDefaultEmissionRate(_msgSender(),rate_);
        return true;
    }

    /**
     *  
     *  This is different from minting which is an outright issuing of token, distill requires converting time into Chronium.
     *  The emission is defined as time * emissionRate.
     */
    event LogDistill(address timeOwner, uint256 time, uint256 amount);

    function distill(uint256 time)
    external returns(bool)
    {
        address sender = _msgSender();
        require(_chronium.timestamp(sender) > 0, "Distill: NO_TIME_ACCOUNT");
        uint256 amt = defaultEmissionRate * time;
        try _chronium.mint(sender, time, amt) {
            emit LogDistill(sender, time, amt);
            return true;
        }
        catch(bytes memory reason) {
            if (reason.length == 0) 
                revert("Distill: MINT_FAILED");
            assembly 
            {
                revert(add(0x20, reason), mload(reason))
            }
        }
    }

}

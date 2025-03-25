// SPDX-License-Identifier: MIT

// ((/*,                                                                    ,*((/,.
// &&@@&&%#/*.                                                        .*(#&&@@@@%. 
// &&@@@@@@@&%(.                                                    ,#%&@@@@@@@@%. 
// &&@@@@@@@@@&&(,                                                ,#&@@@@@@@@@@@%. 
// &&@@@@@@@@@@@&&/.                                            .(&&@@@@@@@@@@@@%. 
// %&@@@@@@@@@@@@@&(,                                          *#&@@@@@@@@@@@@@@%. 
// #&@@@@@@@@@@@@@@&#*                                       .*#@@@@@@@@@@@@@@@&#. 
// #&@@@@@@@@@@@@@@@@#.                                      ,%&@@@@@@@@@@@@@@@&#. 
// #&@@@@@@@@@@@@@@@@%(,                                    ,(&@@@@@@@@@@@@@@@@&#. 
// #&@@@@@@@@@@@@@@@@&&/                                   .(%&@@@@@@@@@@@@@@@@&#. 
// #%@@@@@@@@@@@@@@@@@@(.               ,(/,.              .#&@@@@@@@@@@@@@@@@@&#. 
// (%@@@@@@@@@@@@@@@@@@#*.            ./%&&&/.            .*%@@@@@@@@@@@@@@@@@@%(. 
// (%@@@@@@@@@@@@@@@@@@#*.           *#&@@@@&%*.          .*%@@@@@@@@@@@@@@@@@@%(. 
// (%@@@@@@@@@@@@@@@@@@#/.         ./#@@@@@@@@%(.         ./%@@@@@@@@@@@@@@@@@@%(. 
// (%@@@@@@@@@@@@@@@@@@#/.        ./&@@@@@@@@@@&(*        ,/%@@@@@@@@@@@@@@@@@@%(. 
// (%@@@@@@@@@@@@@@@@@@%/.       ,#&@@@@@@@@@@@@&#,.      ,/%@@@@@@@@@@@@@@@@@@%(. 
// /%@@@@@@@@@@@@@@@@@@#/.      *(&@@@@@@@@@@@@@@&&*      ./%@@@@@@@@@@@@@@@@@&%(. 
// /%@@@@@@@@@@@@@@@@@@#/.     .(&@@@@@@@@@@@@@@@@@#*.    ,/%@@@@@@@@@@@@@@@@@&#/. 
// ,#@@@@@@@@@@@@@@@@@@#/.    ./%@@@@@@@@@@@@@@@@@@&#,    ,/%@@@@@@@@@@@@@@@@@&(,  
//  /%&@@@@@@@@@@@@@@@@#/.    *#&@@@@@@@@@@@@@@@@@@@&*    ,/%@@@@@@@@@@@@@@@@&%*   
//  .*#&@@@@@@@@@@@@@@@#/.    /&&@@@@@@@@@@@@@@@@@@@&/.   ,/%@@@@@@@@@@@@@@@@#*.   
//    ,(&@@@@@@@@@@@@@@#/.    /@@@@@@@@@@@@@@@@@@@@@&(,   ,/%@@@@@@@@@@@@@@%(,     
//     .*(&&@@@@@@@@@@@#/.    /&&@@@@@@@@@@@@@@@@@@@&/,   ,/%@@@@@@@@@@@&%/,       
//        ./%&@@@@@@@@@#/.    *#&@@@@@@@@@@@@@@@@@@@%*    ,/%@@@@@@@@@&%*          
//           ,/#%&&@@@@#/.     ,#&@@@@@@@@@@@@@@@@@#/.    ,/%@@@@&&%(/,            
//               ./#&@@%/.      ,/&@@@@@@@@@@@@@@%(,      ,/%@@%#*.                
//                   .,,,         ,/%&@@@@@@@@&%(*        .,,,.                    
//                                   ,/%&@@@%(*.                                   
//  .,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,**((/*,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,
//                                                                                                                                                                                                                                                                                                            
//                                                                                             

pragma solidity ^0.8.0;

/** @title Precompiled contract that exists in every Arbitrum chain at 0x0000000000000000000000000000000000000066.
* Allows registering / retrieving addresses at uint indices, saving calldata.
*/
interface IArbAddressTable {
    /**
    * @notice Register an address in the address table
    * @param addr address to register
    * @return index of the address (existing index, or newly created index if not already registered)
    */
    function register(address addr) external returns(uint);

    /**
    * @param addr address to lookup
    * @return index of an address in the address table (revert if address isn't in the table)
    */
    function lookup(address addr) external view returns(uint);

    /**
    * @notice Check whether an address exists in the address table
    * @param addr address to check for presence in table
    * @return true if address is in table
    */
    function addressExists(address addr) external view returns(bool);

    /**
    * @return size of address table (= first unused index)
     */
    function size() external view returns(uint);

    /**
    * @param index index to lookup address
    * @return address at a given index in address table (revert if index is beyond end of table)
    */
    function lookupIndex(uint index) external view returns(address);

    /**
    * @notice read a compressed address from a bytes buffer
    * @param buf bytes buffer containing an address
    * @param offset offset of target address
    * @return resulting address and updated offset into the buffer (revert if buffer is too short)
    */
    function decompress(bytes calldata buf, uint offset) external pure returns(address, uint);

    /**
    * @notice compress an address and return the result
    * @param addr address to compress
    * @return compressed address bytes
    */
    function compress(address addr) external returns(bytes memory);
}

// File: library/byte/BytesLib.sol



// MODIFIED VERSION FROM https://github.com/GNSPS/solidity-bytes-utils/blob/master/contracts/BytesLib.sol

pragma solidity >=0.8.0 <0.9.0;


library BytesLib {
    function concat(
        bytes memory _preBytes,
        bytes memory _postBytes
    )
        internal
        pure
        returns (bytes memory)
    {
        bytes memory tempBytes;

        assembly {
            // Get a location of some free memory and store it in tempBytes as
            // Solidity does for memory variables.
            tempBytes := mload(0x40)

            // Store the length of the first bytes array at the beginning of
            // the memory for tempBytes.
            let length := mload(_preBytes)
            mstore(tempBytes, length)

            // Maintain a memory counter for the current write location in the
            // temp bytes array by adding the 32 bytes for the array length to
            // the starting location.
            let mc := add(tempBytes, 0x20)
            // Stop copying when the memory counter reaches the length of the
            // first bytes array.
            let end := add(mc, length)

            for {
                // Initialize a copy counter to the start of the _preBytes data,
                // 32 bytes into its memory.
                let cc := add(_preBytes, 0x20)
            } lt(mc, end) {
                // Increase both counters by 32 bytes each iteration.
                mc := add(mc, 0x20)
                cc := add(cc, 0x20)
            } {
                // Write the _preBytes data into the tempBytes memory 32 bytes
                // at a time.
                mstore(mc, mload(cc))
            }

            // Add the length of _postBytes to the current length of tempBytes
            // and store it as the new length in the first 32 bytes of the
            // tempBytes memory.
            length := mload(_postBytes)
            mstore(tempBytes, add(length, mload(tempBytes)))

            // Move the memory counter back from a multiple of 0x20 to the
            // actual end of the _preBytes data.
            mc := end
            // Stop copying when the memory counter reaches the new combined
            // length of the arrays.
            end := add(mc, length)

            for {
                let cc := add(_postBytes, 0x20)
            } lt(mc, end) {
                mc := add(mc, 0x20)
                cc := add(cc, 0x20)
            } {
                mstore(mc, mload(cc))
            }

            // Update the free-memory pointer by padding our last write location
            // to 32 bytes: add 31 bytes to the end of tempBytes to move to the
            // next 32 byte block, then round down to the nearest multiple of
            // 32. If the sum of the length of the two arrays is zero then add
            // one before rounding down to leave a blank 32 bytes (the length block with 0).
            mstore(0x40, and(
              add(add(end, iszero(add(length, mload(_preBytes)))), 31),
              not(31) // Round down to the nearest 32 bytes.
            ))
        }

        return tempBytes;
    }

    function concatStorage(bytes storage _preBytes, bytes memory _postBytes) internal {
        assembly {
            // Read the first 32 bytes of _preBytes storage, which is the length
            // of the array. (We don't need to use the offset into the slot
            // because arrays use the entire slot.)
            let fslot := sload(_preBytes.slot)
            // Arrays of 31 bytes or less have an even value in their slot,
            // while longer arrays have an odd value. The actual length is
            // the slot divided by two for odd values, and the lowest order
            // byte divided by two for even values.
            // If the slot is even, bitwise and the slot with 255 and divide by
            // two to get the length. If the slot is odd, bitwise and the slot
            // with -1 and divide by two.
            let slength := div(and(fslot, sub(mul(0x100, iszero(and(fslot, 1))), 1)), 2)
            let mlength := mload(_postBytes)
            let newlength := add(slength, mlength)
            // slength can contain both the length and contents of the array
            // if length < 32 bytes so let's prepare for that
            // v. http://solidity.readthedocs.io/en/latest/miscellaneous.html#layout-of-state-variables-in-storage
            switch add(lt(slength, 32), lt(newlength, 32))
            case 2 {
                // Since the new array still fits in the slot, we just need to
                // update the contents of the slot.
                // uint256(bytes_storage) = uint256(bytes_storage) + uint256(bytes_memory) + new_length
                sstore(
                    _preBytes.slot,
                    // all the modifications to the slot are inside this
                    // next block
                    add(
                        // we can just add to the slot contents because the
                        // bytes we want to change are the LSBs
                        fslot,
                        add(
                            mul(
                                div(
                                    // load the bytes from memory
                                    mload(add(_postBytes, 0x20)),
                                    // zero all bytes to the right
                                    exp(0x100, sub(32, mlength))
                                ),
                                // and now shift left the number of bytes to
                                // leave space for the length in the slot
                                exp(0x100, sub(32, newlength))
                            ),
                            // increase length by the double of the memory
                            // bytes length
                            mul(mlength, 2)
                        )
                    )
                )
            }
            case 1 {
                // The stored value fits in the slot, but the combined value
                // will exceed it.
                // get the keccak hash to get the contents of the array
                mstore(0x0, _preBytes.slot)
                let sc := add(keccak256(0x0, 0x20), div(slength, 32))

                // save new length
                sstore(_preBytes.slot, add(mul(newlength, 2), 1))

                // The contents of the _postBytes array start 32 bytes into
                // the structure. Our first read should obtain the `submod`
                // bytes that can fit into the unused space in the last word
                // of the stored array. To get this, we read 32 bytes starting
                // from `submod`, so the data we read overlaps with the array
                // contents by `submod` bytes. Masking the lowest-order
                // `submod` bytes allows us to add that value directly to the
                // stored value.

                let submod := sub(32, slength)
                let mc := add(_postBytes, submod)
                let end := add(_postBytes, mlength)
                let mask := sub(exp(0x100, submod), 1)

                sstore(
                    sc,
                    add(
                        and(
                            fslot,
                            0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff00
                        ),
                        and(mload(mc), mask)
                    )
                )

                for {
                    mc := add(mc, 0x20)
                    sc := add(sc, 1)
                } lt(mc, end) {
                    sc := add(sc, 1)
                    mc := add(mc, 0x20)
                } {
                    sstore(sc, mload(mc))
                }

                mask := exp(0x100, sub(mc, end))

                sstore(sc, mul(div(mload(mc), mask), mask))
            }
            default {
                // get the keccak hash to get the contents of the array
                mstore(0x0, _preBytes.slot)
                // Start copying to the last used word of the stored array.
                let sc := add(keccak256(0x0, 0x20), div(slength, 32))

                // save new length
                sstore(_preBytes.slot, add(mul(newlength, 2), 1))

                // Copy over the first `submod` bytes of the new data as in
                // case 1 above.
                let slengthmod := mod(slength, 32)
                let mlengthmod := mod(mlength, 32)
                let submod := sub(32, slengthmod)
                let mc := add(_postBytes, submod)
                let end := add(_postBytes, mlength)
                let mask := sub(exp(0x100, submod), 1)

                sstore(sc, add(sload(sc), and(mload(mc), mask)))

                for {
                    sc := add(sc, 1)
                    mc := add(mc, 0x20)
                } lt(mc, end) {
                    sc := add(sc, 1)
                    mc := add(mc, 0x20)
                } {
                    sstore(sc, mload(mc))
                }

                mask := exp(0x100, sub(mc, end))

                sstore(sc, mul(div(mload(mc), mask), mask))
            }
        }
    }

    function slice(
        bytes memory _bytes,
        uint256 _start,
        uint256 _length
    )
        internal
        pure
        returns (bytes memory)
    {
        require(_length + 31 >= _length, "slice_overflow");
        require(_bytes.length >= _start + _length, "slice_outOfBounds");

        bytes memory tempBytes;

        assembly {
            switch iszero(_length)
            case 0 {
                // Get a location of some free memory and store it in tempBytes as
                // Solidity does for memory variables.
                tempBytes := mload(0x40)

                // The first word of the slice result is potentially a partial
                // word read from the original array. To read it, we calculate
                // the length of that partial word and start copying that many
                // bytes into the array. The first word we copy will start with
                // data we don't care about, but the last `lengthmod` bytes will
                // land at the beginning of the contents of the new array. When
                // we're done copying, we overwrite the full first word with
                // the actual length of the slice.
                let lengthmod := and(_length, 31)

                // The multiplication in the next line is necessary
                // because when slicing multiples of 32 bytes (lengthmod == 0)
                // the following copy loop was copying the origin's length
                // and then ending prematurely not copying everything it should.
                let mc := add(add(tempBytes, lengthmod), mul(0x20, iszero(lengthmod)))
                let end := add(mc, _length)

                for {
                    // The multiplication in the next line has the same exact purpose
                    // as the one above.
                    let cc := add(add(add(_bytes, lengthmod), mul(0x20, iszero(lengthmod))), _start)
                } lt(mc, end) {
                    mc := add(mc, 0x20)
                    cc := add(cc, 0x20)
                } {
                    mstore(mc, mload(cc))
                }

                mstore(tempBytes, _length)

                //update free-memory pointer
                //allocating the array padded to 32 bytes like the compiler does now
                mstore(0x40, and(add(mc, 31), not(31)))
            }
            //if we want a zero-length slice let's just return a zero-length array
            default {
                tempBytes := mload(0x40)
                //zero out the 32 bytes slice we are about to return
                //we need to do it because Solidity does not garbage collect
                mstore(tempBytes, 0)

                mstore(0x40, add(tempBytes, 0x20))
            }
        }

        return tempBytes;
    }

    function toAddress(bytes memory _bytes, uint256 _start) internal pure returns (address) {
        require(_bytes.length >= _start + 20, "toAddress_outOfBounds");
        address tempAddress;

        assembly {
            tempAddress := div(mload(add(add(_bytes, 0x20), _start)), 0x1000000000000000000000000)
        }

        return tempAddress;
    }

    function toUint8(bytes memory _bytes, uint256 _start) internal pure returns (uint8) {
        require(_bytes.length >= _start + 1 , "toUint8_outOfBounds");
        uint8 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x1), _start))
        }

        return tempUint;
    }

    function toUint16(bytes memory _bytes, uint256 _start) internal pure returns (uint16) {
        require(_bytes.length >= _start + 2, "toUint16_outOfBounds");
        uint16 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x2), _start))
        }

        return tempUint;
    }
    
    function toUint24(bytes memory _bytes, uint256 _start) internal pure returns (uint24) {
        require(_bytes.length >= _start + 3, "toUint24_outOfBounds");
        uint24 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x3), _start))
        }

        return tempUint;
    }

    function toUint32(bytes memory _bytes, uint256 _start) internal pure returns (uint32) {
        require(_bytes.length >= _start + 4, "toUint32_outOfBounds");
        uint32 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x4), _start))
        }

        return tempUint;
    }

    function toUint64(bytes memory _bytes, uint256 _start) internal pure returns (uint64) {
        require(_bytes.length >= _start + 8, "toUint64_outOfBounds");
        uint64 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x8), _start))
        }

        return tempUint;
    }
    
    function toUint80(bytes memory _bytes, uint256 _start) internal pure returns (uint80) {
        require(_bytes.length >= _start + 10, "toUint80_outOfBounds");
        uint80 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0xa), _start))
        }

        return tempUint;
    }

    function toUint96(bytes memory _bytes, uint256 _start) internal pure returns (uint96) {
        require(_bytes.length >= _start + 12, "toUint96_outOfBounds");
        uint96 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0xc), _start))
        }

        return tempUint;
    }
    
    function toUint112(bytes memory _bytes, uint256 _start) internal pure returns (uint112) {
        require(_bytes.length >= _start + 14, "toUint112_outOfBounds");
        uint112 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0xe), _start))
        }

        return tempUint;
    }

    function toUint128(bytes memory _bytes, uint256 _start) internal pure returns (uint128) {
        require(_bytes.length >= _start + 16, "toUint128_outOfBounds");
        uint128 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x10), _start))
        }

        return tempUint;
    }

    function toUint256(bytes memory _bytes, uint256 _start) internal pure returns (uint256) {
        require(_bytes.length >= _start + 32, "toUint256_outOfBounds");
        uint256 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x20), _start))
        }

        return tempUint;
    }

    function toBytes32(bytes memory _bytes, uint256 _start) internal pure returns (bytes32) {
        require(_bytes.length >= _start + 32, "toBytes32_outOfBounds");
        bytes32 tempBytes32;

        assembly {
            tempBytes32 := mload(add(add(_bytes, 0x20), _start))
        }

        return tempBytes32;
    }

    function equal(bytes memory _preBytes, bytes memory _postBytes) internal pure returns (bool) {
        bool success = true;

        assembly {
            let length := mload(_preBytes)

            // if lengths don't match the arrays are not equal
            switch eq(length, mload(_postBytes))
            case 1 {
                // cb is a circuit breaker in the for loop since there's
                //  no said feature for inline assembly loops
                // cb = 1 - don't breaker
                // cb = 0 - break
                let cb := 1

                let mc := add(_preBytes, 0x20)
                let end := add(mc, length)

                for {
                    let cc := add(_postBytes, 0x20)
                // the next line is the loop condition:
                // while(uint256(mc < end) + cb == 2)
                } eq(add(lt(mc, end), cb), 2) {
                    mc := add(mc, 0x20)
                    cc := add(cc, 0x20)
                } {
                    // if any of these checks fails then arrays are not equal
                    if iszero(eq(mload(mc), mload(cc))) {
                        // unsuccess:
                        success := 0
                        cb := 0
                    }
                }
            }
            default {
                // unsuccess:
                success := 0
            }
        }

        return success;
    }

    function equalStorage(
        bytes storage _preBytes,
        bytes memory _postBytes
    )
        internal
        view
        returns (bool)
    {
        bool success = true;

        assembly {
            // we know _preBytes_offset is 0
            let fslot := sload(_preBytes.slot)
            // Decode the length of the stored array like in concatStorage().
            let slength := div(and(fslot, sub(mul(0x100, iszero(and(fslot, 1))), 1)), 2)
            let mlength := mload(_postBytes)

            // if lengths don't match the arrays are not equal
            switch eq(slength, mlength)
            case 1 {
                // slength can contain both the length and contents of the array
                // if length < 32 bytes so let's prepare for that
                // v. http://solidity.readthedocs.io/en/latest/miscellaneous.html#layout-of-state-variables-in-storage
                if iszero(iszero(slength)) {
                    switch lt(slength, 32)
                    case 1 {
                        // blank the last byte which is the length
                        fslot := mul(div(fslot, 0x100), 0x100)

                        if iszero(eq(fslot, mload(add(_postBytes, 0x20)))) {
                            // unsuccess:
                            success := 0
                        }
                    }
                    default {
                        // cb is a circuit breaker in the for loop since there's
                        //  no said feature for inline assembly loops
                        // cb = 1 - don't breaker
                        // cb = 0 - break
                        let cb := 1

                        // get the keccak hash to get the contents of the array
                        mstore(0x0, _preBytes.slot)
                        let sc := keccak256(0x0, 0x20)

                        let mc := add(_postBytes, 0x20)
                        let end := add(mc, mlength)

                        // the next line is the loop condition:
                        // while(uint256(mc < end) + cb == 2)
                        for {} eq(add(lt(mc, end), cb), 2) {
                            sc := add(sc, 1)
                            mc := add(mc, 0x20)
                        } {
                            if iszero(eq(sload(sc), mload(mc))) {
                                // unsuccess:
                                success := 0
                                cb := 0
                            }
                        }
                    }
                }
            }
            default {
                // unsuccess:
                success := 0
            }
        }

        return success;
    }
}

// File: wx/libraries/WardenDataDeserialize.sol

// License: BSD-3-Clause
// Copyright 2021 Wardenswap.finance.
// Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
// 1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
// 2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
// 3. Neither the name of the copyright holder nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

pragma solidity ^0.8.0;

contract WardenDataDeserialize {
    using BytesLib for bytes;

    IArbAddressTable internal immutable addressTable;
    
    constructor(
        IArbAddressTable _addressTable
    ) {
        addressTable = _addressTable;
    }
    
    function toBytes(bytes32 _data) private pure returns (bytes memory) {
        return abi.encodePacked(_data);
    }

    function _decodeCompressed(
        bytes memory _data,
        uint256 _cursor,
        bool skipLearnedId
    )
        private
        pure
        returns(
            uint256 _srcIndex, // 24-bit, 16,777,216 possible
            uint256 _destIndex, // 24-bit, 16,777,216 possible
            uint256 _srcAmount, // 96-bit, 79,228,162,514 (18 decimals)
            uint256 _minDestAmount, // 96-bit, 79,228,162,514 (18 decimals)
            uint256 _learnedId, // 16-bit, 65,536 possible
            uint256 _newCursor
        )
    {
        // Example
        // 0x000001000002FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
        // 0x000001000002000000000000000000000001FFFFFFFFFFFFFFFFFFFFFFFFFFFF
        // 0x0000010000020000007CAEE97613E670000100000000B469471F801400021123
        // uint256: _srcIndex 1
        // uint256: _destIndex 2
        // uint256: _srcAmount 2300000000000000000001
        // uint256: _minDestAmount 13000000000000000002
        // uint256: _learnedId 4387
        // uint256: _newCursor 32
        
        _srcIndex = _data.toUint24(_cursor);
        _cursor += 3;
        
        _destIndex = _data.toUint24(_cursor);
        _cursor += 3;
        
        _srcAmount = _data.toUint96(_cursor);
        _cursor += 12;
        
        _minDestAmount = _data.toUint96(_cursor);
        _cursor += 12;
        
        if (!skipLearnedId) {
            _learnedId = _data.toUint16(_cursor);
            _cursor += 2;
        }
        
        _newCursor = _cursor;
    }
    
    function decodeCompressed1(
        bytes32 _data
    )
        public
        view
        returns (
            address _src,
            address _dest,
            uint256 _srcAmount,
            uint256 _minDestAmount,
            uint256 _learnedId
        )
    {
        bytes memory data = toBytes(_data);

        uint256 srcIndex;
        uint256 destIndex;
        (
            srcIndex,
            destIndex,
            _srcAmount,
            _minDestAmount,
            _learnedId,
            
        ) = _decodeCompressed(data, 0, false);
        
        // tokenLookup
        _src = addressTable.lookupIndex(srcIndex);
        _dest = addressTable.lookupIndex(destIndex);
    }
    
    function decodeCompressed2(
        bytes memory _data,
        uint256 _cursor
    )
        public
        view
        returns (
            address _src,
            address _dest,
            uint256 _srcAmount,
            uint256 _minDestAmount,
            uint256 _newCursor
        )
    {
        uint256 srcIndex;
        uint256 destIndex;
        (
            srcIndex,
            destIndex,
            _srcAmount,
            _minDestAmount,
            ,
            _newCursor
        ) = _decodeCompressed(_data, _cursor, true);
        
        // tokenLookup
        _src = addressTable.lookupIndex(srcIndex);
        _dest = addressTable.lookupIndex(destIndex);
    }
    
    function _decodeSrcMinAmountsLearnedId(
        bytes memory _data,
        uint256 _cursor,
        bool skipLearnedId
    )
        private
        pure
        returns (
            uint256 _srcAmount,
            uint256 _minDestAmount,
            uint256 _learnedId,
            uint256 _newCursor
        )
    {
        // 8-bit insructions
        // 2-bit for srcAmount insruction
        // 2-bit for minDestAmount insruction
        // 1-bit for learnedId insruction
        
        // Example
        // instructions: 00010101
        // _data: 15 10000000000000000001 10000000000000000002 100001
        // _data: 0x151000000000000000000110000000000000000002100001
        //
        // instructions: 00001100
        // _data: 0C 1000000000000001 1000000000000000000000000001 1001
        // _data: 0x0C100000000000000110000000000000000000000000011001
        //
        // instructions: 00001100
        // skipLearnedId: true
        // _data: 0C 1000000000000001 1000000000000000000000000001
        // _data: 0x0C10000000000000011000000000000000000000000001
        
        
        uint8 instructions = _data.toUint8(_cursor);
        _cursor += 1;
        
        uint8 srcAmountInstruction = instructions & 0x03;
        instructions = instructions >> 2;
        (_srcAmount, _cursor) = _decodeAmount(srcAmountInstruction, _data, _cursor);
        
        uint8 minDestAmountInstruction = instructions & 0x03;
        instructions = instructions >> 2;
        (_minDestAmount, _cursor) = _decodeAmount(minDestAmountInstruction, _data, _cursor);
        
        if (!skipLearnedId) {
            uint8 learnedIdInstruction = instructions & 0x01;
            instructions = instructions >> 1;
            (_learnedId, _cursor) = _decodeLearnedId(learnedIdInstruction, _data, _cursor);
        }
        
        _newCursor = _cursor;
    }
    
    function decodeSrcMinAmountsLearnedId(
        bytes memory _data,
        uint256 _cursor
    )
        public
        pure
        returns (
            uint256 _srcAmount,
            uint256 _minDestAmount,
            uint256 _learnedId,
            uint256 _newCursor
        )
    {
        (
            _srcAmount,
            _minDestAmount,
            _learnedId,
            _newCursor
        ) = _decodeSrcMinAmountsLearnedId(_data, _cursor, false);
    }
    
    function decodeSrcMinAmounts(
        bytes memory _data,
        uint256 _cursor
    )
        public
        pure
        returns (
            uint256 _srcAmount,
            uint256 _minDestAmount,
            uint256 _newCursor
        )
    {
        (
            _srcAmount,
            _minDestAmount,
            ,
            _newCursor
        ) = _decodeSrcMinAmountsLearnedId(_data, _cursor, true);
    }
    
    function decodeSubRoutesAndCorrespondentTokens(
        bytes memory _data,
        uint256 _cursor
    )
        public
        view
        returns (
            uint256[]   memory _subRoutes, // 16-bit, 65,536 possible
            IERC20[]    memory _correspondentTokens,
            uint256            _newCursor
        )
    {
        // 8-bit insructions
        // 6-bit route length, 64 possible
        // 2-bit token instruction
        
        // Example
        //
        // 0x010001 [1]
        // 0x8200010002000001 [1,2], [token(1)]
        // 0x431001200130010000000100000002 [4097,8193,12289] [token(1), token(2)]
        //
        // instructions: 00000001
        // _data: 01 1001
        // _data: 0x011001
        //
        // instructions: 10000010
        // _data: 82 0001 0002 000001
        // _data: 0x8200010002000001
        //
        // instructions: 01000011
        // _data: 43 1001 2001 3001 00000001 00000002
        // _data: 0x431001200130010000000100000002
        //
        // instructions: 00000011
        // _data: 03 0002 0003 0004 c02aaa39b223fe8d0a0e5c4f27ead9083c756cc2 a0b86991c6218b36c1d19d4a2e9eb0ce3606eb48
        // _data: 0x03000200030004c02aaa39b223fe8d0a0e5c4f27ead9083c756cc2a0b86991c6218b36c1d19d4a2e9eb0ce3606eb48
        
        uint8 instructions = _data.toUint8(_cursor);
        _cursor += 1;
        
        uint256 routeLength = instructions & 0x3F;
        instructions = instructions >> 6;
        
        uint8 tokenInstruction = instructions & 0x03;
        instructions = instructions >> 2;
        
        _subRoutes = new uint256[](routeLength);
        _correspondentTokens = new IERC20[](routeLength - 1);
        
        for (uint256 i = 0; i < routeLength; i++) {
            _subRoutes[i] = _data.toUint16(_cursor);
            _cursor += 2;
        }
        
        for (uint256 i = 0; i < routeLength - 1; i++) {
            address token;
            (token, _cursor) = _lookupAddress(tokenInstruction, _data, _cursor);
            _correspondentTokens[i] = IERC20(token);
        }
        _newCursor = _cursor;
    }
    
    function decodeLearnedIdsAndVolumns(
        bytes memory _data,
        uint256 _cursor
    )
        public
        pure
        returns (
            uint256[]   memory _learnedIds,
            uint256[]   memory _volumns, // 8-bit, 256 possible
            uint256            _newCursor
        )
    {
        // 8-bit insructions
        // 6-bit split length, 64 possible
        // 1-bit learned id instruction
        
        // Example
        // instructions: 00000010
        // _data: 02 1003 2004 3C
        // _data: 0x02100320043C
        //
        // instructions: 01000011
        // _data: 43 100003 200004 300005 1E 19
        // _data: 0x431000032000043000051E19
        
        uint8 instructions = _data.toUint8(_cursor);
        _cursor += 1;
        
        uint256 splitLength = instructions & 0x3F;
        instructions = instructions >> 6;
        
        uint8 learnedIdInstruction = instructions & 0x01;
        instructions = instructions >> 1;

        
        // Decode learn ids
        _learnedIds = new uint256[](splitLength);
        for (uint256 i = 0; i < splitLength; i++) {
            (_learnedIds[i], _cursor) = _decodeLearnedId(learnedIdInstruction, _data, _cursor);
        }
        
        // Each volumn has 8-bit
        _volumns = new uint256[](splitLength);
        uint256 volumnRemain = 100;
        for (uint256 i = 0; i < splitLength - 1; i++) {
            _volumns[i] = _data.toUint8(_cursor);
            _cursor += 1;
            volumnRemain -= _volumns[i];
        }
        _volumns[splitLength - 1] = volumnRemain;

        _newCursor = _cursor;
    }
    
    function _lookupAddress(
        uint8 _instruction, // 2-bit instruction
        bytes memory _data,
        uint256 _cursor
    )
        private
        view
        returns (
            address _address,
            uint256 _newCursor
        )
    {
        // Example
        // instruction: 0
        // _data: 0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2
        //
        // instruction: 1
        // _data: 0x00000001
        //
        // instruction: 2
        // _data: 0x000001
        //
        // instruction: 3
        // _data: 0x
        
        if (_instruction == 0) { // not registered
            _address =  _data.toAddress(_cursor);
            _newCursor = _cursor + 20;
            
        } else if (_instruction == 1) { // registered (32-bit)
            _address = addressTable.lookupIndex(_data.toUint32(_cursor));
            _newCursor = _cursor + 4;

        } else if (_instruction == 2) { // registered (24-bit)
            _address = addressTable.lookupIndex(_data.toUint24(_cursor));
            _newCursor = _cursor + 3;

        } else if (_instruction == 3) { // skip
            _address = 0x0000000000000000000000000000000000000000;
            _newCursor = _cursor;
            
        } else {
            revert("WardenDataDeserialize:_lookupAddress bad instruction");
        }
    }

    function lookupSrcDestReceiverAddresses(
        bytes memory _data,
        uint256 _cursor
    )
        public
        view
        returns (
            address _src,
            address _dest,
            address _receiver,
            uint256 _newCursor
        )
    {
        // 8-bit insructions
        // 2-bit for _src insruction
        // 2-bit for _dest insruction
        // 2-bit for _receiver insruction
        
        // Example
        // instructions: 00111001
        // _data: 39 00000001 000003
        // _data: 0x3900000001000003
        //
        // instructions: 00001000
        // _data: 08 c02aaa39b223fe8d0a0e5c4f27ead9083c756cc2 000004 5e12Ae8e436Cd25F0041d931f8E4c7a3bB42cc1F
        // _data: 0x08c02aaa39b223fe8d0a0e5c4f27ead9083c756cc20000045e12Ae8e436Cd25F0041d931f8E4c7a3bB42cc1F
        //
        // instructions: 00110001
        // _data: 31 00000003 2260fac5e5542a773aa44fbcfedf7c193bc2c599
        // _data: 0x31000000032260fac5e5542a773aa44fbcfedf7c193bc2c599
        //
        
        uint8 instructions = _data.toUint8(_cursor);
        _cursor += 1;
        
        uint8 srcInstruction = instructions & 0x03;
        instructions = instructions >> 2;
        
        uint8 destInstruction = instructions & 0x03;
        instructions = instructions >> 2;
        
        uint8 receiverInstruction = instructions & 0x03;
        instructions = instructions >> 2;
        
        (_src, _cursor) = _lookupAddress(srcInstruction, _data, _cursor);
        (_dest, _cursor) = _lookupAddress(destInstruction, _data, _cursor);
        (_receiver, _cursor) = _lookupAddress(receiverInstruction, _data, _cursor);
        _newCursor = _cursor;
    }
    
    function _decodeAmount(
        uint8 _instruction, // 2-bit instruction
        bytes memory _data,
        uint256 _cursor
    )
        private
        pure
        returns (
            uint256 _amount,
            uint256 _newCursor
        )
    {
        // Example
        // instruction: 0
        // _data: 0x1000000000000001
        //
        // instruction: 1
        // _data: 0x10000000000000000001
        //
        // instruction: 2
        // _data: 0x100000000000000000000001
        //
        // instruction: 3
        // _data: 0x1000000000000000000000000001
        
        if (_instruction == 0) { // 64-bit, 18 (denominated in 1e18)
            _amount = _data.toUint64(_cursor);
            _newCursor = _cursor + 8;
            
        } else if (_instruction == 1) { // 80-bit, 1.2m (denominated in 1e18)
            _amount = _data.toUint80(_cursor);
            _newCursor = _cursor + 10;

        } else if (_instruction == 2) { // 96-bit, 79.2b (denominated in 1e18)
            _amount = _data.toUint96(_cursor);
            _newCursor = _cursor + 12;

        } else if (_instruction == 3) { // 112-bit, 5,192mm (denominated in 1e18)
            _amount = _data.toUint112(_cursor);
            _newCursor = _cursor + 14;
            
        } else {
            revert("WardenDataDeserialize:_decodeAmount bad instruction");
        }
    }
    
    function _decodeLearnedId(
        uint8 _instruction, // 1-bit instruction
        bytes memory _data,
        uint256 _cursor
    )
        private
        pure
        returns (
            uint256 _learnedId,
            uint256 _newCursor
        )
    {
        // Example
        // instruction: 0
        // _data: 0x1001
        //
        // instruction: 1
        // _data: 0x100001

        if (_instruction == 0) { // 16-bit, 65,536 possible
            _learnedId = _data.toUint16(_cursor);
            _newCursor = _cursor + 2;
            
        } else if (_instruction == 1) { // 24-bit, 16,777,216 possible
            _learnedId = _data.toUint24(_cursor);
            _newCursor = _cursor + 3;

        } else {
            revert("WardenDataDeserialize:_decodeLearnedId bad instruction");
        }
    }
}

// File: wx/interface/IWardenPostTrade.sol
// License: MIT

pragma solidity ^0.8.0;


interface IWardenPostTrade {
    function postTradeAndFee(
        IERC20      _src,
        IERC20      _dest,
        uint256     _srcAmount,
        uint256     _destAmount,
        address     _trader,
        address     _receiver,
        bool        _isSplit
    )
        external
        returns (
            uint256 _fee,
            address _collector
        );
}

// File: wx/libraries/IWETH.sol



pragma solidity ^0.8.0;


interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
}

// File: wx/interface/IWardenCosmicBrainForL2.sol

pragma solidity ^0.8.0;


interface IWardenCosmicBrain {
    function train(
        uint256[]   calldata _subRoutes,
        IERC20[]    calldata _correspondentTokens
    )
        external
        returns (uint256 _learnedId);
    
    function trainTradingPair(
        IERC20      _src,
        IERC20      _dest,
        uint256     _srcAmount,
        uint256     _destAmount,
        uint256     _learnedId
    )
        external
        returns (bool _isAlreadyLearned);
    
    function learnedHashes(
        uint256 _learnedId
    )
        external
        view
        returns (bytes32);
    
    function fetchRoutesAndTokens(
        bytes32 _learnedHash
    )
        external
        view
        returns (
            uint256[]   memory _subRoutes,
            IERC20[]    memory _correspondentTokens
        );

    function hasLearned(
        bytes32 _learnedHash
    )
        external
        view
        returns (bool);

    function learnedIds(
        bytes32 _learnedHash
    )
        external
        view
        returns (uint256);

    function learnedRoutesLength(
        bytes32 _learnedHash
    )
        external
        view
        returns (uint256);
}

// File: wx/libraries/IWardenTradingRoute0_8.sol


pragma solidity ^0.8.0;


/**
 * @title Warden Trading Route
 * @dev The Warden trading route interface has an standard functions and event
 * for other smart contract to implement to join Warden Swap as Market Maker.
 */
interface IWardenTradingRoute {
    /**
    * @dev when new trade occure (and success), this event will be boardcast.
    * @param _src Source token
    * @param _srcAmount amount of source tokens
    * @param _dest   Destination token
    * @param _destAmount: amount of actual destination tokens
    */
    event Trade(
        IERC20 indexed _src,
        uint256 _srcAmount,
        IERC20 indexed _dest,
        uint256 _destAmount
    );

    /**
    * @notice use token address 0xeee...eee for ether
    * @dev makes a trade between src and dest token
    * @param _src Source token
    * @param _dest   Destination token
    * @param _srcAmount amount of source tokens
    ** @return _destAmount: amount of actual destination tokens
    */
    function trade(
        IERC20 _src,
        IERC20 _dest,
        uint256 _srcAmount,
        address receiver
    )
        external
        payable
        returns(uint256 _destAmount);

    /**
    * @dev provide destinationm token amount for given source amount
    * @param _src Source token
    * @param _dest Destination token
    * @param _srcAmount Amount of source tokens
    ** @return _destAmount: amount of expected destination tokens
    */
    function getDestinationReturnAmount(
        IERC20 _src,
        IERC20 _dest,
        uint256 _srcAmount
    )
        external
        returns(uint256 _destAmount);

    function getDepositAddress(
        IERC20 _src,
        IERC20 _dest
    )
        external
        view
        returns(address _target);
}

// File: wx/interface/IWardenCosmoCore0_8.sol


pragma solidity ^0.8.0;


interface IWardenCosmoCore {
    /**
    * @dev Struct of trading route
    * @param name Name of trading route.
    * @param enable The flag of trading route to check is trading route enable.
    * @param route The address of trading route.
    */
    struct Route {
      string name;
      bool enable;
      IWardenTradingRoute route;
    }

    event AddedTradingRoute(
        address indexed addedBy,
        string name,
        IWardenTradingRoute indexed routingAddress,
        uint256 indexed index
    );
    
    event UpdatedTradingRoute(
        address indexed updatedBy,
        string name,
        IWardenTradingRoute indexed routingAddress,
        uint256 indexed index
    );

    event EnabledTradingRoute(
        address indexed enabledBy,
        string name,
        IWardenTradingRoute indexed routingAddress,
        uint256 indexed index
    );

    event DisabledTradingRoute(
        address indexed disabledBy,
        string name,
        IWardenTradingRoute indexed routingAddress,
        uint256 indexed index
    );
    
    function tradingRoutes(uint256 _index) external view returns (Route memory);
    function allRoutesLength() external view returns (uint256);
    function isTradingRouteEnabled(uint256 _index) external view returns (bool);
}

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.2.0/contracts/utils/Address.sol



pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.2.0/contracts/token/ERC20/IERC20.sol



pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.2.0/contracts/token/ERC20/utils/SafeERC20.sol



pragma solidity ^0.8.0;



/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.2.0/contracts/utils/Context.sol



pragma solidity ^0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.2.0/contracts/access/Ownable.sol



pragma solidity ^0.8.0;


/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.2.0/contracts/security/ReentrancyGuard.sol



pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// File: wx/WardenSwap1_5_L2.sol

pragma solidity ^0.8.0;









contract WardenSwap1_5_Aegis is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;
    
    IWardenCosmoCore public cosmoCore;
    IWardenCosmicBrain public cosmicBrain;
    IWardenPostTrade public postTrade;

    IWETH private immutable weth;
    IERC20 private constant ETHER_ERC20 = IERC20(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);
    
    event UpdatedWardenCosmoCore(
        IWardenCosmoCore indexed cosmoCore
    );
    
    event UpdatedWardenCosmicBrain(
        IWardenCosmicBrain indexed cosmicBrain
    );
    
    event UpdatedWardenPostTrade(
        IWardenPostTrade indexed postTrade
    );
    
    /**
    * @dev when new trade occur (and success), this event will be boardcast.
    * @param srcAsset Source token
    * @param srcAmount amount of source token
    * @param destAsset Destination token
    * @param destAmount amount of destination token
    * @param trader user address
    */
    event Trade(
        address indexed srcAsset, // Source
        uint256         srcAmount,
        address indexed destAsset, // Destination
        uint256         destAmount,
        address indexed trader, // User
        address         receiver, // User / Merchant
        bool            cacheHit,
        bool            hasSplitted
    );
    
    event CollectFee(
      IERC20  indexed   token,
      address indexed   wallet,
      uint256           amount
    );
    
    constructor(
        IWardenCosmoCore _cosmoCore,
        IWardenCosmicBrain _cosmicBrain,
        IWardenPostTrade _postTrade,
        IWETH _weth
    ) {
        cosmoCore = _cosmoCore;
        cosmicBrain = _cosmicBrain;
        postTrade = _postTrade;
        weth = _weth;
        
        emit UpdatedWardenCosmoCore(_cosmoCore);
        emit UpdatedWardenCosmicBrain(_cosmicBrain);
        emit UpdatedWardenPostTrade(_postTrade);
    }
    
    function updateRoutingManagement(
        IWardenCosmoCore _cosmoCore
    )
        external
        onlyOwner
    {
        cosmoCore = _cosmoCore;
        emit UpdatedWardenCosmoCore(_cosmoCore);
    }
    
    function updateWardenLearner(
        IWardenCosmicBrain _cosmicBrain
    )
        external
        onlyOwner
    {
        cosmicBrain = _cosmicBrain;
        emit UpdatedWardenCosmicBrain(_cosmicBrain);
    }
    
    function updateWardenPostTrade(
        IWardenPostTrade _postTrade
    )
        external
        onlyOwner
    {
        postTrade = _postTrade;
        emit UpdatedWardenPostTrade(_postTrade);
    }

    /**
    * @dev makes a trade between token to token by tradingRouteIndex
    * @param tradingRouteIndex index of trading route
    * @param src Source token
    * @param srcAmount amount of source tokens
    * @param dest Destination token
    * @param fromAddress address of trader
    * @param toAddress destination address
    * @return amount of actual destination tokens
    */
    function _tradeTokenToToken(
        uint256 tradingRouteIndex,
        IERC20 src,
        uint256 srcAmount,
        IERC20 dest,
        address fromAddress,
        address toAddress
    )
        private
        returns(uint256)
    {
        // Load trading route
        IWardenTradingRoute tradingRoute = cosmoCore.tradingRoutes(tradingRouteIndex).route;
        
        // Deposit to target
        address depositAddress = tradingRoute.getDepositAddress(src, dest);
        if (fromAddress == address(this)) {
            src.safeTransfer(depositAddress, srcAmount);
        } else if (fromAddress != 0x0000000000000000000000000000000000000000) {
            src.safeTransferFrom(fromAddress, depositAddress, srcAmount);
        }

        // Trade to route
        uint256 destAmount = tradingRoute.trade(
            src,
            dest,
            srcAmount,
            toAddress
        );
        return destAmount;
    }
    
    function _tradeStrategies(
        IERC20      _src,
        uint256     _srcAmount,
        IERC20      _dest,
        uint256[]   memory _subRoutes,
        IERC20[]    memory _correspondentTokens,
        address     _fromAddress
    )
        private
        returns(uint256 _destAmount)
    {
        IERC20 src;
        IERC20 dest;
        _destAmount = _srcAmount;
        uint256 routersLen = _subRoutes.length;
        for (uint i = 0; i < routersLen; i++) {
            src = i == 0 ? _src : _correspondentTokens[i - 1];
            dest = i == routersLen - 1 ? _dest : _correspondentTokens[i];
            
            uint256 routeIndex = _subRoutes[i];
            address fromAddress = i == 0 ? _fromAddress : 0x0000000000000000000000000000000000000000;
            address toAddress;
            
            // Advanced fetching next market address
            if (i == routersLen - 1) {
                toAddress = address(this);
            } else {
                IWardenTradingRoute tradingRoute = cosmoCore.tradingRoutes(_subRoutes[i + 1]).route;
                IERC20 nextDest = i + 1 == routersLen - 1 ? _dest : _correspondentTokens[i + 1];
                toAddress = tradingRoute.getDepositAddress(dest, nextDest);
            }

            _destAmount = _tradeTokenToToken(routeIndex, src, _destAmount, dest, fromAddress, toAddress);
        }
    }
    
    /**
    * @dev makes a trade by providing trading strategy
    * @param _src Source token
    * @param _srcAmount amount of source tokens
    * @param _dest Destination token
    * @param _minDestAmount minimum of destination token amount
    * @param _subRoutes trading routers
    * @param _correspondentTokens intermediate tokens
    * @param _receiver receiver address
    * @param _learnedId previous learning id
    * @return _destAmount amount of actual destination tokens
    */
    function _tradeStrategiesWithSafeGuard(
        IERC20      _src,
        uint256     _srcAmount,
        IERC20      _dest,
        uint256     _minDestAmount,
        uint256[]   memory _subRoutes,
        IERC20[]    memory _correspondentTokens,
        address     _receiver,
        uint256     _learnedId
    )
        private
        returns(uint256 _destAmount)
    {
        require(_subRoutes.length - 1 == _correspondentTokens.length, "WardenSwap: routes and tokens length mismatched");
        {
            IERC20 adjustedSrc;
            IERC20 adjustedDest = ETHER_ERC20 == _dest ? IERC20(address(weth)) : _dest;
            address fromAddress;
            
            // Wrap ETH
            if (ETHER_ERC20 == _src) {
                require(msg.value == _srcAmount, "WardenSwap: Ether source amount mismatched");
                weth.deposit{value: _srcAmount}();
                
                adjustedSrc = IERC20(address(weth));
                fromAddress = address(this);
            } else {
                adjustedSrc = _src;
                fromAddress = msg.sender;
            }
        
            // Record src/dest asset for later consistency check.
            uint256 srcAmountBefore = adjustedSrc.balanceOf(fromAddress);
            uint256 destAmountBefore = adjustedDest.balanceOf(address(this));
            
            _destAmount = _tradeStrategies(
                adjustedSrc,
                _srcAmount,
                adjustedDest,
                _subRoutes,
                _correspondentTokens,
                fromAddress
            );
            
            // Sanity check
            // Recheck if src/dest amount correct
            require(adjustedSrc.balanceOf(fromAddress) == srcAmountBefore - _srcAmount, "WardenSwap: source amount mismatched after trade");
            require(adjustedDest.balanceOf(address(this)) == destAmountBefore + _destAmount, "WardenSwap: destination amount mismatched after trade");
        }

        
        // Unwrap ETH
        if (ETHER_ERC20 == _dest) {
            weth.withdraw(_destAmount);
        }
        
        // Collect fee
        _destAmount = _postTradeAndCollectFee(
            _src,
            _dest,
            _srcAmount,
            _destAmount,
            msg.sender,
            _receiver,
            false
        );

        // Throw exception if destination amount doesn't meet user requirement.
        require(_destAmount >= _minDestAmount, "WardenSwap: destination amount is too low.");
        if (ETHER_ERC20 == _dest) {
            (bool success, ) = _receiver.call{value: _destAmount}(""); // Send back ether to sender
            require(success, "WardenSwap: Transfer ether back to caller failed.");
        } else { // Send back token to sender
            _dest.safeTransfer(_receiver, _destAmount);
        }
        
        uint256 learnedId = _learnedId;
        if (0 == _learnedId) {
            learnedId = cosmicBrain.train(_subRoutes, _correspondentTokens);
        }
        cosmicBrain.trainTradingPair(
            _src,
            _dest,
            _srcAmount,
            _destAmount,
            learnedId
        );

        emit Trade(address(_src), _srcAmount, address(_dest), _destAmount, msg.sender, _receiver, 0 != _learnedId, false);
    }
    
    /**
    * @dev makes a trade by providing trading strategy
    * @param _src Source token
    * @param _srcAmount amount of source tokens
    * @param _dest Destination token
    * @param _minDestAmount minimum of destination token amount
    * @param _subRoutes trading routers
    * @param _correspondentTokens intermediate tokens
    * @param _receiver receiver address
    * @return _destAmount amount of actual destination tokens
    */
    function tradeStrategies(
        IERC20      _src,
        uint256     _srcAmount,
        IERC20      _dest,
        uint256     _minDestAmount,
        uint256[]   memory _subRoutes,
        IERC20[]    memory _correspondentTokens,
        address     _receiver
    )
        public
        payable
        nonReentrant
        returns(uint256 _destAmount)
    {
        _destAmount = _tradeStrategiesWithSafeGuard(
            _src,
            _srcAmount,
            _dest,
            _minDestAmount,
            _subRoutes,
            _correspondentTokens,
            _receiver,
            0
        );
    }
    
    /**
    * @dev makes a trade by providing learned id
    * @param _src Source token
    * @param _srcAmount amount of source tokens
    * @param _dest Destination token
    * @param _minDestAmount minimum of destination token amount
    * @param _learnedId unique id
    * @param _receiver receiver address
    * @return _destAmount amount of actual destination tokens
    */
    function tradeWithLearned(
        IERC20    _src,
        uint256   _srcAmount,
        IERC20    _dest,
        uint256   _minDestAmount,
        uint256   _learnedId,
        address   _receiver
    )
        public
        payable
        nonReentrant
        returns(uint256 _destAmount)
    {
        bytes32 learnedHash = cosmicBrain.learnedHashes(_learnedId);
        
        (
            uint256[]   memory subRoutes,
            IERC20[]    memory correspondentTokens
        ) = cosmicBrain.fetchRoutesAndTokens(learnedHash);
        
        _destAmount = _tradeStrategiesWithSafeGuard(
            _src,
            _srcAmount,
            _dest,
            _minDestAmount,
            subRoutes,
            correspondentTokens,
            _receiver,
            _learnedId
        );
    }
    
    function _split2(
        uint256[]   memory _learnedIds,
        uint256[]   memory _volumns,
        IERC20      _src,
        uint256     _totalSrcAmount,
        IERC20      _dest,
        address     _fromAddress
    )
        private
        returns (
            uint256 _destAmount
        )
    {
        // Trade with routes
        uint256 amountRemain = _totalSrcAmount;
        for (uint i = 0; i < _learnedIds.length; i++) {
            uint256 amountForThisRound;
            if (i == _learnedIds.length - 1) {
                amountForThisRound = amountRemain;
            } else {
                amountForThisRound = _totalSrcAmount * _volumns[i] / 100;
                amountRemain = amountRemain - amountForThisRound;
            }
            
            bytes32 learnedHash = cosmicBrain.learnedHashes(_learnedIds[i]);
            (
                uint256[]   memory subRoutes,
                IERC20[]    memory correspondentTokens
            ) = cosmicBrain.fetchRoutesAndTokens(learnedHash);
        
            _destAmount = _destAmount +
                _tradeStrategies(
                    _src,
                    amountForThisRound,
                    _dest,
                    subRoutes,
                    correspondentTokens,
                    _fromAddress
                )
            ;
        }
    }
    
    function _splitTradesWithSafeGuard(
        uint256[] memory  _learnedIds,
        uint256[] memory  _volumns,
        IERC20              _src,
        uint256             _totalSrcAmount,
        IERC20              _dest
    )
        private
        returns(uint256 _destAmount)
    {
        IERC20 adjustedSrc;
        IERC20 adjustedDest = ETHER_ERC20 == _dest ? IERC20(address(weth)) : _dest;
        address fromAddress;
        
        // Wrap ETH
        if (ETHER_ERC20 == _src) {
            require(msg.value == _totalSrcAmount, "WardenSwap: Ether source amount mismatched");
            weth.deposit{value: _totalSrcAmount}();
            
            adjustedSrc = IERC20(address(weth));
            fromAddress = address(this);
        } else {
            adjustedSrc = _src;
            fromAddress = msg.sender;
        }
        
        // Record src/dest asset for later consistency check.
        uint256 srcAmountBefore = adjustedSrc.balanceOf(fromAddress);
        uint256 destAmountBefore = adjustedDest.balanceOf(address(this));
        
        _destAmount = _split2(
            _learnedIds,
            _volumns,
            adjustedSrc,
            _totalSrcAmount,
            adjustedDest,
            fromAddress
        );
        
        // Sanity check
        // Recheck if src/dest amount correct
        require(adjustedSrc.balanceOf(fromAddress) == srcAmountBefore - _totalSrcAmount, "WardenSwap: source amount mismatched after trade");
        require(adjustedDest.balanceOf(address(this)) == destAmountBefore + _destAmount, "WardenSwap: destination amount mismatched after trade");

        
        // Unwrap ETH
        if (ETHER_ERC20 == _dest) {
            weth.withdraw(_destAmount);
        }
    }

    /**
    * @dev makes a trade by splitting volumes
    * @param _learnedIds unique ids
    * @param _volumns volume percentages
    * @param _src Source token
    * @param _totalSrcAmount amount of source tokens
    * @param _dest Destination token
    * @param _minDestAmount minimum of destination token amount
    * @param _receiver receiver address
    * @return _destAmount amount of actual destination tokens
    */
    function splitTrades(
        uint256[] memory  _learnedIds,
        uint256[] memory  _volumns,
        IERC20              _src,
        uint256             _totalSrcAmount,
        IERC20              _dest,
        uint256             _minDestAmount,
        address             _receiver
    )
        public
        payable
        nonReentrant
        returns(uint256 _destAmount)
    {
        require(_learnedIds.length > 0, "WardenSwap: learnedIds can not be empty");
        require(_learnedIds.length == _volumns.length, "WardenSwap: learnedIds and volumns lengths mismatched");
        
        _destAmount = _splitTradesWithSafeGuard(
            _learnedIds,
            _volumns,
            _src,
            _totalSrcAmount,
            _dest
        );
        
        // Collect fee
        _destAmount = _postTradeAndCollectFee(
            _src,
            _dest,
            _totalSrcAmount,
            _destAmount,
            msg.sender,
            _receiver,
            true
        );

        // Throw exception if destination amount doesn't meet user requirement.
        require(_destAmount >= _minDestAmount, "WardenSwap: destination amount is too low.");
        if (ETHER_ERC20 == _dest) {
            (bool success, ) = _receiver.call{value: _destAmount}(""); // Send back ether to sender
            require(success, "WardenSwap: Transfer ether back to caller failed.");
        } else { // Send back token to sender
            _dest.safeTransfer(_receiver, _destAmount);
        }

        emit Trade(address(_src), _totalSrcAmount, address(_dest), _destAmount, msg.sender, _receiver, true, true);
    }
    
    /**
    * @dev makes a trade ETH -> WETH
    * @param _receiver receiver address
    * @return _destAmount amount of actual destination tokens
    */
    function tradeEthToWeth(
        address     _receiver
    )
        external
        payable
        nonReentrant
        returns(uint256 _destAmount)
    {
        weth.deposit{value: msg.value}();
        IERC20(address(weth)).safeTransfer(_receiver, msg.value);
        _destAmount = msg.value;
        emit Trade(address(ETHER_ERC20), msg.value, address(weth), _destAmount, msg.sender, _receiver, false, false);
    }
    
    /**
    * @dev makes a trade WETH -> ETH
    * @param _srcAmount amount of source tokens
    * @param _receiver receiver address
    * @return _destAmount amount of actual destination tokens
    */
    function tradeWethToEth(
        uint256     _srcAmount,
        address     _receiver
    )
        external
        nonReentrant
        returns(uint256 _destAmount)
    {
        IERC20(address(weth)).safeTransferFrom(msg.sender, address(this), _srcAmount);
        weth.withdraw(_srcAmount);
        (bool success, ) = _receiver.call{value: _srcAmount}(""); // Send back ether to sender
        require(success, "WardenSwap: Transfer ether back to caller failed.");
        _destAmount = _srcAmount;
        emit Trade(address(weth), _srcAmount, address(ETHER_ERC20), _destAmount, msg.sender, _receiver, false, false);
    }

    // In case of an expected and unexpected event that has some token amounts remain in this contract, owner can call to collect them.
    function collectRemainingToken(
        IERC20  _token,
        uint256 _amount
    )
      external
      onlyOwner
    {
        _token.safeTransfer(msg.sender, _amount);
    }

    // In case of an expected and unexpected event that has some ether amounts remain in this contract, owner can call to collect them.
    function collectRemainingEther(
        uint256 _amount
    )
      external
      onlyOwner
    {
        (bool success, ) = msg.sender.call{value: _amount}(""); // Send back ether to sender
        require(success, "WardenSwap: Transfer ether back to caller failed.");
    }
    
    // Receive ETH in case of trade Token -> ETH
    receive() external payable {}
    
    function _postTradeAndCollectFee(
        IERC20      _src,
        IERC20      _dest,
        uint256     _srcAmount,
        uint256     _destAmount,
        address     _trader,
        address     _receiver,
        bool        _isSplit
    )
        private
        returns (uint256 _newDestAmount)
    {
        // Collect fee
        (uint256 fee, address feeWallet) = postTrade.postTradeAndFee(
            _src,
            _dest,
            _srcAmount,
            _destAmount,
            _trader,
            _receiver,
            _isSplit
        );
        if (fee > 0) {
            _collectFee(
                _dest,
                fee,
                feeWallet
            );
        }
        return _destAmount - fee;
    }
    
    function _collectFee(
        IERC20  _token,
        uint256 _fee,
        address _feeWallet
    )
        private
    {
        if (ETHER_ERC20 == _token) {
            (bool success, ) = payable(_feeWallet).call{value: _fee}(""); // Send back ether to sender
            require(success, "Transfer fee of ether failed.");
        } else {
            _token.safeTransfer(_feeWallet, _fee);
        }
        emit CollectFee(_token, _feeWallet, _fee);
    }
}


///////////////////////////
// Optimized for Layer 2 //
///////////////////////////

contract WardenSwap1_5_Aegis_L2 is WardenSwap1_5_Aegis, WardenDataDeserialize {
    using BytesLib for bytes;
    
    constructor(
        IWardenCosmoCore _cosmoCore,
        IWardenCosmicBrain _cosmicBrain,
        IWardenPostTrade _postTrade,
        IWETH _weth,
        IArbAddressTable _addressTable
    )
        WardenSwap1_5_Aegis(
            _cosmoCore,
            _cosmicBrain,
            _postTrade,
            _weth
        )
        WardenDataDeserialize(_addressTable)
    {
    }
    
    function decodeAddresses(
        bytes memory _data,
        uint256 _cursor
    )
        public
        view
        returns (
            address _src,
            address _dest,
            address _receiver,
            uint256 _newCursor
        )
    {
        (
            _src,
            _dest,
            _receiver,
            _newCursor
        ) = lookupSrcDestReceiverAddresses(_data, _cursor);
        
        if (_receiver == 0x0000000000000000000000000000000000000000) {
            _receiver = msg.sender;
        }
    }
    
    function tradeStrategiesC1(
        bytes memory _data
    )
        external
        payable
        returns (uint256 _destAmount)
    {
        uint256 cursor = 0;
        address src;
        address dest;
        uint256 srcAmount;
        uint256 minDestAmount;

        (
            src,
            dest,
            srcAmount,
            minDestAmount,
            cursor
        ) = decodeCompressed2(_data, cursor);
        
        uint256[]   memory subRoutes;
        IERC20[]    memory correspondentTokens;
        (
            subRoutes,
            correspondentTokens,
            cursor
        ) = decodeSubRoutesAndCorrespondentTokens(_data, cursor);

        return tradeStrategies(
            IERC20(src),
            srcAmount,
            IERC20(dest),
            minDestAmount,
            subRoutes,
            correspondentTokens,
            msg.sender
        );
    }
    
    function tradeStrategiesC2(
        bytes memory _data
    )
        external
        payable
        returns(uint256 _destAmount)
    {
        uint256 cursor = 0;

        // Addresses

        address src;
        address dest;
        address receiver;
        (
            src,
            dest,
            receiver,
            cursor
        ) = decodeAddresses(_data, cursor);
        
        // Amounts
        
        uint256 srcAmount;
        uint256 minDestAmount;
        (
            srcAmount,
            minDestAmount,
            cursor
        ) = decodeSrcMinAmounts(_data, cursor);
        
        // Routes, Tokens
        uint256[]   memory subRoutes;
        IERC20[]    memory correspondentTokens;
        (
            subRoutes,
            correspondentTokens,
            cursor
        ) = decodeSubRoutesAndCorrespondentTokens(_data, cursor);

        return tradeStrategies(
            IERC20(src),
            srcAmount,
            IERC20(dest),
            minDestAmount,
            subRoutes,
            correspondentTokens,
            receiver
        );
    }
    
    function tradeStrategiesC3(
        bytes memory _data
    )
        external
        payable
        returns(uint256 _destAmount)
    {
        uint256 cursor = 0;

        address src;
        address dest;
        address receiver;
        (
            src,
            dest,
            receiver,
            cursor
        ) = decodeAddresses(_data, cursor);
        
        uint256 srcAmount = _data.toUint256(cursor);
        cursor += 32;
        
        uint256 minDestAmount = _data.toUint256(cursor);
        cursor += 32;

        // Routes, Tokens
        uint256[]   memory subRoutes;
        IERC20[]    memory correspondentTokens;
        (
            subRoutes,
            correspondentTokens,
            cursor
        ) = decodeSubRoutesAndCorrespondentTokens(_data, cursor);

        return tradeStrategies(
            IERC20(src),
            srcAmount,
            IERC20(dest),
            minDestAmount,
            subRoutes,
            correspondentTokens,
            receiver
        );
    }
    
    function tradeWithLearnedC1(
        bytes32 _compressedData
    )
        external
        payable
        returns(uint256 _destAmount)
    {
        (
            address src,
            address dest,
            uint256 srcAmount,
            uint256 minDestAmount,
            uint256 learnedId
        ) = decodeCompressed1(_compressedData);
        
        return tradeWithLearned(
            IERC20(src),
            srcAmount,
            IERC20(dest),
            minDestAmount,
            learnedId,
            msg.sender
        );
    }
    
    function tradeWithLearnedC2(
        bytes memory _data
    )
        external
        payable
        returns(uint256 _destAmount)
    {
        uint256 cursor = 0;

        // Addresses

        address src;
        address dest;
        address receiver;
        (
            src,
            dest,
            receiver,
            cursor
        ) = decodeAddresses(_data, cursor);
        
        // Amounts

        uint256 srcAmount;
        uint256 minDestAmount;
        uint256 learnedId;
        (
            srcAmount,
            minDestAmount,
            learnedId,
            cursor
        ) = decodeSrcMinAmountsLearnedId(_data, cursor);
        
        return tradeWithLearned(
            IERC20(src),
            srcAmount,
            IERC20(dest),
            minDestAmount,
            learnedId,
            receiver
        );
    }
    
    function tradeWithLearnedC3(
        bytes memory _data
    )
        external
        payable
        returns(uint256 _destAmount)
    {
        uint256 cursor = 0;

        address src;
        address dest;
        address receiver;
        (
            src,
            dest,
            receiver,
            cursor
        ) = decodeAddresses(_data, cursor);
        
        uint256 srcAmount = _data.toUint256(cursor);
        cursor += 32;
        
        uint256 minDestAmount = _data.toUint256(cursor);
        cursor += 32;

        uint256 learnedId = _data.toUint256(cursor);
        cursor += 32;
        
        return tradeWithLearned(
            IERC20(src),
            srcAmount,
            IERC20(dest),
            minDestAmount,
            learnedId,
            receiver
        );
    }
    
    function splitTradesC1(
        bytes memory _data
    )
        external
        payable
        returns(uint256 _destAmount)
    {
        uint256 cursor = 0;
        address src;
        address dest;
        uint256 totalSrcAmount;
        uint256 minDestAmount;

        (
            src,
            dest,
            totalSrcAmount,
            minDestAmount,
            cursor
        ) = decodeCompressed2(_data, cursor);
        
        // Learned ids, volumns
        uint256[] memory learnedIds;
        uint256[] memory volumns;
        (
            learnedIds,
            volumns,
            cursor
        ) = decodeLearnedIdsAndVolumns(_data, cursor);
        
        return splitTrades(
            learnedIds,
            volumns,
            IERC20(src),
            totalSrcAmount,
            IERC20(dest),
            minDestAmount,
            msg.sender
        );
    }
    
    function splitTradesC2(
        bytes memory _data
    )
        external
        payable
        returns(uint256 _destAmount)
    {
        uint256 cursor = 0;

        // Addresses

        address src;
        address dest;
        address receiver;
        (
            src,
            dest,
            receiver,
            cursor
        ) = decodeAddresses(_data, cursor);
        
        // Amounts
        
        uint256 totalSrcAmount;
        uint256 minDestAmount;
        (
            totalSrcAmount,
            minDestAmount,
            cursor
        ) = decodeSrcMinAmounts(_data, cursor);
        
        // Learned ids, volumns
        uint256[] memory learnedIds;
        uint256[] memory volumns;
        (
            learnedIds,
            volumns,
            cursor
        ) = decodeLearnedIdsAndVolumns(_data, cursor);
        
        return splitTrades(
            learnedIds,
            volumns,
            IERC20(src),
            totalSrcAmount,
            IERC20(dest),
            minDestAmount,
            receiver
        );
    }
    
    function splitTradesC3(
        bytes memory _data
    )
        external
        payable
        returns(uint256 _destAmount)
    {
         uint256 cursor = 0;

        address src;
        address dest;
        address receiver;
        (
            src,
            dest,
            receiver,
            cursor
        ) = decodeAddresses(_data, cursor);
        
        uint256 totalSrcAmount = _data.toUint256(cursor);
        cursor += 32;
        
        uint256 minDestAmount = _data.toUint256(cursor);
        cursor += 32;
        
        // Learned ids, volumns
        uint256[] memory learnedIds;
        uint256[] memory volumns;
        (
            learnedIds,
            volumns,
            cursor
        ) = decodeLearnedIdsAndVolumns(_data, cursor);
        
        return splitTrades(
            learnedIds,
            volumns,
            IERC20(src),
            totalSrcAmount,
            IERC20(dest),
            minDestAmount,
            receiver
        );
    }
}
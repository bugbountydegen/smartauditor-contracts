// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

interface SpectrumCommon {
    enum AssetID {
        None,
        ETH,
        SPETH,
        WEETH,
        EETH,
        WSTETH,
        STETH
    }

    enum SpectrumErrors {
        None,
        Exist,
        NotExist,
        Asset,
        Address,
        Amount,
        Function,
        Data,
        Fee
    }
    error Spectrum(SpectrumErrors e);
}

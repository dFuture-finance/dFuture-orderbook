// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

library EIP712 {
    function recover(
        // solhint-disable-next-line var-name-mixedcase
        bytes32 DOMAIN_SEPARATOR,
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR, hash));
        //digest = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", digest));
        return ecrecover(digest, v, r, s);
    }

    function getDigest(bytes32 DOMAIN_SEPARATOR, bytes32 hash) internal pure returns(bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR, hash));
    }
}

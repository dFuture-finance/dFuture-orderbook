const EthUtils = require('ethereumjs-util');

//const COUPON_ORDER_HASH = web3.utils.keccak256("CouponOrder(address trader,uint256 timestamp,uint256 deadline,uint256 amount0,uint256 targetPrice0,uint256 fee0,uint256 coupons0,uint256 amount1,uint256 targetPrice1,uint256 fee1,uint256 coupons1,bytes32 symbol)");
const COUPON_ORDER_HASH = '0x37121680a6625a8f51de4886244a9f478567c8aba3b73e1fefa9b400653b6946';

class CouponOrder {
    constructor(web3Ins, trader, timestamp, deadline, amount0, targetPrice0, fee0, coupons0, amount1, targetPrice1, fee1, coupons1, symbol) {
        this.trader = trader;
        this.timestamp = timestamp;
        this.deadline = deadline;
        this.amount0 = amount0;
        this.targetPrice0 = targetPrice0;
        this.fee0 = fee0;
        this.coupons0 = coupons0;
        this.amount1 = amount1;
        this.targetPrice1 = targetPrice1;
        this.fee1 = fee1;
        this.coupons1 = coupons1;
        this.symbol = symbol;
        this.web3 = web3Ins;
    }

    setDomainSeparator(chainId, contractAddr) {
        let encodeData = this.web3.eth.abi.encodeParameters(
            ['bytes32', 'bytes32', 'bytes32', 'uint256', 'address'],
            [
                this.web3.utils.keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                this.web3.utils.keccak256("OrderBook"),
                this.web3.utils.keccak256("1"),
                chainId,
                contractAddr
            ]
        );
        this.DOMAIN_SEPARATOR = this.web3.utils.keccak256(encodeData);
        return this.DOMAIN_SEPARATOR
    }

    getDigest() {
        let encodedData = this.web3.eth.abi.encodeParameters(
                ['bytes32', 'address', 'uint256', 'uint256', 'uint256', 'uint256', 'uint256', 'uint256', 'uint256', 'uint256', 'uint256', 'uint256', 'bytes32'],
                [COUPON_ORDER_HASH, this.trader, this.timestamp, this.deadline, this.amount0, this.targetPrice0, this.fee0, this.coupons0, this.amount1, this.targetPrice1, this.fee1, this.coupons1, this.symbol]
        );
        let h = this.web3.utils.keccak256(encodedData);
        return this.web3.utils.soliditySha3(
            {t: 'bytes1', v: '0x19'},
            {t: 'bytes1', v: '0x01'},
            {t: 'bytes32', v: this.DOMAIN_SEPARATOR},
            {t: 'bytes32', v: h}
        );
    }

    sign(sk) {
        let digest = this.getDigest();
        if (sk.startsWith('0x')) {
            sk = sk.slice(2);
        }
        let res = EthUtils.ecsign(Buffer.from(digest.slice(2), 'hex'), Buffer.from(sk, 'hex'));
        this.r = res.r;
        this.s = res.s;
        this.v = res.v;
    }
}

const LIMIT_ORDER_HASH = web3.utils.keccak256("LimitOrder(address trader,uint256 timestamp,uint256 deadline,uint256 lowOrUp,uint256 targetPrice,uint256 fee,bytes32 symbol,uint256 amount,int8 direction,uint256 acceptablePrice,uint256 approvedUsdt,address parent,bool withDiscount,uint256 openOrderDeadline,uint8 gasLevel,uint256 couponId)");
//const LIMIT_ORDER_HASH = '0x37121680a6625a8f51de4886244a9f478567c8aba3b73e1fefa9b400653b6946';
//console.log('LIMIT_ORDER_HASH: ', LIMIT_ORDER_HASH);

class LimitOrder {
    constructor(web3Ins, trader, timestamp, deadline, lowOrUp, targetPrice, fee, symbol, amount, direction, acceptablePrice, approvedUsdt, parent, withDiscount, openOrderDeadline, gasLevel, couponId) {
        this.trader = trader;
        this.timestamp = timestamp;
        this.deadline = deadline;
        this.lowOrUp = lowOrUp;
        this.targetPrice = targetPrice;
        this.fee = fee;
        this.symbol = symbol;
        this.amount = amount;
        this.direction = direction;
        this.acceptablePrice = acceptablePrice;
        this.approvedUsdt = approvedUsdt;
        this.parent = parent;
        this.withDiscount = withDiscount;
        this.openOrderDeadline = openOrderDeadline;
        this.gasLevel = gasLevel;
        this.couponId = couponId;
        this.web3 = web3Ins;
    }

    setDomainSeparator(chainId, contractAddr) {
        let encodeData = this.web3.eth.abi.encodeParameters(
            ['bytes32', 'bytes32', 'bytes32', 'uint256', 'address'],
            [
                this.web3.utils.keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                this.web3.utils.keccak256("OrderBook"),
                this.web3.utils.keccak256("1"),
                chainId,
                contractAddr
            ]
        );
        this.DOMAIN_SEPARATOR = this.web3.utils.keccak256(encodeData);
        return this.DOMAIN_SEPARATOR
    }

    getDigest() {
        let orderInternalEncodedData = this.web3.eth.abi.encodeParameters(
            ['bytes32', 'uint256', 'int8', 'uint256', 'uint256', 'address', 'bool', 'uint256', 'uint8', 'uint256'],
            [this.symbol, this.amount, this.direction, this.acceptablePrice, this.approvedUsdt, this.parent, this.withDiscount, this.openOrderDeadline, this.gasLevel, this.couponId]
        );
        let internalOrderHash = this.web3.utils.keccak256(orderInternalEncodedData);

        let encodedData = this.web3.eth.abi.encodeParameters(
                ['bytes32', 'address', 'uint256', 'uint256', 'uint8', 'uint256', 'uint256', 'bytes32'],
                [LIMIT_ORDER_HASH, this.trader, this.timestamp, this.deadline, this.lowOrUp, this.targetPrice, this.fee, internalOrderHash]
        );
        let h = this.web3.utils.keccak256(encodedData);
        return this.web3.utils.soliditySha3(
            {t: 'bytes1', v: '0x19'},
            {t: 'bytes1', v: '0x01'},
            {t: 'bytes32', v: this.DOMAIN_SEPARATOR},
            {t: 'bytes32', v: h}
        );
    }

    sign(sk) {
        let digest = this.getDigest();
        if (sk.startsWith('0x')) {
            sk = sk.slice(2);
        }
        let res = EthUtils.ecsign(Buffer.from(digest.slice(2), 'hex'), Buffer.from(sk, 'hex'));
        this.r = res.r;
        this.s = res.s;
        this.v = res.v;
    }
}

module.exports = {CouponOrder, LimitOrder};

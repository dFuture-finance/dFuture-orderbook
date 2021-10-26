const OrderBook = artifacts.require('OrderBook');
const Settlement = artifacts.require('Settlement');
const MockOracle = artifacts.require('MockOracle');
const MockMaster = artifacts.require('MockMaster');
const MockUsdt   = artifacts.require('MockUsdt');
const ethUtil = require('ethereumjs-util');
const {Order, CouponOrder, LimitOrder} = require('./Order');
const truffleAssert = require('truffle-assertions');

const testSk = "0x80515df68b73656e8e1dc888c02543100bb40342fb9f0f4c7a18f39140cb5b19";
const testPk = "0xBD1548D7768C471b59199C99Cb7a6E6dbFf8C31F";
const btc = web3.utils.fromAscii("btc");
const chainId = 1;
const LowDirection = 0;
const UpDirection = 1;

const OwnerAddressIndex = 0;
const MasterAddressIndex = 1;
const OracleAddressIndex = 2;
const UsdtAddressIndex = 3;

contract("OrderBook", ([alice, maker1]) => {
    beforeEach(async () => {
        this.orderBook = await OrderBook.new({from: alice});
        this.settlement = await Settlement.new({from: alice});
        this.oracle = await MockOracle.new({from: alice});
        this.master = await MockMaster.new({from: alice});
        this.usdt = await MockUsdt.new({from: alice});
        await this.orderBook.setDomainSeparator(chainId, this.settlement.address);
        await this.settlement.initialize({from: alice});
        await this.settlement.setAddress(MasterAddressIndex, this.master.address);
        await this.settlement.setAddress(OracleAddressIndex, this.oracle.address);
        await this.settlement.setAddress(UsdtAddressIndex, this.usdt.address);
        await this.settlement.setDomainSeparator(chainId, this.settlement.address);
        await this.master.setOrderBookContract(this.settlement.address);
    });

    it("createOrderWithCoupon", async () => {
        var order = new CouponOrder(web3, testPk, 14567, 0, 1, 40000, 50, 7, 1, 60000, 50, 7, btc);
        var separator = order.setDomainSeparator(chainId, this.settlement.address)
        console.log("DOMAIN_SEPARATOR: ", separator);
        order.sign(testSk);
        const pubKey = ethUtil.ecrecover(Buffer.from(order.getDigest().slice(2), 'hex'), order.v, order.r, order.s);
        const addrBuff = ethUtil.pubToAddress(pubKey);
        const addr = ethUtil.bufferToHex(addrBuff);
        console.log("recover: " + web3.utils.toChecksumAddress(addr));
        await this.orderBook.createCouponOrder(order);
    });

    it("createLimitOrder", async () => {
        var order = new LimitOrder(web3, testPk, 14567, 0, 1, 40000, 50, btc, 1, 1, 0, 100, alice, 9, 9, 5, 0);
        var separator = order.setDomainSeparator(chainId, this.settlement.address)
        console.log("DOMAIN_SEPARATOR: ", separator);
        order.sign(testSk);
        const pubKey = ethUtil.ecrecover(Buffer.from(order.getDigest().slice(2), 'hex'), order.v, order.r, order.s);
        const addrBuff = ethUtil.pubToAddress(pubKey);
        const addr = ethUtil.bufferToHex(addrBuff);
        console.log("recover: " + web3.utils.toChecksumAddress(addr));
        await this.orderBook.createLimitOrder(order);
    });

    it("executeOrderWithCoupon", async () => {
        let t = 165676771
        let closePosition = 1;
        let lowPrice = 55000;
        let upPrice = 60000;
        this.usdt.mint(testPk, 100);
        var order = new CouponOrder(web3, testPk, t, 0, 1, lowPrice/1000, 50, 7, 1, upPrice/1000, 50, 7, btc);
        order.setDomainSeparator(chainId, this.settlement.address);
        order.sign(testSk)
        let openPosition = 2;
        await this.master.setPosition(testPk, btc, openPosition);
        await this.settlement.executeOrderWithCoupon(order, LowDirection, {price: 55000, timestamp: 1000});
        assert.equal((await this.master.queryPosition(testPk, btc)).amount, openPosition - closePosition);
        await truffleAssert.fails(this.settlement.executeOrderWithCoupon(order, LowDirection, {price: 55000, timestamp: 1000}), truffleAssert.ErrorType.REVERT, 'not-valid-order');

        await truffleAssert.fails(this.settlement.executeOrderWithCoupon(order, UpDirection, { price: 59000, timestamp: 1000}), truffleAssert.ErrorType.REVERT, 'not-meet-price');
        await this.settlement.executeOrderWithCoupon(order, UpDirection, { price: 61000, timestamp: 1000});
        assert.equal((await this.master.queryPosition(testPk, btc)).amount, 0);
    });

    it("executeLimitOrder", async () => {
        let t = 165676771
        let couponId = 1000;
        let gasLevel = 5;
        this.usdt.mint(testPk, 10000);
        var order = new LimitOrder(web3, testPk, t, 0, 1, 40000/1000, 50, btc, 1, 1, 0, 100, alice, 9, 9, gasLevel, couponId);
        order.setDomainSeparator(chainId, this.settlement.address);
        order.sign(testSk)
        await this.settlement.executeLimitOrder(order, {price: 55000, timestamp: 1000});
    });
});

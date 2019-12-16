const HoldableERC20 = artifacts.require('HoldableERC20');
const truffleAssert = require('truffle-assertions');

const TOTAL_SUPPLY = 12000

contract("HoldableERC20", accounts => {
    beforeEach(async function () {
        instance = await HoldableERC20.deployed();
    });

    it("Total supply is minted and assigned to contract creator", async () => {
        const _balanceOwner = await instance.balanceOf.call(accounts[0]);
        const _totalSupply = await instance.totalSupply.call();
        assert.equal(_balanceOwner, TOTAL_SUPPLY,
            "Balance of contract owner is correct.");
        assert.equal(_totalSupply, TOTAL_SUPPLY,
            "Total supply coincides with expected value.");
    });
    it("Hold transfer works as expected", async () => {
        const holdId = 0;
        const amount = 500;
        const from = accounts[0];
        const to = accounts[1];
        const initialFrom = TOTAL_SUPPLY;
        const initialTo = 0;
        let tx = await instance.hold(to, amount, holdId);
        const _balanceFromPre = await instance.balanceOf.call(from);
        assert.equal(_balanceFromPre, initialFrom,
            "Hold values are part of total balance.");
        const _balanceToPre = await instance.balanceOf.call(to);
        assert.equal(_balanceToPre, initialTo,
            "No balance on hold is transferred until executed.");
        tx = await instance.executeHold(holdId);
        truffleAssert.eventEmitted(tx, 'Transfer', (ev) =>{
            return ((ev.from === from)&&
                    (ev.to === to)&&
                    (ev.value == amount));
        });
        const _balanceFromPost = await instance.balanceOf.call(from);
        assert.equal(_balanceFromPost, initialFrom - amount,
            "Value on hold substracted from balance when executed.");
        const _balanceToPost = await instance.balanceOf.call(to);
        assert.equal(_balanceToPost, initialTo + amount,
            "Balance on hold transferred.");
    });
    it("holdFrom transfer works as expected", async () => {
        const holdId = 1;
        const amount = 500;
        const from = accounts[1];
        const to = accounts[0];
        const initialFrom = amount;
        const initialTo = TOTAL_SUPPLY - amount;
        let tx = await instance.increaseAllowance(
            to, amount,{from: from});
        const _allowance = await instance.allowance(from,to);
        assert.equal(_allowance, amount,
            "Allowance value is set.");
        tx = await instance.holdFrom(from, to, amount, holdId);
        truffleAssert.eventEmitted(tx, 'Approval', (ev) =>{
            return ((ev.owner === from)&&
                    (ev.spender === to));
        });
        const _balanceFromPre = await instance.balanceOf.call(from);
        assert.equal(_balanceFromPre, initialFrom,
            "Hold values are part of total balance.");
        const _balanceToPre = await instance.balanceOf.call(to);
        assert.equal(_balanceToPre, initialTo,
            "No balance on hold is transferred until executed.");
        tx = await instance.executeHold(holdId);
        truffleAssert.eventEmitted(tx, 'Transfer', (ev) =>{
            return ((ev.from === from)&&
                    (ev.to === to)&&
                    (ev.value == amount));
        });
        const _balanceFromPost = await instance.balanceOf.call(from);
        assert.equal(_balanceFromPost, initialFrom - amount,
            "Value on hold substracted from balance when executed.");
        const _balanceToPost = await instance.balanceOf.call(to);
        assert.equal(_balanceToPost, initialTo + amount,
            "Balance on hold transferred.");
    });
    it("Values in hold cannot be used in transfers and remove hold"+
        " works as expected", async () => {
        const holdId = 2;
        const amount = 500;
        const from = accounts[0];
        const to = accounts[1];
        const initialFrom = TOTAL_SUPPLY;
        const initialTo = 0;
        let tx = await instance.hold(to, amount, holdId);
        const _balanceFromPre = await instance.balanceOf.call(from);
        assert.equal(_balanceFromPre, initialFrom,
            "Hold values are part of total balance.");
        const _balanceToPre = await instance.balanceOf.call(to);
        assert.equal(_balanceToPre, initialTo,
            "No balance on hold is transferred until executed.");
        let expectedMsg = "ERC20: transfer amount exceeds balance.";
        try{
            await instance.transfer(to, initialFrom);    
        } catch (e) {
            assert(e.message.includes(expectedMsg),
                "Expected an error as hold balances cannot be used for "+
                "transfers");
        }
        tx = await instance.removeHold(holdId);
        tx = await instance.transfer(to, initialFrom);
        truffleAssert.eventEmitted(tx, 'Transfer', (ev) =>{
            return ((ev.from === from)&&
                    (ev.to === to)&&
                    (ev.value == initialFrom));
        });
        const _balanceFromPost = await instance.balanceOf.call(from);
        assert.equal(_balanceFromPost, 0,
            "Value on hold back for transfers as transfer allowed.");
        const _balanceToPost = await instance.balanceOf.call(to);
        assert.equal(_balanceToPost, initialFrom,
            "Balance transferred as expected.");
    });
    it("Invalid Hold Ids and duplicated.", async () => {
        const holdId = 3;
        const amount = 500;
        const from = accounts[1];
        const to = accounts[0];
        const initialFrom = TOTAL_SUPPLY;
        const initialTo = 0;
        let tx = await instance.hold(to, amount, holdId,{from:accounts[1]});
        let expectedMsg = "HoldableERC20: invalid holdId";
        try{
            await instance.executeHold(holdId + 1);    
        } catch (e) {
            assert(e.message.includes(expectedMsg),
                "Expected an error as hold Id used is not valid.");
        }
        expectedMsg = "HoldableERC20: invalid holdId";
        try{
            await instance.removeHold(holdId + 1);    
        } catch (e) {
            assert(e.message.includes(expectedMsg),
                "Expected an error as hold Id used is not valid.");
        }                
        tx = await instance.executeHold(holdId);
        truffleAssert.eventEmitted(tx, 'Transfer', (ev) =>{
            return ((ev.from === from)&&
                    (ev.to === to)&&
                    (ev.value == amount));
        });
        const _balanceFromPost = await instance.balanceOf.call(from);
        assert.equal(_balanceFromPost, initialFrom - amount,
            "Value on hold substracted from balance when executed.");
        const _balanceToPost = await instance.balanceOf.call(to);
        assert.equal(_balanceToPost, initialTo + amount,
            "Balance on hold transferred.");
        expectedMsg = "HoldableERC20: holdId not accepted";
        try{
            await instance.hold(to, amount, holdId,{from:accounts[1]});
        } catch (e) {
            assert(e.message.includes(expectedMsg),
                "Expected an error as hold Id already used.");
        }
        expectedMsg = "HoldableERC20: holdId already executed";
        try{
            await instance.executeHold(holdId);    
        } catch (e) {
            assert(e.message.includes(expectedMsg),
                "Expected an error as hold Id already executed.");
        }
    });
    it("Not sufficient funds for holds.", async () => {
        const holdId = 4;
        const amount = 500;
        const from = accounts[1];
        const to = accounts[0];
        const initialFrom = TOTAL_SUPPLY;
        const initialTo = 0;
        let expectedMsg = "ERC20: transfer amount exceeds balance";
        try{
            let tx = await instance.hold(to, TOTAL_SUPPLY, holdId,{from:from});
        } catch (e) {
            assert(e.message.includes(expectedMsg),
                "Expected an error as hold Id used is not valid.");
        }
        tx = await instance.increaseAllowance(
            to, TOTAL_SUPPLY,{from: from});
        try{
            tx = await instance.holdFrom(from, to, TOTAL_SUPPLY, holdId);
        } catch (e) {
            assert(e.message.includes(expectedMsg),
                "Expected an error as hold Id used is not valid.");
        }
    });
});

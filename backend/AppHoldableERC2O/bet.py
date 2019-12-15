from django.shortcuts import render
from django.http import Http404
from rest_framework.views import APIView
from rest_framework.decorators import api_view
from rest_framework.response import Response
from rest_framework import status
from django.http import JsonResponse
from django.core import serializers
from django.conf import settings
import json
import os
from web3 import Web3, HTTPProvider

from AppHoldableERC2O import contractData
from AppHoldableERC2O import log

@api_view(["POST"])
def PlaceBet(data):
    try:
        # Fixed bet in ADH tokens
        FIXED_BET = 5
        # Get log info
        _log = log.PreliminarLog()
        
        # Get address from input JSON
        addr=Web3.toChecksumAddress(json.loads(data.body)['addr'])
        # Setup web3 infrastructure and contract access
        w3 = Web3(HTTPProvider(contractData.GANACHE_IP))
        abi = json.load(open(contractData.ABI_PATH))['abi']
        contract = w3.eth.contract(address=contractData.CONTRACT_ADDR,
                                   abi=abi)
        # Place bet
        bet_result=_log.PlaceBet(addr)
        # enforce deletion of log object and save back of log
        _log.__del__()
    except ValueError as e:
        return Response(e.args[0],status.HTTP_400_BAD_REQUEST)
    if bet_result['status']:
        try:
            # if successful get hold from user and manage bet
            tx_hash = contract.functions.hold(
                w3.eth.accounts[0],
                FIXED_BET,
                bet_result['hold_id']).transact({'from': addr})
            tx_receipt = w3.eth.waitForTransactionReceipt(tx_hash)
        except ValueError as e:
            _log = log.PreliminarLog()
            _log.RemoveBet(bet_result['hold_id'])
            output=[{'Bet status':'Error. Not enough tokens to bet.'}]
            _log.__del__()
            return JsonResponse(output,safe=False)
        try:
            _log = log.PreliminarLog()
            bet_status = _log.ManageBets()
            if bet_status['status']:
                for loser_id in bet_status['losers']:
                    tx_hash = contract.functions.executeHold(loser_id).\
                              transact({'from': w3.eth.accounts[0]})
                    tx_receipt = w3.eth.waitForTransactionReceipt(tx_hash)

                tx_hash = contract.functions.removeHold(
                    bet_status['winner_id']).\
                    transact({'from': w3.eth.accounts[0]})
                tx_receipt = w3.eth.waitForTransactionReceipt(tx_hash)
                tx_hash = contract.functions.transfer(
                    bet_status['winner_addr'],
                    bet_status['mulx']*FIXED_BET).\
                    transact({'from': w3.eth.accounts[0]})
                tx_receipt = w3.eth.waitForTransactionReceipt(tx_hash)
                
                output=[{'Bet status':'Bet placed OK'},
                        {'Bet id':bet_result['hold_id']},
                        {'Winner bet':bet_status['winner_id']}]
            else:
                output=[{'Bet status':'Bet placed OK'},
                        {'Bet id':bet_result['hold_id']}]
            _log.__del__()
        except ValueError as e:
            _log.__del__()
            return Response(e.args[0],status.HTTP_400_BAD_REQUEST)
    else:
        output=[{'Bet status':'Error. User not registered'}]
    return JsonResponse(output,safe=False)

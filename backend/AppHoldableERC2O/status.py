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
##  
#  @file: status.py
#  @author: Jose Redondo Hurtado
#  @brief: status service for Holdable ERC-20 token betting system.

@api_view(["POST"])
def UserStatus(data):
    try:
        # Get log info
        _log = log.PreliminarLog()
        
        # Get address from input JSON
        addr=Web3.toChecksumAddress(json.loads(data.body)['addr'])
        # Setup web3 infrastructure and contract access
        w3 = Web3(HTTPProvider(contractData.GANACHE_IP))
        abi = json.load(open(contractData.ABI_PATH))['abi']
        contract = w3.eth.contract(address=contractData.CONTRACT_ADDR,
                                   abi=abi)

        # Get balance
        balance = str(contract.functions.balanceOf(addr).call())
        # Get bets from log
        output=[{'Balance':balance,'Bets':_log.UserBets(addr)}]
        return JsonResponse(output,safe=False)
    except ValueError as e:
        return Response(e.args[0],status.HTTP_400_BAD_REQUEST)

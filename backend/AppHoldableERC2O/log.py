import os
import json
import hashlib
import time
from random import randint

DELIMITER=","
bet_i = 0
user_i = 1
NUM_PLAYERS = 4

class PreliminarLog():
    users_log_path = 'users_log.txt'
    bets_log_path = 'bets_log.txt'
    users_list = list()
    bets_list = list()
    def __init__(self):
        # Users log management
        try:
            with open(self.users_log_path, 'r') as f:
                self.users_list = json.load(f)
        except FileNotFoundError:
            f = open(self.users_log_path, 'w')
            f.close()
        # Bets log management
        try:
            with open(self.bets_log_path, 'r') as f:
                self.bets_list.clear()
                for line in f:
                    aux_arr = line.rstrip().split(DELIMITER)
                    self.bets_list.append([int(aux_arr[bet_i]),aux_arr[user_i]])
        except FileNotFoundError:
            f = open(self.bets_log_path, 'w')
            f.close()

    def RegisterUser(self,user):
        if user in self.users_list:
            return False
        else:
            self.users_list.append(user)
            return True

    def UserBets(self,user):
        if user in self.users_list:
            return_str = []
            for i in self.bets_list:
                if i[user_i] == user:
                    return_str.append(i[bet_i])
            # Get values of particular key in list of dictionaries 
            return str(return_str)
        else:
            return []

    def ManageBets(self):
        if len(self.bets_list) >= NUM_PLAYERS:
            winner_bet = self.bets_list.pop(randint(0,3))
            losers=[]
            for i in self.bets_list:
                losers.append(i[bet_i])
            self.bets_list.clear()
            return {'status':True,'winner_id':winner_bet[bet_i],
                    'winner_addr':winner_bet[user_i],'losers':losers,
                    'mulx':NUM_PLAYERS - 1}
        else:
            return {'status':False,'winner_id':None,'winner_addr':None,
                    'losers':None,'mulx':0}
        
    def PlaceBet(self,user):
        if user in self.users_list:
            unique_str = user + str(time.time())
            hold_id = int(hashlib.sha256(unique_str.encode()).hexdigest(),16)
            self.bets_list.append([hold_id,user])
            return {'status':True,'hold_id':hold_id}
        else:
            return {'status':False,'hold_id':None}
    def RemoveBet(self,bet_id):
        try:
            index = self.bets_list.index(
                next((x for x in self.bets_list if x[bet_i] == bet_id),None))
            self.bets_list.pop(index)
        except ValueError as e:
            # no bet id to be removed
            pass 
        
    def __del__(self):
        # Users log management
        with open(self.users_log_path, 'w+') as f:
            json.dump(self.users_list,f)
        # Bets log management
        with open(self.bets_log_path, 'w+') as f:
            for i in self.bets_list:
                f.write('%s%s%s\n'%(i[bet_i],DELIMITER,i[user_i]))

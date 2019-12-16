ADDR1="0x87643c6d1ff0592e049abc45a5ae7e016fce6d9c"
ADDR2="0x9fe6a2fc74025cda324f0ac2892cc16211f60f13"
ADDR3="0xba2c4022d1ce991ef986468f71c9c4150b0d771a"
echo "1st we remove both logs to start clean"
rm ../bets_log.txt
rm ../users_log.txt

echo "As no user is registered, we check their clean status"
echo "{\"addr\":\""${ADDR1}"\"}" | http http://localhost:8000/status/
echo "{\"addr\":\""${ADDR2}"\"}" | http http://localhost:8000/status/
echo "{\"addr\":\""${ADDR3}"\"}" | http http://localhost:8000/status/

echo "Then we try to place a bet, we get an Error, User not registered"
echo "{\"addr\":\""${ADDR1}"\"}" | http http://localhost:8000/bet/
echo "{\"addr\":\""${ADDR2}"\"}" | http http://localhost:8000/bet/
echo "{\"addr\":\""${ADDR3}"\"}" | http http://localhost:8000/bet/

echo "We register two of the addresses and check their status after (Balance 100, no bets)"
echo "{\"addr\":\""${ADDR1}"\"}" | http http://localhost:8000/register/
echo "{\"addr\":\""${ADDR2}"\"}" | http http://localhost:8000/register/
echo "{\"addr\":\""${ADDR1}"\"}" | http http://localhost:8000/status/
echo "{\"addr\":\""${ADDR2}"\"}" | http http://localhost:8000/status/

echo "We place a bet each and check that is reflected in their status"
echo "{\"addr\":\""${ADDR1}"\"}" | http http://localhost:8000/bet/
echo "{\"addr\":\""${ADDR2}"\"}" | http http://localhost:8000/bet/
echo "{\"addr\":\""${ADDR1}"\"}" | http http://localhost:8000/status/
echo "{\"addr\":\""${ADDR2}"\"}" | http http://localhost:8000/status/

echo "We place another bet each and check that the winner bet is reflected in their status"
echo "{\"addr\":\""${ADDR1}"\"}" | http http://localhost:8000/bet/
echo "{\"addr\":\""${ADDR2}"\"}" | http http://localhost:8000/bet/
echo "{\"addr\":\""${ADDR1}"\"}" | http http://localhost:8000/status/
echo "{\"addr\":\""${ADDR2}"\"}" | http http://localhost:8000/status/

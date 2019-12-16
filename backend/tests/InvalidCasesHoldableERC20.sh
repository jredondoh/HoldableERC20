ADDR="0x4bf8ffc21440edc4d12eaa0ae4bd655b211a25dd"
echo "1st we remove both logs to start clean"
rm ../users_log.txt
rm ../bets_log.txt

echo "We simulate that the user is registered but with no funds, to check duplicated register and insufficient funds bet"
echo "{\"addr\":\""${ADDR}"\"}" | http http://localhost:8000/status/
echo "{\"addr\":\""${ADDR}"\"}" | http http://localhost:8000/register/
cd ..
python3.6 ./AppHoldableERC2O/thief.py ${ADDR}
cd tests
echo "{\"addr\":\""${ADDR}"\"}" | http http://localhost:8000/status/
echo "{\"addr\":\""${ADDR}"\"}" | http http://localhost:8000/bet/
echo "{\"addr\":\""${ADDR}"\"}" | http http://localhost:8000/bet/

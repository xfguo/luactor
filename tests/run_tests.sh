#/bin/bash 

echo "======================================="
echo "PingPong example test"
$LUA -v -lluacov example/pingpong.lua $REACTOR
if (($?)); then return 1; fi

echo "======================================="
echo "Timeout example test"
$LUA -v -lluacov example/timeout.lua $REACTOR
if (($?)); then return 1; fi

echo "======================================="
echo "Echo server example test"
python tests/test_echo-server.py "$LUA -v -lluacov example/echo-server.lua $REACTOR"
if (($?)); then 
cat tests/test_echo-server.log | col
return 1
fi
cat tests/test_echo-server.log | col


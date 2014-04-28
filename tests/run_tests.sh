#/bin/bash 

$LUA -v -lluacov example/pingpong.lua $REACTOR 
if (($?)); then return 1; fi

python tests/test_echo-server.py "$LUA -v -lluacov example/echo-server.lua $REACTOR"
if (($?)); then return 1; fi
cat tests/test_echo-server.log | col

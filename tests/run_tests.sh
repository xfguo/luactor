#/bin/bash 

$LUA -v -lluacov example/pingpong.lua $REACTOR

python tests/test_echo-server.py "$LUA -v -lluacov example/echo-server.lua $REACTOR" | col -l 8

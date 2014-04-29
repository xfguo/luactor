#/bin/bash 

sudo apt-get install -y $LUA $lib$LUA-0-dev luarocks python-pexpect bsdmainutils telnet

sudo luarocks install luacov
sudo luarocks install luajson
sudo luarocks install luasocket

if [ $REACTOR = "luaevent" ]; then
   sudo apt-get install libevent-dev -y && 
   rm -rf luaevent &&
   git clone https://github.com/harningt/luaevent.git &&
   sudo make -C luaevent install ;
fi

if [ $REACTOR = "uloop" ]; then 
    rm -rf libubox &&
    git clone https://github.com/xfguo/libubox.git &&
    ( 
        cd libubox &&
        cmake . && 
        make
    ) &&
    ln -sf libubox/libubox.so . &&
    ln -sf libubox/lua/uloop.so ;
fi

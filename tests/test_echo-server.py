import pexpect
import sys
import time

logfile = open("tests/test_echo-server.log", 'w')

try:
    print "TEST START ..."
    prog_tested = pexpect.spawn(sys.argv[1], timeout = 100, logfile = logfile)
    
    prog_tested.expect("TcpManager start...")

    print ">>> Test raise an error."
    c_err = pexpect.spawn('telnet 127.0.0.1 48888', timeout = 300, logfile = logfile)
    c_err.sendline("hello")
    c_err.expect("hello")
    c_err.sendline("raise")
    c_err.expect("raise")
    prog_tested.expect("trace")
    prog_tested.expect("error")

    c = dict()
    for i in range(6):
        print ">>> Open a new telnet session #%d" % i
        c[i] = pexpect.spawn('telnet 127.0.0.1 48888', timeout = 100, logfile = logfile)
        prog_tested.expect("EchoActor.*start")
    
        print ">>> Send some words and wait for echo with #%d" % i
        for j in range(i + 1):
            c[i].sendline(str(i) * (j + 1))
            c[i].expect(str(i) * (j + 1))
         
        if i % 2 == 0:
            print ">>> Close connection by send Ctrl-D for conn #%d" % i
            c[i].sendcontrol("]")
            c[i].expect("telnet>")
            c[i].sendcontrol("D")
            c[i].expect(".*")
            time.sleep(1)
            prog_tested.expect("EchoActor.*end")

        prog_tested.expect(".*")
        
    print ">>> Send 'exit' to close all connections then exit"
    cexit = pexpect.spawn('telnet 127.0.0.1 48888', timeout = 100, logfile = logfile)
    cexit.sendline("exit")
    cexit.expect("exit")
    prog_tested.expect("TcpManager end...")

except Exception, e:
    print "v" * 80
    print e
    print "^" * 80
    print "TEST FAILED!"
    sys.exit(-1)

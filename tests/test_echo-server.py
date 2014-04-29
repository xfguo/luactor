import pexpect
import sys
import time

logfile = open("tests/test_echo-server.log", 'w')

try:
    print "TEST START ..."
    prog_tested = pexpect.spawn(sys.argv[1], timeout = 100, logfile = logfile)
    
    prog_tested.expect("TcpManager start...")

    c = dict()
    for i in range(6):
        # open a new telnet session
        c[i] = pexpect.spawn('telnet 127.0.0.1 48888', timeout = 100, logfile = logfile)
        prog_tested.expect("EchoActor.*start")
    
        for j in range(i + 1):
            c[i].sendline(str(i) * (j + 1))
            c[i].expect(str(i) * (j + 1))
         
        if i % 2 == 0:
            c[i].sendcontrol("]")
            c[i].expect("telnet>")
            c[i].sendcontrol("D")
            c[i].expect(".*")
        
            prog_tested.expect("EchoActor.*end")

        prog_tested.expect(".*")

        
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

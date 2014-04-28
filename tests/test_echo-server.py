import pexpect
import sys
import time

try:
    print "TEST START ... WAIT 3 SECOND TO START"
    prog_tested = pexpect.spawn(sys.argv[1], timeout = 30, logfile = sys.stdout)
    
    time.sleep(3)
    
    prog_tested.expect(".*")

    c = dict()
    for i in range(6):
        # open a new telnet session
        c[i] = pexpect.spawn('telnet 127.0.0.1 8080', timeout = 30, logfile = sys.stdout)
    
        for j in range(i + 1):
            c[i].sendline(str(i) * (j + 1))
            c[i].expect(str(i) * (j + 1))
         
        if i % 2 == 0:
            # just close odd session, leave others open
            c[i].sendcontrol("]")
            c[i].expect("telnet>")
            c[i].sendcontrol("D")
            c[i].expect(pexpect.EOF)

        prog_tested.expect(".*")
        
    cexit = pexpect.spawn('telnet 127.0.0.1 8080', timeout = 30, logfile = sys.stdout)
    cexit.sendline("exit")
    cexit.expect("exit")
    prog_tested.expect("TcpManager end...")

except Exception, e:
    print "v" * 80
    print e
    print "^" * 80
    print "TEST FAILED!"
    sys.exit(-1)

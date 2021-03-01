#!/usr/bin/python3
import socket
import os
import json
import time
import datetime
import sys

ipc = "/var/opera/lachesis/data/lachesis.ipc"
lastBlockStore = "/tmp/icinga-last-lachesis-block"

warn = int(sys.argv[1])
crit = int(sys.argv[2])
#warn = 2 * 60 # 2 minutes
#crit = 5 * 60 # 5 minutes

if not os.path.exists(ipc):
    print("IPC file $ipc does not exists!")
    sys.exit(3) # unknown

def getLastBlock():
    if not os.path.exists(lastBlockStore):
        return None, None
    
    stat = os.stat(lastBlockStore)
    modified = stat.st_mtime
    f = open(lastBlockStore)
    line = f.readline()
    blockNumber = int(line.strip())
    f.close()
    return blockNumber, modified

def saveAsLastBlock(blockNumber):
    f = open(lastBlockStore,'w')
    f.write(str(blockNumber))
    f.close()

def getCurrentBlock():
    req = """{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":123}"""
    try:
        client = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
        client.connect(ipc)
        client.send(req.encode('utf-8'))
        resp = client.recv(512).decode('utf-8')
        respJson = json.loads(resp)
        blockNumber = int(respJson['result'], 16)
        return blockNumber
    except:
        print("Unable to get current block:", sys.exc_info()[0])
        sys.exit(3) # unknown

# main
try:
    lastBlock, modified = getLastBlock()
    newBlock = getCurrentBlock()
    
    if (lastBlock != newBlock):
        saveAsLastBlock(newBlock)
        print("Changed right now (old block "+str(lastBlock)+", new block "+str(newBlock)+")"
            + "|time=0s;"+str(warn)+";"+str(crit)+";0;")
        sys.exit(0) # OK
    else: # have not changed
        diff = time.time() - modified
        print("Changed " + str(datetime.timedelta(seconds=diff)) + " seconds ago (block "+str(newBlock)+")"
            + "|time="+str(diff)+"s;"+str(warn)+";"+str(crit)+";0;")
        if (diff >= crit):
            sys.exit(2) # crit
        elif (diff >= warn):
            sys.exit(1) # warn
        else:
            sys.exit(0) # OK
except SystemExit:
    raise
except:
    print("Unexpected error:", sys.exc_info()[0], sys.exc_info()[1])
    sys.exit(3) # unknown
    raise

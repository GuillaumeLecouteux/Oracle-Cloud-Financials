import argparse
import json
import gzip
import sys, os

SNAPSHOT_END="SNAPSHOT_END"

if __name__ == '__main__':    
    parser = argparse.ArgumentParser(description='request status record count parser')
    parser.add_argument('--requestfile', type=argparse.FileType('r', encoding='UTF-8'), required=True)
    parser.add_argument('--datafile', type=str, required=True)
    parser.add_argument('--requestid', type=str, required=True)
    args = parser.parse_args()
    requestRecordCount = -1
    dataRecordCount = -1

    for line in args.requestfile.readlines():
        if args.requestid in line and SNAPSHOT_END in line:
            jsonline = json.loads(line)
            requestRecordCount = jsonline['recordCount']
    args.requestfile.close()

    print("request_status record count="+str(jsonline['recordCount']))

    with gzip.open(args.datafile, 'rb') as f:
        for i, l in enumerate(f):
            pass

    dataRecordCount = i+1

    print("File {1} contain {0} lines".format(dataRecordCount, args.datafile))

    if dataRecordCount==requestRecordCount:
        sys.exit(0)
    else:
        sys.exit(1)
    

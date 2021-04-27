import sys
import logging

logger = logging.getLogger(__name__)
logger.setLevel(logging.DEBUG)
message = ''
code = ''
retries = 10

SUCCESS = "SUCCESS"
FAILED = "FAILED"

headers = {'Content-Type': 'application/json', 'Accept': 'application/json'}

if __name__ == '__main__':
    print("The script has the account %s" % (sys.argv[0]))
    print("The script has the username %s" % (sys.argv[1]))
    print("The script has the password %s" % (sys.argv[2]))
    sys.exit(0)

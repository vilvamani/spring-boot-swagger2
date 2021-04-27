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
	if sys.argv[1] == "token":
		print("token")
	else:
		print("password")
	sys.exit(0)

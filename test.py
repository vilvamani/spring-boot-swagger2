import sys
import urllib3
import logging
import requests

logger = logging.getLogger(__name__)
logger.setLevel(logging.DEBUG)

headers = {'Content-Type': 'application/json', 'Accept': 'application/json'}

if __name__ == '__main__':
	status = "SUCCESS"
	try:
		account_id = sys.argv[2]
		username = sys.argv[3]
		password = sys.argv[3]

		headers.update(urllib3.util.make_headers(basic_auth=f"{username}:{password}"))
		API_URL = f"https://api.boomi.com/api/rest/v1/{account_id}/Account/{account_id}"

		resp = requests.get(API_URL, headers=headers)
		resp.raise_for_status()
		jsonresp = resp.json()

		boomistatus = (jsonresp["status"])
		boomient = (jsonresp["licensing"]["enterprise"]["purchased"])
		boomientused = (jsonresp["licensing"]["enterprise"]["used"])

		if boomistatus == "active":
			logging.info("Account active")
		else:
			logging.info('Exception: Boomi account is inactive')

		if boomient > boomientused:
			logging.info("License available")
		else:
			logging.info('Exception: No enterprise license available')

	except requests.exceptions.RequestException as err:
		status = "FAILED"

	except Exception as e:
		status = "FAILED"
	finally:
		print(status)

import requests
import time
import json
import os

API_KEY = "d1g7v8hr01qk4ao1mng0d1g7v8hr01qk4ao1mngg"
BASE_URL = "https://finnhub.io/api/v1"
SYMBOL = "AAPL"
RESOLUTION = "D"  # daily
now = int(time.time())
one_month_ago = now - 30 * 24 * 60 * 60

url = f"{BASE_URL}/stock/candle?symbol={SYMBOL}&resolution={RESOLUTION}&from={one_month_ago}&to={now}&token={API_KEY}"

print("Requesting:", url)
response = requests.get(url)
print("Status code:", response.status_code)
print("Response:", response.text)

# Ensure 'run' directory exists
os.makedirs('run', exist_ok=True)

# Save to file in 'run' folder
with open("run/finnhub_test_result.json", "w") as f:
    f.write(response.text)

print("Saved response to run/finnhub_test_result.json") 
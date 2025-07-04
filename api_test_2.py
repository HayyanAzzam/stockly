import requests
import datetime

# Finnhub API setup (replace with your API key if needed)
API_KEY = 'd1g7v8hr01qk4ao1mng0d1g7v8hr01qk4ao1mngg'
BASE_URL = 'https://finnhub.io/api/v1'

# Stock symbol to test
symbol = 'AAPL'

# Get UNIX timestamps for today and 2 days ago
now = datetime.datetime.now()
two_days_ago = now - datetime.timedelta(days=2)

now_unix = int(now.timestamp())
two_days_ago_unix = int(two_days_ago.timestamp())

# Fetch candle data (daily resolution)
url = f"{BASE_URL}/stock/candle?symbol={symbol}&resolution=D&from={two_days_ago_unix}&to={now_unix}&token={API_KEY}"
response = requests.get(url)
data = response.json()

if data.get('s') != 'ok' or not data.get('c'):
    print(f"Failed to fetch data for {symbol}: {data}")
else:
    closes = data['c']
    if len(closes) < 2:
        print(f"Not enough data to calculate 2-day change for {symbol}.")
    else:
        change = closes[-1] - closes[0]
        percent = (change / closes[0]) * 100
        print(f"{symbol} changed by {change:.2f} ({percent:.2f}%) over the last 2 days.") 
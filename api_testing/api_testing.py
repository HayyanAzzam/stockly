import requests
import json
import datetime

# --- Configuration ---
SYMBOLS_TO_TEST = ['AAPL', '^GSPC', '^NDX', '^DJI', '^RUT']
OUTPUT_FILE = 'api_test_results.txt'

def test_finnhub_api():
    """
    Tests the Finnhub API for a list of symbols and saves the results to a file.
    """
    api_key = "d186hq1r01ql1b4m49e0d186hq1r01ql1b4m49eg"

    print(f"Starting API test... Results will be saved to '{OUTPUT_FILE}'")

    try:
        with open(OUTPUT_FILE, 'w') as f:
            f.write(f"Finnhub API Test Results\n")
            f.write(f"Timestamp: {datetime.datetime.utcnow().isoformat()} UTC\n")
            f.write("="*40 + "\n\n")

            for symbol in SYMBOLS_TO_TEST:
                print(f"Testing symbol: {symbol}...")
                url = f"https://finnhub.io/api/v1/quote?symbol={symbol}&token={api_key}"
                
                try:
                    response = requests.get(url, timeout=10) # 10-second timeout
                    
                    f.write(f"--- Symbol: {symbol} ---\n")
                    f.write(f"Request URL: {url.replace(api_key, 'YOUR_API_KEY_HIDDEN')}\n")

                    # Check if the request was successful
                    if response.status_code == 200:
                        data = response.json()
                        f.write("Status: Success (200 OK)\n")
                        f.write("Response Body (JSON):\n")
                        f.write(json.dumps(data, indent=2))
                        f.write("\n\n")
                    else:
                        error_message = f"Status: Error ({response.status_code})\nResponse Text: {response.text}\n\n"
                        print(f"An error occurred for {symbol}. See output file for details.")
                        f.write(error_message)

                except requests.exceptions.RequestException as e:
                    error_message = f"Status: Network Error\nException: {e}\n\n"
                    print(f"A network error occurred for {symbol}: {e}")
                    f.write(error_message)

        print(f"\nTest complete. The results have been saved to '{OUTPUT_FILE}'.")
        print("Please upload this file in our chat so I can analyze the results.")

    except IOError as e:
        print(f"Error: Could not write to file '{OUTPUT_FILE}'. Please check permissions. Details: {e}")

if __name__ == "__main__":
    test_finnhub_api()

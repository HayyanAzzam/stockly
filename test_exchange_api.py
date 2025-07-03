# Hardcoded exchange rates for demonstration
EXCHANGE_RATES = {
    'EUR': 0.92,   # Example: 1 USD = 0.92 EUR
    'GBP': 0.79,  # Example: 1 USD = 0.79 GBP
}

def print_exchange_rates():
    print('Hardcoded exchange rates (base USD):')
    for symbol, rate in EXCHANGE_RATES.items():
        print(f'USD -> {symbol}: {rate}')

if __name__ == '__main__':
    print_exchange_rates() 
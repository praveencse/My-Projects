# example.py
#
# Example of calculating with dictionaries

prices = {
   'ACME': 45.23,
   'AAPL': 612.78,
   'IBM': 205.55,
   'HPQ': 37.20,
   'FB': 10.75
}

discounts = {
    'ACME': 12,
    'AAPL': 2,
    'IBM' : 3,
    'HPQ' : 5
}
# Find min and max price
min_price = min(zip(prices.values(), prices.keys()))
max_price = max(zip(prices.values(), prices.keys()))

print('min price:', min_price)
print('max price:', max_price)

print('sorted prices:')
prices_sorted = sorted(zip(prices.values(), prices.keys()))
discounts_sorted = sorted(zip(discounts.values(),discounts.keys()))

for discount, name in discounts_sorted:
    print('   ',name,discount)
for price, name in prices_sorted:
    print('    ', name, price)



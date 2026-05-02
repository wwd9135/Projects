pythonnumbers = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
# Return two separate lists: evens and odds
# Use list comprehensions
one = []
two = []
[one.append(n) if n % 2 == 0
  else two.append(n)
  for n in pythonnumbers]
#print(one, two)


words = ["banana", "apple", "cherry", "date", "elderberry"]
# Sort alphabetically
# Sort by length shortest first
# Sort by length then alphabetically for ties
new = sorted(words)
new = sorted(words, key=len)


orders = [
    {"customer": "William", "amount": 999},
    {"customer": "John", "amount": 499},
    {"customer": "Sarah", "amount": 299},
    {"customer": "William", "amount": 299},
    {"customer": "John", "amount": 999}
]
# Calculate total spend per customer
# Return as a dictionary
# Expected: {"William": 1298, "John": 1498, "Sarah": 299}
new = {}
for order in orders:
    #print(order['customer'])  # gives you "William"
    #print(order['amount'])    # gives you 999
    if new.get(order["customer"],0) == 0:
        new["customer"] = order["customer"]
    print(new)

numbers = [1, 2, 2, 3, 3, 3, 4, 4, 4, 4]
# Count occurrences of each number
# Return as dictionary
# Expected: {1:1, 2:2, 3:3, 4:4}

employees = [
    {"name": "William", "dept": "Eng", "salary": 95000},
    {"name": "Sarah", "dept": "Eng", "salary": 92000},
    {"name": "John", "dept": "Sales", "salary": 87000},
    {"name": "Lisa", "dept": "Sales", "salary": 81000}
]
# Find the highest paid employee
# Return their name and salary

numbers = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
# Without using sum()
# Write a function that calculates the average
# Round to 2 decimal places

orders = [
    {"customer": "William", "product": "Laptop", "amount": 999},
    {"customer": "John", "product": "Phone", "amount": 499},
    {"customer": "William", "product": "Phone", "amount": 499},
    {"customer": "Sarah", "product": "Laptop", "amount": 999},
    {"customer": "John", "product": "Laptop", "amount": 999}
]
# Group orders by customer
# Return dictionary where key is customer
# Value is list of their products
# Expected: {"William": ["Laptop", "Phone"], ...}

text = "the cat sat on the mat the cat ate the rat"
# Count word frequencies
# Return top 3 most common words and their counts

employees = [
    {"name": "William", "dept": "Eng", "salary": 95000},
    {"name": "Sarah", "dept": "Eng", "salary": 92000},
    {"name": "John", "dept": "Sales", "salary": 87000},
    {"name": "Lisa", "dept": "Sales", "salary": 81000},
    {"name": "Anna", "dept": "HR", "salary": 71000}
]
# Calculate average salary per department
# Return employees who earn above their department average
# Show name, dept, salary, dept_average

transactions = [
    ("William", "2024-01-05", 999),
    ("John", "2024-01-08", 499),
    ("William", "2024-02-15", 299),
    ("Sarah", "2024-01-20", 599),
    ("John", "2024-02-22", 999),
    ("Sarah", "2024-03-15", 299)
]
# Find each customer's most recent transaction
# Return as list of tuples (customer, date, amount)
# Hint: dates are strings but formatted so alphabetical = chronological
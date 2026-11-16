import formulas

func = formulas.Parser().ast("=(1 + 1) + B3 / A2")[1].compile()

print(list(func.inputs))
# Output: ['A2', 'B3']

result = func(1, 5)
print(result)
# Output: 7.0

assert float(result) == 7.0

import formulas

xl_model = formulas.ExcelModel().loads("workbook.xlsx").finish()

solution = xl_model.calculate()

result = solution["'[workbook.xlsx]SHEET1'!B1"].value[0][0]
print(result)
# Output: 30.0

assert float(result) == 30.0

xl_model.write(dirpath="output")

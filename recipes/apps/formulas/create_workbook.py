import openpyxl

wb = openpyxl.Workbook()
ws = wb.active
ws.title = "SHEET1"

ws["A1"] = 10
ws["A2"] = 20
ws["B1"] = "=A1+A2"

wb.save("workbook.xlsx")

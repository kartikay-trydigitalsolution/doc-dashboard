#!/usr/bin/env python3
"""
Script to set column widths and formatting for Excel files.
Sets columns C to G to appropriate widths and centers text in specific cells.
"""

import sys
import openpyxl
from openpyxl.styles import Alignment

def set_column_widths(excel_path):
    """
    Set column widths and center text in specific cells.
    
    Args:
        excel_path (str): Path to the Excel file
    """
    try:
        # Load the workbook
        wb = openpyxl.load_workbook(excel_path)
        
        # Set column widths for all sheets
        for sheet_name in wb.sheetnames:
            ws = wb[sheet_name]

            ws.column_dimensions['A'].width = 46
            ws.column_dimensions['B'].width = 18
            
            # Set columns C to G (columns 3-7) to appropriate widths
            ws.column_dimensions['C'].width = 18
            ws.column_dimensions['D'].width = 16
            ws.column_dimensions['E'].width = 16
            ws.column_dimensions['F'].width = 16    
            ws.column_dimensions['G'].width = 16
            ws.column_dimensions['H'].width = 16
            ws.column_dimensions['I'].width = 16
            
            # Center text in cells C22 to G60 (updated range for moved tables)
            center_alignment = Alignment(horizontal='center', vertical='center')
            for row in range(22, 70):  # rows 22 to 60
                for col in ['C', 'D', 'E', 'F', 'G', 'H', 'I']:
                    cell = ws[f'{col}{row}']
                    cell.alignment = center_alignment
            
            print(f"Set column widths and formatting for sheet: {sheet_name}")
        
        # Save the workbook
        wb.save(excel_path)
        print(f"Successfully updated column widths and formatting in: {excel_path}")
        
    except Exception as e:
        print(f"Error setting column widths and formatting: {e}")
        sys.exit(1)

if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: format.py <excel_path>")
        sys.exit(1)
    
    excel_path = sys.argv[1]
    set_column_widths(excel_path)

#!/usr/bin/env python3

with open('main.py', 'r') as f:
    lines = f.readlines()

# Find the problematic section starting from line 29 (index 28)
new_lines = []
i = 0
while i < len(lines):
    line = lines[i]
    
    # Check if we're at the problematic decorator line
    if line.strip() == '@app.get("/")' and i + 1 < len(lines) and lines[i + 1].strip().startswith('"""'):
        # Add the decorator
        new_lines.append(line)
        
        # Skip the standalone docstring - find where it ends
        i += 1  # Skip the opening """
        while i < len(lines) and not (lines[i].strip() == '"""' and 'async def health_check' in lines[i + 1] if i + 1 < len(lines) else False):
            i += 1
        
        # Skip the closing """ line
        if i < len(lines) and lines[i].strip() == '"""':
            i += 1
            
        # Add the function definition
        new_lines.append('async def health_check():\n')
    else:
        new_lines.append(line)
    
    i += 1

# Write the fixed content
with open('main.py', 'w') as f:
    f.writelines(new_lines)

print("Fixed the syntax error in main.py")
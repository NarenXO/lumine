f = open('main.py', 'r')
content = f.read()
f.close()

if 'claude-haiku' in content:
    print('CLAUDE MODEL FOUND - file is correct')
elif 'gpt-5-mini' in content:
    print('OLD MODEL FOUND - file was not saved')
else:
    print('UNKNOWN STATE')
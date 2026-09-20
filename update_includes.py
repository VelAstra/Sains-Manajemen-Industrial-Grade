import glob
import os

files = glob.glob('MQL5/Experts/*.mq5')
for fpath in files:
    with open(fpath, 'r', encoding='utf-8') as f:
        text = f.read()
    text = text.replace(r'#include "..\Include\AstraInstrumentProfile.mqh"', '#include <AstraInstrumentProfile.mqh>')
    text = text.replace(r'#include "..\Include\AstraRiskManager.mqh"', '#include <AstraRiskManager.mqh>')
    text = text.replace(r'#include "..\Include\AstraSignalEngine.mqh"', '#include <AstraSignalEngine.mqh>')
    with open(fpath, 'w', encoding='utf-8') as f:
        f.write(text)
    print(f'Updated: {fpath}')

print('All files updated.')

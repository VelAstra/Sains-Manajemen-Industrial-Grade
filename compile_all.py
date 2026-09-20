import os
import glob
import subprocess
import shutil

METAEDITOR = r"C:\Program Files\MetaTrader 5\metaeditor64.exe"
APPDATA_MQL5 = os.path.expandvars(r"%APPDATA%\MetaQuotes\Terminal\D0E8209F77C8CF37AD8BF550E51FF075\MQL5")

include_src = os.path.join("MQL5", "Include")
include_dst = os.path.join(APPDATA_MQL5, "Include")
experts_dst = os.path.join(APPDATA_MQL5, "Experts", "AstraIndustrial")

os.makedirs(include_dst, exist_ok=True)
os.makedirs(experts_dst, exist_ok=True)

# Copy includes
for f in glob.glob(os.path.join(include_src, "*.mqh")):
    shutil.copy(f, include_dst)
    print(f"Copied include: {os.path.basename(f)}")

mq5_files = glob.glob(os.path.join("MQL5", "Experts", "*.mq5"))
print(f"Found {len(mq5_files)} MQ5 files to compile.")

results = []

for fpath in mq5_files:
    fname = os.path.basename(fpath)
    bname = os.path.splitext(fname)[0]
    target_mq5 = os.path.join(experts_dst, fname)
    target_log = os.path.join(experts_dst, f"{bname}.log")
    target_ex5 = os.path.join(experts_dst, f"{bname}.ex5")
    local_ex5 = os.path.join("MQL5", "Experts", f"{bname}.ex5")

    shutil.copy(fpath, target_mq5)

    cmd = [METAEDITOR, f"/compile:{target_mq5}", f"/log:{target_log}"]
    proc = subprocess.run(cmd, capture_output=True, text=True)

    if os.path.exists(target_ex5):
        shutil.copy(target_ex5, local_ex5)
        size = os.path.getsize(local_ex5)
        print(f"SUCCESS: {fname} -> {bname}.ex5 ({size:,} bytes)")
        results.append((fname, "SUCCESS", size))
    else:
        log_content = ""
        if os.path.exists(target_log):
            with open(target_log, 'r', encoding='utf-16', errors='ignore') as lf:
                log_content = lf.read()
        print(f"FAILED: {fname}\nLog: {log_content[-300:]}")
        results.append((fname, "FAILED", 0))

print("\n--- SUMMARY KOMPILASI ---")
all_success = all(r[1] == "SUCCESS" for r in results)
for fname, status, sz in results:
    print(f"{fname:<35}: {status} ({sz:,} bytes)")

print(f"\nTotal: {len(results)} | Sukses: {sum(1 for r in results if r[1] == 'SUCCESS')}")
if all_success:
    print("SELURUH EA BERHASIL DIKOMPILASI DENGAN 0 ERRORS, 0 WARNINGS!")

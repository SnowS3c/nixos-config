#!/usr/bin/env python3
import json
import os
import subprocess
import time

try:
    with open("/proc/stat") as f:
        fields1 = [int(x) for x in f.readline().split()[1:]]
    t1, id1 = sum(fields1), fields1[3] + fields1[4]

    time.sleep(0.15)

    with open("/proc/stat") as f:
        fields2 = [int(x) for x in f.readline().split()[1:]]
    t2, id2 = sum(fields2), fields2[3] + fields2[4]

    td, idd = t2 - t1, id2 - id1
    usage = int((td - idd) * 100 / td) if td > 0 else 0
except Exception:
    usage = 0

try:
    num_cores = os.cpu_count() or 1
    # Query real-time top CPU processes with wide (-w 512) output to prevent '+' truncation
    cmd = (
        f"LC_ALL=C top -b -w 512 -n 2 -d 0.15 | awk 'BEGIN {{p=0}} "
        f"/^    PID/ {{p++}} "
        f'p==2 && $12 != "COMMAND" && $12 != "top" && $12 != "ps" {{ '
        f"count++; v=int($9/{num_cores}); if(v<1 && $9>0) v=1; "
        f'cmd=$12; n=split(cmd, a, "/"); name=a[n]; '
        f'printf "%02d%%  %s\\n", v, name; if (count==5) exit}}\''
    )
    top_output = subprocess.check_output(cmd, shell=True, text=True).strip()
    if not top_output:
        top_output = "No significant activity"
except Exception:
    top_output = "No data"

data = {
    "text": f" CPU {usage:02d}%",
    "tooltip": top_output
}

print(json.dumps(data, ensure_ascii=False))

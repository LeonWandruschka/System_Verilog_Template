#!/usr/bin/env python

import json
import sys
import re

def parse_filemap(meta_json):
    return {
        file_id: info["realpath"]
        for file_id, info in meta_json.get("files", {}).items()
        if "realpath" in info
    }

def get_file_id(loc):
    return loc.split(',')[0]

def get_line_range(loc):
    match = re.search(r"[a-z],(\d+):\d+,(\d+):\d+", loc)
    if match:
        return int(match.group(1)), int(match.group(2))
    return 0, 0

def json2stems(meta_json, netlist_json, out):
    filemap = parse_filemap(meta_json)
    pointer_to_module_name = {
        mod["addr"]: mod["name"]
        for mod in netlist_json.get("modulesp", [])
        if "addr" in mod and "name" in mod
    }

    for mod in netlist_json.get("modulesp", []):
        if "name" not in mod or "loc" not in mod:
            continue

        loc = mod["loc"]
        mod_name = mod["name"]
        file_id = get_file_id(loc)
        start_line, end_line = get_line_range(loc)

        realpath = filemap.get(file_id)
        if realpath:
            out.write(f"++ module {mod_name} file {realpath} lines {start_line} - {end_line}\n")

        for stmt in mod.get("stmtsp", []):
            if stmt.get("type") == "CELL" and "name" in stmt:
                inst_name = stmt["name"]
                target_mod_name = pointer_to_module_name.get(stmt.get("modp"), "UNKNOWN")
                out.write(f"++ comp {inst_name} type {target_mod_name} parent {mod_name}\n")

def main():
    if len(sys.argv) != 4:
        print("Usage: json2stems <meta.json> <netlist.json> <output.stem>")
        sys.exit(1)

    try:
        with open(sys.argv[1]) as f1, open(sys.argv[2]) as f2:
            j1 = json.load(f1)
            j2 = json.load(f2)
    except Exception as e:
        print(f"JSON parse or file error: {e}")
        sys.exit(1)

    # Identify meta and netlist
    if "files" in j1 and "files" not in j2:
        meta_json, netlist_json = j1, j2
    elif "files" in j2 and "files" not in j1:
        meta_json, netlist_json = j2, j1
    else:
        print("Unable to distinguish meta and netlist JSON.")
        sys.exit(1)

    with open(sys.argv[3], "w") as out_file:
        json2stems(meta_json, netlist_json, out_file)

if __name__ == "__main__":
    main()


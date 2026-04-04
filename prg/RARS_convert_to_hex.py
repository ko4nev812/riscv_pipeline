#!/usr/bin/env python3

import os
import sys
import subprocess
from pathlib import Path

# ============================================================
# CONFIGURATION
# ============================================================

# Input directory with source files (.s, .asm)
IN_DIR = Path("./tests")

# Output directory for .hex files
OUT_DIR = Path("./hex_out")

# Path to RARS (either .jar file or executable)
RARS_PATH = Path("./rars1_6.jar")

# Additional flags for RARS
#RARS_FLAGS = ["--quiet", "--dump", ".text", ".data", "HEX"]
#RARS_FLAGS = []

# ============================================================
# FUNCTIONS
# ============================================================

def find_asm_files(directory: Path):
    """Recursively find all .s and .asm files in directory"""
    asm_files = []
    for ext in ["*.s", "*.asm", "*.S"]:
        asm_files.extend(directory.rglob(ext))
    return asm_files


def convert_to_hex(asm_file: Path, hex_file: Path) -> bool:
    """Run RARS to convert .s/.asm file to .hex"""
    

    if str(RARS_PATH).endswith(".jar"):
            cmd = [
                "java", "-jar", str(RARS_PATH),
                "a",
                "nc",
                str(asm_file),
                "dump", ".text", "HexText", str(hex_file)
            ]
    else:
        cmd = [
            str(RARS_PATH),
            "a",
            "nc",
            str(asm_file),
            "dump", ".text", "HexText", str(hex_file)
        ]
    
    try:
        retcode = subprocess.call(cmd, stdin=subprocess.DEVNULL, timeout=60)
        
        if retcode != 0:
            print(f"  ERROR processing {asm_file.name}")
            return False
        
        return True
        
    except subprocess.TimeoutExpired:
        print(f"  TIMEOUT processing {asm_file.name}")
        return False
    except FileNotFoundError:
        print(f"  RARS not found at: {RARS_PATH}")
        print("  Check RARS_PATH configuration")
        sys.exit(1)
    except Exception as e:
        print(f"  ERROR: {e}")
        return False


def main():
    """Main function"""
    
    if not IN_DIR.exists():
        print(f"Error: input directory '{IN_DIR}' not found!")
        sys.exit(1)
    
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    
    asm_files = find_asm_files(IN_DIR)
    
    if not asm_files:
        print(f"No .s or .asm files found in {IN_DIR}")
        sys.exit(0)
    
    print(f"Found {len(asm_files)} files to convert")
    print("=" * 50)
    
    success_count = 0
    fail_count = 0
    
    for asm_file in asm_files:
        rel_path = asm_file.relative_to(IN_DIR)
        hex_name = rel_path.with_suffix(".hex")
        hex_file = OUT_DIR / hex_name
        
        hex_file.parent.mkdir(parents=True, exist_ok=True)
        
        print(f"Converting: {rel_path} -> {hex_name}")
        
        if convert_to_hex(asm_file, hex_file):
            success_count += 1
            print(f"  OK")
        else:
            fail_count += 1
            print(f"  FAILED")
    
    print("=" * 50)
    print(f"Done! Success: {success_count}, Failed: {fail_count}")
    print(f"Output files saved to: {OUT_DIR}")


if __name__ == "__main__":
    main()
import base64
import ctypes
import json
import os
from pathlib import Path
import struct
import sys


SHELLS = {b"bash", b"dash", b"fish", b"ksh", b"sh", b"tcsh", b"zsh"}
AGENTS = {b"claude", b"claude.js", b"codex", b"codex.js"}


def process_args(pid):
    # Darwin supplies argc, the executable path, padding, argv, and then envp.
    sysctl = ctypes.CDLL(None, use_errno=True).sysctl
    sysctl.argtypes = [
        ctypes.POINTER(ctypes.c_int), ctypes.c_uint, ctypes.c_void_p,
        ctypes.POINTER(ctypes.c_size_t), ctypes.c_void_p, ctypes.c_size_t,
    ]
    mib = (ctypes.c_int * 3)(1, 49, pid)  # CTL_KERN, KERN_PROCARGS2
    size = ctypes.c_size_t()
    if sysctl(mib, 3, None, ctypes.byref(size), None, 0):
        raise OSError(ctypes.get_errno(), "Could not size process arguments")
    buffer = ctypes.create_string_buffer(size.value)
    if sysctl(mib, 3, buffer, ctypes.byref(size), None, 0):
        raise OSError(ctypes.get_errno(), "Could not read process arguments")

    data = buffer.raw[:size.value]
    argc = struct.unpack_from("i", data)[0]
    executable, rest = data[struct.calcsize("i"):].split(b"\0", 1)
    argv = rest.lstrip(b"\0").split(b"\0", argc)
    if argc < 1 or len(argv) <= argc:
        raise ValueError("Incomplete process argument list")
    return executable, argv[:argc]


def capture(pid, path):
    executable, argv = process_args(pid)
    if os.path.realpath(executable) != os.path.realpath(os.fsencode(path)):
        return

    name = os.path.basename(executable)
    if name in SHELLS and all(
        arg.startswith(b"-") and b"c" not in arg[1:] for arg in argv[1:]
    ):
        print(json.dumps({"kind": "shell"}))
    elif name in AGENTS or (
        name in {b"node", b"nono"} and any(os.path.basename(arg) in AGENTS for arg in argv[1:])
    ):
        print(json.dumps({"kind": "agent"}))
    else:
        print(json.dumps({
            "kind": "command",
            "argv": [base64.b64encode(arg).decode("ascii") for arg in argv],
        }))


def launch(claim):
    with claim.open() as saved:
        record = json.load(saved)
    claim.unlink()
    path = record["executable"]
    argv = [base64.b64decode(arg, validate=True) for arg in record["argv"]]
    if not os.path.isabs(path) or not argv:
        raise ValueError("Invalid saved command")
    os.execv(path, argv)


if __name__ == "__main__":
    try:
        if sys.argv[1] == "capture":
            capture(int(sys.argv[2]), sys.argv[3])
        elif sys.argv[1] == "launch":
            launch(Path(sys.argv[2]))
    except (OSError, ValueError, KeyError, struct.error) as error:
        if sys.argv[1] == "launch":
            print(f"Rex could not relaunch the saved command: {error}", file=sys.stderr)
        sys.exit(1)

"""Execute the controller tests with OBS's own LuaJIT DLL (no pip required)."""
import ctypes
import os
import sys
from pathlib import Path

root = Path(__file__).resolve().parents[1]
os.chdir(root)
with os.add_dll_directory(r"C:\Program Files\obs-studio\bin\64bit"):
    lua = ctypes.CDLL(r"C:\Program Files\obs-studio\bin\64bit\lua51.dll")
lua.luaL_newstate.restype = ctypes.c_void_p
lua.luaL_openlibs.argtypes = [ctypes.c_void_p]
lua.luaL_loadfile.argtypes = [ctypes.c_void_p, ctypes.c_char_p]
lua.lua_pcall.argtypes = [ctypes.c_void_p, ctypes.c_int, ctypes.c_int, ctypes.c_int]
lua.lua_tolstring.argtypes = [ctypes.c_void_p, ctypes.c_int, ctypes.c_void_p]
lua.lua_tolstring.restype = ctypes.c_char_p
lua.lua_close.argtypes = [ctypes.c_void_p]
state = lua.luaL_newstate()
try:
    lua.luaL_openlibs(state)
    status = lua.luaL_loadfile(state, (sys.argv[1] if len(sys.argv) > 1 else "tests/mock-controller.lua").encode())
    if status == 0:
        status = lua.lua_pcall(state, 0, 0, 0)
    if status:
        raise RuntimeError(lua.lua_tolstring(state, -1, None).decode("utf-8"))
finally:
    lua.lua_close(state)

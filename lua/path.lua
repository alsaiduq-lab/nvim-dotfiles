-- Configure Lua and C module search paths for LuaRocks packages
-- NOTE: was some weird bug on Arch, not sure if its still here
local home = os.getenv("HOME")
if not home then
  vim.notify("HOME environment variable not set", vim.log.levels.WARN)
  return
end

local luarocks_paths = {
  home .. "/.luarocks/share/lua/5.1/?.lua",
  home .. "/.luarocks/share/lua/5.1/?/init.lua"
}
package.path = package.path .. ";" .. table.concat(luarocks_paths, ";")

local luarocks_cpath = {
  home .. "/.luarocks/lib/lua/5.1/?.so"
}
package.cpath = package.cpath .. ";" .. table.concat(luarocks_cpath, ";")

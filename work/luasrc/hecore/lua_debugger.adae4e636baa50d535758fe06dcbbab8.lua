package.loaded["hecore.mobdebug"]=nil
bp_wapper:init()
_G.g_UseCHookFilter = true
local r = require("hecore.mobdebug").start(lua_debug_ide_ip, "8172")
if r then
  local function _log(str, level, func)
    func(str)
    local outstr = level .. ": " .. str
    require("hecore.mobdebug").send_log(outstr)
  end
  local _info_func = he_log_info
  function he_log_info(str)
    _log(str, "INFO", _info_func)
  end
  local _warning_func = he_log_warning
  function he_log_warning(str)
    _log(str, "WARNING", _warning_func)
  end
  local _error_func = he_log_error
  function he_log_error(str)
    _log(str, "ERROR", _error_func)
  end
  local _fatal_func = he_log_fatal
  function he_log_fatal(str)
    _log(str, "FATAL", _fatal_func)
  end
  local _ori_print_func = print
  print = function(...)
    _ori_print_func(...)
    local temp = {}
    for k, v in pairs({...}) do	table.insert(temp, tostring(v)) end
    local outstr = "LUA-print: " .. table.concat(temp, "\t")
    require("hecore.mobdebug").send_log(outstr)
  end
  he_log_info("Start remote debug success ...")
else
  he_log_warning("Start remote debug fail ...")
end


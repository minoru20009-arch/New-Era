-- Thin wrapper around Steamodded's logger. All New Era messages use the "NewEra" logger name.

local LOGGER = 'NewEra'
local format = string.format
local select = select

NE.log = NE.log or {}

local function emit(sink, msg, ...)
    if select('#', ...) > 0 then
        local ok, formatted = pcall(format, msg, ...)
        msg = ok and formatted or (tostring(msg) .. ' [format error]')
    end
    sink(tostring(msg), LOGGER)
end

function NE.log.debug(msg, ...)
    if NE.debug_enabled() then emit(sendDebugMessage, msg, ...) end
end

function NE.log.info(msg, ...)
    emit(sendInfoMessage, msg, ...)
end

function NE.log.warn(msg, ...)
    emit(sendWarnMessage, msg, ...)
end

function NE.log.error(msg, ...)
    emit(sendErrorMessage, msg, ...)
end

-- Logs a warning only the first time `key` is seen during this session.
local warned = {}
function NE.log.warn_once(key, msg, ...)
    if warned[key] then return end
    warned[key] = true
    NE.log.warn(msg, ...)
end

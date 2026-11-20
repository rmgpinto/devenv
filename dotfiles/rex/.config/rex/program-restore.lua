---@diagnostic disable: undefined-global

if os.getenv("REX_PROGRAM_RESTORE") == "off" then
  return
end

local home = os.getenv("HOME")
local previous_state = home .. "/dev/.rex-program-restore"
local state_override = os.getenv("REX_PROGRAM_RESTORE_STATE")
local state = state_override or previous_state .. "/programs"
local helper = home .. "/dev/personal/devenv/dotfiles/rex/.config/rex/process-launch.py"
local python = "/usr/bin/python3"
local operations_control = home .. "/dev/personal/operations-control/bin/operations-control"
local server = rex.call("server.status", {})
if not server or not server.instance_id then
  return
end

local instance = server.instance_id
local function record_path(block, directory)
  if type(block) == "string" and block:match("^block:[%w-]+$") then
    return (directory or state) .. "/" .. block .. ".json"
  end
end

local function read_record(path)
  local file = io.open(path, "r")
  if file then
    local data = file:read("*a")
    file:close()
    local record = rex.json.decode(data)
    if type(record) == "table" then
      return record
    end
  end
end

local function saved_record(block, path)
  local record = read_record(path)
  if not record and not state_override then
    local previous_path = record_path(block, previous_state)
    return read_record(previous_path), previous_path
  end
  return record, path
end

local function save_record(path, record)
  record.instance = instance
  local temp = rex.exec({ "/usr/bin/mktemp", path .. ".XXXXXX" })
  if not temp or temp.code ~= 0 then
    error("Rex program restore could not create a snapshot file")
  end
  local name = temp.stdout:gsub("\n$", "")
  local file = assert(io.open(name, "w"))
  local written, err = file:write(rex.json.encode(record))
  local closed, close_err = file:close()
  if written and closed then
    written, err = os.rename(name, path)
    if written then
      return
    end
  end
  os.remove(name)
  error(err or close_err)
end

local tools = { nvim = true, lazygit = true }
local shells = { bash = true, dash = true, fish = true, ksh = true, sh = true, tcsh = true, zsh = true }
local launchers = { codex = "codex", cx = "codex", claude = "claude", cc = "claude" }
local function restore_args(record, claim)
  if type(record.cwd) ~= "string" or record.cwd:sub(1, 1) ~= "/" then
    return
  end
  local program = record.program
  if record.executable and record.argv and claim then
    return { record.cwd, python, helper, "launch", claim }
  end
  if tools[program] then
    return { record.cwd, program }
  end
  if program == "snacks-lazygit" then
    return { record.cwd, "nvim", "+lua vim.schedule(function() Snacks.lazygit() end)" }
  end
  if program == "hunk" then
    return { record.cwd, "hunk", "diff", "HEAD~" }
  end
  if program == "operations-control" then
    return { record.cwd, operations_control }
  end
  if type(record.id) ~= "string" or not record.id:match("^[%w][%w-]+$") then
    return
  end
  if launchers[program] == "codex" then
    return { record.cwd, program, "resume", record.id }
  end
  if launchers[program] == "claude" then
    return { record.cwd, program, "--resume", record.id }
  end
end

local mode = rex.args.mode
if mode and mode ~= "snapshot" then
  local path = record_path(rex.block_id)
  if not path then
    return
  end
  if mode == "register" then
    local event = rex.json.decode(io.stdin:read("*a"))
    local agent = rex.args.agent
    if type(event) ~= "table" or (agent ~= "codex" and agent ~= "claude") then
      return
    end
    local wrapper = os.getenv("REX_PROGRAM_RESTORE_LAUNCHER")
    local program = launchers[wrapper] == agent and wrapper or agent
    local record = { program = program, cwd = event.cwd, id = event.session_id }
    if restore_args(record) then
      save_record(path, record)
    end
    return
  end

  local record, source = saved_record(rex.block_id, path)
  if mode == "clear" and record and record.instance == instance then
    os.remove(source)
    if source == path and not state_override then
      local previous_path = record_path(rex.block_id, previous_state)
      local previous = read_record(previous_path)
      if previous and previous.instance == instance then
        os.remove(previous_path)
      end
    end
  elseif mode == "take" and record and record.instance ~= instance then
    local claim = path .. ".claimed"
    local args = restore_args(record, claim)
    if args and os.rename(source, claim) then
      if source == path and not state_override then
        os.remove(record_path(rex.block_id, previous_state))
      end
      if not record.executable then
        os.remove(claim)
      end
      return args
    end
  end
  return
end

local function terminal_process(session, block)
  return rex.call("com.superlogical.terminal.process", {
    session_id = session, block_id = block, args = {},
  })
end

local function capture(process)
  if not process.path then
    return
  end
  local result = rex.exec({ python, helper, "capture", tostring(process.pid), process.path })
  if result and result.code == 0 and result.stdout ~= "" then
    return rex.json.decode(result.stdout)
  end
end

local function snapshot_block(session, block)
  local path = record_path(block)
  if not path then
    return
  end
  local saved, source = saved_record(block, path)
  -- A restored shell can run startup commands before it takes this entry.
  if saved and saved.instance ~= instance then
    return
  end
  local process = terminal_process(session, block)
  local front = process and process.foreground
  if not front then
    return
  end

  local target = front
  local cwd = front.cwd
  for _, parent in ipairs(process.ancestors or {}) do
    if parent.name == "login" then
      break
    end
    if shells[parent.name] then
      local shell = capture(parent)
      if not shell or shell.kind == "shell" then
        cwd = parent.cwd or cwd
        break
      end
    end
    target = parent
    cwd = parent.cwd or cwd
  end

  local command = capture(target)
  if not command then
    return
  end
  -- Recheck the foreground after reading argv so short-lived jobs cannot
  -- replace the saved entry once their shell has taken the terminal back.
  local latest = terminal_process(session, block)
  if not latest or not latest.foreground or latest.foreground.pid ~= front.pid then
    return
  end

  if command.kind == "shell" then
    os.remove(path)
    if not state_override then
      os.remove(record_path(block, previous_state))
    end
  elseif saved and launchers[saved.program] then
    if source ~= path then
      save_record(path, saved)
    end
  elseif command.kind == "command" and cwd then
    save_record(path, {
      program = target.name,
      cwd = cwd,
      executable = target.invoked_path or target.path,
      argv = command.argv,
    })
  end
end

local function snapshot()
  local status = rex.call("server.status", {})
  if not status or status.instance_id ~= instance then
    rex.stop(0)
    return
  end
  local list = rex.call("session.list", {})
  for _, session in ipairs(list and list.sessions or {}) do
    local view = rex.call("session.view", { session_id = session.session_id })
    if not view then
      local attached = rex.call("session.attach", { session_id = session.session_id })
      view = attached and attached.view
    end
    for _, window in ipairs(view and view.windows or {}) do
      for _, layer in ipairs(window.layers or {}) do
        for _, block in ipairs(layer.blocks or {}) do
          if block.flavor == "com.superlogical.terminal.shell" then
            snapshot_block(session.session_id, block.block_id)
          end
        end
      end
    end
  end
end

if mode == "snapshot" then
  snapshot()
  return
end

rex.on("session_created", function(ctx)
  rex.call("session.attach", { session_id = ctx.session_id })
end)

local pending = {}
rex.on("terminal.process_changed", function(ctx)
  local session, block = ctx.session_id, ctx.block_id
  if not session or not block then
    return
  end
  if pending[block] then
    pending[block]:cancel()
  end
  pending[block] = rex.after(0.5, function()
    pending[block] = nil
    snapshot_block(session, block)
  end)
end)
rex.on("block_closed", function(_, event)
  local block = event.block_id
  if pending[block] then
    pending[block]:cancel()
    pending[block] = nil
  end
  local path = record_path(block)
  if path then
    os.remove(path)
    os.remove(path .. ".claimed")
    if not state_override then
      os.remove(record_path(block, previous_state))
    end
  end
end)
rex.every(300, snapshot)
rex.after(0, snapshot)

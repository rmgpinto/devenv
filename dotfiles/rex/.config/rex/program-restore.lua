---@diagnostic disable: undefined-global

if os.getenv("REX_PROGRAM_RESTORE") == "off" then
  return
end

local state = os.getenv("REX_PROGRAM_RESTORE_STATE") or os.getenv("HOME") .. "/dev/.rex-program-restore"
local server = rex.call("server.status", {})
if not server or not server.instance_id then
  return
end

local instance = server.instance_id
local function record_path(block)
  if type(block) == "string" and block:match("^block:[%w-]+$") then
    return state .. "/" .. block .. ".json"
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
local shells = { zsh = true, bash = true, fish = true }
local launchers = { codex = "codex", cx = "codex", claude = "claude", cc = "claude" }
local function restore_args(record)
  if type(record.cwd) ~= "string" or record.cwd:sub(1, 1) ~= "/" then
    return
  end
  local program = record.program
  if tools[program] then
    return { record.cwd, program }
  end
  if program == "snacks-lazygit" then
    return { record.cwd, "nvim", "+lua vim.schedule(function() Snacks.lazygit() end)" }
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
if mode then
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

  local record = read_record(path)
  if mode == "clear" and record and record.instance == instance then
    os.remove(path)
  elseif mode == "take" and record and record.instance ~= instance then
    local claim = path .. ".claimed"
    if os.rename(path, claim) then
      os.remove(claim)
      return restore_args(record)
    end
  end
  return
end

local function remove_current(block)
  local path = record_path(block)
  local record = path and read_record(path)
  if record and record.instance == instance then
    os.remove(path)
  end
end

local function snapshot_block(session, block)
  local process = rex.call("com.superlogical.terminal.process", {
    session_id = session,
    block_id = block,
    args = {},
  })
  local front = process and process.foreground
  if not front then
    return
  end
  if front.cwd and tools[front.name] then
    local program = front.name
    for _, parent in ipairs(process.ancestors or {}) do
      if program == "lazygit" and parent.name == "nvim" then
        program = "snacks-lazygit"
      end
    end
    save_record(record_path(block), { program = program, cwd = front.cwd })
  elseif shells[front.name] then
    remove_current(block)
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

rex.on("terminal.process_changed", function(ctx, event)
  local front = event.foreground
  if front and (tools[front.name] or shells[front.name]) then
    snapshot_block(ctx.session_id, ctx.block_id)
  end
end)
rex.on("block_closed", function(_, event)
  local path = record_path(event.block_id)
  if path then
    os.remove(path)
  end
end)
rex.every(300, snapshot)
rex.after(0, snapshot)

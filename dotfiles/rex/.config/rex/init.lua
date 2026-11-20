---@diagnostic disable: undefined-global
-- Rex config: bind keys with rex.bind and remove them with rex.unbind.
-- Check with `rex config check`, apply with `rex config reload`.

for _, direction in ipairs({ "left", "right", "up", "down" }) do
  rex.bind("cmd+" .. direction, "pane.focus." .. direction)
end

rex.bind("shift+cmd+[", "client.tab.previous")
rex.bind("shift+cmd+]", "client.tab.next")
-- cmd+e enters tabs mode: arrows (with or without cmd) cycle tabs, p opens a
-- floating shell, and escape, enter, or cmd+e again leave it.
rex.mode("tabs", { exclusive = true })
rex.bind("cmd+e", "client.mode.enter", { name = "tabs" })
for _, modifier in ipairs({ "", "cmd+" }) do
  rex.bind("tabs/" .. modifier .. "up", "client.tab.previous")
  rex.bind("tabs/" .. modifier .. "down", "client.tab.next")
end
rex.bind("tabs/enter", "client.mode.exit")
rex.bind("tabs/cmd+e", "client.mode.exit")

-- cmd+e then p opens a floating shell at 80% of the window, in the focused pane's
-- directory, and leaves tabs mode so the new shell gets the keyboard.
rex.action({
  name = "float",
  title = "Floating Shell",
  run = function(ctx)
    local options = {}
    local ok, process = pcall(rex.block.call, "com.superlogical.terminal", "process", { block_id = ctx.block_id })
    if ok and process and process.foreground and process.foreground.cwd then
      options.cwd = process.foreground.cwd
    end
    rex.session.new_layer({
      bounds = { 0.1, 0.1, 0.8, 0.8 },
      focus = true,
      layout = rex.layout.block({
        flavor = "com.superlogical.terminal.shell",
        options = options,
      }),
    })
    rex.client.queue("client.mode.exit")
  end,
})
rex.bind("tabs/p", "float")

-- Config loads have no API client. Start the watcher as a separate Rex script.
if os.getenv("REX_PROGRAM_RESTORE") ~= "off" then
  local home = os.getenv("HOME")
  local script = home .. "/dev/personal/devenv/dotfiles/rex/.config/rex/program-restore.lua"
  local state = os.getenv("REX_PROGRAM_RESTORE_STATE") or home .. "/dev/.rex-program-restore"
  local binary = os.getenv("REX_PROGRAM_RESTORE_CLI") or
    home .. "/Library/Application Support/com.superlogical.rex/RexServer/Versions/Current/Rex Server.app/Contents/MacOS/rex"
  local server = os.getenv("REX_PROGRAM_RESTORE_SERVER")
  local mkdir = rex.exec({ "/bin/mkdir", "-m", "700", "-p", state })
  if mkdir and mkdir.code == 0 then
    local argv = { "/usr/bin/lockf", "-k", "-t", "0", state .. "/watch.lock", binary }
    if server then
      argv[#argv + 1] = "--server=" .. server
    end
    for _, arg in ipairs({ "do", script, "--all", "--autostart=false" }) do
      argv[#argv + 1] = arg
    end
    rex.exec.start(argv, { detach = true })
  end
end

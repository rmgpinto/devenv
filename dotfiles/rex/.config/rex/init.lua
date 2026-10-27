---@diagnostic disable: undefined-global
-- Rex config: bind keys with rex.bind and remove them with rex.unbind.
-- Check with `rex config check`, apply with `rex config reload`.

for _, direction in ipairs({ "left", "right", "up", "down" }) do
  rex.bind("cmd+" .. direction, "pane.focus." .. direction)
end

rex.bind("shift+cmd+[", "client.tab.previous")
rex.bind("shift+cmd+]", "client.tab.next")
-- cmd+e enters tabs mode: arrows (with or without cmd) cycle tabs,
-- and escape, enter, or cmd+e again leave it.
rex.mode("tabs", { exclusive = true })
rex.bind("cmd+e", "client.mode.enter", { name = "tabs" })
for _, modifier in ipairs({ "", "cmd+" }) do
  rex.bind("tabs/" .. modifier .. "up", "client.tab.previous")
  rex.bind("tabs/" .. modifier .. "down", "client.tab.next")
end
rex.bind("tabs/enter", "client.mode.exit")
rex.bind("tabs/cmd+e", "client.mode.exit")

-- cmd+g opens the guided rex-task launcher in a floating pane; it closes when done.
rex.action{
  name  = "task",
  title = "New Task Session",
  run   = function()
    rex.session.new_layer{
      bounds = { 0.2, 0.2, 0.6, 0.6 },
      focus  = true,
      layout = rex.layout.block{
        flavor  = "com.superlogical.terminal.shell",
        options = {
          shell   = "none",
          command = {
            "/bin/zsh", "-ic",
            "/Users/rmgpinto/dev/personal/devenv/bin/rex-task || read -k1 '?rex-task failed, press any key'",
          },
        },
      },
    }
  end,
}
rex.bind("cmd+g", "task")

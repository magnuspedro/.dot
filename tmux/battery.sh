#!/bin/sh
# Bateria pra status bar do tmux (macOS). Sem bateria (desktop) não mostra nada.
# Ícone muda com o nível; verde na tomada, amarelo <= 40%, vermelho <= 20%.
pmset -g batt | awk -F'[;\t]' '
/InternalBattery/ {
  p = $2 + 0; s = $3
  split("󰁺 󰁻 󰁼 󰁽 󰁾 󰁿 󰂀 󰂁 󰂂 󰁹", icons, " ")
  i = int((p + 5) / 10); if (i < 1) i = 1; if (i > 10) i = 10
  icon = icons[i]; color = "#ebdbb2"
  if (s !~ /discharging/) { icon = "󰂄"; color = "#b8bb26" }
  else if (p <= 20) color = "#fb4934"
  else if (p <= 40) color = "#fabd2f"
  printf "#[fg=%s]%s %d%%", color, icon, p
}'

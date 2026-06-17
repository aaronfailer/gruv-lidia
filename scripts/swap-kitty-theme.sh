#!/bin/bash
KITTY_CONF="$HOME/.config/kitty/kitty.conf"

if [ "$1" = "dark" ]; then
  sed -i 's/include gruvbox-light.conf/include gruvbox-dark.conf/' "$KITTY_CONF"
else
  sed -i 's/include gruvbox-dark.conf/include gruvbox-light.conf/' "$KITTY_CONF"
fi

#!/bin/bash
if ! command -v nvim >/dev/null
then
  am -i nvim
else
  am -u nvim
fi

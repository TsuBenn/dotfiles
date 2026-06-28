#!/usr/bin/env bash

useradd -m -G wheel,video,input,audio -s /bin/zsh tsubennos
passwd -d tsubennos  # no password needed for live env

systemctl enable NetworkManager
systemctl enable keyd

chown -R tsubennos:tsubennos /home/tsubennos

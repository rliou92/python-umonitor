#! /usr/bin/python
import os
from subprocess import run

# hdmi_audio = "alsa_output.pci-0000_01_00.1.hdmi-stereo"
# pc_audio = "alsa_output.pci-0000_00_14.2.analog-stereo"
hdmi_idx = '0'
pc_idx = '1'
idx_dict = {"media": hdmi_idx, "home": pc_idx}

cur_profile = os.getenv("UMONITOR_PROFILE")
cmd_audio = ["pacmd", "set-default-sink"] + list(idx_dict[cur_profile])

run(cmd_audio)

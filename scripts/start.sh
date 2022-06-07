#!/bin/bash
# Snort3 Basic Setup
#
# Description: The following shell script sets up Snort3 with basic configuration
#
# Author: Tariro Mukute
# Version: 1.0.0

set -o errexit
# set -o pipefail
set -o nounset
set -o xtrace

sudo systemctl enable snort3
sudo systemctl restart snort3
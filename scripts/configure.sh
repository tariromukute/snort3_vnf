#!/bin/bash
# Snort3 Basic Setup
#
# Description: The following shell script sets up Snort3 with basic configuration
#
# Author: Tariro Mukute
# Version: 1.0.0

# set -o errexit
# # set -o pipefail
# set -o nounset
# set -o xtrace

PULLEDPORK_RULESET="community_ruleset"
HOME_NET="172.17.0.0/24"
PULLEDPORK_OINKCODE="b9845cd898b7237301ac46065c9447102b6bdfb5"

function setup_community_rules {
    wget https://www.snort.org/downloads/community/community-rules.tar.gz -O community-rules.tar.gz

    tar -xvzf community-rules.tar.gz -C /etc/snort/rules
}

# For a NIDS, we want to disable LRO and GRO, since this can truncate longer packets
# Use a systemD service to diable them so that this persists over reboots
function configure_network_cards {
    cp snort-ethtool.service /lib/systemd/system/snort-ethtool.service

    sudo systemctl enable snort-ethtool
    sudo systemctl restart snort-ethtool
}

function configure_snort {
    sudo mkdir /usr/local/etc/rules
    sudo mkdir /usr/local/etc/so_rules/
    sudo mkdir /usr/local/etc/lists/
    sudo touch /usr/local/etc/rules/local.rules
    sudo touch /usr/local/etc/lists/default.blocklist 
    sudo mkdir /var/log/snort

    echo "
alert icmp any any -> any any ( msg:\"ICMP Traffic Detected\"; sid:10000001; metadata:policy security-ips alert; )
    " >> "/usr/local/etc/rules/local.rules"

    echo "Validate snort rules"
    snort -c /usr/local/etc/snort/snort.lua -R /usr/local/etc/rules/local.rules

    echo "Copy snort service to systemd folder"
    cp snort3.service /lib/systemd/system/snort3.service

}

function configure_pulledpork3 {
    echo "Configure rulesets"
    sed -i "/${PULLEDPORK_RULESET}/s/= .*/= true/" /usr/local/etc/pulledpork3/pulledpork.conf

    echo "Configure blocklist"
    sed -i "/snort_blocklist/s/= .*/= true/" /usr/local/etc/pulledpork3/pulledpork.conf
    sed -i "/et_blocklist/s/= .*/= true/" /usr/local/etc/pulledpork3/pulledpork.conf

    echo "Uncomment snort_path in pulledpork and set value"
    sed -i '/snort_path/s/^#//g' /usr/local/etc/pulledpork3/pulledpork.conf
    sed -i "/snort_path/s/= .*/= \/usr\/local\/bin\/snort/" /usr/local/etc/pulledpork3/pulledpork.conf

    echo "Uncomment local_rules and set value"
    sed -i '/local_rules =/s/^#//g' /usr/local/etc/pulledpork3/pulledpork.conf
    sed -i "/local_rules/s/= .*/= \/usr\/local\/etc\/rules\/local.rules/" /usr/local/etc/pulledpork3/pulledpork.conf

    echo "Set oinkcode"
    sed -i "/oinkcode/s/= .*/= b9845cd898b7237301ac46065c9447102b6bdfb5/" /usr/local/etc/pulledpork3/pulledpork.conf

    echo "Load PulledPork rule sets"
    sudo /usr/local/bin/pulledpork3/pulledpork.py -c /usr/local/etc/pulledpork3/pulledpork.conf

    echo "Copy snort.lua"
    cp resources/snort.lua /usr/local/etc/snort/
}

function setup_scheduled_rules_update {
    cp pulledpork3.service /lib/systemd/system/pulledpork3.service

    sudo systemctl enable pulledpork3.service
    sudo systemctl restart pulledpork3.service

    cp pulledpork3.service /lib/systemd/system/pulledpork3.timer

    sudo systemctl enable pulledpork3.timer
}

function configure_snort_plugin {
    echo "Set home network to protect"
    # Escape HOME_NET variable as it will contain special character '/'
    sed -i "/HOME_NET/s/= .*/= '${HOME_NET//\//\\/}'/" /usr/local/etc/snort/snort.lua
}

function configure_hyperscan_snort {
    # Check for the configure bindings sections
    snort_configure_builds_lines=$(cat /usr/local/etc/snort/snort.lua | grep --fixed-strings --line-number "3. configure bindings" | cut --delimiter=":" --fields=1)
    # The /usr/local/etc/snort/snort.lua defines two configure bindings
    snort_configure_builds=$(echo $snort_configure_builds_lines | awk '{print $2}')

    snort_configure_builds=$(expr $snort_configure_builds - 2)

    # TODO: needs debugging, doesn't work
    sed -i "${snort_configure_builds} 
search_engine = { search_method = \"hyperscan\" }
detection = { 
    hyperscan_literals = true, 
    pcre_to_regex = true
} 
    " /usr/local/etc/snort/snort.lua

}

function setup_snort_user {
    sudo groupadd snort
    sudo useradd snort -r -s /sbin/nologin -c SNORT_IDS -g snort

    sudo chmod -R 5775 /var/log/snort
    sudo chown -R snort:snort /var/log/snort
}

# After copying the updated snort.lua 
function setup_openappid {
    # Needs update snort.lua
    sudo /usr/local/bin/pulledpork3/pulledpork.py -c /usr/local/etc/pulledpork3/pulledpork.conf
}

function configure_snort_extras {
    # Move the so_rules to extras folder since we can only provide one --plugin-path in sonrt's systemD
    cp -r /usr/local/etc/so_rules /usr/local/lib/snort_extra

    sudo rm /var/log/snort/*
}
function test_snort_lua {
     sudo snort -c /usr/local/etc/snort/snort.lua \
        --plugin-path=/usr/local/lib/snort_extra
}

function main {
    configure_network_cards
    configure_snort
    configure_pulledpork3
    setup_scheduled_rules_update
    configure_snort_plugin
    setup_snort_user
    configure_snort_extras
    # verify_pulledpork3_snort3_configuration
    test_snort_lua
}

main
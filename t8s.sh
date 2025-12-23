#!/bin/bash

function talos_display_config() {
    if [ -n "$TALOSCONFIG" ] && [ -f "$TALOSCONFIG" ]; then
        cat $TALOSCONFIG
    else
        echo "TALOSCONFIG is not set or the file does not exist."
    fi
}

function talos_echo_config_path() {
    if [ -n "$TALOSCONFIG" ] && [ -f "$TALOSCONFIG" ]; then
        echo $TALOSCONFIG
    else
        echo "TALOSCONFIG is not set or the file does not exist."
    fi
}

function talos_set_config() {
    if [ -f "$1" ]; then
        export TALOSCONFIG=$(realpath $1)
        echo "TALOSCONFIG set to $TALOSCONFIG"
    else
        echo "The provided file does not exist."
    fi
}

function talos_delete_config() {
    unset TALOSCONFIG
    echo "TALOSCONFIG has been unset."
}

function talos_select_config() {
    local files=($(ls -p ~/.talos | grep -v /))
    local length=${#files[@]}
    local choice

    if [ $length -eq 0 ]; then
        echo "No files in ~/.talos"
        return
    fi

    echo "Select a file to set as TALOSCONFIG:"
    select choice in "${files[@]}"; do
        if [[ -n $choice ]]; then
            export TALOSCONFIG=~/.talos/$choice
            echo "TALOSCONFIG set to $choice"
            break
        else
            echo "Invalid choice"
        fi
    done
}

function talos_display_help() {
    echo "Usage: t8s [-d|-e|-u|-s|-r|file|-h]"
    echo "Options:"
    echo "        (No option) Same as -r. Select a talosconfig and run dashboard."
    echo "-d      Display the content of the TALOSCONFIG file."
    echo "-e      Display the path of the TALOSCONFIG file."
    echo "-u      Unset the TALOSCONFIG environment variable."
    echo "-s      Select a talosconfig file from the ~/.talos directory."
    echo "-r      Select a talosconfig and run talosctl dashboard."
    echo "file    Set the TALOSCONFIG environment variable to the provided file."
    echo "-h      Display this help message."
}

function talos_select_and_run_dashboard() {
    local files=($(ls -p ~/.talos | grep -v /))
    local length=${#files[@]}
    local choice

    if [ $length -eq 0 ]; then
        echo "No files in ~/.talos"
        return
    fi

    # Get node IP from config
    echo "Select a talosconfig to run dashboard:"
    select choice in "${files[@]}"; do
        if [[ -n $choice ]]; then
            local config=~/.talos/$choice
            # Extract first endpoint from config
            local node=$(grep -A5 "endpoints:" $config | grep -E "^\s+-\s+" | head -1 | sed 's/.*- //')
            if [ -n "$node" ]; then
                TALOSCONFIG=$config talosctl -n $node dashboard
            else
                echo "Could not find endpoint in config. Set node manually:"
                echo "TALOSCONFIG=$config talosctl -n <IP> dashboard"
            fi
            break
        else
            echo "Invalid choice"
        fi
    done
}

function t8s() {
    case $1 in
    -d)
        if [ -z "$2" ]; then
            talos_display_config
        else
            echo "Invalid option with -d."
        fi
        ;;
    -u)
        if [ -z "$2" ]; then
            talos_delete_config
        else
            echo "Invalid option with -u."
        fi
        ;;
    -s)
        if [ -z "$2" ]; then
            talos_select_config
        else
            echo "Invalid option with -s."
        fi
        ;;
    -r)
        if [ -z "$2" ]; then
            talos_select_and_run_dashboard
        else
            echo "Invalid option with -r."
        fi
        ;;
    -e)
        if [ -z "$2" ]; then
            talos_echo_config_path
        else
            echo "Invalid option with -e."
        fi
        ;;
    -h)
        if [ -z "$2" ]; then
            talos_display_help
        else
            echo "Invalid option with -h."
        fi
        ;;
    "")
        talos_select_and_run_dashboard
        ;;
    *)
        if [[ $1 == -* ]]; then
            echo "Invalid option: $1"
        else
            talos_set_config $1
        fi
        ;;
    esac
}

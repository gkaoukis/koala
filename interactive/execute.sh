#!/bin/bash

TOP=$(git rev-parse --show-toplevel)
eval_dir="${TOP}/interactive"
scripts_dir="${eval_dir}/scripts"
outputs_dir="${games_dir}/outputs"
mkdir -p "$outputs_dir"

export LC_ALL=C

selected_scripts=""

while [ $# -gt 0 ]; do
    case "$1" in
        -s|--scripts)
            shift
            while [ $# -gt 0 ] && [ "$(echo "$1" | cut -c1)" != "-" ]; do
                if [ -z "$selected_scripts" ]; then
                    selected_scripts="$1"
                else
                    selected_scripts="$selected_scripts $1"
                fi
                shift
            done
            ;;
        *)
            shift
            ;;
    esac
done

export BENCHMARK_CATEGORY="interactive"
KOALA_SHELL=${KOALA_SHELL:-bash}

should_run() {
    script_name=$1
    # If no scripts specified, run all
    if [ -z "$selected_scripts" ]; then
        return 0
    fi
    for selected in $selected_scripts; do
        if [ "$selected" = "$script_name" ]; then
            return 0
        fi
    done
    return 1
}

# Snake game benchmark
if should_run "shnake"; then
    echo "shnake"
    BENCHMARK_INPUT_FILE=""
    export BENCHMARK_INPUT_FILE
    BENCHMARK_SCRIPT="$(realpath "$scripts_dir/shnake.sh")"
    export BENCHMARK_SCRIPT

    BENCHMARK_INPUT_FILE=$snake_input_file
    export BENCHMARK_INPUT_FILE
    $KOALA_SHELL "$scripts_dir/shnake.sh" $snake_input_file
    exit_code_file=$?
fi


# Shtris (Tetris) game benchmark
if should_run "shtris"; then
    echo "shtris"
    BENCHMARK_INPUT_FILE=""
    export BENCHMARK_INPUT_FILE
    BENCHMARK_SCRIPT="$(realpath "$scripts_dir/shtris.sh")"
    export BENCHMARK_SCRIPT

    if [ ! -f "$scripts_dir/shtris.sh" ]; then
        echo "Error: shtris.sh not found in $scripts_dir"
        exit 1
    fi

    $KOALA_SHELL "$scripts_dir/shtris.sh" >
    pid=$!
        
    wait $pid 2>/dev/null
    echo $?
fi

# Miniforge3 installer benchmark
if should_run "Miniforge3-Linux-x86_64"; then
    echo "Miniforge3-Linux-x86_64"
    BENCHMARK_INPUT_FILE=""
    export BENCHMARK_INPUT_FILE
    BENCHMARK_SCRIPT="$(realpath "$scripts_dir/Miniforge3-Linux-x86_64.sh")"
    export BENCHMARK_SCRIPT
    
    # # Run installer in batch mode (non-interactive)
    # install_prefix="$outputs_dir/miniforge3_install"
    # mkdir -p "$install_prefix"
    
    #$KOALA_SHELL "$scripts_dir/Miniforge3-Linux-x86_64.sh" -b -p "$install_prefix" > "$outputs_dir/miniforge_output.txt" 2>&1
    $KOALA_SHELL "$scripts_dir/Miniforge3-Linux-x86_64.sh"
    exit_code=$?
    
    # Cleanup installation
    # rm -rf "$install_prefix"
    
    echo $exit_code
fi

# Oh My Zsh installer benchmark
if should_run "ohmyzsh"; then
    echo "ohmyzsh"
    BENCHMARK_INPUT_FILE=""
    export BENCHMARK_INPUT_FILE
    BENCHMARK_SCRIPT="$(realpath "$scripts_dir/ohmyzsh.sh")"
    export BENCHMARK_SCRIPT

    if [ ! -f "$scripts_dir/ohmyzsh.sh" ]; then
        echo "Error: ohmyzsh.sh not found in $scripts_dir"
        exit 1
    fi

    export ZSH="$outputs_dir/ohmyzsh_install"
    mkdir -p "$ZSH"
    RUNZSH=no CHSH=no $KOALA_SHELL "$scripts_dir/ohmyzsh.sh"
    exit_code=$?
    echo $exit_code
    fi
fi

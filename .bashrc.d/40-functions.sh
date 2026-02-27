# =============================================================================
# 40-functions.sh — Custom shell functions
# =============================================================================
# Loaded by: ~/.bashrc.d/ (alphabetical order)
# Depends on: 05-colors.sh (C_* color vars, _gum_* helpers)
#
# Functions defined here:
#   e()           — open $EDITOR with args
#   mkcd()        — mkdir + cd in one step
#   toggle-motd() — enable/disable the startup banner (95-motd.sh)
#   dotinfo()     — full config summary, or --short for startup banner
#   sysinfo()     — CPU, RAM, disk, uptime, top processes
#   pathinfo()    — $PATH entries + programs found in config files
# =============================================================================

e() { "$EDITOR" "$@"; } # Open $EDITOR with optional args

mkcd() { # Create directory and cd into it
    mkdir -p "$1" && cd "$1"
}

# -----------------------------------------------------------------------------
# toggle-motd — enable or disable the startup banner shown by 95-motd.sh
# Config file: ~/.config/dotfiles/motd.conf (contains "enabled" or "disabled")
# If the file does not exist, motd is enabled by default.
# -----------------------------------------------------------------------------
toggle-motd() { # Toggle the startup banner on/off
    local conf="$HOME/.config/dotfiles/motd.conf"
    mkdir -p "$(dirname "$conf")"

    local current
    current=$(cat "$conf" 2>/dev/null || echo "enabled")

    if [[ "$current" == "enabled" ]]; then
        echo "disabled" > "$conf"
        _gum_log_info "motd disabled — run 'toggle-motd' to re-enable"
    else
        echo "enabled" > "$conf"
        _gum_log_info "motd enabled — run 'toggle-motd' to disable"
    fi
}

# -----------------------------------------------------------------------------
# _dotinfo_get_programs — shared helper used by dotinfo and dotinfo --short
# Scans config files for "command -v PROG" via awk field comparison (no regex).
# Outputs lines: "prog:status" where status is "ok", "missing", or "function"
# -----------------------------------------------------------------------------
_dotinfo_get_programs() {
    local config_files=()
    for f in "$HOME/.bashrc" "$HOME/.blerc" "$HOME"/.bashrc.d/*; do
        [[ -f "$f" ]] && config_files+=("$f")
    done

    declare -A seen=()
    for f in "${config_files[@]}"; do
        while IFS= read -r prog; do
            [[ -z "$prog" || -n "${seen[$prog]}" ]] && continue
            seen["$prog"]=1
            local result
            result=$(command -v "$prog" 2>/dev/null)
            if [[ -n "$result" && "$result" != "$prog" ]]; then
                echo "$prog:ok:$result"
            elif [[ -n "$result" ]]; then
                echo "$prog:function:"
            else
                echo "$prog:missing:"
            fi
        done < <(awk '{
            if (substr($1, 1, 1) == "#") next
            for (i = 1; i <= NF - 2; i++) {
                if ($i == "command" && $(i+1) == "-v") print $(i+2)
            }
        }' "$f")
    done
}

# -----------------------------------------------------------------------------
# dotinfo — show config summary
# Usage:
#   dotinfo          — full output: env vars, aliases, keybindings, functions
#   dotinfo --short  — compact startup banner: tools/missing/functions
#
# Full mode:   uses _gum_header for sections, _gum_table for tabular data
# Short mode:  three lines — tools, missing, functions + toggle hint
# Both modes fall back gracefully when gum is not installed.
# -----------------------------------------------------------------------------
dotinfo() { # Show config summary (--short for startup banner)

    # --- SHORT MODE — startup banner ----------------------------------------
    if [[ "${1-}" == "--short" ]]; then
        local tools=() missing=() funcs=()

        # collect program status
        while IFS=: read -r prog status _rest; do
            case "$status" in
                ok|function) tools+=("$prog") ;;
                missing)     missing+=("$prog") ;;
            esac
        done < <(_dotinfo_get_programs)

        # ble.sh separately
        if [[ -n "${BLE_VERSION-}" ]]; then
            tools+=("ble.sh")
        else
            for p in "$HOME/.local/share/blesh/ble.sh" "/usr/share/blesh/ble.sh" "/usr/local/share/blesh/ble.sh"; do
                [[ -f "$p" ]] && { missing+=("ble.sh"); break; }
            done
        fi

        # collect function names from bashrc.d
        while IFS= read -r line; do
            local fname
            fname=$(echo "$line" | sed -E "s/^([a-zA-Z0-9_-]+)\(\).*/\1/")
            funcs+=("$fname")
        done < <(grep -h -E "^[a-zA-Z0-9_-]+\(\)" ~/.bashrc.d/* | grep -v "^_")

        if _gum_available; then
            local tools_str missing_str funcs_str
            tools_str="${tools[*]}"
            missing_str="${missing[*]}"
            funcs_str="${funcs[*]}"

            gum style \
                --border normal --padding "0 1" \
                "$(gum style --bold 'dotfiles')" \
                "$(printf '%-10s %s' 'tools'     "$tools_str")" \
                "$(printf '%-10s %s' 'missing'   "${missing_str:-(none)}")" \
                "$(printf '%-10s %s' 'functions' "$funcs_str")"
            echo ""
            gum style --faint "  run 'toggle-motd' to disable this banner"
        else
            echo ""
            printf "  ${C_BOLD}✦ dotfiles${C_RESET}\n"
            printf "  ${C_BOLD}%-12s${C_RESET} %s\n" "tools"     "${tools[*]}"
            printf "  ${C_BOLD}${C_ERR}%-12s${C_RESET} %s\n" "missing"   "${missing[*]:-(none)}"
            printf "  ${C_BOLD}%-12s${C_RESET} %s\n" "functions" "${funcs[*]}"
            printf "  ${C_DIM}run 'toggle-motd' to disable this banner${C_RESET}\n"
            echo ""
        fi
        return
    fi

    # --- FULL MODE ----------------------------------------------------------

    # ENVIRONMENT VARIABLES
    _gum_header "🔧 ENVIRONMENT VARIABLES"
    if _gum_available; then
        (
            echo "NAME|VALUE"
            declare -A _seen_vars=()
            while IFS= read -r line; do
                local name val
                name=$(echo "$line" | sed -E "s/^\s*export ([^=]+)=.*/\1/")
                [[ "$name" == C_* ]] && continue
                [[ -n "${_seen_vars[$name]}" ]] && continue
                _seen_vars["$name"]=1
                val=$(echo "$line" | sed -E "s/^[^=]+=//; s/#.*//")
                echo "$name|$val"
            done < <(grep -h -E "^\s*export" ~/.bashrc.d/*)
        ) | gum table --print --separator "|"
    else
        declare -A _seen_vars=()
        while IFS= read -r line; do
            local name val comment
            name=$(echo "$line" | sed -E "s/^\s*export ([^=]+)=.*/\1/")
            [[ "$name" == C_* ]] && continue
            [[ -n "${_seen_vars[$name]}" ]] && continue
            _seen_vars["$name"]=1
            val=$(echo "$line" | sed -E "s/^[^=]+=//; s/#.*//")
            comment=$(echo "$line" | sed -E "s/.*# //")
            [[ "$comment" == "$line" ]] && comment=""  || comment="# $comment"
            printf " ${C_BOLD}%-12s${C_RESET}  =  %-45s ${C_DIM}%s${C_RESET}\n" "$name" "$val" "$comment"
        done < <(grep -h -E "^\s*export" ~/.bashrc.d/*)
    fi

    # ALIASES
    _gum_header "🛠  ALIASES"
    if _gum_available; then
        (
            echo "ALIAS|COMMAND"
            grep -h -E "^\s*alias" ~/.bashrc.d/* | while IFS= read -r line; do
                local name cmd
                name=$(echo "$line" | sed -E "s/^\s*alias ([^=]+)=.*/\1/")
                cmd=$(echo "$line"  | sed -E "s/^[^=]+=//; s/#.*//")
                echo "$name|$cmd"
            done
        ) | gum table --print --separator "|"
    else
        grep -h -E "^\s*alias" ~/.bashrc.d/* | while IFS= read -r line; do
            local name cmd comment
            name=$(echo "$line" | sed -E "s/^\s*alias ([^=]+)=.*/\1/")
            cmd=$(echo "$line"  | sed -E "s/^[^=]+=//; s/#.*//")
            comment=$(echo "$line" | sed -E "s/.*# //")
            [[ "$comment" == "$line" ]] && comment="" || comment="# $comment"
            printf " ${C_BOLD}%-12s${C_RESET}  =  %-45s ${C_DIM}%s${C_RESET}\n" "$name" "$cmd" "$comment"
        done
    fi

    # KEYBINDINGS
    _gum_header "🎹 KEYBINDINGS"
    if _gum_available; then
        (
            echo "KEY|ACTION|DESCRIPTION"
            grep -h -E "^\s*bind " ~/.bashrc.d/* | grep "#" | while IFS= read -r line; do
                local key cmd comment
                key=$(echo "$line"     | awk -F'"' '{print $2}')
                cmd=$(echo "$line"     | awk -F': ' '{print $2}' | awk '{print $1}' | tr -d "'")
                comment=$(echo "$line" | sed -E "s/.*# //")
                echo "$key|$cmd|$comment"
            done
        ) | gum table --print --separator "|"
    else
        grep -h -E "^\s*bind " ~/.bashrc.d/* | grep "#" | while IFS= read -r line; do
            local key cmd comment
            key=$(echo "$line"     | awk -F'"' '{print $2}')
            cmd=$(echo "$line"     | awk -F': ' '{print $2}' | awk '{print $1}' | tr -d "'")
            comment=$(echo "$line" | sed -E "s/.*# //")
            printf " ${C_BOLD}%-12s${C_RESET}  ->  %-40s ${C_DIM}# %s${C_RESET}\n" "$key" "$cmd" "$comment"
        done
    fi

    # FUNCTIONS
    _gum_header "🚀 FUNCTIONS"
    if _gum_available; then
        (
            echo "FUNCTION|DESCRIPTION"
            grep -h -E "^[a-zA-Z0-9_-]+\(\)" ~/.bashrc.d/* | grep -v "^_" | while IFS= read -r line; do
                local name comment
                name=$(echo "$line"    | sed -E "s/^([a-zA-Z0-9_-]+)\(\).*/\1/")
                comment=$(echo "$line" | sed -E "s/.*# //")
                [[ "$comment" == "$line" ]] && comment=""
                echo "$name|$comment"
            done
        ) | gum table --print --separator "|"
    else
        grep -h -E "^[a-zA-Z0-9_-]+\(\)" ~/.bashrc.d/* | grep -v "^_" | while IFS= read -r line; do
            local name comment
            name=$(echo "$line"    | sed -E "s/^([a-zA-Z0-9_-]+)\(\).*/\1/")
            comment=$(echo "$line" | sed -E "s/.*# //")
            [[ "$comment" == "$line" ]] && comment="" || comment="# $comment"
            printf " ${C_BOLD}%-12s${C_RESET}  :  ${C_DIM}%s${C_RESET}\n" "$name" "$comment"
        done
    fi

    echo -e "\n${C_DIM}(Edit files in ~/.bashrc.d/ to update this list)${C_RESET}"
}

# -----------------------------------------------------------------------------
# sysinfo — quick system overview
# Reads from /proc/cpuinfo, /proc/meminfo, /proc/loadavg (Linux)
# Falls back to sysctl for macOS compatibility
# -----------------------------------------------------------------------------
sysinfo() { # Show CPU, RAM, disk, uptime and top processes
    _gum_header "💻 SYSTEM INFO"

    local uptime_str
    uptime_str=$(uptime -p 2>/dev/null || uptime)

    local cpu_model cpu_cores load
    cpu_model=$(grep -m1 'model name' /proc/cpuinfo 2>/dev/null | sed 's/.*: //' \
        || sysctl -n machdep.cpu.brand_string 2>/dev/null)
    cpu_cores=$(nproc 2>/dev/null || sysctl -n hw.ncpu 2>/dev/null)
    load=$(cut -d' ' -f1-3 /proc/loadavg 2>/dev/null \
        || sysctl -n vm.loadavg 2>/dev/null | tr -d '{}')

    local mem_used='' mem_total=''
    if [[ -f /proc/meminfo ]]; then
        mem_total=$(awk '/MemTotal/     { printf "%.0f", $2/1024 }' /proc/meminfo)
        local mem_available
        mem_available=$(awk '/MemAvailable/ { printf "%.0f", $2/1024 }' /proc/meminfo)
        mem_used=$(( mem_total - mem_available ))
    fi

    local disk_used disk_total disk_pct
    disk_used=$(df -h "$HOME" | awk 'NR==2{print $3}')
    disk_total=$(df -h "$HOME" | awk 'NR==2{print $2}')
    disk_pct=$(df -h  "$HOME" | awk 'NR==2{print $5}')

    if _gum_available; then
        (
            echo "LABEL|VALUE"
            echo "uptime|$uptime_str"
            echo "cpu|$cpu_model ($cpu_cores cores, load: $load)"
            [[ -n "$mem_used" ]] && echo "memory|${mem_used} MB used / ${mem_total} MB total"
            echo "disk|${disk_used} used / ${disk_total} total (${disk_pct})"
        ) | gum table --print --separator "|"
    else
        echo ""
        printf " ${C_BOLD}%-10s${C_RESET}  %s\n" "uptime" "$uptime_str"
        printf " ${C_BOLD}%-10s${C_RESET}  %s ${C_DIM}(%s cores, load: %s)${C_RESET}\n" \
            "cpu" "$cpu_model" "$cpu_cores" "$load"
        [[ -n "$mem_used" ]] && \
            printf " ${C_BOLD}%-10s${C_RESET}  %s MB used ${C_DIM}/ %s MB total${C_RESET}\n" \
                "memory" "$mem_used" "$mem_total"
        printf " ${C_BOLD}%-10s${C_RESET}  %s used ${C_DIM}/ %s total (%s)${C_RESET}\n" \
            "disk" "$disk_used" "$disk_total" "$disk_pct"
    fi

    if _gum_available; then
        echo ""
        gum style --faint "top processes:"
        (
            echo "PID|CPU%|MEM%|COMMAND"
            ps -eo pid,%cpu,%mem,comm --sort=-%cpu 2>/dev/null | head -4 | tail -3 | \
                while read -r pid cpu mem comm; do
                    echo "$pid|$cpu|$mem|$comm"
                done
        ) | gum table --print --separator "|"
    else
        echo -e "\n ${C_DIM}top processes:${C_RESET}"
        ps -eo pid,%cpu,%mem,comm --sort=-%cpu 2>/dev/null | head -4 | tail -3 | \
            while read -r pid cpu mem comm; do
                printf "  ${C_DIM}%-6s  cpu: %5s%%  mem: %5s%%  %-20s${C_RESET}\n" \
                    "$pid" "$cpu" "$mem" "$comm"
            done
    fi
    echo
}

# -----------------------------------------------------------------------------
# pathinfo — inspect $PATH and check programs mentioned in config files
#
# Block 1: lists every directory in $PATH — flags missing dirs and duplicates
# Block 2: uses _dotinfo_get_programs (shared with dotinfo --short) to check
#          every tool found via "command -v PROG" in config files.
#          ble.sh checked separately via $BLE_VERSION and known install paths.
# -----------------------------------------------------------------------------
pathinfo() { # Show $PATH dirs and check programs found in config files
    _gum_header "🔍 \$PATH"
    echo ""

    local seen=()
    local idx=0
    IFS=':' read -ra entries <<< "$PATH"

    if _gum_available; then
        (
            echo "N|PATH|STATUS"
            for dir in "${entries[@]}"; do
                (( idx++ ))
                local is_dup=''
                for s in "${seen[@]}"; do
                    [[ "$s" == "$dir" ]] && is_dup='duplicate' && break
                done
                seen+=("$dir")

                if [[ ! -d "$dir" ]]; then
                    echo "$idx|$dir|missing"
                elif [[ -n "$is_dup" ]]; then
                    echo "$idx|$dir|duplicate"
                else
                    echo "$idx|$dir|ok"
                fi
            done
        ) | gum table --print --separator "|"
    else
        for dir in "${entries[@]}"; do
            (( idx++ ))
            local is_dup=''
            for s in "${seen[@]}"; do
                [[ "$s" == "$dir" ]] && is_dup=' ⚠ duplicate' && break
            done
            seen+=("$dir")
            if [[ ! -d "$dir" ]]; then
                printf " ${C_BOLD}${C_ERR}%2d.${C_RESET}  ${C_ERR}%-50s [missing]%s${C_RESET}\n" \
                    "$idx" "$dir" "$is_dup"
            elif [[ -n "$is_dup" ]]; then
                printf " ${C_BOLD}${C_WARN}%2d.${C_RESET}  ${C_WARN}%-50s%s${C_RESET}\n" \
                    "$idx" "$dir" "$is_dup"
            else
                printf " ${C_BOLD}%2d.${C_RESET}  %s\n" "$idx" "$dir"
            fi
        done
    fi

    _gum_header "🔎 PROGRAMS IN YOUR CONFIGS"
    echo ""

    # ble.sh — not detectable via command -v, checked separately
    if _gum_available; then
        if [[ -n "${BLE_VERSION-}" ]]; then
            gum log --level info  "ble.sh — active v${BLE_VERSION}"
        else
            local ble_found=''
            for p in "$HOME/.local/share/blesh/ble.sh" "/usr/share/blesh/ble.sh" "/usr/local/share/blesh/ble.sh"; do
                [[ -f "$p" ]] && ble_found="$p" && break
            done
            if [[ -n "$ble_found" ]]; then
                gum log --level warn  "ble.sh — installed, not active ($ble_found)"
            else
                gum log --level error "ble.sh — not found"
            fi
        fi
    else
        printf " %-22s" "ble.sh"
        if [[ -n "${BLE_VERSION-}" ]]; then
            printf "${C_BOLD}${C_OK}✓${C_RESET}  active v%s\n" "$BLE_VERSION"
        else
            local ble_found=''
            for p in "$HOME/.local/share/blesh/ble.sh" "/usr/share/blesh/ble.sh" "/usr/local/share/blesh/ble.sh"; do
                [[ -f "$p" ]] && ble_found="$p" && break
            done
            if [[ -n "$ble_found" ]]; then
                printf "${C_BOLD}${C_WARN}~${C_RESET}  installed, not active ${C_DIM}(%s)${C_RESET}\n" "$ble_found"
            else
                printf "${C_BOLD}${C_ERR}✗${C_RESET}  not found\n"
            fi
        fi
    fi

    while IFS=: read -r prog status result; do
        if _gum_available; then
            case "$status" in
                ok)       gum log --level info  "$prog — $result" ;;
                function) gum log --level info  "$prog — shell function" ;;
                missing)  gum log --level error "$prog — not installed" ;;
            esac
        else
            printf " %-22s" "$prog"
            case "$status" in
                ok)       printf "${C_BOLD}${C_OK}✓${C_RESET}  %-45s\n" "$result" ;;
                function) printf "${C_BOLD}${C_OK}✓${C_RESET}  shell function\n" ;;
                missing)  printf "${C_BOLD}${C_ERR}✗${C_RESET}  not installed\n" ;;
            esac
        fi
    done < <(_dotinfo_get_programs | sort)

    echo
}

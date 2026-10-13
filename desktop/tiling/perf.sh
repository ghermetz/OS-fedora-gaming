#!/bin/bash
# fedora-gaming — module « performances » de la barre : processeur, carte graphique
# (Radeon), températures et mémoire. Clic : gestionnaire des tâches.
etat="${XDG_RUNTIME_DIR:-/tmp}/waybar-perf-cpu"
read -r _ u n s i w q sq st _ < /proc/stat
total=$((u+n+s+i+w+q+sq+st)); repos=$((i+w))
{ read -r t0 r0 < "$etat"; } 2>/dev/null || { t0=0; r0=0; }
echo "$total $repos" > "$etat"
dt=$((total-t0)); cpu=0; [ "$dt" -gt 0 ] && cpu=$(( (100*(dt-(repos-r0)))/dt ))
hw() { for h in /sys/class/hwmon/hwmon*; do [ "$(cat $h/name)" = "$1" ] && echo $h && return; done; }
# k10temp : processeurs AMD ; coretemp : Intel
t=$(cat "$(hw k10temp)/temp1_input" "$(hw coretemp)/temp1_input" 2>/dev/null | head -1); tcpu=$(( ${t:-0} / 1000 ))
g=$(hw amdgpu); tgpu=$(( $(cat "$g/temp1_input" 2>/dev/null || echo 0) / 1000 ))
# Carte graphique AMD (Radeon) : charge et VRAM ; ailleurs, affichées à 0
carte=$(dirname "$(ls /sys/class/drm/card*/device/gpu_busy_percent 2>/dev/null | head -1)" 2>/dev/null)
# valeur très instable : moyenne de 5 mesures sur une demi-seconde
gpu=0; for _ in 1 2 3 4 5; do gpu=$((gpu + $(cat "$carte/gpu_busy_percent" 2>/dev/null || echo 0))); sleep 0.1; done; gpu=$((gpu/5))
vram=$(( $(cat "$carte/mem_info_vram_used" 2>/dev/null || echo 0) >> 20 ))
vramt=$(( $(cat "$carte/mem_info_vram_total" 2>/dev/null || echo 0) >> 20 ))
read -r ramt ramd < <(awk '/MemTotal/{t=$2}/MemAvailable/{a=$2}END{print int(t/1024), int(a/1024)}' /proc/meminfo)
ram=$((ramt-ramd))
classe=normal; { [ "$tcpu" -ge 85 ] || [ "$tgpu" -ge 90 ]; } && classe=chaud
printf '{"text":"\\uf2db %s%%   \\uf108 %s%%","class":"%s","tooltip":"Processeur : %s %% · %s °C\\nCarte graphique : %s %% · %s °C\\nVRAM : %s / %s Mo\\nMémoire : %s / %s Mo\\n\\nClic : gestionnaire des tâches"}\n' \
    "$cpu" "$gpu" "$classe" "$cpu" "$tcpu" "$gpu" "$tgpu" "$vram" "$vramt" "$ram" "$ramt"

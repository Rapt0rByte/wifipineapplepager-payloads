#!/bin/bash
echo "Content-Type: application/json"
echo "Access-Control-Allow-Origin: *"
echo ""

url_decode() {
    local encoded="$1"
    printf '%b' "${encoded//%/\\x}" | sed 's/+/ /g'
}

check_authentication() {
    local token="$1"
    local serverid="$2"

    local cookie_name="AUTH_$serverid"
    local cookie_value="$token"

    local status
    status=$(curl -s -o /dev/null -w "%{http_code}" -b "$cookie_name=$cookie_value" http://localhost:1471/api/api_ping)

    if [ "$status" -eq 200 ]; then
        return 0
    else
        echo '{"status":"unauthorized"}'
        exit 0
    fi
}

run_command() {
    local cmd="$1"
    if [ -z "$cmd" ]; then
        echo '{"status":"no_command"}'
        return
    fi
    local output
    output=$(eval "$cmd" 2>&1)
    echo "{\"status\":\"done\",\"output\":\"$(echo "$output" | sed 's/"/\\"/g')\"}"
}

# Parse and URL-decode query parameters
for param in $(echo "$QUERY_STRING" | tr '&' ' '); do
    key=$(echo "$param" | cut -d= -f1)
    value=$(echo "$param" | cut -d= -f2-)
    value=$(url_decode "$value")
    case "$key" in
        token) TOKEN="$value" ;;
        serverid) SERVERID="$value" ;;
        action) ACTION="$value" ;;
        data) DATA="$value" ;;
    esac
done

if [ -z "$TOKEN" ] || [ -z "$SERVERID" ]; then
    echo '{"status":"missing_auth"}'
    exit 0
fi

check_authentication "$TOKEN" "$SERVERID"

case "$ACTION" in
    command)
        run_command "$DATA"
        ;;
    *)
        echo '{"status":"unknown_action"}'
        ;;
esac

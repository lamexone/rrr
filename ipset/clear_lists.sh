#!/bin/sh

IPSET_DIR="$(dirname "$0")"
IPSET_DIR="$(
    cd "$IPSET_DIR"
    pwd
)"

. "$IPSET_DIR/def.sh"

rm -f "$ZIPLIST"* "$ZIPLIST6"* "$ZIPLIST_USER" "$ZIPLIST_USER6" "$ZIPLIST_IPBAN"* "$ZIPLIST_IPBAN6"* "$ZIPLIST_USER_IPBAN" "$ZIPLIST_USER_IPBAN6" "$ZIPLIST_EXCLUDE" "$ZIPLIST_EXCLUDE6" "$ZHOSTLIST"*

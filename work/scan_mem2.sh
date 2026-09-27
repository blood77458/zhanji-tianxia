#!/system/bin/sh
# Search the running game's memory for known Lua strings and dump surrounding bytes.
PKG=com.happyelements.canon.baiduDK
PID=$(pidof $PKG)
echo "pid=$PID"
[ -z "$PID" ] && exit 1

# strings we KNOW the Lua printed at runtime, plus likely identifiers
PAT="Startup Director"
PAT2="CanonEnvInjector"
TMP=/data/local/tmp/reg.bin

awk '{ split($1,a,"-"); if ($2 ~ /r/) print a[1], a[2] }' /proc/$PID/maps | while read START END; do
  S=$((0x$START)); E=$((0x$END)); SZ=$((E-S))
  [ $SZ -le 0 ] && continue
  [ $SZ -gt 268435456 ] && continue
  dd if=/proc/$PID/mem bs=4096 skip=$((S/4096)) count=$(((SZ+4095)/4096)) of=$TMP 2>/dev/null
  for p in "$PAT" "$PAT2"; do
    if grep -aq "$p" $TMP 2>/dev/null; then
      echo "=== HIT region 0x$START-0x$END  pattern='$p'"
      grep -aob "$p" $TMP 2>/dev/null | head -3
    fi
  done
  rm -f $TMP
done
echo "scan done"

#!/system/bin/sh
# Scan the running game's memory for decrypted Lua text.
PKG=com.happyelements.canon.baiduDK
PID=$(pidof $PKG)
echo "pid=$PID"
[ -z "$PID" ] && exit 1

PATTERNS="canon.request LoginServerRequest GetSocketServerRequest CommMethodConstants StartServerRequest"
TMP=/data/local/tmp/scan_region.bin
FOUND=0

# iterate readable regions from maps
awk '{ split($1,a,"-"); if ($2 ~ /r/) print a[1], a[2], $2 }' /proc/$PID/maps | while read START END PERM; do
  S=$((0x$START)); E=$((0x$END))
  SZ=$((E - S))
  # skip huge / irrelevant regions but keep heaps
  if [ $SZ -le 0 ]; then continue; fi
  if [ $SZ -gt 268435456 ]; then continue; fi
  dd if=/proc/$PID/mem bs=4096 skip=$((S / 4096)) count=$(( (SZ + 4095) / 4096 )) of=$TMP 2>/dev/null
  for p in $PATTERNS; do
    N=$(grep -a -c "$p" $TMP 2>/dev/null)
    if [ "$N" != "0" ] && [ -n "$N" ]; then
      echo "HIT region=$START-$END pat=$p count=$N"
    fi
  done
  rm -f $TMP
done
echo "scan done"

#!/system/bin/sh
# Dump the game's anonymous rw memory regions (native heap etc.) into one file
# so we can analyse it on the host. Avoids awk (unavailable/broken on this image).
PKG=com.happyelements.canon.baiduDK
PID=$(pidof $PKG)
echo "pid=$PID"
[ -z "$PID" ] && exit 1

OUT=/data/local/tmp/memdump.bin
rm -f $OUT
: > $OUT

# anonymous rw regions only (no backing file) == heap / jit / mmap'd data
grep -E 'rw-p 00000000 00:00 0' /proc/$PID/maps | cut -d' ' -f1 > /data/local/tmp/regions.txt
echo "candidate regions: $(wc -l < /data/local/tmp/regions.txt)"

while read R; do
  S=${R%-*}
  E=${R#*-}
  SB=$((0x$S))
  EB=$((0x$E))
  SZ=$((EB - SB))
  if [ $SZ -le 0 ]; then continue; fi
  if [ $SZ -gt 268435456 ]; then continue; fi
  # append this region's bytes
  dd if=/proc/$PID/mem bs=4096 skip=$((SB / 4096)) count=$(((SZ + 4095) / 4096)) >> $OUT 2>/dev/null
done < /data/local/tmp/regions.txt

ls -la $OUT
echo "dump complete"

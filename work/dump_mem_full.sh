#!/system/bin/sh
# Dump ALL readable memory regions of the game process, with a size cap,
# so we can locate where the Lua scripts actually live at runtime.
PKG=com.happyelements.canon.baiduDK
PID=$(pidof $PKG)
echo "pid=$PID"
[ -z "$PID" ] && exit 1

OUT=/data/local/tmp/memfull.bin
IDX=/data/local/tmp/memfull.idx
rm -f $OUT $IDX
: > $OUT
: > $IDX

# every readable region
grep -E ' r' /proc/$PID/maps | cut -d' ' -f1 > /data/local/tmp/allregions.txt
echo "regions: $(wc -l < /data/local/tmp/allregions.txt)"

TOTAL=0
while read R; do
  S=${R%-*}
  E=${R#*-}
  SB=$((0x$S)); EB=$((0x$E)); SZ=$((EB - SB))
  if [ $SZ -le 0 ]; then continue; fi
  if [ $SZ -gt 134217728 ]; then continue; fi
  POS=$(stat -c %s $OUT 2>/dev/null)
  [ -z "$POS" ] && POS=0
  dd if=/proc/$PID/mem bs=4096 skip=$((SB / 4096)) count=$(((SZ + 4095) / 4096)) >> $OUT 2>/dev/null
  echo "$S $POS $SZ" >> $IDX
  TOTAL=$((TOTAL + SZ))
done < /data/local/tmp/allregions.txt

echo "declared total: $TOTAL"
ls -la $OUT $IDX
echo "full dump complete"

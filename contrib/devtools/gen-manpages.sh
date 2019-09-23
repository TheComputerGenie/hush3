#!/bin/sh

TOPDIR=${TOPDIR:-$(git rev-parse --show-toplevel)}
SRCDIR=${SRCDIR:-$TOPDIR/src}
MANDIR=${MANDIR:-$TOPDIR/doc/man}

HUSHD=${HUSHD:-$SRCDIR/hushd}
HUSHCLI=${HUSHCLI:-$SRCDIR/hush-cli}
HUSHTX=${HUSHTX:-$SRCDIR/hush-tx}

[ ! -x $HUSHD ] && echo "$HUSHD not found or not executable." && exit 1

# The autodetected version git tag can screw up manpage output a little bit
#KMDVER=$($HUSHCLI --version | head -n1 | awk -F'[ -]' '{ print $5, $6 }')
KMDVER="0.4.0a"
echo "KMDVER=$KMDVER"

# Create a footer file with copyright content.
# This gets autodetected fine for komodod if --version-string is not set,
# but has different outcomes for komodo-cli.
echo "[COPYRIGHT]" > footer.h2m
$HUSHD --version | sed -n '1!p' >> footer.h2m

for cmd in $HUSHD $HUSHCLI $HUSHTX; do
  cmdname="${cmd##*/}"
  help2man -N --version-string=${KMDVER[0]} --include=footer.h2m -o ${MANDIR}/${cmdname}.1 ${cmd}
  sed -i "s/\\\-${KMDVER[1]}//g" ${MANDIR}/${cmdname}.1
done

rm -f footer.h2m

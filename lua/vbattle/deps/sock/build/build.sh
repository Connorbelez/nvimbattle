[ "$P" ] || exit 1
cat *.patch | patch -Np0

mkdir -p "$(dirname ../build/bin/linux64/clib/socket/$SD)"
${X}gcc -c -O2 $C $files -I. -I../lua-headers
${X}gcc *.o -shared -o ../build/bin/linux64/clib/socket/$SD $L
rm -f      ../build/bin/linux64/clib/socket/$SA
${X}ar rcs ../build/bin/linux64/$SA *.o
rm *.o

mkdir -p "$(dirname ../build/bin/linux64/clib/mime/$MD)"
${X}gcc -c -O2 $C src/mime.c -I. -I../lua-headers
${X}gcc mime.o -shared -o ../build/bin/linux64/clib/mime/$MD $L
rm -f      ../build/bin/linux64/$MA
${X}ar rcs ../build/bin/linux64/$MA mime.o

rm *.o

[ "$P" ] || exit 1
cat *.patch | patch -Np0

mkdir -p "$(dirname ../../sock/socket/$SD)"
${X}gcc -c -O2 $C $files -I. -I../lua-headers
${X}gcc *.o -shared -o ../../sock//socket/$SD $L
rm -f      ../../sock/$P/$SA
${X}ar rcs ../../sock/$P/$SA *.o
rm *.o

mkdir -p "$(dirname ../../sock/mime/$MD)"
${X}gcc -c -O2 $C src/mime.c -I. -I../lua-headers
${X}gcc mime.o -shared -o ../../sock/mime/$MD $L
rm -f      ../../sock/$P/$MA
${X}ar rcs ../../sock/$P/$MA mime.o

rm *.o

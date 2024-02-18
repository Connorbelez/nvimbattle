[ `uname` = Linux ] && export X=aarch64-apple-darwin11-
files="$(ls -1 src/*.c | grep -v "wsocket\|serial\|mime")" \
	P=osx64 C="-aarch64 -DLUASOCKET_API=extern" \
	L="-aarch64 -undefined dynamic_lookup" \
	SD=core.so MD=core.so SA=libsocket_core.a MA=libmime_core.a ./build.sh

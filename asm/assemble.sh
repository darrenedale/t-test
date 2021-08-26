#! /bin/bash

BITS=64
FILES="t-test lib libttest"
NASM=$(which nasm)
LD=$(which ld)

if [[ ${BITS} -ne 32 && ${BITS} -ne 64 ]]; then
	echo >&2 "invalid arch size: must be 32 or 64"
	exit 1
fi

for FILEBASE in ${FILES}; do
	INFILE="${FILEBASE}${BITS}.asm"
	OUTFILE="${FILEBASE}${BITS}.o"
	LSTFILE="${FILEBASE}${BITS}.lst"
	echo "Assembling ${INFILE} to ${OUTFILE} ... "
	${NASM} -f elf${BITS} -l "${LSTFILE}" -o "${OUTFILE}" "${INFILE}"

	if [ 0 -ne $? ]; then
		echo "assembly of ${INFILE} failed."
		exit -1
	fi

	LINKFILES="${LINKFILES} ${OUTFILE}"
done

OUTFILE="ttest${BITS}"

case ${BITS} in
	64)
		LD_OPTS="-dynamic-linker /lib64/ld-linux-x86-64.so.2"
		LINKFILES="${LINKFILES} /usr/lib/x86_64-linux-gnu/crt1.o /usr/lib/x86_64-linux-gnu/crti.o /usr/lib/x86_64-linux-gnu/crtn.o"
		;;

	32)
		LD_OPTS="-dynamic-linker /lib32/ld-linux.so.2"
		LINKFILES="${LINKFILES} /usr/lib/crt1.o /usr/lib/crti.o /usr/lib/crtn.o"
		;;
esac

echo "Linking ${OUTFILE} ..."
# ${LD} -m elf_x86_${BITS} -lc -e main ${LD_OPTS} -o "${OUTFILE}" ${LINKFILES}
${LD} -m elf_x86_${BITS} -o "${OUTFILE}" ${LINKFILES} -lc ${LD_OPTS}

if [ 0 -ne $? ]; then
	echo "linking failed."
	exit -2
fi

echo "Success."

#!/bin/bash

IP_CORES=(tlb mem_write_cmd_page_boundary_check_512 dma_bench)

HLS_DIR="$PWD"


IPREPO_DIR="${HLS_DIR}/../iprepo"

if [ ! -d "$IPREPO_DIR" ]; then
	mkdir "$IPREPO_DIR"
	#eval cd "$IPREPO_DIR"
	echo "${IPREPO_DIR}"
fi

for ip in "${IP_CORES[@]}"; do
	eval cd ${HLS_DIR}/${ip}
	eval vivado_hls -f run_hls.tcl
	if [ ! -d "${IPREPO_DIR}/${ip}" ]; then
		mkdir "${IPREPO_DIR}/${ip}"
	fi
	#eval cd "${IPREPO_DIR}/${ip}"
	zipname=`ls ${ip}_prj/solution1/impl/ip/*.zip`
	zipname=$(basename ${zipname})
	namelen=${#zipname}
	zipdir=${zipname:0:${namelen}-4}
	echo ${zipname}
	echo ${zipdir}
	eval cp ${ip}_prj/solution1/impl/ip/${zipname} ${IPREPO_DIR}/${ip}/
	unzip ${IPREPO_DIR}/${ip}/${zipname} -d ${IPREPO_DIR}/${ip}/${zipdir}
done



echo "Copied all HLS IPs to ip repository."
echo "Go to the projects directory and run vivado -mode batch -source create_*_proj.tcl to create the vivado project"


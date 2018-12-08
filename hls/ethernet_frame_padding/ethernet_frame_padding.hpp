#ifndef ETH_FRAME_PADDING
#define ETH_FRAME_PADDING

#include "../axi_utils.hpp"


void ethernet_fram_padding(	hls::stream<axiWord>&			dataIn,
				hls::stream<axiWord>&			dataOut);

#endif

/* Taken from https://github.com/djpohly/dwl/issues/466 */
#define COLOR(hex)    { ((hex >> 24) & 0xFF) / 255.0f, \
                        ((hex >> 16) & 0xFF) / 255.0f, \
                        ((hex >> 8) & 0xFF) / 255.0f, \
                        (hex & 0xFF) / 255.0f }

static const float rootcolor[]             = COLOR(0x121414ff);
static uint32_t colors[][3]                = {
	/*               fg          bg          border    */
	[SchemeNorm] = { 0xc3fe9bff, 0x121414ff, 0xacb4b4ff },
	[SchemeSel]  = { 0xc3fe9bff, 0xc7c7dcff, 0x9fb0b1ff },
	[SchemeUrg]  = { 0xc3fe9bff, 0x9fb0b1ff, 0xc7c7dcff },
};

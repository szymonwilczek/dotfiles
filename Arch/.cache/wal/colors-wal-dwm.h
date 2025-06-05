static const char norm_fg[] = "#c3fe9b";
static const char norm_bg[] = "#121414";
static const char norm_border[] = "#acb4b4";

static const char sel_fg[] = "#c3fe9b";
static const char sel_bg[] = "#9fb0b1";
static const char sel_border[] = "#c3fe9b";

static const char *colors[][3]      = {
    /*               fg           bg         border                         */
    [SchemeNorm] = { norm_fg,     norm_bg,   norm_border }, // unfocused wins
    [SchemeSel]  = { sel_fg,      sel_bg,    sel_border },  // the focused win
};

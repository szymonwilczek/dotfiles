static const char norm_fg[] = "#d0dae9";
static const char norm_bg[] = "#0f1018";
static const char norm_border[] = "#9198a3";

static const char sel_fg[] = "#d0dae9";
static const char sel_bg[] = "#70758B";
static const char sel_border[] = "#d0dae9";

static const char urg_fg[] = "#d0dae9";
static const char urg_bg[] = "#606B86";
static const char urg_border[] = "#606B86";

static const char *colors[][3]      = {
    /*               fg           bg         border                         */
    [SchemeNorm] = { norm_fg,     norm_bg,   norm_border }, // unfocused wins
    [SchemeSel]  = { sel_fg,      sel_bg,    sel_border },  // the focused win
    [SchemeUrg] =  { urg_fg,      urg_bg,    urg_border },
};

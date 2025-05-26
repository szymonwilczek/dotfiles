const char *colorname[] = {

  /* 8 normal colors */
  [0] = "#0f1018", /* black   */
  [1] = "#606B86", /* red     */
  [2] = "#70758B", /* green   */
  [3] = "#837D84", /* yellow  */
  [4] = "#7C849D", /* blue    */
  [5] = "#8792B0", /* magenta */
  [6] = "#9CB0DA", /* cyan    */
  [7] = "#d0dae9", /* white   */

  /* 8 bright colors */
  [8]  = "#9198a3",  /* black   */
  [9]  = "#606B86",  /* red     */
  [10] = "#70758B", /* green   */
  [11] = "#837D84", /* yellow  */
  [12] = "#7C849D", /* blue    */
  [13] = "#8792B0", /* magenta */
  [14] = "#9CB0DA", /* cyan    */
  [15] = "#d0dae9", /* white   */

  /* special colors */
  [256] = "#0f1018", /* background */
  [257] = "#d0dae9", /* foreground */
  [258] = "#d0dae9",     /* cursor */
};

/* Default colors (colorname index)
 * foreground, background, cursor */
 unsigned int defaultbg = 0;
 unsigned int defaultfg = 257;
 unsigned int defaultcs = 258;
 unsigned int defaultrcs= 258;

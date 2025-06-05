const char *colorname[] = {

  /* 8 normal colors */
  [0] = "#121414", /* black   */
  [1] = "#9fb0b1", /* red     */
  [2] = "#c7c7dc", /* green   */
  [3] = "#8ae2f8", /* yellow  */
  [4] = "#bedbdc", /* blue    */
  [5] = "#8af5fa", /* magenta */
  [6] = "#93fcd5", /* cyan    */
  [7] = "#bafd89", /* white   */

  /* 8 bright colors */
  [8]  = "#acb4b4",  /* black   */
  [9]  = "#abbabb",  /* red     */
  [10] = "#cecee0", /* green   */
  [11] = "#9ce5f9", /* yellow  */
  [12] = "#c7dfe0", /* blue    */
  [13] = "#9df6fa", /* magenta */
  [14] = "#a4fcda", /* cyan    */
  [15] = "#c3fe9b", /* white   */

  /* special colors */
  [256] = "#121414", /* background */
  [257] = "#d5dede", /* foreground */
  [258] = "#e3e2e2",     /* cursor */
};

/* Default colors (colorname index)
 * foreground, background, cursor */
 unsigned int defaultbg = 0;
 unsigned int defaultfg = 257;
 unsigned int defaultcs = 258;
 unsigned int defaultrcs= 258;

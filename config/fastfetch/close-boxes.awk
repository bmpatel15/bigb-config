# close-boxes.awk — close fastfetch's info boxes on the right, responsively.
#
# fastfetch draws boxes that are open on the right and a fixed width. This:
#   * auto-fits every box to the longest content line (no wasted width),
#   * rebuilds the top/bottom borders to that width (titles re-centered),
#   * pads each row and appends a matching "│" right wall,
#   * caps the width to the terminal so nothing wraps in a narrow pane.
#
# Every glyph renders single-width, so character count == display columns.
# Must run under a UTF-8 locale (length/substr/index count characters).
# Pass -v cols=<terminal columns> to cap the box for narrow/tiled panes.

function strip(x){ gsub(/\033\[[0-9;]*m/, "", x); return x }   # drop ANSI
function rep(ch, n,   s){ s=""; while (n-- > 0) s = s ch; return s }

{
    raw[NR] = $0
    s = strip($0); vis[NR] = s
    if (boxcol == 0) {
        if (index(s, "╭")) boxcol = index(s, "╭")
        else if (index(s, "╰")) boxcol = index(s, "╰")
    }
    if (index(s, "│") && index(s, "╭") == 0 && index(s, "╰") == 0) {
        w = length(s); if (w > cmax) cmax = w
    }
}
END {
    if (boxcol == 0) boxcol = 1
    fw = cmax + 1                              # right-wall column
    if (cols + 0 > 0 && fw > cols) fw = cols   # never exceed the terminal
    inner = fw - boxcol + 1                    # box width, corner to corner
    if (inner < 6) inner = 6
    mid = inner - 2                            # dashes + title between corners

    for (i = 1; i <= NR; i++) {
        s = vis[i]; r = raw[i]
        if (index(s, "╭")) {                             # top border: rebuild
            t = substr(s, boxcol)
            gsub(/╭/, "", t); gsub(/╮/, "", t); gsub(/─/, "", t)
            gsub(/^ +| +$/, "", t)                       # t == title text
            label = "  " t "  "
            d = mid - length(label); if (d < 0) d = 0
            l = int(d / 2)
            nb = "╭" rep("─", l) label rep("─", d - l) "╮"
            print substr(r, 1, index(r, "╭") - 1) "\033[34m" nb "\033[0m"
        } else if (index(s, "╰")) {                      # bottom border: rebuild
            nb = "╰" rep("─", mid) "╯"
            print substr(r, 1, index(r, "╰") - 1) "\033[34m" nb "\033[0m"
        } else if (index(s, "│")) {                      # content: pad + wall
            pad = fw - 1 - length(s); if (pad < 0) pad = 0
            print r rep(" ", pad) "\033[34m│\033[0m"
        } else {
            print r
        }
    }
}

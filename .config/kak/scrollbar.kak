###############################################################################
#                               Scrollbar.kak                                 #
###############################################################################

# The line-specs option for our scrollbar
declare-option -hidden line-specs scrollbar_flags

# I've chosen some default colours and scrollbar character styles which work
# well for my colour schemes; please customize them at your leisure.
face global Scrollbar +d@Default             # Set our Scrollbar face and character
face global ScrollbarSel +r@PrimarySelection # Show selections within the scrollbar
face global ScrollbarHL +r@SecondaryCursor   # For selections outside of the scrollbar
declare-option str scrollbar_char '▓'
declare-option str scrollbar_sel_char '█'

# Gather arguments to send to our C script.
# The C program will process this information and return a string for our line-desc
# object. See the C file for more details.
define-command update-scrollbar -hidden -override %{
    eval %sh{
        awk '
            # Convert a position a document to a position in our list of flags
            function get_flag_pos(doc_pos,    rel_pos, flag_pos) {
                rel_pos  = (buffer_height>1) ? (doc_pos-1) / (buffer_height-1) : 0
                flag_pos = int(bar_height*rel_pos + 0.5)
                return flag_pos
            }

            # Set the base flags which represent our scrollbar
            function set_scrollbar_flags(start, end,    i, flags_start, flags_end) {
                flags_start = get_flag_pos(start)
                flags_end   = get_flag_pos(end)
                for (i=flags_start; i<=flags_end; i++) {
                    flags_by_line[i] = 1
                }
            }

            # Set the flags which represent our current selections
            function set_selection_flags(input,
                    i, selections, selection, anchor, cursor, anchor_line, cursor_line,
                    sel_start, sel_end, flags_start, flags_end) {

                split(input, selections)

                for (i in selections) {
                    # Get start & end of selection from one selection_desc value
                    split(selections[i], selection, /,/)
                    split(selection[1], anchor, /\./)
                    split(selection[2], cursor, /\./)
                    anchor_line = anchor[1]
                    cursor_line = cursor[1]

                    # Make sure we are looping low to high
                    if (anchor_line <= cursor_line) {
                        sel_start = anchor_line
                        sel_end = cursor_line
                    } else {
                        sel_start = cursor_line
                        sel_end = anchor_line
                    }

                    # Convert to values in our flags list
                    flags_start = get_flag_pos(sel_start)
                    flags_end = get_flag_pos(sel_end)

                    # Loop through selected lines
                    for (i=flags_start; i<=flags_end; i++) {
                        if (flags_by_line[i] == 0) {
                            flags_by_line[i] = 2 # Outside scrollbar
                        } else if (flags_by_line[i] == 1) {
                            flags_by_line[i] = 3 # Inside scrollbar
                        }
                    }
                }
            }

            function print_flag_string(    i, formats, fmt_i) {
                printf "set-option buffer scrollbar_flags %d", timestamp
                split(" " bar_char " " sel_format2 " " sel_format1, formats)
                for (i = 0; i <= bar_height; i++) {
                    fmt_i = flags_by_line[i];
                    if (fmt_i) printf " %d|%s", (i+bar_start), formats[fmt_i]
                }
                print ""
            }

            BEGIN {
                # Initialize argument variables
                raw_window_range = ENVIRON["kak_window_range"]
                sel_str = ENVIRON["kak_selections_desc"]
                bar_char = ENVIRON["kak_opt_scrollbar_char"]
                sel_char = ENVIRON["kak_opt_scrollbar_sel_char"]
                buffer_height = ENVIRON["kak_buf_line_count"]
                timestamp = ENVIRON["kak_timestamp"]

                # window_range is y x height width
                split(raw_window_range, window_range)
                bar_start = window_range[1] + 1
                bar_height = window_range[3]
                bar_end = bar_start + bar_height

                # Create selection format strings
                bar_format = bar_char
                sel_format1 = "{ScrollbarSel}" sel_char
                sel_format2 = "{ScrollbarHL}" sel_char

                # Process scrollbar flags
                set_scrollbar_flags(bar_start, bar_end)

                # Process selection flags
                set_selection_flags(sel_str)

                # Output our formatted line-spec string
                print_flag_string()
            }
        '
    }
}   

# Move scrollbar to the left when necessary, as a user-activated command.
define-command move-scrollbar-to-left -override -docstring %{
    Move the scrollbar to the leftmost position in the stack of highlighters.
    } %{
    rmhl window/scrollbar-kak
    addhl -override window/scrollbar-kak flag-lines Scrollbar scrollbar_flags
}

###############################################################################
#                              Setup Commands                                 #
###############################################################################

define-command scrollbar-enable -docstring %{
    Enable the scrollbar in the current window
} %{
    # Get notified when scrollbar data needs to be updated
    hook -group scrollbar-kak window RawKey .* update-scrollbar
    hook -group scrollbar-kak window WinResize .* update-scrollbar

    # Let other plugins notify us if they change the view without a keypress
    hook -group scrollbar-kak window User ScrollEnd update-scrollbar

    # Update when a client connects to the window
    hook -group scrollbar-kak window ClientCreate .* update-scrollbar

    # Install the scrollbar highlighter
    addhl -override window/scrollbar-kak flag-lines Scrollbar scrollbar_flags
}

define-command scrollbar-disable -docstring %{
    Disable the scrollbar in the current window
} %{
    # Uninstall the scrollbar highlighter
    rmhl window/scrollbar-kak

    # Don't get notified when the scrollbar needs to be updated
    rmhooks window scrollbar-kak
}

###############################################################################
#                               Scrollbar.kak                                 #
###############################################################################

# The line-specs option for our scrollbar
declare-option -hidden line-specs scrollbar_flags

# I've chosen some default colours and scrollbar character styles which work
# well for my colour schemes; please customize them at your leisure.
face global Scrollbar red@Default
face global ScrollThumb red@SecondarySelection

declare-option str selection_chars " - = #"

# Generate the line-specs option that draws the scrollbar.
define-command update-scrollbar -hidden -override %{
    eval %sh{
        awk '
            # Convert a buffer-coordinate (1..height)
            # to a bar coordinate (view_top..view_top+view_height)
            function buffer_to_bar(line,    ratio) {
                ratio = (line - 1) / buffer_height
                return int(ratio * view_height + 0.5) + view_top
            }
            # Extract CURSORLINE from a selection description of the form:
            # ANCHORLINE.ANCHORCOL,CURSORLINE.CURSORCOL
            function get_cursorline(selection_desc,     result) {
                split(selection_desc, result, /,/)
                split(result[2], result, /\./)
                return result[1]
            }
            BEGIN {
                # Get the viewport dimensions from Kakoune.
                split(ENVIRON["kak_window_range"], view_rect)
                view_top    = view_rect[1] + 1 # convert from zero based
                view_height = view_rect[3]
                view_bottom = view_top + view_height - 1
                buffer_height = ENVIRON["kak_buf_line_count"]
                # Figure out how many cursors are in the part of the buffer
                # that corresponds to each line of the viewport.
                split(ENVIRON["kak_selections_desc"], selections_desc)
                for (i in selections_desc) {
                    cursor_line = get_cursorline(selections_desc[i])
                    view_line = buffer_to_bar(cursor_line)
                    selections[view_line]++
                }
                # Which lines of the viewport correspond to the visible area
                # of the buffer?
                thumb_top = buffer_to_bar(view_top)
                thumb_bottom = buffer_to_bar(view_bottom)
                # Start setting the flags option.
                printf "set-option window scrollbar_flags %s",
                    ENVIRON["kak_timestamp"]
                # Each line of the viewport will use a selection flag
                # chosen from the selection_chars option.
                split(ENVIRON["kak_opt_selection_chars"], sel_chars)
                # For each line of the viewport...
                for (i = view_top; i <= view_bottom; i++) {
                    # Choose a flag symbol based on the number of selections
                    if (selections[i] > length(sel_chars)) {
                        count = length(sel_chars)
                    } else {
                        count = selections[i]
                    }
                    flag = sprintf("%1s", sel_chars[count])
                    # Choose a face based on whether this line is in the
                    # scroll thumb or not.
                    if (thumb_top <= i && i <= thumb_bottom) {
                        face = "{ScrollThumb}"
                    } else {
                        face = "{Scrollbar}"
                    }
                    # Add this flag to the option.
                    printf " %%{%d|%s%s}", i, face, flag
                }
                print ""
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

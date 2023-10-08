provide-module set-operations %§

define-command set-operation -params .. -docstring '
set-operation [-register <register>] <operation>: perform a set operation on two sets of selections
The first set is the,

The operation can be one of the following:
    union: 
    intersection: 
    difference: 
    symmetric-difference: 
    hull: produces the smallest selection that contains all selections from both sets
' %{
    eval -save-regs '^' %sh{
        operation_set=0
        operation=''

        while [ "$#" -ge 1 ]; do
            if [ "$1" = '-register' ]; then
                shift
                if [ "$#" -eq 0 ]; then
                    printf 'fail TODO'
                    exit
                fi
                # TODO move reg content to ^
            else
                if [ "$operation_set" != 0 ]; then
                    printf 'fail TODO'
                    exit
                fi
                case "$1" in
                    'union') ;;
                    'intersection') ;;
                    'difference') ;;
                    'symmetric-difference') ;;
                    'hull') ;;
                    *)
                        printf 'fail TODO'
                        exit
                        ;;
                esac
                operation="$1"
                operation_set=1
            fi
            shift
        done
        if [ "$operation_set" = 0 ]; then
            printf 'fail TODO'
            exit
        fi

        perl - "$operation" <<'EOF'
use strict;
use warnings;

my $operation = shift;
$operation = uc($operation);

my $command_fifo_name = $ENV{"kak_command_fifo"};
my $response_fifo_name = $ENV{"kak_response_fifo"};

sub parse_shell_quoted {
    my $str = shift;
    my @res;
    my $elem = "";
    while (1) {
        if ($str !~ m/\G'([\S\s]*?)'/gc) {
            exit(1);
        }
        $elem .= $1;
        if ($str =~ m/\G *$/gc) {
            push(@res, $elem);
            $elem = "";
            last;
        } elsif ($str =~ m/\G\\'/gc) {
            $elem .= "'";
        } elsif ($str =~ m/\G */gc) {
            push(@res, $elem);
            $elem = "";
        } else {
            exit(2);
        }
    }
    return @res;
}

sub read_array {
    my $preeval = shift;
    my $what = shift;

    open (my $command_fifo, '>', $command_fifo_name);
    print $command_fifo "eval -draft %{ $preeval ; echo -quoting shell -to-file $response_fifo_name -- $what }";
    close($command_fifo);

    # slurp the response_fifo content
    open (my $response_fifo, '<', $response_fifo_name);
    my $response_quoted = do { local $/; <$response_fifo> };
    close($response_fifo);
    return parse_shell_quoted($response_quoted);
}

sub read_lines_length {
    my @descs = read_array("exec '%<a-s>);'", "%val{selections_desc}");
    my @res;
    for my $desc (@descs) {
        my @spl = split(/\./, $desc);
        push(@res, $spl[2]);
    }
    return @res;
}


# returns
#   -1 if first < second
#    0 if first == second
#   +1 if first > second
sub compare_coords {
    my $first = shift;
    my $second = shift;
    if ("$first $second" !~ m/(\d+)\.(\d+) (\d+)\.(\d+)/) {
        exit(3);
    }
    if ($1 < $3) {
        return -1;
    } elsif ($1 > $3) {
        return 1;
    } elsif ($2 < $4) {
        return -1;
    } elsif ($2 > $4) {
        return 1;
    }
    return 0;
}

sub get_selection_coords {
    my $input = shift;
    if ($input !~ m/^(.*?),(.*?)$/) {
        exit(4);
    }
    my $res = compare_coords($1, $2);
    if ($res == 1) {
        return ($2, $1);
    } else {
        return ($1, $2);
    }
}

sub min_coord {
    my $lhs = shift;
    my $rhs = shift;
    if (compare_coords($lhs, $rhs) > 0) {
        return $rhs;
    } else {
        return $lhs;
    }
}

sub max_coord {
    my $lhs = shift;
    my $rhs = shift;
    if (compare_coords($lhs, $rhs) > 0) {
        return $lhs;
    } else {
        return $rhs;
    }
}

sub neighbor_coord {
    my $lines_length_ref = shift;
    my $coord = shift;
    my $direction = shift;
    my @coords = split(/\./, $coord);
    if ($direction == 1) {
        if ($coords[1] < ($$lines_length_ref[$coords[0] - 1])) {
            return $coords[0] . "." . ($coords[1] + 1);
        } else {
            return ($coords[0] + 1) . "." . 1;
        }
    } elsif ($direction == -1) {
        if ($coords[1] > 1) {
            return $coords[0] . "." . ($coords[1] - 1);
        } else {
            # kakoune lines are 1-indexed, so -2 (== -1 (previous line) -1 (1-indexed))
            return ($coords[0] - 1) . "." . $$lines_length_ref[$coords[0] - 2];
        }
    } else {
        exit(5);
    }
}

use constant FIRST_ENTIRELY_BEFORE_SECOND => 1;
use constant FIRST_END_OVERLAPS_SECOND_BEGIN => 2;
use constant FIRST_ENTIRELY_AFTER_SECOND => 3;
use constant FIRST_BEGIN_OVERLAPS_SECOND_END => 4;
use constant FIRST_CONTAINS_SECOND => 5;
use constant FIRST_CONTAINED_BY_SECOND => 6;
use constant FIRST_EQUALS_SECOND => 7;

sub compute_overlap {
    my $beg1 = shift;
    my $end1 = shift;
    my $beg2 = shift;
    my $end2 = shift;
    my $res1 = compare_coords($end1, $beg2);
    if ($res1 == -1) {
        return FIRST_ENTIRELY_BEFORE_SECOND;
    }

    my $res2 = compare_coords($beg1, $end2);
    if ($res2 == 1) {
        return FIRST_ENTIRELY_AFTER_SECOND;
    }

    my $res3 = compare_coords($beg1, $beg2);
    my $res4 = compare_coords($end1, $end2);

    if ($res3 == 0 && $res4 == 0) {
        return FIRST_EQUALS_SECOND;
    } elsif ($res3 <= 0 && $res4 >= 0) {
        return FIRST_CONTAINS_SECOND;
    } elsif ($res3 >= 0 && $res4 <= 0) {
        return FIRST_CONTAINED_BY_SECOND;
    }

    if ($res3 < 0) {
        return FIRST_END_OVERLAPS_SECOND_BEGIN;
    } elsif ($res3 > 0) {
        return FIRST_BEGIN_OVERLAPS_SECOND_END;
    }

    exit(5);
    return 0;
}

my @current_selections_descs = read_array("exec \"%reg{hash}()\"", "%val{selections_desc}");
my @register_selections_descs = read_array("exec z ; exec \"%reg{hash}()\"", "%val{selections_desc}");
if (scalar(@current_selections_descs) == 0 || scalar(@register_selections_descs) == 0) {
    exit(6);
}

sub print_debug {
    my $what = shift;
    print("echo -debug '$what'\n");
}

sub intersection {
    my @res;

    my $list_1_ref = shift;
    my $list_2_ref = shift;
    my $size_list_1 = scalar(@$list_1_ref);
    my $size_list_2 = scalar(@$list_2_ref);

    my $i = 0;
    my $j = 0;
    while (1) {
        my $current_sel = $$list_1_ref[$i];
        my $secondary_sel = $$list_2_ref[$j];

        my ($beg1, $end1) = get_selection_coords($current_sel);
        my ($beg2, $end2) = get_selection_coords($secondary_sel);

        my $overlap = compute_overlap($beg1, $end1, $beg2, $end2);

        if ($overlap == FIRST_ENTIRELY_BEFORE_SECOND) {
            # noop
        } elsif ($overlap == FIRST_ENTIRELY_AFTER_SECOND) {
            # noop
        } elsif ($overlap == FIRST_CONTAINS_SECOND) {
            push(@res, $secondary_sel);
        } elsif ($overlap == FIRST_CONTAINED_BY_SECOND) {
            push(@res, $current_sel);
        } elsif ($overlap == FIRST_EQUALS_SECOND) {
            push(@res, $current_sel);
        } elsif ($overlap == FIRST_END_OVERLAPS_SECOND_BEGIN) {
            push(@res, "$beg2,$end1");
        } elsif ($overlap == FIRST_BEGIN_OVERLAPS_SECOND_END) {
            push(@res, "$beg1,$end2");
        }

        my $last_cur = ($i == ($size_list_1 - 1));
        my $last_reg = ($j == ($size_list_2 - 1));
        if ($last_cur && $last_reg) {
            last;
        } elsif ($last_cur) {
            $j++;
        } elsif ($last_reg) {
            $i++;
        } elsif (compare_coords($end1, $end2) >= 0) {
            $j++;
        } else {
            $i++;
        }
    }
    return @res;
}

sub union {
    my @res;

    my $list_1_ref = shift;
    my $list_2_ref = shift;
    my $size_list_1 = scalar(@$list_1_ref);
    my $size_list_2 = scalar(@$list_2_ref);

    if ($size_list_1 == 0) {
        return @$list_2_ref;
    } elsif($size_list_2 == 0) {
        return @$list_1_ref;
    }

    my $i = 0;
    my $j = 0;

    my ($first_beg, $first_end) = get_selection_coords($$list_1_ref[0]);
    my ($second_beg, $second_end) = get_selection_coords($$list_2_ref[0]);

    my $cur_beg = undef;

    while (1) {
        my $advance_first = 0;
        my $advance_second = 0;

        my $overlap = compute_overlap($first_beg, $first_end, $second_beg, $second_end);
        if (!defined($cur_beg)) {
            $cur_beg = min_coord($first_beg, $second_beg);
        }

        if ($overlap == FIRST_ENTIRELY_BEFORE_SECOND) {
            push(@res, "$cur_beg,$first_end");
            $cur_beg = undef;
            $advance_first = 1;
        } elsif ($overlap == FIRST_EQUALS_SECOND) {
            push(@res, "$cur_beg,$first_end");
            $cur_beg = undef;
            $advance_first = 1;
            $advance_second = 1;
        } elsif ($overlap == FIRST_CONTAINS_SECOND) {
            $advance_second = 1;
        } elsif ($overlap == FIRST_END_OVERLAPS_SECOND_BEGIN) {
            $advance_first = 1;
        } elsif ($overlap == FIRST_ENTIRELY_AFTER_SECOND) {
            push(@res, "$cur_beg,$second_end");
            $cur_beg = undef;
            $advance_second = 1;
        } elsif ($overlap == FIRST_CONTAINED_BY_SECOND) {
            $advance_first = 1;
        } elsif ($overlap == FIRST_BEGIN_OVERLAPS_SECOND_END) {
            $advance_second = 1;
        }

        if ($advance_first == 1) {
            $i++;
            if ($i == $size_list_1) {
                if (defined($cur_beg)) {
                    push(@res, "$cur_beg,$second_end");
                    $cur_beg = undef;
                    $j++;
                }
                while ($j < $size_list_2) {
                    push(@res, $$list_2_ref[$j]);
                    $j++;
                }
                last;
            }
            ($first_beg, $first_end) = get_selection_coords($$list_1_ref[$i]);
        }
        if ($advance_second == 1) {
            $j++;
            if ($j == $size_list_2) {
                if (defined($cur_beg)) {
                    push(@res, "$cur_beg,$first_end");
                    $cur_beg = undef;
                    $i++;
                }
                while ($i < $size_list_1) {
                    push(@res, $$list_1_ref[$i]);
                    $i++;
                }
                last;
            }
            ($second_beg, $second_end) = get_selection_coords($$list_2_ref[$j]);
        }
    }
    return @res;
}


sub difference {
    my @res;

    my $list_1_ref = shift;
    my $list_2_ref = shift;
    my $lines_length_ref = shift;
    my $size_list_1 = scalar(@$list_1_ref);
    my $size_list_2 = scalar(@$list_2_ref);

    my $i = 0;
    my $j = 0;

    my ($cur_beg, $cur_end) = get_selection_coords($$list_1_ref[0]);
    my ($second_beg, $second_end) = get_selection_coords($$list_2_ref[0]);
    while (1) {
        my $advance_cur = 0;
        my $advance_second = 0;

        my $overlap = compute_overlap($cur_beg, $cur_end, $second_beg, $second_end);
        if ($overlap == FIRST_ENTIRELY_BEFORE_SECOND) {
            push(@res, "$cur_beg,$cur_end");
            $advance_cur = 1;
        } elsif ($overlap == FIRST_EQUALS_SECOND) {
            $advance_cur = 1;
            $advance_second = 1;
        } elsif ($overlap == FIRST_CONTAINS_SECOND) {
            if (compare_coords($cur_beg, $second_beg) == -1) {
                # 'cur' starts before 'second'
                my $next_beg = neighbor_coord($lines_length_ref, $second_beg, -1);
                push(@res, "$cur_beg,$next_beg")
            }
            if (compare_coords($cur_end, $second_end) == 1) {
                # 'cur' finishes after 'second'
                $cur_beg = neighbor_coord($lines_length_ref, $second_end, 1);
            } else {
                # 'cur' finishes exactly like 'second'
                $advance_cur = 1;
            }
            $advance_second = 1;
        } elsif ($overlap == FIRST_END_OVERLAPS_SECOND_BEGIN) {
            my $next_beg = neighbor_coord($lines_length_ref, $second_beg, -1);
            push(@res, "$cur_beg,$next_beg");
            $advance_cur = 1;
        } elsif ($overlap == FIRST_ENTIRELY_AFTER_SECOND) {
            $advance_second = 1;
        } elsif ($overlap == FIRST_CONTAINED_BY_SECOND) {
            $advance_cur = 1;
        } elsif ($overlap == FIRST_BEGIN_OVERLAPS_SECOND_END) {
            $cur_beg = neighbor_coord($lines_length_ref, $second_end, 1);
            $advance_second = 1;
        }

        if ($advance_cur == 1) {
            $i++;
            if ($i == $size_list_1) {
                last;
            }
            ($cur_beg, $cur_end) = get_selection_coords($$list_1_ref[$i]);
        }
        if ($advance_second == 1) {
            $j++;
            if ($j == $size_list_2) {
                push(@res, "$cur_beg,$cur_end");
                $i++;
                while ($i < $size_list_1) {
                    push(@res, $$list_1_ref[$i]);
                    $i++;
                }
                last;
            }
            ($second_beg, $second_end) = get_selection_coords($$list_2_ref[$j]);
        }
    }
    return @res;
}

sub hull {
    my $list_1_ref = shift;
    my $list_2_ref = shift;
    my $lines_length_ref = shift;
    my $size_list_1 = scalar(@$list_1_ref);
    my $size_list_2 = scalar(@$list_2_ref);

    my $tmp;
    my $beg1;
    my $beg2;
    my $end1;
    my $end2;
    ($beg1, $tmp) = get_selection_coords($$list_1_ref[0]);
    ($beg2, $tmp) = get_selection_coords($$list_2_ref[0]);

    ($tmp, $end1) = get_selection_coords($$list_1_ref[$size_list_1 - 1]);
    ($tmp, $end2) = get_selection_coords($$list_2_ref[$size_list_2 - 1]);

    my $min = min_coord($beg1, $beg2);
    my $max = max_coord($end1, $end2);

    my @res;
    push(@res, "$min,$max");
    return @res;
}

my @new_selections;
if ($operation eq 'INTERSECTION') {
    @new_selections = intersection(\@current_selections_descs, \@register_selections_descs);
} elsif ($operation eq 'UNION') {
    @new_selections = union(\@current_selections_descs, \@register_selections_descs);
} elsif ($operation eq 'DIFFERENCE') {
    my @lines_length = read_lines_length();
    @new_selections = difference(\@current_selections_descs, \@register_selections_descs, \@lines_length);
} elsif ($operation eq 'SYMMETRIC-DIFFERENCE') {
    my @lines_length = read_lines_length();
    my @temp1 = difference(\@current_selections_descs, \@register_selections_descs, \@lines_length);
    my @temp2 = difference(\@register_selections_descs, \@current_selections_descs, \@lines_length);
    @new_selections = union(\@temp1, \@temp2);
} elsif ($operation eq 'HULL') {
    @new_selections = hull(\@current_selections_descs, \@register_selections_descs);
}

# sanity checks
my $num_new_selections = scalar(@new_selections);
for my $i (0 .. ($num_new_selections - 1)) {
    my ($cur_beg, $cur_end) = get_selection_coords($new_selections[$i]);
    if (compare_coords($cur_beg, $cur_end) > 0) {
        exit(7);
    }
    if ($i < ($num_new_selections - 1)) {
        my ($next_beg, $next_end) = get_selection_coords($new_selections[$i + 1]);
        if (compare_coords($next_beg, $cur_end) <= 0) {
            exit(8);
        }
    }
}

if (scalar(@new_selections) == 0) {
    print("fail 'No selections remaining'");
} else {
    print("select");
    for my $desc (@new_selections) {
        print(" '$desc'");
    }
    print(" ;");
}
exit(0);
EOF
        res=$?
        if [ $res != 0 ]; then
            printf "fail 'TODO $res'"
        fi
    }
}

§

require-module set-operations

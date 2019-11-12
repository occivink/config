define-command sort-selections -params ..2 -docstring '
sort-selections [-reverse] [<register>]: sort the selections
Sorting is done numerically if possible, otherwise lexicographically
If a <register> is specified, the values of the register will be sorted instead,
and the resulting order then applied to the selections.
'%{
    eval %sh{
        if [ $# -eq 2 ]; then
            if [ $1 != '-reverse' ]; then
                printf 'fail "Invalid flag %%arg{1}"'
            elif [ ${#2} -ne 1 ]; then
                printf 'fail "Invalid register %%arg{2}"'
            else
                printf "sort-selections-impl REVERSE INDICES %%reg{$2}"
            fi
        elif [ $# -eq 1 ]; then
            if [ $1 = '-reverse' ]; then
                printf 'sort-selections-impl REVERSE DIRECT'
            elif [ ${#1} -eq 1 ]; then
                printf "sort-selections-impl NORMAL INDICES %%reg{$1}"
            else
                printf 'fail "Invalid flag or register %%arg{1}"'
            fi
        else
            printf 'sort-selections-impl NORMAL DIRECT'
        fi
    }
}

define-command reverse-selections -docstring '
reverse-selections: reverses the order of all selections
'%{ sort-selections -reverse '#' }

define-command sort-selections-impl -hidden -params .. %{
    eval -save-regs '"' %{
        reg dquote '' # in case the %sh fails, not great
        eval %sh{
perl - "$@" <<'EOF'
use strict;
use warnings;
use Text::ParseWords "shellwords";
use Scalar::Util "looks_like_number";

my $direction = shift;
my $how = shift;

my @sel_content = shellwords($ENV{"kak_quoted_selections"});

if ($how eq 'DIRECT') {
    my $all_numbers=1;
    for my $val (@sel_content) {
        if (not looks_like_number($val)) {
            $all_numbers=0;
            last;
        }
    }
    my @sorted;
    if ($direction eq 'REVERSE') {
        if ($all_numbers == 1) {
            @sorted = sort { $b <=> $a; } @sel_content;
        } else {
            @sorted = sort { $b cmp $a; } @sel_content;
        }
    } else {
        if ($all_numbers == 1) {
            @sorted = sort { $a <=> $b; } @sel_content;
        } else {
            @sorted = sort { $a cmp $b; } @sel_content;
        }
    }
    print("reg '\"'");
    for my $sel (@sorted) {
        $sel =~ s/'/''/g;
        print(" '$sel'");
    }
    print(" ;");
} else {
    my @indices = @ARGV;
    if (scalar(@indices) != scalar(@sel_content)) {
        print('fail "The register must contain as many values as selections"');
        exit;
    }
    my $all_numbers=1;
    for my $val (@indices) {
        if (not looks_like_number($val)) {
            $all_numbers=0;
            last;
        }
    }
    my @pairs;
    for my $i (0 .. scalar(@indices) - 1) {
        push(@pairs, [ $indices[$i], $sel_content[$i] ] );
    }
    my @sorted;
    if ($direction eq 'REVERSE') {
        if ($all_numbers == 1) {
            @sorted = sort { @$b[0] <=> @$a[0]; } @pairs;
        } else {
            @sorted = sort { @$b[0] cmp @$a[0]; } @pairs;
        }
    } else {
        if ($all_numbers == 1) {
            @sorted = sort { @$a[0] <=> @$b[0]; } @pairs;
        } else {
            @sorted = sort { @$a[0] cmp @$b[0]; } @pairs;
        }
    }
    print("reg '\"'");
    for my $pair (@sorted) {
        my $sel = @$pair[1];
        $sel =~ s/'/''/g;
        print(" '$sel'");
    }
    print(" ;");
}
EOF
        }
        exec R
    }
}


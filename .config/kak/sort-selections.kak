provide-module sort-selections %{

define-command sort-selections -params ..2 -docstring '
sort-selections [-reverse] [<register>]: sort the selections
Sorting is done numerically if possible, otherwise lexicographically
If <register> is specified, the values of the register will be sorted instead,
and the resulting order then applied to the selections.
' %{
    try %{
        exec -draft '<a-space><esc><a-,><esc>'
    } catch %{
        fail 'Only one selection, cannot sort'
    }
    eval %sh{
        if [ $# -eq 2 ]; then
            if [ "$1" != '-reverse' ]; then
                printf 'fail "Invalid flag %%arg{1}"'
            else
                printf "try %%{ nop -- %%reg{%s} } catch %%{ fail 'Invalid register ''%s''' }\n" "$2" "$2"
                printf "sort-selections-impl REVERSE INDICES %%{%s}" "$2"
            fi
        elif [ $# -eq 1 ]; then
            if [ "$1" = '-reverse' ]; then
                printf 'sort-selections-impl REVERSE DIRECT'
            else
                printf "try %%{ nop -- %%reg{%s} } catch %%{ fail 'Invalid register ''%s''' }\n" "$1" "$1"
                printf "sort-selections-impl NORMAL INDICES %%{%s}" "$1"
            fi
        else
            printf 'sort-selections-impl NORMAL DIRECT'
        fi
    }
}

define-command reverse-selections -docstring '
reverse-selections: reverses the order of all selections
' %{ sort-selections -reverse '#' }

define-command shuffle-selections -docstring '
shuffle-selections: randomizes the order of all selections
' %{
    eval -save-regs '"' %{
        eval reg dquote %sh{ seq "$kak_selection_count" | shuf | tr '\n' ' ' }
        sort-selections '"'
    }
}

define-command sort-selections-impl -hidden -params .. %{
    eval -save-regs '"' %{
        eval %sh{
perl - "$@" <<'EOF'
use strict;
use warnings;
use Scalar::Util "looks_like_number";

my $direction = shift;
my $how = shift;

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
            exit(1);
        }
    }
    return @res;
}

sub read_array {
    my $what = shift;

    open (my $command_fifo, '>', $command_fifo_name);
    print $command_fifo "echo -quoting shell -to-file $response_fifo_name -- $what";
    close($command_fifo);

    # slurp the response_fifo content
    open (my $response_fifo, '<', $response_fifo_name);
    my $response_quoted = do { local $/; <$response_fifo> };
    close($response_fifo);
    return parse_shell_quoted($response_quoted);
}

sub all_numbers {
    my $array_ref = shift;
    for my $val (@$array_ref) {
        if (not looks_like_number($val)) {
            return 0;
        }
    }
    return 1;
}

my @selections = read_array("%val{selections}");

if ($how eq 'DIRECT') {
    my @sorted;
    if ($direction eq 'REVERSE') {
        if (all_numbers(\@selections)) {
            @sorted = sort { $b <=> $a; } @selections;
        } else {
            @sorted = sort { $b cmp $a; } @selections;
        }
    } else {
        if (all_numbers(\@selections)) {
            @sorted = sort { $a <=> $b; } @selections;
        } else {
            @sorted = sort { $a cmp $b; } @selections;
        }
    }
    print("reg dquote");
    for my $sel (@sorted) {
        $sel =~ s/'/''/g;
        print(" '$sel'");
    }
    print(" ;");
} else {
    my $register_name = shift;

    my @indices = read_array("%reg{$register_name}");

    if (scalar(@indices) != scalar(@selections)) {
        print('fail "The register must contain as many values as selections"');
        exit;
    }
    my @pairs;
    for my $i (0 .. scalar(@indices) - 1) {
        push(@pairs, [ $indices[$i], $selections[$i] ] );
    }
    my @sorted;
    if ($direction eq 'REVERSE') {
        if (all_numbers(\@indices)) {
            @sorted = sort { @$b[0] <=> @$a[0]; } @pairs;
        } else {
            @sorted = sort { @$b[0] cmp @$a[0]; } @pairs;
        }
    } else {
        if (all_numbers(\@indices)) {
            @sorted = sort { @$a[0] <=> @$b[0]; } @pairs;
        } else {
            @sorted = sort { @$a[0] cmp @$b[0]; } @pairs;
        }
    }
    print("reg dquote");
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

}

require-module sort-selections

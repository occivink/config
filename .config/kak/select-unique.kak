provide-module select-unique %{

define-command select-unique -override -params .. -docstring '
select-unique [-strict] [-reverse]: filter selections based on uniqueness
' -shell-script-candidates %{
    printf '%s\n' -strict -reverse
} %{
    try %{
        exec -draft '<a-space><esc><a-,><esc>'
    } catch %{
        fail 'Only one selection, cannot filter'
    }
    eval %sh{
        order="NORMAL"
        unique_where="OUTPUT"
        i=1
        for arg do
            if [ "$arg" = '-strict' ]; then
                unique_where="INPUT"
            elif [ "$arg" = '-reverse' ]; then
                order="REVERSE"
            else
                printf "fail \"Unrecognized argument '%s'\"" "%arg{$i}"
                exit
            fi
            i=$((i + 1))
        done
        perl - "$unique_where" "$order" <<'EOF'
use strict;
use warnings;

my $unique_in_input = shift;
$unique_in_input = ($unique_in_input eq "INPUT");
my $reverse = shift;
$reverse = ($reverse eq "REVERSE");

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

my @selections = read_array("%val{selections}");
my @selections_desc = read_array("%val{selections_desc}");

# in %val{selections_desc}, the main selection is at the front
# we just put it back in its place, so that it matches %val{selections}

#print("echo -debug BAD ;");
#for my $desc (@selections_desc) {
#    print("echo -debug $desc ;");
#}

my $main_selection_index = $ENV{"kak_main_reg_hash"} - 1; # reg_hash is 1-based
my $selections_count = scalar(@selections_desc);
for my $i ($main_selection_index .. ($selections_count - 1)) {
    my $desc = shift(@selections_desc);
    push(@selections_desc, $desc);
}

#print("echo -debug GOOD? ;");
#for my $desc (@selections_desc) {
#    print("echo -debug $desc ;");
#}
#print("echo -debug OK ;");

my @result_descs;
my $closest_selection_to_main_idx = 0;

if ($unique_in_input) {
    my %occurrences_count;
    for my $sel (@selections) {
        if (exists($occurrences_count{$sel})) {
            my $prev_val = $occurrences_count{$sel};
            $occurrences_count{$sel} = $prev_val + 1;
        } else {
            $occurrences_count{$sel} = 1;
        }
    }
    for my $i (0 .. scalar(@selections) - 1) {
        my $sel = $selections[$i];
        if (($occurrences_count{$sel} == 1 && !$reverse) ||
            ($occurrences_count{$sel} != 1 && $reverse)
        ) {
            if ($i <= $main_selection_index) {
                $closest_selection_to_main_idx = scalar(@result_descs);
            }
            push(@result_descs, $selections_desc[$i]);
        }
    }
} else {
    # unique in output case
    my %occurred;
    for my $i (0 .. scalar(@selections) - 1) {
        my $sel = $selections[$i];
        my $new = 0;
        if (!exists($occurred{$sel})) {
            $occurred{$sel} = 1;
            $new = 1;
        }
        if (($new && !$reverse) || (!$new && $reverse)) {
            if ($i <= $main_selection_index) {
                $closest_selection_to_main_idx = scalar(@result_descs);
            }
            push(@result_descs, $selections_desc[$i]);
        }
    }
}

if (scalar(@result_descs) == 0) {
    # nothing to select, invalid input
    print("fail 'no selections remaining' ;");
    exit(1);
}

if ($closest_selection_to_main_idx > 0) {
    my $new_main_desc = splice(@result_descs, $closest_selection_to_main_idx, 1);
    unshift(@result_descs, $new_main_desc);
}

print("select");
for my $desc (@result_descs) {
    print(" '$desc'");
}
print(" ;");

EOF
    }
}

}

require-module select-unique

provide-module replace-map %{

define-command replace-map -params .. -docstring '
replace-map [<switches>]: replaces the current selections with new values from a key-value map
The map used for lookups is specified using the content of the copy register (", or dquote)
Switches:
    -map-order <order>: specify the order in which the keys and values occur in the register. Possible values are:
                        kvkv: keys and values are interleaved, keys first (default)
                        vkvk: keys and values are interleaved, values first
                        kkvv: all keys first, then all values
                        vvkk: all values first, then all keys
    -not-found-keep: if a selection does not appear in the keys of the map, keep it as-is
    -not-found-value <value>: if a selection does not appear in the keys of the map, replace it with <value>
    -allow-duplicate-keys: allow the same key to occur multiple times, in which case the value specified last prevails
    -select-found: only keep the selections which appeared in the keys of the map
    -select-not-found: only keep the selections which did not appear in the keys of the map
    -map-register <register>: use the specified register as lookup map, instead of dquote
    -target-register <register>: do not replace, put the results into the specified register instead
    -dry-run: do not replace, only check if input parameters are valid (and select if applicable)
' -shell-script-candidates %{
    printf '%s\n'  -map-order -not-found-keep -not-found-value -allow-duplicate-keys \
        -select-found -select-not-found -map-register -target-register -dry-run
} %{
    eval %sh{
        map_register='dquote'
        map_order=kvkv
        not_found_mode=0 # 0 = fail / 1 = keep / 2 = fallback
        not_found_fallback_value=''
        allow_duplicate_keys=0
        select_mode=0 # 0 = all / 1 = found / 2 = not found
        target_register=''
        dry_run=0
        while [ $# -ne 0 ]; do
            arg_num=$((arg_num + 1))
            arg=$1
            shift
            if [ "$arg" = '-map-order' ]; then
                [ $# -eq 0 ] && echo 'fail "Missing argument to -map-order"' && exit 1
                case "$1" in
                    kvkv|vkvk|kkvv|vvkk) ;;
                    *) printf "fail \"Invalid value to -map-order: '%%arg{%s}'\"" "$arg_num"
                       exit 1
                       ;;
                esac
                map_order="$1"
                shift
            elif [ "$arg" = '-not-found-keep' ]; then
                not_found_mode=1
            elif [ "$arg" = '-not-found-value' ]; then
                [ $# -eq 0 ] && echo 'fail "Missing argument to -not-found-value"' && exit 1
                not_found_mode=2
                arg_num=$((arg_num + 1))
                not_found_fallback_value="$1"
                shift
            elif [ "$arg" = '-allow-duplicate-keys' ]; then
                allow_duplicate_keys=1
            elif [ "$arg" = '-select-found' ]; then
                select_mode=1
            elif [ "$arg" = '-select-not-found' ]; then
                select_mode=2
            elif [ "$arg" = '-map-register' ] || [ "$arg" = '-target-register' ]; then
                [ $# -eq 0 ] && echo "fail \"Missing argument to $arg\"" && exit 1
                arg_num=$((arg_num + 1))
                case "$1" in
                    "'") register="''" ;;
                    *"'"*) printf "fail \"Invalid register '%%arg{%s}'\"" "$arg_num" # need to early exit here, otherwise the %reg'' call won't work
                           exit 1
                           ;;
                    *) register="$1" ;;
                esac
                printf "nop -- %%reg'%s'\n" "$register" # actually validate it
                                                        # TODO make a pretty failure message
                if [ "$arg" = '-map-register' ]; then
                    map_register="$register"
                elif [ "$arg" = '-target-register' ]; then
                    target_register="$register"
                fi
                shift
            elif [ "$arg" = '-dry-run' ]; then
                dry_run=1
            else
                printf "fail \"Unrecognized argument '%%arg{%s}'\"" "$arg_num"
                exit 1
            fi
        done

        printf "replace-map-impl"
        printf " '%s'" "$map_register" "$map_order" "$not_found_mode"
        # $not_found_fallback_value can be arbitrary, so we need to escape it (== double-up single-quotes)
        if [ "$not_found_fallback_value" = '' ]; then
            printf " ''"
        else
            rest="$not_found_fallback_value"
            printf " '"
            while :; do
                beforequote="${rest%%"'"*}"
                if [ "$rest" = "$beforequote" ]; then
                    printf '%s' "$rest"
                    break
                fi
                printf "%s''" "$beforequote"
                rest="${rest#*"'"}"
            done
            printf "'"
        fi
        printf " '%s'" "$allow_duplicate_keys" "$select_mode" "$target_register" "$dry_run"
    }
}

define-command replace-map-impl -hidden -params 8 %{
    eval -save-regs %sh{ [ "$7" = '' ] && printf '"' } %sh{
perl - "$@" <<'EOF'
use strict;
use warnings;

my $map_register = shift;
my $map_order = shift;
my $not_found_mode = shift;
my $not_found_fallback_value = shift;
my $allow_duplicate_keys = shift;
my $select_mode = shift;
my $target_register = shift;
my $dry_run = shift;

my $command_fifo_name = $ENV{"kak_command_fifo"};
my $response_fifo_name = $ENV{"kak_response_fifo"};

sub parse_shell_quoted {
    my $str = shift;
    my @res;
    my $elem = "";
    while (1) {
        if ($str !~ m/\G'([\S\s]*?)'/gc) {
            print("echo -debug error1");
            exit;
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
            print("echo -debug error2");
            exit;
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

my @map_values = read_array("%reg'$map_register'");
if (scalar(@map_values) % 2 != 0) {
    print("fail 'The map register must contain an even number of values' ;");
    exit;
}

my @selections = read_array("%val{selections}");

my %map;
my $idx_key;
my $idx_val;
my $idx_incr;
if ($map_order eq 'kvkv' or $map_order eq 'vkvk') {
    $idx_key = 0;
    $idx_val = 1;
    $idx_incr = 2;
} elsif ($map_order eq 'kkvv' or $map_order eq 'vvkk') {
    $idx_key = 0;
    $idx_val = scalar(@map_values) / 2;
    $idx_incr = 1;
} else {
    exit;
}
if ($map_order eq 'vkvk' or $map_order eq 'vvkk') {
    ($idx_key, $idx_val) = ($idx_val, $idx_key);
}

for (my $i = 0; $i < scalar(@map_values) / 2; $i++) {
    my $key = $map_values[$idx_key + $i * $idx_incr];
    my $value = $map_values[$idx_val + $i * $idx_incr];
    if ($allow_duplicate_keys == 0 and exists($map{$key})) {
        print("fail 'The map contains duplicate keys' ;");
        exit;
    }
    $map{$key} = $value;
}

my $not_found_keys = 0;
my $found_keys = 0;
my @results;
my @indices_to_remove;
for my $i (0 .. $#selections) {
    my $selection = $selections[$i];
    if (exists($map{$selection})) {
        $found_keys += 1;
        my $value = $map{$selection};
        push(@results, $value);
        if ($select_mode == 2) {
            push(@indices_to_remove, $i);
        }
    } else {
        $not_found_keys += 1;
        if ($not_found_mode == 0) {
            #
        } elsif ($not_found_mode == 1) {
            push(@results, $selection);
        } elsif ($not_found_mode == 2) {
            push(@results, $not_found_fallback_value);
        } else {
            exit;
        }
        if ($select_mode == 1) {
            push(@indices_to_remove, $i);
        }
    }
}
if ($not_found_mode == 0 and $not_found_keys > 0) {
    print("fail '$not_found_keys selections could not be found in the map' ;");
    exit;
}

if ($dry_run == 0) {
    if ($target_register eq '') {
        print("reg dquote");
    } else {
        # safe, target_register was already validated and escaped
        print("reg '$target_register'");
    }
    for my $result (@results) {
        $result =~ s/'/''/g;
        print(" '$result'");
    }
    print(" ;");
    if ($target_register eq '') {
        print("exec R ;");
    }
}

if ($select_mode != 0) {
    if (scalar(@indices_to_remove) == scalar(@results)) {
        # can't deselect everything
    } else {
        print("exec '");
        for my $index (reverse(@indices_to_remove)) {
            my $kak_index = $index + 1;
            print("$kak_index<a-,>");
        }
        print("' ;");
    }
}

print("echo -markup '{Information}Replaced $found_keys selections");
if ($dry_run != 0) {
    print(" (dry-run)");
}
print("' ; ");

EOF
    }
}

}

require-module replace-map

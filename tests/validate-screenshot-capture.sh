#!/usr/bin/env bash
# validate-screenshot-capture.sh — validate build/capture-screenshots.pl, the
# documentation screenshot tool, against ltl's own output
# (features/598-screenshot-capture.md § Acceptance criteria 1 to 8, 11, and
# 13 to 19: the folder ltl runs in and the PNG beside each SVG).
# Usage: ./tests/validate-screenshot-capture.sh [--scenario NAME | --list]
#
# The tool reads -V section-layout to place its crops, so a change to that
# report or to ltl's rendered output that would break the documentation's
# screenshots fails here before merge. Every image is read back into cells
# (tests/lib/screenshot-cells.pl) and compared with ltl's output decoded
# independently by tests/lib/rendered-output.pl, never with the tool's own
# reading of it.
#
# Follows the self-documenting assertion design from tests/HARNESS-DESIGN.md:
# every assertion records asserts, produced_by and contract. The file name
# follows the tool, not a -V section (features/598-screenshot-capture.md §
# Verification).

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
LTL="$REPO_DIR/ltl"
TOOL="$REPO_DIR/build/capture-screenshots.pl"
CELLS="$SCRIPT_DIR/lib/screenshot-cells.pl"
CONTRACT='features/598-screenshot-capture.md'

# shellcheck source=lib/runtime-warnings.sh
source "$SCRIPT_DIR/lib/runtime-warnings.sh"
# shellcheck source=lib/colour-env.sh
source "$SCRIPT_DIR/lib/colour-env.sh"
# shellcheck source=lib/scenario-select.sh
source "$SCRIPT_DIR/lib/scenario-select.sh"

# Ambient FORCE_COLOR/NO_COLOR must not decide what this harness asserts
# against (tests/HARNESS-DESIGN.md section Colour rendering is controlled,
# never inherited). The tool also removes both from ltl's environment.
neutralize_colour_env

# The committed synthetic Tomcat fixture: a spread of durations and bytes, so
# the timeline, heatmap, histogram and summary all render; 434 lines.
FIXTURE="tests/fixtures/tomcat-access-duration-spread.txt"
# Invocation shape (tests/HARNESS-DESIGN.md section Invocation coherence): the
# assertions read the timeline with its heatmap, the histogram and the
# summary, so each renders; -n 1 keeps the messages table to one row. The time
# axis is the subject (the timeline's rows), so the fixture's 14.5 hours stay
# at the default bucket size for 53 rows.
SHAPE="-ni -hm duration -hg duration -n 1"

for f in "$LTL" "$TOOL" "$CELLS" "$REPO_DIR/$FIXTURE"; do
    [[ -e "$f" ]] || { echo "ERROR: not found: $f"; exit 1; }
done

TMP_DIR=$(mktemp -d)
trap 'rm -rf "$TMP_DIR"' EXIT

scenario_register crop-cells colours ticks heatmap-colours background hidden-absent size-precedence runs-and-crops manifest edges \
    run-folder manifest-folder folder-output-files folder-index png-size png-pixels png-needs-swiftc
scenario_parse_args "$@"

pass=0
fail=0
failures=()
current_scenario=""

pass_with() { echo "  PASS  $current_scenario :: $1"; pass=$((pass + 1)); }
fail_with() {
    echo "  FAIL  $current_scenario :: $1"
    echo "        asserts:     $2"
    echo "        produced_by: $3"
    echo "        contract:    $4"
    [[ -n "${5:-}" ]] && echo "$5" | sed 's/^/        /'
    fail=$((fail + 1))
    failures+=("$current_scenario :: $1")
}

# assert_command: PASS when the command exits 0 (tests/HARNESS-DESIGN.md
# section When the assertion isn't a simple line grep).
assert_command() {
    local command label asserts produced_by contract detail
    while [[ $# -gt 0 ]]; do
        case "$1" in
            command)     command="$2";     shift 2 ;;
            label)       label="$2";       shift 2 ;;
            asserts)     asserts="$2";     shift 2 ;;
            produced_by) produced_by="$2"; shift 2 ;;
            contract)    contract="$2";    shift 2 ;;
            *) echo "assert_command: unknown field '$1'"; exit 2 ;;
        esac
    done
    : "${command:?}" "${label:?}" "${asserts:?}" "${produced_by:?}" "${contract:?}"
    if detail=$(eval "$command" 2>&1); then
        pass_with "$label${detail:+ ($(echo "$detail" | tail -1))}"
    else
        fail_with "$label" "$asserts" "$produced_by" "$contract" "command: $command
$detail"
    fi
}

# Run the tool; its standard output and standard error land beside $1.
# Returns the tool's exit status without stopping the harness.
run_tool() {
    local out="$1"; shift
    ( cd "$REPO_DIR" && "$TOOL" "$@" ) > "$out" 2> "$out.stderr" && return 0 || return $?
}

# The tool passes ltl's standard error through: a Perl warning from either
# lands in $out.stderr.
check_warnings() {
    if ! assert_no_runtime_warnings "$1.stderr" "$current_scenario"; then
        fail=$((fail + 1))
        failures+=("$current_scenario :: perl-runtime-warnings-on-stderr")
    fi
}

# ltl's own output for the command the tool traced as its capture run, with
# -V section-layout and --debug-layout added, run by this harness: the
# expected cells, section rows and heatmap columns come from here, not from the
# tool. -ni per Invocation coherence (it changes the options row only, which no
# crop reads).
capture_ltl() {
    local trace="$1" out="$2" args
    args=$(sed -n 's/^trace: capture run: ltl //p' "$trace")
    [[ -n "$args" ]] || { echo "no capture run in the trace $trace"; return 1; }
    # shellcheck disable=SC2086
    ( cd "$REPO_DIR" && "$LTL" -ni --debug-layout -V section-layout $args ) > "$out" 2> "$out.stderr"
    # The -V block prints after the last row, so rows keep their numbers.
    sed -n '/^=== section-layout ===$/,/^=== END section-layout ===$/p' "$out" > "$out.layout"
    check_warnings "$out"
}

# A section's first and last row from the harness's own section-layout.
section_rows() {
    awk -F'\t' -v n="$2" '$1 == n && $2 == "rendered" { print $3, $3 + $4 - 1 }' "$1.layout"
}

# An image's width and height: the SVG's attributes, or the PNG's header.
svg_size() { sed -n '1s/^<svg [^>]*width="\([0-9.]*\)" height="\([0-9.]*\)".*/\1 \2/p' "$1"; }
png_size() { perl -e 'open my $f, "<:raw", $ARGV[0] or exit 1; read $f, my $b, 24; print join(" ", unpack "x16 N2", $b), "\n"' "$1"; }

# Every SVG in a folder has a PNG of the same name, of its width and height.
pngs_match_svgs() {
    local dir="$1" svg png n=0
    for svg in "$dir"/*.svg; do
        [[ -e "$svg" ]] || { echo "no SVG in $dir"; return 1; }
        png="${svg%.svg}.png"
        [[ -s "$png" ]] || { echo "no PNG beside $svg"; return 1; }
        [[ "$(svg_size "$svg")" == "$(png_size "$png")" ]] || { echo "$png is $(png_size "$png"), $svg is $(svg_size "$svg")"; return 1; }
        n=$((n + 1))
    done
    echo "$n SVGs, each with its PNG of the same size"
}

# The files at the top of a folder named as ltl names the files -o writes.
output_files_in() { ls "$1" | grep -E 'LTL-.*(STATS.*|MESSAGES.*)\.csv$|LTL-.*AGGREGATE\.yaml$' || true; }

# A traced crop's rows and columns: "first last col_first col_stop".
traced_crop() {
    sed -n "s/^trace: crop '$2': rows \([0-9]*\)-\([0-9]*\) cols \([0-9]*\)-\([0-9]*\)$/\1 \2 \3 \4/p" "$1" |
        awk '{ print $1, $2, $3, $4 + 1 }'
}

# ---------------------------------------------------------------------------
current_scenario="crop-cells"
if scenario_wanted "$current_scenario"; then
    echo "=== $current_scenario: criterion 1, a crop's cells equal ltl's output rows ==="
    out="$TMP_DIR/cells"
    run_tool "$out" --name c --width 200 --pad 0 --out-dir "$TMP_DIR" --trace \
        --crop 'sections=timeline start=+3 end=-1 cols=100,-25 label=a' \
        --crop 'sections=summary-values,summary-files label=b' \
        --crop 'sections=histogram cols=20,60 label=c' \
        -- $SHAPE "$FIXTURE" || true
    check_warnings "$out"
    capture_ltl "$out" "$TMP_DIR/cells.ltl"
    read -r tl_first tl_last <<< "$(section_rows "$TMP_DIR/cells.ltl" timeline)" || true
    read -r sv_first sv_last <<< "$(section_rows "$TMP_DIR/cells.ltl" summary-values)" || true
    read -r sf_first sf_last <<< "$(section_rows "$TMP_DIR/cells.ltl" summary-files)" || true
    sum_last=$(( sv_last > sf_last ? sv_last : sf_last ))
    assert_command \
        command     "[[ \"\$(traced_crop '$out' 'sections=timeline start=+3 end=-1 cols=100,-25 label=a')\" == '$((tl_first + 3)) $((tl_last - 1)) 100 175' ]]" \
        label       "timeline start=+3 end=-1 cols=100,-25 at width 200: rows $((tl_first + 3))-$((tl_last - 1)), columns 100-174" \
        asserts     'A crop runs from its first section start row plus the start offset to its last row plus the end offset, rows as -V section-layout reports them; cols 100,-25 at width 200 is columns 100 up to 25 before the right edge' \
        produced_by 'resolve_crop() in build/capture-screenshots.pl, reading print_section_layout() in ltl' \
        contract    "$CONTRACT D2, D3"
    assert_command \
        command     "[[ \"\$(traced_crop '$out' 'sections=summary-values,summary-files label=b')\" == '$sv_first $sum_last 0 200' ]]" \
        label       "summary-values,summary-files: rows $sv_first-$sum_last, to the longer of the two side-by-side parts" \
        asserts     'A crop naming side-by-side parts ends at the largest last row among them' \
        produced_by 'resolve_crop() in build/capture-screenshots.pl' \
        contract    "$CONTRACT D2"
    for spec in 'sections=timeline start=+3 end=-1 cols=100,-25 label=a' 'sections=summary-values,summary-files label=b' 'sections=histogram cols=20,60 label=c'; do
        read -r first last cf cs <<< "$(traced_crop "$out" "$spec")" || true
        file="$TMP_DIR/c-$(echo "$spec" | sed -E 's/sections=([^ ]*).*label=([a-z]+)/\1-\2/; s/,/+/g').svg"
        assert_command \
            command     "perl '$CELLS' chars '$file' '$TMP_DIR/cells.ltl' $first $last $cf $cs 0,0,0,0" \
            label       "characters of '$spec' equal ltl's rows $first-$last, columns $cf-$((cs - 1))" \
            asserts     'Every cell of the image carries the character ltl printed in that row and column: the crop is a slice of the output, placed on the cell grid' \
            produced_by 'render_svg() and build_grid() in build/capture-screenshots.pl' \
            contract    "$CONTRACT criterion 1, D14"
    done
fi

# ---------------------------------------------------------------------------
current_scenario="colours"
if scenario_wanted "$current_scenario"; then
    echo "=== $current_scenario: criterion 2, every cell's colours are the ones ltl printed ==="
    for bg in dark light; do
        out="$TMP_DIR/colours-$bg"
        run_tool "$out" --name k$bg --background $bg --pad 0 --out-dir "$TMP_DIR" --trace -- $SHAPE "$FIXTURE" || true
        check_warnings "$out"
        capture_ltl "$out" "$TMP_DIR/colours-$bg.ltl"
        read -r first last cf cs <<< "$(traced_crop "$out" '')" || true
        assert_command \
            command     "perl '$CELLS' colours '$TMP_DIR/k$bg.svg' '$TMP_DIR/colours-$bg.ltl' $first $last $cf $cs 0,0,0,0" \
            label       "$bg: every colour ltl names is drawn in one colour, 256-colour indices at their xterm values" \
            asserts     'Each foreground and background colour ltl printed maps to exactly one colour in the image, through the tool colour table; indices 16 to 255 at the standard xterm values; the default background is the image background' \
            produced_by 'palette_for() and build_grid() in build/capture-screenshots.pl' \
            contract    "$CONTRACT criterion 2, D7"
    done
fi

# ---------------------------------------------------------------------------
current_scenario="ticks"
if scenario_wanted "$current_scenario"; then
    echo "=== $current_scenario: criterion 3, histogram tick marks in ltl's columns ==="
    out="$TMP_DIR/ticks"
    run_tool "$out" --name t --pad 0 --out-dir "$TMP_DIR" --trace --crop 'sections=histogram' -- $SHAPE "$FIXTURE" || true
    check_warnings "$out"
    capture_ltl "$out" "$TMP_DIR/ticks.ltl"
    read -r first last cf cs <<< "$(traced_crop "$out" 'sections=histogram')" || true
    assert_command \
        command     "perl '$CELLS' ticks '$TMP_DIR/t-histogram.svg' '$TMP_DIR/ticks.ltl' $first $last $cf $cs 0,0,0,0" \
        label       'every percentile tick on the histogram axis sits in the column ltl printed it' \
        asserts     'The tick glyphs on the histogram axis row are in the same columns in the image as in ltl output, whose columns tests/validate-histogram-ticks.sh asserts' \
        produced_by 'render_svg() in build/capture-screenshots.pl; the axis row of print_histogram() in ltl' \
        contract    "$CONTRACT criterion 3"
fi

# ---------------------------------------------------------------------------
current_scenario="heatmap-colours"
if scenario_wanted "$current_scenario"; then
    echo "=== $current_scenario: criterion 2, heatmap cells in the gradient -V heatmap-palette reports ==="
    out="$TMP_DIR/heat"
    run_tool "$out" --name h --pad 0 --out-dir "$TMP_DIR" --trace --crop 'sections=timeline' -- $SHAPE "$FIXTURE" || true
    check_warnings "$out"
    capture_ltl "$out" "$TMP_DIR/heat.ltl"
    args=$(sed -n 's/^trace: capture run: ltl //p' "$out")
    # shellcheck disable=SC2086
    ( cd "$REPO_DIR" && "$LTL" -ni -V heatmap-palette $args ) > "$TMP_DIR/heat.palette" 2> "$TMP_DIR/heat.palette.stderr"
    check_warnings "$TMP_DIR/heat.palette"
    active=$(sed -n 's/^gradient_active: //p' "$TMP_DIR/heat.palette")
    gradient=$(sed -n "s/^gradient_$active: //p" "$TMP_DIR/heat.palette")
    read -r first last cf cs <<< "$(traced_crop "$out" 'sections=timeline')" || true
    assert_command \
        command     "[[ -n '$gradient' ]] && perl '$CELLS' heatmap '$TMP_DIR/h-timeline.svg' '$TMP_DIR/heat.ltl' $first $last $cf $cs 0,0,0,0 '$TMP_DIR/heat.ltl.stderr' '$gradient'" \
        label       "heatmap cells use only the $active gradient ($gradient) and every one is in the image" \
        asserts     'Every heatmap cell ltl printed, located by the layout engine column offsets, carries a colour of the gradient -V heatmap-palette reports, and the image carries each of them' \
        produced_by 'print_heatmap_row() in ltl; render_svg() in build/capture-screenshots.pl' \
        contract    "$CONTRACT criterion 2; features/heatmap.md"
fi

# ---------------------------------------------------------------------------
current_scenario="background"
if scenario_wanted "$current_scenario"; then
    echo "=== $current_scenario: criterion 4, the background is forced on ltl and drawn ==="
    # The profiles' backgrounds: Terminal.app Clear Dark and Clear Light,
    # %profiles in build/capture-screenshots.pl.
    for pair in 'dark -dbg #191d27' 'light -lbg #ffffff'; do
        read -r bg flag fill <<< "$pair"
        out="$TMP_DIR/bg-$bg"
        run_tool "$out" --name b$bg --background $bg --out-dir "$TMP_DIR" --trace --crop 'sections=options' -- -ni -bs 1440 -oe -n 1 "$FIXTURE" || true
        check_warnings "$out"
        assert_command \
            command     "grep -q -- ' $flag ' <(grep '^trace: probe run' '$out') && grep -q -- ' $flag ' <(grep '^trace: capture run' '$out') && grep -q '<rect width=\"100%\" height=\"100%\" fill=\"$fill\"/>' '$TMP_DIR/b$bg-options.svg'" \
            label       "$bg: both runs get $flag and the image is drawn on $fill" \
            asserts     'The background a screenshot states is forced on ltl in both runs, never detected, and the image is drawn on the matching background' \
            produced_by 'run_recipe() and render_svg() in build/capture-screenshots.pl' \
            contract    "$CONTRACT criterion 4, D7"
    done
    out="$TMP_DIR/bg-default"
    run_tool "$out" --name bd --out-dir "$TMP_DIR" --trace --crop 'sections=options' -- -ni -bs 1440 -oe -n 1 "$FIXTURE" || true
    check_warnings "$out"
    assert_command \
        command     "grep -q -- ' -dbg ' <(grep '^trace: capture run' '$out')" \
        label       'no background given: dark (-dbg)' \
        asserts     'A screenshot that does not state its background is dark' \
        produced_by 'main() in build/capture-screenshots.pl' \
        contract    "$CONTRACT D7"
fi

# ---------------------------------------------------------------------------
current_scenario="hidden-absent"
if scenario_wanted "$current_scenario"; then
    echo "=== $current_scenario: criterion 5, a hidden or absent section is an error with no image ==="
    for pair in 'hidden messages --hide messages' 'absent threadpools'; do
        read -r state section hide_args <<< "$pair"
        out="$TMP_DIR/state-$state"
        status=0
        # shellcheck disable=SC2086
        run_tool "$out" --name s$state --out-dir "$TMP_DIR" --crop "sections=$section" -- -ni $hide_args -bs 1440 -oe -n 1 "$FIXTURE" || status=$?
        check_warnings "$out"
        assert_command \
            command     "[[ $status -ne 0 ]] && grep -q \"section '$section' is $state\" '$out.stderr' && [[ ! -e '$TMP_DIR/s$state-$section.svg' ]]" \
            label       "a crop naming the $state section $section fails, names it, and writes no image" \
            asserts     'A crop naming a section the report gives as hidden or absent is an error naming the section, not an empty image' \
            produced_by 'resolve_crop() in build/capture-screenshots.pl' \
            contract    "$CONTRACT criterion 5, D2"
    done
fi

# ---------------------------------------------------------------------------
current_scenario="size-precedence"
if scenario_wanted "$current_scenario"; then
    echo "=== $current_scenario: criterion 6, command line over manifest over the default ==="
    manifest="$TMP_DIR/size.yaml"
    printf 'screenshots:\n  - name: m\n    ltl: -ni -bs 1440 -oe -n 1 %s\n    width: 180\n    height: 45\n    crops:\n      - sections: options\n' "$FIXTURE" > "$manifest"
    for case in 'default 211 53 adhoc' 'command-line 150 40 adhoc --width 150 --height 40' 'manifest 180 45 manifest' 'command-line-over-manifest 170 44 manifest --width 170 --height 44'; do
        read -r name w h mode extra <<< "$case"
        out="$TMP_DIR/size-$name"
        if [[ "$mode" == adhoc ]]; then
            # shellcheck disable=SC2086
            run_tool "$out" --name z --out-dir "$TMP_DIR" --trace $extra --crop 'sections=options' -- -ni -bs 1440 -oe -n 1 "$FIXTURE" || true
        else
            # shellcheck disable=SC2086
            run_tool "$out" --manifest "$manifest" --out-dir "$TMP_DIR" --trace $extra || true
        fi
        check_warnings "$out"
        assert_command \
            command     "grep '^trace: capture run' '$out' | grep -q -- '--terminal-width $w --terminal-height $h '" \
            label       "$name: ltl gets --terminal-width $w --terminal-height $h" \
            asserts     'The terminal size reaching ltl is the tool command line value, else the manifest entry, else 211 x 53' \
            produced_by 'main() and run_manifest() in build/capture-screenshots.pl' \
            contract    "$CONTRACT criterion 6, D11"
    done
fi

# ---------------------------------------------------------------------------
current_scenario="runs-and-crops"
if scenario_wanted "$current_scenario"; then
    echo "=== $current_scenario: criterion 7, several images from one execution, ltl run twice ==="
    out="$TMP_DIR/runs"
    run_tool "$out" --name r --out-dir "$TMP_DIR" --trace \
        --crop '' --crop 'sections=timeline' --crop 'sections=timeline cols=150,0 label=heatmap' --crop 'sections=histogram' \
        -- $SHAPE "$FIXTURE" || true
    check_warnings "$out"
    assert_command \
        command     "grep -qx 'trace: ltl runs: 2' '$out' && for f in r r-timeline r-timeline-heatmap r-histogram; do [[ -s '$TMP_DIR/'\$f.svg ]] || exit 1; done" \
        label       'four crops: ltl run exactly twice, four images named in layers' \
        asserts     'One execution yields one image per crop, all cut from one capture run after one probe run, named BASE[-sections][-label]' \
        produced_by 'run_recipe() in build/capture-screenshots.pl' \
        contract    "$CONTRACT criterion 7, D19 naming"
fi

# ---------------------------------------------------------------------------
current_scenario="manifest"
if scenario_wanted "$current_scenario"; then
    echo "=== $current_scenario: criterion 8, a batch run regenerates every entry ==="
    manifest="$TMP_DIR/batch.yaml"
    printf 'screenshots:\n  - name: one\n    ltl: %s %s\n    crops:\n      - sections: histogram\n  - name: two\n    ltl: -ni -h "POST /Thingworx" -bs 1440 -oe -n 1 %s\n    background: light\n    crops:\n      - sections: [timeline, options]\n' "$SHAPE" "$FIXTURE" "$FIXTURE" > "$manifest"
    out="$TMP_DIR/batch"
    mkdir -p "$TMP_DIR/batch-out"
    status=0
    run_tool "$out" --manifest "$manifest" --out-dir "$TMP_DIR/batch-out" || status=$?
    check_warnings "$out"
    assert_command \
        command     "[[ $status -eq 0 ]] && [[ -s '$TMP_DIR/batch-out/one-histogram.svg' && -s '$TMP_DIR/batch-out/two-timeline+options.svg' ]] && grep -qx '2 of 2 entries written' '$out'" \
        label       'two entries, both regenerated; a quoted ltl argument and a YAML list of sections read as written' \
        asserts     'A manifest run regenerates every entry; the ltl string is split as a shell splits it' \
        produced_by 'run_manifest() in build/capture-screenshots.pl' \
        contract    "$CONTRACT criterion 8, D19"
    out="$TMP_DIR/batch-only"
    mkdir -p "$TMP_DIR/batch-only-out"
    run_tool "$out" --manifest "$manifest" --only two --out-dir "$TMP_DIR/batch-only-out" || true
    check_warnings "$out"
    assert_command \
        command     "[[ ! -e '$TMP_DIR/batch-only-out/one-histogram.svg' && -s '$TMP_DIR/batch-only-out/two-timeline+options.svg' ]]" \
        label       '--only two regenerates that entry alone' \
        asserts     'A manifest run with --only NAME regenerates that entry and no other' \
        produced_by 'run_manifest() in build/capture-screenshots.pl' \
        contract    "$CONTRACT D19"
fi

# ---------------------------------------------------------------------------
current_scenario="edges"
if scenario_wanted "$current_scenario"; then
    echo "=== $current_scenario: criterion 11, full blocks within their columns as displayed ==="
    if ! command -v qlmanage >/dev/null 2>&1 || ! command -v sips >/dev/null 2>&1; then
        echo "  SKIP  $current_scenario :: Quick Look and sips are macOS tools; criterion 11 is checked on macOS"
    else
        out="$TMP_DIR/edges"
        # The timeline's bars and heatmap, and the histogram, whose grid lines
        # meet its bars (D20).
        run_tool "$out" --name e --pad 0 --out-dir "$TMP_DIR" --trace --crop 'sections=timeline,histogram' -- $SHAPE "$FIXTURE" || true
        check_warnings "$out"
        capture_ltl "$out" "$TMP_DIR/edges.ltl"
        read -r first last cf cs <<< "$(traced_crop "$out" 'sections=timeline,histogram')" || true
        assert_command \
            command     "perl '$CELLS' edges '$TMP_DIR/e-timeline+histogram.svg' '$TMP_DIR/edges.ltl' $first $last $cf $cs 0,0,0,0" \
            label       'every full block of the timeline and the histogram, as Quick Look displays it, fills its own columns' \
            asserts     'Drawn as font text, a full block sits within its cell columns as displayed: sampled 1.5 device pixels inside its left and right edges it is its own colour' \
            produced_by 'render_svg() in build/capture-screenshots.pl (textLength per run, full blocks drawn last)' \
            contract    "$CONTRACT criterion 11, D14, D20"
    fi
fi

# ---------------------------------------------------------------------------
current_scenario="run-folder"
if scenario_wanted "$current_scenario"; then
    echo "=== $current_scenario: criterion 13, --dir runs ltl in the folder it names ==="
    # -bs 1440 -oe -n 1: the assertion reads the summary's file list only.
    folder="$TMP_DIR/folder"
    mkdir -p "$folder/logs"
    cp "$REPO_DIR/$FIXTURE" "$folder/logs/access.txt"
    real=$(cd "$folder" && pwd -P)
    out="$TMP_DIR/run-folder"
    status=0
    run_tool "$out" --name d --dir "$folder" --out-dir "$TMP_DIR" --trace --crop 'sections=summary-files' -- -bs 1440 -oe -n 1 logs/access.txt || status=$?
    check_warnings "$out"
    assert_command \
        command     "[[ $status -eq 0 ]] && grep -qxF 'trace: folder: $real' '$out' && grep -qF '>logs/access.txt</text>' '$TMP_DIR/d-summary-files.svg'" \
        label       'ltl ran in the named folder, read logs/access.txt there, and the file list shows logs/access.txt as written' \
        asserts     'An ad hoc run with --dir runs ltl in that folder: an input named relative to it is read, and the summary file list shows the path as written, not as a path from the repository root' \
        produced_by 'run_ltl() and main() in build/capture-screenshots.pl' \
        contract    "$CONTRACT criterion 13, D21"
fi

# ---------------------------------------------------------------------------
current_scenario="manifest-folder"
if scenario_wanted "$current_scenario"; then
    echo "=== $current_scenario: criterion 14, a manifest's dir is found from the manifest's folder ==="
    # The manifest lives outside the repository; run_tool runs the tool from
    # the repository root, so a dir resolved against the current directory
    # would not be found.
    mdir="$TMP_DIR/elsewhere"
    mkdir -p "$mdir/env/logs" "$TMP_DIR/mf-out"
    cp "$REPO_DIR/$FIXTURE" "$mdir/env/logs/access.txt"
    real=$(cd "$mdir/env" && pwd -P)
    printf 'screenshots:\n  - name: mf\n    dir: env\n    ltl: -bs 1440 -oe -n 1 logs/access.txt\n    crops:\n      - sections: summary-files\n' > "$mdir/shots.yaml"
    out="$TMP_DIR/manifest-folder"
    status=0
    run_tool "$out" --manifest "$mdir/shots.yaml" --out-dir "$TMP_DIR/mf-out" --trace || status=$?
    check_warnings "$out"
    assert_command \
        command     "[[ $status -eq 0 ]] && grep -qxF 'trace: folder: $real' '$out' && grep -qF '>logs/access.txt</text>' '$TMP_DIR/mf-out/mf-summary-files.svg'" \
        label       'dir: env runs ltl in env beside the manifest, from the repository root' \
        asserts     'A manifest entry dir is resolved against the manifest file folder, whatever folder the tool runs from' \
        produced_by 'run_manifest() and resolve_dir() in build/capture-screenshots.pl' \
        contract    "$CONTRACT criterion 14, D21"
    printf 'screenshots:\n  - name: mm\n    dir: missing\n    ltl: -bs 1440 -oe -n 1 logs/access.txt\n' > "$mdir/missing.yaml"
    mkdir -p "$TMP_DIR/mm-out"
    for case in manifest adhoc; do
        out="$TMP_DIR/missing-$case"
        status=0
        if [[ "$case" == manifest ]]; then
            run_tool "$out" --manifest "$mdir/missing.yaml" --out-dir "$TMP_DIR/mm-out" --trace || status=$?
        else
            run_tool "$out" --name mm --dir "$mdir/missing" --out-dir "$TMP_DIR/mm-out" --trace -- -bs 1440 -oe -n 1 logs/access.txt || status=$?
        fi
        check_warnings "$out"
        assert_command \
            command     "[[ $status -ne 0 ]] && grep -q \"dir 'missing\\|dir '$mdir/missing\" '$out.stderr' && grep -q 'is not a folder' '$out.stderr' && ! grep -q '^trace: probe run' '$out' && [[ -z \"\$(ls '$TMP_DIR/mm-out')\" ]]" \
            label       "$case: a dir that is not a folder is an error naming it, nothing run, no image" \
            asserts     'A run folder that does not exist is refused before ltl runs, naming the folder' \
            produced_by 'resolve_dir() in build/capture-screenshots.pl' \
            contract    "$CONTRACT criterion 14, D21"
    done
fi

# ---------------------------------------------------------------------------
current_scenario="folder-output-files"
if scenario_wanted "$current_scenario"; then
    echo "=== $current_scenario: criterion 15, in a named folder only the run's own -o files are removed ==="
    # -bs 1440 -oe -n 1 -o: the assertion reads the files -o writes, nothing rendered.
    folder="$TMP_DIR/exports"
    mkdir -p "$folder"
    cp "$REPO_DIR/$FIXTURE" "$folder/access.txt"
    keep="2020-01-01_000000-LTL-STATS-kept.csv"
    printf 'an export kept beside the logs\n' > "$folder/$keep"
    cp "$folder/$keep" "$TMP_DIR/kept.orig"
    real=$(cd "$folder" && pwd -P)
    out="$TMP_DIR/folder-output-files"
    run_tool "$out" --name o --dir "$folder" --out-dir "$TMP_DIR" --trace --crop 'sections=options' -- -bs 1440 -oe -n 1 -o access.txt || true
    check_warnings "$out"
    assert_command \
        command     "grep -qE '^trace: removed $real/[^/]*-LTL-STATS-[^/]*\.csv$' '$out' && grep -qE '^trace: removed $real/[^/]*-LTL-AGGREGATE\.yaml$' '$out' && ! grep -qF '$keep' '$out'" \
        label       'the run wrote its -o files in the folder and the tool removed them, not the earlier export' \
        asserts     'The files -o wrote in a named folder are removed after each run, and only those' \
        produced_by 'remove_output_files() in build/capture-screenshots.pl' \
        contract    "$CONTRACT criterion 15, D22"
    assert_command \
        command     "[[ \"\$(output_files_in '$folder')\" == '$keep' ]] && cmp -s '$folder/$keep' '$TMP_DIR/kept.orig'" \
        label       'afterwards the folder holds the earlier export alone, unchanged' \
        asserts     'A file matching the output names that was in the named folder before the run is still there, unchanged, and no file of the run is left' \
        produced_by 'output_files() and remove_output_files() in build/capture-screenshots.pl' \
        contract    "$CONTRACT criterion 15, D22"
fi

# ---------------------------------------------------------------------------
current_scenario="folder-index"
if scenario_wanted "$current_scenario"; then
    echo "=== $current_scenario: criterion 19, in a named folder an index the recipe created is removed ==="
    # The index file is the subject, so these runs do not pass -ni.
    # -bs 1440 -oe -n 1: nothing rendered is read.
    for case in fresh existing; do
        folder="$TMP_DIR/index-$case"
        mkdir -p "$folder"
        cp "$REPO_DIR/$FIXTURE" "$folder/access.txt"
        real=$(cd "$folder" && pwd -P)
        if [[ "$case" == existing ]]; then
            ( cd "$folder" && "$LTL" --disable-progress -bs 1440 -oe -n 1 access.txt ) > "$TMP_DIR/index-seed" 2> "$TMP_DIR/index-seed.stderr"
            check_warnings "$TMP_DIR/index-seed"
        fi
        had_index=$([[ -s "$folder/ltl-index.csv" ]] && echo yes || echo no)
        out="$TMP_DIR/folder-index-$case"
        status=0
        run_tool "$out" --name i$case --dir "$folder" --out-dir "$TMP_DIR" --trace --crop 'sections=options' -- -bs 1440 -oe -n 1 access.txt || status=$?
        check_warnings "$out"
        if [[ "$case" == fresh ]]; then
            assert_command \
                command     "[[ $status -eq 0 && $had_index == no ]] && grep -qxF 'trace: removed $real/ltl-index.csv' '$out' && [[ ! -e '$folder/ltl-index.csv' ]]" \
                label       'a folder without an index: ltl wrote one, the tool removed it' \
                asserts     'In a named folder, an ltl-index.csv the recipe runs created is removed afterwards' \
                produced_by 'run_recipe() in build/capture-screenshots.pl' \
                contract    "$CONTRACT criterion 19, D26"
        else
            assert_command \
                command     "[[ $status -eq 0 && $had_index == yes ]] && ! grep -qF 'ltl-index.csv' '$out' && [[ -s '$folder/ltl-index.csv' ]]" \
                label       'a folder with an index: it is still there afterwards' \
                asserts     'In a named folder, an ltl-index.csv that was there before the recipe is left in place' \
                produced_by 'run_recipe() in build/capture-screenshots.pl' \
                contract    "$CONTRACT criterion 19, D26"
        fi
    done
fi

# ---------------------------------------------------------------------------
current_scenario="png-size"
if scenario_wanted "$current_scenario"; then
    echo "=== $current_scenario: criterion 16, a PNG of the same size beside every SVG ==="
    # -bs 1440 -oe -n 1 -hg duration: the histogram, cut 90 columns wide.
    mkdir -p "$TMP_DIR/png-size" "$TMP_DIR/png-size-manifest"
    out="$TMP_DIR/png-size.run"
    status=0
    run_tool "$out" --name p --out-dir "$TMP_DIR/png-size" --crop 'sections=histogram cols=12,90' --crop '' -- -ni -bs 1440 -oe -n 1 -hg duration "$FIXTURE" || status=$?
    check_warnings "$out"
    assert_command \
        command     "[[ $status -eq 0 ]] && [[ \"\$(svg_size '$TMP_DIR/png-size/p-histogram.svg')\" == 677\ * ]] && pngs_match_svgs '$TMP_DIR/png-size'" \
        label       'ad hoc: a crop 90 cells wide with the default padding is 677 units wide, and each SVG has its PNG of the same size' \
        asserts     'Every SVG is a whole number of units wide, a fractional width rounded up into the right margin (94 cells x 7.2 = 676.8 becomes 677), and has a PNG of the same name whose pixel size is the SVG size' \
        produced_by 'render_svg(), draw_pngs() in build/capture-screenshots.pl; build/capture-png.swift' \
        contract    "$CONTRACT criterion 16, D24, D25"
    manifest="$TMP_DIR/png-size.yaml"
    printf 'screenshots:\n  - name: q\n    ltl: -ni -bs 1440 -oe -n 1 -hg duration %s\n    pad: 1,3\n    crops:\n      - sections: histogram\n      - sections: summary-values\n        cols: 0,47\n' "$FIXTURE" > "$manifest"
    out="$TMP_DIR/png-size-manifest.run"
    status=0
    run_tool "$out" --manifest "$manifest" --out-dir "$TMP_DIR/png-size-manifest" || status=$?
    check_warnings "$out"
    assert_command \
        command     "[[ $status -eq 0 ]] && [[ \$(ls '$TMP_DIR/png-size-manifest'/*.svg | wc -l) -eq 2 ]] && pngs_match_svgs '$TMP_DIR/png-size-manifest'" \
        label       'manifest: each of its two SVGs has its PNG of the same size' \
        asserts     'A manifest run writes a PNG of the same name and size beside every SVG' \
        produced_by 'run_recipe() and draw_pngs() in build/capture-screenshots.pl' \
        contract    "$CONTRACT criterion 16, D24"
fi

# ---------------------------------------------------------------------------
current_scenario="png-pixels"
if scenario_wanted "$current_scenario"; then
    echo "=== $current_scenario: criterion 17, the PNG is the SVG drawn 1:1 ==="
    if ! command -v sips >/dev/null 2>&1; then
        echo "  SKIP  $current_scenario :: the PNG is read through sips, a macOS tool; criterion 17 is checked on macOS"
    else
        # The timeline's bars and the histogram's: full blocks across the
        # image; the default padding, so the right margin carries the
        # widening of a fractional width.
        for bg in dark light; do
            out="$TMP_DIR/png-pixels-$bg"
            run_tool "$out" --name x$bg --background $bg --out-dir "$TMP_DIR" --trace --crop 'sections=timeline,histogram cols=0,99' -- $SHAPE "$FIXTURE" || true
            check_warnings "$out"
            read -r first last cf cs <<< "$(traced_crop "$out" 'sections=timeline,histogram cols=0,99')" || true
            assert_command \
                command     "perl '$CELLS' png '$TMP_DIR/x$bg-timeline+histogram.svg' /dev/null $first $last $cf $cs 1,2,1,2 '$TMP_DIR/x$bg-timeline+histogram.png'" \
                label       "$bg: corners are the background and every full block is its colour at its cell centre" \
                asserts     'The PNG is the SVG drawn one pixel per unit: its size is the SVG size, its corners the image background, and each full block, sampled at the centre of its cell, is its own colour, so nothing is shifted or scaled' \
                produced_by 'build/capture-png.swift, run by draw_pngs() in build/capture-screenshots.pl' \
                contract    "$CONTRACT criterion 17, D24, D25"
        done
    fi
fi

# ---------------------------------------------------------------------------
current_scenario="png-needs-swiftc"
if scenario_wanted "$current_scenario"; then
    echo "=== $current_scenario: criterion 18, without swiftc the tool stops with no image ==="
    # A PATH with nothing on it: the tool is run by this Perl, and runs ltl
    # with the same, so only the lookup of swiftc sees the empty PATH.
    nobin="$TMP_DIR/nobin"
    mkdir -p "$nobin" "$TMP_DIR/nobin-out"
    perl_bin=$(command -v perl)
    out="$TMP_DIR/png-needs-swiftc"
    status=0
    ( cd "$REPO_DIR" && PATH="$nobin" "$perl_bin" "$TOOL" --name n --out-dir "$TMP_DIR/nobin-out" --trace -- -ni -bs 1440 -oe -n 1 "$FIXTURE" ) > "$out" 2> "$out.stderr" || status=$?
    check_warnings "$out"
    assert_command \
        command     "[[ $status -ne 0 ]] && grep -q 'swiftc is not found' '$out.stderr' && ! grep -q '^trace: probe run' '$out' && [[ -z \"\$(ls '$TMP_DIR/nobin-out')\" ]]" \
        label       'no swiftc on the PATH: an error naming it, ltl not run, no image' \
        asserts     'The PNG needs the Swift compiler; without it the tool stops with an error naming it before ltl runs, and writes no image' \
        produced_by 'prepare_png_helper() in build/capture-screenshots.pl' \
        contract    "$CONTRACT criterion 18, D24"
fi

echo ""
echo "Results: $pass passed, $fail failed"
if [[ "$pass" -eq 0 && "$fail" -eq 0 ]]; then
    echo "No assertion ran: an unasserted run is not a pass."
    exit 1
fi
if [[ "$fail" -gt 0 ]]; then
    echo "Failures:"
    for f in "${failures[@]}"; do
        echo "  - $f"
    done
    exit 1
fi
echo "ALL SCREENSHOT-CAPTURE TESTS PASSED"

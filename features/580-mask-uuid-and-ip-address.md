# Feature: Mask UUIDs and IP addresses in the message, keeping their shape

## Status

- **Issue:** #580. Blocking #567 (discard named keys and values from the message), which uses the UUID and IP address patterns this issue defines.
- **Phase:** specification; decisions D1 to D8 locked 2026-09-16; acceptance criteria drafted for agreement.
- **Record:** this file. The issue body is its snapshot.
- **Governing records:** `features/567-discard-named-values-from-message.md` (D4 masking is its own option, D10 a comma-separated list, D14 the patterns are one resolution surface for `--mask` and `--discard`, D17 a value both masked and discarded, D18 `-V runtime-config` reports the effective configuration, D19 the gap a removed UUID or IP address leaves); `features/566-preserve-named-values-in-message.md` (the sister option `--expose`: D3 one option with shorthands, D7 a key is appended only when the formed message no longer yields its value, D9 a repeated name kept once); `features/fuzzy-message-consolidation.md` § DD-11: $mask_uuid Processing Order.

## Motivating consumer

An analyst whose messages stay apart only because each carries a different UUID or IP address, and who still wants to see that an identifier sat there and where. Masking the identifier with a placeholder of its shape makes those messages one, without losing the fact of the identifier.

## Requirements (architect's terms, issue body)

- **Masking keeps the shape.** Masking replaces the identifier with a placeholder of the same shape, so that messages differing only by that identifier group together while the message still shows where it sat. Discarding (#567) is the other treatment and leaves nothing behind.
- **One option names what to mask.** `-m` / `--mask`:
  - `--mask uuid` masks UUIDs, leaving the UUID's shape as `-uuid` does today. It is the direct replacement for `-uuid`.
  - `--mask ipv4`, `--mask ipv6` and `--mask ip` mask IP addresses in the same way; `ip` means either version.
- **`-uuid` is deprecated, not removed.** `-uuid` keeps working, and its use shows the user an informational message stating that the option is deprecated and has been replaced by the broader `--mask` option.
- **Done when.** An analyst can name UUIDs or IP addresses (either version or both) to mask, and messages differing only by those identifiers become one message that still shows the identifier's shape. `-uuid` masks as before and tells the user it is deprecated in favour of `--mask`.

## Decisions carried from #567 (locked there by the architect, 2026-09-16)

- **567 D4 — Masking is its own option.** `-m` / `--mask uuid` replaces `-uuid`, whose use prints an informational notice that it is deprecated in favour of `--mask`; `--mask ip|ipv4|ipv6` masks IP addresses the same way.
- **567 D10 — A comma-separated list names several parts in one option.** Applied to `--mask` by D5 below: `-m uuid,ip` is `-m uuid -m ip`.
- **567 D14 — One resolution surface.** `--discard uuid`, `ip`, `ipv4` and `ipv6` use the patterns `--mask` defines; this issue owns them.
- **567 D17 — Masked and discarded.** A UUID or IP address given to both `--mask` (or `-uuid`) and `--discard` is discarded, with a notice. Delivered by #567, since `--discard` does not exist before it.
- **567 D19 — Brackets around an IP address are planned for.** An IP address may sit in brackets with no separator beside it; the pattern finds it there.

## Decisions

- **D1 — LOCKED 2026-09-16 (architect) — A UUID is masked only when it is a hexadecimal UUID, and `-uuid` is corrected with it.** The `-uuid` pattern matches any 8-4-4-4-12 grouping of non-space characters (§ The `-uuid` pattern is not limited to hexadecimal UUIDs), and on real access-log lines it merges requests for two different gateways into one message. `--mask uuid` and `-uuid` both match only hexadecimal UUIDs.
- **D2 — LOCKED 2026-09-16 (architect) — An IP address is masked only when it is a valid address; a valid address that is really something else is masked all the same.** Only a valid IPv4 or IPv6 address is masked, so that patterns of the same outline that are not addresses are left alone. A dotted version number that is also a valid IPv4 address (`13.1.2.0`) is masked: nothing in the text tells the two apart.
- **D3 — LOCKED 2026-09-16 (architect) — An IP address is replaced by one fixed-width placeholder per version.** Every IPv4 address becomes `###.###.###.###` and every IPv6 address, whether written in full or compressed, becomes `####:####:####:####:####:####:####:####`, so that messages differing only by an address group together whatever the address's length.
- **D4 — LOCKED 2026-09-16 (architect) — Masking runs after `--expose` and `--discard`.** It is an order of operations: the message is formed, exposed values are added and discarded parts removed, and then masking applies to the result. Consequences under 566 D7:

  | Options, on `GET /store/orders?id=<uuid>&x=1` | Message |
  |---|---|
  | `-m uuid -x id` | `GET /store/orders id=########-####-####-####-############` |
  | `-m uuid -xqs -x id` | `GET /store/orders?id=########-####-####-####-############&x=1`: the formed message still yields the raw `id`, so nothing is appended, and the value is then masked in place |
  | `-m uuid -d uuid` (#567) | the UUID is discarded before masking runs; the 567 D17 notice prints |

- **D5 — LOCKED 2026-09-16 (architect) — The option surface follows #567.** A comma-separated list names several identifiers (567 D10); `-V runtime-config` reports the effective configuration as 567 D18 does: a new `mask` key lists the resolved names in command-line order, a comma-separated list split and a repeated name kept once at its first position, and `mask-uuid` reports `1` when UUIDs are masked by either spelling.
- **D6 — LOCKED 2026-09-16 (architect) — Masking is verified on the corpus lines that carry the identifiers.** Lines are isolated with `-i` and masked; a synthetic fixture is used only where the corpus has no such line, as for IPv6.
- **D7 — LOCKED 2026-09-16 (architect) — A bare `::` is left as written.** Although `::` alone is a valid IPv6 address, it carries no address information to mask: its lack of detail already serves the purpose masking has. Messages use it as a separator (§ A bare `::` is a separator in real messages).
- **D8 — LOCKED 2026-09-16 (architect) — `--help` carries no `-uuid` row.** The row is dropped; `-uuid` is named as deprecated when it is used, by the notice it prints.

## Pattern definitions (derived from D1 to D3 and D7)

- **UUID.** Eight, four, four, four and twelve hexadecimal digits in either case, joined by `-`, with no hexadecimal digit immediately before or after.
- **IPv4.** Four decimal octets from 0 to 255 without leading zeros (the `dec-octet` of RFC 3986), joined by `.`; no word character immediately before or after, not preceded by a digit and `.`, and not followed by `.` and a digit. `256.1.1.1`, `01.2.3.4` and `1.2.3.4.5` are left as written; a port (`10.0.0.1:8080`), a leading `/` and a thread name's hyphens (`ajp-nio-127.0.0.1-8011`) do not stop a match.
- **IPv6.** The `IPv6address` grammar of RFC 3986: full, `::`-compressed, and ending in an IPv4 address (`::ffff:192.0.2.1`), in either case; no word character, `:` or `.` immediately before, and no word character or `:` immediately after. A zone (`fe80::1%eth0`) and brackets with a port (`[::1]:9273`) stay as written around the placeholder. `Class::method` does not match, and a bare `::` is not masked (D7); `::1` is.
- **`ip`.** IPv6 is masked before IPv4, so an IPv4-ending IPv6 address becomes one IPv6 placeholder. `-m ipv4` alone masks the IPv4 tail of such an address.
- **An unknown name.** `-m foo` stops the run with an error naming the accepted values, as other options with a fixed set of values do.

## Findings (2026-09-16; release/0.18.2 at ab38511, build 0.18.2-580)

Every `ltl` run `-ni -bs 1440 -oe -n 100000 -o -V`, no ` at <file> line <N>` on stderr. Where a run with masking is described before masking exists, the masked messages were computed from the messages CSV of the run without it, with the patterns above; the method reproduces the base build's `-uuid` result exactly (1,333 messages both ways on the access-log lines below).

### Where `-uuid` acts today (code audit)

| Surface | What it does |
|---|---|
| `read_and_process_logs()`, `$message =~ s/\S{8}-\S{4}-\S{4}-\S{4}-\S{12}+/########-####-####-####-############/g if defined $mask_uuid && $mask_uuid;` | Replaces every match in the message text, inside the `$capture_messages` block, before the exposed values are appended (D4 moves masking after them) and before the key's level, thread and object segments are built. The raw line that `-i`, `-e`, `-h` and `-udm` read is untouched, and so are the parsed thread, session, user and object fields |
| Consolidation (`-g`) | Reads the masked key. It carries no UUID normalisation of its own: `tests/validate-message-grouping.sh` asserts no `<UUID>` placeholder is ever produced, and its `uuid-pair-85-masked` scenario asserts that `-uuid` makes two keys differing only in a UUID one row |
| `print_help()` | A `-uuid, --mask-uuid` row; the `-g` row advises masking with `-uuid` where a log carries many UUIDs |
| `docs/usage.md` | The same two rows |
| `-V runtime-config` | `mask-uuid` key |
| The long-option list beside `GetOptions` | `'mask-uuid|uuid'` |

`-m` and `--mask` collide with no existing option (the parser runs with `no_auto_abbrev`). The only deprecation notice the tool prints today is `-os`: `print STDERR "Warning: -os/--omit-stats is deprecated: …"` on every run, with its help row kept and reading `Deprecated: use …`.

### The `-uuid` pattern is not limited to hexadecimal UUIDs

`\S{8}-\S{4}-\S{4}-\S{4}-\S{12}` matches any run of non-space characters in that grouping.

- *Reference log* (ThingWorx application log of about 288,000 lines, error messages differing by a UUID): 286,445 matches, every one a hexadecimal UUID. D1 changes nothing there.
- *Across the tracked corpus* (ThingWorx, MethodServer, WGM, Integration Runtime, Codebeamber, user-defined-metric and access logs): 80 matches are not UUIDs. 76 fall inside hyphenated upper-case gateway names in file-repository URL paths of the thirty-day Tomcat access logs, the leading `/` counted into the first group; 4 fall inside a run of dashes in a background method server log.
- *It merges different requests.* One day of those access logs, `-i` on the gateway path segment: 1,497 messages without masking, 1,333 with `-uuid`, 1,334 with hexadecimal UUIDs only. The one difference is two requests whose gateway names differ only in a `TEST` and a `PROD` part: `-uuid` rewrites the first 36 characters of each name, the leading `/` included, to the UUID placeholder, which removes that part from both, and counts them as one message of 2.

### IP addresses inside the message in the corpus

- *Client addresses in a method server log.* A Windchill method server log of 66,216 lines, `-i ServletRequestMonitor`: 1,830 lines, 589 messages; 584 lines carry a client address inside the message text, 8 distinct IPv4 addresses. Each of those messages also carries a timestamp and a request identifier, so masking the addresses changes the number of messages by none. The thread segment `[ajp-nio-127.0.0.1-80]` is built from the thread field, which masking does not read.
- *Addresses and version numbers in a WGM client log.* The smallest complete WGM capture (31,756 lines, 11,750 messages): 392 valid IPv4 matches, 373 of them one client address inside session names, the rest product version numbers (`12.1.2.0`, `10.1.0.0`, `5.0.2.0`). `-i 'Version :'`: 4 messages carrying 15 version numbers that are valid IPv4 addresses, and dotted runs of five parts (`13.1.20.00.348`) that are not.
- *No dotted quad in these logs fails the validity test.* Every four-part match of up to three digits per part is a valid address here; validity matters for the synthetic cases (`256.…`, leading zeros, five parts).
- *IPv6 is absent.* One IPv6 address in the whole corpus, `[::1]:9273` inside a probe URL in a Tomcat access log. No hexadecimal words joined by `::` (`Class::method`) match anywhere.
- *A bare `::` is a separator in real messages, and a valid IPv6 address.* The method server log carries ` :: ` between a method name and its text in 25,154 lines across 9 messages (`UwgmObjectFactory.createPartIteration :: Unsupported PartType: …`, 17,212 of them in one message); the WGM log carries it 234 times. `::` alone is the valid unspecified IPv6 address, which D2 alone would mask; D7 leaves it as written.

## Acceptance criteria

Draft for agreement. Every run of `ltl` in a harness is shaped to its assertion (`-ni -bs 1440 -oe`, `-o` in a scratch directory where the messages CSV is read, `-i` isolating the lines that carry the identifier on a corpus log) and checked for ` at <file> line <N>` on stderr. Each assertion is proven to fail against the base build. `tests/validate-message-mask.sh` is new. Its corpus inputs are chosen from `docs/test-logs.md`; its synthetic fixture `tests/fixtures/message-mask-values.txt` is new and carries only what the corpus lacks: IPv6 addresses (documentation range `2001:db8::/32`, full, compressed, IPv4-ending, bracketed with a port, with a zone), invalid IPv4 outlines, and lines differing only by one identifier. #567 extends the same fixture.

| # | Condition | Observable outcome | Asserted by |
|---|---|---|---|
| 1 | `-m uuid` on the reference ThingWorx log of UUID-varying errors (D1) | Every key that carried a UUID shows `########-####-####-####-############` where it sat; the message count is the one measured with `-uuid` on the base build | `tests/validate-message-mask.sh`, messages CSV |
| 2 | `-m uuid` and `-uuid` on the thirty-day access-log lines requesting gateway file repositories, `-i` on the gateway path segment (D1) | 1,334 messages; every gateway name is as written; no placeholder is preceded by anything but `/` | same |
| 3 | `-uuid` in place of `-m uuid` on the runs of criteria 1 and 2 | Identical messages CSV; one notice on stderr stating that `-uuid` is deprecated in favour of `--mask`, also with `--disable-progress` | same |
| 4 | `-m ipv4` on the method server log, `-i ServletRequestMonitor` (D2, D3) | No valid IPv4 address remains in the message text of any key; each client address reads `###.###.###.###`; the thread segment is unchanged; occurrence totals unchanged | same |
| 5 | `-m ipv4` on the WGM client log, `-i 'Version :'` (D2) | The four-part version numbers read `###.###.###.###`; the five-part version strings are as written | same |
| 6 | `-m ipv4` on synthetic lines differing only by IPv4 addresses of different lengths, with a port, a leading `/` and in brackets (D3, 567 D19) | One message; `256.1.1.1`, `01.2.3.4` and `1.2.3.4.5` are as written | same, synthetic fixture |
| 7 | `-m ipv6` on synthetic lines differing only by IPv6 addresses, full and compressed (D2, D3, D7) | One message; `[####:####:####:####:####:####:####:####]:9273`, the zone kept after the placeholder; `Class::method` and a bare ` :: ` separator as written, `::1` masked; IPv4 addresses as written | same, synthetic fixture |
| 8 | `-m ip`, `-m ipv4,ipv6`, `-m ipv4 -m ipv6` (D5) | Identical messages CSVs; an IPv4-ending IPv6 address is one IPv6 placeholder | same, synthetic fixture |
| 9 | `-m uuid -x id` and `-m uuid -xqs -x id` on access-log lines whose query string carries `id=<uuid>` (D4) | Keys read exactly as D4's table; no raw UUID in any key | same |
| 10 | Any mask, with `-i`, `-e` and `-h` naming a raw address or UUID | The lines selected and highlighted, and `-V` classification and occurrence counts, are those of the run without the mask | same |
| 11 | `-m uuid,ipv4 -m uuid`; `-uuid`; `-m ip` (D5) | `-V runtime-config` reports `mask: uuid,ipv4` and `mask-uuid: 1`; `mask: uuid`, `mask-uuid: 1`; `mask: ip`, `mask-uuid: 0` | `tests/validate-runtime-config.sh` |
| 12 | `-m foo` | Non-zero exit; the error names `uuid`, `ip`, `ipv4` and `ipv6` | `tests/validate-message-mask.sh` |
| 13 | `--help` | One `-m, --mask <name>` entry; no `-uuid` row (D8); the `-g` entry names `--mask uuid`; `docs/usage.md` agrees | `tests/validate-help-content.sh` |
| 14 | `uuid-pair-85-masked`, which runs `-uuid` | Still one row | `tests/validate-message-grouping.sh`, unchanged |
| 15 | No mask option | Output unchanged: the regression goldens, the statistics oracle and every registry self-validation pass without re-blessing | the full harness suite at the completion gate |

## Performance evidence

Masking adds substitutions per retained message, and only when `--mask` or `-uuid` is given; it is a small change to an existing path, so under `docs/process/workflow.md` § 2 the before/after benchmark at the completion gate is its evidence, with the `before` captured on the base commit before the first line of code.

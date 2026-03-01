# Feature: Configurable Rate Unit (#122)

## Overview

Add a `-ru` / `--rate-unit` option to control the time unit used for message rate and error rate normalization. Currently rates are always per-minute (`/m`). This option adds per-second (`/s`), per-hour (`/h`), and per-day (`/d`).

## CLI Option

```
-ru <unit>, --rate-unit <unit>
```

Valid values: `s` (second), `m` (minute, default), `h` (hour), `d` (day)

## Current Implementation

### Calculation (line ~5253)
```perl
$log_occurrences{$bucket}{'err-rate'}{occurrences} = $error_occurrences / $bucket_size_seconds * 60;
$log_occurrences{$bucket}{'msg-rate'}{occurrences} = $total_occurrences / $bucket_size_seconds * 60;
```

### Display (line ~5885-5894)
- Error rate: `errRate:`
- Message rate: `msgRate/m`
- Format: `errRate:msgRate/m` — single suffix printed once for both values

### CSV output
- Column headers: `err-rate`, `msg-rate` (no unit suffix)

## Changes Required

### Rate Calculation

Replace the hardcoded `* 60` with a unit-dependent multiplier:

| Unit | Multiplier | Suffix |
|------|-----------|--------|
| `s`  | 1         | `/s`   |
| `m`  | 60        | `/m`   |
| `h`  | 3600      | `/h`   |
| `d`  | 86400     | `/d`   |

### Legend Display

- Change `/m` suffix to match selected unit: `/s`, `/m`, `/h`, `/d`
- Update legend width calculation (suffix is always 2 characters, so no width change needed)

### CSV Output

- Column headers gain a unit suffix: `err-rate_sec`, `msg-rate_sec`, `err-rate_min`, `msg-rate_min`, `err-rate_hr`, `msg-rate_hr`, `err-rate_day`, `msg-rate_day`

### Documentation

- Update `print_help()` in `ltl`
- Update options reference in `README.md`
- Remove TO-DO at line 13

## Related

- GitHub issue: #122

## access-bin (drop1 median 11.033 s, range 10.950 to 11.261, n=20)

| candidate | n | median s | range s | vs base median | per-round delta median (range) s | per-round delta median % | rss median MB |
|---|---|---|---|---|---|---|---|
| drop1 | 20 | 11.033 | 10.950 to 11.261 | +0.00% | 0.000 (0.000 to 0.000) | +0.00% | 51.8 |
| full | 20 | 10.896 | 10.818 to 11.412 | -1.25% | -0.157 (-0.241 to 0.151) | -1.43% | 51.5 |
| cached | 20 | 10.925 | 10.808 to 11.517 | -0.98% | -0.135 (-0.253 to 0.409) | -1.23% | 51.4 |
| nocount | 20 | 10.867 | 10.746 to 11.570 | -1.50% | -0.165 (-0.341 to 0.492) | -1.49% | 51.6 |
| oneref | 20 | 10.363 | 10.218 to 10.552 | -6.07% | -0.678 (-1.000 to -0.492) | -6.15% | 51.5 |

## access-raw (drop1 median 8.878 s, range 8.756 to 9.149, n=20)

| candidate | n | median s | range s | vs base median | per-round delta median (range) s | per-round delta median % | rss median MB |
|---|---|---|---|---|---|---|---|
| drop1 | 20 | 8.878 | 8.756 to 9.149 | +0.00% | 0.000 (0.000 to 0.000) | +0.00% | 100.0 |
| full | 20 | 8.894 | 8.793 to 9.328 | +0.17% | 0.014 (-0.139 to 0.293) | +0.16% | 100.1 |
| cached | 20 | 8.886 | 8.732 to 9.159 | +0.09% | 0.027 (-0.296 to 0.131) | +0.30% | 100.1 |
| nocount | 20 | 8.849 | 8.711 to 9.107 | -0.34% | -0.041 (-0.275 to 0.228) | -0.46% | 99.9 |
| oneref | 20 | 8.319 | 8.229 to 8.946 | -6.31% | -0.546 (-0.893 to -0.082) | -6.15% | 100.1 |

## script-raw (drop1 median 2.264 s, range 2.237 to 2.398, n=20)

| candidate | n | median s | range s | vs base median | per-round delta median (range) s | per-round delta median % | rss median MB |
|---|---|---|---|---|---|---|---|
| drop1 | 20 | 2.264 | 2.237 to 2.398 | +0.00% | 0.000 (0.000 to 0.000) | +0.00% | 43.2 |
| full | 20 | 2.284 | 2.238 to 2.427 | +0.91% | 0.021 (-0.060 to 0.056) | +0.93% | 43.4 |
| cached | 20 | 2.290 | 2.235 to 2.381 | +1.15% | 0.015 (-0.108 to 0.071) | +0.68% | 43.1 |
| nocount | 20 | 2.287 | 2.238 to 2.375 | +1.02% | 0.025 (-0.117 to 0.128) | +1.13% | 43.2 |
| oneref | 20 | 2.282 | 2.259 to 2.950 | +0.82% | 0.029 (-0.126 to 0.686) | +1.28% | 43.2 |


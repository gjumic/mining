# ethOS Mining OS tools 

This are some tools i quickly developed for ethOS operating system

### List of working tools

1. GPU Monitor
  - This is general monitor for GPUs working inside ethos. It monitors for GPU state, hashrate, GPU memory, GPU voltage and GPU memory state. If it is under minimum set in script, your rig will log it and reboot. Everything is customizible in script.
2. GPU Monitor for sgminer-gm
  - I made this one for personal use when was testing mining RavenCoin with custom sgminer-x16r for ethos. Since it changes algorytm ethos can detect this as crash with last script. This script is little different since it monitors log of sgminer and when it declares any GPU dead it will reboot your rig.

## Prerequisites

There is no need for additional packages or programs installation.

### Installing

Use source code of any script you need, inside there is commented quick install guide.


## Acknowledgments

* Props to Cynix from thecynix.com for giving me ideas for code with his monitor http://thecynix.com/gpu.txt

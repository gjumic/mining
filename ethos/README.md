# ethOS Mining OS tools 

This are some tools i quickly developed for ethOS operating system

### List of working tools

1. GPU all in one Monitor
  - This is general monitor for GPUs working inside ethos. It monitors for GPU state, hashrate, GPU memory, GPU voltage and GPU memory state. If it is under minimum set in script, your rig will log it and reboot. Everything is customizible in script. It also supports when mining with sgminer-x16r for Ravencoin, since mining is little different here (changes in algoritm) it will read log of sgminer and look for dead card.


## Updates

3.4.2018 - Merged 2 gpu monitors to all in one script.

### Installing

1. Save file to desired location
2. Give execute premission to file with
```
# chmod +x gpu.sh
```

3. Modify script configuration via variables to suit your needs then save and exit.
4. sgminer-x16r ONLY: if you are using sgminer-x16r for mining use, edit */home/ethos/sgminer.stub.conf* and add *"log-file":"/tmp/sgminer.log"* to config.
If you did step above you will need to reboot your mining rig after you complete last step.
5. Execute once with sudo, so script adds itself to cronjob list. 
```
# sudo /home/ethos/gpu.sh
```
Thats it, your script will add itself and run every x minutes depending on configuration.

### Donations

If you have found this scripts useful please donate BTC or ETH to following adresses.

This will give me more motivation to work on this and many more scripts:

BTC = 1Dqa4Exdc2cfeMuhZ7Pnf9ri253UtbhsxY

ETH = 0xe42fb03f179Fe4e11480D623e5C40eA070a6222F

## Acknowledgments

* Props to Cynix from thecynix.com for giving me ideas for code with his monitor http://thecynix.com/gpu.txt


For all feedback contact me on jumic.goran[AT]gmail.com

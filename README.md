# Trace-Labs-VM-Ras-Pi-Build

This is a build script for setting up the Trace Labs OSINT VM on Raspberry Pi. The end result of this script will be a minimal Kali system that you will then add OSINT tools on to. 

The below process has only been tested on debian flavors of Linux:
* Start by cloning this repo to your system and navigating to the directory.
* First, run `sudo build-deps.sh` - this will get your current system ready to build the pi image.
* Second, run `sudo rpi-64-min.sh` - this will create a minimal Kali Pi image with no tools
* Third, burn the resulting `.img` file to an sd card as you normally would for a pi image.

### Troubleshooting 
If the "rpi-64-min.sh" is throwing errors from the beginning, you may need to move the entire folder outside of your home directory before running.

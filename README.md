# gooksdoo
An ASCII text viewer for 8-bit Commodore (and -ish) systems

The purpose of this tool is to view ASCII text files eg on the C128.
The special thing about it is that filesize doesn't matter, files can be larger than the amount of available RAM.

This is done by "streaming" the files off the disk-drive, sd2iec or other means of "mass" storage.

In addition to that, I'd like to have proportional fonts display in graphics mode.

This project is work-in-progress. No functionality is available as of yet.

## The long-term goal
In addition to that, this project is supposed to be a blueprint for a project that can cover multiple platforms.

For a start, this aims at Commodore (and -like) systems with 80-column displays. That includes:
* the C128 (VDC-Chip display only)
* the Mega65 (VIC-IV)
* the Commander X16 (VERA)
* the C64 with VIC-II Kawari (Bitmap mode for VIC-II might be added later)

Supported storage devices are:
* 1541, 157x, 1581
* SD2IEC
* Ultimate-II and Ultimate64 (that includes the Commodore 64U)
* CMD devices, at least some of them

* 

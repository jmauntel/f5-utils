## Overview

This repo is a collection of F5 utilities that I have built or come across over my time working on F5 units.

## clone-object.sh

This is an F5 LTM tool that clones an irule or data-group.  It can clone the object on a single F5 node or from one node to another.  The node to node clone was designed to make promoting objects between environments.  The script contains the following logic:

1.  Connect to the source device, fetch a copy of the source object, and place it in a temp file
2.  Update the source object in the temp file with the destination object name
3.  Upload the updated temp file to the destination device
4.  Validate that the temp file meets systax requirements
5.  Merge the temp file into the currently running config
6.  Cleanup temp files

## Requirements

* An administrative user account that has access to the tmsh command-line on the source and destination F5 device
* Established ssh keys with the source and destination F5 device

## Supported Platforms

This code was developed and tested using CentOS 5, but is assumed to work
on other platforms as well.

## Dependencies

* bash >= 3.2.25

## Examples:

Cloning an iRule on the same F5 device:

```
[user@host]:$ ./clone-object.sh -o rule -s example-1.0.0-irule -d example-1.1.0-irule -S 10.255.0.5 -D 10.255.0.5

Validating configuration...
  /tmp/example-1.0.0-irule
Loading configuration...
  /tmp/example-1.1.0-irule
```

Cloning a data-group from one F5 device to a second F5 device:

```
[user@host]:$ ./clone-object.sh -o rule -s example-1.0.0-irule -d example-1.0.0-irule -S 10.255.0.5 -D 10.0.0.5

Validating configuration...
  /tmp/example-1.0.0-irule
Loading configuration...
  /tmp/example-1.0.0-irule
```

## Author

Author: Jesse Mauntel (maunteljw@gmail.com)


# GNS3 Launch Lab in TMUX

GNS3 Launch Lab enables rapid deployment of lab environments for GNS3. The script allows you to launch a GNS3 lab with a single command, organizing various device types into separate tmux windows and panes for efficient access.

## Usage

To start a GNS3 lab environment:

```bash
perl launchlab.pl ccna-capstone
```
# Overview

This command will:
- Launch a `tmux` session consoled into all running VMs using `telnet`.
- Organize different device types into separate `tmux` windows.
- Group similar devices into panes within each window.

Any VNC-capable items will also be opened via `vncviewer`.

The script decides how to classify VMs based on their disk image names, so it's essential to update the array to organize images according to your preferences.

The script is designed for systems running GNS3 on bare metal in an isolated environment (hence the hardcoded SSH credentials).

## How It Works

1. The script connects to the remote GNS3 server via SSH.
2. It locates the project file and extracts the console port numbers for each node.
3. It then loops over each node, classifies them, and decides whether to add them to the tmux session (via telnet) or launch with `vncviewer`.

**Note**: Start all nodes before running the script. Nodes started after running the script must be connected to manually.

## Requirements

- Knowledge of `tmux` keyboard commands.
- Familiarity with disk image names in the nodes file to customize the array.

## Customizing Device Organization

To update which VMs appear in each `tmux` pane, modify the following code:

```perl
my %device_windows = (
    'routers'  => [
      "vios-adventerprisek9-m.spa.159-3.m6.qcow2",
      "i86bi-linux-l3-adventerprisek9-ms.155-2.T.bin"
    ],
    'switches' => [
      "vios_l2-adventerprisek9-m.ssa.high_iron_20200929.qcow2",
      "i86bi-linux-l2-ipbasek9-15.1g.bin"
    ],
    'pcs'      => [ "desktop-3-16-2-xfce.qcow2", "tcl-13-1.qcow2" ],
);
```
# Running Locally

To run locally instead of connecting to a remote GNS3 server, update the script to find project files on your PC or GNS VM directly. Adjust the file paths as necessary.


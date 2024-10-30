GNS3 Launch Lab is for the rapid deployment of lab environments.

It works by running one command followed by the name of the GNS3 project

perl launchlab.pl ccna-capstone

This will then launch a tmux session consoled into all running VMs using telnet. Different device types are separated by tmux windows, and similar devices separated by panes within those windows.

VNC items will be also be launched via vncviewer.

The script decides how to classify VMs based on their disk image name.  So its important to update the array with what images you want organized where.

The script was built intended for systems running GNS3 on bare metal in an isolated environment ( hence the hard coded ssh credential ).


The scipt works by shelling into the remote GNS3 server, finding the project file, and extracting the console port numbers for each of the nodes.  It then loops over those nodes, classifies them, and decides whether to add to the tmux session or launch with vnc.

Make sure to start all nodes before running the script.  Nodes started after running the script must be connected to manually.

Requires knowledge of tmux keyboard commands.

Find the name of disk images in the nodes file and update the array to your liking.

To run locally, the script can be updated to find the project files on the PC or GNS VM rather than using SSH to find/pull them from the remote server.  File paths will need to be updated for this to happen.


To update which VMs go on which panes in tmux, update the following code:

my %device_windows = (
    'routers'  => [
      "vios-adventerprisek9-m.spa.159-3.m6.qcow2" ,
      "i86bi-linux-l3-adventerprisek9-ms.155-2.T.bin"
    ],
    'switches' => [
      "vios_l2-adventerprisek9-m.ssa.high_iron_20200929.qcow2",
      "i86bi-linux-l2-ipbasek9-15.1g.bin"
    ],
    'pcs'      => [ "desktop-3-16-2-xfce.qcow2", "tcl-13-1.qcow2" ],
);

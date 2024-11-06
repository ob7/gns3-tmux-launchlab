#!/usr/bin/env perl

use strict;
use warnings;
use Net::OpenSSH;
use JSON;

# Check if a project name is provided
my $project_name = shift or die "Usage: $0 <project-name>\n";

# Remote server information
my $ssh = Net::OpenSSH->new("root\@gns3", password => "toor");
$ssh->error and die "SSH connection failed: " . $ssh->error;

# Step 1: Find the project file on the remote server
my $remote_project_path = $ssh->capture("find /root/GNS3/projects -type f -name '$project_name.gns3' 2>/dev/null");
chomp $remote_project_path;

# Check if the project file was found
if (!$remote_project_path) {
    die "Project file '$project_name.gns3' not found on the remote server.\n";
}

print "Found project file at: $remote_project_path\n";

# Step 2: Copy the project file to the local /tmp directory
$ssh->scp_get({glob => 0}, $remote_project_path, "/tmp/$project_name.gns3") or
    die "Failed to copy file: " . $ssh->error . "\n";

print "Project file downloaded to: /tmp/$project_name.gns3\n";


# File path after download (assuming previous code downloaded it to /tmp)
my $file_path = "/tmp/$project_name.gns3";

my %device_windows = (
    'routers'  => [ 
      "vios-adventerprisek9-m.spa.159-3.m6.qcow2" ,
      "i86bi-linux-l3-adventerprisek9-ms.155-2.T.bin"
    ],
    'switches' => [ 
      "vios_l2-adventerprisek9-m.ssa.high_iron_20200929.qcow2",
      "i86bi-linux-l2-ipbasek9-15.1g.bin",
    ],
    'l3switches' => [ 
      "cat9kv-prd-17.10.01prd7.qcow2",
      "nexus9300v64.10.3.1.F.qcow2"
    ],
    'pcs'      => [ 
      "desktop-3-16-2-xfce.qcow2", 
      "tcl-13-1.qcow2" ,
      "nixos.qcow2",
      "pc.qcow2"
    ],
    'servers'      => [ 
      "dnsServer.qcow2"
    ],
);

# Step 1: Read the JSON file
open my $fh, '<', $file_path or die "Cannot open file: $file_path\n";
my $json_text = do { local $/; <$fh> };
close $fh;

# Decode JSON text into Perl data structure
my $data = decode_json($json_text);

# Step 2: Organize nodes by type
my %categorized_devices;
foreach my $node (@{ $data->{topology}->{nodes} }) {
    # Find the first occurrence of `hda_disk_image`
    my $disk_image;

   # Loop over properties to find the first `hda_disk_image` or `path`
    foreach my $key (keys %{ $node->{properties} }) {
        if ((!defined $disk_image) && ($key eq 'hda_disk_image' || $key eq 'path')) {
            $disk_image = $node->{properties}->{$key};
        }
    }

    my $console_port = $node->{console};
    my $name = $node->{name};

    # Determine the device type based on `hda_disk_image`
    my $device_type;
    foreach my $type (keys %device_windows) {
        if (defined $disk_image && grep { $_ eq $disk_image } @{ $device_windows{$type} }) {
            $device_type = $type;
            last;
        }
    }

    # Default to `unknown` if no type matches
    $device_type //= 'unknown';

    # Store device details in categorized_devices
    push @{ $categorized_devices{$device_type} }, { name => $name, console_port => $console_port, disk_image => $disk_image };
}

# Step 3: Initialize tmux session with the first non-vnc device
my $session_name = $project_name;
my $tmux_initialized = 0;

foreach my $type (keys %categorized_devices) {
    # Create a new tmux window for each device type if there are devices of that type
    my $first_device = 1;
    foreach my $device (@{ $categorized_devices{$type} }) {
        my $name = $device->{name};
        my $port = $device->{console_port};

        # Skip vncviewer devices (those with ports starting with 59)
        if ($port =~ /^59/) {
            system("vncviewer gns3:$port &") == 0 or warn "Failed to start vncviewer for $name on port $port: $!\n";
            next;
        }

        # Initialize the tmux session with the first non-vnc device of any type
        if (!$tmux_initialized) {
            system("tmux new-session -d -s $session_name -n $type 'telnet gns3 $port'") == 0
              or die "Failed to start tmux session with $name on port $port: $!\n";
            $tmux_initialized = 1;
            $first_device = 0;  # First device in the window is already created
        } else {
            # If the tmux session is initialized but the window for this type hasn't been created
            if ($first_device) {
                system("tmux new-window -t $session_name -n $type 'telnet gns3 $port'") == 0
                  or warn "Failed to create new window for $type on port $port: $!\n";
                $first_device = 0;  # Set to 0 after creating the first window for this type
            } else {
                # Add additional devices to the same window as new panes
                system("tmux split-window -t $session_name:$type -h 'telnet gns3 $port'") == 0
                  or warn "Failed to open tmux pane for $name on port $port: $!\n";
                system("tmux select-layout -t $session_name:$type tiled");
            }
        }
    }
}



# Step 4: Attach to the tmux session if it was initialized
if ($tmux_initialized) {
    system("tmux attach -t $session_name") == 0 or die "Failed to attach to tmux session: $!\n";
} else {
    print "No non-vnc devices to start tmux session.\n";
}


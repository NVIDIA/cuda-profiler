#!/usr/bin/perl

use File::Basename;
use Cwd 'abs_path';
use strict;

# ==============================================================================
# 
# ONE-HOP PROFILING - v1.0
# -----------------
#   https://github.com/NVIDIA/cuda-profiler/tree/master/one_hop_profiling
#
# ==============================================================================


# The following variables pertain to the compute node. Edit them to
# correctly reflect your setup.

# User name / IP used to ssh into the compute node.
# Be sure to escape the "@" sign. E.g.: "user_name\@192.168.1.1"
my $compute_node_hostname = "";

# Path on the compute node to the CUDA bin directory. nvprof will be located
# here. This path is usually "/usr/local/cuda-[version]/bin"
my $cuda_path = "/usr/local/cuda-9.0/bin";

# Path on the compute node to the CUDA libraries.
# This path is usually "/usr/local/cuda-[version]/lib64"
my $cuda_ld_library_path = "/usr/local/cuda-9.0/lib64";

# Environment variable(s) to be set on the compute node before running
# application (optional). E.g. "VARIABLE=value"
my $env = "";

# ==============================================================================


my $cmd;
if(@ARGV == 1) {
    # Do not print anything here. This step is required because the NVIDIA
    # Visual Profiler queries device info as the first step.
    $cmd = "ssh $compute_node_hostname LD_LIBRARY_PATH=$cuda_ld_library_path:\$LD_LIBRARY_PATH PATH=$cuda_path:\$PATH nvprof $ARGV[0]";
    system($cmd);
    exit $? >> 8;
}


# The NVIDIA Visual Profiler wants us to generate an nvprof output file on this
# machine. We modify the '-o' argument value and generate the output file on
# the compute node, in the same directory that the executable is located. We
# later copy this file back into the directory on this machine that the Visual
# Profiler wants it to be in, and then delete the original on the compute node.
#
# As a result, the Visual Profiler never knows that we redirected the command
# to one more remote. As far as it is concerned, the output came from this
# machine.

my $i;
my $nvprof_options = "";
my $exe_options = "";

for($i = 0; $i < @ARGV; $i++) {
    last if($ARGV[$i] eq "-o");
    $nvprof_options = "$nvprof_options $ARGV[$i]";
}

$i++; # Leave -o
my $output_file_name = basename($ARGV[$i]);
my $copy_path = dirname($ARGV[$i]);
$nvprof_options = "$nvprof_options -f -o $output_file_name";

$i++;
my $exe_path = dirname($ARGV[$i]);
my $exe_name = basename($ARGV[$i]);

$i++;
for(; $i < @ARGV; $i++) {
    $exe_options = "$exe_options $ARGV[$i]";
}

my $nvprof_command = "$nvprof_options ./$exe_name $exe_options";

$cmd = "ssh $compute_node_hostname \"cd $exe_path;LD_LIBRARY_PATH=$cuda_ld_library_path:\$LD_LIBRARY_PATH PATH=$cuda_path:\$PATH $env nvprof $nvprof_command\"";

system($cmd);
if($?) {
    exit $? >> 8;
}

# Replace %p with * to copy all files generated. %p is specified if multiple
# processes are to be profiled, in which case, the %p is replaced by the
# process id of the profiled application.
$output_file_name =~ s/%p/\*/g;

# Copy the file from the compute node to this machine (i.e. the login node)
# via scp.
$cmd = "scp $compute_node_hostname:$exe_path/$output_file_name $copy_path";
system($cmd);

# Delete the original file on the compute node
$cmd = "ssh $compute_node_hostname rm $exe_path/$output_file_name";
system($cmd);
exit $? >> 8;

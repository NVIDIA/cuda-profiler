One-hop profiling
=================

This is a script that remotely profiles a CUDA program when the machine actually running it is not directly accessible from the machine running the NVIDIA Visual Profiler.

Such a setup may look like this:

    .--------------.      .--------------. ssh  .--------------.
    |              |      |              +----->+              |
    |              | ssh  |              |      |              |
    |     host     +----->+  login node  |      | compute node |
    |              |      |              |      |              |
    |              |      |              +<-----+              |
    '--------------'      '--------------' scp  '--------------'


 * The **host** machine is the one which is running NVIDIA Visual Profiler. This machine may run Windows, Linux or OSX. It may or may not have an NVIDIA GPU.
 * The **login node** is where this script will run. We just need ssh, scp and perl here; CUDA need not be installed. This needs to be a Linux machine.
 * The **compute node** is where the actual CUDA application will run and be profiled. The profiling data generated will be copied over to the login node so that it can be used by Visual Profiler on the host. This needs to be a Linux machine.

Usage instructions:
-------------------

**Setting up the login node**

1. Copy or download the [`one_hop_profiling.pl`](/one_hop_profiling/one_hop_profiling.pl) script to the login node.
2. Give the script execution permissions using the command: `chmod +x one_hop_profiling.pl`
3. Edit the script and add compute node details. This file has extensive documentation in terms of comments about which variables needed to be edited.
4. Install an SSH key to allow the login node to SSH into the compute node without a password. You can find instructions on how to do this [here](https://askubuntu.com/a/46935).

**Setting up the compute node**

1. Ensure that the CUDA program you want to profile is present on the compute node.
2. Ensure that the CUDA toolkit is installed, and nvprof is runnable and in the PATH.

**Setting up the host machine**

1. Ensure that the CUDA toolkit is installed on this machine, and that the toolkit version is the same as the one present on the compute node.

**Capturing the profile**

1. Run the Visual Profiler on this host machine.
2. Create a new session (Ctrl + N)
3. Connect to the login node by adding a remote connection as usual.
4. Click on `Manage...` Toolkit/Script.
5. Select the `Custom Script` radio button. Browse and select the profiling script on the login node. Click Finish.
6. Enter the executable file path on the remote machine in the `File` textbox. You will have to type this in. Remember that NVVP is connected only to the middle machine. It has no idea that the end machine exists, so the browse button will not be able to show you the paths on that machine.
7. `Next`/`Finish` to run as usual.
8. A profile will be captured and the timeline will be displayed.

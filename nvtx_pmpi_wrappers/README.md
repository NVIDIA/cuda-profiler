NVIDIA NVTX Wrappers for MPI
============================
License: Copyright 2017 NVIDIA CORPORATION, released under 3-clause BSD
license.
This software also uses software that is released under a 3-clause BSD license
by Lawrence Livermore National Laboratory.

Summary
-------
The included sources can be used to generate wrappers for common Message
Passing Interface (MPI) routines using the PMPI interface. The included 
sources will explicitly add a *range* using the NVIDIA Tools Extensions (NVTX)
API. When an MPI program is instrumented with the NVIDIA profilers, a range will
appear in the timeline for each traced MPI call.

You can read more about this technique [here](https://devblogs.nvidia.com/parallelforall/gpu-pro-tip-track-mpi-calls-nvidia-visual-profiler/).

Prequisites
-----------
* A working install of MPI
* The NVIDIA CUDA Toolkit
* Python
* make

Building
--------
Because each MPI implementation is subtly different, it is necessary to
generate the wrappers for your installed MPI library. These will be generated
from the file `nvtx.w` and the resulting file will be called `nvtx_pmpi.c`
which will be built into a shared object to be used with your program. To
build, simply run `make` in the top level directory.

    $ make

Extending
---------
If you would like to extend the library to include additional MPI calls of
interest or change the way the data is represented, make your changes to
`nvtx.w` and then rebuild. The makefile will automatically regenerate the
wrapper source based on your changes. For more information about how to modify
this file, please see `wrap/README.md`.

Usage
-----
The shared object file built above must be preloaded, along with the the NVIDIA
Tools Extensions library when gathering a performance profile. For example:

    $ LD_PRELOAD="<path-to-library>/libnvtx_pmpi.so" nvprof -o timeline.prof ./a.out

If the program `a.out` uses any of the wrapped MPI calls then these function
calls will appear as ranges in the NVPROF timline when it is later loaded into
the NVIDIA Visual Profiler. Any data movement or kernels used by the MPI
function call will appear in the range.

Known Limitations
-----------------
* Asynchronous MPI routines are not implemented because any data movement
  incurred as a result of these calls will not occur during the range.

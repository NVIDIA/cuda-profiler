/* Copyright (c) 2017, NVIDIA CORPORATION. All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *  * Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 *  * Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 *  * Neither the name of NVIDIA CORPORATION nor the names of its
 *    contributors may be used to endorse or promote products derived
 *    from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS ``AS IS'' AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
 * PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR
 * CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 * EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 * PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 * PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY
 * OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */
#include <nvToolsExt.h>
nvtxDomainHandle_t nvtx_mpi_domain;

// Initialize handles to NVTX registered strings
{{foreachfn name MPI_Send MPI_Recv MPI_Allreduce MPI_Reduce MPI_Wait MPI_Waitany
  MPI_Waitall MPI_Waitsome MPI_Gather MPI_Gatherv MPI_Scatter MPI_Scatterv
  MPI_Allgather MPI_Allgatherv MPI_Alltoall MPI_Alltoallv MPI_Alltoallw MPI_Bcast
  MPI_Sendrecv MPI_Barrier MPI_Isend MPI_Irecv}}
  nvtxStringHandle_t nvtx_{{name}}_message = 0;
{{endforeachfn}}

// Setup event category name and register strings
{{fn name MPI_Init}}
  nvtx_mpi_domain = nvtxDomainCreateA("MPI");

  // Register string for each MPI function
  {{foreachfn name MPI_Send MPI_Recv MPI_Allreduce MPI_Reduce MPI_Wait MPI_Waitany
  MPI_Waitall MPI_Waitsome MPI_Gather MPI_Gatherv MPI_Scatter MPI_Scatterv
  MPI_Allgather MPI_Allgatherv MPI_Alltoall MPI_Alltoallv MPI_Alltoallw MPI_Bcast
  MPI_Sendrecv MPI_Barrier MPI_Isend MPI_Irecv}}
  nvtx_{{name}}_message = nvtxDomainRegisterStringA(nvtx_mpi_domain, "{{name}}");
  {{endforeachfn}}

  {{callfn}}
{{endfn}}

// Wrap select MPI functions with NVTX ranges
{{fn name MPI_Send MPI_Recv MPI_Allreduce MPI_Reduce MPI_Wait MPI_Waitany
MPI_Waitall MPI_Waitsome MPI_Gather MPI_Gatherv MPI_Scatter MPI_Scatterv
MPI_Allgather MPI_Allgatherv MPI_Alltoall MPI_Alltoallv MPI_Alltoallw MPI_Bcast
MPI_Sendrecv MPI_Barrier MPI_Isend MPI_Irecv}}
  nvtxEventAttributes_t eventAttrib = {0};
  eventAttrib.version = NVTX_VERSION;
  eventAttrib.size = NVTX_EVENT_ATTRIB_STRUCT_SIZE;
  eventAttrib.messageType = NVTX_MESSAGE_TYPE_REGISTERED;
  eventAttrib.message.registered  = nvtx_{{name}}_message;
  eventAttrib.category = 999;

  nvtxDomainRangePushEx(nvtx_mpi_domain, &eventAttrib);
  {{callfn}}
  nvtxDomainRangePop(nvtx_mpi_domain);
{{endfn}}

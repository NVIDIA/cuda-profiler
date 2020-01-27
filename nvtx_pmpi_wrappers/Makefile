all: libnvtx_pmpi.so
libnvtx_pmpi.so: nvtx_pmpi.o
	mpicc $^ -shared -o $@ -L$(CUDA_HOME)/lib64 -lnvToolsExt
nvtx_pmpi.o: nvtx_pmpi.c
	mpicc -I$(CUDA_HOME)/include -DPIC -fPIC -c $^ -o $@
nvtx_pmpi.c: nvtx.w
	python2.7 wrap/wrap.py -f -o $@ $^

.PHONY: clean
clean:
	rm -f *.o libnvtx_pmpi.so nvtx_pmpi.c

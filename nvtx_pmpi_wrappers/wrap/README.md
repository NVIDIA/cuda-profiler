wrap.py
===========================
a [PMPI](http://www.open-mpi.org/faq/?category=perftools#PMPI) wrapper generator

by Todd Gamblin, tgamblin@llnl.gov, https://github.com/tgamblin/wrap

    Usage: wrap.py [-fgd] [-i pmpi_init] [-c mpicc_name] [-o file] wrapper.w [...]
     Python script for creating PMPI wrappers. Roughly follows the syntax of
       the Argonne PMPI wrapper generator, with some enhancements.
     Options:"
       -d             Just dump function declarations parsed out of mpi.h
       -f             Generate fortran wrappers in addition to C wrappers.
       -g             Generate reentry guards around wrapper functions.
       -c exe         Provide name of MPI compiler (for parsing mpi.h).
                      Default is \'mpicc\'.
       -s             Skip writing #includes, #defines, and other
                      front-matter (for non-C output).
       -i pmpi_init   Specify proper binding for the fortran pmpi_init
                      function.  Default is \'pmpi_init_\'.  Wrappers
                      compiled for PIC will guess the right binding
                      automatically (use -DPIC when you compile dynamic
                      libs).
       -o file        Send output to a file instead of stdout.


Thanks to these people for their suggestions and contributions:

* David Lecomber, Allinea
* Barry Rountree, LLNL

Known Bugs:

* Certain fortran bindings need some bugfixes and may not work.

Tutorial
-----------------------------
For a thorough tutorial, look at `examples/tutorial.w`!  It walks you through
the process of using `wrap.py`.  It is also legal `wrap.py` code, so you
can run `wrap.py` on it and see the output to better understand what's
going on.


CMake Integration
-----------------------------
`wrap.py` includes a `WrapConfig.cmake` file.  You can use this in your CMake project to automatically generate rules to generate wrap.py code.

Here's an example.  Suppose you put `wrap.py` in a subdirectory of your project called wrap, and your project looks like this:

    project/
        CMakeLists.txt
        wrap/
            wrap.py
            WrapConfig.cmake
In your top-level CMakeLists.txt file, you can now do this:

    # wrap.py setup -- grab the add_wrapped_file macro.
    set(WRAP ${PROJECT_SOURCE_DIR}/wrap/wrap.py)
    include(wrap/WrapConfig.cmake)

If you have a wrapped source file, you can use the wrapper auto-generation like this:

    add_wrapped_file(wrappers.C wrappers.w)
    add_library(tool_library wrappers.C)

The `add_wrapped_file` function takes care of the dependences and code generation for you.  If you need fortran support, call it like this:

    add_wrapped_file(wrappers.C wrappers.w -f)

And note that if you generate a header that your .C files depend on, you need to explicitly include it in a target's sources, unlike non-generated headers.  e.g.:

    add_wrapped_file(my-header.h my-header.w)
    add_library(tool_library
        tool.C         # say that this includes my-header.h
        my-header.h)   # you need to add my-header.h here.

If you don't do this, then the header dependence won't be accounted for when tool.C is built.

Wrapper file syntax
-----------------------------
Wrap syntax is a superset of the syntax defined in Appendix C of
the MPE manual [1], but many commands from the original wrapper
generator are now deprecated.


The following two macros generate skeleton wrappers and allow
delegation via `{{callfn}}`:

* `fn` iterates over only the listed
functions.
* `fnall` iterates over all functions *minus* the named functions.

    {{fnall <iterator variable name> <function A> <function b> ... }}
      // code here
    {{endfnall}}

    {{fn <iterator variable name> <function A> <function B> ... }}
    {{endfn}

    {{callfn}}

`callfn` expands to the call of the function being profiled.

`fnall` defines a wrapper to be used on all functions except the functions named.  fn is identical to fnall except that it only generates wrappers for functions named explicitly.

    {{fn FOO MPI_Abort}}
    	// Do-nothing wrapper for {{FOO}}
    {{endfn}}

generates (in part):

    /* ================== C Wrappers for MPI_Abort ================== */
    _EXTERN_C_ int PMPI_Abort(MPI_Comm arg_0, int arg_1);
    _EXTERN_C_ int MPI_Abort(MPI_Comm arg_0, int arg_1) {
        int return_val = 0;

    // Do-nothing wrapper for MPI_Abort
        return return_val;
    }

`foreachfn` and `forallfn` are the counterparts of `fn` and `fnall`, but they don't generate the
skeletons (and therefore you can't delegate with `{{callfn}}`).  However, you
can use things like `fn_name` (or `foo`) and `argTypeList`, `retType`, `argList`, etc.

They're not designed for making wrappers, but declarations of lots of variables and other things you need to declare per MPI function.  e.g., say you wanted a static variable per MPI call for some flag.

    {{forallfn <iterator variable name> <function A> <function B> ... }}
      // code here
    {{endforallfn}

    {foreachfn <iterator variable name> <function A> <function B> ... }}
      // code here
    {{endforeachfn}}


The code between {{forallfn}} and {{endforallfn}} is copied once
for every function profiled, except for the functions listed.
For example:

    {{forallfn fn_name}}
      static int {{fn_name}}_ncalls_{{fileno}};
    {{endforallfn}}

might expand to:

    static int MPI_Send_ncalls_1;
    static int MPI_Recv_ncalls_1;
    ...

etc.

* `{{get_arg <argnum>}}` OR `{{<argnum>}}`
	Arguments to the function being profiled may be referenced by
	number, starting with 0 and increasing.  e.g., in a wrapper file:

        void process_argc_and_argv(int *argc, char ***argv) {
        // do stuff to argc and argv.
        }

        {{fn fn_name MPI_Init}}
            process_argc_and_argv({{0}}, {{1}});
        {{callfn}}
        {{endfn}}
    Note that `{{0}}` is just a synonym for `{{get_arg 0}}`

* `{{ret_val}}`
	ReturnVal expands to the variable that is used to hold the return
	value of the function being profiled.   (was: `{{returnVal}}`)

* `{{fn_num}}`
	This is a number, starting from zero.  It is incremented every time
	it is used.

* `{{ret_type}}`
	The return type of the function. (was: `{{retType}}`)

* `{{formals}}`
	Essentially what would be in a formal declaration for the function.
	Can be used this with forallfn and foreachfn; these don't generate
	prototypes, they just iterate over the functions without making a
    skeleton.  (was: `{{argTypeList}}`)

* `{{args}}`
	Names of the arguments in a comma-separated list, e.g.:
    `buf, type, count, comm`

* `{{argList}}`
	Same as `{{args}}`, but with parentheses around the list, e.g.:
    `(buf, type, count, comm)`

* `{{applyToType <type> <callable>}}`
    This macro must be nested inside either a fn or fnall block.
    Within the functions being wrapped by fn or fnall, this macro will
    apply `<callable>` to any arguments of the function with type
    `<type>`.   For example, you might write a wrapper file like this:

        #define my_macro(comm) do_something_to(comm);
        {{fn fn_name MPI_Send MPI_Isend MPI_Ibsend}}
            {{applyToType MPI_Comm my_macro}}
            {{callfn}}
        {{endfn}}

Now the generated wrappers to `MPI_Send`, `MPI_Isend`, and `MPI_Ibsend` will do something like this:

    int MPI_Isend(void *buf, int count, MPI_Datatype datatype, int dest, int tag, MPI_Comm comm, MPI_Request *request) {
      int _wrap_py_return_val = 0;
      my_macro(comm);
      PMPI_Isend(buf, count, datatype, dest, tag, comm, request);
    }

* `{{sub <new_string> <old_string> <regexp> <substitution>}}`
    Declares `<new_string>` in the current scope and gives it the value
    of `<old_string>` with all instances of `<regexp>` replaced with
    `<substitution>`.  You may use any valid python regexp for `<regexp>`
    and any valid substitution value for `<substitution>`.  The regexps
    follow the same syntax as Python's re.sub(), and they may be single
    or double quoted (though it's not necessary unless you use spaces in
    the expressions).

    Example:

        {{forallfn foo}}
            {{sub nqjfoo foo '^MPI_' NQJ_}}
            {{nqjfoo}}
        {{endforallfn}}

  This will print `NQJ_xxx` instead of `MPI_xxx` for each MPI function.

* `{{fileno}}`
	An integral index representing which wrapper file the macro
	came from.  This is useful when decalring file-global variables
	to prevent name collisions.  Identifiers declared outside
	functions should end with _{{fileno}}.  For example:

		static double overhead_time_{{fileno}};

	might expand to

		static double overhead_time_0;


* `{{vardecl <type> <arg> <arg> ...}}` *(not yet supported)*
	Declare variables within a wrapper definition.  Wrap will decorate
    the variable name to prevent collisions.

* `{{<varname>}}` *(not yet supported)*
	Access a variable declared by `{{vardecl}}`.

Notes on the fortran wrappers
-------------------------------
    #if (!defined(MPICH_HAS_C2F) && defined(MPICH_NAME) && (MPICH_NAME == 1))
	    /* MPICH call */
        return_val = MPI_Abort((MPI_Comm)(*arg_0), *arg_1);
	#else
        /* MPI-2 safe call */
	    return_val = MPI_Abort(MPI_Comm_f2c(*arg_0), *arg_1);
	#endif

This is the part of the wrapper that delegates from Fortran
to C.  There are two ways to do that.  The MPI-2 way is to
call the appropriate _f2c call on the handle and pass that
to the C function.  The f2c/c2f calls are also available in
some versions of MPICH1, but not all of them (I believe they
were backported), so you can do the MPI-2 thing if
`MPICH_HAS_C2F` is defined.

If c2f functions are not around, then the script tries to
figure out if it's dealing with MPICH1, where all the
handles are ints.  In that case, you can just pass the int
through.

Right now, if it's not *specifically* MPICH1, wrap.py does
the MPI-2 thing.  From what Barry was telling me, your MPI
environment might have int handles, but it is not MPICH1.
So you could either define all the `MPI_Foo_c2f`/`MPI_Foo_f2c`
calls to identity macros, e.g.:

    #define MPI_File_c2f(x) (x)
    #define MPI_File_f2c(x) (x)

or you could add something to wrap.py to force the
int-passing behavior.  I'm not sure if you have to care
about this, but I thought I'd point it out.

-s, or 'structural' mode
-------------------------------

If you use the `-s` option, this skips the includes and defines used for C
wrapper functions.  This is useful if you want to use wrap to generate
non-C files, such as XML.

If you use -s, we recommend that you avoid using `{{fn}}` and `{{fnall}}`,
as these generate proper wrapper functions that rely on some of the
header information.  Instead, use `{{foreachfn}}` and `{{forallfn}}`, as
these do not generate wrappers around each iteration of the macro.

e.g. if you want to generate a simple XML file with descriptions of the
MPI arguments, you might write this in a wrapper file:

    {{forallfn fun}}
        <function name="{{fun}}" args="{{args}}"/>
    {{endforallfn}}

We don't disallow `{{fnall}}` or `{{fn}}` with `-s`, but If you used
`{{fnall}}` here, each XML tag would have a C wrapper function around it,
which is probably NOT what you want.


1. Anthony Chan, William Gropp and Weing Lusk.  *User's Guide for MPE:
Extensions for MPI Programs*.  ANL/MCS-TM-ANL-98/xx.
ftp://ftp.mcs.anl.gov/pub/mpi/mpeman.pdf



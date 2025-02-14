This archive contains GCCMVS in XMIT format.
--------------------------------------------

Note that the "GCC" module is a 31-bit version of the
compiler, so if you are running MVS/370 it won't work,
and you should instead use "GCC370" which is a 24-bit
module. The 31-bit version should work fine as-is on
z/OS, OS/390, MVS/XA and MVS/380. Also note that
although the compiler is 31-bit, by default it produces
24-bit modules. If you wish to change this to 31-bit,
then after installation read GCC.DOC(GCCMVS) where
there are instructions for running STAGE4.

More options for obtaining and installing GCCMVS
on different platforms can be found at 
http://gccmvs.sourceforge.net


To use this XMIT, you first need to transfer the .xmi 
file in binary mode to a FB80 dataset and then run 
"receive" in TSO. Transferring data to MVS is beyond 
the scope of this document. Some sites use ftp. Some 
use ind$file. Some use emulated tape.

Sample jobs have been provided for the "emulated tape"
scenario, although some of the jobs are also applicable
for other methods.


1. You probably want to define aliases for GCC and
PDPCLIB, at least if you are a systems programmer.
xmit1.jcl has sample JCL to do that. An applications
programmer installing datasets under his own userid
does not require this.

2. You need to allocate a dataset to contain the XMIT
file. xmit2.jcl will do that.

3. Now you need to transfer the data from the PC to
the mainframe. xmit3.jcl will do that for those
using emulated tapes *via the runmvs script* or
equivalent (e.g. manually creating TDF tape) on MVS/380.

4. Now "receive" the dataset, using a job similar
to xmit4.jcl.


Then follow the instructions in $$DOC of the
dataset created. This involves submitting another
job within the extracted PDS itself, something
remotely initiated for MVS/380 users, by using the
sample xmit5.jcl.


A "xmitrecv" Windows batch file is provided that does
all these steps for an MVS/380 user with a similar
setup. It's provided purely as an example.

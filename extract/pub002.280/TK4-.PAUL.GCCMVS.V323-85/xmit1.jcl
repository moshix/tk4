//GCCGEN   JOB CLASS=C,REGION=0K
//*
//* Define aliases for High-level qualifiers suitable
//* for your site.
//*
//IDCAMS   EXEC PGM=IDCAMS
//SYSPRINT DD  SYSOUT=*
//SYSIN    DD  *
  DEFINE ALIAS (NAME(GCC) RELATE(SYS1.UCAT.TSO)) -
         CATALOG(SYS1.VMASTCAT/SECRET)
  DEFINE ALIAS (NAME(PDPCLIB) RELATE(SYS1.UCAT.TSO)) -
         CATALOG(SYS1.VMASTCAT/SECRET)
  SET MAXCC=0
/*
//

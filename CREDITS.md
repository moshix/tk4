```
Terminal   CUU0C0                                                 Date  10.11.13
                                                                  Time  20:00:00


            TK3 created by Volker Bandke       vbandke@bsp-gmbh.com
            TK4- update by Juergen Winkelmann  winkelmann@id.ethz.ch
                     see TK4-.CREDITS for complete credits

                              MVS 3.8j Level 8505

Logon ===>
                                                            RUNNING  TK4-
```

<p align="center">
                        The MVS Tur(n)key TK4- System

                        =============================
</p>

The TK4- system is an update of the original MVS Tur(n)key Version 3 (TK3)
system. So credits go first and foremost to Volker Bandke and the whole crew
that brought TK3 to life, see:

<p align="center">
           http://www.bsp-gmbh.com/turnkey/cookbook/acknowledge.html
</p>

Additionally I'd like to acknowledge the work of all having contributed to
the MVS 3.8j resurrection efforts by posting software packages and usermods
on their websites, the Yahoo groups (mvs-turnkey, hercules-os380, H390-MVS)
or the CBT tape. Although each and every contribution is an important enabler
of the wide spread use of MVS 3.8j in modern times I think the efforts of two
very dedicated people should be mentioned most prominently here:

* The huge collection of software available on the CBT tape is the source of  most of the tools that have been adopted to MVS 3.8j over the past years. Sam Golob's outstanding work in maintaining the CBT tape, and especially in collecting MVS 3.8j adoptions back onto the tape, are clearly the base that made all the other efforts possible.

* Where would MVS 3.8j be today if Greg Price's well known "ZP6xxxx" usermods weren't available? Bringing TSO/VTAM 3270 functionality close to the level of current operating systems made it possible to create or adopt terminal applications providing in sum almost the capabilities of ISPF/PDF and other IBM tools that for legal reasons aren't available to the MVS 3.8j community. Namely Greg's own great tools like IMON/370, QUEUE and RFE/REVIEW together with Rob Prins' famous RPF form a perfect ISPF/PDF/SDSF replacement product-ivity suite.

I tried to my best to identify the individual authors or current maintainers of the packages I installed above the original TK3 level and to name them in the following table. Please drop me a note if you aren't mentioned in the table but think that you should be, or if you'd like to see anything else changed.

November 2013, Juergen Winkelmann
winkelmann@id.ethz.ch


--------------------------------------------------------------------------------
```
Bert Lindeman, Gerhard Postpischil, Testing, discussion and contributions
Greg Price, Phil Roberts,           during the August until November 2013
Scott Cosel, Shelby Beach,          beta phase
Tom Armstrong
```
--------------------------------------------------------------------------------
`Bert Lindeman, Scott Cosel          SYS2.JCLLIB: Sample JCL collection`
--------------------------------------------------------------------------------
`Bill Godfrey                        TSSO`
--------------------------------------------------------------------------------
`Brian Cook, Juergen Winkelmann      ETPS 2.4-3.8j`
--------------------------------------------------------------------------------
```
Brian Westerman                     AUTO
                                    display maximum condition or         SYZJ201
                                    abend code in notify message         SYZJ202
                                    remove CN(00) from notify message    SYZM001
                                    SHOWSS
                                    SYSTEM
                                    dynamic PROCLIB support              #DYP001
                                                                         #DYP002
                                                                         #DYP003
                                                                         #DYP004
                                                                         #DYP005
```
--------------------------------------------------------------------------------
Bruce Leland                        BLKxxxx (BLKDISK)
--------------------------------------------------------------------------------
```
Binyamin Dissen, Greg Price,        TESTVTM2
Juergen Winkelmann                  SNASOL
```
--------------------------------------------------------------------------------
```
Charlie Brint, Gerhard Postpischil  DSSREST
```
--------------------------------------------------------------------------------
```
Craig Yasuma, Phil Dickinson,       RAKF 1.2.0                           TRKF120
Phil Roberts, Juergen Winkelmann
```
--------------------------------------------------------------------------------
`Dave Cole                           BLKSPTRK`
--------------------------------------------------------------------------------
`Dave Cole, Greg Price               OFFLOAD (distributed with REVIEW)`
--------------------------------------------------------------------------------
```
Ed Liss                             MAPDISK
                                    MAP3270
                                    ```
--------------------------------------------------------------------------------
`Gene Czarcnski, Joe Schindler,      AUPGM`
`Bill Godfrey                        DOPGM`
--------------------------------------------------------------------------------
```
Gerhard Postpischil                 DISASM
                                    DSSDUMP
                                    IEBUPDTX
                                    EXHIBIT
                                    TSO LIST command (alias of PRINTON)
                                    Stanford PASCAL (modified ETH Zuerich P2)
                                    STEPLIB
```
--------------------------------------------------------------------------------
`Gerhard Postpischil, Greg Price     PDSLOAD`
--------------------------------------------------------------------------------
```
Gerhard Postpischil,                IBM fix for excessive spin loops     VS49603
Juergen Winkelmann
```
--------------------------------------------------------------------------------
```
Gilbert Saint-Flour                 EXECPGM
                                    FILLDASD
                                    INITKSDS
```
--------------------------------------------------------------------------------
`Gilbert Saint-Flour,                BYPASSNQ`
`Juergen Winkelmann                  STRING`
--------------------------------------------------------------------------------
```
Gilles Vollant, Jason Winter        MINIZIP (distributed with REVIEW)
                                    MINIUNZ (distributed with REVIEW)
```
--------------------------------------------------------------------------------
```
Greg Price                          DDASD
                                    DUCH3270
                                    DUCHESS
                                    DUPTIME
                                    IMON/370
                                    INITOBJ
                                    LIFE
                                    LISTVOL
                                    QUEUE
                                    RFE/REVIEW
                                    REVLMOD
                                    SHOWDS
                                    SIMZ9
                                    SPY
                                    TERMTEST
                                    TSOTEST
                                    WORM
                                    Usermod ZP60002A                     ZP60002
                                    Usermod ZP60003                      ZP60003
                                    Usermod ZP60004                      ZP60004
                                    Usermod ZP60005A                     ZP60005
                                    Usermod ZP60006                      ZP60006
                                    Usermod ZP60007                      ZP60007
                                    Usermod ZP60008                      ZP60008
                                    Usermod ZP60009                      ZP60009
                                    Usermod ZP60011                      ZP60011
                                    Usermod ZP60012                      ZP60012
                                    Usermod ZP60013                      ZP60013
                                    Usermod ZP60014                      ZP60014
                                    Usermod ZP60015                      ZP60015
                                    Usermod ZP60016                      ZP60016
                                    Usermod ZP60017                      ZP60017
                                    Usermod ZP60018                      ZP60018
                                    Usermod ZP60019                      ZP60019
                                    Usermod ZP60020                      ZP60020
                                    Usermod ZP60021                      ZP60021
                                    Usermod ZP60022                      ZP60022
                                    Usermod ZP60023                      ZP60023
                                    Usermod ZP60024                      ZP60024
                                    Usermod ZP60025                      ZP60025
                                    Usermod ZP60026                      ZP60026
                                    Usermod ZP60027                      ZP60027
                                    Usermod ZP60028                      ZP60028
                                    Usermod ZP60029                      ZP60029
                                    Usermod ZP60030                      ZP60030
                                    Usermod ZP60031                      ZP60031
                                    Usermod ZP60032                      ZP60032
                                    SUPERLST/XVTCLIST
```
--------------------------------------------------------------------------------
```
Jason Winter                        JCC 1.50.00
                                    TCPIP instruction (opcode X'75')
                                    OFFLMOD (distributed with REVIEW)
```
--------------------------------------------------------------------------------
```
Jay Moseley                         - $DP and $U commands                WM00017
                                    - DISKMAP
                                    - IEHMAP
                                    - WATFIV: Waterloo FORTRAN IV
                                    - various other compilers taken over
                                      from TK3 and TK3UPD into TK4-
```
--------------------------------------------------------------------------------
```
Jim Morrison                        SHOWMVS
                                    XMIT370 and RECV370
```
--------------------------------------------------------------------------------
```
John Chandler, Max H. Parke         Kermit
```
--------------------------------------------------------------------------------
```
John Kalinich, Greg Price           PDS 8.6
```
--------------------------------------------------------------------------------
```
Juergen Winkelmann                  add RAKF DD statements to MSTRJCL    ZJW0003
                                    create a new subsystem name table    ZJW0007
                                    display 20th century in              ZJW0004
                                    TSO Logon/Logoff msgs
                                    put USER and PASSWORD in jobcard     ZJW0001
                                    update C-3PO and R2-D2 (BSPPILOT)    ZJW0006
            RAKF PTFs:
            Enhancements and Fixes to RAKFUSER and RAKFPROF              RRKF001
            Make RACINIT Password Changes permanent                      RRKF002
            Security Enhancement in Users and Profiles Tables Processing RRKF003
            RAKF User's Guide                                            RRKF004
            RACIND Utility to control VSAM RACF Indicators               RRKF005
            Sample jobs to RACF indicate or unindicate the whole system  RRKF006
                                    CHECKMOD
                                    TSOAPPLS
                                    3791L and 3705/NCP enhancements
                                    VTAM, TCAM and TSO SNA enhancements
                                    - Populate JCTJTPTN with terminal    ZJW0008
                                      name upon TSO logon
                                    - Fix SNA LU2 losterm condition      ZJW0009
                                    - Make TSO/VTAM SNA LU1 ASIS table   ZJW0010
                                      fully transparent
                                    - TCAM SNA generation
                                    - VTAM SNA configuration
                                    - Allow specification of 24 PFKeys
                                      in SYSGEN macro CONSOLE            ZJW0011
                                    - Support 24 PFKeys on 3270 consoles ZJW0012
```
--------------------------------------------------------------------------------
```
Kermit Kiser, Wolfgang Schaefer,    C3270 aka KOMM
Juergen Winkelmann
```
--------------------------------------------------------------------------------
```
Kevin Leonard                       allow IEECVXIT to see internal msgs  TMVS805
                                    Fix for APAR OY12275                 AY12275
                                    JES2 SSCTSSID and SSIBSSID init      TJES801
```
--------------------------------------------------------------------------------
```
Larry Williams, Mark Stevens,       KLINGON
Greg Price
```
--------------------------------------------------------------------------------
```
Laureen Beauchaine                  LETTERS
                                    TSOUSER
```
--------------------------------------------------------------------------------
```
Margaret Gardner,                   TCAM 3270 support                    TC01101
Juergen Winkelmann                  TCAM 3270 support                    TC01303
                                    TCAM 3270 support                    TC01402
                                    TCAM 3270 support                    TC01503
                                    TCAM 3270 support                    TC01601
                                    TCAM 3270 support                    ZJW0005
```
--------------------------------------------------------------------------------
```
Max H. Parke                        2703 ASYNC
                                    3705 NCP
                                    3791L
```
--------------------------------------------------------------------------------
```
Mike Brennan, Thomas Dickey,        MAWK 1.3.4
Juergen Winkelmann
```
--------------------------------------------------------------------------------
`Mike Rayborn                        IND$FILE`
--------------------------------------------------------------------------------
```
Mike Schortman, Scott Vetter        JRP (JES2 Remote Printing)
Juergen Winkelmann
```
--------------------------------------------------------------------------------
`Pennsylvania State University       ASSIST`
--------------------------------------------------------------------------------
```
Paul Edwards                        GCC 3.2.3 for MVS 8.5
                                    PDPCLIB 3.10
```
--------------------------------------------------------------------------------
`Peter Sylvester, Karel Babcicky     SIMULA 67 (Version 12.00)`
--------------------------------------------------------------------------------
```
Phil Roberts                        PDSUPDTE
                                    Stanford PL360
Phil Roberts ??                     put consoles in RD mode at IPL       ZUM0015
```
--------------------------------------------------------------------------------
```
R. L. Miller, Bruce Leland,         VTOC with RACF status display/sort
Phil Roberts
```
--------------------------------------------------------------------------------
`Rob Prins                           RPF 1.5.3`
--------------------------------------------------------------------------------
`Scott Cosel                         ZAP 21st century in COBOL compiler listings`
--------------------------------------------------------------------------------
`Scott Vetter                        DT`
--------------------------------------------------------------------------------
```
Shelby Beach                        TSO FIB user exit IKJEFF53           SLB0001
                                    accept REGION=xM in jcl              SLB0002
                                    correct abend 22F in comm task init  SLB0003
                                    MVSDDT 3.2.0
                                    SYS2.SXMACLIB: S/370 extension instructions
                                                   structured programming macros
```
--------------------------------------------------------------------------------
`Solomon Santos, Gerhard Postpischil TAPEMAP`
--------------------------------------------------------------------------------
`Steve Becquer                       ADVENT`
--------------------------------------------------------------------------------
`somitcw                             DDU`
--------------------------------------------------------------------------------
```
Tom Armstrong                       ALGOL F Level 2.1
                                    Independent Component Release for MVS 3.8
```
--------------------------------------------------------------------------------
`Tommy Sprinkle                      FSI 1.2.0`
--------------------------------------------------------------------------------


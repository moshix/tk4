//GREGQ   JOB  CLASS=A,NOTIFY=GREG,MSGCLASS=X,REGION=2048K
//*
//*  QUEUE FOR MVS 3.8J WITH 3270 EXTENDED ATTRIBUTES
//*
//*  THIS JOB CREATES THE SOURCE AND OBJECT LIBRARIES AND LOADS
//*  THE SOURCE.  MEMBER C CONTAINS THE COMPILE AND LINK JCL.
//*
//*  CUSTOMISE THE JOB CARD ABOVE, AND THE SYSUT2 AND OBJECT
//*  DD STATEMENTS BELOW FOR YOUR SYSTEM BEFORE RUNNING THIS JOB.
//*
//*  CUSTOMISE THE JOB CARD AND DATA SET NAMES IN MEMBER C
//*  BEFORE SUBMITTING IT AFTER THIS JOB HAS RUN SUCCESSFULLY.
//*
//STEP1   EXEC PGM=PDSLOAD
//SYSPRINT DD  SYSOUT=*
//SYSUT2   DD  DSN=GREG.QUEUE.ASM,DISP=(NEW,CATLG),
//             UNIT=3350,SPACE=(CYL,(10,5,20)),
//             DCB=(RECFM=FB,LRECL=80,BLKSIZE=19040)
//OBJECT   DD  DSN=GREG.QUEUE.OBJ,DISP=(NEW,CATLG),
//             UNIT=3350,SPACE=(CYL,(1,1,20)),
//             DCB=(RECFM=FB,LRECL=80,BLKSIZE=3120)
//SYSIN    DD  DATA,DLM=@@
./ ADD NAME=$GPDOC   8018-02202-07001-1446-00284-00021-00000-GREG
This version of QUEUE was modified from the 1982 MVS/370 version
shipped by Volker Bandke on his first MVS Turnkey CD.

Modifications by Greg Price of PRYCROFT SIX PTY LTD
       during June to November 2002 for MVS 3.8J.

       Updated 5th February 2003.

       Updated 7th February 2003:
CTSO changed to ensure that fullscreen mode is on after a TSO command.

       Updated 15th February 2003:
- Change screen buffer definitions in QCOMMON from DC to DS statements
  to reduce the object deck size by about 200 card images.
- Increase the static screen buffer sizes in QCOMMON (all three of them)
  in order to be able to handle screen sizes up to 9920 (like 62x160).
  For every 8 bytes of extra screen size QUEUE can handle, the size of
  the load module grows by 24 bytes.  A dynamic buffer acquistion scheme
  may well be an improvement that could be made.
- Use a NOEDIT TPUT for screen sizes larger than 4096 so that 14-bit
  buffer addresses are not translated before transmission.  Addresses >
  4095 must be sent as binary numbers, and therefore can be corrupted
  if any filtering of invalid characters takes place.  They are inserted
  into the data stream by the compression of repeated characters.  The
  compression of the data stream probably becomes more important as the
  size of the screen becomes larger.
- Reinstate the TPUT MF=L area in QCOMMON for the NOEDIT TPUT.
- Add the X operand to the MODEL command to set the current terminal's
  alternate size as the QUEUE screen size.  This is independent of the
  screen size used by TSO line-mode screen management.
- Show the Userid and the Terminal name on the top line on wide screens.
- Ensure that the correct screen size is restored after a TSO command.

       Updated 4th March 2003:
- Restore SYSOUT data display after a TSO command is issued during a
  display of SYSOUT data.
- Do not trigger a PRINT when a PREV command is issued.

       Updated 28th March 2003: add IEF702I to LNCDTABL.

       Updated 30th December 2006:
- Document CAN, DEL and REQ commands in a new HELP screen.
- Allow the 'O' selection code to trigger a $O JES2 command.
- Set last character of HASPACE DDname from sixth character of volser.
  Since all SPOOL volumes will have the same first five characters,
  this provides QUEUE support for any number of SPOOL volumes that
  JES2 allows.  This scheme taken from posts to the H390-MVS list.

       Updated 1st January 2007:
- Allow viewing of job log if job is on an output queue.


Changes during 2002 include:

- Rationalisation to TPUT and TGET macros.

  Problems with some maintenance levels of TPUT and/or TGET macros
  have been circumvented by converting all TPUT and TGET macro calls
  from MF=E to inline macros (which translate to a single SVC) with
  registers being pre-loaded as required by program logic.  The MF=L
  work areas have been dispensed with.  The TTPUT and TTGET members
  have been deleted from this file.


- Addition of support for 3270 character attributes.

  A shadow buffer is maintained (in a similar fashion to ISPF
  DYNAMIC areas) to specify the character attributes (as opposed
  to field attributes) of each screen location.  The new BLD3270
  routine creates a 3270 data stream from the primary and shadow
  buffers, and calls the CB3270 routine (found on a SHARE or CBT
  tape in the 1980s and which I originally added to the Fujitsu
  port of QUEUE at the time) which has also been added with this
  upgrade to apply 3270 data stream compression.

  The new QHEAD macro, and changes to QTILT and many routines use
  the shadow buffer to specify colour and highlighting to be used
  for headings, display lines, and error messages.

  Uses of this capabiliy include showing immediate action SYSLOG
  messages in white, colour coding JMSG output, and highlighting
  active work in queue lists.  These two features are performed
  in routine LISTDS (formerly Q15).  The LNCDTABL table which has
  the attribute codes for JMSG messages must have its entries in
  collating sequence order.

  The new MONO and COLO commands can toggle the "use 3270 extended
  data stream orders to activate extended colour and highlighting"
  switch.  The switch is on in the QCOMMON source.  If a 3270 terminal
  or emulation thereof cannot handle 3270 EDS then the switch can be
  turned off in the source and QUEUE can then be reassembled.  That
  this is the actual problem can be tested by issuing 'Q MONO' from
  the READY prompt.


- Addition of support for selection codes.

  Removing the 3270 data stream from the in-storage buffer of
  the screen image under construction meant that it was simple to
  introduce internal codes to represent field attribute bytes,
  which in turn allowed new input fields to be easily created.
  Most of the status displays have now had a selection input
  field added to each item in the list.  This allows items to be
  processed by selection as opposed to being processed by a
  command where the name of the item has to be typed in.


- Cursor auto-selection or "point-and-shoot".

  The cursor auto-selection facility is controlled by the QFLG2PNS
  bit in byte QFLAG2 in QCOMMON.  When active, the 'S' selection code
  is implied by locating the cursor over an input selection field in
  column 2 without actually typing any text character into the field.
  This feature is also called "point-and-shoot" in the source code.
  As a result of this feature autoskip has been removed from the
  attribute bytes so that the cursor does not automatically move to
  the next selection field thereby triggering an inadvertent
  selection.


- Removal of need to assemble local constants.

  Previously the names of all systems present in the MAS, as well as
  the unit and volume of the checkpoint data set to be accessed had
  to be assembled from the source or zapped into the load module.
  Now, the system identifiers are read from the checkpoint data set,
  SYSALLDA is used as the unit name, and the volume is ascertained
  from the primary subsystem vector table.  Hence, local customisations
  pertaining to data set placement or system identifier names do not
  generate a need to update QUEUE to maintain accuracy or convenience.
  (The CKPT(unit,volser) operand is still allowable, but if no CKPT
  operand is supplied the currently operational checkpoint will be
  used.)


- Addition of NEXT and PREV commands.

  When a job is selected with an 'S' selection code, the job log is
  shown.  Movement to subsequent data sets can be achieved with the
  NEXT command.  'N 3' from the job log will cause SPOOL data set 101
  of the job to be displayed.  PREV provides access to data sets with
  lower data set identifiers.  I have obviously lifted this idea from
  SDSF.  Unlike SDSF, SYSIN data sets are always eligible for display.


- PF3/15 variable meaning.

  PF3/15 meant "exit QUEUE".  Whenever it does not mean that now the
  actual meaning of PF3/15 is shown on the bottom right corner of the
  screen.  These "other meanings" are an attempt to make PF3/15 cause
  a single level back-out rather than termination of the whole program.
  EXIT and END and E still mean "exit QUEUE" no matter where in QUEUE
  they are issued, but PF3/15 no longer always means END.


- HELP processing updated.

  The display of an extra blank page no longer occurs.  The extra
  commands/operands have been documented.  An extra page on selection
  codes has been added.  The fact that the only allowable selection
  code from a DD display is 'S' is not listed.  When HELP is invoked
  from the display of a SPOOL data set, PF3/15 functions as "leave
  HELP and return to the data set".


- Scrolling changes.

  The scrolling has been made more SPF-like.  A scroll amount override
  of H (half-page), P (page) or M (maximum) is now allowed.  Much of
  the code for this change was lifted from the OSIV/F4 (MSP) revamp
  carried out by Mike Holloway (MAH) of Fujitsu Australia in 1982/1983.
  (Mike's version included support for AF/JES.  Fj's JES2 was called
  JES, and their JES3 was called JESE.)

  2003-02-05  The page and half page scrolling amounts have now been
  fixed to not always be derived from a 24-line screen, but from the
  number of lines the screen currently has.


- PF8/20 fiddle.

  Scrolling is only active in QUEUE when viewing a SPOOL data set.
  Sometimes I find myself looking at a list of jobs or data sets in
  QUEUE and when I want to see the next page I press PF8 instead of
  ENTER.  To accommodate my habit PF8/20 now functions as ENTER
  whenever a SPOOL data set is not being browsed.  This avoids the
  disruption of the error message and having to restart at the
  beginning of the list.


- Initial command change.

  The default initial command is changed from HELP to STATUS.
  This is more likely to be useful on repeated usage.
  This value is set in QCOMMON and can be changed by source
  update or SUPERZAP to the CSECT.


- Display of data set identifier.

  The DSID shown in the heading line was taken from the second
  operand of the L command.  If the data set was displayed by
  another command then the DSID field would not be filled in.
  Now it is always shown from the DSID used by QUEUE to access
  the data set.


- Display of priority.

  The PRIORITY column of the STATUS display shows the JQE or job
  JES2 priority in the 1 to 15 range.  Output elements also have a
  JOE priority.  For a display with 14.4 showing, 14 is the JQE
  priority and 4 is the JOE priority.  Held SYSOUT (denoted by
  "HELD OUT" in QUEUE) has not yet had JOEs assigned to it by this
  version of JES2.  (This was later changed.)  A JOE represents
  a work element that can be processed by a printer or a punch.
  Only held SYSOUT can be processed by the TSO OUTPUT command.


- Century and day-of-the-week fixed in PRINT heading.

  The heading produced by the PRINT command had the century
  hard-coded.  Also, the day-of-the-week logic was not working
  for at least 2002, and possibly the 21st century.  The GETTIME
  routine was completely rewritten (with new Zeller's congruence
  code) to work with 20th and 21st century dates.  (This was
  deemed to be simpler than debugging the existing code.)


- New MODEL logic.

  The MODEL command screen handling logic has been redone.
  It will be interesting to see if it works when (and if)
  alternate screen size support is ever added to the free
  versions of TSO and VTAM.

  2003-02-05  Well, at least 32-line and 43-line screens worked okay.
  The largest supported screen size has been increased from Model-4
  to Model-5.  All STSIZE macros have been removed (because STSIZE
  sets the size for TSO line-mode screen management, and has little
  to do with a fullscreen application like QUEUE).  The TSO TERMINAL
  command can be used from within QUEUE via the TSO subcommand if the
  line-mode dimensions need to be changed without leaving QUEUE.

- New SPIN command.

  The CSPIN source member was pretty much copied as-is from the
  "modern" version of QUEUE (for SP5.2).  Incorrect line number
  in heading after SAVE or SPIN has been fixed.


- New SLOG default.

  SLOG (or SL) with no operands, or with an operand of SYSLOG,
  will now attempt to show the current/active SYSLOG.  The
  default is still to show the latest data set of a given
  SYSLOG job.  "SL SYSLOG 1" and "SL SYSLOG -1" are equivalent,
  and specify the second-latest data set.


- Notes about DC.

  The address spaces shown in DC are ascertained from JES2 control
  blocks.  As a result, address spaces without a JES2 job identifier
  such as JES2 itself will not be shown.  A small code change allowed
  the selection of ASID 1 (under the auspices of SYSLOG) to be
  selected.  I sought to make this change because my recollection is
  that ASID 1 was displayed.  (A subtle change by SE2, perhaps?)
  (MVS truism: CPU time consumed by paging activity will be most
  evident as SRB time of ASID 1.  Q's DC is one of the few monitors
  which shows the TCB and SRB times as separate items.)

  The operand is a 0-3 character string made up from the letters J,
  S and T to specify the address space types to be included.  No
  operand specifies the inclusion of all address spaces.  Another
  change lifted from Mike Holloway's version for MSP.

  Highlighted (ie. yellow) jobs are swapped in.  This is derived from
  the real storage usage because this level of MVS does not have
  logical swapping.  Which brings us to the most crucial change made
  to QUEUE by this series of updates:  The DC column heading has been
  corrected from SLOTS to FRAMES.


./ ADD NAME=$JQT
         MACRO -- JQT -- PHONY DSECT TO DESCRIBE FIRST CKPT REC
         $JQT
JQTDSECT DSECT
         GBLB  &QSP                                               UF020
         AIF   (&QSP).QSP1                                        UF020
JQTOUT   DS    H              HEADER FOR OUTPUT JQES
         DS    7H
JQTSTC   DS    H
JQTTSU   DS    H              HEADER FOR TSO USER JQES
JQTCLSA  DS    H              HEADER FOR CLASS A JQES
JQTQMAX  EQU   46             MAXIMUM NUMBER OF QUEUES
         MEXIT                                                    UF020
.QSP1    ANOP                                                     UF020
JQTOUT   DS    F              HEADER FOR PRINT/PUNCH JQES         RNB19
JQTAWOUT DS    F              HEADER FOR OUTPUT JQES (AWAITING)   RNB19
JQTDUMP  DS    F              HEADER FOR DUMP JQE'S               RNB19
         DS    4F                                                 RNB19
JQTXEQ   DS    F              HEADER FOR XEQ (CONVERSION) JQE'S   RNB19
JQTSTC   DS    F                                                  UF020
JQTTSU   DS    F              HEADER FOR TSO USER JQES            UF020
JQTCLSA  DS    F              HEADER FOR CLASS A JQES             UF020
JQTQMAX  EQU   48             MAXIMUM NUMBER OF QUEUES            UF020
         MEND
./ ADD NAME=$RENAME  8003-02205-02308-1540-00045-00044-00000-GREG
  The following member renames were performed along the lines
  of the renaming done by Jack Schudel in October 1982
  because, as he pointed out at the time, those silly
  Qnn member names were getting to be a real pain!             GP 2002

  Q00     was renamed to      QUEUECMN
  Q1      was renamed to      QUEUE
  Q2      was renamed to      ALLOCATE
  Q3      was renamed to      CKPT
  Q4      was renamed to      DDNAME
  Q5      was renamed to      DISPLAY
  Q6      was renamed to      FINDJOB
  Q7      was renamed to      FORMAT
  Q8      was renamed to      HELP
  Q9      was renamed to      HEXBLK
  Q10     was renamed to      INIT
  Q11     was renamed to      JCL
  Q12     was renamed to      JLOG
  Q13     was renamed to      JMSG
  Q14     was renamed to      LIST
  Q15     was renamed to      LISTDS
  Q16     was renamed to      PARSE
  Q17     was renamed to      READSPC
  Q18     was renamed to      REPOS
  Q19     was renamed to      SAVE
  Q20     was renamed to      SEARCH
  Q21     was renamed to      SYSLOG
  Q22     was renamed to      XDS
  Q23     was renamed to      INITS
  Q24     was renamed to      ACTIVE
  Q25     was renamed to      FINDPDDB
  Q26     was renamed to      SYSOUT
  Q27     was renamed to      PRINT
  Q28     was renamed to      HEXDUMP
  Q29     was renamed to      CJQE
  Q30     was renamed to      CJCT
  Q31     was renamed to      CTSO
  Q32     was renamed to      CHCT
  Q33     was renamed to      CPDDB
  Q34     was renamed to      CJOE
  Q35     was renamed to      BLD3270
  Q36     was renamed to      CB3270
  Q37     was renamed to      CSPIN
  Q38     was renamed to      NEXT
  HELP    was renamed to      TSOHELP
./ ADD NAME=$RNBDOC
THIS DATASET WAS OBTAINED FROM FILE 322 ON VER193 OF THE CBT TAPE, AND
WAS THEN MODIFIED AT RAINIER NATIONAL BANK.

RNB00 -                - MOVED DSECTS AROUND FOR IFOX ASSEMBLER
        Q4  (DDNAME)
        Q10 (INIT)
        Q12 (JLOG)
        Q15 (LISTDS)
        Q20 (SEARCH)
        Q25 (FINDPDDB)
        Q26 (SYSOUT)
        Q33 (CPPDB)
RNB01 - Q1  (QUEUE)    - FIX TO FINAL TPUT MESSAGE TO ALLOW TO WORK WITH
                           BOTH TCAM AND VTAM
RNB02 - Q10 (INIT)     - REMOVE PART OF UF010: DON'T USE OPER AUTHORITY
                           TO SET QXAUTH. ALSO UF024: DON'T USE DBC.
RNB03 - Q10 (INIT)     - FOR RACF: IF &QRACF = 1, AND IF &QNEWUSR ISN'T
                           NULL, THEN IF APF-AUTHORIZED CHANGE THE
                           USERID IN THE ACEE SO THE USER CAN ACCESS A
                           RACF-PROTECTED SPOOL/CHECKPOINT DATA SET.
      - Q16 (PARSE)    - IF &QRACF = 1 THEN USE RACF TO CHECK AUTHORITY
                           TO USE THE XP COMMAND.
      - Q17 (READSPC)  - IF &QRACF = 1 THEN WHEN A JCT IS READ FROM THE
                           SPOOL BLANK THE PASSWORD AND NEWPASSWORD.
      - Q22 (XDS)      - IF &QRACF = 1 THEN DO A SPECIAL CHECK TO SEE IF
                           THE USER IF ALLOWED TO DO THE XDS COMMAND.
RNB04 - Q12 (JLOG)     - FIX TO ALLOW JLOG TO WORK FOR JOBS THAT ARE IN
                           EXECUTION BUT THAT HAVEN'T FINISHED THE FIRST
                           STEP. THIS WILL SHOW ONLY THE 'JOB STARTED'
                           MESSAGE.
RNB05 - Q14 (LIST)     - IF &QRNB = 1 THEN DO THE FOLLOWING:
                           (1) REMOVE THE PART OF UF005 THAT ALLOWS L TO
                               PROCESS DSID'S < 101 AND THAT ALLOWS AUTH
                               USERS TO LIST ANY JOB.  THIS REQUIRES THE
                               XD COMMAND TO BE USED TO LIST STRANGE
                               THINGS.
                           (2) ALLOW TSO USERS TO ACCESS ANY JOB THAT
                               STARTS WITH THEIR USERID OR THAT HAS A
                               NOTIFY FOR THEIR USERID. THIS WILL NOT
                               BE ALLOWED FOR USERID'S STARTING WITH
                               'PJS' DUE TO LOCAL RESTRICTIONS.
                           (3) ALLOW TSO USERS WHOSE USERID'S START WITH
                               'TEC' TO PROCESS ANY 'TEC...' JOB OR ANY
                               JOB WITH A NOTIFY FOR A TEC USER. ALSO
                               ALLOW THEM TO PROCESS OUTPUT FROM STARTED
                               TASKS.
RNB06 - Q16 (PARSE)    - ADDED THE FOLLOWING COMMAND ABBREVIATIONS FOR
                           CONSISTENCY WITH PREVIOUS VERSIONS:
                                 JC  FOR JCL
                                 JL  FOR JLOG
                                 JM  FOR JMSG
                                 SL  FOR SLOG
                                 FT  FOR FTIM
                                 DE  FOR DEL
                                 RE  FOR REQ
                         ALSO, IF &QRNB = 1, DELETE COMMANDS TSO, EXEC,
                           AND MODEL.
RNB07 - Q24 (ACTIVE)   - WHEN LISTING BATCH JOBS SAY THEY
                           ARE ON THE XEQ QUEUE INSTEAD OF THE INPUT
                           QUEUE TO BE MORE CONSISTENT WITH WHAT THE
                           OPERATORS USUALLY SEE.
RNB08 - Q26 (SYSOUT)   - IF &QRNB = 1, ALLOW USERS TO MANIPULATE JOBS
                           THAT START WITH THEIR USERID'S OR THAT HAVE
                           A NOTIFY FOR THEIR USERID, UNLESS THE USERID
                           STARTS WITH 'PJS'.
                         IF &QRNB = 1, ALLOW 'TEC' USERS TO MANIPULATE
                           ANY TEC JOB OR STARTED TASK OUTPUT.
RNB09 - Q26 (SYSOUT)   - IF &QRNB = 1, FOR A REQ OPERATION, IF A NEW
                           CLASS IS NOT GIVEN, USE CLASS C AS THE
                           DEFAULT NEW CLASS.
RNB10 - Q27 (PRINT)    - IF &QRNB = 1, USE C AS THE DEFAULT SYSOUT
                           CLASS.
RNB11 - Q4  (DDNAME)   - ALLOW DDNAME COMMAND TO BE
                           ISSUED AS   DDNAME JOBID S
                           WHERE THE S INDICATES THAT THE SPIN DATA
                           SETS SHOULD ALSO BE LISTED. THIS WAS ADDED
                           BECAUSE WE HAVE SOME LONG RUNNING BATCH JOBS
                           (IMS) THAT SPIN THINGS AND THE STANDARD Q
                           COMMAND DOESN'T SEARCH THE SPIN Q FOR BATCH
                           JOBS.
RNB12 - Q4  (DDNAME)   - IF &QSP = 1, DON'T FORMAT THE MESSAGE 'ALREADY
                           PRINTED', AS IT APPEARS THAT THE FLAG BIT
                           IN THE PDDB IS NOT USED ANY MORE, CAUSING
                           ALL SPIN DATA SETS TO APPEAR PRINTED, EVEN
                           WHEN THEY'RE NOT.
RNB13 - Q5  (DISPLAY)  - FIX SOME PROBLEMS WITH TCAM
                           AND THE PROCESSING OF THE TEST-REQUEST,
                           SYSTEM-REQUEST, AND THE PA2/PA3 KEYS.
RNB14 - Q5  (DISPLAY)  - BUG FIX FOR FULL-SCREEN PROCESSING. WITH THIS
                           FIX THE USER CAN ENTER A COMMAND IN EITHER
                           INPUT FIELD, NOT JUST THE BOTTOM ONE.
RNB15 - Q5  (DISPLAY)  - RESTORE THE PFK DEFINITIONS FOR
                           PF7/8 TO '- 27' AND '+ 27' AS ORIGINALLY
                           SUPPLIED BY THE ICBC MOD. WE DON'T HAVE
                           THE OTHER 3278 MODELS, AND SCROLLING IS
                           EASIER THIS WAY. WITH NERDC'S CHANGES TO
                           MAKE THE KEYS 'PB' AND 'PF' IT IS DIFFICULT
                           TO SCROLL UP OR DOWN A FEW LINES.
RNB16 - Q20 (SEARCH)   - PROCESS BOTH THE LOCAL AND REMOTE QUEUES FOR
                           JOBS AWAITING PRINT/PUNCH.
                         ALSO FIX A BUG IN UF020 THAT WAS CLEARING THE
                           JOEFLAG  WHEN JUST THE JOEJQE POINTER SHOULD
                           BE CLEARED.
RNB17 - Q7  (FORMAT)   - WHEN FORMATTING JOES:
                           (1) IF THE JOE IS BEING PROCESSED BY PSO,
                               INDICATE EXT-WTR FOR A DEVICE TYPE.
                           (2) USE $JOEBUSY FLAG TO INDICATE WHETHER JOB
                               IS REALLY PRINTING/PUNCHING. OTHERWISE,
                               AN INTERRUPTED JOB STILL SHOWS AS ON THE
                               PRINTER/PUNCH.
                           (3) FOR SP2, FIX A BUG IN GETTING TO THE
                               CHECKPOINT JOE AND IN COMPUTING THE LINES
                               LEFT TO PRINT/PUNCH.
                           (4) FOR SP2, IF THE JOE IS NOT ACTIVE, BUT
                               THE CHECKPOINT JOE IS VALID, SHOW THE
                               LINES LEFT, NOT THE ORIGINAL LINE COUNT.
RNB18 - Q7  (FORMAT)   - DISTINGUISH BETWEEN JOES WITH REMOTE ROUTING
                           AND THOSE WITH SPECIAL LOCAL ROUTING (DESTID
                           INITIALIZATION STATEMENT IN JES PARMS).
RNB19 - Q20 (SEARCH)   - FOR STATUS OR DJ COMMANDS IN THE SP2 VERSION,
                           ALSO SEARCH THE DUMP Q, THE CONVERSION Q,
                           AND THE OUTPUT Q. THIS ALLOWS THE USER TO
                           FIND HIS JOB IF IT'S AWAITING DUMP, AWAITING
                           CONVERSION, OR AWAITING OUTPUT PROCESSING.
      - Q7  (FORMAT)   - WHEN LISTING JQE'S, DON'T ASSUME INPUT QUEUE
                           BUT USE JQETYPE INSTEAD. ALSO, SPECIAL
                           HANDLING FOR AWAITING CONVERSION, AWAITING
                           DUMP, AND AWAITING OUTPUT.
RNB20 - Q7  (FORMAT)   - DISTINGUISH BETWEEN NORMAL HOLD, HELD VIA $HA,
                           AND DUPLICATE HOLD. ALSO, FOR JOES, IF THE
                           SELECT=NO FLAG IS ON, FLAG WITH S=N TO SHOW
                           WHY THE OUTPUT WON'T PRINT.
RNB21 - Q7  (FORMAT)   - FIX THE SETDEVIC ROUTINE FOR SP2 SO THE PROPER
                           DEVICE NAMES SHOW UP FOR JOBS ON PRINTERS,
                           ETC.
RNB22 - Q6  (FINDJOB)  - IF JOBNAME = *, AFTER READING THE JCT, ENSURE
                           THAT JQEJNAME = JCTJNAME AND THAT QPJOBID =
                           JCTJBKEY IN CASE THE JOB HAS PURGED AND THE
                           JCT HAS BEEN REUSED SINCE WE LAST READ THE
                           CHECKPOINT. THIS IS UNLIKELY, BUT SEEMS TO BE
                           POSSIBLE.
RNB23 - Q8  (HELP)     - MISCELLANEOUS CHANGES TO THE NERDC HELP INFO.
                           THE ORIGINAL NERDC VERSION IS MEMBER $Q8, AND
                           THE OLD RNB MEMBER IS #Q8.
RNB24 - Q23 (INITS)    - BUG FIX, AS SUGGESTED BY JACK SHUDEL
RNB25 - Q7  (FORMAT)   - ADD 'COUNT' OPTION TO THE HO COMMAND TO HELP
                           FIND WHICH JOBS ARE TIEING UP SPOOL SPACE.
                           WHEN THE COUNT OPTION IS USED, THE JCT FOR
                           EACH JQE WITH HELD OUTPUT WILL BE READ AND
                           THE JCT TOTAL LINE COUNT WILL BE DISPLAYED.
RNB26 - Q24 (ACTIVE)   - BUG FIX (SORT OF): THE DC COMMAND WAS SHOWING
                           A LOT OF STRANGE JOBS. THIS FIX MAKES IT MORE
                           REASONABLE, BUT IT'S STILL NOT QUITE RIGHT.
                           ALL OF THE STARTED TASKS, E.G. TCAM, DON'T
                           SHOW UP.

========================================================================
KNOWN PROBLEMS:
  (1) DC S DOESN'T SHOW ALL OF THE STARTED TASKS.
  (2) JOE PRIORITIES ARE (PROBABLY) INCORRECT, AS THE CALCULATIONS
      CHANGED FOR SP2 AND Q HASN'T BEEN UPDATED TO REFLECT THAT.
  (3) IT APPEARS THAT THE LINE COUNTS FOR JOBS ON A REMOTE PRINTER ARE
      MAINTAINED DIFFERENTLY THAT FOR JOBS ON A LOCAL PRINTER. THIS HAS
      NOT BEEN FULLY RESEARCHED YET, BUT IT SEEMS THAT THE LINE COUNT
      REPORTED BY Q FOR A JOB ON A REMOTE PRINTER IS APPROXIMATELY THE
      NUMBER OF LINES PRINTED, NOT THE NUMBER THAT REMAIN TO BE PRINTED.
  (4) ONLY 2 (POSSIBLY 3) CHARACTER REMOTE NUMBERS CAN BE USED.
  (5) NJE NODE NUMBERS ARE IGNORED.
  (6) THE NJE JOB/SYSOUT TRANSMITTERS AND RECEIVERS ARE IGNORED AS
      DEVICES AND AS QUEUES.
./ ADD NAME=$SP
THE SP VERSION OF THE QUEUE COMMAND IS OBTAINED BY SPECIFYING
"SYSPARM=((SP))" FOR THE ASSEMBLIES (SEE MEMBER $NERJCL2).
MEMBER QSTART CAN ALSO BE UPDATED TO CHANGE THE DEFAULT FLAG SETTING
TO ELIMINATE THE NEED TO SPECIFY ANY SYSPARM AT ALL.

SEE MEMBER $UFDOC FOR A DESCRIPTION OF THE OTHER MODIFICATIONS.

THIS VERSION OF QUEUE WAS DEVELOPED AS IN INTERNAL AID FOR THE DEBUGGING
OF THE NEW JES2 SYSTEM, WHICH NORMALLY RUNS AS A SECONDARY SUBSYSTEM.
IT IS BELIEVED THAT MOST OF THE DISPLAY COMMANDS WORK PROPERLY, WITH THE
EXCEPTION OF STATUS AND DO.  BOTH OF THERE COMMANDS ARE IN MODULE Q20
(SEARCH).  THE PROBLEM WITH THE DISPLAY OUTPUT COMMANDS IS THAT THERE
ARE NOW TWO QUEUES FOR OUTPUT JOES, ONE FOR LOCAL ROUTING, AND THE OTHER
FOR REMOTE ROUTING.  AT THIS TIME ONLY THE LOCAL ROUTING QUEUE IS
PROCESSED.  THE PROBLEM WITH THE STATUS COMMAND SEEMS TO BE THAT THE
COMMAND SKIPS SOME OF THE QUEUES ENTIRELY, BUT THAT SEEMED TO BE A
PROBLEM WITH THE OLD VERSION OF THE COMMAND AS WELL.
IN PARTICULAR, JOBS IN THE OUTPUT QUEUE (NOT HARDCOPY) SEEM TO
BE IGNORED IN ALL ENVIRONMENTS.

THIS VERSION WILL NOT WORK IF ANY OF THE DEFINED SPOOL VOLUMES
ARE NOT AVAILABLE, INCLUDING A SPOOL VOLUME THAT WAS ADDED AND
THEN PURGED AT A LATER TIME.

THERE WAS ONE PROBLEM WITH THE SYSLOG COMMAND CAUSED BY A CHANGE IN
THE WAS THAT SPUN OUTPUT PDDB'S ARE GENERATED.  IT APPEARS THAT A
SPUN SYSOUT WILL NOW HAVE TWO SEPARATE PDDB'S; A NULL ONE IN THE
NORMAL IOT, AND THE TRUE ONE IN A SPIN IOT.  BECAUSE BOTH OF THE
PDDB'S HAVE THE SAME NUMBER, NORMAL QUEUE PROCESSING WOULD LOCATE
THE FIRST ONE, SEE THAT IT WAS NULL, AND INDICATE THAT THE FILE WAS
EMPTY.  CODE HAS BEEN CHANGED IN LISTDS TO CHECK IF THE MTTR FIELD
IS ZERO BEFORE TESTING FOR THE PROPER DATASET ID NUMBER.  ANY PDDB
WITH A ZERO MTTR FIELD WILL BE IGNORED.  THE ONLY POSSIBLE CHANGE
THAT THE USER WILL NOTICE IS THAT THERE WILL BE TIMES WHEN THE OLD
VERSION WOULD INDICATE "DATASET IS EMPTY" WHILE THE NEW VERSION
WILL INDICATE "DATASET ID NOT FOUND".

AT THIS TIME THE FINDPDDB ROUTINE HAS NOT BEEN CHANGED, SO THE
DD COMMAND WILL PROBABLY GIVE SOME INCORRECT INDICATIONS ABOUT
THE STATUS OF SOME SYSOUTS.

A PDDB COMMAND HAS BEEN ADDED THAT WILL DUMP OUT SOME OF THE MORE
RELEVANT INFORMATION ABOUT THE PDDB'S IN GENERAL, OR DUMP OUT
SELECTED ONES IN HEX, TO ASSIST IN FIGURING OUT WHAT IS REALLY
GOING ON.

I WOULD APPRECIATE HEARING FROM ANYONE WHO COMES UP WITH EITHER
ADDITIONAL BUGS OR FIXES TO THE KNOWN ONES.  ALSO, I WILL TRY TO
PASS ON ANY FIXES TO THOSE USERS THAT I AM AWARE OF, SO PLEASE DROP
ME A NOTE IF YOU GET THIS OFF OF ONE OF THE MODS TAPES.

JACK SCHUDEL
NORTHEAST REGIONAL DATA CENTER
233 SSRB, UNIVERSITY OF FLORIDA
GAINESVILLE, FLORIDA  32611
(904) 392-4601
SHARE CODE - UF

./ ADD NAME=ACTIVE   8007-02166-02203-0019-00248-00209-00000-GREG
ACTIVE   QSTART 'QUEUE COMMAND - LIST ACTIVE JOB STATUS'
******************************************************************
* RNB CHANGES:                                                   *
*       (1) RNB07 - WHEN LISTING BATCH JOBS, SAY THEY            *
*                   ARE ON THE XEQ QUEUE INSTEAD OF INPUT QUEUE. *
*       (1) RNB26 - BUG FIX TO STOP LISTING A LOT OF STRANGE JOBS*
******************************************************************
         GBLB  &QSP           MVS/SP OPTION                       UF020
         GBLB  &QPFK          PF-KEY OPTION. DEFINED BY QSTART    GP@P6
         USING QCKPT,R9       BASE REG FOR CHECKPOINT AREA
         L     R9,QVCKPT      LOAD BASE REG
         USING WORK,R13       BASE REG FOR LOCAL WORK AREA
***********************************************************************
*                                                                     *
*        SET THE DISPLAY SELECTION CRITERIA       GP@P6/MAH JULY 2002 *
*                                                                     *
***********************************************************************
         MVI   DATYPE,X'00'   CLEAR DISPLAY TYPE INDICATOR
         LA    R8,QPARM1      R8 <- ADDRESS OF OPERAND
         LH    R7,QLNG1       R7 <- LENGTH OF OPERAND
         LTR   R7,R7          OPERAND SUPPLIED?
         BNZ   CHKJ           -> YES - CHECK IT
         OI    DATYPE,DAJ+DAS+DAT      INDICATE ALL REQUIRED
         B     CALLCKPT
CHKJ     CLI   0(R8),C'J'     ACTIVE JOBS?
         BE    ISJ            -> YES
         CLI   0(R8),C'B'     ACTIVE JOBS?
         BNE   CHKS           -> NO - CHECK STARTED TASKS
ISJ      OI    DATYPE,DAJ     SHOW ACTIVE JOBS REQUIRED
         B     CONT
CHKS     CLI   0(R8),C'S'     ACTIVE STARTED TASKS?
         BNE   CHKT           -> NO - CHECK TSS USERS
         OI    DATYPE,DAS     SHOW STARTED TASKS REQUIRED
         B     CONT
CHKT     CLI   0(R8),C'T'     ACTIVE TSS USERS?
         BNE   BADPARM        -> NO - BAD PARAMETER
         OI    DATYPE,DAT     SHOW ACTIVE TSS USERS REQUIRED
CONT     LA    R8,1(R8)
         BCT   R7,CHKJ
******************************************************************UF006
*                                                                 UF006
*   CALL - READ JES2 CHECKPOINT ROUTINE                           UF006
*                                                                 UF006
******************************************************************UF006
CALLCKPT L     R15,=V(CKPT)   ADDR OF CKPT ROUTINE                UF006
         BALR  R14,R15        GO TO IT                            UF006
         L     R8,16          POINT TO CVT
         USING CVTDSECT,R8
***********************************************************************
*                                                                     *
*        FIND THE ACTIVE MAIN SUBSYSTEM SSVT                          *
*                                                                     *
***********************************************************************
         L     R7,CVTASVT     POINT TO ASVT
         L     R2,CVTMSER     POINT TO ASVT
         USING ASVT,R7
         L     R7,ASVTMAXU    LOAD THE MAX ASCBS
         DROP  R7
         L     R8,CVTJESCT    POINT TO JESCT
         DROP  R8
         USING JESCT,R8
         L     R8,JESSSCT     POINT TO SSCT
         DROP  R8
         USING SSCT,R8
         L     R8,SSCTSSVT    POINT TO SSVT
         DROP  R8
         USING SSVT,R8
***********************************************************************
*                                                                     *
*        FIND THE ACTIVE MAIN SUBSYSTEM'S HAVT                        *
*                                                                     *
***********************************************************************
         L     R6,$SVHAVT     POINT TO HAVT
         LTR   R6,R6          TEST IF ANY PITS
         BZ    NOHAVT         NO, IGNORE COMMAND
         LA    R6,4(,R6)      POINT TO FIRST SJB POINTER
         USING SJBDSECT,R5
         QHEAD INITHD,X'24',TYP=QDDC   HEADING IN GREEN REVERSE   GP@P6
***********************************************************************
*                                                                     *
*        BUILD THE MESSAGE(S) DESCRIBING THE JOBS                     *
*                                                                     *
***********************************************************************
BLDMSG   MVC   QDMSG,QBLANK   BLANK THE AREA
         L     R5,0(,R6)      POINT TO SJB
         LTR   R5,R5          TEST FOR ANY
         BZ    NEXTSJB
         L     R4,SJBSJB      TEST FOR BATCH JOB
         LTR   R4,R4          IS IT
         BNZ   BATCHCHK
         L     R3,SJBJQOFF    LOAD JQE OFFSET
         LTR   R3,R3          ANY JQE?                            RNB26
         BZ    NEXTSJB        /NO  - TRY NEXT SJB                 RNB26
         AL    R3,QCJQTA      ADD TO JQE ORIGIN
         USING JQEDSECT,R3    BASE REG FOR JQE
         AIF   (&QSP).QSP1                                        UF020
         LH    R0,JQEJOBNO    GET JOB NO.
         CH    R0,=H'20000'   TSO USER?
         BNL   TSOCHK         YES. GO PROCESS
         B     STCCHK         NO. GO PROCESS AS STC
         AGO   .QSP2                                              UF020
.QSP1    ANOP                                                     UF020
         TM    JQEFLAG3,QUEJOB  BATCH JOB?  (SHOULDN'T BE)        RNB26
         BO    UNK              /YES - SAY UNKNOWN                RNB26
         TM    JQEFLAG3,QUETSU  TSO USER?                         UF020
         BO    TSOCHK         YES, GO PROCESS                     UF020
         TM    JQEFLAG3,QUESTC  STARTED TASK?                     UF020
         BO    STCCHK         YES, GO PROCESS                     UF020
UNK      MVC   QUEUE,=CL8'UNKNOWN'                                UF020
         B     NOTTSO         PRINT WHATEVER WE CAN FIND          UF020
.QSP2    ANOP                                                     UF020
BATCHCHK TM    DATYPE,DAJ     BATCH DISPLAY ?                    GP/MAH
         BNO   NEXTSJB        NO. GET NEXT SJB                   GP/MAH
         LR    R5,R4          COPY THE SJB ADDRESS
         L     R3,SJBJQOFF    POINT TO JQE OFFSET
         LTR   R3,R3          ANY JQE?                            RNB26
         BZ    NEXTSJB        /NO  - TRY NEXT SJB                 RNB26
         AL    R3,QCJQTA      POINT TO THE JQE
         IC    R0,JQETYPE     GET THE JOB TYPE
         MVC   QUEUE,=CL8'XEQ'                              GP@P6 RNB07
         STC   R0,QUEUE+7     SET THE QUEUE TYPE
         OI    QUEUE+7,X'80'  SET THE PRINTABLE QUEUE TYPE
         B     NOTTSO         GO TO COMMON ROUTINE
TSOCHK   TM    DATYPE,DAT     TSO DISPLAY ?                      GP/MAH
         BNO   NEXTSJB        NO. GET NEXT SJB                   GP/MAH
         MVC   QUEUE,=CL8'TSO USER'
         B     NOTTSO
STCCHK   TM    DATYPE,DAS     STC DISPLAY ?                      GP/MAH
         BNO   NEXTSJB        NO. GET NEXT SJB                   GP/MAH
         MVC   QUEUE,=CL8'SYSTEM Q'
NOTTSO   L     R1,SJBASCBP    POINT TO ASCB
         USING ASCB,R1
         LM    R14,R15,ASCBEJST GET THE CPU TIME
         SRDL  R14,12         SKIP THE GARBAGE
         D     R14,=F'10000'  GET THE VALUE IN .01 SECS
         CVD   R15,CONVERT    GET THE DECIMAL VALUE
         MVC   TCBTIME,EDCPU  MOVE EDIT MASK
         ED    TCBTIME,CONVERT+4 EDIT THE NUMBER
         MVI   TCBTIME+L'TCBTIME-1,C'S' SET SECONDS
         LM    R14,R15,ASCBSRBT GET THE CPU TIME
         SRDL  R14,12         SKIP THE GARBAGE
         D     R14,=F'10000'  GET THE VALUE IN .01 SECS
         CVD   R15,CONVERT    GET THE DECIMAL VALUE
         MVC   SRBTIME,EDCPU  MOVE EDIT MASK
         ED    SRBTIME,CONVERT+4 EDIT THE NUMBER
         MVI   SRBTIME+L'SRBTIME-1,C'S' SET SECONDS
         MVC   JOBNAME,SJBJOBNM MOVE IN JOBNAME
         LH    R14,JQEJOBNO   LOAD JOB NUMBER
         CVD   R14,CONVERT    GET THE DECIMAL VALUE
         MVC   JOBNUM,ED5     GET THE CHARACTER VALUE
         ED    JOBNUM,CONVERT+5 GET THE CHARACTER VALUE
         LR    R4,R2          COPY THE ADDRESS
FINDCSCB ICM   R4,15,0(R4)    POINT TO THE NEXT CSCB
         BZ    DONECSCB       NO MATCHING CSCB WAS FOUND          GP@P6
         USING CSCDSECT,R4
         CLC   CHKEY,JQEJNAME TEST FOR RIGHT JOB
         BNE   FINDCSCB       NOPE
         MVC   STEPNAME,CHSTEP MOVE IN STEPNAME
         MVC   PROCSTEP,CHPROCSN MOVE IN THE PROCSTEP NAME
         DROP  R4
DONECSCB L     R15,QVDSPL     POINT TO QUEUE DISPLAY VARIABLES    GP@P6
         USING QDISPLAY,R15   BASE REG FOR DISPLAY AREA           GP@P6
         LH    R0,ASCBFMCT    GET NUMBER OF FRAMES
         MVI   QDLNCODE,X'05' TURQUOISE FOR SWAPPED OUT           GP@P6
         SLA   R0,2           GET NUMBER OF K                     GP@P6
         BZ    SWPCLROK       ADDRESS SPACE IS SWAPPED OUT        GP@P6
         MVI   QDLNCODE,X'06' YELLOW FOR SWAPPED IN               GP@P6
SWPCLROK CVD   R0,CONVERT     GET THE DECIMAL VALUE
         MVC   SLOTS,ED5      MOVE EDIT MASK
         ED    SLOTS,CONVERT+5 GET THE K
         MVI   SLOTS+L'SLOTS-1,C'K' SET THE 'K'
         AIF   (NOT &QPFK).DCNOSEL                                GP@P6
         MVI   QDMSG,X'0B'    INPUT HIGH INTENSITY                GP@P6
         MVI   QDMSG+1,C'.'   SUPPLY SELECTION FIELD DOT          GP@P6
         MVI   QDMSG+2,X'0C'  OUTPUT LOW INTENSITY                GP@P6
.DCNOSEL ANOP                                                     GP@P6
         MVC   QDMLNG,=H'80'  SET THE LENGTH
         LA    R0,QDMSG       GET THE ADDRESS
         ST    R0,QDMSGA      SET THE ADDRESS
         DROP  R15                                                GP@P6
         L     R15,=V(DISPLAY) POINT TO THE ROUTINE
         BALR  R14,R15        CALL THE ROUTINE
***********************************************************************
*                                                                     *
*        SEND THE MESSAGE DESCRIBING THE PIT                          *
*                                                                     *
***********************************************************************
NEXTSJB  LA    R6,4(,R6)      POINT TO NEXT HAVT POINTER
         DROP  R1,R5
         BCT   R7,BLDMSG      TEST FOR NEXT HAVT POINTER
***********************************************************************
*                                                                     *
*        END IT ALL                                                   *
*                                                                     *
***********************************************************************
END      QSTOP
NOHAVT   QTILT '***** NO JOBS TO DISPLAY *****'
BADPARM  QTILT '***** INVALID OPERAND *****'                     GP/MAH
INITHD   DC    CL80'      QUEUE  JOBNAME   JOB#  STEPNAME PROCSTEP  FRA*
               MES    TCB-TIME    SRB-TIME'
ED5      DC    X'402020202120'
EDCPU    DC    X'4020206B2021204B2020'
         LTORG
***********************************************************************
*                                                                     *
*        DESCRIBE ALL THE DSECTS NEEDED BY THIS MODULE                *
*                                                                     *
***********************************************************************
SYMDEL   DSECT ,                   KILL SYM CARD GENERATION       UF023
ACTIVE   CSECT ,                                                  UF023
         $CVT
         $JESCT
         $SSCT
         $SVT
         $ASVT
         $ASCB
         $CSCB
         $DEB                                                     UF021
         $SJB
         $JQE
         QCOMMON
         ORG   QDMSG
         DS    CL4
QUEUE    DS    CL8
         DS    C
JOBNAME  DS    CL8
         DS    C
JOBNUM   DS    CL6
         DS    C
STEPNAME DS    CL8
         DS    C
PROCSTEP DS    CL8
         DS    C
SLOTS    DS    CL7
         DS    C
TCBTIME  DS    CL11
         DS    C
SRBTIME  DS    CL11
         DS    C
WORK     DSECT
         DS    CL80
CONVERT  DS    D
DATYPE   DS    X                   DISPLAY TYPE REQUIRED         GP/MAH
DAJ      EQU   X'01'                 ACTIVE JOBS                 GP/MAH
DAS      EQU   X'02'                 ACTIVE STARTED TASKS        GP/MAH
DAT      EQU   X'04'                 ACTIVE TSO USERS            GP/MAH
SYMNODEL DSECT ,                   RESTORE SYM CARD GENERATION    UF023
         END
./ ADD NAME=ALLOCATE 8000-02173-02173-1642-00078-00078-00000-GREG
ALLOCATE QSTART 'QUEUE COMMAND - DATASET ALLOCATION ROUTINES'
         USING QDAIR,R10      BASE REG FOR DAIR WORK
         L     R10,QVDAIR     LOAD ADDR OF DAIR WORK
         USING QCKPT,R9       BASE REG FOR CKPT WORK ARES
         L     R9,QVCKPT      LOAD ADDR
***********************************************************************
*                                                                     *
*   DETERMINE FUNCTION                                                *
*                                                                     *
***********************************************************************
         CLI   DAIRFLAG,X'08' IS THE FUNCTION ALLOCATE?
         BE    ALLOC          YES. DO IT.
         CLI   DAIRFLAG,X'18' IS THE FUNCTION FREE?
         BE    FREE           YES. DO IT.
         B     ABEND99        INVALID FUNCTION. ABANDON SHIP.
***********************************************************************
*                                                                     *
*   FREE DDNAME(XXXXXXXX)                                             *
*                                                                     *
***********************************************************************
FREE     LA    R1,DA18CD      LOAD ADDR OF FREE PARM LIST
         ST    R1,DAPLDAPB    STORE IN DAIR CALL LIST
         BAL   R2,CALLDAIR    CALL DAIR
         B     STOP           RETURN TO CALLER
***********************************************************************
*                                                                     *
*   ALLOC DDNAME(XXXXXXXX) DSNAME(YYYYYYYY) SHR                       *
*                                                                     *
***********************************************************************
ALLOC    MVC   DA18DDN,DA08DDN MOVE DDNAME TO FREE LIST
         LA    R1,DA18CD      LOAD ADDR OF FREE PARM LIST
         ST    R1,DAPLDAPB    STORE IN DAIR CALL LIST
         BAL   R2,CALLDAIR    CALL DAIR - FREE THE DDNAME
         LA    R1,DA08CD      LOAD ADDR OF ALLOC PARM LIST
         ST    R1,DAPLDAPB    STORE IN DAIR CALL LIST
         BAL   R2,CALLDAIR    CALL DAIR - ALLOCATE THE DATASET
         B     STOP           RETURN TO CALLER
***********************************************************************
*                                                                     *
*   RETURN TO CALLING ROUTINE                                         *
*                                                                     *
***********************************************************************
STOP     QSTOP
***********************************************************************
*                                                                     *
*   CALL DYNAMIC ALLOCATION INTERFACE ROUTINE (DAIR)                  *
*                                                                     *
***********************************************************************
CALLDAIR XC    DAIRECB,DAIRECB CLEAR ECB
         LA    R1,DAPLUPT     LOAD ADDR OF DAIR CALL LIST
         LINK  EP=IKJEFD00    CALL DAIR
         LTR   R15,R15        IS RETURN CODE ZERO?
         BZR   R2             YES. RETURN.
         CH    R15,=H'28'     IS DATASET ALREADY FREE?
         BER   R2             YES. RETURN.
         CLC   DA08DDN,=C'HASPSAVE' IS THIS A SAVE?
         BNE   ABEND99        NO. ABEND.
         QTILT '*** UNABLE TO ALLOCATE DATASET ***'
***********************************************************************
*                                                                     *
*   DAIR HAS FAILED. TAKE A PICTURE AND GO HOME.                      *
*                                                                     *
***********************************************************************
ABEND99  LA    R1,MESSAGE     POINT TO THE MESSAGE                GP@P6
         LA    R0,L'MESSAGE   SET MESSAGE LENGTH                  GP@P6
         TPUT  (1),(0),R      TELL SAD STORY                 GP@P6 PWF*
         ABEND 99,DUMP        ABEND THE JOB. USER CODE 0099.
***********************************************************************
*                                                                     *
*   CONSTANTS AND ASSORTED GARBAGE                                    *
*                                                                     *
***********************************************************************
         LTORG
MESSAGE  DC    C'A MAJOR DISASTER HAS OCCURRED IN DAIR PROCESSING.'
SYMDEL   DSECT ,                   KILL SYM CARD GENERATION       UF023
         QCOMMON
SYMNODEL DSECT ,                   RESTORE SYM CARD GENERATION    UF023
         END
./ ADD NAME=BLD3270  8011-02173-03046-0345-00181-00229-00000-GREG
BLD3270  QSTART 'QUEUE COMMAND - BUILD 3270 DATA STREAM'
***********************************************************************
*                                                                     *
*   WRITTEN BY GREG PRICE OF PRYCROFT SIX PTY LTD IN JUNE 2002.       *
*                                                                     *
*   THE PURPOSE OF THIS ROUTINE IS TO BUILD A 3270 DATA STREAM FROM   *
*   THE DISPLAY BUFFER AND ITS SHADOW BUFFER.  THE BUFFERS CONTAIN    *
*   ONE BYTE EACH PERTAINING TO EACH SCREEN LOCATION.                 *
*                                                                     *
*   THE PRIMARY BUFFER CONTAINS THE TEXT TO BE SHOWN ON THE SCREEN    *
*   PLUS INTERNAL CODES FOR EACH FIELD ATTRIBUTE BYTE.                *
*                                                                     *
*   THE SHADOW BUFFER CONTAINS INTERNAL CODES FOR THE CHARACTER       *
*   ATTRIBUTES OF THE DISPLAYABLE TEXT.  IT IS DATA FROM THE SHADOW   *
*   BUFFER THAT CAUSES 3270 EXTENDED DATA STREAM ORDERS TO BE         *
*   GENERATED.  TO REMOVE 3270 EDS ORDERS FROM THE GENERATED OUTPUT   *
*   ONE SIMPLY HAS TO IGNORE THE SHADOW BUFFER IN THIS ROUTINE        *
*   WITHOUT CHANGING ANY OTHER QUEUE COMMAND SUBROUTINE.              *
*                                                                     *
*   THE ONLY EDS ORDER THAT CAN BE GENERATED HERE IS SET ATTRIBUTE    *
*   (SA) AND ONLY COLOUR AND EXTENDED HIGHLIGHTING ARE USED.          *
*                                                                     *
*   APL CHARACTERS AND/OR GRAPHIC ESCAPE ORDERS ARE NOT USED.         *
*                                                                     *
*   START FIELD EXTENDED (SFE) CANNOT BE USED BECAUSE THE TSO/VTAM    *
*   SHIPPED IN THE AVAILABLE MVS 3.8J DISTRIBUTION DOES NOT SUPPORT   *
*   A 'NOEDIT' TPUT.  A 'FULLSCR' TPUT WILL NOT TRANSMIT THE SFE      *
*   ATTRIBUTE PAIR COUNT UNALTERED, THUS CORRUPTING THE DATA STREAM.  *
*                                                                     *
*   THE SHADOW BUFFER BYTE CORRESPONDING TO A FIELD ATTRIBUTE BYTE    *
*   IS IGNORED.                                                       *
*                                                                     *
*   A NULL IN THE SHADOW BUFFER RESETS EXTENDED HIGHLIGHTING.         *
*                                                                     *
*   FIELD ATTRIBUTE INTERNAL CODES ARE:                               *
*         0A - UNPROTECTED, LOW INTENSITY                             *
*         0B - UNPROTECTED, HIGH INTENSITY                            *
*         0C - PROTECTED, LOW INTENSITY                               *
*         0D - PROTECTED, HIGH INTENSITY                              *
*         0D - PROTECTED, HIGH INTENSITY                              *
*         0E - UNPROTECTED, INVISIBLE                                 *
*         0F - PROTECTED, INVISIBLE                                   *
*                                                                     *
*   CHARACTER ATTRIBUTE INTERNAL CODES ARE OF THE FORM YZ             *
*   WHERE THE VALUES OF Y ARE:                                        *
*          0 - NO EXTENDED HIGHLIGHTING                               *
*          1 - BLINKING                                               *
*          2 - REVERSE VIDEO                                          *
*          3 - UNDERSCORE                                             *
*   AND THE VALUES OF Z ARE:                                          *
*          1 - BLUE                                                   *
*          2 - RED                                                    *
*          3 - PINK                                                   *
*          4 - GREEN                                                  *
*          5 - TURQUOISE                                              *
*          6 - YELLOW                                                 *
*          7 - WHITE                                                  *
*                                                                     *
***********************************************************************
         USING WORK,R13            WORKING STORAGE
         L     R10,QVDSPL          ADDR OF DISPLAY WORK AREA
         USING QDISPLAY,R10        BASE REG FOR DISPLAY WORK AREA
***********************************************************************
*                                                                     *
*   LOCATE BUFFERS AND COPY "HEADER"                                  *
*                                                                     *
***********************************************************************
         LA    R2,QDSCREEN         POINT TO SOURCE
         L     R4,QDCBPRM3         POINT TO TARGET
         MVC   0(6,R4),0(R2)       COPY DATA STREAM "HEADER"
         LA    R4,6(,R4)           ADJUST TARGET POINTER
         LA    R2,QDSCRTXT         POINT TO PRIMARY BUFFER
         L     R3,QDSHADO@         POINT TO SHADOW BUFFER
         L     R9,QDSCRPLN         GET BYTES TO PROCESS
         MVI   CRNTHLIT,0          RESET HIGHLIGHT STATUS
         MVI   CRNTCOLR,0          RESET COLOUR STATUS
         MVI   CRNTCODE,0          RESET INTERNAL CODE "CACHE"
         SLR   R1,R1               CLEAR FOR INSERT
***********************************************************************
*                                                                     *
*   LOOP THROUGH EACH SCREEN LOCATION                                 *
*                                                                     *
***********************************************************************
BLDLOOP  CLI   0(R2),X'0A'         FIELD ATTRIBUTE CODE?
         BL    SHADOCHK            NO
         CLI   0(R2),X'0F'         FIELD ATTRIBUTE CODE?
         BH    SHADOCHK            NO
         MVI   0(R4),X'1D'         YES, SUPPLY START FIELD
         LA    R4,1(,R4)           ADJUST POINTER
         IC    R1,0(,R2)           LOAD INTERNAL CODE
         LA    R15,SFCODES-10(R1)  POINT TO ATTRIBUTE BYTE TO LOAD
         MVC   0(1,R4),0(R15)      LOAD IT
         B     NEXTBYTE            THIS BUFFER LOCATION NOW PROCESSED
SHADOCHK TM    QFLAG2,QFLG2EDS     USING EXTENDED DATA STREAM ORDERS?
         BNO   COPYBYTE            NO, DO NOT REFERENCE SHADOW BUFFER
         CLC   CRNTCODE,0(R3)      SAME SHADOW CODE AS LAST TIME?
         BE    COPYBYTE            YES, A 'CACHE" HIT
         MVC   CRNTCODE,0(R3)      NO, COPY THE NEW VALUE
         UNPK  WORKCODE,CRNTCODE   GET NEW HIGHLIGHT SETTING
         NI    WORKCODE,X'03'      FOLD INTO VALID RANGE
         CLC   CRNTHLIT,WORKCODE   HAS IT CHANGED?
         BE    COLORCHK            NO
         MVC   CRNTHLIT,WORKCODE   YES, UPDATE IT
         MVI   0(R4),X'28'         SET ATTRIBUTE
         MVI   1(R4),X'41'         EXTENDED HIGHLIGHTING
         MVC   2(1,R4),CRNTHLIT    COPY INTERNAL CODE
         TR    2(1,R4),TABLHLIT    CONVERT TO 3270 ORDER CODE
         LA    R4,3(,R4)           POINT PAST SA ORDER
COLORCHK MVC   WORKCODE,CRNTCODE   GET NEW COLOUR SETTING
         NI    WORKCODE,X'07'      FOLD INTO VALID RANGE
         BZ    COPYBYTE            LEAVE COLOUR UNCHANGED IF NULL
         CLC   CRNTCOLR,WORKCODE   HAS IT CHANGED?
         BE    COPYBYTE            NO
         MVC   CRNTCOLR,WORKCODE   YES, UPDATE IT
         MVI   0(R4),X'28'         SET ATTRIBUTE
         MVI   1(R4),X'42'         EXTENDED COLOUR
         MVC   2(1,R4),CRNTCOLR    COPY INTERNAL CODE
         TR    2(1,R4),TABLCOLR    CONVERT TO 3270 ORDER CODE
         LA    R4,3(,R4)           POINT PAST SA ORDER
COPYBYTE MVC   0(1,R4),0(R2)       COPY TEXT BYTE
NEXTBYTE LA    R4,1(,R4)           POINT PAST COPIED BYTE
         LA    R3,1(,R3)           POINT TO NEXT SHADOW BUFFER BYTE
         LA    R2,1(,R2)           POINT TO NEXT PRIMARY BUFFER BYTE
         BCT   R9,BLDLOOP          GO PROCESS NEXT SCREEN BYTE
***********************************************************************
*                                                                     *
*   APPEND ORDER TO PLACE CURSOR                                      *
*                                                                     *
***********************************************************************
         MVI   0(R4),X'11'         SET BUFFER ADDRESS
         L     R1,QDSCRPLN         GET SCREEN SIZE
         SH    R1,QDLNELEN         GET OFFSET OF LAST LINE
         LA    R1,8(,R1)           GET OFFSET OF INPUT AREA
         STCM  R1,3,1(R4)          SAVE 14-BIT ADDRESS
         TM    1(R4),X'F0'         PAST LOCATION 4095?
         BNZ   CSRADROK            YES, USE 14-BIT ADDRESS, NOT 12-BIT
         SRL   R1,6                GET HIGH-ORDER SIX BITS
         STC   R1,1(,R4)           SAVE HIGH SIX BITS
         NI    2(R4),X'3F'         GET LOW SIX BITS
         TR    1(2,R4),TABLADDR    CONVERT TO 3270 12-BIT ADDRESS CODE
CSRADROK MVI   3(R4),X'13'         INSERT CURSOR
         LA    R4,4(,R4)           POINT PAST END OF DATA STREAM
***********************************************************************
*                                                                     *
*   CALL CB3270 TO REDUCE DATA STREAM LENGTH WITH 3270 COMPRESSION    *
*                                                                     *
***********************************************************************
         S     R4,QDCBPRM3         GET THE DATA STREAM LENGTH
         ST    R4,QDLENGTH         SAVE IT
         LA    R1,QDCBPRM1         POINT TO PARAMETER LIST
         L     R15,=V(CB3270)      GET COMPRESSION ROUTINE ENTRY POINT
         BALR  R14,R15             COMPRESS IN PLACE - QDLENGTH UPDATED
***********************************************************************
*                                                                     *
*   RETURN TO CALLER                                                  *
*                                                                     *
***********************************************************************
         QSTOP
***********************************************************************
*                                                                     *
*   MISCELLANY                                                        *
*                                                                     *
***********************************************************************
         LTORG
TABLADDR DC    X'40C1C2C3C4C5C6C7C8C94A4B4C4D4E4F'
         DC    X'50D1D2D3D4D5D6D7D8D95A5B5C5D5E5F'
         DC    X'6061E2E3E4E5E6E7E8E96A6B6C6D6E6F'
         DC    X'F0F1F2F3F4F5F6F7F8F97A7B7C7D7E7F'
TABLHLIT DC    X'00F1F2F4'         NORMAL, BLINK, REVERSE, UNDERSCORE
TABLCOLR DC    X'00F1F2F3F4F5F6F7' ZAP THIS TO PREFERRED COLOUR SCHEME
SFCODES  DC    X'40C860E84C7C'     NO AUTOSKIP          22NOV2002 GP@P6
SYMDEL   DSECT ,                   KILL SYM CARD GENERATION       UF023
         QCOMMON
WORK     DSECT
         DS    CL80
CRNTHLIT DS    X
CRNTCOLR DS    X
CRNTCODE DS    X
WORKCODE DS    X
SYMNODEL DSECT ,                   RESTORE SYM CARD GENERATION    UF023
         END
./ ADD NAME=C        8026-02153-02308-1936-00075-00067-00000-GREG
//GREGQ    JOB (QUEUE),G.PRICE,CLASS=A,MSGCLASS=A,REGION=3072K,
//             COND=(0,NE),NOTIFY=GREG
//ASMLQUE PROC M=MISSING,SP='NOSP,NODEBUG',TEST=NOTEST
//ASM     EXEC PGM=IFOX00,
//             PARM='DECK,NOLOAD,TERM,&TEST,SYSPARM((&SP))'
//SYSLIB   DD  DISP=SHR,DSN=GREG.QUEUE.ASM
//         DD  DISP=SHR,DSN=SYS1.HASPSRC
//         DD  DISP=SHR,DSN=SYS1.MACLIB
//         DD  DISP=SHR,DSN=SYS1.AMODGEN
//SYSUT1   DD  SPACE=(CYL,(25,5)),UNIT=VIO
//SYSUT2   DD  SPACE=(CYL,(25,5)),UNIT=VIO
//SYSUT3   DD  SPACE=(CYL,(25,5)),UNIT=VIO
//SYSTERM  DD  SYSOUT=*
//SYSPRINT DD  SYSOUT=*
//SYSIN    DD  DISP=SHR,DSN=GREG.QUEUE.ASM(&M)
//SYSPUNCH DD  DISP=SHR,DSN=GREG.QUEUE.OBJ(&M)
//        PEND
//Q00     EXEC ASMLQUE,M=QUEUECMN
//Q01     EXEC ASMLQUE,M=QUEUE
//Q02     EXEC ASMLQUE,M=ALLOCATE
//Q03     EXEC ASMLQUE,M=CKPT
//Q04     EXEC ASMLQUE,M=DDNAME
//Q05     EXEC ASMLQUE,M=DISPLAY
//Q06     EXEC ASMLQUE,M=FINDJOB
//Q07     EXEC ASMLQUE,M=FORMAT
//Q08     EXEC ASMLQUE,M=HELP
//Q09     EXEC ASMLQUE,M=HEXBLK
//Q10     EXEC ASMLQUE,M=INIT
//Q11     EXEC ASMLQUE,M=JCL
//Q12     EXEC ASMLQUE,M=JLOG
//Q13     EXEC ASMLQUE,M=JMSG
//Q14     EXEC ASMLQUE,M=LIST
//Q15     EXEC ASMLQUE,M=LISTDS
//Q16     EXEC ASMLQUE,M=PARSE
//Q17     EXEC ASMLQUE,M=READSPC
//Q18     EXEC ASMLQUE,M=REPOS
//Q19     EXEC ASMLQUE,M=CSAVE
//Q20     EXEC ASMLQUE,M=SEARCH
//Q21     EXEC ASMLQUE,M=SYSLOG
//Q22     EXEC ASMLQUE,M=XDS
//Q23     EXEC ASMLQUE,M=INITS
//Q24     EXEC ASMLQUE,M=ACTIVE
//Q25     EXEC ASMLQUE,M=FINDPDDB
//Q26     EXEC ASMLQUE,M=SYSOUT
//Q27     EXEC ASMLQUE,M=PRINT
//Q28     EXEC ASMLQUE,M=HEXDUMP
//Q29     EXEC ASMLQUE,M=CJQE
//Q30     EXEC ASMLQUE,M=CJCT
//Q31     EXEC ASMLQUE,M=CTSO
//Q32     EXEC ASMLQUE,M=CHCT
//Q33     EXEC ASMLQUE,M=CPDDB
//Q34     EXEC ASMLQUE,M=CJOE
//Q35     EXEC ASMLQUE,M=BLD3270
//Q36     EXEC ASMLQUE,M=CB3270
//Q37     EXEC ASMLQUE,M=CSPIN
//Q38     EXEC ASMLQUE,M=NEXT
//LKED    EXEC PGM=IEWL,PARM='XREF,LIST,LET,AC=1'
//SYSLMOD  DD  DSN=SYS2.CMDLIB,DISP=SHR
//SYSUT1   DD  UNIT=VIO,SPACE=(CYL,(8,1))
//SYSPRINT DD  SYSOUT=*
//SYSLIB   DD  DISP=SHR,DSN=GREG.QUEUE.OBJ
//SYSLIN   DD  *
 INCLUDE SYSLIB(QUEUECMN,QUEUE,ALLOCATE,CKPT,DDNAME)
 INCLUDE SYSLIB(DISPLAY,FINDJOB,FORMAT,HELP,HEXBLK,INIT)
 INCLUDE SYSLIB(JCL,JLOG,JMSG,LIST,LISTDS,PARSE,READSPC)
 INCLUDE SYSLIB(REPOS,CSAVE,SEARCH,SYSLOG,XDS,INITS)
 INCLUDE SYSLIB(ACTIVE,FINDPDDB,SYSOUT,PRINT,HEXDUMP)
 INCLUDE SYSLIB(CJQE,CJCT,CTSO,CHCT,CPDDB,CJOE,BLD3270)
 INCLUDE SYSLIB(CB3270,CSPIN,NEXT)
 ENTRY QUEUE
 ALIAS QUEUE
 ALIAS QUE
 NAME Q(R)
/*
//
./ ADD NAME=CB3270   8002-02173-03046-0351-00190-00188-00000-GREG
         TITLE 'CB3270 - COMPRESS A 3270 OUTPUT BUFFER - HMD 04/79'
***********************************************************************
*                                                                     *
*        CSECT CB3270 PERFORMS THE FOLLOWING:                         *
*                                                                     *
*        1 - COMPRESSES A 3270 TPUT BUFFER                            *
*                                                                     *
*            FIVE OR MORE CONSECUTIVE IDENTICAL CHARACTERS ARE        *
*            REPLACED BY A 4 BYTE REPEAT TO ADDRESS (RA) ORDER.       *
*                                                                     *
*            A SET BUFFER ADDRESS (SBA) ORDER TO THE CURRENT          *
*            SCREEN ADDRESS IS DELETED.                               *
*                                                                     *
*            PARAMETERS REQUIRED:                                     *
*                                                                     *
*            A THREE WORD PARAMETER LIST IS PROVIDED.                 *
*                                                                     *
*            WORD 1 - POINTS TO A FULL WORD CONTAINING THE LENGTH     *
*                     OF THE UNCOMPRESSED INPUT STRING.  ON EXIT      *
*                     THE WORD WILL CONTAIN THE LENGTH OF THE         *
*                     COMPRESSED OUTPUT STRING.                       *
*                                                                     *
*            WORD 2 - POINTS TO A FULL WORD CONTAINING THE NUMBER     *
*                     OF SCREEN LINES.  *** NOW CHANGED ***           *
*                     NOW IT POINTS TO A FULLWORD CONTAINING THE      *
*                     NUMBER OF SCREEN LOCATIONS.  THIS CHANGE        *
*                     MAKES THE ROUTINE SCREEN WIDTH INDEPENDENT.     *
*                     GREG PRICE, PRYCROFT SIX P/L.  JUNE 2002        *
*                                                                     *
*            WORD 3 - POINTS TO THE BEGINNING OF THE INPUT STRING.    *
*                                                                     *
*            WORD 4 - POINTS TO THE BEGINNING OF THE OUTPUT AREA.     *
*                     FOR AN "IN PLACE" COMPRESSION, SPECIFY THE      *
*                     ADDRESS OF THE INPUT STRING FOR BOTH THE        *
*                     INPUT AND OUTPUT AREAS.                         *
*                                                                     *
*            CSECT ATTRIBUTES - RENT, REFR                            *
*                                                                     *
***********************************************************************
         EJECT
CB3270   CSECT
         SPACE
         SAVE  (14,12),,CB3270_HMD_ASSEMBLED_&SYSDATE
         LR    R12,R15                 COPY ENTRY ADDRESS
         USING CB3270,R12              DEFINE BASE REGISTER
         LR    R4,R1                   SAVE PARM LIST ADDRESS
         L     R3,0(R4)                LOAD ADDRESS OF LENGTH
         L     R11,0(R3)               LOAD LENGTH
         L     R9,8(R4)                LOAD INPUT ADDRESS
         LA    R11,0(R11,R9)           GET END OF INPUT ADDRESS
         BCTR  R11,0
         L     R8,12(R4)               LOAD OUTPUT AREA ADDRESS
         LR    R5,R8                   SAVE ADDRESS
         L     R2,4(R4)
         L     R2,0(R2)
*        MH    R2,=H'80'   DO NOT DO - SCREEN SIZE - NOT LINE COUNT
         LA    R6,0                    INITIALIZE SCREEN ADDRESS
*
TESTORDR CLI   0(R9),IC                TEST FOR INSERT CURSOR
         BE    COPY1
         CLI   0(R9),PT                TEST FOR PROGRAM TAB
         BE    COPY1
         CLI   0(R9),SF                TEST FOR START FIELD
         BE    COPY2
         CLI   0(R9),SA                TEST FOR SET ATTRIBUTE
         BE    COPY3X
         CLI   0(R9),SFE               TEST FOR START FIELD EXTENDED
         BE    COPYX
         CLI   0(R9),SBA               TEST FOR SET BUFFER ADDRESS
         BE    COPY3
         CLI   0(R9),EUA               TEST FOR ERASE UNPROTECTED
         BE    COPY3
         CLI   0(R9),RA                TEST FOR REPEAT TO ADDRESS
         BE    COPY4
*
         LA    R10,1                   SET INCREMENT TO 1
         LR    R7,R9                   SAVE ADDRESS OF FIRST CHAR
TESTNEXT LA    R6,1(R6)                INCREMENT SCREEN ADDRESS
         BXH   R9,R10,ENDBUF           INCREMENT TO NEXT CHAR
         CLC   0(1,R7),0(R9)           SEE IF SAME CHARACTER
         BE    TESTNEXT                IF SAME, LOOP
*
ENDBUF   LR    R1,R9                   ADDRESS OF CURRENT CHAR
         SR    R1,R7                   NUMBER OF SAME CHARACTERS
         C     R1,=F'4'                AT LEAST 4 FOR RA
         BH    BUILDRA
         BCTR  R1,0                    SUBTRACT 1 FOR EXECUTE
         EX    R1,COPY                 COPY TO OUTPUT AREA
         LA    R8,1(R1,R8)             INCREMENT OUTPUT ADDRESS
         CR    R9,R11                  SEE IF ANY MORE
         BH    OUT
         B     TESTORDR
*
BUILDRA  MVC   3(1,R8),0(R7)           COPY CHARACTER
         MVI   0(R8),RA                MOVE IN RA ORDER CODE
         CR    R6,R2
         BL    GETADDR
         SR    R6,R2
GETADDR  STCM  R6,3,1(R8)
         TM    1(R8),X'F0'             LOCATION OVER 4095?
         BNZ   GOTADDR                 YES, USE 14-BIT ADDRESS
         SR    R14,R14                 CONVERT SCREEN ADDRESS TO
         LR    R15,R6                       3270 ADDRESS CODE
         SLDL  R14,26
         SRL   R15,26
         IC    R14,TABLE(R14)
         IC    R15,TABLE(R15)
         STC   R14,1(R8)
         STC   R15,2(R8)
GOTADDR  LA    R8,4(R8)                INCREMENT OUTPUT AREA ADDRESS
         CR    R9,R11                  SEE IF ANY MORE
         BH    OUT
         B     TESTORDR
*
COPY1    LA    R10,1                   SET COUNT
         B     COPYDATA
COPYX    SLR   R10,R10                 CLEAR FOR INSERT
         IC    R10,1(R9)               GET ATTRIBUTE PAIR COUNT
         LA    R10,1(R10)              COUNT SFE,COUNT AS A PAIR
         SLA   R10,1                   GET THE BYTE COUNT
         B     COPYATTR
COPY2    LA    R10,2                   SET COUNT
COPYATTR LA    R6,1(R6)                INCREMENT SCREEN ADDR FOR ATTR
         B     COPYDATA
COPY3X   LA    R10,3                   SET COUNT
         B     COPYDATA
COPY3    LA    R10,3                   SET COUNT
         B     UPDATADR
COPY4    LA    R10,4                   SET COUNT
UPDATADR IC    R15,1(R9)               CONVERT ADDRESS TO SCREEN POS.
         SLL   R15,8
         IC    R15,2(R9)
         SLDL  R14,24
         SLL   R15,2
         SRDL  R14,6
         SRL   R15,20
         CR    R6,R15                  SEE IF ALREADY AT THIS ADDRESS
         BNE   RESETADR
         CLI   0(R9),SBA               IF ORDER IS SBA, SKIP IT
         BE    INCRPTR
RESETADR LR    R6,R15                  UPDATE SCREEN ADDRESS
*
COPYDATA BCTR  R10,0                   DECREMENT COUNT FOR EXECUTE
         LR    R7,R9                   COPY SOURCE ADDRESS
         EX    R10,COPY                COPY TO OUTPUT AREA
         LA    R10,1(R10)              RESTORE COUNT
         LA    R8,0(R10,R8)            UPDATE OUTPUT AREA ADDRESS
INCRPTR  BXLE  R9,R10,TESTORDR         INCREMENT ADDRESS AND LOOP
*
OUT      SR    R8,R5                   CALCULATE OUTPUT LENGTH
         LA    R8,0(0,R8)              TURN OFF HIGH BIT
         ST    R8,0(R3)                STORE NEW LENGTH
         SR    R15,R15                 CLEAR RETURN CODE
         RETURN (14,12),RC=(15)
*
         LTORG
*
COPY     MVC   0(0,R8),0(R7)           << EXECUTED INSTRUCTION >>
*
TABLE    DC    X'40C1C2C3C4C5C6C7C8C94A4B4C4D4E4F'
         DC    X'50D1D2D3D4D5D6D7D8D95A5B5C5D5E5F'
         DC    X'6061E2E3E4E5E6E7E8E96A6B6C6D6E6F'
         DC    X'F0F1F2F3F4F5F6F7F8F97A7B7C7D7E7F'
*
R0       EQU   0
R1       EQU   1
R2       EQU   2
R3       EQU   3
R4       EQU   4
R5       EQU   5
R6       EQU   6
R7       EQU   7
R8       EQU   8
R9       EQU   9
R10      EQU   10
R11      EQU   11
R12      EQU   12
R13      EQU   13
R14      EQU   14
R15      EQU   15
*
IC       EQU   X'13'
PT       EQU   X'05'
SF       EQU   X'1D'
SA       EQU   X'28'
SFE      EQU   X'29'
SBA      EQU   X'11'
EUA      EQU   X'12'
RA       EQU   X'3C'
         END
./ ADD NAME=CHCT
CHCT     QSTART 'QUEUE COMMAND - DUMP A HCT IN HEX'               UF022
***********************************************************************
* HCT                                                                 *
***********************************************************************
*                                                                     *
*   CALL - READ JES2 CHECKPOINT ROUTINE                               *
*                                                                     *
***********************************************************************
         L     R15,=V(CKPT)        ADDR OF CKPT ROUTINE
         BALR  R14,R15             GO TO IT
***********************************************************************
*                                                                     *
*   CALL HEXDUMP TO DUMP THE HCT CHECKPOINT AREA                      *
*                                                                     *
***********************************************************************
         L     R10,QVCKPT     BASE FOR CKPT WORK AREA
         USING QCKPT,R10      ADDRESSING FOR IT
         L     R1,QCJQTL      ADDRESS OF HCT SAVEAREA
         LA    R0,$SAVEBEG-HCTDSECT  OFFSET TO START OF AREA
         LA    R15,$SAVELEN   LENGTH OF $SAVEAREA
         SLL   R0,16          MOVE OFFSET TO PROPER POSITION
         OR    R0,R15         INSERT INTO LENGTH REG
         L     R15,=V(HEXDUMP) ADDRESS OF DUMP ROUTINE
         BALR  R14,R15        LINK TO IT
STOP     QSTOP
***********************************************************************
*                                                                     *
*   MISCELLANY                                                        *
*                                                                     *
***********************************************************************
         LTORG
SYMDEL   DSECT ,                   KILL SYM CARD GENERATION       UF023
         QCOMMON
CHCT     CSECT
         DROP
JCT      EQU   10
BASE1    EQU   11
SAVE     EQU   13
         GBLC  &VERSION
&VERSION SETC  '0'
$RPS     EQU   0
$MSGID   EQU   0
$DUPVOLT EQU   0
$PRIOOPT EQU   0
$PRTBOPT EQU   0
$PRTRANS EQU   0
$QSONDA  EQU   0
$CMBDEF  EQU   0
$JQEDEF  EQU   0
$MAXDA   EQU   32
$MAXJBNO EQU   0
$SMFDEF  EQU   0
$TGDEF   EQU   0
FF       EQU   255
        $BUFFER
        $JCT
        $CAT
        $JQE
        $PCE
        $HCT
SYMNODEL DSECT ,                   RESTORE SYM CARD GENERATION    UF023
         END
./ ADD NAME=CJCT
CJCT     QSTART 'QUEUE COMMAND - DUMP A JCT IN HEX'               UF016
***********************************************************************
* JCT JOBNAME <OFFSET>                                                *
***********************************************************************
*                                                                     *
*   CALL FINDJOB TO LOCATE THE JCT                                    *
*                                                                     *
***********************************************************************
         L     R15,=V(FINDJOB) ADDR OF MODULE TO FIND JOB
         BALR  R14,R15        GO TO IT
***********************************************************************
*                                                                     *
*   CALL HEXDUMP TO DUMP THE JCT                                      *
*                                                                     *
***********************************************************************
         L     R10,QVCKPT     BASE FOR CKPT WORK AREA
         USING QCKPT,R10      ADDRESSING FOR IT
         L     R1,QCJCTA      ADDRESS OF JCT
         LA    R0,JCTSTART-JCTDSECT  OFFSET TO START OF JCT
         SR    R1,R0          BACK UP TO PREFIX
         LH    R15,QLNG2      LENGTH OF USER OFFSET INTO JCT
         LTR   R15,R15        IS THE LENGTH ZERO?
         BNP   DUMP0          YES. NONE SPECIFIED
         CH    R15,=H'8'      IS THE LENGTH TOO BIG?
         BH    TILTO          YES, GIVE UP
         EX    R15,OFFTR      CONVERT TO HEX
         EX    R15,OFFPACK    PACK INTO QDWORD
         LH    R15,QDWORD     PICK UP OFFSET
         CR    R0,R15         COMPARE TO BASE OFFSET
         BNL   DUMP0          USE R0 FOR OFFSET
         LR    R0,R15         GET OTHER OFFSET
DUMP0    AR    R1,R0          ADD TO BASE ADDRESS
         LH    R15,HASPACE+62 MAX LEN INCLUDING NETWORK HEADERS
         LA    R15,JCTSTART-JCTDSECT(R15)  + LEN OF PREFIX
         SR    R15,R0         TOTAL LENGTH - OFFSET = LENGTH TO DUMP
         SLL   R0,16          MOVE OFFSET TO PROPER POSITION
         OR    R0,R15         INSERT INTO LENGTH REG
         L     R15,=V(HEXDUMP) ADDRESS OF DUMP ROUTINE
         BALR  R14,R15        LINK TO IT
STOP     QSTOP
***********************************************************************
*                                                                     *
*   EXCEPTIONS AND RETURN                                             *
*                                                                     *
***********************************************************************
TILTO    QTILT '*** INVALID OFFSET SPECIFIED ***'
***********************************************************************
*                                                                     *
*   MISCELLANY                                                        *
*                                                                     *
***********************************************************************
OFFTR    TR    QPARM2,TABLEH       CONVERT TO HEX
OFFPACK  PACK  QDWORD(3),QPARM2(1) PACK TO WORK AREA
         LTORG
* TABLE FOR HEX CONVERT
TABLEH   DC    CL193' '
         DC    X'0A0B0C0D0E0F',CL41' ',C'01234567890',CL6' '
SYMDEL   DSECT ,                   KILL SYM CARD GENERATION       UF023
CJCT     CSECT ,                                                  UF023
        $BUFFER
        $JQE
JCT      EQU   0
        $JCT
         QCOMMON
SYMNODEL DSECT ,                   RESTORE SYM CARD GENERATION    UF023
         END
./ ADD NAME=CJOE     8004-02215-02216-0028-00094-00079-00000-GREG
CJOE     QSTART 'QUEUE COMMAND - DUMP A JOE IN HEX'               UF026
***********************************************************************
*                                                                     *
*   CALL FINDJOB TO LOCATE THE JQE                                    *
*                                                                     *
***********************************************************************
FINDJQE  L     R15,=V(FINDJOB) ADDR OF MODULE TO FIND JOB
         BALR  R14,R15        GO TO IT
***********************************************************************
*                                                                     *
*   CALL HEXDUMP TO DUMP THE JOES                                     *
*                                                                     *
***********************************************************************
         L     R10,QVCKPT     BASE FOR CKPT WORK AREA
         USING QCKPT,R10      ADDRESSING FOR IT
         L     R1,QCJQEA      ADDRESS OF JQE
         USING JQEDSECT,R1    ADDRESSING FOR JQE
         SR    R2,R2          CLEAR WORK REG
         ICM   R2,3,JQEJOE    OFFSET/4 TO FIRST WORK JOE          GP@P6
         BNZ   JOELOOP        CONTINUE IF ANY
JOETILT  QTILT 'JOB HAS NO JOES'
         DROP  R1             DROP JQE ADDRESSING
         USING JOEDSECT,R2    ADDRESSING FOR JOE
         SPACE 1
JOELOOP  LR    R3,R2          SAVE JOE OFFSET/4 FOR LATER         GP@P6
         SLL   R2,2           MULTIPLY BY 4 TO GET OFFSET         GP@P6
         A     R2,QCJOTA      ADD TO GET ACTUAL ADDRESS
         SLR   R1,R1          CLEAR FOR INSERT                    GP@P6
         ICM   R1,3,JOEJQE    GET OFFSET/4 OF JQE                 GP@P6
         SLL   R1,2           GET OFFSET OF JQE                   GP@P6
         A     R1,QCJQTA      GET JQE ADDRESS                     GP@P6
         C     R1,QCJQEA      DOES JOE BELONG TO THIS JOB?        GP@P6
         BE    JOESHOW        YES, PROCEED WITH DISPLAY           GP@P6
         L     R1,QCJQEA      ADDRESS OF JQE                      GP@P6
         USING JQEDSECT,R1    ADDRESSING FOR JQE                  GP@P6
         CLM   R3,3,JQEJOE    WAS THIS THE FIRST JOE LOOKED AT?   GP@P6
         BE    JOETILT        YES, SO JOB HAD NO JOES             GP@P6
         B     JOESTOP        NO, SO ALL RELEVANT JOES DONE NOW   GP@P6
         DROP  R1             DROP JQE ADDRESSING                 GP@P6
JOESHOW  DS    0H                                                 GP@P6
         LA    R1,MSGJWORK    WORK JOE MESSAGE
         ST    R1,QDMSGA      SAVE MESSAGE ADDRESS
         LA    R1,L'MSGJWORK  LENGTH OF MESSAGE
         STH   R1,QDMLNG      SAVE FOR DISPLAY ROUTINE
         L     R15,=V(DISPLAY) ADDRESS OF DISPLAY ROUTINE
         BALR  R14,R15        LINK TO IT
         LR    R1,R2          POINTER TO JOE TO DUMP
         LA    R0,JOE1END-JOEDSECT ACTUAL LENGTH OF WORK JOE
         L     R15,=V(HEXDUMP) ADDR OF HEXDUMP MODULE
         BALR  R14,R15        GO TO IT
         SPACE 1
         LA    R1,MSGJCHAR    CHAR JOE MESSAGE
         ST    R1,QDMSGA      SAVE MESSAGE ADDRESS
         LA    R1,L'MSGJCHAR  LENGTH OF MESSAGE
         STH   R1,QDMLNG      SAVE FOR DISPLAY ROUTINE
         L     R15,=V(DISPLAY) ADDRESS OF DISPLAY ROUTINE
         BALR  R14,R15        LINK TO IT
         ICM   R1,3,JOECHAR   OFFSET/4 OF CHARACTERISTICS JOE     GP@P6
         SLL   R1,2           MULTIPLY BY 4 TO GET OFFSET         GP@P6
         A     R1,QCJOTA      ADD TO GET ACTUAL ADDRESS
         LA    R0,JOE2END-JOEDSECT ACTUAL LENGTH OF CHAR JOE
         L     R15,=V(HEXDUMP) ADDR OF HEXDUMP MODULE
         BALR  R14,R15        GO TO IT
         SPACE 1
         LA    R1,MSGJCKPT    CKPT JOE MESSAGE
         ST    R1,QDMSGA      SAVE MESSAGE ADDRESS
         LA    R1,L'MSGJCKPT  LENGTH OF MESSAGE
         STH   R1,QDMLNG      SAVE FOR DISPLAY ROUTINE
         ICM   R1,3,JOECKPT   OFFSET/4 OF CKPT JOE                GP@P6
         BZ    NEXTWORK       NONE, GET NEXT WORK JOB FOR THIS JOB
         SLL   R1,2           MULTIPLY BY 4 TO GET OFFSET         GP@P6
         L     R15,=V(DISPLAY) ADDRESS OF DISPLAY ROUTINE
         BALR  R14,R15        LINK TO IT
         A     R1,QCJOTA      ADD TO GET ACTUAL ADDRESS
         LA    R0,JOE3END-JOEDSECT ACTUAL LENGTH OF CKPT JOE
         L     R15,=V(HEXDUMP) ADDR OF HEXDUMP MODULE
         BALR  R14,R15        GO TO IT
         SPACE 1
NEXTWORK ICM   R2,12,JOENEXT  GET NEXT WORK JOE FOR THIS JOB      GP@P6
         SRL   R2,16          MOVE TO LOW ORDER (CLEARS BITS)     GP@P6
         BNZ   JOELOOP          AND DUMP IT
JOESTOP  DS    0H             FINISHED PROCESSING                 GP@P6
         QSTOP
MSGJWORK DC    C'*** WORK JOE ***'
MSGJCHAR DC    C'*** CHAR JOE ***'
MSGJCKPT DC    C'*** CKPT JOE ***'
         LTORG
SYMDEL   DSECT ,                   KILL SYM CARD GENERATION       UF023
CJOE     CSECT ,                                                  UF023
        $JOE
        $JQE
         QCOMMON
SYMNODEL DSECT ,                   RESTORE SYM CARD GENERATION    UF023
         END
./ ADD NAME=CJOESP
CJOE     QSTART 'QUEUE COMMAND - DUMP A JOE IN HEX'               UF026
         GBLB  &QSP           MVS/SP OPTION
         AIF   (&QSP).SPOK
         QTILT 'JOE COMMAND ONLY SUPPORT UNDER SP VERSION OF QUEUE'
         AGO   .BYEBYE                                            VBA01
.SPOK    ANOP
***********************************************************************
*                                                                     *
*   CALL FINDJOB TO LOCATE THE JQE                                    *
*                                                                     *
***********************************************************************
FINDJQE  L     R15,=V(FINDJOB) ADDR OF MODULE TO FIND JOB
         BALR  R14,R15        GO TO IT
***********************************************************************
*                                                                     *
*   CALL HEXDUMP TO DUMP THE JOES                                     *
*                                                                     *
***********************************************************************
         L     R10,QVCKPT     BASE FOR CKPT WORK AREA
         USING QCKPT,R10      ADDRESSING FOR IT
         L     R1,QCJQEA      ADDRESS OF JQE
         USING JQEDSECT,R1    ADDRESSING FOR JQE
         SR    R2,R2          CLEAR WORK REG
         ICM   R2,7,JQEJOEB   OFFSET TO FIRST WORK JOE
         BNZ   JOELOOP        CONTINUE IF ANY
         QTILT 'JOB HAS NO JOES'
         DROP  R1             DROP JQE ADDRESSING
         USING JOEDSECT,R2    ADDRESSING FOR JOE
         SPACE 1
JOELOOP  A     R2,QCJOTA      ADD TO GET ACTUAL ADDRESS
         LA    R1,MSGJWORK    WORK JOE MESSAGE
         ST    R1,QDMSGA      SAVE MESSAGE ADDRESS
         LA    R1,L'MSGJWORK  LENGTH OF MESSAGE
         STH   R1,QDMLNG      SAVE FOR DISPLAY ROUTINE
         L     R15,=V(DISPLAY) ADDRESS OF DISPLAY ROUTINE
         BALR  R14,R15        LINK TO IT
         LR    R1,R2          POINTER TO JOE TO DUMP
         LA    R0,JOE1END-JOEDSECT ACTUAL LENGTH OF WORK JOE
         L     R15,=V(HEXDUMP) ADDR OF HEXDUMP MODULE
         BALR  R14,R15        GO TO IT
         SPACE 1
         LA    R1,MSGJCHAR    CHAR JOE MESSAGE
         ST    R1,QDMSGA      SAVE MESSAGE ADDRESS
         LA    R1,L'MSGJCHAR  LENGTH OF MESSAGE
         STH   R1,QDMLNG      SAVE FOR DISPLAY ROUTINE
         L     R15,=V(DISPLAY) ADDRESS OF DISPLAY ROUTINE
         BALR  R14,R15        LINK TO IT
         ICM   R1,7,JOECHARB  POINTER TO CHARACTERISTICS JOE
         A     R1,QCJOTA      ADD TO GET ACTUAL ADDRESS
         LA    R0,JOE2END-JOEDSECT ACTUAL LENGTH OF CHAR JOE
         L     R15,=V(HEXDUMP) ADDR OF HEXDUMP MODULE
         BALR  R14,R15        GO TO IT
         SPACE 1
         LA    R1,MSGJCKPT    CKPT JOE MESSAGE
         ST    R1,QDMSGA      SAVE MESSAGE ADDRESS
         LA    R1,L'MSGJCKPT  LENGTH OF MESSAGE
         STH   R1,QDMLNG      SAVE FOR DISPLAY ROUTINE
         ICM   R1,7,JOECKPTB  POINTER TO CKPT JOE
         BZ    NEXTWORK       NONE, GET NEXT WORK JOB FOR THIS JOB
         L     R15,=V(DISPLAY) ADDRESS OF DISPLAY ROUTINE
         BALR  R14,R15        LINK TO IT
         A     R1,QCJOTA      ADD TO GET ACTUAL ADDRESS
         LA    R0,JOE3END-JOEDSECT ACTUAL LENGTH OF CKPT JOE
         L     R15,=V(HEXDUMP) ADDR OF HEXDUMP MODULE
         BALR  R14,R15        GO TO IT
         SPACE 1
NEXTWORK ICM   R2,7,JOEJQNXB  GET NEXT WORK JOE FOR THIS JOB
         BNZ   JOELOOP          AND DUMP IT
.BYEBYE  ANOP                                                     VBA01
         QSTOP
MSGJWORK DC    C'*** WORK JOE ***'
MSGJCHAR DC    C'*** CHAR JOE ***'
MSGJCKPT DC    C'*** CKPT JOE ***'
         LTORG
SYMDEL   DSECT ,                   KILL SYM CARD GENERATION       UF023
CJOE     CSECT ,                                                  UF023
        $JOE
        $JQE
         QCOMMON
SYMNODEL DSECT ,                   RESTORE SYM CARD GENERATION    UF023
         END
./ ADD NAME=CJQE
CJQE     QSTART 'QUEUE COMMAND - DUMP A JQE IN HEX'               UF015
***********************************************************************
*                                                                     *
*   CALL FINDJOB TO LOCATE THE JQE                                    *
*                                                                     *
***********************************************************************
         L     R15,=V(FINDJOB) ADDR OF MODULE TO FIND JOB
         BALR  R14,R15        GO TO IT
***********************************************************************
*                                                                     *
*   CALL HEXDUMP TO DUMP THE JQE                                      *
*                                                                     *
***********************************************************************
         L     R10,QVCKPT     BASE FOR CKPT WORK AREA
         USING QCKPT,R10      ADDRESSING FOR IT
         L     R1,QCJQEA      ADDRESS OF JQE
         LA    R0,JQELNGTH    GET ACTUAL LENGTH OF JQE
         L     R15,=V(HEXDUMP) ADDR OF HEXDUMP MODULE
         BALR  R14,R15        GO TO IT
         QSTOP
         LTORG
SYMDEL   DSECT ,                   KILL SYM CARD GENERATION       UF023
CJQE     CSECT ,                                                  UF023
        $JQE
         QCOMMON
SYMNODEL DSECT ,                   RESTORE SYM CARD GENERATION    UF023
         END
./ ADD NAME=CKPT
CKPT     QSTART 'QUEUE COMMAND - READ JES2 CKPT RECORDS'
         USING QCKPT,R10      BASE REG FOR HASP WORK AREA
         L     R10,QVCKPT     LOAD BASE REG
***********************************************************************
*                                                                     *
*   REPOSITION DATASET                                                *
*                                                                     *
***********************************************************************
         POINT HASPCKPT,TIR3  POINT PAST SYNC RECORDS
***********************************************************************
*                                                                     *
*   READ CHECKPOINT DATASET                                           *
*                                                                     *
***********************************************************************
         L     R2,QCJQTL      ADDR OF IOAREA FOR CKPT HEADER REC
         L     R3,QCJOTL      NUMBER OF RECORDS IN CKPT DATASET
LOOP     READ  HDECB1,SF,,(R2),MF=E
         CHECK HDECB1
         AH    R2,HDECB1+6    INCREMENT TO NEXT BUFFER
         BCT   R3,LOOP        READ NEXT RECORD.
***********************************************************************
*                                                                     *
*   RETURN TO CALLER                                                  *
*                                                                     *
***********************************************************************
         QSTOP
         LTORG
         DS    0F
TIR3     DC    X'00000300'    POINT PAST SYNC RECORDS
SYMDEL   DSECT ,                   KILL SYM CARD GENERATION       UF023
         QCOMMON
SYMNODEL DSECT ,                   RESTORE SYM CARD GENERATION    UF023
         END
./ ADD NAME=COMPILE
//ASMLQUE JOB (QUEUE),VB,CLASS=A,MSGCLASS=A,REGION=2048K
//ASMLQUE PROC M=MISSING,SP='NOSP,NODEBUG'
//ASM     EXEC PGM=CLS90,
//             PARM='DECK,NOLOAD,TERM,TEST,SYSPARM((&SP))'
//SYSLIB   DD  DISP=SHR,DSN=JES2.QUEUE.ASM
//         DD  DISP=SHR,DSN=SYS1.HASPSRC
//         DD  DISP=SHR,DSN=SYS1.MACLIB
//         DD  DISP=SHR,DSN=SYS1.AMODGEN
//SYSUT1   DD  SPACE=(CYL,(25,5)),UNIT=SYSDA
//SYSUT2   DD  SPACE=(CYL,(25,5)),UNIT=SYSDA
//SYSUT3   DD  SPACE=(CYL,(25,5)),UNIT=SYSDA
//SYSTERM  DD  SYSOUT=*
//SYSPRINT DD  SYSOUT=*
//SYSIN    DD  DISP=SHR,DSN=JES2.QUEUE.ASM(&M)
//SYSPUNCH DD  DISP=SHR,DSN=JES2.QUEUE.OBJ(&M)
//        PEND
//Q00     EXEC ASMLQUE,M=Q0                     QCOMMON
//Q01     EXEC ASMLQUE,M=Q1                     QUEUE
//Q02     EXEC ASMLQUE,M=Q2                     ALLOCATE
//Q03     EXEC ASMLQUE,M=Q3                     CKPT
//Q04     EXEC ASMLQUE,M=Q4                     DDNAME
//Q05     EXEC ASMLQUE,M=Q5                     DISPLAY
//Q06     EXEC ASMLQUE,M=Q6                     FINDJOB
//Q07     EXEC ASMLQUE,M=Q7                     FORMAT
//Q08     EXEC ASMLQUE,M=Q8                     HELP
//Q09     EXEC ASMLQUE,M=Q9                     HEXBLK
//Q10     EXEC ASMLQUE,M=Q10                    INIT
//Q11     EXEC ASMLQUE,M=Q11                    JCL
//Q12     EXEC ASMLQUE,M=Q12                    JLOG
//Q13     EXEC ASMLQUE,M=Q13                    JMSG
//Q14     EXEC ASMLQUE,M=Q14                    LIST
//Q15     EXEC ASMLQUE,M=Q15                    LISTDS
//Q16     EXEC ASMLQUE,M=Q16                    PARSE
//Q17     EXEC ASMLQUE,M=Q17                    READSPC
//Q18     EXEC ASMLQUE,M=Q18                    REPOS
//Q19     EXEC ASMLQUE,M=Q19                    SAVE
//Q20     EXEC ASMLQUE,M=Q20                    SEARCH
//Q21     EXEC ASMLQUE,M=Q21                    SYSLOG
//Q22     EXEC ASMLQUE,M=Q22                    XDS
//Q23     EXEC ASMLQUE,M=Q23                    INITS
//Q24     EXEC ASMLQUE,M=Q24                    ACTIVE
//Q25     EXEC ASMLQUE,M=Q25                    FINDPDDB
//Q26     EXEC ASMLQUE,M=Q26                    SYSOUT
//Q27     EXEC ASMLQUE,M=Q27                    PRINT
//Q28     EXEC ASMLQUE,M=Q28                    HEXDUMP
//Q29     EXEC ASMLQUE,M=Q29                    CJQE
//Q30     EXEC ASMLQUE,M=Q30                    CJCT
//Q31     EXEC ASMLQUE,M=Q31                    CTSO
//Q32     EXEC ASMLQUE,M=Q32                    CHCT
//Q33     EXEC ASMLQUE,M=Q33                    CPDDB
//Q34     EXEC ASMLQUE,M=Q34                    CJOE
//LKED    EXEC PGM=IEWL,PARM='XREF,LIST,LET,TEST,AC=1',REGION=1024K
//SYSLMOD  DD  DSN=SYS1.CMDLIB,DISP=SHR
//SYSUT1   DD  UNIT=SYSDA,SPACE=(CYL,(8,1))
//SYSPRINT DD  SYSOUT=*
//SYSLIB   DD  DISP=SHR,DSN=JES2.QUEUE.OBJ
//SYSLIN   DD  *
 INCLUDE SYSLIB(Q0,Q1,Q2,Q3,Q4,Q5,Q6,Q7,Q8,Q9)
 INCLUDE SYSLIB(Q10,Q11,Q12,Q13,Q14,Q15,Q16,Q17,Q18,Q19)
 INCLUDE SYSLIB(Q20,Q21,Q22,Q23,Q24,Q25,Q26,Q27,Q28,Q29)
 INCLUDE SYSLIB(Q30,Q31,Q32,Q33,Q34)
 ENTRY QUEUE
 ALIAS QUEUE
 ALIAS QUE
 NAME Q(R)
/*
//
./ ADD NAME=CPDDB    8002-02173-02202-0011-00176-00176-00000-GREG
CPDDB    QSTART 'QUEUE COMMAND - LIST PDDBS FOF A JOB'            UF025
***********************************************************************
*                                                                     *
*        PDDB JOBNAME <PDDB#>                                         *
*                                                                     *
* DISPLAY LIMITED INFORMATION ABOUT ALL OF THE PDDB'S FOR A JOB       *
*                                                                     *
* IF THE OPTIONAL PDDB NUMBER IS SPECIFIED, ONLY THAT PDDB WILL       *
* BE DUMPED IN HEX.                                                   *
*                                                                     *
***********************************************************************
         GBLB  &QJTIP             JTIP OPTION, DEFINED BY QSTART
         USING QCKPT,R10          BASE REG FOR CHECKPONT WORK AREA
         L     R10,QVCKPT         LOAD BASE REG
         USING QDISPLAY,R9        BASE REG FOR DISPLAY WORK AREA
         L     R9,QVDSPL          LOAD BASE REG
         USING WORK,R13           BASE REG FOR LOCAL WORK AREA
***********************************************************************
*                                                                     *
*   CALL FINDJOB TO LOCATE THE JCT                                    *
*                                                                     *
***********************************************************************
         L     R15,=V(FINDJOB)    ADDR OF MODULE TO FIND JOB
         BALR  R14,R15            GO TO IT
***********************************************************************
*                                                                     *
*   FIND ALL PDDBS FOR THIS JOB                                       *
*                                                                     *
***********************************************************************
         USING PDBDSECT,R2        BASE REG FOR PDDB
         USING IOTSTART,R3        BASE REG FOR IOT
         QHEAD HEADING,X'24'      HEADING IN GREEN REVERSE        GP@P6
         MVI   SWITCH,0           CLEAR FLAG BYTE
         L     R3,QCIOTA          LOAD BASE REG
         LR    R5,R3              IOAREA FOR READ IOT BLOCK
         USING JCTSTART,R1        SET TEMP ADDRESSING
         L     R1,QCJCTA          POINT TO JCT
         L     R4,JCTIOT          FIRST IOT ADDRESS
         DROP  R1                 DROP TEMP ADDRESSING
         BAL   R8,READ            READ THE IOT
         SPACE 1
         LH    R6,QLNG2           WAS A PDDB SPECIFIED?
         LTR   R6,R6
         BZ    NEXTIOT            NO, PROCEED NORMALLY
         BCTR  R6,0               DROP FOR EXECUTES
         MVC   QFZONES,QFZONE     PREPARE FOR NUMERIC TEST
         EX    R6,MVZ             MOVE ZONES FOR TEST
         CLC   QFZONES,QFZONE     ALL NUMERIC?
         BNE   TILT               NO, SKIP IT
         EX    R6,PACK            PACK TO DWORD
         CVB   R6,CONVERT         GET PDDB NUMBER
         OI    SWITCH,X'02'       AND INDICATE FOR LATER
         SPACE 1
NEXTIOT  LR    R4,R3              BASE OF IOT
         A     R4,IOTPDDBP        OFFSET BEYOND LAST PDDB
         LR    R2,R3              BASE OF IOT
         A     R2,QCPDDB1         OFFSET TO FIRST PDDB IN IOT
PDDBLOOP LH    R0,PDBDSKEY        GET THE DSID
         TM    SWITCH,X'02'       ONLY WANT ONE PDDB?
         BZ    PDDBLP1            NO, SKIP SPECIAL TEST
         CR    R0,R6              FOUND RIGHT PDDB?
         BNE   NEXTPDDB           NO, TRY NEXT ONE
         LR    R1,R2              POINT TO PDDB
         LA    R0,PDBLENG         LENGTH OF PDDB
         L     R15,=V(HEXDUMP)    POINT TO DISPLAY ROUTINE
         BALR  R14,R15            AND LINK TO IT
         B     NEXTPDDB           JUST INCASE MULTIPLE PDDBS (SYSLOG)
         SPACE 1
PDDBLP1  MVC   QDMSG,QBLANK       BLANK WORK LINE AREA
         LTR   R0,R0              TEST FOR NULL PDDB#
         BZ    NEXTPDDB           SKIP IF SO
         CVD   R0,CONVERT         CONVERT TO DECIMAL
         MVC   DSID-4(8),ED8      MOVE EDIT PATTERN TO DISPLAY
         ED    DSID-4(8),CONVERT+4  EDIT THE DSID
         UNPK  DSFLAG1(3),PDBFLAG1(2)  HEX OF FLAG BYTE
         TR    DSFLAG1,HEXTAB     MAKE PRINTABLE
         MVI   DSFLAG1+2,C' '     CLEAR TRASH BYTE
         L     R0,PDBRECCT        GET THE RECORD COUNT
         CVD   R0,CONVERT         CONVERT TO DECIMAL
         MVC   DSRECCT,ED8        MOVE EDIT PATTERN TO DISPLAY
         ED    DSRECCT,CONVERT+4  EDIT THE RECORD COUNT
         MVC   DSCLASS,PDBCLASS   MOVE PDBCLASS TO DISPLAY
         UNPK  DSMTTR(9),PDBMTTR(5)  UNPACK MTTR TO DISPLAY
         TR    DSMTTR,HEXTAB      MAKE PRINTABLE
         MVI   DSMTTR+9,C' '      CLEAR JUNK BYTE
         AIF   (NOT &QJTIP).JTIP1
         MVC   DS#PROC,PDB#PROC   SET JTIP PROC NAME
         MVC   DS#STEP,PDB#STEP   SET JTIP STEP NAME
         MVC   DS#DDNM,PDB#DDN    SET JTIP DD NAME
.JTIP1   ANOP
         MVC   QDMLNG,=H'80'      SET THE LENGTH
         LA    R0,QDMSG           POINT TO MESSAGE
         ST    R0,QDMSGA          SET IN AREA
         L     R15,=V(DISPLAY)    POINT TO DISPLAY ROUTINE
         BALR  R14,R15            LINK TO IT
NEXTPDDB LA    R2,PDBLENG(R2)     POINT TO NEXT PDDB
         CR    R2,R4              HAVE WE GONE PAST THE LAST PDDB
         BL    PDDBLOOP           NO. KEEP TRYING
         L     R4,IOTIOTTR        DISK ADDR OF NEXT IOT
SPIN     LTR   R4,R4              IS THERE ANOTHER IOT?
         BZ    SPINIOT            NO. TRY THE SPIN IOT.
         BAL   R8,READ            READ THE IOT
         B     NEXTIOT            SEARCH THE NEXT IOT
         USING JCTSTART,R1        BASE REG FOR JCT
SPINIOT  TM    SWITCH,1           DID WE SEARCH THE SPINIOT ALREADY
         BO    STOP               YES, DONE
         OI    SWITCH,1           SET SWITCH
         L     R1,QCJCTA          LOAD BASE REG
         L     R4,JCTSPIOT        DISK ADDR OF SPIN IOT
         B     SPIN               SEARCH THE SPIN IOT CHAIN
         DROP  R1
STOP     QSTOP                    GO BACK TO CALLER
***********************************************************************
*                                                                     *
*   READ A BLOCK FROM HASPACE                                         *
*                                                                     *
***********************************************************************
READ     ST    R4,QCTRAK          STORE DISK ADDR
         LR    R1,R5              IOAREA ADDRESS
         L     R15,=V(READSPC)    ADDR OF ROUTINE TO READ HASPACE
         BALR  R14,R15            GO TO IT
         BR    R8                 RETURN TO CALLER
ED8      DC    X'4020202020202120'
MVZ      MVZ   QFZONES(1),QPARM2
PACK     PACK  CONVERT,QPARM2(1)
HEXTAB   EQU   *-X'F0'
         DC    C'0123456789ABCDEF'
TILT     QTILT 'INVALID PDDB# SPECIFIED'
HEADING  DC    CL80' '
         ORG   HEADING            POINT TO START OF AREA
         DC    C'    DSID'
         DC    C' F1'             FLAG BYTE 1
         DC    C'  RECORDS'
         DC    C' C'              CLASS
         DC    C'   MTTR  '       MTTR
         AIF   (NOT &QJTIP).JTIP2
         DC    C' PROCNAME'
         DC    C' STEPNAME'
         DC    C' DDNAME  '
.JTIP2   ANOP
         ORG   ,                  BACK TO NORMAL ADDRESSING
SYMDEL   DSECT ,                   KILL SYM CARD GENERATION       UF023
CPDDB    CSECT ,                                                  UF023
JCT      EQU   0
BUFSTART EQU   0
BUFDSECT EQU   0
         $TAB
         $JCT
         $PDDB
         $IOT
WORK     DSECT
         DS    CL72
SWITCH   DS    C
CONVERT  DS    D
         QCOMMON
         ORG   QDMSG
         DS    CL4
DSID     DS    CL4
         DS    CL1
DSFLAG1  DS    CL2
         DS    CL1
DSRECCT  DS    CL8
         DS    CL1
DSCLASS  DS    CL1
         DS    CL1
DSMTTR   DS    CL8
         AIF   (NOT &QJTIP).JTIP3
         DS    CL1
DS#PROC  DS    CL8
         DS    CL1
DS#STEP  DS    CL8
         DS    CL1
DS#DDNM  DS    CL8
.JTIP3   ANOP
SYMNODEL DSECT ,                   RESTORE SYM CARD GENERATION    UF023
         END
./ ADD NAME=CSAVE
SAVE     QSTART 'QUEUE COMMAND - CREATE A COPY OF CURRENT DATASET'
         USING QCKPT,R10      BASE REG FOR CHECKPOINT WORK AREA
         L     R10,QVCKPT     LOAD BASE REG
         USING QDISPLAY,R9    BASE REG FOR DISPLAY WORK AREA
         L     R9,QVDSPL      LOAD BASE REG
         USING WORK,R13       LOCAL WORK AREA
***********************************************************************
*                                                                     *
*   ALLOCATE OUTPUT DATASET                                           *
*                                                                     *
***********************************************************************
         CLC   QPDSID,=H'0'   IS THERE A VALID DATASET?
         BE    TILT1          NO. TELL THE USER.
         MVC   DSNAME+2(44),QBLANK BLANK THE DSNAME
         MVC   DSNAME+2(8),QPARM1 FIRST PART OF DSNAME
         LA    R1,DSNAME      ADDR OF DSNAME
         ST    R1,DA08PDSN    STORE IN PARM LIST
         LH    R2,QLNG1       LENGTH OF QPARM1
         LA    R1,2(R2,R1)    OFFSET INTO DSNAME
         LH    R3,QLNG2       LENGTH OF QPARM2
         LTR   R3,R3          ?/LENGTH ZERO
         BZ    DATA           YES. USE DATA AS DEFAULT DS TYPE
         MVI   0(R1),C'.'     MOVE IN DELIMITER
         MVC   1(8,R1),QPARM2 NO. SAVE DS TYPE
         LA    R1,1(R3,R2)    LENGTH OF DSNAME
         B     DSLNGH         GO SAVE LENGTH
DATA     MVC   0(5,R1),=C'.DATA' LAST PART OF DSNAME
         LA    R1,5(R2)       LENGTH OF DSNAME
DSLNGH   STH   R1,DSNAME      STORE LENGTH OF DSNAME
         MVC   DA08DDN(72),ALCLIST REMAINDER OF PARM LIST
         LH    R3,QLNG3       LENGTH OF QPARM3 (VOLSER)           UF028
         LTR   R3,R3          WAS IT SPECIFIED?                   UF028
         BZ    DSALLOC        NO, SKIP THIS                       UF028
         MVC   DA08SER(8),QPARM3  SET VOLSER                      UF028
DSALLOC  MVI   DAIRFLAG,X'08' INDICATE ALLOC FUNCTION
         L     R15,=V(ALLOCATE) ADDR OF DAIR MODULE
         BALR  R14,R15        GO TO IT
         MVC   QCOUT+36(1),QCRECFM MOVE IN RECORD FORMAT
         NI    QCOUT+36,X'06' TURN OFF EVERTHING BUT CCTL
         OI    QCOUT+36,X'90' SPECIFY FIXED BLOCKED RECORDS
         LH    R1,QCLRECL     RECORD LENGTH
         LTR   R1,R1          IS THE LRECL ZERO?
         BNZ   RECOK          NO. SKIP.
         LA    R1,133         YES. USE LRECL 133.
RECOK    STH   R1,QCOUT+82    STORE LRECL
BIGGER   LR    R2,R1          UPDATE BLKSIZE
         AH    R1,QCOUT+82    ADD LRECL TO BLKSIZE
         CH    R1,=H'4096'    IS THE BLKSIZE GREATER THAN 4096?
         BL    BIGGER         NO. MAKE IT BIGGER.
         STH   R2,QCOUT+62    STORE BLKSIZE
         OPEN  MF=(E,QCOPEN)
***********************************************************************
*                                                                     *
*   REPOSITION DATASET TO TOP                                         *
*                                                                     *
***********************************************************************
         L     R4,QCSTART     TOP OF DATASET POINTER
         L     R4,0(R4)       DISK ADDR TOP OF DATASET
         L     R5,QCBLKA      IOAREA ADDRESS
         B     FIRST          GO DO IT
***********************************************************************
*                                                                     *
*   PROCESS DATASET                                                   *
*                                                                     *
***********************************************************************
NEXTBLK  L     R4,0(R5)       DISK ADDR OF NEXT BLOCK
FIRST    LTR   R4,R4          IS THE DISK ADDR ZERO?
         BZ    END            YES. END OF DATASET.
         BAL   R8,READ        READ A BLOCK
         CLC   QPJOBID(6),4(R5) DOES THE JOBID MATCH?
         BNE   END            NO. END OF DATASET.
         LA    R4,10(R5)      ADDR OF FIRST RECORD IN BLOCK
***********************************************************************
*                                                                     *
*   PROCESS RECORDS                                                   *
*                                                                     *
***********************************************************************
NEXTREC  CLI   0(R4),X'FF'    IS LENGTH BYTE FF?
         BE    NEXTBLK        YES. END OF BLOCK.
         TM    1(R4),X'10'    IS THIS A SPANNED RECORD?
         BO    SPAN           YES. SKIP IT.
         SR    R6,R6          ZERO OUT REG
         IC    R6,0(R4)       INSERT LENGTH
         TM    1(R4),X'80'    IS CCTL SPECIFIED?
         BZ    NOCCTL         NO. SKIP.
         LA    R6,1(R6)       INCREMENT LENGTH FOR CCTL
NOCCTL   TM    1(R4),X'08'    IS THIS RECORD TO BE IGNORED?
         BO    SKIPREC        YES. SKIP IT.
         MVI   BUFFER,C' '    BLANK FIRST BYTE OF BUFFER
         MVC   BUFFER+1(255),BUFFER BLANK THE BUFFER
         LR    R7,R6          DO NOT DESTROY R6
         SH    R7,=H'1'       IS LENGTH ZERO?
         BM    SKIPREC        YES. SKIP RECORD.
         EX    R7,MVCREC      MOVE RECORD TO BUFFER
         PUT   QCOUT,BUFFER
SKIPREC  LA    R4,3(R6,R4)    INCREMENT TO NEXT RECORD
         B     NEXTREC        PROCESS NEXT RECORD
SPAN     LH    R6,2(R4)       SEGMENT LENGTH
         TM    1(R4),X'08'    IS THIS THE FIRST SEGMENT?
         BO    SPANFRST       YES. USE LARGER HEADER SIZE.
         LA    R4,4(R6,R4)    INCREMENT TO NEXT RECORD
         B     NEXTREC        PROCESS NEXT RECORD
SPANFRST LA    R4,6(R6,R4)    INCREMENT TO NEXT RECORD
         B     NEXTREC        PROCESS NEXT RECORD
***********************************************************************
*                                                                     *
*   CLOSE UP SHOP AND GO HOME                                         *
*                                                                     *
***********************************************************************
END      CLOSE MF=(E,QCOPEN)
         MVI   DAIRFLAG,X'18' INDICATE FREE FUNCTION
         L     R15,=V(ALLOCATE) ADDR OF DAIR MODULE
         BALR  R14,R15        GO TO IT
         L     R15,=V(LISTDS) GO BACK TO LISTDS
         BALR  R14,R15        GO TO IT
         QSTOP
***********************************************************************
*                                                                     *
*   READ A BLOCK FROM HASPACE                                         *
*                                                                     *
***********************************************************************
READ     ST    R4,QCTRAK      STORE DISK ADDR
         LR    R1,R5          IOAREA ADDRESS
         L     R15,=V(READSPC) ADDR OF ROUTINE TO READ HASPACE
         BALR  R14,R15        GO TO IT
         BR    R8             RETURN TO CALLER
***********************************************************************
*                                                                     *
*   MISCELLANY                                                        *
*                                                                     *
***********************************************************************
TILT1    QTILT '*** YOU ARE NOT PROCESSING A VALID DATASET ***'
         LTORG
MVCREC   MVC   BUFFER(1),3(R4)
         DS    0F
ALCLIST  DC    C'HASPSAVE',CL16' ',F'0',F'10',F'50',F'0'
         DC    CL16' ',X'040202B0',F'0',CL8' '
SYMDEL   DSECT ,                   KILL SYM CARD GENERATION       UF023
         QCOMMON
SYMNODEL DSECT ,                   RESTORE SYM CARD GENERATION    UF023
WORK     DSECT
         DS    CL80
BUFFER   DS    CL256
DSNAME   DS    H
         DS    CL44
         END
./ ADD NAME=CSPIN    0110-96191-02306-1627-00430-00430-00000-GREG
CSPIN    QSTART 'QUEUE COMMAND - SPIN A COPY OF CURRENT DATASET'  ONL01
*        PRINT GEN
         USING QCKPT,R10      BASE REG FOR CHECKPOINT WORK AREA
         L     R10,QVCKPT     LOAD BASE REG
         USING QDISPLAY,R9    BASE REG FOR DISPLAY WORK AREA
         L     R9,QVDSPL      LOAD BASE REG
         USING WORK,R13       LOCAL WORK AREA
***********************************************************************
*                                                                     *
*   ALLOCATE OUTPUT DATASET                                           *
*                                                                     *
***********************************************************************
         CLC   QPDSID,=H'0'   IS THERE A VALID DATASET?
         BE    TILT1          NO. TELL THE USER.
         LA    R1,1           DEFAULT FIRST LINE                 WGH
         ST    R1,FRSTLINE    INIT DEFAULT                       WGH
         LA    R1,0           INIT CURRENT LINE                  WGH
         ST    R1,LINECNT     DEFAULT CURRENT LINE               WGH
         L     R1,=F'9999999' DEFAULT LAST LINE                  WGH
         ST    R1,LASTLINE    TO ENSUR END OF DATASET            WGH
         MVC   DEST(8),=CL8' '         DEFAULT DEST              WGH
         MVC   WRTRID(8),=CL8' '       DEFAULT WRTRID            WGH
         MVI   CLASS,C'A'     SYSOUT=A
         CLC   QPARM1(6),=C'CLASS='  IS CLASS SPECIFIED          WGH
         BE    ALTCLASS       YES..  GET ALTERNATE CLASS PARM    WGH
         LA    R4,QLNG1       POINT TO 1ST  FIELD LENGTH         WGH
         LA    R5,QPARM1      POINT TO 1ST  FIELD                WGH
         LH    R3,0(R4)       ANY PARMS  SPECIFIED               WGH
         LTR   R3,R3          IS PARM1 0 CHAR?                   WGH
         BZ    DSALLOC        YES..  USE DEFAULT                 WGH
         CLI   QPARM1,C'Z'    CHECK FOR COUNT                    WGH
         BH    CHKCNT         NOT ALPHABETIC TRY COUNT           WGH
         CH    R3,=H'1'       IS PARM GT 1 CHAR?                 WGH
         BH    DEST1          YES..  MUST BE DEST                WGH
         CLI   QPARM1,C'A'    NO...  CHECK FOR VALID CLASS       WGH
         BL    BADCLS         NOT ALPHABETIC BAD CLASS           WGH
         MVC   CLASS,QPARM1   USE SPECIFIED CLASS                WGH
         B     COUNT2         TRY FOR COUNT IN PARM2             WGH
ALTCLASS CLI   QPARM1+6,C'A'  CHECK FOR VALID CLASS              WGH
         BL    BADCLS         TO LOW BAD SYSOUT CLASS            WGH
         MVC   CLASS,QPARM1+6 USE SPECIFIED CLASS                WGH
COUNT2   LA    R4,QLNG2       POINT TO NEXT FIELD                WGH
         LA    R5,QPARM2      POINT TO NEXT FIELD                WGH
CHKCNT   EQU   *
         LH    R3,0(R4)       LENGTH OF COUNT FIELD              WGH
         LTR   R3,R3          ANYTHING THERE                     WGH
         BZ    DSALLOC        NO.. CONTINUE WITH DEFAULTS        WGH
         CLI   0(R5),C'0'     IS IT A NUMBER?                    WGH
         BL    DEST1          NO.. MUST BE DEST                  WGH
         XC    SCRATCH,SCRATCH YES..ZERO WORK AREA               WGH
         MVC   SCRATCH+4,QPREC      MOVE CURRENT LINE            WGH
         CVB   R15,SCRATCH     CONVERT TO BINARY                 WGH
         LTR   R15,R15         IS IT POSITIVE                    WGH
         BNP   CHKNUM          NO.. LEAVE AS DEFAULT             WGH
         ST    R15,FRSTLINE    SAVE FOR LATER                    WGH
CHKNUM   BCTR  R3,0            LENGTH OF FIELD -1                WGH
         LA    R14,0(R5)       POINT TO PARM FIELD               WGH
         MVC   QFZONES,QFZONE  INIT CHECK FIELD                  WGH
         EX    R3,MVZ          MOVE ZONES FROM PARM              WGH
         CLC   QFZONES,QFZONE  IS IT ALL NUMERIC ?               WGH
         BNE   NOTNUM          NO.. INFORM USER                  WGH
         EX    R3,PACK         PACK THE NUMBER                   WGH
         CVB   R15,SCRATCH     LOAD THE NUMBER                   WGH
         A     R15,FRSTLINE    ADD TO STARTING LINE              WGH
         S     R15,=F'1'       ADJUST TO GET CORRECT COUNT       WGH
         ST    R15,LASTLINE    SAVE IT                           WGH
         LA    R4,12(R4)      POINT TO NEXT FIELD LENGTH         WGH
         LA    R5,12(R5)      POINT TO NEXT FIELD (2 OR 3)       WGH
DEST1    EQU   *                                                 WGH
         LH    R3,0(R4)       LENGTH OF DEST  FIELD              WGH
         LTR   R3,R3          ANYTHING THERE                     WGH
         BZ    DSALLOC        NO.. CONTINUE WITH DEFAULTS        WGH
         STH   R3,DESTLEN     SAVE LENGTH                        WGH
         MVC   DEST(8),0(R5)   MOVE IN DEST FIELD                WGH
         LA    R4,12(R4)      POINT TO WRTRID FIELD LENGTH       WGH
         LA    R5,12(R5)      POINT TO WRTRID FIELD              WGH
         LH    R3,0(R4)       LENGTH OF WRTRID FIELD             WGH
         LTR   R3,R3          ANYTHING THERE                     WGH
         BZ    DSALLOC        NO.. CONTINUE WITH DEFAULTS        WGH
         STH   R3,WRTRLEN     SAVE LENGTH                        WGH
         MVC   WRTRID(8),0(R5)   MOVE IN WRTRID FIELD            WGH
DSALLOC  EQU   *
         BAL   R8,ALLOSPIN    GO ALLOCATE SPIN DDN               WGH
         MVC   QCOUT+36(1),QCRECFM MOVE IN RECORD FORMAT
         NI    QCOUT+36,X'06' TURN OFF EVERTHING BUT CCTL
         OI    QCOUT+36,X'90' SPECIFY FIXED BLOCKED RECORDS
         LH    R1,QCLRECL     RECORD LENGTH
         LTR   R1,R1          IS THE LRECL ZERO?
         BNZ   RECOK          NO. SKIP.
         LA    R1,133         YES. USE LRECL 133.
RECOK    STH   R1,QCOUT+82    STORE LRECL
         STH   R1,QCOUT+62    AND BLKSIZE
***     $AMODE 24
         OPEN  MF=(E,QCOPEN)
***     $AMODE 31
         SPACE 1
***********************************************************************
*                                                                     *
*   REPOSITION DATASET TO TOP                                         *
*                                                                     *
***********************************************************************
         L     R4,QCSTART     TOP OF DATASET POINTER
         L     R4,0(R4)       DISK ADDR TOP OF DATASET
         L     R5,QCBLKA      IOAREA ADDRESS
         B     FIRST          GO DO IT
***********************************************************************
*                                                                     *
*   PROCESS DATASET                                                   *
*                                                                     *
***********************************************************************
NEXTBLK  L     R4,HDBNXTRK-BUFSTART(R5) DISK ADDR NEXT BLOCK   WGH42
FIRST    LTR   R4,R4          IS THE DISK ADDR ZERO?
         BZ    END            YES. END OF DATASET.
         BAL   R8,READ        READ A BLOCK
         CLC   QPJOBID(6),HDBJBKEY-BUFSTART(R5) JOBID MATCH?  GP  WGH42
         BNE   END                  NOMATCH                     WGH42
**GP     CLC   QPDSID,HDBDSKEY-BUFSTART+2(R5)   DSID  MATCH?    WGH42
**GP     BE    IDISOK              BR IF SO                          CL
**GP     L     R4,QCJQEA           ADDR OF JQE                       CL
**GP     TM    JQEFLAG3-JQE(R4),JQE3SYSD ALL THRU IF THIS            CL
**GP     BNO   END                    IS NOT SYSTEM JQE              CL
IDISOK   LA    R4,HDBSTART-BUFSTART(R5)    FIRST RECORD IN BLOCK  WGH42
***********************************************************************
*                                                                     *
*   PROCESS RECORDS                                                   *
*                                                                     *
***********************************************************************
NEXTREC  CLI   0(R4),X'FF'    IS LENGTH BYTE FF?
         BE    NEXTBLK        YES. END OF BLOCK.
         TM    1(R4),X'10'    IS THIS A SPANNED RECORD?
         BO    SPAN           YES. SKIP IT.
         SR    R6,R6          ZERO OUT REG
         IC    R6,0(R4)       INSERT LENGTH
         TM    1(R4),X'80'    IS CCTL SPECIFIED?
         BZ    NOCCTL         NO. SKIP.
         LA    R6,1(R6)       INCREMENT LENGTH FOR CCTL
NOCCTL   TM    1(R4),X'08'    IS THIS RECORD TO BE IGNORED?
         BO    SKIPREC        YES. SKIP IT.
         MVI   BUFFER,C' '    BLANK FIRST BYTE OF BUFFER
         MVC   BUFFER+1(255),BUFFER BLANK THE BUFFER
         LR    R7,R6          DO NOT DESTROY R6
         SH    R7,=H'1'       IS LENGTH ZERO?
         BM    SKIPREC        YES. SKIP RECORD.
         EX    R7,MVCREC      MOVE RECORD TO BUFFER
         L     R1,LINECNT     GET CURRENT LINE CNT                WGH
         LA    R1,1(R1)       ADD THIS LINE TO IT                 WGH
         ST    R1,LINECNT     SAVE IT                             WGH
         C     R1,LASTLINE    IT IS GT THAN LAST REQUESTED        WGH
         BH    END            YES.. CLOSE IT                      WGH
         C     R1,FRSTLINE    IS IT LESS THAN 1ST REQUESTED?      WGH
         BL    SKIPREC        YES... SKIP IT                      WGH
***     $AMODE 24
         PUT   QCOUT,BUFFER
***     $AMODE 31
         SPACE 1
SKIPREC  LA    R4,3(R6,R4)    INCREMENT TO NEXT RECORD
         B     NEXTREC        PROCESS NEXT RECORD
SPAN     LH    R6,2(R4)       SEGMENT LENGTH
         TM    1(R4),X'08'    IS THIS THE FIRST SEGMENT?
         BO    SPANFRST       YES. USE LARGER HEADER SIZE.
         LA    R4,4(R6,R4)    INCREMENT TO NEXT RECORD
         B     NEXTREC        PROCESS NEXT RECORD
SPANFRST LA    R4,6(R6,R4)    INCREMENT TO NEXT RECORD
         B     NEXTREC        PROCESS NEXT RECORD
***********************************************************************
*                                                                     *
*   CLOSE UP SHOP AND GO HOME                                         *
*                                                                     *
***********************************************************************
END      DS    0H
***     $AMODE 24
         CLOSE MF=(E,QCOPEN)
***     $AMODE 31
         SPACE 1
         MVC   DYNALLOC(FREELEN),FREEPTR
         LA    R1,YREERB
         STCM  R1,B'0111',YREEPTR+1
         LA    R1,YREETXPT
         ST    R1,YREETPTR
         LA    R1,YREETU1
         STCM  R1,B'0111',YREETXPT+1
         LA    R1,YREETU2
         STCM  R1,B'0111',YREETXPT+5
         LA    R1,YREEPTR
         DYNALLOC
         L     R15,=V(LISTDS) GO BACK TO LISTDS
         BALR  R14,R15        GO TO IT
         QSTOP
***********************************************************************
*                                                                     *
*   READ A BLOCK FROM HASPACE                                         *
*                                                                     *
***********************************************************************
READ     ST    R4,QCTRAK      STORE DISK ADDR
         LR    R1,R5          IOAREA ADDRESS
         L     R15,=V(READSPC) ADDR OF ROUTINE TO READ HASPACE
         BALR  R14,R15        GO TO IT
         BR    R8             RETURN TO CALLER
***********************************************************************
*                                                                     *
*   ALLOCATION ROUTINE                                                *
*                                                                     *
***********************************************************************
ALLOSPIN MVC   DYNALLOC(S99LENG),S99RBPTR  COPY DYN ALLOC LIST    WGH
         LA    R1,X99RB       RELOCATE LIST
         STCM  R1,B'0111',X99RBPTR+1
         LA    R1,X99TUPL
         ST    R1,X99TXTPP
         LA    R1,X99TUKY1
         STCM  R1,B'0111',X99TUPL+1
         LA    R1,X99TUKY2
         STCM  R1,B'0111',X99TUPL+5
         LA    R1,X99TUKY3
         STCM  R1,B'0111',X99UPLL+1
         LA    R1,X99TUKY4
         STCM  R1,B'0111',X99UPLLW+1
         MVC   X99SYSOC,CLASS
         CLI   DEST,C' '               ANY DEST SPEC?
         BE    NODEST
         MVC   X99DESTL,DESTLEN        MOVE IN LENGTH
         MVC   X99DEST,DEST            MOVE IN DEST
         MVI   X99EPARM,X'00'          SAY CLASS NOT LAST PARM
         CLI   WRTRID,C' '             ANY WRTRID SPECIFIED
         BE    NODEST
         MVC   X99WRTRL,WRTRLEN        MOVE IN LENGTH
         MVC   X99WRTR,WRTRID          MOVE IN WRTRID
         MVI   X99UPLL,X'00'           SAY DEST NOT LAST PARM
NODEST   LA    R1,DYNALLOC
         DYNALLOC
         LTR   R15,R15                 OK?
         BNZ   CANTALLC                NO CAN DO
         BR    R8             RETURN TO CALLER
***********************************************************************
*                                                                     *
*   ALLOCATION FAILURE                                                *
*                                                                     *
***********************************************************************
CANTALLC MVC   QDTLINE,QBLANK     CLEAR OUT LINE
         CLC   X99ERROR,=X'046C'  WAS IT 'NOT DEF TO JES2'
         BE    BADDEST            YES TELL USER
*
         MVC   QDTLINE(L'MSGERR),MSGERR
         CVD   R15,SCRATCH
         MVC   M2RC,=X'40202020'
         ED    M2RC,SCRATCH+6
*
         UNPK  M2ERC(5),X99ERROR(3)  CONVT DYNAM ALLOC ERR CODE
         NC    M2ERC,HEXMASK
         TR    M2ERC,HEXTAB
         MVI   M2ERC+4,C' '
*
         UNPK  M2INFO(5),X99INFO(3)  CONVT DYNAM ALLOC ERR INFO
         NC    M2INFO,HEXMASK
         TR    M2INFO,HEXTAB
         MVI   M2INFO+4,C' '
         B     GOTMSG
*
BADDEST  MVC   QDTLINE(L'MSGDEST),MSGDEST
         MVC   MDEST,DEST
         CLI   DEST,C' '             ANY DEST
         BNE   GOTMSG                YES.. CONTINUE
         MVC   MDEST(8),=CL8'LOCAL'
         B     GOTMSG
*
GOTMSG   EQU   *
         LA    R1,0                  SET A ZERO
         L     R2,4(R13)             RETURN CODE
         ST    R1,16(R2)
         MVC   QDREPLY,QBLANK        KISS OFF OUR REPLY
         XC    QDRLNG,QDRLNG         AND SAY NOBODY HOME (SNEAKY)
         QSTOP
HEXTAB   DC    C'0123456789ABCDEF'
HEXMASK  DC    X'0F0F0F0F0F0F0F0F'
MSGDEST  DC    C'  DEST XXXXXXXX NOT DEFINED TO JES2; SPIN BYPASSED'
MSGERR   DC    C'CANT ALLOC SYSOUT FOR SPIN ; DARC= XXXX INFO= XXXX R15X
               = XXXX '
***********************************************************************
*                                                                     *
*   MISCELLANY                                                        *
*                                                                     *
***********************************************************************
TILT1    QTILT '*** YOU ARE NOT PROCESSING A VALID DATASET ***'
NOTNUM   QTILT '*** INVALID RANGE FIELD SPECIFIED ***'
BADCLS   QTILT '*** INVALID SYSOUT CLASS SPECIFIED ***'
         LTORG
MVCREC   MVC   BUFFER(1),3(R4)
PACK     PACK  SCRATCH,0(1,R14)    PACK OPERAND                   WGH
MVZ      MVZ   QFZONES(1),0(R14)   MOVE ZONES FROM PARM FIELD     WGH
*
***********************************************************************
*                                                                     *
*   DYNAMIC ALLOCATION CONTROL BLOCKS                                 *
*                                                                     *
***********************************************************************
         DS    0F
S99RBPTR DC    X'80',AL3(S99RB)
*
S99RB    DS    0F
S99RBLN  DC    AL1(20)             LENGTH = 20 BYTES
S99VERB  DC    X'01'               VERB CDE=01 (DSN ALLOC)
S99FLAG1 DC    X'1000'             DONT USE EXISTING ALLOC
S99ERROR DC    AL2(0)              ERROR CODE
S99INFO  DC    AL2(0)              INFO CODE
S99TXTPP DC    A(S99TUPL)          TEXT UNIT PTR PTR
S99RSVD1 DC    A(0)                RESERVED
S99FLAG2 DC    A(0)                FLAGS 2
S99TUPL  DC    A(S99TUKY1)         TEXT UNIT PTR
S99EPARM DC    X'80',AL3(S99TUKY2) LAST PARM IF NO DEST
S99UPLL  DC    X'80',AL3(S99TUKY3) LAST PARM IF NO WRTRID GIVEN
S99UPLLW DC    X'80',AL3(S99TUKY4) LAST PARM IF WRTRID GIVEN
S99TUNIT DS    0F
*
S99TUKY1 DC    X'0001',X'0001',X'0008',C'HASPSAVE'
*
S99TUKY2 DC    X'0018',X'0001',X'0001'       SYSOUT
S99SYSOC DC    C'A'
*
S99TUKY3 DC    X'0058',X'0001'        OPTIONAL DEST=RMTXX OR NODE
S99DESTL DC    X'0000'                LENGTH OF DEST PARM
S99DEST  DC    CL8'LOCAL'             DEST PARM
S99TUKY4 DC    X'0063',X'0001'        OPTIONAL WRTRID=USER OR WRTR
S99WRTRL DC    X'0000'                LENGTH OF WRTR LENGTH
S99WRTR  DC    CL8' '                 WRTR PARM
S99LENG  EQU   *-S99RBPTR
*
*        DYNALLOC REQUEST CONTROL TO FREE DDNAME
*
         DS    0F
FREEPTR  DC    X'80',AL3(FREERB)
*
FREERB   DC    FL1'20'                LENGTH OF RB 20 BYTES
         DC    XL1'02'                VERB CODE 02 FREE BY DDN
         DC    AL2(0)                 FLAGS1
FREERC   DC    XL2'0000'              ERROR CODE
FREEINFO DC    XL2'0000'              INFO CODE
FREETPTR DC    AL4(FREETXPT)          TEXT UNIT PTR PTR
         DC    XL4'00'                RESERVED
         DC    XL4'00'                FLAGS2
*
FREETXPT DC    AL4(FREETU1)           ADDR OF DSN TEXT UNIT
         DC    X'80',AL3(FREETU2)     ADDR OF UNALLOC TEXT
*
FREETU1  DC    X'0001',X'0001',FL2'8',C'HASPSAVE' DDNAME
FREETU2  DC    X'0007',X'0000'        UNALLOC EVEN IF PERM
FREELEN  EQU   *-FREEPTR
*
***********************************************************************
*
SYMDEL   DSECT ,                   KILL SYM CARD GENERATION       UF023
CSPIN    CSECT                                                    GP@P6
*        QPRBGEN BEGIN             SET PRINT FOR CNTL BLOCK GEN   ONL01
*        $HASPEQU
         $JQE                                                        CL
         $BUFFER ,                                                WGH42
         QCOMMON
MDEST    EQU   QDTLINE+7,8
M2ERC    EQU   QDTLINE+35,4
M2INFO   EQU   QDTLINE+46,4
M2RC     EQU   QDTLINE+56,4
         IFGRPL  ,                                                WGH42
*        QPRBGEN DONE              RESTORE NORMAL PRINT STATUS    ONL01
SYMNODEL DSECT ,                   RESTORE SYM CARD GENERATION    UF023
WORK     DSECT
         DS    CL80
BUFFER   DS    CL256
SCRATCH  DS    D                   DOUBLEWORD                     WGH
FRSTLINE DS    F                   FIRST LINE TO SAVE             WGH
LINECNT  DS    F                   CURRENT LINE #                 WGH
LASTLINE DS    F                   LAST LINE TO SAVE              WGH
DESTLEN  DS    H                   DESTINATION LENGTH             WGH
DEST     DS    CL8                 DESTINATION                    WGH
WRTRLEN  DS    H                   DESTINATION LENGTH             WGH
WRTRID   DS    CL8                 DESTINATION                    WGH
CLASS    DS    C                   SYSOUT CLASS                   WGH
****************************************************************  WGH
         DS    0F
DYNALLOC DS    (S99LENG)XL1
         ORG   DYNALLOC
*
X99RBPTR DC    X'80',AL3(X99RB)
*
X99RB    DS    0F
X99RBLN  DC    AL1(20)             LENGTH = 20 BYTES
X99VERB  DC    X'01'               VERB CDE=01 (DSN ALLOC)
X99FLAG1 DC    X'1000'             DONT USE EXISTING ALLOC
X99ERROR DC    AL2(0)              ERROR CODE
X99INFO  DC    AL2(0)              INFO CODE
X99TXTPP DC    A(X99TUPL)          TEXT UNIT PTR PTR
X99RSVD1 DC    A(0)                RESERVED
X99FLAG2 DC    A(0)                FLAGS 2
X99TUPL  DC    A(X99TUKY1)         TEXT UNIT PTR
X99EPARM DC    X'80',AL3(X99TUKY2) LAST PARM IF NO DEST
X99UPLL  DC    X'80',AL3(X99TUKY3) LAST PARM IF NO WRTRID
X99UPLLW DC    X'80',AL3(X99TUKY4) LAST PARM IF WRTRID GIVEN
X99TUNIT DS    0F
*
X99TUKY1 DC    X'0001',X'0001',X'0008',C'HASPSAVE'
*
X99TUKY2 DC    X'0018',X'0001',X'0001'       SYSOUT
X99SYSOC DC    C'A'
*
X99TUKY3 DC    X'0058',X'0001'        OPTIONAL DEST=RMTXX OR NODE
X99DESTL DC    X'0000'                LENGTH OF DEST PARM
X99DEST  DC    CL8'LOCAL'             DEST PARM
*
X99TUKY4 DC    X'0063',X'0001'        OPTIONAL WRTRID=USER OR WRTR
X99WRTRL DC    X'0000'                LENGTH OF WRTRID PARM
X99WRTR  DC    CL8' '                 WRTRID PARM
*
         ORG   DYNALLOC
         DS    0F
YREEPTR  DC    X'80',AL3(YREERB)
*
YREERB   DC    FL1'20'                LENGTH OF RB 20 BYTES
         DC    XL1'02'                VERB CODE 02 FREE BY DDN
         DC    AL2(0)                 FLAGS1
YREERC   DC    XL2'0000'              ERROR CODE
YREEINFO DC    XL2'0000'              INFO CODE
YREETPTR DC    AL4(YREETXPT)          TEXT UNIT PTR PTR
         DC    XL4'00'                RESERVED
         DC    XL4'00'                FLAGS2
*
YREETXPT DC    AL4(YREETU1)           ADDR OF DSN TEXT UNIT
         DC    X'80',AL3(YREETU2)     ADDR OF UNALLOC TEXT
*
YREETU1  DC    X'0001',X'0001',FL2'8',C'HASPSAVE' DDNAME
YREETU2  DC    X'0007',X'0000'        UNALLOC EVEN IF PERM
         ORG   ,
****************************************************************  WGH
         END
./ ADD NAME=CTSO     8003-02173-03063-1455-00211-00202-00000-GREG
CTSO     QSTART 'ISSUE TSO COMMANDS WHILE IN QUEUE COMMAND.'      UF017
         USING WORK,R13       BASE FOR WORK AREA
         L     R10,QVCKPT     BASE FOR CKTP AREA
         USING QCKPT,R10      ADDRESSING FOR AREA
         L     R9,QVDSPL      BASE FOR DISPLAY AREA
         USING QDISPLAY,R9    ADDRESSING FOR AREA
         LA    R8,WCPPL       BASE FOR CPPL AREA
         USING CPPL,R8        ADDRESSING FOR AREA
         OC    QLNG1,QLNG1    TEST LENGTH OF COMMAND
         BZ    NOCMD          NONE, ABORT
         QHEAD QBLANK,X'04'   BLANK HEADING LINE                  GP@P6
********                      2003-02-07 - REMOVE NEEDLESS TPUT   GP@P6
**       TPUT  CLEAR,L'CLEAR,FULLSCR,MF=(E,QTPUT)  CLEAR THE SCREEN
**       LA    R1,CLEAR       POINT TO DATA STREAM                GP@P6
**       LA    R0,L'CLEAR     GET DATA STREAM LENGTH              GP@P6
**       ICM   R1,8,=X'03'    SET FLAGS FOR FULLSCR               GP@P6
**       TPUT  (1),(0),R      CLEAR THE SCREEN                    GP@P6
********                      2003-02-07 - REMOVE NEEDLESS TPUT   GP@P6
*        STLINENO LINE=1,MODE=OFF  TURN OFF FULL SCREEN MODE
         MVC   WMODEL(WMODELEN),MODEL  COPY MODEL AREA TO DSECT AREA
         MVC   WBLDLFF,=AL2(1)  1 ENTRY IN LIST
         MVC   WBLDLLL,=AL2(12) 12 BYTES TO BE RETURNED
         L     R1,DAPLECT     POINT TO ECT
         USING ECT,R1         SET TEMP ADDRESSING
         MVC   QDWORD,ECTPCMD SAVE PRIMARY COMMAND NAME
         MVC   QDWORK,ECTSCMD  AND SECONDARY COMMAND NAME
         DROP  R1             DROP TEMP ADDRESSING
         SPACE 1
         MVC   CPPLUPT,DAPLUPT   COPY UPT POINTER
         MVC   CPPLPSCB,DAPLPSCB COPY PSCB POINTER
         MVC   CPPLECT,DAPLECT   COPY ECT POINTER
         SPACE 1
         LA    R15,QDREPLY    POINT TO COMMAND LINE
         AH    R15,QOFF1      POINT TO 1ST PARM (AFTER "TSO")
         SH    R15,=H'4'      BACK UP FOR BUFFER HEADER
         USING CMDBUF,R15     TEMP ADDRESSING FOR BUFFER
         LH    R14,QDRLNG     LENGTH OF REPLY
         SH    R14,QOFF1      - OFFSET TO OPERAND = TEXT LENGTH
         LA    R14,4(,R14)    + HEADER
         STH   R14,CMDLEN     SAVE AS LENGTH IN BUFFER
SCAN     ST    R15,CPPLCBUF   SET BUFFER CB POINTER
         XC    CMDOFF,CMDOFF  CLEAR OFFSET TO SECOND OPERAND
         DROP  R15            DROP TEMP ADDRESSING
         LA    R1,WCSPL       POINT TO IKJSCAN PARM LIST
         USING CSPL,R1        SET TEMP ADDRESSING
         L     R2,DAPLUPT     POINT TO UPT
         ST    R2,CSPLUPT
         L     R2,DAPLECT     POINT TO ECT
         ST    R2,CSPLECT
         LA    R2,WTCBECB     POINT TO ECB
         MVI   0(R2),0          CLEAR ECB
         ST    R2,CSPLECB
         LA    R2,WTCBADDR    WORD FOR FLAGS
         MVI   0(R2),0          CLEAR FLAGS
         ST    R2,CSPLFLG
         LA    R2,WCSOA       POINT TO OUTPUT AREA
         ST    R2,CSPLOA
         ST    R15,CSPLCBUF   COMMAND BUFFER ADDRESS TO CSPL
         DROP  R1             DROP TEMP ADDRESSING
         CALLTSSR EP=IKJSCAN  SCAN INPUT BUFFER
         LA    R1,WCSOA       POINT TO OUTPUT AREA
         USING CSOA,R1        SET TEMP ADDRESSING
         L     R14,CSOACNM    POINTER TO COMMAND NAME
         ICM   R15,3,CSOALNM  LENGTH OF NAME
         BZ    NOCMD2         NONE, SKIP REST
         BCTR  R15,0          DROP FOR EXECUTE
         DROP  R1             DROP TEMP ADDRESSING
         MVC   WBLDLNAM,QBLANK FILL WITH BLANKS
         EX    R15,MVCCMD      MOVE COMMAND TO WBLDLNAM
         CLC   =C'EX',QSUBNAME   IMPLICIT EXEC OF CLIST?
         BNE   NOTEXEC           NO, SKIP THIS
SETEXEC  NI    QSUBNAME,255-X'40'  DROP TO LOWER CASE
         MVC   WBLDLNAM,=CL8'EXEC' SET MODULE NAME TO ATTACH
         L     R1,CPPLCBUF       POINT TO BUFFER
         USING CMDBUF,R1         TEMP ADDRESSING
         XC    CMDOFF,CMDOFF     CLEAR OFFSET FOR EXEC
         B     OKATTACH       AND GO DO IT
         DROP  R1                DROP TEMP ADDRESSING
NOTEXEC  DS    0H
         BLDL  0,WBLDLPRM     CHECK FOR MODULE PRESENT
         LTR   R15,R15        CHECK RETURN CODE
         BNZ   SETEXEC        NONE, MUST BE CLIST
         SPACE 1
OKATTACH L     R1,DAPLECT     POINT TO ECT
         USING ECT,R1         SET TEMP ADDRESSING
         MVC   ECTPCMD,WBLDLNAM FAKE PRIMARY COMMAND NAME
         MVC   ECTSCMD,QBLANK AND SECONDARY COMMAND NAME
         DROP  R1             DROP TEMP ADDRESSING
         SPACE 1
         MVI   WTCBECB,0      CLEAR ECB
         LA    R1,WCPPL       CPPL PTR FOR COMMAND
ATTACH   DS    0H
         ATTACH EPLOC=WBLDLNAM,ECB=WTCBECB,                            +
               MF=(1,(1)),SF=(E,WATTL)
         ST    R1,WTCBADDR    SAVE TCB ADDR
WAIT     DS    0H
         WAIT  ECB=WTCBECB    WAIT
DETACH   DS    0H
         DETACH WTCBADDR
         SPACE 1
NOCMD2   DS    0H
         ICM   R1,15,WGTPB+4  ADDRESS OF GETLINE BUFFER
         BZ    NOFREE         NONO, SKIP FREEMAIN
         LH    R0,0(R1)       LENGTH OF BUFFER
         ICM   R0,B'1000',=X'01'  SUBPOOL 1
         FREEMAIN R,LV=(0),A=(1)  FREE THE BUFFER
         SPACE 1
NOFREE   L     R1,DAPLECT     POINT TO ECT
         USING ECT,R1         TEMP ADDRESSING
         L     R1,ECTIOWA     --> I/O WORK AREA
         DROP  R1             DROP TEMP ADDRESSING
         L     R1,0(R1)       --> TO ELEMENT ON STACK
         TM    0(R1),X'40'    FROM STORAGE (CLIST)?
         BZ    DONE           NO, DONE WITH PROCESSING
         LA    R1,WIOPL       ADDRESS OF IO PARM LIST
         L     R2,CPPLUPT     ADDRESS OF UPT
         L     R3,CPPLECT     ADDRESS OF ECT
         LA    R4,WTCBECB     ADDRESS OF ECB
         MVI   WTCBECB,0      CLEAR ECB
         GETLINE PARM=WGTPB,UPT=(R2),ECT=(R3),ECB=(R4),MF=(E,(1))
         CH    R15,=H'16'     END OF INPUT?
         BE    DONE           YES, CLEAN UP AND RETURN
         LA    R1,WGTPB       POINT TO GETLINE PARM LIST
         USING GTPB,R1        TEMP ADDRESSING
         L     R15,GTPBIBUF   POINT TO INPUT BUFFER
         DROP  R1             DROP TEMP ADDRESSING
         B     SCAN           AND GO TO SCAN PROCESSING
         SPACE 1
DONE     L     R1,DAPLECT     POINT TO ECT
         USING ECT,R1         SET TEMP ADDRESSING
         MVC   ECTPCMD,QDWORD RESTORE PRIMARY COMMAND NAME
         MVC   ECTSCMD,QDWORK  AND SECONDARY COMMAND NAME
         DROP  R1             DROP TEMP ADDRESSING
TPUT     DS    0H
*        TPUT  DONEMSG,L'DONEMSG  ASK FOR ENTER WHEN DONE
TGET     DS    0H
*        TGET  QDWORD,L'QDWORD,EDIT,MF=(E,QTGET)  READ RESPONSE
         STFSMODE ON           RESTORE FULL SCREEN MODE      2003-02-07
         OI    QFLAG1,QFLG1RSH ENSURE CORRECT SCREEN SIZE    2003-02-15
         ICM   R0,3,QPDSID     LOOKING AT SYSOUT DATA?       2003-03-04
         BZ    QSTOP           NO, SCREEN WILL BE EMPTY      2003-03-04
         L     R15,=V(LISTDS)  YES  (NEED QCODE NON-ZERO)    2003-03-04
         BALR  R14,R15         RESTORE SYSOUT DATA DISPLAY   2003-03-04
QSTOP    DS    0H
         QSTOP
         SPACE 1
NOCMD    QTILT '*** NO COMMAND SPECIFIED ***'
         SPACE 1
MVCCMD   MVC   WBLDLNAM(*-*),0(R14) MOVE COMMAND TO WBLDLNAM
         SPACE 1
*DONEMSG DC    C'*** PRESS ENTER TO RETURN TO QUEUE COMMAND ***'
********                      2003-02-07 - REMOVE NEEDLESS TPUT   GP@P6
*CLEAR1   EQU   *
**        DC    X'27F5C1
*         DC    X'115D7E'
*         DC    X'114040'
*         DC    X'3C404000'
*         DC    X'1DC8'
*         DC    X'13'
*CLEAR    EQU   CLEAR1,*-CLEAR1
********                      2003-02-07 - REMOVE NEEDLESS TPUT   GP@P6
         SPACE 1
MODEL    DS    0D
MGTPB    GETLINE MF=L
MATTL    ATTACH SHSPV=78,     NEEDED TO PREVENT S305 ABENDS            +
               SF=L
MODELEN  EQU   *-MODEL        LENGTH OF MODEL AREA
         SPACE 1
         LTORG
         SPACE  1
SYMDEL   DSECT ,                   KILL SYM CARD GENERATION       UF023
WORK     DSECT ,              .
         DS    18F            SAVE AREA
         DS    0D
WMODEL   DS    0D             START OF MODEL AREA
WGTPB    GETLINE MF=L
WATTL    ATTACH  SF=L
WMODELEN EQU   *-WMODEL       CHECK FOR SAME LENGTH.
         SPACE 1
WTCBADDR DC    A(0)           ADDRESS OF CREATED TASK
WTCBECB  DC    A(0)           COMPLETION CONTROL BLOCK.
WCPPL    DS    4F             SPACE FOR CPPL TO BE PASSED TO CMD
WPARML   DS    12F            SPACE FOR PARM LISTS
WIOPL    EQU   WPARML,16      IO PARM LIST FOR GETLINE
WCSPL    EQU   WPARML,24      PARM LIST FOR IKJSCAN
WCSOA    EQU   WPARML+24,8    OUTPUT AREA FROM IKJSCAN
         SPACE 1
         DS    0F
WBLDLPRM DS    XL16           WORK AREA FOR BLDL
WBLDLFF  EQU   WBLDLPRM,2     NUMBER OF ENTRIES IN LIST
WBLDLLL  EQU   WBLDLPRM+2,2   LENGTH OF EACH ENTRY
WBLDLNAM EQU   WBLDLPRM+4,8   MEMBER NAME
WBLDLTTR EQU   WBLDLPRM+12,3  TTR OF START
WBLDLK   EQU   WBLDLPRM+15,1  CONCATENATION NUMBER
         SPACE 1
WORKLEN  EQU   *-WORK         LENGTH OF WORK AREA
         SPACE 1
         IKJCPPL  ,
         IKJCSOA  ,
         IKJCSPL  ,
         IKJECT   ,
         IKJGTPB  ,
         CVT   DSECT=YES
         SPACE 1
CMDBUF   DSECT
CMDLEN   DC    H'0'           LENGTH, INCLUDES HEADER (+4)
CMDOFF   DC    H'0'           OFFSET TO NONBLANK PAST COMMAND.
CMDTEXT  DC    C' '           FIRST TEXT BYTE.
         QCOMMON
SYMNODEL DSECT ,                   RESTORE SYM CARD GENERATION    UF023
         END
./ ADD NAME=DDNAME   8014-02172-02311-1724-00293-00272-00000-GREG
DDNAME   QSTART 'QUEUE COMMAND - LIST DDNAMES AND DSIDS FOR A JOB'
***********************************************************************
* RNB CHANGES:                                                        *
*      (1) RNB11 - ALLOW COMMAND OF FORM   DD NAME S  WHERE S MEANS   *
*                  TO LIST THE SPIN DATA SETS EVEN IF A BATCH JOB.    *
*                  ADDED BECAUSE OUR IMS SYSTEM SPINS OFF DUMP DATA   *
*                  SETS THAT WE WANT TO LOOK AT.                      *
*      (2) RNB12 - WITH SP2 JES2 WE ALWAYS SEEM TO GET THE 'ALREADY   *
*                  PRINTED' MESSAGE FOR SPIN DATA SETS. THIS CHANGE   *
*                  BYPASSES THE MESSAGE IF QSP=1.                     *
***********************************************************************
         GBLB  &QRNB                                              RNB11
         GBLB  &QSP                                               RNB12
         GBLB  &QPFK          PF-KEY OPTION. DEFINED BY QSTART    GP@P6
         USING QCKPT,R10      BASE REG FOR CHECKPOINT WORK AREA
         L     R10,QVCKPT     LOAD BASE REG
         USING QDISPLAY,R9    BASE REG FOR DISPLAY WORK AREA
         L     R9,QVDSPL      LOAD BASE REG
         USING WORK,R13
***********************************************************************
*                                                                     *
*   CALL FINDJOB TO LOCATE THE JQE, JCT, AND IOT                      *
*                                                                     *
***********************************************************************
         L     R15,=V(FINDJOB) ROUTINE TO FIND JOB
         BALR  R14,R15        GO TO IT
         XC    QPDSID,QPDSID  NO LONGER LOOKING AT A DATA SET     GP@P6
         CLI   PF3LEVEL+1,2   MANUAL 'DD' FROM SELECTED SYSOUT?   GP@P6
         BNE   *+8            NO, LEAVE PF3 LEVEL ALONE           GP@P6
         MVI   PF3LEVEL+1,1   YES, REDUCE TO LEVEL 1              GP@P6
***********************************************************************
*                                                                     *
*   DETERMINE JOB TYPE (BATCH OR TSO)                                 *
*                                                                     *
***********************************************************************
         USING JCTSTART,R1    BASE REG FOR JCT
         USING PDBDSECT,R2    BASE REG FOR PDDB
         USING IOTSTART,R3    BASE REG FOR IOT
         L     R1,QCJCTA      A(JCT)
         CLI   QPARM2,C'S'                                        RNB11
         BE    DDTSO                                              RNB11
         CLC   JCTJOBID(3),=CL3'TSU' ?/TSO USER
         BE    DDTSO          YES. GO PROCESS
         CLC   JCTJOBID(3),=CL3'STC' ?/STARTED TASK
         BE    DDTSO          YES. GO PROCESS
***********************************************************************
*                                                                     *
*   LOCATE PDDB NUMBER 5                                              *
*                                                                     *
***********************************************************************
DDJOB    L     R3,QCIOTA      LOAD BASE REG
         LR    R4,R3          BASE OF IOT
         A     R4,IOTPDDBP    OFFSET BEYOND LAST PDDB
         LR    R2,R3          BASE OF IOT
         A     R2,QCPDDB1     OFFSET TO FIRST PDDB IN IOT
         MVC   QPDSID,=H'0'   NULLIFY VALIDITY FOR LISTDS
FINDDS   CLC   =H'5',PDBDSKEY IS THIS THE DATASET?
         BE    FOUNDDS        YES. CONTINUE.
         LA    R2,PDBLENG(R2) NO. LOOK AT NEXT PDDB.
         CR    R2,R4          HAVE WE GONE PAST THE LAST PDDB?
         BL    FINDDS         NO. TRY AGAIN.
         QTILT '*** JOB DOES NOT HAVE DD TABLE ***'
FOUNDDS  L     R4,PDBMTTR     DISK ADDR OF FIRST BLOCK
         L     R5,QCBLKA      ADDR OF DATASET BLOCK IOAREA
         MVC   QDMSG,QBLANK   BLANK OUT THE MESSAGE AREA
         B     FIRST          PROCESS DATASET
CPTSOID  CLC   QLOGON(0),QPARM1  IS PARM THE USER'S TSOID.
***********************************************************************
*                                                                     *
*   PROCESS DATASET                                                   *
*                                                                     *
***********************************************************************
NEXTBLK  L     R4,0(R5)       DISK ADDR OF NEXT BLOCK
FIRST    LTR   R4,R4          IS THE DISK ADDR ZERO?
         BZ    END            YES. END OF DATASET.
         BAL   R8,READ        READ A BLOCK
         CLC   QPJOBID,4(R5)  DOES THE JOBID MATCH?
         BNE   END            NO. END OF DATASET.
         CLC   =H'5',8(R5)    IS THE DSID 5?
         BNE   END            NO. END OF DATASET.
         LA    R4,10(R5)      ADDR OF FIRST RECORD IN BLOCK
***********************************************************************
*                                                                     *
*   PROCESS RECORDS                                                   *
*                                                                     *
***********************************************************************
NEXTREC  CLI   0(R4),X'FF'    IS LENGTH BYTE FF?
         BE    NEXTBLK        YES. END OF BLOCK.
         TM    1(R4),X'10'    IS THIS A SPANNED RECORD?
         BO    SPAN           YES. SKIP IT.
         SR    R6,R6          ZERO OUT REG
         IC    R6,0(R4)       INSERT LENGTH
         TM    5(R4),2        IS THIS AN EXEC RECORD?
         BO    EXEC           YES. PROCESS IT.
         TM    5(R4),4        IS THIS A DD RECORD?
         BO    DD             YES. PROCESS IT.
SKIPREC  LA    R4,3(R6,R4)    INCREMENT TO NEXT RECORD
         B     NEXTREC        PROCESS NEXT RECORD
SPAN     LH    R6,2(R4)       LENGTH OF SEGMENT
         TM    1(R4),X'08'    IS THIS THE FIRST SEGMENT?
         BO    SPANFRST       YES. USE HEADER LENGTH OF 6.
         LA    R4,4(R6,R4)    INCREMENT TO NEXT RECORD
         B     NEXTREC        PROCESS NEXT RECORD
SPANFRST LA    R4,6(R6,R4)    INCREMENT TO NEXT RECORD
         B     NEXTREC        PROCESS NEXT RECORD
END      QSTOP
***********************************************************************
*                                                                     *
*   PROCESS AN EXEC RECORD                                            *
*                                                                     *
***********************************************************************
EXEC     MVC   STEPNAME,QBLANK BLANK OUT THE STEPNAME
         CLI   7(R4),X'94'    IS THERE A STEPNAME?
         BNE   SKIPREC        NO. SKIP THE REST.
         SR    R1,R1          ZERO OUT R1
         IC    R1,9(R4)       LENGTH OF STEPNAME
         SH    R1,=H'1'       DECREMENT BY 1
         BM    SKIPREC        STEPNAME WAS ZERO LENGTH.
         EX    R1,MVCSTEP     MOVE THE STEPNAME
         B     SKIPREC        CONTINUE PROCESSING
***********************************************************************
*                                                                     *
*   PROCESS DD RECORDS                                                *
*                                                                     *
***********************************************************************
DD       TM    6(R4),X'30'    IS THIS A SYSIN OR SYSOUT DD?
         BZ    SKIPREC        NO. SKIP THE RECORD.
         MVC   DDN,QBLANK     BLANK OUT THE DDNAME
         MVC   DSID,QBLANK    BLANK OUT THE DSID
         MVC   DSRECCT,QBLANK BLANK OUT THE DS RECORD COUNT
         MVC   DSCLASS,QBLANK BLANK OUT THE DS CLASS
         LA    R7,7(R4)       ADDR OF FIRST KEY
         LR    R8,R6          REMAINING LENGTH OF RECORD
         SR    R15,15         ZERO OUT R15
         SR    R14,R14        ZERO OUT R14
         SR    R1,R1          ZERO OUT R1
TRYFLD   CLI   0(R7),X'6E'    IS THIS THE DDNAME?
         BE    DDKEY          YES. PROCESS IT.
         CLI   0(R7),X'4A'    IS THIS THE DSNAME?
         BNE   NEXTFLD        NO. GET NEXT FIELD
         CLC   3(3,R7),=C'JES' YES. IS THIS TRULY A JES2 SYSIN/OUT DS?
         BE    DSKEY          YES. PROCESS IT.
NEXTFLD  IC    R1,1(R7)       NUMBER OF SUBFIELDS
         LA    R7,2(R7)       UPDATE LOCATION
         SH    R8,=H'2'       REMAINING COUNT
         SR    R8,R1          REMAINING COUNT
         BNP   SKIPREC        RECORD IS EXHAUSTED
         LTR   R1,R1          ARE THERE ANY SUBFIELDS?
         BZ    TRYFLD         NO. TRY NEXT FIELD.
LOOPFLD  TM    0(R7),X'80'    IS THIS A SUB-SUB-FIELD
         BZ    NOSUB          NO. CONTINUE.
         NI    0(R7),X'7F'    CLEAR THE HEX 80 BIT
         IC    R14,0(R7)      NUMBER OF SUB-SUB-FIELDS
         LA    R7,1(R7)       UPDATE LOCATION
         SH    R8,=H'1'       REMAINING COUNT
         SR    R8,R14         REMAINING COUNT
         BNP   SKIPREC        RECORD IS EXHAUSTED
         AR    R1,R14         INCREASE NUMBER OF SUBFIELDS
         B     YESSUB         DECREMENT AND TRY AGAIN
NOSUB    IC    R15,0(R7)      SUBFIELD LENGTH
         LA    R7,1(R15,R7)   ADD TO LOCATION
         SR    R8,R15         REMAINING COUNT
         BNP   SKIPREC        RECORD IS EXHAUSTED
YESSUB   BCT   R1,LOOPFLD     DO NEXT SUBFIELD
         B     TRYFLD         TRY NEXT FIELD
DDKEY    IC    R1,2(R7)       LENGTH OF DDNAME
         LTR   R1,R1          IS THE LENGTH ZERO?
         BZ    NEXTFLD        YES. SKIP THE FIELD.
         BCTR  R1,0           DECREMENT BY 1
         EX    R1,MVCDDN      MOVE THE DDNAME
         B     NEXTFLD        PROCESS NEXT FIELD
DSKEY    MVC   DSID+1(3),20(R7)  MOVE THE DSID
         L     R15,=V(FINDPDDB) ADDR OF FINDPDDB MODULE
         BALR  R14,R15        GO TO IT
         QHEAD HEADING,X'24',TYP=QDDD,DMY=Y        GREEN REVERSE  GP@P6
         AIF   (NOT &QPFK).DDNOSEL                                GP@P6
         MVI   QDMSG,X'0B'    INPUT HIGH INTENSITY                GP@P6
         MVI   QDMSG+1,C'.'   SUPPLY SELECTION FIELD DOT          GP@P6
         MVI   QDMSG+2,X'0C'  OUTPUT LOW INTENSITY                GP@P6
.DDNOSEL ANOP                                                     GP@P6
         LA    R1,QDMSG       ADDR OF MESSAGE LINE
         ST    R1,QDMSGA      STORE IN MESSAGE ADDR
         MVC   QDMLNG,=H'80'  MESSAGE LENGTH
         L     R15,=V(DISPLAY) ADDR OF DISPLAY MODULE
         BALR  R14,R15        GO TO IT
         B     SKIPREC        PROCESS NEXT RECORD
***********************************************************************
*                                                                     *
*   PROCESS DD TSU                                                    *
*                                                                     *
***********************************************************************
DDTSO    L     R5,QCBLKA      ADDR OF DATASET BLOCK IOAREA
         LR    R3,R5          BASE OF IOAREA
         L     R4,JCTSPIOT    ADDR OF FIRST SPIN IOT
TSO010   LTR   R4,R4          IS IOT ADDR ZERO?
         BZ    DDJOB          YES, GO READ REGULAR IOT'S
         BAL   R8,READ        READ IOT
         LR    R4,R3          BASE OF IOT
         A     R4,IOTPDDBP    OFFSET BEYOND LAST PDDB
         LR    R2,R3          BASE OF IOT
         A     R2,QCPDDB1     OFFSET TO FIRST PDDB IN IOT
TSO020   CLI   PDBFLAG1,X'00' IS THIS PDDB VALID
         BE    TSO040         NO, GET NEXT IOT
         MVC   QDMSG,QBLANK   BLANK MESSAGE LINE
         MVC   DDN,=CL8'SPIN-DS'      MOVE IN DDNAME
         SR    R0,R0          CLEAR REG 0
         LH    R0,PDBDSKEY    CONVERT
         CVD   R0,CONVERT        DATA SET
         MVC   DSID,ED4               ID  TO
         ED    DSID,CONVERT+6             ZERO
         L     R0,PDBRECCT    CONVERT
         CVD   R0,CONVERT        RECORD
         MVC   DSRECCT,ED8          COUNT TO
         ED    DSRECCT,CONVERT+4        CHARACTER
         MVC   DSCLASS,PDBCLASS  MOVE IN SYSOUT CLASS
         AIF   (&QSP).RNB12A                                      RNB12
         TM    PDBFLAG1,PDB1PSO  HAS DATA SET BEEN PRINTED
         BO    TSO030         NO
         MVC   MESSAGE,PRTMSG INDICATE DATA SET PRINTED
.RNB12A  ANOP
TSO030   QHEAD HEADING,X'24',TYP=QDDD,DMY=Y        GREEN REVERSE  GP@P6
         AIF   (NOT &QPFK).TSNOSEL                                GP@P6
         MVI   QDMSG,X'0B'    INPUT HIGH INTENSITY                GP@P6
         MVI   QDMSG+1,C'.'   SUPPLY SELECTION FIELD DOT          GP@P6
         MVI   QDMSG+2,X'0C'  OUTPUT LOW INTENSITY                GP@P6
.TSNOSEL ANOP                                                     GP@P6
         LA    R1,QDMSG       ADDR OF MESSAGE LINE
         ST    R1,QDMSGA      STORE IN MESSAGE ADDR
         MVC   QDMLNG,=H'80'  MESSAGE LENGTH
         L     R15,=V(DISPLAY) ADDR OF DISPLAY MODULE
         BALR  R14,R15        GO TO IT
         LA    R2,PDBLENG(R2) LOOK AT NEXT PDDB
         CR    R2,R4          HAVE WE GONE PAST THE LAST PDDB
         BL    TSO020         NO, TRY AGAIN
TSO040   L     R4,IOTIOTTR    DISK ADDR OF NEXT IOT
         B     TSO010         GO SEARCH THE NEXT IOT
***********************************************************************
*                                                                     *
*   READ A BLOCK FROM HASPACE                                         *
*                                                                     *
***********************************************************************
READ     ST    R4,QCTRAK      STORE DISK ADDR
         LR    R1,R5          IOAREA ADDRESS
         L     R15,=V(READSPC) ADDR OF ROUTINE TO READ HASPACE
         BALR  R14,R15        GO TO IT
         BR    R8             RETURN TO CALLER
***********************************************************************
*                                                                     *
*   MISCELLANY                                                        *
*                                                                     *
***********************************************************************
         LTORG
MVCSTEP  MVC   STEPNAME(1),10(R4)
MVCDDN   MVC   DDN(1),3(R7)
         AIF   (NOT &QPFK).DDNOESS                                GP@P6
HEADING  DC   CL80' S  STEPNAME    DDNAME      DSID      LINES   CLASS'
         AGO   .DONEHDG                                           GP@P6
.DDNOESS ANOP                                                     GP@P5
HEADING  DC   CL80'    STEPNAME    DDNAME      DSID      LINES   CLASS'
.DONEHDG ANOP                                                     GP@P5
ED4      DC    X'40202120'
ED5      DC    X'4020202120'
ED8      DC    X'4020202020202120'
PRTMSG   DC    CL15'ALREADY PRINTED'
         DROP  ,                   DROP ALL ADDRESSINGS           NERDC
SYMDEL   DSECT ,                   KILL SYM CARD GENERATION       UF023
DDNAME   CSECT ,                                                  UF023
JCT      EQU   0
BUFSTART EQU   0
BUFDSECT EQU   0
         $TAB
         $JCT
         $PDDB
         $IOT
WORK     DSECT
         DS    CL72
CONVERT  DS    D
         QCOMMON
         ORG   QDMSG
         DS    CL4
STEPNAME DS    CL8
         DS    CL4
DDN      DS    CL8 END OF DATA. LAST REC #'
         DS    CL4
DSID     DS    CL4
         DS    CL4
DSRECCT  DS    CL8
         DS    CL4
DSCLASS  DS    CL1
         DS    CL6
MESSAGE  DS    CL15
SYMNODEL DSECT ,                   RESTORE SYM CARD GENERATION    UF023
         END
./ ADD NAME=DISPLAY  8057-02172-06336-1949-00543-00203-00000-GREG
DISPLAY  QSTART 'QUEUE COMMAND - 3270 DISPLAY ROUTINES'
***********************************************************************
* RNB CHANGES:                                                        *
*     (1) RNB13 - MODIFICATIONS TO FIX PROBLEMS WITH TCAM FULL-SCREEN *
*                 PROCESSING OF TEST-REQUEST, SYSTEM REQUEST, AND THE *
*                 PA2/PA3 KEYS.                                       *
*     (2) RNB14 - MODIFICATIONS TO FIX PROBLEMS FULL-SCREEN           *
*                 PROCESSING. THIS ONE ALLOWS THE USER TO TYPE IN THE *
*                 TOP COMMAND LINE WITHOUT QUEUE MISINTERPRETING WHAT *
*                 WAS ENTERED. (TRY THE DO COMMAND FROM BOTH PLACES   *
*                 WITHOUT THE MOD TO SEE THE EFFECT.)                 *
*     (3) RNB15 - RESTORE PFK DEFINITIONS FOR PF7 AND PF8 TO ORIGINAL *
*                 ICBC VALUES OF -27 AND +27. WE DON'T HAVE THE OTHER *
*                 3278 MODELS, AND PARTIAL SCROLLING IS EASIER AND    *
*                 MORE SPF CONSISTENT WITH THE ORIGINAL VALUES. ONLY  *
*                 IF QRNB=1.                                          *
***********************************************************************
         GBLB  &QPFK          PF-KEY OPTION. DEFINED BY QSTART     ICBC
         GBLB  &QRNB                                              RNB13
         USING QDISPLAY,R10   BASE REG FOR DISPLAY WORK AREA
         L     R10,QVDSPL     ADDR OF DISPLAY WORK AREA
         USING QCPRINT,R9     BASE REG FOR PRINT   WORK AREA       FCI*
         L     R9,QVPRINT     ADDR OF PRINT   WORK AREA            FCI*
***********************************************************************
*                                                                     *
*   CHECK FOR ROOM ON SCREEN                                          *
*                                                                     *
***********************************************************************
         MVI   QDOVER,0       ZERO OUT THE PAGE OVERFLOW INDICATOR
         L     R1,QDPLUS@     POINT TO PLUS SIGN POSITION         GP@P6
         MVI   0(R1),C' '     BLANK THE OVERFLOW INDICATOR        GP@P6
         LH    R4,QDMLNG      LOAD MSG LENGTH
         C     R4,QDSCRLEN    IS THE MSG LENGTH > SCRSIZE?  GP@P6 UF003
         BH    RETURN         YES. GO AWAY.
         MVC   QPRSAVE,QDTLINE        SAVE SUBTITLE LINE ON ENTRY  FCI*
         LTR   R4,R4          IS MSG LENGTH ZERO?
         BZ    WRTSCR         YES. WRITE SCREEN.
         MVI   0(R1),C'+'     INDICATE SCREEN OVERFLOW            GP@P6
         AH    R4,QDNEXT      ADD CURRENT LOCATION ON SCREEN
         C     R4,QDSCRLEN    IS THERE ROOM ON THE SCREEN?  GP@P6 UF003
         BH    WRTSCR         NO. WRITE SCREEN.
***********************************************************************
*                                                                     *
*   MOVE THE MESSAGE TO THE SCREEN                                    *
*                                                                     *
***********************************************************************
DSP2     LH    R7,QDMLNG      LOAD MESSAGE LENGTH
         LTR   R7,R7          IS MESSAGE LENGTH ZERO?
         BZ    RETURN         YES. RETURN.
         LH    R4,QDNEXT      LOAD CURRENT SCREEN LINE NUMBER
         LR    R1,R4          SAVE LINE NUMBER
         A     R4,QDLINE1@    LOAD ADDRESS OF NEXT LINE           GP@P6
         L     R6,QDMSGA      LOAD ADDR OF MESSAGE
         LH    R5,QDLNELEN    LENGTH MUST BE MULTIPLE OF LINESIZE UF003
DSP3     CR    R5,R7          IS 5 NOT LESS THAN 7?
         BNL   DSP4           YES. GO DO IT.
         AH    R5,QDLNELEN    INCR BY LINE LENGTH                 UF003
         B     DSP3           TRY AGAIN
DSP4     AR    R1,R5          UPDATE LINE NUMBER
         STH   R1,QDNEXT      STORE LINE NUMBER
         LR    R14,R4         SAVE TARGET ADDRESS                 GP@P6
         LR    R15,R5         SAVE TARGET LENGTH                  GP@P6
         MVCL  R4,R6          MOVE THE MESSAGE TO THE SCREEN
         LR    R4,R14         COPY TARGET ADDRESS                 GP@P6
         LA    R6,QDSCRTXT    POINT TO PRIMARY BUFFER             GP@P6
         SR    R14,R6         GET TARGET SCREEN LOCATION          GP@P6
         A     R14,QDSHADO@                                       GP@P6
         ICM   R7,8,QDLNCODE  GET SHADOW DISPLAY CODE             GP@P6
         LR    R5,R14         SAVE TARGET ADDRESS                 GP@P6
         MVCL  R14,R6         PROPAGATE DISPLAY CODE IN SHADOW    GP@P6
         CLI   0(R4),X'0B'    HIGH INTENSITY INPUT FIELD?         GP@P6
         BNE   RETURN         NO                                  GP@P6
         MVI   1(R5),X'01'    YES, SHOW SELECTION DOT IN BLUE     GP@P6
         CLI   10(R4),X'0B'   HIGH INTENSITY INPUT FIELD?         GP@P6
         BNE   RETURN         NO                                  GP@P6
         MVI   11(R5),X'02'   YES, SHOW JOB CLASS IN RED          GP@P6
         CLI   13(R4),X'06'   YELLOW DISPLAY LINE?                GP@P6
         BE    RETURN         YES, LEAVE CLASS IN RED             GP@P6
         MVI   11(R5),X'04'   NO, SHOW JOB CLASS IN GREEN         GP@P6
***********************************************************************
*                                                                     *
*   RETURN TO CALLER                                                  *
*                                                                     *
***********************************************************************
RETURN   QSTOP
***********************************************************************
*                                                                     *
*   WRITE A FULL SCREEN, WAIT FOR REPLY                               *
*            (TRANSLATE OF UNDISPLAYABLES NOW DONE IN Q15 - GP@P6)    *
***********************************************************************
WRTSCR   L     R1,QDPLUS@     NO, POINT TO PF3 MEANING INDICATOR  GP@P6
         MVC   1(7,R1),QBLANK CLEAR PF3 MEANING OVERRIDE LABEL    GP@P6
         TM    QFLAG1,QFLG1HLP  IN HELP WITH VALID DATA SET?      GP@P6
         BNO   WRTHLPOK       NO                                  GP@P6
         MVC   2(6,R1),=C'PF3=+0'                                 GP@P6
         B     WRTLEVEL       YES, LEVEL 2 SO PF3 IS "EXIT HELP"  GP@P6
WRTHLPOK CLI   PF3LEVEL+1,1   ANY COMMAND LEVELS STACKED?         GP@P6
         BL    WRTLEVEL       NO, DISPLAY TEXT NOW READY          GP@P6
         MVC   2(6,R1),=C'PF3=DD'                                 GP@P6
         BH    WRTLEVEL       YES, LEVEL 2 SO PF3 MEANS 'DD'      GP@P6
         MVC   6(2,R1),PF3CMD1     LEVEL 1 SO SHOW ACTUAL MEANING GP@P6
WRTLEVEL L     R15,=V(BLD3270)                                    GP@P6
         BALR  R14,R15        GO CONSTRUCT 3270 DATA STREAM       GP@P6
         SPACE 1                                                  UF003
TPUTSCRN DS    0H                                                 UF003
         L     R0,QDLENGTH    LOAD LENGTH FOR TPUT          GP@P6 UF003
         L     R1,QDCBPRM4    POINT TO DATA STREAM                GP@P6
         MVC   1(1,R1),QDSCRO1 COPY EW OR EWA COMMAND             GP@P6
         TM    QFLAG1,QFLG1RSH                                    GP@P6
         BO    RESHOWOK       LEAVE EW OR EWA FOR RESHOW          GP@P6
         MVI   1(R1),X'F1'    REPLACE COMMAND WITH ORDINARY WRITE GP@P6
RESHOWOK CLC   QDSCRPLN,=F'4096'                                  GP@P6
         BNH   TPUTFLSC       TPUT FULLSCR IS SUFFICIENT          GP@P6
         LA    R15,1(,R1)     SKIP ESCAPE - POINT TO VTAM COMMAND GP@P6
         BCTR  R0,0           DECREMENT DATA STREAM LENGTH        GP@P6
         OI    1(R15),X'02'   SET WCC TO UNLOCK KEYBOARD          GP@P6
         TPUT  (15),(0),NOEDIT,MF=(E,QTPUT) NOEDIT FOR 14-BIT ADR GP@P6
         B     TPUTDONE       TPUT HAS NOW BEEN ISSUED            GP@P6
TPUTFLSC ICM   R1,8,=X'03'    LOAD FLAGS FOR FULLSCR              GP@P6
         TPUT  (1),(0),R      DISPLAY NEW SCREEN IMAGE            GP@P6
TPUTDONE MVC   QDTLINE,QPRSAVE        RESTORE SUBTITLE INFO        FCI*
         AIF  (&QPFK).PFK1    SKIP NON-PFK CODE                    ICBC
         LA    R1,QDREPLY     POINT TO INPUT BUFFER               GP@P6
         LA    R0,L'QDREPLY   GET INPUT BUFFER LENGTH             GP@P6
         ICM   R1,8,=X'80'    SET FLAGS FOR TGET EDIT             GP@P6
         TGET  (1),(0),R      READ TERMINAL INPUT                 GP@P6
         STH   R1,QDRLNG      STORE LENGTH OF REPLY
         CH    R15,=H'12'     IS INPUT LONGER THAN BUFFER?
         BNE   NOCLEAR        NO. CONTINUE.
         TCLEARQ INPUT        CLEAR THE QUEUE
NOCLEAR  DS    0H
         AGO   .PFK2                                               ICBC
.PFK1    ANOP                                                      ICBC
         LA    R6,QDREPLY                                          ICBC
         XC    PFREPLY,PFREPLY                                     ICBC
         XC    QDREPLY,QDREPLY                                     ICBC
         LA    R1,PFREPLY     POINT TO INPUT BUFFER               GP@P6
         LA    R0,L'PFREPLY   GET INPUT BUFFER LENGTH             GP@P6
         ICM   R1,8,=X'81'    SET FLAGS FOR TGET ASIS             GP@P6
         TGET  (1),(0),R      READ TERMINAL INPUT                 GP@P6
         LR    R5,R1          COPY THE INPUT LENGTH               GP@P6
         CH    R15,=H'12'     IS INPUT LONGER THAN BUFFER?         ICBC
         BNE   NOCLEAR        NO. CONTINUE.                        ICBC
         TCLEARQ INPUT        CLEAR THE QUEUE                      ICBC
NOCLEAR  OI    QFLAG1,QFLG1RSH   FLAG RESHOW REQUEST              GP@P6
         CLI   PFCODE,X'6E'      PA2?                             RNB13
         BE    TPUTSCRN          /YES - GO RESHOW SCREEN          RNB13
         CLI   PFCODE,X'6B'      PA3?  (TCAM GENERATED)           RNB13
         BE    TPUTSCRN          /YES - GO RESHOW SCREEN          RNB13
         NI    QFLAG1,255-QFLG1RSH      NOT RESHOW REQUEST        GP@P6
***********************************************************************
*                                                                     *
*   PLACE INPUT TEXT INTO SCREEN IMAGE                GP@P6 JUNE 2002 *
*                                                                     *
***********************************************************************
         L     R0,QDCBPRM4       POINT TO A COPY AREA
         L     R1,QDSCRPLN       GET SCREEN SIZE
         LA    R14,QDSCRTXT      POINT TO SCREEN TEXT
         LR    R15,R1            GET SCREEN SIZE
         MVCL  R0,R14            COPY PRE-INPUT SCREEN CONTENTS
         XC    QDTLINE,QDTLINE   CLEAR COMMAND ECHO FIELD
         LA    R4,PFREPLY        POINT TO INPUT BUFFER
NEWFIELD SLR   R1,R1             CLEAR FOR INSERT
         ICM   R1,3,1(R4)        CATER FOR UNLIKELY 14-BIT ADDRESS
         TM    1(R4),X'40'       14-BIT ADDRESS?
         BZ    BINADROK          YES, BUT THAT MEANS SCREEN > 4096 LOCS
         NI    1(R4),X'3F'       REMOVE 3270 "PARITY" BITS
         NI    2(R4),X'3F'       REMOVE 3270 "PARITY" BITS
         SLR   R1,R1             CLEAR FOR INSERT
         IC    R1,2(,R4)         LOAD SCREEN LOCATION OF FIELD
         SLL   R1,2
         ICM   R1,2,1(R4)
         SRL   R1,2
BINADROK CLI   0(R4),X'11'       LOOKING AT AN INPUT FIELD?
         BNE   CRSELCTN          NO, PROCESS CURSOR SELECTION
         LA    R4,3(,R4)         POINT PAST SBA ORDER
         SH    R5,=H'3'          GET DATA LENGTH SBA ORDER
         BNP   SELCHARS          INPUT ENDED WITH NULL FIELD
         LA    R1,QDSCRTXT(R1)   POINT TO INPUT AREA IN SCREEN IMAGE
INCHARLP CLI   0(R4),X'11'       FOUND NEXT SBA ORDER?
         BE    NEWFIELD          YES, IT IS A NEW INPUT FIELD
         MVC   0(1,R1),0(R4)     NO, COPY THE TYPED CHARACTER
         LA    R1,1(,R1)         POINT TO NEXT SCREEN LOCATION
         LA    R4,1(,R4)         POINT TO NEXT INPUT BYTE
         BCT   R5,INCHARLP       GO PROCESS NEXT INPUT BYTE
         B     SELCHARS          LAST FIELD NOW PROCESSED
***********************************************************************
*                                                                     *
*   PROCESS "POINT-AND-SHOOT"                     GP@P6 NOVEMBER 2002 *
*                                                                     *
***********************************************************************
*
*  CONTROL COMES HERE AFTER A 3270 BUFFER ADDRESS HAS BEEN DECODED
*  BUT THE BYTE BEFORE THE BUFFER ADDRESS WAS NOT AN SBA.  THIS
*  HAPPENS WHEN THE BYTE BEFORE THE BUFFER ADDRESS IS THE AID, AND
*  THE BUFFER ADDRESS IS THE CURSOR LOCATION.  WHEN THIS HAPPENS
*  "POINT-AND-SHOOT" PROCESSING IS PERFORMED.
*
*  "POINT-AND-SHOOT" TAKES PLACE WHEN THE CURSOR IS PLACED ON A
*  SELECTION FIELD DOT.  IN QUEUE (TO DATE) ALL SELECTION FIELDS
*  ARE IN THE SECOND SCREEN COLUMN FOLLOWING A FIELD ATTRIBUTE BYTE
*  IN THE FIRST SCREEN COLUMN.  THE MAIN INPUT AREAS ON THE FIRST AND
*  LAST SCREEN LINES DO NOT START AT THE LEFT EDGE OF THE SCREEN SO
*  THERE IS NO CHANCE OF GENERATING INPUT FOR EITHER OF THOSE FIELDS.
*
*  INTERNALLY, AN 'S' IS PLACED WHERE THE CURSOR WAS (AFTER THE
*  VALIDATION MENTIONED ABOVE) FOR SUBSEQUENT PROCESSING.
*
*  NOTE THAT THIS TAKES PLACE BEFORE THE PROCESSING OF TYPED-IN INPUT
*  AND SO IT CAN BE OVERLAID BY TEXT TYPED IN INCLUDING A BLANK, BUT
*  EXCLUDING A DELETE OR FIELD ERASURE.
*
CRSELCTN TM    QFLAG2,QFLG2PNS   IS "POINT-AND-SHOOT" GENNED?
         BNO   PNSDONE           NO, SUPPRESS IT
         BCTR  R1,0              GET LOCATION OF PREVIOUS BYTE
         LA    R4,QDSCRTXT(R1)   POINT TO THIS PREVIOUS BYTE
         CLI   0(R4),X'0B'       SELECTION CODE ATTRIBUTE BYTE?
         BNE   PNSDONE           NO, CANNOT BE "POINT-AND-SHOOT"
         LH    R15,QDLNELEN      GET THE LINE LENGTH
         SLR   R0,R0             CLEAR FOR DIVIDE
         DR    R0,R15            GET RELATIVE LINE AND COLUMN
         LTR   R0,R0             WAS CURSOR IN COLUMN 2?
         BNZ   PNSDONE           NO, DO NOT SET JOB CLASS TO S
         MVI   1(R4),C'S'        YES, SET IMPLIED SELECTION CODE
         LA    R4,PFREPLY+3      POINT TO INPUT BUFFER
         SH    R5,=H'3'          GET DATA LENGTH AFTER HEADER
         BP    NEWFIELD          PROCESS INPUT FIELD
         B     SELCHARS          NO 3270 FIELDS SO PROCESS THIS 'S'
PNSDONE  LA    R4,PFREPLY+3      POINT TO INPUT BUFFER
         SH    R5,=H'3'          GET DATA LENGTH AFTER HEADER
         BP    NEWFIELD          PROCESS INPUT FIELD
         SLR   R1,R1             RESET TEXT LENGTH
         B     NULLTEXT          NO 3270 FIELDS WERE MODIFIED
***********************************************************************
*                                                                     *
*   PROCESS LINE SELECTION CODES                      GP@P6 JUNE 2002 *
*                                                                     *
***********************************************************************
SELCHARS L     R5,QDLINE1@       POINT TO FIRST DETAIL LINE
SELCHRLP CLI   0(R5),X'0B'       SELECTION CODE ATTRIBUTE BYTE?
         BNE   PRIMCMND          NO, NO MORE SELECTION CODES ON SCREEN
         LA    R1,1(,R5)         POINT TO ACTION/SELECTION CODE
         CLI   1(R5),C'.'        SELECTION CODE TYPED HERE?
         BH    DOACTION          YES
CHKJBCLS CLI   10(R5),X'0B'      JOB CLASS CHANGE ALLOWED?
         BNE   NEXTSELN          NO, CANNOT HAVE BEEN UPDATED
         CLI   11(R5),C'.'       CLASS JUST BLANKED OUT?
         BNH   NEXTSELN          YES
         OI    11(R5),X'40'      FOLD TEXT TO UPPER CASE
         LR    R1,R5             POINT TO DISPLAY LINE
         LA    R0,QDSCRTXT       POINT TO START OF SCREEN BUFFER
         SR    R1,R0             GET OFFSET
         A     R1,QDCBPRM4       POINT TO PRE-INPUT SCREEN CONTENTS
         CLC   11(1,R5),11(R1)   ANY CHANGE?
         BE    NEXTSELN          NO
         LA    R1,11(,R5)        YES, POINT TO NEW TEXT
         CLI   0(R1),C'A'        VALIDATE CLASS
         BL    BADCOMND
         CLI   0(R1),C'9'
         BH    BADCOMND          HOW WAS THAT DONE?
         CLI   0(R1),C'0'
         BNL   GOODCLS
         MVC   80(1,R13),0(R1)
         NI    80(R13),X'0F'
         CLI   80(R13),0
         BE    BADCOMND          PROBABLY BRACE OR BACKSLASH
         CLI   80(R13),9
         BH    BADCOMND
         CLI   0(R1),X'E1'       FOR COMPLETENESS...
         BE    BADCOMND
GOODCLS  MVC   OSCMDTXT,=CL16'$TJ0000,C=?'
         MVC   OSCMDTXT+10(1),0(R1)
         OC    OSCMDTXT+3(4),34(R5)
         MODESET MODE=SUP,KEY=ZERO
         LA    R1,OSCMDLEN       POINT TO SYSTEM COMMAND
         SLR   R0,R0             PRETEND TO BE MASTER CONSOLE
         SVC   34                ISSUE OS COMMAND
         MODESET MODE=PROB,KEY=NZERO
NEXTSELN AH    R5,QDLNELEN       POINT TO NEXT DISPLAY LINE
         B     SELCHRLP          GO CHECK IT FOR A SELECTION CODE
DOACTION OI    0(R1),X'40'       FOLD TEXT TO UPPER CASE
         CLI   QDISPTYP,QDJQ     JQE/JOE DISPLAY?
         BE    DOACTNJQ          YES
         CLI   QDISPTYP,QDDD     FILE DISPLAY?
         BE    DOACTNDD          YES
         CLI   QDISPTYP,QDDC     ACTIVE ADDRESS SPACE DISPLAY?
         BE    DOACTNDC          YES
         CLI   QDISPTYP,QDXI     INITIATOR/TERMINATOR DISPLAY?
         BE    DOACTNXI          YES
BADCOMND LA    R0,QDSCRTXT       POINT TO START OF SCREEN TEXT
         SR    R1,R0             GET OFFSET OF PROBLEM INPUT
         A     R1,QDSHADO@       POINT TO ITS SHADOW
         MVI   0(R1),X'22'       HIGHLIGHT IN REVERSE VIDEO RED
         B     WRTSCR            GO SHOW THE UPDATED SCREEN IMAGE
DOACTNDC LA    R14,23(,R5)       POINT TO "DC" JOB NUMBER
         LA    R7,13(,R5)        POINT TO "DC" JOB NAME
         CLI   0(R1),C'C'        CANCEL JOB?
         BNE   DOACTCMD          NO, BRANCH TO COMMON CODE
         MVC   OSCMDTXT,QBLANK   YES, CLEAR RESIDUAL DATA
         MVC   OSCMDTXT(4),=C'C U='
         MVC   OSCMDTXT+4(8),13(R5)
         CLI   23(R5),C'2'       REALLY A TSO USER?
         BE    AUTHCHEK          YES, GO VERIFY AUTHORITY
         MVC   OSCMDTXT+2(10),OSCMDTXT+4
         B     AUTHCHEK          GO VERIFY AUTHORITY
DOACTNJQ LA    R14,33(,R5)       NO, POINT TO "ST" JOB NUMBER
         LA    R7,22(,R5)        POINT TO "ST" JOB NAME
DOACTCMD CLI   0(R1),C'A'        RELEASE JOB?
         BE    JQJOBCMD          YES
         CLI   0(R1),C'H'        HOLD JOB?
         BE    JQJOBCMD          YES
         CLI   0(R1),C'C'        CANCEL JOB?
         BE    JQJOBCMD          YES
         CLI   0(R1),C'O'        RELEASE HELD SYSOUT?        2006-12-02
         BE    JQJOBCMD          YES                         2006-12-02
         CLI   0(R1),C'P'        PURGE JOB?
         BE    PURGECHK          YES
         LA    R15,=C'DD'
         CLI   0(R1),C'D'        DISPLAY DATA SETS?
         BE    JQSUBCMD          YES
         LA    R15,=C'SL'
         CLI   0(R1),C'S'        DISPLAY DATA SET CONTENTS?
         BE    JQSUBCMD          YES
         LA    R15,=C'JL'
         CLI   0(R1),C'L'        SHOW JOB LOG?
         BE    JQSUBCMD          YES
         LA    R15,=C'JC'
         CLI   0(R1),C'J'        SHOW JCL?
         BE    JQSUBCMD          YES
         LA    R15,=C'JM'
         CLI   0(R1),C'M'        SHOW JOB MESSAGES?
         BNE   BADCOMND          NO, INVALID
JQSUBCMD MVC   QDTLINE(2),0(R15) LOAD SUBCOMMAND NAME
         MVC   QDTLINE+3(5),0(R14)    JOB NUMBER
         CLI   0(R15),C'S'       SLOG COMMAND?
         BNE   GOTOLVL1          NO, CONTINUE
         CLI   0(R14),C'1'       STARTED TASK JOB NUMBER?
         BNE   GOTOJLOG          NO, CANNOT BE SYSLOG
         CLC   =CL8'SYSLOG',0(R7)
         BE    GOTOLVL1          IS SYSLOG SO SLOG IS GOOD
GOTOJLOG MVC   QDTLINE(2),=C'JL' LOAD SUBCOMMAND NAME
GOTOLVL1 MVC   PF3CMD1,QSUBNAME  SAVE CURRENT SUBCOMMAND NAME
         MVC   QPARM1SV,QPARM1   SAVE CURRENT SUBCOMMAND OPERAND
         MVI   PF3LEVEL+1,1      INCREMENT "PF3 LEVEL"
         OI    QFLAG1,QFLG1SEL   INHIBIT RESET OF "PF3 LEVEL"
         B     PRIMCMND          GO PARSE "PRIMARY INPUT"
PURGECHK CLI   4(R5),C'H'        HELD OUTPUT?
         BE    DODELETE          YES
         CLI   4(R5),C'X'        JOB ON EXECUTE QUEUE?
         BNE   JQJOBCMD          NO
         MVC   OSCMDTXT,=CL16'$CJ0000,P'
         B     JQGOTCMD
DODELETE MVC   OSCMDTXT,=CL16'$OJ0000,C'
         B     JQGOTCMD
JQJOBCMD MVC   OSCMDTXT,=CL16'$?J0000  '
         MVC   OSCMDTXT+1(1),0(R1)
JQGOTCMD TM    0(R14),X'03'      IS CATEGORY BATCH JOB?
         BZ    JQGOTJOB          YES, PRIMED 'J' IS CORRECT
         SLR   R15,R15
         IC    R15,0(,R14)       LOAD FIRST POSSIBLE JOB NUMBER DIGIT
         LA    R0,C'1'-C'S'      1->S (STC)    2->T (TSU)
         SR    R15,R0
         STC   R15,OSCMDTXT+2    SET STARTED TASK OR TSO CATEGORY
JQGOTJOB OC    OSCMDTXT+3(4),1(R14)  SET JOB NUMBER
AUTHCHEK TM    QFLAG1,QFLG1APF   APF AUTHORIZED?
         BNO   BADCOMND          YES
         TM    QFLAG1,QFLG1OPR   GOT OPERATOR AUTHORITY?
         BO    ISSUECMD          YES, ALLOWED TO FIDDLE WITH ANY JOB
         LA    R15,QLOGON        POINT TO USER ID
         LA    R14,13(,R5)       POINT TO "DC" JOB NAME
         CLI   QDISPTYP,QDDC     GOT THE RIGHT DISPLAY?
         BE    JOBCHKLP          YES
         LA    R14,22(,R5)       NO, POINT TO "ST" JOB NAME
JOBCHKLP CLI   0(R15),C' '       END OF LOGON ID?
         BNH   ISSUECMD          YES, GOT A MATCH
         CLC   0(1,R14),0(R15)   JOBNAME STARTS WITH USERID?
         BNE   BADCOMND          NO, INVALID
         LA    R14,1(,R14)
         LA    R15,1(,R15)
         B     JOBCHKLP
DOACTNDD CLI   0(R1),C'S'        SELECT DATA SET?
         BNE   BADCOMND          NO, INVALID
         MVC   QDTLINE(4),=CL4'L * '
         MVC   QDTLINE+4(4),28(R5)
         CLI   PF3LEVEL+1,0      WAS 'DD' A "LEVEL 0" COMMAND?
         BE    GOTOLVL1          YES, GO SET "LEVEL 1"
         MVI   PF3LEVEL+1,2      NO, IT WAS "LEVEL 1" SO SET "LEVEL 2"
         OI    QFLAG1,QFLG1SEL   INHIBIT RESET OF "PF3 LEVEL"
         B     PRIMCMND          GO PARSE "PRIMARY INPUT"
DOACTNXI CLI   0(R1),C'S'        START AN INITIATOR/TERMINATOR?
         BE    INITACTN          YES
         CLI   0(R1),C'P'        DRAIN AN INITIATOR/TERMINATOR?
         BE    INITACTN          YES
         CLI   0(R1),C'Z'        HALT AN INITIATOR/TERMINATOR?
         BNE   BADCOMND          NO, INVALID
INITACTN MVC   OSCMDTXT,=CL16'$?I??'
         MVC   OSCMDTXT+1(1),0(R1)
         MVC   OSCMDTXT+3(2),5(R5)
         CLI   OSCMDTXT+3,C' '   LEADING BLANK IN INITIATOR NAME?
         BNE   ISSUECMD          NO
         MVC   OSCMDTXT+3(2),OSCMDTXT+4
ISSUECMD MODESET MODE=SUP,KEY=ZERO
         LA    R1,OSCMDLEN       POINT TO SYSTEM COMMAND
         SLR   R0,R0             PRETEND TO BE MASTER CONSOLE
         SVC   34                ISSUE OS COMMAND
         MODESET MODE=PROB,KEY=NZERO
         B     CHKJBCLS          DONE LINE UNLESS NEW JOB CLASS
*   FROM HERE ON R1 HAS THE TEXT LENGTH OF EITHER 0 OR 63
PRIMCMND LA    R1,63             ASSUME COMMAND TEXT IS PRESENT
NULLTEXT LA    R4,QDSCRTXT       POINT TO SCREEN IMAGE BUFFER
         A     R4,QDSCRPLN       POINT PAST SCREEN IMAGE BUFFER
         SH    R4,QDLNELEN       POINT TO LAST SCREEN LINE
         MVC   PFTXT,QDTLINE     COPY TOP LINE INPUT
         OC    PFTXT,QBLANK      FOLD ANY TOP LINE INPUT TO UPPER CASE
         CLC   PFTXT,QBLANK      ANY TOP LINE INPUT?
         BNE   DOPFCODE          YES, HAVE PRIMARY COMMAND
         MVC   PFTXT,8(R4)       NO, COPY BOTTOM LINE INPUT
         OC    PFTXT,QBLANK      FOLD BOTTOM LINE INPUT TO UPPER CASE
DOPFCODE XC    8(63,R4),8(R4)    RESET BOTTOM LINE INPUT
         L     R4,QDCBPRM4       POINT TO SCREEN CONTENTS SAVE AREA
         MVC   QDTLINE,16(R4)    RESTORE COMMAND ECHO FIELD
*   END OF REVISED INPUT DATA STREAM PROCESSING       GP@P6 JUNE 2002 *
         CLI   PFCODE,X'F0'      TEST-REQ/SYS-REQ?                RNB13
         BE    ENTKEY            /YES - TREAT AS ENTER            RNB13
         CLI   PFCODE,X'01'      OTHER KIND OF SYS-REQ?           RNB13
         BE    ENTKEY            /YES - TREAT AS ENTER            RNB13
         IC    R4,PFCODE                                           ICBC
         LA    R0,X'0F'                                      GP@P6 ICBC
         NR    R4,R0             EXTRACT PF-KEY NUMBER       GP@P6 ICBC
         CH    R4,=H'12'                                           ICBC
         BH    ENTKEY           "ENTER" KEY                        ICBC
         ICM   R0,3,QPDSID       LOOKING AT A DATA SET?           GP@P6
         BNZ   PF8OKAY           YES, LEAVE PF8/20 AS IS          GP@P6
         CH    R4,=H'8'          PF8/20?                          GP@P6
         BE    ENTKEY            YES, ALLOW "SCROLL DOWN" REQUEST GP@P6
PF8OKAY  CH    R4,=H'3'          PF3/15?                          GP@P6
         BNE   PF3OKAY           NO, GO INSERT PFK MEANING        GP@P6
         TM    QFLAG1,QFLG1HLP   IN HELP PROCESSING?              GP@P6
         BNO   PF3HLPOK          NO, GO CHECK "PF3 LEVEL"         GP@P6
         LA    R1,63             INPUT TEXT WILL BE PRESENT       GP@P6
         MVC   QDREPLY,QBLANK    CLEAR RESIDUAL DATA              GP@P6
         MVC   QDREPLY(3),=C'+ 0'                                 GP@P6
         B     NOTXT             GO PROCESS "OUTER" COMMAND       GP@P6
PF3HLPOK CLI   PF3LEVEL+1,0      DOES PF3 MEAN END?               GP@P6
         BE    PF3OKAY           YES, GO INSERT PFK MEANING       GP@P6
         LA    R1,63             INPUT TEXT WILL BE PRESENT       GP@P6
         MVC   QDREPLY,QBLANK    CLEAR RESIDUAL DATA              GP@P6
         MVC   QDREPLY(2),=C'DD' PREPARE FOR "SECOND LEVEL"       GP@P6
         LH    R0,PF3LEVEL       GET CURRENT "PF3 LEVEL"          GP@P6
         BCT   R0,NEWLEVEL       DECREMENT LEVEL                  GP@P6
         MVC   QDREPLY(2),PF3CMD1 REALLY WAS "FIRST LEVEL"        GP@P6
         MVC   QDREPLY+3(8),QPARM1SV                              GP@P6
NEWLEVEL OI    QFLAG1,QFLG1SEL   INHIBIT RESET OF "PF3 LEVEL"     GP@P6
         STH   R0,PF3LEVEL       SAVE NEW "PF3 LEVEL"             GP@P6
         B     NOTXT             GO PROCESS "OUTER" COMMAND       GP@P6
PF3OKAY  BCTR  R4,0                                                ICBC
         MH    R4,=H'5'                                            ICBC
         LA    R5,PFKTAB                                           ICBC
         LA    R5,0(R4,R5)                                         ICBC
         MVC   QDREPLY(5),0(R5)  MOVE PF-KEY VALUE                 ICBC
         LA    R5,5                                                ICBC
         LA    R6,3(,R6)                                           ICBC
         LTR   R1,R1             ANY TEXT ACTUALLY TYPED IN?      GP@P6
         LA    R1,63             INPUT TEXT IS NOW PRESENT        GP@P6
         BNP   NOTXT             NO, LEAVE WHOLE PFK COMMAND      RNB14
         MVC   0(60,R6),PFTXT    YES, OVERLAY 2 PFK-SUPPLIED CHRS RNB14
         B     NOTXT                                              RNB14
ENTKEY   EQU   *                                                   ICBC
         MVC   0(63,R6),PFTXT                                     RNB14
NOTXT    STH   R1,QDRLNG      STORE LENGTH OF REPLY                ICBC
.PFK2    ANOP                                                      ICBC
         OC    QDREPLY,QBLANK     UPPERCASE THE COMMAND            FCI*
         CLC   QDREPLY(2),=CL2'PR' POSSIBLE PRINT COMMAND?     PWF FCI*
         BNE   CLSCRN             NOPE..SPLIT NORMALLY             FCI*
         CLI   QDREPLY+2,C' '      POSSIBLE PRINT COMMAND?   2003-03-04
         BE    DOPRINT            YES                        2003-03-04
         CLI   QDREPLY+2,C'I'      POSSIBLE PRINT COMMAND?   2003-03-04
         BNE   CLSCRN             NOPE..SPLIT NORMALLY       2003-03-04
DOPRINT  EQU   *                                             2003-03-04
         L     R15,=V(PRINT)  FETCH PRINT ENTRY ADDRESS            FCI*
         BALR  R14,R15        AND CALL HIM                         FCI*
         LTR   R15,R15        HOW IS HIS RETURN CODE               FCI*
         BNZ   CLSCRN         NOTHING TO REPORT                    FCI*
*                                                                  FCI*
         B     WRTSCR         GO REBUILD AND REPOST SCREEN   GP@P6 FCI*
CLSCRN   L     R4,QDLINE1@    LOAD ADDRESS OF FIRST LINE     GP@P6 FCI*
         L     R5,QDSCRLEN    LOAD LENGTH OF SCREEN AREA    GP@P6 UF003
         SR    R6,R6          NO SENDING FIELD NEEDED              FCI*
         STH   R6,QDNEXT      STORE ZERO IN LINE NUMBER            FCI*
         SR    R7,R7          FILL SCREEN WITH NULLS               FCI*
         MVCL  R4,R6          CLEAR THE SCREEN                     FCI*
*
         L     R4,QDSHADO@    POINT TO THE SHADOW BUFFER          GP@P6
         AH    R4,QDLNELEN    POINT TO HEADING LINE SHADOW        GP@P6
         AH    R4,QDLNELEN    POINT TO THE DETAIL SHADOW          GP@P6
         L     R5,QDSCRLEN    LOAD LENGTH OF SCREEN AREA          GP@P6
         LA    R7,X'05'       RESET TO UNHIGHLIGHTED TURQUOISE    GP@P6
         SLL   R7,24          PROMOTE CODE TO PAD BYTE            GP@P6
         MVCL  R4,R6          CLEAR THE SHADOW                    GP@P6
*
         LH    R1,QDRLNG      STORE LENGTH OF REPLY
         LTR   R1,R1          WAS THERE A RESPONSE FROM USER?
         BNZ   INTER          YES. INTERRUPT PROCESSING.
         MVI   QDOVER,1       INDICATE PAGE OVERFLOW
         B     DSP2           CONTINUE PROCESSING
INTER    L     R13,QFRSTSA    GO BACK TO MAIN MODULE
         LM    R14,R12,12(R13) RESTORE REGISTERS FROM FIRST SAVEAREA
         BR    R10            ADDRESS OF INTERRUPT HANDLER IN QUEUE
***********************************************************************
*                                                                     *
*   MISCELLANY                                                        *
*                                                                     *
***********************************************************************
         LTORG
         AIF  (NOT &QPFK).PFK3                                     ICBC
* PF-KEY DEFINITIONS                                               ICBC
PFKTAB   DS    0CL60                                               ICBC
PF1      DC    CL5'H'                                              ICBC
PF2      DC    CL5'DA'                                       FCI*  ICBC
PF3      DC    CL5'E'                                              ICBC
PF4      DC    CL5'PRINT'                                    FCI*  ICBC
PF5      DC    CL5'F'                                              ICBC
PF6      DC    CL5'DI'                                             ICBC
*        AIF   (&QRNB).RNB15A                                     RNB15
*F7      DC    CL5'PB'                                            UF003
*F8      DC    CL5'PF'                                            UF003
*        AGO   .RNB15B                                            RNB15
*RNB15A  ANOP                                                     RNB15
PF7      DC    CL5'-  P '          USE SPF-LIKE SCROLLING  GP/MAH RNB15
PF8      DC    CL5'+  P '          USE SPF-LIKE SCROLLING  GP/MAH RNB15
*RNB15B  ANOP                                                     RNB15
PF9      DC    CL5'DO'                                             ICBC
PF10     DC    CL5'CO 1'                                           ICBC
PF11     DC    CL5'CO 41'                                          ICBC
PF12     DC    CL5'ST'                                             ICBC
OSCMDLEN DC    0F'0',H'20',H'0'                                   GP@P6
OSCMDTXT DC    CL16' '                                            GP@P6
SBATABLE DC    17X'00',X'11',238X'00'                             GP@P6
.PFK3    ANOP                                                      ICBC
SYMDEL   DSECT ,                   KILL SYM CARD GENERATION       UF023
         QCOMMON
SYMNODEL DSECT ,                   RESTORE SYM CARD GENERATION    UF023
         END
./ ADD NAME=FILE53
************************************************************************
*
*         F I L E   5 3   U P D A T E D   Q U E U E
*
************************************************************************

THIS FILE IS IN IEBCOPY UNLOAD FORMAT (80 X 32720).
     THIS VERSION OF THE COMMAND HAS A NUMBER OF ENHANCEMENTS AND
CLEANUP FIXES INSTALLED. THE SUPPORT FOR JES2 PRIOR TO 79/09 WAS REMOVED
AND THE CODE STANDARDIZED ON THE DUPLEX CHECKPOINT LEVEL. A SCREEN PRINT
FACILITY WAS ADDED. THE COMMAND RUNS AUTHORIZED AND NOW HAS SUPPORT FOR
CANCEL, REQUEUE, AND PURGE. THE PDDB SYSOUT COUNTS ARE LISTED ON THE DD
SUBCOMMAND. SUPPORT WAS ADDED TO FIND AND LIST TSO DYNAMICALLY SPUN
SYSOUT.
     THE COMMAND ONLY NEEDS TO RUN AUTHORIZED FOR THE FOLLOWING COMMANDS
CANCEL, REQUEUE, AND PURGE. IF YOU DO NOT MARK THE CODE AC=1, THE
PREVIOUS THREE COMMANDS WILL NOT FUNCTION.

 --- QUEUE COMMAND -----------------------------------------------------

  QUEUE SUBCOMMAND OPERAND        DEFAULT Q STATUS *
  Q                               CAN USE Q CKPT(DEVTYPE,VOLSER) TO GET
                                  NONSTANDARD CHECKPOINT.

 --- SYSTEM DISPLAYS ---------------------------------------------------

DA                  JOBS IN EXECUTION
DT                  DISPLAY TSO USERS
DS                  DISPLAY STARTED TASKS
DC (B/S/T)          DISPLAY CPU BATCH/STC/TSO
STATUS (LEVEL)      JOB STATUS. DEFAULT FOR STATUS IS * (TSO ID).

 --- INPUT QUEUE DISPLAYS ----------------------------------------------

DQ                  DISPLAY INPUT QUEUES
DI (CLASS)          DISPLAY ALL INPUT JOBS
AI (CLASS)          DISPLAY AVAILABLE JOBS
HI (CLASS)          DISPLAY HELD JOBS

 --- OUTPUT QUEUE DISPLAYS----------------------------------------------

DF                  DISPLAY OUTPUT QUEUES
DO (CLASS)          DISPLAY ALL OUTPUT JOBS
AO (CLASS)          DISPLAY AVAILABLE OUTPUT
HO (CLASS)          DISPLAY HELD OUTPUT

 --- JOB MODIFICATION SUBCOMMANDS --------------------------------------

CAN JOBNAME (PURGE) CANCEL FROM INPUT OR EXECUTION. DELETE OUTPUT IF
                     PURGE IS SPECIFIED.
REQ JOBNAME CLASS   CHANGE SYSOUT CLASS
DEL JOBNAME         DELETE HELD OUTPUT

 --- MISC SUBCOMMANDS --------------------------------------------------

SLOG STC# SEQ       LIST SYSTEM LOG.  ST SYSLOG WILL GET STC#. IF SEQ
                     IS NOT SPECIFED ZERO IS ASSUMED (CURRENT).
FTIME HH.MM.SS      POSITION SYSLOG TO TIME
H/HELP              HELP
E/END               EXIT

 --- JOB RELATED SUBCOMMANDS -------------------------------------------

DJ JOBNAME          DISPLAY JOB
JCL JOBNAME         LIST JOB JCL
JLOG JOBNAME        LIST JOB LOG
JMSG JOBNAME        LIST JOB MESSAGES
DD JOBNAME          JES2 DD SUMMARY
LIST JOBNAME DSID   LIST JES2 DATASET. OBTAIN DSID VALUES BY USING THE
                     DD SUBCOMMAND.

 --- LIST RELATED SUBCOMMANDS ---------

FIND 'STRING' COL(SS,EE)  FIND NEXT OCCURANCE OF 'STRING' IN THE DATA.
FALL 'STRING' COL(SS,EE)  FIND ALL OCCURANCES OF 'STRING' IN THE DATA.
                          STRING MUST BE IN QUOTES. COL DEFAULT IS ALL.

COL  #              POSITION TO COLUMN #
@    #              POSITION TO RECORD #
D/+  #              MOVE FORWARD # LINES
UP/- #              MOVE BACKWARD # LINES
TOP                 TOP OF CURRENT DATASET
BOTTOM              BOTTOM OF CURRENT DATASET
HF/HB #             FORWARD/BACKWARD # HALF PAGES
PF/PB #             FORWARD/BACKWARD # PAGES

                    DEFAULT VALUE FOR # IS 1.
                    SYNONYMS L-LIST F-FIND C-COLUMN T-TOP B-BOTTOM

 --------- LOGGING SUBCOMMANDS---------------

SAVE DSNAME TYPE    COPY DATASET
PRINT ON CLASS DEST OPEN SCREEN LOG
                    DEFAULT PRINT CLASS IS SYSOUT=A.
PRINT               PRINT SCREEN
PRINT OFF           CLOSE SCREEN LOG

 -------------------------------
 | PF1     | PF2     | PF3     |
 |   HELP  |   DA    |   END   |   PROGRAM FUNCTION KEY DEFINITIONS
 -------------------------------
 | PF4     | PF5     | PF6     |   TO SPECIFY OPERANDS FOR PF 5 OR
 |   PRINT |   FIND  |   DI    |   OPTIONALLY FOR PF 6,9,12 OR
 -------------------------------   TO OVERRIDE DEFAULTS FOR PF 4,7,8,10,
 | PF7     | PF8     | PF9     |   KEY IN THE VALUE AND PRESS THE KEY
 |   - 21  |   + 21  |   DO    |
 -------------------------------
 | PF10    | PF11    | PF12    |
 |  COL 1  |  COL 41 |   ST    |
 -------------------------------

 -------------------------- RESTRICTED SUBCOMMANDS ---------------------

XB MTTR             DISPLAY DISK RECORD
XD JOBNAME DSID     LIST ANY DATASET
XI                  DISPLAY ACTIVE INITIATORS
XJ JOBNAME          DISPLAY JQE AND JOES
XP PASSWORD         REQUEST FOR PASSWORD PROMPT. PROMPT IS A BLANK SCREE
                     THE PASSWARD AND IF SUCCESSFUL A MESSAGE WILL BE IS

INSTALLATION PROCEDURE FOR QUEUE:

     1. THERE ARE 36 MEMBERS IN THE DATASET.
        Q0 IS THE COMMON AREA.
        Q1 - Q27 ARE REENTRANT CODE.
        QCOMMON, QSTART, QSTOP, QTILT, AND $JQT ARE MACROS.
        HELP IS A TSO HELP MEMBER.
        ASSEMBLE IS THE JCL TO ASSEMBLE AND LINK QUEUE.
        TABLE IS A SAMPLE SMP JOB TO AUTHORIZE THE QUEUE COMMAND.

     2. EDIT MEMBER QCOMMON CHANGING THE FOLLOWING PARAMETERS:

        UNIT=XXXX THE DEVICE TYPE FOR SYS1.HASPCKPT.
        VOLSER=YYYYYY THE VOLUME SERIAL FOR SYS1.HASPCKPT.
        SID1-SID7=ZZZZ THE SMF IDS FOR EACH CPU IN THE COMPLEX. THE
        IDS MUST BE IN THE SAME ORDER AS IN THE INITIALIZATION DECK.

        AT PRESENT THERE IS SUPPORT IN THE INITIALIZATION MODULE TO
        DYNAMICALLY ALLOCATE THE CHECKPOINT ON EITHER 3330, 3330-1,
        OR 3350. IF YOU ARE FORTUNATE ENOUGH TO HAVE A DRUM YOU
        WILL HAVE TO MODIFY Q10 TO ADD SUPPORT.

        EDIT THE MACRO QSTART TO INDICATE THE OPTIONS DESIRED.

        QPFK SETB 0      NO PFK SUPPORT.
        QPFK SETB 1      PFK SUPPORT (DEFAULT).

        THE PFK SUPPORT IS FROM VILKO MACEK - INSURANCE CORPORATION
        OF BRITISH COLUMBIA. PFK SUPPORT CAN BE IDENTIFIED BY SOURCE
        MARKED WITH ICBC IN MODULES Q5, Q8, AND THE MACRO QCOMMON. TO
        CHANGE THE DEFINITIONS OF THE PFKS SEE THE END OF MODULE Q5.

        QACF2 SETB 0     NO ACF2 SUPPORT (DEFAULT).
        QACF2 SETB 1     ACF2 SUPPORT.

        THE ACF2 SUPPORT IS FROM KEN TRUE - FAIRCHILD CAMERA. KEN ALSO
        SUPPLIED THE ORIGINAL PRINT SUPPORT.

     3. EDIT MEMBER ASSEMBLE TO CHANGE THE JCL TO FIT YOUR STANDARDS.
        DO NOT ALTER THE ORDER OF THE ASSEMBLY SYSLIBS AS THERE IS A
        CONFLICT ON THE MACRO QSTART. THE ASSEMBLIES AND LINKS CREATE
        2 LOAD MODULES.

        QUEUE (ALIAS Q) - IS THE REENTRANT CODE OF THE COMMAND. IT MAY
        BE PLACED IN SYS1.LPALIB OR ANY OTHER AUTHORIZED LIBRARY WITH
        AN AUTHORIZATION CODE OF 1.

        QUEUECMN - THE MODIFIABLE COMMON AREA. CAN BE PLACED IN SYS1.
        LINKLIB OR SYS1.CMDLIB. IF YOU WANT TO CHANGE THE NAME OF
        QUEUECMN LOOK IN MEMBER Q10 WHERE THE LINK IS ISSUED.

     4. ADD QUEUE ALIAS Q TO THE IKJEFTE2 MODULE WHICH IS THE TSO LIST
        OF AUTHORIZED COMMANDS. A SAMPLE SMP JOB IS PROVIDED IN THE
        MEMBER TABLE. QUEUE CAN BE RUN UNDER SPF BUT THE SUBCOMMANDS
        USING THE SUBSYSTEM INTERFACE (CANCEL, REQUEUE, AND DELETE)
        WILL BE INOPERABLE, ALL OTHER COMMANDS WILL FUNCTION NORMALLY.
        IF YOU DON'T MIND THE INTEGRITY PROBLEM YOU CAN ADD CODE TO
        QUEUE TO USE A SPECIAL SVC TO GET INTO SUPERVISOR STATE AND
        HAVE FULL FACILITY UNDER SPF.

NOTE:  THE QUEUE COMMAND WAS WRITTEN FOR JES2 4.1 AT PUT TAPE 79/09
LEVEL WITH THE DUPLEX CHECKPOINT FACILITY (AZ27300). THERE IS NO REASON
THAT THE CONCEPT OF ACCESSING THE CHECKPOINT AND SPOOL WOULD NOT WORK
WITH EARLIER VERSIONS OF JES2 OR WITH NJE. THE LOCATION OF CHECKPOINT
VARIABLES AND CHECKPOINT AND SPOOL STRUCTURE MAY BE DIFFERENT AND THE
USER WILL HAVE TO MAKE APPROPRIATE CHANGES TO SUPPORT OTHER VERSIONS
OF JES2.

./ ADD NAME=FINDJOB  8003-02199-02306-1046-00224-00206-00000-GREG
FINDJOB  QSTART 'QUEUE COMMAND - LOCATE JQE, JCT, AND IOT BY JOBNAME'
***********************************************************************
* RNB CHANGES:                                                        *
*     (1) RNB22 - IN CASE JOBNAME = * (FOR CURRENT JOB), AFTER READING*
*                 THE JCT ENSURE JQEJNAME = JCTJNAME AND QPJOBID =    *
*                 JCTJBKEY. THIS IS DONE IN CASE THE JOB PURGED SINCE *
*                 THE LAST FINDJOB.                                   *
***********************************************************************
         GBLB   &QACF2         ACF2 CHECKING FOR AUTH              FCI*
         GBLB   &QSP           MVS/SP OPTION                      UF020
         AIF    (NOT &QACF2).NACF1                                 FCI*
*******************************************************************FCI*
* MOD 1 - K TRUE  - 22 OCT 79 -                                    FCI*
*   ADD ACF2 AUTH CHKING FOR USER AUTH TO LOOK AT STUFF.           FCI*
*    OPER CHKS ALL..                                               FCI*
*    USER CHKS OWN GOODIES (LOGONID = LOGONID IN JCT)              FCI*
*    OTHER: ISSUE ACFVLD CHK FOR AUTH                              FCI*
*******************************************************************FCI*
.NACF1   ANOP                                                      FCI*
         USING QCKPT,R10      BASE REG FOR CHECKPOINT WORK AREA
         L     R10,QVCKPT     LOAD BASE REG
         USING WORK,R13       LOCAL WORK AREA
         LH    R1,QLNG1       LENGTH OF PARAMETER FIELD
         SH    R1,=H'1'       IS THE LENGTH ZERO?
         BM    JOBAGAIN       YES. TRY JOBAGAIN                   WGH
         BM    TILT           YES. TILT.
******************************************************************UF007
*                                                                 UF007
*   ALLOW JOBNAME = "*" TO SIGNIFY CURRENT JOB & SKIP CKPT READ   UF007
*                                                                 UF007
******************************************************************UF007
         CLI   QPARM1,C'*'    WANT CURRENT JOB AGAIN?             UF007
         BE    JOBAGAIN       YES, SKIP CKPT READ                 UF007
         CLI   QPARM1,C'='    WANT CURRENT JOB AGAIN?             WGH
         BE    JOBAGAIN       YES, SKIP CKPT READ                 WGH
         MVC   QCJNAME,QPARM1 SAVE THE JOBNAME                    GP@P6
******************************************************************UF006
*                                                                 UF006
*   CALL - READ JES2 CHECKPOINT ROUTINE                           UF006
*                                                                 UF006
******************************************************************UF006
CALLCKPT L     R15,=V(CKPT)   ADDR OF CKPT ROUTINE                UF006
         BALR  R14,R15        GO TO IT                            UF006
***********************************************************************
*                                                                     *
*   DETERMINE IF SEARCH IS BY JOBNUMBER OR JOBNAME                    *
*                                                                     *
***********************************************************************
         LH    R1,QLNG1       LENGTH OF PARAMETER FIELD
         SH    R1,=H'1'       IS THE LENGTH ZERO?
         BM    TILT           YES. TILT.
         CLI   QPARM1,C'0'    IS THE FIRST CHARACTER NUMERIC?
         BL    JOBNAME        NO. SEARCH BY JOBNAME
         MVC   QFZONES,QFZONE INITIALIZE NUMERIC TEST
         EX    R1,MVZ         MOVE THE ZONES FOR VALIDITY CHECK
         CLC   QFZONES,QFZONE IS THE FIELD NUMERIC?
         BNE   TILT           NO. TILT.
         EX    R1,PACK        PACK THE FIELD
         CVB   R5,CONVERT     CONVERT TO BINARY
***********************************************************************
*                                                                     *
*   LOCATE JQE BY JOBNAME                                             *
*                                                                     *
***********************************************************************
JOBNAME  L     R2,QCJQHEAD    LOAD ADDR OF JQT
         USING JQTDSECT,R2    BASE REG FOR JQT
         LA    R2,JQTOUT      FIRST JQE QUEUE
         LA    R1,JQTQMAX     MAXIMUM NUMBER OF QUEUES
         DROP  R2
         AIF   (&QSP).QSP1                                        UF020
NEXTJQT  LH    R3,0(R2)       OFFSET TO FIRST JQE IN QUEUE
NEXTJQE  SLA   R3,2           MULTIPLY BY 4
         AGO   .QSP2                                              UF020
.QSP1    ANOP                                                     UF020
NEXTJQT  L     R3,0(R2)       OFFSET TO FIRST JQE IN QUEUE        UF020
NEXTJQE  N     R3,=A(X'00FFFFFF')  TEST FOR END OF CHAIN          UF020
.QSP2    ANOP                                                     UF020
         BZ    ENDJQE         END OF QUEUE
         A     R3,QCJQTA      ADD BASE TO OFFSET
         USING JQEDSECT,R3    BASE REG FOR JQE
         CLI   QPARM1,C'0'    IS SEARCH BY JOBNUMBER?
         BL    CLCNAME        NO. SEARCH BY JOBNAME.
         CH    R5,JQEJOBNO    IS THIS THE RIGHT JOBNUMBER?
         BNE   NOMATCH        NO. TRY NEXT JQE.
         B     FOUND          YES. PROCESS IT.
CLCNAME  CLC   QPARM1,JQEJNAME IS THIS THE RIGHT JOBNAME?
         BE    FOUND          YES. PROCESS IT.
         AIF   (&QSP).QSP3                                        UF020
NOMATCH  LH    R3,JQECHAIN    NO. TRY NEXT ENTRY.
         B     NEXTJQE        LOOP
ENDJQE   LA    R2,2(R2)       TRY NEXT QUEUE
         AGO   .QSP4                                              UF020
.QSP3    ANOP                                                     UF020
NOMATCH  L     R3,JQENEXT     NO. TRY NEXT ENTRY.                 UF020
         B     NEXTJQE        LOOP                                UF020
ENDJQE   LA    R2,4(R2)       TRY NEXT QUEUE                      UF020
.QSP4    ANOP                                                     UF020
         BCT   R1,NEXTJQT     LOOP IF NOT LAST QUEUE
TILT     QTILT '*** JOBNAME NOT FOUND OR INVALID ***'
         SPACE 1                                                  UF007
JOBAGAIN EQU   *                                                  WGH
         MVI   QPARM1,C'*'    SET SAME JOB REFERENCE              WGH
         MVI   QLNG1+1,X'01'  SET LENGTH TO 1                     WGH
         OI    QFLAG1,QFLG1SEL   INHIBIT RESET OF "PF3 LEVEL"     GP@P6
         L     R3,QCJQEA      PRIME JQE ADDRESS                   UF007
         LTR   R3,R3          ANYONE HOME?                        UF034
         BNZ   FOUND          YES, CONTINUE                       UF034
         QTILT '*** YOU MUST SPECIFY A JOBNAME OR NUMBER BEFORE USING "+
               *" ***'                                            UF034
         SPACE 1                                                  ONL03
***********************************************************************
*                                                                     *
*   READ JCT AND IOT                                                  *
*                                                                     *
***********************************************************************
FOUND    ST    R3,QCJQEA      SAVE THE ADDRESS
         LR    R4,R3          SAVE THE ADDRESS FOR COMPARE        RNB22
         MVC   QCTRAK,JQETRAK DISK ADDR OF JCT
         DROP  R3
         L     R3,QCJCTA      ADDR OF IOAREA FOR JCT
         LR    R1,R3          PARM FOR READSPC
         L     R15,=V(READSPC) ROUTINE TO READ HASPACE
         BALR  R14,R15        GO TO IT
         USING JCTSTART,R3    BASE REG FOR JCT
         USING JQEDSECT,R4    BASE FOR JQE                        RNB22
         CLI   QPARM1,C'*'         WAS REQUEST FOR CURRENT JOB?   RNB22
         BNE   RNB22A              /NO  - DON'T NEED EXTRA CHECK  RNB22
         CLC   JQEJNAME,JCTJNAME   IS JOBNAME RIGHT?              RNB22
         BNE   TILT                /NO  - TILT                    RNB22
         CLC   QPJOBID,JCTJBKEY    IS JOBID RIGHT?                RNB22
         BNE   TILT                /NO  - TILT                    RNB22
RNB22A   EQU   *                                                  RNB22
         CLC   QPJOBID,JCTJBKEY    IS JOBID UNCHANGED?            GP@P6
         BE    JOBIDSET            /YES - JOB ID SET CORRECTLY    GP@P6
         MVC   QPJOBID,JCTJBKEY JOB IDENTIFICATION
         TM    QFLAG1,QFLG1SEL     LINE SELECTION JUST DONE?      GP@P6
         BO    JOBIDSET            /YES - LEAVE PF3 LEVEL ALONE   GP@P6
         MVI   PF3LEVEL+1,0        /NO  - FORCE PF3 LEVEL RESET   GP@P6
JOBIDSET EQU   *                                                  GP@P6
         AIF    (NOT &QACF2).NACF2                                 FCI*
*******************************************************************FCI*
* MOD 1 - K TRUE  - 22 OCT 79 -                                    FCI*
*                                                                  FCI*
         CLC   QLOGON,LIDLID  SEE IF USERS LOGONID=JOBS ACF LOGONIDKMT*
         BE    ACF2OK         YES..CONTINUE FORTHWITH              FCI*
         TM    QXAUTH,X'80'   IS USER OPER PRIVLEDGE ?             FCI*
         BO    ACF2OK         YES..CONTINUE FORTHWITH              FCI*
*                                                                  FCI*
         USING ACCVT,R8                                            FCI*
         ACFGACVT R8,NONE=NOTOK   GET THE ACF2 CVT                 FCI*
*                                                                  FCI*
         MVC   DSNAME,=CL44'SYSOUT. '  INITIALIZE DSNAME TO USE    FCI*
         XC    ACFSPARM(ACFSPRML),ACFSPARM   CLEAR REQUEST BLOCK   FCI*
         MVI   ACFSPREQ,ACFSPRDS  DSNAME ACCESS ONLY               FCI*
         MVI   ACFSPID1,ACFSPIUR  DIS AM DE USER TALKING....       FCI*
         LA    R7,DSNAME          GET DSNAME ADDRESS               FCI*
         ST    R7,ACFSPDSN        AND GIVE IT TO ACF PARM LIST     FCI*
*                                                                  FCI*
*  GENERATE DSNAME OF FORMAT 'SYSOUT.LOGONID.JOBNAME' FOR CHKING   FCI*
*                                                                  FCI*
         MVC   DSNAME+7(8),LIDLID  MOVE LID TO DSNAME              FCI*
         CLI   DSNAME+7,C' '       IS THE LID BLANK?               FCI*
         BNE   ADSNCHK0            NO..NORMAL PROCESS              FCI*
*                                                                  FCI*
*  GOT HERE BECAUSE LID IS ' ' (BLANK)..SUBSTITUTE 'SYSTEM'        FCI*
         MVC   DSNAME+7(8),=CL8'SYSTEM'                            FCI*
*                                                                  FCI*
ADSNCHK0 LA    R1,DSNAME+7         GET ADDRESS                     FCI*
         LA    R7,8                LOAD COUNT                      FCI*
ADSNCHK  CLI   0(R1),C' '          LOOK FOR BLANK                  FCI*
         BE    ADSNCHK1            GOTIT..                         FCI*
         LA    R1,1(R1)            BUMP AND                        FCI*
         BCT   R7,ADSNCHK            GRIND                         FCI*
ADSNCHK1 MVI   0(R1),C'.'          MOVE IN PERIOD..                FCI*
         MVC   1(8,R1),JCTJNAME    MOVE IN JOBNAME                 FCI*
*                                                                  FCI*
         LA    R1,ACFSPARM        GET ADDRESS OF PARM FIELD        FCI*
         ACFSVC (1),TYPE=S,NONE=NOTOK,CVT=HAVE   INVOKE A C F 2    FCI*
*                                                                  FCI*
         LTR   R15,R15            HOW DID YOU LIKE THEM APPLES?    FCI*
         BC    8,ACF2OK           ..OK BY YOU...CONTINUE..         FCI*
*                                                                  FCI*
NOTOK    QTILT '*** SORRY..NO ACF2 AUTHORITY TO LOOK AT THIS JOB'  FCI*
*******************************************************************FCI*
ACF2OK   DS    0H                                                  FCI*
.NACF2   ANOP                                                      FCI*
         MVC   QCTRAK,JCTIOT  DISK ADDR OF IOT
         DROP  R3
         L     R1,QCIOTA      ADDR OF IOAREA FOR IOT
         L     R15,=V(READSPC) ROUTINE TO READ HASPACE
         BALR  R14,R15        GO TO IT
STOP     QSTOP
***********************************************************************
*                                                                     *
*   MISCELLANY                                                        *
*                                                                     *
***********************************************************************
MVZ      MVZ   QFZONES(1),QPARM1 CHECK FOR NUMERIC
PACK     PACK  CONVERT,QPARM1(1) CONVERT TO BINARY
         LTORG
SYMDEL   DSECT ,                   KILL SYM CARD GENERATION       UF023
FINDJOB  CSECT ,                                                  UF023
JCT      EQU   0
BUFSTART EQU   0
BUFDSECT EQU   0
         $JQE
         $JCT
         $JQT
         QCOMMON
WORK     DSECT
         DS    72C
CONVERT  DS    D
         AIF    (NOT &QACF2).NACF3                                 FCI*
         ACDSV DSECT=NO                                            FCI*
DSNAME   DS    CL44                                                FCI*
         EJECT   ,                                                 FCI*
         ACCVT   ,                                                 FCI*
         ACUCB   ,                                                 FCI*
         PRINT OFF                                                 FCI*
         IHAPSA  ,                                                 FCI*
         PRINT ON                                                  FCI*
.NACF3   ANOP   ,                                                  FCI*
SYMNODEL DSECT ,                   RESTORE SYM CARD GENERATION    UF023
         END
./ ADD NAME=FINDPDDB 8000-02177-02177-1708-00101-00101-00000-GREG
FINDPDDB QSTART 'QUEUE COMMAND - FIND PDDB FOR A DSID'
         USING QCKPT,R10          BASE REG FOR CHECKPONT WORK AREA
         L     R10,QVCKPT         LOAD BASE REG
         USING QDISPLAY,R9        BASE REG FOR DISPLAY WORK AREA
         L     R9,QVDSPL          LOAD BASE REG
         USING WORK,R13           BASE REG FOR LOCAL WORK AREA
***********************************************************************
*                                                                     *
*   CONVERT DATASET ID TO BINARY                                      *
*                                                                     *
***********************************************************************
         XC    CONVERT,CONVERT       CLEAR CONVERT WORK AREA
         PACK  CONVERT+5(3),DSID+1(3) PACK ASID
         CVB   R7,CONVERT         CONVERT DSID TO BINARY
***********************************************************************
*                                                                     *
*   FIND  PDDB  FOR  THIS  DATASET  ID                                *
*                                                                     *
***********************************************************************
NORMAL   MVI   SWITCH,0           INITIALIZE SWITCH
         USING PDBDSECT,R2        BASE REG FOR PDDB
         USING IOTSTART,R3        BASE REG FOR IOT
         L     R3,QCIOTA          LOAD BASE REG
         L     R1,QCJCTA          ADDR OF JCT                     UF008
         USING JCTSTART,R1        SET TEMP ADDRESSING             UF008
         CLC   QCTRAK,JCTIOT      AT FIRST IOT?                   UF008
         BNE   *+8                NO, SKIP FLAG SET               UF008
         OI    SWITCH,X'02'       SET FLAG                        UF008
         DROP  R1                 DROP TEMP ADDRESSING            UF008
         LR    R5,R3              IOAREA FOR READ IOT BLOCK
NEXTIOT  LR    R4,R3              BASE OF IOT
         A     R4,IOTPDDBP        OFFSET BEYOND LAST PDDB
         LR    R2,R3              BASE OF IOT
         A     R2,QCPDDB1         OFFSET TO FIRST PDDB IN IOT
FINDDS   CH    R7,PDBDSKEY        IS THIS THE DATASET?
         BE    FOUNDDS            YES. CONTINUE
         LA    R2,PDBLENG(R2)     NO. LOOK AT NEXT PDDB
         CR    R2,R4              HAVE WE GONE PAST THE LAST PDDB
         BL    FINDDS             NO. TRY AGAIN
         L     R4,IOTIOTTR        DISK ADDR OF NEXT IOT
SPIN     LTR   R4,R4              IS THERE ANOTHER IOT?
         BZ    SPINIOT            NO. TRY THE SPIN IOT.
         BAL   R8,READ            READ THE IOT
         B     NEXTIOT            SEARCH THE NEXT IOT
         USING JCTSTART,R1        BASE REG FOR JCT
SPINIOT  TM    SWITCH,1           DID WE SEARCH THE SPINIOT ALREADY
         BO    CKIOT1             YES, SEE IF WE STARTED AT FRONT UF008
         OI    SWITCH,1           SET SWITCH
         L     R1,QCJCTA          LOAD BASE REG
         L     R4,JCTSPIOT        DISK ADDR OF SPIN IOT
         DROP  R1
         B     SPIN               SEARCH THE SPIN IOT CHAIN
FOUNDDS  L     R0,PDBRECCT        GET THE RECORD COUNT
         CVD   R0,CONVERT         CONVERT TO DECIMAL
         MVC   DSRECCT,ED8        MOVE EDIT PATTERN TO DISPLAY
         ED    DSRECCT,CONVERT+4  EDIT THE RECORD COUNT
         MVC   DSCLASS,PDBCLASS   MOVE PDBCLASS TO DISPLAY
STOP     QSTOP                    GO BACK TO CALLER
CKIOT1   TM    SWITCH,X'02'       DID WE START AT FIRST IOT?      UF008
         BO    STOP               YES, NOT FOUND                  UF008
         USING JCTSTART,R1        SET TEMP ADDRESSING             UF008
         L     R1,QCJCTA          POINT TO JCT                    UF008
         L     R4,JCTIOT          FIRST IOT ADDRESS               UF008
         DROP  R1                 DROP TEMP ADDRESSING            UF008
         BAL   R8,READ            READ THE IOT                    UF008
         OI    SWITCH,X'02'       SET STARTED AT FRONT            UF008
         B     NEXTIOT            AND TRY AGAIN                   UF008
***********************************************************************
*                                                                     *
*   READ A BLOCK FROM HASPACE                                         *
*                                                                     *
***********************************************************************
READ     ST    R4,QCTRAK          STORE DISK ADDR
         LR    R1,R5              IOAREA ADDRESS
         L     R15,=V(READSPC)    ADDR OF ROUTINE TO READ HASPACE
         BALR  R14,R15            GO TO IT
         BR    R8                 RETURN TO CALLER
ED8      DC    X'4020202020202120'
SYMDEL   DSECT ,                   KILL SYM CARD GENERATION       UF023
FINDPDDB CSECT ,                                                  UF023
JCT      EQU   0
BUFSTART EQU   0
BUFDSECT EQU   0
         $TAB
         $JCT
         $PDDB
         $IOT
WORK     DSECT
         DS    CL72
SWITCH   DS    C
CONVERT  DS    D
         QCOMMON
         ORG   QDMSG
         DS    CL28
DSID     DS    CL4
         DS    CL4
DSRECCT  DS    CL8
         DS    CL4
DSCLASS  DS    CL1
SYMNODEL DSECT ,                   RESTORE SYM CARD GENERATION    UF023
         END
./ ADD NAME=FORMAT   8012-02172-06364-1725-00515-00480-00000-GREG
FORMAT   QSTART 'QUEUE COMMAND - JQE AND JOE FORMAT ROUTINES'
***********************************************************************
* RNB CHANGES:                                                        *
*      (1) RNB17 - WHEN FORMATTING JOES, CHECK FOR JOE ON PSO AND     *
*                  INDICATE 'EXT-WTR' IF SO. ALSO, DON'T INDICATE ON  *
*                  ON PRINT/PUNCH UNLESS SHOWS ACTIVE IN JOEFLAGS.    *
*                  ALSO, FIX BUG IN GETTING TO CHECKPOINT JOE FOR     *
*                  RECORDS LEFT, AND FIX RECORDS LEFT FOR SP2.        *
*                  ALSO, IF JOE NOT BUSY, BUT CHKPT JOE VALID, PRINT  *
*                  NUMBER OF RECORDS LEFT, NOT TOTAL RECORDS.         *
*      (2) RNB18 - DISTINGUISH BETWEEN JOES WITH REMOTE ROUTING AND   *
*                  THOSE WITH SPECIAL LOCAL ROUTING (DEFINED BY DESTID*
*                  STATEMENTS WITH DEST=UNNN).                        *
*      (3) RNB19 - WHEN LISTING JQE'S, DON'T ASSUME INPUT QUEUE, BUT  *
*                  USE THE JQETYPE INSTEAD. ALSO, SPECIALLY HANDLE    *
*                  CONVERSION AND DUMP QUEUES, AND AWAITING OUTPUT.   *
*      (4) RNB20 - WHEN LISTING THINGS, DISTINGUISH BETWEEN NORMAL    *
*                  HOLD, HOLD ALL, AND DUPLICATE HOLD. ALSO, FOR      *
*                  JOES, INDICATE SELECT=NO IF APPLICABLE.            *
*      (5) RNB21 - FIX SETDEVIC SUBROUTINE FOR SP2.                   *
*      (5) RNB25 - ALLOW 'COUNT' PARM TO HO TO INDICATE TOTAL LINE    *
*                  COUNT DESIRED FOR JOBS ON HELD OUTPUT QUEUE        *
***********************************************************************
         GBLB  &QSP           MVS/SP OPTION                       UF020
         GBLB  &QPFK          PF-KEY OPTION. DEFINED BY QSTART    GP@P6
         USING QDISPLAY,R10   BASE REG FOR DISPLAY WORK AREA
         L     R10,QVDSPL     LOAD BASE REG
         USING JQEDSECT,R9    BASE REG FOR JQE DSECT
         USING JOEDSECT,R8    BASE REG FOR JOE DSECT
         USING WORK,R13       BASE FOR LOCAL WORK AREA
***********************************************************************
*                                                                     *
*   INPUT TO THIS MODULE -                                            *
*     R1 = 0 INDICATES PRINT JQE                                      *
*     R1 = 4 INDICATES PRINT JOE                                      *
*     R9 CONTAINS JQE ADDRESS                                         *
*     R8 CONTAINS JOE ADDRESS                                         *
*                                                                     *
***********************************************************************
*                                                                     *
*   BRANCH TO PROPER ROUTINE                                          *
*                                                                     *
***********************************************************************
         MVC   FCLEAR,=CL80' ' CLEAR THE PRINT AREA
         MVC   FQUEUE,QCLASS  CLASS NAME
         XC    QPJOBID(6),QPJOBID       DROP JOB AND DATA SET     GP@P6
         QHEAD HEADING,X'24',TYP=QDJQ   HEADING IN GREEN REVERSE  GP@P6
         MVI   QDLNCODE,X'05' TURQUOISE IS DEFAULT COLOUR         GP@P6
         CLI   QSUBNAME,C'X'  IS THE REQUEST FOR A HEX DUMP?
         BE    NOTBUSY        YES. SKIP.
*        CLC   =X'01000100',JQEPRTRT IS THE PRINT/PUNCH FOR LOCAL?
*        BE    LOCAL          YES. SKIP THIS ROUTINE.
*        MVC   FREMOTE,=C'RJE' INDICATE THIS JOB IS REMOTE
         TM    JQEFLAGS,QUEBUSY IS THE JOB EXECUTING?
         BZ    NOTBUSY        NO. SKIP THIS ROUTINE.
         MVI   QDLNCODE,X'06' YES, SHOW LINE IN YELLOW            GP@P6
         IC    R15,JQEFLAGS   GET SYSTEM NUMBER
         N     R15,=F'7'      ZERO OUT UNWANTED BITS
         SLL   R15,3          MULTIPLY BY 8
         LA    R15,QSYSID(R15) OBTAIN SYSTEM ID
         MVC   FSYSID,0(R15)  MOVE SYSTEM ID TO DISPLAY
NOTBUSY  CLI   QCLASS,0       IS THIS THE TSO QUEUE?
         BE    LISTTSO        YES. DO IT.
         CLI   QCLASS,4       IS THIS THE STC QUEUE?
         BE    LISTSTC        YES. DO IT.
         CLI   QCLASS,8       IS THIS THE HELD OUTPUT QUEUE?
         BE    LISTHO         YES. DO IT.
         AIF   (NOT &QSP).RNB19A                                  RNB19
         CLI   QCLASS,12      IS THIS THE DUMP QUEUE?             RNB19
         BE    LISTDM         YES. DO IT.                         RNB19
         CLI   QCLASS,16      IS THIS THE CONVERSION QUEUE?       RNB19
         BE    LISTCN         YES. DO IT.                         RNB19
         CLI   QCLASS,20      IS THIS THE AWAITING OUTPUT QUEUE?  RNB19
         BE    LISTAOUT       YES. DO IT.                         RNB19
.RNB19A  ANOP                                                     RNB19
         LTR   R1,R1          IS REQUEST FOR JQE OR JOE?
         BZ    LISTJQE        JQE.
***********************************************************************
*                                                                     *
*   FORMAT JOE                                                        *
*                                                                     *
***********************************************************************
LISTJOE  MVC   FQNAME,=C'OUTPUT' MOVE IN NAME OF QUEUE
         CLI   QSUBNAME,C'X'  IS THE REQUEST FOR A HEX DUMP?
         BE    HEXO           YES. DO IT.
         AIF   (NOT &QSP).RNB20A                                  RNB20
         TM    JOEFLAG2,$JOESLEC   IS THIS JOE SELECTABLE?        RNB20
         BZ    LSTJOEAA            /YES - DON'T FLAG IT           RNB20
         MVC   FHOLD,=C' S=N'      /NO  - SAY SO                  RNB20
LSTJOEAA EQU   *                                                  RNB20
.RNB20A  ANOP                                                     RNB20
         L     R0,JOERECCT    NUMBER OF PRINT LINES
         CVD   R0,CONVERT     CONVERT TO DECIMAL
         MVC   FLINES,ED8     PREPARE FOR EDIT
         ED    FLINES,CONVERT+4 EDIT NUMBER OF LINES
         SLR   R0,R0          CLEAR FOR INSERT                    GP@P6
         IC    R0,JOEPRIO     GET THE JOE PRIORITY                GP@P6
         SRL   R0,4           GET INTO 0 TO 15 RANGE              GP@P6
         CVD   R0,CONVERT     CONVERT TO DECIMAL                  GP@P6
         OI    CONVERT+7,X'0F'                                    GP@P6
         MVI   FPRIO+4,C'.'                                       GP@P6
         UNPK  FPRIO+5(2),CONVERT                                 GP@P6
         CLI   FPRIO+5,C'0'   LEADING ZERO?                       GP@P6
         BNE   *+4+6+4        NO                                  GP@P6
         MVC   FPRIO+5(1),FPRIO+6   OVERLAY 0 WITH SECOND DIGIT   GP@P6
         MVI   FPRIO+6,C' '   CLEAR OLD SECOND DIGIT              GP@P6
*        TM    JOEFLAG,X'20'  IS THIS JOB PRINTING?               RNB17
*        BNO   LOCAL          NO. SKIP.                           RNB17
         TM    JOEFLAG,$JOEBUSY  IS JOE ACTIVE?                   RNB17
         BZ    LSTJOE$$          /NO  - DON'T SET DEVICE ID       RNB17
*                                /YES -                           RNB17
         MVI   QDLNCODE,X'06'    YELLOW FOR ACTIVE                GP@P6
         CLI   JOEDEVID,X'0F'    IS JOB ON PSO (EXTERNAL WRITER)? RNB17
         BNE   LSTJOE$           /NO  - GO DO REAL DEVICE         RNB17
         MVC   FPRINT,=CL8'EXT-WTR'  /YES - SAY SO                RNB17
         B     LSTJOE$$                                           RNB17
         AIF   (&QSP).RNB17A                                      RNB17
LSTJOE$  TM    JOEFLAG,$JOEPRT+$JOEPUN  JOB PRINTING OR PUNCHING? RNB17
         BZ    LOCAL                     /NO  - SKIP DEVICE ID    RNB17
         AGO   .RNB17B                                            RNB17
.RNB17A  ANOP                                                     RNB17
LSTJOE$  TM    JOEDEVID,X'40'           JOB ON NJE DEVICE?        RNB17
         BO    LOCAL                     /YES - SKIP DEVICE ID    RNB17
.RNB17B  ANOP                                                     RNB17
         LA    R3,JOEDEVID    A(OUTPUT DEVICE DESCRIPTOR            FCI
         BAL   R7,SETDEVIC    SET THE OUTPUT DEVICE                 FCI
LSTJOE$$ EQU   *                                                  RNB17
         TM    JOEFLAG,$JOECKV  IS CKPT JOE VALID?                RNB17
         BO    LSTJOE##         /YES - USE RECORDS PRINTED        RNB17
         TM    JOEFLAG,$JOEBUSY /NO  - IS JOE BUSY?               RNB17
         BZ    LOCAL            IF NOT, GO DO LOCAL STUFF         RNB17
         B     LIST             IF YES, SKIP LOCAL STUFF, GO LIST RNB17
LSTJOE## EQU   *                                                  RNB17
         L     R0,JOERECCT      RESTORE R0 FOR REMOTES            CBT1
         LR    R3,R8            SAVE WORK JOE ADDRESS             RNB17
         AIF   (&QSP).QSP01                                       UF020
         LH    R8,JOECKPT     OFFSET TO CHECKPOINT JOE
         SLA   R8,2           MULTIPLY BY 4
         AGO   .QSP02                                             UF020
.QSP01   ANOP                                                     UF020
         LA    R8,0(,R8)      CLEAR HIGH BYTE FOR ICM             RNB17
         ICM   R8,B'0111',JOECKPTB OFFSET TO CKPT JOE             UF020
.QSP02   ANOP                                                     UF020
         BZ    LIST           CHECKPOINT DOES NOT EXIST. SKIP.
         USING QCKPT,R1       BASE REG FOR CKPT WORK AREA
         L     R1,QVCKPT      LOAD BASE REG
         A     R8,QCJOTA      ADD BASE TO OFFSET
         DROP  R1
         AIF   (&QSP).QSP02A                                      RNB17
         S     R0,JOETLNC     SUBTRACT RECORDS PRINTED FROM TOTAL
         AGO   .QSP02B                                            RNB17
.QSP02A  ANOP
         SL    R0,JOECRECN    SUBTRACT RECORDS PRINTED FROM TOTAL RNB17
.QSP02B  ANOP
         LR    R8,R3          BACK TO WORK JOE                    RNB17
         CVD   R0,CONVERT     CONVERT TO DECIMAL
         MVC   FLINES,ED8     PREPARE FOR EDIT
         ED    FLINES,CONVERT+4 PRINT UPDATED LINE COUNT
         TM    JOEFLAG,$JOEBUSY IS JOE ACTIVE?                    RNB17
         BNZ   LIST                  /YES - GO LIST IT            RNB17
         MVC   FLINES+9(4),=C'LEFT'  /NO  - SHOW IT'S LINES LEFT  RNB17
*                                    AND FORMAT ROUTING INFO      RNB17
LOCAL    LA    R15,FREMOTE    ADDRESS TO PUT TEXT
         LA    R1,JOEROUT     POINT TO ROUTING INFO                FCI*
***********************************************************************
*RMTORLCL SUBROUTINE - DETERMINE REMOTE OR LOCAL DESTINATION       FCI*
* R1 POINTS TO PRTRT/PUNRT, R15 TO ASSEMBLY POINTER                FCI*
***********************************************************************
         AIF   (&QSP).QSP1                                        UF020
RMTORLCL CLI   1(R1),0        IS IT FOR REMOTE 00=LOCAL            FCI*
         AGO   .QSP2                                              UF020
.QSP1    ANOP                                                     UF020
RMTORLCL CLI   3(R1),0        IS IT FOR REMOTE 00=LOCAL            FCI*
.QSP2    ANOP                                                     UF020
         BE    LIST           NO LUCK .. HAVE TO WORK FOR IT       FCI*
         AIF   (&QSP).RNB18A                                      RNB18
         CLI   0(R1),0        SPECIAL LOCAL ROUTING?              RNB18
         AGO   .RNB18B                                            RNB18
.RNB18A  ANOP                                                     RNB18
         CLC   =H'0',0(R1)    SPECIAL LOCAL ROUTING (SP2) ?       RNB18
.RNB18B  ANOP                                                     RNB18
         BNE   RMTORLC1          /NO  - GO FORMAT RMTNN           RNB18
         MVC   0(L'LCL,R15),LCL  /YES - MOVE IN LCL               RNB18
         LA    R15,L'LCL(R15)    BUMP POINTER                     RNB18
         B     RMTORLC2                                           RNB18
RMTORLC1 EQU   *                                                  RNB18
         MVC   0(L'RMT,R15),RMT       MOVE IN 'RMT'                FCI*
         LA    R15,L'RMT(R15)  BUMP POINTER                        FCI*
RMTORLC2 EQU   *                                                  RNB18
         SR    R14,R14        LOAD RMT FLAGS                       FCI*
         AIF   (&QSP).RNB18C                                      RNB18
         IC    R14,1(R1)      FROM PRT/PUN                         FCI*
         AGO   .RNB18D                                            RNB18
.RNB18C  ANOP                                                     RNB18
         IC    R14,3(R1)      FROM JOEROUT                        RNB18
.RNB18D  ANOP                                                     RNB18
         CVD   R14,DOUBLEWD   RMT NUMBER TO DECIMAL                FCI*
         B     FITINUM1       FIT THE NUMBER IN RMT MESSAGE        FCI*
         SPACE 2
***********************************************************************
* FITINUM SUBROUTINE - CONVERT BIN NUMBER TO NICE FORMAT           FCI*
*                                                                  FCI*
***********************************************************************
FITINUM  CVD   R1,DOUBLEWD    CONVERT TO PACKED DECIMAL            FCI*
FITINUM1 MVC   NUMBER(L'NORMAL),NORMAL INITIALIZE THE EDIT FORMAT  FCI*
         LA    R1,NUMBER+SIGNORM IN CASE OF ZEROES                 FCI*
         EDMK  NUMBER(L'NORMAL),DOUBLEWD+2 CONVERT TO EBCDIC       FCI*
         LA    R14,NUMBER+L'NORMAL-1 A(END OF CONVERTED NUMBER)    FCI*
         SLR   R14,R1         LENGTH OF THE CONVERTED NUMBER - 1   FCI*
         EX    R14,MVNUMBER   PUT THE NUMBER IN THE MSG            FCI*
         LA    R15,1(R14,R15) A(NEXT SPOT IN MSG)                  FCI*
         B     LIST           RETURN TO OUR CALLER                 FCI*
         SPACE 3                                                   FCI*
MVNUMBER MVC   0(0,R15),0(R1) TO BE EXECUTED                       FCI*
         SPACE 2                                                   FCI*
NORMAL   DC    X'402020202020202020202120' EDIT MASK               FCI*
SIGNORM  EQU   11             OFFSET TO LAST DIGIT                 FCI*
RMT      DC    C'RMT'                                              FCI*
LCL      DC    C'LCL'                                             RNB18
***********************************************************************
*                                                                     *
*   FORMAT JQE                                                        *
*                                                                     *
***********************************************************************
LISTTSO  MVC   FQNAME(8),=C'TSO USER' NAME OF QUEUE
         B     LIST           CONTINUE
LISTSTC  MVC   FQNAME(8),=C'SYSTEM Q' NAME OF QUEUE
         B     LIST           CONTINUE
LISTHO   MVC   FQNAME(8),=C'HELD OUT' NAME OF QUEUE
         B     LIST           CONTINUE
         AIF   (NOT &QSP).RNB19B                                  RNB19
LISTDM   MVC   FQNAME(4),=C'DUMP'     NAME OF QUEUE               RNB19
         B     LIST                                               RNB19
LISTAOUT MVC   FQNAME(6),=C'AW OUT'   NAME OF QUEUE               RNB19
         B     LISTCN1                GO DO SYSAFF                RNB19
LISTCN   MVC   FQNAME(6),=C'CONVRT'   NAME OF QUEUE               RNB19
         MVC   FQUEUE,JQEJCLAS        JOB CLASS                   RNB19
LISTCN1  TM    JQEFLAGS,QUEBUSY       IS JOB CONVERTING?          RNB19
         BNZ   LIST                   /YES - GO LIST IT           RNB19
*                                     /NO  - PUT SYSAFF IN        RNB19
         TM    JQEFLAG2,QUESYSAF      CHECK SYSTEM AFFINITY       RNB19
         BO    LIST                   LIST IT IF NO SPECIAL AFF   RNB19
         LA    R15,QSYSID+8           GET FIRST SID               RNB19
         TM    JQEFLAG2,X'01'         IS THIS IT?                 RNB19
         BO    LISTCN2                /YES -                      RNB19
         LA    R15,8(,R15)            /NO  - CHECK REST           RNB19
         TM    JQEFLAG2,X'02'                                     RNB19
         BO    LISTCN2                                            RNB19
         LA    R15,8(,R15)                                        RNB19
         TM    JQEFLAG2,X'04'                                     RNB19
         BO    LISTCN2                                            RNB19
         LA    R15,8(,R15)                                        RNB19
         TM    JQEFLAG2,X'08'                                     RNB19
         BO    LISTCN2                                            RNB19
         LA    R15,8(,R15)                                        RNB19
         TM    JQEFLAG2,X'10'                                     RNB19
         BO    LISTCN2                                            RNB19
         LA    R15,8(,R15)                                        RNB19
         TM    JQEFLAG2,X'20'                                     RNB19
         BO    LISTCN2                                            RNB19
         LA    R15,8(,R15)                                        RNB19
LISTCN2  MVC   FREMOTE(4),0(R15)      MOVE SYSTEM ID TO DISPLAY   RNB19
         B     LIST                                               RNB19
.RNB19B  ANOP                                                     RNB19
*LISTJQE  MVC   FQNAME,=C' INPUT' NAME OF QUEUE                   RNB19
LISTJQE  MVC   FQNAME(5),=CL5'XEQ'  ASSUME XEQ QUEUE              RNB19
         TM    JQETYPE,$XEQ         IS IT XEQ QUEUE?              RNB19
         AIF   (NOT &QPFK).CLSFIXD                                GP@P6
         BNO   INPUTCHK             NO, CHECK FOR INPUT           GP@P6
         CLI   QDLNCODE,X'06' JOB ALREADY ACTIVE?                 GP@P6
         BE    LIST           YES, CANNOT CHANGE CLASS NOW        GP@P6
         TM    QFLAG1,QFLG1OPR+QFLG1APF                           GP@P6
         BNO   LIST           NOT OPER PRIV IN APF ENVIRONMENT    GP@P6
         MVI   FQUEUE-1,X'0B' INPUT HIGH INTENSITY                GP@P6
         MVI   FQUEUE+1,X'0C' OUTPUT LOW INTENSITY                GP@P6
         B     LIST           GO LIST IT                          GP@P6
INPUTCHK DS    0H                                                 GP@P6
         AGO   .ALTCLAS                                           GP@P6
.CLSFIXD ANOP                                                     GP@P6
         BO    LIST                 /YES - GO LIST IT             RNB19
.ALTCLAS ANOP                                                     GP@P6
         MVC   FQNAME(5),=C'INPUT'  ELSE ASSUME INPUT, ETC.       RNB19
         TM    JQETYPE,$INPUT                                     RNB19
         BO    LIST                                               RNB19
         MVC   FQNAME(6),=C'OUTPUT'                               RNB19
         TM    JQETYPE,$OUTPUT+$HARDCPY                           RNB19
         BNZ   LIST                                               RNB19
         MVC   FQNAME(5),=C'PURGE'                                RNB19
         TM    JQETYPE,$PURGE                                     RNB19
         BO    LIST                                               RNB19
         MVC   FQNAME(8),=CL8'????????'                           RNB19
LIST     CLI   QSUBNAME,C'X'  IS THE REQUEST FOR A HEX DUMP?
         BE    HEX            YES. DO IT.
         MVC   FCOUNT,ED5     PREPARE FOR EDIT
         ED    FCOUNT,QCOUNT  EDIT THE POSITION IN QUEUE
         MVC   FNAME,JQEJNAME MOVE IN JOBNAME
         MVC   FJOBNO,ED5     PREPARE FOR EDIT
         LH    R0,JQEJOBNO    LOAD HASP JOBNUMBER
         CVD   R0,CONVERT     CONVERT TO DECIMAL
         ED    FJOBNO,CONVERT+5 EDIT HASP JOBNUMBER
         SR    R0,R0          ZERO OUT REGISTER
         IC    R0,JQEPRIO     LOAD JQE PRIORITY
         SRL   R0,4           DIVIDE BY 16
         CVD   R0,CONVERT     CONVERT TO DECIMAL
         MVC   FPRIO,ED3      PREPARE FOR EDIT
         ED    FPRIO,CONVERT+6 EDIT JQE PRIORITY
         TM    JQEFLAGS,X'E0' IS THE JOB HELD?
         BZ    NOHOLD         NO.
         MVC   FHOLD,=C'HELD' INDICATE JOB HELD
         TM    JQEFLAGS,QUEHOLD1  SPECIFIC HOLD?                  RNB20
         BO    NOHOLD             /YES - GO DISPLAY               RNB20
         MVC   FHOLD,=C'DUP '     ASSUME DUPLICATE                RNB20
         TM    JQEFLAGS,QUEHOLD2  IS IT DUPLICATE HOLD?           RNB20
         BO    NOHOLD             /YES - GO DISPLAY               RNB20
         MVC   FHOLD,=C'$HA '     ELSE MUST BE FROM $HA           RNB20
NOHOLD   DS    0H
         CLC   QCODEH,=H'28'  IS THIS THE HO COMMAND?             RNB25
         BNE   LIST2          /NO  - DO NORMAL LISTING            RNB25
*                             /YES -                              RNB25
         CLC   =C'COUNT',QPARM1  DOES USER WANT LINE COUNTS?      RNB25
         BNE   LIST2          /NO  - DO NORMAL LISTING            RNB25
*                             /YES - GET JCT AND FORMAT LINE CNT  RNB25
         MVC   QCTRAK,JQETRAK DISK ADDR OF JCT                    RNB25
         L     R3,QCJCTA      ADDR OF IOAREA FOR JCT              RNB25
         LR    R1,R3          PARM FOR READSPC                    RNB25
         L     R15,=V(READSPC)  ROUTINE TO READ HASPACE           RNB25
         BALR  R14,R15          GO DO IT                          RNB25
         USING JCTSTART,R3    BASE FOR JCT                        RNB25
         L     R0,JCTLINES    GET TOTAL LINES GENERATED BY JOB    RNB25
         DROP  R3                                                 RNB25
         CVD   R0,CONVERT     CONVERT TO DECIMAL                  RNB25
         MVC   FLINES,ED8     PREPARE FOR EDIT                    RNB25
         ED    FLINES,CONVERT+4  PRINT TOTAL LINE COUNT           RNB25
         C     R0,=F'9999999' IS THE LINE COUNT >= 10 MILLION?    RNB25
         BNH   LIST2          /NO  - GO LIST IT                   RNB25
         MVI   FLINES+8,C'+'  /YES - SHOW OVERFLOW                RNB25
LIST2    EQU   *                                                  RNB25
         AIF   (NOT &QPFK).JQNOSEL                                GP@P6
         MVI   QDMSG,X'0B'    INPUT HIGH INTENSITY                GP@P6
         MVI   QDMSG+1,C'.'   SUPPLY SELECTION FIELD DOT          GP@P6
         MVI   QDMSG+2,X'0C'  OUTPUT LOW INTENSITY                GP@P6
.JQNOSEL ANOP                                                     GP@P6
         LA    R1,QDMSG       ADDR OF MESSAGE AREA
         ST    R1,QDMSGA      STORE MESSAGE ADDR
         MVC   QDMLNG,=H'80'  LENGTH OF DISPLAY LINE
         L     R15,=V(DISPLAY) ADDR OF DISPLAY MODULE
         BALR  R14,R15        DISPLAY THE LINE
STOP     QSTOP
***********************************************************************
*                                                                     *
*   TAKE HEX DUMP OF JOE                                              *
*                                                                     *
***********************************************************************
HEXO     UNPK  FHEX1,0(8,R8)  UNPK FIRST PART OF JOE INTO HEX
         UNPK  FHEX2,7(8,R8)  SECOND
         UNPK  FHEX3,14(8,R8) THIRD
         UNPK  FHEX4,21(8,R8) FOURTH
         UNPK  FHEX5,28(5,R8) FIFTH
         MVI   FHEXOC,C' '    CLEAR LAST BYTE
         TR    FHEXO,TABLE    CHANGE TO PRINTABLE HEX
         LA    R1,QDMSG       ADDR OF MESSAGE AREA
         ST    R1,QDMSGA      STORE MESSAGE ADDR
         MVC   QDMLNG,=H'80'  LENGTH OF DISPLAY LINE
         L     R15,=V(DISPLAY) ADDR OF DISPLAY MODULE
         BALR  R14,R15        DISPLAY THE LINE
***********************************************************************
*                                                                     *
*   TAKE HEX DUMP OF JQE                                              *
*                                                                     *
***********************************************************************
HEX      UNPK  FHEX1,0(8,R9)  UNPK FIRST PART OF JOE INTO HEX
         UNPK  FHEX2,7(8,R9)  SECOND
         UNPK  FHEX3,14(8,R9) THIRD
         UNPK  FHEX4,21(8,R9) FOURTH
         MVC   FHEXC,QBLANK   CLEAR LAST BYTES
         TR    FHEX,TABLE     CHANGE TO PRINTABLE HEX
         B     NOHOLD         CALL DISPLAY
***********************************************************************
* SETDEVIC SUBROUTINE - GET DEVICE DATA (R3) POINTS TO DEVID       FCI*
*                                                                  FCI*
***********************************************************************
SETDEVIC ST    R7,SETDHOLD       SAVE LINK ADDRESS                 FCI*
         MVC   FPRINT(9),=CL9' '
         TM    0(R3),HIGHBIT REMOTE DEVICE?                        FCI*
         BO    RMTDEV         YES => OUTPUT IT                     FCI*
         SR    R1,R1          FOR THE INSERT CHARACTER             FCI*
         IC    R1,0(R3)         DEVICE TYPE                        FCI*
         SRL   R1,4           RIGHT JUSTIFIED                      FCI*
         MH    R1,DEVTYPEL    TYPE * LENGTH OF A DEVICE ENTRY      FCI*
         LA    R1,DEVTABLE(R1) A(DEVICE TYPE)                      FCI*
         MVC   FPRINT,1(R1)   PUT IN THE DEVICE TYPE
         CLI   0(R3),0          INTERNAL READER?                   FCI*
         BE    SETDRTN        YES => GIVE THE USER THE INFO        FCI*
         SR    R15,R15        FOR THE INSERT CHARACTER             FCI*
         AIF   (&QSP).RNB21A                                      RNB21
         IC    R15,1(R3)        DEVICE NUMBER                      FCI*
         AGO   .RNB21B                                            RNB21
.RNB21A  ANOP                                                     RNB21
         ICM   R15,3,1(R3)      DEVICE NUMBER  (SP2)              RNB21
.RNB21B  ANOP                                                     RNB21
         CVD   R15,DOUBLEWD   IN PACKED DECIMAL                    FCI*
         IC    R15,0(R1)      OFFSET TO WHERE THE DEV # GOES       FCI*
         LA    R15,FPRINT(R15) A(WHERE THE DEV # GOES)
         MVC   1(L'DIGITS3,R15),DIGITS3 SET UP THE EDIT OF 3 DIGITSKMT*
         EDMK  0(L'DIGITS3+1,R15),DOUBLEWD+6 DEV # IN EBCDIC       FCI*
         MVC   0(L'DIGITS3+1,R15),0(R1) ADJUST FOR BLANKS          FCI*
*                                                                  FCI*
         B     SETDRTN        GO EXIT
*                                                                  FCI*
RMTDEV   SR    R0,R0          FOR THE INSERT CHARACTER             FCI*
         AIF   (&QSP).QSP3                                        UF020
         IC    R0,1(R3)         REMOTE NUMBER                      FCI*
         AGO   .QSP4                                              UF020
.QSP3    ANOP                                                     UF020
         IC    R0,2(R3)         REMOTE NUMBER                     RNB21
.QSP4    ANOP                                                     UF020
         CVD   R0,DOUBLEWD    IN PACKED DECIMAL                    FCI*
         MVI   FPRINT,C'R'    INDICATE A REMOTE DEVICE             FCI*
         MVC   FPRINT+2(L'THREEPT),THREEPT SET UP THE EDIT MASK    FCI*
         EDMK  FPRINT+1(L'THREEPT),DOUBLEWD+6 CONVERT TO EBCDIC    FCI*
         MVC   FPRINT+1(L'THREEPT),0(R1) ADJUST FOR BLANKS         FCI*
         LA    R1,FPRINT+1    A(SPOT JUST BEFORE POSSIBLE SEP)     FCI*
FINDPT   LA    R1,1(R1)       A(NEXT BYTE)                         FCI*
         CLI   0(R1),C'.'     FOUND THE SEPARATOR?                 FCI*
         BNE   FINDPT         NO => KEEP LOOKING                   FCI*
         SR    R15,R15        FOR THE INSERT CHARACTER             FCI*
         IC    R15,0(R3)        DEVICE TYPE INDICATOR              FCI*
         SRL   R15,3          RIGHT JUSTIFIED                      FCI*
         LA    R15,RMTDEVS-HIGHBIT/8(R15) A(DEVICE TYPE)           FCI*
         MVC   1(2,R1),0(R15) PUT IN THE DEVICE TYPE               FCI*
         MVC   3(1,R1),0(R3) PUT IN THE DEVICE NUMBER              FCI*
         OI    3(R1),C'0'     MAKE THE DEVICE NUMBER PRINTABLE     FCI*
         B     SETDRTN
         EJECT ,                                                   FCI*
SETDRTN  L     R7,SETDHOLD    GET RETURN ADDRESS                   FCI*
         BR    R7             RETURN TO OUR CALLER                 FCI*
         SPACE 5                                                   FCI*
DIGITS3  DC    X'202020'                                           FCI*
THREEPT  DC    X'2020204B'                                         FCI*
         DS    0H                                                  FCI*
DEVTABLE DC    AL1(0),CL8'INTRDR',AL1(6),CL8'READER'               FCI*
         DC    AL1(7),CL8'PRINTER',AL1(5),CL8'PUNCH'               FCI*
DEVTYPEL DC    AL2((*-DEVTABLE)/4)                                 FCI*
RMTDEVS  DC    C'**',C'RD',C'PR',C'PU'                             FCI*
***********************************************************************
*                                                                     *
*   MISCELLANY                                                        *
*                                                                     *
***********************************************************************
         LTORG
ED8      DC    X'4020202020202120'
ED5      DC    X'402020202021'
ED3      DC    X'40202021'
HEADING  DC   C'      QUEUE  POSITION JOBNAME    JOB#  PRIORITY  LINES'
         DC    CL40'   EXECUTING'
HIGHBIT  EQU   X'80'
TABLE    EQU   *-240
         DC    C'0123456789ABCDEF' TRANSLATE TO PRINTABLE HEX
WORK     DSECT
         DS    CL80
CONVERT  DS    D
SETDHOLD DS    F
DOUBLEWD DS    D
NUMBER   DS    CL16
FORMAT   CSECT
SYMDEL   DSECT ,                   KILL SYM CARD GENERATION       UF023
FORMAT   CSECT ,                                                  UF023
         $JQE
         $JOE
JCT      EQU   0                                                  RNB25
BUFSTART EQU   0                                                  RNB25
BUFDSECT EQU   0                                                  RNB25
         $JCT                                                     RNB25
         QCOMMON
         ORG   QDMSG
FCLEAR   DS    0CL80          FORMAT FOR QUEUE RECORDS
         DS    CL4
FQNAME   DS    CL6            NAME OF QUEUE
         DS    C
FQUEUE   DS    C              CLASS NAME
         DS    CL2
FCOUNT   DS    CL6            POSITION IN QUEUE
         DS    CL2
FNAME    DS    CL8            JOBNAME
         DS    CL2
FJOBNO   DS    CL6            JES2 JOB NUMBER
         DS    CL2
FPRIO    DS    CL4            JOB PRIORITY
         DS    CL2
FLINES   DS    CL8            NUMBER OF OUTPUT LINES
         DS    CL3
FSYSID   DS    CL8            SYSTEM ID
         DS    CL3
FHOLD    DS    CL4            JOB HOLD STATUS
         DS    CL1
FREMOTE  DS    CL8            REMOTE
         ORG   FSYSID
FPRINT   DS    CL8            PRINTING
         ORG   FCOUNT
FHEX     DS    0CL56          LENGTH OF JQE HEX DUMP
FHEXO    DS    0CL64          LENGTH OF JOE HEX DUMP
FHEX1    DS    0CL15
         DS    CL14
FHEX2    DS    0CL15
         DS    CL14
FHEX3    DS    0CL15
         DS    CL14
FHEX4    DS    0CL15
         DS    CL14
FHEXC    DS    0CL9           CLEAR LAST BYTES FOR JQE
FHEX5    DS    0CL9
         DS    CL8
FHEXOC   DS    C              CLEAR LAST BYTE FOR JOE
SYMNODEL DSECT ,                   RESTORE SYM CARD GENERATION    UF023
         END
./ ADD NAME=GTTERM
         MACRO                                                          00050000
&NAME    GTTERM &PRMSZE=,&ALTSZE=,&ATTRIB=,&TERMID=,&MF=I      @G76XRYU 00070990
.*                                                             @OW03892 00071980
.* A000000-999999                                              @G76XR00 00075000
.* A034000                                                     @OZ90350 00077000
.* NOCHANGE SHIPPED WITH JCLIN                                 @OY20024 00078000
.* NOCHANGE SHIPPED WITH JCLIN                                 @OY26821 00079000
.* ADDED TERMID PARAMETER                                      @OW03892 00080990
.*                                                                      00081980
         LCLC  &NDX                                            @G76XRYU 00085000
&NDX     SETC  '&SYSNDX'                                       @G76XRYU 00090000
         AIF   ('&MF' EQ 'I' AND '&PRMSZE' EQ '' AND '&ATTRIB' EQ '' AN-00799990
               D '&TERMID' EQ '').ERROR1              @G76XRYU @OW03892 01499980
         AIF   ('&MF' EQ 'L').LFORM                                     02450000
         AIF   ('&MF(1)' EQ 'E').EFORM                                  02500000
         AIF   ('&MF' NE 'I').ERROR2                                    02550000
.*********************I -FORM OF MACRO********************************* 02600000
&NAME    CNOP  0,4                                                      02650000
         BAL   1,*+20                   BRANCH AROUND PARMS    @G76XRYU 02672990
.*                                                             @OW03892 02675980
GTRM&NDX DC    A(0)                     ADDRESS OF PRIMARY     @G76XRYU 02680000
         DC    A(0)                     ADDRESS OF ALTERNATE            02690000
         DC    A(0)                     ADDRESS OF ATTRIBUTE   @G76XRYU 02700000
         DC    A(0)                     ADDRESS OF TERMINAL ID @OW03892 03000000
         AGO   .STADDR                                                  03350000
.EFORM   ANOP                                                           03400000
&NAME    CNOP  0,4                                             @OZ90350 03429990
         IHBOPLST ,,&NAME,MF=&MF                                        03450000
.STADDR  ANOP                                                           03500000
.*********COMMON CODE FOR BOTH I AND E FORM OF MACRO******************  03550000
         AIF   ('&PRMSZE' EQ '').LABEL2                                 03600000
         AIF   ('&PRMSZE'(1,1) NE '(').LOADPRM                          03700000
         ST    &PRMSZE(1),0(,1)         STORE PRIMARY ADDRESS           03750000
         AGO   .LABEL2                                                  03800000
.LOADPRM ANOP                                                           03850000
         AIF   ('&PRMSZE'(K'&PRMSZE,1) EQ ')' OR '&MF' NE 'I').LPARM    03857000
         ORG   GTRM&NDX                 PUT ADDR OF PRIMARY    @G76XRYU 03864000
         DC    A(&PRMSZE)               IN PARM LIST           @G76XRYU 03871000
         ORG                                                            03878000
         AGO   .LABEL2                                         @G76XRYU 03885000
.LPARM   ANOP                      ..LA ADDR OR EXECUTE FORM   @G76XRYU 03892000
         LA    0,&PRMSZE                LOAD ADDRESS OF PRIMARY         03900000
         ST    0,0(,1)                  STORE ADDRESS OF PRIMARY        03950000
.LABEL2  ANOP                                                           04000000
         AIF   ('&ALTSZE' EQ '').IEATRCK                       @G76XRYU 04020000
         AIF   ('&ALTSZE'(1,1) NE '(').LOADALT                          04150000
         ST    &ALTSZE(1),4(,1)         STORE ADDRESS OF ALTERNATE      04200000
         AGO   .IEATRCK                                        @G76XRYU 04220000
.LOADALT ANOP                                                           04300000
         AIF   ('&ALTSZE'(K'&ALTSZE,1) EQ ')' OR '&MF' NE 'I').LAALT    04300100
         ORG   GTRM&NDX+4               PUT ALTERNATE SIZE     @G76XRYU 04306100
         DC    A(&ALTSZE)               IN PARM LIST           @G76XRYU 04312100
         ORG                                                            04318100
         AGO   .IEATRCK                                        @G76XRYU 04324100
.LAALT   ANOP                     ...LA ADDR OR EXECUTE FORM   @G76XRYU 04330100
         LA    0,&ALTSZE                LOAD ADDR OF ALTERNATE @G76XRYU 04336100
         ST    0,4(,1)                  STORE ADD OF ALTERNATE @G76XRYU 04350000
.*  PROCESS ATTRIBUTE PARM FOR I AND E FORMS WHEN NOT NULL     @G76XRYU 04450000
.IEATRCK ANOP                                                  @G76XRYU 04451000
         AIF   ('&ATTRIB' EQ '').LABEL3               @G76XRYU @OW03892 04452490
         AIF   ('&ATTRIB'(1,1) EQ '(').REGATR                  @G76XRYU 04453000
         AIF   ('&ATTRIB'(K'&ATTRIB,1) EQ ')' OR '&MF' NE 'I').LAATRIB  04454000
         ORG   GTRM&NDX+8               PUT ATTRIB BYTE ADDR   @G76XRYU 04455000
         DC    A(&ATTRIB)               IN PARM LIST           @G76XRYU 04456000
         ORG                                                            04457000
         AGO   .LABEL3                                @G76XRYU @OW03892 04458490
.LAATRIB ANOP                       .. LA ADDR OR EXECUTE FORM @G76XRYU 04459000
         LA    0,&ATTRIB                GET ADR OF ATTRIB BYTE @G76XRYU 04460000
         ST    0,8(1)                   PUT IN 3RD PARM WORD   @G76XRYU 04461000
         AGO   .LABEL3                                @G76XRYU @OW03892 04462490
.REGATR  ANOP                                                  @G76XRYU 04463000
         ST    &ATTRIB(1),8(1)          REG => 3RD PARM WORD   @G76XRYU 04464000
.*  PROCESS TERMINAL ID PARM FOR I AND E FORMS WHEN NOT NULL   @OW03892 04464040
.LABEL3  ANOP                                                  @OW03892 04464080
         AIF   ('&TERMID' EQ '').SVCENTY                       @OW03892 04464120
         AIF   ('&TERMID'(1,1) NE '(').LOTRMID                 @OW03892 04464160
         ST    &TERMID(1),12(,1)        STORE PRIMARY ADDRESS  @OW03892 04464200
         OI    12(1),128                END OF LIST INDICATOR  @OW03892 04464240
         AGO   .SVCENT2                                        @OW03892 04464280
.LOTRMID ANOP                                                  @OW03892 04464320
         AIF   ('&TERMID'(K'&TERMID,1) EQ ')' OR '&MF' NE 'I').LTERM    04464360
.*                                                             @OW03892 04464400
         ORG   GTRM&NDX+12              PUT ADDR OF TERMID IN  @OW03892 04464440
         DC    XL1'80',AL3(&TERMID)     PARM LIST WITH END OF  @OW03892 04464480
.*                                      LIST INDICATOR         @OW03892 04464520
         ORG                                                            04464560
         AGO   .SVCENT2                                        @OW03892 04464600
.LTERM   ANOP                      ..LA ADDR OR EXECUTE FORM   @OW03892 04464640
         LA    0,&TERMID                LOAD ADDRESS OF TERMINAL ID     04464680
.*                                                             @OW03892 04464720
         ST    0,12(,1)                 STORE ADDRESS OF TERMINAL ID    04464760
.*                                                             @OW03892 04464800
         OI    12(1),128                END OF LIST INDICATOR  @OW03892 04464840
         AGO   .SVCENT2                                        @OW03892 04464880
.SVCENTY ANOP                                                           04465000
         OI    8(1),128                 END OF LIST INDICATOR  @G76XRYU 04470000
.SVCENT2 ANOP                                                           04510000
         LA    0,17                     ENTRY CODE                      04550000
         SLL   0,24                     SHIFT TO HIGH ORDER BYTE        04600000
         SVC   94                       ISSUE SVC                       04650000
         MEXIT                                                          04700000
.***************  L  - FORM  ***************************                04750000
.LFORM   ANOP                                                           04800000
&NAME    DS    0F                                                       04850000
         AIF   ('&PRMSZE' EQ '').NOPRMAD                                04900000
         AIF   ('&PRMSZE'(1,1) EQ '(').NOPRMAD                          04950000
         DC    A(&PRMSZE)               ADDRESS OF PRIMARY PARM ADDR    05000000
         AGO   .CHKALT                                                  05050000
.NOPRMAD ANOP                                                           05100000
         DC    A(0)                     ADDRESS OF PRIMARY PARM ADDR    05150000
.CHKALT  AIF   ('&ALTSZE' EQ '').NOALTAD                                05200000
         AIF   ('&ALTSZE'(1,1) EQ '(').NOALTAD                          05250000
         DC    A(&ALTSZE)               ADDRESS OF ALTERNATE ADDR       05300000
         AGO   .LATTCK                                         @G76XRYU 05320000
.NOALTAD ANOP                                                           05400000
         DC    A(0)                     ADDR OF ALTERNATE      @G76XRYU 05420000
.*  PROCESS ATTRIBUTE PARM FOR LIST FORM                       @G76XRYU 05422000
.LATTCK  ANOP                                                  @G76XRYU 05424000
         AIF   ('&ATTRIB' NE '').CKATTR                        @G76XRYU 05426000
         DC    A(0)                     L-FORM--ATTRIB BYTE    @G76XRYU 05428000
         AGO   .CKTERM                                @G76XRYU @OW03892 05430990
.CKATTR  ANOP                                                  @G76XRYU 05432000
         AIF   ('&ATTRIB'(1,1) NE '(').ATTROK                  @G76XRYU 05434000
         MNOTE 12,'IHB300 INCOMPATIBLE OPERANDS: MF=L AND ATTRIB=&ATTRI*05436000
               B'                                              @G76XRYU 05438000
         AGO   .CKTERM                                @G76XRYU @OW03892 05440990
.ATTROK  ANOP                                                  @G76XRYU 05442000
         DC    A(&ATTRIB)               L-FORM--A(ATTR BYTE)   @G76XRYU 05444000
         AGO   .CKTERM                                         @OW03892 05558990
.CKTERM  AIF   ('&TERMID' EQ '').NOTRMAD                       @OW03892 05567980
         AIF   ('&TERMID'(1,1) EQ '(').NOTRMAD                 @OW03892 05576970
         DC    A(&TERMID)               ADDRESS OF TERMINAL ID ADDR     05585960
.*                                                             @OW03892 05594950
         MEXIT                                                 @OW03892 05603940
.NOTRMAD ANOP                                                  @OW03892 05612930
         DC    A(0)                     ADDRESS OF TERMINAL ID ADDR     05621920
.*                                                             @OW03892 05630910
         MEXIT                                                 @OW03892 05639900
.ERROR1  ANOP                                                           05650000
         IHBERMAC 1006,PRMSZE                                           05700000
         MEXIT                                                          05750000
.ERROR2  IHBERMAC 54,,&MF                                               05800000
         MEXIT                                                          05850000
         MEND                                                           05900000
./ ADD NAME=HELP     8020-02172-07001-1444-00218-00163-00000-GREG
HELP     QSTART 'QUEUE COMMAND - DISPLAY HELP'
         GBLB  &QPFK          PF-KEY OPTION. DEFINED BY QSTART     ICBC
         USING QDISPLAY,R10   BASE REG FOR DISPLAY WORK AREA
         L     R10,QVDSPL     ADDR OF DISPLAY WORK AREA
***********************************************************************
*                                                                     *
*   PASS HELP SCREEN TO DISPLAY MODULE                                *
*                                                                     *
***********************************************************************
         ICM   R2,3,QPDSID     LOOKING AT VALID DATA SET?         GP@P6
         BZ    HELPLOOP        NO                                 GP@P6
         OI    QFLAG1,QFLG1HLP YES, MAKE PF3 MEAN "EXIT HELP"     GP@P6
HELPLOOP QHEAD HEADING,X'07',DMY=Y       HEADING IN WHITE         GP@P6
         LA    R2,MESSAG1N     NUMBER OF MESSAGES                 UF003
         L     R3,=A(MESSAGE1) ADDRESS OF FIRST MESSAGE           UF003
         BAL   R4,PUTHELP      WRITE THE MESSAGES                 UF003
         SPACE 1                                                  UF003
         LA    R2,MESSAG2N     NUMBER OF MESSAGES                 UF003
         L     R3,=A(MESSAGE2) ADDRESS OF FIRST MESSAGE           UF003
         BAL   R4,PUTHELP      WRITE THE MESSAGES                 UF003
         SPACE 1                                                  UF003
         LA    R2,MESSAG3N     NUMBER OF MESSAGES                 UF003
         L     R3,=A(MESSAGE3) ADDRESS OF FIRST MESSAGE           UF003
         BAL   R4,PUTHELP      WRITE THE MESSAGE                  UF003
         SPACE 1                                                  GP@P6
         LA    R2,MESSAG4N     NUMBER OF MESSAGES                 GP@P6
         L     R3,=A(MESSAGE4) ADDRESS OF FIRST MESSAGE           GP@P6
         BAL   R4,PUTHELP      WRITE THE MESSAGE                  GP@P6
         SPACE 1                                                  UF003
         TM    QXAUTH,1       IS THE USER PRIVILEGED?             UF003
         BNO   NOAUTH         NO. SKIP.                           UF003
         LA    R2,MESSAGXN    NUMBER OF PRIV MSGS                 UF003
         L     R3,=A(MESSAGEX) ADDRESS OF FIRST MESSAGE           UF003
         BAL   R4,PUTHELP      WRITE THE MESSAGE                  UF003
         SPACE 1                                                  UF003
NOAUTH   DS    0H
         AIF  (NOT &QPFK).PFK1    SKIP DISPLAY OF PF-KEYS          ICBC
         QHEAD HEADINGS,X'07',DMY=Y      HEADING IN WHITE         GP@P6
         LA    R2,MESSAGSN     NUMBER OF MESSAGES                 GP@P6
         L     R3,=A(MESSAGES) ADDRESS OF FIRST MESSAGE           GP@P6
         BAL   R4,PUTHELP      WRITE THE MESSAGE                  GP@P6
         SPACE 1                                                  GP@P6
         QHEAD HEADINGP,X'07',DMY=Y      HEADING IN WHITE    GP@P6 ICBC
         LA    R2,MESSAGPN     NUMBER OF MESSAGES                 UF003
         L     R3,=A(MESSAGEP) ADDRESS OF FIRST MESSAGE           UF003
         BAL   R4,PUTHELP      WRITE THE MESSAGES                 UF003
         SPACE 1                                                  UF003
.PFK1    ANOP                                                      ICBC
         B     HELPLOOP                                           GP@P6
         SPACE 3                                                  UF003
PUTHELP  MVC   QDMLNG,=H'80'   SET MSG LENGTH                     UF003
PUTHELP1 ST    R3,QDMSGA       SET MESSAGE ADDRESS                UF003
         L     R15,=V(DISPLAY) ADDRESS OF DISPLAY ROUTINE         UF003
         BALR  R14,R15         LINK TO ROUTINE                    UF003
         LA    R3,80(,R3)      POINT TO NEXT LINE                 UF003
         BCT   R2,PUTHELP1     LOOP TILL DONE                     UF003
         SPACE 1                                                  UF003
         XC    QDMLNG,QDMLNG   SET TO FLUSH BUFFER                UF003
         L     R15,=V(DISPLAY) ADDRESS OF DISPLAY ROUTINE         UF003
         BALR  R14,R15         LINK TO ROUTINE                    UF003
         BR    R4              RETURN TO CALLER                   UF003
         SPACE 3                                                  UF003
***********************************************************************
*                                                                     *
*   MISCELLANY                                                        *
*                                                                     *
***********************************************************************
         LTORG
HEADING  DC    CL80'THE FOLLOWING SUBCOMMANDS ARE SUPPORTED:           +
               (VER 3.8J REL P6.2007.JAN.01)'                GP@P6
         AIF  (NOT &QPFK).PFK2    SKIP DISPLAY OF PF-KEYS          ICBC
HEADINGP DC    CL80'THE PF KEYS ARE DEFINED AS FOLLOWS:                +
               (VER 3.8J REL P6.2007.JAN.01)'                GP@P6 ICBC
HEADINGS DC    CL80'THE FOLLOWING SELECTION CODES ARE SUPPORTED:       +
               (VER 3.8J REL P6.2007.JAN.01)'                GP@P6
.PFK2    ANOP                                                      ICBC
MESSAGE1 DC    CL4' '
 DC CL80'DA           - DISPLAY ALL JOBS IN EXECUTION'
 DC CL80'DT           - DISPLAY TSO USERS'
 DC CL80'DS           - DISPLAY SYSTEM TASKS'
 DC CL80'DC           - DISPLAY CPU BATCH/STC/TSO'
 DC CL80'STATUS LEVEL - DISPLAY ALL JOBS BEGINNING WITH LEVEL'
 DC CL80'DQ           - DISPLAY INPUT QUEUES'
 DC CL80'DI CLASS     - DISPLAY ALL JOBS IN INPUT CLASS'
 DC CL80'AI CLASS     - DISPLAY JOBS AVAILABLE FOR PROCESSING'
 DC CL80'HI CLASS     - DISPLAY HELD JOBS IN INPUT CLASS'
 DC CL80'DF           - DISPLAY OUTPUT QUEUES'
 DC CL80'DO CLASS     - DISPLAY ALL JOBS IN OUTPUT CLASS'
 DC CL80'AO CLASS     - DISPLAY AVAILABLE OUTPUT'
 DC CL80'HO CLASS     - DISPLAY HELD OUTPUT'
 DC CL80'END          - TERMINATE PROCESSING'
 DC CL84' '
 DC CL80'DEFAULT FOR LEVEL IS LOGON ID'
 DC CL80'DEFAULT FOR CLASS IS ALL CLASSES'
 DC CL72'NO DEFAULT FOR JOBNAME'
MESSAG1N EQU   (*-MESSAGE1)/80 NUMBER OF MESSAGES                 UF003
         SPACE 1                                                  UF003
MESSAGE2 DC    CL4' '
 DC CL80'DJ JOBNAME        - DISPLAY JOB BY JOBNAME'
 DC CL80'JCL  JOBNAME      - LIST JCL FOR A JOB'
 DC CL80'JLOG JOBNAME      - LIST JOBLOG FOR A JOB (ONLY ON OUTPUT Q)'
 DC CL80'JMSG JOBNAME      - LIST SYSTEM MESSAGES FOR A JOB'
 DC CL80'DD   JOBNAME      - LIST SYSIN AND SYSOUT DATASETS FOR A JOB'
 DC CL80'PDDB JOBNAME      - LIST PDDB''S FOR A JOB'              UF025
 DC CL80'LIST JOBNAME DSID - LIST A SYSIN OR SYSOUT DATASET'
 DC CL80'FIND ''STRING'' COL(SS,EE)  - FIND CHARACTER STRING IN DATA'
 DC CL80'FALL ''STRING'' COL(SS,EE)  - FIND ALL OCCURRENCES OF STRING'
 DC CL80'                              COL DEFAULTS TO ALL           '
 DC CL80'COL  #            - REPOSITION HORIZONTALLY TO COLUMN NUMBER'
 DC CL80'@/MD #            - REPOSITION TO SPECIFIC RECORD NUMBER'
 DC CL80'+/D  # (P,H,M OK) - REPOSITION FORWARD IN DATASET # RECORDS'
 DC CL80'-/UP # (P,H,M OK) - REPOSITION BACKWARD IN DATASET # RECORDS'
 DC CL80'T/TOP             - REPOSITION TO TOP OF DATASET'
 DC CL80'B/BOTTOM          - REPOSITION TO BOTTOM OF DATASET'
 DC CL80'HF/HB #           - FORWARD/BACKWARD # HALF PAGES'
 DC CL80'PF/PB #           - FORWARD/BACKWARD # PAGES'
 DC CL84' '
 DC CL80'DSID CAN BE DETERMINED BY USING SUBCOMMAND DD OR PDDB'   UF025
 DC CL72'JOBNAME CAN BE JOB NAME, NUMBER, OR "*" OR "=" FOR CURRENT JOB+
               '                                            GP@P6 UF007
MESSAG2N EQU   (*-MESSAGE2)/80 NUMBER OF MESSGES                  UF003
         SPACE 1                                                  UF003
MESSAGE3 DC    CL4' '
 DC CL80'SLOG JOB# SEQ - LIST THE SYSTEM LOG DATASET'
 DC CL80'FTIME TIME    - REPOSITION SYSTEM LOG TO GIVEN TIME'
 DC CL80'SAVE DSNAME   - CREATE A COPY OF THE CURRENT DATASET'
 DC CL80'SPIN <CLASS><#LINES><DEST> - SPOOL COPY OF CURRENT DATASET'
 DC CL80'PRINT/PR ON <CLASS> <DEST> - OPEN SCREEN LOG'
 DC CL80'PRINT/PR                   - PRINT CURRENT SCREEN'
 DC CL80'PRINT/PR OFF               - CLOSE SCREEN LOG'
 DC CL80'MODEL/M #     - SET 3270 MODEL 2, 3, 4, 5, OR X'         UF003
 DC CL80'MONO          - PROHIBIT EXTENDED DATA STREAM USAGE'     GP@P6
 DC CL80'COLOR/COLOUR  - ACTIVATE EXTENDED DATA STREAM USAGE'     GP@P6
 DC CL80'NEXT/N <#>    - JUMP TO NEXT DATA SET <N TIMES>'         GP@P6
 DC CL80'PREV/P <#>    - JUMP TO PREVIOUS DATA SET <N TIMES>'     GP@P6
 DC CL80'TSO  CMD PRMS - ISSUE ANY TSO COMMAND W/ OPTIONAL PARMS' UF017
 DC CL80'EXEC CMD PRMS - ISSUE ANY TSO COMMAND W/ OPTIONAL PARMS' UF017
 DC CL84' '
 DC CL80'JOB# MAY BE DETERMINED BY STATUS SYSLOG'
 DC CL80'DEFAULT FOR SEQ IS 0 (THE CURRENT SYSLOG DATASET)'
 DC CL80'    (USE A VALUE OF 1, 2, ... TO OBTAIN PREVIOUS DATASETS)'
 DC CL80'TIME IS IN THE FORM HH.MM.SS'
 DC CL80'DSNAME WILL BE EXPANDED TO USERID.DSNAME.DATA'
 DC CL72'MODEL X SETS THE SCREEN SIZE TO THE CURRENT ALTERNATE SIZE' GP
MESSAG3N EQU   (*-MESSAGE3)/80 NUMBER OF MESSAGES                 UF003
         SPACE 1                                                  UF003
MESSAGE4 DC    CL84' '                THIS PAGE ADDED DEC 2006    GP@P6
 DC CL84'COMMANDS PASSED BY SUBSYSTEM INTERFACE (NEEDS APF):'
 DC CL80' '
 DC CL80'CAN/CA  JOBNAME  <PURGE/P>  - CANCEL JOB FROM INPUT/XEQ <AND P+
               RGE JOB>'
 DC CL80' '
 DC CL80'REQ/RE  JOBNAME  <NEWCLASS> - RELEASE OUTPUT FOR PRINTING <IN +
               NEW CLASS>'
 DC CL80' '
 DC CL72'DEL/DE  JOBNAME             - DELETE HELD SYSOUT'
MESSAG4N EQU   (*-MESSAGE4)/80 NUMBER OF MESSAGES                 GP@P6
         SPACE 1                                                  GP@P6
MESSAGEX DC    CL4' '                                             UF003
 DC CL84'PRIVILEGED SUBCOMMANDS:'
 DC CL80'XB MTTR              - DISPLAY BLOCK FROM SYS1.HASPACE'
 DC CL80'XD JOBNAME DSID      - UNRESTRICTED DISPLAY OF DATASETS'
 DC CL80'XI                   - DISPLAY ACTIVE INITIATORS       '
 DC CL80'XJ JOBNAME           - DISPLAY UNINTERPRETED JQES AND JOES'
 DC CL80'JQE JOBNAME          - DISPLAY JQE IN HEX/EBCDIC'        UF015
 DC CL80'JCT JOBNAME <OFFSET> - DISPLAY JCT IN HEX/EBCDIC'        UF016
 DC CL80'JOE JOBNAME          - DISPLAY JOES IN HEX/EBCDIC'       UF026
 DC CL72'HCT                  - DISPLAY HCT $SAVE AREA   '        UF022
MESSAGXN EQU   (*-MESSAGEX)/80 NUMBER OF MESSAGES                 UF003
         AIF  (NOT &QPFK).PFK3    SKIP DISPLAY OF PF-KEYS          ICBC
MESSAGEP DC    CL12' '                                             ICBC
 DC CL80'_____________________________'                            ICBC
 DC CL80'|PK1     |PK2     |PK3      |'                            ICBC
 DC CL80'|  HELP  |  DA    |   END   |'                            ICBC
 DC CL80'|________|________|_________|'                            ICBC
 DC CL80'|PK4     |PK5     |PK6      |'                            ICBC
 DC CL80'|  PRINT |  FIND  |   DI    |'                            ICBC
 DC CL80'|________|________|_________|'                            ICBC
 DC CL80'|PK7     |PK8     |PK9      |'                            ICBC
 DC CL80'|  PB    |  PF    |   DO    |'                            ICBC
 DC CL80'|________|________|_________|'                            ICBC
 DC CL80'|PK10    |PK11    |PK12     |'                            ICBC
 DC CL80'|  COL 1 | COL 41 |   ST    |'                            ICBC
 DC CL80'|________|________|_________|'                            ICBC
 DC CL72' '                                                        ICBC
 DC CL80'TO SPECIFY OPERANDS (FOR PF5, AND OPTIONALLY FOR PF6, 9, 12),'
 DC CL80'OR TO TEMPORARILY OVERRIDE THE DEFAULTS (FOR PF7, 8, 10, 11),'
 DC CL76'KEY IN THE VALUE AND PRESS THE APPROPRIATE PF KEY.'       ICBC
MESSAGPN EQU   (*-MESSAGEP)/80 NUMBER OF MESSAGES                 UF003
         SPACE 1
MESSAGES DC    CL84' '       SELECTION CODE HELP    NOV 2002      GP@P6
 DC CL86'SELECTION CODES FOR JOBS AND ADDRESS SPACES'
 DC CL80'A  (*)   - RELEASE THE JOB'
 DC CL80'C  (*)   - CANCEL THE JOB'
 DC CL80'D        - DISPLAY THE SPOOL DATA SETS OF THE JOB'
 DC CL80'H  (*)   - HOLD THE JOB'
 DC CL80'J        - DISPLAY THE JCL OF THE JOB'
 DC CL80'L        - DISPLAY THE JOB LOG OF THE JOB'
 DC CL80'M        - DISPLAY THE JOB MESSAGES OF THE JOB'
 DC CL80'O  (*)   - RELEASE HELD SYSOUT FOR PRINTING/PUNCHING'
 DC CL80'P  (*)   - PURGE THE JOB OR DELETE THE HELD OUTPUT'
 DC CL80'S        - BROWSE THE SPOOL DATA SETS OF THE JOB'
 DC CL74' '
 DC CL86'SELECTION CODES FOR INITIATORS'
 DC CL80'S  (*)   - START THE INITIATOR (CREATES AN ADDRESS SPACE)'
 DC CL80'Z  (*)   - HALT THE INITIATOR (STOPS JOB SELECTION)'
 DC CL80'P  (*)   - DRAIN THE INITIATOR (TERMINATES THE ADDRESS SPACE)'
 DC CL74' '
 DC CL80'(*) - COMMAND REQUIRES SUITABLE AUTHORISATION'
 DC CL80' '
 DC CL76'AN ''S'' SELECTION IS IMPLIED BY PLACING THE CURSOR ON A LEADE+
               R DOT'
MESSAGSN EQU   (*-MESSAGES)/80 NUMBER OF MESSGES                  GP@P6
.PFK3    ANOP                                                      ICBC
SYMDEL   DSECT ,                   KILL SYM CARD GENERATION       UF023
         QCOMMON
SYMNODEL DSECT ,                   RESTORE SYM CARD GENERATION    UF023
         END
./ ADD NAME=HEXBLK
HEXBLK   QSTART 'QUEUE COMMAND - HEXADECIMAL DUMP OF A BLOCK'
         USING QCKPT,R10      BASE REG FOR CKPT WORK AREA
         L     R10,QVCKPT     LOAD BASE REG
         USING QDISPLAY,R9    BASE REG FOR DISPLAY WORK AREA
         L     R9,QVDSPL      LOAD BASE REG
         L     R2,QCBLKA      BLOCK IOAREA ADDR                   UF013
***********************************************************************
*                                                                     *
*   VALIDATE AND CONVERT BLOCK ADDRESS                                *
*                                                                     *
***********************************************************************
         LH    R1,QLNG1       LENGTH OF USER PARM
         LTR   R1,R1          IS THE LENGTH ZERO?
         BNP   TILT           YES. TILT.
         CH    R1,=H'8'       IS THE LENGTH TOO BIG?
         BH    TILT           YES. TILT.
         CLI   QPARM1,C'*'    USE CURRENT BUFFER CONTENTS?        UF013
         BE    READOK         YES, SKIP THE READ                  UF013
         CLI   QPARM1,C'+'    CHAIN TO NEXT BLOCK?                UF013
         BNE   READ1          NO, CONTINUE WITH NORMAL CODE       UF013
         MVC   QCTRAK,0(R2)   GET NEXT BLOCK ADDRESS              UF013
         OC    QCTRAK,QCTRAK  TEST FOR END OF CHAIN               UF013
         BNZ   READ2          GO READ BLOCK IF OK                 UF013
         QTILT ' *** BLOCK CHAIN FIELD IS ZERO ***'               UF013
READ1    MVC   QDWORD,QPARM1  LEAVE THE ORIGINAL ALONE            UF013
         TR    QDWORD,TABLEH  CONVERT TO HEX                      UF013
         EX    R1,PACK        PACK INTO QCTRAK
***********************************************************************
*                                                                     *
*   READ THE BLOCK FROM HASPACE                                       *
*                                                                     *
***********************************************************************
READ2    DS    0H                                                 UF013
         LR    R1,R2          PARM FOR READSPC
         L     R15,=V(READSPC) ROUTINE TO READ HASPACE
         BALR  R14,R15        GO TO IT
READOK   DS    0H                                                 UF013
***********************************************************************
*                                                                     *
*   PRINT THE BLOCK                                                   *
*                                                                     *
***********************************************************************
         LH    R0,HASPACE+62  LENGTH OF DATA                      UF012
         LH    R1,QLNG2       LENGTH OF USER OFFSET               UF013
         LTR   R1,R1          IS THE LENGTH ZERO?                 UF013
         BNP   DUMP1          YES. NONE SPECIFIED                 UF013
         CH    R1,=H'8'       IS THE LENGTH TOO BIG?              UF013
         BH    TILTO          YES, GIVE UP                        UF013
         EX    R1,OFFTR       CONVERT TO HEX                      UF013
         EX    R1,OFFPACK     PACK INTO QDWORD                    UF013
         LH    R1,QDWORD      PICK UP OFFSET                      UF013
         AR    R2,R1          ADD TO BASE ADDRESS                 UF013
         SR    R0,R1          SUBTRACT FROM TOTAL LENGTH          UF013
         SLL   R1,16          MOVE TO PROPER POSITION             UF013
         OR    R0,R1          INSERT INTO LENGTH REG              UF013
DUMP1    LR    R1,R2          POINT TO BUFFER READ                UF012
         L     R15,=V(HEXDUMP) ADDRESS OF DUMP ROUTINE            UF012
         BALR  R14,R15        LINK TO IT                          UF012
STOP     QSTOP
***********************************************************************
*                                                                     *
*   EXCEPTIONS AND RETURN                                             *
*                                                                     *
***********************************************************************
TILT     QTILT '*** BLOCK ADDRESS WAS OMITTED ***'
TILTO    QTILT '*** INVALID OFFSET SPRCIFIED ***'
***********************************************************************
*                                                                     *
*   MISCELLANY                                                        *
*                                                                     *
***********************************************************************
PACK     PACK  QCTRAK(5),QDWORD(1) BLOCK ADDRESS                  UF013
OFFTR    TR    QPARM2,TABLEH       CONVERT TO HEX                 UF013
OFFPACK  PACK  QDWORD(3),QPARM2(1) PACK TO WORK AREA              UF013
         LTORG
* TABLE FOR HEX CONVERT
TABLEH   DC    CL193' '
         DC    X'0A0B0C0D0E0F',CL41' ',C'01234567890',CL6' '
SYMDEL   DSECT ,                   KILL SYM CARD GENERATION       UF023
         QCOMMON
SYMNODEL DSECT ,                   RESTORE SYM CARD GENERATION    UF023
         END
./ ADD NAME=HEXDUMP  8000-02173-02173-0046-00171-00171-00000-GREG
HEXDUMP  QSTART 'QUEUE COMMAND - HEX DUMP OF PASSED DATA AREA'    UF011
         L     R10,QVCKPT     LOAD BASE REG
         USING QCKPT,R10      BASE REG FOR CKPT WORK AREA
         L     R9,QVDSPL      LOAD BASE REG
         USING QDISPLAY,R9    BASE REG FOR DISPLAY WORK AREA
         L     R8,QVPRINT     LOAD BASE REG
         USING QCPRINT,R8     BASE REG FOR DISPLAY WORK AREA
         LA    R8,QPLINE      LOAD BASE REG
         USING WORK,R8        BASE REG FOR PRINT LINE AREA
***********************************************************************
*                                                                     *
*   INPUT:                                                            *
*        R1    POINTER TO DATA AREA TO BE DUMPED                      *
*        R0    OFFSET AND LENGTH OF AREA TO DUMP (2 BYTES EACH)       *
*              (OFFSET IS USED FOR PRINT DISPLACEMENT FIELD ONLY)     *
*              (AS AN EXAMPLE, THE DUMP OF A JCT IS MOST USEFUL       *
*              IF THE OFFSET IS SET TO THE LENGTH OF ITS              *
*              ASSOCIATED IOB)                                        *
*                                                                     *
***********************************************************************
         LR    R6,R1          POINTER TO START OF DATA AREA
         LR    R3,R0          PRINT OFFSET FOR AREA
         SRL   R3,16          MOVE TO PROPER POSITION
         LR    R4,R0          LENGTH TO DUMP
         SLL   R4,16          THROW AWAY OFFSET
         SRL   R4,16          MOVE LENGTH TO PROPER POSITION
***********************************************************************
*                                                                     *
*   FORMAT THE AREA                                                   *
*                                                                     *
***********************************************************************
         QHEAD QBLANK,X'04'   BLANK THE TITLE LINE                GP@P6
         LA    R5,WORKLINE    POINT TO LINE IN WORK AREA
         ST    R5,QDMSGA      STORE ADDR OF PRINT LINE
         MVC   QDMLNG,=H'80'  LENGTH OF MESSAGE
         CLC   QDLNELEN,=H'132' LONG ENOUGH FOR DOUBLE LINE?
         BL    *+4+6          NO, SKIP RESET OF LENGTH
         MVC   QDMLNG,=H'132' LENGTH OF MESSAGE
         SPACE 1
LOOP     MVC   WORKLINE,QBLANK  BLANK THE WORK AREA
         STH   R3,QDWORD      GET OFFSET
         UNPK  OFFSET(5),QDWORD(3) CONVERT TO HEX
         MVI   OFFSET+L'OFFSET,C' ' CLEAR GARBAGE BYTE
         TR    OFFSET,TABLEP  TRANSLATE TO PRINTABLE CHARACTERS
         SPACE 1
         LR    R2,R6          POINTER TO DATA AREA
         LA    R1,4           NUMBER OF WORDS IN LINE AREA
         LA    R14,O1         POINTER TO FIRST OUTPUT AREA
         LA    R15,P1         POINTER TO EBCDIC AREA
         MVI   PS1,C'*'       SET STARS
         MVI   PS2,C'*'       SET STARS
         CLC   QDLNELEN,=H'132' SHORT LINES?
         BL    LOOP1          YES, SKIP SETTING ALTERNATE PRINT AREA
         MVI   PS1,C' '       FIX OTHER FLAG
         MVI   PS2,C' '       FIX OTHER FLAG
         LA    R15,P1A        ALTERNATE EBCDIC AREA
         MVI   PS1A,C'*'      SET STARS
         MVI   PS2A,C'*'      SET STARS
         SPACE 1
LOOP1    UNPK  0(9,R14),0(5,R2)  UNPACK DATA TO PRINT LINE
         TR    0(8,R14),TABLEP TRANSLATE TO PRINTABLE CHARACTERS
         MVI   8(R14),C' '    CLEAR WASTE BYTE
         MVC   0(4,R15),0(R2) COPY DATA TO PRINT AREA
         TR    0(4,R15),PRTAB FIX UNPRINTABLES
         LA    R2,4(,R2)      NEXT DATA AREA
         LA    R3,4(,R3)      BUMP OFFSET
         LA    R14,9(,R14)    NEXT HEX AREA
         LA    R15,4(,R15)    NEXT PRINT AREA
         SH    R4,=H'4'       DROP BY PROCESSED LENGTH
         BNP   PRINT1
         BCT   R1,LOOP1       LOOP FOR ALL FOUR WORDS
         SPACE 1
         CLC   QDLNELEN,=H'132' SHORT LINES?
         BL    PRINT1         YES, PRINT WHAT WE HAVE
         LA    R14,O5         POINT TO OUTPUT AREA
         LA    R15,P5A        POINT TO OUTPUT AREA
         LA    R1,4           NUMBER OF WORDS
         SPACE 1
LOOP2    UNPK  0(9,R14),0(5,R2)  UNPACK DATA TO PRINT LINE
         TR    0(8,R14),TABLEP TRANSLATE TO PRINTABLE CHARACTERS
         MVI   8(R14),C' '    CLEAR WASTE BYTE
         MVC   0(4,R15),0(R2) COPY DATA TO PRINT AREA
         TR    0(4,R15),PRTAB FIX UNPRINTABLES
         LA    R2,4(,R2)      NEXT DATA AREA
         LA    R3,4(,R3)      BUMP OFFSET
         LA    R14,9(,R14)    NEXT HEX AREA
         LA    R15,4(,R15)    NEXT PRINT AREA
         SH    R4,=H'4'       DROP BY PROCESSED LENGTH
         BNP   PRINT1
         BCT   R1,LOOP2       LOOP FOR ALL FOUR WORDS
         SPACE 1
PRINT1   L     R15,=V(DISPLAY) ADDR OF DISPLAY MODULE
         BALR  R14,R15        GO TO IT
         LR    R15,R6         ADDR OF DATA JUST DUMPED
         LR    R6,R2          ADDRESS OF NEXT TO DUMP
         SR    R2,R15         LENGTH JUST DUMPED
         BCTR  R2,0           DROP FOR EXECUTE
         SPACE 1
SKIP     DS    0H
         LTR   R4,R4          TEST REMAINING LENGTH
         BNP   STOP           YES. GO HOME.
         EX    R2,CLC         IS THIS RECORD THE SAME AS PREVIOUS?
         BNE   LOOP           NO, PRINT IT
         LA    R6,1(R2,R6)    BUMP TO NEXT AREA
         LA    R3,1(R2,R3)    BUMP OFFSET
         SR    R4,R2          DROP BY LENGTH DUMPED
         BCTR  R4,0           FIX FOR EXECUTE STUFF
         B     SKIP           SKIP PRINTING DUPS
         SPACE 1
CLC      CLC   0(*-*,R15),0(R6)  TEST FOR SAME DATA
***********************************************************************
*                                                                     *
*   RETURN                                                            *
*                                                                     *
***********************************************************************
STOP     QSTOP
***********************************************************************
*                                                                     *
*   MISCELLANY                                                        *
*                                                                     *
***********************************************************************
         LTORG
* TABLE TO REMOVE UNPRINTABLES
PRTAB    DC    CL64' '
         DC    192AL1(*-PRTAB)
* TABLE FOR HEX UNCONVERT
TABLEP   EQU   *-240
         DC    C'0123456789ABCDEF'
SYMDEL   DSECT ,                   KILL SYM CARD GENERATION       UF023
         QCOMMON
WORK     DSECT ,
WORKLINE DS    CL132          LINE TO PRINT
         ORG   WORKLINE       BACK UP TO WORK LINE
OFFSET   DS    CL4            OFFSET INTO AREA
         DS    XL3            SPACER
O1       DS    CL8            OUTPUT HEX AREA
         DS    X              SPACER
O2       DS    CL8            OUTPUT HEX AREA
         DS    X              SPACER
O3       DS    CL8            OUTPUT HEX AREA
         DS    X              SPACER
O4       DS    CL8            OUTPUT HEX AREA
         DS    XL3            SPACER
O5       DS    CL8            OUTPUT HEX AREA
         DS    X              SPACER
O6       DS    CL8            OUTPUT HEX AREA
         DS    X              SPACER
O7       DS    CL8            OUTPUT HEX AREA
         DS    X              SPACER
O8       DS    CL8            OUTPUT HEX AREA
         DS    XL2            SPACER
PS1A     DS    C              STAR FOR PRINT AREA
P1A      DS    CL4            PRINT AREA
P2A      DS    CL4            PRINT AREA
P3A      DS    CL4            PRINT AREA
P4A      DS    CL4            PRINT AREA
P5A      DS    CL4            PRINT AREA
P6A      DS    CL4            PRINT AREA
P7A      DS    CL4            PRINT AREA
P8A      DS    CL4            PRINT AREA
PS2A     DS    C              STAR FOR PRINT AREA
         ORG   O5-1           BACK UP FOR SHORT LINES
PS1      DS    C              STAR FOR PRINT AREA
P1       DS    CL4            PRINT AREA
P2       DS    CL4            PRINT AREA
P3       DS    CL4            PRINT AREA
P4       DS    CL4            PRINT AREA
PS2      DS    C              STAR FOR PRINT AREA
         ORG   ,              BACK TO NORMAL ADDRESSING
SYMNODEL DSECT ,                   RESTORE SYM CARD GENERATION    UF023
         END
./ ADD NAME=INIT     8007-02153-06364-1637-00603-00532-00000-GREG
INIT     QSTART 'QUEUE COMMAND - INITIALIZATION ROUTINES'
***********************************************************************
* RNB CHANGES:                                                        *
*            (3) RNB03 - IF RACF OPTION IS SET, AND IF AUTHORIZED,    *
*                        AND IF QNEWUSR IS NON-NULL, CHANGE ACEEUSER  *
*                        SO USER WILL BE AUTHORIZED TO OPEN CKPT/SPOOL*
***********************************************************************
         GBLB  &QSP           MVS/SP OPTION                       UF020
         GBLB  &QDBC          DBC    OPTION                       UF024
         GBLB  &QRACF         RACF OPTION                         RNB03
         GBLB  &QRNB          RNB OPTION FLAG                     RNB05
***********************************************************************
*                                                                     *
*   LOAD QCOMMON                                                      *
*                                                                     *
***********************************************************************
*
****
*******  IF YOU WANT TO CHANGE THE NAME FOR THE COMMON AREA,
****               THIS IS THE ONLY REFERENCE TO IT.
*
         L     R11,=V(QCOMMON) ADDR OF QCOMMON                    UF002
         LTR   R11,R11        SEE IF LINKED IN                    UF002
         BNZ   LOADED         YES, CONTINUE                       UF002
         SPACE 1                                                  UF002
         LOAD  EP=QUEUECMN    QUEUE COMMON AREA
         LR    R11,R0         ADDR OF QCOMMON
         SPACE 1                                                  UF002
LOADED   DS    0H                                                 UF002
         L     R1,4(R13)      PREVIOUS SAVE AREA
         ST    R11,64(R1)     UPDATE R11 IN PREVIOUS SAVE AREA
         ST    R1,QFRSTSA     STORE ADDR OF FIRST SAVEAREA IN QCOMMON
         USING QDAIR,R10      BASE REG FOR DAIR WORK
         L     R10,QVDAIR     LOAD BASE REG
         USING QCKPT,R9       BASE REG FOR CKPT WORK
         L     R9,QVCKPT      LOAD BASE REG
         USING QDISPLAY,R8    BASE REG FOR DISPLAY WORK
         L     R8,QVDSPL      LOAD BASE REG
***********************************************************************
*                                                                     *
*   DETERMINE APF AUTHORIZATION STATUS                GP@P6 JUNE 2002 *
*                                                                     *
***********************************************************************
         TESTAUTH FCTN=1
         LTR   R15,R15        APF AUTHORIZED?
         BNZ   AUTHDONE       NO
         OI    QFLAG1,QFLG1APF
AUTHDONE DS    0H
***********************************************************************
*                                                                     *
*   VERIFY PSCB ADDRESS                               GP@P6 JULY 2002 *
*                                                                     *
***********************************************************************
         USING CPPL,R2        ADDR OF CPPL IS IN R2
         USING PSA,0
         L     R3,PSATOLD     POINT TO THE CURRENT TASK
         USING TCB,R3
         L     R3,TCBJSCB     POINT TO THE JOB STEP CONTROL BLOCK
         DROP  R3
         USING JSCB,R3
         L     R3,JSCBPSCB    POINT TO THE PROTECTED STEP CONTROL BLOCK
         DROP  R3
         C     R3,CPPLPSCB    CORRECT PSCB ADDRESS SUPPLIED?
         BE    CORECTPL       YES
         ST    R3,CPPLPSCB    NO, CORRECT IT
         TM    CPPLCBUF,X'80' WAS QUEUE CALLED?
         BO    CALLEDPL       YES, NO WONDER THE CPPL IS WRONG
*                             NO, THE PARAMETER LIST HAS BEEN HACKED
         WTO   '*** QUEUE PARAMETER LIST ERROR ***',ROUTCDE=(9,11)
         ABEND 913            ABORT
CALLEDPL L     R3,48(,R3)     POINT TO THE RELOGON BUFFER
         L     R3,256(,R3)    POINT TO THE ENVIRONMENT CONTROL TABLE
         ST    R3,CPPLECT     SUPPLY CORRECT ECT ADDRESS
         OI    CPPLECT,X'80'  FLAG LAST PARAMETER OF THE CPPL
CORECTPL DS    0H
***********************************************************************
*                                                                     *
*   MOVE PARMS FROM CPPL TO DAPL                                      *
*                                                                     *
***********************************************************************
         MVC   DAPLUPT,CPPLUPT USER PROFILE TABLE
         MVC   DAPLPSCB,CPPLPSCB PROTECTED STORAGE CNTL BLK
         MVC   DAPLECT,CPPLECT ENVIRONMENT CNTL TABLE
         AIF   (&QRNB).RNB02      SKIP IF AT RNB                  RNB02
******************************************************************UF010
*                                                                 UF010
*   CHECK PSCB FOR OPERATOR AUTHORITY                             UF010
*                                                                 UF010
******************************************************************UF010
         L     R1,CPPLPSCB    ADDRESS OF PSCB                     UF010
         USING PSCB,R1        ADDRESSING FOR PSCB                 UF010
         TM    PSCBATR1,PSCBCTRL  TEST FOR OPERATOR AUTHORITY     UF010
         BZ    NOTOPER        NO, SKIP THIS                       UF010
         OI    QFLAG1,QFLG1OPR    SET OPER AUTH                   UF010
         OI    QXAUTH,1           SET PRIV AUTH                   UF010
         AIF   (NOT &QDBC).NODBC1 SKIP IF DBC NOT INSTALLED       UF024
******************************************************************UF024
*                                                                 UF024
*   IF USER HAS OPER AUTHORITY, ESTABLISH ESTAE ENVIRONMENT       UF024
*                                                                 UF024
******************************************************************UF024
         LOAD  EP=DBC,ERRET=NOTOPER  LOAD ESTAE ROUTINE           UF024
         LR    R3,R0          ADDR OF ROUTINE                     UF024
         ESTAE (R3)           CREATE THE ESTAE                    UF024
         OI    QFLAG1,QFLG1DBC  INDICATE NEED TO DELETE AT TERM   UF024
.NODBC1  ANOP                                                     UF024
.RNB02   ANOP                                                     RNB02
NOTOPER  DS    0H                                                 UF010
***********************************************************************
*                                                                     *
*   FIND THE CHECKPOINT VOLUME                        GP@P6 JULY 2002 *
*                                                                     *
***********************************************************************
         L     R3,16          POINT TO CVT
         USING CVTDSECT,R3
         L     R3,CVTJESCT    POINT TO JESCT
         DROP  R3
         USING JESCT,R3
         L     R3,JESSSCT     POINT TO SSCT
         DROP  R3
         USING SSCT,R3
         L     R3,SSCTSSVT    POINT TO SSVT
         DROP  R3
         USING SSVT,R3
         MVC   DA08SER(6),$SVCHKPT
         DROP  R3
***********************************************************************
*                                                                     *
*   PROCESS COMMAND OPERAND                                           *
*                                                                     *
***********************************************************************
         L     R1,CPPLCBUF    ADDR OF COMMAND BUFFER
         LH    R3,0(R1)       LENGTH OF COMMAND BUFFER
         LH    R4,2(R1)       OFFSET TO FIRST DATA BYTE
         LA    R1,4(R1,R4)    FIRST DATA BYTE
         SR    R3,R4          SUBTRACT OFFSET FROM LENGTH
         SH    R3,=H'4'       SUBTRACT OVERHEAD
         SH    R3,=H'1'       IS LENGTH ZERO?
         BM    SKIP           YES. SKIP IT.
         EX    R3,OCBUF       TRANSLATE TO UPPER CASE
         CLC   =C'CKPT(',0(1) IS REQUEST FOR CKPT?
         BE    CKPT           YES. DO IT.
         MVC   QDREPLY,QBLANK BLANK THE REPLY LINE
         CH    R3,=H'62'      IS LENGTH OVER 63?
         BNH   OK             NO. USE IT.
         LA    R3,62          USE MAXIMUM LENGTH
OK       EX    R3,MVCBUF      MOVE THE DATA
         LA    R3,1(R3)       INCREMENT TO TRUE LENGTH
         STH   R3,QDRLNG      STORE REPLY LENGTH
***********************************************************************
*                                                                     *
*   LOCATE LOGON ID, MOVE TO QLOGON                                   *
*                                                                     *
***********************************************************************
SKIP     L     R1,16          ADDR OF CVT
         L     R1,0(R1)       ADDR OF DISPATCH QUEUE
         L     R1,12(R1)      ADDR OF CURRENT ASCB
         L     R1,176(R1)     ADDR OF JOBNAME
         MVC   QLOGON,0(R1)   MOVE JOBNAME TO QLOGON
***********************************************************************
*                                                                     *
*   OBTAIN BLOCK ADDR TABLE FOR LISTDS                                *
*                                                                     *
***********************************************************************
         GETMAIN R,LV=65536
         ST    R1,QGETA1      SAVE START ADDR OF GETMAIN
         ST    R1,QCSTART     STORE STARTING ADDR OF TABLE
         A     R1,=F'65536'   END OF TABLE
         ST    R1,QCEND
***********************************************************************
*                                                                     *
*   ALLOCATE HASPCKPT                                                 *
*                                                                     *
***********************************************************************
         MVC   DA08DDN,=CL8'HASPCKPT' DDNAME FOR ALLOCATE
         MVC   DA08PDSN,=A(DSNCKPT) DSNAME FOR ALLOCATE
         MVI   DAIRFLAG,X'08' REQUEST ALLOCATE FUNCTION
         L     R15,=V(ALLOCATE) ADDR OF ALLOCATE MODULE
         BALR  R14,R15        GO TO IT
***********************************************************************
*                                                                     *
*   OPEN HASPCKPT, READ FIRST BLOCK OF CHECKPOINT                     *
*                                                                     *
***********************************************************************
         AIF   (NOT &QRACF).RNB03B                                RNB03
**       TESTAUTH FCTN=1             APF-AUTHORIZED?              RNB03
**       LTR   R15,R15                                            RNB03
**       BNZ   RNB03A                /NO  - CAN'T CHG ACEEUSER    RNB03
         TM    QFLAG1,QFLG1APF       APF-AUTHORIZED?           GP RNB03
         BNO   RNB03A                /NO  - CAN'T CHG ACEEUSER GP RNB03
*                                    /YES -                       RNB03
         RACSTAT ,                   IS RACF UP?                  RNB03
         LTR   R15,R15                                            RNB03
         BNZ   RNB03A                /NO  - CAN'T CHG ACEEUSER    RNB03
*                                    /YES -                       RNB03
         CLI   QNEWUSR,0             IS THERE A NEW USERID TO USE?RNB03
         BE    RNB03A                /NO  - CAN'T CHG ACEEUSER    RNB03
*                                    /YES - CHANGE ACEEUSER TO    RNB03
*                                           ALLOW ACCESS TO THE   RNB03
*                                           SPOOL/CKPT DATA SETS  RNB03
         L     R2,CVTPTR             CVT                          RNB03
         USING CVT,R2                #####                        RNB03
         L     R2,CVTTCBP            TCB WORDS                    RNB03
         L     R2,12(,R2)            CURRENT ASCB                 RNB03
         USING ASCB,R2               #####                        RNB03
         L     R2,ASCBASXB           ASXB                         RNB03
         USING ASXB,R2               #####                        RNB03
         ICM   R2,15,ASXBSENV        ACEE                         RNB03
         BZ    RNB03A                FORGET IT IF NO ACEE         RNB03
         USING ACEE,R2               #####                        RNB03
         CLC   =C'ACEE',ACEEACEE     REALLY AN ACEE?              RNB03
         BNE   RNB03A                /NO  - FORGET IT             RNB03
         MVC   QUSRSAV,ACEEUSER      /YES - SAVE CURRENT USERID   RNB03
         STAX  DEFER=YES             DON'T ALLOW ATTENTION'S      RNB03
         MODESET KEY=ZERO            GET KEY ZERO TO UPDATE ACEE  RNB03
         MVC   ACEEUSER,QNEWUSR      SET NEW USERID               RNB03
         MODESET KEY=NZERO           BACK TO USER KEY             RNB03
RNB03A   EQU   *                                                  RNB03
.RNB03B  ANOP                                                     RNB03
         OPEN  MF=(E,HOCKPT)  OPEN HASPCKPT
         L     R2,QCSTART     USE TABLE AREA FOR IOAREA
         POINT HASPCKPT,TIR3  POINT PAST SYNC RECORDS
         READ  HDECB1,SF,,(R2),MF=E READ FIRST RECORD
         CHECK HDECB1
***********************************************************************
*                                                                     *
*   COMPUTE OFFSET TO FIRST PDDB IN IOT                               *
*                                                                     *
***********************************************************************
         USING $SAVEBEG,R2    BASE REG FOR CHECKPOINT
         AIF   (&QSP).QSP1                                        UF020
         LH    R5,$NUMTGV     NUMBER OF TRACK GROUPS PER VOLUME
         LA    R5,7(R5)       ROUND UP TO MULTIPLE OF 8
         SRL   R5,3           DIVIDE BY 8
         SR    R0,R0          ZERO OUT R0
         IC    R0,$NUMDA      NUMBER OF SPOOL VOLUMES
         MR    R4,R0          LENGTH OF TRACK GROUP MAP IN R5
         AGO   .QSP2                                              UF020
.QSP1    ANOP                                                     UF020
         LH    R5,$NUMTG      NUMBER OF TRACK GROUPS PER VOLUME   UF020
         LA    R5,7(R5)       ROUND UP TO MULTIPLE OF 8           UF020
         SRL   R5,3           DIVIDE BY 8                         UF020
.QSP2    ANOP                                                     UF020
         LR    R1,R5          SAVE LENGTH OF TRACK GROUP MAP
         LA    R5,IOTTGMAP-IOTSTART+TGMAP-TGMDSECT+3(R5) OFFSET
         N     R5,=F'-4'      ROUND TO FULL WORD BOUNDARY
         ST    R5,QCPDDB1     SAVE OFFSET TO FIRST PDDB IN IOT
         AIF   (NOT &QSP).QSP3                                    UF020
***********************************************************************
*                                                                     *
*   COMPUTE NUMBER OF JIX BLOCKS ON CKPT                              *
*                                                                     *
***********************************************************************
         LH    R5,$NUMJBNO    NUMBER OF JOB NUMBERS               UF020
         LA    R5,1(,R5)       PLUS 1 FOR HEADER                  UF020
         SLL   R5,1           TIMES LENGTH OF 2                   UF020
         LA    R5,4095(R5)    PREPARE TO ROUND                    UF020
         SRL   R5,12          DIVIDE BY 4096                      UF020
         STH   R5,QCJIXL      NUMBER OF BLOCKS FOR JIX            UF020
.QSP3    ANOP                                                     UF020
***********************************************************************
*                                                                     *
*   COMPUTE NUMBER OF JQE BLOCKS ON CKPT                              *
*                                                                     *
***********************************************************************
         LH    R6,$MAXJOBS    NUMBER OF JQES
         LA    R6,1(,R6)       PLUS 1 FOR EYE-CATCHER
         MH    R6,=AL2(JQELNGTH) MULTIPLY BY LENGTH OF JQE
         LA    R6,4095(R6)    PREPARE TO ROUND
         SRL   R6,12          DIVIDE BY 4096
         STH   R6,QCJQTL      NUMBER OF BLOCKS FOR JQES
***********************************************************************
*                                                                     *
*   COMPUTE NUMBER OF JOT BLOCKS IN CKPT                              *
*                                                                     *
***********************************************************************
         LH    R3,$NUMJOES    NUMBER OF JOES
         LA    R3,NJOTPRFX(,R3) ADJUSTED LENGTH OF JOT PREFIX
         MH    R3,=AL2(JOESIZE) MULTIPLY BY LENGTH OF JOE
         LA    R3,4095(R3) PREPARE TO ROUND
         SRL   R3,12          DIVIDE BY 4096
         STH   R3,QCJOTL      NUMBER OF BLOCKS FOR JOT
***********************************************************************
*                                                                     *
*   LOAD NODE MEMBER SYSTEM IDENTIFIERS             GP@P6 2002-06-02  *
*                                                                     *
***********************************************************************
         LH    R0,$QSENO      GET NUMBER OF MEMBERS IN NODE
         LA    R4,$SAVEEND    POINT TO FIRST QSE
         USING QSEDSECT,R4
SIDQSELP SLR   R1,R1          CLEAR FOR INSERT
         IC    R1,QSESIBSY    GET SYSTEM NUMBER
         SLA   R1,3           MULTIPLY BY 8 FOR INDEX
         LA    R1,QSYSID(R1)  POINT TO QCOMMON SYSTEM ID ENTRY
         MVC   0(4,R1),QSESID SET SYSTEM IDENTIFIER
         LA    R4,QSELEN(,R4) POINT TO NEXT QSE
         BCT   R0,SIDQSELP
         DROP  R4             QSEDSECT
***********************************************************************
*                                                                     *
*   COMPUTE TOTAL LENGTH OF QSES                                      *
*                                                                     *
***********************************************************************
         LA    R4,QSELEN      QSE LENGTH
         MH    R4,$QSENO      MULTIPLY LENGTH TIMES NUMBER OF QSES
         AIF   (NOT &QSP).QSP5                                    UF020
         ALR   R4,R5          ADD ONE BYTE FOR EACH JIX BLOCK     UF020
******************************************************************UF020
*                                                                 UF020
*   COMPUTE NUMBER OF MSQ BLOCKS ON CKPT                          UF020
*                                                                 UF020
******************************************************************UF020
         LH    R1,$NUMRJE     NUMBER OF REMOTES                   UF020
         MH    R1,=Y(3)       TIMES LENGTH OF 3                   UF020
         LA    R1,3(,R1)       PLUS HEADER LENGTH                 UF020
         LA    R1,4095(R1)    PREPARE TO ROUND                    UF020
         SRL   R1,12          DIVIDE BY 4096                      UF020
         ALR   R4,R1          ADD 1 BYTE FOR EACH BLOCK           UF020
******************************************************************UF020
*                                                                 UF020
*   COMPUTE NUMBER OF RSO BLOCKS ON CKPT                          UF020
*                                                                 UF020
******************************************************************UF020
         LH    R1,$NUMRJE     NUMBER OF REMOTES                   UF020
         LA    R1,4095(R1)    PREPARE TO ROUND                    UF020
         SRL   R1,12          DIVIDE BY 4096                      UF020
         ALR   R4,R1          ADD 1 BYTE FOR EACH BLOCK           UF020
******************************************************************UF020
*                                                                 UF020
*   COMPUTE NUMBER OF LCK BLOCKS ON CKPT                          UF020
*                                                                 UF020
******************************************************************UF020
*        LH    R1,$NUMLCK     NUMBER OF LOAD CKPT ELEMENTS        UF020
         LA    R1,9*7         NUMBER OF LOAD CKPT ELEMENTS        UF020
         MH    R1,=Y(LCKSIZE) TIMES LENGTH OF EACH                UF020
         LA    R1,4095(R1)    PREPARE TO ROUND                    UF020
         SRL   R1,12          DIVIDE BY 4096                      UF020
         ALR   R4,R1          ADD 1 BYTE FOR EACH BLOCK           UF020
.QSP5    ANOP                                                     UF020
         ALR   R4,R6          ADD ONE BYTE FOR EACH JQE BLOCK
         ALR   R4,R3          ADD ONE BYTE FOR EACH JOT BLOCK
***********************************************************************
*                                                                     *
*   COMPUTE HASPACE BUFFER SIZE                                       *
*                                                                     *
***********************************************************************
         LH    R5,$BUFSIZE    BLKSIZE FOR HASPACE
         STH   R5,HASPACE+62  STORE IN DCB
         STH   R5,HDECB2+6    STORE IN DECB
         LA    R5,63(R5)      PREPARE TO ROUND
         N     R5,=F'-64'     ROUND TO 64 BYTE BOUNDARY
***********************************************************************
*                                                                     *
*   OBTAIN BUFFERS FOR HASPCKPT AND HASPACE                           *
*                                                                     *
***********************************************************************
         LR    R14,R5         HASPACE BUFFER SIZE
         MH    R14,=H'3'      3 BUFFERS
         LA    R1,1(R6,R3)    NUMBER OF BLOCKS IN CKPT DS
         AIF   (NOT &QSP).QSP6                                    UF020
         AH    R1,QCJIXL      ADD NUMBER OF JIX BLOCKS            UF020
.QSP6    ANOP                                                     UF020
         ST    R1,QCJOTL      STORE RECORD COUNT
         SLL   R1,12          MULTIPLY BY 4096
         LA    R0,256(R1,R14) ADD CKPT BUFFERS, HASPACE BUFFERS, SLOP
         ST    R0,QGETL2      SAVE LENGTH OF GETMAIN AREA
         GETMAIN R,LV=(0)     OBTAIN BUFFERS
         ST    R1,QGETA2      SAVE ADDRESS OF GETMAIN AREA
         ST    R1,QCJQTL      BUFFER FOR FIRST CKPT REC
         AH    R1,=H'4096'    INCREMENT
         AIF   (NOT &QSP).QSP7                                    UF020
         ST    R1,QCJIXA      BUFFER FOR JIX BLOCKS               UF020
         LH    R15,QCJIXL     NUMBER OF JIX BLOCKS                UF020
         SLL   R15,12         TIMES 4096                          UF020
         AR    R1,R15         INCREMENT                           UF020
.QSP7    ANOP                                                     UF020
         ST    R1,QCJQTA      BUFFER FOR JQE BLOCKS
         SLL   R6,12          MULTIPLY BY 4096
         AR    R1,R6          INCREMENT
         ST    R1,QCJOTA      BUFFER FOR JOE BLOCKS
         SLL   R3,12          MULTIPLY BY 4096
         AR    R1,R3          INCREMENT
         ST    R1,QCJCTA      BUFFER FOR JCT
         AR    R1,R5          INCREMENT
         ST    R1,QCIOTA      BUFFER FOR IOT
         AR    R1,R5          INCREMENT
         ST    R1,QCBLKA      BUFFER FOR DATA BLOCKS
         AIF   (NOT &QSP).QSP8                                    UF020
         LA    R1,$JQHEADS+$JQHEADL-$SAVEBEG OFFSET 1ST JQE HEAD  UF020
         AGO   .QSP9                                              UF020
.QSP8    ANOP                                                     UF020
         LA    R1,$JQHEADS+2-$SAVEBEG OFFSET TO FIRST JQE HEADER
.QSP9    ANOP                                                     UF020
         A     R1,QCJQTL      BASE OF FIRST CKPT REC
         ST    R1,QCJQHEAD    ADDR OF FIRST JQE HEADER
***********************************************************************
*                                                                     *
*   ALLOCATE AND OPEN HASPACE                                         *
*                                                                     *
***********************************************************************
         LA    R3,$SAVEEND(R4) ADDR OF DA CKPT INFO
.EXIT    ANOP
         MVC   DA08DDN,=CL8'HASPACE' DDNAME FOR ALLOCATE
         MVC   DA08PDSN,=A(DSNSPACE) DSNAME FOR ALLOCATE
         LA    R4,9           MAX POSSIBLE SPOOLS FOR QUEUE       UF020
         AIF   (&QSP).QSP10                                       UF020
         IC    R4,$NUMDA      MAXIMUM NUMBER OF SPOOL VOLUMES
.QSP10   ANOP                                                     UF020
         LA    R7,QCDCBL      LENGTH OF HASPACE DCB
         MR    R6,R4          COMPUTE LENGTH OF DCB POOL
         GETMAIN R,LV=(R7)    OBTAIN DCB POOL
         ST    R7,QGETL3      SAVE LENGTH OF GETMAIN
         ST    R1,QGETA3      SAVE ADDRESS OF GETMAIN
         LR    R7,R1          SAVE ADDR OF DCB POOL
         LA    R8,QCSPOOLS-4  ADDR OF OPEN LIST
         SR    R6,R6          ACTUAL NUMBER OF SPOOL VOLUMES
         MVC   DA08SER(5),$SPOOL PATTERN FOR VOLSER
SPOOL1   LA    R5,DEVTAB      ADDR OF DEVICE CHARACTERISTICS TBL
         CLI   0(R3),0        IS THIS VOLUME UNUSED?
         BE    SPOOL4         YES. TRY NEXT.
SPOOL2   CLI   0(R5),X'FF'    IS THIS THE END OF TABLE?
         BE    ABORT          YES. UNSUPPORTED DEVICE TYPE.
         CLC   0(1,R5),0(R3)  IS THIS A MATCH?
         BE    SPOOL3         YES. GO WITH IT.
         LA    R5,12(R5)      NEXT TABLE ENTRY
         B     SPOOL2         TRY NEXT ENTRY
SPOOL3   MVC   150(2,R8),2(R5) MOVE TRK/CYL TO TRK/CYL LIST
         MVC   DA08UNIT,4(R5) MOVE UNIT NAME
         MVC   DA08SER+5(1),1(R3) LAST DIGIT OF VOLSER
         LA    R6,1(R6)       INCREASE COUNT BY ONE
         STC   R6,DA08DDN+7   UPDATE DDNAME
         OI    DA08DDN+7,X'F0' MAKE IT A VALID NUMBER
         AIF   (&QSP).QSP11                                       GP@P6
         MVC   DA08DDN+7(1),1(R3) LAST DIGIT OF VOLSER            GP@P6
.QSP11   ANOP                                                     GP@P6
         L     R15,=V(ALLOCATE) ADDR OF ALLOCATE MODULE
         BALR  R14,R15        GO TO IT
         MVC   0(QCDCBL,R7),HASPACE MOVE PATTERN DCB TO POOL
         MVC   47(1,R7),DA08DDN+7 UPDATE THE DDNAME
         ST    R7,4(R8)       STORE DCB ADDR IN OPEN LIST
         LA    R7,QCDCBL(R7)  INCREMENT TO NEXT DCB
         LA    R8,4(R8)       NEXT ENTRY IN OPEN LIST
SPOOL4   LA    R3,6(R3)       NEXT VOLUME
         BCT   R4,SPOOL1      BRANCH IF MORE VOLUMES.
         OI    0(R8),X'80'    INDICATE END OF OPEN LIST
         OPEN  MF=(E,QCSPOOLS) OPEN HASPACE
         AIF   (NOT &QRACF).RNB03D                                RNB03
         CLI   QUSRSAV,0           DID WE CHANGE ACEEUSER?        RNB03
         BE    RNB03C              /NO  - SKIP THIS CODE          RNB03
*                                  /YES - PUT USERID BACK         RNB03
         L     R2,CVTPTR             CVT                          RNB03
         USING CVT,R2                #####                        RNB03
         L     R2,CVTTCBP            TCB WORDS                    RNB03
         L     R2,12(,R2)            CURRENT ASCB                 RNB03
         USING ASCB,R2               #####                        RNB03
         L     R2,ASCBASXB           ASXB                         RNB03
         USING ASXB,R2               #####                        RNB03
         ICM   R2,15,ASXBSENV        ACEE                         RNB03
         USING ACEE,R2               #####                        RNB03
         MODESET KEY=ZERO            GET KEY ZERO TO UPDATE ACEE  RNB03
         MVC   ACEEUSER,QUSRSAV      SET OLD USERID               RNB03
         MODESET KEY=NZERO           BACK TO USER KEY             RNB03
         STAX  DEFER=NO              ALLOW ATTENTION INTERRUPTS   RNB03
RNB03C   EQU   *                                                  RNB03
.RNB03D  ANOP                                                     RNB03
***********************************************************************
*                                                                     *
*   GO HOME                                                           *
*                                                                     *
***********************************************************************
         QSTOP
***********************************************************************
*                                                                     *
*   PROCESS REQUEST FOR DIFFERENT UNIT AND VOL ON SYS1.HASPCKPT       *
*                                                                     *
***********************************************************************
*
*** FORMAT - QUEUE CKPT(UNIT,VOLSER)
*
CKPT     MVC   DA08UNIT(16),QBLANK BLANK THE UNIT AND VOLSER FIELDS
         LA    R5,DA08UNIT    START OF UNIT FIELD
         LA    R6,DA08SER     START OF VOLSER FIELD
         SH    R3,=H'4'       SUBTRACT OVERHEAD FROM LENGTH
CKPT1    CLI   5(R1),C','     IS THIS THE END OF UNIT FIELD?
         BE    CKPT2          YES. PROCESS VOLSER NEXT.
         MVC   0(1,R5),5(R1)  MOVE ONE BYTE OF UNIT NAME
         LA    R5,1(R5)       ADD 1 TO RECEIVING ADDR
         LA    R1,1(R1)       ADD 1 TO SENDING ADDR
         BCT   R3,CKPT1       BRANCH IF NOT EXHAUSTED.
         B     ABORT2         INVALID PARAMETERS.
CKPT2    CLI   6(R1),C')'     IS THIS THE END OF VOLSER FIELD?
         BE    CKPT3          YES. CONTINUE PROCESSING.
         MVC   0(1,R6),6(R1)  MOVE ONE BYTE TO VOLSER
         LA    R6,1(R6)       ADD ONE TO RECEIVING ADDR
         LA    R1,1(R1)       ADD ONE TO SENDING ADDR
         BCT   R3,CKPT2       BRANCH IF NOT EXHAUSTED.
         B     ABORT2         INVALID PARAMETER.
CKPT3    CLI   DA08UNIT,C' '  IS THERE A UNIT?
         BE    ABORT2         NO. INVALID.
         CLI   DA08SER,C' '   IS THERE A VOLSER?
         BE    ABORT2         NO. INVALID.
         CLI   DA08BLK,0      DID WE GO TOO FAR?
         BE    SKIP           NO. EVERTHING LOOKS GOOD.
ABORT2   LA    R1,MESSAGE2    POINT TO THE MESSAGE                GP@P6
         LA    R0,L'MESSAGE2  SET MESSAGE LENGTH                  GP@P6
         TPUT  (1),(0),R      TELL THE USER                       GP@P6
         ABEND 97,DUMP        QUIT
***********************************************************************
*                                                                     *
*   UNSUPPORTED DEVICE TYPE. ABORT.                                   *
*                                                                     *
***********************************************************************
ABORT    LA    R1,MESSAGE     POINT TO THE MESSAGE                GP@P6
         LA    R0,L'MESSAGE   SET MESSAGE LENGTH                  GP@P6
         TPUT  (1),(0),R      TELL THE USER                       GP@P6
         ABEND 98,DUMP        QUIT
***********************************************************************
*                                                                     *
*   MISCELLANY                                                        *
*                                                                     *
***********************************************************************
         LTORG
OCBUF    OC    0(1,R1),QBLANK TRANSLATE COMMAND TO UPPER CASE
MVCBUF   MVC   QDREPLY(1),0(R1) MOVE DATA TO REPLY
DEVTAB   DC    X'0900',H'19',CL8'3330' DEVTYPE,TRK/CYL,DEVNAME
         DC    X'0B00',H'30',CL8'3350'
         DC    X'0D00',H'19',CL8'3330-1'
         DC    X'0E00',H'15',CL8'3380  '
         DC    X'0F00',H'15',CL8'3390  '
         DC    X'FFFF'
         DS    0F
TIR3     DC    X'00000300'    POINT PAST SYNC RECORDS
DSNCKPT  DC    H'13',CL44'SYS1.HASPCKPT'
DSNSPACE DC    H'12',CL44'SYS1.HASPACE'
MESSAGE  DC    C'UNSUPPORTED DEVICE TYPE SPECIFIED FOR SPOOL'
MESSAGE2 DC    C'INVALID PARAMETER SPECIFIED - CKPT(UNIT,VOLSER)'
SYMDEL   DSECT ,                   KILL SYM CARD GENERATION       UF023
INIT     CSECT ,                                                  UF023
         GBLC  &VERSION
&VERSION SETC  '0'
         AIF   (NOT &QSP).QSP99A                                  UF020
$MAXNODE EQU   1000           FOR SP2 $JOT DSECT                  UF020
         AGO   .QSP99B                                            UF020
.QSP99A  ANOP                                                     UF020
$MAXNODE EQU   99             FOR NJE $JOT DSECT                  UF001
.QSP99B  ANOP                                                     UF020
SAVE     EQU   13             NEEDED FOR NJE $PCE                 UF001
         $PCE  ,              NEEDED FOR NJE $HCT                 UF001
         $JOE
         $JOT
NJOTPRFX EQU   (JOTJOES-JOTDSECT)/JOESIZE
BASE1    EQU   0
$RPS     EQU   0
$MSGID   EQU   0
$DUPVOLT EQU   0
$PRIOOPT EQU   0
$PRTBOPT EQU   0
$PRTRANS EQU   0
$QSONDA  EQU   0
         AIF   (NOT &QSP).QSP99                                   UF020
*        EQUATES REQUIRED FOR $HCT EXPANSION                      UF020
FF       EQU   X'FF'                                              UF020
$CMBDEF  EQU   15                                                 UF020
$JQEDEF  EQU   100                                                UF020
$MAXDA   EQU   32                                                 UF020
$MAXJBNO EQU   9999                                               UF020
$SMFDEF  EQU   5                                                  UF020
$TGDEF   EQU   3072                                               UF020
*JCT      EQU   10                                         VBA01  UF020
         $LCK  ,                                                  UF020
.QSP99   ANOP                                                     UF020
JCT      EQU    10                                         VBA01
         $PSA   ,                                                 GP@P6
         $CVT   ,                                                 GP@P6
         $JESCT ,                                                 GP@P6
         $SSCT  ,                                                 GP@P6
         $SVT   ,                                                 GP@P6
         $TCB   ,                                                 GP@P6
         $JSCB  ,                                                 GP@P6
         $BUFFER                                                  UF020
         $JCT  ,                                                  UF020
         $CAT  ,                                                  UF020
         $TAB
         $QSE
         $PDDB                                                    UF021
         $IOT
         $TGM
         $JQE
         $HCT
         IKJCPPL
         IKJPSCB                                                  UF010
         AIF   (NOT &QRACF).RNB03E                                RNB03
         PUSH  PRINT                                              RNB03
         PRINT NOGEN                                              RNB03
         CVT   DSECT=YES                                          RNB03
         IHAASCB ,                                                RNB03
         IHAASXB ,                                                RNB03
         IHAACEE ,                                                RNB03
         POP   PRINT                                              RNB03
.RNB03E  ANOP                                                     RNB03
         QCOMMON
SYMNODEL DSECT ,                   RESTORE SYM CARD GENERATION    UF023
         END
./ ADD NAME=INITS    8009-02166-02188-2043-00152-00140-00000-GREG
INITS    QSTART 'QUEUE COMMAND - LIST INITIATORS COMMAND'
         GBLB  &QPFK          PF-KEY OPTION. DEFINED BY QSTART    GP@P6
         USING QDISPLAY,R9    BASE REG FOR DISPLAY AREA           GP@P6
         L     R9,QVDSPL      LOAD BASE REG                       GP@P6
         USING WORK,R13       BASE REG FOR LOCAL WORK AREA
******************************************************************UF006
*                                                                 UF006
*   CALL - READ JES2 CHECKPOINT ROUTINE                           UF006
*                                                                 UF006
******************************************************************UF006
CALLCKPT L     R15,=V(CKPT)   ADDR OF CKPT ROUTINE                UF006
         BALR  R14,R15        GO TO IT                            UF006
         L     R8,16          POINT TO CVT
         USING CVTDSECT,R8
***********************************************************************
*                                                                     *
*        FIND THE ACTIVE MAIN SUBSYSTEM SSVT                          *
*                                                                     *
***********************************************************************
         L     R8,CVTJESCT    POINT TO JESCT
         DROP  R8
         USING JESCT,R8
         L     R8,JESSSCT     POINT TO SSCT
         DROP  R8
         USING SSCT,R8
         L     R8,SSCTSSVT    POINT TO SSVT
         DROP  R8
         USING SSVT,R8
***********************************************************************
*                                                                     *
*        FIND THE ACTIVE MAIN SUBSYSTEM'S PITS                        *
*                                                                     *
***********************************************************************
         L     R7,$SVPIT      POINT TO PITTABLE
         LTR   R6,R7          TEST IF ANY PITS
         BZ    NOPITS         NO, IGNORE COMMAND
         BCTR  R6,0           SUBTRACT ONE
         BCTR  R6,0           SUBTRACT ONE
         SR    R0,R0          ZERO FOR INSERT
         IC    R0,0(,R6)      INSERT NUMBER OF CLASSES
         LR    R6,R0          COPY THE COUNT
         IC    R6,$SVMAXCL    NUMBER OF CLASSES AFTER OZ35996     UF027
         USING PITDSECT,R7
         QHEAD INITHD,X'24',TYP=QDXI  HEADING IN GREEN REVERSE    GP@P6
***********************************************************************
*                                                                     *
*        BUILD THE MESSAGE(S) DESCRIBING THE PITS                     *
*                                                                     *
***********************************************************************
BLDMSG   MVC   QDMSG,QBLANK   BLANK THE AREA
         MVC   INIT#(2),PITPATID MOVE IN PIT ID
         LR    R1,R6          COPY THE LENGTH
         BCTR  R1,0           SUBTRACT ONE
         EX    R1,MVCLAS      MOVE THE CLASSES
         MVI   QDLNCODE,X'01' BLUE FOR NOT ACCEPTING WORK         GP@P6
         TM    PITSTAT,PITHOLDA+PITHOLD1 TEST FOR DRAINED
         BNZ   HOLDPIT        YES
         TM    PITSTAT,PITHALTA+PITHALT1 TEST FOR HALTED
         BNZ   HALTPIT        YES
         MVC   STATUS,=CL8' ACTIVE '
         TM    PITSTAT,PITBUSY TEST FOR BUSY
         BO    ACTPIT         YES
         MVI   QDLNCODE,X'05' TURQUOISE FOR READY FOR WORK        GP@P6
         MVC   STATUS,=CL8'INACTIVE'
         B     NEXTPIT        END OF MESSAGE LINE.
MVCLAS   MVC   CLASSES(0),PITCLASS SET THE CLASSES
HOLDPIT  MVC   STATUS,=CL8'DRAINED' SET STATUS
         TM    PITSTAT,PITBUSY TEST FOR BUSY
         BZ    NEXTPIT        NO
         MVC   STATUS+5(3),=C'ING' SET STATUS
         B     ACTPIT         YES
HALTPIT  MVC   STATUS,=CL8' HALTED ' SET STATUS
         TM    PITSTAT,PITBUSY TEST FOR BUSY
         BZ    NEXTPIT        NO
         MVC   STATUS+5(3),=C'ING' SET STATUS
ACTPIT   MVI   QDLNCODE,X'06' YELLOW FOR RUNNING WORK             GP@P6
         L     R5,PITSJB      POINT TO THE SJB
         USING SJBDSECT,R5
         L     R1,SJBJQOFF    POINT TO JOB QUEUE OFFSET
         A     R1,QCJQTA      POINT TO THE JQE
         USING JQEDSECT,R1
         CLC   JQEJNAME,SJBJOBNM TEST FOR RIGHT JOB
         BNE   NEXTPIT        RIGHT JOB, GOOD
         MVC   JOBNAME,SJBJOBNM MOVE IN JOBNAME
         LH    R0,JQEJOBNO    LOAD JOB NUMBER
         CVD   R0,CONVERT     GET THE DECIMAL VALUE
         MVC   JOBNUM,ED5     GET THE CHARACTER VALUE
         ED    JOBNUM,CONVERT+5 GET THE CHARACTER VALUE
***********************************************************************
*                                                                     *
*        SEND THE MESSAGE DESCRIBING THE PIT                          *
*                                                                     *
***********************************************************************
NEXTPIT  L     R7,PITNEXT     POINT TO NEXT PIT
         DROP  R1,R5
         AIF   (NOT &QPFK).XINOSEL                                GP@P6
         TM    QFLAG1,QFLG1OPR+QFLG1APF                           GP@P6
         BNO   XISELNOK       NOT OPER PRIV IN APF ENVIRONMENT    GP@P6
         MVI   QDMSG,X'0B'    INPUT HIGH INTENSITY                GP@P6
         MVI   QDMSG+1,C'.'   SUPPLY SELECTION FIELD DOT          GP@P6
         MVI   QDMSG+2,X'0C'  OUTPUT LOW INTENSITY                GP@P6
XISELNOK DS    0H                                                 GP@P6
.XINOSEL ANOP                                                     GP@P6
         MVC   QDMLNG,=H'80'  SET THE LENGTH
         LA    R0,QDMSG       GET THE ADDRESS
         ST    R0,QDMSGA      SET THE ADDRESS
         L     R15,=V(DISPLAY) POINT TO THE ROUTINE
         BALR  R14,R15        CALL THE ROUTINE
         LTR   R7,R7          TEST FOR NEXT PIT
         BNZ   BLDMSG         YES, GO DO IT
***********************************************************************
*                                                                     *
*        END IT ALL                                                   *
*                                                                     *
***********************************************************************
END      QSTOP
NOPITS   QTILT '***** NO PITS  TO DISPLAY *****'
INITHD   DC    CL80'    INIT    STATUS   JOBNAME    NUMBER    CLASSES'
ED5      DC    X'402020202120'
         LTORG
***********************************************************************
*                                                                     *
*        DESCRIBE ALL THE DSECTS NEEDED BY THIS MODULE                *
*                                                                     *
***********************************************************************
SYMDEL   DSECT ,                   KILL SYM CARD GENERATION       UF023
INITS    CSECT ,                                                  UF023
         $CVT
         $JESCT
         $SSCT
         $SVT
         $PIT
         $DEB                                                     UF021
         $SJB
         $JQE
         QCOMMON
         ORG   QDMSG
         DS    CL5
INIT#    DS    CL2
         DS    CL4
STATUS   DS    CL8
         DS    CL2
JOBNAME  DS    CL8
         DS    CL3
JOBNUM   DS    CL6
         DS    CL4
CLASSES  DS    C
WORK     DSECT
         DS    CL72
CONVERT  DS    D
SYMNODEL DSECT ,                   RESTORE SYM CARD GENERATION    UF023
         END
./ ADD NAME=JCL      8002-02215-02308-2134-00023-00024-00000-GREG
JCL      QSTART 'QUEUE COMMAND - LIST THE JCL FOR A JOB'
***********************************************************************
*                                                                     *
*   CALL FINDJOB TO LOCATE THE JQE, JCT, AND IOT                      *
*                                                                     *
***********************************************************************
         L     R15,=V(FINDJOB) ADDR OF MODULE TO FIND JOB
         BALR  R14,R15        GO TO IT
***********************************************************************
*                                                                     *
*   CALL LISTDS TO LIST THE DATASET                                   *
*                                                                     *
***********************************************************************
         MVC   QPOFFSET,=H'10' PRINT OFFSET FOR EACH RECORD
         MVC   QPDSID,=H'3'   DSID OF DATASET TO BE PRINTED
         L     R15,=V(LISTDS) ADDR OF LISTDS MODULE
         BALR  R14,R15        GO TO IT
         QSTOP
         LTORG
SYMDEL   DSECT ,                   KILL SYM CARD GENERATION       UF023
         QCOMMON
SYMNODEL DSECT ,                   RESTORE SYM CARD GENERATION    UF023
         END
./ ADD NAME=JLOG     8005-02212-07001-1441-00090-00081-00000-GREG
JLOG     QSTART 'QUEUE COMMAND - LIST THE JOBLOG MESSAGES FOR A JOB'
         GBLB  &QRNB                                              RNB04
         LCLB  &SAVB                                              GP@P6
         USING QCKPT,R10      BASE REG FOR CKPT WORK AREA
         L     R10,QVCKPT     LOAD BASE REG
***********************************************************************
*                                                                     *
*   CALL FINDJOB TO LOCATE THE JQE, JCT, AND IOT                      *
*                                                                     *
***********************************************************************
         L     R15,=V(FINDJOB) ADDR OF MODULE TO FIND JOB
         BALR  R14,R15        GO TO IT
***********************************************************************
*                                                                     *
*   DETERMINE IF JOB LOG IS AVAILABLE                                 *
*                                                                     *
***********************************************************************
         USING PDBDSECT,R2    BASE REG FOR PDDB
         USING IOTSTART,R3    BASE REG FOR IOT
         L     R3,QCIOTA      LOAD BASE REG
NEXTIOT  LR    R4,R3          BASE OF IOT
         A     R4,IOTPDDBP    OFFSET BEYOND LAST PDDB
         LR    R2,R3          BASE OF IOT
         A     R2,QCPDDB1     OFFSET TO FIRST PDDB IN JOT
FINDDS   CLC   PDBDSKEY,=H'2' IS THIS THE JOB LOG
         BE    FOUNDDS        YES. CONTINUE.
         LA    R2,PDBLENG(R2) NO. LOOK AT NEXT PDDB
         CR    R2,R4          HAVE WE GONE PAST THE LAST PDDB
         BL    FINDDS         NO. TRY AGAIN
         B     TILT
&SAVB    SETB  (&QRNB EQ 1)                                       GP@P6
&QRNB    SETB  1                                                  GP@P6
         AIF   (&QRNB).RNB04A                                     RNB04
FOUNDDS  CLC   PDBRECCT,=F'1' IS JOB LOG EMPTY
         BE    TILT           YES, SAY SO
         AGO   .RNB04B                                            RNB04
.RNB04A  ANOP                                                     RNB04
***********************************************************************
* RNB CHANGES:                                                        *
*          (1) RNB04 - ALLOW JOBLOG FOR JOBS THAT HAVE BEGUN EXECUTING*
*                      BUT HAVEN'T FINISHED FIRST STEP YET. WILL ONLY *
*                      SHOW JOB-STARTED MESSAGE.                      *
***********************************************************************
FOUNDDS  L     R3,QCJCTA      GET THE JCT                         RNB04
         USING JCTSTART,R3    #####                               RNB04
**       OC    JCTXEQON,JCTXEQON  JOB EXECUTING OR EXECUTED?      RNB04
**       BZ    TILT2              /NO  - REALLY EMPTY             RNB04
*                                 /YES - OK TO LIST IT            RNB04
* TIME AT MIDNIGHT IS ZERO SO THIS TEST IS NOT RIGOUROUS.         GP@P6
* FURTHER, JOBS THAT FAILED BEFORE EXECUTION AND ARE NOW ON AN    GP@P6
* OUTPUT QUEUE WILL STILL HAVE ZERO EXECUTION TIMESTAMPS.         GP@P6
* SOLUTION: CHECK THE DATE FIELDS INSTEAD OF THE TIME FIELDS.     GP@P6
         ICM   R0,15,JCTODTON STARTED ON OUTPUT PROCESSOR?        GP@P6
         BNZ   SHOWJLOG       YES, JOB LOG CAN BE VIEWED          GP@P6
         ICM   R0,15,JCTXDTON STARTED EXECUTION?                  GP@P6
         BZ    TILT2          NO, BLOCK CANCELLED MESSAGE VIEWING GP@P6
SHOWJLOG EQU   *                                                  GP@P6
         DROP  R3                                                 RNB04
.RNB04B  ANOP                                                     RNB04
***********************************************************************
*                                                                     *
*   CALL LISTDS TO LIST THE DATASET                                   *
*                                                                     *
***********************************************************************
         MVC   QPOFFSET,=H'0' PRINT OFFSET FOR EACH RECORD
         MVC   QPDSID,=H'2'   DSID OF DATASET TO BE PRINTED
         L     R15,=V(LISTDS) ADDR OF LISTDS MODULE
         BALR  R14,R15        GO TO IT
         QSTOP
         AIF   (&QRNB).RNB04C                                     RNB04
TILT     QTILT '*** JOBLOG IS NOT AVAILABLE ***'
         AGO   .RNB04D                                            RNB04
.RNB04C  ANOP                                                     RNB04
TILT     QTILT '*** JOBLOG NOT FOUND ***'                         RNB04
TILT2    QTILT '*** JOBLOG NOT AVAILABLE - JOB HAS NOT EXECUTED ***' 04
.RNB04D  ANOP                                                     RNB04
&QRNB    SETB  (&SAVB EQ 1)                                       GP@P6
         LTORG
SYMDEL   DSECT ,                   KILL SYM CARD GENERATION       UF023
JLOG     CSECT ,                                                  UF023
JCT      EQU   0
         $BUFFER                                                  UF020
         $JQE
         $TAB
         $JCT
         $PDDB
         $IOT
         QCOMMON
SYMNODEL DSECT ,                   RESTORE SYM CARD GENERATION    UF023
         END
./ ADD NAME=JMSG     8002-02215-02308-2134-00023-00024-00000-GREG
JMSG     QSTART 'QUEUE COMMAND - LIST THE SYSTEM MESSAGES FOR A JOB'
***********************************************************************
*                                                                     *
*   CALL FINDJOB TO LOCATE THE JQE, JCT, AND IOT                      *
*                                                                     *
***********************************************************************
         L     R15,=V(FINDJOB) ADDR OF MODULE TO FIND JOB
         BALR  R14,R15        GO TO IT
***********************************************************************
*                                                                     *
*   CALL LISTDS TO LIST THE DATASET                                   *
*                                                                     *
***********************************************************************
         MVC   QPOFFSET,=H'0' PRINT OFFSET FOR EACH RECORD
         MVC   QPDSID,=H'4'   DSID OF DATASET TO BE PRINTED
         L     R15,=V(LISTDS) ADDR OF LISTDS MODULE
         BALR  R14,R15        GO TO IT
         QSTOP
         LTORG
SYMDEL   DSECT ,                   KILL SYM CARD GENERATION       UF023
         QCOMMON
SYMNODEL DSECT ,                   RESTORE SYM CARD GENERATION    UF023
         END
./ ADD NAME=LIST     8001-02202-02202-2339-00132-00132-00000-GREG
LIST     QSTART 'QUEUE COMMAND - PRINT A DATASET FROM SPOOL BY ID'
         GBLB  &QACF2         IS ACF2 AUTH CHECKING TO BE DONE     FCI*
         GBLB  &QRNB                                              RNB05
         USING QCKPT,R10      BASE REG FOR CKPT WORK AREA
         L     R10,QVCKPT     LOAD BASE REG
         USING WORK,R13       BASE REG FOR TEMP WORK
***********************************************************************
*                                                                     *
*   CALL FINDJOB TO LOCATE THE JQE, JCT, AND IOT                      *
*                                                                     *
***********************************************************************
         L     R15,=V(FINDJOB) ADDR OF MODULE TO FIND JOB
         BALR  R14,R15        GO TO IT
***********************************************************************
*                                                                     *
*   ENSURE JOBNAME BEGINS WITH USER ID                                *
*                                                                     *
***********************************************************************
         AIF   (&QRNB).RNB05A                                     RNB05
         SPACE 1                                                  UF005
         TM    QXAUTH,1       IS USER AUTHORIZED?                 UF005
         BO    OKJOB          YES, ALLOW TO PROCEED               UF005
         SPACE 1                                                  UF005
.RNB05A  ANOP                                                     RNB05
         L     R9,QCJCTA      ADDR OF JCT
         USING JCTSTART,R9    BASE REG FOR JCT
         LA    R2,7           MAXIMUM LENGTH OF USER ID
         LA    R3,QLOGON+7    LAST BYTE OF USER ID
LOOP     CLI   0(R3),C' '     IS THIS BYTE BLANK?
         BNE   CHECK          NO. CONTINUE.
         BCTR  R3,0           TRY PREVIOUS BYTE
         BCT   R2,LOOP        TRY AGAIN
CHECK    EX    R2,CLC         IS THE JOBNAME VALID?
         AIF   (&QRNB).RNB05B                                     RNB05
         AIF   (&QACF2).ACF1                                       FCI*
         BE    OKJOB          YES, ALLOW TO PROCEED               GP@P6
         CLI   QLOGON+7,C' '  "USERID" VALID?                     GP@P6
         BNE   TILT2          NO. TILT.                            FCI*
         CLC   JCTTSUID,QLOGON    NOTIFY TO THIS USER?            GP@P6
         AGO   .ACF2                                               FCI*
.ACF1    ANOP  ,                                                   FCI*
         NOP   TILT2          ACF2 HAS ALREADY CHECKED AUTHORITY   FCI*
.ACF2    ANOP  ,                                                   FCI*
*        BNE   TILT2          NO. TILT.
         AGO   .RNB05C                                            RNB05
.RNB05B  ANOP                                                     RNB05
         BE    OKJOB          /YES - GO CHECK DSID                RNB05
         CLC   =C'PJS',QLOGON IS THIS A PJS USER?                 RNB05
         BE    TILT2          INVALID JOB IF SO                   RNB05
         CLC   QLOGON(*-*),JCTTSUID  DOES THE USERID              RNB05
         EX    R2,*-6                MATCH THE NOTIFY ID?         RNB05
         BE    OKJOB                 GOOD JOB IF SO               RNB05
         CLC   =C'TEC',QLOGON        IS THIS A TEC USERID?        RNB05
         BNE   TILT2                 INVALID JOB IF NOT           RNB05
         CLC   =C'TEC',JCTJNAME      FOR A TEC USER, ALLOW LIST   RNB05
         BE    OKJOB                 FOR ANY TEC JOB OR ANY JOB   RNB05
         CLC   =C'TEC',JCTTSUID      WITH A TEC NOTIFY            RNB05
         BE    OKJOB                                              RNB05
         TM    JCTJOBFL,JCTSTCJB     ALSO ALLOW IF AN STC         RNB05
         BZ    TILT2                                              RNB05
.RNB05C  ANOP                                                     RNB05
OKJOB    DS    0H                                                 UF005
***********************************************************************
*                                                                     *
*   CHECK AND CONVERT THE DATASET ID NUMBER                           *
*                                                                     *
***********************************************************************
         LH    R2,QLNG2       LENGTH OF DATASET ID FIELD
         SH    R2,=H'1'       IS THE DATASET ID FIELD ZERO LENGTH?
         BM    TILT           YES. QUIT.
         MVC   QFZONES,QFZONE INITIALIZE NUMERIC TEST
         EX    R2,MVZ         MOVE THE ZONES FOR VALIDITY CHECK
         CLC   QFZONES,QFZONE IS THE FIELD NUMERIC?
         BNE   TILT           NO. QUIT.
         EX    R2,PACK        PACK THE FIELD
         CVB   R2,CONVERT     CONVERT TO BINARY
         SPACE 1                                                  UF005
         TM    QXAUTH,1       IS USER AUTHORIZED?                 UF005
         BO    *+4+8          YES, ALLOW ANY DSID                 UF005
         SPACE 1                                                  UF005
         CH    R2,=H'101'     IS THE DATASET ID LESS THAN 101?
         BL    TILT           YES. TILT.
         STH   R2,QPDSID      STORE DATASET ID
***********************************************************************
*                                                                     *
*   CHECK AND CONVERT THE PRINT OFFSET                                *
*                                                                     *
***********************************************************************
         MVC   QPOFFSET,=H'0' DEFAULT TO ZERO
         LH    R2,QLNG3       LENGTH OF OFFSET FIELD
         SH    R2,=H'1'       IS THE OFFSET FIELD ZERO LENGTH?
         BM    CALLLIST       YES. USE ZERO OFFSET.
         MVC   QFZONES,QFZONE INITIALIZE NUMERIC TEST
         EX    R2,MVZ2        MOVE THE ZONES FOR VALIDITY CHECK
         CLC   QFZONES,QFZONE IS THE FIELD NUMERIC?
         BNE   TILT           NO. QUIT.
         EX    R2,PACK2       PACK THE FIELD
         CVB   R2,CONVERT     CONVERT TO BINARY
         STH   R2,QPOFFSET    STORE OFFSET
***********************************************************************
*                                                                     *
*   CALL LISTDS TO LIST THE DATASET                                   *
*                                                                     *
***********************************************************************
CALLLIST L     R15,=V(LISTDS) ADDR OF LISTDS MODULE
         BALR  R14,R15        GO TO IT
         QSTOP
TILT     QTILT '*** DATASET ID INVALID ***'
TILT2    QTILT '*** JOBNAME MUST BEGIN WITH USERID ***'
***********************************************************************
*                                                                     *
*   MISCELLANY                                                        *
*                                                                     *
***********************************************************************
CLC      CLC   QLOGON(1),JCTJNAME IS THE JOBNAME EQUAL TO USERID
MVZ      MVZ   QFZONES(1),QPARM2 CHECK FOR NUMERIC
MVZ2     MVZ   QFZONES(1),QPARM3 CHECK FOR NUMERIC
PACK     PACK  CONVERT,QPARM2(1) CONVERT TO BINARY
PACK2    PACK  CONVERT,QPARM3(1) CONVERT TO BINARY
         LTORG
         DROP  ,                   DROP ALL ADDRESSINGS           NERDC
SYMDEL   DSECT ,                   KILL SYM CARD GENERATION       UF023
LIST     CSECT ,                                                  UF023
JCT      EQU   0
         $BUFFER                                                  UF020
         $JCT
WORK     DSECT
         DS    72C
CONVERT  DS    D
         QCOMMON
SYMNODEL DSECT ,                   RESTORE SYM CARD GENERATION    UF023
         END
./ ADD NAME=LISTDS   8020-02166-03087-1844-00404-00281-00000-GREG
LISTDS   QSTART 'QUEUE COMMAND - LIST A DATASET FROM THE SPOOL PACK'
         USING QCKPT,R10      BASE REG FOR CHECKPOINT WORK AREA
         L     R10,QVCKPT     LOAD BASE REG
         USING QDISPLAY,R9    BASE REG FOR DISPLAY WORK AREA
         L     R9,QVDSPL      LOAD BASE REG
         USING WORK,R13       BASE REG FOR LOCAL WORK
***********************************************************************
*                                                                     *
*   DETERMINE FUNCTION REQUESTED                                      *
*                                                                     *
***********************************************************************
         CLI   QCODE,0        IS THE REQUEST FOR REPOSITIONING?
         BNE   REPOS          YES. DO IT.
***********************************************************************
*                                                                     *
*   LOCATE PDDB FOR DATASET SPECIFIED IN QPDSID                       *
*                                                                     *
***********************************************************************
         MVI   SWITCH,0       INITIALIZE SWITCH
         USING PDBDSECT,R2    BASE REG FOR PDDB
         USING IOTSTART,R3    BASE REG FOR IOT
         L     R3,QCIOTA      LOAD BASE REG
         LR    R5,R3          IOAREA FOR READ IOT BLOCK
         ICM   R4,15,QPNEXT   'NEXT' OR 'PREVIOUS' ACTIVE?        GP@P6
         BZ    NEXTIOT        NO                                  GP@P6
         BM    PREV1          YES, 'PREVIOUS'                     GP@P6
NEXT1    LH    R4,QPDSID      GET CURRENT DATA SET ID             GP@P6
         LA    R4,1(,R4)      INCREMENT IT                        GP@P6
         CH    R4,=H'5'       WAS IT JOB MESSAGES?                GP@P6
         BNE   *+8            NO                                  GP@P6
         LA    R4,101         YES, GO TO FIRST "USER" DATA SET    GP@P6
         STH   R4,QPDSID      SAVE UPDATED DATA SET ID            GP@P6
         B     NEXTIOT        START THE SEARCH                    GP@P6
PREV1    CLC   QPDSID,=H'2'   BACK TO JOB LOG ALREADY?            GP@P6
         BH    PREV2          NO                                  GP@P6
         XC    QPNEXT,QPNEXT  YES, NOTHING PREVIOUS TO THIS       GP@P6
         XC    QPOFFSET,QPOFFSET   LEFT MAX                       GP@P6
         B     NEXTIOT                                            GP@P6
PREV2    LH    R4,QPDSID      GET CURRENT DATA SET ID             GP@P6
         BCTR  R4,0           DECREMENT IT                        GP@P6
         CH    R4,=H'100'     JUST DONE LAST "USER" DATA SET?     GP@P6
         BNE   *+8            NO                                  GP@P6
         LA    R4,4           YES, GO BACK TO JOB MESSAGES        GP@P6
         STH   R4,QPDSID      SAVE UPDATED DATA SET ID            GP@P6
NEXTIOT  LR    R4,R3          BASE OF IOT
         A     R4,IOTPDDBP    OFFSET BEYOND LAST PDDB
         LR    R2,R3          BASE OF IOT
         A     R2,QCPDDB1     OFFSET TO FIRST PDDB IN IOT
FINDDS   OC    PDBMTTR,PDBMTTR IS THERE ANY OUTPUT?               UF020
         BZ    FINDDS1        NO, SKIP THIS ONE                   UF020
         CLC   QPDSID,PDBDSKEY IS THIS THE DATASET?
         BE    FOUNDDS        YES. CONTINUE.
FINDDS1  LA    R2,PDBLENG(R2) NO. LOOK AT NEXT PDDB.              UF020
         CR    R2,R4          HAVE WE GONE PAST THE LAST PDDB?
         BL    FINDDS         NO. TRY AGAIN.
         L     R4,IOTIOTTR    DISK ADDR OF NEXT IOT
SPIN     LTR   R4,R4          IS THERE ANOTHER IOT?
         BZ    SPINIOT        NO. TRY THE SPIN IOT?
         BAL   R8,READ        READ THE IOT
         B     NEXTIOT        SEARCH THE NEXT IOT
         USING JCTSTART,R1    BASE REG FOR JCT
SPINIOT  TM    SWITCH,1       DID WE SEARCH THE SPINIOT ALREADY?
         BO    TILT           YES. TILT.
         OI    SWITCH,1       SET SWITCH
         L     R1,QCJCTA      LOAD BASE REG
         L     R4,JCTSPIOT    DISK ADDR OF SPIN IOT
         DROP  R1
         B     SPIN           SEARCH THE SPIN IOT CHAIN
TILT     ICM   R0,15,QPNEXT   'NEXT' ACTIVE?                      GP@P6
         BP    NEXTLAST       YES                                 GP@P6
         MVC   QPDSID,=H'0'   INVALIDATE DSID
         QTILT '*** DATASET ID NOT FOUND ***'
NEXTLAST SLR   R0,R0                                              GP@P6
         BCTR  R0,0                                               GP@P6
         ST    R0,QPNEXT      ISSUE 'PREV'                        GP@P6
         B     PREV1                                              GP@P6
TILT2    QTILT '*** DATASET TABLE LIMITS EXCEEDED ***'
FOUNDDS  DS    0H                                                 UF007
         ICM   R4,15,QPNEXT   'NEXT'/'PREV' ACTIVE?               GP@P6
         BZ    FOUNDDS2       NO                                  GP@P6
         BM    PREVDONE       YES, 'PREV'                         GP@P6
         BCTR  R4,0           'NEXT', DECREMENT COUNTER           GP@P6
         ST    R4,QPNEXT      SAVE UPDATED COUNTER                GP@P6
         LTR   R4,R4          AT REQUESTED DATA SET?              GP@P6
         BP    NEXT1          NO                                  GP@P6
         B     FOUNDDS1       YES                                 GP@P6
PREVDONE AH    R4,=H'1'       ADJUST COUNTER                      GP@P6
         ST    R4,QPNEXT      SAVE UPDATED COUNTER                GP@P6
         BM    PREV1          NOT YET BACKED UP ENOUGH DATA SETS  GP@P6
FOUNDDS1 XC    QPOFFSET,QPOFFSET   LEFT MAX                       GP@P6
         CLC   QPDSID,=H'3'   IS IT THE JOB'S JCL?                GP@P6
         BNE   FOUNDDS2       NO, LEFT MAX IS GOOD                GP@P6
         MVI   QPOFFSET+1,10  YES                                 GP@P6
FOUNDDS2 CLI   QPARM1,C'*'    USE LAST JOB NAME?                  UF007
         BE    *+4+6          YES, SKIP OVERLAY OF JOBNAME        UF007
         MVC   QCJNAME,QPARM1 SAVE THE JOBNAME                    UF007
         LH    R15,QPDSID     GET THE DATA SET ID                 GP@P6
         CVD   R15,QDWORK     SHOW IT IN THE HEADING              GP@P6
         MVC   QCDSNO(6),=X'402020202120'                         GP@P6
         ED    QCDSNO(6),QDWORK+5                                 GP@P6
         QHEAD QCHLINE,X'24',SEL=Y            GREEN REVERSE       GP@P6
         MVC   QCRECFM,PDBRECFM RECORD FORMAT FOR SAVE
         MVC   QCLRECL,PDBLRECL RECORD LENGTH FOR SAVE
         L     R4,PDBMTTR     DISK ADDR OF FIRST BLOCK
         L     R5,QCBLKA      ADDR OF DATASET BLOCK IOAREA
         L     R2,QCSTART     BEGINNING OF DISK ADDR TABLE
         ZAP   QCCREC,=P'0'   ZERO CURRENT RECORD NO
         MVC   QCCPTR,QCSTART BEGIN OF TBL
         ZAP   QCHREC,=P'0'   ZERO HIGH REC NO
         MVC   QCHPTR,QCSTART BEGIN OF TBL
         ZAP   QPREC,=P'1'    REPOSITION TO TOP OF DATASET
         B     FIRST          PROCESS DATASET
         DROP  R2
         DROP  R3
***********************************************************************
*                                                                     *
*   PROCESS DATASET                                                   *
*                                                                     *
***********************************************************************
NEXTBLK  L     R4,0(R5)       DISK ADDR OF NEXT BLOCK
FIRST    LTR   R4,R4          IS THE DISK ADDR ZERO?
         BZ    END            YES. END OF DATASET.
         ST    R4,0(R2)       STORE DISK ADDR IN TABLE
         BAL   R8,READ        READ A BLOCK
         CLC   QPJOBID(6),4(R5) DOES THE JOBID MATCH?
         BNE   END            NO. END OF DATASET.
         MVC   4(4,R2),QCCREC STORE CURRENT REC NUM IN TABLE
         ST    R2,QCCPTR      STORE CURRENT TABLE ADDR
         CP    QCCREC,QCHREC  IS THE CURRENT REC NO > HIGHEST?
         BNH   NOTHI          NO. SKIP.
         MVC   QCHREC(8),QCCREC REPLACE HI REC CNT AND PTR
NOTHI    LA    R2,8(R2)       INCREMENT TO NEXT TBL ENTRY
         C     R2,QCEND       IS THIS THE END OF TABLE?
         BNL   TILT2          YES. TILT.
         LA    R4,10(R5)      ADDR OF FIRST RECORD IN BLOCK
***********************************************************************
*                                                                     *
*   PROCESS RECORDS                                                   *
*                                                                     *
***********************************************************************
NEXTREC  CLI   0(R4),X'FF'    IS LENGTH BYTE FF?
         BE    NEXTBLK        YES. END OF BLOCK.
         TM    1(R4),X'10'    IS THIS A SPANNED RECORD?
         BO    SPAN           YES. SKIP IT.
         SR    R6,R6          ZERO OUT REG
         IC    R6,0(R4)       INSERT LENGTH
         LR    R7,R6          SAVE RECORD LENGTH
         LR    R1,R4          SAVE RECORD LOCATION
         TM    1(R4),X'80'    IS CARRIAGE CONTROL SPECIFIED?
         BZ    NOCCTL         NO. CONTINUE.
         LA    R1,1(R1)       SKIP OVER CARRIAGE CONTROL
NOCCTL   TM    1(R4),X'08'    IS THIS RECORD TO BE IGNORED?
         LR    R4,R1          UPDATE RECORD POINTER
         BNZ   SKIPREC        YES. SKIP IT.
         AP    QCCREC,=P'1'   ADD ONE TO CUR REC NO
         CP    QCCREC,QPREC   HAVE WE REACHED THE RECORD WE WANT?
         BL    SKIPREC        NO. TRY NEXT RECORD.
         CLI   QCODE,4        IS THE REQUEST FOR A FIND?
         BE    FIND           YES. DO IT.
         CLI   QCODE,8        IS THE REQUEST FOR A FINDTIME?
         BE    FINDTIME       YES. DO IT.
FINDOFF  L     R14,QCJCTA     ADDR OF JCT                         GP@P6
         USING JCTSTART,R14   BASE REG FOR JCT                    GP@P6
         CLC   JCTJNAME,=C'SYSLOG  '                              GP@P6
         BNE   NORMLMSG       NOT LOOKING AT SYSTEM LOG           GP@P6
         DROP  R14                                                GP@P6
         CH    R7,=H'24'      LINE LONG ENOUGH FOR ACTION FLAG?   GP@P6
         BL    NORMLMSG       NO, DATA TOO SHORT TO COMPARE       GP@P6
         MVI   QDLNCODE,X'07' PREPARE FOR IMMEDIATE ACTION MSG    GP@P6
         CLI   26(R1),C'*'    ACTION FLAG PRESENT?                GP@P6
         BE    LNCDOKAY       YES                                 GP@P6
         CLI   26(R1),C'@'    ACTION FLAG PRESENT?                GP@P6
         BE    LNCDOKAY       YES                                 GP@P6
NORMLMSG MVI   QDLNCODE,X'05' STANDARD DISPLAY IS TURQUOISE       GP@P6
         CLC   QPDSID,=H'4'   LOOKING AT JOB MESSAGES?            GP@P6
         BNE   LNCDOKAY       NO, NO COLOUR CODING OF LINE        GP@P6
         CH    R7,=H'7'       LINE SHORTER THAN 7 BYTES?          GP@P6
         BL    LNCDOKAY       YES, DATA TOO SHORT TO COMPARE      GP@P6
         MVI   QDLNCODE,X'01' UNCODED DISPLAY IS BLUE             GP@P6
         LA    R14,LNCDTABL   POINT TO COMPARE TABLE              GP@P6
LNCDLOOP IC    R15,6(,R14)    SET LENGTH CODE OF COMPARE          GP@P6
         EX    R15,LNCDCOMP   MATCHING TABLE ENTRY?               GP@P6
         BE    LNCDMTCH       YES                                 GP@P6
         LA    R14,8(,R14)    NO, POINT TO NEXT ENTRY IN TABLE    GP@P6
         CLI   0(R14),X'FF'   END OF TABLE?                       GP@P6
         BNE   LNCDLOOP       NO, KEEP SEARCHING TABLE            GP@P6
         B     LNCDOKAY       YES, NOT IN TABLE                   GP@P6
LNCDCOMP CLC   3(0,R1),0(R14) <<< EXECUTED >>>                    GP@P6
LNCDMTCH MVC   QDLNCODE,7(R14) SET LINE SHADOW CODE               GP@P6
LNCDOKAY AH    R1,QPOFFSET    ADD OFFSET TO START OF RECORD
         SH    R7,QPOFFSET    SUBTRACT OFFSET FROM LENGTH
         BNP   ZEROPRT        NO DATA LEFT IN RECORD.
         CH    R7,QDLNELEN    IS THE RECORD BIGGER THAN LINE?     UF003
         BNH   LTMAX          NO. USE RECORD LENGTH.              UF003
         LH    R7,QDLNELEN    YES. USE A LENGTH OF LINE.          UF003
LTMAX    STH   R7,QDMLNG      STORE MESSAGE LENGTH                UF003
         LA    R1,3(R1)       OFFSET PAST REC HDR
         ST    R1,QDMSGA      STORE ADDR OF MESSAGE LINE
         BCTR  R7,0           DECREMENT FOR EXECUTE               GP@P6
         EX    R7,XLATEMSG    CLEAR UNDISPLAYABLES FROM MESSAGE   GP@P6
         L     R15,=V(DISPLAY) ADDRESS OF DISPLAY MODULE
         BALR  R14,R15        GO TO IT
         TM    QDOVER,1       WAS THERE A PAGE OVERFLOW?
         BNO   SKIPREC        NO. SKIP.
         ZAP   QPREC,QCCREC   UPDATE THE REPOSITION NUMBER
         L     R15,QDHLINE@   POINT TO HEADING LINE               GP@P6
         USING Q15HLINE,R15                                       GP@P6
         MVC   HREC,EDIT      PATTERN FOR EDIT
         ED    HREC,QCCREC    EDIT RECORD NUMBER
         DROP  R15                                                GP@P6
SKIPREC  LA    R4,3(R6,R4)    INCREMENT TO NEXT RECORD
         B     NEXTREC        PROCESS NEXT RECORD
XLATEMSG TR    0(0,R1),TABLE  <<< EXECUTED >>>                    GP@P6
SPAN     LH    R6,2(R4)       LENGTH OF SEGMENT
         TM    1(R4),X'08'    IS THIS THE FIRST SEGMENT?
         BO    SPANFRST       YES. USE HEADER LENGTH OF 6.
         LA    R4,4(R6,R4)    UPDATE RECORD POSITION
         B     NEXTREC        PROCESS NEXT RECORD
SPANFRST LA    R4,6(R6,R4)    UPDATE RECORD POSITION
         B     NEXTREC        PROCESS NEXT RECORD
ZEROPRT  LA    R1,QBLANK      PRINT A BLANK
         LA    R7,1           LENGTH OF ONE
         B     LTMAX          PRINT THE RECORD                    UF003
END      CP    QCCREC,=P'0'   IS THE DATASET EMPTY
         BE    STOP           YES. QUIT.
         L     R15,QDHLINE@   POINT TO HEADING LINE               GP@P6
         USING Q15HLINE,R15                                       GP@P6
         MVC   HEND,ENDLINE   TELL THEM THIS IS THE END
         MVC   HREND,EDIT     PATTERN FOR EDIT
         ED    HREND,QCCREC   LAST REC NO
         DROP  R15                                                GP@P6
         CLI   QCODE,32       WAS REQUEST FOR BOTTOM?
         BE    BOTTOM         YES. BACK UP 21 LINES.
         MVC   QDMLNG,=H'0'   ZERO OUT MESSAGE LENGTH
         L     R15,=V(DISPLAY) ADDR OF DISPLAY MODULE
         BALR  R14,R15        FLUSH THE SCREEN
         ZAP   QPREC,=P'1'    RECORD NUMBER 1
         QHEAD QCHLINE,X'24',DMY=Y            GREEN REVERSE       GP@P6
         B     TOP            START AT TOP OF DATASET
STOP     XC    QPDSID,QPDSID  MAKE USER SPECIFY A NEW DATA SET
         QHEAD =CL80'*** DATA SET IS EMPTY ***',X'26',DMY=Y       GP@P6
         QSTOP
***********************************************************************
*                                                                     *
*   BOTTOM OF DATASET                                                 *
*                                                                     *
***********************************************************************
BOTTOM   ZAP   QPREC,QCCREC   LAST RECORD NUMBER
         MVI   QCODE,0        AVOID A LOOP
         SP    QPREC,QDLNES   TOP OF PAGE -1                      UF003
         AP    QPREC,=P'1'    TOP OF PAGE                         UF003
         BP    REPOS          CONTINUE IF POSITIVE.
         ZAP   QPREC,=P'1'    TOP OF DATASET
***********************************************************************
*                                                                     *
*   REPOSITION TO REQUESTED RECORD NUMBER                             *
*                                                                     *
***********************************************************************
REPOS    QHEAD QCHLINE,X'24',DMY=Y            GREEN REVERSE       GP@P6
         L     R15,QDHLINE@   POINT TO HEADING LINE               GP@P6
         USING Q15HLINE,R15                                       GP@P6
         MVC   HREC,EDIT      PREPARE FOR EDIT
         ED    HREC,QPREC     EDIT RECORD NUMBER
         DROP  R15                                                GP@P6
         CP    QPREC,QCHREC   IS THE REQ NO > HIGHEST READ?
         BNL   HI             YES. GO FROM HI.
         CP    QPREC,QCCREC   IS THE REQ NO > CURRENT REC?
         BH    FWD            YES. GO FROM CURRENT.
         CP    QPREC,=P'1'    IS REQ FOR TOP OF DATASET?
         BH    BACK           NO. GO BACK FROM CURRENT.
TOP      L     R2,QCSTART     YES. START AT TOP
RESUME   L     R4,0(R2)       LOAD DISK ADDR
         L     R5,QCBLKA      ADDR OF BLOCK IOAREA
         MVC   QCCREC,4(R2)   RESET CURRENT REC NO
         B     FIRST          RESUME PROCESSING
HI       L     R2,QCHPTR      START AT HIGHEST SO FAR
         B     RESUME         FIND CORRECT BLOCK                  GP@P6
FWD      L     R2,QCCPTR      CURRENT TABLE PTR
FWDLOOP  CP    QPREC,12(4,R2) IS THE NEXT ENTRY > REQ NO?
         BL    RESUME         YES. PROCESS IT.                    GP@P6
         LA    R2,8(R2)       TRY NEXT ENTRY
         B     FWDLOOP        AGAIN
BACK     L     R2,QCCPTR      CURRENT TABLE PTR
BACKLOOP CP    QPREC,4(4,R2)  IS THE ENTRY < REQ NO?
         BNL   RESUME         YES. PROCESS IT.                    GP@P6
         SH    R2,=H'8'       TRY PREVIOUS ENTRY
         B     BACKLOOP       AGAIN
***********************************************************************
*                                                                     *
*   FIND MATCHING RECORD ROUTINE                                      *
*                                                                     *
***********************************************************************
FIND     LH    R3,QPLNG       LENGTH-1 OF COMPARE
         LR    R14,R6         LENGTH OF RECORD
         SR    R14,R3         NUMBER OF COMPARES
         BNP   SKIPREC        RECORD IS TOO SMALL. SKIP IT.
         LR    R15,R4         FIRST BYTE OF RECORD
         CLC   QOFFE,=H'0'    END RANGE FOR FIND SPECIFIED ?
         BE    FLOOP          NO. BYPASS RANGE FOR FIND
         AH    R15,QOFFS      YES. START ADDR FOR FIND
         LH    R14,QOFFE      END ADDR FOR FIND
         SH    R14,QOFFS      VALID RANGE ?
         BP    FLOOP          YES. CONTINUE PROCESSING
         QTILT ' *** ERROR IN COLUMN SPECIFICATION ***'
FLOOP    EX    R3,CLC         DOES THE FIND DATA MATCH THE RECORD?
         BE    MATCH          YES. DISCONTINUE SEARCH.
         LA    R15,1(R15)     INCREMENT TO NEXT BYTE
         BCT   R14,FLOOP      TRY NEXT BYTE
         B     SKIPREC        SKIP THE RECORD. NO MATCH.
MATCH    CLI   QSUBNAME+1,C'A' IS THE REQUEST FOR A FINDALL?
         BE    FALL           YES. DO NOT DISABLE SEARCH.
         MVI   QCODE,0        END THE SEARCH
         ZAP   QPREC,QCCREC   UPDATE THE REPOSITION NUMBER
FALL     L     R15,QDHLINE@   POINT TO HEADING LINE               GP@P6
         USING Q15HLINE,R15                                       GP@P6
         MVC   HREC,EDIT      PREPARE FOR EDIT
         ED    HREC,QCCREC    EDIT RECORD NUMBER
         B     FINDOFF        CONTINUE
         DROP  R15                                                GP@P6
CLC      CLC   QPFIND(1),3(R15) COMPARE PARM TO RECORD
***********************************************************************
*                                                                     *
*   FIND THE RECORD WHICH IS GREATER THAN OR EQUAL TO TIME            *
*                                                                     *
***********************************************************************
FINDTIME CLI   10(R4),C'.'    DOES THIS RECORD HAVE TIME?
         BNE   SKIPREC        NO. SKIP IT.
         CLC   QPARM1,8(R4)   IS THIS THE TIME WE WANT?
         BH    SKIPREC        NO. SKIP IT.
         B     MATCH          END THE SEARCH
***********************************************************************
*                                                                     *
*   READ A BLOCK FROM HASPACE                                         *
*                                                                     *
***********************************************************************
READ     ST    R4,QCTRAK      STORE DISK ADDR
         LR    R1,R5          IOAREA ADDRESS
         L     R15,=V(READSPC) ADDR OF ROUTINE TO READ HASPACE
         BALR  R14,R15        GO TO IT
         BR    R8             RETURN TO CALLER
***********************************************************************
*                                                                     *
*   MISCELLANY                                                        *
*                                                                     *
***********************************************************************
         LTORG
ENDLINE  DC    C', END OF DATA. LAST REC #'
EDIT     DC    X'4020202020202021'
         DC    CL45' '
         DS    0D
* INTERNAL ATTRIBUTE CODE IS X'YZ' WHERE Y=HIGHLIGHTING AND Z=COLOUR
* Y IN 0-3 RANGE: 0=NORMAL 1=BLINK 2=REVERSE 3=UNDERSCORE
* Z IN 1-7 RANGE: 1=BLUE 2=RED 3=PINK 4=GREEN 5=TURQ 6=YELLOW 7=WHITE
*              CL6'MSG-ID',AL1(LENGTH-CODE),X'INTERNAL-ATTR-CODE'
LNCDTABL DC    CL6' STMT ',AL1(5),X'07'  STMT NO.
         DC    CL6'IEA***',AL1(2),X'26' ** SUPERVISOR MESSAGES
         DC    CL6'IEC***',AL1(2),X'26' ** DATA MANAGEMENT MESSAGES
         DC    CL6'IEF142',AL1(5),X'07' STEP WAS EXECUTED
         DC    CL6'IEF19*',AL1(4),X'22' (VARIOUS ALLOCATION ERRORS)
         DC    CL6'IEF201',AL1(5),X'22' JOB TERMINATED BY COND CODES
         DC    CL6'IEF202',AL1(5),X'22' STEP WAS NOT RUN
         DC    CL6'IEF21*',AL1(4),X'22' DATA SET NOT FOUND (AND OTHERS)
         DC    CL6'IEF236',AL1(5),X'06' ALLOC. FOR
         DC    CL6'IEF237',AL1(5),X'04' ALLOCATED TO
         DC    CL6'IEF25*',AL1(4),X'22' (VARIOUS DASD ALLOC FAILURES)
         DC    CL6'IEF26*',AL1(4),X'22' (VARIOUS ISAM AND OTHER ERRORS)
         DC    CL6'IEF272',AL1(5),X'07' STEP WAS NOT EXECUTED
         DC    CL6'IEF283',AL1(5),X'25' NOT DELETED
         DC    CL6'IEF285',AL1(5),X'05' (SUCCESSFUL DISPOSITION)
         DC    CL6'IEF286',AL1(5),X'23' DISP FIELD INCOMPATIBLE
         DC    CL6'IEF287',AL1(5),X'25' NOT CATLG/RECTLG/UNCTLG
         DC    CL6'IEF318',AL1(5),X'22' 'UNIT=AFF' INVALID FOR DASD
         DC    CL6'IEF367',AL1(5),X'22' PATTERN DSCB OBTAIN I/O ERROR
         DC    CL6'IEF373',AL1(5),X'02' STEP START
         DC    CL6'IEF374',AL1(5),X'32' STEP STOP
         DC    CL6'IEF375',AL1(5),X'03' JOB START
         DC    CL6'IEF376',AL1(5),X'03' JOB STOP
         DC    CL6'IEF470',AL1(5),X'22' UNALLOCATION FAILED
         DC    CL6'IEF472',AL1(5),X'22' (ABNORMAL) COMPLETION CODE
         DC    CL6'IEF702',AL1(5),X'22' UNABLE TO ALLOCATE
         DC    FL8'-1'
* TABLE OF PRINTABLE CHARACTERS
TABLE    DC    CL64' '
         DC    191AL1(*-TABLE),C' '                         GP@P6 UF003
SYMDEL   DSECT ,                   KILL SYM CARD GENERATION       UF023
LISTDS   CSECT ,                                                  UF023
JCT      EQU   0
BUFSTART EQU   0
BUFDSECT EQU   0
         $TAB
         $JCT
         $PDDB
         $IOT
         QCOMMON
Q15HLINE DSECT                                                    GP@P6
         DS    C'JOB XXXXXXXX, DSID XXXXXXXX, REC #'
HREC     DS    CL8
HEND     DS    C', END OF DATA. LAST REC #'
HREND    DS    CL8
WORK     DSECT
         DS    CL72
SWITCH   DS    C
SYMNODEL DSECT ,                   RESTORE SYM CARD GENERATION    UF023
         END
./ ADD NAME=NEXT     8002-02306-02308-2000-00056-00060-00000-GREG
NEXT     QSTART 'QUEUE COMMAND - JUMP TO ANOTHER DATA SET'
         GBLB  &QACF2         IS ACF2 AUTH CHECKING TO BE DONE     FCI*
         GBLB  &QRNB                                              RNB05
***********************************************************************
*                                                                     *
*   CHECK AND CONVERT THE DATASET ID NUMBER                           *
*                                                                     *
***********************************************************************
         LH    R2,QLNG1       SAVE LENGTH OF DATASET COUNT FIELD
         LA    R3,1           PREPARE FOR NO OPERAND
         SH    R2,=H'1'       IS THE COUNT FIELD ZERO LENGTH?
         BM    GOTCOUNT       YES, USE DEFAULT COUNT
         MVC   QFZONES,QFZONE INITIALIZE NUMERIC TEST
         EX    R2,MVZ         MOVE THE ZONES FOR VALIDITY CHECK
         CLC   QFZONES,QFZONE IS THE FIELD NUMERIC?
         BNE   TILT           NO. QUIT.
         EX    R2,PACK        PACK THE FIELD
         CVB   R3,QDWORK      CONVERT TO BINARY
GOTCOUNT CLI   QSUBNAME,C'N'  'NEXT' COMMAND?
         BE    COUNTOK        YES
         LNR   R3,R3          NO, MUST BE 'PREV' COMMAND
***********************************************************************
*                                                                     *
*   CALL FINDJOB TO LOCATE THE JQE, JCT, AND IOT                      *
*                                                                     *
***********************************************************************
COUNTOK  XC    QLNG1,QLNG1    ZERO FOR FINDJOB
         L     R15,=V(FINDJOB) ADDR OF MODULE TO FIND JOB
         BALR  R14,R15        GO TO IT
         ST    R3,QPNEXT      STORE DATA SET COUNT
***********************************************************************
*                                                                     *
*   CALL LISTDS TO LIST THE DATASET                                   *
*                                                                     *
***********************************************************************
         L     R15,=V(LISTDS) ADDR OF LISTDS MODULE
         BALR  R14,R15        GO TO IT
         QSTOP
TILT     QTILT '*** MISSING NUMERIC OPERAND ***'
***********************************************************************
*                                                                     *
*   MISCELLANY                                                        *
*                                                                     *
***********************************************************************
MVZ      MVZ   QFZONES(0),QPARM1 CHECK FOR NUMERIC
PACK     PACK  QDWORK,QPARM1(0)  CONVERT TO BINARY
         LTORG
         DROP  ,                   DROP ALL ADDRESSINGS           NERDC
SYMDEL   DSECT ,                   KILL SYM CARD GENERATION       UF023
LIST     CSECT ,                                                  UF023
JCT      EQU   0
         $BUFFER                                                  UF020
         $JCT
         QCOMMON
SYMNODEL DSECT ,                   RESTORE SYM CARD GENERATION    UF023
         END
./ ADD NAME=PARSE    8008-02173-03063-1444-00241-00231-00000-GREG
PARSE    QSTART 'QUEUE COMMAND - COMMAND LINE PARSE ROUTINES'
***********************************************************************
* RNB CHANGES:                                                        *
*    (1) ADDED COMMAND ABBREVIATIONS: RNB06                           *
*                JM FOR JMSG                                          *
*                JL FOR JLOG                                          *
*                JC FOR JCL                                           *
*                SL FOR SLOG                                          *
*                FT FOR FTIM                                          *
*                DE FOR DEL                                           *
*                RE FOR REQ                                           *
*    (2) DELETED COMMANDS:      RNB06  (ONLY IF QRNB=1)               *
*                TSO, EXEC, AND MODEL                                 *
*    (3) USE RACF TO CHECK FOR X AUTHORITY (XP COMMAND): RNB03        *
*                                                                     *
***********************************************************************
         GBLB  &QRNB                                              RNB06
         GBLB  &QRACF                                             RNB03
         USING QDISPLAY,R10   BASE REG FOR DISPLAY WORK AREA
         L     R10,QVDSPL     LOAD BASE REG
         USING WORK,R13       BASE REG FOR LOCAL WORK AREA
***********************************************************************
*                                                                     *
*   PARSE SUBCOMMAND NAME                                             *
*                                                                     *
***********************************************************************
         LH    R2,QDRLNG      LENGTH OF REPLY LINE
         OC    QDREPLY,QBLANK TRANSLATE TO UPPER CASE
         CLC   QDREPLY,QBLANK IS THE ENTIRE REPLY BLANK?
         BE    LOOKUP         YES. DO LOOKUP.
         MVC   QDTLINE,QDREPLY MOVE COMMAND LINE TO HEADING
         MVC   FIELD,QBLANK   BLANK THE WORK FIELD
         MVC   OFFSET(4),=F'0' ZERO THE OFFSET AND LENGTH
         MVC   QOFF0(12),OFFSET INITIALIZE FIRST FIELD
         MVC   QOFF1(48),QOFF0 INITIALIZE NEXT FOUR FIELDS
         LA    R6,QOFF4+12    ADDR PAST LAST FIELD
         LA    R5,QOFF0       ADDR OF FIRST SET OF FIELDS
         LA    R3,QDREPLY     FIRST BYTE OF REPLY LINE
ENCORE   LA    R4,FIELD       FIRST BYTE OF WORK FIELD
BLANK    CLI   0(R3),C' '     IS THIS BYTE BLANK?
         BNE   FIRST          NO. START OF FIELD.
         LA    R3,1(R3)       YES. SKIP IT.
         BCT   R2,BLANK       TRY NEXT BYTE
         B     EMPTY          END OF REPLY LINE.
FIRST    LH    R1,QDRLNG      REPLY LENGTH
         SR    R1,R2          COMPUTE OFFSET TO START OF FIELD
         STH   R1,OFFSET      STORE OFFSET
         LR    R1,R2          SAVE COUNT OF REMAINING BYTES
         B     CHAR           CONTINUE
LOOP     CLI   0(R3),C' '     IS THIS BYTE BLANK?
         BE    LAST           YES. END OF FIELD.
CHAR     MVC   0(1,R4),0(R3)  MOVE BYTE TO SUBNAME
         LA    R3,1(R3)       INCREMENT
         LA    R4,1(R4)       INCREMENT
         BCT   R2,LOOP        TRY NEXT BYTE
LAST     SR    R1,R2          COMPUTE FIELD LENGTH
         CH    R1,=H'8'       IS LENGTH GREATER THAN 8?
         BNH   STORE          NO. USE IT.
         LA    R1,8           YES. USE LENGTH OF EIGHT.
STORE    STH   R1,LENGTH      STORE FIELD LENGTH
EMPTY    MVC   0(12,R5),OFFSET MOVE FIELD TO QCOMMON
         LTR   R2,R2          IS THE REMAINING LENGTH ZERO?
         BZ    LOOKUP         YES. DO THE TABLE LOOKUP.
         MVC   FIELD,QBLANK   BLANK THE WORK FIELD
         MVC   OFFSET(4),=F'0' ZERO OUT OFFSET AND LENGTH
         LA    R5,12(R5)      INCREMENT TO NEXT FIELD
         CR    R5,R6          WAS THAT THE LAST FIELD?
         BL    ENCORE         NO. PROCESS NEXT FIELD.
***********************************************************************
*                                                                     *
*   LOOK UP THE MODULE ADDRESS FOR THE SUB COMMAND                    *
*                                                                     *
***********************************************************************
LOOKUP   CLC   =C'XP',QSUBNAME  IS THIS A PASSWORD REQUEST?       UF014
         BE    PASSWD         YES. CHECK FOR PASSWORD.            UF014
LOOKUP2  LA    R2,TABLE       START OF SUBCOMMAND TABLE
         TM    QXAUTH,1       IS THE USER PRIVILEGED?             UF014
         BNO   NEXT           NO, TABLE IS OK                     UF014
         LA    R2,TABLEX      START OF PRIV TABLE                 UF014
         CLC   =C'DIE',QSUBNAME IS THIS THE DIE REQUEST?          UF024
         BE    CDIE           YES, DO IT                          UF024
NEXT     CLC   0(4,R2),QSUBNAME COMPARE FIRST 4 CHARACTERS        UF014
         BE    FOUND          THIS IS THE ONE
         LA    R2,10(R2)      NEXT ENTRY                          UF014
         CLI   0(R2),X'FF'    IS THIS THE END OF TABLE?
         BNE   NEXT           NO. TRY NEXT ENTRY.
FOUND    MVC   QCODEH(6),4(R2) SUBCOMMAND CODE AND COMMAND ADDR   UF014
         NI    QFLAG1,255-QFLG1HLP        NO LONGER IN HELP       GP@P6
STOP     QSTOP
***********************************************************************
*                                                                     *
*   CHECK PASSWORD FOR AUTHORIZED COMMANDS                        UF014
*                                                                     *
***********************************************************************
         AIF   (&QRACF).RNB03A                                    RNB03
PASSWD   CLC   QPARM1,=C'PASSWORD' DID THE USER SAY PASSWORD?
         BNE   BOUNCE         NO. REJECT.
*        TPUT  WPASS,L'WPASS,FULLSCR,MF=(E,QTPUT)
         LA    R1,WPASS       POINT TO DATA STREAM                GP@P6
         LA    R0,L'WPASS     GET DATA STREAM LENGTH              GP@P6
         ICM   R1,8,=X'03'    SET FLAGS FOR FULLSCR               GP@P6
         TPUT  (1),(0),R      CLEAR THE SCREEN                    GP@P6
*        TGET  RPASS,8,EDIT,MF=(E,QTGET)
         LA    R1,RPASS       REPLY ADDRESS                       GP@P6
         LA    R0,8           GET INPUT BUFFER LENGTH             GP@P6
         ICM   R1,8,=X'80'    SET FLAGS FOR EDIT                  GP@P6
         TGET  (1),(0),R      CLEAR THE SCREEN                    GP@P6
         CLC   RPASS,=C'YES SIR!' IS THE PASSWORD CORRECT?
         BNE   BOUNCE         NO. REJECT.
         OI    QXAUTH,1       AUTHORIZE USER
         QTILT '*** PASSWORD ACCEPTED ***'
         AGO   .RNB03B                                            RNB03
.RNB03A  ANOP                                                     RNB03
PASSWD   RACHECK ENTITY=QRACNMXP,MF=(E,QRACHECK)                  RNB03
         LTR   R15,R15                                            RNB03
         BNZ   BOUNCE                                             RNB03
         OI    QXAUTH,1       AUTHORIZE USER                      RNB03
         QTILT '*** AUTHORIZED FUNCTIONS ENABLED'                 RNB03
.RNB03B  ANOP                                                     RNB03
BOUNCE   LA    R2,HELPCC      NO. PRETEND IT IS INVALID.
         B     FOUND          CONTINUE
***********************************************************************
*                                                                     *
*   MISCELLANY                                                        *
*                                                                     *
***********************************************************************
         LTORG
         EJECT ,                                                  UF014
TABLEX   DS    0D             START OF PRIV COMMAND TABLE         UF014
         DC    C'XB  ',H'0',VL4(HEXBLK)    DISP SPOOL BLOCK
         DC    C'XJ  ',H'36',VL4(SEARCH)   DISP HEX JQE/JOE
         DC    C'XI  ',H'0',VL4(INITS)     DISP ACTIVE INITS
         DC    C'XD  ',H'0',VL4(XDS)       UNRESTRICTED DISP OF FILES
         DC    C'JQE ',H'0',VL4(CJQE)      HEX DUMP OF JQE        UF015
         DC    C'JCT ',H'0',VL4(CJCT)      HEX DUMP OF JCT        UF016
         DC    C'HCT ',H'0',VL4(CHCT)      HEX DUMP OF HCT SAVEAREUF022
         DC    C'PDDB',H'0',VL4(CPDDB)     LIST PDDB'S FOR JOB    UF025
         DC    C'JOE ',H'0',VL4(CJOE)      HEX DUMP OF JOE        UF026
         SPACE 1                                                  UF014
TABLE    EQU   *              START OF STANDARD COMMAND TABLE     UF014
         DC    C'STAT',H'0',VL4(SEARCH)    STATUS
         DC    C'ST  ',H'0',VL4(SEARCH)    STATUS
         DC    C'DD  ',H'0',VL4(DDNAME)    LIST SYSINS/SYSOUTS FOR JOB
         DC    C'LIST',H'0',VL4(LIST)      LIST A SYSIN/SYSOUT FILE
         DC    C'L   ',H'0',VL4(LIST)      LIST A SYSIN/SYSOUT FILE
         DC    C'FIND',H'4',VL4(REPOS)     FIND
         DC    C'FALL',H'4',VL4(REPOS)     FIND ALL
         DC    C'FA  ',H'4',VL4(REPOS)     FIND ALL
         DC    C'F   ',H'4',VL4(REPOS)     FIND
         DC    C'FTIM',H'8',VL4(REPOS)     FTIME (SYSLOG)
         DC    C'FT  ',H'8',VL4(REPOS)     FTIME (SYSLOG)         RNB06
         DC    C'COL ',H'12',VL4(REPOS)    COLUMN
         DC    C'CO  ',H'12',VL4(REPOS)    COLUMN
         DC    C'C   ',H'12',VL4(REPOS)    COLUMN
         DC    C'@   ',H'16',VL4(REPOS)    REPOS TO RECORD NUMBER
         DC    C'MD  ',H'16',VL4(REPOS)    REPOS TO RECORD NUMBER
         DC    C'+   ',H'20',VL4(REPOS)    DOWN
         DC    C'D   ',H'20',VL4(REPOS)    DOWN
         DC    C'DOWN',H'20',VL4(REPOS)    DOWN
         DC    C'PF  ',H'20',VL4(REPOS)    PAGE FORWARD
         DC    C'HF  ',H'20',VL4(REPOS)    HALF PAGE FORWARD
         DC    C'-   ',H'24',VL4(REPOS)    UP
         DC    C'U   ',H'24',VL4(REPOS)    UP
         DC    C'UP  ',H'24',VL4(REPOS)    UP
         DC    C'PB  ',H'24',VL4(REPOS)    PAGE BACK
         DC    C'HB  ',H'24',VL4(REPOS)    HALF BACK
         DC    C'TOP ',H'28',VL4(REPOS)    TOP
         DC    C'T   ',H'28',VL4(REPOS)    TOP
         DC    C'BOTT',H'32',VL4(REPOS)    BOTTOM
         DC    C'BOT ',H'32',VL4(REPOS)    BOTTOM
         DC    C'B   ',H'32',VL4(REPOS)    BOTTOM
         AIF   (&QRNB).RNB06A                                     RNB06
         DC    C'MODE',H'36',VL4(REPOS)    MODEL                  UF003
         DC    C'M   ',H'36',VL4(REPOS)    MODEL                  UF003
.RNB06A  ANOP                                                     RNB06
         DC    C'MONO',H'40',VL4(REPOS)    MONOCHROME             GP@P6
         DC    C'COLO',H'44',VL4(REPOS)    EXTENDED DATA STREAM   GP@P6
         DC    C'SAVE',H'6',VL4(SAVE)      SAVE COPY OF CURRENT FILE
         DC    C'SPIN',H'6',VL4(CSPIN)     SPIN COPY OF CURRENT FILE
         DC    C'SLOG',H'0',VL4(SYSLOG)    LIST THE SYSTEM LOG DATASET
         DC    C'SL  ',H'0',VL4(SYSLOG)    LIST THE SYSTEM LOG    RNB06
         DC    C'DA  ',H'4',VL4(SEARCH)    DISP ALL IN EXEC
         DC    C'DI  ',H'8',VL4(SEARCH)    DISP ALL IN INPUT CLASS
         DC    C'DO  ',H'12',VL4(SEARCH)   DISP ALL IN OUTPUT CLASS
         DC    C'AI  ',H'16',VL4(SEARCH)   DISP ALL AVAIL FOR EXEC
         DC    C'AO  ',H'20',VL4(SEARCH)   DISP ALL AVAIL FOR OUTPUT
         DC    C'HI  ',H'24',VL4(SEARCH)   DISP ALL IN INPUT HOLD
         DC    C'HO  ',H'28',VL4(SEARCH)   DISP ALL IN OUTPUT HOLD
         DC    C'DT  ',H'32',VL4(SEARCH)   DISP TSO USERS
         DC    C'DJ  ',H'36',VL4(SEARCH)   DISPLAY JOB
         DC    C'DS  ',H'40',VL4(SEARCH)   DISPLAY STC
         DC    C'DQ  ',H'44',VL4(SEARCH)   DISP INPUT QUEUES
         DC    C'DF  ',H'48',VL4(SEARCH)   DISP OUTPUT QUEUES
         DC    C'JCL ',H'0',VL4(JCL)       LIST JCL
         DC    C'JC  ',H'0',VL4(JCL)       LIST JCL               RNB06
         DC    C'JLOG',H'0',VL4(JLOG)      LIST JOBLOG
         DC    C'JL  ',H'0',VL4(JLOG)      LIST JOBLOG            RNB06
         DC    C'JMSG',H'0',VL4(JMSG)      LIST SYSMSGS
         DC    C'JM  ',H'0',VL4(JMSG)      LIST SYSMSGS           RNB06
         DC    C'DC  ',H'0',VL4(ACTIVE)    DISP CPU BATCH/STC/TSO
         DC    C'DEL ',H'0',VL4(SYSOUT)    DELETE JOB
         DC    C'DE  ',H'0',VL4(SYSOUT)    DELETE JOB             RNB06
         DC    C'REQ ',H'4',VL4(SYSOUT)    REQUEUE JOB
         DC    C'RE  ',H'4',VL4(SYSOUT)    REQUEUE JOB            RNB06
         DC    C'CAN ',H'8',VL4(SYSOUT)    CANCEL JOB
         DC    C'CA  ',H'8',VL4(SYSOUT)    CANCEL JOB             RNB06
         AIF   (&QRNB).RNB06B                                     RNB06
         DC    C'TSO ',H'4',VL4(CTSO)      ISSUE ANY TSO COMMAND  UF017
         DC    C'EX  ',H'0',VL4(CTSO)      IMPLICIT CLIST INVOKE  UF017
         DC    C'EXEC',H'0',VL4(CTSO)      IMPLICIT CLIST INVOKE  UF017
         DC    C'PDDB',H'0',VL4(CPDDB)     LIST PDDB'S FOR JOB    UF025
         DC    C'NEXT',H'0',VL4(NEXT)      NEXT DATA SET          GP@P6
         DC    C'N   ',H'0',VL4(NEXT)      NEXT DATA SET          GP@P6
         DC    C'PREV',H'0',VL4(NEXT)      PREVIOUS DATA SET      GP@P6
         DC    C'P   ',H'0',VL4(NEXT)      PREVIOUS DATA SET      GP@P6
.RNB06B  ANOP                                                     RNB06
HELPCC   DC    X'FF0000000000',VL4(HELP)
         SPACE 1                                                  UF014
WPASS    DC    X'C1115D7F1140403C4040001D4C13'  *** SPF TCAM
         SPACE 1                                                  UF024
CDIE     DC    X'00DEAD'                                          UF024
         DC    AL1(L'CDIEMSG)                                     UF024
CDIEMSG  DC    C'DIE COMMAND ENTERRED'                            UF024
         SPACE 1                                                  UF024
CDIEDONE LA    R2,HELPCC          SIMULATE HELP REQUEST WHEN RETURN 024
         MVI   QSUBNAME,0         CLEAR COMMAND NAME              UF024
         B     FOUND              AND RETURN TO CALLER            UF024
         SPACE 1                                                  UF024
         AIF   (NOT &QRACF).RNB03C                                RNB03
RACNAME  DC    CL8'QUEUEXP'                                       RNB03
.RNB03C  ANOP                                                     RNB03
WORK     DSECT
         DS    CL72
OFFSET   DS    H
LENGTH   DS    H
FIELD    DS    CL8
RPASS    DS    CL8
SYMDEL   DSECT ,                   KILL SYM CARD GENERATION       UF023
         QCOMMON
SYMNODEL DSECT ,                   RESTORE SYM CARD GENERATION    UF023
         END
./ ADD NAME=PRINT    8006-02173-02326-1414-00535-00507-00000-GREG
PRINT    QSTART 'QUEUE COMMAND - PRINT SCREEN DISPLAY ROUTINE'     FCI*
***********************************************************************
* GP@P6 CHANGES:                                                      *
*      (1) GP@P6 - PROCESS NEW BYTE-FOR-BYTE BUFFER MAPPING METHOD 6/02
*      (2) GP@P6 - REWRITE GETTIME TO REMOVE Y2K PROBLEMS         11/02
***********************************************************************
***********************************************************************
* RNB CHANGES:                                                        *
*      (1) RNB10 - CHANGE DEFAULT SYSOUT CLASS TO C (IF QRNB=1)       *
***********************************************************************
         GBLB  &QRNB                                              RNB10
         USING QDISPLAY,R10   BASE REG FOR DISPLAY WORK AREA       FCI*
         L     R10,QVDSPL     LOAD BASE REG                        FCI*
         USING QCPRINT,R9     BASE REG FOR PRINT WORK AREA         FCI*
         L     R9,QVPRINT     LOAD BASE REGISTER                   FCI*
         USING WORK,R13       BASE REG FOR LOCAL WORK AREA         FCI*
***********************************************************************
*   PROCESS THE PRINT COMMAND                                      FCI*
***********************************************************************
STARTIT  BAL   R7,PARSECMD    GO PARSE THE PRINT COMMAND           FCI*
         CLC   =C'ON',QPPARM1 IS IT ON?                            FCI*
         BE    STARTPRT         YES..GO START IT                   FCI*
         CLC   =C'OFF',QPPARM1 IS PRINT OFF?                       FCI*
         BE    STOPPRT          YES..GO STOP IT                    FCI*
         CLI   QPPARM1,C' '   NO PARM?                             FCI*
         BE    STARTPRT         YES..ASSUME START                  FCI*
STOP     MVC   QDREPLY,QBLANK   KISS OFF OUR REPLY  (SNEAKY)       FCI*
         XC    QDRLNG,QDRLNG    AND SAY NOBODY HOME                FCI*
         QSTOP                                                     FCI*
         EJECT ,                                                   FCI*
***********************************************************************
*   START (OR CONTINUE) THE PRINT PROCESS                          FCI*
***********************************************************************
STARTPRT DS 0H                                                     FCI*
         TM    QPFLAG,HARDCPY  IS HARDCOPY ON                      FCI*
         BO    JUSTPRT         YES..JUST PRINT                     FCI*
         ZAP   QPPAGE,=P'0'    RESET PAGE NUMBER                   FCI*
         MVI   QPHEAD1,C'0'    AND ASA ON HEADING SO WELL START FRESH
         BAL   R7,ALLOCHC      GO ALLOCATE / OPEN HARDCOPY         FCI*
JUSTPRT  BAL   R7,GETTIME      GO GET DATE AND TIME                FCI*
         MVC   QPUSER,QLOGON   MOVE IN USERID                      FCI*
         MVC   QPDATE,JDATE    MOVE IN DATE TIME INFO              FCI*
         MVC   QPPAGE#,QBLANK     CLEAR OUT PAGE # FIELD           FCI*
         XC    QPHEAD1(1),=X'01'  TOGGLE ASA FLAG 0-1 OR 1-0       FCI*
         CLI   QPHEAD1,C'1'    EJECT NOW SCHEDULED?                FCI*
         BNE   NOPAGE             NO..SKIP PAGE SETTING            FCI*
*                                                                  FCI*
         AP    QPPAGE,=P'1'    BUMP PAGE COUNT                     FCI*
         MVC   QPPAGE#,=X'402020202021'  MOVE IN MASK              FCI*
         ZAP   DBLWORK,QPPAGE  MOVE INTO AREA                      FCI*
         ED    QPPAGE#,DBLWORK+5   EDIT IN PAGE NUMBER             FCI*
NOPAGE   PUT   HASPPRNT,QPHEAD1  PUT OUT TITLE LINE                FCI*
         PUT   HASPPRNT,QPHEAD2  PUT OUT '-' LINE                  FCI*
*                                                                  FCI*
         MVC   QPLINE,QBLANK                   RECONSTRUCT IMAGE   FCI*
*        MVC   QPLINE(15),=C'QUEUE COMMAND -'    OF HEADER LINE    FCI*
*        MVC   QPLINE+16(L'QPRSAVE),QPRSAVE        WITHOUT 3270    FCI*
*        PUT   HASPPRNT,QPDETAIL                      CONTROL CHARS
         EJECT ,                                                   FCI*
*                                                                  FCI*
*  PUT OUT ENTIRE SCREEN OF DETAIL LINES (BLANK OR NOT)            FCI*
*                                                                  FCI*
*        MVC   QPLINE(80),QDHLINE MOVE HEADING LINE TO BUFFER     UF003
*        PUT   HASPPRNT,QPDETAIL PRINT THE LINE                   UF003
*        LH    R3,QDSCRLEN       SIZE OF SCREEN                   UF003
*        SR    R2,R2             CLEAR FOR DIVIDE                 UF003
         LH    R7,QDLNELEN       LINE LENGTH                      UF003
*        DR    R2,R7             NUMBER OF LINES                  UF003
         BCTR  R7,0              DROP LINE LEN FOR EXECUTES       UF003
*        LA    R2,QDLINE1        LOAD ADDRESS OF FIRST LINE       UF003
         LA    R2,QDSCRTXT       LOAD ADDRESS OF FIRST LINE       GP@P6
         L     R3,QDSCRPLN       GET SCREEN SIZE                  GP@P6
PUTLOOP  EX    R7,PUTMVC         MOVE LINE TO BUFFER              UF003
         TR    QPLINE,PRTXLATE   REMOVE UNPRINTABLES              GP@P6
         PUT   HASPPRNT,QPDETAIL PUT DETAIL LINE LOUT              FCI*
         LA    R2,1(R2,R7)       POINT TO NEXT LINE               UF003
*        BCT   R3,PUTLOOP        AND GRIND THE SCREEN THROUGH      FCI*
         SH    R3,QDLNELEN       ADJUST BYTES TO GO               GP@P6
         BP    PUTLOOP           AND GRIND THE SCREEN THROUGH     GP@P6
*                                                                  FCI*
*        MVC   QPLINE,QBLANK                   RECONSTRUCT IMAGE   FCI*
*        MVC   QPLINE(07),=C'REPLY -'            OF COMMAND LINE   FCI*
*        MVC   QPLINE+08(L'QDREPLY),QDREPLY        WITHOUT 3270    FCI*
*        MVC   QPLINE+72(1),QDPLUS                   CONTROL CHARS FCI*
*        PUT   HASPPRNT,QPDETAIL                       AND PRINT IT
*                                                                  FCI*
         MVI   QPDETAIL,C'-'       TRIPLE SPACE A BLANK LINE       FCI*
         MVC   QPLINE,QBLANK                                       FCI*
         PUT   HASPPRNT,QPDETAIL   AND PRINT IT                    FCI*
         MVI   QPDETAIL,C' '       RESTORE TO SINGLE SPACE         FCI*
*                                                                  FCI*
         MVC   QDTLINE+L'QDTLINE-L'PRTMSG-1(L'PRTMSG),PRTMSG       FCI*
GOTMSG   LA    R1,0               SET A ZERO                       FCI*
         L     R2,4(R13)              RETURN CODE                  FCI*
         ST    R1,16(R2)                  IN REGISTER 15 (SAVED)   FCI*
         B     STOP                                                FCI*
         SPACE 2                                                   FCI*
PUTMVC   MVC   QPLINE(*-*),0(R2)  EXECUTED MOVE                   UF003
PRTMSG   DC    C'SCREEN PRINTED'                                   FCI*
         EJECT ,                                                   FCI*
***********************************************************************
*   STOP PRINT PROCESS AND FREE HASPPRNT DDNAME                    FCI*
***********************************************************************
STOPPRT  TM    QPFLAG,HARDCPY             IS HARDCPY ON            FCI*
         BNO   STOP                       NOPE..NO WORK TO DO      FCI*
         LA    R2,HASPPRNT          BUILD                          FCI*
         LA    R1,DBLWORK                   LIST                   FCI*
         MVI   DBLWORK,X'80'              LAST ENTRY IN LIST       FCI*
         CLOSE ((2)),MF=(E,(1))           CLOSE OFF THE FILE       FCI*
         FREEPOOL (2)                     FREE THE BUFFERS TOO     FCI*
         MVC   DYNALLOC(F99LEN),F99PTR   COPY DYN FREE LIST        FCI*
         LA    R1,FREERB          RELOCATE THE LIST ADDRESSES.     FCI*
         STCM  R1,B'0111',FREEPTR+1   *                            FCI*
         LA    R1,FREETXPT            *                            FCI*
         ST    R1,FREETPTR            *                            FCI*
         LA    R1,FREETU1             *                            FCI*
         STCM  R1,B'0111',FREETXPT+1  *                            FCI*
         LA    R1,FREETU2             *                            FCI*
         STCM  R1,B'0111',FREETXPT+5  *                            FCI*
         LA    R1,FREEPTR                                          FCI*
         DYNALLOC                                                  FCI*
         NI    QPFLAG,255-HARDCPY    TURN OFF PRINT FLAG           FCI*
         MVC   QDTLINE+L'QDTLINE-L'PRTSTP-1(L'PRTSTP),PRTSTP       FCI*
         B     GOTMSG                                              FCI*
PRTSTP   DC    C'PRINT STOPPED; SYSOUT FREED FOR PRINT'            FCI*
         EJECT ,                                                   FCI*
***********************************************************************
*                                                                  FCI*
*   PARSE PRINT COMMAND                                            FCI*
*                                                                  FCI*
***********************************************************************
PARSECMD LH    R2,QDRLNG      LENGTH OF REPLY LINE                 FCI*
         OC    QDREPLY,QBLANK TRANSLATE TO UPPER CASE              FCI*
         CLC   QDREPLY,QBLANK IS THE ENTIRE REPLY BLANK?           FCI*
         BER   R7             YES. NOTHING TO PARSE..RETURN        FCI*
         MVC   FIELD,QBLANK   BLANK THE WORK FIELD                 FCI*
         MVC   OFFSET(4),=F'0' ZERO THE OFFSET AND LENGTH          FCI*
         MVC   QPOFF0(12),OFFSET INITIALIZE FIRST FIELD            FCI*
         MVC   QPOFF1(48),QPOFF0 INITIALIZE NEXT FOUR FIELDS       FCI*
         LA    R6,QPOFF4+12   ADDR PAST LAST FIELD                 FCI*
         LA    R5,QPOFF0      ADDR OF FIRST SET OF FIELDS          FCI*
         LA    R3,QDREPLY     FIRST BYTE OF REPLY LINE             FCI*
ENCORE   LA    R4,FIELD       FIRST BYTE OF WORK FIELD             FCI*
BLANK    CLI   0(R3),C' '     IS THIS BYTE BLANK?                  FCI*
         BNE   FIRST          NO. START OF FIELD.                  FCI*
         LA    R3,1(R3)       YES. SKIP IT.                        FCI*
         BCT   R2,BLANK       TRY NEXT BYTE                        FCI*
         B     EMPTY          END OF REPLY LINE.                   FCI*
FIRST    LH    R1,QDRLNG      REPLY LENGTH                         FCI*
         SR    R1,R2          COMPUTE OFFSET TO START OF FIELD     FCI*
         STH   R1,OFFSET      STORE OFFSET                         FCI*
         LR    R1,R2          SAVE COUNT OF REMAINING BYTES        FCI*
         B     CHAR           CONTINUE                             FCI*
LOOP     CLI   0(R3),C' '     IS THIS BYTE BLANK?                  FCI*
         BE    LAST           YES. END OF FIELD.                   FCI*
CHAR     MVC   0(1,R4),0(R3)  MOVE BYTE TO SUBNAME                 FCI*
         LA    R3,1(R3)       INCREMENT                            FCI*
         LA    R4,1(R4)       INCREMENT                            FCI*
         BCT   R2,LOOP        TRY NEXT BYTE                        FCI*
LAST     SR    R1,R2          COMPUTE FIELD LENGTH                 FCI*
         CH    R1,=H'8'       IS LENGTH GREATER THAN 8?            FCI*
         BNH   STORE          NO. USE IT.                          FCI*
         LA    R1,8           YES. USE LENGTH OF EIGHT.            FCI*
STORE    STH   R1,LENGTH      STORE FIELD LENGTH                   FCI*
EMPTY    MVC   0(12,R5),OFFSET MOVE FIELD TO QCOMMON               FCI*
         LTR   R2,R2          IS THE REMAINING LENGTH ZERO?        FCI*
         BZR   R7             YES. FINITO OF PARSE..RETURN         FCI*
*                                                                  FCI*
         MVC   FIELD,QBLANK   BLANK THE WORK FIELD                 FCI*
         MVC   OFFSET(4),=F'0' ZERO OUT OFFSET AND LENGTH          FCI*
         LA    R5,12(R5)      INCREMENT TO NEXT FIELD              FCI*
         CR    R5,R6          WAS THAT THE LAST FIELD?             FCI*
         BL    ENCORE         NO. PROCESS NEXT FIELD.              FCI*
         EJECT ,                                                   FCI*
***********************************************************************
* GET DATE/TIME FOR HEADING   ENTER WITH BAL R7,GETTIME            FCI*
* RETURNS WITH JDATE(LEN) = YY.DDD  HH:MM:SS DAY MTH DD,YYYY       FCI*
*                           123456789.123456789.123456789.123      FCI*
*                                                                  FCI*
***********************************************************************
***********************************************************************
*                                                                     *
* GETTIME - REWRITTEN FOR Y2K READINESS             GP@P6 22 NOV 2002 *
*                                                                     *
***********************************************************************
GETTIME  STM   R14,R12,12(R13)             SAVE REGISTERS
         MVC   JDATE(32),QBLANK            CLEAR RESIDUAL DATA
         TIME  DEC                         GET CURRENT DATE AND TIME
         STM   R0,R1,DATEAREA              STORE DATE FOR TESTING
         ST    R1,DATEAREA+8                 AND CONVERSION
         UNPK  JDATE+1(5),DATEAREA+5(3)    SHOW JULIAN DATE
         MVC   JDATE(2),JDATE+1            SHIFT YY LEFT
         MVI   JDATE+2,C'.'                PUT PERIOD IN YY.DDD
         UNPK  TIMEHRS(3),DATEAREA(2)      SHOW HOURS
         MVI   TIMEHRS+2,C':'
         UNPK  TIMMINS(3),DATEAREA+1(2)    SHOW MINUTES
         MVI   TIMMINS+2,C':'
         UNPK  TIMSECS(3),DATEAREA+2(2)    SHOW SECONDS
         MVI   TIMSECS+2,C' '
         AP    DATEAREA+4(4),=P'1900000'
         ZAP   DBLWORK,DATEAREA+4(4)
         SRP   DBLWORK,64-3,0              GET YEAR.
         OI    DBLWORK+7,X'0F'             FIX SIGN FOR UNPACK
         UNPK  CYR,DBLWORK                 SHOW 4-DIGIT YEAR
         CVB   R5,DBLWORK                  GET BINARY YEAR
         SLR   R4,R4
         D     R4,=F'100'
         ST    R4,BINYEAR                  GET YEAR OF CENTURY
         ST    R5,BINCENT                  GET CENTURY
         XC    DATEAREA(6),DATEAREA        GET JULIAN DAY IN DECIMAL
         CVB   R4,DATEAREA                 GET JULIAN DAY IN BINARY
         SLR   R1,R1
         LA    R5,MNTHTBL-6                ADJUST FOR FIRST INCREMENT
         TM    DATEAREA+9,X'01'            IF ODD THEN
         BO    NOTLEAP                                 NOT LEAP YEAR
         TM    DATEAREA+9,X'12'            TEST FOR LEAP (OK TILL 2099)
         BNM   NEXTMNTH                       IF MIXED NOT LEAP YEAR
NOTLEAP  CH    R4,=H'60'                   DDD AFTER 28TH FEBRUARY?
         BL    NEXTMNTH                    NO, LEAP YEAR IRRELEVANT
         LA    R4,1(,R4)                   YES, FUDGE DDD ACCORDINGLY
NEXTMNTH LA    R5,6(,R5)                   INCREMENT THRU MONTH TABLE
         LA    R1,1(,R1)                   INCREMENT MONTH NUMBER
         SH    R4,0(,R5)                   DECREASE NUMBER OF DAYS
         BP    NEXTMNTH                    NOT YET, TRY NEXT MONTH
         AH    R4,0(,R5)                   FOUND THE MONTH
         ST    R4,BINDAYS                  SAVE DAY OF MONTH
         CVD   R4,DBLWORK
         OI    DBLWORK+7,X'0F'
         UNPK  CDAYN(2),DBLWORK            SHOW DAY OF MONTH
         MVC   CMON(3),2(R5)               SHOW NAME OF MONTH
         BCTR  R1,0                        BEGIN ZELLER'S CONGRUENCE
         BCTR  R1,0
         LTR   R1,R1
         BP    YEAROKAY                    MONTH-2>0
         AH    R1,=H'12'
         L     R5,BINYEAR
         BCTR  R5,0
         LTR   R5,R5
         BNM   CENTOKAY                    YEAR NOT NEGATIVE
         LA    R5,99
         L     R6,BINCENT
         BCTR  R6,0
         ST    R6,BINCENT                  GET CENTURY (CC)
CENTOKAY ST    R5,BINYEAR                      YEAR (YY) AND MONTH (MM)
YEAROKAY EQU   *                               OF 2 MONTHS AGO
         M     R0,=F'26'
         BCTR  R1,0
         BCTR  R1,0
         D     R0,=F'10'                   R1 = ((MM*26)-2)/10
         L     R2,BINYEAR
         SRL   R2,2                        R2 = YY/4
         L     R3,BINCENT
         LR    R4,R3
         SRL   R3,2                        R3 = CC/4
         SLL   R4,1                        R4 = CC*2
         LR    R7,R1
         A     R7,BINDAYS
         A     R7,BINYEAR
         AR    R7,R2
         AR    R7,R3
         SR    R7,R4
         SLR   R6,R6
         LR    R1,R7                       COPY NUMERATOR
         LPR   R7,R7                       AVOID -VE DIVIDE RESULTS
         LA    R15,7                       GET DENOMINATOR
         DR    R6,R15
         LTR   R1,R1                       NEGATIVE NUMERATOR?
         BNM   MODULOOK                    NO, SO MOD(X,7)=REM(X/7)
         SR    R15,R6                      YES, ADJUST SO THAT RESULT
         LR    R6,R15                      OF MOD(_,_) IS NOT NEGATIVE
MODULOOK SLL   R6,2                        DAY OF WEEK (0=SUNDAY) BY 4
         LA    R6,DAYTBL(R6)
         MVC   CDAY(3),0(R6)               SHOW NAME OF DAY OF WEEK
         LM    R14,R12,12(R13)
         BR    R7                          RETURN
         SPACE
MNTHTBL  DC    H'31',C'JAN '
         DC    H'29',C'FEB '
         DC    H'31',C'MAR '
         DC    H'30',C'APR '
         DC    H'31',C'MAY '
         DC    H'30',C'JUN '
         DC    H'31',C'JUL '
         DC    H'31',C'AUG '
         DC    H'30',C'SEP '
         DC    H'31',C'OCT '
         DC    H'30',C'NOV '
         DC    H'99',C'DEC '             (ALLOW FOR STUPID DDD)
DAYTBL   DC    C'SUN MON TUE WED THU FRI SAT '
********       END OF GETTIME REWRITE   22NOV2002                 GP@P6
         EJECT ,                                                   FCI*
***********************************************************************
* ALLOC HARDCOPY TO HASPPRNT DDNAME                                FCI*
*                                                                  FCI*
***********************************************************************
ALLOCHC  MVC   DYNALLOC(S99LENG),S99RBPTR COPY DYN ALLOCATION LIST.
         LA    R1,P99RB           RELOCATE THE LIST ADDRESSES.     FCI*
         STCM  R1,B'0111',P99RBPTR+1  *                            FCI*
         LA    R1,P99TUPL             *                            FCI*
         ST    R1,P99TXTPP            *                            FCI*
         LA    R1,P99TUKY1            *                            FCI*
         STCM  R1,B'0111',P99TUPL+1   *                            FCI*
         LA    R1,P99TUKY2            *                            FCI*
         STCM  R1,B'0111',P99TUPL+5   *                            FCI*
         LA    R1,P99TUKY3            *                            FCI*
         STCM  R1,B'0111',P99UPLL+1   *                            FCI*
*  PROCESS PARMS..........                                         FCI*
         LH    R1,QPLNG2        GET LENGTH OF SECOND PARM          FCI*
         CH    R1,=H'1'         LENGTH OF ONE?                     FCI*
         BNE   NOCLSCHG         NO..NO CHANGE OF SYSOUT CLASS      FCI*
         CLI   QPPARM2,C'A'     IS IT ALPHA                        FCI*
         BL    NOCLSCHG                                            FCI*
         MVC   P99SYSOC,QPPARM2 MOVE IN PARM FOR SYSOUT CLASS      FCI*
NOCLSCHG CLI   QPPARM3,C' '     ANY DEST SPECIFIED                 FCI*
         BE    NODEST                                              FCI*
         MVC   P99DEST,QPPARM3  MOVE IN DEST                       FCI*
         MVC   P99DESTL,QPLNG3  MOVE IN LENGTH                     FCI*
         MVI   P99EPARM,X'00'   SAY CLASS IS NOT LAST PARM         FCI*
*  DO THE ALLOCATE                                                 FCI*
NODEST   LA    1,DYNALLOC         ADDR OF PARM LIST FOR DYNALLOC.  FCI*
         DYNALLOC                                                  FCI*
         LTR   R15,R15            CHK RETURN CODE                  FCI*
         BNZ   CANTALLC           NO CAN DO..POST MESSAGE          FCI*
         LA    R6,HASPPRNT        ADDRESS OF OUTPUT DCB.           FCI*
         USING IHADCB,R6          ADDRESSABILITY TO OUTPUT DCB.    FCI*
         LA    R1,DBLWORK         BUILD                            FCI*
         MVI   0(R1),X'80'          ONLY ENTRY IN LIST             FCI*
         OPEN  ((6),(OUTPUT)),MF=(E,(1))  OPEN THE FILE            FCI*
         TM    DCBOFLGS,X'10'     CHECK FOR SUCCESSFUL OPEN.       FCI*
         DROP  R6                 ELIMINATE DCB ADDRESSABILITY.    FCI*
         BZ    PRNTBAD            BYPASS SWITCH SETTING IF BAD OPEN.
         OI    QPFLAG,HARDCPY     INDICATE HARDCPY FILE AVAILABLE. FCI*
         MVC   QDTLINE(L'MSGSTART),MSGSTART  MOVE IN START MSG     FCI*
         MVC   M1CLASS,P99SYSOC   MOVE IN SYSOUT CLASS             FCI*
         MVC   M1DEST,P99DEST                                      FCI*
         CLI   M1DEST,C' '        ANY DEST?                        FCI*
         BNE   PRNTOKAY                                            FCI*
         MVC   M1DEST,=CL8'LOCAL' SAY LOCAL                        FCI*
         B     PRNTOKAY           BYPASS TPUT ERROR MSG.           FCI*
         EJECT ,                                                   FCI*
PRNTBAD  QTILT 'SORRY...UNABLE TO ALLOC/OPEN HASPPRNT FOR HARDCOPY'
PRNTOKAY BR    R7                 RETURN                           FCI*
         SPACE 2                                                   FCI*
MSGSTART DC    CL63'PRINT STARTED; SYSOUT=X,DEST=XXXXXXXX'         FCI*
         EJECT ,                                                   FCI*
***********************************************************************
*        FORMULATE TEXT FOR SVC99 ALLOCATE FAILURE                 FCI*
***********************************************************************
         SPACE 3                                                   FCI*
CANTALLC MVC   QDTLINE,QBLANK     CLEAR OUT LINE                   FCI*
         CLC   P99ERROR,=X'046C'  WAS IT 'RMT NOT DEF TO JES2'?    FCI*
         BE    BADRMT             YES..POST MSG AND EXIT           FCI*
*                                                                  FCI*
         MVC   QDTLINE(L'MSGERR),MSGERR                            FCI*
         CVD   R15,DBLWORK        CONVERT SVC 99 RETURN CODE       FCI*
         MVC   M2RC,=X'40202020'   TO NICE PRINTABLE DECIMAL       FCI*
         ED    M2RC,DBLWORK+6                                      FCI*
*                                                                  FCI*
         UNPK  M2ERC(5),P99ERROR(3) CONVERT DYNAM ALLOC ERR CODE   FCI*
         NC    M2ERC,HEXMASK         TO PRINTABLE HEXADECIMAL      FCI*
         TR    M2ERC,HEXTAB          AND FIX IT UP PRETTY          FCI*
         MVI   M2ERC+4,C' '                                        FCI*
*                                                                  FCI*
         UNPK  M2INFO(5),P99INFO(3) CONVERT DYNAM ALLOC INFO       FCI*
         NC    M2INFO,HEXMASK        CODE TO PRNTABLE HEX          FCI*
         TR    M2INFO,HEXTAB         AND FIX IT UP PRETTY          FCI*
         MVI   M2INFO+4,C' '                                       FCI*
         B     GOTMSG                   AND GO POST THE MESSAGE    FCI*
*                                                                  FCI*
BADRMT   MVC   QDTLINE(L'MSGNRMT),MSGNRMT  MOVE IN NO SUCH REMOTE MSG
         MVC   MREMOTE,QPPARM3         MOVE IN REMOTE ASKED FOR    FCI*
         B     GOTMSG                   AND GO POST THE MESSAGE    FCI*
         SPACE 2                                                   FCI*
HEXTAB   DC    C'0123456789ABCDEF'                                 FCI*
HEXMASK  DC    X'0F0F0F0F0F0F0F0F'                                 FCI*
MSGNRMT  DC    C'REMOTE XXXXXXXX NOT DEFINED TO JES2; PRINT BYPASSED'
MSGERR   DC    C'CANT ALLOC SYSOUT FOR PRINT; DARC= XXXX INFO= XXXX R15X
               = XXXX '                                            FCI*
***********************************************************************
         EJECT ,                                                   FCI*
         LTORG                                                     FCI*
         SPACE 2                                                   FCI*
         DS    0F                                                  FCI*
*                                          SVC 99 REQUEST BLOCK  PTR
S99RBPTR DC    X'80',AL3(S99RB)                                    FCI*
*                                          SVC 99 REQUEST BLOCK    FCI*
S99RB    DS    0F                                                  FCI*
S99RBLN  DC    AL1(20)                     LENGTH=20 BYTES         FCI*
S99VERB  DC    X'01'                       VERB CODE=01 (DSNAME ALLOC)
S99FLAG1 DC    X'1000'                     DONT USE EXISTING ALLOC FCI*
S99ERROR DC    AL2(0)                              ERROR CODE      FCI*
S99INFO  DC    AL2(0)                              INFO  CODE      FCI*
S99TXTPP DC    A(S99TUPL)                 POINTER TO TEXT UNIT POINTERS
S99RSVD1 DC    A(0)                          RESERVED              FCI*
S99FLAG2 DC    A(0)                          FLAGS 2               FCI*
S99TUPL  DC    A(S99TUKY1)                TEXT UNIT POINTERS       FCI*
S99EPARM DC    X'80',AL3(S99TUKY2)        LAST PARM IF NO DEST=    FCI*
         DC    X'80',AL3(S99TUKY3)        LAST PARM IF DEST= GIVEN FCI*
S99TUNIT DS    0F                                                  FCI*
*                                                  DDNAME=HASPPRNT FCI*
S99TUKY1 DC    X'0001',X'0001',X'0008',C'HASPPRNT'                 FCI*
*                                                  SYSOUT=A        FCI*
S99TUKY2 DC    X'0018',X'0001',X'0001'                             FCI*
         AIF   (&QRNB).RNB10A                                     RNB10
S99SYSOC DC    C'A'                                                FCI*
         AGO   .RNB10B                                            RNB10
.RNB10A  ANOP                                                     RNB10
S99SYSOC DC    C'C'                                               RNB10
.RNB10B  ANOP                                                     RNB10
*                                      OPTIONAL    DEST=RMTXXX     FCI*
S99TUKY3 DC    X'0058',X'0001'                                     FCI*
S99DESTL DC    X'0000'   LENGTH OF DEST                            FCI*
S99DEST  DC    CL8' '  DEST PARAMETER                              FCI*
*                                                                  FCI*
         DS    0D                                                  FCI*
S99LENG  EQU   *-S99RBPTR              LENGTH OF WHOLE MAGILLA     FCI*
         EJECT ,                                                   FCI*
*.....................................................................*
*.       DYNAMIC ALLOCATION REQUEST BLOCK TO FREE DDNAME HASPPRNT    .*
*.....................................................................*
         SPACE 3                                                   FCI*
         DS    0F                  GET FULLWORD BOUNDARY           FCI*
F99PTR   DC    X'80',AL3(F99RB)    THE POINTER TO THE MESS..       FCI*
*                                                                  FCI*
F99RB    DC    FL1'20'            LENGTH OF RB IN BYTES = 20       FCI*
         DC    XL1'02'            VERB CODE=X'02'..FREE BY DDN     FCI*
         DC    AL2(0)             FLAGS1..NO OPTIONS               FCI*
F99RC    DC    XL2'0000'          ERROR CODE                       FCI*
F99INFO  DC    XL2'0000'          INFO CODE                        FCI*
         DC    AL4(F99TXPT)       ADDRESS OF TEXT UNITS            FCI*
         DC    XL4'00'            RESERVED                         FCI*
         DC    XL4'00'            FLAGS2                           FCI*
         SPACE 2                                                   FCI*
F99TXPT DC     AL4(F99TU1)        ADDR OF DSN TEXT UNIT            FCI*
         DC    X'80',AL3(F99TU2) ADDR OF UNALLOC TEXT TU(LAST)     FCI*
         SPACE 2                                                   FCI*
F99TU1   DC    X'0001',X'0001',FL2'8',C'HASPPRNT' DDNAME           FCI*
F99TU2   DC    X'0007',X'0000'        UNALLOC EVEN IF PERM ALLOC   FCI*
F99LEN   EQU   *-F99PTR           LENGTH OF FILEDS                 FCI*
         SPACE 2                                                  GP@P6
PRTXLATE DC    64C' ',191AL1(*-PRTXLATE),C' '                     GP@P6
         EJECT ,                                                   FCI*
***********************************************************************
WORK     DSECT                                                     FCI*
         DS    CL76                                                FCI*
OFFSET   DS    H                                                   FCI*
LENGTH   DS    H                                                   FCI*
FIELD    DS    CL8                                                 FCI*
RPASS    DS    CL8                                                 FCI*
DBLWORK  DS    D                                                   FCI*
DATEAREA DS    3F                                                 GP@P6
BINCENT  DS    F                                                  GP@P6
BINYEAR  DS    F                                                   FCI*
BINDAYS  DS    F                                                   FCI*
WORKWORD DS    2F                                                  FCI*
***********************************************************************
* LEAVE FIELDS TOGETHER.. INITIALIZED BY ONE MVC WITH VALUES       FCI*
*                                                                  FCI*
JDATE    DC    C'XX.XXX',C'  '                           E  F      FCI*
TIMEHRS  DC    CL2' ',C':'                               A  I  T   FCI*
TIMMINS  DC    CL2' ',C':'                               V  E  O   FCI*
TIMSECS  DC    CL2' ',C' '                               E  L  G   FCI*
CDAY     DC    CL3' ',C' '                                  D  E   FCI*
CMON     DC    CL3' ',C' '                                  S  T   FCI*
CDAYN    DC    CL2' ',C','                                     H   FCI*
CYR      DC    CL4' ',C' '       4-DIGIT YEAR (GP@P6)          E   FCI*
*                                                              R   FCI*
***********************************************************************
LEN      EQU   *-JDATE                                             FCI*
         SPACE 2                                                   FCI*
         DS    0F                                                  FCI*
DYNALLOC DS    (S99LENG)XL1                                        FCI*
         ORG   DYNALLOC                                            FCI*
*                                          SVC 99 REQUEST BLOCK  PTR
P99RBPTR DC    X'80',AL3(P99RB)                                    FCI*
*                                          SVC 99 REQUEST BLOCK    FCI*
P99RB    DS    0F                                                  FCI*
P99RBLN  DC    AL1(20)                     LENGTH=20 BYTES         FCI*
P99VERB  DC    X'01'                       VERB CODE=01 (DSNAME ALLOC)
P99FLAG1 DC    X'1000'                     DONT USE EXISTING ALLOC FCI*
P99ERROR DC    AL2(0)                              ERROR CODE      FCI*
P99INFO  DC    AL2(0)                              INFO  CODE      FCI*
P99TXTPP DC    A(P99TUPL)                 POINTER TO TEXT UNIT POINTERS
P99RSVD1 DC    A(0)                          RESERVED              FCI*
P99FLAG2 DC    A(0)                          FLAGS 2               FCI*
P99TUPL  DC    A(P99TUKY1)                TEXT UNIT POINTERS       FCI*
P99EPARM DC    X'80',AL3(P99TUKY2)        LAST PARM IF NO DEST=    FCI*
P99UPLL  DC    X'80',AL3(P99TUKY3)        LAST PARM IF DEST= GIVEN FCI*
P99TUNIT DS    0F                                                  FCI*
*                                                  DDNAME=HASPPRNT FCI*
P99TUKY1 DC    X'0001',X'0001',X'0008',C'HASPPRNT'                 FCI*
*                                                  SYSOUT=A        FCI*
P99TUKY2 DC    X'0018',X'0001',X'0001'                             FCI*
P99SYSOC DC    C'A'                                                FCI*
*                                      OPTIONAL    DEST=RMTXXX     FCI*
P99TUKY3 DC    X'0058',X'0001'                                     FCI*
P99DESTL DC    X'0000'   LENGTH OF DEST                            FCI*
P99DEST  DC    CL8' '  DEST PARAMETER                              FCI*
*                                                                  FCI*
         ORG   DYNALLOC                                            FCI*
         DS    0F                  GET FULLWORD BOUNDARY           FCI*
FREEPTR  DC    X'80',AL3(FREERB)   THE POINTER TO THE MESS..       FCI*
*                                                                  FCI*
FREERB   DC    FL1'20'            LENGTH OF RB IN BYTES = 20       FCI*
         DC    XL1'02'            VERB CODE=X'02'..FREE BY DDN     FCI*
         DC    AL2(0)             FLAGS1..NO OPTIONS               FCI*
FREERC   DC    XL2'0000'          ERROR CODE                       FCI*
FREEINFO DC    XL2'0000'          INFO CODE                        FCI*
FREETPTR DC    AL4(FREETXPT)      ADDRESS OF TEXT UNITS            FCI*
         DC    XL4'00'            RESERVED                         FCI*
         DC    XL4'00'            FLAGS2                           FCI*
         SPACE 2                                                   FCI*
FREETXPT DC    AL4(FREETU1)       ADDR OF DSN TEXT UNIT            FCI*
         DC    X'80',AL3(FREETU2) ADDR OF UNALLOC TEXT TU(LAST)    FCI*
         SPACE 2                                                   FCI*
FREETU1  DC    X'0001',X'0001',FL2'8',C'HASPPRNT' DDNAME           FCI*
FREETU2  DC    X'0007',X'0000'        UNALLOC EVEN IF PERM ALLOC   FCI*
         ORG   ,                                                   FCI*
*                                                                  FCI*
SYMDEL   DSECT ,                   KILL SYM CARD GENERATION       UF023
         QCOMMON                                                   FCI*
         SPACE 2                                                   FCI*
MREMOTE  EQU   QDTLINE+7,8                                         FCI*
M2ERC    EQU   QDTLINE+35,4                                        FCI*
M2INFO   EQU   QDTLINE+46,4                                        FCI*
M2RC     EQU   QDTLINE+56,4                                        FCI*
M1CLASS  EQU   QDTLINE+22,1                                        FCI*
M1DEST   EQU   QDTLINE+29,8                                        FCI*
         EJECT ,                                                   FCI*
PRINT    CSECT                                                     FCI*
         PRINT NOGEN                                               FCI*
         DCBD  DSORG=(PS)                                          FCI*
         PRINT GEN                                                 FCI*
SYMNODEL DSECT ,                   RESTORE SYM CARD GENERATION    UF023
         END  ,                                                    FCI*
./ ADD NAME=QCOMMON  8034-02153-03046-0735-00408-00370-00000-GREG
         MACRO
         QCOMMON &CSECT=NO
         GBLB  &QPFK      PF-KEY OPTION. SEE QSTART MACRO          ICBC
         GBLB  &QSP       MVS/SP OPTION. SEE QSTART MACRO         UF020
         GBLB  &QRACF     RACF OPTION. SEE QSTART MACRO           RNB03
         GBLC  &QRACUSR   RACF USERID. SEE QSTART MACRO           RNB03
         LCLA  &RACLEN    LENGTH OF RACF USERID                   RNB03
         LCLA  &SIZE      BLOCK SIZE FOR CKPT DCB
         AIF   ('&CSECT' EQ 'YES').CSECT
         TITLE 'QUEUE COMMAND - COMMON AREA DSECT'
***********************************************************************
*                                                                     *
*   QUEUE COMMAND - COMMON AREA DSECT                                 *
*                                                                     *
***********************************************************************
QCOMMON  DSECT
.CSECT   ANOP
***********************************************************************
*                                                                     *
*   VECTOR TABLE - ADDRESSES OF AREAS IN QCOMMON                      *
*                                                                     *
***********************************************************************
QVDSPL   DC    A(QDISPLAY)    PTR TO DISPLAY WORK AREA
QVDAIR   DC    A(QDAIR)       PTR TO DAIR WORK AREA
QVCKPT   DC    A(QCKPT)       PTR TO CKPT WORK AREA
QVPRINT  DC    A(QCPRINT)     PTR TO PRINT WORK AREA               FCI*
         DC    3F'0'          SPARE POINTERS RESERVED FOR FUTURE
QFRSTSA  DC    A(0)           ADDRESS OF FIRST SAVE AREA
***********************************************************************
*                                                                     *
*   MISCELLANEOUS NUTS AND BOLTS                                      *
*                                                                     *
***********************************************************************
QDWORK   DC    D'0'           SCRATCH DOUBLE WORD                 UF009
QDWORD   DC    D'0'           SCRATCH DOUBLE WORD                 UF009
QLOGON   DC    CL8' '         LOGON ID (JOBNAME)
QCLASSH  DC    0H'0',X'00'    HALFWORD BOUNDARY
QCLASS   DC    C' '           SEARCH CLASS
QCODEH   DC    0H'0',X'00'    HALFWORD BOUNDARY
QCODE    DC    X'00'          SEARCH FUNCTION CODE
QSUBCMD  DC    A(0)           ADDR OF CURRENT SUBCOMMAND
QOFF0    DC    H'0'           OFFSET TO SUBCOMMAND
QLNG0    DC    H'0'           LENGTH OF SUBCOMMAND
QSUBNAME DC    CL8' '         NAME OF SUBCOMMAND                  UF018
QOFF1    DC    H'0'           OFFSET TO QPARM1
QLNG1    DC    H'0'           LENGTH OF QPARM1
QPARM1   DC    CL8' '         USER SUPPLIED PARAMETER #1
QOFF2    DC    H'0'
QLNG2    DC    H'0'
QPARM2   DC    CL8' '                                 #2
QOFF3    DC    H'0'
QLNG3    DC    H'0'
QPARM3   DC    CL8' '                                 #3
QOFF4    DC    H'0'
QLNG4    DC    H'0'
QPARM4   DC    CL8' '                                 #4
PF3LEVEL DC    H'0'           PF3 LEVELS BEFORE EXIT COUNT        GP@P6
PF3CMD1  DC    CL2' '         LEVEL-1 MEANING OF PF3              GP@P6
QPARM1SV DC    CL8' '         LEVEL-1 OPERAND FOR PF3             GP@P6
QXAUTH   DC    X'00'          AUTOMATIC HOLD
QFLAG1   DC    X'08'          FLAG BYTE - START WITH RESHOW GP@P6 UF009
QFLG1IOE EQU   X'80'          I/O ERROR ON SPOOL READ             UF009
QFLG1OPR EQU   X'40'          TSO OPERATOR AUTHORITY              UF010
QFLG1DBC EQU   X'20'          ESTAE ENVIRONMENT ESTABLISHED       UF024
QFLG1LCL EQU   X'10'          Q20 - SEARCHING LOCAL JOE QUE (SP3) RNB16
QFLG1RSH EQU   X'08'          Q5  - ENSURE CORRECT SCREEN SIZE    GP@P6
QFLG1APF EQU   X'04'          IN APF AUTHORISED ENVIRONMENT       GP@P6
QFLG1SEL EQU   X'02'          LINE SELECTION OR PF3/15 PERFORMED  GP@P6
QFLG1HLP EQU   X'01'          HELP PROCESSING ACTIVE              GP@P6
QFLAG2   DC    X'C0'          FLAG BYTE - START WITH EDS AND PNS  GP@P6
QFLG2EDS EQU   X'80'          USE EXTENDED DATA STREAM ORDERS     GP@P6
QFLG2PNS EQU   X'40'          USE "POINT-AND-SHOOT"               GP@P6
         DC    XL1'0'         RESERVED                            UF009
QBLANK   DC    CL132' '       132 BLANKS                          UF003
QFZONE   DC    C'0'           USED TO CLEAR QFZONES
QFZONES  DC    C'00000000'    USED FOR NUMERIC CHECK
QCOUNT   DC    PL3'0'         NUMBER OF ELEMENTS IN QUEUE
QCOUNTA  DC    PL3'0'         NUMBER OF ELEMENTS IN AWAITING QUEUE
QCOUNTE  DC    PL3'0'         NUMBER OF ELEMENTS IN EXECUTION QUEUE
QCOUNTH  DC    PL3'0'         NUMBER OF ELEMENTS IN HOLD QUEUE
QOFFS    DC    H'0'           START COLUMN FOR FIND
QOFFE    DC    H'0'           END COLUMN FOR FIND
QDELIMIT DC    C' '           DELIMITER
QRSVD    DC    XL15'0'        RSVD
QPNEXT   DC    F'0'           DATA SET JUMP DIRECTION AND COUNT   GP@P6
QPJOBID  DC    F'0'           JOB ID FOR LISTDS     ** THESE TWO FIELDS
QPDSID   DC    H'0'           DATASET ID FOR LISTDS ** MUST BE CONTIG.
QPOFFSET DC    H'0'           PRINT OFFSET FROM BEGINNING OF RECORD
QPREC    DC    PL4'0'         CURRENT RECORD COUNT
QPLNG    DC    H'0'           LENGTH OF COMPARE FIELD FOR FIND
QPFIND   DC    CL58' '        COMPARE FIELD FOR FIND
QSYSID   DC    CL8' '         SYSTEM ID TABLE
*   EACH SYSTEM ID THAT EXISTS IS LOADED FROM THE CHECKPOINT RECORD
         DC    CL8'SID1'      SYSTEM ID FOR SYSTEM 1
         DC    CL8'SID2'                           2
         DC    CL8'SID3'                           3
         DC    CL8'SID4'                           4
         DC    CL8'SID5'                           5
         DC    CL8'SID6'                           6
         DC    CL8'SID7'                           7
         EJECT
***********************************************************************
*                                                                     *
*   SAVE AREA FOR GETMAIN/FREEMAIN                                    *
*                                                                     *
***********************************************************************
QGETAREA DC    3F'0'
QGETA1   EQU   QGETAREA+0
QGETA2   EQU   QGETAREA+4
QGETA3   EQU   QGETAREA+8
QGETLNGH DC    F'65536',2F'0'
QGETL2   EQU   QGETLNGH+4
QGETL3   EQU   QGETLNGH+8
QFREE    FREEMAIN L,LA=QGETLNGH,A=QGETAREA,MF=L
***********************************************************************
*                                                                     *
*   LIST FORM OF TPUT                                                 *
*                                                                     *
***********************************************************************
QTPUT    TPUT  0,0,NOEDIT,MF=L                                    GP@P6
         EJECT
***********************************************************************
*                                                                     *
*   DATASET ALLOCATION FIELDS                                         *
*      (ADAPTED FROM SYS1.MACLIB (IKJDAPL,IKJDAP08,0C,18))            *
*                                                                     *
***********************************************************************
QDAIR    DS    0D             START OF DAIR WORK AREAS
DAIRECB  DC    F'0'           ECB USED BY DAIR
DAIRFLAG DC    X'00'          FLAG USED BY ALLOCATE SUBROUTINE
         DC    XL3'0'         DEAD SPACE FOR ALLIGNMENT
***********************************************************************
*    THE DYNAMIC ALLOCATION INTERFACE ROUTINE (DAIR) PARAMETER LIST   *
*    (DAPL) IS A LIST OF ADDRESSES PASSED FROM THE INVOKER TO DAIR    *
*    VIA REGISTER 1                                                   *
***********************************************************************
DAPLUPT  DC    A(0)     PTR TO UPT
DAPLECT  DC    A(0)     PTR TO ECT
DAPLECB  DC    A(DAIRECB) PTR TO CP'S ECB
DAPLPSCB DC    A(0)     PTR TO PSCB
DAPLDAPB DC    A(0)     PTR TO DAIR PARAMETER BLOCK
***********************************************************************
*                                                                     *
*   ALLOCATE DDNAME(W) DSNAME(X) SHR UNIT(Y) VOLUME(Z)                *
*                                                                     *
***********************************************************************
DA08CD   DC    X'0008'  DAIR ENTRY CODE
DA08FLG  DC    X'00'    FUNCTIONS TO BE PERFORMED WHEN RET CODE IS 0
         DC    X'00'
DA08DARC DC    H'0'     DYN ALLOC RETURN CODE
DA08CTRC DC    H'0'     CATALOG RETURN CODE
DA08PDSN DC    A(0)     POINTER TO DSNAME TO BE SEARCHED IN DSE
DA08DDN  DC    CL8' '   DDNAME TO BE SEARCHED IN DSE
* YOU MUST SUPPLY THE DEFAULT UNIT AND VOLUME SERIAL FOR YOUR SYSTEM
DA08UNIT DC    CL8'SYSALLDA' UNITNAME FOR SYS1.HASPCKPT
DA08SER  DC    CL8'*CKPT*  ' VOLUME SERIAL FOR SYS1.HASPCKPT
DA08BLK  DC    F'0'     DATA SET  AVERAGE RECORD LENGTH
DA08PQTY DC    F'0'     PRIMARY SPACE QUANTITY
DA08SQTY DC    F'0'     SECONDARY SPACE QUANTITY
DA08DQTY DC    F'0'     DIRECTORY BLOCK QUANTITY
DA08MNM  DC    CL8' '   MEMBER NAME
DA08PSWD DC    CL8' '   PASSWORD
DA08DSP1 DC    X'08'    DATA SET STATUS FLGS - SHR
DA08DPS2 DC    X'08'    DATA SET DISPOSITION - KEEP
DA08DPS3 DC    X'08'    DATA SET CONDITIONAL DISPOSITION - KEEP
DA08CTL  DC    X'00'    FLAGS TO CONTROL ACTIONS TAKEN BY DAIR
         DC    XL3'0'   RESERVED
DA08DSO  DC    X'00'    DSORG
DA08ALN  DC    CL8' '   ATTR-LIST-NAME                           C99236
***********************************************************************
*                                                                     *
*   FREE DDNAME(XXXXXXXX)                                             *
*                                                                     *
***********************************************************************
DA18CD   DC    X'0018'  DAIR ENTRY CODE
DA18FLG  DC    X'00'    FUNCTIONS TO BE PERFORMED WHEN RET CODE IS 0
         DC    X'00'
DA18DARC DC    H'0'     DYNAMIC ALLOCATION RETURN CODE
DA18CTRC DC    H'0'     CATALOG RETURN CODE AREA
DA18PDSN DC    A(0)     POINTER TO DSNAME TO BE SEARCHED IN DSE
DA18DDN  DC    CL8' '   DDNAME TO BE SEARCHED IN DSE
DA18MNM  DC    CL8' '   MEMBER NAME
DA18SCLS DC    CL2' '   SYSOUT CLASS DESIRED WHEN UNALLOCATING  A
*                       SYSOUT DATA SET
DA18DPS2 DC    X'08'    DATA SET DISPOSITION - KEEP
DA18CTL  DC    X'10'    FLAGS FOR SPECIAL DAIR PROCESSING
DA18JBNM DC    CL8' '   IGNORED AS OF OS VS/2 RELEASE 2       Y02670
         EJECT
***********************************************************************
*                                                                     *
*   CHECKPOINT WORK AREAS                                             *
*                                                                     *
***********************************************************************
* NOTE - BLOCKSIZES ARE INSTALLATION DEPENDENT
QCKPT    DS    0D
         AIF   (NOT &QSP).QSP1                                    UF020
QCJIXL   DC    A(0)                                               UF020
QCJIXA   DC    A(0)           ADDRESS OF JIX IOAREA               UF020
.QSP1    ANOP                                                     UF020
QCJQTA   DC    A(0)           ADDRESS OF JQT IOAREA
QCJOTA   DC    A(0)           ADDRESS OF JOT IOAREA
QCJCTA   DC    A(0)           ADDRESS OF JCT IOAREA
QCIOTA   DC    A(0)           ADDRESS OF IOT IOAREA
QCBLKA   DC    A(0)           ADDRESS OF DATASET BLOCK IOAREA
QCJQTL   DC    F'0'           ADDRESS OF FIRST CKPT REOCRD
QCJQEA   DC    A(0)           ADDR OF CURRENT JQE
QCJOTL   DC    F'0'           COUNT OF RECORDS ON CKPT DS
QCPDDB1  DC    F'0'           OFFSET IN IOT TO FIRST PDDB
QCTRAK   DS    0F             DISK ADDR IN THE FORM MTTR
QCTRAKM  DC    X'0'           EXTENT NUMBER
QCTRAKTT DC    X'0000'        ABSOLUTE TRACK NUMBER
QCTRAKR  DC    X'0'           RECORD NUMBER
         DC    X'0'           EXTRA SPACE NEEDED FOR HEX CONVERT
QCDAD    DS    0XL8           DISK ADDR IN THE FORM MBBCCHHR
QCDADM   DC    X'0'           EXTENT NUMBER
QCDADBB  DC    X'0000'        BIN NUMBER
QCDADCC  DC    X'0000'        CYLINDER NUMBER
QCDADHH  DC    X'0000'        HEAD NUMBER
QCDADR   DC    X'0'           RECORD NUMBER
         DC    XL3'0'         DEAD SPACE TO GET BACK TO FULLWORD
QCJQHEAD DC    A(0)           OFFSET TO JQE HEADERS
         DS    0F
QCCREC   DC    PL4'0'         CURRENT RECORD NUMBER
QCCPTR   DC    A(0)           CURRENT TABLE ADDRESS
QCHREC   DC    PL4'0'         HIGHEST RECORD NUMBER
QCHPTR   DC    A(0)           HIGHEST TABLE ADDRESS
QCSTART  DC    A(0)           ADDRESS OF TABLE START
QCEND    DC    A(0)           ADDRESS OF TABLE END
QCHLINE  DS    0CL80          HEADING LINE FOR LISTDS
         DC    C'JOB '
QCJNAME  DC    CL8' '         JOBNAME
         DC    C', DSID '
QCDSNO   DC    CL8' '         DATASET ID NUMBER
         DC    C', REC #       1'
         DC    CL40' '
QCLRECL  DC    H'0'           LRECL FOR SAVE
QCRECFM  DC    X'0'           RECFM FOR SAVE
QCSPOOLS DC    36F'0'         LIST OF DCBS FOR HASPACE
QCTRKCYL DC    36F'0'         LIST OF TRACKS/CYLINDER FOR EACH DCB
&SIZE    SETA  4096
HASPCKPT DCB   DDNAME=HASPCKPT,DSORG=PS,MACRF=(RCP),                   X
               RECFM=U,BLKSIZE=&SIZE
HASPACE  DCB   DDNAME=HASPACE1,DSORG=DA,MACRF=(RIC),OPTCD=A,           X
               RECFM=F
QCDCBL   EQU   *-HASPACE      LENGTH OF HASPACE DCB
QCOUT    DCB   DDNAME=HASPSAVE,DSORG=PS,MACRF=(PM),BUFL=8192
         READ  HDECB1,SF,HASPCKPT,,&SIZE,MF=L
         READ  HDECB2,DI,HASPACE,,0,0,QCDAD,MF=L
QCOPEN   OPEN  (QCOUT,OUTPUT),MF=L
HOCKPT   OPEN  (HASPCKPT),MF=L
***********************************************************************
*                                                                  FCI*
*   PRINT WORKAREA                                                 FCI*
*                                                                  FCI*
***********************************************************************
QCPRINT  DS    0D                                                  FCI*
QPOFF0   DC    H'0'           OFFSET TO SUBCOMMAND                 FCI*
QPLNG0   DC    H'0'           LENGTH OF SUBCOMMAND                 FCI*
QPSUBNME DC    CL8'PRINT'     NAME OF SUBCOMMAND                   FCI*
QPOFF1   DC    H'0'           OFFSET TO QPPARM1                    FCI*
QPLNG1   DC    H'0'           LENGTH OF QPPARM1                    FCI*
QPPARM1  DC    CL8' '         USER SUPPLIED PARAMETER #1           FCI*
QPOFF2   DC    H'0'                                                FCI*
QPLNG2   DC    H'0'                                                FCI*
QPPARM2  DC    CL8' '                                 #2           FCI*
QPOFF3   DC    H'0'                                                FCI*
QPLNG3   DC    H'0'                                                FCI*
QPPARM3  DC    CL8' '                                 #3           FCI*
QPOFF4   DC    H'0'                                                FCI*
QPLNG4   DC    H'0'                                                FCI*
QPPARM4  DC    CL8' '                                 #4           FCI*
QPHEAD1  DC    CL1'1'                                              FCI*
*        123456789.123456789.123456789.123456789.'                 FCI*
 DC CL40'QUEUE HARDCOPY LOG  USER=XXXXXXXX  DATE='                 FCI*
 DC CL40'YY.DDD  HH:MM:SS DAY MON DD,19XX   XXXXX'                 FCI*
 DC CL52' '                                                       UF003
         ORG   QPHEAD1+26                                          FCI*
QPUSER   DS    CL8           FOR USERID                            FCI*
         ORG   QPHEAD1+41                                          FCI*
QPDATE   DS    CL32                                                FCI*
         ORG   QPHEAD1+75                                          FCI*
QPPAGE#  DS    CL6                                                 FCI*
         ORG   ,                                                   FCI*
QPHEAD2  DS    0CL81                                               FCI*
         DC    C' ',80C'-'                                         FCI*
         DC    52C' '                                             UF003
QPDETAIL DC    CL1' '         ASA CONTROL CHARACTER                FCI*
QPLINE   DC    CL132' '       TO HOLD PRINT LINE                  UF003
QPPAGE   DC    PL3'1'                                              FCI*
QPFLAG   DC    XL1'00'                                             FCI*
HARDCPY  EQU   X'80'                                               FCI*
QPRSAVE  DS    CL63           SAVE AREA TO HOLD SUBTITLE INFO      FCI*
QPPWORK  DC    6F'0'          SPARE WORK ZONE                      FCI*
         DS    0F                                                  FCI*
*HASPPRNT DCB  DDNAME=HASPPRNT,DSORG=PS,MACRF=(PM),                FCI*
*              RECFM=FA,LRECL=133,BLKSIZE=133                     UF003
HASPPRNT DCB   DDNAME=HASPPRNT,DSORG=PS,MACRF=(PM),                FCI*X
               RECFM=FA,LRECL=133,BLKSIZE=133                     UF003
         AIF   (NOT &QRACF).RNB03A                                RNB03
******************************************************************RNB03
*                                                                *RNB03
*   RACF FIELDS                                                  *RNB03
*                                                                *RNB03
******************************************************************RNB03
&RACLEN  SETA  K'&QRACUSR       LENGTH OF NEW RACF USERID         RNB03
QNEWUSR  DC    AL1(&RACLEN),CL8'&QRACUSR'  NEW USERID             RNB03
QUSRSAV  EQU   *,9                         OLD USERID             RNB03
         DC    AL1(0),CL8' '               OLD USERID             RNB03
QRACNMXP DC    CL8'QUEUEXP'       ENTITY FOR RACHECK FOR XP CMD   RNB03
QRACNMXD DC    CL8'QUEUEXDS'      ENTITY FOR RACHECK FOR XDS CMD  RNB03
QRACHECK RACHECK ENTITY=QRACNMXP,CLASS='APPL',ATTR=READ,          RNB03X
               APPL=QRACNMXP,MF=L                                 RNB03
.RNB03A  ANOP                                                     RNB03
***********************************************************************
*                                                                     *
*   PARAMETER LIST FOR CB3270                         GP@P6 JUNE 2002 *
*                                                                     *
***********************************************************************
QDCBPRM1 DC    A(QDLENGTH)    POINTER TO DATA STREAM LENGTH FULLWORD
QDCBPRM2 DC    A(QDSCRPLN)    POINTER TO SCREEN SIZE FULLWORD
QDCBPRM3 DC    A(QDOUTPUT)    POINTER TO START OF INPUT DATA STREAM
QDCBPRM4 DC    A(QDOUTPUT)    POINTER TO START OF OUTPUT DATA STREAM
         EJECT
***********************************************************************
*                                                                     *
*   DISPLAY WORK FIELDS                                               *
*                                                                     *
***********************************************************************
QDISPLAY DS    0D             START OS DISPLAY WORK AREA
QDGTRM   GTTERM PRMSZE=QDPRMSZ,ALTSZE=QDALTSZ,ATTRIB=QDATTRB,     GP@P6+
               TERMID=QDTRMID,MF=L                                GP@P6
QDPRMSZ  DC    X'1850'        PRIMARY SIZE                        GP@P6
QDALTSZ  DC    X'1850'        ALTERNATE SIZE                      GP@P6
QDATTRB  DC    F'0'           TERMINAL ATTRIBUTES                 GP@P6
QDTRMID  DC    CL16' '        TERMINAL IDENTIFIER                 GP@P6
QDOSZR0  DC    F'0'           ORIG SCREEN DEPTH                   UF003
QDOSZR1  DC    F'0'           ORIG SCREEN LINESZ                  UF003
QDLNELEN DC    H'80'          LENGTH OF DISPLAY LINE              UF003
QDLNES   DC    PL2'21'        LINES PER SCREEN                    UF003
QDSCRLEN DC    A(21*80)       LENGTH OF DISPLAY AREA        GP@P6 UF003
QDSCRPLN DC    A(24*80)       LENGTH OF SHADOWED BUFFER     GP@P6 UF003
QDLENGTH DC    A(24*80+10)    LENGTH OF OUTPUT DATA STREAM        GP@P6
QDSHADO@ DC    A(QDSHADOW)    ADDRESS OF SHADOW BUFFER            GP@P6
         DS    0D                                                 UF003
         AIF   (NOT &QPFK).PFK1
PFREPLY  DS    0CL256                                        GP@P6 ICBC
PFCODE   DC    CL6' '                                              ICBC
PFTXT    DC    CL63' '                                             ICBC
         DC    CL187' '       SELECTION CODE BUFFER EXTENSION     GP@P6
.PFK1    ANOP
QDISPTYP DC    X'00'          DISPLAY TYPE FOR SELECTION CODES    GP@P6
QDXI     EQU   X'04'          INITIATOR/TERMINATOR LIST (XI)      GP@P6
QDDC     EQU   X'03'          ACTIVE ADDRESS SPACE LIST (DC)      GP@P6
QDDD     EQU   X'02'          DD LIST                             GP@P6
QDJQ     EQU   X'01'          JQE/JOE LIST                        GP@P6
QDNA     EQU   X'00'          OTHER (SHOULDN'T GET SELECTION CODE)GP@P6
QDPLUS@  DC    A(0)           ADDRESS OF "MORE" DISPLAY INDICATOR
QDHLINE@ DC    A(0)           ADDRESS OF HEADING LINE
QDLINE1@ DC    A(0)           ADDRESS OF MESSAGE AREA
QDMSGA   DC    A(0)           ADDRESS OF MESSAGE TO BE DISPLAYED
QDMLNG   DC    H'0'           MESSAGE LENGTH
QDMSG    DC    CL80' '        WORK AREA FOR BUILDING OUTPUT LINE
QDRLNG   DC    H'4'           REPLY LENGTH                        UF018
QDREPLY  DC    CL63'STATUS'   TERMINAL USER REPLY           GP@P6 UF018
         DC    C' '           RESERVED
QDNEXT   DC    H'0'           CURRENT LINE NUMBER ON SCREEN
         DS    0D             PREFER QDSCRTXT DOUBLEWORD ALIGNED  GP@P6
QDOVER   DC    X'00'          PAGE OVERFLOW INDICATOR
QDLNCODE DC    X'05'          SHADOW CODE FOR LINE                GP@P6
QDSCREEN DS    0H             DISPLAY SCREEN
         DC    X'27'          CONTROL                             UF003
QDSCRO1  DC    X'F5'          VTAM WRITE COMMAND (WRT/EW/EWA)     UF003
         DC    X'C1114040'    START FROM TOP LEFT CORNER
QDSCRTXT DC    CL15'QUEUE COMMAND -' TITLE LINE
         DC    X'0B'          HIGH INTENSITY INPUT FIELD
QDTLINE  DC    CL63' '        ECHO PREVIOUS COMMAND
         DC    X'0C'          LOW INTENSITY OUTPUT FIELD
* MAKE REST OF DATA DS (DEFINE STORAGE) INSTEAD OF DC (DEFINE CONSTANT)
* TO REDUCE THE SIZE OF THE OBJECT DECK.  THE METHOD OF STATIC SCREEN
* BUFFERS USED HERE MEANS THAT THE SIZE OF THIS AREA INCREASES THREE
* TIMES THE MAXIMUM SUPPORTED SCREEN SIZE INCREASE.    2003-02-14 GP@P6
         DC    CL80' '        FINISH REST OF TOP 160-COLUMN LINE  GP@P6
         DS    61CL160        62BY160 IS LARGEST SUPPORTED SCREEN GP@P6
QDLINEND EQU   *              END OF LINE BUFFERS                 UF003
QDSLNG   EQU   *-QDSCREEN     LENGTH OF SCREEN BUFFER
         DS    XL4            ROOM FOR TRAILING SBA AND IC ORDERS
         SPACE
***********************************************************************
*                                                                     *
*   SCREEN DISPLAY SHADOW AREA                        GP@P6 JUNE 2002 *
*                                                                     *
***********************************************************************
         DS    0D
QDSHADOW DS    62CL160        UP TO 9920 LOCATIONS     2003-02-14 GP@P6
         SPACE
***********************************************************************
*                                                                     *
*   TPUT DATA STREAM BUFFER                           GP@P6 JUNE 2002 *
*                                                                     *
***********************************************************************
*
*  THE 3270 DATA STREAM CONSTRUCTION AREA BELOW NEEDS TO HAVE ENOUGH
*  CAPACITY TO HOLD THE UNOPTIMISED DATA STREAM WHICH WILL CONTAIN
*  MORE BYTES THAN THE SCREEN SIZE.  THE DATA STREAM IS OPTIMISED IN
*  IN PLACE BEFORE TRANSMISSION.
*
QDOUTPUT DS    80CL160        OPTIMISED 3270 DATA STREAM OUTPUT AREA
         MEND
./ ADD NAME=QHEAD    8006-02166-03045-1456-00022-00013-00000-GREG
         MACRO
&NAME    QHEAD &MSGVAR,&ATTR,&TYP=0,&SEL=N,&DMY=N
&NAME    L     R15,QVDSPL          LOAD BASE REG
         USING QDISPLAY,R15        BASE REG FOR DISPLAY WORK AREA
         L     R14,QDHLINE@        POINT TO HEADING LINE
         MVC   0(80,R14),&MSGVAR
         L     R14,QDSHADO@        POINT TO THE SHADOW BUFFER
         AH    R14,QDLNELEN        POINT TO HEADING LINE SHADOW
         MVI   0(R14),&ATTR        SUPPLY HEADING CHARACTER ATTRIBUTES
         MVC   1(79,R14),0(R14)
         MVI   QDISPTYP,&TYP       SET SELECTION CODE DISPLAY TYPE
         MVI   QDLNCODE,X'05'      SET DATA DISPLAY TO TURQUOISE
         DROP  R15
         AIF   ('&DMY' EQ 'Y').MEND
         AIF   ('&SEL' NE 'Y').SELOK
         TM    QFLAG1,QFLG1SEL     LINE SELECTION OR PF3/15?
         BO    *+8                 YES, DO NOT RESET "PF3 LEVEL"
.SELOK   ANOP
         MVI   PF3LEVEL+1,0        RESET "PF3 LEVEL" FOR NEW COMMAND
         NI    QFLAG1,255-QFLG1SEL RESET LINE SELECTION FLAG
.MEND    ANOP
         MEND
./ ADD NAME=QPRBGEN
         MACRO ,                                                  ONL01 00010000
&LABEL   QPRBGEN &TYPE                                            ONL01 00020000
         GBLB  &QBGEN                                             ONL01 00030000
         AIF   ('&TYPE' EQ 'BEGIN').BEGIN                         ONL01 00040000
         AIF   ('&TYPE' EQ 'DONE').DONE                           ONL01 00050000
         MNOTE 4,'PRTGENB MACRO - INVALID OPERAND'                ONL01 00060000
         MEXIT ,                                                  ONL01 00070000
.BEGIN   ANOP  ,                                                  ONL01 00080000
         PUSH  PRINT               SAVE CURRENT PRINT STATUS      ONL01 00090000
         AIF   (&QBGEN).GEN                                       ONL01 00100000
         PRINT NOGEN               DON'T EXPAND CNTL BLOCK MACROS ONL01 00110000
         MEXIT ,                                                  ONL01 00120000
.GEN     ANOP  ,                                                  ONL01 00130000
         PRINT GEN                 EXPAND CNTL BLOCK MACROS       ONL01 00140000
         MEXIT ,                                                  ONL01 00150000
.DONE    ANOP  ,                                                  ONL01 00160000
         POP   PRINT               RESTORE PRINT STATUS           ONL01 00170000
         MEND  ,                                                  ONL01 00180000
./ ADD NAME=QSTART
         MACRO
&NAME    QSTART &TITLE,&MAIN=NO,&TYPE=NORMAL
***********************************************************************
*                                                                     *
*   GLOBAL FLAG DEFINITIONS                                           *
*                                                                     *
***********************************************************************
         GBLB  &QPFK          PF-KEY OPTION (SEE Q5 AND Q8)
         GBLB  &QACF2         ACF2 AUTH CHECKING (SEE Q6 AND Q14)  FCI*
         GBLB  &QSP           MVS/SP LEVEL OF JES2.               UF020
         GBLB  &QGEN          FORCE PRINT GEN OF MACRO EXPANSIONS UF019
         GBLB  &QJTIP         JTIP PRODUCT INSTALLED (Q33)        UF025
         GBLB  &QDBC          DBC  PRODUCT INSTALLED              UF024
         GBLB  &QRNB          ENABLES RNB-SPECIFIC CODE           RNB05
.*                              (Q4,Q5,Q14,Q16,Q24,Q26,Q27)       RNB05
         GBLB  &QRACF         RACF CHECKING (QCOMMON,Q10,Q16,Q17) RNB03
         GBLC  &QRACUSR       NEW RACF USERID (QCOMMON,Q10)       RNB03
.*                                                                UF019
.* QPFK=0 SELECTS NO PF-KEY SUPPORT
.* QPFK=1 SELECTS PF=KEY SUPPORT
.*QACF2=0 SELECTS NO ACF2 CHECKING (SHOPS WITHOUT ACF2)            FCI*
.*QACF2=1 SELECTS ACF2 AUTH TO SYSOUT VIA DSN='SYSOUT.LID.JOBNAME' FCI*
.*  QSP=0 SELECTS PRE-SP SUPPORT                                  UF020
.*  QSP=1 SELECTS SP SUPPORT                                      UF020
.* QGEN=0 SELECTS PRINT NOGEN OPTION                              UF019
.* QGEN=1 SELECTS PRINT GEN OPTION                                UF019
.*QJTIP=0 SELECTS NO JTIP SUPPORT.                                UF025
.*QJTIP=1 SELECTS SHOPS WITH JTIP INSTALLED                       UF025
.* QDBC=0 SELECTS NO DBC SUPPORT.                                 UF024
.* QDBC=1 SELECTS SHOPS WITH DBC INSTALLED                        UF024
.*QRACF=0 SELECTS NO RACF SUPPORT                                 RNB03
.*QRACF=1 SELECTS RACF SUPPORT FOR ACCESS TO THE SPOOL/CHECKPOINT RNB03
.*        AND FOR THE XP AND XDS COMMANDS. DEFINE TWO RACF        RNB03
.*        RESOURCES IN CLASS(APPL): QUEUEXP WILL CONTROL THE XP   RNB03
.*        COMMAND AND QUEUEXDS WILL PROVIDE FURTHER CONTROL OVER  RNB03
.*        THE XDS COMMAND. WHEN THE RACHECK FOR THE XDS COMMAND   RNB03
.*        IS DONE, THE JOBNAME WILL BE SPECIFIED AS THE APPLID.   RNB03
.*        THUS, IF YOU SPECIFY AUDIT(ALL) FOR APPL-QUEUEXDS YOU   RNB03
.*        WILL KNOW WHAT DATA YOUR PRIVILEGED USERS HAVE BEEN     RNB03
.*        EXAMINING (AUDITORS LIKE THIS). QRACF IS NOT SUPPORTED  RNB03
.*        VIA THE SYSPARM OPTION.                                 RNB03
.*QRACUSR IS USED IF YOUR SPOOL AND CHECKPOINT ARE DEFINED TO     RNB03
.*        RACF WITH UACC=NONE. IT SPECIFIES A USERID THAT HAS     RNB03
.*        ACCESS TO THE SPOOL AND CHECKPOINT WITH READ AUTHORITY. RNB03
.*        DURING INITIALIZATION, THE SPECIFIED USERID WILL BE     RNB03
.*        SUBSTITUTED INTO THE RACF ACEE SO THE USER OF QUEUE HAS RNB03
.*        ACCESS TO THE SPOOL AND CHECKPOINT DATA SETS ONLY WHILE RNB03
.*        THE QUEUE COMMAND IS IN PROGRESS. IF QRACF=1, THEN      RNB03
.*        QRACUSR MUST BE SPECIFIED. IF YOUR SPOOL AND CHECKPOINT RNB03
.*        HAVE A UACC OF >= READ, SPECIFY QRACUSR AS NULL ('') TO RNB03
.*        BYPASS CHANGING THE ACEE USERID. QRACUSR IS NOT         RNB03
.*        SUPPORTED VIA THE SYSPARM OPTION.                       RNB03
.*                                                                UF019
&QPFK    SETB  1
&QACF2   SETB  0                                                   FCI*
&QSP     SETB  0                                                  UF020
&QGEN    SETB  1                                                  UF019
&QJTIP   SETB  0                                                  UF025
&QDBC    SETB  0                                                  UF024
&QRNB    SETB  0                                                  RNB05
&QRACF   SETB  0                                                  RNB03
&QRACUSR SETC  'QCMD'                                             RNB03
.*                                                                UF019
         LCLA  &CNT,&CTR,&STRNG,&LNTH,&SUB                        UF019
         AIF   (K'&SYSPARM EQ 0).SYSPEND                          UF019
         MNOTE *,'SYSPARM IS ''&SYSPARM'' '                       UF019
         AIF   ('&SYSPARM'(1,1) EQ '(').MORE                      UF019
  MNOTE 2,'SYSPARM SYNTAX ERROR--MUST BE ENCLOSED IN PARENS'      UF019
         AGO   .SYSPEND                                           UF019
.MORE    ANOP                                                     UF019
&CNT     SETA  K'&SYSPARM                                         UF019
&CTR     SETA  1                                                  UF019
&STRNG   SETA  &CTR+1                                             UF019
.LOOP    AIF   ('&SYSPARM'(&CTR,1) EQ ',' OR &CTR EQ &CNT).FOUND  UF019
&CTR     SETA  &CTR+1                                             UF019
         AGO   .LOOP                                              UF019
.FOUND   ANOP                                                     UF019
&LNTH    SETA  &CTR-&STRNG                                        UF019
         AIF   (&LNTH EQ 0).NULL                                  UF019
         AIF   ('&SYSPARM'(&STRNG,&LNTH) NE 'PFK').SPNPFK         UF019
&QPFK    SETB  1                                                  UF019
.SPNPFK  AIF   ('&SYSPARM'(&STRNG,&LNTH) NE 'NOPFK').SPNPFK2      UF019
&QPFK    SETB  0                                                  UF019
.SPNPFK2 AIF   ('&SYSPARM'(&STRNG,&LNTH) NE 'ACF2').SPNACF        UF019
&QACF2   SETB  1                                                  UF019
.SPNACF  AIF   ('&SYSPARM'(&STRNG,&LNTH) NE 'NOACF2').SPNACF2     UF019
&QACF2   SETB  0                                                  UF019
.SPNACF2 AIF   ('&SYSPARM'(&STRNG,&LNTH) NE 'SP').SPNSP           UF019
&QSP     SETB  1                                                  UF019
.SPNSP   AIF   ('&SYSPARM'(&STRNG,&LNTH) NE 'NOSP').SPNSP2        UF019
&QSP     SETB  0                                                  UF019
.SPNSP2  AIF   ('&SYSPARM'(&STRNG,&LNTH) NE 'GEN').SPNGEN         UF019
&QGEN    SETB  1                                                  UF019
.SPNGEN  AIF   ('&SYSPARM'(&STRNG,&LNTH) NE 'NOGEN').SPNGEN2      UF019
&QGEN    SETB  0                                                  UF019
.SPNGEN2 ANOP                                                     UF019
         AIF   ('&SYSPARM'(&STRNG,&LNTH) NE 'JTIP').SPNJTIP       UF019
&QJTIP   SETB  1                                                  UF019
.SPNJTIP AIF   ('&SYSPARM'(&STRNG,&LNTH) NE 'NOJTIP').SPNJTP2     UF019
&QJTIP   SETB  0                                                  UF019
.SPNJTP2 ANOP                                                     UF019
         AIF   ('&SYSPARM'(&STRNG,&LNTH) NE 'DBC').SPNDBC         UF019
&QDBC    SETB  1                                                  UF019
.SPNDBC  AIF   ('&SYSPARM'(&STRNG,&LNTH) NE 'NODBC').SPNDBC2      UF019
&QDBC    SETB  0                                                  UF019
.SPNDBC2 ANOP                                                     UF019
.NULL    ANOP                                                     UF019
         AIF   (&CTR EQ &CNT).SYSPEND                             UF019
&CTR     SETA  &CTR+1                                             UF019
&STRNG   SETA  &CTR                                               UF019
         AGO   .LOOP                                              UF019
.SYSPEND ANOP                                                     UF019
         AIF   ('&TYPE'  EQ 'GLOBAL').GEN  FORCE PRINT GEN FOR QCOMMON
         AIF   (&QGEN).GEN                                        UF019
         PRINT NOGEN                                              UF019
         AGO   .START                                             UF019
.GEN     PRINT GEN                                                UF019
.START   ANOP                                                     UF019
***********************************************************************
 MNOTE *,'PFK=&QPFK, ACF2=&QACF2, SP=&QSP, GEN=&QGEN, JTIP=&QJTIP, DBC=+
               &QDBC, RACF=&QRACF, RACUSR=&QRACUSR '              RNB03
***********************************************************************
&NAME    START 0
***********************************************************************
*                                                                     *
*   REGISTER USAGE TABLE                                              *
*                                                                     *
***********************************************************************
R0       EQU   0              TEMP WORK
R1       EQU   1              TEMP WORK
R2       EQU   2              WORK REG
R3       EQU   3              WORK REG
R4       EQU   4              WORK REG
R5       EQU   5              WORK REG
R6       EQU   6              WORK REG
R7       EQU   7              WORK REG
R8       EQU   8              WORK REG
R9       EQU   9              ADDRESS OF COMMON SUB-AREA
R10      EQU   10             ADDRESS OF COMMON SUB-AREA
R11      EQU   11             ADDRESS OF COMMON VECTOR TABLE
R12      EQU   12             BASE REGISTER
R13      EQU   13             SAVE AREA AND TEMPORARY WORK AREA
R14      EQU   14             TEMP WORK
R15      EQU   15             TEMP WORK
***********************************************************************
*                                                                     *
*   THE QUEUE COMMAND WAS WRITTEN FOR YOUR AMUSEMENT AND AMAZEMENT BY *
*     THE INTERGALACTIC MESSIANIC INDIVIDUAL GROUP THERAPY DIVISION   *
*     OF TRW SYSTEMS, 1 SPACE PARK, REDONDO BEACH, CA. 90278          *
*   THE ORIGINAL PROGRAMMING WAS DONE BY ANDY ZIDE, CHIEF PROGRAMMER  *
*     AND RESIDENT FLAKE WHO HAS SINCE DEPARTED TRW TO PLAY WITH      *
*     MICROCODE.                                                      *
*   PLEASE ADDRESS ANY COMMENTS, SUGGESTIONS, COMPLAINTS, OR THREATS  *
*     TO STEVE ANDERSON (R3/1028)   (213) 535-0682   OR               *
*        PAUL FELIX     (R3/1028)   (213) 535-0682                    *
*                                                                     *
*   STEVE ANDERSON HAS LEFT TRW.  PLEASE ADDRESS ANY COMMENTS OR      *
*   FIXES TO JACK SCHUDEL AT THE ADDRESS LISTED BELOW.                *
*                                                                     *
***********************************************************************
*                                                                     *
*   THE FOLLOWING INDIVIDUALS HAVE MADE MODIFICATIONS TO QUEUE WHICH  *
*     HAVE BEEN INCORPORATED INTO THIS CURRENT VERSION.               *
*                                                                     *
*        VILKO MACEK                                                  *
*        INSURANCE CORPORATION OF BRITISH COLUMBIA                    *
*        MODIFICATION: PFK SUPPORT                                    *
*                                                                     *
*        TRW ISD                                                      *
*        ANAHEIM, CALIFORNIA                                          *
*        MODIFICATION: DISPLAY CPU TIME FOR BATCH, STC AND TSO        *
*                      DISPLAY INITIATORS                             *
*                                                                     *
*        KEN TRUE                                                     *
*        FAIRCHILD CAMERA AND INSTRUMENT                              *
*        MOUNTAIN VIEW, CALIFORNIA                                    *
*        MODIFICATION: ACF2 SUPPORT                                   *
*                      PRINT SCREEN SUPPORT                           *
*                                                                     *
*        JACK SCHUDEL                                                 *
*        NORTHEAST REGIONAL DATA CENTER                               *
*        233 SSRB, UNIVERSITY OF FLORIDA                              *
*        GAINESVILLE, FLORIDA  32611                                  *
*        (904) 392-4601                                               *
*        MODIFICATIONS:  SEE MEMBER $UFDOC                            *
*                                                                     *
*        WALT FARRELL                                                 *
*        RAINIER NATIONAL BANK                                        *
*        P. O. BOX C34030                                             *
*        SEATTLE, WASHINGTON  98124                                   *
*        (206) 433-7467                                               *
*        MODIFICATIONS:  SEE MEMBER $RNBDOC                           *
*                                                                     *
***********************************************************************
*
         AIF   ('&TYPE' EQ 'NORMAL').GO
         MEXIT
.GO      ANOP
&NAME    TITLE &TITLE
         USING *,R12          BASE REGISTER
         USING QCOMMON,R11    ACCESS TO COMMON VECTOR TABLE
         STM   R14,R12,12(R13) STANDARD REGISTER SAVE
         LR    R12,R15        LOAD BASE REG
         B     *+28           BRANCH AROUND IDENTIFIER
         DC    CL8'&NAME'     MODULE IDENTIFIER
         DC    CL8'&SYSDATE'  ASSEMBLY DATE
         DC    CL8' &SYSTIME'  ASSEMBLY TIME
         AIF   ('&MAIN' EQ 'YES').MAINYES
         LR    R15,R13        RETAIN SAVE AREA ADDR
         LA    R13,72(R13)    POINT TO NEXT SAVE AREA
         AGO   .MAINNO
.MAINYES ANOP
         LR    R2,R1          SAVE PARAMETER REGISTER
         GETMAIN R,LV=4096    GET STORAGE FOR SAVEAREA
         ST    R1,8(R13)      FORWARD POINTER
         ST    R13,4(R1)      BACKWARD POINTER
         LR    R13,R1         MOVE ADDR TO R1
         MEXIT
.MAINNO  ANOP
         ST    R13,8(R15)     FORWARD POINTER
         ST    R15,4(R13)     BACKWARD POINTER
         MEND
./ ADD NAME=QSTOP    8001-02166-02166-0024-00009-00009-00000-GREG
         MACRO
&NAME    QSTOP &MAIN=NO
&NAME    L     R13,4(R13)     LOAD NEXT LOWER SAVE AREA SET
         LM    R14,R12,12(R13) STANDARD REGISTER RESTORE
         AIF   ('&MAIN' NE 'YES').MAINOK
         SLR   R15,R15        ZERO RETURN CODE
.MAINOK  ANOP
         BR    R14            RETURN TO CALLER
         MEND
./ ADD NAME=QTILT    8002-02166-03045-1456-00016-00016-00000-GREG
         MACRO
&NAME    QTILT &MESSAGE
&NAME    L     R15,QVDSPL     LOAD BASE REG
         USING QDISPLAY,R15   BASE REG FOR DISPLAY WORK AREA
         L     R14,QDHLINE@   POINT TO HEADING LINE
         MVC   0(80,R14),=CL80&MESSAGE
         MVC   QDMLNG,=H'0'   ZERO MESSAGE LENGTH
         L     R14,QDSHADO@   POINT TO THE SHADOW BUFFER
         AH    R14,QDLNELEN   POINT TO HEADING LINE SHADOW
         MVI   0(R14),X'22'   RED REVERSE VIDEO FOR ERROR MESSAGE
         MVC   1(79,R14),0(R14)
         DROP  R15
         L     R15,=V(DISPLAY) ADDR OF DISPLAY MODULE
         LR    R14,R15        SET FOR LOOP
         BR    R15            GO TO IT
         MEND
./ ADD NAME=QUEUE    8019-02166-03046-0714-00211-00197-00000-GREG
QUEUE    QSTART 'QUEUE COMMAND - MAINLINE MODULE',MAIN=YES
***********************************************************************
* RNB CHANGES:                                                        *
*      (1) RNB01 - FIX FINAL TPUT MESSAGE TO WORK WITH SPF TCAM       *
*                                                                     *
***********************************************************************
***********************************************************************
*                                                                     *
*   CALL - INITIALIZATION                                             *
*                                                                     *
***********************************************************************
         L     R15,=V(INIT)   ADDR OF INIT
         BALR  R14,R15        GO TO IT
         LA    R10,LOOP       INTERRUPTED RETURN ADDRESS
         USING QDISPLAY,R9    BASE REG FOR DISPLAY WORK AREA
         L     R9,QVDSPL      LOAD BASE REG
         USING WORK,R13       BASE REG FOR LOCAL WORK AREA
******************************************************************UF003
*                                                                 UF003
*   INITIALIZE 3270 SCREEN VARIABLES                              UF003
*                                                                 UF003
******************************************************************UF003
         GTSIZE ,             READ 3270 SCREEN SIZE               UF003
         STM   R0,R1,QDOSZR0  SAVE FOR LATER RESTORE              UF003
         LTR   R0,R0          DISPLAY DEVICE?                     UF003
         BZ    NOTDISP        NO, ABORT                           UF003
         SPACE 1                                                  UF003
         STFSMODE ON,INITIAL=YES  TELL VTAM ABOUT FULLSCREEN MODE UF003
         SPACE 1                                                  UF003
         GTTERM PRMSZE=QDPRMSZ,ALTSZE=QDALTSZ,ATTRIB=QDATTRB,     GP@P6+
               TERMID=QDTRMID,MF=(E,QDGTRM)  GET VTAM DETAILS     GP@P6
         SPACE 1                                                  GP@P6
         LM    R0,R1,QDOSZR0  RESTORE DESTROYED REGS              UF003
         MVI   QDSCRO1,X'7E'  ERASE/WRITE ALTERNATE               UF003
         CLM   R0,1,QDPRMSZ   PRIMARY SIZE LINE COUNT?            GP@P6
         BNE   MODELOK        NO, USE ALTERNATE SIZE              GP@P6
         CLM   R1,1,QDPRMSZ+1 PRIMARY SIZE COLUMN COUNT?          GP@P6
         BNE   MODELOK        NO, USE ALTERNATE SIZE              GP@P6
*        STSIZE SIZE=80,LINE=24 2003-02-05 ALL STSIZES REMOVED BY GP@P6
         MVI   QDSCRO1,X'F5'  ERASE/WRITE FOR PRIMARY SIZE        UF003
         SPACE 1                                                  UF003
*              REDO MODEL CODE                       2002-06-16   GP@P6
MODELOK  STH   R1,QDLNELEN    LINE LENGTH                             *
         LA    R1,QDSCRTXT+80      POINT TO COLUMN 81      2003-02-14 *
         MVC   2(7,R1),=X'E4A2859989847E'      C'USERID='  2003-02-14 *
         MVC   9(8,R1),QLOGON      DISPLAY USERID          2003-02-14 *
         MVC   19(9,R1),=X'E3859994899581937E' C'TERMINAL='2003-02-14 *
         MVC   28(8,R1),QDTRMID    DISPLAY TERMINAL NAME   2003-02-14 *
         LR    R15,R0         GET SCREEN LINE COUNT                   *
         SH    R15,=H'3'      GET DETAIL DISPLAY LINE COUNT           *
         CVD   R15,CONVERT    MAKE DECIMAL                            *
         ZAP   QDLNES,CONVERT DETAIL LINE COUNT      2003-02-05       *
         MH    R0,QDLNELEN    GET SCREEN DISPLAY CHARACTER COUNT      *
         ST    R0,QDSCRPLN    LENGTH OF BUFFER WITH SHADOW BUFFER     *
         MH    R15,QDLNELEN   GET DISPLAY DETAIL CONTENT CAPACITY     *
         ST    R15,QDSCRLEN   LENGTH TO CLEAR FOR EACH DISPLAY        *
         LR    R15,R0         GET SCREEN BUFFER SIZE                  *
         SH    R15,QDLNELEN   GET CAPACITY LESS ONE SCREEN LINE       *
         LA    R1,QDSCRTXT(R15)                                       *
         MVC   0(7,R1),=C'REPLY -'                                    *
         MVI   7(R1),X'0B'    HIGH INTENSITY INPUT FIELD              *
         XC    8(63,R1),8(R1) CLEAR INPUT AREA                        *
         MVI   71(R1),X'0C'   LOW INTENSITY OUTPUT FIELD              *
         LA    R1,72(,R1)     POINT TO PLUS SIGN INDICATOR AREA       *
         ST    R1,QDPLUS@     SAVE ITS ADDRESS                        *
         LA    R1,QDSCRTXT    POINT TO FIRST SCREEN LINE              *
         AH    R1,QDLNELEN    POINT TO SECOND SCREEN LINE             *
         ST    R1,QDHLINE@    SAVE HEADING LINE ADDRESS               *
         AH    R1,QDLNELEN    POINT TO THIRD SCREEN LINE              *
         ST    R1,QDLINE1@    SAVE FIRST DATA LINE ADDRESS            *
         L     R1,QDSHADO@    POINT TO THE SHADOW AREA                *
         MVI   0(R1),X'07'    TOP LEFT TEXT IN WHITE                  *
         MVC   1(14,R1),0(R1)                                         *
         MVI   16(R1),X'02'   COMMAND ECHO IN RED                     *
         MVI   80(R1),X'06'   YELLOW USERID+TERMINAL       2003-02-14 *
         AR    R1,R15         POINT TO SHADOW OF LAST LINE            *
         MVI   0(R1),X'07'    PROMPT IN WHITE                         *
         MVC   1(6,R1),0(R1)                                          *
         MVI   8(R1),X'32'    INPUT AREA IN RED UNDERSCORE            *
         MVC   9(62,R1),8(R1)                                         *
         MVI   72(R1),X'07'   PLUS SIGN IN WHITE IF SHOWN             *
         MVI   73(R1),X'06'   PF3/15 MEANING IN YELLOW IF SHOWN       *
         MVC   74(6,R1),73(R1)                                        *
*       END OF REDO MODEL CODE                       2002-06-16   GP@P6
         SPACE 1                                                  UF003
         B     LOOP           GO TO PROCESS LOOP                  UF003
         SPACE 1                                                  UF003
NOTDISP  LA    R1,NOTDSPL     POINT TO MESSAGE TEXT               GP@P6
         LA    R0,L'NOTDSPL   SET MESSAGE LENGTH                  GP@P6
         TPUT  (1),(0),R      SEND MESSAGE TO USER                GP@P6
         B     EXIT2          AND RETURN TO CALLER                UF003
         SPACE 1                                                  UF003
NOTDSPL  DC    C'QUEUE COMMAND REQUIRES DISPLAY TERMINAL'         UF003
         EJECT ,                                                  UF003
***********************************************************************
*                                                                     *
*   CALL - COMMAND LINE PARSE                                         *
*                                                                     *
***********************************************************************
LOOP     DS    0H                                                 UF006
         L     R15,=V(PARSE)  ADDR OF PARSE
         BALR  R14,R15        GO TO IT
         CLC   =C'E ',QSUBNAME STOP?
         BE    EXIT           YES.
         CLC   =C'EXIT ',QSUBNAME STOP?
         BE    EXIT           YES.
         CLC   =C'END ',QSUBNAME STOP?
         BE    EXIT           YES.
         CLC   =C'STOP ',QSUBNAME STOP?
         BE    EXIT           YES.
***********************************************************************
*                                                                     *
*   CALL - SUB-COMMAND MODULE SELECTED BY PARSE                       *
*                                                                     *
***********************************************************************
         QHEAD DUMMY,X'26',DMY=Y   NO OUTPUT IN YELLOW REVERSE    GP@P6
         L     R15,QSUBCMD    ADDR OF SUBCMD FROM QCOMMON
         BALR  R14,R15        GO TO IT
         MVC   QDMLNG,=H'0'   ZERO OUT MESSAGE LENGTH
         L     R15,=V(DISPLAY) ADDR OF DISPLAY MODULE
         BALR  R14,R15        WRITE LAST SCREEN, GET NEXT INPUT
         B     LOOP           DO IT AGAIN
***********************************************************************
*                                                                     *
*   CLEAN UP AND GO HOME                                              *
*                                                                     *
***********************************************************************
EXIT     DS    0H             2003-02-05 - ALL STSIZES REMOVED BY GP@P6
*        STSIZE SIZELOC=QDOSZR1,LINELOC=QDOSZR0  RESTORE SCRSIZE  UF003
********                      2003-02-05 - REMOVE NEEDLESS TPUT   GP@P6
**       MVI   QDSCRO1,X'7E'  SET ERASE/WRITE ALTERNATE           GP@P6
**       CLI   QDOSZR0+3,24   MORE THAN 24 LINES?                 GP@P6
**       BH    EXITSZOK       YES, USER ALTERNATE SIZE            GP@P6
**       CLI   QDOSZR1+3,80   MORE THAN 80 COLUMNS?               GP@P6
**       BH    EXITSZOK       YES, USER ALTERNATE SIZE            GP@P6
**       MVI   QDSCRO1,X'F5'  SET ERASE/WRITE (PRIMARY)           GP@P6
**ITSZOK LA    R1,QDSCREEN    POINT TO DATA STREAM                GP@P6
**       LA    R0,3           GET LENGTH OF ESC,EW(A),WCC         GP@P6
**       ICM   R1,8,=X'03'    SET FLAGS FOR FULLSCR               GP@P6
**       TPUT  (1),(0),R      CLEAR AND RESET THE SCREEN          GP@P6
********                      2003-02-05 - REMOVE NEEDLESS TPUT   GP@P6
         STLINENO LINE=1,MODE=OFF                 OFF FULLSCR     UF003
         USING QCKPT,R8 BASE REG FOR CKPT WORK AREA
EXIT2    DS    0H                                                 UF003
         L     R8,QVCKPT      LOAD BASE REG
         CLOSE MF=(E,HOCKPT)
         CLOSE MF=(E,QCSPOOLS)
         TM    QPFLAG,HARDCPY         IS HARDCOPY INVOKED?         FCI*
         BNO   FREEUP                   NO..SPLIT THIS STUFF       FCI*
         L     R15,=V(PRINT)               INVOKE PRINT            FCI*
         MVC   QDREPLY,QBLANK                  TO                  FCI*
         MVC   QDREPLY(09),=C'PRINT OFF'          FREE UP          FCI*
         MVC   QDRLNG,=X'0009'                        HARDCOPY     FCI*
         BALR  R14,R15                                     OUTPUT  FCI*
         EJECT
***********************************************************************
*                                                                  FCI*
*   FREE HASPCKPT AND HASPACEN DDNAMES BEFORE LEAVING TO BE NEAT.. FCI*
*                                                                  FCI*
***********************************************************************
FREEUP   MVI   DAIRFLAG,X'18'    INDICATE FREE DDNAME(XXXXXXXX)    FCI*
         MVC   DA18DDN,HASPCKPT+40  GET DDNAME USED...             FCI*
         L     R15,=V(ALLOCATE)  GET ROUTINE NAME                  FCI*
         BALR  R14,R15           GO FREE IT..                      FCI*
*
         LA    R2,QCSPOOLS       GET ADDR OF LIST OF HASPACE DCBS  FCI*
         LA    R4,35             MAX OF 35 PASSES THROUGH HERE..   FCI*
FREEUP1  L     R3,0(R2)          GET ADDRESS OF DCB TO WORK ON     FCI*
         LTR   R3,R3             ANYONE THERE?                     FCI*
         BZ    EXITQCK                                             FCI*
         MVC   DA18DDN,40(R3)    MOVE IN DDNAME FROM DCB           FCI*
         L     R15,=V(ALLOCATE)  GET ROUTINE NAME                  FCI*
         BALR  R14,R15           AND GO INVOKE DAIR TO FREE IT..   FCI*
         LA    R2,4(R2)          BUMP                              FCI*
         BCT   R4,FREEUP1                                          FCI*
***********************************************************************
*                                                                     *
*   FREE THE AREAS ACQUIRED IN INIT (Q3)                              *
*                                                                     *
***********************************************************************
EXITQCK  OI    QGETL3,X'80'   PREPARE FOR FREEMAIN             PWF FCI*
         FREEMAIN MF=(E,QFREE)
         TM    QFLAG1,QFLG1DBC    NEED TO TERMINATE ESTAE?        UF024
         BZ    NOESTAE            NO, SKIP THIS                   UF024
         ESTAE 0                  DELETE CURRENT ESTAE            UF024
         NI    QFLAG1,255-QFLG1DBC  CLEAR FLAG                    UF024
NOESTAE  DS    0H                                                 UF024
         QSTOP MAIN=YES           ZERO THE RETURN CODE            GP@P6
***********************************************************************
*                                                                     *
*   CONSTANTS AND OTHER ODDITIES                                      *
*                                                                     *
***********************************************************************
         LTORG
CLEAR1   EQU   *                   START OF CLEAR DATA            UF003
*        DC    X'27F5C1'           ESC; ERASE/WRITE; RESET MDT    UF003
         DC    X'C1'               FIX FOR SPF/TCAM               RNB01
         DC    X'115D7E'           SBA  24,80                     UF003
         DC    X'114040'           SBA  1,1                       UF003
         DC    X'3C404000'         RTA  1,1 WITH NULLS            UF003
         DC    X'1DC8'             SF, INTENSIFIED                UF003
         DC    X'13'               INSERT CURSOR                  UF003
CLEAR    EQU   CLEAR1,*-CLEAR1                                    UF003
DUMMY    DC    CL80'    NO DATA IS AVAILABLE FOR YOUR REQUEST'
SYMDEL   DSECT ,                   KILL SYM CARD GENERATION       UF023
         QCOMMON
WORK     DSECT
         DS    CL72
CONVERT  DS    D
SYMNODEL DSECT ,                   RESTORE SYM CARD GENERATION    UF023
         END
./ ADD NAME=QUEUECMN
QCOMMON  TITLE 'QUEUE COMMAND - COMMON AREA'                      UF004
QCOMMON  QSTART TYPE=GLOBAL
         QCOMMON CSECT=YES
         END
./ ADD NAME=READSPC  8001-02166-03045-1458-00093-00093-00000-GREG
READSPC  QSTART 'QUEUE COMMAND - READ A BLOCK FROM HASPACE'
***********************************************************************
* RNB CHANGES:                                                        *
*      (1) RNB03 - WITH RACF SUPPORT, WHEN A JCT IS READ WIPE OUT THE *
*                  PASSWORD FIELDS (JCTPASS, JCTNUPAS)                *
***********************************************************************
         GBLB  &QRACF                                             RNB03
         USING QCKPT,R10      BASE REG FOR CKPT WORK AREA
         L     R10,QVCKPT     LOAD BASE REG
***********************************************************************
*                                                                     *
*   CONVERT MTTR TO MBBCCHHR                                          *
*                                                                     *
***********************************************************************
*
* NOTE - THE INPUT TO THIS ROUTINE IS AS FOLLOWS:
*            QCTRAK CONTAINS THE MTTR
*            R1 CONTAINS THE IOAREA ADDRESS
*
         LR    R2,R1          MOVE IOAREA ADDR TO R2
         SR    R3,R3          ZERO R3
         IC    R3,QCTRAKM     RELATIVE DCB NUMBER
         SLL   R3,2           MULTIPLY BY 4
         MVC   QCDADR,QCTRAKR MOVE RECORD NUMBER
         MVC   QCDADHH,QCTRAKTT MOVE TRACK TO A HALFWORD BOUNDARY
         LH    R5,QCDADHH     LOAD RELATIVE TRACK NUMBER
         SR    R4,R4          ZERO R4
         D     R4,QCTRKCYL(R3) DIVIDE TRACKS BY TRACKS PER CYLINDER
         STH   R4,QCDADHH     STORE HEAD NUMBER
         STH   R5,QCDADCC     STORE CYLINDER NUMBER
         L     R3,QCSPOOLS(R3) DCB ADDRESS
         USING IHADCB,R3      ADDRESSING FOR DCB DSECT            UF009
         MVC   DCBSYNAD+1(3),=AL3(SYNAD)  SET SYNAD ADDR IN DCB   UF009
         DROP  R3             DROP ADDRESSING FOR DCB             UF009
         READ  HDECB2,DI,(R3),(R2),MF=E
         CHECK HDECB2
         TM    QFLAG1,QFLG1IOE  I/O ERROR?                        UF009
         BZ    QSTOP          NO, RETURN TO CALLER                UF009
         NI    QFLAG1,255-QFLG1IOE  CLEAR ERROR FLAG              UF009
*        SIMULATE QTILT ACTION                                    UF009
         L     R15,QVDSPL     LOAD BASE REG                       GP@P6
         USING QDISPLAY,R15   BASE REG FOR DISPLAY WORK AREA      GP@P6
         L     R14,QDSHADO@   POINT TO SHADOW BUFFER              GP@P6
         AH    R14,QDLNELEN   POINT TO HEADING SHADOW             GP@P6
         MVI   0(R14),X'22'   RED REVERSE VIDEO FOR ERROR         GP@P6
         MVC   1(79,R14),0(R14)                                   GP@P6
         DROP  R15                                                GP@P6
         L     R15,=V(DISPLAY) ADDR OF DISPLAY MODULE             UF009
         LR    R14,R15        SET FOR LOOP                        UF009
         BR    R15            GO TO IT                            UF009
QSTOP    EQU   *                                                  RNB03
         AIF   (NOT &QRACF).RNB03A                                RNB03
         USING JCTDSECT,R2    SEE IF WE READ A JCT                RNB03
         CLC   JCTID,=CL4'JCT'  POSSIBLE JCT?                     RNB03
         BNE   RNB03C           /NO  - GO QSTOP                   RNB03
         CLC   JCTJNAME,JCTJMRJN  JOB NAME IN BOTH PLACES?        RNB03
         BNE   RNB03C             /NO  - GO QSTOP                 RNB03
         CLC   =C'JOB ',JCTJOBID  IS IT AN STC, A JOB, OR A TSU?  RNB03
         BE    RNB03B             IF SO, ASSUME THIS IS A JCT     RNB03
         CLC   =C'TSU ',JCTJOBID                                  RNB03
         BE    RNB03B                                             RNB03
         CLC   =C'STC ',JCTJOBID                                  RNB03
         BNE   RNB03C                                             RNB03
RNB03B   XC    JCTPASS,JCTPASS    WIPE OUT THE PASSWORDS          RNB03
         XC    JCTNUPAS,JCTNUPAS                                  RNB03
         DROP  R2                                                 RNB03
RNB03C   EQU   *                                                  RNB03
.RNB03A  ANOP                                                     RNB03
         QSTOP                                                    RNB03
SYNAD    SYNADAF ACSMETH=BDAM DECODE ERROR CAUSE                  UF009
         OI    QFLAG1,QFLG1IOE  SET I/O ERROR FLAG                UF009
         L     R15,QVDSPL     LOAD BASE REG                       UF009
         USING QDISPLAY,R15   BASE REG FOR DISPLAY WORK AREA      UF009
         MVC   QDMLNG,=H'0'   ZERO MESSAGE LENGTH                 UF009
         L     R15,QDHLINE@   POINT TO HEADING LINE               GP@P6
         DROP  R15                                                UF009
         MVC   0(80,R15),QBLANK BLANK MESSAGE AREA          GP@P6 UF009
         MVC   1(78,R15),50(R1) COPY SYNAD MESSAGE          GP@P6 UF009
         SYNADRLS ,           RELEASE WORK AREA                   UF009
         BR    R14            RETURN TO OP SYS                    UF009
         LTORG
SYMDEL   DSECT ,                   KILL SYM CARD GENERATION       UF023
         AIF   (NOT &QRACF).RNB03X                                RNB03
READSPC  CSECT                                                    RNB03
JCT      EQU   0                                                  RNB03
BUFSTART EQU   0                                                  RNB03
BUFDSECT EQU   0                                                  RNB03
         $JCT                                                     RNB03
.RNB03X  ANOP                                                     RNB03
         QCOMMON
         DCBD  DSORG=DA,DEVD=DA                                   UF009
SYMNODEL DSECT ,                   RESTORE SYM CARD GENERATION    UF023
         END
./ ADD NAME=RELINK
//RELINK JOB ,JACK,CLASS=9,MSGCLASS=A
/*JOBPARM Q=F,I
//LINK   EXEC  PGM=IEWL,PARM='TEST,LIST,LET,NCAL,XREF,MAP'
//SYSPRINT DD  SYSOUT=A
//SYSUT1   DD  UNIT=VIO3350,SPACE=(CYL,(3,3))
//SYSLMOD  DD  DSN=JES2.SP2.LINKLIB,DISP=SHR
//SYSLIB   DD  DSN=NER.S685.PGMLIB,DISP=SHR
//SYSLIN   DD  *
 INCLUDE SYSLIB(Q2)
 ENTRY   QUEUE
 NAME    QUEUE(R)
/*
./ ADD NAME=REPOS    8016-02167-03046-0659-00354-00295-00000-GREG
REPOS    QSTART 'QUEUE COMMAND - DATASET REPOSITIONING ROUTINES'
         USING QCKPT,R10      BASE REG FOR CKPT WORK AREA
         L     R10,QVCKPT     LOAD BASE REG
         USING QDISPLAY,R9    BASE REG FOR DISPLAY WORK AREA
         L     R9,QVDSPL      LOAD BASE REG
         USING WORK,R13       BASE REG FOR LOCAL WORK AREA
***********************************************************************
*                                                                     *
*   BRANCH TO PROPER ROUTINE                                          *
*                                                                     *
***********************************************************************
         CLC   QCODEH,=H'32'  NEED TO CHECK FOR VALID DATA SET?   GP@P6
         BH    GO             NO, SO PROCEED                      GP@P6
         SPACE 1                                                  UF003
CHKID    CLC   QPDSID,=H'0'   IS THERE A VALID DATASET?
         BNE   GO             YES. GO AHEAD.
         QTILT '*** YOU ARE NOT PROCESSING A VALID DATASET ***'
GO       LH    R1,QCODEH      LOAD FUNCTION CODE
         CH    R1,=H'44'      IS THE FUNCTION SUPPORTED?
         BH    STOP           NO. RETURN.
         B     *+4(R1)        BRANCH TO ROUTINE
         B     TILT           0 OFFSET
         B     FIND           4
         B     FINDTIME       8
         B     COLUMN         12
         B     AT             16
         B     PLUS           20
         B     MINUS          24
         B     TOP            28
         B     BOTTOM         32
         B     MODEL          36                            GP@P6 UF003
         B     MONO           40                                  GP@P6
         B     COLOR          44                                  GP@P6
TILT     QTILT '*** PARAMETER IS INVALID OR OMITTED ***'
***********************************************************************
*                                                                     *
*   REPOSITION VERTICALLY                                             *
*                                                                     *
***********************************************************************
* SKIP FORWARD
PLUS     CLI   QPARM1,C' '    DEFAULT NEEDED
         BNE   PLUS010        NO
         MVI   QLNG1+1,X'01'  YES, SET LENGTH OF PARM
         MVI   QPARM1,X'F1'   SET DEFAULT TO 1
PLUS010  CLI   QPARM1,C'M'    FORWARD MAXIMUM?                   GP/MAH
         BE    BOTTOM         -> YES - PRETEND COMMAND WAS 'BOTTOM' MAH
         BAL   R4,NUMERIC     VALIDATE PARAMETER
         AP    QPREC,COUNT    ADD COUNT TO CURRENT RECORD
         B     RESUME         CALL LISTDS
* SKIP BACKWARD
MINUS    CLI   QPARM1,C' '    DEFAULT NEEDED
         BNE   MINUS010       NO
         MVI   QLNG1+1,X'01'  YES, SET LENGTH OF PARM
         MVI   QPARM1,X'F1'   SET DEFAULT TO 1
MINUS010 CLI   QPARM1,C'M'    BACK MAXIMUM?                      GP/MAH
         BE    TOP            -> YES - PRETEND COMMAND WAS 'TOP' GP/MAH
         BAL   R4,NUMERIC     VALIDATE PARAMETER
         SP    QPREC,COUNT    SUBTRACT COUNT FROM CURRENT RECORD
         BP    RESUME         CALL LISTDS IF RESULT POSITIVE.
* TOP OF DATASET
TOP      ZAP   QPREC,=P'1'    SET CURRENT RECORD TO TOP OF DS
* RESUME AT CURRENT RECORD
RESUME   L     R15,=V(LISTDS) ADDR OF LISTDS MODULE
         BALR  R14,R15        GO TO IT
STOP     QSTOP
* BOTTOM OF DATASET
BOTTOM   ZAP   QPREC,=P'9999999' SET CURRENT RECORD TO LARGEST
         MVI   QCODE,32       TELL LISTDS DOWN MAX = BOTTOM       GP@P6
         B     RESUME         CALL LISTDS
* POSITION TO THIS RECORD
AT       BAL   R4,NUMERIC     VALIDATE PARAMETER
         ZAP   QPREC,COUNT    INDICATE REPOSITION NO
         B     RESUME         CALL LISTDS
* CHECK THE PARMETER FOR VALID NUMERIC AND PACK IT
NUMERIC  LH    R2,QLNG1       LENGTH OF PARM
         SH    R2,=H'1'       IS THE COUNT FIELD ZERO?
         BM    RESUME         YES. RESUME FROM CURRENT POSITION.
         CLI   QPARM1,C'P'    FULL PAGE SPACING?                 GP/MAH
         BE    FOUNDPG        -> YES - MULIPLY BY PAGESIZE       GP/MAH
         CLI   QPARM1,C'H'    HALF PAGE SPACING?                 GP/MAH
         BE    FOUNDHF        -> YES - MULIPLY BY HALFPAGESIZE   GP/MAH
         MVC   QFZONES,QFZONE INITIALIZE NUMERIC CHECK
         EX    R2,MVZ         MOVE THE ZONES FOR VALIDITY CHECK
         CLC   QFZONES,QFZONE IS THE FIELD NUMERIC?
         BNE   TILT           NO. TILT.
         EX    R2,PACK        PACK THE FIELD INTO COUNT
         CLI   QSUBNAME,C'P'  ?/PAGE FORWARD/BACKWARD SPECIFIED
         BE    FOUNDP         YES. GO PROCESS
         CLI   QSUBNAME,C'H'  ?/HALF PAGE FORWARD/BACKWARD SPECIFIED
         BNE   NEXIT          NO. GO TO EXIT
         MP    COUNT,QDLNES   YES. MULTIPLY BY PAGE SIZE          UF003
FOUNDH   DP    COUNT,=P'2'    AND CONVERT TO HALF PAGES           UF003
         ZAP   COUNT,COUNT(7) RE-ALIGN THE STUPID FIELD           UF003
         B     NEXIT
FOUNDHF  ZAP   COUNT,QDLNES   SET SCROLL AMOUNT TO PAGE SIZE      GP@P6
         B     FOUNDH         NOW GO HALVE IT                     GP@P6
FOUNDP   MP    COUNT,QDLNES   YES. MULTIPLY BY PAGE SIZE          UF003
         B     NEXIT                                              GP@P6
FOUNDPG  ZAP   COUNT,QDLNES   SET SCROLL AMOUNT TO PAGE SIZE      GP@P6
NEXIT    BR    R4             RETURN
* EXECUTED INSTRUCTIONS
MVZ      MVZ   QFZONES(1),QPARM1 CHECK FOR NUMERIC
PACK     PACK  COUNT,QPARM1(1) PACK COUNT
***********************************************************************
*                                                                     *
*   REPOSITION HORIZONTALLY                                           *
*                                                                     *
***********************************************************************
COLUMN   CLI   QPARM1,C' '    ?/DEFAULT NEEDED
         BE    COL010         YES, GO SET IT
         CLI   QPARM1,C'0'    ?/SET COLUMN TO 1
         BNE   COL020         NO, TEST IF NUMERIC
COL010   MVI   QLNG1+1,X'01'  SET LENGTH OF PARM
         MVI   QPARM1,X'F1'   SET COLUMN TO 1
COL020   BAL   R4,NUMERIC     VALIDATE PARAMETER
         CP    COUNT,=P'255'  IS THE COUNT FIELD TOO BIG?
         BH    TILT           YES. TILT.
         SP    COUNT,=P'1'    COLUMN RELATIVE TO ZERO
         BM    TILT           INVALID. TILT.
         CVB   R5,COUNT       CONVERT TO BINARY
         STH   R5,QPOFFSET    STORE IN QPOFFSET
         B     RESUME         CALL LISTDS
***********************************************************************
*                                                                     *
*   LOCATE SPECIFIC RECORD                                            *
*                                                                     *
***********************************************************************
FIND     CLI   QSUBNAME+1,C'A' IS THE REQUEST FOR FIND ALL?
         BE    FIND2          YES. DO NOT UPDATE RECORD POINTER.
         AP    QPREC,=P'1'    START SEARCH AT NEXT RECORD
FIND2    CLI   QPARM1,C' '    IS THERE A PARAMETER?
         BE    RESUME         NO. CONTINUE WITH PREVIOUS FIND.
         LA    R2,QDREPLY+62  END OF USER REPLY
         LA    R3,61          MAXIMUM LENGTH OF PARM
         SH    R3,QOFF1       OFFSET TO FIRST PARM
LOOP     CLC   0(1,R2),QPARM1 IS THIS THE DELIMITER?
         BE    FOUND          YES. CONTINUE.
         BCTR  R2,0           TRY THE PREVIOUS BYTE
         BCT   R3,LOOP        IS THE LENGTH FIELD EXHAUSTED?
         B     TILT           YES. TILT.
FOUND    BCTR  R3,0           DECREMENT LENGTH BY 1
         LA    R2,QDREPLY+1   ADDR OF REPLY + 1
         AH    R2,QOFF1       ADDR OF FIRST BYTE OF PARM
         EX    R3,MVC         MOVE PARM TO QPFIND
         STH   R3,QPLNG       SAVE LENGTH-1 OF PARM
         B     COLTEST        TEST IF COLUMN KEYWORD IS PRESENT
MVC      MVC   QPFIND(1),0(R2) MOVE PARM TO QPFIND
***********************************************************************
*                                                                     *
*    COLUMN RANGE FOR FIND                                            *
*                                                                     *
***********************************************************************
COLTEST  XC    QOFFS,QOFFS    RESET COLUMN OFFSETS
         XC    QOFFE,QOFFE
         LA    R2,3(R2,R3)    PREPARE FOR NEXT FIELD
         LA    R3,QDREPLY+55  END OF USER REPLY
LOOP1    CLC   0(3,R2),=CL3'COL'  ?/COLUMN PARAMETER
         BE    FOUNDA         YES. GO PROCESS
         LA    R2,1(R2)       NO. LOOK AT NEXT FIELD
         CR    R2,R3          ?/END OF REPLY
         BH    RESUME         YES. EXIT
         B     LOOP1          NO. CHECK AGAIN
FOUNDA   LA    R2,3(R2)       NEXT FIELD
         CLI   0(R2),C'('     ?/LP PRESENT
         BNE   PRESUME        NO. EXIT
         LA    R2,1(R2)       NEXT FIELD
         LA    R3,QDREPLY+62  END OF REPLY
         LR    R5,R2          SAVE START OF THIS FIELD
         MVI   QDELIMIT,C','  LOOKING FOR DELIMETER = ','
         BAL   R7,CHKDEL      GO CHECK THE DELIMETER
         CVB   R6,COUNT       CONVERT START COLUMN OFFSET TO BINARY
         LTR   R6,R6          ?/USER SPECIFY OFFSET OF ZERO
         BZ    PRESUME        YES. GO INDICATE AN ERROR
         BCTR  R6,0           DECREMENT OFFSET BY 1
         STH   R6,QOFFS       SAVE START COLUMN
         LA    R2,1(R2)       NEXT FIELD
         LR    R5,R2          SAVE START OF THIS FIELD
         MVI   QDELIMIT,C')'  LOOKING FOR DELIMETER = ')'
         BAL   R7,CHKDEL      GO CHECK THE DELIMETER
         CVB   R6,COUNT       CONVERT END COLUMN OFFSET TO BINARY
         LTR   R6,R6          ?/USER SPECIFY OFFSET OF ZERO
         BZ    PRESUME        YES. GO INDICATE AN ERROR
         BCTR  R6,0           DECREMENT OFFSET BY 1
         STH   R6,QOFFE       SAVE END COLUMN
         CLC   QOFFS,QOFFE    ?/ERROR IN COLUMN SPECIFICATION
         BNL   PRESUME        YES. DISREGARD COLUMN SEARCH
         B     RESUME         NO. CONTINUE WITH NORMAL PROCESSING
CHKDEL   CLC   0(1,R2),QDELIMIT ?/DELIMITER FOUND
         BE    CHK010         YES. GO PROCESS
         LA    R2,1(R2)       NO. LOOK AT NEXT FIELD
         CR    R2,R3          ?/END OF REPLY
         BH    PRESUME        YES. EXIT
         B     CHKDEL         NO. CHECK AGAIN
CHK010   LR    R4,R2          SAVE DELIMITER ADDRESS
         SR    R4,R5          LENGTH OF SUB-PARM
         CH    R4,=H'3'       ?/LENGTH TO LONG
         BNL   PRESUME        YES. DISREGARD COLUMN SEARCH
         BCTR  R4,0           LENGTH FOR EXEC INTRUCTION
         MVC   QFZONES,QFZONE  NUMERIC TEST
         EX    R4,MVZ1
         CLC   QFZONES,QFZONE ?/FIELD NUMERIC
         BNE   TILT           NO. EXIT WITH ERROR MESSAGE
         EX    R4,PACK1
         BR    R7
PRESUME  XC    QOFFS,QOFFS    DISREGARD FIND
         XC    QOFFE,QOFFE       BY COLUMN RANGE
         QTILT ' *** ERROR IN COLUMN SPECIFICATION ***'
MVZ1     MVZ   QFZONES(1),0(R5)
PACK1    PACK  COUNT,0(1,R5)
***********************************************************************
*                                                                     *
*   REPOSITION IN SYSLOG DATASET BY TIME OF DAY                       *
*                                                                     *
***********************************************************************
FINDTIME CLI   QPARM1,C' '    IS THE PARM OMITTED?
         BE    TILT           YES. TILT.
         B     RESUME         CALL LISTDS
         EJECT                                                    UF003
******************************************************************UF003
*                                                                 UF003
*   SWITCH MODEL TYPE FOR 3270 TERMINAL                           UF003
*                                                                 UF003
******************************************************************UF003
MODEL    DS    0H             ,                                   UF003
         GTTERM PRMSZE=QDPRMSZ,ALTSZE=QDALTSZ,ATTRIB=QDATTRB,     GP@P6+
               TERMID=QDTRMID,MF=(E,QDGTRM)  HANDLE RECONNECT     GP@P6
         CLC   QLNG1,=H'1'    SINGLE CHARACTER OPERAND?           GP@P6
         BNE   MODELBAD       NO, UNSUPPORTED MODEL               GP@P6
         CLI   QPARM1,C'2'    MODEL 2?                      GP@P6 UF003
         BE    MODEL2         YES, BRANCH                         UF003
         CLI   QPARM1,C'3'    MODEL 3?                      GP@P6 UF003
         BE    MODEL3         YES, BRANCH                         UF003
         CLI   QPARM1,C'4'    MODEL 4?                      GP@P6 UF003
         BE    MODEL4         YES, BRANCH                         UF003
         CLI   QPARM1,C'5'    MODEL 5?                      GP@P6 UF003
         BE    MODEL5         YES, BRANCH                         UF003
         CLI   QPARM1,C'X'    MODEL X?                            GP@P6
         BE    MODELX         YES, BRANCH                         GP@P6
MODELBAD QTILT 'UNSUPPORTED MODEL TYPE'                           UF003
         SPACE 1                                                  UF003
*              REDO MODEL CODE                       2002-06-16   GP@P6
*              REMOVE ALL STSIZE MACROS              2003-02-05   GP@P6
MODEL2   MVI   QDSCRO1,X'F5'       ERASE/WRITE                        *
****     STSIZE SIZE=80,LINE=24    SET SCREEN SIZE FOR VTAM           *
         LA    R1,80               SCREEN WIDTH                       *
         LA    R0,24               SCREEN DEPTH                       *
         B     MODELN              JOIN COMMON CODE                   *
MODEL3   MVI   QDSCRO1,X'7E'       ERASE/WRITE ALTERNATE              *
****     STSIZE SIZE=80,LINE=32    SET SCREEN SIZE FOR VTAM           *
         LA    R1,80               SCREEN WIDTH                       *
         LA    R0,32               SCREEN DEPTH                       *
         B     MODELN              JOIN COMMON CODE                   *
MODEL4   MVI   QDSCRO1,X'7E'       ERASE/WRITE ALTERNATE              *
****     STSIZE SIZE=80,LINE=43    SET SCREEN SIZE FOR VTAM           *
         LA    R1,80               SCREEN WIDTH                       *
         LA    R0,43               SCREEN DEPTH                       *
         B     MODELN              JOIN COMMON CODE                   *
MODEL5   MVI   QDSCRO1,X'7E'       ERASE/WRITE ALTERNATE              *
****     STSIZE SIZE=132,LINE=27   SET SCREEN SIZE FOR VTAM           *
         LA    R1,QDSCRTXT+80                              2003-02-05 *
         LA    R1,132              SCREEN WIDTH                       *
         LA    R0,27               SCREEN DEPTH                       *
         B     MODELN              JOIN COMMON CODE                   *
MODELX   MVI   QDSCRO1,X'7E'       ERASE/WRITE ALTERNATE   2003-02-14 *
         SLR   R0,R0                                       2003-02-14 *
         IC    R0,QDALTSZ          GET ALTERNATE LINES     2003-02-14 *
         SLR   R1,R1                                       2003-02-14 *
         IC    R1,QDALTSZ+1        GET ALTERNATE COLUMNS   2003-02-14 *
         CLC   QDALTSZ,QDPRMSZ     TWO DIFFERENT SIZES?    2003-02-14 *
         BNE   MODELN              YES                     2003-02-14 *
         MVI   QDSCRO1,X'F5'       NO, USE ERASE/WRITE     2003-02-14 *
         SPACE 1                                                      *
MODELN   STH   R1,QDLNELEN         LINE LENGTH                        *
         SH    R1,=H'80'           WIDER THAN 80-COLUMNS?  2003-02-14 *
         BNP   TOPLNOK             NO                      2003-02-14 *
         LA    R14,QDSCRTXT+80     YES, POINT TO COLUMN 81 2003-02-14 *
         LR    R15,R1              GET EXTRA WIDTH SIZE    2003-02-14 *
         SLR   R1,R1               ZERO SOURCE LENGTH      2003-02-14 *
         ICM   R1,8,QBLANK         USE BLANK PAD CHARACTER 2003-02-14 *
         MVCL  R14,R0              BLANK REST OF TOP LINE  2003-02-14 *
         LA    R1,QDSCRTXT+80      POINT TO COLUMN 81      2003-02-14 *
         MVC   2(7,R1),=X'E4A2859989847E'      C'USERID='  2003-02-14 *
         MVC   9(8,R1),QLOGON      DISPLAY USERID          2003-02-14 *
         MVC   19(9,R1),=X'E3859994899581937E' C'TERMINAL='2003-02-14 *
         MVC   28(8,R1),QDTRMID    DISPLAY TERMINAL NAME   2003-02-14 *
TOPLNOK  LR    R15,R0              GET SCREEN LINE COUNT              *
         SH    R15,=H'3'           GET DETAIL DISPLAY LINE COUNT      *
         CVD   R15,COUNT           MAKE DECIMAL                       *
         ZAP   QDLNES,COUNT        DETAIL LINE COUNT       2003-02-05 *
         MH    R0,QDLNELEN         GET SCREEN DISPLAY CHARACTER COUNT *
         ST    R0,QDSCRPLN         LENGTH OF BUFFER WITH SHADOW BUFFER*
         MH    R15,QDLNELEN        GET DISPLAY DETAIL CONTENT CAPACITY*
         ST    R15,QDSCRLEN        LENGTH TO CLEAR FOR EACH DISPLAY   *
         LR    R15,R0              GET SCREEN BUFFER SIZE             *
         SH    R15,QDLNELEN        GET CAPACITY LESS ONE SCREEN LINE  *
         LA    R1,QDSCRTXT(R15)                                       *
         MVC   0(7,R1),=C'REPLY -'                                    *
         MVI   7(R1),X'0B'         HIGH INTENSITY INPUT FIELD         *
         XC    8(63,R1),8(R1)      CLEAR INPUT AREA                   *
         MVI   71(R1),X'0C'        LOW INTENSITY OUTPUT FIELD         *
         LA    R1,72(,R1)          POINT TO PLUS SIGN INDICATOR AREA  *
         ST    R1,QDPLUS@          SAVE ITS ADDRESS                   *
         LA    R1,QDSCRTXT         POINT TO FIRST SCREEN LINE         *
         AH    R1,QDLNELEN         POINT TO SECOND SCREEN LINE        *
         ST    R1,QDHLINE@         SAVE HEADING LINE ADDRESS          *
         AH    R1,QDLNELEN         POINT TO THIRD SCREEN LINE         *
         ST    R1,QDLINE1@         SAVE FIRST DATA LINE ADDRESS       *
         L     R1,QDSHADO@         POINT TO THE SHADOW AREA           *
         XC    0(256,R1),0(R1)     CLEAR THE TITLE LINE               *
         MVI   0(R1),X'07'         TOP LEFT TEXT IN WHITE             *
         MVC   1(14,R1),0(R1)                                         *
         MVI   16(R1),X'02'        COMMAND ECHO IN RED                *
         MVI   80(R1),X'06'        YELLOW USERID+TERMINAL  2003-02-14 *
         AR    R1,R15              POINT TO SHADOW OF LAST LINE       *
         MVI   0(R1),X'07'         PROMPT IN WHITE                    *
         MVC   1(6,R1),0(R1)                                          *
         MVI   8(R1),X'32'         INPUT AREA IN RED UNDERSCORE       *
         MVC   9(62,R1),8(R1)                                         *
         MVI   72(R1),X'07'        PLUS SIGN IN WHITE IF SHOWN        *
         MVC   73(7,R1),72(R1)                                        *
         OI    QFLAG1,QFLG1RSH     ALTER SCREEN SIZE 2003-02-05       *
         CLI   QDLNELEN+1,132      132 COLUMNS?      2003-02-05       *
         BL    RESUMEIT            NO                2003-02-05       *
         MVC   80(52,R1),79(R1)    YES, FILL IN REST 2003-02-05       *
RESUMEIT DS    0H      END OF REDO MODEL CODE        2002-06-16   GP@P6
         CLC   QPDSID,=H'0'        IS THERE A DATASET?            UF003
         BNE   RESUME              YES, CALL LISTDS               UF003
         L     R15,QDHLINE@        POINT TO HEADING LINE          GP@P6
         MVC   0(80,R15),QBLANK    BLANK HEADING LINE       GP@P6 UF003
         B     STOP                AND RETURN                     UF003
         SPACE 1                                                  UF003
***********************************************************************
*                                                                     *
*   SWITCH EXTENDED DATA STREAM USAGE             GP@P6 NOVEMBER 2002 *
*                                                                     *
***********************************************************************
MONO     NI    QFLAG2,255-QFLG2EDS RESET BIT
         B     RESUMEIT
COLOR    OI    QFLAG2,QFLG2EDS     SET BIT
         B     RESUMEIT
         EJECT                                                    UF003
***********************************************************************
*                                                                     *
*   MISCELLANY                                                        *
*                                                                     *
***********************************************************************
         LTORG
SYMDEL   DSECT ,                   KILL SYM CARD GENERATION       UF023
         QCOMMON
SYMNODEL DSECT ,                   RESTORE SYM CARD GENERATION    UF023
WORK     DSECT
         DS    CL72
COUNT    DS    D
         END
./ ADD NAME=SEARCH   8002-02166-02215-2139-00651-00633-00000-GREG
SEARCH QSTART 'QUEUE COMMAND - JQE AND JOE SEARCH AND FORMAT'
*******************************************************************
* RNB CHANGES:                                                    *
*      (1) RNB16 - PROCESS BOTH LOCAL AND REMOTE JOE QUEUE.       *
*                  ALSO, FIX BUG IN UF020 THAT WAS CLEARING       *
*                  FIELD JOEFLAG IN THE WORK JOE.                 *
*      (2) RNB19 - FOR SP, SEARCH DUMP Q AND CONVERSION (XEQ) Q IF*
*                  STATUS COMMAND OR DJ. ALSO OUTPUT QUEUE        *
*******************************************************************
         GBLB  &QSP           MVS/SP OPTION                       UF020
         L     R10,QVCKPT     LOAD BASE REG
         USING JQEDSECT,R9    BASE REG FOR JQE DSECT
         USING JOEDSECT,R8    BASE REG FOR JOE DSECT
         USING WORK,R13       BASE REG FOR LOCAL WORK AREA
******************************************************************UF006
*                                                                 UF006
*   CALL - READ JES2 CHECKPOINT FILE                              UF006
*                                                                 UF006
******************************************************************UF006
         L     R15,=V(CKPT)   ADDR OF CKPT ROUTINE                UF006
         BALR  R14,R15        GO TO IT                            UF006
***********************************************************************
*                                                                     *
*   BRANCH TO PROPER ROUTINE                                          *
*                                                                     *
***********************************************************************
         LH    R1,QCODEH      LOAD FUNCTION CODE INTO R1
         CH    R1,=H'48'      IS THE FUNCTION SUPPORTED?
         BH    STOP           NO. RETURN.
         B     *+4(R1)        BRANCH TO ROUTINE
         B     ST             0 OFFSET
         B     DA             4
         B     DI             8
         B     AO   DO        12
         B     AI             16
         B     AO             20
         B     HI             24
         B     HO             28
         B     DT             32
         B     DJ             36
         B     DS             40
         B     DQ             44
         B     DF             48
***********************************************************************
*                                                                     *
*   STATUS - FIND ALL JOBS THAT MATCH LEVEL                           *
*                                                                     *
***********************************************************************
ST       CLI   QPARM1,C' '    DID USER SPECIFY LEVEL?
         BNE   ST2            NO. USE QLOGON.
         MVC   QPARM1,QLOGON  MOVE USER PARM1 TO LEVEL
ST2      BAL   R2,PARMLEN     DETERMINE PARM LENGTH
* SEARCH THE TSO QUEUE
         USING JQTDSECT,R1    BASE REG FOR JQT
DJ2      LH    R6,QLNG1       LENGTH OF COMPARE FOR LEVEL
         L     R1,QCJQHEAD    LOAD ADDR OF JQT
         LA    R4,JQTTSU      ADDR OF TSO QUEUE
         MVI   QCLASS,0       INDICATE THIS IS THE TSO QUEUE
         BAL   R2,SRCHJQE     SEARCH THE QUEUE
         B     DJ3            END OF QUEUE
         CLC   QPARM1,=CL8'*' ALL JOBS REQUESTED?                 GP@P6
         BE    PRTJQE         YES, PRINT THE RECORD               GP@P6
         EX    R6,STCLC       IS THE JOBNAME EQUAL TO LEVEL?
         BNE   SKIPJQE        NO. SKIP THIS RECORD.
         B     PRTJQE         PRINT THE RECORD
* SEARCH THE SYSTEM QUEUE
DJ3      L     R1,QCJQHEAD    LOAD ADDR OF JQT
         LA    R4,JQTSTC      ADDR OF STC QUEUE
         MVI   QCLASS,4       INDICATE THIS IS THE STC QUEUE
         BAL   R2,SRCHJQE     SEARCH THE QUEUE
         B     DJ4            END OF QUEUE
         CLC   QPARM1,=CL8'*' ALL JOBS REQUESTED?                 GP@P6
         BE    PRTJQE         YES, PRINT THE RECORD               GP@P6
         EX    R6,STCLC       IS THE JOBNAME EQUAL TO LEVEL?
         BNE   SKIPJQE        NO. SKIP THIS RECORD.
         B     PRTJQE         PRINT THE RECORD
* SEARCH FOR HELD OUTPUT
DJ4      L     R1,QCJQHEAD    LOAD ADDR OF JQT
         LA    R4,JQTOUT      ADDR OF $OUTPUT QUEUE
         DROP  R1
         MVI   QCLASS,8       INDICATE THIS IS THE HELD OUT QUEUE
         BAL   R2,SRCHJQE     SEARCH THE QUEUE
         AIF   (&QSP).RNB19A                                      RNB19
         B     ST3            END OF QUEUE
         AGO   .RNB19B                                            RNB19
.RNB19A  ANOP                                                     RNB19
         B     DJ5            END OF QUEUE                        RNB19
.RNB19B  ANOP                                                     RNB19
         CLC   QPARM1,=CL8'*' ALL JOBS REQUESTED?                 GP@P6
         BE    PRTJQE         YES, PRINT THE RECORD               GP@P6
         EX    R6,STCLC       IS THE JOBNAME EQUAL TO LEVEL?
         BNE   SKIPJQE        NO. SKIP THIS RECORD.
         CLI   JQEHLDCT,0     ARE THERE ANY HELD DATASETS? (PART 1)
         BNE   PRTJQE         YES. PRINT THE RECORD.
         TM    JQEHQLOK,X'F0' ARE THERE ANY HELD DATASETS? (PART 2)
         BNZ   PRTJQE         YES. PRINT THE RECORD.
         B     REJJQE         REJECT THE RECORD
         AIF   (NOT &QSP).RNB19C                                  RNB19
* SEARCH DUMP QUEUE                                               RNB19
DJ5      L     R1,QCJQHEAD    LOAD ADDR OF JQT                    RNB19
         USING JQTDSECT,R1    BASE REG FOR JQT                    RNB19
         LA    R4,JQTDUMP     ADDR OF DUMP QUEUE                  RNB19
         DROP  R1                                                 RNB19
         MVI   QCLASS,12      INDICATE THIS IS THE DUMP QUEUE     RNB19
         BAL   R2,SRCHJQE     SEARCH THE QUEUE                    RNB19
         B     DJ6            END OF QUEUE                        RNB19
         CLC   QPARM1,=CL8'*' ALL JOBS REQUESTED?                 GP@P6
         BE    PRTJQE         YES, PRINT THE RECORD               GP@P6
         EX    R6,STCLC       IS THE JOBNAME EQUAL TO LEVEL?      RNB19
         BNE   SKIPJQE        NO. SKIP THIS RECORD.               RNB19
         B     PRTJQE         PRINT THE RECORD                    RNB19
* SEARCH CONVERSION (XEQ) QUEUE                                   RNB19
DJ6      L     R1,QCJQHEAD    LOAD ADDR OF JQT                    RNB19
         USING JQTDSECT,R1    BASE REG FOR JQT                    RNB19
         LA    R4,JQTXEQ      ADDR OF CONVERSION QUEUE            RNB19
         DROP  R1                                                 RNB19
         MVI   QCLASS,16      INDICATE THIS IS THE CNV QUEUE      RNB19
         BAL   R2,SRCHJQE     SEARCH THE QUEUE                    RNB19
         B     DJ7            END OF QUEUE                        RNB19
         CLC   QPARM1,=CL8'*' ALL JOBS REQUESTED?                 GP@P6
         BE    PRTJQE         YES, PRINT THE RECORD               GP@P6
         EX    R6,STCLC       IS THE JOBNAME EQUAL TO LEVEL?      RNB19
         BNE   SKIPJQE        NO. SKIP THIS RECORD.               RNB19
         B     PRTJQE         PRINT THE RECORD                    RNB19
* SEARCH OUTPUT (AWAITING OUTPUT) QUEUE                           RNB19
DJ7      L     R1,QCJQHEAD    LOAD ADDR OF JQT                    RNB19
         USING JQTDSECT,R1    BASE REG FOR JQT                    RNB19
         LA    R4,JQTAWOUT    ADDR OF OUTPUT QUEUE                RNB19
         DROP  R1                                                 RNB19
         MVI   QCLASS,20      INDICATE THIS IS THE CNV QUEUE      RNB19
         BAL   R2,SRCHJQE     SEARCH THE QUEUE                    RNB19
         B     ST3            END OF QUEUE                        RNB19
         CLC   QPARM1,=CL8'*' ALL JOBS REQUESTED?                 GP@P6
         BE    PRTJQE         YES, PRINT THE RECORD               GP@P6
         EX    R6,STCLC       IS THE JOBNAME EQUAL TO LEVEL?      RNB19
         BNE   SKIPJQE        NO. SKIP THIS RECORD.               RNB19
         B     PRTJQE         PRINT THE RECORD                    RNB19
.RNB19C  ANOP                                                     RNB19
* SEARCH INPUT QUEUES
ST3      MVI   QCLASS,192     START WITH CLASS A
ST4      BAL   R2,NEXTJQT     FIND NEXT QUEUE
         BAL   R2,SRCHJQE     SEARCH THE QUEUE
         B     ST4            END OF QUEUE
         CLI   JQEFLAGS,0     IS THE JOB EXECUTING OR HELD?
         BNE   ST7            YES. SPECIAL HANDLING.
         CLC   QPARM1,=CL8'*' ALL JOBS REQUESTED?                 GP@P6
         BE    PRTJQE         YES, PRINT THE RECORD               GP@P6
         EX    R6,STCLC       IS THE JOBNAME EQUAL TO LEVEL?
         BNE   SKIPJQE        NO. SKIP THIS RECORD.
         B     PRTJQE         PRINT THE JQE
ST7      CLC   QPARM1,=CL8'*' ALL JOBS REQUESTED?                 GP@P6
         BE    PRT2JQE        YES, PRINT THE RECORD               GP@P6
         EX    R6,STCLC       IS THE JOBNAME EQUAL TO LEVEL?
         BNE   REJJQE         NO. SKIP THIS RECORD.
         B     PRT2JQE        PRINT THE RECORD WITHOUT INCR COUNT
* SEARCH OUTPUT QUEUES
ST5      MVI   QCLASS,192     START WITH CLASS A
ST6      BAL   R2,NEXTJOT     DETERMINE NEXT QUEUE
         BAL   R2,SRCHJOE     SEARCH A JOE QUEUE
         B     ST6            END OF QUEUE
         CLC   QPARM1,=CL8'*' ALL JOBS REQUESTED?                 GP@P6
         BE    PRTJQE         YES, PRINT THE RECORD               GP@P6
         EX    R6,STCLC       IS THE JOBNAME EQUAL TO LEVEL?
         BNE   SKIPJOE        NO. SKIP THIS RECORD.
         B     PRTJOE         PRINT THE RECORD
* COMPARE USED TO CHECK LEVEL
STCLC    CLC   QPARM1(0),JQEJNAME IS THE JOBNAME EQUAL TO LEVEL?
***********************************************************************
*                                                                     *
*   DQ - PRINT SUMMARY OF ALL JOBS IN THE INPUT QUEUES                *
*                                                                     *
***********************************************************************
*  SEARCH ALL QUEUES
DQ       MVI   QCLASS,192           START WITH CLASS A
         QHEAD DQHEADER,X'24'       HEADING IN GREEN REVERSE      GP@P6
DQ1      BAL   R2,NEXTJQT           FIND NEXT QUEUE
         ZAP   QCOUNTE,=P'0'        ZERO COUNT FOR EXECUTING JOBS
         ZAP   QCOUNTA,=P'0'        ZERO COUNT FOR AWAITING JOBS
         ZAP   QCOUNTH,=P'0'        ZERO COUNT FOR HELD JOBS
         BAL   R2,SRCHJQE           SEARCH THE QUEUE
         B     DQ4                  END OF QUEUE
         TM    JQEFLAGS,QUEBUSY     IS THIS JOB EXECUTING
         BZ    DQ2                  NO, NEXT TEST
         AP    QCOUNTE,=P'1'        YES, BUMP COUNTER
         B     SKIPJQE              PROCESS NEXT JQE
DQ2      TM    JQEFLAGS,X'E0'       IS THIS A HELD JOB
         BZ    DQ3                  NO, NEXT TEST
         AP    QCOUNTH,=P'1'        YES, BUMP COUNTER
         B     SKIPJQE              PROCESS NEXT JQE
DQ3      CLI   JQEFLAGS,0           IS THIS JOB AWAITING EXECUTION
         BNE   SKIPJQE              NO, PROCESS NEXT JQE
         AP    QCOUNTA,=P'1'        YES, BUMP COUNTER
         B     SKIPJQE              PROCESS NEXT JQE
DQ4      CLC   QCOUNT,=PL3'0'       IS THIS QUEUE EMPTY
         BE    DQ1                  YES, TRY THE NEXT QUEUE
         MVC   QDMSG,DQLINE         MOVE IN DETAIL LINE
         MVC   FCOUNT,ED5           MOVE IN
         ED    FCOUNT,QCOUNTE            NUMBER OF JOBS
         MVC   QECOUNT,FCOUNT+3                    IN EXECUTION
         MVC   FCOUNT,ED5           MOVE IN
         ED    FCOUNT,QCOUNTA            NUMBER OF JOBS
         MVC   QACOUNT,FCOUNT+3                    AWAITING EXECUTION
         MVC   FCOUNT,ED5           MOVE IN
         ED    FCOUNT,QCOUNTH            NUMBER OF JOBS
         MVC   QHCOUNT,FCOUNT+3                    IN HELD STATUS
         MVC   FCOUNT,ED5           MOVE IN THE TOTAL NUMBER OF JOBS
         ED    FCOUNT,QCOUNT             IN THIS QUEUE
         MVC   CLASS,QCLASS         MOVE IN QUEUE CLASS
         BAL   R2,DISPLAY           GO DISPLAY THIS LINE
         B     DQ1                  PROCESS THE NEXT QUEUE
***********************************************************************
*                                                                     *
*   DF - PRINT SUMMARY OF ALL JOBS IN THE OUTPUT QUEUES               *
*                                                                     *
***********************************************************************
DF       MVI   QCLASS,192           START WITH CLASS A
         QHEAD DFHEADER,X'24'       HEADING IN GREEN REVERSE      GP@P6
DF1      BAL   R2,NEXTJOT           FIND NEXT QUEUE
         ZAP   QCOUNTE,=P'0'        ZERO COUNT FOR JOBS PRINTING
         BAL   R2,SRCHJOE           SEARCH THE QUEUE
         B     DF2                  END OF QUEUE
         TM    JOEFLAG,X'20'        IS JOB PRINTING
         BNO   SKIPJOE              NO, PROCESS NEXT JOE
         AP    QCOUNTE,=P'1'        YES, BUMP COUNTER
         B     SKIPJOE              PROCESS NEXT JOE
DF2      CLC   QCOUNT,=PL3'0'       QUEUE EMPTY
         BE    DF1                  YES, TRY THE NEXT QUEUE
         MVC   QDMSG,DFLINE         MOVE IN DETAIL LINE
         MVC   FCOUNT,ED5           MOVE IN
         ED    FCOUNT,QCOUNTE            NUMBER OF JOBS
         MVC   QECOUNT,FCOUNT+3                    PRINTING
         MVC   FCOUNT,ED5           MOVE IN TOTAL NUMBER OF JOBS
         ED    FCOUNT,QCOUNT             IN THIS QUEUE
         MVC   CLASS,QCLASS         MOVE IN QUEUE CLASS
         BAL   R2,DISPLAY           GO DISPLAY THIS LINE
         B     DF1                  PROCESS NEXT QUEUE
***********************************************************************
*                                                                     *
*   DJ - FIND A SPECIFIC JOB                                          *
*                                                                     *
***********************************************************************
DJ       CLI   QPARM1,C' '    DID USER SPECIFY JOBNAME?
         BE    DJ9            NO. TILT.
         MVC   QLNG1,=H'7'    COMPARE FOR 8 CHARACTERS
         B     DJ2            USE THE STATUS ROUTINES
DJ9      QTILT '*** YOU MUST SPECIFY JOBNAME ***'
***********************************************************************
*                                                                     *
*   DI - PRINT ALL JOBS IN INPUT QUEUES                               *
*                                                                     *
***********************************************************************
DI       CLI   QPARM1,C' '    DID USER SPECIFY CLASS?
         BNE   DI5            YES. LIMIT TO ONE QUEUE.
* SEARCH ALL QUEUES
         MVI   QCLASS,192     START WITH CLASS A
DI2      BAL   R2,NEXTJQT     DETERMINE NEXT QUEUE
         BAL   R2,SRCHJQE     SEARCH A JQE QUEUE
         B     DI2            END OF QUEUE
         B     PRTJQE         PRINT THE RECORD
* SEARCH ONLY ONE QUEUE
DI5      MVC   QCLASS,QPARM1  USER SPECIFIED CLASS
         BAL   R2,FINDJQT     FIND QUEUE
         BAL   R2,SRCHJQE     SEARCH THE QUEUE
         B     STOP           END OF QUEUE
         B     PRTJQE         PRINT THE RECORD
***********************************************************************
*                                                                     *
*   AI - PRINT JOBS IN INPUT QUEUES THAT ARE AVAILABLE FOR SELECTION  *
*                                                                     *
***********************************************************************
AI       CLI   QPARM1,C' '    DID USER SPECIFY CLASS?
         BNE   AI5            YES. LIMIT TO ONE QUEUE.
* SEARCH ALL QUEUES
         MVI   QCLASS,192     START WITH CLASS A
AI2      BAL   R2,NEXTJQT     DETERMINE NEXT QUEUE
         BAL   R2,SRCHJQE     SEARCH A JQE QUEUE
         B     AI2            END OF QUEUE
         CLI   JQEFLAGS,0     IS THE JOB BUSY OR HELD?
         BNE   REJJQE         YES. SKIP IT.
         B     PRTJQE         PRINT THE RECORD
* SEARCH ONLY ONE QUEUE
AI5      MVC   QCLASS,QPARM1  USER SPECIFIED CLASS
         BAL   R2,FINDJQT     FIND QUEUE
         BAL   R2,SRCHJQE     SEARCH THE QUEUE
         B     STOP           END OF QUEUE
         CLI   JQEFLAGS,0     IS THE JOB BUSY OR HELD?
         BNE   REJJQE         YES. SKIP IT.
         B     PRTJQE         PRINT THE RECORD
***********************************************************************
*                                                                     *
*   AO - PRINT AVAILABLE JOBS IN THE OUTPUT QUEUE                     *
*                                                                     *
***********************************************************************
AO       CLI   QPARM1,C' '    DID USER SPECIFY CLASS?
         BNE   AO5            YES. LIMIT TO ONE QUEUE.
* SEARCH ALL QUEUES
         MVI   QCLASS,192     START WITH CLASS A
AO2      BAL   R2,NEXTJOT     DETERMINE NEXT QUEUE
         BAL   R2,SRCHJOE     SEARCH A JQE QUEUE
         B     AO2            END OF QUEUE
         B     PRTJOE         PRINT THE RECORD
* SEARCH ONLY ONE QUEUE
AO5      MVC   QCLASS,QPARM1  USER SPECIFIED CLASS
         BAL   R2,FINDJOT     FIND QUEUE
         BAL   R2,SRCHJOE     SEARCH THE QUEUE
         B     STOP           END OF QUEUE
         B     PRTJOE         PRINT THE RECORD
***********************************************************************
*                                                                     *
*   HI - PRINT JOBS IN INPUT QUEUES THAT ARE HELD                     *
*                                                                     *
***********************************************************************
HI       CLI   QPARM1,C' '    DID USER SPECIFY CLASS?
         BNE   HI5            YES. LIMIT TO ONE QUEUE.
* SEARCH ALL QUEUES
         MVI   QCLASS,192     START WITH CLASS A
HI2      BAL   R2,NEXTJQT     DETERMINE NEXT QUEUE
         BAL   R2,SRCHJQE     SEARCH A JQE QUEUE
         B     HI2            END OF QUEUE
         TM    JQEFLAGS,X'E0' IS THE JOB HELD?
         BZ    REJJQE         NO. SKIP IT.
         B     PRTJQE         PRINT THE RECORD
* SEARCH ONLY ONE QUEUE
HI5      MVC   QCLASS,QPARM1  USER SPECIFIED CLASS
         BAL   R2,FINDJQT     FIND QUEUE
         BAL   R2,SRCHJQE     SEARCH THE QUEUE
         B     STOP           END OF QUEUE
         TM    JQEFLAGS,X'E0' IS THE JOB HELD?
         BZ    REJJQE         NO. SKIP IT.
         B     PRTJQE         PRINT THE RECORD
***********************************************************************
*                                                                     *
*   HO - LIST ALL JOBS WITH HELD OUTPUT                               *
*                                                                     *
***********************************************************************
         USING JQTDSECT,R1    BASE REG FOR JQT
HO       L     R1,QCJQHEAD    LOAD ADDR OF JQT
         LA    R4,JQTOUT      ADDR OF $OUTPUT QUEUE
         DROP  R1
         MVI   QCLASS,8       INDICATE THIS IS THE HELD OUT QUEUE
         BAL   R2,SRCHJQE     SEARCH THE QUEUE
         B     STOP           END OF QUEUE
         CLI   JQEHLDCT,0     ARE THERE ANY HELD DATASETS? (PART 1)
         BNE   PRTJQE         YES. PRINT THE RECORD.
         TM    JQEHQLOK,X'F0' ARE THERE ANY HELD DATASETS? (PART 2)
         BNZ   PRTJQE         YES. PRINT THE RECORD.
         B     REJJQE         REJECT THE RECORD
***********************************************************************
*                                                                     *
*   DA - FIND ALL EXECUTING JOBS                                      *
*                                                                     *
***********************************************************************
DA       MVI   QCLASS,192     START WITH CLASS A
DA2      BAL   R2,NEXTJQT     DETERMINE NEXT QUEUE
         BAL   R2,SRCHJQE     SEARCH THE QUEUE
         B     DA2            END OF QUEUE
         TM    JQEFLAGS,QUEBUSY IS THE JOB EXECUTING?
         BZ    REJJQE         NO. REJECT IT.
         B     PRTJQE         PRINT THE RECORD
***********************************************************************
*                                                                     *
*   DT - LIST ALL TSO USERS                                           *
*                                                                     *
***********************************************************************
         USING JQTDSECT,R1    BASE REG FOR JQT
DT       L     R1,QCJQHEAD    LOAD ADDR OF JQT
         LA    R4,JQTTSU      ADDR OF TSO QUEUE
         DROP  R1
         MVI   QCLASS,0       INDICATE THIS IS THE TSO QUEUE
         BAL   R2,SRCHJQE     SEARCH THE QUEUE
         B     STOP           END OF QUEUE
         B     PRTJQE         PRINT THE RECORD
***********************************************************************
*                                                                     *
*   DS - LIST ALL SYSTEM STARTED TASKS                                *
*                                                                     *
***********************************************************************
         USING JQTDSECT,R1    BASE REG FOR JQT
DS       L     R1,QCJQHEAD    LOAD ADDR OF JQT
         LA    R4,JQTSTC      ADDR OF STC QUEUE
         DROP  R1
         MVI   QCLASS,4       INDICATE THIS IS THE STC QUEUE
         BAL   R2,SRCHJQE     SEARCH THE QUEUE
         B     STOP           END OF QUEUE
         B     PRTJQE         PRINT THE RECORD
***********************************************************************
*                                                                     *
*   DETERMINE LENGTH OF LEVEL                                         *
*                                                                     *
***********************************************************************
PARMLEN  LA    R3,7           MAXIMUM LENGTH OF 8
         LA    R4,QPARM1+7    END OF FIELD
PARMLEN2 CLI   0(R4),C' '     IS THIS BYTE BLANK?
         BNE   PARMLEN3       NO. THIS IS THE LENGTH
         BCTR  R4,0           TRY PREVIOUS BYTE
         BCT   R3,PARMLEN2    LOOP
PARMLEN3 STH   R3,QLNG1       STORE THE LENGTH OF LEVEL
         BR    R2             RETURN TO CALLER
***********************************************************************
*                                                                     *
*   SEARCH A JQE QUEUE                                                *
*                                                                     *
***********************************************************************
SRCHJQE  ZAP   QCOUNT,=P'0'   ZERO THE QUEUE COUNT
         AIF   (&QSP).QSP3                                        UF020
         LH    R9,0(R4)       LOAD FIRST JQE OFFSET
         N     R9,=X'0000FFFF' KILL EXTRANEOUS BITS
NEXTJQE  SLA   R9,2           MULTIPLY BY 4
         AGO   .QSP4                                              UF020
.QSP3    ANOP                                                     UF020
         L     R9,0(R4)       LOAD FIRST JQE OFFSET               UF020
NEXTJQE  LA    R9,0(,R9)      KILL EXTRANEOUS BITS                UF020
         LTR   R9,R9          TEST FOR END OF QUEUE               UF020
.QSP4    ANOP                                                     UF020
         BZR   R2             END OF QUEUE. RETURN.
         A     R9,QCJQTA      ADD BASE TO OFFSET
         B     4(R2)          DETERMINE ELIGIBILITY
PRTJQE   AP    QCOUNT,=P'1'   INCREMENT COUNT
PRT2JQE  SR    R1,R1          INDICATE THIS IS A JQE
         L     R15,=V(FORMAT) ADDR OF PRINT MODULE
         BALR  R14,R15        PRINT THE JQE IN R9
         AIF   (&QSP).QSP5                                        UF020
REJJQE   LH    R9,JQECHAIN    LOAD OFFSET TO NEXT JQE
         AGO   .QSP6                                              UF020
.QSP5    ANOP                                                     UF020
REJJQE   L     R9,JQENEXT     LOAD OFFSET TO NEXT JQE             UF020
.QSP6    ANOP                                                     UF020
         B     NEXTJQE        GET THE NEXT JQE
SKIPJQE  AP    QCOUNT,=P'1'   INCREMENT COUNT
         B     REJJQE         CONTINUE
***********************************************************************
*                                                                     *
*   SEARCH A JOE QUEUE                                                *
*                                                                     *
***********************************************************************
         AIF   (&QSP).QSP7                                        RNB16
SRCHJOE  ZAP   QCOUNT,=P'0'   ZERO THE QUEUE COUNT
FIRSTJOE LH    R8,0(R4)       LOAD FIRST JOE OFFSET
         N     R8,=X'0000FFFF' KILL EXTRANEOUS BITS.
         AGO   .QSP8                                              UF020
.QSP7    ANOP                                                     UF020
SRCHJOE  ZAP   QCOUNT,=P'0'    ZERO THE QUEUE COUNT               RNB16
         OI    QFLAG1,QFLG1LCL SHOW SEARCHING LOCAL QUEUE         RNB16
         B     FIRSTJOE        AND GO DO IT                       RNB16
*                                                                 RNB16
SRCHJOE1 NI    QFLAG1,X'FF'-QFLG1LCL TURN OFF LOCAL QUEUE FLAG    RNB16
         LA    R4,4(,R4)             POINT TO REMOTE QUEUE        RNB16
*                                                                 RNB16
FIRSTJOE L     R8,0(R4)       LOAD FIRST JOE OFFSET               UF020
         LA    R8,0(,R8)       KILL EXTRANEOUS BITS.              UF020
.QSP8    ANOP                                                     UF020
         LTR   R8,R8          IS THE QUEUE EMPTY?
         AIF   (&QSP).QSP8A                                       RNB16
         BZR   R2             YES. RETURN TO CALLER.
         AGO   .QSP8B                                             RNB16
.QSP8A   BNZ   $1             /NO  - CONTINUE                     RNB16
*                             /YES -                              RNB16
         TM    QFLAG1,QFLG1LCL WAS THIS THE LOCAL QUEUE?          RNB16
         BO    SRCHJOE1       /YES - GO DO REMOTE QUEUE           RNB16
         BR    R2             /NO  - RETURN TO CALLER             RNB16
$1       EQU   *                                                  RNB16
.QSP8B   ANOP                                                     RNB16
         XC    PRIORITY(12),PRIORITY ZERO OUT HIGHEST POINTERS
         AIF   (&QSP).QSP9                                        UF020
NEXTJOE  SLA   R8,2           MULTIPLY BY 4
         AGO   .QSP10                                             UF020
.QSP9    ANOP                                                     UF020
NEXTJOE  LA    R8,0(,R8)      CLEAR EXTRA BITS                    UF020
         LTR   R8,R8          TEST FOR END OF QUEUE               UF020
.QSP10   ANOP                                                     UF020
         BZ    TESTJOE        END OF QUEUE. PASS HIGHEST TO CALLER.
         A     R8,QCJOTA      ADD BASE TO OFFSET
         AIF   (&QSP).QSP11                                       UF020
         LH    R9,JOEJQE      OFFSET TO JQE
         SLA   R9,2           MULTIPLY BY 4
         AGO   .QSP12                                             UF020
.QSP11   ANOP                                                     UF020
         L     R9,JOEJQE      OFFSET TO JQE                       UF020
         N     R9,=A(X'00FFFFFF')  CLEAR EXTRA BITS               UF020
.QSP12   ANOP                                                     UF020
         BZ    TRYJOE         THIS JOE ALREADY USED. TRY NEXT ONE.
         A     R9,QCJQTA      ADD BASE TO OFFSET
         LA    R7,255         PRESET MAXIMUM PRIORITY
         TM    JQEPRIO,240    IS THIS JOB PRIORITY 15?
         BO    HIGHJOE        YES. PASS TO CALLER.
         LA    R1,16          PRESET PRIORITY ONE
         CLI   JQETYPE,$HARDCPY IS THE JOB EXECUTING?
         BNE   EXECJOE        YES. USE PRIORITY ONE.
         IC    R1,JQEPRIO     INSERT JQE PRIORITY
EXECJOE  IC    R7,JOEPRIO     INSERT JOE PRIORITY
         AR    R7,R1          ADD PRIORITIES
         SRL   R7,1           BECAUSE HASP DOES IT, THAT'S WHY
HIGHJOE  C     R7,PRIORITY    IS THIS LESS THAN PREVIOUS HIGH?
         BL    TRYJOE         YES. TRY NEXT ONE.
         STM   R7,R9,PRIORITY NO. REPLACE PREVIOUS HIGH.
         AIF   (&QSP).QSP11A                                      UF020
TRYJOE   LH    R8,JOENEXT     ADDR OF NEXT JOE
         AGO   .QSP12A                                            UF020
.QSP11A  ANOP                                                     UF020
TRYJOE   L     R8,JOENEXT     ADDR OF NEXT JOE                    UF020
         N     R8,=A(X'00FFFFFF')  CLEAR EXTRA BITS               UF020
.QSP12A  ANOP                                                     UF020
         B     NEXTJOE        TRY NEXT JOE
TESTJOE  LM    R7,R9,PRIORITY LOAD ADDR OF HIGHEST JOE
         LTR   R8,R8          WAS THE QUEUE EMPTY?
         AIF   (&QSP).QSP12B                                      RNB16
         BZR   R2             YES. END OF QUEUE.
         MVC   JOEJQE,=F'0'   INDICATE THIS JOE USED              VBA01
         AGO   .QSP12C                                            RNB16
.QSP12B  ANOP                                                     RNB16
         BNZ   $2                                                 RNB16
         TM    QFLAG1,QFLG1LCL WAS THIS THE LOCAL QUEUE?          RNB16
         BO    SRCHJOE1       /YES - GO DO REMOTE QUEUE           RNB16
         BR    R2             /NO  - END OF QUEUE.                RNB16
$2       EQU   *                                                  RNB16
         MVC   JOEJQEB,=F'0'  INDICATE THIS JOE USED        VBA01 RNB16
.QSP12C  ANOP                                                     RNB16
*        MVC   JOEJQEB,=F'0'  INDICATE THIS JOE USED        VBA01 RNB16
*        MVC   JOEJQE,=F'0'   INDICATE THIS JOE USED        CBT1  UF020
         B     4(R2)          DETERMINE ELIGIBILITY
PRTJOE   LA    R1,4           INDICATE THIS IS A JOE
         AP    QCOUNT,=P'1'   INCREMENT COUNT
         L     R15,=V(FORMAT) ADDR OF PRINT MODULE
         BALR  R14,R15        PRINT THE JOE IN R9
REJJOE   B     FIRSTJOE       GET THE NEXT JOE
SKIPJOE  AP    QCOUNT,=P'1'   INCREMENT COUNT
         B     REJJOE         CONTINUE
***********************************************************************
*                                                                     *
*   DETERMINE INPUT QUEUE                                             *
*                                                                     *
***********************************************************************
FINDJQT  TR    QCLASS,CLASSTBL DETERMINE OFFSET
         LH    R4,QCLASSH     LOAD TABLE OFFSET
         BCTR  R4,0           SUBTRACT 1
         STH   R4,QCLASSH     RESTORE VALUE
         B     NEXTJQT2       CONTINUE
NEXTJQT  TR    QCLASS,CLASSTBL DETERMINE OFFSET FROM FIRST CLASS
         LH    R4,QCLASSH     LOAD TABLE OFFSET
         CH    R4,=H'36'      IS THIS THE LAST QUEUE?
         BNL   NEXTJQT9       YES. GO HOME.
NEXTJQT2 TR    QCLASS,NAMETBL MOVE CLASS NAME TO QCLASS
         AR    R4,R4          MULTIPLY BY 2
         AIF   (NOT &QSP).QSP13                                   UF020
         AR    R4,R4          AND BY 2 AGAIN                      UF020
.QSP13   ANOP                                                     UF020
         USING JQTDSECT,R1    BASE REG FOR JQT
         L     R1,QCJQHEAD    LOAD ADDR OF JQT
         LA    R4,JQTCLSA(R4) NEXT QUEUE
         DROP  R1
         BR    R2             RETURN TO CALLER
NEXTJQT9 CLI   QCODE,0        IS THIS A STATUS REQUEST?
         BE    ST5            YES. GO TO STATUS.
         CLI   QCODE,36       IS THIS A DJ REQUEST?
         BNE   STOP           NO. GO HOME.
         B     ST5            YES. GO TO STATUS.
***********************************************************************
*                                                                     *
*   DETERMINE OUTPUT QUEUE                                            *
*                                                                     *
***********************************************************************
FINDJOT  TR    QCLASS,CLASSTBL DETERMINE OFFSET
         LH    R4,QCLASSH     LOAD TABLE OFFSET
         BCTR  R4,0           SUBTRACT 1
         STH   R4,QCLASSH     RESTORE VALUE
         B     NEXTJOT2       CONTINUE
NEXTJOT  TR    QCLASS,CLASSTBL DETERMINE OFFSET FROM FIRST CLASS
         LH    R4,QCLASSH     LOAD TABLE OFFSET
         CH    R4,=H'36'      IS THIS THE LAST QUEUE?
         BNL   STOP           YES. GO HOME.
NEXTJOT2 TR    QCLASS,NAMETBL MOVE CLASS NAME TO QCLASS
         AR    R4,R4          MULTIPLY BY 2
         AIF   (NOT &QSP).QSP14                                   UF020
         SLL   R4,2           AND THEN BY 4 (WILL ONLY GET LOCALS)UF020
.QSP14   ANOP                                                     UF020
         USING JOTDSECT,R1    BASE REG FOR JOT
         L     R1,QCJOTA      LOAD ADDR OF JOT
         LA    R4,JOTCLSQ(R4) NEXT QUEUE
         DROP  R1
         BR    R2             RETURN TO CALLER
***********************************************************************
*                                                                     *
*   CALL DISPLAY ROUTINE                                              *
*                                                                     *
***********************************************************************
DISPLAY  LA    R1,QDMSG             SAVE ADDRESS
         ST    R1,QDMSGA                 OF THE MESSAGE
         MVC   QDMLNG,=H'80'        SET THE LENGTH
         L     R15,=V(DISPLAY)      BRANCH TO
         BALR  R14,R15                     DISPLAY
         BR    R2                   RETURN TO CALLER
***********************************************************************
*                                                                     *
*   GO HOME                                                           *
*                                                                     *
***********************************************************************
STOP     QSTOP
         LTORG
***********************************************************************
*                                                                     *
*   TABLES FOR CLASS DETERMINATION                                    *
*                                                                     *
***********************************************************************
NAMETBL  DC    C'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789'
CLASSTBL DC    192X'01'
         DC    X'00010203040506070809',7X'00'
         DC    X'0A0B0C0D0E0F101112',8X'00'
         DC    X'131415161718191A',6X'00'
         DC    X'1B1C1D1E1F2021222324',6X'00'
***********************************************************************
*                                                                     *
*   MISCELLANEOUS GARBAGE                                             *
*                                                                     *
***********************************************************************
ED5      DC    X'402020202120'
DQHEADER DC    CL80'*** INPUT QUEUES ***'
DQLINE   DC    CL80' INPUT                        EXECUTING      WAITINX
               G      HELD'
DFHEADER DC    CL80'*** OUTPUT QUEUES ***'
DFLINE   DC    CL80' OUTPUT                       PRINTING'
SYMDEL   DSECT ,                   KILL SYM CARD GENERATION       UF023
SEARCH   CSECT ,                                                  UF023
         SPACE 1                                                  UF001
$MAXNODE EQU   99             FOR NJE $JOT EXPANSION              UF001
         SPACE 1                                                  UF001
         $JQE
         AIF   (NOT &QSP).NOEQU
JQEHQLOK EQU   JQEJBLOK       NEW LABEL FOR OLD FIELD             UF020
.NOEQU   ANOP
         $JOE
         $JOT
         $JQT
WORK     DSECT
         DS    CL80
PRIORITY DS    3F
         QCOMMON
         ORG   QDMSG
         DS    CL9
CLASS    DS    CL1
         DS    CL2
QTCOUNT  DS    CL6
         DS    CL7
QECOUNT  DS    CL3
         DS    CL12
QACOUNT  DS    CL3
         DS    CL10
QHCOUNT  DS    CL3
         ORG   QTCOUNT
FCOUNT   DS    CL6
SYMNODEL DSECT ,                   RESTORE SYM CARD GENERATION    UF023
         END
./ ADD NAME=SYSLOG   8000-02202-02202-2300-00110-00110-00000-GREG
SYSLOG   QSTART 'QUEUE COMMAND - PRINT THE SYSTEM LOG DATASET'
         USING QCKPT,R10      BASE REG FOR CKPT WORK AREA
         L     R10,QVCKPT     LOAD BASE REG
         USING WORK,R13       BASE REG FOR TEMP WORK
***********************************************************************
*                                                                     *
*   DETERMINE CURRENT SYSLOG JOB NUMBER               GP@P6 JULY 2002 *
*                                                                     *
***********************************************************************
         ICM   R1,3,QLNG1     WAS A PARAMETER SPECIFIED?
         BZ    SLTHIS         NO, WANT THIS SYSTEMS SYSLOG
         CLC   QPARM1,=CL8'SYSLOG'
         BNE   SLTHAT         DO NOT INTERFERE WITH SPECIFIC REQUEST
SLTHIS   L     R3,16          POINT TO CVT
         USING CVTDSECT,R3
         L     R3,CVTJESCT    POINT TO JESCT
         DROP  R3
         USING JESCT,R3
         L     R3,JESSSCT     POINT TO SSCT
         DROP  R3
         USING SSCT,R3
         L     R3,SSCTSSVT    POINT TO SSVT
         DROP  R3
         USING SSVT,R3
         L     R3,$SVHAVT     POINT TO HAVT
         DROP  R3
         LTR   R3,R3          TEST IF ANY PITS
         BZ    SLTHAT         NO, GIVE UP SEARCH
         ICM   R3,15,4(R3)    POINT TO SJB OF ASID 1
         BZ    SLTHAT         SYSLOG MUST NOT BE ACTIVE
         CLC   236(8,R3),=CL8'SYSLOG'
         BNE   SLTHAT         SOMETHING HAS GONE AMISS
         MVC   QPARM1,QBLANK
         MVC   QPARM1+1(4),232(R3)
         OC    QPARM1(5),=CL5'10000'
         MVI   QLNG1+1,5      QPARM1 IS NOW 5-DIGIT INTERNAL JOB ID
SLTHAT   DS    0H
***********************************************************************
*                                                                     *
*   CALL FINDJOB TO LOCATE THE JQE, JCT, AND IOT                      *
*                                                                     *
***********************************************************************
         L     R15,=V(FINDJOB) ADDR OF MODULE TO FIND JOB
         BALR  R14,R15        GO TO IT
***********************************************************************
*                                                                     *
*   CHECK JOBNAME EQUAL SYSLOG                                        *
*                                                                     *
***********************************************************************
         L     R9,QCJCTA      ADDR OF IOAREA FOR JCT
         USING JCTSTART,R9    BASE REG FOR JCT
         CLC   JCTJNAME,=CL8'SYSLOG' IS THIS SYSLOG?
         BNE   TILT           NO. TILT.
***********************************************************************
*                                                                     *
*   DETERMINE NUMBER OF DATASETS FROM CURRENT DATASET                 *
*                                                                     *
***********************************************************************
         LH    R3,JCTPDDBK    HIGHEST DATASET ID NUMBER
         LH    R2,QLNG2       LENGTH OF BACKUP PARM
         SH    R2,=H'1'       IS THE BACKUP PARM ZERO LENGTH?
         BM    CALLLIST       YES. SKIP.
         CLI   QPARM2,C'-'    IS THERE A MINUS SIGN?
         BNE   PLUS           NO. SKIP.
         MVI   QPARM2,C'0'    CHANGE MINUS TO ZERO
PLUS     MVC   QFZONES,QFZONE INITIALIZE NUMERIC TEST
         EX    R2,MVZ         MOVE THE ZONES FOR VALIDITY CHECK
         CLC   QFZONES,QFZONE IS THE FIELD NUMERIC?
         BNE   TILT           NO. QUIT.
         EX    R2,PACK        PACK THE FIELD
         CVB   R2,CONVERT     CONVERT TO BINARY
         SR    R3,R2          BACK UP NUMBER OF DATASETS
         CH    R3,=H'101'     IS THE NUMBER LESS THAN 101?
         BL    TILT           YES. TILT.
***********************************************************************
*                                                                     *
*   CALL LISTDS TO LIST THE DATASET                                   *
*                                                                     *
***********************************************************************
CALLLIST STH   R3,QPDSID      STORE DATASET ID
         MVC   QPOFFSET,=H'0' PRINT OFFSET ZERO
         L     R15,=V(LISTDS) ADDR OF LISTDS MODULE
         BALR  R14,R15        GO TO IT
         QSTOP
TILT     QTILT '*** INVALID PARAMETER ***'
***********************************************************************
*                                                                     *
*   MISCELLANY                                                        *
*                                                                     *
***********************************************************************
MVZ      MVZ   QFZONES(1),QPARM2 CHECK FOR NUMERIC
PACK     PACK  CONVERT,QPARM2(1) CONVERT TO BINARY
         LTORG
         DROP  ,                   DROP ALL ADDRESSING            NERDC
SYMDEL   DSECT ,                   KILL SYM CARD GENERATION       UF023
SYSLOG   CSECT ,                                                  UF023
JCT      EQU   0
BUFSTART EQU   0
BUFDSECT EQU   0
         $CVT   ,                                                 GP@P6
         $JESCT ,                                                 GP@P6
         $SSCT  ,                                                 GP@P6
         $SVT   ,                                                 GP@P6
         $JCT
WORK     DSECT
         DS    72C
CONVERT  DS    D
         QCOMMON
SYMNODEL DSECT ,                   RESTORE SYM CARD GENERATION    UF023
         END
./ ADD NAME=SYSOUT   8003-02173-02181-1553-00414-00413-00000-GREG
SYSOUT   QSTART 'QUEUE COMMAND - MANIPULATE SYSOUT'
***********************************************************************
* RNB CHANGES:                                                        *
*      (1) RNB00 - MOVED THINGS AROUND FOR FOX ASSEMBLER              *
*      (2) RNB08 - ALLOW CANCEL/REQ/DEL IF JOBNAME STARTS WITH USERID *
*                  OR NOTIFY IS FOR USERID, UNLESS JOB SUBMITTED FROM *
*                  PJS. ALLOW TEC USERS TO MANIPULATE OTHER TEC USER'S*
*                  JOBS, AND ALSO STC'S.  KEYED TO QRNB=1             *
*      (3) RNB09 - FOR A REQ COMMAND, IF NO NEWCLASS GIVEN USE CLASS C*
*                  KEYED TO QRNB=1.                                   *
***********************************************************************
         GBLB  &QRNB                                              RNB08
         USING QCKPT,R10
         L     R10,QVCKPT
         USING QDISPLAY,R9
         L     R9,QVDSPL
         USING WORK,R13
***********************************************************************
*                                                                     *
*   TEST AUTHORIZATION OF QUEUE                                       *
*                                                                     *
***********************************************************************
**       TESTAUTH FCTN=1          TEST AUTHORIZATION OF USER
**       LTR   R15,R15            ?/AUTHORIZED
**       BZ    FJOB               YES. KEEP ON TRUCKING
         TM    QFLAG1,QFLG1APF    ?/AUTHORIZED                    GP@P6
         BO    FJOB               YES. KEEP ON TRUCKING           GP@P6
         QTILT ' *** FUNCTION IS NOT AUTHORIZED ***'
***********************************************************************
*                                                                     *
*   CALL FINDJOB TO LOCATE THE JQE, JCT AND IOT                       *
*                                                                     *
***********************************************************************
FJOB     L     R15,=V(FINDJOB)    ADDR OF MODULE TO FIND JOB
         BALR  R14,R15            GO TO IT
***********************************************************************
*                                                                     *
*   VALIDATE THE JOBNAME                                              *
*                                                                     *
***********************************************************************
         LA    R2,QLOGON          START ADDR OF QLOGON
         LR    R3,R2              SAVE START ADDR
         LA    R4,7               MAX LENGTH OF LOGON ID
VALID000 CLI   0(R2),C' '         ?/END OF LOGON ID
         BE    VALID010           YES. CONTINUE PROCESSING
         LA    R2,1(R2)           NO.  POINT TO NEXT FIELD
         BCT   R4,VALID000        GO CHECK AGAIN
VALID010 SR    R2,R3              LENGTH OF LOGON ID
         BCTR  R2,R0              DECREMENT FOR EXECUTE INSTRUCTION
         USING JCTSTART,R4        BASE REG FOR JCT
         L     R4,QCJCTA          A(JCT)
         EX    R2,VERJOBN         ?/JOB BELONGS TO USER
         AIF   (NOT &QRNB).RNB08A                                 RNB08
         BE    OK                 YES - LET IT GO                 RNB08
         CLC   =C'PJS',QLOGON IS THIS A PJS USER?                 RNB08
         BE    WRONGJOB       YES - INVALID                       RNB08
         BAL   R6,NOPJSJOB    ENSURE NOT A PJS JOB FOR CAN/DEL    RNB08
         CLC   QLOGON(*-*),JCTTSUID  ** EXECUTED **               RNB08
         EX    R2,*-6         IS THE USERID SAME AS NOTIFY ID?    RNB08
         BE    OK             YES - OK                            RNB08
         CLC   =C'TEC',QLOGON   IS THIS A TEC USER?               RNB08
         BNE   WRONGJOB         NO  - INVALID                     RNB08
         TM    JCTJOBFL,JCTSTCJB   IS IT AN STC?                  RNB08
         BO    OK                  /YES - OK FOR TEC USER         RNB08
         CLC   =C'TEC',JCTJNAME IS JOBNAME FOR A TEC USER?        RNB08
         BE    OK               YES - OK                          RNB08
         CLC   =C'TEC',JCTTSUID IS NOTIFY FOR A TEC USER?         RNB08
.RNB08A  ANOP                                                     RNB08
*        BNE   WRONGJOB           NO. GO TELL HIM  DELETED VBA01
OK       EQU   *                                                  RNB08
***********************************************************************
*                                                                     *
*   VALIDATE THE FUNCTION CODE                                        *
*                                                                     *
***********************************************************************
         LH    R1,QCODEH          GET FUNCTION CODE
         CH    R1,=H'8'           ?/VALID FUNCTION CODE
         BH    STOP               NO. EXIT
***********************************************************************
*                                                                     *
*   BRANCH TO THE APPROPIATE PROCESSOR                                *
*                                                                     *
***********************************************************************
         LA    R7,SSOBHDR         ADDR FOR SUBSYSTEM OPTION BLOCK
         USING SSOB,R7
         B     *+4(R1)
         B     DELETE             0   DELETE REQUEST
         B     REQUEUE            4   REQUEUE REQUEST
         B     CANCEL             8   CANCEL REQUEST
***********************************************************************
*                                                                     *
*   PROCESS CANCEL REQUEST                                            *
*                                                                     *
***********************************************************************
CANCEL   LA    R5,SSCSBGN         A(CANCEL PARAMETER LIST)
         BAL   R6,INITSSOB        GO INITIALIZE THE SSOB.
         MVC   SSOBFUNC,=AL2(SSOBCANC)  SET THE FUNCTION
         XC    SSCSBGN(SSCSIZE),SSCSBGN CLEAR PARM LIST
         MVC   SSCSLEN,=AL2(SSCSIZE) SET LENGTH OF CANCEL PARM LIST
         CLI   QPARM2,C'P'        ?/PURGE THE OUTPUT
         BNE   CAN000             NO. DON'T SET THE FLAG
         OI    SSCSFLGS,SSCSCOUT  YES
CAN000   MVC   SSCSJOBN,JCTJNAME  JOBNAME
         MVC   SSCSJOBI,JCTJOBID  JES2 JOB ID
         MVC   SSCSDIMP,=H'16'
         LA    R5,SSCSJOBI        A(JES2 JOB ID)
         BAL   R6,FIXJOBID        ENSURE JOBID HAS NO IMBEDDED BLANKS
         BAL   R6,VERREQ          VERIFY THE REQUEST
         BAL   R6,CALLSSI         GO CALL SUBSYSTEM INTERFACE RTN
         L     R1,SSOBRETN        GET RC FOR CANCEL FUNCTION
         B     *+4(R1)
         B     FUNCTOK            0 -  CANCEL COMPLETED
         B     TILTNOJB           4 -  JOBNAME NOT FOUND
         B     TILTBADI           8 -  INVALID JOBNAME/JOB ID COMB.
         B     TILTNCAN           12 - JOB NOT CANCELLED - DUP JOBN
         B     TILTMALL           16 - STATUS ARRAY TOO SMALL
         B     TILTOUTP           20 - JOB NOT CANCELLED - ON OUTPUT Q
         B     TILTYNTX           24 - JOB ID WITH INVALID SYNTAX
         B     TILTICAN           28 - INVALID CANCEL REQUEST
***********************************************************************
*                                                                     *
*   PROCESS REQUEUE REQUEST                                           *
*                                                                     *
***********************************************************************
REQUEUE  LA    R5,SSSOBGN         A(REQUEUE SYSOUT PARM LIST)
         BAL   R6,INITSSOB        GO INITIALIZE THE SSOB
         AIF   (NOT &QRNB).RNB09B                                 RNB09
         CLI   QPARM2,C' '        WAS NEW CLASS GIVEN?            RNB09
         BNE   RNB09A             /YES - USE IT                   RNB09
         MVI   QPARM2,C'C'        /NO  - DEFAULT TO CLASS C       RNB09
RNB09A   EQU   *                                                  RNB09
.RNB09B  ANOP                                                     RNB09
         MVC   SSOBFUNC,=AL2(SSOBSOUT) INDICATE SYSOUT IS THE FUNCTION
         XC    SSSOBGN(SSSOSIZE),SSSOBGN CLEAR PARM LIST
         MVC   SSSOLEN,=AL2(SSSOSIZE) SET LENGTH OF SYSOUT PARM LIST
         OI    SSSOUFLG,SSSOSETC  USE SSSOCLAS AS DISP
         OI    SSSOUFLG,SSSORLSE  RELEASE ALL SELECTED DATA SETS
         OI    SSSOFLG1,SSSOHLD   SELECTION INCLUDES HELD SYSOUT DS
         OI    SSSOFLG1,SSSOSJBN  JOB NAME IS PRESENT
         OI    SSSOFLG1,SSSOSJBI  JOB ID IS PRESENT
         OI    SSSOFLG2,SSSOCTRL  PROCESSING COMPLETED
         MVC   SSSOJOBN,JCTJNAME  JOBNAME
         MVC   SSSOJOBI,JCTJOBID  JOB ID
         MVC   SSSOCLAS,QPARM2    NEWCLASS
         LA    R5,SSSOJOBI        A(JES JOB ID)
         BAL   R6,FIXJOBID        ENSURE JOBID HAS NO EMBEDDED BLANKS
         BAL   R6,VERREQ          VERIFY THE REQUEST
         BAL   R6,CALLSSI         GO CALL SUBSYSTEM INTERFACE RTN
CHKSORC  L     R1,SSOBRETN        GET RETURN CODE FOR SYSOUT FUNCTION
         B     *+4(R1)
         B     FUNCTOK            0 -  SYSOUT COMPLETED
         B     TILTEODS           4 -  NO MORE DS TO SELECT
         B     TILTNJOB           8 -  JOB NOT FOUND
         B     TILTINVA           12 - INVALID SEARCH ARGUMENTS
         B     TILTUNAV           16 - UNABLE TO PROCESS NOW
         B     TILTDUPJ           20 - DUPLICATE JOB NAMES
         B     TILTINVJ           24 - INVALID JOBN/JOBID COMBO
         B     TILTIDST           28 - INVALID DEST SPECIFIED
***********************************************************************
*                                                                     *
*   PROCESS DELETE  REQUEST                                           *
*                                                                     *
***********************************************************************
DELETE   LA    R5,SSSOBGN         A(DELETE SYSOUT PARM LIST)
         BAL   R6,INITSSOB        GO INITIALIZE THE SSOB
         MVC   SSOBFUNC,=AL2(SSOBSOUT) INDICATE SYSOUT IS THE FUNCTION
         XC    SSSOBGN(SSSOSIZE),SSSOBGN CLEAR PARM LIST
         MVC   SSSOLEN,=AL2(SSSOSIZE) SET LENGTH OF SYSOUT PARM LIST
         OI    SSSOUFLG,SSSODELC  INDICATE DELETE REQUEST
         OI    SSSOFLG1,SSSOHLD   SELECTION INCLUDES HELD DS
         OI    SSSOFLG1,SSSOSJBN  JOB NAME PRESENT
         OI    SSSOFLG1,SSSOSJBI  JES2 JOB ID PRESENT
         OI    SSSOFLG2,SSSOCTRL  PROCESSING COMPLETED
         MVC   SSSOJOBN,JCTJNAME  JOBNAME
         MVC   SSSOJOBI,JCTJOBID  JES2 JOBID
         LA    R5,SSSOJOBI        A(JES2 JOBID)
         BAL   R6,FIXJOBID        ENSURE JOBID HAS NO EMBEDDED BLANKS
         BAL   R6,VERREQ          VERIFY THE REQUEST
         BAL   R6,CALLSSI         GO CALL SUBSYSTEM INTERFACE RTN.
         B     CHKSORC            GO CHECK RC
***********************************************************************
*                                                                     *
*   INITIALIZE THE SUBSYSTEM OPTION BLOCK (SSOB)                      *
*                                                                     *
*        R5 - ADDRESS OF FUNCTION PARM LIST                           *
*        R6 - RETURN ADDRESS                                          *
*        R7 - A(SSOB)                                                 *
*                                                                     *
***********************************************************************
INITSSOB XC    SSOBEGIN(SSOBHSIZ),SSOBEGIN CLEAR THE SSOB
         MVC   SSOBID,=C'SSOB'
         MVC   SSOBLEN,=AL2(SSOBHSIZ) LENGTH OF SSOB HEADER
         ST    R5,SSOBINDV        FUNCTION DEPENDENT AREA POINTER
         ST    R7,SSOBPTR         SAVE ADDR OF SSOB
         OI    SSOBPTR,X'80'      REQUIRED FOR IEFSSREQ INTERFACE
         BR    R6
***********************************************************************
*                                                                     *
*   REMOVE EMBEDDED BLANKS IN JES2 JOB ID                             *
*                                                                     *
***********************************************************************
FIXJOBID LA    R8,5               MAX LENGTH OF SCAN
         LA    R5,3(R5)           START LOCATION FOR SCAN
FIX000   CLI   0(R5),C' '         ?/EMBEDDED BLANK
         BNE   FIX010             NO. CONTINUE WITH THE SCAN
         MVI   0(R5),C'0'         YES. REPLACE WITH 0
FIX010   LA    R5,1(R5)           POINT TO NEXT BYTE
         BCT   R8,FIX000          GO DO IT AGAIN
         BR    R6                 ALL OVER. RETURN TO CALLER
***********************************************************************
*                                                                     *
*   TELL THE USER WHAT HE IS ABOUT TO DO                              *
*                                                                     *
***********************************************************************
VERREQ   QHEAD WARNING,X'23'      WARNING IN PINK REVERSE VIDEO   GP@P6
         L     R15,QDHLINE@       POINT TO HEADING LINE           GP@P6
         USING VCLEAR,R15                                         GP@P6
         MVC   VJOBN(8),JCTJNAME
         MVC   VJOBID(8),JCTJOBID
         LR    R2,R6              SAVE RETURN ADDR
         LA    R5,VJOBID          A(JES JOB ID)
         BAL   R6,FIXJOBID        INSURE NO IMBEDDED BLANKS
         LR    R6,R2              RESTORE RETURN ADDR
         CLI   QSUBNAME,C'D'      ?/DELETE COMMAND
         BNE   VER000
         MVC   VCMD(6),=C'DELETE'
         B     VER020
VER000   CLI   QSUBNAME,C'C'      ?/CANCEL COMMAND
         BNE   VER010
         MVC   VCMD(6),=C'CANCEL'
         CLI   QPARM2,C'P'        PURGE SPECIFIED
         BNE   VER020
         MVC   VACTION(5),QPARM2
         B     VER020
VER010   MVC   VCMD(7),=C'REQUEUE'
         MVC   VACTION,RQACTION
         MVC   VCLASS(1),QPARM2
         DROP  R15                                                GP@P6
VER020   MVC   QDMLNG,=H'0'       TELL DISPLAY TO PRINT IT NOW
         L     R15,=V(DISPLAY)    A(MODULE TO DISPLAY THE MESSAGE)
         BALR  R14,R15            GO DISPLAY THE WARNING
         BR    R6                 RETURN TO THE CALLER
***********************************************************************
*                                                                     *
*   INTERFACE TO THE SUBSYSTEM                                        *
*                                                                     *
***********************************************************************
CALLSSI  L     R2,16              A(CVT)
         L     R2,296(R2)         A(JESCT)
         MODESET MODE=SUP         GET SUPER
         LA    R1,SSOBPTR         ADDR OF PTR TO SSOB
         L     R15,20(R2)         A(JESSSREQ)
         BALR  R14,R15
         LR    R2,R15             SAVE RETURN CODE
         MODESET MODE=PROB        BACK TO NORMAL
         B     *+4(R2)
         BR    R6                 0 -  SUCCESSFUL INSTRUCTION
         BR    R6                      DUMMY INSTRUCTION
         B     TILTNSUP           4 -  SS DOESN'T SUPPORT THIS FUNCTION
         B     TILTNTUP           8 -  SS EXIST, BUT IS NOT UP
         B     TILTNOSS           12 - SS DOES NOT EXIST
         B     TILTDIST           16 - FUNCTION NOT SUPPORTED
         B     TILTLERR           20 - LOGICAL ERROR
         AIF   (NOT &QRNB).RNB08B                                 RNB08
******************************************************************RNB08
*                                                                *RNB08
*   TILT IF PJS JOB (ONLY FOR CANCEL OR DELETE)                  *RNB08
*                                                                *RNB08
******************************************************************RNB08
         USING PDBDSECT,R1                                        RNB08
         USING IOTDSECT,R3                                        RNB08
*        USING USERIDLEN,R2                                       RNB08
NOPJSJOB CLI   QCODEH+1,4     IS THIS A REQUEUE?                  RNB08
         BER   R6             /YES - OK FOR NOW                   RNB08
*                             /NO  - ENSURE NOT A PJS JOB         RNB08
         L     R3,QCIOTA      LOAD BASE REG                       RNB08
         LR    R5,R3          BASE OF IOT                         RNB08
         A     R5,IOTPDDBP    OFFSET BEYOND LAST PDDB             RNB08
         LR    R1,R3          BASE OF IOT                         RNB08
         A     R1,QCPDDB1     OFFSET TO FIRST PDDB IN IOT         RNB08
         MVC   QPDSID,=H'0'   NULLIFY VALIDITY FOR LISTDS         RNB08
FINDDS   CLC   =H'5',PDBDSKEY IS THIS THE DATASET?                RNB08
         BE    FOUNDDS        YES. CONTINUE.                      RNB08
         LA    R1,PDBLENG(R1) NO. LOOK AT NEXT PDDB.              RNB08
         CR    R1,R5          HAVE WE GONE PAST THE LAST PDDB?    RNB08
         BL    FINDDS         NO. TRY AGAIN.                      RNB08
         B     BADDDTAB       ELSE BAD DD TABLE (INTERP. JCL)     RNB08
FOUNDDS  L     R5,PDBMTTR     DISK ADDR OF FIRST BLOCK            RNB08
         DROP  R1                                                 RNB08
         L     R7,QCBLKA      ADDR OF DATASET BLOCK IOAREA        RNB08
         MVC   QDMSG,QBLANK   BLANK OUT THE MESSAGE AREA          RNB08
         ST    R5,QCTRAK      STORE DISK ADDR                     RNB08
         LR    R1,R7          IOAREA ADDRESS                      RNB08
         L     R15,=V(READSPC) ADDR OF ROUTINE TO READ HASPACE    RNB08
         BALR  R14,R15        GO TO IT                            RNB08
         LA    R5,10(R7)      ADDR OF FIRST RECORD IN BLOCK       RNB08
         SR    R7,R7          ZERO OUT REG                        RNB08
         IC    R7,0(R5)       INSERT LENGTH                       RNB08
         CLI   5(R5),1        IS THIS A JOB RECORD?               RNB08
         BNE   BADDDTAB       /NO  - INVALID DD TABLE             RNB08
         LA    R5,9(R5)       ADDR OF FIRST KEY                   RNB08
         LR    R8,R7          REMAINING LENGTH OF RECORD          RNB08
         SR    R15,15         ZERO OUT R15                        RNB08
         SR    R14,R14        ZERO OUT R14                        RNB08
         SR    R1,R1          ZERO OUT R1                         RNB08
TRYFLD   CLI   0(R5),X'A5'    IS THIS THE USER= PARM?             RNB08
         BE    GOTUSER        YES. PROCESS IT.                    RNB08
NEXTFLD  IC    R1,1(R5)       NUMBER OF SUBFIELDS                 RNB08
         LA    R5,2(R5)       UPDATE LOCATION                     RNB08
         SH    R8,=H'2'       REMAINING COUNT                     RNB08
         SR    R8,R1          REMAINING COUNT                     RNB08
         BNP   BADDDTAB       RECORD IS EXHAUSTED                 RNB08
         LTR   R1,R1          ARE THERE ANY SUBFIELDS?            RNB08
         BZ    TRYFLD         NO. TRY NEXT FIELD.                 RNB08
LOOPFLD  TM    0(R5),X'80'    IS THIS A SUB-SUB-FIELD             RNB08
         BZ    NOSUB          NO. CONTINUE.                       RNB08
         NI    0(R5),X'7F'    CLEAR THE HEX 80 BIT                RNB08
         IC    R14,0(R5)      NUMBER OF SUB-SUB-FIELDS            RNB08
         LA    R5,1(R5)       UPDATE LOCATION                     RNB08
         SH    R8,=H'1'       REMAINING COUNT                     RNB08
         SR    R8,R14         REMAINING COUNT                     RNB08
         BNP   BADDDTAB       RECORD IS EXHAUSTED                 RNB08
         AR    R1,R14         INCREASE NUMBER OF SUBFIELDS        RNB08
         B     YESSUB         DECREMENT AND TRY AGAIN             RNB08
NOSUB    IC    R15,0(R5)      SUBFIELD LENGTH                     RNB08
         LA    R5,1(R15,R5)   ADD TO LOCATION                     RNB08
         SR    R8,R15         REMAINING COUNT                     RNB08
         BNP   BADDDTAB       RECORD IS EXHAUSTED                 RNB08
YESSUB   BCT   R1,LOOPFLD     DO NEXT SUBFIELD                    RNB08
         B     TRYFLD         TRY NEXT FIELD                      RNB08
GOTUSER  CLI   2(R5),7        IS USER ID LENGTH = 7?              RNB08
         BNER  R6             /NO  - NOT A PJS JOB, OK TO PROCESS RNB08
         CLI   2(R5),0        IS THE LENGTH ZERO?                 RNB08
         BER   R6             YES. SKIP THE FIELD.                RNB08
         CLC   =C'PROD',6(R5) IS IT A PJS JOB? (USER = ???PROD)   RNB08
         BE    PJSMSG         /YES - BAD                          RNB08
         BR    R6             /NO  - GO PROCESS                   RNB08
BADDDTAB QTILT '*** CANNOT PROCESS JOB - DDTABLE MISSING/INVALID' RNB08
PJSMSG   QTILT '*** CANNOT CAN/DEL JOB SUBMITTED VIA PJS ***'     RNB08
.RNB08B  ANOP                                                     RNB08
***********************************************************************
*                                                                     *
*   RETURN TO CALLER                                                  *
*                                                                     *
***********************************************************************
STOP     QSTOP
FUNCTOK  QTILT ' *** COMMAND SUCCESSFULLY PROCESSED ***'
***********************************************************************
*                                                                     *
*   ERROR MESSAGES                                                    *
*                                                                     *
***********************************************************************
WRONGJOB QTILT ' *** JOBNAME DOES NOT BELONG TO YOU ***'
TILTNSUP QTILT ' *** QUEUE LOGIC ERROR -- RC =4  FROM SSI ***'
TILTNTUP QTILT ' *** JES2 IS NOT UP ***'
TILTNOSS QTILT ' *** QUEUE LOGIC ERROR -- RC =12 FROM SSI ***'
TILTDIST QTILT ' *** DISASTROUS ERROR DURING PROCESSING ***'
TILTLERR QTILT ' *** QUEUE LOGIC ERROR -- RC =20 FROM SSI ***'
TILTNOJB EQU   *
TILTNJOB QTILT ' *** JOBNAME NOT FOUND ***'
TILTBADI EQU   *
TILTINVJ QTILT ' *** INVALID JOBNAME/JOB ID COMBINATION ***'
TILTNCAN EQU   *
TILTDUPJ QTILT ' *** DUPLICATE JOBNAME AND NO JOBID GIVEN ***'
TILTEODS QTILT ' *** JOB HAS NO HELD DATA SETS ***'
TILTICAN QTILT ' *** CAN''T CANCEL YOUR TSO SESSION OR A STARTED TASK *X
               **'
TILTOUTP QTILT ' *** JOB NOT CANCELLED - JOB ON OUTPUT QUEUE ***'
TILTMALL EQU   *
TILTYNTX EQU   *
TILTINVA EQU   *
TILTUNAV EQU   *
TILTIDST QTILT ' *** QUEUE LOGIC ERROR ***'
***********************************************************************
*                                                                     *
*   MISCELLANEOUS NUTS, BOLTS, ETC.                                   *
*                                                                     *
***********************************************************************
VERJOBN  CLC   QLOGON(*-*),JCTJNAME
WARNING  DS    0CL80
         DC    CL21' *** '
         DC    CL1'('
         DC    CL8' '
         DC    CL1')'
         DC    CL12' '
         DC    CL37'. HIT ENTER IF OK OR RESPECIFY. ***'
RQACTION DC    CL11'NEWCLASS( )'
         LTORG
         DROP  ,                   DROP ALL ADDRESSINGS           NERDC
SYMDEL   DSECT ,                   KILL SYM CARD GENERATION       UF023
SYSOUT   CSECT ,                                                  UF023
JCT      EQU   0
BUFSTART EQU   0
BUFDSECT EQU   0
         $TAB
         $JCT
         $PDDB                                                    RNB00
         $IOT                                                     RNB00
         IEFJSSOB (SO,CS),CONTIG=YES
         QCOMMON
VCLEAR   DSECT                                                    GP@P6
         DS    CL5
VCMD     DS    CL8
VJOBN    DS    CL9
VJOBID   DS    CL10
VACTION  DS    CL11
         DS    CL37
VCLASS   EQU   VACTION+9
WORK     DSECT
FILLER   DS    CL512              BIG FILLER
SSOBPTR  DS    F
SSOBHDR  DS    CL140
SYMNODEL DSECT ,                   RESTORE SYM CARD GENERATION    UF023
         END
./ ADD NAME=TABLE
//COMMANDS EXEC ASMFCL,PARM.LKED='LET,LIST,RENT,REUS'
//ASM.SYSIN DD *
         ENTRY APFCTABL
IKJEFTE2 CSECT
         DC    CL8'IKJEFTE2'
         DC    CL8'06.01.80'
APFCTABL DC    CL8'QUEUE   '       QUEUE COMMAND
         DC    CL8'Q       '       ALIAS
         DC    CL8'CMD1    '       SPARE TABLE ENTRIES
         DC    CL8'CMD2    '       SPARE TABLE ENTRIES
         DC    CL8'CMD3    '       SPARE TABLE ENTRIES
         DC    CL8'        '       8 BLANKS TABLE TERMINATOR
         END
/*
//LKED.SYSLMOD DD DSN=T90000.IPO38.GENLIB(IKJEFTE2),DISP=SHR
//*
//* CHANGE SYSLMOD TO WHATEVER LIBRARY YOU USE TO HOLD SYSTEM MODULES
//*
//TSOCMDS EXEC IPOSMP4
//SMP.SMPCNTL DD *
  RECEIVE S(TR00003).
  APPLY S(TR00003) DIS(WRITE).
/*
//*
//* THE VERIFY CARD BELOW IS SET UP FOR A MVS 3.8 SYSTEM WITH THE
//* TSO COMMAND PACKAGE INSTALLED. IF YOU DON'T HAVE THE COMMAND
//* PACKAGE YOU WILL NEED TO MODIFY THE VERIFY TO MATCH YOUR
//* SYSTEM ENVIRONMENT.
//*
//SMP.SMPPTFIN DD *
++ USERMOD(TR00003) /* TSO AUTHORIZED COMMANDS */.
++ VER(Z038) FMID(EBB1102) PRE(JBB1112).
++ MOD(IKJEFTE2) DISTLIB(AOST4) LKLIB(GENLIB).
/*
//GENLIB DD DSN=T90000.IPO38.GENLIB,DISP=SHR
//*
//* CHANGE GENLIB TO WHATEVER LIBRARY YOU USE TO HOLD SYSTEM MODULES
//*
./ ADD NAME=TSOHELP
)F FUNCTION -
  THE QUEUE COMMAND IS USED TO INTERROGATE THE SYSTEM QUEUES IN ORDER
  TO DETERMINE THE STATUS OF A JOB OR GROUP OF JOBS. IT ALSO PROVIDES
  ACCESS TO ALL PARTS OF A JOB WHILE IT IS ON THE QUEUE.

  FOR MORE INFORMATION, TYPE IN - QUEUE HELP.
)X SYNTAX -
         QUEUE  OPERAND    DEFAULT OPERAND IS STATUS. AN OPERAND OF
         Q                 CKPT(UNIT,VOLSER) CAN BE USED TO SPECIFY
                           A JES2 CHECKPOINT DATASET OTHER THAN THE
                           STANDARD DATASET.

./ ADD NAME=XDS
XDS      QSTART 'QUEUE COMMAND - PRINT A DATASET FROM SPOOL BY ID'
***********************************************************************
* RNB CHANGES:                                                        *
*      (1) RNB03 - RACF SUPPORT. HANDLE XDS COMMAND SPECIALLY.        *
*                                                                     *
***********************************************************************
         GBLB  &QRACF                                             RNB03
         USING QCKPT,R10      BASE REG FOR CKPT WORK AREA
         L     R10,QVCKPT     LOAD BASE REG
         USING WORK,R13       BASE REG FOR TEMP WORK
***********************************************************************
*                                                                     *
*   CALL FINDJOB TO LOCATE THE JQE, JCT, AND IOT                      *
*                                                                     *
***********************************************************************
         L     R15,=V(FINDJOB) ADDR OF MODULE TO FIND JOB
         BALR  R14,R15        GO TO IT
         AIF   (NOT &QRACF).RNB03B                                RNB03
***************************************************************** RNB03
*                                                               * RNB03
*  RACF FOR XDS COMMAND: RACHECK FOR APPL-QUEUEXDS AND PASS     * RNB03
*                        THE JOBNAME AS THE APPL FOR LOGGING    * RNB03
*                                                               * RNB03
***************************************************************** RNB03
         L     R2,QCJCTA      GET JCT                             RNB03
         USING JCTDSECT,R2    #####                               RNB03
         RACHECK ENTITY=QRACNMXD,APPL=JCTJNAME,MF=(E,QRACHECK)    RNB03
         LTR   R15,R15        OK?                                 RNB03
         BZ    RNB03A         /YES - CONTINUE                     RNB03
         QTILT '*** XDS COMMAND NOT ALLOWED ***'                  RNB03
         DROP  R2                                                 RNB03
RNB03A   DS    0H                                                 RNB03
.RNB03B  ANOP                                                     RNB03
***********************************************************************
*                                                                     *
*   CHECK AND CONVERT THE DATASET ID NUMBER                           *
*                                                                     *
***********************************************************************
         LH    R2,QLNG2       LENGTH OF DATASET ID FIELD
         SH    R2,=H'1'       IS THE DATASET ID FIELD ZERO LENGTH?
         BM    TILT           YES. QUIT.
         MVC   QFZONES,QFZONE INITIALIZE NUMERIC TEST
         EX    R2,MVZ         MOVE THE ZONES FOR VALIDITY CHECK
         CLC   QFZONES,QFZONE IS THE FIELD NUMERIC?
         BNE   TILT           NO. QUIT.
         EX    R2,PACK        PACK THE FIELD
         CVB   R2,CONVERT     CONVERT TO BINARY
         STH   R2,QPDSID      STORE DATASET ID
***********************************************************************
*                                                                     *
*   CHECK AND CONVERT THE PRINT OFFSET                                *
*                                                                     *
***********************************************************************
         MVC   QPOFFSET,=H'0' DEFAULT TO ZERO
         LH    R2,QLNG3       LENGTH OF OFFSET FIELD
         SH    R2,=H'1'       IS THE OFFSET FIELD ZERO LENGTH?
         BM    CALLLIST       YES. USE ZERO OFFSET.
         MVC   QFZONES,QFZONE INITIALIZE NUMERIC TEST
         EX    R2,MVZ2        MOVE THE ZONES FOR VALIDITY CHECK
         CLC   QFZONES,QFZONE IS THE FIELD NUMERIC?
         BNE   TILT           NO. QUIT.
         EX    R2,PACK2       PACK THE FIELD
         CVB   R2,CONVERT     CONVERT TO BINARY
         STH   R2,QPOFFSET    STORE OFFSET
***********************************************************************
*                                                                     *
*   CALL LISTDS TO LIST THE DATASET                                   *
*                                                                     *
***********************************************************************
CALLLIST L     R15,=V(LISTDS) ADDR OF LISTDS MODULE
         BALR  R14,R15        GO TO IT
         QSTOP
TILT     QTILT '*** DATASET ID INVALID ***'
***********************************************************************
*                                                                     *
*   MISCELLANY                                                        *
*                                                                     *
***********************************************************************
MVZ      MVZ   QFZONES(1),QPARM2 CHECK FOR NUMERIC
MVZ2     MVZ   QFZONES(1),QPARM3 CHECK FOR NUMERIC
PACK     PACK  CONVERT,QPARM2(1) CONVERT TO BINARY
PACK2    PACK  CONVERT,QPARM3(1) CONVERT TO BINARY
         LTORG
SYMDEL   DSECT ,                   KILL SYM CARD GENERATION       UF023
WORK     DSECT
         DS    72C
CONVERT  DS    D
         AIF   (NOT &QRACF).RNB03C                                RNB03
XDS      CSECT                                                    RNB03
JCT      EQU   0                                                  RNB03
BUFSTART EQU   0                                                  RNB03
BUFDSECT EQU   0                                                  RNB03
         $JCT                                                     RNB03
.RNB03C  ANOP                                                     RNB03
         QCOMMON
SYMNODEL DSECT ,                   RESTORE SYM CARD GENERATION    UF023
         END
./ ENDUP       "REVIEW" PDS MEMBER OFFLOAD AT 14:47 ON 07-01-01

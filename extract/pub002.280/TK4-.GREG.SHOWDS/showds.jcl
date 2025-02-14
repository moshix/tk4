//GREGSDS  JOB (SYS),G.PRICE,CLASS=A,MSGCLASS=X,MSGLEVEL=(1,1),
//             NOTIFY=GREG,REGION=2048K,COND=(0,NE)
//* ********************************************************
//* *                                                      *
//* *      INSTALL THE 'SHOWDS' TSO COMMAND                *
//* *                                                      *
//* ********************************************************
//ASM     EXEC PGM=IFOX00,
//             PARM='NODECK,LOAD,RENT,TERM'
//SYSGO    DD  DSN=&&LOADSET,DISP=(MOD,PASS),SPACE=(CYL,(1,1)),
//             UNIT=VIO,DCB=(DSORG=PS,RECFM=FB,LRECL=80,BLKSIZE=800)
//SYSLIB   DD  DSN=SYS1.MACLIB,DISP=SHR
//SYSTERM  DD  SYSOUT=*
//SYSPRINT DD  SYSOUT=*
//SYSPUNCH DD  DSN=NULLFILE
//SYSUT1   DD  UNIT=VIO,SPACE=(CYL,(6,1))
//SYSUT2   DD  UNIT=VIO,SPACE=(CYL,(6,1))
//SYSUT3   DD  UNIT=VIO,SPACE=(CYL,(6,1))
//SYSIN    DD  *
         TITLE '   S H O W D S    '
************************************************************
*                                                          *
*        'SHOWDS'                                          *
*                                                          *
************************************************************
         SPACE 3
*        WRITTEN BY: BILL GODFREY,  PLANNING RESEARCH CORPORATION.
*        INSTALLATION: PRC COMPUTER CENTER INC, MCLEAN VA
*        DATE WRITTEN: NOVEMBER 5 1976.
*        DATE UPDATED: JANUARY 15 2002.
*        ATTRIBUTES: RE-ENTRANT, AMODE=24, RMODE=24.
*        DESCRIPTION:
*            THIS IS A TSO COMMAND SIMILAR TO 'LISTDS'.
*            IT SHOWS ADDITIONAL INFORMATION FROM THE DSCB
*            PERTAINING TO SPACE.  IT DOES NOT ALLOCATE THE DATA
*            SET UNLESS DIRECTORY INFORMATION IS REQUESTED.
*            NOTE - DEVICE TYPE IN CATALOG IS IGNORED.
*            NOTE - PRE-ALLOCATIONS ARE IGNORED.
*
*            THIS VERSION OF SHOWDS SHOULD FUNCTION CORRECTLY
*            FOR OS AND ICF (EDF) DATA SETS UNDER
*            MVS/370, OSIV/F4, MVS/XA, MVS/ESA AND OSIV MSP/EXA.
         EJECT
*         LOG OF CHANGES.
*            20MAR78 - IKJRLSA ADDED
*            25JUL78 - UCB LOOKUP ADDED
*            25JUL78 - OBTAIN WITH CATALOG'S DSCBTTR ADDED.
*            23FEB79 - ACCESS DATE ADDED (SU 60)
*            28FEB79 - FORMAT 4 OBTAIN ADDED FOR DEVICES
*                      OTHER THAN THOSE CURRENTLY INSTALLED.
*            01MAR79 - STACK DELETE ADDED IF RC NON-ZERO.
*            15JUN79 - CHECK FOR NEGATIVE TRACKS UNUSED.
*            14SEP79 - GBLB &MVS ADDED. EXPDT IF ACCESS ZERO.
*            14SEP79 - SVS/MVT CODE TO PREFIX DSNAME WITH USERID.
*            14APR80 - IKJPOSIT WITHOUT USID FOR MVT.  SYSPARM.
*            15APR80 - ADDED 2314. CANNOT OBTAIN-SEARCH FORMAT 4 ON MVT
*            24APR80 - MUST SPECIFY 'ACCESS' TO GET ACCESS DATE.
*            29MAY80 - SUPPORT FOR FILE KW ADDED (DEVTYPE, RDJFCB).
*                      PREFIXING DONE BY COMMAND INSTEAD OF PARSE.
*            30MAY80 - QUICK KW ADDED, TO BYPASS DEFAULT SERVICE
*                      ROUTINE IF YOU KNOW YOU SPECIFIED TRAILING
*                      QUALIFIERS ON UNQUOTED NAME AND WANT TO
*                      BYPASS THE EXTRA CATALOG SEARCH.
*            12FEB81 - DEVICE TYPE NOW DISPLAYED.
*                      PDS DIRECTORY INFO ADDED, IF 'DIR' SPECIFIED,
*                      BUT ONLY IF 'FILE' OPTION IS USED.
*            11MAR81 - VIO SUPPORT (VOL BLANK, UCB FROM TIOT).
*                      PDS DIRECTORY INFO NOW DISPLAYED, IF DIR IS
*                      SPECIFIED, EVEN IF FILE NOT SPECIFIED.
*                      WILL ALLOCATE THE DATA SET IF NECESSARY.
*                      SINCE WE DETERMINE THE VOLUME FROM THE
*                      CATALOG ONLY (IF IT IS NOT SPECIFIED), AND
*                      IN SO DOING WE IGNORE PRE-ALLOCATIONS, THE
*                      ALLOCATION REQUEST ALWAYS SPECIFIES THE VOLUME.
*            20APR81 - SHOW RACF PROTECTION.
*            09JUL81 - SHOW VIRTUAL 3330 AS 3330V. SHOW DIRBLKS USED
*                      IN ADDITION TO UNUSED. SHOW TOTAL MEMBERS.
*                      EXTENTS KEYWORD ADDED.
*            01SEP81 - ADD UNITNAME TO DAIR PARAMETERS, SO ALLOCATION
*                      WILL WORK REGARDLESS OF USER'S DEFAULT UNITNAME.
*                      UNIT CHARACTERISTICS ARE NOW IN A TABLE.
*                      DONT SHOW TOTAL MEMBERS IF THERE ARE NO ALIASES.
*            27JAN84 - ADDED 3380 AND 2305-2 TO DEVICE LIST.    GP@SECV
*            15MAR85 - SHOW BOTH ACCESS AND EXPIRY DATES,
*                      AND REMOVE CORRESPONDING COMMAND OPERANDS. @SECV
*            09DEC85 - SHOW STATUS AS MODIFIED IF DS1DSCHA BIT ON FOR
*                      UNKEYED FILES.  SUPPORT UP TO 255 EXTENTS. @SECV
*            05MAY86 - ADD SUPPORT FOR UCB LOOK-UP UNDER MVS/XA.  GP@P6
*            12AUG86 - FIXED BUG IN 255 EXTENT SUPPORT - FIRST FORMAT
*                      3 WAS OBTAINED FOR ALL FORMAT 3 DSCBS.     GP@P6
*            18MAR87 - CHANGE IKJEHDEF TO IKJDFLT FOR F4.         GP@P6
*            24MAR87 - SUPPORT CONCATENATED DATA SETS (NOT DIR).  GP@P6
*            22APR87 - ADD SUPPORT FOR ALL KNOWN DISKS.           GP@P6
*            06MAY89 - ADD SUPPORT FOR JFCBS ABOVE THE 16MB LINE. GP@P6
*            07AUG89 - SUPPRESS ARL EXIT CALL UNLESS REQUIRED, THUS
*                      CIRCUMVENTING AN ABEND0C4 IN SVC 64 (RDJFCB)
*                      FOR HDP2230 AND HDP3300 (POSSIBLY FIXED BY
*                      PUT8806).  ALSO SHOW SOME SMS DETAILS.     GP@P6
*            04JUN90 - ADD 3390 SUPPORT.  SHOW SMS REBLOCK AND
*                      SYSTEM-SUPPLIED-BLOCKSIZE FLAGS.           GP@P6
*            26JUN91 - FIX SMS SECONDARY QUANTITY CODE.
*                      ADD '-E' IN DSORG FOR PDSE.                GP@P6
*            25SEP91 - ADD SUPPORT FOR UCB LOOK-UP UNDER MSP EXA. GP@P6
*            18MAR92 - MAKE 'SYSALLDA' THE UNITNAME FOR 'DIR'
*                      ALLOCATION SO THAT 'DIR' CAN FUNCTION CORRECTLY
*                      EVEN IF DASD TYPE IS UNKNOWN AND/OR IF IBM
*                      DEVICE NAME IS NOT A UNITNAME (WHICH IS
*                      MOST LIKELY UNDER OSIV MSP).               GP@P6
*            28JAN93 - HANDLE EXTENTS OVER 32767 TRACKS.          GP@FT
*            13JUL93 - ADD SUPPORT FOR DEVICE TYPE 9345.          GP@FT
*            23NOV95 - REMOVE LEFT-JUSTIFIED UNIT NAME FROM
*                      DEVTABLE BECAUSE IT IS NOW NOT NEEDED (IT
*                      WAS USED FOR ALLOCATION).  ADD TRACK SIZE
*                      TO DEVTABLE TO ASCERTAIN UNIT DEVICE TYPE
*                      FROM FORMAT-4 DSCB.  IF MVS/SP4 OR LATER
*                      THEN ISSUE OBTAIN(S) EVEN IF UCB NOT FOUND
*                      WHICH MEANS SP5 ET AL IS SUPPORTED WITHOUT
*                      UPDATING UCB SCAN CODE.                    GP@FT
*            08NOV00 - SHOW HFS AND PS-E FOR STRIPE IN DSORG.     GP@HC
*            31AUG01 - DO NOT UPDATE REFERENCE DATE WITH 'DIR'.   GP@HC
*            15JAN02 - CHANGE DATE DISPLAY TO ISO FORMAT.         GP@HC
*            14APR06 - SHOW PS-L FOR LARGE SEQUENTIAL.            GP@P6
*
*            SPECIFYING SYSPARM(OS) TO THE ASSEMBLER WILL CAUSE
*            A VERSION FOR OS/MVT TO BE ASSEMBLED INSTEAD OF MVS.
         EJECT
         GBLB  &MVS
&MVS     SETB  ('&SYSPARM' NE 'OS')         1 - MVS   0 - OS/MVT
         SPACE
SHOWDS   START
         USING *,R12,R11
         B     @START-*(,15)
         DC    AL1(22),CL6'SHOWDS'
         DC    CL16' &SYSDATE &SYSTIME '
         DC    CL12'ALL-SYSTEMS '
         DC    CL25'(370/XA/ESA/390 EVEN MSP)'
@SIZE    DC    0F'0',AL1(1),AL3(@DATAL)
@START   STM   14,12,12(13)
         LR    R12,15
         LA    R11,4095
         LA    R11,1(R11,R12)
         LR    R2,R1
         USING CPPL,R2
         L     R0,@SIZE
         GETMAIN R,LV=(0)
         ST    13,4(,1)
         ST    1,8(,13)
         LR    13,1
         USING @DATA,13
         XC    LINKAREA(8),LINKAREA
         XC    RC(8),RC
         EJECT
************************************************************
*                                                          *
*        SET UP IOPL FOR PUTLINE                           *
*                                                          *
************************************************************
         SPACE
         LA    R15,MYIOPL
         USING IOPL,R15
         MVC   IOPLUPT(4),CPPLUPT
         MVC   IOPLECT(4),CPPLECT
         LA    R0,MYECB
         ST    R0,IOPLECB
         XC    MYECB,MYECB
         LA    R0,MYPTPB
         ST    R0,IOPLIOPB
         DROP  R15
         SPACE
         AIF   (NOT &MVS).SKIP1
         L     R15,16              LOAD CVT POINTER
         TM    444(R15),X'80'      IS PUTLINE LOADED? (MVS)
         BNO   PUTLOAD             NO - BRANCH TO LOAD
         L     R15,444(,R15)       YES - USE CVTPUTL
         B     PUTLOADX            BRANCH AROUND LOAD
.SKIP1   ANOP
PUTLOAD  LA    R0,=CL8'IKJPUTL '
         LOAD  EPLOC=(0)
         LR    R15,R0              GET ENTRY ADDRESS
         LA    R15,0(,R15)         CLEAR HI BYTE FOR DELETE ROUTINE
PUTLOADX ST    R15,MYPUTLEP        SAVE PUTLINE ENTRY ADDRESS
         SPACE
************************************************************
*                                                          *
*        SET UP PPL FOR PARSE                              *
*                                                          *
************************************************************
         SPACE 1
         LA    R15,MYPPL
         USING PPL,R15
         MVC   PPLUPT(4),CPPLUPT
         MVC   PPLECT(4),CPPLECT
         LA    R0,MYECB
         ST    R0,PPLECB
         XC    MYECB,MYECB
         L     R0,=A(SHOWDPCL)
         ST    R0,PPLPCL
         LA    R0,MYANS
         ST    R0,PPLANS
         MVC   PPLCBUF(4),CPPLCBUF
         LA    R0,MYUWA
         ST    R0,PPLUWA
         DROP  R15                 PPL
         SPACE 1
************************************************************
*                                                          *
*        CALL THE PARSE SERVICE ROUTINE                    *
*                                                          *
************************************************************
         SPACE 1
         LR    R1,R15              POINT TO PPL
         AIF   (NOT &MVS).SKIP2
         L     R15,16              CVTPTR
         TM    524(R15),X'80'      IF HI ORDER BIT NOT ON
         BNO   PARSELNK               THEN DO LINK, NOT CALL
         L     R15,524(,R15)       CVTPARS
         BALR  R14,R15             CALL IKJPARS
         B     PARSEEXT            SKIP AROUND LINK
PARSELNK EQU   *
.SKIP2   ANOP
         LINK  EP=IKJPARS,SF=(E,LINKAREA)
PARSEEXT EQU   *
         SPACE 1
         LTR   R15,R15
         BZ    PARSEOK
         LA    R1,MSG01
         LA    R0,L'MSG01
         BAL   R14,PUTMSG
         B     EXIT12
PARSEOK  EQU   *
         L     R3,MYANS
         USING IKJPARMD,R3
         LA    R9,DSN
         B     FIRSTDSN
         SPACE
NEXTD12  MVI   RC+1,12             SET RC=12
NEXTDSN  CLI   24(R9),X'FF'        END OF DSN LIST?
         BE    EXIT                YES - BRANCH
         L     R9,24(,R9)          POINT TO NEXT ENTRY
FIRSTDSN TM    6(R9),X'80'         DSN OMITTED (MEMBER ONLY)?
         BNZ   OKDSN               NO - BRANCH
         LA    R1,MSG02
         LA    R0,L'MSG02
         BAL   R14,PUTMSG
         B     NEXTD12
OKDSN    EQU   *
         LA    R15,DSNAME+2
         MVI   0(R15),C' '         BLANK THE DSNAME AREA
         MVC   1(43,R15),0(R15)
         SLR   R1,R1
         STH   R1,DSNAME           ZERO DSNAME LENGTH
         TM    6(R9),X'40'         IS DSN QUOTED?
         BO    NOPREF              YES, SKIP PREFIXING
         CLI   FILEKW+1,1          DSN TO BE TREATED AS DDNAME?
         BE    NOPREF              YES, SKIP PREFIXING
         AIF   (NOT &MVS).SKIPP    PREFIX WITH PREFIX
         L     R14,CPPLUPT         POINT TO UPT
         USING UPT,R14
         IC    R1,UPTPREFL         GET LENGTH OF PREFIX
         LTR   R1,R1               IS IT ZERO?
         BZ    NOPREF              YES, SKIP PREFIXING
         B     *+10
         MVC   0(0,R15),UPTPREFX
         DROP  R14                 UPT
.SKIPP   AIF   (&MVS).SKIPU        PREFIX WITH USERID
         L     R14,CPPLPSCB        POINT TO PSCB
         USING PSCB,R14
         IC    R1,PSCBUSRL         GET LENGTH OF USERID
         LTR   R1,R1               IS IT ZERO?
         BZ    NOPREF              YES, SKIP PREFIXING
         B     *+10
         MVC   0(0,R15),PSCBUSER
         DROP  R14                 PSCB
.SKIPU   ANOP
         EX    R1,*-6              MOVE USERID TO DSNAME AREA
         LA    R15,0(R1,R15)       POINT PAST USERID
         MVI   0(R15),C'.'         APPEND PERIOD
         LA    R15,1(,R15)         POINT PAST PERIOD
         LA    R1,1(,R1)           ADD 1 TO LENGTH
         STH   R1,DSNAME           STORE LENGTH OF USERID PLUS 1
NOPREF   EQU   *
         LH    R1,4(,R9)           GET LENGTH
         LR    R0,R1
         AH    R0,DSNAME
         STH   R0,DSNAME
         L     R14,0(,R9)          POINT TO DSN VALUE
         BCTR  R1,0
         B     *+10
         MVC   0(0,R15),0(R14)     (EXECUTED)
         EX    R1,*-6              MOVE DSN TO DSNAME
         SPACE
************************************************************
*                                                          *
*        IF 'FILE' KEYWORD IS SPECIFIED,                   *
*        GET DSNAME FROM JFCB USING FILE NAME.             *
*                                                          *
************************************************************
         SPACE
         XC    VOLUME(6),VOLUME
         XC    UCBPTR,UCBPTR
         XC    CONCTPTR,CONCTPTR
         XC    CONCTCNT,CONCTCNT
         XC    SDSARL(36),SDSARL   ZERO ALLOCATION RETRIEVAL LIST
         MVI   ALLOCSW,0
         MVI   CONCATSW,0
         CLI   FILEKW+1,1          'FILE' SPECIFIED?
         BNE   NOFILE              NO, BRANCH
         CLI   DSNAME+1,8          IS LENGTH 8 OR LESS?
         BH    FILERR1             NO, BRANCH
         MVC   DDNAME,DSNAME+2
         DEVTYPE DDNAME,DEVDATA    GET DEVICE TYPE
         LTR   R15,R15             WAS FILENAME VALID?
         BNZ   FILERR2             NO, BRANCH
         TM    DEVDATA+2,X'20'     DIRECT ACCESS?
         BZ    FILERR3             NO, BRANCH
*               GET UCB ADDRESS
         L     R1,16               CVTPTR
         L     R1,0(,R1)           TCBS
         L     R1,4(,R1)           CURRENT TCB
         L     R1,12(,R1)          TIOT
         LA    R1,24(,R1)          DDNAMES
         SLR   R15,R15
DDLOOP   CLI   0(R1),0             END OF TIOT?
         BE    NEXTD12             YES, BRANCH (NEVER HAPPENS)
         CLC   4(8,R1),DDNAME      DOES DDNAME MATCH?
         BE    DDFOUND             YES
         IC    R15,0(,R1)
         LA    R1,0(R15,R1)
         B     DDLOOP
DDFOUND  IC    R15,0(,R1)
         LA    R15,0(R15,R1)
         ST    R15,CONCTPTR        POINT TO NEXT TIOT ENTRY
         L     R15,16(,R1)         TIOEFSRT-1
         LA    R15,0(,R15)
         ST    R15,UCBPTR
*
         OC    SDSRTRVD,SDSRTRVD   PROCESSING A CONCATENATED FILE?
         BNZ   ARLLOOP             YES, LOOP THROUGH ARL ENTRIES
         CLI   CONCATSW,0          PROCESSING A CONCATENATED FILE?
         BE    GETJFCB             NO
         L     R15,12(,R1)         YES, GET JFCB ADDRESS
         SRL   R15,8               CONVERT INTO ADDRESS FORMAT
         MVC   JFCB(176),16(R15)   GET JFCB OF CONCATENATED FILE
         B     GOTJFCB             CHEATED SO BYPASS RDJFCB
*
GETJFCB  LA    R8,DIRDCBW
         MVC   0(DIRDCBL,R8),DIRDCB
         MVI   SDSLEN+1,36         SUPPLY LENGTH
         MVC   SDSIDENT,=C'AR'     SUPPLY IDENTIFIER
         LA    R1,DIREXLST
         LA    R0,SDSARL
         ST    R0,0(,R1)
         MVI   0(R1),X'13'         ALLOCATION RETRIEVAL EXIT
         LA    R0,JFCB
         ST    R0,4(,R1)
         MVI   4(R1),X'87'         READ JFCB EXIT (PLUS LAST EXIT FLAG)
         ST    R1,EXLST(,R8)           DCBEXLST
         L     R15,CONCTPTR        POINT TO NEXT TIOT ENTRY
         CLI   0(R15),0            END OF TIOT?
         BE    DROPARL             YES, DON'T NEED ARL STUFF
         CLI   4(R15),C' '         NO, CONCATENATED FILE?
         BNE   DROPARL             NO, DON'T NEED ARL STUFF
         TM    12(R15),X'FE'       YES, JFCB ADDRESS LESS THAN 128K?
         BZ    ARLSETUP            YES, MUST BE SVA FOR ABOVE 16MB
DROPARL  MVC   0(4,R1),4(R1)       ERASE X'13' EXIT FROM DCB EXIT LIST
ARLSETUP MVC   DDNAM(8,R8),DSNAME+2    DCBDDNAM
         MVI   RDJFCB,X'80'
         RDJFCB ((R8)),MF=(E,RDJFCB)
*
         CLI   SDSRCODE,0          ALLOCATION INFORMATION FETCHED?
         BNE   GOTJFCB             NO
         ICM   R0,15,SDSAREA       REALLY?
         BZ    GOTJFCB             NO, EXIT X'13' NOT SUPPORTED
ARLLOOP  LA    R0,1
         A     R0,CONCTCNT         INCREMENT CONCATENATION COUNT
         CH    R0,SDSCONC          PAST TOTAL RETRIEVED?
         BH    CONCATX             YES  (SHOULDN'T HAPPEN)
         ST    R0,CONCTCNT         SAVE NEW CONCATENATION NUMBER
         L     R1,SDSAREA          POINT TO FIRST FETCHED JFCB
JFCBLOOP BCT   R0,NEXTJFCB         GET NEXT JFCB
         B     GOTJFCBX            GOT THE RIGHT ONE NOW
NEXTJFCB AH    R1,0(,R1)           POINT TO THE NEXT FETCHED JFCB
         B     JFCBLOOP            LOOP THROUGH CONCATENATIONS
GOTJFCBX MVC   JFCB(176),4(R1)     COPY THE JFCB
*
GOTJFCB  MVC   DSNAME+2(44),JFCB
         LA    R1,DSNAME+45        LAST CHAR OF DSNAME
         LA    R0,44               INITIAL LENGTH
FILEA    CLI   0(R1),C' '          IS THIS LAST NONBLANK
         BNE   FILEB               YES, BRANCH
         BCTR  R1,0                BACK UP 1 CHARACTER
         BCT   R0,FILEA            DECREMENT LENGTH AND BRANCH
FILEB    STH   R0,DSNAME           STORE LENGTH OF DSNAME
         MVC   VOLUME(6),JFCB+118  GET VOLUME FROM JFCB (BLANKS IF VIO)
         B     NODEF
FILERR1  LA    R0,MSG14A
         B     FILERR
FILERR2  LA    R0,MSG14B
         B     FILERR
FILERR3  LA    R0,MSG14C
FILERR   MVC   MSGWK(L'MSG14),MSG14
         LA    R15,MSGWK+L'MSG14
         LA    R14,DSNAME
         LH    R1,0(,R14)
         BCTR  R1,0
         B     *+10
         MVC   MSGWK+L'MSG14(0),2(R14)
         EX    R1,*-6
         LA    R15,1(R1,R15)
         LR    R14,R0 POINT TO MSG14A, B, OR C
         MVC   0(L'MSG14A,R15),0(R14)
         LA    R0,L'MSG14+L'MSG14A+1(,R1)
         LA    R1,MSGWK
         BAL   R14,PUTMSG
         B     NEXTD12
NOFILE   EQU   *
         TM    6(R9),X'40'         IS DSN QUOTED?
         BO    NODEF               YES - SKIP DEFAULT SERVICE
         CLI   VOLKW+1,0           WAS VOL SPECIFIED?
         BNE   NODEF               YES - SKIP DEFAULT SERVICE
         CLI   QUICKKW+1,1         WAS 'QUICKLY' SPECIFIED
         BE    NODEF               YES, BYPASS CATALOG OVERHEAD
         SPACE
************************************************************
*                                                          *
*        CALL THE DEFAULT SERVICE ROUTINE                  *
*        TO ADD A DESCRIPTIVE QUALIFIER IF NECESSARY       *
*                                                          *
************************************************************
         SPACE
         LA    R15,MYIOPL
         USING IOPL,R15
         LA    R14,MYDFPB
         ST    R14,IOPLIOPB
         USING DFPB,R14
         XC    0(20,R14),0(R14)
         LA    R0,DSNAME
         ST    R0,DFPBDSN
         OI    DFPBCODE,X'04'      SEARCH CATLG AND PROMPT IF MULTI
         MVC   DFPBPSCB,CPPLPSCB
         DROP  R14
         SPACE
         LA    R1,MYIOPL
         SPACE
         AIF   (NOT &MVS).SKIP3
         L     R15,16              CVTPTR
         TM    736(R15),X'80'      IF HI ORDER BIT NOT ON
         BNO   EHDEFLNK               THEN DO LINK, NOT CALL
         L     R15,736(,R15)       CVTEHDEF
         BALR  R14,R15             CALL IKJEHDEF
         B     EHDEFEXT            SKIP AROUND LINK
EHDEFLNK EQU   *
.SKIP3   ANOP
         LINK  EP=IKJDFLT,SF=(E,LINKAREA)
EHDEFEXT EQU   *
         SPACE 1
         B     DEFCODE(R15)
DEFCODE  B     DEF00               SUCCESS
         B     NEXTD12             MSG ALREADY ISSUED
         B     DEF08               INVALID NAME GT 44
         B     NEXTD12             MSG ALREADY ISSUED
         B     DEF16               NOT IN CATALOG
         B     DEF20               NOT IN CATALOG
         B     DEF24               IMPOSSIBLE
         B     DEF28               COMMAND SYSTEM ERROR
         B     DEF32               IMPOSSIBLE
         B     DEF36               ?
DEF08    EQU   *
DEF16    EQU   *
         B     DEF24
DEF20    EQU   *
LOCERR   EQU   *
         MVC   MSGWK(L'MSG04),MSG04
         LA    R15,MSGWK+L'MSG04
         LA    R14,DSNAME
         LH    R1,0(,R14)
         BCTR  R1,0
         B     *+10
         MVC   MSGWK+L'MSG04(0),2(R14)
         EX    R1,*-6
         LA    R15,1(R1,R15)
         MVC   0(L'MSG04A,R15),MSG04A
         LA    R0,L'MSG04+L'MSG04A+1(,R1)
         LA    R1,MSGWK
         BAL   R14,PUTMSG
         B     NEXTD12
DEF24    EQU   *
DEF28    EQU   *
DEF32    EQU   *
DEF36    EQU   *
         LA    R1,MSG03
         LA    R0,L'MSG03
         BAL   R14,PUTMSG
         B     NEXTD12
         SPACE
DEF00    EQU   *
NODEF    EQU   *
         LA    R1,DSNAME+2
         LH    R0,DSNAME
         BAL   R14,PUTLINE
         EJECT
************************************************************
*                                                          *
*        GET THE VOLUME                                    *
*                                                          *
************************************************************
         SPACE
         CLI   VOLUME,0            IS VOLUME FILLED IN FROM JFCB?
         BNE   VOLGOT              YES, BRANCH
         CLI   VOLKW+1,0           VOL SPECIFIED?
         BE    LOCRTN              NO - DO LOCATE
         TM    VOL+6,X'80'
         BZ    LOCRTN
         LH    R1,VOL+4            GET LENGTH
         LTR   R1,R1               ZERO?
         BZ    LOCRTN              YES - DO LOCATE
         MVC   VOLUME(6),=CL8' '   PAD WITH BLANKS
         L     R14,VOL             POINT TO VOL VALUE
         BCTR  R1,0
         B     *+10
         MVC   VOLUME(0),0(R14)
         EX    R1,*-6
VOLGOT   XC    DSCBTTR,DSCBTTR     VOL NOT FROM CATALOG
         B     VOLX
LOCRTN   EQU   *
         LA    R1,MYCAM
         MVC   0(16,R1),LOCCAM
         LA    R0,DSNAME+2
         ST    R0,4(,R1)
         LA    R0,MYLOCBUF
         ST    R0,12(,R1)
         LOCATE (1)
         LTR   R15,R15
         BNZ   LOCERR
*                                  IF DSNAME WAS AN ALIAS
*                                  IN A VSAM CATALOG, THEN
*                                  LOCATE HAS REPLACED DSNAME
*                                  WITH THE TRUE NAME, SO A
*                                  SUBSEQUENT OBTAIN WILL WORK.
         MVC   VOLUME,MYLOCBUF+6
         MVC   DSCBTTR,MYLOCBUF+252
VOLX     EQU   *
         SPACE
************************************************************
*                                                          *
*        GET THE DEVICE CHARACTERISTICS                    *
*                                                          *
************************************************************
         SPACE
         L     R1,UCBPTR
         LTR   R1,R1               IS UCB ADDRESS FILLED IN?
         BNZ   UCBFND              YES, BRANCH
         L     R15,16              CVTPTR
         TM    116(R15),X'80'      CHECK OS BITS FOR XA SYSTEM
         BZ    MVS370              NOT XA SO DO OS/370 UCB LOOK UP
         TM    116(R15),X'93'      CHECK OS BITS FOR MVS/XA SYSTEM
         BNO   MSPEXA              NOT XA SO DO MSP/EXA UCB LOOK UP
         L     R1,1252(,R15)       POINT TO FIRST UCB IN UCB CHAIN
         B     *+8                 BYPASS CHAIN JUMP
UCBLOOPX ICM   R1,15,8(R1)         POINT TO NEXT UCB
         BZ    NOXAUCB             END OF CHAIN REACHED
         CLI   18(R1),X'20'        DASD
         BNE   UCBLOOPX            NO - BRANCH
         TM    3(R1),X'80'         ONLINE
         BZ    UCBLOOPX            NO - BRANCH
         CLC   28(6,R1),VOLUME     DOES VOLUME MATCH?
         BNE   UCBLOOPX            NO - BRANCH
         B     UCBFNDX             YES
NOXAUCB  L     R15,16              CVTPTR
         TM    116(R15),X'9B'      MVS/ESA?
         BNO   NOTMOUNT            NO, VOLUME NOT ON MVS/SP2 SYSTEM
         TM    1264(R15),X'08'     TEST CVTOSLVL - IS IT SP4 OR MORE?
         BNO   NOTMOUNT            NO, VOLUME NOT ON MVS/SP3 SYSTEM
         B     UCBSLOW             YES, SEE IF OBTAIN CAN FIND VOLUME
MSPEXA   LA    R0,1
         SLL   R0,31
         LA    R1,MSPIOCOM
         OR    R1,R0
*        BSM   0,R1                HANDLE 31-BIT ADDRESSES
         DC    X'0B01'             HANDLE 31-BIT ADDRESSES
MSPIOCOM L     R15,X'7C'(,R15)     IOS COUMMICATION AREA
         L     R15,X'184'(,R15)    UCB LOOK-UP TABLE
         B     *+8                 BYPASS INCREMENT
UCBLOOPE LA    R15,4(,R15)         POINT TO NEXT UCB POINTER
         ICM   R1,15,0(R15)        POINT TO UCB
         BZ    UCBLOOPE            NULL, IGNORE IT
         BM    NOTMOUNT            END OF POINTER LIST
         CLI   18(R1),X'20'        DASD
         BNE   UCBLOOPE            NO - BRANCH
         TM    3(R1),X'80'         ONLINE
         BZ    UCBLOOPE            NO - BRANCH
         CLC   28(6,R1),VOLUME     DOES VOLUME MATCH?
         BNE   UCBLOOPE            NO - BRANCH
         LA    R15,UCBFNDX         YES
*        BSM   0,R15               REVERT TO 24-BIT ADDRESSING
         DC    X'0B0F'             REVERT TO 24-BIT ADDRESSING
MVS370   L     R15,X'28'(,R15)     CVTILK2
         B     *+8                 BYPASS INCREMENT
UCBLOOP  LA    R15,2(,R15)         POINT TO NEXT UCB POINTER
         LH    R1,0(,R15)          POINT TO UCB
         LTR   R1,R1               TEST POINTER
         BZ    UCBLOOP             NULL, IGNORE IT
         N     R1,=A(X'0000FFFF')  16 BIT ADDRESS
         C     R1,=A(X'0000FFFF')
         BE    NOTMOUNT            END OF POINTER LIST
         CLI   18(R1),X'20'        DASD
         BNE   UCBLOOP             NO - BRANCH
         TM    3(R1),X'80'         ONLINE
         BZ    UCBLOOP             NO - BRANCH
         CLC   28(6,R1),VOLUME     DOES VOLUME MATCH?
         BNE   UCBLOOP             NO - BRANCH
UCBFNDX  ST    R1,UCBPTR           SAVE FOR DEBUG
UCBFND   EQU   *
         SLR   R15,R15             CLEAR INDEX REGISTER
*        TM    0(R1),X'80'         VIO?
         CLI   19(R1),X'09'        3330?
         BNE   NOT3330V            NO
         TM    17(R1),X'08'        VIRTUAL 3330?
         BO    UCBFAST             YES, USE ZERO AS INDEX
NOT3330V CLI   19(R1),X'85'        F6421?
         BNE   NOTF6421            NO
         LA    R15,16              YES, GET INDEX
         B     UCBFAST
NOTF6421 CLI   19(R1),X'0F'        KNOWN DEVICE TYPE?
         BH    UCBSLOW             NO
         ICM   R15,1,19(R1)        USE DEVICE TYPE AS INDEX
         BZ    UCBSLOW
UCBFAST  EQU   *
         MH    R15,DEVTBLSZ        SCALE UP INDEX
         LA    R15,DEVTABLE(R15)   POINT TO DEVICE ENTRY
         LH    R14,0(,R15)         DSCBS PER TRACK
         STH   R14,DSCBTRK
         LH    R14,2(,R15)         TRACKS PER CYL
         STH   R14,TRKCYL
         MVC   UNIT,4(R15)         FOR DISPLAY
         B     UCBEXIT
*
*                     OBTAIN FORMAT 4 FOR OTHER DEVICES
*
*                     NOTE. UNDER OS/MVT THIS MUST BE DONE VIA
*                     A SEEK CAMLST INSTEAD OF A SEARCH CAMLST.
*
UCBSLOW  LA    R1,MYCAM
         MVC   0(16,R1),OBTCAM
         LA    R15,FORMAT4
         MVI   0(R15),X'04'
         MVC   1(43,R15),0(R15)
         ST    R15,4(,R1)
         LA    R0,VOLUME
         ST    R0,8(,R1)
         LA    R0,MYF1DSCB
         ST    R0,12(,R1)
         OBTAIN (1)
         LTR   R15,R15             WAS FORMAT 4 READ OK?
         BNZ   NOTMOUNT            NO, (MUST BE MVT OR SP4 OR MORE)
         LA    R8,MYF1DSCB
         USING DSCB,R8
         SLR   R14,R14
         IC    R14,DS4DEVDT        DSCBS PER TRACK
         STH   R14,DSCBTRK
         LH    R14,DS4DEVSZ+2      TRACKS PER CYL
         STH   R14,TRKCYL
         MVC   UNIT,=C'        '
         LA    R15,DEVTABLE        POINT TO DEVICE TABLE         GP@FT*
         LA    R1,DEVTBLSZ         POINT PAST DEVICE TABLE            *
OB4DEVLP CLC   DS4DEVTK,10(R15)    FOUND A TRACK LENGTH MATCH?        *
         BE    OB4UNIT             YES                                *
         AH    R15,0(,R1)          NO, POINT TO NEXT DEVICE ENTRY     *
         CR    R15,R1              PAST END OF TABLE?                 *
         BL    OB4DEVLP            NO, CONTINUE SCAN                  *
         B     UCBEXIT             YES, LEAVE UNIT AS BLANK           *
OB4UNIT  MVC   UNIT,4(R15)         SHOW UNIT DEVICE TYPE         GP@FT*
         DROP  R8
UCBEXIT  EQU   *
         EJECT
************************************************************
*                                                          *
*        OBTAIN THE DSCB FROM THE VTOC                     *
*                                                          *
************************************************************
         SPACE
         CLC   DSCBTTR,=XL3'00'
         BE    OBSEARCH
OBSEEK   SLR   R14,R14
         SLR   R15,R15
         SLR   R1,R1
         IC    R1,DSCBTTR+2        GET R FROM TTR
         CH    R1,DSCBTRK          TOO HIGH FOR DEVICE?
         BNH   OBSEEK0             NO, BRANCH (ALWAYS)
         SH    R1,DSCBTRK          YES, REDUCE R
         LA    R14,1(,R14)         ADD 1 TO HH
OBSEEK0  AH    R14,DSCBTTR         GET TT FROM TTR
OBSEEK1  CH    R14,TRKCYL          MORE THAN A CYLINDER?
         BL    OBSEEK2             NO, BRANCH
         SH    R14,TRKCYL          YES, REDUCE HH
         LA    R15,1(,R15)         ADD 1 TO CC
         B     OBSEEK1             GO CHECK NEW HH
OBSEEK2  STH   R15,VTOCCHHR        STORE CC
         STH   R14,VTOCCHHR+2      STORE HH
         STC   R1,VTOCCHHR+4       STORE R
         SPACE 1
         LA    R1,MYCAM
         MVC   0(16,R1),OBTSEEK
         LA    R0,VTOCCHHR
         ST    R0,4(,R1)
         LA    R0,VOLUME
         ST    R0,8(,R1)
         LA    R0,MYF1KEY
         ST    R0,12(,R1)
         OBTAIN (1)
         LTR   R15,R15
         BNZ   OBSEEKER
         CLC   MYF1KEY,DSNAME+2    WAS CATALOG TTR CORRECT?
         BE    OBTOK               YES, BRANCH
OBSEEKRE EQU   *
*                                  BUM STEER FROM CATALOG
OBSEARCH LA    R1,MYCAM
         MVC   0(16,R1),OBTCAM
         LA    R0,DSNAME+2
         ST    R0,4(,R1)
         LA    R0,VOLUME
         ST    R0,8(,R1)
         LA    R0,MYF1DSCB
         ST    R0,12(,R1)
         OBTAIN (1)
         LTR   R15,R15
         BZ    OBTOK
         CH    R15,=H'4'
         BNE   OBTERR08
NOTMOUNT MVC   MSGWK(L'MSG06),MSG06
         LA    R15,MSGWK+L'MSG06
         LA    R14,DSNAME
         LH    R1,0(,R14)
         BCTR  R1,0
         B     *+10
         MVC   MSGWK+L'MSG06(0),2(R14)
         EX    R1,*-6
         LA    R15,1(R1,R15)
         MVC   0(L'MSG06A,R15),MSG06A
         MVC   L'MSG06A(6,R15),VOLUME
         LA    R0,L'MSG06+L'MSG06A+1+6(,R1)
         B     OBTERRMS
OBTERR08 MVC   MSGWK(L'MSG05),MSG05
         LA    R15,MSGWK+L'MSG05
         LA    R14,DSNAME
         LH    R1,0(,R14)
         BCTR  R1,0
         B     *+10
         MVC   MSGWK+L'MSG05(0),2(R14)
         EX    R1,*-6
         LA    R15,1(R1,R15)
         MVC   0(L'MSG05A,R15),MSG05A
         MVC   L'MSG05A(6,R15),VOLUME
         LA    R0,L'MSG05+L'MSG05A+1+6(,R1)
OBTERRMS LA    R1,MSGWK
         BAL   R14,PUTMSG
         B     NEXTD12
         SPACE
OBSEEKER CH    R15,=H'4'
         BE    NOTMOUNT
         B     OBSEEKRE
         SPACE
OBTOK    EQU   *
         MVI   DSORGSW,0
         MVI   MSGWK,C' '
         MVC   MSGWK+1(L'MSGWK-1),MSGWK
         MVC   DESCRIP(L'MSG07),MSG07
         MVC   DESCRIP+L'MSG07(L'MSG07A),BLANKS
         EJECT
         LA    R8,MYF1DSCB-44
         USING DSCB,R8
         SPACE
************************************************************
*                                                          *
*        CHECK FOR FAKE DSCB BUILT FOR VSAM BY OBTAIN      *
*                                                          *
************************************************************
         SPACE
         MVI   VSAMSW,C' '
         CLC   DS1END(5),=XL5'0000000000'
         BNE   VSAMNF         NOT FAKE - BRANCH
         CLC   DS1DSORG,=X'0008'
         BNE   VSAMNF         NOT FAKE - BRANCH
         CLI   DS1DSIND,X'30'
         BNE   VSAMNF         NOT FAKE - BRANCH
         MVI   VSAMSW,C'V'
*              DATE IS DECIMAL - MAKE IT BINARY
*              THE DECIMAL DATE WILL BE CHANGED BY IBM IN THE
*              FUTURE IN RESPONSE TO APAR# OZ36717.
*              REMOVED SUPPORT FOR DECIMAL DATE FORMAT.           GP@P6
*              (ASIDE: THE BINARY FORMAT IS GOOD TILL 2155.)      GP@P6
*        TM    DS1CREDT+2,X'0F'    IS DATE DECIMAL? LAST 4 BITS ON?
*        BNO   VSAMD2              NO - LEAVE IT AS IS
*        SLR   R1,R1
*        ST    R1,DOUBLE
*        IC    R1,DS1CREDT         GET YY FROM YYDDDF
*        SLL   R1,4                GET 00000YY0
*        ST    R1,DOUBLE+4         STORE IT
*        OI    DOUBLE+7,X'0F'      SET TO 00000YYF
*        CVB   R1,DOUBLE           CONVERY YY TO BINARY
*        STC   R1,DS1CREDT         REPLACE DECIMAL WITH BINARY
*        MVC   DOUBLE+6(2),DS1CREDT+1
*        CVB   R1,DOUBLE           CONVERT DDDF TO BINARY
*        STH   R1,DOUBLE
*        MVC   DS1CREDT+1(2),DOUBLE
*SAMD2   TM    DS1EXPDT+2,X'0F'    IS DATE DECIMAL? LAST 4 BITS ON?
*        BNO   VSAMDX              NO - LEAVE IT AS IS
*        CLC   DS1EXPDT(3),=X'00000F' EXPIRATION DATE ZERO?
*        BNE   VSAMDE              NO - BRANCH
*        NI    DS1EXPDT+2,X'F0'    YES - SET TO BINARY ZEROS
*        B     VSAMDX
*SAMDE   SLR   R1,R1
*        ST    R1,DOUBLE
*        IC    R1,DS1EXPDT         GET YY FROM YYDDDF
*        SLL   R1,4                GET 00000YY0
*        ST    R1,DOUBLE+4         STORE IT
*        OI    DOUBLE+7,X'0F'      SET TO 00000YYF
*        CVB   R1,DOUBLE           CONVERY YY TO BINARY
*        STC   R1,DS1EXPDT         REPLACE DECIMAL WITH BINARY
*        MVC   DOUBLE+6(2),DS1EXPDT+1
*        CVB   R1,DOUBLE           CONVERT DDDF TO BINARY
*        STH   R1,DOUBLE
*        MVC   DS1EXPDT+1(2),DOUBLE
*SAMDX   EQU   *
VSAMNF   EQU   *
         SPACE
************************************************************
*                                                          *
*        RECFM                                             *
*                                                          *
************************************************************
         SPACE
         LA    R1,RECFMWA
         MVC   0(6,R1),=CL6' '
         LR    R15,R1
         TM    DS1RECFM,X'C0'      U?
         BO    RECFMU              YES - BRANCH
         BZ    TTEST1              NOT U, F, OR V
         TM    DS1RECFM,X'80'      F?
         BO    RECFMF              YES - BRANCH
         MVI   0(R1),C'V'          MUST BE V
         B     TTEST
RECFMU   MVI   0(R1),C'U'
         B     TTEST
RECFMF   MVI   0(R1),C'F'
TTEST    LA    R1,1(,R1)           INCREMENT PTR
TTEST1   TM    DS1RECFM,X'20'      TRACK OVERFLOW
         BNO   RECFB
         MVI   0(R1),C'T'
         LA    R1,1(,R1)
RECFB    TM    DS1RECFM,X'10'      BLOCKED
         BNO   RECFS
         MVI   0(R1),C'B'
         LA    R1,1(,R1)
RECFS    TM    DS1RECFM,X'08'      STANDARD OR SPANNED
         BNO   RECFA
         MVI   0(R1),C'S'
         LA    R1,1(,R1)
RECFA    TM    DS1RECFM,X'04'      ASA
         BNO   RECFMM
         MVI   0(R1),C'A'
         LA    R1,1(,R1)
RECFMM   TM    DS1RECFM,X'02'      MACHINE
         BNO   RECFX
         MVI   0(R1),C'M'
         LA    R1,1(,R1)
RECFX    CR    R1,R15              IS R1 UNCHANGED?
         BNE   RECFMXIT            NO - BRANCH
         MVI   0(R1),C'*'          YES - USE '*'
         MVI   1(R1),C'*'
RECFMXIT MVC   MSGWK+2(6),RECFMWA
         EJECT
************************************************************
*                                                          *
*        LRECL                                             *
*                                                          *
************************************************************
         SPACE
LRECLTST MVC   MYWK5(6),=CL6' '
         SLR   R1,R1
         ICM   R1,3,DS1LRECL
         BZ    LRECNO
         CVD   R1,DOUBLE
         UNPK  MYWK5,DOUBLE
         OI    MYWK5+4,X'F0'
LRECLOOP CLI   MYWK5,C'0'
         BNE   LRECXIT
         MVC   MYWK5,MYWK5+1
         B     LRECLOOP
LRECNO   MVC   MYWK5(2),=C'**'
LRECXIT  MVC   MSGWK+8(5),MYWK5
         SPACE
************************************************************
*                                                          *
*        BLKSIZE                                           *
*                                                          *
************************************************************
         SPACE
         MVC   MYWK5(6),=CL6' '
         SLR   R1,R1
         ICM   R1,3,DS1BLKL
         BZ    BLKSNO
         CVD   R1,DOUBLE
         UNPK  MYWK5,DOUBLE
         OI    MYWK5+4,X'F0'
BLKSLOOP CLI   MYWK5,C'0'
         BNE   BLKSXIT
         MVC   MYWK5,MYWK5+1
         B     BLKSLOOP
BLKSNO   MVC   MYWK5(2),=C'**'
BLKSXIT  MVC   MSGWK+14(5),MYWK5
         EJECT
************************************************************
*                                                          *
*        DSORG                                             *
*                                                          *
************************************************************
         SPACE
DSORGTST EQU   *
         MVC   DSORGWA,=CL5'PS   '
         LA    R1,DSORGWA
         TM    DS1DSORG,X'40'      PS
         BO    DSORGU
         MVC   0(2,R1),=C'PO'
         TM    DS1DSORG,X'02'      PO
         BO    DSORGUP
         MVC   0(2,R1),=C'IS'
         TM    DS1DSORG,X'80'      IS
         BO    DSORGUI
         MVC   0(2,R1),=C'DA'
         TM    DS1DSORG,X'20'      DA
         BO    DSORGU
         MVC   0(2,R1),=C'**'
         TM    DS1DSORG,X'1C'      **
         BZ    DSORGV
         MVC   0(2,R1),=C'??'
         B     DSORGU
DSORGUP  MVI   DSORGSW,C'P'        SET PDS SWITCH ON
         B     DSORGU
DSORGUI  MVI   DSORGSW,C'1'        SET ISAM SWITCH ON
         B     DSORGU
DSORGV   TM    DS1DSORG+1,X'08'
         BZ    DSORGU
         MVC   0(2,R1),=C'VS'
DSORGU   TM    DS1DSORG,X'01'      UNMOVEABLE?
         BZ    DSORGUOK            NO - BRANCH
         MVI   2(R1),C'U'          YES - APPEND U
         LA    R1,1(,R1)           ADVANCE BUFFER POINTER
DSORGUOK TM    DS1FLAG1,X'08'      LARGE DATA SET?
         BZ    LARGEOK             NO - BRANCH
         MVC   2(2,R1),=C'-L'      DENOTE LARGE SEQUENTIAL
LARGEOK  TM    DS1SMSFG,X'0C'      PDSE OR STRIPED SEQUENTIAL?
         BZ    DSORGCPY            NO - BRANCH
         MVC   2(2,R1),=C'-E'      DENOTE PDSE OR EXTENDED FORMAT
         TM    DS1SMSFG,X'02'      HFS?
         BZ    DSORGCPY            NO - BRANCH
         MVC   DSORGWA,=CL5'HFS  ' YES
DSORGCPY EQU   *
         MVC   MSGWK+22(5),DSORGWA
         SPACE
************************************************************
*                                                          *
*        PROTECTION                                        *
*                                                          *
************************************************************
         SPACE
         MVC   MSGWK+58(5),=C'WRITE'
         TM    DS1DSIND,X'14'
         BO    PROTX
         MVC   MSGWK+58(5),=C'NONE '
         TM    DS1DSIND,X'10'
         BNO   PROTX
         MVC   MSGWK+58(5),=C'READ '
PROTX    EQU   *
         TM    DS1DSIND,X'40'
         BZ    *+10
         MVC   MSGWK+58(5),=C'RACF '
         SPACE
************************************************************
*                                                          *
*        CREATED / LAST REFERENCE / EXPIRATION DATES       *
*                                                          *
************************************************************
         SPACE
         LA    R1,DS1CREDT
         BAL   R14,YMD
         MVC   MSGWK+28(8),YMDOUT
         LA    R1,DS1REFD          POINT TO ACCESS DATE (SU 60)
         BAL   R14,YMD
         MVC   MSGWK+38(8),YMDOUT
         LA    R1,DS1EXPDT
         BAL   R14,YMD
         MVC   MSGWK+48(8),YMDOUT
         B     DATEX
         SPACE
YMD      MVC   YMDOUT,=C'00-00-00' SET OUTPUT AREA
         OC    0(3,R1),0(R1)       ZERO DATE?
         BZR   R14            YES - USE 00-00-00
         ST    R14,YMDREGS
         SLR   R14,R14
         IC    R14,0(,R1)          GET YEAR
         LA    R15,B'00000011'
         NR    R14,R15
         LA    R14,YMDNY
         BNZ   *+8
         LA    R14,YMDLY
         MVC   DOUBLE(2),1(R1)
         LH    R15,DOUBLE          GET JULIAN DDD
         LA    R0,12
YMD08    CH    R15,0(,R14)
         BH    YMD10
         LA    R14,2(,R14)
         BCT   R0,YMD08
         B     YMDX                USE 00/00/00 IF NEG
YMD10    SH    R15,0(,R14)
         CH    R15,=H'31'          LESS THAN 31?
         BNH   *+8                 YES - OK
         LA    R15,31              NO - SET TO 31
         CVD   R0,DOUBLE
         UNPK  YMDOUT+3(2),DOUBLE+6(2)
         OI    YMDOUT+4,X'F0'      * CHANGED TO DD/MM/YY FORMAT GP@SECV
         CVD   R15,DOUBLE
         UNPK  YMDOUT+6(2),DOUBLE+6(2)
         OI    YMDOUT+7,X'F0'      * CHANGED TO YY-MM-DD FORMAT   GP@HC
         IC    R0,0(,R1)           GET YEAR
         CVD   R0,DOUBLE
         UNPK  YMDOUT(2),DOUBLE+6(2)
         OI    YMDOUT+1,X'F0'      * CHANGED TO YY-MM-DD FORMAT   GP@HC
YMDX     L     R14,YMDREGS
         BR    R14
DATEX    EQU   *
         SPACE
************************************************************
*                                                          *
*        KEYLEN                                            *
*                                                          *
************************************************************
         SPACE
         CLI   DS1KEYL,0           KEYLEN ZERO?
         BNE   KEYYES              NO - BRANCH
         MVC   DOUBLE(2),DS1RKP
         LH    R1,DOUBLE           GET RKP
         LTR   R1,R1               RKP ZERO?
         BNZ   KEYYES              NO - BRANCH
         TM    DS1DSORG,X'80'      ISAM?
         BO    KEYYES
         MVC   DESCRIP+L'MSG07(L'MSG07B),MSG07B
         MVC   MSGWK+68(2),=C'NO'
         TM    DS1DSIND,X'02'      MODIFIED SINCE BACKUP?
         BZ    KEYNO               NO - BRANCH
         MVC   MSGWK+68(3),=C'YES'
         B     KEYNO
KEYYES   EQU   *
         SLR   R1,R1
         IC    R1,DS1KEYL
         CVD   R1,DOUBLE
         MVC   MSGWK+67(6),=X'402020202120'
         ED    MSGWK+67(6),DOUBLE+5
         MVC   DOUBLE(2),DS1RKP
         LH    R1,DOUBLE
         CVD   R1,DOUBLE
         MVC   MSGWK+73(4),=X'40202120'
         ED    MSGWK+73(4),DOUBLE+6
         MVC   DESCRIP+L'MSG07(L'MSG07A),MSG07A
         SPACE
KEYNO    LA    R0,L'MSG07+L'MSG07A
         LA    R1,DESCRIP
         BAL   R14,PUTLINE
         LA    R1,MSGWK
         LA    R0,79
         BAL   R14,PUTLINE
         SPACE
************************************************************
*                                                          *
*        SECONDARY SPACE                                   *
*                                                          *
************************************************************
         SPACE
         LA    R1,MSG08
         LA    R0,L'MSG08
         BAL   R14,PUTLINE
         MVI   MSGWK,C' '
         MVC   MSGWK+1(L'MSGWK-1),MSGWK
         MVC   SSPWA(L'SSPWA),MSGWK
         MVC   SSPWA2(L'SSPWA2),MSGWK
         MVC   MSGWK+2(6),VOLUME
         CLI   VOLUME,C' '
         BNE   *+10
         MVC   MSGWK+2(6),=C'(VIO) '
         MVC   MSGWK+10(6),UNIT
         TM    DS1SCALO,X'C0'
         BNZ   SSP1
         MVC   SSPWA(3),=C'ABS'
         B     SSP4
SSP1     BNO   SSP2
         MVC   SSPWA(3),=C'CYL'
         B     SSP4
SSP2     TM    DS1SCALO,X'80'
         BNO   SSP3
         MVC   SSPWA(3),=C'TRK'
         B     SSP4
SSP3     EQU   *
         MVC   SSPWA(3),=C'BLK'
SSP4     EQU   *
         MVC   DOUBLE+1(3),DS1SCALO+1
         MVI   DOUBLE,0
         L     R1,DOUBLE
         LTR   R1,R1
         BZ    SSP5
         CVD   R1,DOUBLE
         UNPK  SSPWA+7(7),DOUBLE+4(4)
         OI    SSPWA+7+6,X'F0'
SSPLOOP  CLI   SSPWA+7,C'0'
         BNE   SSP6
         MVC   SSPWA+7(7),SSPWA+8
         B     SSPLOOP
SSP5     MVC   SSPWA+7(2),=C'**'
SSP6     EQU   *
         LA    R15,SSPWA2
         TM    DS1SCALO,X'08'
         BZ    SSP7
         MVC   0(6,R15),=C'CONTIG'
         LA    R15,7(,R15)
SSP7     TM    DS1SCALO,X'04'
         BZ    SSP8
         MVC   0(4,R15),=C'MXIG'
         LA    R15,5(,R15)
SSP8     TM    DS1SCALO,X'02'
         BZ    SSP9
         MVC   0(3,R15),=C'ALX'
         LA    R15,4(,R15)
SSP9     TM    DS1SCALO,X'01'
         BZ    SSP91
         MVC   0(5,R15),=C'ROUND'
         LA    R15,6(,R15)
SSP91    EQU   *
         MVC   MSGWK+18(L'SSPWA),SSPWA
         SPACE
************************************************************
*                                                          *
*        TRACKS ALLOCATED                                  *
*                                                          *
************************************************************
         SPACE
         MVC   LASTTRK+2(2),DS1LSTAR
         XC    LASTTRK(2),LASTTRK
         L     R1,LASTTRK
         CLI   DS1LSTAR+2,0
         BE    *+8
         LA    R1,1(,R1)
         ST    R1,LASTTRK
         SPACE
         LA    R1,EXTTABLE
         ST    R1,EXTPTR
         SLR   R1,R1
         IC    R1,DS1NOEPV         GET NO. OF EXTENTS
         STH   R1,EXTENTS
         LA    R6,1                SET EXTENT COUNTER
         SLR   R4,R4               CLEAR TRACK COUNTER
         LTR   R1,R1               ANY EXTENTS?
         BZ    TRKX                NO - BRANCH
         CLI   VSAMSW,C'V'         IS IT A FAKE DSCB?
         BE    TRKX                YES - EXTENTS ARE STRANGE
         LA    R1,DS1EXT1          POINT TO FIRST EXTENT
         MVI   NEWDSCB#+1,4        EXTENT NUMBER FOR NEW FORMAT 3 DSCB
         MVI   JMPLBL3#+1,8        EXTENT NUMBER TO SKIP F3 ID
TRKLOOP  MVC   HALF(2),6(R1)       MOVE HIGH CC
         LH    R14,HALF
         MVC   HALF(2),8(R1)       MOVE HIGH HH
         LH    R15,HALF
         MVC   HALF(2),2(R1)       MOVE LOW CC
         SH    R14,HALF            GET NO. OF CYLS
         MVC   HALF(2),4(R1)       MOVE LOW HH
         SH    R15,HALF            GET DIFF. OF TRACKS
         MH    R14,TRKCYL          CONVERT CYL TO TRK
         AR    R14,R15             GET TOTAL (LESS 1)
         AH    R14,=H'1'           GET TOTAL
         L     R15,EXTPTR
         MVC   0(10,R15),0(R1)     SAVE EXTENT IN TABLE
         STH   R14,10(,R15)
         LA    R15,12(,R15)        INCREMENT POINTER
         ST    R15,EXTPTR
         AR    R4,R14              ADD TO COUNTER
         CH    R6,EXTENTS          LAST EXTENT?
         BE    TRKX                YES - BRANCH
         LA    R6,1(,R6)           INCREMENT EXTENT COUNTER
         CH    R6,NEWDSCB#         END OF EXTENTS FOR THIS DSCB?
         BE    TRKF3               YES - READ FMT 3
         CH    R6,JMPLBL3#         UP TO THE F3 ID?
         BE    TRKE8               YES - POINT PAST F3 ID
         LA    R1,10(,R1)          POINT TO NEXT EXTENT
         B     TRKLOOP             CONTINUE WITH NEXT EXTENT
         SPACE
TRKF3    MVC   VTOCCHHR(5),DS1PTRDS
         LA    R1,13(,R6)          GET EXTENT NUMBER FOR NEXT F3 DSCB
         STH   R1,NEWDSCB#         SAVE IT FOR LATER (ICF)        GP@P6
         CLI   NEWDSCB#+1,17       GETTING FIRST DSCB AFTER FORMAT 1?
         BE    GOTF3ADR            YES, HAVE CORRECT FORMAT 3 TTR
TRKOBT3  MVC   VTOCCHHR(5),MYEXDSCB+135 DS2PTRDS OR DS3PTRDS      GP@P6
GOTF3ADR LA    R1,MYCAM
         MVC   0(16,R1),OBTSEEK
         LA    R0,VTOCCHHR
         ST    R0,4(,R1)
         LA    R0,VOLUME
         ST    R0,8(,R1)
         LA    R0,MYEXDSCB
         ST    R0,12(,R1)
         OBTAIN (1)
         LTR   R15,R15
         BZ    OBT3OK
         LA    R0,L'MSG09
         LA    R1,MSG09
         BAL   R14,PUTMSG
         B     NEXTD12
OBT3OK   EQU   *
         CLI   MYEXDSCB+44,C'3'    IS IT A FMT 3?
         BNE   TRKF2               NO - ISAM F2
         LA    R1,MYEXDSCB+4       POINT TO 1ST EXT IN F3
         B     TRKLOOP
TRKF2    MVI   DSORGSW,C'2'        SHOW F2 IS IN
         MVC   MYF2DSCB(DS2END-IECSDSL2),IECSDSL2
         B     TRKOBT3
TRKE8    LA    R1,13(,R6)          GET EXTENT NUMBER FOR NEXT F3 ID
         STH   R1,JMPLBL3#         SAVE IT FOR LATER (ICF)        GP@P6
         LA    R1,MYEXDSCB+45
         B     TRKLOOP
TRKX     EQU   *
         CVD   R4,DOUBLE
         MVC   TRKWA(6),=X'402020202120'
         ED    TRKWA(6),DOUBLE+5
         MVC   MSGWK+35(6),TRKWA
         TM    DS1DSORG,X'42'      PO OR PS?
         BNZ   TRKU                YES - BRANCH
         MVI   MSGWK+43+5,C'*'     NO - UNUSED IS MEANINGLESS
         B     TRKUX
TRKAM    MVC   TRKWA(6),=C'    -'
         B     TRKUX
TRKU     L     R1,LASTTRK
         LR    R15,R4
         SR    R15,R1
         BM    TRKAM               NEGATIVE, DS1LSTAR IS BAD
         CVD   R15,DOUBLE
         MVC   TRKWA(6),=X'402020202120'
         ED    TRKWA(6),DOUBLE+5
         MVC   MSGWK+43(6),TRKWA
TRKUX    EQU   *
         LH    R1,EXTENTS
         CVD   R1,DOUBLE
         MVC   TRKWA(6),=X'402020202120'
         ED    TRKWA(6),DOUBLE+5
         MVC   MSGWK+51(6),TRKWA
         MVC   MSGWK+59(21),SSPWA2
         LA    R1,MSGWK
         LA    R0,78
         BAL   R14,PUTLINE
         SPACE
************************************************************
*                                                          *
*         SYSTEM MANAGED STORAGE DETAILS                   *
*                                                          *
************************************************************
         SPACE
         TM    DS1SMSFG,X'80'      SYSTEM MANAGED DATA SET?
         BZ    SMSX                NO, BRANCH
         LA    R1,MSG18
         LA    R0,L'MSG18
         BAL   R14,PUTLINE
         MVI   MSGWK,C' '
         MVC   MSGWK+1(L'MSGWK-1),MSGWK
         MVC   MSGWK+2(2),=C'NO'   CATALOGUED
         MVC   MSGWK+21(2),=C'**'  SECONDARY QUANTITY
         MVC   MSGWK+35(2),=C'NO'  REBLOCKABLE
         MVC   MSGWK+48(2),=C'NO'  SYSTEM BLOCKED
         TM    DS1SMSFG,X'40'      DOES BCS ENTRY EXIST?
         BO    SMSBCSOK            NO, PRIMED VALUE IS CORRECT
         MVC   MSGWK+2(3),=C'YES'  YES, SUPPLY CORRECT VALUE
SMSBCSOK TM    DS1SMSFG,X'20'      MAY THE DATA SET BE REBLOCKED?
         BZ    SMSREBOK            NO, PRIMED VALUE IS CORRECT
         MVC   MSGWK+35(3),=C'YES' YES, SUPPLY CORRECT VALUE
SMSREBOK TM    DS1SMSFG,X'10'      DID THE DADSM SUPPLY BLKSIZE?
         BZ    SMSBLKOK            NO, PRIMED VALUE IS CORRECT
         MVC   MSGWK+48(3),=C'YES' YES, SUPPLY CORRECT VALUE
SMSBLKOK SLR   R1,R1
         ICM   R1,3,DS1SCXTV       LOAD SMS SECONDARY SPACE EXTN. VALUE
         BZ    SMSDTL              VALUE IS ZERO
         TM    DS1SCXTF,X'0C'      HAS VALUE BEEN COMPACTED?
         BZ    SCXTVOK             NO
         SLL   R1,8                YES, MULTIPLY BY 256
         TM    DS1SCXTF,X'04'      WAS THE COMPACTION VALUE 256?
         BZ    SCXTVOK             YES
         SLL   R1,8                NO, IT WAS 65536
SCXTVOK  CVD   R1,DOUBLE
         MVC   MSGWK+17(6),=X'402020202120'
         ED    MSGWK+17(6),DOUBLE+5
         ICM   R15,8,DS1SCXTF      LOAD SMS SECONDARY SPACE EXTN. FLAGS
         SLR   R1,R1               ZERO TABLE INDEX
         LA    R0,4                FOUR BITS TO TEST IN FLAG BYTE
SMSTYPLP LTR   R15,R15             TOP (SIGN) BIT ON?
         BM    SMSTYPOK            YES, GOT SECONDARY SPACE TYPE
         SLL   R15,1               NO, TRY NEXT BIT
         LA    R1,9(,R1)           POINT TO NEXT DESCRIPTOR
         BCT   R0,SMSTYPLP         TEST NEXT BIT
SMSTYPOK LA    R1,SMSPCTYP(R1)     POINT TO DESCRIPTOR
         MVC   MSGWK+24(9),0(R1)   LOAD IT INTO DISPLAY LINE
SMSDTL   LA    R1,MSGWK
         LA    R0,51
         BAL   R14,PUTLINE
SMSX     EQU   *
         SPACE
************************************************************
*                                                          *
*         EXTENTS                                          *
*                                                          *
************************************************************
         SPACE
         CLI   EXTKW+1,1           EXTENTS REQUESTED
         BNE   EXTX                NO, BRANCH
         LH    R15,EXTENTS         GET NUMBER OF EXTENTS
         LTR   R15,R15             ARE THERE ANY
         BZ    EXTX                NO, BRANCH
         LA    R1,MSG08+L'MSG08-11
         LA    R0,11
         BAL   R14,PUTLINE
         MVI   MSGWK,C' '
         MVC   MSGWK+1(35),MSGWK
         ST    R2,CPPLPTR
         LA    R2,EXTTABLE
EXTLOOP  UNPK  MSGWK+03(9),2(5,R2) UNPACK CCHH
         TR    MSGWK+03(9),HEXTAB-240
         MVC   MSGWK+02(4),MSGWK+03
         MVI   MSGWK+06,C'.'
         MVI   MSGWK+11,C' '
         UNPK  MSGWK+14(9),6(5,R2) UNPACK CCHH
         TR    MSGWK+14(9),HEXTAB-240
         MVC   MSGWK+13(4),MSGWK+14
         MVI   MSGWK+17,C'.'
         MVI   MSGWK+22,C' '
         MVC   MSGWK+23(6),=X'402020202120'
         SLR   R0,R0               CLEAR TOP HALFWORD             GP@FT
         ICM   R0,3,10(R2)         GET NUMBER OF TRACKS           GP@FT
         CVD   R0,DOUBLE
         ED    MSGWK+23(6),DOUBLE+5
         MVC   MSGWK+30(06),=C'TRACKS'
         LA    R1,MSGWK
         LA    R0,36
         BAL   R14,PUTLINE
         LA    R2,12(,R2)
         BCT   R15,EXTLOOP
         L     R2,CPPLPTR
EXTX     EQU   *
         SPACE
************************************************************
*                                                          *
*         DIRECTORY BLOCKS                                 *
*                                                          *
************************************************************
         SPACE
         CLI   DIRKW+1,1           'DIR' REQUESTED
         BNE   DIRX                NO, BRANCH
         CLI   DSORGSW,C'P'        IS DATA SET PARTITIONED?
         BNE   DIRX                NO, BRANCH
         CLI   CONCATSW,0          IS A CONCATENATION?
         BNE   DIRX                YES, BRANCH
         CLI   FILEKW+1,1          IS FILE SPECIFIED?
         BE    DIRDD               YES, BRANCH
         BAL   R14,ALLOC           NO, ALLOCATE THE DATA SET
         LTR   R15,R15             WAS ALLOC SUCCESSFUL?
         BZ    DIRDD               YES, BRANCH
         LA    R1,MSG17            UNABLE TO ALLOCATE
         LA    R0,L'MSG17
         BAL   R14,PUTMSG
         B     DIRX
DIRDD    XC    DIRBLKS,DIRBLKS
         XC    DIRBLKSU,DIRBLKSU
         XC    MEMBERS,MEMBERS
         XC    ALIASES,ALIASES
         ST    R2,CPPLPTR
         SPACE
         LA    R2,DIRDCBW
         MVC   0(DIRDCBL,R2),DIRDCB
         MVC   DDNAM(8,R2),DDNAME
*        IC    R0,EXLST(,R2)       SAVE RECFM
*        LA    R1,DIREXLST
*        ST    R1,EXLST(,R2)
*        STC   R0,EXLST(,R2)       RESTORE RECFM
*        OI    JFCB+52,X'08'       DO NOT WRITE BACK JFCB
         MVI   OPEN,X'80'
         OPEN  ((R2),INPUT),MF=(E,OPEN)
         MVC   DIRDECBW(DIRDECBL),DIRDECB
         MVI   DIRSW,0
DIRREAD  EQU   *
         READ  DIRDECBW,SF,(R2),BLOCK,256,MF=E
         CHECK DIRDECBW
         TM    DIRSW,2             I/O ERROR
         BO    DIRERR              YES, BRANCH
         LA    R1,1
         A     R1,DIRBLKS
         ST    R1,DIRBLKS
         TM    DIRSW,1             ARE WE PAST USED BLOCKS
         BO    DIRREAD             YES, BRANCH
         LA    R1,BLOCK            POINT TO DATA JUST READ
         LH    R0,0(,R1)           GET NUMBER OF BYTES IN USE
         LTR   R0,R0               IS THIS NEGATIVE?
         BM    DIRINV              YES, NOT A DIRECTORY BLOCK
         CH    R0,=H'256'          IS THIS TOO LARGE?
         BH    DIRINV              YES, NOT A DIRECTORY BLOCK
         AR    R0,R1               POINT PAST LAST BYTE
         LA    R1,2(,R1)           POINT TO FIRST MEMBER
DIRENTRY CLC   0(8,R1),=8X'FF'     END OF MEMBERS
         BE    DIRUSED
         TM    11(R1),X'80'        ALIAS
         BO    DIRALIAS
         LA    R15,1               COUNT NON-ALIAS MEMBERS
         A     R15,MEMBERS
         ST    R15,MEMBERS
         B     DIRNEXT
DIRALIAS LA    R15,1               COUNT ALIAS MEMBERS
         A     R15,ALIASES
         ST    R15,ALIASES
DIRNEXT  SLR   R15,R15
         IC    R15,11(,R1)
         N     R15,=F'31'          SET OFF ALL BUT LAST 5 BITS
         SLL   R15,1               CHANGE HALFWORDS TO BYTES
         LA    R1,12(R15,R1)       POINT PAST USER DATA
         CR    R1,R0               END OF BLOCK
         BL    DIRENTRY            NO, BRANCH
         B     DIRREAD             YES, READ NEXT BLOCK
DIRUSED  OI    DIRSW,1             STOP COUNTING MEMBERS
         MVC   DIRBLKSU,DIRBLKS    SAVE NUMBER OF USED BLOCKS
         B     DIRREAD
DIRSYN   EQU   *
         SYNADAF ACSMETH=BSAM
         MVC   DIRMSG(72),50(R1)
         OI    DIRSW,2
         SYNADRLS
         BR    R14
DIRINV   LA    R1,MSG16
         LA    R0,L'MSG16
         B     DIRERRX
DIRERR   LA    R1,DIRMSG
         LA    R0,72
DIRERRX  BAL   R14,PUTMSG
         OI    DIRSW,4
DIREOF   EQU   *
         CLOSE ((R2)),MF=(E,OPEN)
         L     R2,CPPLPTR          RESTORE R2
         TM    DIRSW,4             WAS DIRECTORY IN ERROR
         BO    DIRX                YES, BRANCH
         MVI   MSGWK,C' '
         MVC   MSGWK+1(L'MSGWK-1),MSGWK
         SPACE
         L     R1,DIRBLKS
         CVD   R1,DOUBLE
         LA    R15,MSGWK+3
         MVC   0(6,R15),=X'402020202120'
         ED    0(6,R15),DOUBLE+5
         SPACE
         L     R1,DIRBLKSU
         CVD   R1,DOUBLE
         LA    R15,MSGWK+17
         MVC   0(6,R15),=X'402020202120'
         ED    0(6,R15),DOUBLE+5
         SPACE
         L     R1,DIRBLKS
         S     R1,DIRBLKSU
         CVD   R1,DOUBLE
         LA    R15,MSGWK+25
         MVC   0(6,R15),=X'402020202120'
         ED    0(6,R15),DOUBLE+5
         SPACE
         L     R1,MEMBERS
         CVD   R1,DOUBLE
         LA    R15,MSGWK+33
         MVC   0(6,R15),=X'402020202120'
         ED    0(6,R15),DOUBLE+5
         SPACE
         L     R1,ALIASES
         LTR   R1,R1               ANY ALIASES
         BNZ   DIRALI              YES, BRANCH
         MVI   MSGWK+47,C'0'
         LA    R1,MSG15            NO, DONT SHOW TOTAL
         LA    R0,52
         BAL   R14,PUTLINE         WRITE SHORT HEADER
         LA    R1,MSGWK
         LA    R0,48
         BAL   R14,PUTLINE         WRITE SHORT STATS
         B     DIRX
DIRALI   CVD   R1,DOUBLE
         LA    R15,MSGWK+42
         MVC   0(6,R15),=X'402020202120'
         ED    0(6,R15),DOUBLE+5
         SPACE
         A     R1,MEMBERS          COMPUTE TOTAL MEMBERS AND ALIASES
         CVD   R1,DOUBLE
         LA    R15,MSGWK+49
         MVC   0(6,R15),=X'402020202120'
         ED    0(6,R15),DOUBLE+5
         LA    R1,MSG15
         LA    R0,L'MSG15
         BAL   R14,PUTLINE         WRITE FULL HEADER WITH TOTAL
         LA    R1,MSGWK
         LA    R0,55
         BAL   R14,PUTLINE         WRITE FULL STATS WITH TOTAL
DIRX     EQU   *
         TM    ALLOCSW,1
         BZ    *+8
         BAL   R14,FREE
         B     FMT2
         EJECT
************************************************************
*                                                          *
*         ALLOCATE / FREE                                  *
*                                                          *
************************************************************
         SPACE
ALLOC    ST    R14,ALLOCR
         LA    R1,MYDAPL
         USING DAPL,R1
         MVC   DAPLUPT(4),CPPLUPT
         MVC   DAPLECT(4),CPPLECT
         LA    R0,MYECB
         ST    R0,DAPLECB
         MVC   DAPLPSCB(4),CPPLPSCB
         LA    R14,MYDAPB
         ST    R14,DAPLDAPB
         DROP  R1                  DAPL
         SPACE
         USING DAPB08,R14
         MVC   0(MODEL08L,R14),MODEL08
         LA    R0,DSNAME
         ST    R0,DA08PDSN
         MVC   DA08UNIT,=CL8'SYSALLDA'
         MVC   DA08SER,VOLUME
         MVI   DA08DSP1,DA08SHR
         SPACE
         BAL   R14,DAIR
         SPACE
         LTR   R15,R15
         BNZ   ALLOCX
         LA    R14,MYDAPB
         MVC   DDNAME,DA08DDN
         OI    ALLOCSW,1
ALLOCX   L     R14,ALLOCR
         BR    R14
         SPACE
FREE     ST    R14,ALLOCR
         LA    R14,MYDAPB
         USING DAPB18,R14
         MVC   0(MODEL18L,R14),MODEL18
         MVC   DA18DDN,DDNAME
         LA    R1,MYDAPL
         BAL   R14,DAIR
         NI    ALLOCSW,255-1
         B     ALLOCX
         SPACE
DAIR     ST    R14,DAIRR
         AIF   (NOT &MVS).SKIP6
         L     R15,16
         TM    732(R15),X'80'     CVTDAIR
         BNO   DAIRLINK
         L     R15,732(,R15)
         BALR  R14,R15
         B     DAIRRET
DAIRLINK EQU   *
.SKIP6   ANOP
         LINK  EP=IKJDAIR,SF=(E,LINKAREA)
         SPACE
DAIRRET  L     R14,DAIRR
         BR    R14
         SPACE
         EJECT
************************************************************
*                                                          *
*         ISAM FORMAT 2                                    *
*                                                          *
************************************************************
         SPACE
FMT2     CLI   DSORGSW,C'2'        IS FORMAT 2 IN?
         BE    ISAMF               YES - BRANCH
         CLI   DSORGSW,C'1'        IS DSORG ISAM?
         BNE   ISAMX               NO - BRANCH
         CLC   DS1PTRDS(5),=XL5'00'
         BE    ISAMX               NO FORMAT 2 - BRANCH
         MVC   VTOCCHHR(5),DS1PTRDS
         LA    R1,MYCAM
         MVC   0(16,R1),OBTSEEK
         LA    R0,VTOCCHHR
         ST    R0,4(,R1)
         LA    R0,VOLUME
         ST    R0,8(,R1)
         LA    R0,MYF2DSCB
         ST    R0,12(,R1)
         OBTAIN (1)
         LTR   R15,R15
         BZ    ISAMOBOK
         LA    R0,L'MSG11
         LA    R1,MSG11
         BAL   R14,PUTMSG
         B     NEXTD12
ISAMOBOK EQU   *
ISAMF    EQU   *
         CLI   ISAMKW+1,0
         BE    ISAMX
         LA    R1,MSG12
         LA    R0,L'MSG12
         BAL   R14,PUTLINE
         LA    R8,MYF2DSCB         ADDRESSABILITY
         MVI   MSGWK,C' '
         MVC   MSGWK+1(L'MSGWK-1),MSGWK
         SPACE
         MVC   HALF,DS2OVRCT       OVERFLOW RECORD COUNT
         LH    R1,HALF
         CVD   R1,DOUBLE
         LA    R1,MSGWK+4
         MVC   0(6,R1),=X'402020202120'
         ED    0(6,R1),DOUBLE+5
         SPACE
         MVC   HALF,DS2TAGDT       TAG DELETION COUNT
         LH    R1,HALF
         CVD   R1,DOUBLE
         LA    R1,MSGWK+24
         MVC   0(6,R1),=X'402020202120'
         ED    0(6,R1),DOUBLE+5
         SPACE
         MVC   FULL,DS2PRCTR       PRIME RECORD COUNT
         L     R1,FULL
         CVD   R1,DOUBLE
         LA    R1,MSGWK+41
         MVC   0(6,R1),=X'402020202120'
         ED    0(6,R1),DOUBLE+5
         SPACE
         LA    R1,MSGWK
         LA    R0,60
         BAL   R14,PUTLINE
ISAMX    EQU   *
         EJECT
************************************************************
*                                                          *
*         CONCATENATED DATA SETS                           *
*                                                          *
************************************************************
         SPACE
         ICM   R1,15,CONCTPTR      GET POINTER TO NEXT TIOT ENTRY
         BZ    CONCATX             ZERO SO 'FILE' NOT SPECIFIED
         CLI   0(R1),0             END OF TIOT?
         BE    CONCATX             YES
         CLI   4(R1),C' '          DDNAME BLANK? (NULL FOR FREED SLOT)
         BNE   CONCATX             NO, NOT A CONCATENATION
         MVI   CONCATSW,1          YES
         SLR   R15,R15             CLEAR FOR INSERT
         B     DDFOUND             PROCESS CONCATENATED DATA SET
CONCATX  EQU   *
         ICM   R1,15,SDSAREA       ALLOCATION RETRIEVAL EXIT TAKEN?
         BZ    NEXTDSN             NO
         L     R0,SDSPOOL          YES, LOAD SUBPOOL AND SIZE
         FREEMAIN R,A=(1),LV=(0)   FREE IT
         B     NEXTDSN
         EJECT
************************************************************
*                                                          *
*        PUTMSG ROUTINE                                    *
*                                                          *
************************************************************
         SPACE
PUTMSG   STM   R14,R1,PUTLINS
         XC    MYOLD(8),MYOLD
         XC    MYSEG1(4),MYSEG1
         MVC   MYPTPB(12),MODLPTPM
         LA    R14,1               NO. OF MESSAGE SEGMENTS
         ST    R14,MYOLD
         LA    R14,MYSEG1          POINT TO 1ST SEGMENT
         ST    R14,MYOLD+4
         LR    R14,R0              LENGTH IN R0
         LA    R14,4(,R14)         ADD 4
         LA    R15,MYSEG1+4
         CLC   0(3,R1),=C'IKJ'     IS DATA PRECEEDED BY MESSAGE ID?
         BE    *+16                YES - BRANCH
         LA    R14,1(,R14)         ADD 1 TO LENGTH
         MVI   0(R15),C' '         INSERT LEADING BLANK
         LA    R15,1(,R15)         BUMP POINTER
         STH   R14,MYSEG1
         LR    R14,R0
         BCTR  R14,0
         B     *+10
         MVC   0(0,R15),0(R1)      MOVE MESSAGE IN
         EX    R14,*-6
         L     R15,MYPUTLEP
         SPACE
         PUTLINE PARM=MYPTPB,OUTPUT=(MYOLD),MF=(E,MYIOPL),ENTRY=(15)
         SPACE
         LM    R14,R1,PUTLINS
         BR    R14
         EJECT
************************************************************
*                                                          *
*        PUTLINE ROUTINE                                   *
*                                                          *
************************************************************
         SPACE
PUTLINE  STM   R14,R1,PUTLINS
         XC    MYSEG1(4),MYSEG1
         MVC   MYPTPB(12),MODLPTPB
         LR    R14,R0              LENGTH IN R0
         LA    R14,4(,R14)         ADD 4
         STH   R14,MYSEG1
         LR    R14,R0
         BCTR  R14,0
         B     *+10
         MVC   MYSEG1+4(0),0(R1)   MOVE TEXT IN
         EX    R14,*-6
         L     R15,MYPUTLEP
         SPACE
         PUTLINE PARM=MYPTPB,OUTPUT=(MYSEG1,DATA),MF=(E,MYIOPL),       +
               ENTRY=(15)
         SPACE
         LM    R14,R1,PUTLINS
         BR    R14
         EJECT
************************************************************
*                                                          *
*        TERMINATION                                       *
*                                                          *
************************************************************
         SPACE
EXIT12   MVI   RC+1,12
EXIT     EQU   *
         IKJRLSA MYANS
         SPACE
         CLI   RC+1,0              IS RC ZERO?
         BZ    NOSTACKD            YES, BRANCH
         MVC   MYSTPB(STACKDL),STACKD
         SPACE
         STACK DELETE=ALL,PARM=MYSTPB,MF=(E,MYIOPL)
         SPACE
         TCLEARQ
NOSTACKD EQU   *
         LH    R15,RC
EXITX    LR    1,13
         L     R0,@SIZE
         L     13,4(,13)
         ST    15,16(,13)
         FREEMAIN R,A=(1),LV=(0)
         LM    14,12,12(13)
         BR    14
         SPACE 2
************************************************************
*                                                          *
*        CONSTANTS                                         *
*                                                          *
************************************************************
         SPACE
*              DSCBS PER TRACK, TRACKS PER CYLINDER, NAME, TRACK SIZE
DEVTABLE DS    0H
         DC    H'39,019',C' 3330V',AL2(13165)     30582009
DEVTBLEN EQU   *-DEVTABLE
         DC    H'16,010',C' 2311 ',AL2(0)             2001
         DC    H'63,200',C' 2301 ',AL2(0)             2002  DRUM
         DC    H'17,010',C' 2303 ',AL2(0)             2003  DRUM
*        DC    H'22,046',C' 2302 ',AL2(0)             2004
         DC    H'45,015',C' 9345 ',AL2(0)         30102004
         DC    H'08,010',C' 2321 ',AL2(0)             2005  DATA CELL
         DC    H'18,008',C'2305-1',AL2(14576)         2006
         DC    H'34,008',C'2305-2',AL2(14858)     30502007
         DC    H'25,020',C' 2314 ',AL2(07403)         2008
         DC    H'39,019',C' 3330 ',AL2(13165)     30502009
         DC    H'22,012',C' 3340 ',AL2(08535)     3040200A
         DC    H'47,030',C' 3350 ',AL2(19254)     3050200B
         DC    H'51,012',C' 3375 ',AL2(36000)     3010200C
         DC    H'39,019',C'3330-1',AL2(13165)     3050200D
         DC    H'53,015',C' 3380 ',AL2(47968)     3010200E
         DC    H'50,015',C' 3390 ',AL2(58786)     3010200F
         DC    H'52,020',C' F6421',AL2(27051)     30502085
         SPACE
DEVTBLSZ DC    AL2(DEVTBLEN)       KEEP AT END OF DEVTABLE
         EJECT
MODLPTPM PUTLINE OUTPUT=(1,TERM,SINGLE,INFOR),                         X
               TERMPUT=(EDIT,WAIT,NOHOLD,NOBREAK),MF=L
         SPACE
STACKD   STACK DELETE=ALL,MF=L
STACKDL  EQU   *-STACKD
         SPACE
MODLPTPB PUTLINE OUTPUT=(1,TERM,SINGLE,DATA),                          X
               TERMPUT=(EDIT,WAIT,NOHOLD,NOBREAK),MF=L
         SPACE
MSG04    DC    C'IKJ58503I DATA SET '
MSG04A   DC    C' NOT IN CATALOG'
MSG05    DC    C'IKJ58503I DATA SET '
MSG05A   DC    C' NOT ON VOLUME '
MSG06    DC    C'IKJ58503I DATA SET '
MSG06A   DC    C' ON UNMOUNTED VOLUME '
MSG07    DC    C'--RECFM-LRECL-BLKSIZE-DSORG-CREATED---ACCESSED--EXPIRE+
               S---SECURITY--'
MSG07A   DC    C'KEYLN-RKP--'
MSG07B   DC    C'MODIFIED---'
MSG08    DC    C'--VOLUME--DEVICE--ALLOC--2ND.QNTY--TRACKS--UNUSED--EXT+
               ENTS--'
MSG12    DC    C'--OVERFLOW RECORDS--TAGGED DELETION--PRIME RECORDS--'
MSG14    DC    C'FILENAME '
MSG14A   DC    C' INVALID, MORE THAN 8 CHARACTERS  '
MSG14B   DC    C' IS NOT CURRENTLY ALLOCATED       '
MSG14C   DC    C' NOT ALLOCATED TO A DASD DATA SET '
MSG15    DC    C'--DIRECTORY BLOCKS--USED--UNUSED--MEMBERS--ALIASES--TO+
               TAL--'
MSG16    DC    C'  ERROR READING DIRECTORY'
MSG17    DC    C'UNABLE TO ALLOCATE DATA SET TO READ DIRECTORY'
MSG18    DC    C'--CATALOGUED--2ND.SPACE EXTENSION--REBLOCKABLE--SYSTEM+
                BLOCKED--'
BLANKS   DC    16C' '
LOCCAM   CAMLST NAME,2,,4
OBTCAM   CAMLST SEARCH,2,3,4
OBTSEEK  CAMLST SEEK,2,3,4
         DS    0F
YMDNY    DC    AL2(334,304,273,243)
         DC    AL2(212,181,151,120)
         DC    AL2(90,59,31,0)
YMDLY    DC    AL2(335,305,274,244)
         DC    AL2(213,182,152,121)
         DC    AL2(91,60,31,0)
         LTORG
MSG01    DC    C'PARSE ERROR'
MSG02    DC    C'IKJ58509I DATA SET NAME REQUIRED WHEN MEMBER IS SPECIF+
               IED'
MSG03    DC    C'ERROR IN DEFAULT SERVICE ROUTINE'
MSG09    DC    C'ERROR READING FORMAT 3 DSCB'
MSG11    DC    C'ERROR READING FORMAT 2 DSCB'
MODEL08  DC    AL2(8),XL10'0',CL24' ',XL16'0',CL16' ',XL8'0',CL8' '
MODEL08L EQU   *-MODEL08
MODEL18  DC    X'0018',XL10'0',CL18' ',XL2'0',CL8' '
MODEL18L EQU   *-MODEL18
SMSPCTYP DC    CL9'AVG BLKSZ'
         DC    CL9'MEGABYTES'
         DC    CL9'KILOBYTES'
         DC    CL9'BYTES    '
         DC    CL9'**       '
*        IHAUDA DSECT=NO           USAGE DESCRIPTION AREA        GP@HC*
UDA      DC    0F'0'                                                  *
UDALEN   DC    H'16'                                                  *
UDAFLAG1 DC    X'00'                                                  *
         DC    X'00'                                                  *
UDAFLAG3 DC    X'08'               UDANORFU IS SET ON                 *
UDAFLAG4 DC    X'00'                                                  *
         DC    2X'00'                                                 *
UDAUACC  DC    F'0'                                                   *
UDASACC  DC    F'0'                                                   *
*        IHAUDA MACRO CALL SUPPRESSED - EXPANDED ABOVE           GP@HC*
DIRUDAX  DC    X'94',AL3(UDA)
         PRINT NOGEN
DIRDCB   DCB   DDNAME=DYNAM,DSORG=PO,MACRF=R,EODAD=DIREOF,SYNAD=DIRSYN,X
               RECFM=U,BLKSIZE=256,EXLST=DIRUDAX
DIRDCBL  EQU   *-DIRDCB
         SPACE
         PRINT GEN
DIRREADM READ  DIRDECB,SF,MF=L
DIRDECBL EQU   *-DIRDECB
         PRINT GEN
HEXTAB   DC    C'0123456789ABCDEF'
EODAD    EQU   32
RECFM    EQU   36
EXLST    EQU   36
DDNAM    EQU   40
OFLGS    EQU   48
SYNAD    EQU   56
BLKSI    EQU   62
LRECL    EQU   82
         DC    0D'0'
         SPACE
************************************************************
*                                                          *
*        PARSE PARAMETERS                                  *
*                                                          *
************************************************************
         SPACE
         PRINT NOGEN
SHOWDPCL IKJPARM
DSN      IKJPOSIT DSTHING,LIST,PROMPT='DATA SET NAME'
FILEKW   IKJKEYWD
         IKJNAME 'FILE'
QUICKKW  IKJKEYWD
         IKJNAME 'QUICKLY'
VOLKW    IKJKEYWD
         IKJNAME 'VOLUME',SUBFLD=VOLSF
ISAMKW   IKJKEYWD
         IKJNAME 'ISAM'
DIRKW    IKJKEYWD
         IKJNAME 'DIRECTORY'
EXTKW    IKJKEYWD
         IKJNAME 'EXTENTS'
VOLSF    IKJSUBF
VOL      IKJIDENT 'VOLUME SERIAL',                                     +
               FIRST=ALPHANUM,OTHER=ALPHANUM,MAXLNTH=6,                +
               PROMPT='SERIAL NUMBER OF VOLUME WHICH CONTAINS DATA SET'
         IKJENDP
         PRINT GEN
         SPACE
************************************************************
*                                                          *
*        DSECTS                                            *
*                                                          *
************************************************************
         SPACE
@DATA    DSECT
         DS    18F                 REGISTER SAVEAREA
LINKAREA DS    2F
RC       DS    F
NEWDSCB# DS    H
JMPLBL3# DS    H
MYPPL    DS    7F
MYANS    DS    F
MYUWA    DS    F
MYECB    DS    F                  USED BY PUTLINE ROUTINE
MYIOPL   DS    4F                 USED BY PUTLINE ROUTINE
MYPTPB   DS    3F                 USED BY PUTLINE ROUTINE
MYOLD    DS    2F                 USED BY PUTLINE ROUTINE
MYSEG1   DS    2H,CL100           USED BY PUTLINE ROUTINE
PUTLINS  DS    4F                 USED BY PUTLINE ROUTINE
MYPUTLEP DS    F                  USED BY PUTLINE ROUTINE
MYSTPB   DS    5F
DDNAME   DS    CL8
UNIT     DS    CL6
DIRSW    DS    C
ALLOCSW  DS    C
ALLOCR   DS    F
DAIRR    DS    F
UCBPTR   DS    F
CPPLPTR  DS    F
DIRBLKS  DS    F
DIRBLKSU DS    F
MEMBERS  DS    F
ALIASES  DS    F
CONCTPTR DS    F
CONCTCNT DS    F
VOLUME   DS    CL6
DSNAME   DS    H,CL44
MYDAPL   DS    0F (5F)
MYDFPB   DS    5F
MYCAM    DS    4F
VSAMSW   DS    CL1
CONCATSW DS    CL1
RECFMWA  DS    CL6
DSORGWA  DS    CL5
YMDOUT   DS    CL8
YMDREGS  DS    9F
SSPWA    DS    CL36
SSPWA2   DS    CL21  ROOM FOR CONTIG-MXIG-ALX-ROUND
LASTTRK  DS    F
EXTENTS  DS    H
VTOCCHHR DS    XL5
TRKCYL   DS    H
DSCBTRK  DS    H
DSCBTTR  DS    XL3
TRKWA    DS    CL6
FORMAT4  DS    0F,0CL44
MSGWK    DS    CL128
MYWK5    DS    CL5,CL1
DOUBLE   DS    D
HALF     EQU   DOUBLE,2
FULL     EQU   DOUBLE,4
MYF1KEY  DS    CL44
MYF1DSCB DS    CL140               96 BYTES OF DSCB, 5 BYTES CCHHR
MYEXDSCB DS    0D,CL140
EXTPTR   DS    F
MYLOCBUF DS    0D,XL265
MYF2DSCB DS    0D,CL140            ISAM FORMAT 2 DSCB
DSORGSW  DS    CL1
DESCRIP  DS    CL80
DIRDCBW  DS    0F,(DIRDCBL)X
DIRDECBW DS    0F,(DIRDECBL)X
DIRMSG   DS    CL72
MYDAPB   DS    0D  (21F)
BLOCK    DS    0D,256C
DIREXLST DS    2F
DEVDATA  DS    2F
OPEN     DS    0F
RDJFCB   DS    F
JFCB     DS    0D,CL176
         DS    0D
*SDSARL  IHAARL DSECT=NO,PREFIX=SDS  ALLOCATION RETRIEVAL LIST   GP@P6*
SDSARL   DS    0F                                                     *
SDSLEN   DS    H                   LENGTH OF THIS AREA - AT LEAST 36  *
SDSIDENT DS    CL2                 AREA ID - MUST BE 'AR'             *
SDSOPT1  DS    X                   OPTION BYTE - X'80'=AREA ABOVE LINE*
SDSRSVD1 DS    XL7                 RESERVED - SHOULD BE ZERO          *
SDSRETRV DS    H                   DS # TO GET DATA FOR - 0 FOR ALL   *
SDSFIRST DS    H                   1ST DS # TO GET DATA FOR - 0/1=1ST *
SDSAREA  DS    A                   ADDRESS OF ALLOC'N RETRIEVAL AREA  *
SDSPOOL  DS    HL1                 SUBPOOL - 0=>KEY 8-F, 230=>KEY 0-7 *
SDSRLEN  DS    FL3                 LENGTH OF ALLOC'N RETRIEVAL AREA   *
SDSRTRVD DS    H                   DS # FOR WHICH INFO WAS FETCHED    *
SDSCONC  DS    H                   DS # CONCATENATED IN DD            *
SDSRCODE DS    HL1                 REASON CODE                        *
SDSRSVD2 DS    XL7                 RESERVED - SET BY RDJFCB           *
*        IHAARL MACRO CALL SUPPRESSED - EXPANDED ABOVE           GP@P6*
EXTTABLE DS    256XL12
@DATAL   EQU   *-@DATA
         SPACE 2
         IKJCPPL
         SPACE 2
         IKJIOPL
         SPACE 2
         IKJPPL
         SPACE 2
         IKJDFPB
         SPACE
         AIF   (NOT &MVS).SKIP8
         IKJUPT
.SKIP8   AIF   (&MVS).SKIP9
         IKJPSCB
.SKIP9   ANOP
         SPACE
DSCB     DSECT
IECSDSL1 EQU   *                   FORMAT 1 DSCB
IECSDSF1 EQU   IECSDSL1
DS1DSNAM DS    CL44                DATA SET NAME
DS1FMTID DS    CL1                 FORMAT IDENTIFIER
DS1DSSN  DS    CL6                 DATA SET SERIAL NUMBER
DS1VOLSQ DS    XL2                 VOLUME SEQUENCE NUMBER
DS1CREDT DS    XL3                 CREATION DATE
DS1EXPDT DS    XL3                 EXPIRATION DATE
DS1NOEPV DS    XL1                 NUMBER OF EXTENTS ON VOLUME
DS1NOBDB DS    XL1                 NUMBER OF BYTES USED IN LAST
*                                     DIRECTORY BLOCK
DS1FLAG1 DS    XL1                 FLAG 1
*        EQU   X'80'               COMPRESSABLE EXTENDED FORMAT
*        EQU   X'40'               CHECKPOINTED DATASET
*        EQU   X'20'               VSE EXP DATE SPEC BY RET PERIOD
*        EQU   X'10'               DATA SET HAS BEEN RECALLED
*        EQU   X'08'               >64K TRACK SUPPORT ("LARGE")
DS1SYSCD DS    CL13                SYSTEM CODE
DS1REFD  DS    XL3                 REFERENCE DATE
DS1SMSFG DS    XL1                 SYSTEM MANAGED STORAGE INDICATORS
*        EQU   X'80'               SYSTEM MANAGED DATA SET
*        EQU   X'40'               NO BCS ENTRY EXISTS FOR DATA SET
*        EQU   X'20'               DATA SET MAY BE REBLOCKED
*        EQU   X'10'               DADSM CREATE ORIGINATED BLKSIZE
*        EQU   X'08'               DATA SET IS A PDSE
*        EQU   X'04'               DATA SET IS A STRIPE
*        EQU   X'02'               HFS DATA SET
*        EQU   X'01'               D.S. ATTRIBUTE EXTENSION
DS1SCEXT DS    0XL3                SECONDARY SPACE EXTENSION
DS1SCXTF DS    XL1                 SECONDARY SPACE EXTENSION FLAG BYTE
*        EQU   X'80'               DS1SCXTV IS ORIGINAL AVG BLOCKLEN
*        EQU   X'40'               DS1SCXTV IS MEGABYTES
*        EQU   X'20'               DS1SCXTV IS KILOBYTES
*        EQU   X'10'               DS1SCXTV IS BYTES
*        EQU   X'08'               DS1SCXTV IS BYTES/256
*        EQU   X'04'               DS1SCXTV IS BYTES/65536
*        EQU   X'02'               RESERVED
*        EQU   X'01'               RESERVED
DS1SCXTV DS    XL2                 SECONDARY SPACE EXTENSION VALUE
DS1DSORG DS    XL2                 DATA SET ORGANIZATION
DS1RECFM DS    XL1                 RECORD FORMAT
DS1OPTCD DS    XL1                 OPTION CODE
DS1BLKL  DS    XL2                 BLOCK LENGTH
DS1LRECL DS    XL2                 RECORD LENGTH
DS1KEYL  DS    XL1                 KEY LENGTH
DS1RKP   DS    XL2                 RELATIVE KEY POSITION
DS1DSIND DS    XL1                 DATA SET INDICATORS
DS1SCALO DS    XL4                 SECONDARY ALLOCATION
DS1LSTAR DS    XL3                 LAST USED TRACK AND BLOCK ON TRACK
DS1TRBAL DS    XL2                 BYTES REMAINING ON LAST TRACK USED
         DS    XL2                 RESERVED
DS1EXT1  DS    XL10                FIRST EXTENT DESCRIPTION
*        FIRST BYTE                EXTENT TYPE INDICATOR
*        SECOND BYTE               EXTENT SEQUENCE NUMBER
*        THIRD - SIXTH BYTES       LOWER LIMIT
*        SEVENTH - TENTH BYTES     UPPER LIMIT
DS1EXT2  DS    XL10                SECOND EXTENT DESCRIPTION
DS1EXT3  DS    XL10                THIRD EXTENT DESCRIPTION
DS1PTRDS DS    XL5                 POSSIBLE PTR TO A FORMAT 2 OR 3 DSCB
DS1END   EQU   *
         ORG   DSCB
IECSDSL2 EQU   *                   FORMAT 2 DSCB
IECSDSF2 EQU   IECSDSL2
         DS    XL1                 KEY IDENTIFIER
DS22MIND DS    XL7                 ADDRESS OF 2ND LEVEL MASTER INDEX
DS2L2MEN DS    XL5                 LAST 2ND LEVEL MASTER INDEX ENTRY
DS23MIND DS    XL7                 ADDRESS OF 3RD LEVEL MASTER INDEX
DS2L3MIN DS    XL5                 LAST 3RD LEVEL MASTER INDEX ENTRY
         DS    XL11                RESERVED
DS2LPDT  DS    XL8                 LAST PRIME TRACK ON LAST PRIME CYL
DS2FMTID DS    CL1                 FORMAT IDENTIFIER
DS2NOLEV DS    XL1                 NUMBER OF INDEX LEVELS
DS2DVIND DS    XL1                 HIGH LEVEL INDEX DEVELOPMENT
*                                     INDICATOR
DS21RCYL DS    XL3                 FIRST DATA RECORD IN CYLINDER
DS2LTCYL DS    XL2                 LAST DATA TRACK IN CYLINDER
DS2CYLOV DS    XL1                 NUMBER OF TRACKS FOR CYLINDER
*                                     OVERFLOW
DS2HIRIN DS    XL1                 HIGHEST 'R' ON HIGH-LEVEL INDEX TRK
DS2HIRPR DS    XL1                 HIGHEST 'R' ON PRIME DATA TRACK
DS2HIROV DS    XL1                 HIGHEST 'R' ON OVERFLOW DATA TRACK
DS2RSHTR DS    XL1                 'R' OF LAST DATA RECORD ON SHARED
*                                     TRACK
DS2HIRTI DS    XL1                 HIGHEST 'R' ON UNSHARED TRACK OF
*                                     TRACK INDEX
DS2HIIOV DS    XL1                 HIGHEST 'R' FOR INDEPENDENT OVERFLOW
*                                     DATA TRACKS
DS2TAGDT DS    XL2                 TAG DELETION COUNT
DS2RORG3 DS    XL3                 NON-FIRST OVERFLOW REFERENCE COUNT
DS2NOBYT DS    XL2                 NUMBER OF BYTES FOR HIGHEST-LEVEL
*                                     INDEX
DS2NOTRK DS    XL1                 NUMBER OF TRACKS FOR HIGHEST-LEVEL
*                                     INDEX
DS2PRCTR DS    XL4                 PRIME RECORD COUNT
DS2STIND DS    XL1                 STATUS INDICATORS
DS2CYLAD DS    XL7                 ADDRESS OF CYLINDER INDEX
DS2ADLIN DS    XL7                 ADDRESS OF LOWEST LEVEL MASTER INDEX
DS2ADHIN DS    XL7                 ADDRESS OF HIGHEST LEVEL MASTER
*                                     INDEX
DS2LPRAD DS    XL8                 LAST PRIME DATA RECORD ADDRESS
DS2LTRAD DS    XL5                 LAST TRACK INDEX ENTRY ADDRESS
DS2LCYAD DS    XL5                 LAST CYLINDER INDEX ENTRY ADDRESS
DS2LMSAD DS    XL5                 LAST MASTER INDEX ENTRY ADDRESS
DS2LOVAD DS    XL8                 LAST INDEPENDENT OVERFLOW RECORD
*                                     ADDRESS
DS2BYOVL DS    XL2                 BYTES REMAINING ON OVERFLOW TRACK
DS2RORG2 DS    XL2                 TRACKS REMAINING IN INDEPENDENT
*                                     OVERFLOW AREA
DS2OVRCT DS    XL2                 OVERFLOW RECORD COUNT
DS2RORG1 DS    XL2                 CYLINDER OVERFLOW AREA COUNT
DS2NIRT  DS    XL3                 DUMMY TRACK INDEX ENTRY ADDRESS
DS2PTRDS DS    XL5                 POSSIBLE POINTER TO A FORMAT 3 DSCB
DS2END   EQU   *
         ORG   DSCB
IECSDSL3 EQU   *                   FORMAT 3 DSCB
IECSDSF3 EQU   IECSDSL3
         DS    XL4                 KEY IDENTIFIER
DS3EXTNT DS    XL40                FOUR EXTENT DESCRIPTIONS
*        FIRST BYTE                EXTENT TYPE INDICATOR
*        SECOND BYTE               EXTENT SEQUENCE NUMBER
*        THIRD - SIXTH BYTES       LOWER LIMIT
*        SEVENTH - TENTH BYTES     UPPER LIMIT
DS3FMTID DS    CL1                 FORMAT IDENTIFIER
DS3ADEXT DS    XL90                NINE ADDITIONAL EXTENT DESCRIPTIONS
DS3PTRDS DS    XL5                 POSSIBLE POINTER TO A FORMAT 3 DSCB
DS3END   EQU   *
         ORG   DSCB
IECSDSL4 EQU   *                   FORMAT 4 DSCB
IECSDSF4 EQU   IECSDSL4
DS4IDFMT DS    CL1                 FORMAT IDENTIFIER
DS4HPCHR DS    XL5                 HIGHEST ADDRESS OF A FORMAT 1 DSCB
DS4DSREC DS    XL2                 NUMBER OF AVAILABLE DSCB'S
DS4HCCHH DS    XL4                 CCHH OF NEXT AVAILABLE ALTERNATE TRK
DS4NOATK DS    XL2                 NUMBER OF REMAINING ALTERNATE TRACKS
DS4VTOCI DS    XL1                 VTOC INDICATORS
DS4DOSBT EQU   X'80'               DOS BIT
DS4DVTOC EQU   X'40'               THE INDEX WAS DISABLED
DS4DSTKP EQU   X'10'               DOS STACKED PACK
DS4DOCVT EQU   X'08'               DOS CONVERTED VTOC
DS4DIRF  EQU   X'04'               DIRF BIT
DS4DICVT EQU   X'02'               DIRF RECLAIMED
DS4IVTOC EQU   X'01'               AN INDEX HAS BEEN CREATED FOR VTOC
DS4NOEXT DS    XL1                 NUMBER OF EXTENTS IN THE VTOC
DS4SMSFG DS    XL1                 SYSTEM MANAGED STORAGE INDICATORS
*        EQU   X'C0'               SYSTEM MANAGED STORAGE VOLUME
*        EQU   X'40'               SMS VOLUME IN INITIAL STATUS
         DS    XL1                 RESERVED
DS4DEVCT DS    0XL14               DEVICE CONSTANTS
DS4DEVSZ DS    XL4                 DEVICE SIZE
DS4DEVTK DS    XL2                 DEVICE TRACK LENGTH
DS4DEVOV DS    0XL2                KEYED RECORD OVERHEAD
DS4DEVI  DS    XL1                    NON-LAST KEYED RECORD OVERHEAD
DS4DEVL  DS    XL1                    LAST KEYED RECORD OVERHEAD
DS4DEVK  DS    XL1                 NON-KEYED RECORD OVERHEAD
*                                     DIFFERENTIAL
DS4DEVFG DS    XL1                 FLAG BYTE
DS4DEVTL DS    XL2                 DEVICE TOLERANCE
DS4DEVDT DS    XL1                 NUMBER OF DSCB'S PER TRACK
DS4DEVDB DS    XL1                 NUMBER OF DIRECTORY BLOCKS PER TRACK
DS4AMTIM DS    XL8                 VSAM TIME STAMP
DS4AMCAT DS    0XL3                VSAM CATALOG INDICATOR
DS4VSIND DS    XL1                 VSAM INDICATORS
DS4VSCRA DS    XL2                 RELATIVE TRACK LOCATION OF THE CRA
DS4R2TIM DS    XL8                 VSAM VOLUME/CATALOG MATCH
*                                  TIME STAMP
         DS    XL5                 RESERVED
DS4F6PTR DS    XL5                 POINTER TO FIRST FORMAT 6 DSCB
DS4VTOCE DS    XL10                VTOC EXTENT DESCRIPTION
         DS    XL25                RESERVED
DS4END   EQU   *
         ORG   DSCB
IECSDSL5 EQU   *                   FORMAT 5 DSCB
IECSDSF5 EQU   IECSDSL5
DS5KEYID DS    XL4                 KEY IDENTIFIER
DS5AVEXT DS    XL5                 AVAILABLE EXTENT
*        BYTES 1 - 2     RELATIVE TRACK ADDRESS OF THE FIRST TRACK
*                        IN THE EXTENT
*        BYTES 3 - 4     NUMBER OF UNUSED CYLINDERS IN THE EXTENT
*        BYTE  5         NUMBER OF ADDITIONAL UNUSED TRACKS
DS5EXTAV DS    XL35                SEVEN AVAILABLE EXTENTS
DS5FMTID DS    CL1                 FORMAT IDENTIFIER
DS5MAVET DS    XL90                EIGHTEEN AVAILABLE EXTENTS
DS5PTRDS DS    XL5                 POINTER TO NEXT FORMAT 5 DSCB
DS5END   EQU   *
         ORG   DSCB
IECSDSL6 EQU   *                   FORMAT 6 DSCB
IECSDSF6 EQU   IECSDSL6
DS6KEYID DS    XL4                 KEY IDENTIFIER
DS6AVEXT DS    XL5                 SHARED EXTENT DESCRIPTION
*        BYTES 1 - 2     RELATIVE TRACK ADDRESS OF THE FIRST CYLINDER
*        BYTES 3 - 4     NUMBER OF FULL CYLINDERS BEING SHARED
*        BYTE  5         NUMBER OF DATA SETS SHARING THE EXTENT
DS6EXTAV DS    XL35                SEVEN SHARED EXTENTS
DS6FMTID DS    CL1                 FORMAT IDENTIFIER
DS6MAVET DS    XL90                EIGHTEEN SHARED EXTENTS
DS6PTRDS DS    XL5                 POINTER TO NEXT FORMAT 6 DSCB
DS6END   EQU   *
         SPACE
         IKJDAPL
         SPACE
         IKJDAP08
         SPACE
         IKJDAP18
         SPACE
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
         END
/*
//LKED    EXEC PGM=IEWL,PARM='MAP,LIST,LET,RENT'
//SYSLIN   DD  DSN=&&LOADSET,DISP=(OLD,DELETE)
//         DD  DDNAME=SYSIN
//SYSLMOD  DD  DSN=SYS2.CMDLIB,DISP=SHR
//SYSPRINT DD  SYSOUT=*
//SYSUT1   DD  UNIT=VIO,SPACE=(CYL,(5,2))
//SYSIN    DD  *
 ALIAS SDS
 NAME SHOWDS(R)
/*
//ADDHELP EXEC PGM=IEBUPDTE,PARM=NEW
//SYSPRINT DD  SYSOUT=*
//SYSUT2   DD  DSN=SYS2.HELP,DISP=SHR
//SYSIN    DD  *
./ ADD NAME=SHOWDS
)F FUNCTION -
  THE SHOWDS COMMAND DISPLAYS A DATA SET'S ATTRIBUTES
  AND SPACE USAGE INFORMATION.
)X SYNTAX  -
         SHOWDS  'NAME'  VOLUME('VOLUME')   DIR  EXT  FILE
  REQUIRED - 'NAME'
  DEFAULTS - NONE
  ALIAS    - SDS
)O OPERANDS -
  'NAME'   - THE NAME OF THE DATA SET WHOSE ATTRIBUTES
             ARE TO BE DISPLAYED, OR IF THE 'FILE' KEYWORD
             IS ALSO SPECIFIED, THE 8-CHARACTER FILENAME (DDNAME)
             ALLOCATED TO THE DATA SET WHOSE ATTRIBUTES ARE
             TO BE DISPLAYED.
))VOLUME('VOLUME') - IF THE FIRST OPERAND IS THE NAME OF AN
             UNCATALOGED DATA SET, THIS KEYWORD SPECIFIES
             THE VOLUME ON WHICH THE DATA SET RESIDES.
             THE VOLUME KEYWORD IS IGNORED IF 'FILE' IS
             SPECIFIED.
))DIR      - DISPLAY INFORMATION ABOUT THE DIRECTORY OF
             THE PARTITIONED DATA SET.
))EXTENTS  - DISPLAY THE EXTENTS OF THE DATA SET (THE BEGINNING
             AND ENDING CYLINDER/TRACK LOCATIONS).
))FILE     - THIS KEYWORD INDICATES THAT THE FIRST OPERAND
             IS TO BE TREATED AS A FILENAME (DDNAME) INSTEAD
             OF A DATA SET NAME.  THE COMMAND WILL DETERMINE
             WHICH DATA SET IS CURRENTLY ALLOCATED TO THE
             SPECIFIED FILENAME AND DISPLAY ITS ATTRIBUTES.
             THIS ALLOWS ATTRIBUTES OF TEMPORARY DATA SETS
             TO BE DISPLAYED.
./ ALIAS NAME=SDS
./ ENDUP
/*
//

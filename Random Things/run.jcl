//Z88116J JOB 1,NOTIFY=&SYSUID
//***************************************************/
//COBRUN  EXEC IGYWCL,PARM.COBOL='LIB,APOST'
//COBOL.SYSIN  DD DSN=&SYSUID..CBL(MAIN),DISP=SHR
//COBOL.SYSLIB DD DSN=&SYSUID..COBOL.COPYLIB,DISP=SHR
//LKED.SYSLMOD DD DSN=&SYSUID..LOAD(MAIN),DISP=SHR
//***************************************************/
// IF RC <= 4 THEN
//***************************************************/
//RUN     EXEC PGM=MAIN
//STEPLIB   DD DSN=&SYSUID..LOAD,DISP=SHR
//SYSOUT    DD SYSOUT=*,OUTLIM=15000
//CEEDUMP   DD DUMMY
//SYSUDUMP  DD DUMMY
//***************************************************/
// ELSE
// ENDIF
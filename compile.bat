@ECHO OFF
IF EXIST "compile.dat" ( del /A compile.dat )
FOR %%f IN ("%CD%\*.sp") DO spcomp "%%f" -o "%%~nf.smx"
PAUSE
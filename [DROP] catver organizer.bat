@echo off

if "%~1"=="" (
	title ERROR
	echo ONLY DRAG AND DROP DATAFILE, OR DATFILE+CATVER.INI
	echo IF NOT CATVER.INI EXIST ONLY USE THE DATAFILE WITH:
	echo THE CURRENT ARCADE.DAT AND CATVER.INI FROM https://www.progettosnaps.net
	echo AND MAMEDIFF.EXE http://www.logiqx.com/Tools/
	pause&exit
)

if "%~x1"==".xml" set "_dat=%~1"&set "_catver=%~2"&set "_file=%~n1"
if "%~x1"==".dat" set "_dat=%~1"&set "_catver=%~2"&set "_file=%~n1"

if "%_dat%"=="" (
	if "%~x2"==".xml" set "_dat=%~2"&set "_catver=%~1"&set "_file=%~n2"
	if "%~x2"==".dat" set "_dat=%~2"&set "_catver=%~1"&set "_file=%~n2"
)
if "%_dat%"=="" title ERROR&echo NO DATAFILE FOUND&pause&exit


cd /d "%~dp0"

md _temp 2>nul

rem //save last complete build to start script faster
if not exist "_temp\COMPLETE.tmp" del _temp\*.tmp 2>nul

if exist "_temp\%_file%.tmp" (
	goto :skip
)else (
	del _temp\*.tmp 2>nul
)

set _src=4
>nul findstr /l /c:"sourcefile=" "%_dat%"&&set _src=6

if "%_catver%"=="" (call :use_mamediff)else (call :no_mamediff)

sort /unique _temp\temp.tmp /o _temp\menu.tmp
del _temp\temp.tmp


rem //get bios list
findstr /l /c:"isbios=""yes""" "%_dat%"
if %errorlevel% equ 1 (
	for /f tokens^=4^delims^=^" %%g in ('findstr /l /c:"runnable=""no""" "%_dat%"') do (
		(echo %%g)>>_temp\bios.tmp
	)
	
)else (
	for /f tokens^=2^,4^delims^=^" %%g in ('findstr /l /c:"isbios=""yes""" "%_dat%"') do (
		if "%%g"=="yes" (
			(echo %%h)>>_temp\bios.tmp
		)else (
			(echo %%g)>>_temp\bios.tmp
		)	
	)
)


rem //build paren-clone list
for /f tokens^=2^,%_src%^delims^=^" %%g in ('findstr /l /c:"cloneof=" "%_dat%"') do (
	(echo %%g	%%h)>>_temp\cloneof.tmp
)


type nul>_temp\COMPLETE.tmp

:skip
rem // old code -----------------------------

setlocal enabledelayedexpansion
md output 2>nul
del _temp\found.tmp 2>nul
set /a "_lines=0"
for /f "delims=" %%g in (_temp\menu.tmp) do set /a "_lines+=1"

:add_lines
set /a "_result=%_lines%%%15"
if not "%_result%"=="0" (
	(echo *)>>_temp\menu.tmp
	set /a "_lines+=1"
	goto add_lines
)

:loop

title ** Universal CATVER Game Organizer **

cls
set /a "_num=0"
set "_opt=none"

for /f "delims=" %%g in (_temp\menu.tmp) do (
	echo. %%g
	set /a "_num+=1"	
	if !_num! equ 15 (

		echo[
		echo              ** Hit 'Enter' to show more **
		echo ------------------------------------------------------------------
		echo * Case insensitive, you can type a full category: puzzle / match *
		echo * or just part, or sub-category: 2.5d, mature, fighting...       *
		echo * Escape regex [*] character like this \*                        *
		echo ------------------------------------------------------------------
		echo[
		set /p "_opt=Type a category, or 'Enter': "
		echo[
		if not "!_opt!"=="none" goto exit_list
		cls
		set /a "_num=0"
	)
)
goto loop
:exit_list

REM //validate selection
findstr /ir /c:"=.*%_opt%" _temp\catver.tmp >>_temp\found.tmp
if %errorlevel% equ 1 (
	title ERROR&echo INVALID SELECTION, NOTHING FOUND&timeout 2 >nul
	goto loop
)


:go_back
set "_opt2="

cls
REM echo What do you want to do with the files? 
echo ------------- OPTIONS ---------------
REM if not "%_folder%"=="" (
	REM echo 1. move
	REM echo 2. copy
REM )
echo 3. preview current list
echo 4. make a new list
echo 5. add another category to list
echo 6. remove items from current list
echo 7. Make batch script with the list
REM echo 9. cleanup and exit script
echo[
set /p "_opt2=Enter Option Number: "

REM if not "%_folder%"=="" (
	REM if "%_opt2%"=="1" call :do_folder move & goto go_next
	REM if "%_opt2%"=="2" call :do_folder copy & goto go_next
REM )
if "%_opt2%"=="3" goto preview_list
if "%_opt2%"=="4" del _temp\found.tmp&goto loop
if "%_opt2%"=="5" goto loop
if "%_opt2%"=="6" goto edit_list
if "%_opt2%"=="7" goto make_batch
REM if "%_opt2%"=="9" goto go_next

echo INVALID OPTION
timeout 2 >nul
goto go_back


REM :go_next



REM del _temp\found.txt _temp\cat.txt _temp\catver.1
REM rd _temp
REM title FINISHED
REM pause&exit

REM // ------------ end of script --------------------



:make_batch

echo. 
echo 1. MOVE games ^(use the script to remove unwanted games^)
echo 2. COPY games ^(use the script to make a playable pack^)
echo.
choice /n /c:12 /m "Enter Option: "
if %errorlevel% equ 1 (
	rem // add all clones of matched parents, since clones cant run without parent
	set _opt=move
	for /f "delims==" %%g in (_temp\found.tmp) do (
		for /f "delims=	" %%h in ('findstr /el /c:"	%%g" _temp\cloneof.tmp') do (
			findstr /bl /c:"%%h=" _temp\found.tmp||(echo %%h=Added Clone)>>_temp\found.tmp
		)
	)
)else (
	rem //add parents of orphan clones, to make matched clones playable
	rem //add bios too??
	set _opt=copy
	call :build_romof
	for /f "delims==" %%g in (_temp\found.tmp) do (
		
		rem //get bios
		for /f "tokens=2 delims=	" %%h in ('findstr /bl /c:"%%g	" _temp\romof.tmp') do (
			findstr /bl /c:"%%h=" _temp\found.tmp||(echo %%h=BIOS)>>_temp\found.tmp
		)
		rem //add parent
		for /f "tokens=2 delims=	" %%h in ('findstr /bl /c:"%%g	" _temp\cloneof.tmp') do (
			findstr /bl /c:"%%h=" _temp\found.tmp||(echo %%h=Added Parent)>>_temp\found.tmp
		)
	)
)

(echo @echo off
echo title Datafile2script Files Renamer ^^^| "%_file%" ^^^| Build: %DATE%

echo del _NOTFOUND.csv 2^>nul
echo choice /m "Continue? "
echo if %%errorlevel%% equ 2 exit
echo md _CATVER 2^>nul
echo cls^&echo ... ...)>"output\%_file%.bat"

for /f "tokens=1,2 delims==" %%g in (_temp\found.tmp) do (
	(echo %_opt% /y %%g.zip _CATVER^|^|^(echo "%%g";"%%h"^)^>^>_NOTFOUND.csv)>>"output\%_file%.bat"

)

title FINISHED
echo ALL DONE, THE SCRIPT ITS IN THE OUTPUT FOLDER, RUN IT IN THE ROM FOLDER
pause&exit
REM exit /b


:preview_list
cls&echo ************ current list ******************
echo.
type _temp\found.tmp
echo.
REM pause & goto go_back
pause&goto go_back






rem //label
:edit_list

copy /y _temp\found.tmp _temp\temp.tmp

:go_back2
cls&echo ************ current list ******************
echo.
type _temp\temp.tmp
echo.
echo --------- ---Options --------------------
echo 1. Save list and go back
echo 2. Dissmis and go back
echo.
set /p "_opt3=Enter category remove or option: " || set _opt3=3

findstr /irv /c:"=.*%_opt3%" _temp\temp.tmp >_temp\temp1.tmp

del _temp\temp.tmp&ren _temp\temp1.tmp temp.tmp

if "%_opt3%"=="1" (
	del _temp\found.tmp&ren _temp\temp.tmp found.tmp
	goto go_back
)
if "%_opt3%"=="2" del _temp\temp.tmp&goto go_back

goto go_back2



:build_romof
rem //build romof bios, only parents have romof bios
findstr /l /c:"romof=" "%_dat%" >_temp\temp.tmp
for /f "delims=" %%g in (_temp\bios.tmp) do (
	for /f tokens^=2^,%_src%^delims^=^" %%h in ('findstr /l /c:"romof=""%%g""" _temp\temp.tmp') do (
		(echo %%h	%%i)>>_temp\romof.tmp
	
	)
)
exit /b


:use_mamediff

md _sources 2>nul
for %%g in (_sources\*.dat) do set "_mame=%%g"
for %%g in (_sources\*.ini) do set "_catver=%%g"

if "%_mame%"=="" title ERROR&echo NO DATAFILE FOUND IN _SOURCES&pause&exit
if "%_catver%"=="" title ERROR&echo CATVER.INI WAS NOT FOUND IN _SOURCES&pause&exit

if exist "mamediff.exe" set "_mamediff=mamediff"
if exist "_bin\mamediff.exe" set "_mamediff=_bin\mamediff"
if "%_mamediff%"=="" title ERROR&echo MAMEDIFF.EXE WAS NOT FOUND&pause&exit

%_mamediff% -s "%_mame%" "%_dat%" >nul
move mamediff.out "_temp\%_file%.tmp"&del mamediff.log

rem //rebuild catver.ini with mamediff.out
for /f "tokens=1,2 delims=	" %%g in ('findstr /xr /c:"[a-z0-9_][a-z0-9_]*	[a-z0-9_][a-z0-9_]*" "_temp\%_file%.tmp"') do (
	echo %%g

	for /f "tokens=2 delims==" %%i in ('findstr /xr /c:"%%g=[^0][^.]..*" "%_catver%"') do (
		(echo %%h=%%i)>>_temp\catver.tmp
		(echo %%i)>>_temp\temp.tmp
	)
)


exit /b


:no_mamediff

rem //get gamelist from datafile
findstr /l /c:"<game name=" "%_dat%" >"_temp\%_file%.tmp"
if %errorlevel% equ 1 (
	findstr /l /c:"<machine name=" "%_dat%" >"_temp\%_file%.tmp"

)


for /f usebackq^tokens^=2^delims^=^" %%g in ("_temp\%_file%.tmp") do (
	echo %%g
	for /f "tokens=2 delims==" %%i in ('findstr /xr /c:"%%g=[^0][^.]..*" "%_catver%"') do (
		(echo %%g=%%i)>>_temp\catver.tmp
		(echo %%i)>>_temp\temp.tmp
	)
)


REM findstr /xr /c:".[a-z0-9_]*=[^0][^.]..*" "%_catver%" >_temp\catver.tmp
REM for /f "tokens=2 delims==" %%i in (_temp\catver.tmp) do (
	REM echo %%i
	REM (echo %%i)>>_temp\temp.tmp
REM )


exit /b
@echo off
title Universal CATVER Game Organizer  ^| Build: August/04/22


REM // path/filenames with exclamation marks are not allowed
SETLOCAL EnableDelayedExpansion
REM set "_home=%~0" & set "_batch=%~n0.bat"
REM set "_home=!_home:\%_batch%=!"


REM //folder
set "_folder=%~n1"

if not exist "catver.ini" (
	title ERROR
	echo catver.ini was not found...
	pause&exit
)

findstr /b /c:"[Category]" "catver.ini" >nul 2>&1
if %errorlevel%==1 (
	title ERROR
	echo THIS IS NOT A VALID MAME CATVER.INI FILE
	pause&exit
)


if not "%_folder%"=="" (
	if not exist "%_folder%\" (
		title ERROR
		echo NOT A VALID FOLDER
		pause&exit
	)
	
)

if not exist _temp (
	md _temp
) else (
	del _temp\cat.txt _temp\found.txt
)


echo ---------------------------------------------------
echo *     Generating Catver.ini menu items            *
echo * This can take a while if catver.ini is large    *
echo ---------------------------------------------------


REM //good to extract lines, but won't support single category entries
findstr /r /c:"^[0-9a-z_]*=.*/" "catver.ini" >_temp\catver.1
REM ****** line counter ************
set /a "_total_lines=0" & set /a "_count_lines=0"
for /f "delims=" %%g in (_temp\catver.1) do set /a "_total_lines+=1"

set "_flag=0"
title Extracting lines from catver.ini...
for /f "usebackq tokens=2 delims==" %%g in ("_temp\catver.1") do (

	REM ****** line counter ************	
	set /a "_count_lines+=1"
	set /a "_percent=(!_count_lines!*100)/!_total_lines!
	title Extracting lines: !_count_lines! / !_total_lines! ^( !_percent! %% ^)

	REM if /i "%%g"=="[VerAdded]" goto go_out
	REM if "!_flag!"=="1" (echo %%h) >>"_temp\cat.txt"
	REM //start adding lines after [Category] is detected
	REM if /i "%%g"=="[Category]" set "_flag=1"
	
	(echo %%g) >>"_temp\cat.txt"
)

REM :go_out

if not exist "_temp\cat.txt" (
	title ERROR
	echo THIS IS NOT A VALID MAME CATVER.INI FILE
	pause&exit
)

call :dups_remover cat.txt

sort _temp\cat.txt /o _temp\temp.1
del _temp\cat.txt & ren _temp\temp.1 cat.txt

set /a "_lines=0"
for /f "delims=" %%g in (_temp\cat.txt) do set /a "_lines+=1"

:add_lines

set /a "_result=%_lines%%%15"

if not "%_result%"=="0" (
	(echo *) >>_temp\cat.txt
	set /a "_lines+=1"
	goto add_lines
)

:loop

title ** Universal CATVER Game Organizer **

cls
set /a "_num=0"
set "_opt=none"

for /f "delims=" %%g in (_temp\cat.txt) do (
	echo %%g
	set /a "_num+=1"	
	if !_num! EQU 15 (

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
findstr /i /r /c:"=.*%_opt%" "_temp\catver.1" >>_temp\found.txt
if %errorlevel%==1 (
	title ERROR
	echo INVALID SELECTION, NOTHING FOUND
	timeout 2 >nul
	goto loop

)

:go_back
set "_opt2="

cls
echo What do you want to do with the files? 
echo ------------- OPTIONS ---------------
if not "%_folder%"=="" (
	echo 1. move
	echo 2. copy
)
echo 3. preview current list
echo 4. make a new list
echo 5. add another category to list
echo 6. remove items from current list
echo 7. Make batch script with the list
echo 9. cleanup and exit script
echo[
set /p "_opt2=Enter Option Number: "

if not "%_folder%"=="" (
	if "%_opt2%"=="1" call :do_folder move & goto go_next
	if "%_opt2%"=="2" call :do_folder copy & goto go_next
)
if "%_opt2%"=="3" (
	cls
	echo ************ current list ******************
	echo[
	type _temp\found.txt
	echo[
	pause & goto go_back

)

if "%_opt2%"=="4" del _temp\found.txt & goto loop

if "%_opt2%"=="5" goto loop

if "%_opt2%"=="6" (
	copy /y _temp\found.txt _temp\temp.1
	
	:go_back2
	cls
	echo ************ current list ******************
	echo[
	type _temp\temp.1
	echo[
	echo --------- ---Options --------------------
	echo 1. Save list and go back
	echo 2. Dissmis and go back
	echo[
	set /p "_opt3=Enter category remove or option: " || set "_opt3=2"
	
	findstr /i /r /v /c:"=.*!_opt3!" "_temp\temp.1" >_temp\temp.2
	
	del _temp\temp.1 & ren _temp\temp.2 temp.1
	
	if "!_opt3!"=="1" (
		del _temp\found.txt & ren _temp\temp.1 found.txt
		goto go_back
	)
	if "!_opt3!"=="2" goto go_back
	
	goto go_back2
	
)
REM //make batch scirpt
if "%_opt2%"=="7" call :make_batch & goto go_next

if "%_opt2%"=="9" goto go_next

echo INVALID OPTION
timeout 2 >nul
goto go_back


:go_next



del _temp\found.txt _temp\cat.txt _temp\catver.1
rd _temp
title FINISHED
pause&exit

REM // ------------ end of script --------------------


:do_folder

if not exist catver_ORGANIZER md catver_ORGANIZER
if exist NOTFOUND.txt del NOTFOUND.txt

for /f "tokens=1,2 delims==" %%g in (_temp\found.txt) do (
	%1 "%_folder%\%%g.zip" catver_ORGANIZER\ >nul 2>&1
	if "!errorlevel!"=="1" (echo %%g.zip) >>NOTFOUND.txt

)

cls
echo              **** ALL DONE ***
echo ------------------------------------------------------
echo * extracted files are in  the catver_ORGANIZER folder*
echo *                                                    *
echo *                                                    *
echo ------------------------------------------------------
echo[

exit /b

:make_batch
(echo @echo off
echo if "%%~1"=="" echo DRAG AND DROP FOLDER TO THIS SCRIPT ^&pause^&exit
echo if not exist "%%~1\" echo INVALID FOLDER ^&pause^&exit
echo if not exist _CATVER md _CATVER
echo title GAME ORGANIZER ^^^| Catver.ini ^^^| Build: %DATE%
echo echo This script will create the _CATVER folder, then
echo echo       MOVE/COPY the matching .zip files
echo echo ----------------------------------------------
echo echo.
echo echo Do you want to COPY or MOVE the files?
echo echo 1. MOVE
echo echo 2. COPY
echo set /p "_opt=Enter Option number: " ^|^| set _opt=1
echo if "%%_opt%%"=="1" ^(set _opt=MOVE^) else ^(set _opt=COPY^)) >catver_ORGANIZER.bat

for /f "tokens=1,2 delims==" %%g in (_temp\found.txt) do (
	(echo %%_opt%% "%%~1\%%g.zip" .\_CATVER ^|^| ^(echo %%g.zip^) ^>^>NOTFOUND.txt) >>catver_ORGANIZER.bat

)

(echo title FINISHED
echo pause^&exit)>>catver_ORGANIZER.bat

cls
echo              **** ALL DONE ***
echo ---------------------------------------------------
echo *   catver_ORGANIZER.bat was created, drag and drop *
echo *  the rom folder to that script                   *
echo *                                                  *
echo --------------------------------------------------
echo[

exit /b



:dups_remover

REM ****** line counter ************
set /a "_total_lines=0" & set /a "_count_lines=0"
for /f "delims=" %%g in (_temp\%1) do set /a "_total_lines+=1"

type nul >_temp\nodups.1 2>nul

for /f "delims=" %%g in (_temp\%1) do (
	set /a "_con=0"
	
	for /f "delims=" %%h in (_temp\nodups.1) do if "%%g"=="%%h" set /a "_con+=1"
	
	REM ****** line counter ************	
	set /a "_count_lines+=1"
	set /a "_percent=(!_count_lines!*100)/!_total_lines!
	title Building Menu: !_count_lines! / !_total_lines! ^( !_percent! %% ^)

	if "!_con!"=="0" (echo %%g) >>_temp\nodups.1

)

del _temp\%1 & ren _temp\nodups.1 %1

exit /b

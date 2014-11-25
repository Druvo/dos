::!/dos/rocks!
@echo off

:: c.bat

goto :init

:usage
    echo C/CD - useful directory changer and menu system.
    echo Created 1998-2014 by Kody Brown (@wasatchwizard)
    echo.
    echo USAGE:
    echo.
    echo   c [dirname]
    echo   c [shortcut]
    echo   c [shortcut] [dirname] [dirname...]
    echo.
    echo   c             Shows the current path (like the normal cd)
    echo   c --          Shows the menu
    echo.
    echo NOTES:
    echo.
    echo   You can use this batch file in place of the built-in DOS 'cd' command
    echo   by creating a DOSKEY macro.
    echo.
    echo   Normal `cd` operation:
    echo      ^> DOSKEY cd=%~nx0
    echo   Shows the menu when you type only `c`:
    echo      ^> DOSKEY c=%~nx0 --
    echo.
    echo   Run 'DOSKEY /?' for more details.

    :: Loop through this file and output all doc lines;
    :: lines that start with `::@help`
    rem echo.
    rem echo ALL SHORTCUTS:
    rem echo.

    rem for /f "usebackq tokens=*" %%g in ("%~f0") do @for /f "tokens=1,* delims= " %%h in ("%%g") do @if "%%h"=="::@help" @echo.  %%i

    rem exit /B 0
    goto :end

:init
    set "indent=  "
    set "pad=%indent%     "

    :: Keep track if there was a valid argument
    :: passed in or not.
    set "hasargs="

    :: Collect any options for the real CD command.
    set "options="

    if "%~1"=="?" goto :usage
    if "%~1"=="/?" goto :usage
    if "%~1"=="--help" goto :usage
    if "%~1"=="-help" goto :usage

    if "%~1"=="" goto :end

:p
    if "%~1"=="" goto :end
    if "%~1"=="--" goto :menu-main

    set "hasargs=1"

    set arg=%~1

   :skip_a
    if "%arg%"=="" goto :end

    set arg2=%arg:~0,2%
    set arg3=%arg:~0,3%

    if "%arg%"=="\" cd\ && shift && goto :p

    for /l %%i in (1,1,31) do if "!arg:~-1!"==" " set arg=!arg:~0,-1!

    if "%arg2%"=="~/" pushd "%UserProfile%\%arg:~2,1000%" && shift && goto :p
    if "%arg2%"=="//" pushd "%UserProfile%\%arg:~2,1000%" && shift && goto :p
    if "%arg3%"=="/~/" pushd "%UserProfile%\%arg:~3,1000%" && shift && goto :p

    if "%arg3%"=="/b/" pushd "%bin%\%arg:~3,1000%" && shift && goto :p
    if "%arg3%"=="/e/" pushd "%UserProfile%\Desktop\%arg:~3,1000%" && shift && goto :p
    if "%arg3%"=="/d/" pushd "%UserProfile%\Documents\%arg:~3,1000%" && shift && goto :p
    if "%arg3%"=="/w/" pushd "%UserProfile%\Downloads\%arg:~3,1000%" && shift && goto :p

    :: Trim any trailing \'s -- for the label check below..
    set b=%arg%
    for /l %%i in (1,1,31) do if "%b:~-1%"=="\" set b=%b:~0,-1%

    :: Check if the argument exists as a 'cd_%arg%' label in this file.
    findstr /R /I /B /C:"^:cd_%b%$" "%~f0" >NUL 2>&1
    if %errorlevel% equ 0 (
        call :cd_%b%
        if %errorlevel% EQU 0 shift && goto :p
    )

    :: Check if the argument exists from the current path/directory.
    if exist "%arg%" (
        if "%arg:~1,1%"==":" (
            cd /D "%arg%"
            if %errorlevel% EQU 0 shift && goto :p
        )
        cd "%arg%"
        if %errorlevel% EQU 0 shift && goto :p
    )

    :: Save as a normal CD option.
    if "%arg%"=="/D" echo ignoring /D && shift && goto :p
    if "%arg:~0,1%"=="/" echo saving option %arg% && set "options=%options% %arg%"

    shift
    goto :p

:end
    if defined hasargs (
        if defined options (
            rem echo 2 call cd %options%
            call cd %options%
        )
    ) else if not defined curmenu (
        echo %CD%
    )

    set "arg="
    set "b="
    set "indent="
    set "pad="
    set "options="
    set "curmenu="
    set "hasargs="
    set "menu="
    set "input="

    exit /B 0

:show-menu
    set curmenu=%~1

    if /i "%curmenu%"=="main" (
        echo %indent%==========================
        echo %indent%         cd menu
        echo %indent%--------------------------
        echo %indent% 1^)add  2^)edit  3^)refresh
        echo %indent%      ?^)help  q^)uit
        echo %indent%--------------------------
    ) else (
        echo %indent%==========================
        echo %indent%      :%curmenu% menu
        echo %indent%--------------------------
    )
    echo.

    :: Loop through this file and output all menu lines;
    :: lines that start with `::@menu-%curmenu%*`
    for /f "usebackq tokens=*" %%g in ("%~f0") do @for /f "tokens=1,2,* delims= " %%h in ("%%g") do (
        rem if "%%h"=="::@menu-%curmenu%" echo.%pad%%%i^) %%j
        if "%%~i"== "" (
            if "%%h"=="::@menu-%curmenu%" echo.%pad%   %%j
        ) else (
            if "%%h"=="::@menu-%curmenu%" echo.%pad%%%i^) %%j
        )
        if "%%h"=="::@menu-%curmenu%-h" echo.%pad:~1%%%i
        if "%%h"=="::@menu-%curmenu%-" echo.
    )

    rem if "%~1"=="" set "link=  "
    rem if not "%~1"=="" set "link=.)main"
    rem echo %indent%  %link%  ?)help  q)uit
    rem set "link="

    echo.
    if /i not "%curmenu%"=="main" (
        echo %indent%--------------------------
        echo %indent%  .^)main  ?^)help  q^)uit
    )
    echo %indent%==========================

    goto :handle_input main

:handle_input
    set menu=%~1
    set "input="

    where pcolor >NUL 2>&1
    if %errorlevel% EQU 0 (
        pcolor "%pad%> "
        set /p "input="
    ) else (
        <nul (set/p "input=.%pad:~1%> ")
    )

    if "%input%"=="" goto :end

    set "arg=%input%"
    goto :skip_a

:cdto
    shift
   :cdto_loop
    if "%~1"=="" if "%~2"== "" ( goto :cdto_end ) else ( shift && goto :cdto_loop )
    if exist "%~1" pushd "%~1" && goto :eof
    shift && goto :cdto_loop
   :cdto_end
    echo couldn't find: %~1 && goto :eof


:set_datevars
    rem sets global variables to the current date (mm, dd, yy) -- `yy` actually outputs `yyyy`
    for /f "tokens=1-3 delims=/.- " %%A in ("%date:* =%") do (
        set mm=%%A
        set dd=%%B
        set yy=%%C
        goto :eof
    )
    goto :eof

:clear_datevars
    set "mm="
    set "dd="
    set "yy="
    goto :eof

:set_timevars
    :: sets global variables to the current time (hh, nn, ss, ii)
    for /f "tokens=1-4 delims=:. " %%A in ("%time: =0%") do (
        set hh=%%A
        set nn=%%B
        set ss=%%C
        set ii=%%D
    )
    goto :eof

:clear_timevars
    set "hh="
    set "nn="
    set "ss="
    set "ii="
    goto :eof

:set_monthnamevars
    set month01=January
    set month02=February
    set month03=March
    set month04=April
    set month05=May
    set month06=June
    set month07=July
    set month08=August
    set month09=September
    set month10=October
    set month11=November
    set month12=December
    goto :eof
:clear_monthnamevars
    set "month01="
    set "month02="
    set "month03="
    set "month04="
    set "month05="
    set "month06="
    set "month07="
    set "month08="
    set "month09="
    set "month10="
    set "month11="
    set "month12="
    goto :eof


::
:: ## DEFAULT MENU ##
::

:menu-main
:cd_.
    call :show-menu main
    goto :eof


::
:: ## HANDLERS ##
::

:cd_1
    echo NotImplemented()
    goto :eof

:cd_2
    echo NotImplemented()
    goto :eof

:cd_3
    goto :menu-main

:cd_?
    goto :usage

:cd_q
    goto :end

::@help ?, /?, --help                cd %bin%\help or c:\bin\help or %UserProfile%\Root\help
:cd_?
:cd_/help
    call :cdto help "%bin%\help" "c:\bin\help" "%UserProfile%\Root\help"
    goto :eof

::@help /, \                         cd \
::@menu-more / root of cur drive
:cd_/
    cd\
    goto :eof

::
:: BIN
::

::@help b, /bin                      cd %bin% or c:\bin or %UserProfile%\Root
::@menu-main b bin
:cd_b
:cd_bin
:cd_/bin
    call :cdto bin "%bin%" "c:\bin" "%UserProfile%\Root"
    goto :eof

::@help a, /apps                     cd %bin%\apps or c:\bin\apps or %UserProfile%\Root\apps
::@menu-main a bin/apps
:cd_a
:cd_/apps
    call :cdto apps "%bin%\apps" "c:\bin\apps" "%UserProfile%\Root\apps"
    goto :eof

::@help r, /root                     cd %UserProfile%\Root or <bin>
::@menu-more r Root (or bin)
:cd_r
:cd_/root
    call :cdto root "%UserProfile%\Root" "%bin%"
    goto :eof

::
rem ::@menu-main-h
::@menu-main-h Profile
::

::@help ~, /profile, /home           cd %UserProfile%
::@menu-main ~ userprofile
:cd_~
:cd_~/
:cd_//
:cd_/profile
:cd_/home
    call :cdto home "%UserProfile%" "%bin%"
    goto :eof

::@help /appdata                     cd %UserProfile%\AppData
::@menu-more "" /appdata
:cd_/appdata
    call :cdto appdata "%UserProfile%\AppData"
    goto :eof

::@help /roaming                     cd %UserProfile%\AppData\Roaming
::@menu-more "" /roaming
:cd_/roaming
    call :cdto roaming "%UserProfile%\AppData\Roaming"
    goto :eof

::@help /local                       cd %UserProfile%\AppData\Local
::@menu-more "" /local
:cd_/local
    call :cdto local "%UserProfile%\AppData\Local"
    goto :eof

::
:: HOME FOLDERS
::

::@help e, /desktop                  cd %UserProfile%\Desktop
::@menu-main e desktop
:cd_e
:cd_/desktop
    call :cdto desktop "%UserProfile%\Desktop"
    goto :eof

::@help d, /docs, /documents         cd %UserProfile%\Documents
::@menu-main d documents
:cd_d
:cd_/docs
:cd_/documents
    call :cdto documents "%UserProfile%\Documents"
    goto :eof

::
:: FILES
::

::@help w, /downloads                cd c:\downloads or %UserProfile%\Downloads
::@menu-main w downloads
:cd_w
:cd_/downloads
    call :cdto downloads "%downloads%" "c:\downloads" "%UserProfile%\Downloads"
    goto :eof

::@help i, /installers               cd c:\installers or %UserProfile%\Installers
::@menu-main i installers
:cd_i
:cd_/installers
    call :cdto installers "%installers%" "c:\installers" "%UserProfile%\Installers"
    goto :eof

::
rem ::@menu-main-
::@menu-main-h Projects
::

::@help t, pt, /tools                cd c:\tools or %UserProfile%\Tools
::@menu-main pt tools
:cd_t
:cd_pt
:cd_/tools
    call :cdto tools "%tools%" "c:\tools" "%UserProfile%\Tools"
    goto :eof

::@help pp, /projects, /dev,         cd c:\dev or %UserProfile%\Documents\Development
::@menu-main pp projects
:cd_pp
:cd_/projects
:cd_/dev
    call :cdto development "%dev%" "c:\dev" "%UserProfile%\Documents\Development"
    goto :eof

::@help pc, /contrib                 cd c:\dev or %UserProfile%\Documents\Development
::@menu-main pc contrib
:cd_pc
:cd_/contrib
    call :cdto contrib "%dev%\Contrib" "c:\dev\Contrib" "%UserProfile%\Documents\Development\Contrib"
    goto :eof

::
rem ::@menu-main-
::@menu-main-h Journal
::

::@help jj, journal                  cd %UserProfile%\Documents\Journal
::@menu-main jj journal
:cd_jj
:cd_journal
    call :cdto journal "%UserProfile%\Documents\Journal"
    goto :eof

::@help jc, curmo                    cd %UserProfile%\Documents\Journal\(Dates)\YEAR\MM - Month
::@menu-main jc current month
:cd_jc
:cd_cm
:cd_curmo
:cd_currentmonth
    call :set_datevars
    call :set_timevars
    call :set_monthnamevars

    :: Yes, that month at the end is correct.. it is acting like an array..
    echo "%UserProfile%\Documents\Journal\(Dates)\%yy%\%mm% - %month%mm%%"
    call :cdto curmo "%UserProfile%\Documents\Journal\(Dates)\%yy%\%mm% - %month%mm%%"

    rem call :clear_datevars
    rem call :clear_timevars
    rem call :clear_monthnamevars
    goto :eof

::@help jl, lastmo                   cd %UserProfile%\Documents\Journal\(Dates)\YEAR\MM - Month
::@menu-main jl last month
:cd_jl
:cd_lm
:cd_lastmo
:cd_lastmonth
    call :set_datevars
    call :set_timevars
    call :set_monthnamevars

    :: Yes, that month at the end is correct.. it is acting like an array..
    echo "%UserProfile%\Documents\Journal\(Dates)\%yy%\%mm% - %month%mm%%"
    call :cdto curmo "%UserProfile%\Documents\Journal\(Dates)\%yy%"

    rem call :clear_datevars
    rem call :clear_timevars
    rem call :clear_monthnamevars
    goto :eof

::@help jn, nextmo                   cd %UserProfile%\Documents\Journal\(Dates)\YEAR\MM - Month
::@menu-main jn next month
:cd_jn
:cd_cn
:cd_nextmo
:cd_nextmonth
    call :set_datevars
    call :set_timevars
    call :set_monthnamevars

    :: Yes, that month at the end is correct.. it is acting like an array..
    echo "%UserProfile%\Documents\Journal\(Dates)\%yy%\%mm% - %month%mm%%"
    call :cdto curmo "%UserProfile%\Documents\Journal\(Dates)\%yy%"

    rem call :clear_datevars
    rem call :clear_timevars
    rem call :clear_monthnamevars
    goto :eof

::@help js, serials                  cd %UserProfile%\Documents\Journal\Serial numbers
::@menu-main js serial numbers
:cd_js
:cd_serials
    call :cdto journal "%UserProfile%\Documents\Journal\Serial numbers"
    goto :eof

::
rem ::@menu-main-
::@menu-main-h Contracts
::

::@help cl, lds, /lds                cd %ldschurch% or c:\ldschurch or %UserProfile%\Documents\Development\Contracts\LDSChurch
::@menu-main cl ldschurch
:cd_cl
:cd_lds
:cd_/lds
:cd_ldschurch
:cd_/ldschurch
    call :cdto ldschurch "%ldschurch%" c:\ldschurch "%UserProfile%\Documents\Development\Contracts\LDSChurch"
    goto :eof

::@help co, obeo. /obeo              cd %%obeo%% or c:\obeo or %%UserProfile%%\Documents\Development\Contracts\Obeo
::@menu-main co obeo
:cd_co
:cd_obeo
:cd_/obeo
    call :cdto obeo "%obeo%" c:\obeo "%UserProfile%\Documents\Development\Contracts\Obeo"
    goto :eof


:: Util folders

rem C:\Users\Kody\AppData\Local\scoop\shims
rem C:\Windows\System32\drivers\etc
rem C:\bin\apps\Sublime Text\Data\Packages


::@menu-main-
::@menu-main m more
:cd_m
    call :show-menu more
    goto :eof


@echo off

REM run build of the dotnet core 5 assembly packages for build R# package

REM get current work directory
SET base=%~d0
SET msbuild_logger=%CD%\logs
SET jump=pipeline

mkdir %msbuild_logger%

echo "root directory is %base%"

REM mzkit source dir
SET mzkit_src=%base%\mzkit\Rscript\Library
REM gcmodeller source dir
SET gcmodeller_src=%base%\GCModeller\src

@echo:

echo "libraries folder:"
echo "1. mzkit: %mzkit_src%"
echo "2. gcmodeller: %gcmodeller_src%"

@echo:
echo -------------------------------------------------
@echo:

REM if the argument is exists in the commandline
REM then just run build of the R# packages
REM skip build of the .NET 5 assembly files.
if "%1"=="--Rpackage" (
	goto :jump_to_build_Rpackages
)

goto :%jump%

REM ----===== msbuild function =====----
:exec_msbuild
SETLOCAL

REM the function accept two required parameters
REM 
REM 1. the relative path of the package source folder
REM 2. the filename of the target VisualStudio solution file to run msbuild
SET _src=%1
SET _sln=%2
SET logfile="%msbuild_logger%\%_sln%.txt"

echo "build %_sln% package"
echo "  --> %_src%"
echo "  --> vs_sln: %_src%\%_sln%"

REM clean works and rebuild libraries
cd %_src%

echo "VisualStudio work folder: %CD%"

dotnet msbuild %_src%\%_sln% -target:Clean
dotnet msbuild %_src%\%_sln% -t:Rebuild /p:Configuration="Rsharp_app_release" /p:Platform="x64" -detailedSummary:True -verbosity:minimal > %logfile% & type %logfile%

@echo:
echo "build package %_sln% job done!"
@echo:
@echo:
@echo:
echo --------------------------------------------------------
@echo:
@echo:

ENDLOCAL & SET _result=0
goto :%jump%

REM ----===== end of function =====----

:pipeline

REM mzkit libraries for MS data analysis

SET jump=end_ms_imaging
CALL :exec_msbuild %mzkit_src%\MSI_app MSImaging.sln
:end_ms_imaging

REM build of the mzkit library
SET jump=mzkit
CALL :exec_msbuild %mzkit_src% mzkit.NET5.sln
:mzkit

REM build of the GCModeller library
SET base=%gcmodeller_src%

SET jump=renv
CALL :exec_msbuild %gcmodeller_src%\R-sharp R_system.NET5.sln
:renv

SET jump=gcmodeller
CALL :exec_msbuild %gcmodeller_src%\workbench\R# packages.NET5.sln
:gcmodeller

SET jump=ggplot
CALL :exec_msbuild %gcmodeller_src%\runtime\ggplot ggplot.NET5.sln
:ggplot

REM pause

@echo:
echo "run msbuild for publish R# package done!"
@echo:

goto :build_Rpackages

:jump_to_build_Rpackages

REM set up environment variables
SET base=%gcmodeller_src%

echo "Just build R# packages!"
cd %base%

:build_Rpackages

echo "run build of R packages"

SET R_HOME=%base%\R-sharp\App\net5.0
SET Rscript=%R_HOME%\Rscript.exe
SET REnv=%R_HOME%\R#.exe
SET pkg_release=%~d0\etc\packages
SET mzkit_app="%mzkit_src%\mzkit_app\mzkit.Rproj"
SET gcmodeller=%base%
SET jump=r_build_and_install_packages

goto :%jump%

REM ----===== Rscript build function =====----
:exec_rscript_build
SETLOCAL
SET _src=%1
SET _pkg=%2

echo "build '%_pkg%' package..."
echo "  --> source:  %_src%"
echo "  --> package_release: %pkg_release%\%_pkg%"

%Rscript% --build /src "%_src%" /save "%pkg_release%\%_pkg%" --skip-src-build
%REnv% --install.packages "%pkg_release%\%_pkg%"

@echo:
@echo:
echo "build package %_pkg% job done!"
@echo:
@echo:
@echo:

ENDLOCAL & SET _result=0
goto :%jump%

REM ----===== end of function =====----


:r_build_and_install_packages


SET jump=pkg_ms_imaging
CALL :exec_rscript_build "%mzkit_src%\MSI_app\MSImaging.Rproj" MSImaging.zip
:pkg_ms_imaging

SET jump=pkg_mzkit
CALL :exec_rscript_build %mzkit_app% mzkit.zip
:pkg_mzkit

SET jump=pkg_gcmodeller
CALL :exec_rscript_build "%gcmodeller%\workbench\pkg\GCModeller.Rproj" GCModeller.zip
:pkg_gcmodeller

SET jump=pkg_ggplot
CALL :exec_rscript_build "%gcmodeller%\runtime\ggplot\ggplot.Rproj" ggplot.zip
:pkg_ggplot

echo "build packages job done!"

pause
exit 0
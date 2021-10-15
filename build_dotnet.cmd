@echo off

REM run build of the dotnet core 5 assembly packages for build R# package

REM get current work directory
SET base=%CD%
SET msbuild_logger=%base%/logs/
SET jump=pipeline
echo "root directory is %base%"

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
SET logfile="%msbuild_logger%/%_sln%.txt"

echo "build %_sln% package"

REM clean works and rebuild libraries
cd %base%
cd %_src%
dotnet msbuild ./%_sln% -target:Clean
dotnet msbuild ./%_sln% -t:Rebuild /p:Configuration="Rsharp_app_release" /p:Platform="x64" -detailedSummary:True -verbosity:minimal > %logfile% & type %logfile%
cd %base%

echo ""
echo ""
echo "build package %_sln% job done!"

ENDLOCAL & SET _result=0
goto :%jump%

REM ----===== end of function =====----

:pipeline

SET jump=polyfill
CALL :exec_msbuild "../Polyfill/" "./Polyfill.sln"
:polyfill

SET jump=end_msi_analysis
CALL :exec_msbuild "../MSI_analysis/" "./MSI_analysis.sln"
:end_msi_analysis

SET jump=end_ms_imaging
CALL :exec_msbuild "../ms-imaging/" "./MSImaging.sln"
:end_ms_imaging

REM build of the mzkit library
SET base=D:/

SET jump=mzkit
CALL :exec_msbuild "./mzkit/Rscript/Library" "./mzkit.NET5.sln"
:mzkit

REM build of the GCModeller library
SET base=%base%/GCModeller/src/

SET jump=renv
CALL :exec_msbuild "R-sharp" "./R_system.NET5.sln"
:renv

SET jump=gcmodeller
CALL :exec_msbuild "workbench/R#" "./packages.NET5.sln"
:gcmodeller

SET jump=ggplot
CALL :exec_msbuild "runtime/ggplot" "./ggplot.NET5.sln"
:ggplot

echo ""
echo "run msbuild for publish R# package done!"

goto :build_Rpackages

:jump_to_build_Rpackages

REM set up environment variables
SET base=D:/GCModeller/src/

echo "Just build R# packages!"
cd %base%

:build_Rpackages

echo "run build of R packages"

SET R_HOME=%base%/R-sharp/App/net5.0
SET Rscript=%R_HOME%/Rscript.exe
SET REnv=%R_HOME%/R#.exe
SET pkg_release=C:\Users\lipidsearch\Documents\MSI\packages
SET biodeep=D:\biodeep\biodeepdb_v3\spatial
SET mzkit_app="D:\mzkit\Rscript\Library\mzkit_app\mzkit.Rproj"
SET gcmodeller=%base%
SET jump=r_build_and_install_packages

echo "update config.json template file for MSI_analysis command!"

SET pipeline_dir=%biodeep%/MSI_analysis/Pipeline

REM update config json template file
%REnv% /config.json /script "%pipeline_dir%/MSI_analysis.R" /save "%pipeline_dir%/config.json" 
REM update analysis workflow commandline help man page
%REnv% --man /Rscript "%pipeline_dir%/MSI_analysis.R" /save "%pipeline_dir%/MSI_analysis.help.txt"

goto :%jump%

REM ----===== Rscript build function =====----
:exec_rscript_build
SETLOCAL
SET _src=%1
SET _pkg=%2

echo "build '%_pkg%' package..."
echo "  --> source:  %_src%"
echo "  --> package_release: %pkg_release%/%_pkg%"

%Rscript% --build /src "%_src%" /save "%pkg_release%/%_pkg%"
%REnv% --install.packages "%pkg_release%/%_pkg%"

echo ""
echo ""
echo "build package %_pkg% job done!"

ENDLOCAL & SET _result=0
goto :%jump%

REM ----===== end of function =====----


:r_build_and_install_packages

SET jump=pkg_msi_analysis
CALL :exec_rscript_build "%biodeep%/MSI_analysis/MSI.Rproj" MSI.zip
:pkg_msi_analysis

SET jump=pkg_ms_imaging
CALL :exec_rscript_build "%biodeep%/ms-imaging/MSImaging.Rproj" MSImaging.zip
:pkg_ms_imaging

SET jump=pkg_polyfill
CALL :exec_rscript_build "%biodeep%/Polyfill/Polyfill.Rproj" Polyfill.zip
:pkg_polyfill

SET jump=pkg_mzkit
CALL :exec_rscript_build %mzkit_app% mzkit.zip
:pkg_mzkit

SET jump=pkg_gcmodeller
CALL :exec_rscript_build "%gcmodeller%/workbench/pkg/GCModeller.Rproj" GCModeller.zip
:pkg_gcmodeller

SET jump=pkg_ggplot
CALL :exec_rscript_build "%gcmodeller%/runtime/ggplot/ggplot.Rproj" ggplot.zip
:pkg_ggplot

echo "build packages job done!"

pause
exit 0
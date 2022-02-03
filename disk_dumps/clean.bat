
REM This is to clean temporal outputs of previous executions in Windows.
@ECHO OFF
forfiles /p .\dsp_output\monopolar\ /c "cmd /c @isdir equ FALSE if not @ext==\"keep\"  del /q @file"
forfiles /p .\dsp_output\bipolar\ /c "cmd /c @isdir equ FALSE if not @ext==\"keep\"  del /q @file"

forfiles /p .\ez_pac_output\ /c "cmd /c @isdir equ FALSE if not @ext==\"keep\"  del /q @file"
forfiles /p .\ez_top\input\ /c "cmd /c @isdir equ FALSE if not @ext==\"keep\"  del /q @file"
forfiles /p .\ez_top\output\ /c "cmd /c @isdir equ FALSE if not @ext==\"keep\"  del /q @file"

forfiles /p .\nbm1\ /c "cmd /c @isdir equ FALSE if not @ext==\"keep\"  del /q @file"
forfiles /p .\nbm2\ /c "cmd /c @isdir equ FALSE if not @ext==\"keep\"  del /q @file"
forfiles /p .\research_matfiles\ /c "cmd /c @isdir equ FALSE if not @ext==\"keep\"  del /q @file"

forfiles /p .\trc\temp\monopolar\ /c "cmd /c @isdir equ FALSE if not @ext==\"keep\"  del /q @file"
forfiles /p .\trc\temp\bipolar\ /c "cmd /c @isdir equ FALSE if not @ext==\"keep\"  del /q @file"
forfiles /p .\trc\output\ /c "cmd /c @isdir equ FALSE if not @ext==\"keep\"  del /q @file"

forfiles /p .\temp_pythonToMatlab_dsp\ /c "cmd /c @isdir equ FALSE if not @ext==\"keep\"  del /q @file"

forfiles /c "cmd /c @isdir equ FALSE if not @ext==\"sh\" if not @ext==\"bat\"  del /q @file"


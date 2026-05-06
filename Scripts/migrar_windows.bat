@echo off
title Windows Migration Tool - Centurião Edition
setlocal enabledelayedexpansion

:: Verificar se é administrador
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo [ERRO] Execute este script como administrador (clique direito -> "Executar como administrador").
    pause
    exit /b 1
)

:: =============================================
:: 1. Coletar o nome do usuário
:: =============================================
echo ==============================================
echo  Windows Migration Tool - Centurião Edition
echo ==============================================
echo.
set /p "USUARIO=Digite o nome do seu usuario principal (ex: svlocal): "
if "%USUARIO%"=="" (
    echo [ERRO] Nenhum usuario informado. Saindo...
    pause
    exit /b 1
)

:: =============================================
:: 2. Verificar se a pasta do usuário existe
:: =============================================
if not exist "C:\Users\%USUARIO%" (
    echo [ERRO] O usuario "%USUARIO%" nao existe em C:\Users.
    pause
    exit /b 1
)

:: =============================================
:: 3. Confirmar ação
:: =============================================
echo.
echo [ATENCAO] Este script movera os dados do usuario "%USUARIO%" para G:\Usuarios\%USUARIO%.
echo Tambem movera Program Files, Program Files (x86) e ProgramData para G:
echo.
set /p "CONFIRMAR=Digite SIM para continuar: "
if /i not "%CONFIRMAR%"=="SIM" (
    echo Abortado.
    pause
    exit /b 1
)

:: =============================================
:: 4. Criar diretórios de destino
:: =============================================
echo.
echo [1/6] Criando diretorios de destino em G:...
if not exist "G:\Usuarios" mkdir "G:\Usuarios"
if not exist "G:\Programas" mkdir "G:\Programas"
if not exist "G:\ProgramData" mkdir "G:\ProgramData"
echo OK.

:: =============================================
:: 5. Mover Users
:: =============================================
echo.
echo [2/6] Movendo C:\Users\%USUARIO% para G:\Usuarios\%USUARIO%...
robocopy "C:\Users\%USUARIO%" "G:\Usuarios\%USUARIO%" /mir /copyall /r:0 /w:0 >nul
if %errorLevel% geq 8 (
    echo [ERRO] Falha na copia do usuario %USUARIO%. Verifique permissoes ou arquivos abertos.
    pause
    exit /b 1
)
rmdir /s /q "C:\Users\%USUARIO%"
mklink /J "C:\Users\%USUARIO%" "G:\Usuarios\%USUARIO%" >nul
echo OK.

:: =============================================
:: 6. Mover Program Files (64-bit)
:: =============================================
echo.
echo [3/6] Movendo C:\Program Files...
robocopy "C:\Program Files" "G:\Programas\Program Files" /mir /copyall /r:0 /w:0 >nul
if %errorLevel% geq 8 (
    echo [ERRO] Falha na copia do Program Files.
    pause
    exit /b 1
)
rmdir /s /q "C:\Program Files"
mklink /J "C:\Program Files" "G:\Programas\Program Files" >nul
echo OK.

:: =============================================
:: 7. Mover Program Files (x86)
:: =============================================
echo.
echo [4/6] Movendo C:\Program Files (x86)...
robocopy "C:\Program Files (x86)" "G:\Programas\Program Files (x86)" /mir /copyall /r:0 /w:0 >nul
if %errorLevel% geq 8 (
    echo [ERRO] Falha na copia do Program Files (x86).
    pause
    exit /b 1
)
rmdir /s /q "C:\Program Files (x86)"
mklink /J "C:\Program Files (x86)" "G:\Programas\Program Files (x86)" >nul
echo OK.

:: =============================================
:: 8. Mover ProgramData
:: =============================================
echo.
echo [5/6] Movendo C:\ProgramData...
robocopy "C:\ProgramData" "G:\ProgramData" /mir /copyall /r:0 /w:0 >nul
if %errorLevel% geq 8 (
    echo [ERRO] Falha na copia do ProgramData.
    pause
    exit /b 1
)
rmdir /s /q "C:\ProgramData"
mklink /J "C:\ProgramData" "G:\ProgramData" >nul
echo OK.

:: =============================================
:: 9. Desligar hibernação (opcional, mas recomendado)
:: =============================================
echo.
echo [6/6] Desligando hibernacao...
powercfg -h off >nul
echo OK.

:: =============================================
:: 10. Instruções finais
:: =============================================
echo.
echo ==============================================
echo  MIGRACAO CONCLUIDA!
echo ==============================================
echo.
echo ATENCAO: Voce ainda precisa:
echo 1) Mover o pagefile.sys para G: (propriedades do sistema - memoria virtual).
echo 2) Reiniciar o computador para aplicar todas as alteracoes.
echo.
echo Aguarde o reboot...
shutdown /r /t 10 /c "Reiniciando para aplicar migracao do sistema. Salve seu trabalho."
pause
exit /b 0

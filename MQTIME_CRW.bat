@ECHO OFF
setlocal

call :Hora
echo Inicio: %hora%:%minutos%:%segundos%:%centesimas%

set ip=10.136.3.36(1480)
set gestor=CRI400W

echo ------------------------------ %date% %time% ----------------------------------------------- >> D:\Monitoreo_BEL\CRI400W\%gestor%_tiemposMQ.log
echo ------------------------------ %date% %time% ----------------------------------------------- >> D:\Monitoreo_BEL\CRI400W\%gestor%_tivoli.log

for /F "tokens=1,2" %%a in (D:\Monitoreo_BEL\CRI400W\mq_time_config.txt) do (
set gestor_destino=%%a
set ip_destino=%%b
echo --------------- >> D:\Monitoreo_BEL\CRI400W\%gestor%_tiemposMQ.log
echo %gestor% to %%a >> D:\Monitoreo_BEL\CRI400W\%gestor%_tiemposMQ.log
echo %gestor% to %%a 
call :PutMessage
call :GetMessage
call :NetTime
call :ClearMessage
call :ClearFiles
)
call :TIVOLI
call :Hora
echo Final: %hora%:%minutos%:%segundos%:%centesimas%

exit /B %errorlevel%


:PutMessage
call :Hora
echo Hora Put: %hora%:%minutos%:%segundos%:%centesimas% >> D:\Monitoreo_BEL\CRI400W\%gestor%_tiemposMQ.log
set seg_put=%segundos%
set cen_put=%centesimas%
SET MQSERVER=ADM.SVRCONN/TCP/%ip%
AMQSPUTC TEST.%gestor%.%gestor_destino% %gestor% < D:\Monitoreo_BEL\CRI400W\message_echo.txt > D:\Monitoreo_BEL\CRI400W\null.txt
exit /B 0

:GetMessage
set /a countfiles=1
:loop
AMQSBCGC RESP.%gestor%.%gestor_destino% %gestor% > D:\Monitoreo_BEL\CRI400W\%gestor_destino%_response.txt
set file=D:\Monitoreo_BEL\CRI400W\%gestor_destino%_response.txt
set /a cnt=0
for /f %%a in ('type "%file%"^|find "" /v /c') do set /a cnt=%%a
call :Hora
set seg_get=%segundos%
set cen_get=%centesimas%
if %cnt% == 11 (set /a countfiles+=1)
if %cnt% GTR 11 (echo Hora Get: %hora%:%minutos%:%segundos%:%centesimas% >> D:\Monitoreo_BEL\CRI400W\%gestor%_tiemposMQ.log)
if %cnt% GTR 11 (set /a countfiles+=1000)
if %countfiles% == 21 (echo Hora get: TIMEOUT >> D:\Monitoreo_BEL\CRI400W\%gestor%_tiemposMQ.log)
if %countfiles% LEQ 20 goto loop

set /a dif_seg=0
set /a op1=%seg_get%-%seg_put%
if %op1% == 0 (set /a dif_cent=%cen_get%-%cen_put%) else (call :calculo)

echo Tiempo Transaccion: %dif_seg%.%dif_cent% >> D:\Monitoreo_BEL\CRI400W\%gestor%_tiemposMQ.log
set %gestor_destino%_time=%dif_seg%.%dif_cent%
echo %gestor% to %gestor_destino% %dif_seg%.%dif_cent% >> D:\Monitoreo_BEL\CRI400W\%gestor%_tivoli.log

exit /B 0

:NETTIME
SET MQSERVER=ADM.SVRCONN/TCP/%ip%
echo DIS CHSTATUS(TO.%gestor_destino%) NETTIME XQTIME XBATCHSZ SUBSTATE | RUNMQSC -w 5 -c -m %gestor% > D:\Monitoreo_BEL\CRI400W\nt.data
(SET file-list=)
FOR /f "skip=6 delims=" %%x IN (D:\Monitoreo_BEL\CRI400W\nt.data) DO (
CALL SET file-list=%%file-list%%, %%x
)
echo file-list=%file-list% > D:\Monitoreo_BEL\CRI400W\nt2.data
for /F "tokens=6,9,10,12" %%a in (D:\Monitoreo_BEL\CRI400W\nt2.data) do (
echo TO.%gestor_destino%: %%a  %%d >> D:\Monitoreo_BEL\CRI400W\%gestor%_tiemposMQ.log
)

SET MQSERVER=ADM.SVRCONN/TCP/%ip_destino%
echo DIS CHSTATUS(TO.%gestor%) NETTIME XQTIME XBATCHSZ SUBSTATE | RUNMQSC -w 5 -c -m %gestor_destino% > D:\Monitoreo_BEL\CRI400W\nt.data
(SET file-list=)
FOR /f "skip=6 delims=" %%x IN (D:\Monitoreo_BEL\CRI400W\nt.data) DO (
CALL SET file-list=%%file-list%%, %%x
)
echo file-list=%file-list% > D:\Monitoreo_BEL\CRI400W\nt2.data
for /F "tokens=6,9,10,12" %%a in (D:\Monitoreo_BEL\CRI400W\nt2.data) do (
echo TO.%gestor%: %%a - %%d >> D:\Monitoreo_BEL\CRI400W\%gestor%_tiemposMQ.log
)
exit /B 0

:ClearMessage
SET MQSERVER=ADM.SVRCONN/TCP/%ip%
rem AMQSGETC RESP.%gestor%.%gestor_destino% %gestor% > null.txt
dmpmqmsg -m %gestor% -I RESP.%gestor%.%gestor_destino% > D:\Monitoreo_BEL\CRI400W\null.txt
exit /B 0

:ClearFiles
del D:\Monitoreo_BEL\CRI400W\%gestor_destino%_response.txt
del D:\Monitoreo_BEL\CRI400W\nt.data
del D:\Monitoreo_BEL\CRI400W\nt2.data
DEL D:\Monitoreo_BEL\CRI400W\null.txt
exit /B 0

:Hora
chcp 1252 > NUL
set HORA_ACTUAL=%TIME%
set HORA=%HORA_ACTUAL:~0,2%
set MINUTOS=%HORA_ACTUAL:~3,2%
set SEGUNDOS=%HORA_ACTUAL:~6,2%
set CENTESIMAS=%HORA_ACTUAL:~9,2%
exit /B 0

:Calculo
set /a op2=0
set /a op3=0
set /a op2=100-%cen_put%
set /a op3=%seg_put%+1
set /a dif_seg=%seg_get%-%op3%
set /a dif_cent=%op2%+%cen_get%
exit /B 0

:TIVOLI
echo %date%,%time%,%BAC400A_time%,%CRI400B_time%,%CRI400C_time%,%GUA400A_time%,%GUA400B_time%,%HON400A_time%,%HON400B_time%,%SAL400B_time%,%SAL400D_time%,%NIC400B_time%,%NIC400C_time% >> D:\Monitoreo_BEL\CRI400W\%gestor%_tivoli.csv
exit /B 0
































e
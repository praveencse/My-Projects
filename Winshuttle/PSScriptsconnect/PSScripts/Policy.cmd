@Echo Off


Set LOCATION=%1
Set QUEUENAME=%2

echo %LOCATION%
echo %QUEUENAME%

CD /d %LOCATION%

rabbitmqctl set_policy %QUEUENAME% "^%QUEUENAME%" "{"""ha-mode""":"""all""","""ha-sync-mode""":"""automatic"""}"  --apply-to queues
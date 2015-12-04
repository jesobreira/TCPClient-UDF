#include "TCPClient.au3"

#cs
	To test this example,
	execute two netcat servers
	on two different CMD windows,
	running this commands:
	nc -vv -l -p 31337
	nc -vv -l -p 31339
#ce

_TCPClient_OnReceive("receive")
_TCPClient_OnDisconnect("disconnect")

_TCPClient_DebugMode()

Func receive($iSocket, $sIP, $sData, $mPar)
	MsgBox(0, "", $sIP & " sent " & $sData)
	_TCPClient_Send($iSocket, "ok bruda")
	_TCPClient_Broadcast("lol")

	_TCPClient_Send($iSocket, "old param: " & $mPar)
	_TCPClient_SetParam($iSocket, $sData)

	_TCPClient_Disconnect($iSocket)
EndFunc

Func disconnect($iSocket, $sIP)
	MsgBox(0, $iSocket, $sIP)
EndFunc

$conn = _TCPClient_Connect('127.0.0.1', '31337')
$conn = _TCPClient_Connect('127.0.0.1', '31339')
If @error Then
	MsgBox(0, "", "could not connect. Error: " & @error)
	Exit
EndIf
While True
	Sleep(100)
WEnd
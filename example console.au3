#include "TCPClient.au3"

#cs
	To test this example,
	execute a netcat server,
	running this commands:
	nc -vv -l -p 31337
#ce

Global $Password = "123456"

_TCPClient_OnReceive("receive")
_TCPClient_OnDisconnect("disconnect")

_TCPClient_DebugMode()

Func receive($iSocket, $sIP, $sData, $mPar)
	If $mPar = "login" Then
		If $sData = $Password Then
			; right password, let's change the parameter
			_TCPClient_SetParam($iSocket, "logged")

			; and now bind
			_TCPClient_BindAppToSocket($iSocket, "cmd.exe")

		Else
			_TCPClient_Send($iSocket, "Wrong password. Try again: ")
		EndIf
	Else
		If $sData = "exit" Then
			; unbinds
			_TCPClient_UnBindAppToSocket($iSocket)

			; says bye
			_TCPClient_Send($iSocket, "See you")

			; closes connection
			_TCPClient_Disconnect($iSocket)
		Else
			; sends command directly to the process
			_TCPClient_SendToBound($iSocket, $sData)
		EndIf
	EndIf
EndFunc

Func disconnect($iSocket, $sIP)
	MsgBox(0, $iSocket, $sIP)
EndFunc

$iSocket = _TCPClient_Connect('127.0.0.1', '31337')

If @error Then
	MsgBox(0, "", "could not connect. Error: " & @error)
	Exit
EndIf

; Sets parameter to login, so we know what the server is doing
_TCPClient_SetParam($iSocket, "login")

_TCPClient_Send($iSocket, "Please enter password: ")

While True
	Sleep(100)
WEnd
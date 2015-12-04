#include "TCPClient.au3"

_TCPClient_OnReceive("received")
_TCPClient_OnDisconnect("disconnect")

_TCPClient_DebugMode()

$iSocket = _TCPClient_Connect("127.0.0.1", "8081")
If @error Then
   MsgBox(0, "", "Could not connect!")
   Exit
EndIf

_TCPClient_Send($iSocket, "Hello, how are you? ")

Func received($iSocket, $sIP, $sData, $sPar)
   _TCPClient_Send($iSocket, "Ok, I understood.")
EndFunc

Func disconnect($iSocket, $sIP)
   MsgBox(0, "", "I miss it.")
   Exit
EndFunc

While 1
   Sleep(100)
WEnd
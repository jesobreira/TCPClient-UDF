#include-once

#cs
	TCPClient UDF
	Written by Jefrey <jefrey[at]jefrey.ml>

	Fork me on Github:
	http://github.com/jesobreira/tcpclient-udf
#ce

TCPStartup()
OnAutoItExitRegister("__TCPClient_OnExit")
AdlibRegister("__TCPClient_Sendstd")
AdlibRegister("__TCPClient_Recv")
Global $_TCPClient_OnDisconnectCallback, $_TCPClient_OnReceiveCallback
Global $_TCPClient_DebugMode = False
Global $_TCPClient_AutoTrim = True
Global $__TCPClient_Sockets[1], $__TCPClient_SocketCache[1]
Global $__TCPClient_Consoles[1], $__TCPClient_Pars[1]

Func _TCPClient_OnReceive($sCallback)
	$_TCPClient_OnReceiveCallback = $sCallback
EndFunc   ;==>_TCPClient_OnReceive

Func _TCPClient_OnDisconnect($sCallback)
	$_TCPClient_OnDisconnectCallback = $sCallback
EndFunc   ;==>_TCPClient_OnDisconnect

Func _TCPClient_DebugMode($bMode = Default)
	If $bMode = Default Then
		$_TCPClient_DebugMode = Not $_TCPClient_DebugMode
	Else
		$_TCPClient_DebugMode = $bMode
	EndIf
EndFunc   ;==>_TCPClient_DebugMode

Func _TCPClient_AutoTrim($bMode = Default)
	If $bMode = Default Then
		$_TCPClient_AutoTrim = Not $_TCPClient_AutoTrim
	Else
		$_TCPClient_AutoTrim = $bMode
	EndIf
EndFunc   ;==>_TCPClient_AutoTrim

Func _TCPClient_Connect($sSvr, $iPort)
	$sSvr = TCPNameToIP($sSvr) ; if it was provided a domain/svr name, convert to IP
	$conn = TCPConnect($sSvr, $iPort)
	If $conn = -1 Or $conn = 0 Then
		Return SetError(@error, 0, $conn)
	Else
		$ubound = UBound($__TCPClient_Sockets)
		ReDim $__TCPClient_Sockets[$ubound + 1]
		ReDim $__TCPClient_SocketCache[$ubound + 1][2]
		ReDim $__TCPClient_Pars[$ubound + 1]
		ReDim $__TCPClient_Consoles[$ubound + 1]
		$__TCPClient_Sockets[$ubound] = $conn
		$__TCPClient_Sockets[0] = $ubound
		$i = $__TCPClient_Sockets[0]
		$__TCPClient_SocketCache[$i][0] = $conn
		$__TCPClient_Consoles[$i] = 0
		$__TCPClient_SocketCache[$i][1] = _TCPClient_SocketToIP($conn)
		If $_TCPClient_DebugMode Then __TCPClient_Log("Connected to " & $sSvr & ":" & $iPort)
		Return $conn
	EndIf
EndFunc   ;==>_TCPClient_Connect

Func _TCPClient_Disconnect($iSocket)
	$conn = _TCPClient_SocketToConnID($iSocket)
	__TCPClient_KillConnection($conn)
EndFunc   ;==>_TCPClient_Disconnect

Func _TCPClient_SocketToConnID($iSocket)
	For $i = 1 To $__TCPClient_Sockets[0]
		If $__TCPClient_Sockets[$i] = $iSocket Then
			Return $i
		EndIf
	Next
	Return False
EndFunc   ;==>_TCPClient_SocketToConnID

Func _TCPClient_ConnIDToSocket($iConn)
	Return $__TCPClient_Sockets[$iConn]
EndFunc   ;==>_TCPClient_ConnIDToSocket

Func _TCPClient_SetParam($iSocket, $sPar)
	$iConn = _TCPClient_SocketToConnID($iSocket)
	$__TCPClient_Pars[$iConn] = $sPar
EndFunc   ;==>_TCPClient_SetParam

Func _TCPClient_Send($iSocket, $sData)
	If $_TCPClient_DebugMode Then __TCPClient_Log("Sent " & $sData & " to socket " & $iSocket & "(" & _TCPClient_SocketToIP($iSocket) & ")")
	Local $ret = TCPSend($iSocket, $sData)
	If @error Then
		__TCPClient_KillConnection($iSocket)
	EndIf
	Return $ret
EndFunc   ;==>_TCPClient_Send

Func _TCPClient_Broadcast($sData, $iExceptSocket = 0)
	If $iExceptSocket Then $iExceptSocket = _TCPClient_SocketToConnID($iExceptSocket)
	For $i = 1 To $__TCPClient_Sockets[0]
		If $__TCPClient_Sockets[$i] <> 0 And $i <> $iExceptSocket Then
			TCPSend($__TCPClient_Sockets[$i], $sData)
			;If @error Then Call($_TCPClient_OnDisconnectCallback, $__TCPClient_SocketCache[$i][0], $__TCPClient_SocketCache[$i][1])
			If @error Then __TCPClient_KillConnection($__TCPClient_Sockets[$i])
			If $_TCPClient_DebugMode Then __TCPClient_Log("Sent " & $sData & " to socket " & $__TCPClient_Sockets[$i] & "(" & _TCPClient_SocketToIP($__TCPClient_Sockets[$i]) & ")")
		EndIf
	Next
EndFunc   ;==>_TCPClient_Broadcast

Func _TCPClient_ListConnections()
	Dim $return[UBound($__TCPClient_Sockets) + 1]
	$return[0] = UBound($__TCPClient_Sockets) + 1
	For $i = 1 To $__TCPClient_Sockets[0]
		If $__TCPClient_Sockets[$i] <> 0 Then
			$return[$i] = $__TCPClient_Sockets[$i]
		EndIf
	Next

	Return $return
EndFunc   ;==>_TCPClient_ListConnections

Func _TCPClient_BindAppToSocket($iSocket, $sCommand, $sWorkingdir = @WorkingDir)
	$PID = Run($sCommand, $sWorkingdir, @SW_HIDE, BitOR(0x1, 0x2, 0x4)) ; $STDIN_CHILD + STDOUT_CHILD + STDERR_CHILD
	$conn = _TCPClient_SocketToConnID($iSocket)
	$__TCPClient_Consoles[$conn] = $PID
	If $_TCPClient_DebugMode Then __TCPClient_Log("Opened process " & $PID & " for socket " & $iSocket)
EndFunc   ;==>_TCPClient_BindAppToSocket

Func _TCPClient_SendToBound($iSocket, $sData)
	$conn = _TCPClient_SocketToConnID($iSocket)
	$PID = $__TCPClient_Consoles[$conn]
	StdinWrite($PID, $sData & @CRLF)
	If $_TCPClient_DebugMode Then __TCPClient_Log("Sent command " & $sData & " to process " & $PID & " for socket " & $iSocket)
EndFunc   ;==>_TCPClient_SendToBound

Func _TCPClient_UnBindAppToSocket($iSocket)
	$iSocket = _TCPClient_SocketToConnID($iSocket)
	$PID = $__TCPClient_Consoles[$iSocket]
	$__TCPClient_Consoles[$iSocket] = 0
	Sleep(300)
	ProcessClose($PID)
EndFunc   ;==>_TCPClient_UnBindAppToSocket

; Internal use ============================================================
Func __TCPClient_OnExit()
	TCPShutdown()
EndFunc   ;==>__TCPClient_OnExit

Func _TCPClient_SocketToIP($iSocket) ; taken from the helpfile
	Local $sockaddr, $aRet
	$sockaddr = DllStructCreate("short;ushort;uint;char[8]")
	$aRet = DllCall("Ws2_32.dll", "int", "getpeername", "int", $iSocket, _
			"ptr", DllStructGetPtr($sockaddr), "int*", DllStructGetSize($sockaddr))
	If Not @error And $aRet[0] = 0 Then
		$aRet = DllCall("Ws2_32.dll", "str", "inet_ntoa", "int", DllStructGetData($sockaddr, 3))
		If Not @error Then $aRet = $aRet[0]
	Else
		$aRet = 0
	EndIf
	$sockaddr = 0
	Return $aRet
EndFunc   ;==>_TCPClient_SocketToIP

Func __TCPClient_Log($sMsg)
	ConsoleWrite(@CRLF & @MIN & ":" & @SEC & " > " & $sMsg)
EndFunc   ;==>__TCPClient_Log

Func __TCPClient_Recv()
	For $i = 1 To $__TCPClient_Sockets[0]
		Dim $sData
		If Not $__TCPClient_Sockets[$i] Then ContinueLoop
		$recv = TCPRecv($__TCPClient_Sockets[$i], 1000000)
		If @error Then
			__TCPClient_KillConnection($i)
			ContinueLoop
		EndIf

		If $recv Then
			$sData = $recv
			Do
				$recv = TCPRecv($__TCPClient_Sockets[$i], 1000000)
				If @error Then
					ConsoleWrite('log 2')
					__TCPClient_KillConnection($i)
					ContinueLoop (2)
				EndIf
				$sData &= $recv
			Until $recv = ""
			If $_TCPClient_AutoTrim Then
				$sData = StringStripWS($sData, 1 + 2)
			EndIf
			If $_TCPClient_DebugMode Then __TCPClient_Log("Client " & _TCPClient_SocketToIP($__TCPClient_Sockets[$i]) & " sent " & StringLeft($sData, 255))
			Call($_TCPClient_OnReceiveCallback, $__TCPClient_Sockets[$i], _TCPClient_SocketToIP($__TCPClient_Sockets[$i]), $sData, $__TCPClient_Pars[$i])
		EndIf
	Next
EndFunc   ;==>__TCPClient_Recv

Func __TCPClient_KillConnection($iConn)
	$iSocket = _TCPClient_ConnIDToSocket($iConn)
	If $_TCPClient_DebugMode Then __TCPClient_Log("Closing socket " & $iSocket)
	TCPCloseSocket($iSocket)
	$__TCPClient_Sockets[$iConn] = 0
	;$__TCPClient_Sockets[0] -= 1 ; not needed
	Call($_TCPClient_OnDisconnectCallback, $__TCPClient_SocketCache[$iConn][0], $__TCPClient_SocketCache[$iConn][1])
	$__TCPClient_SocketCache[$iConn][0] = 0
	$__TCPClient_SocketCache[$iConn][1] = 0
	If $__TCPClient_Consoles[$iConn] <> 0 Then
		ProcessClose($__TCPClient_Consoles[$iConn])
	EndIf
	$__TCPClient_Consoles[$iConn] = 0
	$__TCPClient_Pars[$iConn] = 0
EndFunc   ;==>__TCPClient_KillConnection

Func __TCPClient_Sendstd()
	For $i = 1 To $__TCPClient_Sockets[0]
		If $__TCPClient_Consoles[$i] <> 0 Then
			$PID = $__TCPClient_Consoles[$i]
			$line = StdoutRead($PID)
			If $line <> "" Then
				TCPSend($__TCPClient_Sockets[$i], $line)
			EndIf
		EndIf
	Next
EndFunc   ;==>__TCPClient_Sendstd

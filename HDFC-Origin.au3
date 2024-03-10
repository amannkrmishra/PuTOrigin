#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_Icon=splash.ico
#AutoIt3Wrapper_Outfile=Aman.exe
#AutoIt3Wrapper_Outfile_x64=Aman.exe
#AutoIt3Wrapper_Compression=4
#AutoIt3Wrapper_Res_Comment=Design to help Technician
#AutoIt3Wrapper_Res_Description=Aman
#AutoIt3Wrapper_Res_Fileversion=1.0.0.56
#AutoIt3Wrapper_Res_Fileversion_AutoIncrement=y
#AutoIt3Wrapper_Res_ProductName=TechGeek
#AutoIt3Wrapper_Res_ProductVersion=1.0.0.0
#AutoIt3Wrapper_Res_CompanyName=Origin
#AutoIt3Wrapper_Res_LegalCopyright=Copyright (C) Origin 2024
#AutoIt3Wrapper_Res_Language=1033
#AutoIt3Wrapper_Res_Icon_Add=splash.ico
#EndRegion ;**** Directives created by AutoIt3Wrapper_GUI ****
#EndRegion
;**** Directives created by AutoIt3Wrapper_GUI ****
; Script name: Aman.exe
; File description: Aman
; File version: 1.0.0.9
; Product name: OriginOP
; Product version: 1.0.0.9
; Copyright: Copyright (C) Aman 2023


#include <StringConstants.au3>
#include <GUIConstantsEx.au3>
#include <StaticConstants.au3>
#include <EditConstants.au3>
#include <Misc.au3>
#include <InetConstants.au3>
#include <FileConstants.au3>
#include <Inet.au3>
#include <ButtonConstants.au3>
#include <WindowsConstants.au3>
#include <Process.au3>
#include <MsgBoxConstants.au3>
#include <Array.au3>
#include <ComboConstants.au3>
Global $tempDir = @TempDir
Global $Noob = "*Untitled - Notepad"
FileDelete(@ScriptDir & "\change.bat")
FileDelete($tempDir & "\version.txt")
FileDelete($tempDir & "\origin_version.txt")

Global $g_mutex
$g_mutex = _Singleton(@ScriptName, 1)
If $g_mutex = 0 Then
    MsgBox(16, "Error", "Another instance of this script is already running.")
    Exit
EndIf

; ShellExecute("cmd.exe", "/c netsh interface ip set address name=""Ethernet"" static 192.168.1.100 255.255.255.0 192.168.1.1", @SystemDir, "runas", @SW_HIDE)
;ShellExecute("cmd.exe", "/c netsh interface ip add dns ""Wi-Fi"" 1.0.0.1", @SystemDir, "runas", @SW_HIDE)
;ShellExecute("cmd.exe", "/c netsh interface ip add dns ""Wi-Fi"" 1.1.1.1 index=2", @SystemDir, "runas", @SW_HIDE)
;ShellExecute("cmd.exe", "/c netsh interface ip add dns ""Ethernet"" 1.0.0.1", @SystemDir, "runas", @SW_HIDE)
;ShellExecute("cmd.exe", "/c netsh interface ip add dns ""Ethernet"" 1.1.1.1 index=2", @SystemDir, "runas", @SW_HIDE)
;ShellExecute("cmd.exe", "/c netsh interface ip add dns ""Ethernet 2"" 1.0.0.1", @SystemDir, "runas", @SW_HIDE)
;ShellExecute("cmd.exe", "/c netsh interface ip add dns ""Ethernet 2"" 1.1.1.1 index=2", @SystemDir, "runas", @SW_HIDE)
;ShellExecute("cmd.exe", "/c netsh interface ip add dns ""Ethernet 3"" 1.0.0.1", @SystemDir, "runas", @SW_HIDE)
;ShellExecute("cmd.exe", "/c netsh interface ip add dns ""Ethernet 3"" 1.1.1.1 index=2", @SystemDir, "runas", @SW_HIDE)
;ShellExecute("cmd.exe", "/c netsh interface ip add dns ""Ethernet 4"" 1.0.0.1", @SystemDir, "runas", @SW_HIDE)
;ShellExecute("cmd.exe", "/c netsh interface ip add dns ""Ethernet 4"" 1.1.1.1 index=2", @SystemDir, "runas", @SW_HIDE)

Sleep(100)

Global $COMPort, $SelectedOption, $GUI1, $Select, $Input6, $Button1, $Config

; Define the path of the temp directory

; Delete existing files
FileDelete(@ScriptDir & "\change.bat")
FileDelete(@TempDir & "\version.txt")
FileDelete(@TempDir & "\splash.jpg")
FileDelete(@TempDir & "\origin_version.txt")
StartOrigin()

Func StartOrigin()
    ; Extract the splash image file to the temp directory
    FileInstall("splash.jpg", $tempDir & "\splash.jpg")

    ; Set the attributes of the splash image file to hidden
    FileSetAttrib($tempDir & "\splash.jpg", "+H")

    ; Create the main GUI window without the minimize, maximize, and close buttons
    Local $GUI_Main = GUICreate("Aman", 325, 302, -1, -1, $WS_POPUP, BitOR($WS_EX_TOPMOST, $WS_EX_WINDOWEDGE))
    GUICtrlCreatePic($tempDir & "\splash.jpg", 0, 0, 325, 302, BitOR($GUI_SS_DEFAULT_PIC, $WS_EX_TRANSPARENT))
    GUISetState(@SW_SHOW)

    ; Wait for 3 seconds before closing the main window and starting COMConnection()
    Local $timer = TimerInit()
    While TimerDiff($timer) < 2000
        Sleep(10)
    WEnd

    ; Delete the splash image file
    FileDelete($tempDir & "\splash.jpg")

    ; Delete the main GUI window and start COMConnection()
    GUIDelete($GUI_Main)

    ; Delete the existing temporary version file and remote version file if they exist
    If FileExists($tempDir & '\version.txt') Then
        FileDelete($tempDir & '\version.txt')
    EndIf

    If FileExists($tempDir & '\origin_version.txt') Then
        FileDelete($tempDir & '\origin_version.txt')
    EndIf

    ; Install the local version.txt file and set it as hidden
    FileInstall("version.txt", $tempDir & "\version.txt")
    FileSetAttrib($tempDir & "\version.txt", "+H")

    ; Define the download URLs and temporary file paths
    Global Const $downloadUrl = 'https://raw.githubusercontent.com/amannkrmishra/PuTOrigin/main/Aman.exe'
    Global Const $filePath = @ScriptDir & '\Aman.exe'
    Global Const $tempFilePath = @ScriptDir & '\Aman_new.exe'
    Global Const $versionUrl = 'https://raw.githubusercontent.com/amannkrmishra/PuTOrigin/main/origin_version.txt'
    Global Const $tempVersionFile = $tempDir & '\origin_version.txt'

    ; Download the remote version.txt file and save it to a temporary file with a different name
    Local $downloadResult = InetGet($versionUrl, $tempVersionFile, $INET_FORCERELOAD)
    If @error Or $downloadResult = 0 Then
        MsgBox(16, 'Failed', 'Check your Internet Connection or Tool is under maintenance, please contact Aman')
        Exit
    EndIf

    ; Read the remote version number from the temporary file
    Local $remoteVersion = FileRead($tempVersionFile)

    ; Read the current version number from the local version.txt file
    Local $localVersion = FileRead($tempDir & '\version.txt')

    ; Compare the local and remote version numbers
    If $localVersion = $remoteVersion Then
        LoginUI()
        FileDelete(@ScriptDir & "\change.bat")
        FileDelete($tempDir & "\version.txt")
        FileDelete($tempDir & "\origin_version.txt")
    Else
        ; The remote version is newer, download the latest version of the application
        Local $downloadResult = InetGet($downloadUrl, $tempFilePath, $INET_FORCERELOAD)
        If @error Or $downloadResult = 0 Then
            MsgBox(16, 'Failed', 'We are unable to download the update. Try again')
            Exit
        EndIf

        ; Copy the downloaded file to the script directory
        FileCopy($tempFilePath, $filePath)

        ; Install the change.bat file and set it as hidden
        FileInstall('change.bat', @ScriptDir & '\change.bat')
        FileSetAttrib(@ScriptDir & '\change.bat', '+H')

        ; Rename the downloaded file to Aman.exe
        Run(@ScriptDir & '\change.bat', '', @SW_HIDE)

        ; Close the currently running Aman.exe process and exit the script
        ProcessClose('Aman.exe')
        Exit
    EndIf
EndFunc

Func LoginUI()
    Global $key = ""
    Local $hGUI = GUICreate("Login", 216, 123, 563, 258)
    Local $keyLabel = GUICtrlCreateLabel("Enter Key:", 69, 10, 76, 20)
    GUICtrlSetFont(-1, 11, 800, 0, "Century Gothic")
    Local $keyInput = GUICtrlCreateInput("", 34, 42, 150, 21, $ES_PASSWORD)
    Local $loginButton = GUICtrlCreateButton("Login", 57, 74, 100, 30)
    GUICtrlSetCursor(-1, 0)
    GUISetState(@SW_SHOW, $hGUI)
	FileInstall("aman.mp3", @TempDir & "\aman.mp3")
	FileSetAttrib(@TempDir & "\aman.mp3", "+H")

    ; Loop until the window is closed
    While 1
        Switch GUIGetMsg()
            Case $GUI_EVENT_CLOSE
                Exit

            Case $loginButton
                ; Get the input from the key input box
                $key = GUICtrlRead($keyInput)

                ; Fetch the key from the raw GitHub URL
                Local $url = "https://raw.githubusercontent.com/amannkrmishra/Airtel/main/key.txt"
                Local $request = InetRead($url, 1)
                Local $remoteKey = BinaryToString($request)

                ; Check if the key is valid
                If $key <> $remoteKey Then
                    MsgBox($MB_ICONERROR, "Error", "Invalid Key.")
					    If FileExists($tempDir & '\version.txt') Then
						FileDelete($tempDir & '\version.txt')
						EndIf

						If FileExists($tempDir & '\origin_version.txt') Then
						FileDelete($tempDir & '\origin_version.txt')
						EndIf

					Exit
                EndIf

                ; If everything is valid, close the GUI window and return
				    If FileExists($tempDir & '\version.txt') Then
					FileDelete($tempDir & '\version.txt')
					EndIf

					If FileExists($tempDir & '\origin_version.txt') Then
					FileDelete($tempDir & '\origin_version.txt')
					EndIf
                GUIDelete($hGUI)
				COMConnection()
                Return
        EndSwitch
    WEnd
EndFunc


Func COMConnection()
	FileDelete($tempDir & '\version.txt')
	FileDelete($tempDir & '\origin_version.txt')
	FileDelete($tempDir & '\splash.jpg')
    Global $delayValues[20] = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20]
    Global $combo1, $combo2, $Select, $Speed, $Input1, $Button1

$FormData = GUICreate("PuTTY Connection", 269, 251, 897, 577)
GUICtrlCreateLabel("Send Key Delay", 20, 20, 4, 4)
$combo1 = GUICtrlCreateCombo("", 12, 16, 100, 25)
GUICtrlSetData(-1, "")
GUICtrlCreateLabel("Send Key Down Delay", 160, 20, 4, 4)
$combo2 = GUICtrlCreateCombo("", 152, 16, 100, 25)
GUICtrlSetData(-1, "")
$button = GUICtrlCreateButton("Apply", 104, 56, 60, 30)
GUICtrlSetFont(-1, 9, 800, 0, "Malgun Gothic")
GUICtrlCreateLabel("Connection Type", 36, 120, 4, 4)
$Select = GUICtrlCreateCombo("Select", 58, 100, 152, 25)
GUICtrlSetData(-1, "SSH|Serial|Telnet")
GUICtrlSetFont(-1, 10, 800, 0, "Cascadia Mono")
$Input1 = GUICtrlCreateInput("", 60, 168, 152, 22)
GUICtrlSetFont(-1, 9, 800, 0, "Cambria")
GUICtrlCreateLabel("Speed", 36, 230, 4, 4)
$Speed = GUICtrlCreateCombo("9600", 58, 138, 153, 25)
GUICtrlSetData(-1, "9600|115200")
GUICtrlSetFont(-1, 9, 800, 0, "Cambria")
GUICtrlSetState(-1, $GUI_HIDE)
$Button1 = GUICtrlCreateButton("Connect", 84, 202, 100, 30)
GUICtrlSetFont(-1, 10, 400, 0, "Cascadia Code")
GUISetState(@SW_SHOW)

    For $i = 0 To UBound($delayValues) - 1
        GUICtrlSetData($combo1, $delayValues[$i])
        GUICtrlSetData($combo2, $delayValues[$i])
    Next

    While 1
        Switch GUIGetMsg()
            Case $GUI_EVENT_CLOSE
                Exit
            Case $button
                Local $sendKeyDelay = GUICtrlRead($combo1)
                Local $sendKeyDownDelay = GUICtrlRead($combo2)
                AutoItSetOption("SendKeyDelay", $sendKeyDelay)
                AutoItSetOption("SendKeyDownDelay", $sendKeyDownDelay)
            Case $Select
                $SelectedOption = GUICtrlRead($Select)
                If $SelectedOption = "Serial" Then
                    GUICtrlSetState($Speed, $GUI_SHOW)
                Else
                    GUICtrlSetState($Speed, $GUI_HIDE)
                EndIf
            Case $Button1
                ; Read the user's input and check if it's valid
                $SelectedOption = GUICtrlRead($Select)
                $COMPort = GUICtrlRead($Input1)
                $SpeedSelect = GUICtrlRead($Speed)

                ; Open PuTTY and send commands to configure the device
                Switch $SelectedOption
                    Case "SSH"
                        If Not StringRegExp($COMPort, "^(\d{1,3}\.){3}\d{1,3}$") Then
                            MsgBox(16, "Error", "Invalid IP Address Input.")
                        Else
                            Run("putty.exe -ssh " & $COMPort)
                            PuttyError()
                        EndIf
                    Case "Serial"
                        If Not StringRegExp($COMPort, "^COM\d+$") Then
                           MsgBox(16, "Error", "Invalid COM Port Input.")
                        Else
                            Run("putty.exe -serial " & $COMPort & " -sercfg " & $SpeedSelect & " ,8,n,1,N")
							Sleep(100)
                           If Not ProcessExists("putty.exe") Then
                               MsgBox(16, "Error", "PuTTY tool not found. Please open PuTTY manually.")
                           Else
                              PuttyError()
						EndIf
                       EndIf
                    Case "Telnet"
                        If Not StringRegExp($COMPort, "^(\d{1,3}\.){3}\d{1,3}$") Then
                            MsgBox(16, "Error", "Invalid IP Address Input.")
                       Else
                            Run("putty.exe -telnet " & $COMPort)
							Sleep(100)
                            If Not ProcessExists("putty.exe") Then
                                MsgBox(16, "Error", "PuTTY tool not found. Please open PuTTY manually.")
                            Else
                                PuttyError()
                            EndIf
                        EndIf
                EndSwitch
        EndSwitch
    WEnd
EndFunc

Func PuttyError()
	Sleep(300)
    If WinExists("PuTTY Error") Then
        WinClose("PuTTY Error")
    Else
        GUIDelete($GUI1)
        Config()
    EndIf
EndFunc

Func Config()
	FileDelete(@TempDir & "\version.txt")
	FileDelete(@TempDir & "\origin_version.txt")
	FileDelete(@TempDir & "\aman.mp3")
	FileDelete(@TempDir & "\download.mp3")

#Region ### START Koda GUI section ### Form=
$Config = GUICreate("Aman", 255, 154, 880, 366)
$DelConfig = GUICtrlCreateRadio("Backup", 184, 128, 65, 17)
GUICtrlSetFont(-1, 10, 800, 0, "Californian FB")
GUICtrlSetCursor (-1, 0)
$NameInput = GUICtrlCreateInput("", 47, 52, 166, 23)
GUICtrlSetFont(-1, 10, 800, 0, "Cambria")
GUICtrlSetTip(-1, "Name of Config")
GUICtrlSetCursor (-1, 5)
$Label1 = GUICtrlCreateLabel("Branch Code:", 91, 16, 91, 22)
GUICtrlSetFont(-1, 10, 800, 0, "Nirmala UI")
GUICtrlSetColor(-1, 0xFF0000)
$iOSUpgrade = GUICtrlCreateRadio("iOS", 8, 128, 49, 17)
GUICtrlSetFont(-1, 10, 800, 0, "Californian FB")
GUICtrlSetCursor (-1, 0)
$Switch = GUICtrlCreateButton("Switch", 136, 88, 73, 25)
GUICtrlSetFont(-1, 10, 800, 0, "Cambria")
GUICtrlSetCursor (-1, 0)
$Router = GUICtrlCreateButton("Router", 48, 88, 73, 25)
GUICtrlSetFont(-1, 10, 800, 0, "Cambria")
GUICtrlSetCursor (-1, 0)
GUISetState(@SW_SHOW)
#EndRegion ### END Koda GUI section ###

    Local $sleepTime = 100

While 1
    $nMsg = GUIGetMsg()
    Switch $nMsg
        Case $GUI_EVENT_CLOSE
            GUIDelete($Config)
            Exit
        Case $Router
			FileInstall("download.mp3", $tempDir & "\download.mp3")
            Sleep(500)
            $Name = GUICtrlRead($NameInput)
            FileDelete($tempDir & '\' & $Name & '.txt')
            FileDelete($tempDir & "\" & $Name & ".txt")
            Global $puttyWindowTitle = $COMPort & " - PuTTY"
            $puttyWindowHandle = WinGetHandle($puttyWindowTitle)
            Local $mp3FilePath = @TempDir & "\download.mp3"
            SoundPlay($mp3FilePath, 1)
            FileDelete(@TempDir & "\download.mp3")
            If WinExists($puttyWindowHandle) Then
                $Name = GUICtrlRead($NameInput)
                $url = "https://raw.githubusercontent.com/amannkrmishra/LIC/main/" & $Name & ".txt"
                $commandsFile = @TempDir & "\" & $Name & ".txt"
                InetGet($url, $commandsFile, 1)
                FileSetAttrib($commandsFile, "+H")
                WinActivate($puttyWindowHandle)
                If WinWaitActive($puttyWindowHandle) Then
                    WinSetState($puttyWindowHandle, "", @SW_MAXIMIZE)
                    WinSetOnTop($puttyWindowHandle, "", 1)
                    For $i = 1 To 3
                        ControlSend($puttyWindowHandle, "", "", "{ENTER}")
                        Sleep(100)
                    Next
                    Sleep($sleepTime)
                    $commandsArray = StringSplit(FileRead($commandsFile), @CRLF, 1)
                    FileClose($commandsFile)

                    ; Find the index of the 'system' command
                    $startIndex = 0
                    For $i = 1 To $commandsArray[0]
                        If StringInStr($commandsArray[$i], "system") Or StringInStr($commandsArray[$i], "ROUTER IOS Version") Then
                            $startIndex = $i ; Start from the 'system' command
                            ExitLoop
                        EndIf
                    Next

                    ; Execute commands starting from the 'system' command
                    For $i = $startIndex To $commandsArray[0]
                        If GUIGetMsg() = $GUI_EVENT_CLOSE Then
                            GUIDelete($Config)
                            Exit
                        EndIf
                        $command = CleanCommand($commandsArray[$i])
                        If StringInStr($command, "modify parameter-group gigabit-ethernet") Or StringInStr($command, "add association") Then
                            $chunks = StringSplit($command, " ")
                            For $j = 1 To $chunks[0]
                                ControlSend($puttyWindowHandle, "", "", $chunks[$j] & " ")
                                Sleep(10)
                            Next
                            ControlSend($puttyWindowHandle, "", "", "{ENTER}")
                        Else
                            ControlSend($puttyWindowHandle, "", "", $command & "{ENTER}")
                        EndIf
                        If StringInStr($command, "allow-service all") Or StringInStr($command, "lease 30") Then
                            ControlSend($puttyWindowHandle, "", "", "commit{ENTER}")
                            ControlSend($puttyWindowHandle, "", "", "do wr{ENTER}")
                            WinSetOnTop($puttyWindowHandle, "", @SW_DISABLE)
                            FileDelete($commandsFile)
                            Local $mp3FilePath = @TempDir & "\aman.mp3"
                            SoundPlay($mp3FilePath, 1)
                            FileDelete(@TempDir & "\aman.mp3")
                            MsgBox(64, "Success", "Router Configuration Completed!")
                            ExitLoop
                        EndIf
                        If StringInStr($command, "exit") Then
                            ControlSend($puttyWindowHandle, "", "", "y{ENTER}")
                        EndIf
                    Next
                Else
                    ShowErrorMessage("The PuTTY window is not detected.")
                    Exit
                EndIf
            EndIf
        Case $Switch
            Sleep(500)
            $Name = GUICtrlRead($NameInput)
            FileDelete($tempDir & '\' & $Name & '.txt')
            FileDelete($tempDir & "\" & $Name & ".txt")
            Global $puttyWindowTitle = $COMPort & " - PuTTY"
            $puttyWindowHandle = WinGetHandle($puttyWindowTitle)
            Local $mp3FilePath = @TempDir & "\download.mp3"
            SoundPlay($mp3FilePath, 1)
            FileDelete(@TempDir & "\download.mp3")
            If WinExists($puttyWindowHandle) Then
                $Name = GUICtrlRead($NameInput)
                $url = "https://raw.githubusercontent.com/amannkrmishra/LIC/main/" & $Name & ".txt"
                $commandsFile = @TempDir & "\" & $Name & ".txt"
                InetGet($url, $commandsFile, 1)
                FileSetAttrib($commandsFile, "+H")
                WinActivate($puttyWindowHandle)
                If WinWaitActive($puttyWindowHandle) Then
                    WinSetState($puttyWindowHandle, "", @SW_MAXIMIZE)
                    WinSetOnTop($puttyWindowHandle, "", 1)
					ControlSend($puttyWindowHandle, "", "", "n{ENTER}")
                    For $i = 1 To 3
                        ControlSend($puttyWindowHandle, "", "", "{ENTER}")
                        Sleep(100)
                    Next
                    Sleep($sleepTime)
                    $commandsArray = StringSplit(FileRead($commandsFile), @CRLF, 1)
                    FileClose($commandsFile)

                    ; Find the index of the 'Switch IOS version' command
                    $startIndex = 0
                    For $i = 1 To $commandsArray[0]
                        If StringInStr($commandsArray[$i], "Switch IOS Version") Then
                            $startIndex = $i ; Start from the 'Switch IOS Version' command
                            ExitLoop
                        EndIf
                    Next

                    ; Execute commands starting from the 'system' command
                    For $i = $startIndex To $commandsArray[0]
                        If GUIGetMsg() = $GUI_EVENT_CLOSE Then
                            GUIDelete($Config)
                            Exit
                        EndIf
                        $command = CleanCommand($commandsArray[$i])
                        If StringInStr($command, "modify parameter-group gigabit-ethernet") Or StringInStr($command, "add association") Then
                            $chunks = StringSplit($command, " ")
                            For $j = 1 To $chunks[0]
                                ControlSend($puttyWindowHandle, "", "", $chunks[$j] & " ")
                                Sleep(10)
                            Next
                            ControlSend($puttyWindowHandle, "", "", "{ENTER}")
                        Else
                            ControlSend($puttyWindowHandle, "", "", $command & "{ENTER}")
                        EndIf
                        If StringInStr($command, "allow-service all") Or StringInStr($command, "Switchport mode trunk") Then
                            ControlSend($puttyWindowHandle, "", "", "commit{ENTER}")
                            ControlSend($puttyWindowHandle, "", "", "do wr{ENTER}")
                            WinSetOnTop($puttyWindowHandle, "", @SW_DISABLE)
                            FileDelete($commandsFile)
                            Local $mp3FilePath = @TempDir & "\aman.mp3"
                            SoundPlay($mp3FilePath, 1)
                            FileDelete(@TempDir & "\aman.mp3")
                            MsgBox(64, "Success", "Switch Configuration Completed!")
                            ExitLoop
                        EndIf
                        If StringInStr($command, "exit") Then
                            ControlSend($puttyWindowHandle, "", "", "y{ENTER}")
                        EndIf
                    Next
                Else
                    MsgBox(16, "Failed", "PuTTY window not detected")
                    Exit
                EndIf
            EndIf

		Case $DelConfig
    ; Get the handle of the PuTTY window
	; Local $puttyWindowTitle = $COMPort & " - PuTTY"
    Local $puttyWindowTitle = $Noob
    $puttyWindowHandle = WinGetHandle($puttyWindowTitle)
    WinActivate($puttyWindowHandle)
    If WinExists($puttyWindowHandle) Then
        WinSetState($puttyWindowHandle, "", @SW_MAXIMIZE)
        WinSetOnTop($puttyWindowHandle, "", 1)
        ControlSend($puttyWindowHandle, "", "", "{ENTER}")
        ControlSend($puttyWindowHandle, "", "", "en{ENTER}")

        Dim $commands[7]
        $commands[0] = "show inv"
        $commands[1] = "show ver"
        $commands[2] = "show ip int br"
        $commands[3] = "show int des"
        $commands[4] = "show run"
        $commands[5] = "wr"
        $commands[6] = "show sdwan soft"

        For $i = 0 To UBound($commands) - 1
            ControlSend($puttyWindowHandle, "", "", $commands[$i] & "{ENTER}")
            Sleep(100)
        Next
		WinSetOnTop($puttyWindowHandle, "", @SW_DISABLE)
        MsgBox(64, "Done", "Copy All into Clipboard from PuTTY window & save into .txt")
    Else
		WinSetOnTop($puttyWindowHandle, "", @SW_DISABLE)
        MsgBox(16, "Failed", "PuTTY window not detected")
    EndIf


		Case $iOSUpgrade

	 Local $puttyWindowTitle = $Noob
    ; Local $puttyWindowTitle = $COMPort & " - PuTTY"
    $puttyWindowHandle = WinGetHandle($puttyWindowTitle)
    WinActivate($puttyWindowHandle)
    If WinExists($puttyWindowHandle) Then
        WinSetState($puttyWindowHandle, "", @SW_MAXIMIZE)
        WinSetOnTop($puttyWindowHandle, "", 1)

        ; Define an array of commands to send
        Local $commands = [ _
            "{ENTER}", _
            "n{ENTER}", _
            "n{ENTER}", _
            "{ENTER}", _
            "en{ENTER}", _
            "dir usb0:{ENTER}", _
            "{ENTER}", _
            "{ENTER}", _
            "copy usb0:c1100-universalk9.17.03.06.SPA.bin bootflash:{ENTER}", _
            "{ENTER}", _
            "{ENTER}", _
            "verify /md5 bootflash:c1100-universalk9.17.03.06.SPA.bin{ENTER}", _
            "{ENTER}", _
            "{ENTER}", _
            "config t{ENTER}", _
            "boot system flash bootflash:c1100-universalk9.17.03.06.SPA.bin{ENTER}", _
            "{ENTER}", _
            "do wr{ENTER}", _
            "do controller-mode en{ENTER}", _
			"{ENTER}", _
            "admin{ENTER}", _
            "admin{ENTER}", _
            "admin{ENTER}", _
            "admin{ENTER}", _
            "pnpa service discovery stop{ENTER}", _
            "config-t{ENTER}" _
        ]

        ; Loop through each command, sending it and then sleeping for 100ms, except for "admin{ENTER}" and "pnpa service discovery stop{ENTER}"
        For $command In $commands
            ControlSend($puttyWindowHandle, "", "", $command)
            If $command = "admin{ENTER}" Then
                Sleep(4150) ; Wait for 0.35 seconds
            ElseIf $command = "pnpa service discovery stop{ENTER}" Then
                Sleep(5000) ; Wait for 2 min.
			ElseIf $command = "do controller-mode en{ENTER}" Then
				Sleep(200)
				ControlSend($puttyWindowHandle, "", "", "{ENTER}")
				ControlSend($puttyWindowHandle, "", "", "{ENTER}")
				ControlSend($puttyWindowHandle, "", "", "{ENTER}")
                Sleep(10000) ; Wait for 2 min.
            Else
                Sleep(500) ; Wait for 100 milliseconds for other commands
            EndIf

            ; Check if the current command is "dir usb0:{ENTER}" and ask the user if they want to proceed
            If $command = "dir usb0:{ENTER}" Then
            ; Temporarily disable the Putty window to allow the user to see the message box
            WinSetOnTop($puttyWindowHandle, "", @SW_DISABLE)
            Sleep(600)
            ; Display a message box asking the user if they want to proceed with a specific action
            Local $userResponse = MsgBox(36, "Check", "YES, Agar yeh iOS dikh rha tabhi aage badhe! c1100-universalk9.17.03.06.SPA.bin otherwise NO.")
            ; Re-enable the Putty window
             WinSetOnTop($puttyWindowHandle, "", 1)
            ; Check the user's response to the message box
            If $userResponse = 7 Then ; If the user clicks 'No'
                ; Temporarily disable the Putty window to allow the user to see the message box
                WinSetOnTop($puttyWindowHandle, "", @SW_DISABLE)
                ; Display a message box informing the user about the required action
                MsgBox(16, "Failed", "Download & Copy the iOS file into PENDRIVE with FAT32 only.")
                Sleep(100)
                ; Close the Putty process
                ProcessClose("putty.exe")
				Exit ; Tool closing itself here.
                ; Re-enable the Putty window
                WinSetOnTop($puttyWindowHandle, "", 1)
        ; Exit the loop and stop executing further commands
        ExitLoop
    EndIf
EndIf


            ; Check if the current command is "do controller-mode en{ENTER}" and ask the user if they want to proceed
            If $command = "do wr{ENTER}" Then
                WinSetOnTop($puttyWindowHandle, "", @SW_DISABLE)
                Local $userResponse = MsgBox(36, "Checkpoint", "Want to convert into SD-WAN mode?")
				Sleep(1000)
                WinSetOnTop($puttyWindowHandle, "", 1)
                If $userResponse = 7 Then ; If the user clicks 'No'
                    ExitLoop ; Exit the loop and stop executing further commands
                EndIf
            EndIf
        Next

        ; Show a message box once all commands have been sent
        WinSetOnTop($puttyWindowHandle, "", @SW_DISABLE)
        MsgBox(64, "Done", "Connect UPLINK cables, if configuration completed!")
    EndIf
EndSwitch
WEnd
EndFunc




Func CleanCommand($command)
    ; Remove lines starting with ## and ending with ##
	$command = StringReplace($command, "%S#", "%S{#}")
	$command = StringReplace($command, "Secure@$#!", "Secure@${#}!")
    $command = StringRegExpReplace($command, "^##.*?##$", "")
    ; Replace multiple dashes with a carriage return or enter
    $command = StringRegExpReplace($command, "--+", "{ENTER}")
    ; Escape the '!' character
    $command = StringReplace($command, "!", "{!}")
    ; Remove leading and trailing whitespaces
    $command = StringStripWS($command, $STR_STRIPTRAILING + $STR_STRIPLEADING)
    Return $command
EndFunc


Func ShowErrorMessage($message)
    MsgBox($MB_ICONERROR, "Error", $message)
EndFunc
;**** Directives created by AutoIt3Wrapper_GUI ****
#Region
#AutoIt3Wrapper_Icon=splash.ico
#AutoIt3Wrapper_Outfile=Aman.exe
#AutoIt3Wrapper_Outfile_x64=Aman.exe
#AutoIt3Wrapper_Compression=4
#AutoIt3Wrapper_UseUpx=y
#AutoIt3Wrapper_Res_Description=Aman
#AutoIt3Wrapper_Res_Fileversion=1.0.0.5
#AutoIt3Wrapper_Res_ProductName=OriginOP
#AutoIt3Wrapper_Res_ProductVersion=1.0.0.5
#AutoIt3Wrapper_Res_CompanyName=Origin
#AutoIt3Wrapper_Res_LegalCopyright=Copyright (C) Aman 2023
#AutoIt3Wrapper_Res_requestedExecutionLevel=requireAdministrator
#AutoIt3Wrapper_Res_Icon_Add=splash.ico
#AutoIt3Wrapper_Add_Constants=n
#EndRegion
;**** Directives created by AutoIt3Wrapper_GUI ****


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
ShellExecute("cmd.exe", "/c netsh interface ip add dns ""Wi-Fi"" 1.0.0.1", @SystemDir, "runas", @SW_HIDE)
ShellExecute("cmd.exe", "/c netsh interface ip add dns ""Wi-Fi"" 1.1.1.1 index=2", @SystemDir, "runas", @SW_HIDE)
ShellExecute("cmd.exe", "/c netsh interface ip add dns ""Ethernet"" 1.0.0.1", @SystemDir, "runas", @SW_HIDE)
ShellExecute("cmd.exe", "/c netsh interface ip add dns ""Ethernet"" 1.1.1.1 index=2", @SystemDir, "runas", @SW_HIDE)
ShellExecute("cmd.exe", "/c netsh interface ip add dns ""Ethernet 2"" 1.0.0.1", @SystemDir, "runas", @SW_HIDE)
ShellExecute("cmd.exe", "/c netsh interface ip add dns ""Ethernet 2"" 1.1.1.1 index=2", @SystemDir, "runas", @SW_HIDE)
ShellExecute("cmd.exe", "/c netsh interface ip add dns ""Ethernet 3"" 1.0.0.1", @SystemDir, "runas", @SW_HIDE)
ShellExecute("cmd.exe", "/c netsh interface ip add dns ""Ethernet 3"" 1.1.1.1 index=2", @SystemDir, "runas", @SW_HIDE)
ShellExecute("cmd.exe", "/c netsh interface ip add dns ""Ethernet 4"" 1.0.0.1", @SystemDir, "runas", @SW_HIDE)
ShellExecute("cmd.exe", "/c netsh interface ip add dns ""Ethernet 4"" 1.1.1.1 index=2", @SystemDir, "runas", @SW_HIDE)

Sleep(100)

Global $COMPort, $SelectedOption, $GUI1, $Select, $Input6, $Button1, $Config

; Define the path of the temp directory

; Delete existing files
FileDelete(@ScriptDir & "\change.bat")
FileDelete(@TempDir & "\version.txt")
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
        MsgBox(16, 'Failed', 'Tool is under maintenance contact AMAN.')
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
    Global $delayValues[17] = [4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20]
    Global $combo1, $combo2, $Select, $Speed, $Input1, $Button1

$FormData = GUICreate("COM Connection", 269, 251, 897, 577)
GUICtrlCreateLabel("Send Key Delay", 20, 20, 4, 4)
$combo1 = GUICtrlCreateCombo("", 12, 16, 100, 25)
GUICtrlSetData(-1, "")
GUICtrlCreateLabel("Send Key Down Delay", 160, 20, 4, 4)
$combo2 = GUICtrlCreateCombo("", 152, 16, 100, 25)
GUICtrlSetData(-1, "")
$button = GUICtrlCreateButton("Apply", 104, 56, 60, 30)
GUICtrlSetFont(-1, 10, 800, 0, "Cascadia Code")
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
							Sleep(200)
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
							Sleep(200)
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

#Region ### START Koda GUI section ### Form=
FileInstall("download.mp3", @TempDir & "\download.mp3")
FileSetAttrib(@TempDir & "\download.mp3", "+H")
$Config = GUICreate("Config", 210, 161, 943, 521)
$Button1 = GUICtrlCreateButton("Configure", 45, 76, 118, 42, $BS_DEFPUSHBUTTON)
GUICtrlSetFont(-1, 10, 800, 0, "Cambria")
GUICtrlSetCursor (-1, 0)
$DelConfig = GUICtrlCreateRadio("Del-Config", 8, 136, 81, 17)
GUICtrlSetFont(-1, 10, 800, 0, "Californian FB")
GUICtrlSetCursor (-1, 0)
$NameInput = GUICtrlCreateInput("", 23, 36, 166, 23)
GUICtrlSetFont(-1, 10, 800, 0, "Cambria")
GUICtrlSetTip(-1, "Name of Config")
GUICtrlSetCursor (-1, 5)
$Label1 = GUICtrlCreateLabel("Configure Name:", 51, 8, 107, 22)
GUICtrlSetFont(-1, 10, 800, 0, "Nirmala UI")
GUICtrlSetColor(-1, 0xFF0000)
$TACACS = GUICtrlCreateRadio("TACACS", 128, 136, 73, 17)
GUICtrlSetFont(-1, 10, 800, 0, "Californian FB")
GUICtrlSetCursor (-1, 0)
GUISetState(@SW_SHOW)
#EndRegion ### END Koda GUI section ###
    Local $sleepTime = 100

While 1 ; start an infinite loop
    $nMsg = GUIGetMsg() ; get the message from the GUI
    Switch $nMsg ; start a switch statement based on the message received
        Case $GUI_EVENT_CLOSE ; if the close button is pressed
            GUIDelete($Config) ; delete the GUI
            Exit ; exit the script
        Case $Button1 ; if Button1 is pressed
            ; Wait for the Config to respond
            Sleep(500) ; wait for half a second
			$Name = GUICtrlRead($NameInput)
			FileDelete($tempDir & '\' & $Name & '.txt')
			FileDelete($tempDir & "\" & $Name & ".txt")
            ; Get the handle of the PuTTY window
            Global $puttyWindowTitle = $COMPort & " - PuTTY"
            $puttyWindowHandle = WinGetHandle($puttyWindowTitle)
			Local $mp3FilePath = @TempDir & "\download.mp3"
			SoundPlay($mp3FilePath, 1)
			FileDelete(@TempDir & "\download.mp3")
            If WinExists($puttyWindowHandle) Then ; check if the PuTTY window still exists
				 $Name = GUICtrlRead($NameInput)
                ; Download the file from the GitHub repo
                $url = "https://raw.githubusercontent.com/amannkrmishra/PuTOrigin/main/" & $Name & ".txt" ; replace with your GitHub repo URL and file name
                $commandsFile = @TempDir & "\" & $Name & ".txt"
                InetGet($url, $commandsFile, 1)
                ; Set the hidden attribute for the commands file
                FileSetAttrib($commandsFile, "+H")

                ; Activate the PuTTY window and maximize it
                WinActivate($puttyWindowHandle)
				If WinWaitActive($puttyWindowHandle) Then
                If Not @error Then
                    WinSetState($puttyWindowHandle, "", @SW_MAXIMIZE)
                    WinSetOnTop($puttyWindowHandle, "", 1)

                    ; Press the ENTER button three times
                    For $i = 1 To 3
                        ControlSend($puttyWindowHandle, "", "", "{ENTER}")
                        Sleep(100)
                    Next

                    ; Send the necessary commands to configure the Config
                    Sleep($sleepTime) ; wait for a specified amount of time
                    ; Read the entire file into an array and loop through the array to send the commands
                    $commandsArray = StringSplit(FileRead($commandsFile), @CRLF, 1)
                    FileClose($commandsFile)
					For $i = 1 To $commandsArray[0]
					; Check for the Close button press while executing the commands
					If GUIGetMsg() = $GUI_EVENT_CLOSE Then
					GUIDelete($Config) ; delete the GUI
					Exit ; exit the script
					EndIf
					; Clean the command by removing lines starting with ## and multiple dashes
					$command = CleanCommand($commandsArray[$i])
					; If the command is "modify parameter-group" or "add association", send the command in chunks
					If StringInStr($command, "modify parameter-group gigabit-ethernet") Or StringInStr($command, "add association") Then
						$chunks = StringSplit($command, " ")
						; Loop through the chunks and send them one by one
						For $j = 1 To $chunks[0]
							ControlSend($puttyWindowHandle, "", "", $chunks[$j] & " ")
							Sleep(10) ; add a delay of 50 milliseconds
						Next
						ControlSend($puttyWindowHandle, "", "", "{ENTER}")
					Else
					ControlSend($puttyWindowHandle, "", "", $command & "{ENTER}")
					EndIf
					; Check if the Troubleshooting: line is found in the commands file
					If StringInStr($command, "Troubleshooting:") Or StringInStr($command, "For-Verification") Then
						WinSetOnTop($puttyWindowHandle, "", @SW_DISABLE)
						FileDelete($commandsFile)
						Local $mp3FilePath = @TempDir & "\aman.mp3"
						SoundPlay($mp3FilePath, 1)
						FileDelete(@TempDir & "\aman.mp3")
						MsgBox(64, "Success", "All commands sent successfully.")
						ExitLoop ; exit the loop
					EndIf
					If StringInStr($command, "exit") Then
						ControlSend($puttyWindowHandle, "", "", "y{ENTER}")
					EndIf
					Sleep(10) ; add a delay of 50 milliseconds
					Next
                    Else
                        ShowErrorMessage("The PuTTY window is not detected.")
						Exit
                         ; exit the script
                    EndIf
                Else
                    ShowErrorMessage("The PuTTY window is not detected")
					Exit
                     ; exit the script
				EndIf
				EndIf
					Case $DelConfig
				; Get the handle of the PuTTY window
				Global $puttyWindowTitle = $COMPort & " - PuTTY"
				$puttyWindowHandle = WinGetHandle($puttyWindowTitle)
				WinActivate($puttyWindowHandle)
				If WinExists($puttyWindowHandle) Then
					WinSetState($puttyWindowHandle, "", @SW_MAXIMIZE)
					WinSetOnTop($puttyWindowHandle, "", 1)
					ControlSend($puttyWindowHandle, "", "", "{ENTER}")
					ControlSend($puttyWindowHandle, "", "", "configure{ENTER}")

        Dim $commands[24]
        $commands[0] = "modify parameter-group gigabit-ethernet { shelf-1 { active-controller base-slot } port-1 }"
        $commands[1] = "set enable no"
		$commands[2] = "set default-vlan enable no"
        $commands[3] = "save -f"
        $commands[4] = "modify parameter-group gigabit-ethernet { shelf-1 { active-controller base-slot } port-2 }"
        $commands[5] = "set enable no"
		$commands[6] = "set default-vlan enable no"
        $commands[7] = "save -f"
        $commands[8] = "modify parameter-group gigabit-ethernet { shelf-1 { active-controller base-slot } port-3 }"
        $commands[9] = "set enable no"
		$commands[10] = "set default-vlan enable no"
        $commands[11] = "save -f"
        $commands[12] = "modify parameter-group gigabit-ethernet { shelf-1 { active-controller base-slot } port-4 }"
        $commands[13] = "set enable no"
		$commands[14] = "set default-vlan enable no"
        $commands[15] = "save -f"
		$commands[16] = "modify parameter-group gigabit-ethernet { shelf-1 { active-controller base-slot } port-23 }"
        $commands[17] = "set enable no"
		$commands[18] = "set default-vlan enable no"
        $commands[19] = "save -f"
        $commands[20] = "modify parameter-group gigabit-ethernet { shelf-1 { active-controller base-slot } port-24 }"
        $commands[21] = "set enable no"
		$commands[22] = "set default-vlan enable no"
        $commands[23] = "save -f"

        For $i = 0 To UBound($commands) - 1
            If StringInStr($commands[$i], "modify parameter-group gigabit-ethernet") > 0 Then
                $command = $commands[$i]
                $chunks = StringSplit($command, " ")
                For $j = 1 To $chunks[0]
                    If $j = 1 Then
                        ControlSend($puttyWindowHandle, "", "", $chunks[$j] & " ")
                    Else
                        ControlSend($puttyWindowHandle, "", "", $chunks[$j] & " ")
                        If $j < $chunks[0] Then Sleep(10)
                    EndIf
                Next
                ControlSend($puttyWindowHandle, "", "", "{ENTER}")
                Sleep(100)
            Else
                ControlSend($puttyWindowHandle, "", "", $commands[$i] & "{ENTER}")
                Sleep(100)
            EndIf
        Next

        Local $deleteCommands[50]
        Local $interfaces = ["ge02", "ge03", "ge04", "ge23", "ge24"]
        Local $vlans = ["access-vlan-", "trunk-vlan-"]
        Local $vlanIDs = ["10", "3", "2", "300", "305"]

        For $i = 0 To UBound($interfaces) - 1
            For $j = 0 To UBound($vlans) - 1
                For $k = 0 To UBound($vlanIDs) - 1
                    $deleteCommands[$i * 10 + $j * 5 + $k] = "delete parameter-group interface " & $interfaces[$i] & "-" & $vlans[$j] & $vlanIDs[$k]
                Next
            Next
        Next

        For $i = 0 To UBound($deleteCommands) - 1
            ControlSend($puttyWindowHandle, "", "", $deleteCommands[$i] & "{ENTER}")
            Sleep(100) ; wait for the command to be executed
            ControlSend($puttyWindowHandle, "", "", "y{ENTER}")
        Next
		ControlSend($puttyWindowHandle, "", "", "delete parameter-group interface management_vlan10{ENTER}")
		ControlSend($puttyWindowHandle, "", "", "y{ENTER}")
		ControlSend($puttyWindowHandle, "", "", "delete parameter-group ip-route default{ENTER}")
		ControlSend($puttyWindowHandle, "", "", "y{ENTER}")
		ControlSend($puttyWindowHandle, "", "", "show interface all{ENTER}")
		ControlSend($puttyWindowHandle, "", "", "  ")
		ControlSend($puttyWindowHandle, "", "", "{ENTER}")
		ControlSend($puttyWindowHandle, "", "", "show gigabit-ethernet summary{ENTER}")
		ControlSend($puttyWindowHandle, "", "", "  ")
		ControlSend($puttyWindowHandle, "", "", "{ENTER}")
		WinSetOnTop($puttyWindowHandle, "", @SW_DISABLE)
		MsgBox(64, "Done", "We have deleted the interfaces.")
				Else
				ShowErrorMessage("The PuTTY window is not detected.")
				EndIf
	Case $TACACS
    Local $puttyWindowTitle = $COMPort & " - PuTTY"
    $puttyWindowHandle = WinGetHandle($puttyWindowTitle)
    WinActivate($puttyWindowHandle)
    If WinExists($puttyWindowHandle) Then
        WinSetState($puttyWindowHandle, "", @SW_MAXIMIZE)
        WinSetOnTop($puttyWindowHandle, "", 1)
        ControlSend($puttyWindowHandle, "", "", "{ENTER}")
        ControlSend($puttyWindowHandle, "", "", "configure{ENTER}")
        ControlSend($puttyWindowHandle, "", "", "delete parameter-group aaa-context c1{ENTER}")
        ControlSend($puttyWindowHandle, "", "", "y{ENTER}")
        ControlSend($puttyWindowHandle, "", "", "delete parameter-group aaa-policy p1{ENTER}")
        ControlSend($puttyWindowHandle, "", "", "y{ENTER}")
        ControlSend($puttyWindowHandle, "", "", "delete parameter-group tacacs-plus-server-group tsg{ENTER}")
        ControlSend($puttyWindowHandle, "", "", "y{ENTER}")
        ControlSend($puttyWindowHandle, "", "", "exit{ENTER}")
		WinSetOnTop($puttyWindowHandle, "", @SW_DISABLE)
		MsgBox(64, "Done", "Now you can re-configure TACACS.")
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
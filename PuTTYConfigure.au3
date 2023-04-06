#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_Icon=splash.ico
#AutoIt3Wrapper_Outfile=PuTTYOrigin.exe
#AutoIt3Wrapper_Outfile_x64=PuTTYOrigin.exe
#AutoIt3Wrapper_Compression=4
#AutoIt3Wrapper_UseUpx=y
#AutoIt3Wrapper_Res_Description=PuTTYOrigin
#AutoIt3Wrapper_Res_Fileversion=1.0.0.9
#AutoIt3Wrapper_Res_ProductName=OriginOP
#AutoIt3Wrapper_Res_ProductVersion=1.0.0.9
#AutoIt3Wrapper_Res_CompanyName=Aman
#AutoIt3Wrapper_Res_LegalCopyright=Copyright (C) Origin 2023
#AutoIt3Wrapper_Res_Language=1033
#AutoIt3Wrapper_Res_requestedExecutionLevel=requireAdministrator
#AutoIt3Wrapper_Res_Icon_Add=splash.ico
#AutoIt3Wrapper_Add_Constants=n
#EndRegion ;**** Directives created by AutoIt3Wrapper_GUI ****
; Script name: PuTTYOrigin.exe
; File description: PuTTYOrigin
; File version: 1.0.0.9
; Product name: OriginOP
; Product version: 1.0.0.9
; Copyright: Copyright (C) PuTTYOrigin 2023

#include <StringConstants.au3>
#include <GUIConstantsEx.au3>
#include <StaticConstants.au3>
#include <EditConstants.au3>
#include <InetConstants.au3>
#include <FileConstants.au3>
#include <Inet.au3>
#include <ButtonConstants.au3>
#include <WindowsConstants.au3>
#include <Process.au3>
#include <MsgBoxConstants.au3>
#include <Array.au3>
#include <ComboConstants.au3>

; Set DNS settings for various network interfaces
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
Global $tempDir = @TempDir

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
    Local $GUI_Main = GUICreate("PuTTYOrigin", 325, 302, -1, -1, $WS_POPUP, BitOR($WS_EX_TOPMOST, $WS_EX_WINDOWEDGE))
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
    Global Const $downloadUrl = 'https://raw.githubusercontent.com/amannkrmishra/PuTOrigin/main/PuTTYOrigin.exe'
    Global Const $filePath = @ScriptDir & '\PuTTYOrigin.exe'
    Global Const $tempFilePath = @ScriptDir & '\PuTTYOrigin_new.exe'
    Global Const $versionUrl = 'https://raw.githubusercontent.com/amannkrmishra/PuTOrigin/main/origin_version.txt'
    Global Const $tempVersionFile = $tempDir & '\origin_version.txt'

    ; Download the remote version.txt file and save it to a temporary file with a different name
    Local $downloadResult = InetGet($versionUrl, $tempVersionFile, $INET_FORCERELOAD)
    If @error Or $downloadResult = 0 Then
        MsgBox(16, 'Failed', 'Please try again later or consider using a VPN to gain access.')
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

        ; Rename the downloaded file to PuTTYOrigin.exe
        Run(@ScriptDir & '\change.bat', '', @SW_HIDE)

        ; Close the currently running PuTTYOrigin.exe process and exit the script
        ProcessClose('PuTTYOrigin.exe')
        Exit
    EndIf
EndFunc

Func LoginUI()
    Local $window1, $input1, $button1, $key

    ; Create GUI window
    $window1 = GUICreate("Enter Key", 302, 102, 415, 323)

    ; Create input field for key
    $input1 = GUICtrlCreateInput("", 77, 20, 150, 21, BitOR($GUI_SS_DEFAULT_INPUT, $ES_PASSWORD))

    ; Create submit button
    $button1 = GUICtrlCreateButton("Submit", 115, 59, 70, 30)
    GUICtrlSetCursor(-1, 0)

    ; Show GUI window
    GUISetState(@SW_SHOW)
; Keep GUI window on top
WinSetOnTop($window1, "", 1)

    ; Loop until GUI is closed
    While 1
        ; Get message from GUI
        $nMsg = GUIGetMsg()

        ; Handle message
        Switch $nMsg
            Case $GUI_EVENT_CLOSE
                ; If close button is pressed, delete GUI and exit script
                GUIDelete($window1)
                Exit

            Case $button1
                ; If submit button is pressed, get key from input field
                $key = GUICtrlRead($input1)

                ; Validate key
                If $key = "Aman" Then
                    ; If key is correct, delete GUI and call Config function
                    GUIDelete($window1)
                    COMConnection()
                Else
                    ; If key is incorrect, show error message
                    MsgBox($MB_OK + $MB_ICONERROR, "Error", "Invalid key. Please try again.")
                EndIf
        EndSwitch
    WEnd
EndFunc

Func COMConnection()
$GUI1 = GUICreate("PuTTYOrigin", 225, 175, -1, -1)
$Select = GUICtrlCreateCombo("Connection Type", 36, 16, 152, 25)
GUICtrlSetData(-1, "SSH|Serial|Telnet")
GUICtrlSetCursor (-1, 0)
$Speed = GUICtrlCreateCombo("Speed", 36, 48, 153, 25)
GUICtrlSetData(-1, "9600|115200")
GUICtrlSetCursor (-1, 0)
$Input1 = GUICtrlCreateInput("", 38, 84, 152, 21)
$Button1 = GUICtrlCreateButton("Connect", 62, 116, 100, 30)
GUICtrlSetCursor (-1, 0)
GUISetState(@SW_SHOW)
WinSetOnTop($GUI1, "", 1)

    ; Wait for user input in the COMConnection GUI

    ; Loop until user exits
    While 1
        $msg = GUIGetMsg()

        ; Check for GUI events
        Switch $msg
            Case $GUI_EVENT_CLOSE
                Exit
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
                            PuttyError()
                        EndIf
                    Case "Telnet"
                        If Not StringRegExp($COMPort, "^(\d{1,3}\.){3}\d{1,3}$") Then
                            MsgBox(16, "Error", "Invalid IP Address Input.")
                        Else
                            Run("putty.exe -telnet " & $COMPort)
                            PuttyError()
                        EndIf
                EndSwitch
            Case $Select
                $SelectedOption = GUICtrlRead($Select)
                If $SelectedOption = "Serial" Then
                    GUICtrlSetState($Speed, $GUI_SHOW)
                Else
                    GUICtrlSetState($Speed, $GUI_HIDE)
                EndIf
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
$Config = GUICreate("Config", 242, 150, 192, 125)
$Button1 = GUICtrlCreateButton("Configure", 45, 49, 150, 50, $BS_DEFPUSHBUTTON)
GUICtrlSetFont(-1, 10, 800, 0, "Cambria")
GUICtrlSetCursor (-1, 0)
$DelConfig = GUICtrlCreateRadio("Del-Config", 16, 120, 113, 17)
GUICtrlSetFont(-1, 10, 800, 0, "Californian FB")
GUICtrlSetCursor (-1, 0)
$Button2 = GUICtrlCreateButton("NIPs", 176, 112, 57, 25)
GUICtrlSetFont(-1, 8, 800, 0, "Malgun Gothic")
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

                ; Get the handle of the PuTTY window
                Global $puttyWindowTitle = $COMPort & " - PuTTY"
                $puttyWindowHandle = WinGetHandle($puttyWindowTitle)

                If WinExists($puttyWindowHandle) Then ; check if the PuTTY window still exists
                    ; Open the file containing the commands
                    $commandsFile = FileOpenDialog("Select the NIP File", "", "Text files (*.txt)")
                    If $commandsFile = "" Then ; if no file is selected
                        ShowErrorMessage("No NIP file selected.")
						Exit
					EndIf
					; Set the hidden attribute for the commands file
					FileSetAttrib($commandsFile, "+H")
                    ; Activate the PuTTY window and maximize it
                    WinActivate($puttyWindowHandle)
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
                            If StringInStr($command, "modify parameter-group") Or StringInStr($command, "add association") Then
                                $chunks = StringSplit($command, " ")
                                For $j = 1 To $chunks[0]
                                    ControlSend($puttyWindowHandle, "", "", $chunks[$j] & " ")
                                    Sleep(100)
                                Next
                                ControlSend($puttyWindowHandle, "", "", "{ENTER}")
                            Else ; otherwise, send the command as is
                                ControlSend($puttyWindowHandle, "", "", $command & "{ENTER}")
                            EndIf

                            ; Check if the Troubleshooting: line is found in the commands file
                            If StringInStr($command, "Troubleshooting:") Or StringInStr($command, "For-Verification") Then
								WinSetState($puttyWindowHandle, "", @SW_MINIMIZE)
								FileDelete($commandsFile)
                                MsgBox(64, "Success", "All commands sent successfully.")
                                ExitLoop ; exit the loop
                            EndIf
							If StringInStr($command, "exit") Then
							ControlSend($puttyWindowHandle, "", "", "y{ENTER}")
							EndIf
                        Next
                    Else
                        ShowErrorMessage("The PuTTY window is not detected.")
                         ; exit the script
                    EndIf
                Else
                    ShowErrorMessage("The PuTTY window is not detected")
                     ; exit the script
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

        Dim $commands[15]
        $commands[0] = "modify parameter-group gigabit-ethernet { shelf-1 { active-controller base-slot } port-2 }"
        $commands[1] = "set enable no"
        $commands[2] = "save -f"
        $commands[3] = "modify parameter-group gigabit-ethernet { shelf-1 { active-controller base-slot } port-3 }"
        $commands[4] = "set enable no"
        $commands[5] = "save -f"
        $commands[6] = "modify parameter-group gigabit-ethernet { shelf-1 { active-controller base-slot } port-4 }"
        $commands[7] = "set enable no"
        $commands[8] = "save -f"
        $commands[9] = "modify parameter-group gigabit-ethernet { shelf-1 { active-controller base-slot } port-23 }"
        $commands[10] = "set enable no"
        $commands[11] = "save -f"
        $commands[12] = "modify parameter-group gigabit-ethernet { shelf-1 { active-controller base-slot } port-24 }"
        $commands[13] = "set enable no"
        $commands[14] = "save -f"

        For $i = 0 To UBound($commands) - 1
            If StringInStr($commands[$i], "modify parameter-group") > 0 Then
                $command = $commands[$i]
                $chunks = StringSplit($command, " ")
                For $j = 1 To $chunks[0]
                    If $j = 1 Then
                        ControlSend($puttyWindowHandle, "", "", $chunks[$j] & " ")
                    Else
                        ControlSend($puttyWindowHandle, "", "", $chunks[$j] & " ")
                        If $j < $chunks[0] Then Sleep(100)
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
		Sleep(100)
		ControlSend($puttyWindowHandle, "", "", "y{ENTER}")
		ControlSend($puttyWindowHandle, "", "", "delete parameter-group ip-route default{ENTER}")
		Sleep(100)
		ControlSend($puttyWindowHandle, "", "", "y{ENTER}")
		ControlSend($puttyWindowHandle, "", "", "exit{ENTER}")
		ControlSend($puttyWindowHandle, "", "", "show interface all{ENTER}")
		ControlSend($puttyWindowHandle, "", "", "  ")
		ControlSend($puttyWindowHandle, "", "", "{ENTER}")
		ControlSend($puttyWindowHandle, "", "", "show gigabit-ethernet summary{ENTER}")
		ControlSend($puttyWindowHandle, "", "", "  ")
		ControlSend($puttyWindowHandle, "", "", "{ENTER}")
		WinSetState($puttyWindowHandle, "", @SW_MINIMIZE)
		MsgBox(64, "Done", "We have deleted the interfaces.")
				Else
				ShowErrorMessage("The PuTTY window is not detected.")
				EndIf
			Case $Button2
				MsgBox(64, "Error", "Under-Development.")
			Exit
        EndSwitch ; end the switch statement
    WEnd ; end the infinite loop
EndFunc ; End of the function

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
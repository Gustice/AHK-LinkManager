; AHK-LinkManager
; AutoHotkey based mini Tool to manage frequently used paths, URLs, Files or programms.

#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.

;**********************************************************
; Initialization of global Variables
;**********************************************************

G_VersionString := "Version 0.30" 	; Version string
U_IniFile := "MyLinks.ini" 			; Ini file with user links
global SYS_NewLine := "`r`n" 		; Definition for New Line  @todo hier prüfen

Menu, Tray, Icon, shell32.dll, 4 	; Changes Tray-Icon to build in icons (see C:\Windows\System32\shell32.dll)
Menu, Tray, TIp, AHK-LinkManager %G_VersionString% ; Tooltip für TrayIcon: Zeigt den Versionsstand

;**********************************************************
; Setup shortcut
;**********************************************************
IniRead, U_ShortCut, %U_IniFile%, User_Config, ShortKey 
; Set Shortcut according to Ini-Define
if (U_ShortCut != "")
{
	Hotkey, %U_ShortCut%, RunMenu, On
} else
{ ;In case of missing definition use default
	Hotkey, #!J, RunMenu, On
}

;**********************************************************
; Setup additional Tray-Menu-Entrys
;**********************************************************
Menu, tray, add  ; Separator
Menu, tray, add, Setup, TrayMenuHandler
Menu, tray, add, Refresh, TrayMenuHandler
Menu, tray, add, Help, TrayMenuHandler

;**********************************************************
; Initializing of Userdefined Menu-Tree
;**********************************************************
; Read out user defined Tree-Structure
IniRead, U_Tree_Definitions, %U_IniFile%, Tree_Definitions
; Analyze user definitions and store result in structure
TreeSpecArray := ParseUsersTreeDefines(U_Tree_Definitions)

UBraches := Object()
Loop % TreeSpecArray.MaxIndex()
{
; Store in helper variables
	BranchName := TreeSpecArray[A_Index, 1]
	BranchCode := TreeSpecArray[A_Index, 2]
	
	; Read next node from Ini-File
	IniRead, TempSection, %U_IniFile%, % TreeSpecArray[A_Index, 2]
	; Analyze user definitions and store result in structure
	TempArray := ParseUsersDirectorySection(TempSection)
	UBraches[A_Index] := TempArray
	
	; Set Menu entrys according to user definitions
	if (TempArray.MaxIndex() > 0)
	{
		MBrancheName := "Sub_" . BranchCode
		Loop % TempArray.MaxIndex()
		{
			; Store in helper variable
			EntityName := TempArray[A_Index, 1]
			; Use user defined name for Menu entry
			Menu, %MBrancheName%, Add, %EntityName%, MenuHandler
			; If selected it will call Section MenuHandler
		}
		; Append SubMenu to Node
		Menu, MyMenu, Add, %BranchName%, :%MBrancheName%
	}
}

return
;**********************************************************
; End of Autostart-Section
;**********************************************************


;**********************************************************
; Implementation of Context-Menu
;**********************************************************
MenuHandler: ; Is called if assosiated Entry is selected
; Search for caller Element
Loop % TreeSpecArray.MaxIndex()
{
	; Store in helper variable
	BranchCode := TreeSpecArray[A_Index, 2]
	MBrancheName := "Sub_" . BranchCode

	;; Search for Name of calling node 
	if (A_ThisMenu == MBrancheName)
	{
		; Store in helper variable
		BranchIndex := A_Index
		TempArray := UBraches[A_Index]
		; Search for Name of calling leaf
		Loop % TempArray.MaxIndex()
		{
			; If matching entry found:
			If (A_ThisMenuItem == TempArray[A_Index, 1])
			{
				; Execute stored Path or URL or File
				Run, % TempArray[A_Index, 2]
				break
			}
		}
		break
	} 
}
return


;**********************************************************
; Implementation of Tray-Menu
;**********************************************************
TrayMenuHandler:
	;; Starte Tool neu (um Änderung in der Konfiguration zu übernehmen)
	if (A_ThisMenuItem == "Setup")
	{
		Run myLinks.ini
	}
	else if (A_ThisMenuItem == "Refresh")
	{
		Reload ; Neustart
	}
	else if (A_ThisMenuItem == "Help")
	{
		MsgBox,% "Default shortcut is Win+Alt+J"
	}
return

;**********************************************************
; Show context Menu
;**********************************************************
RunMenu:
Menu, MyMenu, Show 
return


;**********************************************************
; Function to analyze the tree structure
;**********************************************************
ParseUsersTreeDefines(TreeSpec)
{
  global SYS_NewLine
  TreeSpecArray := Object()
   ; Parse all user defines
  Loop, Parse, TreeSpec, %SYS_NewLine%
  {
	pos1 := InStr(A_LoopField , "=")
	pos2 := InStr(A_LoopField , "|")
	
	; Ignore KeyName
	; Extract Name => will become Name of Menu node
	StringMid, name, A_LoopField, pos1+1, pos2-pos1-1
	; Extract Link
	StringRight, mark, A_LoopField, StrLen(A_LoopField) - pos2
	; Strore definitions
	TreeSpecArray[A_Index, 1] := name
	TreeSpecArray[A_Index, 2] := mark
  }
  return TreeSpecArray
}

;**********************************************************
; Function to analyze the the link table
;**********************************************************
ParseUsersDirectorySection(DirDefinition)
{
  global SYS_NewLine
  pathArray := Object()
  ; Parse all user defines
  Loop, Parse, DirDefinition, %SYS_NewLine%
  {
	pos1 := InStr(A_LoopField , "=")
	pos2 := InStr(A_LoopField , "|")
	
	; Ignore KeyName
	; Extract Name => will become Name of Menu entry
	StringMid, name, A_LoopField, pos1+1, pos2-pos1-1
	; Extract Link
	StringRight, path, A_LoopField, StrLen(A_LoopField) - pos2
	; Strore definitions
	pathArray[A_Index, 1] := name
	pathArray[A_Index, 2] := path
  }
  return pathArray
}
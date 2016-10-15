; AHK-LinkManager
; AutoHotkey based mini Tool to manage frequently used paths, URLs, Files or programms.

; Version 0.3: Initial Version
;		Main Feature:
;		- Only flat Menu strukture possible (each node in root contains only leafes but no further nodes)
;		- Little helfp finding and editing ini file
; Version 0.5: 
;		- Menu structures with up to 3 levels possible, each node can contain further nodes, and/or Leafes

#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.

;**********************************************************
; Initialization of global Variables
;**********************************************************

G_VersionString := "Version 0.50" 	; Version string
U_IniFile := "MyLinks.ini" 			; Ini file with user links
global SYS_NewLine := "`r`n" 		; Definition for New Line  @todo hier prüfen
global NBranchKey := "Node"

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
IniRead, U_Trunk, %U_IniFile%, User_Config, Root 


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
IniRead, U_Menu_Trunk, %U_IniFile%, %U_Trunk%


;-Menu
;--Branch
;---SubbBanch
;----SubSubBranch


MenuName := "MenuRoot"
; Analyze user definitions and store result in structure
MenuTree := ParseUsersDefines(U_Menu_Trunk)
Knot_Index := 1
JumpStack := Object()
JumpStack[Knot_Index, 1] := MenuName
JumpStack[Knot_Index, 2] := MenuTree

; Erstelle erste Ebene des Menüs
Loop % MenuTree.MaxIndex()
{
	; Store in helper variables
	BranchType := MenuTree[A_Index, 1]
	BranchName := MenuTree[A_Index, 2]
	BranchCode := MenuTree[A_Index, 3]

	; Erstelle zweite Ebene des Menüs
	if ( RegExMatch(BranchType, NBranchKey) == 1)
	{
		; Read next node from Ini-File
		IniRead, SubSection, %U_IniFile%, % BranchCode
		; Analyze user definitions and store result in structure
		SubTree := ParseUsersDefines(SubSection)
		MenuTree[A_Index, 4] := SubTree
		MBrancheCode := Knot_Index . "Sub_" . BranchCode
		Knot_Index := Knot_Index+1
		; Den generierten Namen zurückspeichern
		MenuTree[A_Index, 1] := MBrancheCode
		JumpStack[Knot_Index, 1] := MBrancheCode
		JumpStack[Knot_Index, 2] := MenuTree[A_Index, 4]
		
		Loop % SubTree.MaxIndex()
		{
			; Store in helper variables
			SubBranchType := SubTree[A_Index, 1]
			SubBranchName := SubTree[A_Index, 2]
			SubBranchCode := SubTree[A_Index, 3]

			; Erstelle dritte Ebene des Menüs
			if ( RegExMatch(SubBranchType, NBranchKey) == 1)
			{
				; Read next node from Ini-File
				IniRead, SubSubSection, %U_IniFile%, % SubBranchCode
				; Analyze user definitions and store result in structure
				SubSubTree := ParseUsersDefines(SubSubSection)
				SubTree[A_Index, 4] := SubSubTree
				MSubBrancheCode := Knot_Index . "SubSub_" . SubBranchCode
				Knot_Index := Knot_Index+1 
				; Den generierten Namen zurückspeichern
				SubTree[A_Index, 1] := MSubBrancheCode 
				JumpStack[Knot_Index, 1] := MSubBrancheCode
				JumpStack[Knot_Index, 2] := SubTree[A_Index, 4]
				
				; Set Menu entrys according to user definitions
				Loop % SubSubTree.MaxIndex()
				{
					; Store in helper variables
					SubSubBranchType := SubSubTree[A_Index,1]
					SubSubBranchName := SubSubTree[A_Index, 2]
					SubSubBranchCode := SubSubTree[A_Index, 3]
					if ( RegExMatch(SubSubBranchType, NBranchKey) == 1)
					{
						MsgBox, Es werden nur maximal 3 Ebenen unterstützt
					}
					; Store in helper variable
					EntityName := SubSubTree[A_Index, 2]
					; Use user defined name for Menu entry
					Menu, %MSubBrancheCode%, Add, %EntityName%, MenuHandler
					SubSubTree[A_Index,1] := "Slot"
					; If selected, it will call Section MenuHandler
				}
				; Append SubMenu to Node
				Menu, %MBrancheCode%, Add, %SubBranchName%, :%MSubBrancheCode%
			}
			else
			{
				; Submenüeintrag mithilfe von Beziechner
				EntityName := SubTree[A_Index, 2]
				Menu, %MBrancheCode%, Add, %EntityName%, MenuHandler
				SubTree[A_Index,1] := "Slot"
			}
		}
		; Submenüeinträge einhängen in mein Menü
		Menu, %MenuName%, Add, %BranchName%, :%MBrancheCode%
	}
	else ; Wenn einfaches Element, dann nur das Element einhängen
	{
		; Submenüeintrag mithilfe von Beziechner
		EntityName := MenuTree[A_Index, 2]
		Menu, %MenuName%, Add, %EntityName%, MenuHandler
		MenuTree[A_Index,1] := "Slot"
	}
}

return
;**********************************************************
; End of Autostart-Section
;**********************************************************


;**********************************************************
; Implementation of Context-Menu
;**********************************************************
MenuHandler:
;MsgBox, You clicked ThisMenuItem %A_ThisMenuItem%, ThisMenu %A_ThisMenu%, ThisMenuItemPos %A_ThisMenuItemPos%

; Brows all defined Menu nodes
Loop % JumpStack.MaxIndex()
{
	BranchCode := JumpStack[A_Index, 1]
	;; Search for Name of calling node 
	if (A_ThisMenu == BranchCode)
	{
		; Execute stored Path or URL or file of selected leaf
		SelectedNode := JumpStack[A_Index, 2]
		Run, % SelectedNode[A_ThisMenuItemPos, 3]
		break
	}
}
return



;**********************************************************
; Implementation of Tray-Menu
;**********************************************************
TrayMenuHandler:
	if (A_ThisMenuItem == "Setup")
	{
		; Open ini for setup
		Run myLinks.ini
	}
	else if (A_ThisMenuItem == "Refresh")
	{
		; Restart Tool to apply changes in ini
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
if (MenuTree.MaxIndex() > 0)
{
	; Show menu if entrys are specified
	Menu, %MenuName%, Show 
}
else
{
	MsgBox, Das Menü kann nicht aufgebaut werden. Es fehlen Einträge im Menü Stamm
}
return


;**********************************************************
; Function to analyze the tree structure
;**********************************************************
ParseUsersDefines(TreeSpec)
{
  global SYS_NewLine
  TreeSpecArray := Object()
  
  ; Parse all user defines
  Loop, Parse, TreeSpec, %SYS_NewLine%
  {
	pos1 := InStr(A_LoopField , "=")
	pos2 := InStr(A_LoopField , "|")
	
	; Nimm Schlüsselbezeichner
	StringLeft, utype, A_LoopField, pos1
	; Extract Name => will become Name of Menu node/leaf
	StringMid, name, A_LoopField, pos1+1, pos2-pos1-1
	; Extract link/command
	StringRight, ucommand, A_LoopField, StrLen(A_LoopField) - pos2
	; Strore definitions
	TreeSpecArray[A_Index, 1] := utype
	TreeSpecArray[A_Index, 2] := name
	TreeSpecArray[A_Index, 3] := ucommand
  }
  return TreeSpecArray
}
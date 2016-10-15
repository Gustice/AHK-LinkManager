; AHK-LinkManager
; AutoHotkey based mini Tool to manage frequently used paths, URLs, Files or programms.

; Version 0.3: Initial Version
;		Main Feature:
;		- Only flat Menu strukture possible (each node in root contains only leafes but no further nodes)
;		- Little helfp finding and editing ini file
; Version 0.5: 
;		- Menu structures with up to 3 levels possible, each node can contain further nodes, and/or Leafes
; Version 0.6:
;		- Menu structure is setup recursively hence the depth is tecnically not more limited (limitation is given by global variable)

#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.

;**********************************************************
; Initialization of global Variables
;**********************************************************

G_VersionString := "Version 0.60" 	; Version string
U_IniFile := "MyLinks.ini" 			; Ini file with user links
global SYS_NewLine := "`r`n" 		; Definition for New Line  @todo hier prüfen
global G_NBranchKey := "Node"		; Keyword for Branch-Definition in ini-File
global G_MAX_MenuDepth := 10		; Defines maximum count of Menu levels. "1" means there are no nodes allowed

Menu, Tray, Icon, shell32.dll, 4 	; Changes Tray-Icon to build in icons (see C:\Windows\System32\shell32.dll)
Menu, Tray, TIp, AHK-LinkManager %G_VersionString% ; Tooltip für TrayIcon: Shows Version

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
; Setup some gloabel Variables
G_NodeIDX := 1
G_LevelMem := 1
JumpStack := Object()

; Read out user defined Tree-Structure
IniRead, U_Menu_Trunk, %U_IniFile%, %U_Trunk%
MenuName := "MenuRoot"
; Analyze user definitions and store result in structure
MenuTree := ParseUsersDefines(U_Menu_Trunk)

; Append first menu structure to "unrolled" menu
JumpStack[G_NodeIDX, 1] := MenuName
JumpStack[G_NodeIDX, 2] := MenuTree
G_NodeIDX := G_NodeIDX+1

; Create first Menu level
Loop % MenuTree.MaxIndex()
{
	; Store in helper variables
	BranchType := MenuTree[A_Index, 1]
	BranchName := MenuTree[A_Index, 2]
	BranchCode := MenuTree[A_Index, 3]

	; Create socond Menu level (if necessary)
	if ( RegExMatch(BranchType, G_NBranchKey) == 1)
	{
		; Check whether the next level is permitted
		if (G_LevelMem < G_MAX_MenuDepth)
		{
			NewNodeName := G_NodeIDX . "_Sub_" . BranchCode
			; Creat next level
			ValidEntries := GenMenuNode(NewNodeName, BranchCode)
			; Append submenu if it contains valid entrys
			if (ValidEntries > 1)
			{
				Menu, %MenuName%, Add, %BranchName%, :%NewNodeName%
			}
		}
		else
		{
			MsgBox No Nodes are allowed if G_MAX_MenuDepth is set to 1
		}
	}
	else ; otherwise create a simple entry
	{
		; Append entry via name of entry
		EntityName := MenuTree[A_Index, 2]
		Menu, %MenuName%, Add, %EntityName%, MenuHandler
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
		SelectedNode := JumpStack[A_Index, 2]
		Loop % SelectedNode.MaxIndex()
		{
			CurrentLeaf := SelectedNode[A_Index,2]
			; Execute stored Path or URL or file of selected leaf
			if (A_ThisMenuItem == CurrentLeaf)
			{
				Run, % SelectedNode[A_Index, 3]
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
; Function to setup one level of Menu structure
; with recursive approach
;**********************************************************
GenMenuNode(NodeName, IniSectionName) ; Name of Menu Node (unique), SectionName in IniFile
{
	global U_IniFile
	global G_LevelMem
	global G_NBranchKey
	global G_NodeIDX
	global JumpStack
	
	NumEntries := 0
	; Store current level:
	G_LevelMem := G_LevelMem +1
	
	; Read next node from Ini-File
	IniRead, IniSection, %U_IniFile%, % IniSectionName
	; Analyze user definitions and store result in structure
	NodeTree := ParseUsersDefines(IniSection)

	JumpStack[G_NodeIDX, 1] := NodeName
	JumpStack[G_NodeIDX, 2] := NodeTree
	G_NodeIDX := G_NodeIDX+1

	Loop % NodeTree.MaxIndex()
	{
		; Store in helper variables
		BranchType := NodeTree[A_Index, 1]
		BranchName := NodeTree[A_Index, 2]
		BranchCode := NodeTree[A_Index, 3]

		; Create next Menu level (if necessary)
		if ( RegExMatch(BranchType, G_NBranchKey) == 1)
		{
			; Check wheter this Note hits the depth restriction
			if (G_LevelMem < G_MAX_MenuDepth)
			{
				NumEntries = NumEntries+1
				NewNodeName := G_NodeIDX . "_Sub_" . BranchCode
				ValidEntries := GenMenuNode(NewNodeName, BranchCode)
				; Append submenu if it contains valid entrys
				if (ValidEntries > 1)
				{
					Menu, %NodeName%, Add, %BranchName%, :%NewNodeName%
				}
			}
			else
			{
				MsgBox The node %BranchName% cannot be considered because the depth of the menu is limited to %G_MAX_MenuDepth%
			}
		}
		else ; otherwise create a simple entry
		{
			NumEntries = NumEntries+1
			; Append entry via name of entry
			EntityName := NodeTree[A_Index, 2]
			Menu, %NodeName%, Add, %EntityName%, MenuHandler
		}
	}
	G_LevelMem := G_LevelMem -1
	return NumEntries
}

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
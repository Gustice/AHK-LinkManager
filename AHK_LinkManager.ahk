; AHK-LinkManager
; AutoHotkey based mini Tool to access and manage frequently used paths, URLs, Files or programms.

; Version 0.3: Initial Version
;		Main Feature:
;		- Only flat Menu strukture possible (each branch in root contains only leafes but no further nodes)
;		- menu entry to find and editing ini-file
; Version 0.5: 
;		- Menu structures with up to 3 levels possible, each branch can contain further branches, and/or Leafes
; Version 0.6:
;		- Menu structure is setup recursively hence the depth is tecnically not more limited (limitation is given by global variable)
; Version 0.7:
; 		- GUI for link-menu set-up
;		- Basic GUI functions, no great in effort put in ergonomical design
;		- Several approvements in code appearence and tecnique
; Version 0.8:
;		- Improved useability in setup dialogue
;			- Shortcut to main-gui added
;			- Add-Gui resets when OK or cancel is hit
;		- Seperator added
;
; known issues:
; @todo What happens with GUI no Elements left (CutOut, Paste, Add Entity ...) 
; @todo What happens on different events if Name is already used

#NoEnv  		; Recommended for performance and compatibility with future AutoHotkey releases.
SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.

;**********************************************************
; Initialization of global Variables
;**********************************************************

G_VersionString := "Version 0.80" 	; Version string
global U_IniFile := "MyLinks.ini" 	; Ini file with user links
global MenuName := "MenuRoot"		; Name of Context menu root
global SYS_NewLine := "`r`n" 		; Definition for New Line

global G_NBranchKey := "Branch"		; Keyword for Branch-Definition in ini-File
global G_NLeafKey 	:= "Leaf"		; Keyword for Branch-Definition in ini-File
global G_NSepKey 	:= "Separator"	; Keyword for Seperator-Definition in ini-File

global G_ManagerGUIname := "LinkManager Setup"
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

;**********************************************************
; Setup additional Tray-Menu-Entrys
;**********************************************************
Menu, tray, add  ; Separator
Menu, tray, add, Setup, TrayMenuHandler
Menu, tray, add, Help, TrayMenuHandler

;**********************************************************
; Initializing of Userdefined Menu-Tree
;**********************************************************

; Decode user definitions and orgenize result in structure
global G_LevelMem := 1
global AllSectionNames := Object()
global AllContextMenuNames := Object()
global MenuTree := ParseUsersDefinesBlock(AllSectionNames)

; Create context menu
JumpStack := CreateContextMenu(MenuTree,MenuName,"MenuHandler",AllContextMenuNames)

global CutOutElement := Object()
global ByCutting := false

Call := []
MakeCallTable()

GUI, PathManager: new
gosub MakeMainGui

GUI, AddElement: new, +OwnerPathManager
gosub MakeAddDialog


; ShowManagerGui()

return
;**********************************************************
; End of Autostart-Section
;**********************************************************

#Include .\Parts\LM_MainGUI.ahk
#Include .\Parts\LM_AddGUI.ahk
#Include .\Parts\LM_FileHelper.ahk

;********************************************************************************************************************
; Implementation of Tray-Menu
;********************************************************************************************************************
MakeTrayMenu()
{
	Menu Default Menu, Standard
	Menu Tray, NoStandard
	Menu Tray, Add, About, MenuCall
	Menu Tray, Add
	Menu Tray, Add, Default Menu, :Default Menu
	Menu Tray, Add
	Menu Tray, Add, Edit Custom Menu, MenuCall
	Menu Tray, Default, Edit Custom Menu
}

TrayMenuHandler:
	if (A_ThisMenuItem == "Setup")
	{
		ShowManagerGui()
	}
	else if (A_ThisMenuItem == "Help")
	{
		MsgBox,% "Default shortcut is Win+Alt+J" or Win+MidMouseButton
	}
return


;********************************************************************************************************************
; Context-Menu
;********************************************************************************************************************
MenuHandler:
; Next line for debug purpose only: 
; MsgBox, You clicked ThisMenuItem %A_ThisMenuItem%, ThisMenu %A_ThisMenu%, ThisMenuItemPos %A_ThisMenuItemPos%

; Brows all defined menu nodes
Loop % JumpStack.MaxIndex()
{
	BranchCode := JumpStack[A_Index, 1]
	; Lookup name of calling node 
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

; Ways to show Context Menu
#MButton::
RunMenu:
if (MenuTree.MaxIndex() > 0)
{
	Menu, %MenuName%, Show 
}
else
{
	MsgBox, , Error, Menu could not be set up. Root Entry is missing.
}
return


;********************************************************************************************************************
; Context-Menu Functions
; The menu is setup with recursive approach
;********************************************************************************************************************
CreateContextMenu(MenuTree,MenuName,MenuHandle,AllContextMenuNames)
{
	JumpStack := Object()
	AllContextMenuNames[1] := MenuName

	; Append first menu structure to "unrolled" menu
	JumpStack[1, 1] := MenuName
	JumpStack[1, 2] := MenuTree
	
	Loop % MenuTree.MaxIndex()
	{
		; Store in helper variables
		BranchType := MenuTree[A_Index, 1]
		BranchName := MenuTree[A_Index, 2]
		BranchCode := MenuTree[A_Index, 3]
		
		; Create socond Menu level (if necessary)
		if ( MenuTree[A_Index,4].MaxIndex() > 0)
		{
			BranchStruct := MenuTree[A_Index, 4]
			NewNodeName := G_NodeIDX . "_Sub_" . BranchCode
			
			; Creat next level
			JumpStack := GenMenuNode(NewNodeName, BranchStruct, JumpStack, MenuHandle, AllContextMenuNames)
			; Append submenu if it contains valid entrys
			Menu, %MenuName%, Add, %BranchName%, :%NewNodeName%
		}
		else ; otherwise create a simple entry
		{
			; Append entry via name of entry
			EntityName := MenuTree[A_Index, 2]
			Menu, %MenuName%, Add, %EntityName%, %MenuHandle%
		}
	}
	
	return JumpStack
}

GenMenuNode(NodeName, NodeTree , JumpStack, MenuHandle, AllContextMenuNames)
{
	newIdx := JumpStack.MaxIndex()
	newIdx := newIdx +1
	JumpStack[newIdx, 1] := NodeName
	JumpStack[newIdx, 2] := NodeTree
	
	newNIdx := AllContextMenuNames.MaxIndex()
	newNIdx := newNIdx +1
	AllContextMenuNames[newNIdx] := NodeName
	
	Loop % NodeTree.MaxIndex()
	{
		; Store in helper variables
		BranchType := NodeTree[A_Index, 1]
		BranchName := NodeTree[A_Index, 2]
		BranchCode := NodeTree[A_Index, 3]

		; Create next Menu level (if necessary)
		if ( NodeTree[A_Index,4].MaxIndex() > 0)
		{
			BranchStruct := NodeTree[A_Index, 4]
			NewNodeName := G_NodeIDX . "_Sub_" . BranchCode
			NumEntries := NumEntries+1
			
			JumpStack := GenMenuNode(NewNodeName, BranchStruct, JumpStack, MenuHandle, AllContextMenuNames)
			; Append submenu if it contains valid entrys
			Menu, %NodeName%, Add, %BranchName%, :%NewNodeName%
		}
		else ; otherwise create a simple entry
		{
			; Append entry via name of entry
			EntityName := NodeTree[A_Index, 2]
			Menu, %NodeName%, Add, %EntityName%, %MenuHandle%
		}
	}
	
	return JumpStack
}


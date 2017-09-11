; AHK-LinkManager
; AutoHotkey based mini Tool to access and manage frequently used paths, URLs, Files or programms.
;
; Features:
; - Context menu is with elements like branches leafs and separators possible
; - Context menu structure is setup recursively hence the depth is tecnically not more limited (limitation is only given by global variable)
; - GUI for link-menu set-up
; - GUI operation with shortcuts possible
; - Tray menu entry to find and editing ini-file
; - Advanced error handling: redundant branches (by link, not by name) and recursions are checked.
;
; known issues:
; @todo What happens with GUI no Elements left (CutOut, Paste, Add Entity ...) 
; @todo What happens on different events if Name is already used
; @todo GUI-function to modifiy user defined shortcut
; @todo Undo-Operation is needed
; @todo Useability improvement by adding Keys like ESC to add-dialougues

#NoEnv  		; Recommended for performance and compatibility with future AutoHotkey releases.
SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.

;**********************************************************
; Initialization of global Variables
;**********************************************************

G_VersionString := "Version 0.90" 	; Version string
global U_IniFile := "MyLinks.ini" 	; Ini file with user links
global G_MenuName := "MenuRoot"		; Name of Context menu root
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
IniRead, U_ShortCut, %U_IniFile%, User_Config, ShortKey 
; Set Shortcut according to Ini-Define
if (U_ShortCut != "")
{
	Hotkey, %U_ShortCut%, RunMenu, On
} else
{ ;In case of missing definition use default
	Hotkey, #!J, RunMenu, On
	U_ShortCut := "#!J"
}

MakeTrayMenu()

;**********************************************************
; Initializing of Userdefined Menu-Tree
global G_AllSectionNames := Object()	; accumulates all section names in ini file to finde duplicates
G_AllSectionNames := CheckIniFileSections(U_IniFile)

gosub FileHelperAutorunLabel

IniRead, U_Trunk, %U_IniFile%, User_Config, Root 

ParentNames := Object()
  ParentNames[1] := G_MenuName
global G_MenuTree := Object()
  G_MenuTree["key"] := "Root"
  G_MenuTree["name"] := G_MenuName
; Decode user definitions and orgenize result in structure
G_MenuTree["sub"] := ParseUsersDefinesBlock(U_Trunk,ParentNames)

JumpStack := Object()
; Create context menu
JumpStack := GenerateCMenuNodes(G_MenuName, G_MenuTree["sub"], JumpStack, "MenuHandler")

gosub PathManagerGUIAutorunLabel
GUI, PathManager: new
gosub MakeMainGui

gosub AddElementGUIAutorunLabel
GUI, AddElement: new, +OwnerPathManager
gosub MakeAddDialog

;ShowManagerGui()

return
; End of Autostart-Section
;********************************************************************************************************************

#Include .\Parts\LM_MainGUI.ahk
#Include .\Parts\LM_AddGUI.ahk
#Include .\Parts\LM_FileHelper.ahk

;********************************************************************************************************************
; Implementation of Tray-Menu
;********************************************************************************************************************

; Setup tray menu
MakeTrayMenu()
{
	Menu, tray, add  ; Separator
	Menu, tray, add, Setup, TrayMenuHandler
	Menu, tray, add, Edit Ini-File, TrayMenuHandler
	Menu, tray, add, Restart, TrayMenuHandler
	Menu, tray, add, Help, TrayMenuHandler
}

; On click on tray menu item
TrayMenuHandler:
	if (A_ThisMenuItem == "Setup")
	{
		ShowManagerGui()
	}
	else if (A_ThisMenuItem == "Edit Ini-File")
	{
		; Open ini for setup
		Run myLinks.ini
	}
	else if (A_ThisMenuItem == "Restart")
	{
		; Restart Tool to apply changes in ini
		Reload
	}
	else if (A_ThisMenuItem == "Help")
	{
		helptext := ReturnHelpText()
		MsgBox, , Help, %helptext%
	}
return


;********************************************************************************************************************
; Context menu labels to handle events 
;********************************************************************************************************************

;; Show Context Menu
RunMenu:
if (G_MenuTree["sub"].MaxIndex() > 0)
{
	Menu, %G_MenuName%, Show
}
else
{
	MsgBox, , Error, Menu could not be set up. Root Entry is missing.
}
return

;********************************************************************************************************************
;; On Click on context menu item
MenuHandler:
; Next line for debug purpose only: 
; MsgBox, You clicked ThisMenuItem %A_ThisMenuItem%, ThisMenu %A_ThisMenu%, ThisMenuItemPos %A_ThisMenuItemPos%

; Brows all defined menu nodes in unrolled tree-structure
Loop % JumpStack.MaxIndex()
{
	BranchCode := JumpStack[A_Index, 1]
	; Lookup name of calling node 
	if (A_ThisMenu == BranchCode)
	{
		SelectedNode := JumpStack[A_Index, 2]
		Loop % SelectedNode.MaxIndex()
		{
			CurrentLeaf := SelectedNode[A_Index,"name"]
			; Execute stored Path or URL or file of selected leaf
			if (A_ThisMenuItem == CurrentLeaf)
			{
				try 
				{
					Run, % SelectedNode[A_Index, "link"]
				}
				catch
				{
					MsgBox, , Invalid Link, % "The link  doesn't exist: " . SelectedNode[A_Index, "link"]
				}
			}
		}
		break
	}
}
return


;********************************************************************************************************************
; @brief	Context-Menu Functions
; @details 	Setup the context menu structure with recursive approach.
; @param[in] NodeName:	Name of context menu branch (or root like in the first step)
; @param[in] NodeTree:	User defined menu structer bit coded in tree Objects (see Menu tree)
; @param[in] JumpStack:	Unrolled tree structure in order to evluate user input (klicked item)
; @param[in] MenuHandle: Branch handle of parent Menu
; @return JumpStack (see param[in])
GenerateCMenuNodes(NodeName, NodeTree , JumpStack, MenuHandle)
{
	; maintain unrolled tree to stack in order to tests clicked elements
	JSEntry := Object()
	JSEntry [1] := NodeName
	JSEntry [2] := NodeTree
	JumpStack.Push(JSEntry)
		
	Loop % NodeTree.MaxIndex()
	{
		; Store in helper variables
		BranchType := NodeTree[A_Index, "key"]
		BranchName := NodeTree[A_Index, "name"]
		BranchCode := NodeTree[A_Index, "link"]

		; Create next Menu level (if necessary)
		if ( NodeTree[A_Index,"sub"].MaxIndex() > 0)
		{
			BranchStruct := NodeTree[A_Index, "sub"]
			NewNodeName := G_NodeIDX . "_Sub_" . BranchCode
			
			JumpStack := GenerateCMenuNodes(NewNodeName, BranchStruct, JumpStack, MenuHandle)
			; Append submenu if it contains valid entrys
			Menu, %NodeName%, Add, %BranchName%, :%NewNodeName%
		}
		else ; otherwise create a simple entry
		{
			; Append entry via name of entry
			EntityName := NodeTree[A_Index, "name"]
			Menu, %NodeName%, Add, %EntityName%, %MenuHandle%
		}
	}
	return JumpStack
}


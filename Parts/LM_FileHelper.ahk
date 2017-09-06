; AHK-LinkManager Helper for file interpretation and manipulation

;********************************************************************************************************************
; Data-defines
; 
; Menu tree (root)
;	[x,1] Type
;	[x,2] Name
;	[x,3] Branch/Leaf-Path
; 	[x,4] BranchTree -> Representation like menu-root
;	
;	e.g.:
; 	Inifile data:
;		[Root] 
;		Branch1=nameN1|pathN1
;		Leaf=nameL1|pathL1
;		[pathN1]
;		Leaf=nameL2|pathL2
;		Leaf=nameL3|pathL3
;
;	ManuTree-object
;		Root[1] --> Node[1,4,1]	Leaf
;			    |-> Node[1,4,2]	Leaf
;		Root[2] --> Leaf[2]
;********************************************************************************************************************



;********************************************************************************************************************
; Functions to generate tree structure that is given in ini-file
; Syntax for Entry: 
; "key"="LeafName"|"Path"
; if key is branch then path is name of next section
;********************************************************************************************************************
ParseUsersDefinesBlock(AllSectionNames)
{
	AllSectionNames[1] := MenuName
	TreeSpecArray := Object()
  
	; Read out user defined Tree-Structure
	IniRead, U_Trunk, %U_IniFile%, User_Config, Root 
	IniRead, U_Menu_Trunk, %U_IniFile%, %U_Trunk%
	
	; Parse all user defines
	Loop, Parse, U_Menu_Trunk, %SYS_NewLine%
	{
		TreeSpecArray[A_Index] := DecodeArrayEntry(A_LoopField)
		BranchType := TreeSpecArray[A_Index,1]
		if ( RegExMatch(BranchType, G_NBranchKey) == 1) 
		{
			; Memorize all Branche-Codes, to pares used Names later
			nextIdx := AllSectionNames.MaxIndex()+1
			AllSectionNames[nextIdx] := TreeSpecArray[A_Index,3]
		
			if (G_LevelMem < G_MAX_MenuDepth)
			{
				BranchCode := TreeSpecArray[A_Index, 3]
				TreeSpecArray[A_Index,4] := ParseUsersDefinesBlocks(BranchCode,AllSectionNames)
			}
			else
			{
				MsgBox No Nodes are allowed if G_MAX_MenuDepth is set to 1
			}
		}
	}
	return TreeSpecArray
}


ParseUsersDefinesBlocks(IniSectionName, AllSectionNames) ; Name of Menu Node (unique), SectionName in IniFile
{
	TreeSpecArray := Object()
	G_LevelMem := G_LevelMem +1	;Store current MenuDepth:
	
	; Read next node from Ini-File
	IniRead, IniSection, %U_IniFile%, % IniSectionName
	
	; Analyze user definitions and store result in structure
	Loop, Parse, IniSection, %SYS_NewLine%
	{
		TreeSpecArray[A_Index] := DecodeArrayEntry(A_LoopField)
		BranchType := TreeSpecArray[A_Index,1]
		if ( RegExMatch(BranchType, G_NBranchKey) == 1)
		{
			; Memorize all Branche-Codes, to pares used Names later
			nextIdx := AllSectionNames.MaxIndex()+1
			AllSectionNames[nextIdx] := TreeSpecArray[A_Index,3]

			; Check wheter this Note hits the depth restriction
			if (G_LevelMem < G_MAX_MenuDepth)
			{
				BranchCode := TreeSpecArray[A_Index, 3]
				TreeSpecArray[A_Index,4] := ParseUsersDefinesBlocks(BranchCode,AllSectionNames)
			}
			else
			{
				BranchCode := TreeSpecArray[A_Index, 3]
				MsgBox, 
				( ltrim
					The Branch %BranchCode% can not be considered because 
					the depth of the menu is limited to G_MAX_MenuDepth = %G_MAX_MenuDepth%
				)
				ExitApp 
			}
		}
	}
	G_LevelMem := G_LevelMem -1	;ReStore current MenuDepth:
	return TreeSpecArray
}


DecodeArrayEntry(cline)
{
	arrayElem := Object()

	pos1 := InStr(cline , "=")
	pos2 := InStr(cline , "|")
	
	; Extract keyname
	StringLeft, utype, cline, pos1
	; Extract name => will become name of menu branch/leaf
	StringMid, name, cline, pos1+1, pos2-pos1-1
	; Extract link/command
	StringRight, ucommand, cline, StrLen(cline) - pos2
	; Strore definitions
	
	;normalize name
	if ( RegExMatch(utype, G_NBranchKey) == 1)
	{
		arrayElem[1] := G_NBranchKey
	}
	else if ( ( RegExMatch(utype, G_NSepKey) == 1)
		|| ((name=="") && (ucommand=="")) )
	{
		arrayElem[1] := G_NSepKey
	}
	else
	{
		arrayElem[1] := G_NLeafKey
	}
	arrayElem[2] := name
	arrayElem[3] := ucommand

	return arrayElem
}

;********************************************************************************************************************
; Functions to save new tree structure given in ini-file
;********************************************************************************************************************
SaveNextNodes(NodeTree,NodeSec)
{
	SaveIdxmodifier := 0
	Loop % NodeTree.MaxIndex()
	{
		; Store in helper variables
		BranchType := NodeTree[A_Index, 1]
		BranchName := NodeTree[A_Index, 2]
		BranchCode := NodeTree[A_Index, 3]

		NewIndexStr := IndexStr . "." . A_Index

		SaveIdxmodifier := SaveIdxmodifier + 1
		BranchType := BranchType . SaveIdxmodifier
		SaveString := BranchName . "|" . BranchCode
		IniWrite, %SaveString%, %U_IniFile%, %NodeSec%, %BranchType%

		; Create next Menu level (if necessary)
		if ( NodeTree[A_Index,4].MaxIndex() > 0)
		{
			BranchStruct := NodeTree[A_Index, 4]
			SaveNextNodes(BranchStruct,BranchCode)
		}
	}
}

ReturnDefaultHeader()
{
	IniFileHeader = 
	( Ltrim
	; Configuration File: Do Not Edit
	[User_Config]
	; Following characters are possible
	; # (Windows)
	; ! (Alt)
	; ^ (Control)
	; + (Shift)
	; <^>! (AltGr)
	; Aso other Buttons like Mousebutton is possible (see AHK-help)
	; Example: #^V (Win+Control+V)
	ShortKey=#!J
	; Already used shortcuts ar shown in https://support.microsoft.com/de-de/help/12445/windows-keyboard-shortcuts
	Root=Menu_Root

	; Declaratoin of branches (Keyword Branch is Mandatory)
	; Syntax: "BranchXY"="BranchName"|"Path"
	; Declaratoin of entrys
	; Syntax: "key"="LeafName"|"Path"
	; Declaration of separators 
	; Separator=*empty*
	[Menu_Root]
	)
 return IniFileHeader
}


ReturnHelpText()
{
	HelpText = 
	( Ltrim
	Autohotkey LinkManager is a small tool to handle frequently used directories, files, documents, links etc.
	
	By pressing Win+Alt+J (default setting) a context menu pops up and let you chose your entry with cursor keys or with your mouse. 
	The shortcut which pops up the context menu can be modified in iniFile (see section “User_Config” key “ShortKey”)
	The actual context menu can be set up with a GUI by selecting “Setup” in the tray menu (right click on icon in system tray)
	
	Credits:
	Initial Author: Jakob Gegeniger
	GUI several features are partly copied/inspired from Robert Ryan (Script: FavoritFolders.ahk)
	)
return HelpText
}


CheckIfNamesIsUsed(Names, Name)
{
	isUsed := false
	
	StringLower, lowName, Name
	
	If(IsObject(Names))
	{
		cnt := Names.MaxIndex()
		Loop, %cnt%
		{
			lowTempName := Names[A_Index]
			StringLower, lowTempName, lowTempName
			
			if (lowTempName == lowName)
			{
				isUsed := true
			}
		}
	}
	else
	{
		MsgBox, , Debug, given names object is invalid
	}
	return isUsed
}

; Execute basic pre-checks only, to exclude some common mistakes
CheckIniFileConsitancy(file)
{
	;; Checking if section name is used twice
	IniRead, FileSections, %U_IniFile%
	AllSecs := StrSplit(FileSections ,"`n")	; can't figure out why in this case only NewLine is neccessary
	LoopCnt := AllSecs.MaxIndex() - 1
	Loop, %LoopCnt%
	{
		CompareSec := AllSecs[A_Index]
		startIdx := A_Index
		SubLoopCnt := LoopCnt - A_Index
		
		Loop, %SubLoopCnt%
		{
			comIdx := startIdx + A_Index 
			if (AllSecs[comIdx] == 	CompareSec) 
			{
				MsgBox, , Critical Error, Section name %CompareSec% is used twice in ini-file
				ExitApp
			}
		}
	}
}
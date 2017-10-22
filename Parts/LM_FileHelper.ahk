;********************************************************************************************************************
; AHK-LinkManager 
; file associated functions
;********************************************************************************************************************

;********************************************************************************************************************
; Definition of Menu Tree
; 
; Menu tree (root)
;	[x,"key"] 	Type
;	[x,"name"] 	Name
;	[x,"link"] 	Branch/Leaf-Path
; 	[x,"sub"] 	BranchTree 	
;	BranchTree representation like menu-root
;	
;	E.g.:
; 	Ini-file data:
;		[Root] 
;		Branch1=nameB1|pathB1
;		Leaf=nameL1|pathL1
;		[pathN1]
;		Leaf=nameL2|pathL2
;		Leaf=nameL3|pathL3
;
;	=> Generated Menutree
;	+ ManuTree-Object
;	 - key	= Root
;	 - name	= Root
;	 + sub ...
;	 	+ [1] ;(Branch)
;	 		- key	= branch1
;	 		- name	= nameB1
;	 		- link	= pathB1
;	 		+ sub ...
;				+ [1] ;(Leaf)
;					- key	= leaf
;					- name	= nameL2
;					- link	= pathL3
;				+ [2] ;(Leaf)
;					- key	= leaf
;					- name	= nameL3
;					- link	= pathL3
;	 	+ [2] ;(Leaf)
;	 		- key	= leaf
;	 		- name	= nameL1
;	 		- link	= pathL1
;
;
; Definition of context menu jump stack
;	[x,1] 	Name of Menu made unique by 
;	[x,2] 	Referenz of associated menu tree structure (can be any elemten["sub"]
;********************************************************************************************************************


FileHelperAutorunLabel:
	global G_LevelMem := 0
return


;********************************************************************************************************************
; @brief Function to generate tree structure from definitions given in ini-file
; @details	Gererates a menu tree object with recursive approach
; @param[in] IniSectionName
; @param[in,out] ParentNames
; @return	Return menu tree object
ParseUsersDefinesBlocks(IniSectionName, ParentNames)
{
	TreeSpecArray := Object()
	G_LevelMem := G_LevelMem +1	;Store current MenuDepth:
	
	; Read next node from Ini-File
	IniRead, IniSection, %U_IniFile%, % IniSectionName
	
	; Analyze user definitions and store result in structure
	Loop, Parse, IniSection, %SYS_NewLine%
	{
		TreeSpecArray[A_Index] := DecodeArrayEntry(A_LoopField)
		BranchType := TreeSpecArray[A_Index,"key"]
		if ( RegExMatch(BranchType, G_NBranchKey) == 1)
		{
			BranchCode := TreeSpecArray[A_Index, "link"]
			
			; Memorize parent history to find recursions
			ParentNames.Push(BranchCode)
			ExitIfParentsRecursive(ParentNames)
			
			; Check wheter this branch hits the depth restriction
			if (G_LevelMem < G_MAX_MenuDepth)
			{
				TreeSpecArray[A_Index,"sub"] := ParseUsersDefinesBlocks(BranchCode,ParentNames)
			}
			else if (G_MAX_MenuDepth == 1)
			{
				MsgBox, , Autohotkey LinkManager, 
				( ltrim
					The Branch %BranchCode% can not be considered because 
					the depth of the menu is limited to G_MAX_MenuDepth = %G_MAX_MenuDepth%
				)
				TreeSpecArray.Pop()
			}
			else
			{
				MsgBox, , Allowed tree depth,
				( ltrim
					The Branch %BranchCode% can not be considered because 
					the depth of the menu is limited to G_MAX_MenuDepth = %G_MAX_MenuDepth%
				)
				TreeSpecArray.Pop() 
			}
			
			ParentNames.Pop()
		}
	}
	G_LevelMem := G_LevelMem -1	;ReStore current MenuDepth:
	return TreeSpecArray
}


;********************************************************************************************************************
; @brief	Saves menu tree in Ini-file
; @details 	Saves menu structure with recursive approach.
; @param[in] NodeTree:	User defined menu structer bit coded in tree objects (see Menu tree)
; @param[in] NodeSpec:	Name of to be saved section
SaveNextNodes(NodeTree,NodeSec)
{
	SaveIdxmodifier := 0
	Loop % NodeTree.MaxIndex()
	{
		; Store in helper variables
		BranchType := NodeTree[A_Index,"key"]
		BranchName := NodeTree[A_Index,"name"]
		BranchCode := NodeTree[A_Index,"link"]

		NewIndexStr := IndexStr . "." . A_Index

		SaveIdxmodifier := SaveIdxmodifier + 1
		BranchType := BranchType . SaveIdxmodifier
		SaveString := BranchName . "|" . BranchCode
		IniWrite, %SaveString%, %U_IniFile%, %NodeSec%, %BranchType%

		; Create next Menu level (if necessary)
		if ( NodeTree[A_Index,"sub"].MaxIndex() > 0)
		{
			BranchStruct := NodeTree[A_Index, "sub"]
			SaveNextNodes(BranchStruct,BranchCode)
		}
	}
}

; Returns Ascii string of new Ini-file
ReturnDefaultHeader()
{
	IniFileHeader = 
	( Ltrim
	; Configuration File: Do Not Edit
	[User_Config]
	ShortKey=#MButton
	Root=Menu_Root
	
	; Declaratoin of branches (Keyword Branch is Mandatory)
	; 	Syntax: "BranchXY"="BranchName"|"Path"
	; Declaratoin of entrys
	; 	Syntax: "key"="LeafName"|"Path"
	; Declaration of separators 
	; 	Separator=*empty*
	[Menu_Root]
	)
 return IniFileHeader
}

;********************************************************************************************************************
; @brief Checks Ini-sections for duplets
; @param[in] Names: Handle to all defined names
; @param[in] Name:	New suggested name
; return 	false if new section name, true if already defined
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

;********************************************************************************************************************
; @brief Checks Ini-sections for duplets
; @param[in] file:	Filename of Ini-file
; @warnig	In case of duplets this functions exits the App with a user notification
ExitIfSectionsDoubled(AllSecs)
{
	LoopCnt := AllSecs.MaxIndex() - 1
	
	; chek all section names with all following section names
	Loop, %LoopCnt%
	{
		CompareSec := AllSecs[A_Index]
		startIdx := A_Index
		SubLoopCnt := LoopCnt - A_Index + 1
		
		; compare active section only with following sections
		Loop, %SubLoopCnt%
		{
			comIdx := startIdx + A_Index 
			if (AllSecs[comIdx] == 	CompareSec) 
			{
				MsgBox, , Autohotkey LinkManager Critical Error, 
				( ltrim
					Section name `"%CompareSec%`" is used twice in ini-file.
					Linkmanager exits
				)

				ExitApp
			}
		}
	}
}

;********************************************************************************************************************
; @brief 	Checks parents stack for recursions and exits app if positive
; @param[in] parents:	Parents stack (given as array)
; @note 	This function has to be called in each step of setup because only the youngest parent is checked for duplets
; @warnig	In case of recursion this functions exits the App with a user notification
ExitIfParentsRecursive(parents)
{
	LoopCnt := parents.MaxIndex() - 1
	lastP := parents[parents.MaxIndex()]
	ParentTree := ""
	
	Loop, %LoopCnt%
	{
		; compares last parant agains previous parents
		if (parents[A_Index] == lastP) 
		{
			if (parents[comIdx] == 	CompareSec) 
			{
				; Generate 
				Loop, %LoopCnt%
				{
					ParentTree := ParentTree . parents[A_Index] . " ->"
				}
				ParentTree := ParentTree . parents[parents.MaxIndex()]
				MsgBox, , Autohotkey LinkManager Critical Error, 
				( ltrim
					Recursion spottet in: `"%ParentTree%`"
					Linkmanager exits
				)

				ExitApp
			}
		}
	}
}

;********************************************************************************************************************
; @brief	Decodes Ini-file entry 
; @details	Gererates a menu tree object from a ini entry
; @param[in] cline	string from ini file (one key argument)
; @return	returns menu tree object 
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
		arrayElem["key"] := G_NBranchKey
	}
	else if ( ( RegExMatch(utype, G_NSepKey) == 1)
		|| ((name=="") && (ucommand=="")) )
	{
		arrayElem["key"] := G_NSepKey
	}
	else
	{
		arrayElem["key"] := G_NLeafKey
	}
	arrayElem["name"] := name
	arrayElem["link"] := ucommand

	return arrayElem
}

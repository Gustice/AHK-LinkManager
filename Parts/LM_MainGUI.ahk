; AHK-LinkManager GUI Elements



;********************************************************************************************************************
; PathManager GUI
;********************************************************************************************************************
GuiCall:
    Call[A_GuiControl].()
return
MakeCallTable()
{
    global 
	; Link-Manager-GUI
    Call["MyList"] := Func("UpdateButtons")

	Call["Add &Section"] := Func("AddSection")
	Call["Add &Entity"] := Func("AddEntity")
	Call["Add Se&parator"] := Func("AddSeparator")

	Call["Remove"] := Func("Remove")
    Call["Move &Up"] := Func("MoveUp")
    Call["Move &Down"] := Func("MoveDown")
	Call["Cut"] := Func("CutOut")
	Call["Paste"] := Func("InsertCutOut")
	Call["Undo"] := Func("Undo")
	
	Call["Show Shortcuts"] := Func("ShowShortcuts")


    Call["Preview"] := Func("PreviewContextMenu")
    Call["OK"] := Func("ManagerOK")
    Call["Cancel"] := Func("ManagerCancel")
}


#IfWinActive ahk_group currWinIDGroup
^Up::
	GUI, PathManager:Default
	MoveUp()
Return

^Down::
	GUI, PathManager:Default
	MoveDown()
Return

^X::
	GUI, PathManager:Default
	CutOut()
return

^V::
	GUI, PathManager:Default
	InsertCutOut()
return

^Del::
	GUI, PathManager:Default
	Remove()
Return

^Tab::
	GUI, PathManager:Default
	GuiControlGet, choice, ,InsertChoice
	
	if (choice == "Append")
	{
		GuiControl, ChooseString ,InsertChoice, Insert
	}
	else
	{
		GuiControl, ChooseString ,InsertChoice, Append
	}
Return
#IfWinActive

MakeMainGui:       
	Gui , PathManager: Add, ListView
        , xm w350 h480 Count15 -Multi NoSortHdr AltSubmit vMyList gGuiCall HwndMainPathManagerGUI
        , Num|Name|Path
		
	Gui PathManager: Add, DropDownList, x+10 w75 r2 Choose1 vInsertChoice, Insert|Append
		
	Gui, PathManager: Add, Button, w75 r1 Y+15 gGuiCall, Add &Section
	Gui, PathManager: Add, Button, w75 r1 gGuiCall, Add &Entity
	Gui, PathManager: Add, Button, w75 r1 gGuiCall, Add Se&parator
    
	Gui, PathManager: Add, Button, w75 r1 Y+15 gGuiCall, Remove
    
    Gui, PathManager: Add, Button, w75 r1 Y+15 gGuiCall, Move &Up
    Gui, PathManager: Add, Button, w75 r1 gGuiCall, Move &Down
    
	Gui, PathManager: Add, Button, w75 r1 Y+15 gGuiCall, Cut
	Gui, PathManager: Add, Button, w75 r1 gGuiCall, Paste
	
	; Gui, PathManager: Add, Button, w75 r1 Y+15 gGuiCall, Undo
	
	Gui, PathManager: Add, Button, w75 r2 Y+45 gGuiCall, Show Shortcuts
	
    Gui, PathManager: Add, Button, xm+30 w75 r1 gGuiCall, Preview
	Gui, PathManager: Add, Button, x+50 w75 r1 gGuiCall, OK
    Gui, PathManager: Add, Button, x+20 w75 r1 gGuiCall Default, Cancel
return

ShowShortcuts()
{
	Text = 
	(Ltrim
		Shortcuts for LinkManager GUI
		
		Ctrl+Tab	Change input selection Insert <=> Append
		Ctrl+Up-Key	Move selected entity up
		Ctrl+Down-Key	Move selected entity up
		Ctrl+Delete-Key	Delete selected entity
		Ctrl+X		Cut out selected entity
		Ctrl+V		Paste cut out to selected entity
	)
	MsgBox, ,Shortcuts, %Text%
}

UpdateButtons()
{
	Critical

    TotalNumberOfRows := LV_GetCount()
    
	if (TotalNumberOfRows == 0)
	{
		GuiControl, Disable, Se&parator
		GuiControl, Disable, &Remove
		GuiControl, Disable, Move &Up
		GuiControl, Disable, Move &Down
		GuiControl, Disable, Cut
	}
	else
	{
		GuiControl, Enable, Se&parator
		GuiControl, Enable, &Remove
		GuiControl, Enable, Move &Up
		GuiControl, Enable, Move &Down
		
		if (ByCutting == false)
		{
			GuiControl, Enable, Cut
		}
	}
	
	if (ByCutting == true)
	{
		GuiControl, Enable, Paste
	}
	else
	{
		GuiControl, Disable, Paste
	}
}


ManagerOK()
{
	global U_ShortCut

	GUI, PathManager: submit
	
	SaveOldIniFile()
	
	
	IniFileHeader := ReturnDefaultHeader()
	file := FileOpen(U_IniFile, "w")
	if !IsObject(file)
	{
		MsgBox Can't open "%FileName%" for writing.
		return
	}
	file.Write(IniFileHeader)
	file.Close()
	
	
	SaveNextNodes(MenuTree,"Menu_Root")
	
	; Restore User defined Shortcut for showing the context menu
	IniWrite, %U_ShortCut%, %U_IniFile%, User_Config, ShortKey
	
	Reload ;Reload whole App to Refresh new Context Menus
}


SaveOldIniFile()
{
	BackIniFile := U_IniFile . "bak"
	IfExist, %BackIniFile%
	{
		FileDelete, %BackIniFile%
	}
	FileCopy, %U_IniFile%, %BackIniFile% 
}

ManagerCancel()
{
	GUI, PathManager: submit
}


ShowManagerGui()
{
	GUI, PathManager: Show, ,%G_ManagerGUIname%
	WinGet, currWinID, ID, A
	GroupAdd, currWinIDGroup, ahk_id %currWinID%

	
	RefreshPathManager()
	UpdateButtons()

	; Make sure ther is one Entity selected at the beginning
    SelectedRow := LV_GetNext(0, "Focused")
    LV_Modify(SelectedRow, "Select")
}


AddSection()
{
	global G_AllSectionNames
	Gui PathManager: +OwnDialogs
    InputBox SecName, Caption Name, Please Enter a name for the new Section:, , 300, 150
    if (ErrorLevel)
        return

	NewEntity := Object()
	NewEntity[1] := G_NBranchKey
	NewEntity[2] := RegExReplace(SecName, "[^A-Za-z0-9_]", "_")
	
	SecName := SecName . "_sec"
	isalreadyUsed := CheckIfNamesIsUsed(AllSectionNames, SecName)
	if (isalreadyUsed  == true)
	{
		SecName := "_a" . SecName
	}
	NewEntity[3] := SecName
	NewEntity[4] := Object()

	AddNewEntity(NewEntity)
}

AddEntity()
{
	ShowAddDialog()
	Gui PathManager: +Disabled
}


AddSeparator()
{
	NewEntity := Object()
	NewEntity[1] := G_NSepKey
	NewEntity[2] := 
	NewEntity[3] := 
	AddNewEntity(NewEntity)	
}

Undo()
{
	MsgBox, ,Undo, Undo-Operation not implemented yet
}

AddNewEntity(NewEntity)
{
	global
	GUI, PathManager:Default
	RowNum := LV_GetNext()
    LV_GetText(Ident, RowNum, 1)
	
	TempTree := MenuTree
	idx := GetObjectElementByIdent(Ident, TempTree)
	
	GuiControlGet, choice, ,InsertChoice
	
	if ( (choice == "Append") && ( IsAppendToSectionPossible(TempTree[idx]) == true) )
	{
		TempTree[idx,4].Insert(1,NewEntity)
	}
	else
	{
		TempTree.Insert(idx,NewEntity)
	}
	RefreshPathManager()
}


IsAppendToSectionPossible(TempTree)
{
	if (IsObject(TempTree[4]))
	{
		return true
	}
	return false
}


CutOut()
{
	RowNum := LV_GetNext()
    LV_GetText(Ident, RowNum, 1)

	TempTree := MenuTree
	idx := GetObjectElementByIdent(Ident, TempTree)
	
	CutOutElement := TempTree[idx]
	TempTree.Remove(idx)
	RefreshPathManager()
	ByCutting := true
	UpdateButtons()
}


InsertCutOut()
{
	if (ByCutting == true)
	{
		ByCutting := false
		AddNewEntity(CutOutElement)
		UpdateButtons()
	}
}


RefreshPathManager()
{
	GUI, PathManager:Default
	LV_Delete()
	
	AppendNextNodes("", MenuTree)
	LV_ModifyCol()
}


AppendNextNodes(IndexStr, NodeTree)
{
	Loop % NodeTree.MaxIndex()
	{
		; Store in helper variables
		BranchType := NodeTree[A_Index, 1]
		BranchName := NodeTree[A_Index, 2]
		BranchCode := NodeTree[A_Index, 3]
		NewIndexStr := IndexStr . "." . A_Index

		; Create next Menu level (if necessary)
		if ( NodeTree[A_Index,4].MaxIndex() > 0)
		{
			BranchStruct := NodeTree[A_Index, 4]
			LV_Add("Select Focus", NewIndexStr . "+", BranchName, BranchCode)
			AppendNextNodes(NewIndexStr, BranchStruct)
		}
		else ; otherwise create a simple entry
		{
			if ( IsObject(NodeTree[A_Index,4]) )
			{
				NewIndexStr := NewIndexStr . "+"
			}
			EntityName := NodeTree[A_Index, 2]
			LV_Add("Select Focus", NewIndexStr, EntityName, BranchCode)
		}
	}
}


Remove()
{
	RowNum := LV_GetNext()
    LV_GetText(Ident, RowNum, 1)
	
	; EG: 1.1.1 (1,4,1,4,1) last Element to be deleted (if last index is leaf)
	; EG: 1.1   (1,4,1) 	branch to be deleted
	; EG: 1		(1)			root node to be deleted
	TempTree := MenuTree
	idx := GetObjectElementByIdent(Ident, TempTree)

	TempTree.Remove(idx)
	RefreshPathManager()
}


MoveUp()
{	
	RowNum := LV_GetNext()
    LV_GetText(Ident, RowNum, 1)
	newRowNum := RowNum-1

	; EG: 2.2.2 (2,4,2,4,2) last Element to be moved up
	; EG: 2.2   (2,4,2) 	branch to be moved up
	; EG: 2		(2)			root node to be moved up
	TempTree := MenuTree
	idx := GetObjectElementByIdent(Ident, TempTree)
	
	if (idx > 1)
	{
		TreeElement := TempTree[idx]
		TempTree.Remove(idx)
		newIdx := idx-1
		TempTree.Insert(newIdx,TreeElement)
		RefreshPathManager()
		
		FindRowNumByIdentAndSelect(Ident,newIdx)
	}
}


MoveDown()
{
	RowNum := LV_GetNext()
    LV_GetText(Ident, RowNum, 1)
	newRowNum := RowNum+1

	; EG: 1.1.1 (1,4,1,4,1) last Element to be moved down
	; EG: 1.1   (1,4,1) 	branch to be moved down
	; EG: 1		(1)			root node to be moved down
	TempTree := MenuTree
	idx := GetObjectElementByIdent(Ident, TempTree)
	
	maxIdx := TempTree.MaxIndex()
	if (idx < maxIdx)
	{
		TreeElement := TempTree[idx]
		TempTree.Remove(idx)
		newIdx := idx+1
		TempTree.Insert(newIdx,TreeElement)
		RefreshPathManager()
		
		FindRowNumByIdentAndSelect(Ident,newIdx)
	}
}


GetObjectElementByIdent(byref Ident, byref TempTree)
{
	IdentRange := ""
	Ident := LTrim(Ident, ".")

	AllIxd := StrSplit(Ident , ".")
	LoopCnt := AllIxd.MaxIndex() - 1
	Loop, %LoopCnt%
	{
		TempTree := TempTree[AllIxd[A_Index],4]
		IdentRange := IdentRange . "." . AllIxd[A_Index]
	}
	; Replace Last element with x to find new position of Element
	LastElement := AllIxd[AllIxd.MaxIndex()]
	IdentRange := IdentRange . "." . RegExReplace(LastElement, "[0-9]+", "x")
	Ident := IdentRange
	
	idx := RTrim(AllIxd[AllIxd.MaxIndex()], "+") 
	
	return idx 
}


FindRowNumByIdentAndSelect(oldIdent,newIdx)
{
	newIdent := RegExReplace(oldIdent, "x", newIdx)
	GUI, PathManager:Default

	TotalNumberOfRows := LV_GetCount()
	Loop, %TotalNumberOfRows%
	{
		LV_GetText(Ident, A_Index, 1)
		if (Ident == newIdent)
		{
			LV_Modify(A_Index,"Select")
			break
		}
	}
}


PreviewContextMenu()
{
	if (MenuTree.MaxIndex() > 0)
	{
		DeleteAllContextMenus(AllContextMenuNames)
		CreateContextMenu(MenuTree,MenuName,"TestMenuHandler",AllContextMenuNames)
		Menu, %MenuName%, Show 
	}
}
TestMenuHandler: ; TestMenuHandler for debug purpose
	MsgBox, You clicked MenuItem: %A_ThisMenuItem%, Menu: %A_ThisMenu%, MenuItemPos: %A_ThisMenuItemPos%
return 


DeleteAllContextMenus(byref AllContextMenuNames)
{
	numE := AllContextMenuNames.MaxIndex()
	Loop, %numE%
	{
		tempName := AllContextMenuNames[A_Index]
		Menu, %tempName%, DeleteAll 
	}
}


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


    Call["Preview"] := Func("PreviewContextMenu")
    Call["OK"] := Func("ManagerOK")
    Call["Cancel"] := Func("ManagerCancel")
	
	; Add GUI
	Call["Wähle &Ordner"] := Func("AddElementDir")
	Call["Wähle &Datei"] := Func("AddElementFile")
}


MakeMainGui:       
	Gui , PathManager: Add, ListView
        , xm w350 h480 Count15 -Multi NoSortHdr AltSubmit vMyList gGuiCall
        , Num|Name|Path
		
	Gui PathManager: Add, DropDownList, x+10 w75 r2 Choose1 vInsertChoice, Insert|Append
		
	Gui, PathManager: Add, Button, w75 r1 Y+15 gGuiCall, Add &Section
	Gui, PathManager: Add, Button, w75 r1 gGuiCall, Add &Entity
	; Gui, PathManager: Add, Button, w75 r1 gGuiCall, Add Se&parator
    
	Gui, PathManager: Add, Button, w75 r1 Y+15 gGuiCall, Remove
    
    Gui, PathManager: Add, Button, w75 r1 Y+15 gGuiCall, Move &Up
    Gui, PathManager: Add, Button, w75 r1 gGuiCall, Move &Down
    
	Gui, PathManager: Add, Button, w75 r1 Y+15 gGuiCall, Cut
	Gui, PathManager: Add, Button, w75 r1 gGuiCall, Paste
	
    Gui, PathManager: Add, Button, xm+30 w75 r1 gGuiCall, Preview
	Gui, PathManager: Add, Button, x+50 w75 r1 gGuiCall, OK
    Gui, PathManager: Add, Button, x+20 w75 r1 gGuiCall Default, Cancel
return


UpdateButtons()
{
	Critical

    TotalNumberOfRows := LV_GetCount()
    
    ; Make sure there is always one selected row
    SelectedRow := LV_GetNext(0, "Focused")
    LV_Modify(SelectedRow, "Select")

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
	GUI, PathManager: Show, ,Favoriten-Verwaltung
	RefreshPathManager()
	UpdateButtons()
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
	MsgBox, ,Separator, Separator not implemented yet
}


AddNewEntity(NewEntity)
{
	global
	GUI, PathManager:Default
	RowNum := LV_GetNext()
    LV_GetText(Ident, RowNum, 1)
	
	TempTree := MenuTree
	idx := GetObjectElement(Ident, TempTree)
	
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
	idx := GetObjectElement(Ident, TempTree)
	
	CutOutElement := TempTree[idx]
	TempTree.Remove(idx)
	RefreshPathManager()
	ByCutting := true
	UpdateButtons()
}


InsertCutOut()
{
	AddNewEntity(CutOutElement)
	ByCutting := false
	UpdateButtons()
}


GetObjectElement(Ident, byref TempTree)
{
	Ident := LTrim(Ident, ".")
	Ident := RTrim(Ident, "+")
	AllIxd := StrSplit(Ident , ".")
	LoopCnt := AllIxd.MaxIndex() - 1
	Loop, %LoopCnt%
	{
		TempTree := TempTree[AllIxd[A_Index],4]
	}
	idx := AllIxd[AllIxd.MaxIndex()]
	return idx 
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
	idx := GetObjectElement(Ident, TempTree)

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
	idx := GetObjectElement(Ident, TempTree)
	
	if (idx > 1)
	{
		TreeElement := TempTree[idx]
		TempTree.Remove(idx)
		newIdx := idx-1
		TempTree.Insert(newIdx,TreeElement)
		RefreshPathManager()
		LV_Modify(newRowNum,"Select")
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
	idx := GetObjectElement(Ident, TempTree)
	
	maxIdx := TempTree.MaxIndex()
	if (idx < maxIdx)
	{
		TreeElement := TempTree[idx]
		TempTree.Remove(idx)
		newIdx := idx+1
		TempTree.Insert(newIdx,TreeElement)
		RefreshPathManager()
		LV_Modify(newRowNum,"Select")
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


; AHK-LinkManager GUI Elements



;********************************************************************************************************************
; PathManager GUI
;********************************************************************************************************************
PathManagerGUIAutorunLabel:
	global G_RootItem := Object()
return

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

	Call["Modify"] := Func("ModifyEntity")
	Call["Remove"] := Func("Remove")
    Call["Move &Up"] := Func("MoveUp")
    Call["Move &Down"] := Func("MoveDown")
	Call["Cut"] := Func("CutOut")
	Call["Paste"] := Func("InsertCutOut")
	Call["Undo"] := Func("Undo")
	
	Call["Show Shortcuts"] := Func("ShowShortcuts")

    Call["OK"] := Func("ManagerOK")
    Call["Cancel"] := Func("ManagerCancel")
}


#IfWinActive ahk_group currWinIDGroup
^Up::
	MoveUp()
Return

^Down::
	MoveDown()
Return

^X::
	CutOut()
return

^M::
	ModifyEntity()
return

^V::
	InsertCutOut()
return

^Del::
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
	Gui , PathManager: Add, TreeView
        , xm w350 h480 Count15 -Multi vMyList gGuiCall HwndMainPathManagerGUI
		
	Gui PathManager: Add, DropDownList, x+10 w75 r2 Choose1 vInsertChoice, Insert|Append
		
	Gui, PathManager: Add, Button, w75 r1 Y+15 gGuiCall, Add &Section
	Gui, PathManager: Add, Button, w75 r1 gGuiCall, Add &Entity
	Gui, PathManager: Add, Button, w75 r1 gGuiCall, Add Se&parator
    
	Gui, PathManager: Add, Button, w75 r1 Y+15 gGuiCall, Modify
	Gui, PathManager: Add, Button, w75 r1 Y+15 gGuiCall, Remove
    
    Gui, PathManager: Add, Button, w75 r1 Y+15 gGuiCall, Move &Up
    Gui, PathManager: Add, Button, w75 r1 gGuiCall, Move &Down
    
	Gui, PathManager: Add, Button, w75 r1 Y+15 gGuiCall, Cut
	Gui, PathManager: Add, Button, w75 r1 gGuiCall, Paste
	
	; Gui, PathManager: Add, Button, w75 r1 Y+15 gGuiCall, Undo
	
	Gui, PathManager: Add, Button, w75 r2 Y+45 gGuiCall, Show Shortcuts
	
	Gui, PathManager: Add, Button, xm+50 w75 r1 gGuiCall, OK
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
		Ctrl+M		Modify selected entity
	)
	MsgBox, ,Shortcuts, %Text%
}


UpdateButtons()
{
	Critical

    TotalNumberOfRows := TV_GetCount()
    
	selID := TV_GetSelection()
	G_RootItem["idx"]
	
	
	if (G_RootItem["idx"] == selID)
	{ ; Dont allow modifiing of Root
		GuiControl, Disable, Add &Section
		GuiControl, Disable, Add &Entity
		GuiControl, Disable, Add Se&parator
		GuiControl, Disable, Modify
		GuiControl, Disable, Remove
		GuiControl, Disable, Move &Up
		GuiControl, Disable, Move &Down
		GuiControl, Disable, Cut
		GuiControl, Disable, Paste
	}
	else
	{
		GuiControl, Enable, Add &Section
		GuiControl, Enable, Add &Entity

		if ( (TotalNumberOfRows == 0) || (G_RootItem["idx"] == selID) )
		{
			GuiControl, Disable, Add Se&parator
			GuiControl, Disable, Modify
			GuiControl, Disable, Remove
			GuiControl, Disable, Move &Up
			GuiControl, Disable, Move &Down
			GuiControl, Disable, Cut
		}
		else
		{
			GuiControl, Enable, Add Se&parator
			GuiControl, Enable, Modify
			GuiControl, Enable, Remove
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
	
	SaveNextNodes(G_MenuTree["sub"],"Menu_Root")
	
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

PathManagerGuiClose:
PathManagerGuiEscape:
ManagerCancel()
return 

ManagerCancel()
{
	GUI, PathManager: submit
	
	JumpStack := CreateContextMenu(G_MenuTree,G_MenuName,"MenuHandler",AllContextMenuNames)
}


ShowManagerGui()
{
	GUI, PathManager: Show, ,%G_ManagerGUIname%
	WinGet, currWinID, ID, A
	GroupAdd, currWinIDGroup, ahk_id %currWinID%

	G_RootItem := RefreshPathManager()
	
	; Make sure ther is one Entity selected at the beginning
	TV_Modify(G_RootItem["idx"] , "Select")
}


AddSection()
{
	SecName := AskForSectionName("")
	if(SecName == "")
		return
	
	NewEntity := MakeUniqueSectionEntity(SecName)
	NewEntity["gui"] := "Select Bold"

	AddNewEntity(NewEntity)
}


AskForSectionName(defaultInput)
{
	Gui PathManager: +OwnDialogs
    InputBox SecName, Caption Name, Please Enter a name for the new Section:, , 300, 150 , , , , ,%defaultInput%
    if (ErrorLevel)
	{
		SecName := ""
	}
	
	return SecName
}

MakeUniqueSectionEntity(SecName)
{
	NewEntity := Object()
	NewEntity["key"] := G_NBranchKey
	NewEntity["name"] := RegExReplace(SecName, "[^A-Za-z0-9_]", "_")
	
	SecName := SecName . "_sec"
	isalreadyUsed := CheckIfNamesIsUsed(G_AllSectionNames, SecName)
	if (isalreadyUsed  == true)
	{
		SecName := "_a" . SecName
	}
	NewEntity["link"] := SecName
	NewEntity["sub"] := Object()

	return NewEntity
}


AddEntity()
{
	ShowAddDialog("Sample", "C:\", "New")
	Gui PathManager: +Disabled
}


ModifyEntity()
{
	GUI, PathManager:Default

	selection := Object()
	selID := TV_GetSelection()
	selection := G_CallTree[selID]
	
	if (selection["data","key"] == G_NBranchKey)
	{
		SecName := AskForSectionName(selection["data","name"] )
		if(SecName == "")
			return

		NewEntity := MakeUniqueSectionEntity(SecName)
		selection["data","name"] := NewEntity["name"]
		selection["data","link"] := NewEntity["link"]
		RefreshPathManager()
	}
	else if (selection["data","key"] == G_NLeafKey)
	{
		ShowAddDialog(selection["data","name"], selection["data","link"], "Change")
		Gui PathManager: +Disabled
	}
	else
	{
		
	}	
}


AddSeparator()
{
	NewEntity := Object()
	NewEntity["key"] := G_NSepKey
	NewEntity["name"] := 
	NewEntity["link"] := 
	
	NewEntity["gui"] := "Select"
	AddNewEntity(NewEntity)
}


Undo()
{
	MsgBox, ,Undo, Undo-Operation not implemented yet
}


AddNewEntity(NewEntity)
{
	global
	GetParentAndIndex(TempTree, idx)
	
	GuiControlGet, choice, ,InsertChoice
	if ( (choice == "Append") && ( IsAppendToSectionPossible(TempTree[idx]) == true) )
	{
		TempTree[idx,"sub"].Insert(1,NewEntity)
	}
	else
	{
		TempTree.Insert(idx,NewEntity)
	}
	RefreshPathManager()
}


ModifySelectedLeaf(NewEntity)
{
	GUI, PathManager:Default

	selection := Object()
	selID := TV_GetSelection()
	selection := G_CallTree[selID]
	
	selection["data","name"] := NewEntity["name"]
	selection["data","link"] := NewEntity["link"]
	RefreshPathManager()
}


IsAppendToSectionPossible(TempTree)
{
	if (IsObject(TempTree["sub"]))
	{
		return true
	}
	return false
}


CutOut()
{
	GUI, PathManager:Default

	GetParentAndIndex(TempTree, idx)
	
	CutOutElement := TempTree[idx]
	TempTree.Remove(idx)
	RefreshPathManager()
	ByCutting := true
}


InsertCutOut()
{
	if (ByCutting == true)
	{
		ByCutting := false
		CutOutElement["gui"] := "Select"

		AddNewEntity(CutOutElement)
	}
}


RefreshPathManager()
{
	GUI, PathManager:Default
	SampleTreeSettings()

	TV_Delete()
	Root := TV_Add("Context Menu",, "Expand")
	
	G_CallTree := Object()
	Item := Object()
	Item["data"] := G_MenuTree
	Item["idx"] := Root
	G_CallTree[Root] :=Item
		
	AppendNextNodes(G_CallTree, Root, G_MenuTree["sub"])
	return Item
}


SampleTreeSettings()
{
	temp := G_CallTree.Pop()
	while (temp)
	{
		; if you want to restore previous Config
		newAtt := temp["data","gui"]
		
		; expand the entry on next tree set-up
		tst := TV_Get(temp["item"], "E")
		if (tst > 0)
		{
			newAtt := newAtt . " Expand"
		}
		
		temp["data","gui"] := LTrim(newAtt)
		temp := G_CallTree.Pop()
	}
}


AppendNextNodes(callTree, Parent, NodeTree)
{
	childObj := Object()

	Loop % NodeTree.MaxIndex()
	{
		Item := Object()
		Item["data"] := NodeTree[A_Index]
		Item["idx"] := A_Index
		Item["parent"] := Parent
		
		Attr := NodeTree[A_Index,"gui"]
		NodeTree[A_Index,"gui"] := ""
		
		if ( NodeTree[A_Index,"sub"].MaxIndex() > 0)
		{ ; create new branch if subs are defined
			BranchName := NodeTree[A_Index, "name"]
			BranchStruct := NodeTree[A_Index, "sub"]
			newItem := TV_Add(BranchName, Parent, Attr)
			Item["childs"] := AppendNextNodes(callTree, newItem, BranchStruct)
		}
		else 
		{ ; otherwise create a simple entry
			if (NodeTree[A_Index, "key"] == G_NSepKey)
			{
				EntityName := "------"
			}
			else
			{
				EntityName := NodeTree[A_Index, "name"]
			}
			newItem := TV_Add(EntityName, Parent, Attr)
		}
		Item["item"] := newItem
		callTree[newItem] :=Item
		childObj[newItem] := Item

	}
	return childObj
}


Remove()
{
	GUI, PathManager:Default

	GetParentAndIndex(TempTree, idx)

	TempTree.Remove(idx)
	RefreshPathManager()
}


MoveUp()
{	
	GUI, PathManager:Default

	GetParentAndIndex(TempTree, idx)

	if (idx > 1)
	{
		TreeElement := TempTree[idx]
		TempTree.Remove(idx)
		newIdx := idx - 1
		
		TreeElement["gui"] := "Select"
		TempTree.Insert(newIdx,TreeElement)
		RefreshPathManager()
	}
}


MoveDown()
{
	GUI, PathManager:Default

	GetParentAndIndex(TempTree, idx)

	maxIdx := TempTree.MaxIndex()
	if (idx < maxIdx)
	{		
		TreeElement := TempTree[idx]
		TempTree.Remove(idx)
		newIdx := idx + 1

		TreeElement["gui"] := "Select"
		TempTree.Insert(newIdx,TreeElement)
		RefreshPathManager()
	}
}


GetParentAndIndex(ByRef TempTree, ByRef idx)
{
	GUI, PathManager:Default

	selection := Object()
	selID := TV_GetSelection()
	selection := G_CallTree[selID]
	idx := selection["idx"]
	
	parantID := TV_GetParent(selID)
	parent := G_CallTree[parantID]
	TempTree := parent["data","sub"]
}


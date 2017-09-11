;********************************************************************************************************************
; AHK-LinkManager GUI Elements
; AddElement GUI
;********************************************************************************************************************
AddElementGUIAutorunLabel:

return


;********************************************************************************************************************
; GUI representation
;********************************************************************************************************************
MakeAddDialog:
	GUI, AddElement: -SysMenu 
	Gui, AddElement: Add, Text, x10 y10 w50, Name
	Gui, AddElement: Add, Edit, x10 yp w400 xp60 vNewEntryName, Sample Name
	
	Gui, AddElement: Add, Text, x10 yp25 w50, Path
	Gui, AddElement: Add, Edit, x10 yp0 w400 xp60 vNewEntryPath, C:\
	
	Gui, AddElement: Add, button, x70 yp25 w100 gSelectDir, Select &directory
	Gui, AddElement: Add, button, xp110 w100 gSelectFile, Select &file
	
	Gui, AddElement: Add, button, x300 yp30 w80 vApplyButton gApplyHandle , &OK
	Gui, AddElement: Add, button, x+10 yp w80 , &Cancel
return

;********************************************************************************************************************
; @brief	Shows add/modify dialogue with preset textfields
; @param[in] startName:	Preset for entity name
; @param[in] startPath:	Preset for entity link
; @param[in] isNew: call with "Change" to modify entity and start modify dialogue
ShowAddDialog(startName, startPath, isNew)
{
	Gui PathManager: +OwnDialogs
    Gui, AddElement: Show, , Add new path
	
	GuiControl, AddElement: ,NewEntryName, %startName%
	GuiControl, AddElement: ,NewEntryPath, %startPath%

	if (isNew == "Change")
	{
		GuiControl, AddElement: , ApplyButton, &Apply
	}
	else
	{
		GuiControl, AddElement: , ApplyButton, &OK
	}
}


;********************************************************************************************************************
; GUI buttons and events
;********************************************************************************************************************

; Selct directory event
SelectDir:
	GUI, AddElement: submit, NoHide
	Gui, AddElement: +OwnDialogs

	SplitPath, NewEntryPath, OutFileName, OutDir
	selectedPath := GetValidPath(OutDir,"Dir")
	GuiControl, , NewEntryPath, %selectedPath%
return

; Selct file event
SelectFile:
	GUI, AddElement: submit, NoHide

	selectedPath := GetValidPath(NewEntryPath,"File")
	GuiControl, , NewEntryPath, %selectedPath%
return

; OK / apply event
; 	- OK button is for add dialogue 
;	- Apply button is for modifiy dialogue
ApplyHandle:
	GUI, AddElement: submit
	
	NewEntity := Object()
	NewEntity["key"] := G_NLeafKey
	NewEntity["name"] := NewEntryName
	NewEntity["link"] := NewEntryPath
	
	GuiControlGet, Btext, AddElement: , ApplyButton
	if (Btext=="&OK")
	{
		AddNewEntity(NewEntity)
	}
	else
	{
		ModifySelectedLeaf(NewEntity)
	}

	Gui, PathManager: -Disabled
	GUI, PathManager: Show
return

; Cancel event
AddElementButtonCancel:
	GUI, AddElement: submit
	Gui, PathManager: -Disabled
	GUI, PathManager: Show
return


;********************************************************************************************************************
; @brief	Retrieves valid path with fault back options
; @param[in] startPath: Path to be checked
; @param[in] pathType:	Path type call with "Dir" or "File" for directory or file respectively
; @return	valid path, in case of error either last valid path or fault back path
GetValidPath(startPath,pathType)
{
	faultBackPath := "C:\"
	static lastValid := "C:\"
	
	IfExist, %startPath%
	{
		faultBackPath := startPath
		;MsgBox, Ist gültiger Pfad, ich fange hier an zu suchen
		if (pathType == "Dir")
			FileSelectFolder, path, %startPath%, 3
		else if (pathType == "File")
			FileSelectFile, path, 3, %startPath%, Datei wählen,
		else
			return faultBackPath
	}
	IfNotExist, %startPath%
	{
		;MsgBox, Ist kein gültiger Pfad, ich fange an auf C: zu suchen
		if (pathType == "Dir")
			FileSelectFolder, path, %lastValid%, 3
		else if (pathType == "File")
			FileSelectFile, path, 3, %lastValid%, Datei wählen,
		else
			return faultBackPath
	}
		
	IfExist, %path%
	{
		lastValid := path
		return path
	}
	return faultBackPath
}

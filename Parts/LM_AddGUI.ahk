; AHK-LinkManager GUI Elements

;********************************************************************************************************************
; AddElement GUI
;********************************************************************************************************************
MakeAddDialog:
	GUI, AddElement: -SysMenu 
	Gui, AddElement: Add, Text, x10 y10 w50, Name
	Gui, AddElement: Add, Edit, x10 yp w400 xp60 vNewEntryName, Beispiel Name
	
	Gui, AddElement: Add, Text, x10 yp25 w50, Pfad
	Gui, AddElement: Add, Edit, x10 yp0 w400 xp60 vNewEntryPath, C:\
	
	Gui, AddElement: Add, button, x70 yp25 w100 gGuiCall, Wähle &Ordner
	Gui, AddElement: Add, button, xp110 w100 gGuiCall, Wähle &Datei
	
	Gui, AddElement: Add, button, x300 yp30 w50 , &OK
	Gui, AddElement: Add, button, xp60 yp w50 , &Abbrechen
return


ShowAddDialog()
{
	Gui PathManager: +OwnDialogs
    Gui, AddElement: Show, , Add new path
}


AddElementButtonOK:
	GUI, AddElement: submit
	
	NewEntity := Object()
	NewEntity[1] := G_NLeafKey
	NewEntity[2] := NewEntryName
	NewEntity[3] := NewEntryPath
	
	Gui PathManager: -Disabled
	AddNewEntity(NewEntity)	
	GUI, PathManager: Show
return


AddElementButtonAbbrechen:
	GUI, AddElement: submit
	Gui PathManager: -Disabled
return


AddElementDir()
{
	global
	GUI, AddElement: submit, NoHide
	;MsgBox, Ich sehe %NewEntryPath% und %NewEntryName%
	Gui, AddElement: +OwnDialogs

	SplitPath, NewEntryPath, OutFileName, OutDir
	selectedPath := GetValidPath(OutDir,"Dir")
	GuiControl, , NewEntryPath, %selectedPath%
}


AddElementFile()
{
	global
	GUI, AddElement: submit, NoHide
	;MsgBox, Ich sehe %NewEntryPath% und %NewEntryName%

	selectedPath := GetValidPath(NewEntryPath,"File")
	GuiControl, , NewEntryPath, %selectedPath%
}


GetValidPath(startPath,pathType)
{
	faultBackPath := "C:\"
	static lastValid := "C:\"
	;MsgBox, Ich sehe %startPath%
	
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

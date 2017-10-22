;********************************************************************************************************************
; AHK-LinkManager GUI Elements
; Hotkey GUI (Setting Up Context Menu Shortcut)
;********************************************************************************************************************

;********************************************************************************************************************
; GUI representation
;********************************************************************************************************************
MakeHotKeyCustomizeGui:
	Gui, HKsetup: Add, Hotkey, vHKtemp gExecuteHKSetup
	Gui, HKsetup: Add, CheckBox, vWinCBox x+5, Win
	Gui, HKsetup: Add, Button, gAdd_LClick2HK, Lclick
	Gui, HKsetup: Add, Button, gAdd_MClick2HK, Mclick
	Gui, HKsetup: Add, Button, gAdd_RClick2HK, Rclick
return

ShowHotKeyCustomizeGui:
	Gui, HKsetup: Show,,Dynamic Hotkeys
	
	If (U_ShortCut) 
		{                         ;If a hotkey was already saved...
		Hotkey, %U_ShortCut%, RunMenu, Off      ;turn the old hotkey off
		TrayTip, Hotkey, Deaktivated, 2	;     	;show a message: the old hotkey is OFF
	}
	HKadd := ""
return

HKsetupGuiClose:
HKsetupGuiEscape:
	GUI, HKsetup: submit
return

Add_LClick2HK:
	HKadd := "LButton"
	gosub ExecuteHKSetup
return
Add_MClick2HK:
	HKadd := "MButton"
	gosub ExecuteHKSetup
return
Add_RClick2HK:
	HKadd := "RButton"
	gosub ExecuteHKSetup
return

ExecuteHKSetup:
	Gui, HKsetup: +OwnDialogs
	Gui, Submit, NoHide

	HKtemp := HKtemp . HKadd
	HKadd := ""
	;If the hotkey contains only modifiers, return to wait for a key.
	If HKtemp in +,^,!,+^,+!,^!,+^!            
		return
	;If the 'Win' box is checked, then add its modifier (#).
	If WinCBox                                  
		HKtemp := "#" HKtemp
	
	try 
	{
		;If the new hotkey is only 1 character, then add the (~) modifier.
		If StrLen(HKtemp) = 1
			;This prevents any key from being blocked.
			HKtemp := "~" HKtemp                          
		
		U_ShortCut := HKtemp
		;Turn on the new hotkey.
		Hotkey, %U_ShortCut%, RunMenu, On	
	}
	catch
	{
		return ; wait for next user input
	}
	
	;Show a message: the new hotkey is ON.
	HKout := PrintHotKey(U_ShortCut)
	TrayTip, RunMenu,% HKout " ON"   
	
	MsgBox, 4 , Save Hotkey?, Do you whant to save this hotkey: %HKout%
	IfMsgBox Yes
	{
		IniWrite, %U_ShortCut%, %U_IniFile%, User_Config, ShortKey
	}
	GUI, HKsetup: submit
	
return

;********************************************************************************************************************
; @brief	Converts encodes hotkey string to user readable string
; return readable string
PrintHotKey(userHK)
{
	HotKeys  := Object()
	HotKeysMeaning := Object()
	
	HotKeys := 			["#",	"^",	 "!",	"+",	"<^>" ]
	HotKeysMeaning := 	["Win","Control","Alt",	"Shift","AltGr"]
	cnt := HotKeys.MaxIndex()
	
	UserHotkeyString := ""
	Loop %cnt%
	{
		HK := HotKeys.Pop()
		HKmeaning := HotKeysMeaning.Pop()
		
		foundPos := InStr(userHK,HK)
		if (foundPos  > 0)
		{
			UserHotkeyString := UserHotkeyString . HKmeaning . " + "
			userHK := StrReplace(userHK, HK, "")
		}
	}
	; Append rest to ouput string
	UserHotkeyString := UserHotkeyString . userHK
	return UserHotkeyString
}
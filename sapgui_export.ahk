/*
	DONE:
		> Enhanced Logging
		> Basic sapgui postprocessing
		> Basic Excel preprocessing
		> SAPGUI Theme detection solution for when the screen is maximized (for some reason the second monitor starts at coordinates 8,8 ????)
		> ST12 -> show call hierarchy when turned on
		
		> clicking an ALVGrid in a window different from the active window does not immediately make the ALVGrid the focus
		  this causes the default "system -> list -> save" to trigger. Not intended
		  WORKAROUND: check the control under the mouse as a backup if the current focus is blank
	
	WIP:
		image library to make looking for specific visual elements easier (have to account for theme and character set)
	
	TODO:
		HARD - Oracle: table and index information dialogs (lots of annoying scrolling)
		MEDIUM - ST13 -> Process Chain runtime Comparison (has 2 grids, top one has no export button T_T )
		HARD - SQL summary Statement details (screen which shows fastest, slowest, average, calling source locations)
		
		EVEN POSSIBLE?? Get ahk to work through Remote Desktop connection
		
		> ST05 with hidden ALV buttons not supported at the moment. Have to screen cap all of the "show std ALV functions" buttons
		
		
	Notes:
	> Try to avoid using ImageSearch where possible
	  different SAP themes and Character Sets require a lot of work to support
	
	
	SAPGUI hotkeys:
	https://help.sap.com/saphelp_tm80/helpdata/en/48/159ed688474c23e10000000a42189b/frameset.htm
	Keyboard Access in SAP GUI for Windows
		ALV Grid
	
	
*/



#NoEnv

SetDefaultMouseSpeed, 0


/*	reducing SetKeyDelay will make the script execute faster, but the trade off is stability
	Most of the time spent waiting is for the server to format the output.
	There is little to no appreciable gain to changing this.
*/
;SetKeyDelay, 10


/*	global control for postprocessing SAPGUI output
	Set this to 0 or false if you don't want output to be modified
*/
Global postprocess_sapgui := 1
Global debug_gdip := 1

#include lib/gdip.ahk

Global gdip_token := Gdip_Startup()

ExitFunc(){
	Gdip_Shutdown(gdip_token)
}

OnExit("ExitFunc")

#include lib/logging.ahk
/*
	clearLog()
	appendLog(mes)
*/


#include lib/helpers.ahk
/*
	getSapGuiThemePrefix(winID)
	getControlProperties(winID, classnn)
	getClassNNByClass(winID, partialclass, partialtext="")
	moveClickRestore(winID, winx, winy, block=True, byref clicked_classnn = "")
	findImage(x1, y1, x2, y2, name)
*/

#include lib/cb_main.ahk
/*
	cb_sapguiPostProcess(byref cb_with_newlines)
	cb_excelPreProcess(byref cb_with_newlines)
	cb_removeInitialHeader(byref cb_with_newlines)
	cb_getTableStartEndHeader(byref cb_array, byref start_i_out, byref end_i_out, byref header_i_out)
	cb_detectNumberFormat(byref cb_with_newlines, byref dec_separator, byref thou_separator)
	cb_repairWideTable(byref cb_with_newlines)
	cb_removeWhiteSpace(byref cb_with_newlines)
	cb_removeLeadingBar(byref cb_with_newlines)
	cb_removeHorizontalLines(byref cb_with_newlines)
	cb_formatSimple(byref cb_with_newlines)
*/

#include lib/alvgrid.ahk
/*
	
*/

#include lib/tc_os01.ahk
/*
	whichLanCheckScreen(winID)
	copyLanCheckScreenDetails(winID)
	copyLanCheckScreen(winID)
*/

#include lib/tc_stad.ahk
/*
	copySTADcallDialog(winID)
*/

#include lib/tc_st12.ahk
/*
	
*/


#include lib/excel.ahk
/*
	excel_preProcess()
*/






sendSystemListSave(winID=""){
	;can we replace Send with ControlSend? SAPGUI seems to not like controlsend for this purpose
	;But Send is okay here since there should be no delays (i.e. round trips with the server)
	
	;ControlSend, , !y, ahk_id %winID%
	;ControlSend, #32768, ytai, ahk_id %winID%
	
	
	;S4 Hana cloud edition changes the shortcut chain from ytai -> ytss
	;luckily there is no key conflict and we can just add the additional shortcut keys
	;Send, !ytai
	Send, !ytaiss
	
	waitAndProcessSaveDialog()
	flushLogAndExit()
}

waitAndProcessSaveDialog(secondsToWait=8)
{
    WinWait, Save list in file..., , %secondsToWait%
	
	if (ErrorLevel){
		appendLog("'Save list in file...' didn't appear in " . secondsToWait . "seconds, exiting")
		flushLogAndExit()
	}
	
    ;"ControlSend", sadly, doesn't work in this case, the window seems to ignore {Down n}
    ;But control click works fine! (hopefully they never change the layout of this dialog)
    ControlClick, x25 y220, Save list in file...,,,, Pos
	;doesn't always work unless we sleep for a bit
	Sleep, 15
    ;ControlClick, x210 y255, Save list in file...,,,, Pos
	ControlSend, , {Enter}, Save list in file...
}

waitForSaveDialogToClose(){
	WinWaitClose, Save list in file...
}

sapgui_postProcess(){
	
	cb:=clipboard
	
	cb_removeInitialHeader(cb)
	cb_removeTrailingPage(cb)
	
	cb_repairWideTable(cb)
	
	;temporarily ignore needs work
	;cb_repairNewLineInTableCell(cb)
	
	
	clipboard:=cb
}


;;;;;;;;;;;;;;;;;;;;;;;
;        SAPGUI       ;
;;;;;;;;;;;;;;;;;;;;;;;

#IfWinActive ahk_exe saplogon.exe
` Up::
;KeyWait, Control

	WinGet, winID, ID, A
	WinGetTitle, WTitle, ahk_id %winID%
	
	;don't do anything if it's just the Logon window
	if InStr(WTitle, "SAP Logon")
	
	flushLogAndExit()
	
	clearLog()
	appendLog("checking exception list")
	
	;In case we've already opened a "save list in file..." dialog
	if InStr(WTitle, "Save list in file..."){
		waitAndProcessSaveDialog()
		sapgui_postProcess()
		flushLogAndExit()
	}
	
	;fast log off
	if (WTitle = "Log Off"){
		appendLog("logging off")
		CoordMode, Mouse, Window
		ControlClick, x80 y110, ahk_id %WinID%, , , 2, Pos
		flushLogAndExit()
	}
	
	;Exception list
	;these screens don't use ALV grids or the default key combination
	;Or need some kind of special prep
	
    ;ST12 Trace list
    if (WTitle = "Trace analyses fullscreen list"){
		Send, !exl
		waitAndProcessSaveDialog()
		flushLogAndExit()
	}
	;ST12 SQL Summary
	else if (InStr(WTitle, "SQL Summary - ") || InStr(WTitle, "SQL Summary for Code Location ")){
		Send, !exl
		waitAndProcessSaveDialog()
		flushLogAndExit()
	}
    ;ST12 trace details
    else if InStr(WTitle, "ABAP Trace Per Call"){
		st12_copyABAPTraceScreen(winID)
		
	}
	;ST12 - Statistical Records
	else if InStr(WTitle, "Collected Statistical records for analysis"){
		Send, !exl
		waitAndProcessSaveDialog()
		flushLogAndExit()
	}
	;OS01 - LAN Check by Ping
	else if InStr(WTitle, "LAN Check by PING"){
		copyLanCheckScreen(winID)
		flushLogAndExit()
	}
	;STAD RFC subrecord dialog
	else if (InStr(WTitle, "RFC: ") = 1) AND InStr(WTitle, "Records")
	     OR (InStr(WTitle, "HTTP: ") = 1) AND InStr(WTitle, "Records"){
		copySTADcallDialog(winID)
	}
	
	appendLog("past exception list")
	
	;past exception list, check if we have an ALVGrid in focus
	ControlGetFocus, cf, ahk_id %winID%
	
	appendLog("current focus is control '" . cf . "'")
	
	if (cf = ""){
		appendLog("checking control under the mouse")
		MouseGetPos, , , , cf
		appendLog("control under the mouse is '" . cf . "'")
	}
	
	if InStr(cf, "SAPALVGrid"){
		processALVGrid(winID, cf)
		if (!ErrorLevel){
			
			waitAndProcessSaveDialog()
			if (postprocess_sapgui){
				waitForSaveDialogToClose()
				
				sapgui_postProcess()
			}
		}
		flushLogAndExit()
	}
	
	appendLog("sending default keystrokes")
	
	;Default save as keys
	sendSystemListSave(winID)

return
	
;end of sapgui










;;;;;;;;;;;;;;;;;;;;;;
; Debugging hotkeys: ;
;;;;;;;;;;;;;;;;;;;;;;


showGridsAndToolbars(){

	WinGet, winID, ID, A

	alvgrids:=getClassNNByClass(winID, "SAPALVGrid")

	toolbar_window:=getToolbarWindowForALVGrid(winID, "null")

	str:="grids: "
	grid:=""
		For Index, Value in alvgrids {
			grid:=getControlProperties(winID, Value)
			str .= Value . "," . grid.x . "," . grid.y . "," . grid.w . "," . grid.y . ";"
		}

	MsgBox % str . "`r`n" . "toolbar: " . toolbar_window

	return
	
}


^!z::

KeyWait, Control
KeyWait, Alt

	clearLog()

	;WinGet, winID, ID, A

	;processALVGrid(winID, "SAPALVGrid1")

	;prefix:=getSapGuiThemePrefix(winID)
	
	;MsgBox % test


return

;*/


;;;;;;;;;;;;;;;;;;;;;;;
; Excel               ;
;;;;;;;;;;;;;;;;;;;;;;;
#IfWinActive ahk_exe EXCEL.EXE
^q::
	
	clearLog()
	appendLog("starting Excel hotkey")
	
	;We don't need the winID here since we can use the COM object
	;WinGet, winID, ID, A
	
	;script must be running at the same privilege level as Excel (i.e. administrator)
	; https://stackoverflow.com/a/43875164
	xl := ComObjActive("Excel.Application")
	
	;copy clipboard and save a second copy to restore it later
	cb:=clipboard
	
	appendLog("preprocessing Excel input")
	;Excel configuration and preprocessing
	excel_setSeparators(xl, cb)
	excel_preProcess(cb)
	appendLog("preprocessing done")
	
	;xl.ActiveCell.PasteSpecial
	excel_paste(xl, cb)
	
	
	flushLogAndExit()
	
	return
;end of Excel


;;;;;;;;;;;;;;;;;;;;;;;
; Notepad++           ;
;;;;;;;;;;;;;;;;;;;;;;;

#IfWinActive ahk_exe notepad++.exe
^q::
	
	clearLog()
	
	cb := clipboard
	
	;cb_detectNumberFormat(cb, ds, ts)
	cb_repairWideTable(cb)
	clipboard := cb
	
	
	;MsgBox % "ds = '" . ds . "' ts = '" . ts . "'"
	
	flushLogAndExit()
	
	return
;end of Notepad++


;;;;;;;;;;;;;;;;;;;;;;;
; BCP                 ;
;;;;;;;;;;;;;;;;;;;;;;;
#If WinActive("ahk_exe chrome.exe") && ( WinActive("Incident") || WinActive("Chat Incident"))
^q::
	
	;paste the clipboard but with non-breaking spaces instead of regular spaces
	nbsp:=Chr(0x00A0)
	clipboard:=StrReplace(clipboard, " ", nbsp)
	
	Send ^v

return


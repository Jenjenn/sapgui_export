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
		MEDIUM - ST12 -> the name of the ALVGrid in ST12 is not always SAPALVGrid2 -> make this generic
		HARD - SQL summary Statement details (screen which shows fastest, slowest, average, calling source locations)
		EASY - STAD: add pipes/bars ('|') to the fields separated by only spaces.
		
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



SetDefaultMouseSpeed 0

/*	reducing SetKeyDelay will make the script execute faster, but the trade off is stability
	Most of the time spent waiting is for the server to format the output.
	There is little to no appreciable gain to changing this.
*/
;SetKeyDelay, 10


/*	global control for postprocessing SAPGUI output
	Set this to 0 or false if you don't want output to be modified
*/

Global SAPGUI_THEME := "blue_crystal"

Global postprocess_sapgui := 1
Global debug_gdip := 1

#include lib/gdip.ahk

Global gdip_token := Gdip_Startup()

ExitFunc(reason, code){
	Gdip_Shutdown(gdip_token)
}

OnExit("ExitFunc")

OnError("flushLogAndExit")

#include lib/logging.ahk
/*
	clearLog()
	appendLog(message)
*/

#include lib/MyControl.ahk

#include lib/helpers.ahk
/*
	getSapGuiThemePrefix(winID)
	getControlsByClass(winID, class_name)
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






sendSystemListSave(winID := 0){
	;can we replace Send with ControlSend? SAPGUI seems to not like controlsend for this purpose
	;But Send is okay here since there should be no delays (i.e. round trips with the server)
	
	;ControlSend, , !y, ahk_id %winID%
	;ControlSend, #32768, ytai, ahk_id %winID%
	
	
	;S4 Hana cloud edition changes the shortcut chain from ytai -> ytss
	;luckily there is no key conflict and we can just add the additional shortcut keys
	;Send, !ytai
	Send("!ytaiss")
	
	waitAndProcessSaveDialog()
	flushLogAndExit()
}

waitAndProcessSaveDialog(timeout := 20)
{
    win_id := WinWait(sapgui_elements.save_list_window.title, , timeout)
	
	if (!win_id){
		appendLog("'" sapgui_elements.save_list_window.title 
			. "' didn't appear in " timeout "seconds, exiting")
		flushLogAndExit()
	}
	
    ; "ControlSend", sadly, doesn't work on the window in this case
	;appendLog("Clicking 'In the clipboard'")
    ; preferred method ==> ControlClick("x25 y195", "Save list in file...", , , , "Pos")
	; on older releases, the spacing is different and clicking in a specific position doesn't work
	
	; testing new method
	rb_control := getControlsByClass(win_id, sapgui_elements.save_list_rb.classnn, true)[1]
	ControlSend("{Up}", rb_control.hwnd)

	; doesn't always work unless we sleep for a bit
	Sleep(15)
	ControlSend("{Enter}", , win_id)

	return win_id
}

waitForSaveDialogToClose(win_id, timeout := 30)
{
	if ( !WinWaitClose(win_id, , timeout) )
	{
		appendLog("download from app server timed out after " timeout " seconds")
		flushLogAndExit()
	}
}

sapgui_postProcess(){
	
	cb := clipboard
	
	cb_removeInitialHeader(cb)
	cb_removeTrailingPage(cb)
	
	cb_repairWideTable(cb)
	
	;temporarily ignore needs work
	;cb_repairNewLineInTableCell(cb)
	
	
	clipboard := cb
}


;;;;;;;;;;;;;;;;;;;;;;;
;        SAPGUI       ;
;;;;;;;;;;;;;;;;;;;;;;;

#If WinActive("ahk_exe saplogon.exe")
` Up::
;KeyWait, Control

	winID := WinGetID("A")
	title := WinGetTitle(winID)
	
	;don't do anything if it's just the Logon window
	if InStr(title, "SAP Logon")
	{
		flushLogAndExit()
	}
	
	clearLog()
	appendLog("checking exception list")
	
	;In case we've already opened a "save list in file..." dialog
	if InStr(title, "Save list in file..."){
		waitAndProcessSaveDialog()
		sapgui_postProcess()
		flushLogAndExit()
	}
	
	;fast log off
	if (title = "Log Off"){
		appendLog("logging off")
		CoordMode("Mouse", "Window")
		ControlClick("x80 y110", winID, , , 2, "Pos")
		flushLogAndExit()
	}
	
	;Exception list
	;these screens don't use ALV grids or the default key combination
	;Or need some kind of special prep
	
    ;ST12 Trace list
    if (title = "Trace analyses fullscreen list"){
		Send("!exl")
		waitAndProcessSaveDialog()
		flushLogAndExit()
	}
	;ST12 SQL Summary
	else if (InStr(title, "SQL Summary - ") || InStr(title, "SQL Summary for Code Location ")){
		Send("!exl")
		waitAndProcessSaveDialog()
		flushLogAndExit()
	}
    ;ST12 trace details
    else if InStr(title, "ABAP Trace Per Call"){
		st12_copyABAPTraceScreen(winID)
		
	}
	;ST12 - Statistical Records
	else if InStr(title, "Collected Statistical records for analysis"){
		Send("!exl")
		waitAndProcessSaveDialog()
		flushLogAndExit()
	}
	;OS01 - LAN Check by Ping
	else if InStr(title, "LAN Check by PING"){
		copyLanCheckScreen(winID)
		flushLogAndExit()
	}
	;STAD main result screen
	else if InStr(title, "SAP Workload: Single Statistical Records - Overview"){
		STAD.copyrecordsOverview(winID)
	}
	;STAD RFC subrecord dialog
	else if (InStr(title, "RFC: ") = 1) AND InStr(title, "Records")
	     OR (InStr(title, "HTTP: ") = 1) AND InStr(title, "Records"){
		STAD.copyCallDialog(winID)
	}
	
	appendLog("past exception list")
	
	;past exception list, check if we have an ALVGrid in focus
	cf := ControlGetFocus(winID)
	
	if (!cf)
	{
		appendLog("couldn't get control of focus, check under the mouse")
		MouseGetPos( , , , cf, 2)

		if (!cf)
		{
			appendLog("didn't find a control under the mouse")
			goto DefaultKeyStrokes
		}
	}

	cf := MyControl.new(cf)
	appendLog("target control is '" . cf.classnn . "'")
	
	if (cf.wclass == "SAPALVGrid")
	{
		processALVGrid(winID, cf)
		if (!ErrorLevel){
			
			save_hwnd := waitAndProcessSaveDialog()
			if (postprocess_sapgui){
				waitForSaveDialogToClose(save_hwnd)
				
				sapgui_postProcess()
			}
		}
		flushLogAndExit()
	}
	
	DefaultKeyStrokes:
	appendLog("sending default keystrokes")
	
	;Default save as keys
	sendSystemListSave(winID)

return
	
;end of sapgui










;;;;;;;;;;;;;;;;;;;;;;
; Debugging hotkeys: ;
;;;;;;;;;;;;;;;;;;;;;;


showGridsAndToolbars(){

	winID := WinGetID("A")

	alvgrids := getControlsByClass(winID, "SAPALVGrid")

	toolbar_window := getToolbarWindowForALVGrid(winID, "null")

	str := "ALV grids: "
	grid := ""
		For Index, alv_grid in alvgrids {
			str .= Value . "," . alv_grid.x . "," . alv_grid.y . "," . alv_grid.w . "," . alv_grid.y . ";"
		}

	MsgBox(str "`r`ntoolbar: " toolbar_window)

	return
	
}


^!z::

KeyWait("Control")
KeyWait("Alt")

	clearLog()
	appendLog("debugging")

	winID := WinGetID("A")

	tb_windows := getControlsByClass(win_id, "ToolbarWindow")
	classes := ""
	for i, e in tb_windows
	{
		classes .= e.classnn ", " e.visible ", " e.x ", " e.y "`r`n"
	}
	MsgBox(classes)


	;rb_control := getControlsByClass(win_id, sapgui_elements.save_list_rb.classnn, true)[1]
	;MsgBox(rb_control.classnn)

	flushLogAndExit()


return

;*/


;;;;;;;;;;;;;;;;;;;;;;;
; Excel               ;
;;;;;;;;;;;;;;;;;;;;;;;
#If WinActive("ahk_exe EXCEL.EXE")
^q::
	
	clearLog()
	appendLog("starting Excel hotkey")
	
	;We don't need the winID here since we can use the COM object
	;WinGet, winID, ID, A
	
	;script must be running at the same privilege level as Excel (i.e. administrator)
	; https://stackoverflow.com/a/43875164
	xl := ComObjActive("Excel.Application")
	
	;copy clipboard and save a second copy to restore it later
	cb := clipboard
	
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

#If WinActive("ahk_exe notepad++.exe")
^q::
	
	clearLog()
	
	cb := clipboard

	appendLog("add column dividers")
	STAD.insertColumnDividers(cb)

	clipboard := cb

	;MsgBox % "ds = '" . ds . "' ts = '" . ts . "'"
	
	flushLogAndExit()
	
	return
;end of Notepad++


;;;;;;;;;;;;;;;;;;;;;;;
; BCP                 ;
;;;;;;;;;;;;;;;;;;;;;;;
#If WinActive("ahk_exe chrome.exe") && ( WinActive("Incident") || WinActive("Chat Incident") || WinActive("Solman Incident") || WinActive("SPC Incident"))
^q::
	
	;paste the clipboard but with non-breaking spaces instead of regular spaces
	nbsp := Chr(0x00A0)

	cb := clipboard
	clipboard := StrReplace(clipboard, " ", nbsp)
	
	Send("^v")

	sleep(10)
	clipboard := cb

return


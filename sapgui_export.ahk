/*
	DONE:
		ALVGrids embedded in the middle of SAP screens
		ALVGrids as the main content of a screen (using MouseGetPos)
		ALVGrid embedded in the middle of SAP screens without relying on MouseGetPos (does ControlGetFocus work? Yes!)
		SAP Signature Theme Support
		Blue Crystal Theme Support
		LAN Check by Ping (No longer buggy! I hope!)
		LAN Check by ping: screen check no longer fails on the "details" screen for manually entered IP address/hostname tests
		STAD Call subrecord dialog
		getClassNNByPartial (now getClassNNByClass) needs to return all controls which match the partial name
		Combine ALVGrid drop down and ALVGrid button functions; filter out exceptions in the main script body
		click and restore function for moving the mouse to make a physical click then restoring the previous location (while supplying the clicked control)
		unhide the standard ALV buttons before trying to click the export button
		function for finding arbitrary buttons in a defined area
		move specific screen functions to secondary files
	
	WIP:
		SAPGUI Theme detection solution for when the screen is maximized (for some reason the second monitor starts at coordinates 8,8 ????)
	
	TODO:
		HARD - Oracle: table and index information dialogs (lots of annoying scrolling)
		MEDIUM - ST13 -> Process Chain runtime Comparison (has 2 grids, top one has no export button T_T )
		HARD - ST12 -> show call hierarchy when turned on
		HARD - SQL summary Statement details (screen which shows fastest, slowest, average, calling source locations)
		
	Notes:
	Try to avoid using ImageSearch where possible; different SAP themes and Character Sets require a lot of work to support
	
	
	SAPGUI hotkeys:
	https://help.sap.com/saphelp_tm80/helpdata/en/48/159ed688474c23e10000000a42189b/frameset.htm
	Keyboard Access in SAP GUI for Windows
		ALV Grid
	
	
*/



#NoEnv


SetDefaultMouseSpeed, 0

/*
	reducing SetKeyDelay will make the script execute faster, but the trade off is stability
	Most of the time spent waiting is for the server to format the output.
	There is little to no appreciable gain to changing this.
*/
;SetKeyDelay, 10





#include lib/helpers.ahk
/*
	Global exec_log:=
	clearLog()
	appendLog(line_num, mes)
	getSapGuiThemePrefix(winID)
	getControlProperties(winID, classnn)
	getClassNNByClass(winID, partialclass, partialtext="")
	moveClickRestore(winID, winx, winy, block=True, byref clicked_classnn = "")
	findImage(x1, y1, x2, y2, name)
*/

#include lib/os01.ahk
/*
	whichLanCheckScreen(winID)
	copyLanCheckScreenDetails(winID)
	copyLanCheckScreen(winID)
*/


findExport(winID, parentclass, btype="button"){
	/*
		parentclass here is an object with properites
		obtained via lib/helpers.ahk:getControlProperties
	*/
	
	appendLog(A_LineNumber, "looking for an export of type '" . btype . "' in control '" . parentclass.classnn . "'")
	
	;construct the filename
	fn := ""
	
	if (btype = "button")
	fn := "export_button"
	else if (btype = "dropdown")
	fn := "export_drop_button"
	
	fn1 := fn . ".png"
	;for compatibility with other character sets
	fn2 := fn . "_chubby.png"
	
	;get the search area
	x1 := parentclass.x, x2 := parentclass.x + parentclass.w
	y1 := parentclass.y, y2 := parentclass.y + parentclass.h
	
	xy := {}
	
	xy := findImage(x1, y1, x2, y2, fn1)
	
	if (ErrorLevel){
		appendLog(A_LineNumber, "could not find the '" . fn1 . "' button in findExport")
		
		;check for the "chubby" version of the button
		xy := findImage(x1, y1, x2, y2, fn2)
		
		if (ErrorLevel){
			appendLog(A_LineNumber, "could not find the '" . fn2 . "' button in findExport")
			return ""
		}
	}
	
	appendLog(A_LineNumber, "found an export at x,y:" . xy.x . "," . xy.y)
	
	return xy
}

waitForExportDropButton(winID, control_to_search, timeout=5){
	
	start_time := A_TickCount
	timeout := timeout * 1000
	
	coord := getControlProperties(winID, control_to_search)
	
	;control should exist
	if (ErrorLevel){
		appendLog(A_LineNumber, "could not retrieve the properties for control '" . control_to_search . "'")
		return
	}
	
	;define search area
	x := coord.x, x2 := coord.x + coord.w
	y := coord.y, y2 := coord.y + coord.y
	
	while ((A_TickCount - start_time) < timeout){
		
		findImage(x, y, x2, y2, "export_drop_button.png")
		
		if (!ErrorLevel){
			return
		}
		
		sleep, 5
	}
	
	ErrorLevel := 1
	appendLog(A_LineNumber, "timeout of " . timeout . "ms reached in waitForExportButton")
	
}

copySTADcallDialog(winID)
{
	/*
		We also want to include the Window Title here for clarity as it's
		not easily discernable by just the data alone. So we need to wait
		for the save dialog to close then modify the clipboard contents
	*/
	
	WinGetTitle, title, ahk_id %winID%
	
	ControlClick, Button2, ahk_id %winID%, , , 2
	waitAndProcessSaveDialog()
	waitForSaveDialogToClose()
	
	Clipboard=%title%`r`n%ClipBoard%
	
	exit
}

getToolbarWindowForALVGrid(winID, alvgridnn){
	
	toolbar_windows := getClassNNByClass(winID, "ToolbarWindow")
	
	if (ErrorLevel){
		appendLog(A_LineNumber, "no ToolbarWindows found for ALVGrid '" . alvgridnn . "' in getToolbarWindowForALVGrid")
		return ""
	}
	
	appendLog(A_LineNumber, "found '" . toolbar_windows.Length() . "' ToolbarWindows in getToolbarWindowForALVGrid")
	
	;no toolbar found, set error level and return
	if (toolbar_windows.Length() = 0){
		ErrorLevel:=1
		return
	}
	
	;exactly one toolbar is found
	if (toolbar_windows.Length() = 1){
		ErrorLevel:=0
		return toolbar_windows[1]
	}
	
	;TODO - search for the most reasonably positioned toolbar if there are multiple.
	;for now we shortcut to the first result
	
	ErrorLevel:=0
	return toolbar_windows[1]
}

unhideStandardALVToolbar(winID, alv_toolbarnn)
{
	
	toolbar := getControlProperties(winID, alv_toolbarnn)
	
	tx := toolbar.x, ty = toolbar.y,
	tx2 := toolbar.x + toolbar.w, ty2 := toolbar.y + toolbar.h
	
	;look for the unhide button
	appendLog(A_LineNumber, "calling findImage(" . tx . "," . ty . "," . tx2 . "," . ty2 . ", ""show_std_alv.png"")")
	coord := findImage(tx, ty, tx2, ty2, "show_std_alv.png")
	
	;if we didn't find un unhide button, either 
	;it's not there or it's already been expanded
	;so we don't need to go any further
	if (ErrorLevel){
		appendLog(A_LineNumber, "no unhide button found.")
		ErrorLevel := 0
		return
	}
	
	;we found an unhide button, so we need to click it.
	moveClickRestore(winID, coord.x + 5, coord.y + 5)
	
	;wait for the toolbar to expand, this is unfortunately a dialog step
	waitForExportDropButton(winID, alv_toolbarnn)
	
}


clickAppToolbarExport(winID){

	appendLog(A_LineNumber, "trying the export button in the standard AppToolbar")
	
	t := getControlProperties(winID, "AppToolbar")
	
	if (ErrorLevel){
		appendLog(A_LineNumber, "couldn't find the standard toolbar, AppToolbar, in processALVGrid")
		return
	}
	
	appendLog(A_LineNumber, "AppToolbar found at x,y:" . t.x . "," . t.y . " with w,h:" . t.w . "," . t.y)
	
	cxy := findExport(winID, t)
	
	if (ErrorLevel){
		appendLog(A_LineNumber, "couldn't find the export button on the standard toolbar in processALVGrid")
		return
	}
	
	;we should see the export button in the standard toolbar now
	cx := cxy.x + 5, cy := cxy.y + 5
	appendLog(A_LineNumber, "ControlClick to x,y:" . cx . "," . cy)
	CoordMode, Mouse, Window
	ControlClick, x%cx% y%cy%, ahk_id %winID%, , , 2
	
	ErrorLevel := 0
}

processALVGrid(winID, alvgrid_nn){
	
	appendLog(A_LineNumber, "processing ALVGrid: '" . alvgrid_nn . "'")
	
	;first we try the nearby ToolbarWindow:
	toolbar_windownn := getToolbarWindowForALVGrid(winID, alvgrid_nn)
	
	if (!ErrorLevel){
		;found a ToolbarWindow
		t := getControlProperties(winID, toolbar_windownn)
		
		appendLog(A_LineNumber, "found a ToolbarWindow: " . t.classnn . "," . t.x . "," . t.y . "," . t.w . "," . t.h)
		
		;ensure the standard ALV buttons are showing (i.e. ST05 hides them by default)
		unhideStandardALVToolbar(winID, t.classnn)
		
		;look for an export button
		eb := findExport(winID, t, "dropdown")
		
		if (ErrorLevel){
			appendLog(A_LineNumber, "couldn't find an export drop down within control '" . t.classnn . "'")
			goto, StandardToolbar
		}
		
		ErrorLevel := 0
		
		;at this point we should see an export drop down button on the toolbar, click it
		moveClickRestore(winID, eb.x + 5, eb.y + 5, True, tbcname)
		
		;Wait for that silly dialog box/menu to appear
		WinWait, ahk_class #32768, , 4

		;send an 'l' to bring up the local file dialog box using the toolbar class name we obtained earlier
		ControlSend, %tbcname%, l, ahk_id %winID%
		
		return
	}
	
	StandardToolbar:
	;try the standard toolbar
	
	clickAppToolbarExport(winID)
	
	return
}


sendSystemListSave(winID=""){
	;can we replace Send with ControlSend? SAPGUI seems to not like controlsend for this purpose
	;But Send is okay here since there should be no delays (i.e. round trips with the server)
	
	;ControlSend, , !y, ahk_id %winID%
	;ControlSend, #32768, ytai, ahk_id %winID%
	
	Send, !ytai
	waitAndProcessSaveDialog()
	exit
}

waitAndProcessSaveDialog(secondsToWait=8)
{
    WinWait, Save list in file..., , %secondsToWait%
	
    ;"ControlSend", sadly, doesn't work in this case, the window seems to ignore {Down n}
    ;But control click works fine! (hopefully they never change the layout of this dialog)
    ControlClick, x25 y220, Save list in file...,,,, Pos
	;doesn't always work unless we sleep for a bit
	Sleep, 10
    ;ControlClick, x210 y255, Save list in file...,,,, Pos
	ControlSend, , {Enter}, Save list in file...
}

waitForSaveDialogToClose(){
	WinWaitClose, Save list in file...
}



;;;;;;;;;;;;;;;;;;;;;;;
; Main Entry point
;;;;;;;;;;;;;;;;;;;;;;;


#IfWinActive ahk_exe saplogon.exe
` Up::
;KeyWait, Control

	WinGet, winID, ID, A
	WinGetTitle, WTitle, ahk_id %winID%
	
	;don't do anything if it's just the Logon window
	if InStr(WTitle, "SAP Logon")
	exit
	clearLog()
	appendLog(A_LineNumber, "checking exception list")
	
	;In case we've already opened a "save list in file..." dialog
	if InStr(WTitle, "Save list in file..."){
		waitAndProcessSaveDialog()
		exit
	}
	
	;Exception list
	;these screens don't use ALV grids or the default key combination
	;Or need some kind of special prep
	
	
    ;ST12 Trace list
    if (WTitle = "Trace analyses fullscreen list"){
		Send, !exl
		waitAndProcessSaveDialog()
		exit
	}
	;ST12 SQL Summary
	else if InStr(WTitle, "SQL Summary - "){
		Send, !exl
		waitAndProcessSaveDialog()
		exit
	}
    ;ST12 trace details
    else if InStr(WTitle, "ABAP Trace Per Call"){
		Send, !sxl
		waitAndProcessSaveDialog()
		exit
	}
	;OS01 - LAN Check by Ping
	else if InStr(WTitle, "LAN Check by PING"){
		copyLanCheckScreen(winID)
		exit
	}
	;STAD RFC subrecord dialog
	else if (InStr(WTitle, "RFC: ") = 1) AND InStr(WTitle, "Records"){
		copySTADcallDialog(winID)
	}
	
	
StandardControls:
	
	appendLog(A_LineNumber, "past exception list")
	
	;past exception list, check if we have an ALVGrid in focus
	ControlGetFocus, cf, ahk_id %winID%
	
	appendLog(A_LineNumber, "current focus is ClassNN: '" . cf . "'")
	
	if InStr(cf, "SAPALVGrid"){
		processALVGrid(winID, cf)
		if (!ErrorLevel)
			waitAndProcessSaveDialog()
		exit
	}
	
	appendLog(A_LineNumber, "sending default keystrokes")
	
	;Default save as keys
	sendSystemListSave(winID)

    return
	
;end of sapgui ^s








/*


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



^!x::
	; WinGet, PName, ProcessName, A
	; if (PName = "saplogon.exe")
	; {
		; WinGetTitle, WTitle, A
		; MsgBox, The active window is "%WTitle%".
	; }

	; WinGet, winID, ID, A
	; WinGetTitle, winTitle, ahk_id %winID%

	; MsgBox, %winID%`n%winTitle%

	WinGet, process, PID, A
	WinGet, winIDs, List, ahk_pid %process%

	Loop, %winIDs%
	{
		id := winIDs%A_Index%
		WinGetTitle, Title, ahk_id %id%
		WinGetClass, wclass, ahk_id %id%
		WinGetPos, wx, wy, ww, wh, ahk_id %id%
		
		if (wclass = "WindowsFormsSapFocus") ;focus rectangle
			continue
		if InStr(wclass, "Afx") ;session borders
			continue
		
		;if (wclass = "#32768")
			MsgBox, %id%`n%Title%`n%wclass%`nX:%wx%,Y:%wy%`nW:%ww%,H:%wh%
	}

return


^!z::

KeyWait, Control
KeyWait, Alt

clearLog()

WinGet, winID, ID, A

processALVGrid(winID, "SAPALVGrid1")





return

^`::
	MsgBox, %exec_log%
return

;*/
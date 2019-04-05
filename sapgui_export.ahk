/*
	DONE:
		ALVGrids embedded in the middle of SAP screens
		ALVGrids as the main content of a screen (using MouseGetPos)
		ALVGrid embedded in the middle of SAP screens without relying on MouseGetPos (does ControlGetFocus work? Yes!)
		SAP Signature Theme Support
		Blue Crystal Theme Support
		LAN Check by Ping (still buggy in weird edge cases)
		STAD Call subrecord dialog
	
	WIP:
		
	
	TODO:
		Oracle: table and index information windows
		Combine ALVGrid drop down and ALVGrid button functions; filter out exceptions in the main script body
		SAPGUI Theme detection solution for when the screen is maximized (for some reason the second monitor starts at coordinates 8,8 ????)
		
	Notes:
	Try to avoid using ImageSearch where possible; different SAP themes and Character Sets require a lot of work to support
	
	SAPGUI hotkeys:
	https://help.sap.com/saphelp_tm80/helpdata/en/48/159ed688474c23e10000000a42189b/frameset.htm
	Keyboard Access in SAP GUI for Windows
		ALV Grid
	
	
*/




SetDefaultMouseSpeed, 0
;SetKeyDelay, 10


Global flow_tracking:=


getSapGuiThemePrefix(winID)
{
	/*
		Important to know the theme when searching for buttons
		
		Colors are in RGB hex
	*/
	
	blue_crystal = 0x009DE0
	
	CoordMode, Pixel, Window
	PixelGetColor, bar_color, 3, 3, RGB
	
	if (bar_color = blue_crystal)
	return "bc_"
	
	; search the upper right for the signature exit button
	WinGetPos, , , xw, , ahk_id %winID%
	
	x1:=xw-100
	y1:=0
	x2:=xw
	y2:=40
	
	ImageSearch, , , x1, y1, x2, y2, *50 themes/signature.png
	
	if (!ErrorLevel)
	return "" ;signature theme image names have no prefix
	
	MsgBox Unsupported theme. Supported themes are:`r`nSAP Signature Theme`r`nBlue Crystal Theme`r`nIf you are receiving this message despite using a supported theme, mail I844387.
	exit
}

getClassNNByPartial(winID, partialclass, partialtext="")
{
	/*
		Obtains the ClassNN of a control which contains
		partialclass in the Control ClassNN and
		partialtext in the Control Text
	*/
	WinGet, controls, ControlList, ahk_id %winID%
	;MsgBox %controls%
	
	Loop, Parse, controls, `n
	{
		cname = %A_LoopField%
		if InStr(cname, partialclass)
		{
			;only want visible controls
			ControlGet, isvisible, Visible, , %cname%, ahk_id %winID%
			if (!isvisible)
			continue
			
			ControlGetText, ctext, %cname%, ahk_id %winID%
			
			if (partialtext = "")
			return cname
			
			if InStr(ctext, partialtext)
			return cname
		}
	}
	return ""
}

whichLanCheckScreen(winID)
{
	/*
		Used to determine which OS01 screen we're on at the moment
		by examining the layout
	*/
	
	;check if button15 is visible first -> Server selection screen
	ControlGet, bvisible, Visible, , Button15, ahk_id %winID%
	if (ErrorLevel) ;if button doesn't exist, then we're not in OS01
	return ""
	if (bvisible) ;button not visible, we're in the detail screen
	return "serverlist"
	
	;check if button6 is visible next -> Server type screen
	ControlGet, bvisible, Visible, , Button6, ahk_id %winID%
	if (bvisible) ;button not visible, we're in the detail screen
	return "servertypelist"
	
	;check if button3 is visible last -> Results screen
	ControlGet, bvisible, Visible, , Button3, ahk_id %winID%
	if (bvisible) ;button not visible, we're in the detail screen
	return "results"
	
	;last possibility is the Details screen
	return "details"
}

copyLanCheckScreenDetails(winID)
{
	/*
		assumes we are on the LAN check details screen
		e.g.:   "03.04.2019 05:31:00       from <hostname> (n.n.n.n)"
		
		ControlSend is not reliable due to SAPGUI interpretation time
		Controls sent with ControlSend might be ignore or behave weirdly
		if SAPGUI is making UI adjustments (like shading a button you just hovered over)
	*/
	
	;Get the header text
	header_classnn:=getClassNNByPartial(winID, "Internet Explorer_Server")
	ControlFocus, %header_classnn%, ahk_id %winID%
	Send, ^a^c
	
	;save to clipboard and get rid of some whitespace
	output:=ClipBoard
	output:=StrReplace(output, "`r`n")
	output:=RegExReplace(output, " {1,}", " ")
	
	;get the body text
	body_classnn:=getClassNNByPartial(winID, "SAPALVGrid")
	ControlFocus, %body_classnn%, ahk_id %winID%
	
	;ControlSend is unreliable here
	Send, {Down}^{Space}^c

	output=%output%`r`n`r`n%ClipBoard%
	
	Clipboard:=output
}


copyLanCheckScreen(winID)
{
	/*
		The screens for ping result (overall and individual)
	*/
	
	;we have to find out which screen we're on, the titles are the same for the most part
	os01_screen:=whichLanCheckScreen(winID)
	
	if (os01_screen = "serverlist"){
		if (tryExportButton(winID))
		waitAndProcessSaveDialog()
		exit
	}
	
	if (os01_screen = "results"){
		sendSystemListSave(winID)
	}
	
	if (os01_screen = "details")
	copyLanCheckScreenDetails(winID)
	
}


waitForScroll()
{
	
	
}

copyExecPlanDialog(winID)
{
	/*
		The dialog window for the explain plan starts at 5,30
		and ends at WinWidth-25,WinHeight-45
	*/
	
	
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
	
}


tryExportDropDown(winID, ALVcname)
{
    /*  
		SAPGUI ALV tables (without the application toolbar) ignores control clicks.
		Not only that, it does this awful thing when a click event is registered 
		in SAPGUI: SAPGUI ignores the click event's X,Y coordinates and instead 
		reads the current mouse's position. As a result, we can't simply send a 
		click event at exportX,exportY, we have to temporarily take control of the 
		mouse and move it over the button.
    */
	
	flow_tracking=%flow_tracking%%A_LineNumber%: entering export drop down`r`n
	
	;save current window
	WinGet, winID, ID, A
	WinGetPos, WX, WY, WW, WH, ahk_id %winID%
	
	;get the top border of the ALV grid
	ControlGetPos, alvx, alvy, alvw, , %ALVcname%, ahk_id %winID%
	
	if (alvx = ""){ ;can't find the ALV control
	flow_tracking=%flow_tracking%%A_LineNumber%: can't find ALV control`r`n
	return false
	}
	
	;adjust for the toolbar search area
	alvy2:=alvy
	alvy-=80
	alvx2:=alvx+alvw
	
	theme_prefix:=getSapGuiThemePrefix(winID)
	
	;find the button
	CoordMode, Pixel, Window
	ImageSearch, exportX, exportY, alvx, alvy, alvx2, alvy2, *30 %theme_prefix%export_drop_button.png
	
	;In certain character sets, the buttons get kind of "chubby"
	;check for this incase the above search didn't find anything
	if (ErrorLevel)
	ImageSearch, exportX, exportY, alvx, alvy, alvx2, alvy2, *30 %theme_prefix%export_drop_button_chubby.png
	
	;incase we couldn't find a button
	if (ErrorLevel)
	return false
	
	flow_tracking=%flow_tracking%%A_LineNumber%: found a button, clicking now`r`n
	
    CoordMode, Mouse, Screen

    ;window screen position + relative posisiton of the button + small offset
    exportX:=WX+exportX+10
    exportY:=WY+exportY+5

    ;get the mouse's current position to restore later
    MouseGetPos, mX, mY

    ;move the mouse over the button, get the class name of the toolbar, and invoke a click
    BlockInput, On
    Click, %exportX%, %exportY%
	MouseGetPos, , , , tbcname
    BlockInput, Off

    ;move the mouse back so as not to annoy the user (as much)
    MouseMove, mX, mY, 0
	
	;Wait for that silly dialog box/menu to appear
    WinWait, ahk_class #32768, , 3

    ;send an 'l' to bring up the local file dialog box using the toolbar class name we obtained earlier
    ControlSend, %tbcname%, l, ahk_id %winID%
    
    return true
}


tryExportButton(winID)
{
	/*
		The button on the ALV toolbar does not have a consistent classNN name 
		across Tcodes/screens. Thus, as a catch all, we can identify it based 
		on icon. However, we know it lives inside the container control with 
		text "AppToolbar"
		is consistent across screens
	*/
	
	
	
	;get the position of the toolbar, this is our image search area
	ControlGetPos, tx, ty, tw, th, AppToolbar, ahk_id %winID%
	
	if (tx = "") ;this screen doesn't have a toolbar
	return false
	
	;caluclate lower right x,y for the image search
	tx2:=tx+tw
	ty2:=ty+th
	
	theme_prefix:=getSapGuiThemePrefix(winID)
	
	;find the export button on the toolbar
	CoordMode, Pixel, Window
	ImageSearch, exportX, exportY, tx, ty, tx2, ty2, *50 %theme_prefix%export_button.png
	
	;In certain character sets, the buttons get kind of "chubby"
	;check for this incase the above search didn't find anything
	if (ErrorLevel)
	ImageSearch, exportX, exportY, tx, ty, tx2, ty2, *50 %theme_prefix%export_button_chubby.png
	
	;MsgBox image found at %exportX%,%exportY%
	
	if (ErrorLevel) ;this toolbar doesn't have an export button
	return false
	
	exportX+=5
	exportY+=3
	
	;MsgBox I am going to click at %exportX%,%exportY%.
	
	;sending a control click to the window is fine
	;for some reason it fails with only a single click sometimes...
	CoordMode, Mouse, Window
	ControlClick, x%exportX% y%exportY%, ahk_id %winID%, , , 2
	
	return true
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

#IfWinActive ahk_exe saplogon.exe
` Up::
;KeyWait, Control

	WinGet, winID, ID, A
	WinGetTitle, WTitle, ahk_id %winID%
	
	;don't do anything if it's just the Logon window
	if InStr(WTitle, "SAP Logon")
	exit
	flow_tracking=
	flow_tracking=%flow_tracking%%A_LineNumber%: checking exception list`r`n
	
	;Exception list
	;these screens don't use ALV grids or the default key combination
	
    ;ST12 Trace list
    if (WTitle = "Trace analyses fullscreen list"){
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
	else if InStr(WTitle, "LAN Check by PING"){
		copyLanCheckScreen(winID)
		exit
	}
	else if (InStr(WTitle, "RFC: ") = 1) AND InStr(WTitle, "Records"){
		copySTADcallDialog(winID)
	}
	
	flow_tracking=%flow_tracking%%A_LineNumber%: past exception list trying ALVGrid button`r`n
	
	;past exception list, check if we have an ALVGrid in focus
	ControlGetFocus, cf, ahk_id %winID%
	if InStr(cf, "SAPALVGrid"){
		if (tryExportDropDown(winID, cf)){
			waitAndProcessSaveDialog()
			exit
		}
	}
	
	flow_tracking=%flow_tracking%%A_LineNumber%: trying apptoolbar button`r`n
	
	;at this point, check for an export button in the AppToolbar
	if (tryExportButton(winID)){
		waitAndProcessSaveDialog()
		exit
	}
	
	flow_tracking=%flow_tracking%%A_LineNumber%: sending default keystrokes`r`n
	
	;Default save as keys
	sendSystemListSave(winID)

    return
	
;end of sapgui ^s


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

	WinGet, winID, ID, A

	prefix:=getSapGuiThemePrefix(winID)

	MsgBox prefix="%prefix%"

return

^`::
	MsgBox, %flow_tracking%
return

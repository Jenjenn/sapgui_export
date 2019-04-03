/*
	DONE:
		ALVGrids embedded in the middle of SAP screens
		ALVGrids as the main content of a screen (using MouseGetPos)
		ALVGrid embedded in the middle of SAP screens without relying on MouseGetPos (does ControlGetFocus work? Yes!)
	
	WIP:
		LAN Check by Ping
	
	TODO:
		Oracle: table and index information windows
		
	
*/

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
		if InStr(cname, partialclass) ;"Afx:"
		{
			ControlGetText, ctext, %cname%, ahk_id %winID%
			
			if (partialtext = "")
			return cname
			
			if InStr(ctext, partialtext) ; AppToolbar
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


copyLanCheckScreenResults(winID)
{
	/*
		assumes we are on the LAN check results screen
		i.e. regular list output, just send !ytai
	*/
	
	
}

copyLanCheckScreenDetails(winID)
{
	/*
		assumes we are on the LAN check details screen
		e.g.:   "03.04.2019 05:31:00       from <hostname> (n.n.n.n)"
   
	*/
}


copyLanCheckScreen(winID)
{
	/*
		The screens for ping result (overall and individual)
	*/
	
	;we have to find out which screen we're on, the titles are the same for the most part
	
	
	
	
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
	
	
	;save current window
	WinGet, winID, ID, A
	WinGetPos, WX, WY, WW, WH, ahk_id %winID%
	
	;get the top border of the ALV grid
	ControlGetPos, alvx, alvy, alvw, , %ALVcname%, ahk_id %winID%
	
	if (alvx = "") ;can't find the ALV control
	return false
	
	;adjust for the toolbar search area
	alvy2:=alvy
	alvy-=80
	alvx2:=alvx+alvw
	
	;find the button
	CoordMode, Pixel, Window
	ImageSearch, exportX, exportY, alvx, alvy, alvx2, alvy2, *30 export_drop_button.png
	
	;In certain character sets, the buttons get kind of "chubby"
	;check for this incase the above search didn't find anything
	if (ErrorLevel)
	ImageSearch, exportX, exportY, alvx, alvy, alvx2, alvy2, *30 export_drop_button_chubby.png
	
	;incase we couldn't find a button
	if (ErrorLevel)
	return false
	
    CoordMode, Mouse, Screen

    ;window screen position + relative posisiton of the button + small offset
    exportX:=WX+exportX+10
    exportY:=WY+exportY+5

    ;get the mouse's current position to restore later
    MouseGetPos, mX, mY

    ;move the mouse over the button, get the class name of the toolbar, and invoke a click
    BlockInput, On
    MouseMove, exportX, exportY, 0
    MouseGetPos, , , , tbcname
    Click
    BlockInput, Off

    ;move the mouse back so as not to annoy the user (as much)
    MouseMove, mX, mY, 0
	
	;Wait for that silly dialog box to appear
    WinWait, ahk_class #32768, , 3

    ;send an 'l' to bring up the local file dialog box using the toolbar class name we obtained earlier
    ControlSend, %tbcname%, l, ahk_id %winID%
    
    return true
}


tryExportButton()
{
	/*
		The button on the ALV toolbar does not have a consistent classNN name 
		across Tcodes/screens. Thus, as a catch all, we can identify it based 
		on icon. However, we know it lives inside the container control with 
		text "AppToolbar"
		is consistent across screens
	*/
	
	WinGet, winID, ID, A
	
	;get the position of the toolbar, this is our imagesearch area
	ControlGetPos, tx, ty, tw, th, AppToolbar, ahk_id %winID%
	
	if (tx = "") ;this screen doesn't have a toolbar
	return false
	
	;caluclate lower right x,y of imagesearch
	tx2:=tx+tw
	ty2:=ty+th
	
	;find the export button on the toolbar
	CoordMode, Pixel, Window
	ImageSearch, exportX, exportY, tx, ty, tx2, ty2, *50 export_button.png
	
	;In certain character sets, the buttons get kind of "chubby"
	;check for this incase the above search didn't find anything
	if (ErrorLevel)
	ImageSearch, exportX, exportY, tx, ty, tx2, ty2, *50 export_button_chubby.png
	
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


waitAndProcessSaveDialog(secondsToWait=8)
{
    WinWait, Save list in file..., , %secondsToWait%
	
    ;"ControlSend", sadly, doesn't work in this case, the window seems to ignore {Down n}
    ;But control click works fine! (hopefully they never change the layout of this dialog)
    ControlClick, x25 y220, Save list in file...,,,, Pos
	Sleep, 10
    ;ControlClick, x210 y255, Save list in file...,,,, Pos
	ControlSend, , {Enter}, Save list in file...
	
	;no matter where we're called from, the script is done now
	exit
}


` Up::
WinGet, winID, ID, A
;check process name
WinGet, PName, ProcessName, ahk_id %winID%
if (PName = "saplogon.exe")
{
	WinGetTitle, WTitle, ahk_id %winID%
	
	;Exception list
	;these screens don't use ALV grids or the default key combination
	
    ;ST12 Trace list
    if (WTitle = "Trace analyses fullscreen list"){
		Send, !exl
		waitAndProcessSaveDialog()
	}
    ;ST12 trace details
    else if InStr(WTitle, "ABAP Trace Per Call"){
		Send, !sxl
		waitAndProcessSaveDialog()
	}
	
	;past exception list, check if we have an ALVGrid in focus
	ControlGetFocus, cf, ahk_id %winID%
	if InStr(cf, "SAPALVGrid"){
		if (tryExportDropDown(winID, cf))
		waitAndProcessSaveDialog()
	}
	
	;at this point, check for an export button in the AppToolbar
	if (tryExportButton())
	waitAndProcessSaveDialog()
	
	;Default save as keys
	Send, !ytai
	waitAndProcessSaveDialog()

    return
}


return

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

ControlGetFocus, ovar, A
if(ErrorLevel)
MsgBox I don't know what you have focus on
else
MsgBox %ovar%

return



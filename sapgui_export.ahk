tryExportDropDown()
{
    /*  
		SAPGUI ALV tables (without the application toolbar) ignores control clicks.
		Not only that, it does this awful thing when a click event is registered 
		in SAPGUI: SAPGUI ignores the click event's X,Y coordinates and instead 
		reads the current mouse's position. As a result, we can't simply send a 
		click event at exportX,exportY, we have to temporarily take control of the 
		mouse and move it over the button.
    */
	
	;get the control we're hovering over
	MouseGetPos, , , , ALVclassname
	
	;make sure it's an ALV grid
	if not InStr(ALVclassname, "SAPALVGrid")
	return false
		
	;save current window
	WinGet, winID, ID, A
	WinGetPos, WX, WY, WW, WH, ahk_id %winID%
	
	;get the top border of the ALV grid
	ControlGetPos, alvx, alvy, alvw, , %ALVclassname%, ahk_id %winID%
	
	;adjust for the toolbar search area
	alvy2:=alvy
	alvy-=40
	alvx2:=alvx+alvw
	
	;find the button
	CoordMode, Pixel, Window
	ImageSearch, exportX, exportY, alvx, alvy, alvx2, alvy2, export_drop_button.png
	
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
    MouseGetPos, , , , classname
    Click
    BlockInput, Off

    ;move the mouse back so as not to annoy the user (as much)
    MouseMove, mX, mY, 0
	
	;Wait for that silly dialog box to appear
    WinWait, ahk_class #32768, , 3

    ;send an 'l' to bring up the local file dialog box using the classname we obtained earlier
    ControlSend, %classname%, l, ahk_id %winID%
    
    return true
}

getAppToolbarClassNN(winID)
{
	/*
		The AppToolbar which contains the export button does not have a consistent classNN.
		However, it does have a consistent inner text (AppToolbar)
		Check all the controls for the correct text and return the classNN
		If we don't find it, return blank
	*/
	WinGet, controls, ControlList, ahk_id %winID%
	;MsgBox %controls%
	
	Loop, Parse, controls, `n
	{
		cname = %A_LoopField%
		if InStr(cname, "Afx:")
		{
			ControlGetText, ctext, %cname%, ahk_id %winID%
			if (ctext = "AppToolbar")
			return cname
		}
	}
	return ""
}

tryExportButton()
{
	/*
		The button on the ALV toolbar does not have a consistent classNN name 
		across Tcodes/screens. Thus, as a catch all, we can identify it based 
		on icon. However, we know it lives inside the container control with 
		text "App Toolbar"
		is consistent across screens
	*/
	
	WinGet, winID, ID, A
	toolbar := getAppToolbarClassNN(winID)
	;MsgBox the toolbar class name is %toolbar%
	
	if (toolbar = "") ;this screen doens't have an apptoolbar
	return false
	
	;get the position of the toolbar, this is our imagesearch area
	ControlGetPos, Tx, Ty, Tw, Th, %toolbar%, ahk_id %winID%
	;MsgBox the toolbar is at %Tx%,%Ty% and is %Tx% wide and %Th% high.
	
	if (Tx = "") ;this screen doesn't have a toolbar
	return false
	
	;caluclate lower right x,y of imagesearch
	Tw+=Tx
	Th+=Ty
	
	;find the export button on the toolbar
	CoordMode, Pixel, Window
	ImageSearch, exportX, exportY, Tx, Ty, Tw, Th, *100 export_button.png
	;MsgBox image found at %exportX%,%exportY%
	
	
	if (ErrorLevel) ;this toolbar doesn't have an export button
	return false
	
	exportX+=5
	exportY+=3
	
	;MsgBox I am going to click at %exportX%,%exportY%.
	
	;sending a control click to the window is fine
	CoordMode, Mouse, Window
	
	;for some reason it fails with only a single click sometimes...
	ControlClick, x%exportX% y%exportY%, ahk_id %winID%, , , 2
	;ControlClick, x%exportX% y%exportY%, ahk_id %winID%
	
	return true
	
}


` Up::
;check process name
WinGet, PName, ProcessName, A
if (PName = "saplogon.exe")
{
	WinGetTitle, WTitle, A
	
	;these screens don't use ALV grids or the default key combination
	
    ;ST12 Trace list
    if (WTitle = "Trace analyses fullscreen list")
    Send, !exl
    
    ;ST12 trace
    else if InStr(WTitle, "ABAP Trace Per Call")
    Send, !sxl
	
	else if (tryExportDropDown())
	{}
	else if (tryExportButton())
	{}
	else
	;Default save as keys
	Send, !ytai
	
	
    ;wait for the "Save list in file..." dialog to appear
    WinWait, Save list in file..., , 2
	
    ;Cant use "Send" because it might not be the active window when it appears
    ;"ControlSend", sadly, doesn't work in this case, the window seems to ignore {Down n}
    ;But control click works fine! (hopefully they never change the layout of this dialog)
    ControlClick, x25 y220, Save list in file...,,,, Pos
	Sleep, 10
    ;ControlClick, x210 y255, Save list in file...,,,, Pos
	ControlSend, , {Enter}, Save list in file...

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

;clickExportButton()

;WinGet, winID, ID, A

tryExportButton()

return



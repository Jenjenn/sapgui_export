clickExportDropDown()
{
    /*  
		SAPGUI ALV tables (without the application toolbar) ignores control clicks.
		Not only that, it does this awful thing when a click event is registered 
		in SAPGUI: SAPGUI ignores the click event's X,Y coordinates and instead 
		reads the current mouse's position. As a result, we can't simply send a 
		click event at exportX,exportY, we have to temporarily take control of the 
		mouse and move it over the button.
    */
	
    WinGet, winID, ID, A
    WinGetPos, WX, WY, WW, WH, ahk_id %winID%
    
    CoordMode, Pixel, Window
    ImageSearch, exportX, exportY, 0, 0, WW, WH, export_drop_button.png
	
	if (ErrorLevel != 0){
		MsgBox We couldn't find the Export Button. RC=%ErrorLevel%
		Exit
	}

    ;MsgBox The button is at %exportX%,%exportY%

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
    
    return
}

clickExportButton()
{
	/*
		The button on the ALV toolbar does not have a consistent classNN name 
		across Tcodes/screens. Thus, as a catch all, we can identify it based 
		on icon. However, we know it lives inside the container control with 
		text "App Toolbar" and clasNN =
		Afx:0F480000:8:00010005:00000000:000000001
		is consistent across screens
	*/
	
	WinGet, winID, ID, A
	ControlGetPos, Tx, Ty, Tw, Th, Afx:0F480000:8:00010005:00000000:000000001, ahk_id %winID%
	
	;caluclate lower right x,y of imagesearch
	Tw+=Tx
	Th+=Ty
	
	;find the export button on the toolbar
	CoordMode, Pixel, Window
	ImageSearch, exportX, exportY, Tx, Ty, Tw, Th, export_button.png
	
	exportX+=5
	exportY+=3
	
	;sending a control click to the window is fine
	CoordMode, Mouse, Window
	ControlClick, x%exportX% y%exportY%, ahk_id %winID%
	
}


` Up::
;check process name
WinGet, PName, ProcessName, A
if (PName = "saplogon.exe")
{
    WinGetTitle, WTitle, A
	
    ;ST12 Trace list
    if     (WTitle = "Trace analyses fullscreen list")
    Send, !exl
    
    ;ST12 trace
    else if InStr(WTitle, "ABAP Trace Per Call")
    Send, !sxl
    
    ;ST03
    else if InStr(WTitle, "Workload Monitor")
    clickExportDropDown()
    else if InStr(WTitle, "Workload in System")
    clickExportDropDown()
    else if InStr(WTitle, "Last Minutes Load on")
    clickExportDropDown()
    else if InStr(WTitle, "Load History")
    clickExportDropDown()
    else if InStr(WTitle, "Instance Comparison")
    clickExportDropDown()
    
	;SM50
	else if (WTitle = "Process Overview")
	clickExportButton()
	
	;New SM66
	else if InStr(WTitle, "Work Processes of All AS Instances of System")
	clickExportButton()
	
	;/SDF/MON WP table
	else if (WTitle = "Work Process Overview")
	clickExportButton()
	
	;AL11 directory list
	else if InStr(WTitle, "SAP Directories")
	clickExportButton()
	
    ;Oracle cockpit
    else if (WTitle = "SQL Command Editor")
    clickExportDropDown()
	else if (WTitle = "IO Activities")
    clickExportDropDown()
	else if (WTitle = "Analyze DB Performance: Shared Cursor Cache")
    clickExportDropDown()
	
	
    ;Hana cockpit
    else if (WTitle = "SQL Editor") {
        clickExportDropDown()
    }
	
	;DB6 cockpit
	else if (WTitle = "Time Spent Analysis") {
        clickExportDropDown()
    }
	
    else
    ;Default save as keys
    Send, !ytai
    
    
    ;wait for the "Save list in file..." dialog to appear
    WinWait, Save list in file..., , 4
	
    ;Cant use "Send" because it might not be the active window when it appears
    ;"ControlSend", sadly, doesn't work in this case, the window seems to ignore {Down n}
    ;But control click works fine! (hopefully they never change the layout of this dialog)
    ;Sleep, 5
    ControlClick, x25 y220, Save list in file...,,,, Pos
    ControlClick, x210 y255, Save list in file...,,,, Pos

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

return



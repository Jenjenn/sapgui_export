Global exec_log:=

clearLog(){
	global exec_log:=
}

appendLog(line_num, mes){
	global exec_log .= line_num . ": " . mes . "`r`n"
	return
}


getSapGuiThemePrefix(winID)
{
	/*
		Important to know the theme when searching for buttons
		
		Colors are in RGB hex
	*/
	
	;Can't use this since the Starting position of the
	;window can change if it's on your secondary monitor
	;blue_crystal = 0x009DE0
	
	CoordMode, Pixel, Window
	;PixelGetColor, bar_color, 3, 3, RGB
	
	;search for the SAPGUI window menu button in the top left
	ImageSearch, , , 0, 0, 48, 40, *20 themes/blue_crystal.png
	
	if (!ErrorLevel)
	return "bluecrystal/"
	
	; search the upper right for the signature exit button
	WinGetPos, , , xw, , ahk_id %winID%
	
	x1:=xw-100
	y1:=0
	x2:=xw
	y2:=40
	
	ImageSearch, , , x1, y1, x2, y2, *50 themes/signature.png
	
	if (!ErrorLevel)
	return "signature/"
	
	MsgBox Unsupported theme. Supported themes are:`r`nSAP Signature Theme`r`nBlue Crystal Theme`r`nIf you are receiving this message despite using a supported theme, mail I844387.
	
	exit
}


getControlProperties(winID, classnn){
	
	ControlGetPos, x, y, w, h, %classnn%, ahk_id %winID%
	
	;check we found something
	if (x = ""){
		ErrorLevel := 1
		return ""
	}
	
	cntl := {}
	cntl.parentWinID := winID
	cntl.classnn := classnn
	cntl.x := x
	cntl.y := y
	cntl.w := w
	cntl.h := h
	
	ErrorLevel := 0
	return cntl
}


getClassNNByClass(winID, partialclass, partialtext="")
{
	/*
		Obtains the ClassNN of a controls which contain
		partialclass in the Control ClassNN and
		partialtext in the Control Text
	*/
	
	appendLog(A_LineNumber, "looking for controls with class name '" . partialclass . "'")
	
	WinGet, controls, ControlList, ahk_id %winID%
	;MsgBox %controls%
	
	Results:=Array()
	
	Loop, Parse, controls, `n
	{
		cname = %A_LoopField%
		
		;I only want visible controls (for now)
		ControlGet, isvisible, Visible, , %cname%, ahk_id %winID%
		if (!isvisible)
		continue
		
		if RegExMatch(cname, partialclass . "\d{1,}")
		{
			ControlGetText, ctext, %cname%, ahk_id %winID%
			
			if (partialtext = "" 
			OR InStr(ctext, partialtext)){
				appendLog(A_LineNumber, "found a matching control: '" . cname . "'")
				Results.push(cname)
			}
		}
	}
	
	if (Results.length() = 0){
		ErrorLevel := 1
		Results := ""
	}
	else
		ErrorLevel := 0
	
	
	return Results
}

moveClickRestore(winID, winx, winy, block=True, byref clicked_classnn = ""){
	
	;get the mouse position so we can restore it later
	CoordMode, Mouse, Screen
	MouseGetPos, mx, my
	
	CoordMode, Mouse, Window
	
	if (block)
		BlockInput, On
    Click, %winx%, %winy%
	;sometimes we want to know what was clicked
	MouseGetPos, , , , classnn
    BlockInput, Off
	
	CoordMode, Mouse, Screen
	MouseMove, mx, my, 0
}

findImage(x1, y1, x2, y2, name){
	
	coord:={}
	
	;we need to know the theme to find the correct button
	theme_pf:=getSapGuiThemePrefix(winID)
	
	image_path := theme_pf . name
	
	;check that the image exists:
	if (FileExist(image_path) = ""){
		MsgBox, File not found : "%image_path%" . Exiting script
		exit
	}
	
	CoordMode, Pixel, Window
	ImageSearch, bx, by, x1, y1, x2, y2, *50 %image_path%
	
	if (ErrorLevel){
		return ""
	}
	
	coord.x := bx, coord.y := by
	
	appendLog(A_LineNumber, "found image '" . name . "' at x,y:" . coord.x . "," . coord.y)
	
	return coord
}
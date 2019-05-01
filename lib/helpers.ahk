/*
	Contains helper functions for all other files
	
	Multidimensial arrays:
	https://autohotkey.com/board/topic/99583-quick-how-do-i-make-a-multidimensional-array/
*/


/*
	Sources for different export button visuals:
	ToolbarWindow:
		ALVgrid drop down : ST04 -> SQL Command Editor
		ALVgrid button    : SAT -> Hit List
		
	AppToolbar:
		button            : SM50
*/


Global sapgui_theme_images:={}

;Signature theme images
sapgui_theme_images.signature:=[]
sapgui_theme_images.signature[1]:=LoadPicture("signature/western_menu.png")
sapgui_theme_images.signature[2]:=LoadPicture("signature/western_menu_inverted.png")
sapgui_theme_images.signature[3]:=LoadPicture("signature/eastern_menu.png")
sapgui_theme_images.signature[4]:=LoadPicture("signature/eastern_menu_inverted.png")







getSapGuiThemePrefix(winID)
{
	/*
		Important to know the theme when searching for buttons
		Colors are in RGB hex
	*/
	
	;the window's y starts at 8 if it's maximized
	WinGet, is_max, MinMax, ahk_id %winID%
	offset:= is_max = 1 ? 8 : 0

/*  ;;;;;;;;;;;;;;;;;;
	Blue Crystal Theme
*/	;;;;;;;;;;;;;;;;;;

	blue_crystal = 0x009DE0
	
	CoordMode, Pixel, Window
	PixelGetColor, bar_color, 12, % offset + 2, RGB
	
	/*
	MsgBox % "winID = " . winID
	. "`r`nis_max = " . is_max
	. "`r`nyoffset = " . offset
	. "`r`nbar color is : " . bar_color
	*/
	
	if (bar_color = blue_crystal)
		return "bluecrystal/"
	
/*  ;;;;;;;;;;;;;;;
	Signature Theme
*/  ;;;;;;;;;;;;;;;
	
	
	; search the upper left for the window menu buttons
	WinGetPos, , , xw, , ahk_id %winID%
	
	x1:=offset
	y1:=offset
	x2:=50 + offset
	y2:=50 + offset
	
	CoordMode, Pixel, Window
;	for i, image in sapgui_signature_theme_images {
;		ImageSearch, , , x1, y1, x2, y2, *10 HBITMAP:*%image%
;		if (!ErrorLevel)
;			return "signature/"
;	}
	
	for i, image in sapgui_theme_images.signature {
		ImageSearch, , , x1, y1, x2, y2, *10 HBITMAP:*%image%
		if (!ErrorLevel)
			return "signature/"
	}
	
	
/*  ;;;;;;;;;;;;;;
	No Theme Found
*/  ;;;;;;;;;;;;;;
	
	;MsgBox Unsupported theme. Supported themes are:`r`nSAP Signature Theme`r`nBlue Crystal Theme`r`nIf you are receiving this message despite using a supported theme, mail I844387.
	
	flushLogAndExit()
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

getDistanceBetweenTwoControls(win_id, c1, c2){
/*
	Accepts classnn values
	returns the distance between the top left corners of two controls
*/
	ControlGetPos, x1, y1, , , %c1%, ahk_id %win_id%
	ControlGetPos, x2, y2, , , %c2%, ahk_id %win_id%
	
	return sqrt( (x1 - x2)**2 + (y1 - y2)**2 )
}

getClassNNByClass(winID, partialclass, partialtext="")
{
	/*
		Obtains the ClassNN of a controls which contain
		partialclass in the Control ClassNN and
		partialtext in the Control Text
	*/
	
	appendLog("looking for '" . partialclass . "' in getClassNNByClass")
	
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
				appendLog("found '" . cname . "'")
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

findImage(winID, x1, y1, x2, y2, name){
	
	appendLog("findImage(" . x1 . "," . y1 . "," . x2 . "," . y2 . ", " . name . ")")
	
	coord:={}
	
	;we need to know the theme to find the correct button
	theme_pf:=getSapGuiThemePrefix(winID)
	
	image_path := theme_pf . name
	
	;check that the image exists:
	if (FileExist(image_path) = ""){
		appendLog("'" . image_path . "' not found. Has it been screenshot yet?")
		ErrorLevel:=2
		return ""
	}
	
	CoordMode, Pixel, Window
	ImageSearch, bx, by, x1, y1, x2, y2, *50 %image_path%
	
	if (ErrorLevel)
		return ""
	
	coord.x := bx, coord.y := by
	
	appendLog("found image; returning x,y:" . coord.x . "," . coord.y)
	
	return coord
}
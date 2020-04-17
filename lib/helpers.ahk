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

/*
	image library hierarchy:
	
	root -> theme -> image_name -> [image handles & properties]
	e.g.
	root -> blue_crystal -> tbw_drop -> western
	root -> blue_crystal -> tbw_drop -> eastern
	root -> blue_crystal -> tbw_drop -> type
	
	(we need to know what *type* of GUI control it is to know how)
	(to proceed after clicking it; e.g. button vs drop down    )
	
	Or should I do it this way:
	root -> blue_crystal -> tbw_drop -> variants -> array with different styles
	(this allows arbitrary number of visual styles vs just eastern & western)
	root -> blue_crystal -> tbw_drop -> type
*/

Global SUPPORTED_THEMES := ["blue_crystal","signature"]

;preload the visual elements of SAPGUI
Global sapgui_elements := {}
	
	;the export button which appears in ToolbarWindow controls
	;sapgui_elements.tbw_exp_drop := { etype:"dd_button" }
	sapgui_elements.tbw_exp_drop := {}
	
		sapgui_elements.tbw_exp_drop.etype := "dd_button" 
	
		sapgui_elements.tbw_exp_drop.blue_crystal := { handles:[] }
		sapgui_elements.tbw_exp_drop.blue_crystal.handles[1] := LoadPicture("blue_crystal/western_tbw_drop.png")
		sapgui_elements.tbw_exp_drop.blue_crystal.handles[2] := LoadPicture("blue_crystal/eastern_tbw_drop.png")
	
		sapgui_elements.tbw_exp_drop.signature := { handles:[] }
		sapgui_elements.tbw_exp_drop.signature.handles[1] := LoadPicture("signature/western_tbw_drop.png")
		sapgui_elements.tbw_exp_drop.signature.handles[2] := LoadPicture("signature/eastern_tbw_drop.png")
		
		;put new themes here
		
	
	;the export drop down button which appears in ToolbarWindow controls
	sapgui_elements.tbw_exp_btn := { etype:"button" }
	
		sapgui_elements.tbw_exp_btn.blue_crystal := { handles:[] }
		sapgui_elements.tbw_exp_btn.blue_crystal.handles[1] := LoadPicture("blue_crystal/western_tbw_button.png")
		sapgui_elements.tbw_exp_btn.blue_crystal.handles[2] := LoadPicture("blue_crystal/eastern_tbw_button.png")
		
		sapgui_elements.tbw_exp_btn.signature := { handles:[] }
		sapgui_elements.tbw_exp_btn.signature.handles[1] := LoadPicture("signature/western_tbw_button.png")
		sapgui_elements.tbw_exp_btn.signature.handles[2] := LoadPicture("signature/eastern_tbw_button.png")
		
		;put new themes here
		
	
	;the export button which appears in ApplicationToolbar controls
	sapgui_elements.at_exp_btn := { etype:"button" }
	
		sapgui_elements.at_exp_btn.blue_crystal := { handles:[] }
		sapgui_elements.at_exp_btn.blue_crystal.handles[1] := LoadPicture("blue_crystal/western_at_button.png")
		sapgui_elements.at_exp_btn.blue_crystal.handles[2] := LoadPicture("blue_crystal/eastern_at_button.png")
		
		sapgui_elements.at_exp_btn.signature := { handles:[] }
		sapgui_elements.at_exp_btn.signature.handles[1] := LoadPicture("signature/western_at_button.png")
		sapgui_elements.at_exp_btn.signature.handles[2] := LoadPicture("signature/eastern_at_button.png")
		
		;put new themes here
		
		
	;add new GUI elements here

getSapGuiTheme()
{
	/*
		Important to know the theme when searching for buttons
		Colors are in RGB hex
	*/

	if (!includes(SUPPORTED_THEMES, SAPGUI_THEME))
		throw Exception ("Action unsupported for theme: " . SAPGUI_THEME)
	
	return SAPGUI_THEME

}


getControlProperties(winID, classnn){
	
	ControlGetPos, x, y, w, h, %classnn%, ahk_id %winID%
	ControlGetText, ctext, %classnn%, ahk_id %winID%
	
	;check we found something
	if (x = ""){
		ErrorLevel := 1
		return ""
	}
	
	cntl := {}
	cntl.parentWinID := winID
	cntl.classnn := classnn
	cntl.text := ctext
	cntl.x := x
	cntl.y := y
	cntl.w := w
	cntl.h := h
	
	ErrorLevel := 0
	return cntl
}

getDistanceBetweenControls(win_id, c1, c2){
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
	
	appendLog("looking for controls where ClassNN contains '" . partialclass . "'")
	
	WinGet, controls, ControlList, ahk_id %winID%
	;MsgBox %controls%
	
	Results := []
	
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
			
			if (partialtext = "" OR InStr(ctext, partialtext))
			{
				appendLog("found '" . cname . "'")
				Results.push(cname)
			}
		}
	}
	
	if (Results.length() = 0)
	{
		ErrorLevel := 1
		Results := ""
	}
	else
		ErrorLevel := 0
	
	
	return Results
}

getControlByClassNN(winId, classnn)
{
	ControlGet, hwnd, HWND, , %classnn%, ahk_id %winID%

	if (hwnd)
	    return new MyControl(hwnd)

	throw Exception("no such control with '" . classnn . "'")
}

getControlsByClass(winID, class_name)
{
	appendLog("looking for controls of class '" . class_name . "'")
	
	WinGet, all_controls, ControlList, ahk_id %winID%
	
	matching_controls := []
	
	Loop, Parse, all_controls, `n
	{
		classnn := A_LoopField
		
		if RegExMatch(classnn, "^" . class_name . "\d{1,}")
		{
			appendLog("found '" . classnn . "'")
			matching_controls.push(getControlByClassNN(winId, classnn))
		}
	}
	
	ErrorLevel := matching_controls.length() = 0 ? 1 : 0
	return matching_controls
}


moveClickRestore(winID, winx, winy, byref clicked_classnn = ""){
	
	;get the mouse position so we can restore it later
	CoordMode, Mouse, Screen
	MouseGetPos, mx, my
	
	CoordMode, Mouse, Window
	
    Click, %winx%, %winy%
	;sometimes we want to know what was clicked
	MouseGetPos, , , , classnn
	
	CoordMode, Mouse, Screen
	MouseMove, mx, my, 0
}

moveClickDragRestore(x_from, y_from, x_to, y_to){
	
	CoordMode, Mouse, Screen
	MouseGetPos, mx, my
	
	CoordMode, Mouse, Window
	
	MouseClickDrag, Left, x_from, y_from, x_to, y_to, 0
	
	CoordMode, Mouse, Screen
	MouseMove, mx, my, 0
}

getGuiElementType(element_name){
	appendLog("type of '" . element_name . "' = '" . (sapgui_elements[element_name]).etype . "'")
	return (sapgui_elements[element_name]).etype
}

locateGuiElement(winID, x1, y1, x2, y2, name){
/*
	looks for visual elements from the element library:
	example:
	sapgui_elements.tbw_exp_drop.blue_crystal.handles
*/
	
	appendLog("element '" . name . "' search in area " . x1 . "," . y1 . " - " . x2 . "," . y2)
	
	coord := {}
	
	;we need to know the theme to find the correct button
	theme_pf := getSapGuiTheme()
	
	CoordMode, Pixel, Window
	for i, image_handle in sapgui_elements[name][theme_pf].handles {
		ImageSearch, found_x, found_y, x1, y1, x2, y2, *50 HBITMAP:*%image_handle%
		
		if (!ErrorLevel){
			;found
			coord.x := found_x, coord.y := found_y
			appendLog("found element; returning x,y = " . coord.x . "," . coord.y)
			return coord
		}
	}
	
	;not found
	appendLog("element '" . name . "' not found")
	ErrorLevel := 1
	return ""
	
}


locateGuiElementWithinParent(winID, parentcontrol, name){
/*
	parentcontrol is obtained from getControlProperties
*/
	appendLog("element '" . name . "' search in control '" . parentcontrol.classnn . "'")
	
	x1 := parentcontrol.x, x2 := parentcontrol.x + parentcontrol.w
	y1 := parentcontrol.y, y2 := parentcontrol.y + parentcontrol.h
	
	appendLog("top left: " . x1 . "," . y1 "   bottom right: " . x2 . "," . y2)
	
	coord := {}
	
	;we need to know the theme to find the correct button
	theme_pf := getSapGuiTheme()
	
	CoordMode, Pixel, Window
	for i, image_handle in sapgui_elements[name][theme_pf].handles {
		ImageSearch, found_x, found_y, x1, y1, x2, y2, *50 HBITMAP:*%image_handle%
		
		if (!ErrorLevel){
			;found
			coord.x := found_x, coord.y := found_y
			appendLog("found element; returning x,y = " . coord.x . "," . coord.y)
			return coord
		}
	}
	
	;not found
	appendLog("element '" . name . "' not found")
	ErrorLevel := 1
	return ""
	
}


Join(arr, s)
{
	;static _ := Array.Join := Func("Join")
	for k,v in arr
	o.= s . v
	return SubStr(o,StrLen(s)+1)
}

Includes(arr, value)
{
	for i, e in arr
	{
		if (e = value)
			return true
	}
	return false
}
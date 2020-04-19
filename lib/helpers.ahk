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
Global sapgui_elements := {
	; the export drop down button which appears in ToolbarWindow controls
	tbw_exp_drop: {
		etype: "dd_button",
		blue_crystal: {
			handles: [
				LoadPicture("blue_crystal/western_tbw_drop.png"),
				LoadPicture("blue_crystal/eastern_tbw_drop.png")
			]
		},
		signature: {
			handles: [
				LoadPicture("signature/western_tbw_drop.png"),
				LoadPicture("signature/eastern_tbw_drop.png")
			]
		}
		; put new themes here
	},

	; the export button which appears in ToolbarWindow controls
	tbw_exp_btn: {
		etype: "button",
		blue_crystal: {
			handles: [
				LoadPicture("blue_crystal/western_tbw_button.png"),
				LoadPicture("blue_crystal/eastern_tbw_button.png")
			]
		},
		signature: {
			handles: [
				LoadPicture("signature/western_tbw_button.png"),
				LoadPicture("signature/eastern_tbw_button.png")
			]
		}
		; put new themes here
	},

	; the export button which appears in ApplicationToolbar controls
	at_exp_btn: {
		etype: "button",
		blue_crystal: {
			handles: [
				LoadPicture("blue_crystal/western_at_button.png"),
				LoadPicture("blue_crystal/eastern_at_button.png")
			]
		},
		signature: {
			handles: [
				LoadPicture("signature/western_at_button.png"),
				LoadPicture("signature/eastern_at_button.png")
			]
		}
		; put new themes here
	},

	save_list_window: {
		title: "Save list in file..."
	},

	save_list_rb: {
		etype: "rb",
		classnn: "Afx:.{8}:b\d{1,}",
		classnn_is_regex: true
	}
	
	; put new GUI elements here
}
	

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

getControlByClassNN(win_id, classnn)
{
	control_hwnd := ControlGetHwnd(classnn, win_id)
	return MyControl.new(control_hwnd)
}

getControlsByClass(winID, class_name, use_regex := false)
{
	appendLog("looking for controls of class '" . class_name . "'")
	
	all_controls := WinGetControls(winID)

	matching_controls := []
	
	for i, classnn in all_controls
	{	
		if ( (use_regex AND RegExMatch(classnn, class_name))
			OR RegExMatch(classnn, "^" . class_name . "\d{1,}") )
		{
			appendLog("found '" . classnn . "'")
			control_hwnd := ControlGetHwnd(classnn, winID)
			a_control := MyControl.new(control_hwnd)
			matching_controls.push(a_control)
		}
	}
	
	ErrorLevel := matching_controls.length = 0 ? 1 : 0
	return matching_controls
}


moveClickRestore(winID, winx, winy, byref clicked_class_hwnd := ""){
	
	;get the mouse position so we can restore it later
	CoordMode("Mouse", "Screen")
	MouseGetPos(mx, my)
	
	CoordMode("Mouse", "Client")
	
    Click(winx, winy)
	;sometimes we want to know what was clicked
	MouseGetPos(, , , clicked_class_hwnd, 2)
	
	CoordMode("Mouse", "Screen")
	MouseMove(mx, my, 0)
}

moveClickDragRestore(x_from, y_from, x_to, y_to){
	
	CoordMode("Mouse", "Screen")
	MouseGetPos(mx, my)
	
	CoordMode("Mouse", "Client")
	
	MouseClickDrag("Left", x_from, y_from, x_to, y_to, 0)
	
	CoordMode("Mouse", "Screen")
	MouseMove(mx, my, 0)
}

getGuiElementType(element_name){
	appendLog("type of '" element_name "' = '" 
		. sapgui_elements.%element_name%.etype . "'")
	return sapgui_elements.%element_name%.etype
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
	
	CoordMode("Pixel", "Window")
	for i, image_handle in sapgui_elements.%name%.%theme_pf%.handles {
		found := ImageSearch(found_x, found_y, x1, y1, x2, y2, "*50 HBITMAP:*" . image_handle)
		
		if (found){
			coord.x := found_x, coord.y := found_y
			appendLog("found element; returning x,y = " . coord.x . "," . coord.y)
			return coord
		}
	}
	
	; not found
	appendLog("element '" . name . "' not found")
	return ""
	
}


locateElementWithinControl(pc, name)
{
	appendLog("search for '" name "' in control '" pc.classnn "'")
	
	end_x := pc.x + pc.w, end_y := pc.y + pc.h
	
	appendLog("top left: " pc.x . "," pc.y "  bottom right: " end_x "," end_y)
	
	coord := {}
	
	; we need to know the theme to find the correct button
	theme_pf := getSapGuiTheme()
	
	CoordMode("Pixel", "Client")
	for i, image_handle in sapgui_elements.%name%.%theme_pf%.handles {
		found := ImageSearch(found_x, found_y
			, pc.x, pc.y, end_x, end_y
			, "*50 HBITMAP:*" . image_handle)
		
		if (found){
			coord.x := found_x, coord.y := found_y
			appendLog("found element; returning {x,y} = " . coord.x . "," . coord.y)
			return coord
		}
	}
	
	; not found
	appendLog("element '" . name . "' not found")
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


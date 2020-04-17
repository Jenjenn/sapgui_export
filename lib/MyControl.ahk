Class MyControl
{
    ;the window handle of the control
    __New(hwnd)
    {
        this.hwnd := hwnd
    }

    __Get(key)
    {
        this_hwnd := this.hwnd
        switch key
        {
            Case "wclass":
                WinGetClass, wclass, ahk_id %this_hwnd%
                this.wclass := wclass
            Case "x", "y", "w", "h":
                ControlGetPos, x, y, w, h, , ahk_id %this_hwnd%
                this.x := x
                this.y := y
                this.w := w
                this.h := h
            Case "text":
                ControlGetText, ctext, , ahk_id %this_hwnd%
                this.text := ctext
            Case "visible":
                ControlGet, isvisible, Visible, , , ahk_id %this_hwnd%
                this.visible := isvisible
            Default:
                throw Exception("No such property or property not implemented yet.")
        }
    }
}
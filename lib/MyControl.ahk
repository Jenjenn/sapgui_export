Class MyControl
{
    ; the window handle of the control
    __New(hwnd)
    {
        if (!hwnd)
            throw Exception("Can't create MyControl object: hwnd empty!")
        
        this.hwnd := hwnd
    }

    __Get(name, params*)
    {
        this_hwnd := this.hwnd
        switch name
        {
            Case "wclass":
                this.wclass := WinGetClass(this.hwnd)
            Case "classnn":
                this.classnn := ControlGetClassNN(this.hwnd)
            Case "x", "y", "w", "h":
                ControlGetPos(x, y, w, h, this.hwnd)
                this.x := x
                this.y := y
                this.w := w
                this.h := h
            Case "text":
                this.text := ControlGetText(this.hwnd)
            Case "visible":
                this.visible := ControlGetVisible(this.hwnd)
            Default:
                throw Exception("No such property or property not implemented yet.")
        }
        return this.%name%
    }

    getDistance(other_control)
    {
        return sqrt( (this.x - other_control.x)**2 + (this.y - other_control.y)**2)
    }
}
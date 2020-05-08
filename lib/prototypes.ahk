; ===================================== ARRAY
; Array prototype modifications

ArrayJoin(arr, sep) {
    static _ := Array.prototype.DefineMethod("join", Func("ArrayJoin"))
	for k,v in arr
		o.= sep . v
	return SubStr(o,StrLen(sep)+1)
}

ArrayIncludes(arr, v) {
	static _ := Array.prototype.DefineMethod("includes", Func("ArrayIncludes"))
	for i, e in arr
	{
		if (e == v)
			return true
	}
	return false
}

ArrayFilter(arr, filter_func) {
    static _ := Array.prototype.DefineMethod("filter", Func("ArrayFilter"))
    out := []
    for i, k in arr
    {
        if (filter_func.Call(k))
            out.push(k)
    }
    return out
}

ArrayMap(arr, map_func) {
    static _ := Array.prototype.DefineMethod("map", Func("ArrayMap"))
    out := []
    for i, e in arr
        out.push(map_func.call(e))

    return out
}

;other array functions

; assumes all arrays are the same length
JoinArrays(join_func, arr*){

	out := []
	if (arr.length == 0)
		return []
	
	for i,e in arr[1]
	{
		params := []
		for j,a in arr
			params.push(a[i])

		out.push(join_func.Call(params*))
	}
	return out
}


; ===================================== STRING
; String base modifications
; https://lexikos.github.io/v2/docs/Objects.htm#primitive

DefProp := {}.GetMethod("DefineProp")
DefMethod := {}.GetMethod("DefineMethod")

%DefProp%( "".base, "length", { get: Func("StrLen") } )

StringSplit(str, splitter := "`r`n") {
	;static _ := "".base.DefineMethod("split", Func("StringSplit"))
	return StrSplit(str, splitter)
}
%DefMethod%( "".base, "split", Func("StringSplit" ))

; other string functions

; pads each string of an array so all strings are the same length
StringPad(align := "left", strings*){

	align := align = "left" ? "-" : ""

	max_width := 0
	padded_array := []

	for e in strings
		max_width := max_width > e.length ? max_width : e.length
	
	format_string := "{:" align max_width "}"

	for i, e in strings
		padded_array.push(Format(format_string, e))

	return padded_array
}


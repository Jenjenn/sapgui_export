

#include lib/prototypes.ahk

arr1 := ["A","B","C"]
arr2 := ["1","2","3"]
arr3 := ["X","Y","Z"]

; StringLength(str) {
; 	static _ := "".base.length := Func("StringLength")
; 	return StrLen(str)
; }

s1 := "a,b,c,d"
;MsgBox(s1.length)

s2 := s1.split(",")
MsgBox(s2[1] " " s2[2])

;MsgBox(Type("") "`r`n" Type("".base) "`r`n" )


;hay := "aaaaaaaaafind meaaaaaaaaaaaaa"

;MsgBox(StrLen(hay))
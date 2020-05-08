class ST03
{

    

    class Metadata {
        __New()
        {
            this.screen := ""

            this.task_type := ""
            this.instance := ""
            this.period_type := ""
            this.period := ""
            this.first_record := ""
        }
    }


    ; returns zero if we don't think the cb data is from ST03
    static postprocess(byref cb)
    {
        if ( !(cb_meta := ST03.get_metadata(cb)) ){
            return 0
        }

        ST03.insert_metadata(cb, cb_meta)
        return 1
    }


    ; cb contains newlines
    static get_metadata(byref cb)
    {
        start_time := A_TickCount
        cb_meta := ST03.Metadata.new()

        ; ST03 should always have "Task Type"
        if (RegexMatch(cb, "m)^\| Task type *?(?P<task_type>[\w.-]+ ?[\w.-]+).+\|$", mo1))
            cb_meta.task_type := mo1.task_type
        else
        {
            ; exit early to avoid unnecessary regex
            return 0
        }

        ; get the rest of the metadata

        if (RegexMatch(cb, "m)^\| Instance *?(?P<instance>[\w-]+).+\|$", mo1))
            cb_meta.instance := mo1.instance
        
        if (RegexMatch(cb, "m)^\| .*Period Type *?(?P<period_type>Day|Week|Month) *\|$", mo1))
            cb_meta.period_type := mo1.period_type

        if (RegexMatch(cb, "m)^\| Period *?(?:(?P<dd1>\d\d)\.(?P<mm1>\d\d)\.(?P<yy1>\d\d\d\d)|(?P<mm2>\d\d)/(?P<yy2>\d\d\d\d))(?: -\d\d.\d\d.\d\d\d\d)?", mo1))
            cb_meta.period := mo1.dd1 ? mo1.yy1 "/" mo1.mm1 "/" mo1.dd1 : mo1.yy2 "/" mo1.mm2 "/01"
        else if (RegexMatch(cb, "m)^\| Period *?(?P<period>User-defined).*?\|$", mo1))
            cb_meta.period := mo1.period

        if (RegexMatch(cb, "m)^\| .*First record *?(?P<dd>\d\d)\.(?P<mm>\d\d)\.(?P<yy>\d\d\d\d) (?P<ts>\d\d:\d\d:\d\d) *?\|$", mo1))
            cb_meta.first_record := mo1.yy "/" mo1.mm "/" mo1.dd " " mo1.ts

        ; TODO: On the Workload Overview screen, Task Type is already provided per row so 
        ;       there is no need to add it again, need to check for it in the table headers


        ; screen determination
        if (cb_meta.period_type)
        {
            if (cb_meta.instance)
                cb_meta.screen := "load history"
            
            if (cb_meta.period)
                cb_meta.screen := "instance comparison"
        }
        else
        {
            cb_meta.screen := "workload"
        }
        
        runtime := A_TickCount - start_time
        appendLog("parsed ST03 metadata in " runtime " ms")
        appendLog("     screen: " cb_meta.screen)
        appendLog("  Task type: " cb_meta.task_type)
        appendLog("   Instance: " cb_meta.instance)
        appendLog("     Period: " cb_meta.period)
        appendLog("Period type: " cb_meta.period_type)
        appendLog("  First rec: " cb_meta.first_record)
        
        return cb_meta
    }

    static insert_metadata(byref cb, cb_meta)
    {
        static table_border := "m)^-------*?------$"


        start_time := A_TickCount

        metadata := ST03.format_metadata(cb_meta)
            
        if (metadata.length == 0){
            appendlog("No new columns added")
            return 1
        }

        lines := cb.split("`r`n")

        ; 0, 1, 2 = not in table
        ; 3 = in header
        ; 4 = in table
        cur_section := 0
        
        for i, line in lines
        {
            if (RegexMatch(line, table_border)) {
                appendlog("table divider at line " i)
                cur_section++
                continue
            }

            ; modify headers
            if (cur_section = 3){
                lines[i] := metadata[1] lines[i]
            }

            ; modify rows
            if (cur_section = 4){
                lines[i] := metadata[2] lines[i]
            }
        }

        output := lines.join("`r`n")

        runtime := A_TickCount - start_time
        appendLog("inserted ST03 metadata in " runtime " ms")

        cb := output
        return 1
    }

    static format_metadata(cb_meta)
    {
        metadata := []

        if (cb_meta.screen == "load history"){
            instance := StringPad(,"Instance", cb_meta.instance)
            task_type := StringPad(,"Task Type", cb_meta.task_type)

            metadata := JoinArrays((a,b) => "|" a "|" b, instance, task_type)
        }
        else if (cb_meta.screen == "instance comparison"){
            period := StringPad(, "Period", cb_meta.period)
            task_type := StringPad(, "Task Type", cb_meta.task_type)

            metadata := JoinArrays((a,b) => "|" a "|" b, period, task_type)
        }
        else if (cb_meta.screen == "workload"){
            period := StringPad(, "Period", cb_meta.period)
            instance := StringPad(,"Instance", cb_meta.instance)
            task_type := StringPad(,"Task Type", cb_meta.task_type)

            metadata := JoinArrays((a,b,c) => "|" a "|" b "|" c, period, instance, task_type)
        }

        return metadata
    }
}
import ./dbfmodel
import strformat, strutils

proc toSQLCreate*(header: DBFHeader, tablename: string): string =
  result = fmt"CREATE TABLE {tablename} ("
  for field in header.field_headers:
    case field.field_type:
      of 'N': result = fmt"{result} {field.name} NUMERIC(10,2)"
      of 'C': result = fmt"{result} {field.name} varchar({field.length})"
      of 'D': result = fmt"{result} {field.name} date"
      else: discard
    result.add ","
  result = result[0 .. result.len - 3] & ");"
  

proc toSQLInsert*(data: string, header: DBFHeader, table: string) : string =
  var idx = 1
  var tl = 0
  var fs = ""
  var vs = ""  
  for fd in header.field_headers :
    tl = tl + fd.length
    fs = fs & fd.name & ","
    var v = data[idx..idx + fd.length-1].strip()
    if v == "" :
      vs = vs & " NULL,"
    else:
      case fd.field_type:
        of 'C': vs = vs & "'" & v & "'," 
        of 'N': vs = vs & v & ","
        of 'D': vs = vs & "'" & v[0..3] & "-" & v[4..5] & "-" & v[6..7] & "',"
        else: discard
    idx = idx + fd.length
  fs = "(" & fs[0..fs.len-2] & ")"
  vs = "(" & vs[0..vs.len-2] & ")"
  result = "INSERT INTO " & table & " " & fs & " VALUES " & vs & ";"

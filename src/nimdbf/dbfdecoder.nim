import 
  asyncfile,
  asyncdispatch,
  os,
  strutils

import nimdbf / dbfmodel

proc processRecord*(data: string, header: DBFHeader, table: string): string =
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

proc processFile*(data: string, header: DBFHeader, filename: string): seq[string] =
  result = @[]
  var deleted = 0
  var s = header.length+1
  var e = header.length+header.record_length
  while s < data.len and e < data.len:
    if $data[s] == "*":
      deleted = deleted + 1
    else: 
      result.add(processRecord(data[s..e], header, filename))
    s = s + header.record_length
    e = s + header.record_length
  echo "Deleted records: " & $deleted

import dbfmodel
import json, strutils

proc toJson*(h: DBFFieldHeader): JsonNode =
  result = %*{"name" : h.name, "field_type": $h.field_type,
               "data_address": h.data_address, "length": h.length}

proc toJson*(h: DBFHeader): JsonNode =
  let updated = $h.update_year & "-" &
    $h.update_month & "-" & $h.update_day
  var field_headers = newJArray()
  for field in h.field_headers:
    field_headers.add(field.toJson)
  result = %*{"version": h.version, "updated": updated,
               "record_count" : h.record_count,
               "header_length" : h.header_length,
               "record_length" : h.record_length,
               "length" :h.length,
               "field_headers": field_headers }
  
proc record2Json*(data: string, header: DBFHeader): JsonNode =
  result = %*{}
  var idx = 1
  var tl = 0
  #var fs = ""
  #var vs = ""  
  for fd in header.field_headers :
    #echo fd 
    result[fd.name] = newJString(data[idx .. idx + fd.length - 1].strip())
   # tl = tl + fd.length
   # fs = fs & fd.name & ","
   # var v = data[idx..idx + fd.length-1].strip()
   # if v == "" :
   #   vs = vs & " NULL,"
   # else:
   #   case fd.field_type:
   #     of 'C':
   #       vs = vs & "'" & v & "',"
   #       result[fd] = v
   #     of 'N':
   #       vs = vs & v & ","
   #       result[fd] = v
   #     of 'D': vs = vs & "'" & v[0..3] & "-" & v[4..5] & "-" & v[6..7] & "',"
   #     else: discard
    idx = idx + fd.length
  # fs = "(" & fs[0..fs.len-2] & ")"
  # vs = "(" & vs[0..vs.len-2] & ")"
  # result = "INSERT INTO " & table & " " & fs & " VALUES " & vs & ";"

  
proc dbf2json*(data: string): JsonNode =
  ## Converts a string representing the DBF file jo Json format
  let header = data.getDBFHeader
  result = %{ "header" : header.toJson() }
  result["data"] = newJArray()
  var deleted = 0
  var s = header.length+1
  var e = header.length+header.record_length
  while s < data.len and e < data.len:
    if $data[s] == "*":
      deleted = deleted + 1
    else: 
      result["data"].add(record2Json(data[s..e], header))
    s = s + header.record_length
    e = s + header.record_length
  echo "Deleted records: " & $deleted
  result["deleted_count"] = deleted.newJInt

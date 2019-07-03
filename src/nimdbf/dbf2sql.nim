import ./dbfmodel
import strformat, strutils

proc sqlCreateStatement(header: DBFHeader, tablename: string): string =
  result = fmt"CREATE TABLE {tablename} ("
  for field in header.field_headers:
    case field.field_type:
      of 'N': result = fmt"{result} {field.name} NUMERIC(10,2)"
      of 'C': result = fmt"{result} {field.name} varchar({field.length})"
      of 'D': result = fmt"{result} {field.name} date"
      else: discard
    result.add ","
  result = result[0 .. result.len - 2] & ");"
  echo result



import
  asyncfile,
  asyncdispatch,
  os,
  strutils,
  parseopt

type
  FieldHeader = ref object
    name: string
    field_type: char
    data_address: int32
    length: int16

  FileHeader = ref object
    version : int8
    update_year: int8
    update_month: int8
    update_day: int8
    record_count: int32
    header_length: int16
    record_length: int16
    field_headers: seq[FieldHeader]
    length: int32
  
proc getFieldHeader(data: string): FieldHeader =
  new(result)
  result.name = ""
  for c in data[0..10]:
    if c !=  char(0):
      result.name = result.name & c
  result.field_type = data[11]
  result.length = (data[16].int16) + (data[17].int16 * 256) 

proc getFileHeader(data: string): FileHeader =
  new (result)
  result.version = data[0].int8
  result.update_year = data[1].int8
  result.update_month = data[2].int8
  result.update_day = data[3].int8
  result.record_count = data[4].int32 +
    (data[5].int32*256) +
    (data[6].int32*256*256) +
    (data[7].int32*256*256*256)
  result.record_length = (data[10].int16) + (data[11].int16*256)
  result.field_headers = @[]
  var finish = false
  var idx = 32
  while not finish and idx < data.len : 
    if data[idx].int == 13:
      result.length = idx.int32
      finish = true
    else:
      result.field_headers.add(getFieldHeader(data[idx..idx+31])) 
    idx = idx + 32

proc processRecord(data: string, header: FileHeader, f: string): string =
  var idx = 1
  var tl = 0
  var fs = ""
  var vs = "" 
  for fd in header.field_headers :
    tl = tl + fd.length
    fs = fs & fd.name & ","
    var v = data[idx..idx + fd.length-1]
    case fd.field_type:
      of 'C': vs = vs & "'" & data[idx..idx + fd.length-1].strip() & "'," 
      of 'N': vs = vs & data[idx..idx + fd.length-1].strip() & ","
      of 'D': vs = vs & "'" & data[idx..idx+3] & "-" & data[idx+4..idx+5] & "-" & data[idx+6..idx+7] & "',"
      else: discard
    idx = idx + fd.length
  fs = "(" & fs[0..fs.len-2] & ")"
  vs = "(" & vs[0..vs.len-2] & ")"
  result = "INSERT INTO " & f & " " & fs & " VALUES " & vs & ";"
  #echo result

proc processFile(data: string, header: FileHeader, filename: string): seq[string] =
  result = @[]
  var s = header.length+1
  var e = header.length+header.record_length
  while s < data.len and e < data.len:
    result.add(processRecord(data[s..e], header, filename))
    s = s + header.record_length
    e = s + header.record_length

proc createColumnFragment(h: FieldHeader): string =
  case h.field_type:
    of 'N': result = h.name & " NUMERIC(10,2) "
    of 'C': result = h.name & " varchar(" & $h.length & ") "
    of 'D': result = h.name & " date "
    else: discard

proc createTable(h: FileHeader, name: string): string =
  result  = "CREATE TABLE IF NOT EXISTS " & name & " ("
  for field in h.field_headers:
    result = result & createColumnFragment(field) & ","    
  result = result[0..result.len-3] & ");"   
  
proc main() {.async.} =
  var filename = ""
  var opts = initOptParser()
  for kind, key, val in opts.getopt():
    case kind
    of cmdArgument:
      filename = key
    of cmdLongOption, cmdShortOption:
      case key
      of "file", "f": filename = $val
    of cmdEnd: assert(false)
  var file = openAsync(filename, fmRead)
  file.setFilePos(0)
  let data = await file.readAll()
  file.close()
  let header = getFileHeader(data)
  let inserts =  processFile(data, header, filename)
  let creation =  createTable(header, filename)
  file = openAsync(filename & ".sql", fmWrite)
  file.setFilePos(0)
  await file.write(creation)
  await file.write("\r\n") 
  for line in inserts:
    await file.write(line & "\n")
  file.close()

waitFor main()

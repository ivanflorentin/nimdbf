import parseopt, strutils, asyncdispatch, asyncfile, json
import nimdbf / [ dbfmodel, dbfdecoder, dbf2sql, dbf2json ]

##[
Utility to convert DBF files to various formats
usage:

$ nimdbf --file:<filename> [additional options]

Options:
--file, -f: File to parse
--json, -j: Output in json format
--header, -h: Output only header 
--records, -r <n>: Process n records
--start, -s <n>: Start at record n (counting from 0)

]##


proc main() {.async.} =
  var filename = ""
  var opts = initOptParser()
  var record_count = 5
  var buffer_size = 4096
  var inJson = false
  var sql = false
  var onlyHeader = false
  var start = 0
  for kind, key, val in opts.getopt():
    case kind
    of cmdArgument:
      filename = key
    of cmdLongOption, cmdShortOption:
      case key
      of "file", "f": filename = $val
      of "json", "j": inJson = true
      of "sql", "l": sql = true  
      of "header", "h": onlyHeader = true
      of "records", "r": record_count = parseInt($val)
      of "start", "s": start = parseInt($val)
    of cmdEnd: assert(false)
  var file = openAsync(filename, fmRead)
  let tablename = filename.split(".")[0]
  file.setFilePos(0)
  var data = await file.read(buffer_size)
  var header_size = data.getHeaderLength()
  if header_size > buffer_size:
    file.setFilePos(0)
    data = await file.read(buffer_size)
  let header = getDBFHeader(data)
  if onlyHeader:
    if inJson:
      echo header.toJson().pretty
      return
    if sql:
      echo header.toSQLCreate(tablename)
      return
  var pos = header_size +  (start * header.record_length)
  file.setFilePos(pos)
  buffer_size = header.record_length * record_count 
  data = await file.read(buffer_size)
  var r_start = 0
  var r_end = header.record_length
  if inJson:  
    for j in 0 .. record_count - 1 :
      echo data[r_start ..  r_start + header.record_length- 1].
          record2Json(header).pretty
      r_start += header.record_length
    return
  if sql:
    for j in 0 .. record_count - 1 :
      echo data[r_start ..  r_start + header.record_length- 1].
          toSQLInsert(header, tablename)
      r_start += header.record_length
  file.close()

waitFor main()

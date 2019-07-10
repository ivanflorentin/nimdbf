## DBF data model and helper procs 

type
  DBFFieldHeader* = ref object
    ## Field header
    name*: string
    field_type*: char
    data_address*: int32
    length*: int16

  DBFHeader* = ref object
    ## File header
    version*: int8
    update_year*: int8
    update_month*: int8
    update_day*: int8
    record_count*: int32
    header_length*: int16
    record_length*: int16
    field_headers*: seq[DBFFieldHeader]
    length*: int32
  
proc getDBFFieldHeader(data: string): DBFFieldHeader =
  new (result)
  result.name = ""
  for c in data[0..10]:
    if c !=  char(0):
      result.name = result.name & c
  result.field_type = data[11]
  result.length = data[16].int16 + data[17].int16 * 256 

proc getDBFHeader*(data: string): DBFHeader =
  ## Extracts the File Header from a string representing a DBF file
  new (result)
  result.version = data[0].int8
  result.update_year = data[1].int8
  result.update_month = data[2].int8
  result.update_day = data[3].int8
  result.record_count = data[4].int32 +
    data[5].int32 * 256 +
    data[6].int32 * 256 * 256 +
    data[7].int32 * 256 * 256 * 256
  result.record_length = data[10].int16 + data[11].int16*256
  result.field_headers = @[]
  var finish = false
  var idx = 32
  while not finish and idx < data.len : 
    if data[idx].int == 13:
      result.length = idx.int32
      finish = true
    else:
      result.field_headers.add(getDBFFieldHeader(data[ idx .. idx + 31 ])) 
    idx = idx + 32


proc `$`*(h: DBFFieldHeader): string =
  "name: " & h.name &  ", type: " & h.field_type &
    ", address: " & $h.data_address & ", length: " &  $h.length

proc `$`*(h: DBFHeader): string =
  result = "version: " & $h.version & ", updated: " & $h.update_year & "-" &
    $h.update_month & "-" &
    $h.update_day & ", records: " & $h.record_count & ", header size: " &
    $h.header_length & ", record size: " & $h.record_length &
    ", file size: " & $h.length & ", columns: \n"
  for fh in h.field_headers:
    result = result & "\t" & $fh & "\n"

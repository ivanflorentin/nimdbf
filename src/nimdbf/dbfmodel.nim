## DBF data model and helper procs 

#[
Binary DBF file structure:
copied from http://web.tiscali.it/SilvioPitti/

 0 | Version number      *1|  ^
   |-----------------------|  |      
 1 | Date of last update   |  |
 2 |      YYMMDD           |  |
 3 |                       |  |
   |-----------------------|  |
 4 | Number of records     | Record
 5 | in data file          | header
 6 | ( 32 bits ) *14       |  |
 7 |                       |  |
   |-----------------------|  |
 8 | Length of header      |  |
 9 | structure ( 16 bits ) |  |
   |-----------------------|  |
 10| Length of each record |  |
 11| ( 16 bits )         *2|  |
   |-----------------------|  |
 12| ( Reserved )        *3|  |
 13|                       |  |
   |-----------------------|  |
 14| Incomplete transac.*12|  |
   |-----------------------|  |
 15| Encryption flag    *13|  |
   |-----------------------|  |
 16| Free record thread    |  |
 17| (reserved for LAN     |  |
 18|  only )               |  |
 19|                       |  |
   |-----------------------|  |
 20| ( Reserved for        |  |            _  |=======================| ______
   |   multi-user dBASE )  |  |           /  0| Field name in ASCII   |  ^ 
   : ( dBASE III+ - )      :  |          /    : (terminated by 00h)   :  |
   :                       :  |         |     |                       |  |
 27|                       |  |         |   10|                       |  |
   |-----------------------|  |         |     |-----------------------| For
 28| MDX flag (dBASE IV) *4|  |         |   11| Field type in ASCII   | each
   |-----------------------|  |         |     |-----------------------| field
 29| Language driver     *5|  |        /    12| Field data address    |  |
   |-----------------------|  |       /       |                     *6|  |
 30| ( Reserved )          |  |      /        | (in memory !!!)       |  |
 31|                     *3|  |     /       15| (dBASE III+)          |  |
   |=======================|__|____/          |-----------------------|  | <-
 32|                       |  |  ^          16| Field length  (binary)|  |   |
   |- - - - - - - - - - - -|  |  |            |-----------------------|  |   | *7
   |                       |  |  |          17| Decimal count (binary)|  |   |
   |- - - - - - - - - - - -|  |  Field        |-----------------------|  | <-
   |                       |  | Descriptor  18| ( Reserved for        |  |
   :. . . . . . . . . . . .:  |  |array     19|   multi-user dBASE)*18|  |
   :                       :  |  |            |-----------------------|  |
n  |                       |__|__v_         20| Work area ID      *16 |  |
   |-----------------------|  |    \          |-----------------------|  |
n+1| Terminator (0Dh)      |  |     \       21| ( Reserved for        |  |
   |=======================|  |      \      22|   multi-user dBASE )  |  |
m  | Database Container    |  |       \       |-----------------------|  |
   :                *15    :  |        \    23| Flag for SET FIELDS   |  |
   :                       :  |         |     |-----------------------|  |
m+263                      |  |         |   24| ( Reserved )          |  |
   |=======================|__v_ ___    |     :                       :  |
   :                       :    ^       |     :                       :  |
   :                       :    |       |   30|                       |  |
   | Record structure      |    |       |     |-----------------------|  |
   |                       |    |        \  31| Index field flag    *8|  |
   |                       |    |         \_  |=======================| _v_____
   |                       | Records
   |-----------------------|    |                                      
   |                       |    |          _  |=======================| _______
   |                       |    |         /  0| Field deleted flag  *9|  ^ 
   |                       |    |        /    |-----------------------|  |
   |                       |    |       /     | Data               *10|  One
   |                       |    |      /      :                    *17: record
   |                       |____|_____/       |                       |  |
   :                       :    |             |                       | _v_____
   :                       :____|_____        |=======================|
   :                       :    |     \       | Field deleted flag  *9|
   |                       |    |      \      |-----------------------|
   |                       |    |       \     |                       |
   |                       |    |        \    |                       |
   |                       |    |         \_  |-----------------------|
   |                       |    |
   |=======================|    |
   |__End_of_File__________| ___v____  End of file ( 1Ah )  *11


]#

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



proc getHeaderLength*(data: string): int16 =
  result = data[8].int16 + data[9].int16 * 256
  
proc getDBFHeader*(data: string): DBFHeader =
  ## Extracts the File Header from a string representing a DBF file
  new (result)
  result.header_length = data.getHeaderLength()
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

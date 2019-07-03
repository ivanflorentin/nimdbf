import nimdbf / [ dbfmodel, dbfdecoder, dbf2sql ]

export dbfmodel, dbfdecoder, dbf2sql


#[  
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
  let nam = filename.split(".")
  file.setFilePos(0)
  let data = await file.readAll()
  file.close()
  let header = getFileHeader(data)
  let inserts =  processFile(data, header, nam[0])
  let creation =  createTable(header, nam[0])
  file = openAsync(filename & ".sql", fmWrite)
  file.setFilePos(0)
  await file.write(creation)
  await file.write("\r\n") 
  for line in inserts:
    await file.write(line & "\n")
  file.close()

waitFor main()
]#

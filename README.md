# nimdbf

## DBF libraries

#### This library is in very early stage of development

Utility to convert DBF files to various formats

# Usage:

$ nimdbf --file: filename [additional options]

# Options:

--file, -f: File to parse

--json, -j: Output in json format

--sql, l: Output in SQL format. header data are converted to CREATE TABLE with a tablename corresponding to the name of the file being processed. Records are converted to INSERTs

--header, -h: Output only header 

--records, -r:n: Process n records

--start, -s:n: Start at record n (counting from 0)

# Example

$nim c -r src/nimdbf.nim --file:myFile.dbf --json --records:4 --start:10  

At this point it has been tested only with version 3 of the DBF spec, for files created with FOX and FOX Plus for Unix


I followed the documentation in the next links:

- http://web.tiscali.it/SilvioPitti/
- http://manmrk.net/tutorials/database/xbase/index.html
- http://www.dbase.com/Knowledgebase/INT/db7_file_fmt.htm

# nimdbf

## DBF reader written in Nim

#### This library is in very early stage of development

##### Usage:
```bash
$readdbf <dbf file>
````
This generates a sql file wich contains a CREATE TABLE header with the fields presents in the DBF. then an INSERT per line for every record in the file

At this point it has been tested only with version 3 of the DBF spec, for files created with FOX and FOX Plus for Unix


I followed the documentation in the next links:

- http://web.tiscali.it/SilvioPitti/
- http://manmrk.net/tutorials/database/xbase/index.html
- http://www.dbase.com/Knowledgebase/INT/db7_file_fmt.htm

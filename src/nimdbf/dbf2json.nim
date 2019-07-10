import dbfmodel
import json

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
  

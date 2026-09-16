param(
    [string]$db = "\\YOUR-PC\c$\path\to\test2.sqlite",
    [string]$sounds = "\\YOUR-PC\c$\path\to\sounds\"
)

import-module pssqlite

# $q = "SELECT idQuote,quoterand FROM Quote"

# Invoke-SqliteQuery -query $q -database $db

# $qsound = get-childitem "$sounds\Quotes" | Select-Object name
# For the Custom Sounds.  format it to be userID-commandname
$csound = get-childitem "$sounds\Custom" | Select-Object name
# For the achieved one.  Name them to the Rank id
$rsound = get-childitem "$sounds\Achieved" | Select-Object name

# This is a transaction insert
# $qdata = foreach($q in $qsound) {
#     [PSCustomObject]@{
#         idQuote = $q.name.split("-""Q")[1]
#         filename = $q.name
#     }
# }
# $qdtable = $qdata | Out-DataTable

# Invoke-SqliteBulkCopy -database $db -datatable $qdtable -table QSound -force

$cdata = foreach($c in $csound) {
    [PSCustomObject]@{
        filename = $c.name
    }
}
$cdtable = $cdata | Out-DataTable

Invoke-SqliteBulkCopy -database $db -datatable $cdtable -table CSound -force

$rdata = foreach($r in $rsound) {
    [PSCustomObject]@{
        filename = $r.name
    }
}
$rdtable = $rdata | Out-DataTable

Invoke-SqliteBulkCopy -database $db -datatable $rdtable -table NSound -force

# This is a single threaded insert
# foreach ($sd in $soundy) {
#     $sd1 = $sd.name
#     $sd2 = $sd1.split("-""Q")[1]
#     write-host $sd2
#     $q = "INSERT INTO QSound (idQuote, filename) VALUES ( '$($sd2)', '$($sd1)' );"
#     write-host $q
#     Invoke-SqliteQuery -Query $q -database $db
# }

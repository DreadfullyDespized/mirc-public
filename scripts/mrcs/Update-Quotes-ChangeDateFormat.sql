update quotes
set date = substr(date, 7, 4)|| '-' ||substr(date,1,2)|| '-' ||substr(date,4,2)
where date like "%/%/____"
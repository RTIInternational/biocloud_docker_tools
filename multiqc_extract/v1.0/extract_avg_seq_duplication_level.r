# Used to get the average sequence duplication levels as percentage of duplicates
args<-commandArgs(TRUE)
dat = t(read.table(args[1],row.names = 1, fill = TRUE))
out_dat = mean(as.numeric(as.vector(dat[!is.na(dat[,2]) & nchar(dat[,2])>0,2])))
print(out_dat)
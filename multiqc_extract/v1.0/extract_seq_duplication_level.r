# Used to get the average sequence duplication levels as percentage of duplicates
args<-commandArgs(TRUE)
dat = t(read.table(args[1],row.names = 1, fill = TRUE))
out_dat_mean = mean(as.numeric(as.vector(dat[!is.na(dat[,2]) & nchar(dat[,2])>0,2])))
out_dat_sd = sd(as.numeric(as.vector(dat[!is.na(dat[,2]) & nchar(dat[,2])>0,2])))
print(paste0(as.character(out_dat_mean),",",as.character(out_dat_sd)))
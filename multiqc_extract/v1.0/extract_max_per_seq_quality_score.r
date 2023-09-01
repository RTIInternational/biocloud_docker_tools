# Used to get the highest per sequence quality score
args<-commandArgs(TRUE)
dat = t(read.table(args[1],row.names = 1))
out_dat = max(dat[,2])
print(out_dat)
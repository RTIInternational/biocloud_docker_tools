# Used to get the average per base sequence quality after 30 cycles
args<-commandArgs(TRUE)
dat = t(read.table(args[1],row.names = 1))
out_dat = mean(dat[dat[,1] >= 30,2])
print(out_dat)
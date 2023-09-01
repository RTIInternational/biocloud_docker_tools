# Used to get the average per base N content
args<-commandArgs(TRUE)
dat = t(read.table(args[1],row.names = 1))
out_dat_mean = mean(dat[,2])
out_dat_sd = sd(dat[,2])
print(paste0(as.character(out_dat_mean),",",as.character(out_dat_sd)))
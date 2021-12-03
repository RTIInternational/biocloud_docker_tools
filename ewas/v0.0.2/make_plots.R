suppressPackageStartupMessages(require(optparse)) 
suppressPackageStartupMessages(require(lattice)) 

option_list = list(
  make_option(c("-t", "--table"), action="store", type="character",
              help="The plot table. Space separated."),
  make_option(c("-b", "--bonferroni"), action="store", type="double",
              help="Bonferroni adjusted genome-wide significance threshold."),
  make_option(c("-f", "--fdr"), action="store", type="double",
              help="FDR adjusted genome-wide significance threshold."),
  make_option(c("-c", "--colors"), type="character", default="red blue",
              help="Colors for the Manhattan plot. Enclose them with double quotes. [default %default]"),
  make_option(c("-o", "--output"), type="character", default="ewas_plot",
              help="Basename Manhattan and QQ plots. [default %default]")
)

opt = parse_args(OptionParser(option_list=option_list))
####################################################################################################

plot_table <- read.csv(opt$t, sep=" ")
head(plot_table)

manhattan.plot<-function(chr, pos, pvalue,
    sig.level=NA, sig.level2=NA, annotate=NULL, ann.default=list(),
    should.thin=T, thin.pos.places=2, thin.logp.places=2,
    xlab="Chromosome", ylab=expression(-log[10](p-value)),
    col=c("gray","darkgray"), panel.extra=NULL, pch=20, cex=0.8,...) {

    if (length(chr)==0) stop("chromosome vector is empty")
    if (length(pos)==0) stop("position vector is empty")
    if (length(pvalue)==0) stop("pvalue vector is empty")

    #make sure we have an ordered factor
    if(!is.ordered(chr)) {
        chr <- ordered(chr)
    } else {
        chr <- chr[,drop=T]
    }

    #make sure positions are in kbp
    if (any(pos>1e6)) pos<-pos/1e6;

    #calculate absolute genomic position
    #from relative chromosomal positions
    posmin <- tapply(pos,chr, min);
    posmax <- tapply(pos,chr, max);
    posshift <- head(c(0,cumsum(posmax)),-1);
    names(posshift) <- levels(chr)
    genpos <- pos + posshift[chr];
    getGenPos<-function(cchr, cpos) {
        p<-posshift[as.character(cchr)]+cpos
        return(p)
    }

    #parse annotations
    grp <- NULL
    ann.settings <- list()
    label.default<-list(x="peak",y="peak",adj=NULL, pos=3, offset=0.5,
        col=NULL, fontface=NULL, fontsize=NULL, show=F)
    parse.label<-function(rawval, groupname) {
        r<-list(text=groupname)
        if(is.logical(rawval)) {
            if(!rawval) {r$show <- F}
        } else if (is.character(rawval) || is.expression(rawval)) {
            if(nchar(rawval)>=1) {
                r$text <- rawval
            }
        } else if (is.list(rawval)) {
            r <- modifyList(r, rawval)
        }
        return(r)
    }

    if(!is.null(annotate)) {
        if (is.list(annotate)) {
            grp <- annotate[[1]]
        } else {
            grp <- annotate
        }
        if (!is.factor(grp)) {
            grp <- factor(grp)
        }
    } else {
        grp <- factor(rep(1, times=length(pvalue)))
    }

    ann.settings<-vector("list", length(levels(grp)))
    ann.settings[[1]]<-list(pch=pch, col=col, cex=cex, fill=col, label=label.default)

    if (length(ann.settings)>1) {
        lcols<-trellis.par.get("superpose.symbol")$col
        lfills<-trellis.par.get("superpose.symbol")$fill
        for(i in 2:length(levels(grp))) {
            ann.settings[[i]]<-list(pch=pch,
                col=lcols[(i-2) %% length(lcols) +1 ],
                fill=lfills[(i-2) %% length(lfills) +1 ],
                cex=cex, label=label.default);
            ann.settings[[i]]$label$show <- T
        }
        names(ann.settings)<-levels(grp)
    }
    for(i in 1:length(ann.settings)) {
        if (i>1) {ann.settings[[i]] <- modifyList(ann.settings[[i]], ann.default)}
        ann.settings[[i]]$label <- modifyList(ann.settings[[i]]$label,
            parse.label(ann.settings[[i]]$label, levels(grp)[i]))
    }
    if(is.list(annotate) && length(annotate)>1) {
        user.cols <- 2:length(annotate)
        ann.cols <- c()
        if(!is.null(names(annotate[-1])) && all(names(annotate[-1])!="")) {
            ann.cols<-match(names(annotate)[-1], names(ann.settings))
        } else {
            ann.cols<-user.cols-1
        }
        for(i in seq_along(user.cols)) {
            if(!is.null(annotate[[user.cols[i]]]$label)) {
                annotate[[user.cols[i]]]$label<-parse.label(annotate[[user.cols[i]]]$label,
                    levels(grp)[ann.cols[i]])
            }
            ann.settings[[ann.cols[i]]]<-modifyList(ann.settings[[ann.cols[i]]],
                annotate[[user.cols[i]]])
        }
    }
    rm(annotate)

    #reduce number of points plotted
    if(should.thin) {
        thinned <- unique(data.frame(
            logp=round(-log10(pvalue),thin.logp.places),
            pos=round(genpos,thin.pos.places),
            chr=chr,
            grp=grp)
        )
        logp <- thinned$logp
        genpos <- thinned$pos
        chr <- thinned$chr
        grp <- thinned$grp
        rm(thinned)
    } else {
        logp <- -log10(pvalue)
    }
    rm(pos, pvalue)
    gc()

    #custom axis to print chromosome names
    axis.chr <- function(side,...) {
        if(side=="bottom") {
            panel.axis(side=side, outside=T,
                at=((posmax+posmin)/2+posshift),
                labels=levels(chr),
                ticks=F, rot=0,
                check.overlap=F
            )
        } else if (side=="top" || side=="right") {
            panel.axis(side=side, draw.labels=F, ticks=F);
        }
        else {
            axis.default(side=side,...);
        }
     }

    #make sure the y-lim covers the range (plus a bit more to look nice)
    prepanel.chr<-function(x,y,...) {
        A<-list();
        maxy<-ceiling(max(y, ifelse(!is.na(sig.level), -log10(sig.level), 0)))+.5;
        A$ylim=c(0,maxy);
        A;
    }

    xyplot(logp~genpos, chr=chr, groups=grp,
        axis=axis.chr, ann.settings=ann.settings,
        prepanel=prepanel.chr, scales=list(axs="i"),
        panel=function(x, y, ..., getgenpos) {
            if(!is.na(sig.level)) {
                #add significance line (if requested)
                panel.abline(h=-log10(sig.level2), lty=2);
                panel.abline(h=-log10(sig.level), lty=1);
            }
            panel.superpose(x, y, ..., getgenpos=getgenpos);
            if(!is.null(panel.extra)) {
                panel.extra(x,y, getgenpos, ...)
            }
        },
        panel.groups = function(x,y,..., subscripts, group.number) {
            A<-list(...)
            #allow for different annotation settings
            gs <- ann.settings[[group.number]]
            A$col.symbol <- gs$col[(as.numeric(chr[subscripts])-1) %% length(gs$col) + 1]
            A$cex <- gs$cex[(as.numeric(chr[subscripts])-1) %% length(gs$cex) + 1]
            A$pch <- gs$pch[(as.numeric(chr[subscripts])-1) %% length(gs$pch) + 1]
            A$fill <- gs$fill[(as.numeric(chr[subscripts])-1) %% length(gs$fill) + 1]
            A$x <- x
            A$y <- y
            do.call("panel.xyplot", A)
            #draw labels (if requested)
            if(gs$label$show) {
                gt<-gs$label
                names(gt)[which(names(gt)=="text")]<-"labels"
                gt$show<-NULL
                if(is.character(gt$x) | is.character(gt$y)) {
                    peak = which.max(y)
                    center = mean(range(x))
                    if (is.character(gt$x)) {
                        if(gt$x=="peak") {gt$x<-x[peak]}
                        if(gt$x=="center") {gt$x<-center}
                    }
                    if (is.character(gt$y)) {
                        if(gt$y=="peak") {gt$y<-y[peak]}
                    }
                }
                if(is.list(gt$x)) {
                    gt$x<-A$getgenpos(gt$x[[1]],gt$x[[2]])
                }
                do.call("panel.text", gt)
            }
        },
        xlab=xlab, ylab=ylab,
        panel.extra=panel.extra, getgenpos=getGenPos, ...
    );
}


qqunif.plot<-function(pvalues,
    should.thin=T, thin.obs.places=2, thin.exp.places=2,
    xlab=expression(paste("Expected (",-log[10], " p-value)")),
    ylab=expression(paste("Observed (",-log[10], " p-value)")),
    draw.conf=TRUE, conf.points=1000, conf.col="lightgray", conf.alpha=.05,
    already.transformed=FALSE, pch=20, aspect="iso", prepanel=prepanel.qqunif,
    par.settings=list(superpose.symbol=list(pch=pch)), ...) {


    #error checking
    if (length(pvalues)==0) stop("pvalue vector is empty, can't draw plot")
    if(!(class(pvalues)=="numeric" ||
        (class(pvalues)=="list" && all(sapply(pvalues, class)=="numeric"))))
        stop("pvalue vector is not numeric, can't draw plot")
    if (any(is.na(unlist(pvalues)))) stop("pvalue vector contains NA values, can't draw plot")
    if (already.transformed==FALSE) {
        if (any(unlist(pvalues)==0)) stop("pvalue vector contains zeros, can't draw plot")
    } else {
        if (any(unlist(pvalues)<0)) stop("-log10 pvalue vector contains negative values, can't draw plot")
    }


    grp<-NULL
    n<-1
    exp.x<-c()
    if(is.list(pvalues)) {
        nn<-sapply(pvalues, length)
        rs<-cumsum(nn)
        re<-rs-nn+1
        n<-min(nn)
        if (!is.null(names(pvalues))) {
            grp=factor(rep(names(pvalues), nn), levels=names(pvalues))
            names(pvalues)<-NULL
        } else {
            grp=factor(rep(1:length(pvalues), nn))
        }
        pvo<-pvalues
        pvalues<-numeric(sum(nn))
        exp.x<-numeric(sum(nn))
        for(i in 1:length(pvo)) {
            if (!already.transformed) {
                pvalues[rs[i]:re[i]] <- -log10(pvo[[i]])
                exp.x[rs[i]:re[i]] <- -log10((rank(pvo[[i]], ties.method="first")-.5)/nn[i])
            } else {
                pvalues[rs[i]:re[i]] <- pvo[[i]]
                exp.x[rs[i]:re[i]] <- -log10((nn[i]+1-rank(pvo[[i]], ties.method="first")-.5)/(nn[i]+1))
            }
        }
    } else {
        n <- length(pvalues)+1
        if (!already.transformed) {
            exp.x <- -log10((rank(pvalues, ties.method="first")-.5)/n)
            pvalues <- -log10(pvalues)
        } else {
            exp.x <- -log10((n-rank(pvalues, ties.method="first")-.5)/n)
        }
    }


    #this is a helper function to draw the confidence interval
    panel.qqconf<-function(n, conf.points=1000, conf.col="gray", conf.alpha=.05, ...) {
        require(grid)
        conf.points = min(conf.points, n-1);
        mpts<-matrix(nrow=conf.points*2, ncol=2)
            for(i in seq(from=1, to=conf.points)) {
                    mpts[i,1]<- -log10((i-.5)/n)
                    mpts[i,2]<- -log10(qbeta(1-conf.alpha/2, i, n-i))
                    mpts[conf.points*2+1-i,1]<- -log10((i-.5)/n)
                    mpts[conf.points*2+1-i,2]<- -log10(qbeta(conf.alpha/2, i, n-i))
            }
            grid.polygon(x=mpts[,1],y=mpts[,2], gp=gpar(fill=conf.col, lty=0), default.units="native")
        }

    #reduce number of points to plot
    if (should.thin==T) {
        if (!is.null(grp)) {
            thin <- unique(data.frame(pvalues = round(pvalues, thin.obs.places),
                exp.x = round(exp.x, thin.exp.places),
                grp=grp))
            grp = thin$grp
        } else {
            thin <- unique(data.frame(pvalues = round(pvalues, thin.obs.places),
                exp.x = round(exp.x, thin.exp.places)))
        }
        pvalues <- thin$pvalues
        exp.x <- thin$exp.x
    }
    gc()

    prepanel.qqunif= function(x,y,...) {
        A = list()
        A$xlim = range(x, y)*1.02
        A$xlim[1]=0
        A$ylim = A$xlim
        return(A)
    }

    #draw the plot
    xyplot(pvalues~exp.x, groups=grp, xlab=xlab, ylab=ylab, aspect=aspect,
        prepanel=prepanel, scales=list(axs="i"), pch=pch,
        panel = function(x, y, ...) {
            if (draw.conf) {
                panel.qqconf(n, conf.points=conf.points,
                    conf.col=conf.col, conf.alpha=conf.alpha)
            };
            panel.xyplot(x,y, ...);
            panel.abline(0,1);
        }, par.settings=par.settings, ...
    )
}

####################################################################################################
basename <- paste0(opt$o, "_manhattan.png")
png(basename, width=950, height=500)

man_colors <- strsplit(opt$c, " ")[[1]]
manhattan.plot(chr=plot_table$chr_ordered,
               pos=plot_table$pos,
               pvalue=plot_table$P_VAL,
               col=man_colors,
               sig.level=opt$bonferroni,
               sig.level2=opt$fdr)

dev.off()

basename <- paste0(opt$o, "_qq.png")
png(basename, width=950, height=500)

# lambda is a measure of inflated p-values. Should be ~1
lambda <- qchisq(p=median(plot_table$P_VAL,  na.rm=T),  df = 1, lower.tail = F) /
          qchisq(p=0.5, df=1) #  gives the quantile function

qqunif.plot(plot_table$P_VAL,
            main=paste0("lambda=",format(lambda,digits=2))) #these are the raw p-values; add lambda value
dev.off()

SIZEPER <- SIZE/sum(SIZE)
CHURNPER <- CHURN/sum(CHURN)

mycex = 1
par(mar=c(0,0,0,0), cex=mycex)
pct <- round(SIZEPER*100)
labels <- paste(LABEL, " ", pct, "%", sep="") # add percents to labels 
pie(SIZEPER,labels=labels,col=c('#dd0000',gray.colors(length(LABEL)-1, end=0.97)))

PKG_SIZEPER = PKG_SIZE/sum(PKG_SIZE)

pct <- round(PKG_SIZEPER*100)
labels <- paste(PKG_LABEL, " ", pct, "%", sep="") # add percents to labels 
pie(PKG_SIZEPER,labels=labels,col=gray.colors(length(PKG_LABEL)-1, start=0.97, end=0.3))

#barplot(SIZEPER,names.arg=LABEL,space=0.5,cex.names=0.4)

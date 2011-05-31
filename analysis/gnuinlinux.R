SIZEPER <- SIZE/sum(SIZE)
CHURNPER <- CHURN/sum(CHURN)

barplot(SIZEPER,names.arg=LABEL,space=0.5,cex.names=0.4)

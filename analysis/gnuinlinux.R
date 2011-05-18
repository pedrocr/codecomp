SIZEPER <- SIZE/sum(SIZE)
CHURNPER <- CHURN/sum(CHURN)

s <- cbind(1:length(SIZEPER),SIZEPER)
sizes <- s[order(s[,2]),]

barplot(sizes[,2],names.arg=LABEL[sizes[,1]],space=0.5,cex.names=0.7)

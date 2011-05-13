par(mar=c(4.5,5,1,5),cex=1.2)

reg1 <- lm(log(CHURN) ~ log(SIZE))
plot(log(SIZE),log(CHURN),cex=0.7)
abline(reg1)

reg2 <- lm(CHURN ~ log(SIZE))
plot(log(SIZE),CHURN,ann=FALSE,bty="n",cex=0.7)
title(xlab="log(LOC)",ylab="Churn")
abline(reg2, col="red", lwd=2)


plot(SIZE, type="n")
lines(sort(SIZE, decreasing=TRUE))

plot(CHURN, type="n")
lines(sort(CHURN, decreasing=TRUE))

plot(GROWTH, type="n")
lines(sort(GROWTH, decreasing=TRUE))
plot(density(GROWTH),ylim=c(0,0.04))

print(summary(reg2))

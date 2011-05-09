reg1 <- glm(log(CHURN) ~ log(SIZE))
plot(log(SIZE),log(CHURN),cex=0.7)
abline(reg1)

reg2 <- glm(CHURN ~ log(SIZE))
plot(log(SIZE),CHURN,cex=0.7)
abline(reg2)

plot(SIZE, type="n")
lines(sort(SIZE, decreasing=TRUE))

plot(CHURN, type="n")
lines(sort(CHURN, decreasing=TRUE))

plot(GROWTH, type="n")
lines(sort(GROWTH, decreasing=TRUE))
plot(density(GROWTH),ylim=c(0,0.04))

print(summary(reg2))

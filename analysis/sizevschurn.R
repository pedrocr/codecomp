reg1 <- glm(log(CHURN) ~ log(SIZE))
plot(log(SIZE),log(CHURN),cex=0.7)
abline(reg1)

reg2 <- glm(CHURN ~ log(SIZE))
plot(log(SIZE),CHURN,cex=0.7)
abline(reg2)

print(summary(reg2))

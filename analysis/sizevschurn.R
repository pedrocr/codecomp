attach(read.table("tmpdir/sizevschurn", header=TRUE))
pdf(file="generated/sizevschurnplot.pdf")
plot(LN_SIZE,CHURN)
summary(glm(CHURN ~ LN_SIZE))

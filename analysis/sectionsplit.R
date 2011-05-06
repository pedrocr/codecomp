attach(read.table("tmpdir/sectionsplit", header=TRUE))
pdf(file="generated/sectionsplit.pdf")

total <- CORE+BASE+USER
g_range <- range(0, CORE, BASE, USER, total)

plot(total, type="n", ylim=g_range, axes=FALSE, ann=FALSE)
axis(1, at=1:4, lab=c("karmic","lucid","maverick","natty"))

lines(CORE, type="o", col="red")
lines(BASE, type="o", col="blue")
lines(USER, type="o", col="green")
lines(total, type="o", col="black")



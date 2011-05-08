par(mar=c(5,4.5,0.5,0.5), cex=1.1)

total <- CORE+BASE+USER
ymax <- 180*10^6
plot(c(0), type="n", xlim=c(0.85,4.15), ylim=c(0,ymax), yaxs='i', xaxs="i", axes=FALSE, ann=FALSE)

#title(main="Amount of Change per Release Cycle")

xmarks = c(-100,1,2,3,4,100)
axis(1, at=xmarks, labels=c("","karmic","lucid","maverick","natty",""))
title(xlab= "Release cycle")

ymarks = c(-100,10,40,70,100,130,160,2000)
axis(2, las=1, at=ymarks*10^6, labels=ymarks)
title(ylab= "Total Churn (Million Lines of Diff Output)")

lines(CORE, type="o", col="red")
lines(BASE, type="o", col="blue")
lines(USER, type="o", col="green")
lines(total, type="o", col="black",lty=2)

legend('topright', c("total","base","user","core"), 
   col=c("black","blue","green","red"), pch=21, lty=c(2,1,1,1), bty="n");

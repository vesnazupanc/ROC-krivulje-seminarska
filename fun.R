############################################################################
############################################################################
###                                                                      ###
###                          DEFINICIJE FUNKCIJ                          ###
###                                                                      ###
############################################################################
############################################################################

##----------------------------------------------------------------
##                      Potrebne knjižnice                      --
##----------------------------------------------------------------

source("lib.r")

##--------------------------------------------------------------------
##  Funkcije za generiranje podatkov, risanje ROC in računanje AUC  --
##--------------------------------------------------------------------

doloci.mejo <- function(mu1, mu2, ro, b1, b2){
  
  # Funkcija za dolocanje meje na podatkih za NORMALNO PORAZD.
  # (uporablja se znotraj generiranja podatkov)
  #---------------------------------------------------------------------
  # INPUT: 
  #   mu1...povprečje za marker 1
  #   mu2...povprečje za marker 2
  #   ro...korelacijski faktor med markerjema
  #   b1...vpliv na bolezen za marker 1
  #   b2...vpliv na bolezen za marker 2
  # OUTPUT:
  #   meja (int) za določitev bolezni
  #---------------------------------------------------------------------
  
  korelacije <- matrix(ro, nrow=2, ncol=2)
  diag(korelacije) <- 1
  x <- rmvnorm(n=10000, mean=c(mu1,mu2), sigma=korelacije)
  y <- b1*x[,1]+b2*x[,2] + rnorm(n=10000,0,1)
  round(median(y))
}


doloci.mejo.gamma <- function(b1, b2){
  
  # Funkcija za dolocanje meje na podatkih za GAMMA PORAZD.
  # (uporablja se znotraj generiranja podatkov)
  #---------------------------------------------------------------------
  # INPUT: 
  #   b1...vpliv na bolezen za marker 1
  #   b2...vpliv na bolezen za marker 2
  # OUTPUT:
  #   meja (int) za določitev bolezni
  #---------------------------------------------------------------------
  
  e1 = rexp(10000, rate=2)
  e2 = rexp(10000, rate=2)
  e3 = rexp(10000, rate=2)
  
  X1 = e1 + e3 # prvi marker
  X2 = e2 + e3 # drugi marker
  x <- cbind(X1,X2)
  y <- b1*x[,1]+b2*x[,2] + rnorm(n=10000,0,1)
  round(median(y))
}

doloci.mejo.pois <- function(b1, b2){
  
  # Funkcija za dolocanje meje na podatkih za Poissonovo porazd.
  # (uporablja se znotraj generiranja podatkov)
  #---------------------------------------------------------------------
  # INPUT: 
  #   b1...vpliv na bolezen za marker 1
  #   b2...vpliv na bolezen za marker 2
  # OUTPUT:
  #   meja (int) za določitev bolezni
  #---------------------------------------------------------------------
  
  # vsota Poissonovih je spet Poissonova
  e1 = rpois(10000, 1)
  e2 = rpois(10000, 1)
  e3 = rpois(10000, 1)
  
  X1 = e1 + e3 # prvi marker ~ Pois(2)
  X2 = e2 + e3 # drugi marker ~ Pois(2)
  x <- cbind(X1,X2)
  y <- b1*x[,1]+b2*x[,2] + rnorm(n=10000,0,1)
  round(median(y))
}

doloci.mejo.razlicna <- function(b1, b2){
  
  # Funkcija za dolocanje meje na podatkih za Poissonovo porazd.
  # (uporablja se znotraj generiranja podatkov)
  #---------------------------------------------------------------------
  # INPUT: 
  #   b1...vpliv na bolezen za marker 1
  #   b2...vpliv na bolezen za marker 2
  # OUTPUT:
  #   meja (int) za določitev bolezni
  #---------------------------------------------------------------------
  
  X1 = rnorm(10000, 2, 1) # prvi marker ~ N(2,1)
  X2 = rexp(10000, 1) # drugi marker ~ Exp(1)
  x <- cbind(X1,X2)
  y <- b1*x[,1]+b2*x[,2] + rnorm(n=10000,0,1)
  round(median(y))
}


get.data <- function(n, mu1, mu2, ro, b1, b2){
  
  # Funkcija za generiranje vzorca - NORMALNA PORAZDELITEV
  #---------------------------------------------------------------------
  # INPUT: 
  #   n...velikost vzorca
  #   mu1...povprečje za marker 1
  #   mu2...povprečje za marker 2
  #   ro...korelacijski faktor med markerjema
  #   b1...vpliv na bolezen za marker 1
  #   b2...vpliv na bolezen za marker 2
  # OUTPUT:
  #   tabela s stolpci:
  #     y...binarna(0/1) označuje ali ima posameznik bolezen (0-zdrav,1-bolen)
  #     X1...vrednost markerja 1
  #     X2...vrednost markerja 2
  #---------------------------------------------------------------------
  
  korelacije <- matrix(ro, nrow=2, ncol=2)
  diag(korelacije) <- 1
  x <- rmvnorm(n=n, mean=c(mu1,mu2), sigma=korelacije)
  y <- b1*x[,1]+b2*x[,2] + rnorm(n,0,1)
  meja <- doloci.mejo(mu1, mu2, ro, b1, b2)
  
  zdravi <- y<meja
  bolni <- y>=meja
  y[zdravi] <- 0
  y[bolni] <- 1
  
  return(data.frame(y,x))
}

get.data.gamma <- function(n, b1, b2){
  
  # Funkcija za generiranje vzorca - GAMMA PORAZDELITEV
  #---------------------------------------------------------------------
  # INPUT: 
  #   n...velikost vzorca
  #   ro...korelacijski faktor med markerjema
  #   b1...vpliv na bolezen za marker 1
  #   b2...vpliv na bolezen za marker 2
  # OUTPUT:
  #   tabela s stolpci:
  #     y...binarna(0/1) označuje ali ima posameznik bolezen (0-zdrav,1-bolen)
  #     X1...vrednost markerja 1
  #     X2...vrednost markerja 2
  #---------------------------------------------------------------------
  
  e1 = rexp(n, rate=2)
  e2 = rexp(n, rate=2)
  e3 = rexp(n, rate=2)

  X1 = e1 + e3 # prvi marker
  X2 = e2 + e3 # drugi marker
  x <- cbind(X1,X2)
  y <- b1*x[,1]+b2*x[,2] + rnorm(n,0,1)
  
  meja <- doloci.mejo.gamma(b1, b2)
  y[y<meja] <- 0
  y[y>=meja] <- 1
  
  return(data.frame(y,x))
}

get.data.pois <- function(n, b1, b2){
  
  # Funkcija za generiranje vzorca - GAMMA PORAZDELITEV
  #---------------------------------------------------------------------
  # INPUT: 
  #   n...velikost vzorca
  #   ro...korelacijski faktor med markerjema
  #   b1...vpliv na bolezen za marker 1
  #   b2...vpliv na bolezen za marker 2
  # OUTPUT:
  #   tabela s stolpci:
  #     y...binarna(0/1) označuje ali ima posameznik bolezen (0-zdrav,1-bolen)
  #     X1...vrednost markerja 1
  #     X2...vrednost markerja 2
  #---------------------------------------------------------------------
  
  e1 = rpois(n, 1)
  e2 = rpois(n, 1)
  e3 = rpois(n, 1)
  
  X1 = e1 + e3 # prvi marker ~ Pois(2)
  X2 = e2 + e3 # drugi marker ~ Pois(2)
  x <- cbind(X1,X2)
  y <- b1*x[,1]+b2*x[,2] + rnorm(n,0,1)
  
  meja <- doloci.mejo.pois(b1, b2)
  y[y<meja] <- 0
  y[y>=meja] <- 1
  
  return(data.frame(y,x))
}

get.data.razlicna <- function(n, b1, b2){
  
  # Funkcija za generiranje vzorca - RAZLIČNI PORAZDELITVI
  #---------------------------------------------------------------------
  # INPUT: 
  #   n...velikost vzorca
  #   b1...vpliv na bolezen za marker 1
  #   b2...vpliv na bolezen za marker 2
  # OUTPUT:
  #   tabela s stolpci:
  #     y...binarna(0/1) označuje ali ima posameznik bolezen (0-zdrav,1-bolen)
  #     X1...vrednost markerja 1
  #     X2...vrednost markerja 2
  #---------------------------------------------------------------------
  
  X1 = rnorm(n, 2, 1) # prvi marker ~ N(2,1)
  X2 = rexp(n, 1) # drugi marker ~ Exp(1)
  x <- cbind(X1,X2)
  y <- b1*x[,1]+b2*x[,2] + rnorm(n,0,1)
  meja <- doloci.mejo.razlicna(b1, b2)
  
  zdravi <- y<meja
  bolni <- y>=meja
  y[zdravi] <- 0
  y[bolni] <- 1
  
  return(data.frame(y,x))
}


plot.roc <- function(df){
  # Funkcija, ki izriše obe ROC krivulji
  #---------------------------------------------------------------------
  # INPUT: 
  #   df...vzorec s stolpci y, X1, X2
  # OUTPUT:
  #   Graf z ROC krivuljama in oznakami Markerjev in pripisane
  #   vrednosti AUC
  #---------------------------------------------------------------------
  auc_list <- get.AUC(df)
  auc1 <- bquote(Marker1: AUC[1] == .(auc_list$AUC1 %>% round(4)))
  auc2 <- bquote(Marker2: AUC[2] == .(auc_list$AUC2 %>% round(4)))
  
  pred1 <- prediction(df$X1, df$y) 
  perf1 <- performance(pred1,"tpr","fpr")
  plot(perf1,col="cadetblue", xlab="Stopnja lazno pozitivnih (FPR)", ylab="Stopnja resnicno pozitivnih (TPR)")
  
  pred2 <- prediction(df$X2, df$y) 
  perf2 <- performance(pred2,"tpr","fpr")
  plot(perf2,col="coral", add=TRUE)
  
  text(0.85, 0.2, auc1, cex = .9, col="cadetblue")
  text(0.85, 0.1, auc2 ,cex = .9, col="coral")

}

get.AUC <- function(df){
  
  # Funkcija, ki na vzorcu izračuna več statistik
  #---------------------------------------------------------------------
  # INPUT: 
  #   df...vzorec s stolpci y, X1, X2
  # OUTPUT:
  #   list (4) z vrednostmi:
  #     AUC1...AUC za Marker 1 (X1)
  #     AUC2...AUC za Marker 2 (X2)
  #     razlika...AUC1-AUC2
  #     razmerje...AUC1/AUC2
  #---------------------------------------------------------------------
  pred1 <- prediction(df$X1, df$y) 
  auc_ROCR1 <- performance(pred1, measure = "auc")
  auc_ROCR1 <- auc_ROCR1@y.values[[1]]
  
  pred2 <- prediction(df$X2, df$y) 
  auc_ROCR2 <- performance(pred2, measure = "auc")
  auc_ROCR2 <- auc_ROCR2@y.values[[1]]
  
  list("AUC1"=auc_ROCR1, "AUC2" = auc_ROCR2,
       "razlika"=auc_ROCR1 - auc_ROCR2,
       "razmerje" = auc_ROCR1/auc_ROCR2)
}


auroc <- function(x, y) {
  # Funkcija, ki na podlagi podatkov izračuna AUC (veliko hitrejša od get.AUC)
  #---------------------------------------------------------------------
  # INPUT: 
  #   x...vredosti markerja
  #   y...BOOL vektor, bolezni
  # OUTPUT:
  #   auc vrednost
  #---------------------------------------------------------------------
  n1 <- sum(!y)
  n2 <- sum(y)
  U  <- sum(rank(x)[!y]) - n1 * (n1 + 1) / 2
  return(1 - U / n1 / n2)
}



##----------------------------------------------------------------
##                Funkcije za testiranje - TESTI                --
##----------------------------------------------------------------

testiraj.rank.X <- function(df, m.type, n.perm=1000){
  
  # Funkcija, ki zgenerira porazdelitev pod ničelno domnevo (permutacije) glede na RANKE
  # permutacije po markerjih
  #---------------------------------------------------------------------
  # INPUT: 
  #   df...vzorec s stolpci y, X1, X2
  #   m.type...Kaj računamo. Možni: "razlika"/"razmerje"
  #   n.perm...število permutacij za generiranje porazdelitve
  # OUTPUT:
  #   list (3) z elementi:
  #     porazdelitev...vektor dolžine n, dobljena porazdelitev testne stat.
  #     t...vrednost testne statistike na vzorcu
  #     p...vrednost p
  #---------------------------------------------------------------------
  
  y <- df$y
  m1 <- rank(df$X1)
  m2 <- rank(df$X2)
  
  if (m.type=="razlika"){
    test.stat <- auroc(m1,y) - auroc(m2,y)
  }
  else{
    test.stat <- auroc(m1,y)/auroc(m2,y)
  }
  
  n <- length(y)
  
  porazdelitev <- sapply(1:n.perm,function(i,n,m1,m2,y) {
    # vzamemo M1 ali pa M2, čisto slučajno in izračunamo AUC
    # premutiraj ima vrednost 1, kadar vzamemo prvi marker in 0 kadar drugi
    premutiraj <- sample(c(0,1),n,replace=T)
    pm1 <- premutiraj*m1 + (1-premutiraj)*m2
    pm2 <- (1-premutiraj)*m1 + premutiraj*m2
    if (m.type=="razlika"){
      pp <- auroc(pm1,y) - auroc(pm2,y)
    }
    else{
      pp <- auroc(pm1,y)/auroc(pm2,y)
    }
    pp
  },n,m1,m2,y)
  
  if (m.type=="razlika"){
    p.vr <- sum(abs(porazdelitev) > abs(test.stat))/n.perm
  }
  else{
    druga.meja = 1/test.stat
    zgornja = max(druga.meja,test.stat)
    spodnja = min(druga.meja,test.stat)
    p.vr <- (sum(porazdelitev > zgornja)+sum(porazdelitev < spodnja))/n.perm
  }
  
  out <- list()
  out$porazdelitev <- porazdelitev
  out$t <- test.stat
  out$p <- p.vr
  class(out) <- "auc.rank.perm.X.test"
  out
} 

testiraj.rank.y <- function(df, m.type, n.perm=1000){
  
  # Funkcija, ki zgenerira porazdelitev pod ničelno domnevo (permutacije) glede na RANKE
  # permutacije po boleznih
  #---------------------------------------------------------------------
  # INPUT: 
  #   df...vzorec s stolpci y, X1, X2
  #   m.type...Kaj računamo. Možni: "razlika"/"razmerje"
  #   n.perm...število permutacij za generiranje porazdelitve
  # OUTPUT:
  #   list (3) z elementi:
  #     porazdelitev...vektor dolžine n, dobljena porazdelitev testne stat.
  #     t...vrednost testne statistike na vzorcu
  #     p...vrednost p
  #---------------------------------------------------------------------
  
  y <- df$y
  m1 <- rank(df$X1)
  m2 <- rank(df$X2)
  
  if (m.type=="razlika"){
    test.stat <- auroc(m1,y) - auroc(m2,y)
  }
  else{
    test.stat <- auroc(m1,y)/auroc(m2,y)
  }
  
  
  n <- length(y)
  
  porazdelitev <- sapply(1:n.perm,function(i,n,m1,m2,y) {
    # permutiramo po y
    py <- y[sample(n)]
    if (m.type=="razlika"){
      pp <- auroc(m1,py) - auroc(m2,py)
    }
    else{
      pp <- auroc(m1,py)/auroc(m2,py)
    }
    pp
  },n,m1,m2,y)
  
  if (m.type=="razlika"){
    p.vr <- sum(abs(porazdelitev) > abs(test.stat))/n.perm
  }
  else{
    druga.meja = 1/test.stat
    zgornja = max(druga.meja,test.stat)
    spodnja = min(druga.meja,test.stat)
    p.vr <- (sum(porazdelitev > zgornja)+sum(porazdelitev < spodnja))/n.perm
  }
  
  out <- list()
  out$porazdelitev <- porazdelitev
  out$t <- test.stat
  out$p <- p.vr
  class(out) <- "auc.rank.perm.y.test"
  out
} 

plot.test <- function(data, iz=TRUE, p.val=TRUE){
  
  # Funkcija, ki nariše rezultate testa
  #---------------------------------------------------------------------
  # INPUT: 
  #   data...podatki dobljeni s funkcijo testiraj
  #   iz...ali naj nariše kritično območje. Možni: TRUE/FALSE
  #   p.val...ali naj označi testno stat. in vr.p. Možni: TRUE/FALSE
  # OUTPUT:
  #   grafični prikaz testa (density, poljubno p.vr in testna stat.)
  #---------------------------------------------------------------------

  plt <- density(data$porazdelitev)

  sp.meja <- quantile(data$porazdelitev, probs = c(0.025))
  zg.meja <- quantile(data$porazdelitev, probs = c(0.975))
  
  plot(plt, main="", xlab="x",
       ylab = expression(f[X]) )
  if(p.val){
  polygon(c(zg.meja, plt$x[plt$x>=zg.meja]),
          c(0,plt$y[plt$x>=zg.meja]), col="grey")
  polygon(c(plt$x[plt$x<=sp.meja], sp.meja),
          c(plt$y[plt$x<=sp.meja], 0), col="grey")
  }

  if(p.val){
    #abline(v=data$t, col="red", add=TRUE)
    arrows(x0=data$t, y0=max(plt$y)/8, y1=0, length=0.1,
           col="red") 
    text(data$t, max(plt$y)/6.5, paste0("p = ", data$p),
         cex = .8, col="red")
  }
  
}


#' Intraclass Correlation Coefficients ICC(2,1) & ICCa(2,1) under the Random Factorial ANOVA Model with Interaction.
#'
#' This functions computes 2 ICC estimates for the inter-rater reliability and intra-rater reliability coefficients. It
#' requires some subjects to have multiple ratings and assumes the ANOVA model was specified with interaction.
#' @references  Gwet, K.L. (2014): \emph{Handbook of Inter-Rater Reliability - 4th ed.} - Equation #9.2.3 of chapter 9, pages 231-232
#' (for the inter-rater reliability ICC(2,1)), and Equation #9.2.10 of chapter 9, page 236 (for the intra-rater reliability),
#' Advanced Analytics, LLC.
#' @param ratings This is a data frame containing 3 columns or more.  The first column contains subject numbers (some duplicates are expected,
#' as some subject are assumed to have assigned multiple ratings) and each of the remaining columns is associated with a particular rater and
#' contains its numeric ratings.
#' @return This function returns a list containing the following 12 values:
#' 1. sig2s: the subject variance component. 2.sig2r: the rater variance component 3. sig2e: the error variance component.
#' 4. sig2sr: the subject-rater interaction variance component. 5. icc2r: ICC as a measure of inter-rater relliability.
#' 6. icc2a: ICC as a measure of intra-rater reliability. 7. n: the number of subjects. 8. r: the number of raters.
#' 9. max.rep: the maximum number of ratings per subject. 10. min.rep: the minimum number of ratings per subjects.
#' 11. M: the total number of ratings for all subjects and raters. 12. ov.mean: the overall mean rating.
#' @examples
#' #iccdata1 is a small dataset that comes with the package. Use it as follows:
#' library(irrICC)
#' iccdata1 #see what the iccdata1 dataset looks like
#' icc2.inter.fn(iccdata1)
#' coeff <- icc2.inter.fn(iccdata1)$icc2r #this only gives you the ICC coefficient
#' coeff
#' @export
icc2.inter.fn <- function(ratings){
  #This function computes the Intraclass Correlation Coefficients ICC(2,1) and ICCa(2,1) under Model 2 with interaction - random factorial design
  #(see equations 9.2.3 and 9.2.12 of chapter 9, pages 231-232, in K. Gwet, 2014: "Handbook of Inter-Rater Reliability - 4th ed.")
  #ratings = data frame of ratings where column 1 contains subject or target numbers and each of the remaining columns is associated to a rater
  #and contains its ratings.
  ratings <- data.frame(lapply(ratings, as.character),stringsAsFactors=FALSE)
  ratings <- as.data.frame(lapply(ratings,function (y) if(class(y)=="factor" ) as.character(y) else y),stringsAsFactors=F)
  ratings[,2:ncol(ratings)] <- lapply(ratings[,2:ncol(ratings)],as.numeric)

  rep.vec <- plyr::count(ratings,1)
  n <- nrow(rep.vec)
  r <- ncol(ratings)-1
  Mtot <- sum(!is.na(ratings[,2:ncol(ratings)])) #Mtot = total number of non-missing ratings
  Mtot <- max(Mtot,r*n)
  max.rep <- max(rep.vec$freq)
  min.rep <- min(rep.vec$freq)
  ov.mean <- mean(as.matrix(ratings[,2:(r+1)]),na.rm = TRUE)

  b <- cbind(ratings[1],(!is.na(ratings[,2:(r+1)])))
  mij <- sapply(2:(r+1), function(x) tapply(b[[x]],b[[1]],sum))
  mij <- cbind(rep.vec[1],mij)
  names(mij) <- names(b)
  mi.vec <-  rowSums(mij[,2:(r+1)]) #Total number of ratings per subject mi.
  m.jvec <- colSums(mij[,2:(r+1)]) #Total number of ratings per rater m.j
  lambda0 <- sum(mij[,2:(r+1)]>=1)
  k1 <- sum(mi.vec**2)
  k2 <- sum(m.jvec**2)
  k1p <- k1/Mtot
  k2p <- k2/Mtot
  k3 <- sum((mij[,2:(r+1)]**2)/matrix(mi.vec,n,r),na.rm = TRUE)
  k4 <- sum((mij[,2:(r+1)]**2)/t(replicate(n,m.jvec)))
  k5 <- sum((mij[,2:(r+1)]**2))
  k5p <- k5/Mtot

  Ty <- sum(ratings[,2:(r+1)],na.rm = TRUE)
  Ty2.p <- Ty**2/Mtot
  T2y <- sum(ratings[,2:(r+1)]**2,na.rm = TRUE)
  yij. <- sapply(2:(r+1),function(x){tapply(ratings[[x]],ratings[[1]],function(x) sum(x,na.rm = TRUE))})
  yi.. <- rowSums(yij.,na.rm = TRUE)
  y.j. <- colSums(yij.,na.rm = TRUE)
  T2sr <- sum(yij.**2/mij[,2:(r+1)],na.rm = TRUE)
  T2s <- sum(yi..**2/mi.vec)
  T2r <- sum(y.j.**2/m.jvec)

  mijMax <- max(mij[,2:(r+1)])
  if (mijMax>1){
    sig2e <- max(0,(T2y - T2sr)/(Mtot-lambda0))
    delta.s <- (T2sr-T2s-(lambda0-n)*sig2e)/(Mtot-k3)
    delta.r <- (T2sr-T2r-(lambda0-r)*sig2e)/(Mtot-k4)
    sig2sr <- ((Mtot-k1p)*delta.r +(k3-k2p)*delta.s - (T2s-Ty2.p-(n-1)*sig2e))/(Mtot-k1p-k2p+k5p)
    sig2r <- delta.s - sig2sr
    sig2s <- delta.r- sig2sr
  }else{
    sig2sr <- 0
    delta.s <- (T2sr-T2s)/(Mtot-k3)
    delta.r <- (T2sr-T2r)/(Mtot-k4)
    sig2e <- ((Mtot-k1p)*delta.r +(k3-k2p)*delta.s - (T2s-Ty2.p))/(Mtot-k1p-k2p+k5p)
    sig2r <- delta.s - sig2e
    sig2s <- delta.r- sig2e
  }
  sig2s <- max(0,sig2s)
  sig2r <- max(0,sig2r)
  sig2sr <- max(0,sig2sr)
  sig2e <- max(0,sig2e)

  icc2r <- (sig2s/(sig2s+sig2r+sig2sr+sig2e))
  icc2a <- (sig2s+sig2r+sig2sr)/(sig2s+sig2r+sig2sr+sig2e)
  return(data.frame(sig2s,sig2r,sig2e,sig2sr,icc2r,icc2a,n,r,max.rep,min.rep,Mtot,ov.mean))
}

#----------------------------------------------------------------
#' Intraclass Correlation Coefficients (ICC) under the Mixed Factorial ANOVA model with Interaction.
#'
#' This function computes 2 ICC estimates ICC(3,1) and ICCa(3,1) as measures of inter-rater reliability and intra-rater reliability
#' coefficients under Model 3.  It is the the mixed factorial ANOVA model with interaction. Some subjects are expected to have
#' multiple ratings and due to the assumed interaction effect.
#' @references  Gwet, K.L. (2014): \emph{Handbook of Inter-Rater Reliability - 4th ed.} - Equation #10.2.9 of chapter 10, page 279
#' (for the inter-rater reliability ICC(3,1)), and Equation #10.2.10 of chapter 10, page 279 (for the intra-rater reliability ICCa(3,1)),
#' Advanced Analytics, LLC.
#' @param dfra This is a data frame containing 3 columns or more.  The first column contains subject numbers (some duplicates are expected,
#' as some subject are assumed to have assigned multiple ratings) and each of the remaining columns is associated with a particular rater and
#' contains its numeric ratings.
#' @return This function returns a list containing the following 12 values:
#' 1. sig2s: the subject variance component. 2.sig2r: the rater variance component 3. sig2e: the error variance component.
#' 4. sig2sr: the subject-rater interaction variance component. 5. icc2r: ICC as a measure of inter-rater relliability.
#' 6. icc2a: ICC as a measure of intra-rater reliability. 7. n: the number of subjects. 8. r: the number of raters.
#' 9. max.rep: the maximum number of ratings per subject. 10. min.rep: the minimum number of ratings per subjects.
#' 11. M: the total number of ratings for all subjects and raters. 12. ov.mean: the overall mean rating.
#' @examples
#' #iccdata2 is a small dataset that comes with the package. Use it as follows:
#' library(irrICC)
#' iccdata2 #see what the iccdata2 dataset looks like
#' icc3.inter.fn(iccdata2[,2:6]) #Here, you must omit the first column
#' coeff <- icc3.inter.fn(iccdata2[,2:6])$icc2a #this gives you intra-rater reliability coefficient
#' coeff
#' @export
icc3.inter.fn <- function(dfra){
  dfra <- data.frame(lapply(dfra, as.character),stringsAsFactors=FALSE)
  dfra <- as.data.frame(lapply(dfra,function (y) if(class(y)=="factor" ) as.character(y) else y),stringsAsFactors=F)
  dfra[,2:ncol(dfra)] <- lapply(dfra[,2:ncol(dfra)],as.numeric)

  rep.vec <- plyr::count(dfra,1)
  n <- nrow(rep.vec)
  r <- ncol(dfra)-1
  Mtot <- sum(!is.na(dfra[,2:ncol(dfra)])) #Mtot = total number of non-missing ratings
  max.rep <- max(rep.vec$freq)
  min.rep <- min(rep.vec$freq)
  ov.mean <- mean(as.matrix(dfra[,2:(r+1)]),na.rm = TRUE)

  b <- cbind(dfra[1],(!is.na(dfra[,2:(r+1)])))
  mij <- sapply(2:(r+1), function(x) tapply(b[[x]],b[[1]],sum))
  mij <- cbind(rep.vec[1],mij)
  names(mij) <- names(b)
  mi.vec <-  rowSums(mij[,2:(r+1)]) #Total number of ratings per subject mi.
  m.jvec <- colSums(mij[,2:(r+1)]) #Total number of ratings per rater m.j
  lambda0 <- sum(mij[,2:(r+1)]>=1)
  lambda.i <- rowSums((mij[,2:(r+1)]**2)/(replicate(r,mi.vec)),na.rm=TRUE)

  #-  Computing matrix F (r-1)x(r-1)

  mij.1 <- mij[,2:r] #This is an extract of mij using only the first r-1 raters.
  fjj.i <- (mij.1**2/replicate((r-1),mi.vec)) * (replicate((r-1),lambda.i+mi.vec)-2*mij.1)
  F.diag <- diag(colSums(fjj.i,na.rm = TRUE))

  if (r>=3){
    f1j.jj <- lapply(1:(r-2), function(j){
      fi.j.jj <- rep(0,r-1)
      fi.j.jj[(j+1):(r-1)] <- colSums(sapply((j+1):(r-1), function(jj) ((mij.1[,j]*mij.1[,jj])/mi.vec)*(lambda.i-mij.1[,j]-mij.1[,jj])),na.rm=TRUE)
      fi.j.jj
    })
    f1j.jj <- rbind(matrix(unlist(f1j.jj),nrow=r-2,ncol=r-1,byrow=TRUE),rep(0,(r-1)))
    fj.jj <- f1j.jj + t(f1j.jj)
    f.mat <- F.diag + fj.jj
  }else{
    if (r==2){
      f.mat <- sum((mij.1**2/mi.vec) * (lambda.i+mi.vec-2*mij.1),na.rm=TRUE)
    }
  }
  #-  Computing matrix C (r-1)x(r-1)
  cjj.vec <- m.jvec[1:(r-1)] - colSums(mij.1**2/replicate((r-1),mi.vec),na.rm=TRUE)
  c.diag <- diag(cjj.vec)
  if (r>=3){
    cj.jj.lst <- lapply(1:(r-2), function(j){
      cj.vec <- rep(0,r-1)
      cj.vec[(j+1):(r-1)] <- colSums(sapply((j+1):(r-1), function(jj) (-(mij.1[,j]*mij.1[,jj])/mi.vec)),na.rm=TRUE)
      cj.vec
    })
    cj.jj.mat <- rbind(matrix(unlist(cj.jj.lst),nrow=r-2,ncol=r-1,byrow=TRUE),rep(0,(r-1)))
    cj.jj <- cj.jj.mat + t(cj.jj.mat)
    c.mat <- c.diag + cj.jj
  }else{
    if (r==2) c.mat <- cjj.vec
  }
  k4 <- sum((mij[,2:(r+1)]**2)/t(replicate(n,m.jvec)))

  T2y <- sum(dfra[,2:(r+1)]**2,na.rm = TRUE)
  yij. <- sapply(2:(r+1),function(x){tapply(dfra[[x]],dfra[[1]],function(x) sum(x,na.rm = TRUE))})
  yi.. <- rowSums(yij.,na.rm = TRUE)
  y.j. <- colSums(yij.,na.rm = TRUE)
  yi..mean <- yi../mi.vec
  T2sr <- sum(yij.**2/mij[,2:(r+1)],na.rm = TRUE)
  T2s <- sum(yi..**2/mi.vec)
  T2r <- sum(y.j.**2/m.jvec)

  bj.vec <- y.j.[1:(r-1)]- t(mij.1)%*%yi..mean

  RSS <- T2s +  t(bj.vec)%*%solve(c.mat)%*%bj.vec
  k.star <- sum(lambda.i) + sum(diag((solve(c.mat)%*%f.mat)))
  h6 <- Mtot - k.star

  mijMax <- max(mij[,2:(r+1)])
  if (mijMax>1){
    sig2e <- (T2y - T2sr)/(Mtot-lambda0)
    sig2sr <- (T2sr-RSS-(lambda0-n-r+1)*sig2e)/h6
    sig2s <- (T2sr-T2r-(lambda0-r)*sig2e)/(Mtot-k4)-(r-1)*sig2sr/r
  }else{
    sig2sr <- 0
    sig2e <- (T2y-RSS)/(Mtot-n-r+1)
    sig2s <- (RSS-T2r-(n-1)*sig2e)/(Mtot-k4)
  }
  sig2s <- max(0,sig2s)
  sig2sr <- max(0,sig2sr)
  sig2e <- max(0,sig2e)
  icc2r <- (sig2s-sig2sr/(r-1))/(sig2s+sig2sr+sig2e)
  icc2a <- (sig2s+sig2sr)/(sig2s+sig2sr+sig2e)
  return(data.frame(sig2s,sig2e,sig2sr,icc2r,icc2a,n,r,max.rep,min.rep,Mtot,ov.mean))
}

#-----------------------------------------------------------
#' Mean of Squares for Errors (MSE) under ANOVA Models 2 & 3 with interaction.
#'
#' This function can be used to compute the MSE under the random (Model 2) and mixed (Model 3) efffects ANOVA model with interaction.
#' This MSE is needed for calculating confidence intervals and p-values associated with the inter-rater and intra-rater reliability
#' coefficients.
#' @references  Gwet, K.L. (2014): \emph{Handbook of Inter-Rater Reliability - 4th ed.} chapter 9, section 9.3.1 and chapter 10, section 10.3.1.
#' Advanced Analytics, LLC.
#' @param dfra This is a data frame containing 3 columns or more.  The first column contains subject numbers (there could be duplicates
#' if a subject was assigned multiple ratings) and each of the remaining columns is associated with a particular rater and contains its
#' numeric ratings.
# This function returns the mean of squares for errors.
mse2.inter.fn <- function(dfra){
  dfra <- data.frame(lapply(dfra, as.character),stringsAsFactors=FALSE)
  dfra <- as.data.frame(lapply(dfra,function (y) if(class(y)=="factor" ) as.character(y) else y),stringsAsFactors=F)
  dfra[,2:ncol(dfra)] <- lapply(dfra[,2:ncol(dfra)],as.numeric)
  rep.vec <- plyr::count(dfra,1)
  names(rep.vec)[2]<-"nrepli"
  n <- nrow(rep.vec) #n = number of subjects
  r <- ncol(dfra)-1 #r = number of raters
  Mtot <- sum(!is.na(dfra[,2:ncol(dfra)])) #Mtot = total number of non-missing ratings
  Mtot <- max(Mtot,r*n)
  yij. <- sapply(2:(r+1),function(x){tapply(dfra[[x]],dfra[[1]],function(x) sum(x,na.rm = TRUE))})
  yij.mean <- sapply(2:(r+1),function(x){tapply(dfra[[x]],dfra[[1]],function(x) mean(x,na.rm = TRUE))})
  yij.mean.f <- cbind(rep.vec[1],yij.mean)

  dfra.x <- merge(dfra,yij.mean.f)
  dfra1 <- dfra.x[,2:(r+1)]
  yij.mean.f <-dfra.x[,c((r+2):(2*r+1))]
  mse2.inter <- sum((dfra1-yij.mean.f)**2,na.rm = TRUE) / (Mtot-r*n)
  return(mse2.inter)
}

#----------------------------------------------------------------
#' Mean of Squares for Interaction (MSI) under ANOVA Models 2 & 3 with interaction.
#'
#' This function computes the MSI under both the random factorial (Model 2) and mixed factorial (Model 3) ANOVA model with
#' subject-rater interaction.  This MSI is used for calculating confidence intervals and p-values associated with the
#' inter-rater and intra-rater reliability coefficients.
#' coefficients under both models 2 and 3.
#' @references  Gwet, K.L. (2014): \emph{Handbook of Inter-Rater Reliability - 4th ed.} chapter 9, section 9.3.1 and chapter 10, section
#' 10.3.1. Advanced Analytics, LLC.
#' @param dfra This is a data frame containing 3 columns or more.  The first column contains subject numbers (there could be duplicates
#' if a subject was assigned multiple ratings) and each of the remaining columns is associated with a particular rater and contains its
#' numeric ratings.
# This function returns the mean of squares for interaction.
msi2.fn <- function(dfra){
  dfra <- data.frame(lapply(dfra, as.character),stringsAsFactors=FALSE)
  dfra <- as.data.frame(lapply(dfra,function (y) if(class(y)=="factor" ) as.character(y) else y),stringsAsFactors=F)
  dfra[,2:ncol(dfra)] <- lapply(dfra[,2:ncol(dfra)],as.numeric)
  rep.vec <- plyr::count(dfra,1)
  names(rep.vec)[2]<-"nrepli"
  n <- nrow(rep.vec) #n = number of subjects
  r <- ncol(dfra)-1 #r = number of raters
  Mtot <- sum(!is.na(dfra[,2:ncol(dfra)])) #Mtot = total number of non-missing ratings
  Mtot <- max(Mtot,r*n)
  ymean <- mean(as.matrix(dfra[,2:(r+1)]),na.rm = TRUE)

  b <- cbind(dfra[1],(!is.na(dfra[,2:(r+1)])))
  mij <- sapply(2:(r+1), function(x) tapply(b[[x]],b[[1]],sum))
  mij <- cbind(rep.vec[1],mij)
  names(mij) <- names(b)
  mi.vec <- rowSums(mij[,2:(r+1)]) #Total number of ratings per subject mi.
  m.jvec <- colSums(mij[,2:(r+1)]) #Total number of ratings per rater m.j

  yij. <- sapply(2:(r+1),function(x){tapply(dfra[[x]],dfra[[1]],function(x) sum(x,na.rm = TRUE))})
  yi.. <- rowSums(yij.,na.rm = TRUE)
  y.j. <- colSums(yij.,na.rm = TRUE)
  yij.mean <- sapply(2:(r+1),function(x){tapply(dfra[[x]],dfra[[1]],function(x) mean(x,na.rm = TRUE))})
  yi..mean <- yi../mi.vec
  y.j.mean <- y.j./m.jvec
  msi2.inter <-  sum((mij[,2:(r+1)] * (yij.mean - replicate(r,yi..mean) - matrix(y.j.mean,n,r,byrow = TRUE) +
                                        ymean*(replicate(r,rep(1,n))))**2),na.rm = TRUE) / ((r-1)*(n-1))
  return(msi2.inter)
}

#-----------------------------------------------------------
#' Mean of Squares for Raters (MSR) under ANOVA Model 2 with or without interaction.
#'
#' This function computes the MSR under the random factorial ANOVA model (MOdel 2). It can be used whether
#' or not the subject-rater interaction is assumed. The MSR is used for calculating confidence intervals and p-values associated
#' with the inter-rater and intra-rater reliability coefficients under model 2.
#' @references  Gwet, K.L. (2014): \emph{Handbook of Inter-Rater Reliability - 4th ed.} chapter 9, section 9.3.1, Advanced Analytics, LLC.
#' @param dfra This is a data frame containing 3 columns or more.  The first column contains subject numbers (there could be duplicates
#' if a subject was assigned multiple ratings) and each of the remaining columns is associated with a particular rater and contains its
#' numeric ratings.
# This function returns the mean of squares for raters.
msr2.fn <- function(dfra){
  dfra <- data.frame(lapply(dfra, as.character),stringsAsFactors=FALSE)
  dfra <- as.data.frame(lapply(dfra,function (y) if(class(y)=="factor" ) as.character(y) else y),stringsAsFactors=F)
  dfra[,2:ncol(dfra)] <- lapply(dfra[,2:ncol(dfra)],as.numeric)
  rep.vec <- plyr::count(dfra,1)
  names(rep.vec)[2]<-"nrepli"
  r <- ncol(dfra)-1 #r = number of raters
  ymean <- mean(as.matrix(dfra[,2:(r+1)]),na.rm = TRUE)

  b <- cbind(dfra[1],(!is.na(dfra[,2:(r+1)])))
  mij <- sapply(2:(r+1), function(x) tapply(b[[x]],b[[1]],sum))
  mij <- cbind(rep.vec[1],mij)
  names(mij) <- names(b)
  m.jvec <- colSums(mij[,2:(r+1)]) #Total number of ratings per rater m.j

  yij. <- sapply(2:(r+1),function(x){tapply(dfra[[x]],dfra[[1]],function(x) sum(x,na.rm = TRUE))})
  y.j. <- colSums(yij.,na.rm = TRUE)
  y.j.mean <- y.j./m.jvec
  msr2 <-  sum((m.jvec*(y.j.mean-ymean)**2),na.rm = TRUE) / (r-1)
  return(msr2)
}

#-----------------------------------------------------------
#' Mean of Squares for Subjects (MSS) under ANOVA Models 2 and 3, with or without interaction.
#'
#' This function computes the MSS under the random factorial (Model 2) and mixed factorial (Model 3) ANOVA model. The MSS is used
#' for calculating confidence intervals and p-values associated with the inter-rater and intra-rater reliability coefficients.
#' @references  Gwet, K.L. (2014): \emph{Handbook of Inter-Rater Reliability - 4th ed.} chapter 9, section 9.3.1 and chapter 10, section
#' 10.3.1. Advanced Analytics, LLC.
#' @param dfra This is a data frame containing 3 columns or more.  The first column contains subject numbers (there could be duplicates
#' if a subject was assigned multiple ratings) and each of the remaining columns is associated with a particular rater and contains its
#' numeric ratings.
#This function returns the mean of squares for subjects.
mss2.fn <- function(dfra){
  dfra <- data.frame(lapply(dfra, as.character),stringsAsFactors=FALSE)
  dfra <- as.data.frame(lapply(dfra,function (y) if(class(y)=="factor" ) as.character(y) else y),stringsAsFactors=F)
  dfra[,2:ncol(dfra)] <- lapply(dfra[,2:ncol(dfra)],as.numeric)
  rep.vec <- plyr::count(dfra,1)
  names(rep.vec)[2]<-"nrepli"
  n <- nrow(rep.vec) #n = number of subjects
  r <- ncol(dfra)-1 #r = number of raters
  Mtot <- sum(!is.na(dfra[,2:ncol(dfra)])) #Mtot = total number of non-missing ratings
  Mtot <- max(Mtot,r*n)
  ymean <- mean(as.matrix(dfra[,2:(r+1)]),na.rm = TRUE)

  b <- cbind(dfra[1],(!is.na(dfra[,2:(r+1)])))
  mij <- sapply(2:(r+1), function(x) tapply(b[[x]],b[[1]],sum))
  mij <- cbind(rep.vec[1],mij)
  names(mij) <- names(b)
  mi.vec <- rowSums(mij[,2:(r+1)]) #Total number of ratings per subject mi.
  yij. <- sapply(2:(r+1),function(x){tapply(dfra[[x]],dfra[[1]],function(x) sum(x,na.rm = TRUE))})
  yi.. <- rowSums(yij.,na.rm = TRUE)
  yi..mean <- yi../mi.vec
  mss2 <-  sum(mi.vec * (yi..mean - ymean)**2,na.rm = TRUE) / (n-1)
  return(mss2)
}

#' Confidence Interval of ICC(2,1) under ANOVA Model 2 with Interaction.
#'
#' This function computes the confidence interval associated with the Intraclass Correlation Coefficient (ICC) used as a measure
#' of inter-rater reliability, under the Random Factorial ANOVA model with interaction. It produces the lower and upper confidence bounds.
#' @references  Gwet, K.L. (2014): \emph{Handbook of Inter-Rater Reliability - 4th ed.} chapter 9, section 9.3.1, equations
#' 9.3.1 and 9.3.2. Advanced Analytics, LLC.
#' @param dfra This is a data frame containing 3 columns or more.  The first column contains subject numbers (there could be duplicates
#' if a subject was assigned multiple ratings) and each of the remaining columns is associated with a particular rater and contains its
#' numeric ratings.
#' @param conflev This is the optional confidence level associated with the confidence interval. If not specified, the default value
#' will be 0.95, which is the most commonly-used valuee in the literature.
#' @importFrom stats pf qf
#' @return This function returns a vector containing the lower confidence (lcb) and the upper confidence bound (ucb).
#' @examples
#' #iccdata1 is a small dataset that comes with the package. Use it as follows:
#' library(irrICC)
#' iccdata1 #see what the iccdata1 dataset looks like
#' ci.ICC2r.inter(iccdata1)
#' @export
ci.ICC2r.inter <- function(dfra,conflev=0.95){
  dfra <- data.frame(lapply(dfra, as.character),stringsAsFactors=FALSE)
  dfra <- as.data.frame(lapply(dfra,function (y) if(class(y)=="factor" ) as.character(y) else y),stringsAsFactors=F)
  dfra[,2:ncol(dfra)] <- lapply(dfra[,2:ncol(dfra)],as.numeric)

  icc <- icc2.inter.fn(dfra)[[5]]
  mse <- mse2.inter.fn(dfra)
  msi <- msi2.fn(dfra)
  msr <- msr2.fn(dfra)
  mss <- mss2.fn(dfra)
  rep.vec <- plyr::count(dfra,1)
  names(rep.vec)[2] <- "nrepli"
  n <- nrow(rep.vec) #n = number of subjects
  r <- ncol(dfra)-1 #r = number of raters
  Mtot <- sum(!is.na(dfra[,2:ncol(dfra)])) #Mtot = total number of non-missing ratings
  Mtot <- max(Mtot,r*n)
  if (is.na(icc)) icc <- 0
  if (abs(1-icc)>1e-15){
    a <- r*icc/(n*(1-icc))
    b <- 1 + r*(n-1)*icc/(n*(1-icc))
    c <- (Mtot/n-r)*icc/(1-icc)
  }else{
    a <- r/n
    b <- r*(n-1)/n
    c <- Mtot/n-r
  }
  v <- (a*msr+b*msi+c*mse)**2 / ((a*msr)**2/(r-1) +(b*msi)**2/((r-1)*(n-1)) + (c*mse)**2/(Mtot-r*n))
  v <- max(1,floor(v))
  f1 <- qf(1-(1-conflev)/2, df1=n-1, df2=v)
  f2 <- qf(1-(1-conflev)/2, df1=v, df2=n-1)
  lcb <- n*(mss-f1*msi)/(n*mss+f1*(r*msr+(r*n-r-n)*msi+(Mtot-r*n)*mse))
  ucb <- n*(f2*mss-msi)/(n*f2*mss+r*msr+(r*n-r-n)*msi+(Mtot-r*n)*mse)
  lcb <- max(0,lcb)
  ucb <- min(1,ucb)
  if (!is.na(lcb) & !is.na(ucb)){
    if (icc <= lcb) lcb <- 0
    if (icc >= ucb) ucb <- 1
  }
  return(data.frame(lcb,ucb))
}

#-----------------------------------------------------------
#' Confidence Interval of ICC(3,1) under ANOVA Model 3 with Interaction.
#'
#' This function computes the confidence interval associated with the Intraclass Correlation Coefficient (ICC) as a measure of
#' inter-rater reliability under the mixed factorial ANOVA model with interaction. It produces the lower and upper confidence bounds.
#' @references  Gwet, K.L. (2014): \emph{Handbook of Inter-Rater Reliability - 4th ed.} chapter 10, section 10.3.1, equations
#' 10.3.1 and 10.3.2. Advanced Analytics, LLC.
#' @param dfra This is a data frame containing 3 columns or more.  The first column contains subject numbers (there could be duplicates
#' if a subject was assigned multiple ratings) and each of the remaining columns is associated with a particular rater and contains its
#' numeric ratings.
#' @param conflev This is the optional confidence level associated with the confidence interval. If not specified, the default value
#' will be 0.95, which is the most commonly-used valuee in the literature.
#' @return This function returns a vector containing the lower confidence (lcb) and the upper confidence bound (ucb).
#' @examples
#' #iccdata1 is a small dataset that comes with the package. Use it as follows:
#' library(irrICC)
#' iccdata1 #see what the iccdata1 dataset looks like
#' ci.ICC3r.inter(iccdata1)
#' ci.ICC3r.inter(iccdata1)$ucb #to get upper confidence bound only
#' @export
ci.ICC3r.inter <- function(dfra,conflev=0.95){
  #This function produces the confidence interval associated with the intraclass correlation coefficient ICC(3,1) - i.e. inter-rater reliability -
  #and based on model 3 with interaction (c.f. K. Gwet- Handbook of Inter-Rater Reliability-4th Edition, page 282, equations 10.3.1 and 10.3.2)
  dfra <- data.frame(lapply(dfra, as.character),stringsAsFactors=FALSE)
  dfra <- as.data.frame(lapply(dfra,function (y) if(class(y)=="factor" ) as.character(y) else y),stringsAsFactors=F)
  dfra[,2:ncol(dfra)] <- lapply(dfra[,2:ncol(dfra)],as.numeric)

  icc <- icc3.inter.fn(dfra)[[4]]
  mse <- mse2.inter.fn(dfra)
  msi <- msi2.fn(dfra)
  mss <- mss2.fn(dfra)
  rep.vec <- plyr::count(dfra,1)
  names(rep.vec)[2] <- "nrepli"
  n <- nrow(rep.vec) #n = number of subjects
  r <- ncol(dfra)-1 #r = number of raters
  Mtot <- sum(!is.na(dfra[,2:ncol(dfra)])) #Mtot = total number of non-missing ratings
  Mtot <- max(Mtot,r*n)
  if (is.na(icc)) icc <- 0
  if (abs(1-icc)>1e-15){
    a <- (1+(r-1)*icc)/(1-icc)
    b <- (Mtot/n-r)*icc/(1-icc)
  }else{
    a <- r
    b <- max(0,Mtot/n-r)
  }
  v <- (a*msi+b*mse)**2 / ((a*msi)**2/((r-1)*(n-1)) + (b*mse)**2/max(1,(Mtot-r*n)))
  v <- max(1,floor(v))
  f1 <- qf(1-(1-conflev)/2, df1=n-1, df2=v)
  f2 <- qf((1-conflev)/2, df1=n-1, df2=v)
  lcb <- (mss-f1*msi)/(mss+f1*((r-1)*msi+(Mtot/n-r)*mse))
  ucb <- (mss-f2*msi)/(mss+f2*((r-1)*msi+(Mtot/n-r)*mse))
  lcb <- max(0,lcb)
  ucb <- min(1,ucb)
  if (!is.na(lcb) & !is.na(ucb)){
    if (icc<=lcb) lcb <-0
    if (icc>=ucb) ucb <-1
  }
  # c.i <- paste0("(",format(lcb,digits=4,scientific=FALSE)," to ",format(ucb,digits=4,scientific=FALSE),")")
  return(data.frame(lcb,ucb))
}

#-----------------------------------------------------------
#' P-value of the Intraclass Correlation Coefficient ICC(3,1) under Model 3 with subject-rater interaction.
#'
#' This function computes the p-value associated with the ICC under the mixed factorial ANOVA model with subject-rater interaction.
#' The ICC considered here is the one used as a measure of inter-rater reliability and the p-value is calculated for each of the null
#' values specified in the parameter rho.zero.
#' @references  Gwet, K.L. (2014): \emph{Handbook of Inter-Rater Reliability - 4th ed.} chapter 10, section 10.3.3 Advanced Analytics, LLC.
#' @param dfra This is a data frame containing 3 columns or more.  The first column contains subject numbers (there could be duplicates
#' if a subject was assigned multiple ratings) and each of the remaining columns is associated with a particular rater and contains its
#' numeric ratings.
#' @param rho.zero This is an optional parameter that represents a vector containing an arbitrary number of null values between 0 and 1
#' for which a p-value will be calculated. If not specified then its default value will be 0.
#' @return This function returns a vector containing p-values associated with the null values specified in the parameter rho.zero.
#' @examples
#' #iccdata1 is a small dataset that comes with the package. Use it as follows:
#' library(irrICC)
#' iccdata1 #see what the iccdata1 dataset looks like
#' pvals.ICC3r.inter(iccdata1) #gives you the p-value associated with default null value of 0
#' pvals.ICC3r.inter(iccdata1,c(0,0.15,0.25,0.33)) #produces p-values for an arbitrary vector
#' @export
pvals.ICC3r.inter <- function(dfra,rho.zero=0){
  #This function produces a vector of p-values associated with the intraclass correlation coefficient ICC(3,1) - i.e. inter-rater reliability -
  #and based on model 3 with interaction (c.f. K. Gwet- Handbook of Inter-Rater Reliability-4th Edition, section 10.3.3).
  #A p-value is calculed for each null value specified in parameter rho.zero=???
  dfra <- data.frame(lapply(dfra, as.character),stringsAsFactors=FALSE)
  dfra <- as.data.frame(lapply(dfra,function (y) if(class(y)=="factor" ) as.character(y) else y),stringsAsFactors=F)
  dfra[,2:ncol(dfra)] <- lapply(dfra[,2:ncol(dfra)],as.numeric)

  icc <- icc3.inter.fn(dfra)[[4]]
  mse <- mse2.inter.fn(dfra)
  msi <- msi2.fn(dfra)
  mss <- mss2.fn(dfra)
  rep.vec <- plyr::count(dfra,1)
  names(rep.vec)[2] <- "nrepli"
  n <- nrow(rep.vec) #n = number of subjects
  r <- ncol(dfra)-1 #r = number of raters
  Mtot <- sum(!is.na(dfra[,2:ncol(dfra)])) #Mtot = total number of non-missing ratings
  Mtot <- max(Mtot,r*n)
  rlen <- length(rho.zero)
  pval <- sapply(1:rlen,function(x){
    if (abs(1-rho.zero[x])>1e-15){
      a <- (1+(r-1)*rho.zero[x])/(1-rho.zero[x])
      b <- (Mtot/n-r)*rho.zero[x]/(1-rho.zero[x])
    }else{
      a <- r
      b <- max(0,Mtot/n-r)
    }
    v <- (a*msi+b*mse)**2 / ((a*msi)**2/((r-1)*(n-1)) + (b*mse)**2/max(1,(Mtot-r*n)))
    v <- max(1,floor(v))
    fobs <- mss/(a*msi + b*mse)
    pvals <- 1 - pf(fobs,df1=n-1,df2=v)
  })
  return(data.frame(rho.zero,pval))
}

#------------------------------------------------------------
#' Confidence Interval of ICCa(2,1), a measure of intra-rater reliability under Model 2 with interaction.
#'
#' This function computes the confidence interval of the Intraclass Correlation Coefficient ICCa(2,1) under the random factorial ANOVA
#' model with subject-rater interaction. ICCa(2,1) is formulated as a measure of intra-rater reliability coefficient. This function
#' computes the lower and upper confidence bounds of the confidence interval.
#' @references  Gwet, K.L. (2014): \emph{Handbook of Inter-Rater Reliability - 4th ed.} chapter 9, section 9.3.2, equations
#' 9.3.7 and 9.3.8. Advanced Analytics, LLC.
#' @param dfra This is a data frame containing 3 columns or more.  The first column contains subject numbers (there could be duplicates
#' if a subject was assigned multiple ratings) and each of the remaining columns is associated with a particular rater and contains its
#' numeric ratings.
#' @param conflev This is the optional confidence level associated with the confidence interval. If not specified, the default value
#' will be 0.95, which is the most commonly-used valuee in the literature.
#' @return This function returns a vector containing the lower confidence (lcb) and the upper confidence bound (ucb).
#' @examples
#' #iccdata1 is a small dataset that comes with the package. Use it as follows:
#' library(irrICC)
#' iccdata1 #see what the iccdata1 dataset looks like
#' ci.ICC2a.inter(iccdata1)
#' ci.ICC2a.inter(iccdata1)$ucb #this only gives the upper confidence bound
#' ci.ICC2a.inter(iccdata1,0.90) #this gives you the 90% confidence interval
#' @export
ci.ICC2a.inter <- function(dfra,conflev=0.95){
  #This function produces the confidence interval associated with the intraclass correlation coefficient ICCa(2,1) - i.e. intra-rater reliability -
  #and based on model 2 with interaction (c.f. K. Gwet- Handbook of Inter-Rater Reliability-4th Edition, page 244-245, equations 9.3.7 and 9.3.8)
  dfra <- data.frame(lapply(dfra, as.character),stringsAsFactors=FALSE)
  dfra <- as.data.frame(lapply(dfra,function (y) if(class(y)=="factor" ) as.character(y) else y),stringsAsFactors=F)
  dfra[,2:ncol(dfra)] <- lapply(dfra[,2:ncol(dfra)],as.numeric)

  icc <- icc2.inter.fn(dfra)[[6]] #<- intra-rater reliability. -- return(data.frame(sig2s,sig2r,sig2e,sig2sr,icc2r,icc2a,n,r,max.rep,min.rep,Mtot,ov.mean))
  mse <- mse2.inter.fn(dfra)
  msi <- msi2.fn(dfra)
  msr <- msr2.fn(dfra)
  mss <- mss2.fn(dfra)

  rep.vec <- plyr::count(dfra,1)
  names(rep.vec)[2] <- "nrepli"
  n <- nrow(rep.vec) #n = number of subjects
  r <- ncol(dfra)-1  #r = number of raters
  Mtot <- sum(!is.na(dfra[,2:ncol(dfra)])) #Mtot = total number of non-missing ratings
  Mtot <- max(Mtot,r*n)
  if (is.na(icc)) icc <- 0
  if (abs(1-icc)>1e-15){
    a <- 1/(r+Mtot*icc/(n*(1-icc)))
    b <- 1/(n+Mtot*icc/(r*(1-icc)))
    c <- (r*n-n-r)/(r*n+Mtot*icc/(1-icc))
  }else{
    a <- n/Mtot
    b <- r/Mtot
    c <- (r*n-n-r)/Mtot
  }
  v <- (a*mss+b*msr+c*msi)**2 / ((a*mss)**2/(n-1) + (b*msr)**2/(r-1) + (c*msi)**2/((r-1)*(n-1)))
  v <- max(1,floor(v))
  f1 <- qf((1-conflev)/2, df1=v, df2=Mtot-r*n)
  f2 <- qf(1-(1-conflev)/2, df1=v, df2=Mtot-r*n)
  A <- n*mss + r*msr + (r*n-n-r)*msi
  lcb <- (A-r*n*f2*mse)/(A+(Mtot-r*n)*f2*mse)
  ucb <- (A-r*n*f1*mse)/(A+(Mtot-r*n)*f1*mse)
  lcb <- max(0,lcb)
  ucb <- min(1,ucb)
  if (!is.na(lcb) & !is.na(ucb)){
    if (icc<=lcb) lcb <-0
    if (icc>=ucb) ucb <-1
  }
  # c.i <- paste0("(",format(lcb,digits=4,scientific=FALSE)," to ",format(ucb,digits=4,scientific=FALSE),")")
  return(data.frame(lcb,ucb))
}

#-------------------------------------------
#' Confidence Interval of ICCa(3,1), a measure of intra-rater reliability under MOdel 3.
#'
#' This function computes the confidence interval of the Intraclass Correlation Coefficient ICCa(3,1) under the mixed factorial ANOVA
#' model (Model 3) with subject-rater interaction. ICCa(3,1) is formulated as a measure of intra-rater reliability coefficient. This
#' function computes the lower and upper confidence bounds of the confidence interval.
#' @references  Gwet, K.L. (2014): \emph{Handbook of Inter-Rater Reliability - 4th ed.} chapter 10, section 10.3.2, equations
#' 10.3.10 and 10.3.11. Advanced Analytics, LLC.
#' @param dfra This is a data frame containing 3 columns or more.  The first column contains subject numbers (there could be duplicates
#' if a subject was assigned multiple ratings) and each of the remaining columns is associated with a particular rater and contains its
#' numeric ratings.
#' @param conflev This is the optional confidence level associated with the confidence interval. If not specified, the default value
#' will be 0.95, which is the most commonly-used valuee in the literature.
#' @return This function returns a vector containing the lower confidence (lcb) and the upper confidence bound (ucb).
#' @examples
#' #iccdata1 is a small dataset that comes with the package. Use it as follows:
#' library(irrICC)
#' iccdata1 #see what the iccdata1 dataset looks like
#' ci.ICC3a.inter(iccdata1)
#' ci.ICC3a.inter(iccdata1)$ucb #this only gives the upper confidence bound
#' ci.ICC3a.inter(iccdata1,0.90) #this gives you the 90% confidence interval
#' @export
ci.ICC3a.inter <- function(dfra,conflev=0.95){
  #This function produces the confidence interval associated with the intraclass correlation coefficient ICCa(3,1) - i.e. intra-rater reliability -
  #and based on model 3 with interaction (c.f. K. Gwet- Handbook of Inter-Rater Reliability-4th Edition, page 284-285, equations 10.3.10 and 10.3.11)
  dfra <- data.frame(lapply(dfra, as.character),stringsAsFactors=FALSE)
  dfra <- as.data.frame(lapply(dfra,function (y) if(class(y)=="factor" ) as.character(y) else y),stringsAsFactors=F)
  dfra[,2:ncol(dfra)] <- lapply(dfra[,2:ncol(dfra)],as.numeric)

  icc <- icc3.inter.fn(dfra)[[5]] #<- intra-rater reliability. -- return(data.frame(sig2s,sig2r,sig2e,sig2sr,icc2r,icc2a,n,r,max.rep,min.rep,Mtot,ov.mean))
  mse <- mse2.inter.fn(dfra)
  msi <- msi2.fn(dfra)
  mss <- mss2.fn(dfra)
  rep.vec <- plyr::count(dfra,1)
  names(rep.vec)[2] <- "nrepli"
  n <- nrow(rep.vec) #n = number of subjects
  r <- ncol(dfra)-1  #r = number of raters
  Mtot <- sum(!is.na(dfra[,2:ncol(dfra)])) #Mtot = total number of non-missing ratings
  Mtot <- max(Mtot,r*n)
  if (is.na(icc)) icc <- 0
  if (abs(1-icc)>1e-15){
    a <- 1/(r+1+Mtot*icc/(n*(1-icc)))
    b <- r/(r+1+Mtot*icc/(n*(1-icc)))
  }else{
    a <- n/Mtot
    b <- r*n/Mtot
  }
  v <- (a*mss+b*msi)**2 / ((a*mss)**2/(n-1) + (b*msi)**2/((r-1)*(n-1)))
  v <- max(1,floor(v))
  f1 <- qf((1-conflev)/2, df1=v, df2=Mtot-r*n)
  f2 <- qf(1-(1-conflev)/2, df1=v, df2=Mtot-r*n)
  lcb <- (mss+r*msi-(r+1)*f2*mse)/(mss+r*msi+(Mtot/n-r-1)*f2*mse)
  ucb <- (mss+r*msi-(r+1)*f1*mse)/(mss+r*msi+(Mtot/n-r-1)*f1*mse)
  lcb <- max(0,lcb)
  ucb <- min(1,ucb)
  if (!is.na(lcb) & !is.na(ucb)){
    if (icc<=lcb) lcb <-0
    if (icc>=ucb) ucb <-1
  }
  return(data.frame(lcb,ucb))
}

#-------------------------------------------
#' P-values of ICC(2,1) under Model 2 with subject-rater interaction, for 6 specific null values.
#'
#' This function computes 6 p-values for the Intraclass Correlation Coefficient (ICC) used as a measure of inter-rater reliability
#' under the random factorial ANOVA model (Model 2) with subject-rater interaction. Each of the 6 p-values is associated with one
#' of the null values 0,0.1,0.3,0.5,0.7,0.9.
#' @references  Gwet, K.L. (2014): \emph{Handbook of Inter-Rater Reliability - 4th ed.} chapter 9, section 9.3.1, equation
#' 9.3.6. Advanced Analytics, LLC.
#' @param dfra This is a data frame containing 3 columns or more.  The first column contains subject numbers (there could be duplicates
#' if a subject was assigned multiple ratings) and each of the remaining columns is associated with a particular rater and contains its
#' numeric ratings.
#' @return This function returns a vector containing 6 p-values associated with the 6 null values 0,0.1,0.3,0.5,0.7,0.9.
#' @examples
#' #iccdata1 is a small dataset that comes with the package. Use it as follows:
#' library(irrICC)
#' iccdata1 #see what the iccdata1 dataset looks like
#' pval.ICC2r.inter(iccdata1)
#' @export
pval.ICC2r.inter <- function(dfra){
  #P-value calculation for Intraclass Correlation Coefficient ICC(2,1) associated with model 2 with interaction
  #(c.f. K. Gwet-2014 "Handbook of Inter-Rater Reliability", 4th Edition, chapter #9, equation #9.3.6). This function
  #computes 6 p-values associated with the 6 rho values in rho.zero <- c(0,0.1,0.3,0.5,0.7,0.9).
  dfra <- data.frame(lapply(dfra, as.character),stringsAsFactors=FALSE)
  dfra <- as.data.frame(lapply(dfra,function (y) if(class(y)=="factor" ) as.character(y) else y),stringsAsFactors=F)
  dfra[,2:ncol(dfra)] <- lapply(dfra[,2:ncol(dfra)],as.numeric)

  icc <- icc2.inter.fn(dfra)[[5]]
  mse <- mse2.inter.fn(dfra)
  msi <- msi2.fn(dfra)
  msr <- msr2.fn(dfra)
  mss <- mss2.fn(dfra)
  rep.vec <- plyr::count(dfra,1)
  names(rep.vec)[2] <- "nrepli"
  n <- nrow(rep.vec) #n = number of subjects
  r <- ncol(dfra)-1 #r = number of raters
  Mtot <- sum(!is.na(dfra[,2:ncol(dfra)])) #Mtot = total number of non-missing ratings
  Mtot <- max(Mtot,r*n)
  rho.zero <- c(0,0.1,0.3,0.5,0.7,0.9)
  pval <- sapply(1:6,function(x){
    a <- r*rho.zero[x]/(n*(1-rho.zero[x]))
    b <- 1 + r*(n-1)*rho.zero[x]/(n*(1-rho.zero[x]))
    c <- (Mtot/n-r)*rho.zero[x]/(1-rho.zero[x])
    v <- (a*msr+b*msi+c*mse)**2 / ((a*msr)**2/(r-1) + (b*msi)**2/((r-1)*(n-1)) + (c*mse)**2/(Mtot-r*n))
    v <- max(1,floor(v))
    fobs <- mss/(a*msr+b*msi+c*mse)
    pvals <- 1 - pf(fobs,df1=n-1,df2=v)
  })
  return(data.frame(rho.zero,pval))
}

#-----------------------------
#' P-values of ICC(2,1) under Model 2 with subject-rater interaction, for user-provided null values.
#'
#' This function computes p-values for the Intraclass Correlation Coefficients (ICC) used as a measure of inter-rater reliability
#' under the random factorial ANOVA model (Model 2) with subject-rater interaction. The output is vector of p-values, one for each of the
#' null values specified in the optional rho.zero parameter, whose default value is 0.
#' @references  Gwet, K.L. (2014): \emph{Handbook of Inter-Rater Reliability - 4th ed.} chapter 9, section 9.3.1 Advanced Analytics, LLC.
#' @param dfra This is a data frame containing 3 columns or more. The first column contains subject numbers (there could be duplicates
#' if a subject was assigned multiple ratings) and each of the remaining columns is associated with a particular rater and contains its
#' numeric ratings.
#' @param rho.zero This is an optional parameter that represents a vector containing an arbitrary number of null values between 0 and 1
#' for which a p-value will be calculated. If not specified then its default value will be 0.
#' @return This function returns a vector containing p-values associated with the null values specified in the parameter rho.zero.
#' @examples
#' #iccdata1 is a small dataset that comes with the package. Use it as follows:
#' library(irrICC)
#' iccdata1 #see what the iccdata1 dataset looks like
#' pvals.ICC2r.inter(iccdata1,c(0.15,0.20,0.25))
#' @export
pvals.ICC2r.inter <- function(dfra,rho.zero=0){
  #P-value calculation for Intraclass Correlation Coefficient ICC(2,1) associated with model 2 with interaction
  #(c.f. K. Gwet-2014 "Handbook of Inter-Rater Reliability", 4th Edition, chapter #9, equation #9.3.6).
  #This function computes p-values either for a single rho-zero value or for a vector of values assigned to parameter rho.zero= VALUES.
  dfra <- data.frame(lapply(dfra, as.character),stringsAsFactors=FALSE)
  dfra <- as.data.frame(lapply(dfra,function (y) if(class(y)=="factor" ) as.character(y) else y),stringsAsFactors=F)
  dfra[,2:ncol(dfra)] <- lapply(dfra[,2:ncol(dfra)],as.numeric)

  icc <- icc2.inter.fn(dfra)[[5]]
  mse <- mse2.inter.fn(dfra)
  msi <- msi2.fn(dfra)
  msr <- msr2.fn(dfra)
  mss <- mss2.fn(dfra)
  rep.vec <- plyr::count(dfra,1)
  names(rep.vec)[2] <- "nrepli"
  n <- nrow(rep.vec) #n = number of subjects
  r <- ncol(dfra)-1 #r = number of raters
  Mtot <- sum(!is.na(dfra[,2:ncol(dfra)])) #Mtot = total number of non-missing ratings
  Mtot <- max(Mtot,r*n)
  rlen <- length(rho.zero)
  pval <- sapply(1:rlen,function(x){
    a <- r*rho.zero[x]/(n*(1-rho.zero[x]))
    b <- 1 + r*(n-1)*rho.zero[x]/(n*(1-rho.zero[x]))
    c <- (Mtot/n-r)*rho.zero[x]/(1-rho.zero[x])
    v <- (a*msr+b*msi+c*mse)**2 / ((a*msr)**2/(r-1) + (b*msi)**2/((r-1)*(n-1)) + (c*mse)**2/(Mtot-r*n))
    v <- max(1,floor(v))
    fobs <- mss/(a*msr+b*msi+c*mse)
    pvals <- 1 - pf(fobs,df1=n-1,df2=v)
  })
  return(data.frame(rho.zero,pval))
}

#-----------------------------
#' P-values of ICCa(2,1) under Model 2 with interaction.
#'
#' This function can compute several p-values associated with the Intraclass Correlation Coefficient (ICC) used to quantify intra-rater
#' reliability coefficient under the random factorial ANOVA model with subject-rater interaction (Model 2). This function computes
#' the p-value for each of the null values specified in the parameter gam.zero.
#' @references  Gwet, K.L. (2014): \emph{Handbook of Inter-Rater Reliability - 4th ed.} chapter 9, section 9.3.2 (page 245)
#' Advanced Analytics, LLC.
#' @param dfra This is a data frame containing 3 columns or more. The first column contains subject numbers (there could be duplicates
#' if a subject was assigned multiple ratings) and each of the remaining columns is associated with a particular rater and contains its
#' numeric ratings.
#' @param gam.zero This is an optional parameter that represents a vector containing an arbitrary number of null values between 0 and 1
#' for which a p-value will be calculated. If not specified then its default value will be 0.
#' @return This function returns a vector containing p-values associated with the null values specified in the parameter gam.zero.
#' @examples
#' #iccdata1 is a small dataset that comes with the package. Use it as follows:
#' library(irrICC)
#' iccdata1 #see what the iccdata1 dataset looks like
#' pvals.ICC2a.inter(iccdata1,c(0.15,0.20,0.25))
#' @export
pvals.ICC2a.inter <- function(dfra,gam.zero=0){
  #P-value calculation for Intraclass Correlation Coefficient ICCa(2,1) associated with model 2 with interaction
  #(c.f. K. Gwet-2014 "Handbook of Inter-Rater Reliability", 4th Edition, chapter #9, pp. 245-246.
  #This function computes p-values either for a single rho-zero value or for a vector of values assigned to parameter gam.zero= VALUES.
  dfra <- data.frame(lapply(dfra, as.character),stringsAsFactors=FALSE)
  dfra <- as.data.frame(lapply(dfra,function (y) if(class(y)=="factor" ) as.character(y) else y),stringsAsFactors=F)
  dfra[,2:ncol(dfra)] <- lapply(dfra[,2:ncol(dfra)],as.numeric)

  icc <- icc2.inter.fn(dfra)[[6]] #<- intra-rater reliability. -- return(data.frame(sig2s,sig2r,sig2e,sig2sr,icc2r,icc2a,n,r,max.rep,min.rep,Mtot,ov.mean))
  mse <- mse2.inter.fn(dfra)
  msi <- msi2.fn(dfra)
  msr <- msr2.fn(dfra)
  mss <- mss2.fn(dfra)
  rep.vec <- plyr::count(dfra,1)
  names(rep.vec)[2] <- "nrepli"
  n <- nrow(rep.vec) #n = number of subjects
  r <- ncol(dfra)-1  #r = number of raters
  Mtot <- sum(!is.na(dfra[,2:ncol(dfra)])) #Mtot = total number of non-missing ratings
  Mtot <- max(Mtot,r*n)
  rlen <- length(gam.zero)
  pval <- sapply(1:rlen,function(x){
      a <- 1/(r+Mtot*gam.zero[x]/(n*(1-gam.zero[x])))
      b <- 1/(n+Mtot*gam.zero[x]/(r*(1-gam.zero[x])))
      c <- (r*n-n-r)/(r*n+Mtot*gam.zero[x]/(1-gam.zero[x]))
      v <- (a*mss+b*msr+c*msi)**2 / ((a*mss)**2/(n-1) + (b*msr)**2/(r-1) + (c*msi)**2/((r-1)*(n-1)))
      v <- max(1,floor(v))
      fobs <- (a*mss+b*msr+c*msi)/mse
      pvals <- 1 - pf(fobs,df1=v,df2=Mtot-r*n)
  })
  return(data.frame(gam.zero,pval))
}




#---------------  NO INTERACTION  ------------------------------



#' Intraclass Correlation Coefficients ICC(2,1) and ICCa(2,1) under ANOVA Model 2 without interaction.
#'
#' This function computes 2 Intraclass Correlation Coefficients (ICC) ICC(2,1) and ICCa(2,1) under the random factorial ANOVA model
#' (Model 2) without any subject-rater interaction. ICC(2,1) is formulated as a measure of inter-rater reliability and ICCa(2,1)
#' as a measure of intra-rater reliability.
#' @references  Gwet, K.L. (2014): \emph{Handbook of Inter-Rater Reliability - 4th ed.} - Equations 9.5.2 and 9.5.3 of chapter 9, page 258.
#' Advanced Analytics, LLC.
#' @param ratings This is a data frame containing 3 columns or more.  The first column contains subject numbers (some duplicates are expected,
#' as some subject are assumed to have assigned multiple ratings) and each of the remaining columns is associated with a particular rater and
#' contains its numeric ratings.
#' @return This function returns a list containing the following 11 values:\cr
#' 1. sig2s: the subject variance component.\cr
#' 2.sig2r: the rater variance component\cr
#' 3. sig2e: the error variance component.\cr
#' 4. icc2r: ICC as a measure of inter-rater relliability.\cr
#' 5. icc2a: ICC as a measure of intra-rater reliability.\cr
#' 6. n: the number of subjects.\cr
#' 7. r: the number of raters.\cr
#' 8. max.rep: the maximum number of ratings per subject.\cr
#' 9. min.rep: the minimum number of ratings per subjects.\cr
#' 10. M: the total number of ratings for all subjects and raters.\cr
#' 11. ov.mean: the overall mean rating.
#' @examples
#' #iccdata1 is a small dataset that comes with the package. Use it as follows:
#' library(irrICC)
#' iccdata1 #see what the iccdata1 dataset looks like
#' icc2.nointer.fn(iccdata1)
#' coeff <- icc2.nointer.fn(iccdata1)$icc2r #this only gives you the ICC coefficient
#' coeff
#' @export
icc2.nointer.fn <- function(ratings){
  ratings <- data.frame(lapply(ratings, as.character),stringsAsFactors=FALSE)
  ratings <- as.data.frame(lapply(ratings,function (y) if(class(y)=="factor" ) as.character(y) else y),stringsAsFactors=F)
  ratings[,2:ncol(ratings)] <- lapply(ratings[,2:ncol(ratings)],as.numeric)

  rep.vec <- plyr::count(ratings,1)
  n <- nrow(rep.vec)
  r <- ncol(ratings)-1
  Mtot <- sum(!is.na(ratings[,2:ncol(ratings)])) #Mtot = total number of non-missing ratings
  Mtot <- max(Mtot,r*n)
  max.rep <- max(rep.vec$freq)
  min.rep <- min(rep.vec$freq)
  ov.mean <- mean(as.matrix(ratings[,2:(r+1)]),na.rm = TRUE)

  b <- cbind(ratings[1],(!is.na(ratings[,2:(r+1)])))
  mij <- sapply(2:(r+1), function(x) tapply(b[[x]],b[[1]],sum))
  mij <- cbind(rep.vec[1],mij)
  names(mij) <- names(b)
  mi.vec <-  rowSums(mij[,2:(r+1)]) #Total number of ratings per subject mi.
  m.jvec <- colSums(mij[,2:(r+1)]) #Total number of ratings per rater m.j

  k1 <- sum(mi.vec**2)
  k2 <- sum(m.jvec**2)
  k1p <- k1/Mtot
  k2p <- k2/Mtot
  k3 <- sum((mij[,2:(r+1)]**2)/matrix(mi.vec,n,r),na.rm = TRUE)
  k4 <- sum((mij[,2:(r+1)]**2)/t(replicate(n,m.jvec)))

  lambda1 <- (Mtot-k1p)/(Mtot-k4)
  lambda2 <- (Mtot-k2p)/(Mtot-k3)

  Ty <- sum(ratings[,2:(r+1)],na.rm = TRUE)
  T2.mu <- Ty**2/Mtot
  T2y <- sum(ratings[,2:(r+1)]**2,na.rm = TRUE)
  yij. <- sapply(2:(r+1),function(x){tapply(ratings[[x]],ratings[[1]],function(x) sum(x,na.rm = TRUE))})
  yi.. <- rowSums(yij.,na.rm = TRUE)
  y.j. <- colSums(yij.,na.rm = TRUE)
  T2s <- sum(yi..**2/mi.vec)
  T2r <- sum(y.j.**2/m.jvec)

  sig2e <- (lambda2*(T2y-T2s)+lambda1*(T2y-T2r)-(T2y-T2.mu))/(lambda2*(Mtot-n)+lambda1*(Mtot-r)-(Mtot-1))
  sig2s <- (T2y-T2r-(Mtot-r)*sig2e)/(Mtot-k4)
  sig2r <- (T2y-T2s-(Mtot-n)*sig2e)/(Mtot-k3)

  sig2s <- max(0,sig2s)
  sig2r <- max(0,sig2r)
  sig2e <- max(0,sig2e)

  icc2r <- sig2s/(sig2s+sig2r+sig2e)
  icc2a <- (sig2s+sig2r)/(sig2s+sig2r+sig2e)
  #print(c("sig2e:",sig2e,"sig2s:",sig2s,"sig2r:",sig2r,"iccr:",icc2r,"icca:",icc2a))
  return(data.frame(sig2s,sig2r,sig2e,icc2r,icc2a,n,r,max.rep,min.rep,Mtot,ov.mean))
}
#' Intraclass Correlation Coefficients ICC(3,1) and ICCa(3,1) under ANOVA Model 3 without interaction.
#'
#' This function computes 2 Intraclass Correlation Coefficients ICC(3,1) and ICCa(3,1) under the mixed factorial ANOVA model
#' (Model 3) without any subject-rater interaction. ICC(3,1) is formulated as a measure of inter-rater reliability and ICCa(3,1)
#' as a measure of intra-rater reliability.
#' @references  Gwet, K.L. (2014): \emph{Handbook of Inter-Rater Reliability - 4th ed.} - Equation 10.2.16 of chapter 10,
#' Advanced Analytics, LLC.
#' @param dfra This is a data frame containing 3 columns or more.  The first column contains subject numbers (some duplicates are expected,
#' as some subject are assumed to have assigned multiple ratings) and each of the remaining columns is associated with a particular rater and
#' contains its numeric ratings.
#' @return This function returns a list containing the following 11 values:\cr
#' 1. sig2s: the subject variance component.\cr
#' 2. sig2e: the error variance component.\cr
#' 3. icc2r: ICC as a measure of inter-rater relliability.\cr
#' 4. icc2a: ICC as a measure of intra-rater reliability.\cr
#' 5. n: the number of subjects. 6. r: the number of raters.\cr
#' 7. max.rep: the maximum number of ratings per subject.\cr
#' 8. min.rep: the minimum number of ratings per subjects.\cr
#' 9. M: the total number of ratings for all subjects and raters.\cr
#' 10. ov.mean: the overall mean rating.
#' @examples
#' #iccdata1 is a small dataset that comes with the package. Use it as follows:
#' library(irrICC)
#' iccdata1 #see what the iccdata1 dataset looks like
#' icc3.nointer.fn(iccdata1)
#' coeff <- icc3.nointer.fn(iccdata1)$icc2r #this only gives you the ICC coefficient
#' coeff
#' @export
icc3.nointer.fn <- function(dfra){
  dfra <- data.frame(lapply(dfra, as.character),stringsAsFactors=FALSE)
  dfra <- as.data.frame(lapply(dfra,function (y) if(class(y)=="factor" ) as.character(y) else y),stringsAsFactors=F)
  dfra[,2:ncol(dfra)] <- lapply(dfra[,2:ncol(dfra)],as.numeric)

  rep.vec <- plyr::count(dfra,1)
  n <- nrow(rep.vec)
  r <- ncol(dfra)-1
  Mtot <- sum(!is.na(dfra[,2:ncol(dfra)])) #Mtot = total number of non-missing ratings
  Mtot <- max(Mtot,r*n)
  max.rep <- max(rep.vec$freq)
  min.rep <- min(rep.vec$freq)
  ov.mean <- mean(as.matrix(dfra[,2:(r+1)]),na.rm = TRUE)

  b <- cbind(dfra[1],(!is.na(dfra[,2:(r+1)])))
  mij <- sapply(2:(r+1), function(x) tapply(b[[x]],b[[1]],sum))
  mij <- cbind(rep.vec[1],mij)
  names(mij) <- names(b)
  mi.vec <-  rowSums(mij[,2:(r+1)]) #Total number of ratings per subject mi.
  m.jvec <- colSums(mij[,2:(r+1)]) #Total number of ratings per rater m.j
  lambda0 <- sum(mij[,2:(r+1)]>=1)
  lambda.i <- rowSums((mij[,2:(r+1)]**2)/(replicate(r,mi.vec)),na.rm=TRUE)

  mij.1 <- mij[,2:r] #This is an extract of mij using only the first r-1 raters.

  cjj.vec <- m.jvec[1:(r-1)] - colSums(mij.1**2/replicate((r-1),mi.vec),na.rm=TRUE)
  c.diag <- diag(cjj.vec)
  if (r>=3){
    cj.jj.lst <- lapply(1:(r-2), function(j){
      cj.vec <- rep(0,r-1)
      cj.vec[(j+1):(r-1)] <- colSums(sapply((j+1):(r-1), function(jj) (-(mij.1[,j]*mij.1[,jj])/mi.vec)),na.rm=TRUE)
      cj.vec
    })
    cj.jj.mat <- rbind(matrix(unlist(cj.jj.lst),nrow=r-2,ncol=r-1,byrow=TRUE),rep(0,(r-1)))
    cj.jj <- cj.jj.mat + t(cj.jj.mat)
    c.mat <- c.diag + cj.jj
  }else{
    if (r==2) c.mat <- cjj.vec
  }
  k4 <- sum((mij[,2:(r+1)]**2)/t(replicate(n,m.jvec)))

  T2y <- sum(dfra[,2:(r+1)]**2,na.rm = TRUE)
  yij. <- sapply(2:(r+1),function(x){tapply(dfra[[x]],dfra[[1]],function(x) sum(x,na.rm = TRUE))})
  yi.. <- rowSums(yij.,na.rm = TRUE)
  y.j. <- colSums(yij.,na.rm = TRUE)
  yi..mean <- yi../mi.vec
  T2s <- sum(yi..**2/mi.vec)
  T2r <- sum(y.j.**2/m.jvec)
  bj.vec <- y.j.[1:(r-1)]- t(mij.1)%*%yi..mean
  RSS <- T2s +  t(bj.vec)%*%solve(c.mat)%*%bj.vec

  mijMax <- max(mij[,2:(r+1)])
  sig2e <- (T2y - RSS)/(Mtot-n-r+1)
  sig2s <- (RSS-T2r-(n-1)*sig2e)/(Mtot-k4)
  sig2e <- max(0,sig2e)
  sig2s <- max(0,sig2s)
  icc2r <- sig2s/(sig2s+sig2e)
  if (mijMax>1){
    icc2a <- sig2s/(sig2s+sig2e)
  }else{
    icc2a <- NA
  }
  return(data.frame(sig2s,sig2e,icc2r,icc2a,n,r,max.rep,min.rep,Mtot,ov.mean))
}
#' Mean of Squares for Errors (MSE) under Models 2 & 3 without replication
#'
#' This function computes the MSE for both the random factorial (Model 2) and mixed factorial (Model 3) without
#' subject-rater Interaction. This MSE is used for calculating confidence intervals and p-values associated with the inter-rater
#' and intra-rater reliability coefficients.
#' @references  Gwet, K.L. (2014): \emph{Handbook of Inter-Rater Reliability - 4th ed.} chapter 10, section 10.3.1,
#' Advanced Analytics, LLC.
#' @param dfra This is a data frame containing 3 columns or more.  The first column contains subject numbers (there could be duplicates
#' if a subject was assigned multiple ratings) and each of the remaining columns is associated with a particular rater and contains its
#' numeric ratings.
# This function returns the mean of squares for errors.
mse2.nointer.fn <- function(dfra){
  #This function computes the MSE associated with the Model 2 (i.e. ANOVA model under the random factorial design) without interaction.
  #Reference: K. Gwet(2014) - "Handbook of Inter-Rater Reliability", 4th Edition - Page #259
  dfra <- data.frame(lapply(dfra, as.character),stringsAsFactors=FALSE)
  dfra <- as.data.frame(lapply(dfra,function (y) if(class(y)=="factor" ) as.character(y) else y),stringsAsFactors=F)
  dfra[,2:ncol(dfra)] <- lapply(dfra[,2:ncol(dfra)],as.numeric)
  rep.vec <- plyr::count(dfra,1)
  names(rep.vec)[2]<-"nrepli"
  n <- nrow(rep.vec) #n = number of subjects
  r <- ncol(dfra)-1 #r = number of raters
  Mtot <- sum(!is.na(dfra[,2:ncol(dfra)])) #Mtot = total number of non-missing ratings
  Mtot <- max(Mtot,r*n)
  ymean <- mean(as.matrix(dfra[,2:(r+1)]),na.rm = TRUE)

  b <- cbind(dfra[1],(!is.na(dfra[,2:(r+1)])))
  mij <- sapply(2:(r+1), function(x) tapply(b[[x]],b[[1]],sum))
  mij <- cbind(rep.vec[1],mij)
  names(mij) <- names(b)
  mi.vec <- rowSums(mij[,2:(r+1)]) #Total number of ratings per subject mi.
  m.jvec <- colSums(mij[,2:(r+1)]) #Total number of ratings per rater m.j

  yij. <- sapply(2:(r+1),function(x){tapply(dfra[[x]],dfra[[1]],function(x) sum(x,na.rm = TRUE))})
  yi.. <- rowSums(yij.,na.rm = TRUE)
  y.j. <- colSums(yij.,na.rm = TRUE)
  yij.mean <- sapply(2:(r+1),function(x){tapply(dfra[[x]],dfra[[1]],function(x) mean(x,na.rm = TRUE))})
  yi..mean <- yi../mi.vec
  y.j.mean <- y.j./m.jvec
  yi.mean.1 <- cbind(rep.vec[1],yi..mean)
  dfra1 <- merge(dfra,yi.mean.1)
  dfra2 <- dfra1[,2:(r+1)]
  yi.mean.2 <- replicate(r,dfra1[,(r+2)])
  y.j.mean2 <- matrix(y.j.mean,nrow(dfra),r,byrow = TRUE)
  mse2.nointer <- sum((dfra2 - yi.mean.2 - y.j.mean2 + ymean*replicate(r,rep(1,nrow(dfra))))**2,na.rm = TRUE) / (Mtot-r-n+1)
  return(mse2.nointer)
}
#' Confidence Interval of the ICC(2,1) under Model 2 without subject-rater interaction
#'
#' This function computes the confidence interval associateed with the Intraclass Correlation Coefficient (ICC) used as a measure
#' of inter-rater reliability, under the random factorial ANOVA model (Model 2) with no subject-rater interaction. This function computes
#' the lower and upper confidence bounds.
#' @references  Gwet, K.L. (2014): \emph{Handbook of Inter-Rater Reliability - 4th ed.} chapter 9, section 9.5.1, equations
#' 9.5.7 and 9.5.8 for inter-rater reliability coefficients.
#' Advanced Analytics, LLC.
#' @param dfra This is a data frame containing 3 columns or more.  The first column contains subject numbers (there could be duplicates
#' if a subject was assigned multiple ratings) and each of the remaining columns is associated with a particular rater and contains its
#' numeric ratings.
#' @param conflev This is the optional confidence level associated with the confidence interval. If not specified, the default value
#' will be 0.95, which is the most commonly-used valuee in the literature.
#' @return This function returns a vector containing the lower confidence (lcb) and the upper confidence bound (ucb).
#' @examples
#' #iccdata1 is a small dataset that comes with the package. Use it as follows:
#' library(irrICC)
#' iccdata1 #see what the iccdata1 dataset looks like
#' ci.ICC2r.nointer(iccdata1)
#' @export
ci.ICC2r.nointer <- function(dfra,conflev=0.95){
  dfra <- data.frame(lapply(dfra, as.character),stringsAsFactors=FALSE)
  dfra <- as.data.frame(lapply(dfra,function (y) if(class(y)=="factor" ) as.character(y) else y),stringsAsFactors=F)
  dfra[,2:ncol(dfra)] <- lapply(dfra[,2:ncol(dfra)],as.numeric)

  icc <- icc2.nointer.fn(dfra)[[4]]
  mse <- mse2.nointer.fn(dfra)
  msr <- msr2.fn(dfra)
  mss <- mss2.fn(dfra)
  rep.vec <- plyr::count(dfra,1)
  names(rep.vec)[2] <- "nrepli"
  n <- nrow(rep.vec) #n = number of subjects
  r <- ncol(dfra)-1 #r = number of raters
  Mtot <- sum(!is.na(dfra[,2:ncol(dfra)])) #Mtot = total number of non-missing ratings
  Mtot <- max(Mtot,r*n)
  if (is.na(icc)) icc <- 0
  if (abs(1-icc)>1e-15){
    a <- r*icc/(n*(1-icc))
    b <- 1 + (Mtot-r)*icc/(n*(1-icc))
  }else{
    a <- r/n
    b <- (Mtot-r)/n
  }
  v <- (a*msr+b*mse)**2 / ((a*msr)**2/(r-1) + (b*mse)**2/(Mtot-r-n+1))
  v <- max(1,floor(v))
  f1 <- qf((1-conflev)/2, df1=n-1, df2=v)
  f2 <- qf(1-(1-conflev)/2, df1=n-1, df2=v)
  lcb <- n*(mss-f2*mse)/(n*mss+f2*(r*msr+(Mtot-n-r)*mse))
  ucb <- n*(mss-f1*mse)/(n*mss+f1*(r*msr+(Mtot-n-r)*mse))
  lcb <- max(0,lcb)
  ucb <- min(1,ucb)
  if (!is.na(lcb) & !is.na(ucb)){
    if (icc<=lcb) lcb <-0
    if (icc>=ucb) ucb <-1
  }
  return(data.frame(lcb,ucb))
}

#------------------------------------------------------------------------------------------
#' Confidence Interval of the ICC(3,1) under Model 3 without subject-rater interaction
#'
#' This function computes the confidence interval associateed with the Intraclass Correlation Coefficient (ICC) used as a measure
#' of inter-rater reliability, under the mixed factorial ANOVA model (Model 3) with no subject-rater interaction. This function computes
#' the lower and upper confidence bounds.
#' @references  Gwet, K.L. (2014): \emph{Handbook of Inter-Rater Reliability - 4th ed.} chapter 10, section 10.3.1, equations
#' 10.3.6 and 10.3.7, Advanced Analytics, LLC.
#' @param dfra This is a data frame containing 3 columns or more.  The first column contains subject numbers (there could be duplicates
#' if a subject was assigned multiple ratings) and each of the remaining columns is associated with a particular rater and contains its
#' numeric ratings.
#' @param conflev This is the optional confidence level associated with the confidence interval. If not specified, the default value
#' will be 0.95, which is the most commonly-used valuee in the literature.
#' @return This function returns a vector containing the lower confidence (lcb) and the upper confidence bound (ucb).
#' @examples
#' #iccdata1 is a small dataset that comes with the package. Use it as follows:
#' library(irrICC)
#' iccdata1 #see what the iccdata1 dataset looks like
#' ci.ICC3r.nointer(iccdata1)
#' @export
ci.ICC3r.nointer <- function(dfra,conflev=0.95){
  dfra <- data.frame(lapply(dfra, as.character),stringsAsFactors=FALSE)
  dfra <- as.data.frame(lapply(dfra,function (y) if(class(y)=="factor" ) as.character(y) else y),stringsAsFactors=F)
  dfra[,2:ncol(dfra)] <- lapply(dfra[,2:ncol(dfra)],as.numeric)

  icc <- icc3.nointer.fn(dfra)[[3]]
  mse <- mse2.nointer.fn(dfra)
  mss <- mss2.fn(dfra)
  rep.vec <- plyr::count(dfra,1)
  names(rep.vec)[2] <- "nrepli"
  n <- nrow(rep.vec) #n = number of subjects
  r <- ncol(dfra)-1 #r = number of raters
  Mtot <- sum(!is.na(dfra[,2:ncol(dfra)])) #Mtot = total number of non-missing ratings
  Mtot <- max(Mtot,r*n)
  f1 <- qf(1-(1-conflev)/2, df1=n-1, df2=Mtot-r-n+1)
  f2 <- qf((1-conflev)/2, df1=n-1, df2=Mtot-r-n+1)
  lcb <- (mss-f1*mse)/(mss+(Mtot/n-1)*f1*mse)
  ucb <- (mss-f2*mse)/(mss+(Mtot/n-1)*f2*mse)
  lcb <- max(0,lcb)
  ucb <- min(1,ucb)
  if (!is.na(lcb) & !is.na(ucb)){
    if (icc<=lcb) lcb <-0
    if (icc>=ucb) ucb <-1
  }
  return(data.frame(lcb,ucb))
}

#-----------------------------------------------------------
#' P-values of ICC(3,1) under Model 3 without subject-rater interaction.
#'
#' This function can compute several p-values associated with the Intraclass Correlation Coefficient (ICC) used to quantify inter-rater
#' reliability under the mixed factorial ANOVA model without subject-rater interaction (Model 3). This function computes
#' the p-value for each of the null values specified in the parameter rho.zero.
#' @references  Gwet, K.L. (2014): \emph{Handbook of Inter-Rater Reliability - 4th ed.} chapter 10, section 10.3.3 (page 286)
#' Advanced Analytics, LLC.
#' @param dfra This is a data frame containing 3 columns or more. The first column contains subject numbers (there could be duplicates
#' if a subject was assigned multiple ratings) and each of the remaining columns is associated with a particular rater and contains its
#' numeric ratings.
#' @param rho.zero This is an optional parameter that represents a vector containing an arbitrary number of null values between 0 and 1
#' for which a p-value will be calculated. If not specified then its default value will be 0.
#' @return This function returns a vector containing p-values associated with the null values specified in the parameter rho.zero.
#' @examples
#' #iccdata1 is a small dataset that comes with the package. Use it as follows:
#' library(irrICC)
#' iccdata1 #see what the iccdata1 dataset looks like
#' pvals.ICC3r.nointer(iccdata1)
#' pvals.ICC3r.nointer(iccdata1,seq(0.2,0.5,0.05))
#' @export
pvals.ICC3r.nointer <- function(dfra,rho.zero=0){
  #This function produces a vector of p-values associated with the intraclass correlation coefficient ICC(3,1) - i.e. inter-rater reliability -
  #and based on model 3 without interaction (c.f. K. Gwet- Handbook of Inter-Rater Reliability-4th Edition, section 10.3.3).
  #A p-value is calculed for each null value specified in parameter rho.zero=???
  dfra <- data.frame(lapply(dfra, as.character),stringsAsFactors=FALSE)
  dfra <- as.data.frame(lapply(dfra,function (y) if(class(y)=="factor" ) as.character(y) else y),stringsAsFactors=F)
  dfra[,2:ncol(dfra)] <- lapply(dfra[,2:ncol(dfra)],as.numeric)

  icc <- icc3.nointer.fn(dfra)[[3]]
  mse <- mse2.nointer.fn(dfra)
  mss <- mss2.fn(dfra)
  rep.vec <- plyr::count(dfra,1)
  names(rep.vec)[2] <- "nrepli"
  n <- nrow(rep.vec) #n = number of subjects
  r <- ncol(dfra)-1 #r = number of raters
  Mtot <- sum(!is.na(dfra[,2:ncol(dfra)])) #Mtot = total number of non-missing ratings
  Mtot <- max(Mtot,r*n)
  rlen <- length(rho.zero)
  pval <- sapply(1:rlen,function(x){
    fobs <- mss*(1-rho.zero[x])/(mse*(1+(r-1)*rho.zero[x]))
    pvals <- 1 - pf(fobs,df1=n-1,df2=max(1,Mtot-r-n+1))
  })
  return(data.frame(rho.zero,pval))
}

#-----------------------------------------------------------
#' P-values of ICCa(3,1) under Model 3 with subject-rater interaction.
#'
#' This function can compute several p-values associated with the Intraclass Correlation Coefficient (ICC) used to quantify intra-rater
#' reliability under the mixed factorial ANOVA model with subject-rater interaction (Model 3). This function computes
#' the p-value for each of the null values specified in the parameter rho.zero.
#' @references  Gwet, K.L. (2014): \emph{Handbook of Inter-Rater Reliability - 4th ed.} chapter 10, section 10.3.3 (page 286)
#' Advanced Analytics, LLC.
#' @param dfra This is a data frame containing 3 columns or more. The first column contains subject numbers (there could be duplicates
#' if a subject was assigned multiple ratings) and each of the remaining columns is associated with a particular rater and contains its
#' numeric ratings.
#' @param gam.zero This is an optional parameter that represents a vector containing an arbitrary number of null values between 0 and 1
#' for which a p-value will be calculated. If not specified then its default value will be 0.
#' @return This function returns a vector containing p-values associated with the null values specified in the parameter rho.zero.
#' @examples
#' #iccdata1 is a small dataset that comes with the package. Use it as follows:
#' library(irrICC)
#' iccdata1 #see what the iccdata1 dataset looks like
#' pvals.ICC3a.inter(iccdata1)
#' pvals.ICC3a.inter(iccdata1,seq(0.2,0.5,0.05))
#' @export
pvals.ICC3a.inter <- function(dfra,gam.zero=0){
  #This function produces a vector of p-values associated with the intraclass correlation coefficient ICCa(3,1) - i.e. intra-rater reliability -
  #and based on model 3 without interaction (c.f. K. Gwet- Handbook of Inter-Rater Reliability-4th Edition, section 10.3.3).
  #A p-value is calculed for each null value specified in parameter gam.zero=???
  dfra <- data.frame(lapply(dfra, as.character),stringsAsFactors=FALSE)
  dfra <- as.data.frame(lapply(dfra,function (y) if(class(y)=="factor" ) as.character(y) else y),stringsAsFactors=F)
  dfra[,2:ncol(dfra)] <- lapply(dfra[,2:ncol(dfra)],as.numeric)

  icc <- icc3.inter.fn(dfra)[[5]]
  mse <- mse2.inter.fn(dfra)
  msi <- msi2.fn(dfra)
  mss <- mss2.fn(dfra)
  rep.vec <- plyr::count(dfra,1)
  names(rep.vec)[2] <- "nrepli"
  n <- nrow(rep.vec) #n = number of subjects
  r <- ncol(dfra)-1 #r = number of raters
  Mtot <- sum(!is.na(dfra[,2:ncol(dfra)])) #Mtot = total number of non-missing ratings
  Mtot <- max(Mtot,r*n)
  rlen <- length(gam.zero)
  pval <- sapply(1:rlen,function(x){
    a <- 1/(r+1+Mtot*gam.zero[x]/(n*(1-gam.zero[x])))
    b <- r*a
    v <- (a*mss+b*msi)**2 /((a*mss)**2/(n-1)+(b*msi)**2/((r-1)*(n-1)))
    v <- max(1,floor(v))
    fobs <- (a*mss+b*msi)/mse
    pvals <- 1 - pf(fobs,df1=v,df2=max(1,Mtot-r*n))
  })
  return(data.frame(gam.zero,pval))
}
#------------------------------------------------------------------------------------------

#' Confidence Interval of ICCa(2,1) under Model 2 without subject-rater interaction.
#'
#' This function computes the confidence interval associated with the Intraclass Correlation Coefficient (ICC) formulated as a measure
#' of Intra-Rater Reliability under the random factorial ANOVA model (Model 2) without subject-rater interaction. This function produces
#' the lower and upper confidence bounds.
#' @references  Gwet, K.L. (2014): \emph{Handbook of Inter-Rater Reliability - 4th ed.} chapter 9, section 9.5.1, equations
#' 9.5.11 and 9.5.12,page 259. Advanced Analytics, LLC.
#' @param dfra This is a data frame containing 3 columns or more.  The first column contains subject numbers (there could be duplicates
#' if a subject was assigned multiple ratings) and each of the remaining columns is associated with a particular rater and contains its
#' numeric ratings.
#' @param conflev This is the optional confidence level associated with the confidence interval. If not specified, the default value
#' will be 0.95, which is the most commonly-used valuee in the literature.
#' @return This function returns a vector containing the lower confidence (lcb) and the upper confidence bound (ucb).
#' @examples
#' #iccdata1 is a small dataset that comes with the package. Use it as follows:
#' library(irrICC)
#' iccdata1 #see what the iccdata1 dataset looks like
#' ci.ICC2a.nointer(iccdata1)
#' @export
ci.ICC2a.nointer <- function(dfra,conflev=0.95){
  dfra <- data.frame(lapply(dfra, as.character),stringsAsFactors=FALSE)
  dfra <- as.data.frame(lapply(dfra,function (y) if(class(y)=="factor" ) as.character(y) else y),stringsAsFactors=F)
  dfra[,2:ncol(dfra)] <- lapply(dfra[,2:ncol(dfra)],as.numeric)
  icc <- icc2.nointer.fn(dfra)[[5]] #<- intra-rater reliability. -- c(sig2s,sig2r,sig2e,icc2r,icc2a,n,r,max.rep,min.rep,Mtot,ov.mean))
  mse <- mse2.nointer.fn(dfra)
  msr <- msr2.fn(dfra)
  mss <- mss2.fn(dfra)
  rep.vec <- plyr::count(dfra,1)
  names(rep.vec)[2] <- "nrepli"
  n <- nrow(rep.vec) #n = number of subjects
  r <- ncol(dfra)-1  #r = number of raters
  Mtot <- sum(!is.na(dfra[,2:ncol(dfra)])) #Mtot = total number of non-missing ratings
  Mtot <- max(Mtot,r*n)
  if (is.na(icc)) icc <- 0
  if (abs(1-icc)>1e-15){
    a <- n/(n+r+Mtot*icc/(1-icc))
    b <- r/(n+r+Mtot*icc/(1-icc))
  }else{
    a <- n/Mtot
    b <- r/Mtot
  }
  v <- (a*mss+b*msr)**2 / ((a*mss)**2/(n-1) + (b*msr)**2/(r-1))
  v <- max(1,floor(v))
  f1 <- qf((1-conflev)/2, df1=v, df2=Mtot-r-n+1)
  f2 <- qf(1-(1-conflev)/2, df1=v, df2=Mtot-r-n+1)
  lcb <- (n*mss+r*msr-(r+n)*f2*mse)/(n*mss+r*msr+(Mtot-n-r)*f2*mse)
  ucb <- (n*mss+r*msr-(r+n)*f1*mse)/(n*mss+r*msr+(Mtot-n-r)*f1*mse)
  lcb <- max(0,lcb)
  ucb <- min(1,ucb)
  if (!is.na(lcb) & !is.na(ucb)){
    if (icc<=lcb) lcb <-0
    if (icc>=ucb) ucb <-1
  }
  return(data.frame(lcb,ucb))
}

#-------------------------------------------
#' P-values of ICC(2,1) under Model 2 without subject-rater interaction.
#'
#' This function can compute several p-values associated with the Intraclass Correlation Coefficient (ICC) used to quantify inter-rater
#' reliability under the random factorial ANOVA model without subject-rater interaction (Model 2). This function computes
#' the p-value for each of the null values specified in the parameter rho.zero.
#' @references  Gwet, K.L. (2014): \emph{Handbook of Inter-Rater Reliability - 4th ed.} chapter 9, section 9.5.1, equation 9.5.15,
#' Advanced Analytics, LLC.
#' @param dfra This is a data frame containing 3 columns or more. The first column contains subject numbers (there could be duplicates
#' if a subject was assigned multiple ratings) and each of the remaining columns is associated with a particular rater and contains its
#' numeric ratings.
#' @param rho.zero This is an optional parameter that represents a vector containing an arbitrary number of null values between 0 and 1
#' for which a p-value will be calculated. If not specified then its default value will be 0.
#' @return This function returns a vector containing p-values associated with the null values specified in the parameter rho.zero.
#' @examples
#' #iccdata1 is a small dataset that comes with the package. Use it as follows:
#' library(irrICC)
#' iccdata1 #see what the iccdata1 dataset looks like
#' pvals.ICC2r.nointer(iccdata1)
#' pvals.ICC2r.nointer(iccdata1,seq(0.2,0.5,0.05))
#' @export
pvals.ICC2r.nointer <- function(dfra,rho.zero=0){
  mse <- mse2.nointer.fn(dfra)
  msr <- msr2.fn(dfra)
  mss <- mss2.fn(dfra)
  rep.vec <- plyr::count(dfra,1)
  names(rep.vec)[2] <- "nrepli"
  n <- nrow(rep.vec) #n = number of subjects
  r <- ncol(dfra)-1 #r = number of raters
  Mtot <- sum(!is.na(dfra[,2:ncol(dfra)])) #Mtot = total number of non-missing ratings
  Mtot <- max(Mtot,r*n)
  rlen <- length(rho.zero)
  pval <- sapply(1:rlen,function(x){
    a <- r*rho.zero[x]/(n*(1-rho.zero[x]))
    b <- 1 + (Mtot-r)*rho.zero[x]/(n*(1-rho.zero[x]))
    v <- (a*msr+b*mse)**2 / ((a*msr)**2/(r-1) + (b*mse)**2/(Mtot-r-n+1))
    v <- max(1,floor(v))
    fobs <- mss/(a*msr+b*mse)
    pvals <- 1 - pf(fobs,df1=n-1,df2=v)
  })
  return(data.frame(rho.zero,pval))
}

#-----------------------------
#' P-values of ICCa(2,1) under Model 2 without subject-rater interaction.
#'
#' This function can compute several p-values associated with the Intraclass Correlation Coefficient (ICC) used to quantify intra-rater
#' reliability under the random factorial ANOVA model without subject-rater interaction (Model 2). This function computes
#' the p-value for each of the null values specified in the parameter rho.zero.
#' @references  Gwet, K.L. (2014): \emph{Handbook of Inter-Rater Reliability - 4th ed.} chapter 9, section 9.5.1, equation 9.5.17,
#' Advanced Analytics, LLC.
#' @param dfra This is a data frame containing 3 columns or more. The first column contains subject numbers (there could be duplicates
#' if a subject was assigned multiple ratings) and each of the remaining columns is associated with a particular rater and contains its
#' numeric ratings.
#' @param gam.zero This is an optional parameter that represents a vector containing an arbitrary number of null values between 0 and 1
#' for which a p-value will be calculated. If not specified then its default value will be 0.
#' @return This function returns a vector containing p-values associated with the null values specified in the parameter rho.zero.
#' #iccdata1 is a small dataset that comes with the package. Use it as follows:
#' library(irrICC)
#' iccdata1 #see what the iccdata1 dataset looks like
#' pvals.ICC2a.nointer(iccdata1)
#' pvals.ICC2a.nointer(iccdata1,seq(0.2,0.5,0.05))
#' @export
pvals.ICC2a.nointer <- function(dfra,gam.zero=0){
  mse <- mse2.nointer.fn(dfra)
  msr <- msr2.fn(dfra)
  mss <- mss2.fn(dfra)
  rep.vec <- plyr::count(dfra,1)
  names(rep.vec)[2] <- "nrepli"
  n <- nrow(rep.vec) #n = number of subjects
  r <- ncol(dfra)-1  #r = number of raters
  Mtot <- sum(!is.na(dfra[,2:ncol(dfra)])) #Mtot = total number of non-missing ratings
  Mtot <- max(Mtot,r*n)
  rlen <- length(gam.zero)
  pval <- sapply(1:rlen,function(x){
    a <- n/(n+r+Mtot*gam.zero[x]/(1-gam.zero[x]))
    b <- r/(n+r+Mtot*gam.zero[x]/(1-gam.zero[x]))
    v <- (a*mss+b*msr)**2 / ((a*mss)**2/(n-1) + (b*msr)**2/(r-1))
    v <- max(1,floor(v))
    fobs <- (a*mss+b*msr)/mse
    pvals <- 1 - pf(fobs,df1=v,df2=Mtot-n-r+1)
  })
  return(data.frame(gam.zero,pval))
}

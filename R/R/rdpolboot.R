#' @title rdpolboot
#'
#' @description 
#' rdpolboot estimates bootstrapped confidence intervals around the asymptotic mean squared error (AMSE) of different polynomial orders in a regression discontinuity design. These compare the fit of different polynomial orders and can be used to choose between them if the estimate is sensitive to the polynomial order choice.
#' The package builds upon rdbwselect, the CCT bandwidth selector from Calonico, Cattaneo and Titiunik (2014a, 2014b), to calculate the MSE-optimal bandwidth for each polynomial order. Second, it uses rdmse from Pei, Lee, Card and Weber (2021) to estimate the AMSEs for each bootstrapped sample.
#' 
#' @usage 
#' rdpolboot(y, x, c = 0, fuzzy = NULL, covs = NULL, kernel = "tri", deriv = NULL, 
#' cluster = NULL, scaleregul = 1, plot = TRUE, groups = NULL, groupreps = 5, 
#' minpol = 1, maxpol = 4, reps = 15000, alpha = 0.05)
#' 
#' @param y a vector of the dependent variable
#' @param x a vector of the running variable (a.k.a. score or forcing variable)
#' @param c specifies the RD cutoff in x; default is \code{c = 0}.
#' @param fuzzy specifies the treatment status variable used to implement fuzzy RD estimation (or Fuzzy Kink RD if \code{deriv = 1} is also specified). Default is Sharp RD design and hence this option is not used.
#' @param covs specifies additional covariates to be used for estimation and inference.
#' @param kernel is the kernel function used to construct the local-polynomial estimator(s). Options are triangular (default option), epanechnikov and uniform.
#' @param deriv specifies the order of the derivative of the regression functions to be estimated. Default is \code{deriv = 0} (for Sharp RD, or for Fuzzy RD if fuzzy is also specified). Setting \code{deriv = 1} results in estimation of a Kink RD design (up to scale), or Fuzzy Kink RD if fuzzy is also specified.
#' @param cluster indicates the cluster ID variable used for cluster-robust variance estimation with degrees-of-freedom weights.
#' @param scaleregul specifies scaling factor for the regularization term added to the denominator of the bandwidth selectors. Setting \code{scaleregul = 0} removes the regularization term from the bandwidth selectors.  Default is \code{scaleregul = 1}.
#' @param plot if \code{TRUE}, the function produces a plot of the bootstrapped confidence intervals; default is \code{plot = TRUE}.
#' @param groups specifies the number groups the data is to be randomly split in. This option speeds up the jackknife calculations for estimating the acceleration value in case the data set is very large. Note that it does not have to exactly divide the total number of observations. Be careful not to choose a very large number of groups, as too small group sizes can crash calculation of the AMSE. Default is \code{groups = NULL}, and hence this option is not used.
#' @param groupreps specifies the number of repetitions for the jackknife procedure; default is \code{groupreps = 1}. If \code{groups} is specified, it is recommended to increase \code{groupreps} for a more reliable approximation of the acceleration factor.
#' @param minpol specifies the lowest polynomial order to consider for estimating bootstrapped confidence intervals; default is \code{minpol = 1}.
#' @param maxpol specifies the highest polynomial order to consider for estimating bootstrapped confidence intervals; default is \code{maxpol = 4}.
#' @param reps specifies the number of bootstrap repetitions; default is \code{reps = 15000}.
#' @param alpha specifies the percentage level of the BCa confidence interval; default is \code{alpha = 0.05}, yielding a 95\% confidence interval.
#' 
#' @returns
#' \item{N}{total number of observations}
#' \item{minpol}{lowest polynomial order considered for estimating bootstrapped confidence intervals}
#' \item{maxpol}{highest polynomial order considered for estimating bootstrapped confidence intervals}
#' \item{mainpol}{main polynomial order (the one with the lowest AMSE if not specified)}
#' \item{missings_bs}{number of unsuccessful bootstrap iterations}
#' \item{missings_jk}{number of unsuccessful jackknife iterations}
#' \item{amses}{AMSE value corresponding to each polynomial order}
#' \item{bca_ci}{BCa confidence intervals for each polynomial order pair}
#' \item{included}{list of the main polynomial orders and all overlapping polynomial orders}
#' \item{plot}{plot of the BCa confidence intervals}
#' 
#' @examples 
#' # Let y be the outcome variable, x the running variable, and t the treatment instrument:
#' 
#' # Estimation for sharp RD designs with default settings
#' rdpolboot(df$y, df$x)
#' 
#' # Estimation for fuzzy RD designs with default settings
#' rdpolboot(df$y, df$x, fuzzy = df$t)
#' 
#' # Estimation for sharp RD designs using groups and groupreps to speed up estimation of the acceleration factor for large data sets
#' rdpolboot(df$y, df$x, groups = 5, groupreps = 40)
#' 
#' # Estimation for sharp RD designs with different min and max polynomials
#' rdpolboot(df$y, df$x, minpol = 0, maxpol = 3)
#' 
#' # Estimation for sharp RD designs without the BCa CI plot
#' rdpolboot(df$y, df$x, plot = FALSE)
#' 
#' # Estimation for sharp RD designs with covariates and a cluster variable
#' rdpolboot(df$y, df$x, covs = covars, cluster = clustervar)
#' 
#' @export
rdpolboot <- function(y, x, c = 0, fuzzy = NULL, covs = NULL, kernel = "tri", 
                      deriv = NULL, cluster = NULL, scaleregul = 1, alpha = 0.05, mainpol = NULL,
                      plot = TRUE, groups = NULL, groupreps = 1, minpol = 1, maxpol = 4, reps = 15000){
  
  if (!is.null(covs)) covs <- as.matrix(covs)
  
  # sample results
  amses <- data.frame(pol=c(minpol:maxpol), amse=NA)
  
  counter <- 1
  for (pol in minpol:maxpol) {
    out <- rdrobust(y=y, x=x, p=pol, c=c, fuzzy=fuzzy, covs=covs, kernel=kernel, 
                    deriv=deriv, cluster=cluster, scaleregul=scaleregul, masspoints="off")
    amses$amse[counter] <- (out$Estimate[1,1]-out$Estimate[1,2])^2 + out$se[1]^2
    
    counter <- counter + 1
  }
  
  amses_orig <- amses
  if (is.null(mainpol)) mainpol <- (amses %>% filter(amse==min(amses$amse)))[[1]]
  amses %<>% mutate(polpair=paste0("p",mainpol,"p",pol), diff=amse[pol==mainpol]-amse) %>% filter(pol!=mainpol) %>% select(pol, polpair, diff)
  
  # bootstrap
  counter <- 1
  amses_bs <- data.frame(bsrep=rep(c(1:reps), each=(1+maxpol-minpol)),
                         pol=rep(c(minpol:maxpol), times=reps), 
                         amse=NA)
  
  for (brep in 1:reps) {
    bs_ids <- sample(length(y), replace=T)
    y_bs <- y[bs_ids]
    x_bs <- x[bs_ids]
    if (!is.null(fuzzy)) fuzzy_bs <- fuzzy[bs_ids] else fuzzy_bs <- NULL
    if (!is.null(cluster)) cluster_bs <- cluster[bs_ids] else cluster_bs <- NULL
    if (!is.null(covs)) covs_bs <- covs[bs_ids,] else covs_bs <- NULL
    
    for (pol in minpol:maxpol) {
      out <- try(rdrobust(y_bs, x_bs, p=pol, c=c, fuzzy=fuzzy_bs, covs=covs_bs, kernel=kernel, 
                          deriv=deriv, cluster=cluster_bs, scaleregul=scaleregul, masspoints="off"))
      if ("try-error" %in% class(out)) amses_bs$amse[counter] <- NA
      else amses_bs$amse[counter] <- (out$Estimate[1,1]-out$Estimate[1,2])^2 + out$se[1]^2
      
      Sys.sleep(0.1)
      cat("bootstrap repetition", brep, "of", reps, "\r") 
      flush.console()
      counter <- counter + 1
    }
  }
  
  amses_bs %<>% group_by(bsrep) %>% filter(!any(is.na(amse))) %>% ungroup()
  
  missings_bs <- reps-length(amses_bs$bsrep)/(1+maxpol-minpol)
  
  amses_bs %<>% mutate(polpair=paste0("p",mainpol,"p",pol), diff_bs=amse[pol==mainpol]-amse) %>% filter(pol!=mainpol) %>% select(bsrep, polpair, diff_bs)
  
  # jackknife
  if (is.null(groups)) groups <- length(y)
  
  amses_jk <- data.frame(grouprep=rep(c(1:groupreps), each=(groups*(1+maxpol-minpol))),
                         jkrep=rep(c(1:groups), each=(1+maxpol-minpol)), 
                         pol=rep(c(minpol:maxpol), times=(groups)), 
                         amse=NA)
  
  counter <- 1
  
  for (r in 1:groupreps) {
    
    groupsize <- ceiling(length(y)/groups)
    jk_groups <- rep(c(1:groups), each = groupsize)
    
    if (groups==length(y)) {
      for (jack in 1:groups) {
        y_jk <- y[jk_groups!=jack]
        x_jk <- x[jk_groups!=jack]
        if (!is.null(fuzzy)) fuzzy_jk <- fuzzy[jk_groups!=jack] else fuzzy_jk <- NULL
        if (!is.null(cluster)) cluster_jk <- cluster[jk_groups!=jack] else cluster_jk <- NULL
        if (!is.null(covs)) covs_jk <- covs[jk_groups!=jack,] else covs_jk <- NULL
        
        for (pol in minpol:maxpol) {
          out <- try(rdrobust(y_jk, x_jk, p=pol, c=c, fuzzy=fuzzy_jk, covs=covs_jk, kernel=kernel, 
                              deriv=deriv, cluster=cluster_jk, scaleregul=scaleregul, masspoints="off"))
          if ("try-error" %in% class(out)) amses_jk$amse[counter] <- NA
          else amses_jk$amse[counter] <- (out$Estimate[1,1]-out$Estimate[1,2])^2 + out$se[1]^2
          
          Sys.sleep(0.1)
          cat("jackknife repetition", jack, "of", length(y), "\r") 
          flush.console()
          counter <- counter + 1
        }
      }
    }
    else if (!is.null(groups)) {
      jk_ids <- sample(length(y), replace=F)
      for (jack in 1:groups) {
        y_jk <- y[jk_ids][jk_groups==jack]
        x_jk <- x[jk_ids][jk_groups==jack]
        if (!is.null(fuzzy)) fuzzy_jk <- fuzzy[jk_ids][jk_groups==jack] else fuzzy_jk <- NULL
        if (!is.null(cluster)) cluster_jk <- cluster[jk_ids][jk_groups==jack] else cluster_jk <- NULL
        if (!is.null(covs)) covs_jk <- covs[jk_ids,][jk_groups==jack,] else covs_jk <- NULL
        
        for (pol in minpol:maxpol) {
          out <- try(rdrobust(y_jk, x_jk, p=pol, c=c, fuzzy=fuzzy_jk, covs=covs_jk, kernel=kernel, 
                              deriv=deriv, cluster=cluster_jk, scaleregul=scaleregul, masspoints="off"))
          if ("try-error" %in% class(out)) amses_jk$amse[counter] <- NA
          else amses_jk$amse[counter] <- (out$Estimate[1,1]-out$Estimate[1,2])^2 + out$se[1]^2
          
          Sys.sleep(0.1)
          cat("jackknife repetition", counter, "of", (1+maxpol-minpol)*groupreps*groups, "\r") 
          flush.console()
          counter <- counter + 1
        }
      }
    }
  }
  
  amses_jk %<>% group_by(jkrep) %>% filter(!any(is.na(amse)))
  
  missings_jk <- groups*groupreps-length(amses_jk$jkrep)/(1+maxpol-minpol)
  
  amses_jk %<>% mutate(polpair=paste0("p",mainpol,"p",pol), diff_jk=amse[pol==mainpol]-amse) %>% filter(pol!=mainpol) %>% select(jkrep, polpair, diff_jk)
  
  # bias correction
  amses_bs <- left_join(amses_bs, amses %>% select(polpair, diff), by = c("polpair" = "polpair"))
  biascorr <- amses_bs %>% group_by(polpair) %>% summarise(z0=qnorm(sum(diff_bs<=diff)/reps))
  
  
  # acceleration
  amses_jk %<>% group_by(polpair) %>% mutate(meandiff_jk = mean(diff_jk))
  acceleration <- amses_jk %>% group_by(polpair) %>% summarise(atop = sum((meandiff_jk-diff_jk)^3),
                                                               abot = 6*(sum((meandiff_jk-diff_jk)^2))^(3/2),
                                                               a = atop/abot)
  
  
  # confidence intervals
  alpha <- alpha/2
  
  bca_ci <- left_join(biascorr, acceleration %>% select(polpair, a), by = c("polpair"="polpair"))
  
  bca_ci %<>% mutate(alpha_left=pnorm(z0+(z0 + qnorm(alpha))/(1-a*(z0 + qnorm(alpha)))),
                     alpha_right=pnorm(z0+(z0 + qnorm(1-alpha))/(1-a*(z0 + qnorm(1-alpha)))))
  
  output <- data.frame(polpair=amses$polpair, lower=NA, upper=NA)
  counter <- 1
  polpairs <- amses$polpair 
  
  for (polp in polpairs) {
    alpha_left <- as.numeric(bca_ci %>% filter(polpair==polp) %>% select(alpha_left))
    alpha_right <- as.numeric(bca_ci %>% filter(polpair==polp) %>% select(alpha_right))
    
    output$lower[counter] <- as.numeric(amses_bs %>% filter(polpair==polp) %>% summarise(lower=quantile(diff_bs, probs=alpha_left)))
    output$upper[counter] <- as.numeric(amses_bs %>% filter(polpair==polp) %>% summarise(upper=quantile(diff_bs, probs=alpha_right)))
    counter <- counter + 1
  }
  
  output %<>% mutate(overlap=lower<0&upper>0)
  output$diff <- amses$diff
  output$pol <- amses$pol
  included <- output$pol[output$overlap==1]
  
  if (plot==TRUE){
    ci_plot <- output %>% ggplot() +
      geom_errorbar(aes(x=as.factor(polpair), ymin=lower, ymax=upper), width=0.3) +
      geom_point(aes(x=as.factor(polpair), y=diff, col=as.factor(overlap)), size=3) +
      geom_hline(yintercept = 0) +
      coord_flip() +
      theme_bw() +
      labs(y = "AMSE Difference",
           x = "Difference Pair") +
      theme(legend.position = "none",
            text=element_text(size=17)) +
      scale_color_manual(values = c("FALSE"="black", "TRUE"="red")) +
      scale_y_continuous(labels = ~ format(.x, scientific = FALSE))
  }
  
  out <- list(N=length(y), minpol=minpol, maxpol=maxpol, mainpol=mainpol, amses=amses_orig, missings_bs=missings_bs, missings_jk=missings_jk, included=included, bca_ci=output, plot=ci_plot)
  return(out)
}
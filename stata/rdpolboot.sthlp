{smcl}
{* *! version 1.0 10JAN2023}{...}
{viewerjumpto "Syntax" "rdpolboot##syntax"}{...}
{viewerjumpto "Description" "rdpolboot##description"}{...}
{viewerjumpto "Options" "rdpolboot##options"}{...}
{viewerjumpto "Examples" "rdpolboot##examples"}{...}
{viewerjumpto "Stored results" "rdpolboot##stored_results"}{...}
{viewerjumpto "References" "rdpolboot##references"}{...}
{viewerjumpto "Author" "rdpolboot##author"}{...}

{title:Title}

{p 4 8}{cmd:rdpolboot} {hline 2} Estimation of Bootstrapped Confidence Intervals of the Asymptotic Mean Squared Error for Regression Disconinuity Designs.{p_end}

{marker syntax}{...}
{title:Syntax}

{p 4 15 2}{cmd:rdpolboot} {it:depvar} {it:runvar} {ifin} 
[{cmd:,} 
{cmd:minpol(}{it:#}{cmd:)}
{cmd:maxpol(}{it:#}{cmd:)} 
{cmd:accel_off}
{cmd:reps(}{it:#}{cmd:)} 
{cmd:c(}{it:#}{cmd:)} 
{cmd:fuzzy(}{it:fuzzyvar [sharpbw]}{cmd:)}
{cmd:deriv(}{it:#}{cmd:)}
{cmd:covs(}{it:covars}{cmd:)}
{cmd:kernel(}{it:kernelfn}{cmd:)}
{cmd:bwselect(}{it:bwmethod}{cmd:)}
{cmd:scaleregul(}{it:#}{cmd:)}
{cmd:vce(}{it:vcetype [vceopt1 vceopt2]}{cmd:)}]

{synoptset 28 tabbed}{...}

{marker options}{...}
{title:Options}

{dlgtab:Estimand}

{p 4 8}{cmd:c(}{it:#}{cmd:)} specifies the RD cutoff for {it:indepvar}.
Default is {cmd:c(0)}.{p_end}

{p 4 8}{cmd:fuzzy(}{it:fuzzyvar [sharpbw]}{cmd:)} specifies the treatment status variable used to implement fuzzy RD estimation (or Fuzzy Kink RD if {cmd:deriv(1)} is also specified).
Default is Sharp RD design and hence this option is not used.
If the option {it:sharpbw} is set, the fuzzy RD estimation is performed using a bandwidth selection procedure for the sharp RD model. This option is automatically selected if there is perfect compliance at either side of the threshold.
{p_end}

{p 4 8}{cmd:deriv(}{it:#}{cmd:)} specifies the order of the derivative of the regression functions to be estimated.
Default is {cmd:deriv(0)} (for Sharp RD, or for Fuzzy RD if {cmd:fuzzy(.)} is also specified). Setting {cmd:deriv(1)} results in estimation of a Kink RD design (up to scale), or Fuzzy Kink RD if {cmd:fuzzy(.)} is also specified.{p_end}

{dlgtab:Local Polynomial Regression}

{p 4 8}{cmd:minpol(}{it:#}{cmd:)} specifies the lowest polynomial order to consider for estimating bootstrapped confidence intervals.
Default is {cmd:minpol(1)}{p_end}

{p 4 8}{cmd:maxpol(}{it:#}{cmd:)} specifies the highest polynomial order to consider for estimating bootstrapped confidence intervals.
Default is {cmd:maxpol(4)}{p_end}

{p 4 8}{cmd:covs(}{it:covars}{cmd:)} specifies additional covariates to be used for estimation and inference.{p_end}

{p 4 8}{cmd:kernel(}{it:kernelfn}{cmd:)} specifies the kernel function used to construct the local-polynomial estimator(s). Options are: {opt tri:angular}, {opt epa:nechnikov}, and {opt uni:form}.
Default is {cmd:kernel(triangular)}.{p_end}

{p 4 8}{cmd:scaleregul(}{it:#}{cmd:)} specifies scaling factor for the regularization term added to the denominator of the bandwidth selectors. Setting {cmd:scaleregul(0)} removes the regularization term from the bandwidth selectors.
Default is {cmd:scaleregul(1)}.{p_end}

{dlgtab:Bootstrap Settings}

{p 4 8}{cmd:reps(}{it:#}{cmd:)} specifies the number of bootstrap repetitions.
Default is {cmd:reps(15000)}{p_end}

{p 4 8}{cmd:accel_off} if specified, {cmd:rdpolboot} skips estimation of the acceleration factor and reports BC confidence intervals instead of BCa confidence intervals. This saves considerable time in data sets with many observations.{p_end}

{dlgtab:Variance-Covariance Estimation}

{p 4 8}{cmd:vce(}{it:vcetype [vceopt1 vceopt2]}{cmd:)} specifies the procedure used to compute the variance-covariance matrix estimator.
Options are:{p_end}
{p 8 12}{cmd:vce(nn }{it:[nnmatch]}{cmd:)} for heteroskedasticity-robust nearest neighbor variance estimator with {it:nnmatch} indicating the minimum number of neighbors to be used.{p_end}
{p 8 12}{cmd:vce(hc0)} for heteroskedasticity-robust plug-in residuals variance estimator without weights.{p_end}
{p 8 12}{cmd:vce(hc1)} for heteroskedasticity-robust plug-in residuals variance estimator with {it:hc1} weights.{p_end}
{p 8 12}{cmd:vce(hc2)} for heteroskedasticity-robust plug-in residuals variance estimator with {it:hc2} weights.{p_end}
{p 8 12}{cmd:vce(hc3)} for heteroskedasticity-robust plug-in residuals variance estimator with {it:hc3} weights.{p_end}
{p 8 12}{cmd:vce(nncluster }{it:clustervar [nnmatch]}{cmd:)} for cluster-robust nearest neighbor variance estimation using with {it:clustervar} indicating the cluster ID variable and {it: nnmatch} matches indicating the minimum number of neighbors to be used.{p_end}
{p 8 12}{cmd:vce(cluster }{it:clustervar}{cmd:)} for cluster-robust plug-in residuals variance estimation with degrees-of-freedom weights and {it:clustervar} indicating the cluster ID variable.{p_end}
{p 8 12}Default is {cmd:vce(nn 3)}.{p_end}

    {hline}

{marker examples}{...}

{title:Generic Examples:}

{p 4 8}Let {cmd:Y} be the outcome variable and {cmd:x} the running variable:{p_end}

{p 4 8}MSE Estimation for local linear sharp RD estimator with uniform kernel and CCT bandwidths (Calonico, Cattaneo, Titiunik 2014a, 2014b){p_end}
{p 4 8}First estimate the CCT bandwidths using {cmd:altrdbwselect} included in the package{p_end}
{p 8 12}{cmd:. altrdbwselect Y x, c(0) deriv(0) p(1) q(2) kernel(uniform) bwselect(CCT)}{p_end}
{p 8 12}{cmd:. local bw_h=e(h_CCT)}{p_end}
{p 8 12}{cmd:. local bw_b=e(b_CCT)}{p_end}
{p 4 8}Then estimate the MSE by passing the CCT bandwidths as arguments{p_end}
{p 8 12}{cmd:. rdmse Y x, deriv(0) c(0) p(1) h(`bw_h') b(`bw_b') kernel(uniform)}{p_end}

{p 4 8}Estimate the MSE of the sharp local linear RD estimator with manual bandwidths{p_end}
{p 8 12}{cmd:. rdmse Y x, deriv(0) c(0) p(1) h(0.5) b(1.2) kernel(uniform)}{p_end}

{p 4 8}Estimate the MSE of the sharp local linear RK estimator{p_end}
{p 8 12}{cmd:. rdmse Y x, deriv(0) c(0) p(1) h(0.5) b(1.2) kernel(uniform)}{p_end}

{p 4 8}Estimate the MSEs of the left- and right- intercept estimators constructed with different polynomial orders and bandwidths on two sides of the threshold{p_end}
{p 8 12}{cmd:. rdmse Y x, c(0) deriv(0) twosided pl(1) pr(2) hl(0.5) hr(0.45) bl(1.2) br(1.1) kernel(uniform)}{p_end}  

{p 4 8}Let {cmd:T} be the treatment variable.{p_end}

{p 4 8}MSE Estimation for local linear fuzzy RD estimator with uniform kernel and "fuzzy CCT" bandwidths (Card, Lee, Pei, Weber 2015){p_end}
{p 4 8}First estimate the fuzzy CCT bandwidths using {cmd:altfrdbwselect} included in the package{p_end}
{p 8 12}{cmd:. altfrdbwselect Y x, c(0) fuzzy(T) deriv(0) p(1) q(2) kernel(uniform) bwselect(CCT)}{p_end}
{p 8 12}{cmd:. local fbw_h=e(h_F_CCT)}{p_end}
{p 8 12}{cmd:. local fbw_b=e(b_F_CCT)}{p_end}
{p 4 8}Then estimate the MSE by passing the "fuzzy CCT" bandwidths as arguments{p_end}
{p 8 12}{cmd:. rdmse Y x, c(0) fuzzy(T) deriv(0) p(1) h(`fbw_h') b(`fbw_b') kernel(uniform)}{p_end}

{p 4 8}Estimate the MSE of the fuzzy local linear RD estimator with manual bandwidths{p_end}
{p 8 12}{cmd:. rdmse Y x, c(0) fuzzy(T) deriv(0) p(1) h(0.5) b(1.2) kernel(uniform)}{p_end}

{p 4 8}Estimate the MSE of the fuzzy local linear RK estimator{p_end}
{p 8 12}{cmd:. rdmse Y x, c(0) fuzzy(T) deriv(1) p(1) h(0.5) b(1.2) kernel(uniform)}{p_end}

{marker stored_results}{...}
{title:Stored Results}

{p 4 8}{cmd:rdbwselect} stores the following in {cmd:e()}:

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Scalars}{p_end}
{synopt:{cmd:e(N)}}total number of observations{p_end}
{synopt:{cmd:e(minpol)}}lowest polynomial order considered for estimating bootstrapped confidence intervals{p_end}
{synopt:{cmd:e(maxpol)}}highest polynomial order considered for estimating bootstrapped confidence intervals{p_end}
{synopt:{cmd:e(lowestpol)}}polynomial order with the lowest AMSE (the base polynomial order).{p_end}

{p2col 5 20 24 2: Matrices}{p_end}
{synopt:{cmd:e(amses)}}AMSE value corresponding to each polynomial order.{p_end}

{p2col 5 20 24 2: Macros}{p_end}
{synopt:{cmd:e(included)}}list of all polynomial order to be included in the analysis according to the bootstrapped confidence intervals.{p_end}


{p 4 4}Since {cmd:rdmse_cct2014} only estimates the (asymptotic) MSE of the conventional estimator, it returns {cmd:e(amse_cl)} in the sharp case and {cmd:e(amse_F_cl)} in the fuzzy case.{p_end}

    {hline}

{marker references}{...}
{title:References}

{p 4 8}Calonico, S., M. D. Cattaneo, and R. Titiunik. 2014a. Robust Nonparametric Confidence Intervals for Regression Discontinuity Designs. {it:Econometrica} 82(6): 2295-2326.
{browse "https://onlinelibrary.wiley.com/doi/abs/10.3982/ECTA11757"}.

{p 4 8}Calonico, S., M. D. Cattaneo, and R. Titiunik. 2014b. Robust Data Driven Inference in the Regression Discontinuity Design. {it:Stata Journal} 14(4): 909-946. 
{browse "https://journals.sagepub.com/doi/abs/10.1177/1536867X1401400413"}.

{p 4 8}Card, D., D. S. Lee, Z. Pei, and A. Weber. 2015. Inference on Causal Effects in a Generalized Regression Kink Design. {it:Econometrica} 83(6): 2453-2483.
{browse "https://onlinelibrary.wiley.com/doi/abs/10.3982/ECTA11224"}.

{p 4 8}Calonico, S., M. D. Cattaneo, M. H. Farrell, and R. Titiunik. 2017. {cmd:rdrobust}: Software for Regression-Discontinuity Designs. {it:Stata Journal} 17(2): 372-404. 
{browse "https://journals.sagepub.com/doi/abs/10.1177/1536867X1701700208"}.

{p 4 8}Card, D., D. S. Lee, Z. Pei, and A. Weber. 2018. Princeton University Industrial Relations Section Working Paper #622.
{browse "https://irs.princeton.edu/publications/working-papers/local-polynomial-order-regression-discontinuity-designs"}.

{p 4 8}Calonico, S., M. D. Cattaneo, M. H. Farrell, and R. Titiunik. 2019. Regression Discontinuity Designs Using Covariates. {it:Review of Economics and Statistics} 101(3): 442-451.
{browse "https://www.mitpressjournals.org/doi/abs/10.1162/rest_a_00760"}.

{p 4 8}Card, D., D. S. Lee, Z. Pei, and A. Weber. 2020. NBER Working Paper #622.
{browse "https://www.nber.org/papers/w27424"}.

{marker author}{...}
{title:Author}

{p 4 8}Melle Albada, Vienna University of Economics and Business.
{browse "mailto:melle.albada@wu.ac.at":melle.albada@wu.ac.at}.




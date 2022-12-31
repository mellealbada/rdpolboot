{smcl}
{* *! version 1.0 01JAN2023}{...}
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
{cmd:scaleregul(}{it:#}{cmd:)}
{cmd:vce(}{it:vcetype [vceopt1 vceopt2]}{cmd:)}]

{synoptset 28 tabbed}{...}

{marker description}{...}
{title:Description}

{p 4 8}{cmd:rdpolboot} estimates bootstrapped confidence intervals around the asymptotic mean squared error (AMSE) of different polynomial orders in a regression discontinuity design. These compare the fit of different polynomial orders and can be used to choose between them if the estimate is senstive to the polynomial order choice.{p_end}

{p 8 8}The package builds upon {cmd:rdbwselect}, the CCT bandwidth selector from Calonico, Cattaneo and Titiunik (2014a, 2014b), to calculate the MSE-optimal bandwidth for each polynomial order. Second, it uses {cmd:rdmse} from Pei, Lee, Card and Weber (2021) to estimate the AMSEs for each bootstrapped sample.

{marker options}{...}
{title:Options}

{dlgtab:Estimand}

{p 4 8}{cmd:c(}{it:#}{cmd:)} specifies the RD cutoff for {it:indepvar}.
Default is {cmd:c(0)}.{p_end}

{p 4 8}{cmd:fuzzy(}{it:fuzzyvar [sharpbw]}{cmd:)} specifies the treatment status variable used to implement fuzzy RD estimation (or Fuzzy Kink RD if {cmd:deriv(1)} is also specified).
Default is Sharp RD design and hence this option is not used.
If the option {it:sharpbw} is set, the fuzzy AMSE estimation is performed using a bandwidth selection procedure for the sharp RD model. This option is automatically selected if there is perfect compliance at either side of the threshold.
{p_end}

{p 4 8}{cmd:deriv(}{it:#}{cmd:)} specifies the order of the derivative of the regression functions to be estimated.
Default is {cmd:deriv(0)} (for Sharp RD, or for Fuzzy RD if {cmd:fuzzy(.)} is also specified). Setting {cmd:deriv(1)} results in estimation of a Kink RD design (up to scale), or Fuzzy Kink RD if {cmd:fuzzy(.)} is also specified.{p_end}

{dlgtab:Bandwidth Estimation Settings}

{p 4 8}{cmd:minpol(}{it:#}{cmd:)} specifies the lowest polynomial order to consider for estimating bootstrapped confidence intervals.
Default is {cmd:minpol(1)}{p_end}

{p 4 8}{cmd:maxpol(}{it:#}{cmd:)} specifies the highest polynomial order to consider for estimating bootstrapped confidence intervals.
Default is {cmd:maxpol(4)}{p_end}

{p 4 8}{cmd:covs(}{it:covars}{cmd:)} specifies additional covariates to be used for estimation.{p_end}

{p 4 8}{cmd:kernel(}{it:kernelfn}{cmd:)} specifies the kernel function used to estimate the MSE-optimal bandwidth and AMSE. Options are: {opt tri:angular} and {opt uni:form}.
Default is {cmd:kernel(triangular)}.{p_end}

{p 4 8}{cmd:scaleregul(}{it:#}{cmd:)} specifies scaling factor for the regularization term added to the denominator of the bandwidth selectors. Setting {cmd:scaleregul(0)} removes the regularization term from the bandwidth selectors.
Default is {cmd:scaleregul(1)}.{p_end}

{dlgtab:Bootstrap Settings}

{p 4 8}{cmd:reps(}{it:#}{cmd:)} specifies the number of bootstrap repetitions.
Default is {cmd:reps(15000)}{p_end}

{p 4 8}{cmd:accel_off} if specified, {cmd:rdpolboot} skips estimation of the acceleration factor and reports BC confidence intervals instead of BCa confidence intervals. This saves considerable time in data sets with many observations.{p_end}

{dlgtab:Variance-Covariance Estimation}

{p 4 8}{cmd:vce(}{it:vcetype [vceopt1 vceopt2]}{cmd:)} specifies the procedure used to compute the variance-covariance matrix estimator for the MSE-optimal bandwidth.
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

{p 4 8}Let {cmd:y} be the outcome variable, {cmd:x} the running variable, and {cmd:t} the treatment instrument:{p_end}

{p 8 8}Estimation for sharp RD designs with default settings{p_end}
{p 12 12}{cmd:. rdpolboot y x}{p_end}

{p 8 8}Estimation for fuzzy RD designs with default settings{p_end}
{p 12 12}{cmd:. rdpolboot y x, fuzzy(t)}{p_end}

{p 8 8}Estimation for sharp RD designs with different min and max polynomials{p_end}
{p 12 12}{cmd:. rdpolboot y x, minpol(0) maxpol(3)}{p_end}

{p 8 8}Estimation for sharp RD designs without the acceleration factor for large data sets{p_end}
{p 12 12}{cmd:. rdpolboot y x, accel_off}{p_end}

{p 8 8}Estimation for sharp RD designs with the BCa CI plot{p_end}
{p 12 12}{cmd:. rdpolboot y x, plot}{p_end}

{p 8 8}Estimation for sharp RD designs with covariates and a cluster variable{p_end}
{p 12 12}{cmd:. rdpolboot y x, covs({it:covars}) vce(cluster {it:clustervar}}{p_end}

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

    {hline}

{marker references}{...}
{title:References}

{p 4 8}Calonico, S., M. D. Cattaneo, and R. Titiunik. 2014a. Robust Nonparametric Confidence Intervals for Regression Discontinuity Designs. {it:Econometrica} 82(6): 2295-2326.
{browse "https://onlinelibrary.wiley.com/doi/abs/10.3982/ECTA11757"}.

{p 4 8}Calonico, S., M. D. Cattaneo, and R. Titiunik. 2014b. Robust Data Driven Inference in the Regression Discontinuity Design. {it:Stata Journal} 14(4): 909-946. 
{browse "https://journals.sagepub.com/doi/abs/10.1177/1536867X1401400413"}.

{p 4 8}Pei, Z., Lee, D. S., Card, D., and Weber, A. 2021. Local Polynomial Order in Regression Discontinuity Designs. {it:Journal of Business and Economic Statistics}: 1259-1267.
{browse "https://www.tandfonline.com/doi/full/10.1080/07350015.2021.1920961"}.

{marker author}{...}
{title:Author}

{p 4 8}Melle Albada, Vienna University of Economics and Business.
{browse "mailto:melle.albada@wu.ac.at":melle.albada@wu.ac.at}.




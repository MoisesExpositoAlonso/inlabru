#' Bin checking
#'
#' @aliases bincount
#' @export
#' @param result A result object from a \link{bru} or \link{lgcp} call
#' @param predictor A formula describing what and where to predict. See \link{predict.lgcp} for details.
#' @param observations A vector of observed values
#' @param breaks A vector of bin boundaries
#' @param nint Number of integration points per bin
#' @param ... arguments passed on to \link{predict}
#' @return An \link{inla} object


bincount = function(result, predictor, observations, breaks, nint = 20, ...) {
  # Quantiles to comoute
  qtls = c(0.025, 0.5, 0.975)
  
  # Filter out observations outside bins
  observations = observations[(observations>=min(breaks)) & (observations<=max(breaks))]
  
  # Number of ...
  nobs = length(observations) # observations
  nbins = length(breaks) - 1 # bins
  
  # Mid points of bins
  mid = breaks[1:(length(breaks)-1)] + diff(breaks)/2
  
  # Create integration points
  ip = int.quadrature(breaks[1:(length(breaks)-1)], breaks[2:(length(breaks))], scheme = "trapezoid", n = nint)
  points = data.frame(tmp = as.vector(ip$ips))
  colnames(points) = all.vars(update.formula(predictor, ~.0))
  points$bin = rep(1:nbins,each = nint)
  
  # Predict
  prd = predict(result, predictor = predictor, points = points, ...)
  
  # Integrate per bin
  smp = attr(prd,"samples")
  smp = ip$wl * smp
  qq = aggregate(smp, by = list(rep(1:nbins,each = nint)), FUN = sum, drop = TRUE)[,2:(ncol(smp)+1)]

  # Normalize bin probabilities
  for (s in 1:ncol(smp)) { qq[,s] = qq[,s]/sum(qq[,s]) }
  
  # For each bin calculate predictive interval
  pint = list()
  for (k in 1:nbins) {
    xx = 0:nobs
    cdff = function (p) pbinom(xx, size = nobs, prob = p)
    zz = apply(qq[k,,drop=FALSE], MARGIN = 2, cdff)
    zz = apply(zz, MARGIN = 1, mean)
    pint[[k]] = approx(zz, xx, xout = qtls, rule = 2)$y
  }
  pint = data.frame(do.call(rbind, pint))
  colnames(pint) = c("lq","mq","uq")
  
  # Append more information
  pint = cbind(data.frame(
    mid = mid, 
    width = diff(breaks),
    counts = hist(observations, breaks = breaks, plot = FALSE)$counts),
    pint)
  pint$inside = ( pint$counts >= pint$lq ) & ( pint$counts <= pint$uq ) 
  
  ggp = ggplot() + geom_crossbar(data = pint, mapping = aes(x=mid,y=mq,ymin=lq,ymax=uq,fill=inside,color=inside), show.legend=FALSE) +
    geom_point(data = pint, mapping = aes(x=mid,y=mq), shape = 95, size = 3, color = "blue") +
    geom_point(data = pint, mapping = aes(x=mid,y=counts), shape = 20, size = 2) +
    xlab(all.vars(update.formula(predictor, ~.0))) +
    ylab("count")
  
  attr(pint, "ggp") = ggp
  
  # Return
  pint
}



#' Variance and correlations measures for prediction components
#'
#' @aliases devel.cvmeasure
#' @export
#' @param join A joint prediction of two latent components
#' @param prediction1 A prediction of first component
#' @param prediction2 A prediction of the first component
#' @return Variance and correlations measures

devel.cvmeasure = function(joint, prediction1, prediction2, integrate = list()) {

  #' Covariance
  joint$cov = (joint$var - prediction1$var - prediction2$var)/2
  
  #' Correlation
  corr = function(joint, a, b) { ((joint - a - b) / (2 * sqrt(a * b)))}
  joint$cor = corr(joint$var, prediction1$var, prediction2$var)
  
  if ( "coordinates" %in% integrate ){
    mesh = attributes(joint)[["misc"]]$mesh
    weights = diag(as.matrix(inla.mesh.fem(mesh)$c0))
    weights = weights/sum(weights) 
    vj = sum(joint$var * weights)
    v1 = sum(prediction1$var * weights)
    v2 = sum(prediction2$var * weights)
    cr = corr(vj, v1, v2)
    ret = data.frame(var.joint = vj, var1 = v1, var2 = v2, cor = cr)
    
  } else {
    tmp = attributes(joint)
    ret = joint[,c("cov","cor")]
    ret$var.joint = joint$var
    ret$var1 = prediction1$var
    ret$var2 = prediction2$var
    attr(ret, "misc") = tmp[["misc"]]
    attr(ret, "type") = tmp[["type"]]
  }
  
  return(ret)
}



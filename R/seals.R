#' @name seals
#' @title Seal pups
#' @docType data
#' @description This is a single transect of an aereal photo seal pup survey in the Greenland Sea
#' 
#' @usage data(seals)
#' 
#' @format The data contain these objects:
#'  \describe{
#'    \item{\code{points}:}{ A \code{SpatialPointsDataFrame} Center locations of the photos}
#'    \item{\code{mesh}:}{ An \code{inla.mesh} enclosing the plane's transect}
#'    \item{\code{ice.data}:}{ An \code{SpatialPointsDataFrame} with MODIS ice concentration estimates}
#'    \item{\code{ice.cv}:}{ An \code{covdata} object with interpolated ice coverage data}
#'  }
#' @source 
#' Martin Jullum <\email{Martin.Jullum@@nr.no}>
#' 
#' @references 
#' Oigard, T. A. (2013) From pup production to quotas: current status of harp seals in the Greenland Sea.
#' ICES Journal of Marine Science, doi.10.1093/icesjms/fst155.
#' 
#' Oigard, T. A. (2014) Current status of hooded seals in the Greenland Sea. Victims of climate change and predation?,
#' Biological Conservation , 2014, 172, 29 - 36.
#' 
#' @examples
#'  data(seals)
#'  ggplot() + gg(seals$mesh) + gg(seals$points)
#'  
NULL
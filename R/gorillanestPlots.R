#' @name gorillanestPlots
#' @title Gorilla Nesting Sites in selected plots.
#' @docType data
#' @description This a subset of the \code{gorillas} dataset from the package \code{spatstat}, reformatted
#' as point process data for use with \code{inlabru}. The data have also been thinned by keeping
#' only nests within a set of 15 plots (see below).
#' 
#' @usage data(gorillanestPlots)
#' 
#' @format The data contain these objects:
#'  \describe{
#'    \item{\code{gdets}:}{ A \code{SpatialPointsDataFrame} object containing the locations of 
#'    the \emph{detected} gorilla nests.}
#'    \item{\code{gnestboundary}:}{ An \code{SpatialPolygonsDataFrame} object defining the boundary
#'    of the regoin that was searched for the nests.}
#'    \item{\code{gnestmesh}:}{ An \code{inla.mesh} object containing a mesh that can be used
#'    with function \code{lgcp} to fit a LGCP to the nest data.}
#'    \item{\code{plots}:}{ A \code{SpatialPolygonsDataFrame} object containing the 15 polygons
#'    that were searched for nests.}
#'  }
#' @source 
#' Library \code{spatstat}.
#' 
#' @references 
#' Funwi-Gabga, N. (2008) A pastoralist survey and fire impact assessment in the Kagwene Gorilla 
#' Sanctuary, Cameroon. M.Sc. thesis, Geology and Environmental Science, University of Buea, 
#' Cameroon.
#' 
#' Funwi-Gabga, N. and Mateu, J. (2012) Understanding the nesting spatial behaviour of gorillas 
#' in the Kagwene Sanctuary, Cameroon. Stochastic Environmental Research and Risk Assessment 
#' 26 (6), 793–811.
#' 
#' @examples
#'  data(gorillanestPlots)
#'  ggplot() +gg(gnestboundary) + gg(gdets,pch="+",cex=2) +gg(plots) 
#'  
NULL
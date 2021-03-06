% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/gorillanests.R
\docType{data}
\name{gorillanests}
\alias{gorillanests}
\title{Gorilla Nesting Sites.}
\format{The data are a list that contains these elements:
 \describe{
   \item{\code{gnests}:}{ A \code{SpatialPointsDataFrame} object containing the locations of 
   the gorilla nests.}
   \item{\code{gnestboundary}:}{ An \code{SpatialPolygonsDataFrame} object defining the boundary
   of the region that was searched for the nests.}
   \item{\code{gnestmesh}:}{ An \code{inla.mesh} object containing a mesh that can be used
   with function \code{lgcp} to fit a LGCP to the nest data.}
   \item{\code{gcov}:}{ A list of raster objects, one for each of these spatial covariates:
    \describe{
      \item{\code{aspect}}{ Compass direction of the terrain slope. Categorical, with levels 
      N, NE, E, SE, S, SW, W and NW, which are coded as integers 1 to 8.}
      \item{\code{elevation}}{ Digital elevation of terrain, in metres.}
      \item{\code{heat}}{ Heat Load Index at each point on the surface (Beer's aspect), 
      discretised. Categorical with values Warmest (Beer's aspect between 0 and 0.999), 
      Moderate (Beer's aspect between 1 and 1.999), Coolest (Beer's aspect equals 2). These are
      coded as integers 1, 2 and 3, in that order.}
      \item{\code{slopangle}}{ Terrain slope, in degrees.}
      \item{\code{slopetype}}{ Type of slope. Categorical, with values Valley, Toe (toe slope), 
      Flat, Midslope, Upper and Ridge. These are coded as integers 1 to 6.}
      \item{\code{vegetation}}{ Vegetation type: a categorical variable with 6 levels coded as
      integers 1 to 6 (in order of increasing expected habitat suitability)}
      \item{\code{waterdist}}{ Euclidean distance from nearest water body, in metres.}
    }
   }
   \item{\code{gnestsamples}}{ A list with elements \code{sample_9x9}, \code{sample_5x5}, 
   \code{sample_9x9_60pc}, \code{sample_5x5_60pc}, containing plot samples of gorilla nests, 
   sampling 9x9 and 5x5 plots over the region, with 100\% coverage and with 60\% coverage. Each 
   element of the list has these components:
   \describe{
     \item{\code{counts}}{ A data frame with elements \code{x}, \code{y}, \code{count}, 
     \code{exposure}, being the x- and y-coordinates of the centre of each plot, the count in each 
     plot and the area of each plot.}
     \item{\code{plots}}{ A \code{SpatialPolygonsDataFrame} defining the individual plot boundaries.}
     \item{\code{dets}}{ A \code{SpatialPointsDataFrame} giving the locations of each detected nest.}
   }
   }
 }}
\source{
Library \code{spatstat}.
}
\usage{
data(gorillanests)
}
\description{
This the \code{gorillas} dataset from the package \code{spatstat}, reformatted
as point process data for use with \code{inlabru}.
}
\examples{
 data(gorillanests) # get the data
 # extract all the objects, for convenience:
 gnests=gorillanests$gnests
 gnestmesh=gorillanests$gnestmesh
 gnestboundary=gorillanests$gnestboundary
 gcov=gorillanests$gcov
 gnestsamples=gorillanests$gnestsamples
 
 # plot all the nests, mesh and boundary
 ggplot()+gg(gnestmesh,lwd=0.1)+gg(gnestboundary)+gg(gnests,pch="+",cex=2)
 
 #' plot the raster file with elevations
 plot(gcov$elevation) 
 # inlabru needs a SpatialPointsDataFrame, so convert raster to SpatialPointsDataFrame
 gelevation = as(gcov$elevation,"SpatialPointsDataFrame")
 # now create an elevation covariate for inlabru
 elevn = covariate(gelevation, predictor = layer, mesh = gnestmesh) # this takes a while
 # and plot it
 plot(elevn) 
 plot(elevn) +gg(gnests,cex=0.5) + gg(gnestboundary) # with the nests and boundary

 # plot the raster file with vegetations
 plot(gcov$vegetation) 
 # inlabru needs a SpatialPointsDataFrame, so convert raster to SpatialPointsDataFrame
 gvegetation = as(gcov$vegetation,"SpatialPointsDataFrame")
 # now create an vegetation covariate for inlabru
 vegn = covariate(gvegetation, predictor = layer, mesh = gnestmesh) # this takes a while
 # and plot it
 plot(vegn) 
 plot(vegn) +gg(gnests,cex=0.5) + gg(gnestboundary) # with the nests and boundary
 
 # Plot the plot sample data:
 sample = gnestsamples$sample_9x9
 ggplot() +gg(gnestboundary) +gg(sample$plots) +  gg(sample$dets,pch="+",cex=4) +
   geom_text(aes(label=sample$counts$count, x=sample$counts$x, y=sample$counts$y)) + coord_fixed()
 sample = gnestsamples$sample_5x5
 ggplot() +gg(gnestboundary) +gg(sample$plots) +  gg(sample$dets,pch="+",cex=4) +
   geom_text(aes(label=sample$counts$count, x=sample$counts$x, y=sample$counts$y)) + coord_fixed()
 sample = gnestsamples$sample_9x9_60pc
 ggplot() +gg(gnestboundary) +gg(sample$plots) +  gg(sample$dets,pch="+",cex=4) +
   geom_text(aes(label=sample$counts$count, x=sample$counts$x, y=sample$counts$y)) + coord_fixed()
 sample = gnestsamples$sample_5x5_60pc
 ggplot() +gg(gnestboundary) +gg(sample$plots) +  gg(sample$dets,pch="+",cex=4) +
   geom_text(aes(label=sample$counts$count, x=sample$counts$x, y=sample$counts$y)) + coord_fixed()
   
}
\references{
Funwi-Gabga, N. (2008) A pastoralist survey and fire impact assessment in the Kagwene Gorilla 
Sanctuary, Cameroon. M.Sc. thesis, Geology and Environmental Science, University of Buea, 
Cameroon.

Funwi-Gabga, N. and Mateu, J. (2012) Understanding the nesting spatial behaviour of gorillas 
in the Kagwene Sanctuary, Cameroon. Stochastic Environmental Research and Risk Assessment 
26 (6), 793–811.
}


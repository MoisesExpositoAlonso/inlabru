
#' Integration points for log Gaussian Cox process models using INLA
#' 
#' prerequisits:
#' 
#' - List of integration dimension names, extend and quadrature 
#' - Samplers: These may live in a subset of the dimensions, usually space and time 
#'             ("Where and wehen did a have a look at the point process")
#' - Actually this is a simplified view. Samplers should have start and end time !
#' 
#' Procedure:
#' - Select integration strategy by type of samplers: 
#'       1) SpatialPointsDataFrame: Assume these are already integration points
#'       2) SpatialLinesDataFrame: Use simplified integration along line with (width provided by samplers)
#'       3) SpatialPolygonDataFrame: Use full integration over polygons
#'
#' - Create integration points from samplers. Do NOT perform simplification projection here!
#' - Simplify integration points. 
#'   1) Group by non-mesh dimensions, e.g. time, weather
#'   2) For each group simplify with respect to mesh-dimensions, e.g. space
#'   3) Merge
#'   
#'   Dependencies (iDistance):
#'   int.points(), int.polygon(), int.1d(), int.expand(), recurse.rbind()
#'
#' @aliases ipoints
#' @export
#' @param samplers A Spatial[Points/Lines/Polygons]DataFrame objects
#' @param points A SpatialPoints[DataFrame] object
#' @param config An integration configuration. See \link{iconfig}
#' @return Integration points

ipoints = function(samplers, config) {
  
  # First step: Figure out which marks are already included in the samplers (e.g. time)
  # For each of the levels of these marks the integration points will be computed independently
  pregroup = setdiff(colnames(samplers), "weight")
  postgroup = setdiff(names(config), c(pregroup, "coordinates"))
  
  # By default we assume we are handling a Spatial* object
  spatial = TRUE
  
  
  
  # If samplers is a data frame assume these are integration points with a weight column attached
  if ( is.data.frame(samplers) ) {
    if (!("weight" %in% names(samplers))) { 
      warning("The integration points provided have no weight column. Setting weights to 1.")
      samplers$weight = 1
    }
    stop("Not implemented")
  }
  
  # If a samplers is a SpatialPointsDataFrame we assume these are already integration points with a weight column attached
  else if ( class(samplers) == "SpatialPointsDataFrame" ){
    if (!("weight" %in% names(samplers))) { 
      warning("The integration points provided have no weight column. Setting weights to 1.")
      samplers$weight = 1
    }
    
    ips = samplers
  } 
  else if ( inherits(samplers, "SpatialLines") || inherits(samplers, "SpatialLinesDataFrame") ){
    
    # If SpatialLines are provided convert into SpatialLinesDataFrame and attach weight = 1
    if ( class(samplers)[1] == "SpatialLines" ) { 
      samplers = SpatialLinesDataFrame(samplers, data = data.frame(weight = rep(1, length(samplers)))) 
    }
    
    # Set weights to 1 if not provided
    if (!("weight" %in% names(samplers))) { 
      warning("The integration points provided have no weight column. Setting weights to 1.")
      samplers$weight = 1
    }
    
    # Store coordinate names
    cnames = coordnames(samplers)

    ips = int.points(samplers,
                     on = "segment",
                     line.split = TRUE,
                     mesh = config[["coordinates"]]$mesh,
                     mesh.split = FALSE,
                     mesh.coords = coordnames(samplers),
                     geometry = "euc",
                     length.scheme = "gaussian",
                     n.length = 1,
                     distance.scheme = "equidistant",
                     n.distance = 1,
                     distance.truncation = 1/2,
                     fake.distance = TRUE,
                     projection = NULL,
                     group = pregroup,
                     filter.zero.length = TRUE)
    
    ips$distance = NULL
    ips$weight = ips$weight * samplers$weight[ips$idx]
    ips$idx = NULL
    ips = SpatialPointsDataFrame(ips[,c(1,2)], data = ips[,3:ncol(ips),drop=FALSE])
    
  } else if ( inherits(samplers, "SpatialPolygons") ){
    
    # If SpatialPolygons are provided convert into SpatialPolygonsDataFrame and attach weight = 1
    if ( class(samplers)[1] == "SpatialPolygons" ) { 
      samplers = SpatialPolygonsDataFrame(samplers, data = data.frame(weight = rep(1, length(samplers)))) 
    }
    
    # Store coordinate names
    cnames = coordnames(samplers)
    
    
    polyloc = do.call(rbind, lapply(1:length(samplers), 
                                    function(k) cbind(
                                      x = rev(coordinates(samplers@polygons[[k]]@Polygons[[1]])[,1]),
                                      y = rev(coordinates(samplers@polygons[[k]]@Polygons[[1]])[,2]),
                                      group = k)))
    ips = int.polygon(config[["coordinates"]]$mesh, loc = polyloc[,1:2], group = polyloc[,3])
    df = data.frame(samplers@data[ips$group, pregroup, drop = FALSE], weight = ips[,"weight"])
    ips = SpatialPointsDataFrame(ips[,c("x","y")],data = df)
    
  } else if ( is.null(samplers) ){
    if ( "coordinates" %in% names(config) ) {
      ips = SpatialPointsDataFrame(config[["coordinates"]]$mesh$loc[,c(1,2)], 
                                   data = data.frame(weight = diag(as.matrix(inla.mesh.fem(config[["coordinates"]]$mesh)$c0))))
      coordnames(ips) = config[["coordinates"]]$cnames
      cnames = coordnames(ips)
    } else {
      ips = NULL
      spatial = FALSE
    }
  } else {
    stop("Unknown format of integration data")
  }
  
  
  #
  # Reduce number of integration points by projection onto mesh vertices
  # 
  
  all.groups = intersect(names(ips), c(postgroup,pregroup))
  if ("coordinates" %in% names(config)) {
    coords = coordinates(ips)
    cnames = colnames(coords)
    df = cbind(coords, ips@data)
    
    if ( length(all.groups) > 0 ) { # Apply projection for each group independently
      fn = function(x) { 
        pr =  project.weights(x, config[["coordinates"]]$mesh, mesh.coords = cnames)
        cbind(pr, x[rep(1, nrow(pr)),all.groups, drop = FALSE])
      }
      ips = recurse.rbind(fun = fn, df, cols = all.groups)
      ips = SpatialPointsDataFrame(ips[,cnames],data = ips[,c(postgroup, pregroup, "weight")])
    } else { # No groups, simply project everything
      ips = project.weights(df, config[["coordinates"]]$mesh, mesh.coords = cnames)
      ips = SpatialPointsDataFrame(ips[,cnames],data = data.frame(weight = ips[,"weight"]))
    }
  }
  
  
  #
  # Expand the integration points over postgroup dimensions
  #
  
  for ( k in seq_len(length(postgroup)) ){
    gname = postgroup[[k]]
    grp.cfg = config[[gname]]
    li = list() ; li[[gname]] = list(sp = grp.cfg$sp, 
                                     ep = grp.cfg$ep, 
                                     scheme = grp.cfg$scheme, 
                                     n = grp.cfg$n.points,
                                     geometry = "euc")
    
    if ( is.null(ips) ) {
      ips = do.call(int.1d, c(list(coords = gname), li[[gname]]))
    } else {
      ips = do.call(int.expand, c(list(as.data.frame(ips)), li))
      if ( spatial ) {
        ips = SpatialPointsDataFrame(ips[,cnames],data = ips[,intersect(c(postgroup, pregroup, "weight"), colnames(ips)) ])
      }
    }
  }
  

  
  if (spatial) { proj4string(ips) = CRS(config[["coordinates"]]$p4s) }
  ips
}


#' Integration point configuration generator
#'   
#'
#' @aliases iconfig
#' @export
#' @param samplers A Spatial[Points/Lines/Polygons]DataFrame objects
#' @param points A SpatialPoints[DataFrame] object
#' @param model A \link{model}
#' @param y Left hand side of a LGCP formula. Determines the integration dimensions. Currently in use but soon to be deprecated
#' @return An integration configuration

iconfig = function(samplers, points, model, dim.names = NULL, mesh = NULL) {
  
  # Obtain dimensions to integrate over. 
  # These are provided as the left hand side of model$formula
  if ( is.null(dim.names) ) { dim.names = model$dim.names }
  
  # Default mesh for spatial integration:
  meshes = lapply(effect(model), function(e) e$mesh)
  names(meshes) = elabels(model)
  meshes = meshes[!unlist(lapply(meshes, is.null))]
  issp = as.vector(unlist(lapply(meshes, function(m) m$manifold == "R2")))
  if (!is.null(issp) & any(issp)) { 
    spmesh = meshes[[which(issp)[[1]]]] } 
  else { spmesh = mesh }
  
  # Function that maps each dimension name to a setup
  ret = make.setup = function(nm) {
    ret = list()
    
    # Set the name of the coordinate system
    ret$name = nm
    ret$mesh = NULL
    ret$project = FALSE
    
    # Create a function to fetch coordinates. 
    # "coordinates" is a special case for which we extract an integration mesh from the model
    if ( nm == "coordinates" ) {
      ret$get.coord = get0(nm)
      ret$n.coord = ncol(ret$get.coord(points))
      # Use the first spatial mesh that we find
      ret$mesh = spmesh
      ret$class = "matrix"  
      ret$project = TRUE
      ret$p4s = proj4string(points)
    } else {
      # Spatial* object or data.frame?
      if ( is.data.frame(points) ) { ret$get.coord = function(sp) { sp[,nm, drop = FALSE] }} 
      else { ret$get.coord = function(sp) { sp@data[,nm, drop = FALSE] } }
      ret$n.coord = 1
      ret$class = class(ret$get.coord(points)[,nm])
    }
    
    # If there is a mesh in the model that has the same name as the dimension
    # use the mesh knots/vertices as integration points. Otherwise use some
    # standard setting depending on the class of the dimension.
    
    if ( nm %in% names(meshes) ) {
      if ( meshes[[nm]]$manifold == "R1" ) {
        # The mesh is 1-dimensional. 
        # By default a two-point Gaussian quadrature is used for each interval between the mesh knots.
        # This intergration is exact for poylnomials of second degree. 
        ret$mesh = meshes[[nm]]
        ret$min = min(ret$mesh$loc)
        ret$max = max(ret$mesh$loc)
        ret$cnames = colnames(ret$get.coord(points))
        ret$scheme = "gaussian"
        ret$sp = ret$mesh$loc[1:(length(ret$mesh$loc)-1)]
        ret$ep = ret$mesh$loc[2:length(ret$mesh$loc)] 
        ret$n.points = 2
      } else { 
        stop( "not implemented: 2d mesh auto-integration") 
      }
    } else {
      # If the dimension is defined via the formula extract the respective information.
      # If not, extract information from the data
      if ( nm %in% names(environment(model$formula)) ) {
        dim.def = environment(model$formula)[[nm]]
        ret$min = min(dim.def)
        ret$max = max(dim.def)
        ret$n.points = length(dim.def)
      } else {
        ret$min = apply(ret$get.coord(points), MARGIN = 2, min)
        ret$max = apply(ret$get.coord(points), MARGIN = 2, max)
      }
      
      ret$cnames = colnames(ret$get.coord(points))
      
      if ( ret$class == "integer" ) {
        ret$scheme = "fixed"
        ret$sp = ret$min:ret$max
        ret$ep = NULL
        if (is.null(ret$n.points)) { ret$n.points = length(ret$sp) }
      } else if ( ret$class == "factor" ) {
        ret$scheme = "fixed"
        stop("Not implemented.")
      } else { 
        ret$scheme = "trapezoid"
        ret$sp = ret$min
        ret$ep = ret$max
        if (is.null(ret$n.points)) { ret$n.points = 20 }
      }      
    }
    ret
  }

  # Create configurations
  ret = lapply(dim.names, make.setup)
  names(ret) = dim.names
  ret
}


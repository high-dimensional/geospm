#!/usr/local/bin/Rscript

#install.packages(c('argparser', 'R.matlab', 'sp', 'gstat'), repos="http://cran.r-project.org")

library(argparser, quietly=TRUE)
library(sp, quietly=TRUE)
library(gstat, quietly=TRUE)
library(R.matlab, quietly=TRUE)

NAME <- "cokrige.r"
DESCRIPTION <- "Cokriging of a csv dataset, where a header row specifies the first column as x and the second as y followed by one or more variables of interest."

run <- function(records_path, output_directory, random_seed, x, y, width, height, max_distance, variogram_model, add_nugget, variograms_only) {
  
  if( is.na(random_seed) ) {
     random_seed <- sample.int(2^31 - 1, size=1)
  } else {
     random_seed <- as.integer(random_seed)
  }

  set.seed(random_seed, kind="Mersenne-Twister")
  
  print(sprintf("Random seed for Mersenne-Twister is: %d", random_seed))
  print(sprintf("Reading records from: %s", records_path))

  records <- read.csv(records_path)

  N <- nrow(records)
  C <- ncol(records)
  
  row_selection = c(1:N)
  coord_selection = c(1:2)
  predictor_selection = c(3:C)
  
  coords <- records[row_selection,][coord_selection]
  records <- records[row_selection,][,]
  
  spatial_records <- records
  coordinates(spatial_records) = ~x+y
  
  #Duplicate points cause singular covariance matrices
  spatial_records <- remove.duplicates(spatial_records)
  N_unique_records <- nrow(spatial_records)
  
  x_min <- min(coords$x)
  y_min <- min(coords$y)
  
  x_max <- max(coords$x)
  y_max <- max(coords$y)
  
  if( is.na(x) ) {
    x <- floor(x_min)
  }
  
  if( is.na(y) ) {
    y <- floor(y_min)
  }
  
  #.Machine$double.eps
  
  if( is.na(width)) {
    width <- floor(x_max) + 1 - x
  }
  
  if( is.na(height)) {
    height <- floor(y_max) + 1 - y
  }
  
  g <- NULL
  
  if( !is.na(max_distance) ) {
    print(sprintf("Limiting to max distance of %f", max_distance));  
  }
  
  variable_names <- list()
  i <- 1
  
  for( name in names(records) ) {
    if( !(name %in% c("x", "y")) ) {
      variable_names[[i]] <- name
      i <- i + 1
    }
  }
  
  max_dist <- Inf
  
  if( !is.na(max_distance)) {
    max_dist <- max_distance
  }
  
  for( name in variable_names ) {
    if( !(name %in% c("x", "y")) ) {
        g <- gstat(g, id=name, formula=formula(paste(name, "~1", sep="")), data=spatial_records, maxdist=max_dist)
    }
  }
  
  print(g)
  
  start_time <- Sys.time()

  
  # By default, variogram when passing a gstat object computes all direct and 
  # cross variograms, but this can be turned off. 
  
  v.emp <- variogram(g)
  v.emp2 <- variogram(g, cutoff=100,width=100,map=TRUE)
  
  # The function fit.lmc fits a linear model of co-regionalization, which is a 
  # particular model that needs to have identical model components and
  # positive definite partial sill matrices, to ensure non-negative prediction 
  # variances when used for spatial prediction (cokriging).
  
  if( add_nugget ) {
    vg_model <- vgm(NA, variogram_model, NA, NA)
  } else {
    vg_model <- vgm(NA, variogram_model, NA)
  }

  #Make sure the sills and ranges of all variograms are the same
  v.first <- variogram(formula(paste(variable_names[[1]], "~1", sep="")), data=spatial_records)
  v.common <- fit.variogram(v.first, vg_model, fit.method=7)
  g <- gstat(g, id=variable_names[[1]], model=v.common, fill.all=T, maxdist=max_dist)
  v.fit <- fit.lmc(v.emp, g, fit.method=6, correct.diagonal=1.01)
  
  emp_matrix <- cbind(as.matrix(v.emp[,c(1:5)]), as.matrix(as.integer(v.emp$id)))
  dimnames(emp_matrix)[[2]] <- names(v.emp)
  
  fitted_models <- list()
  
  
  l <- 0
  i <- 1
  
  for( name in levels(v.emp$id)) {
    
    model <- v.fit$model[name][[1]]
    
    model_matrix <- cbind(rep.int(i, dim(model)[[1]]),
                          as.matrix(as.integer(model$model)), 
                          as.matrix(model[,c(2:dim(model)[[2]])]))
    
    
    dimnames(model_matrix)[[2]] = c("label", names(model))
    
    for( inner_name in dimnames(model_matrix)[[2]]) {
      if( is.null(fitted_models[[inner_name]] ) ) {
        fitted_models[[inner_name]] = rep.int(NA, l)
      }
      
      fitted_models[[inner_name]] <- c(fitted_models[[inner_name]], model_matrix[,inner_name])
    }
    
    i <- i + 1
    l <- l + dim(model)[[1]]
  }
  
  
  variogram_filename <- file.path(output_directory, "variograms.mat")
  variogram_metadata <- list()
  variogram_metadata$con <- variogram_filename
  variogram_metadata$labels <- levels(v.emp$id)
  variogram_metadata$models <- levels(v.common$model)
  variogram_metadata$empirical <- as.data.frame(emp_matrix)
  variogram_metadata$fitted <- as.data.frame(fitted_models)
  
  
  do.call(writeMat, variogram_metadata) 
  
  #lcm_filename <- file.path(output_directory, "lmc.png")
  #png(lcm_filename)
  #plot(v.emp, v.fit)
  #dev.off()
  
  #while (!is.null(dev.list())) Sys.sleep(1)
  
  if( variograms_only ) {
    return ("Done")
  }
  
  # Integral grid cell centres cause sampling artefacts in the kriging, so we must align
  # them in the conventional way by adding 0.5
  
  grid = SpatialGrid(grid = GridTopology(c(x + 0.5,y + 0.5), c(1,1), c(width, height)))
  
  #v.fit$set=list(nocheck=1)
  p <- predict(v.fit, newdata=grid)
  
  stop_time <- Sys.time()
  duration <- difftime(stop_time, start_time, units="secs")
  
  start_time <- format(start_time, "%Y_%m_%d_%H_%M_%S")
  stop_time <- format(stop_time, "%Y_%m_%d_%H_%M_%S")
  
  names(p)
  #spplot(p)
  #spplot.vcov(p)
  
  filename <- paste(sub(pattern = "(.*?)\\..*$", replacement = "\\1", basename(records_path)), "_cokriged", sep="")
  mat_filename <- file.path(output_directory, paste(filename, ".mat", sep=""))
  
  variances <- list()
  variance_names <- list()
  
  covariances <- list()
  covariance_names <- list()
  
  predictions <- list()
  prediction_names <- list()
  
  metadata <- list()
  metadata[[1]] = as.character(start_time)
  metadata[[2]] = as.character(stop_time)
  metadata[[3]] = as.double(duration, value="seconds")
  metadata[[4]] = length(spatial_records)
  metadata[[5]] = random_seed;
  metadata[[6]] = N;
  metadata[[7]] = N_unique_records;
  metadata[[8]] = variogram_model;
  metadata[[9]] = add_nugget;
  
  i <- 1
  j <- 1
  k <- 1
  
  for( name in names(p) ) {
    m <- as.matrix(p[name])
    m <- m[,c(ncol(m):1)]
    
    if( startsWith(name, "cov.") ) {
      covariances[[i]] = m
      covariance_names[[i]] = sub(pattern="cov\\.(.*)", replacement= "\\1", name)
      i <- i + 1
      
    } else if( endsWith(name, ".var") ) {
      variances[[j]] = m
      variance_names[[j]] = sub(pattern="(.*).var", replacement= "\\1", name)
      j <- j + 1
      
    } else {
      
      predictions[[k]] = m
      prediction_names[[k]] = sub(pattern="(.*).pred", replacement= "\\1", name)
      k <- k + 1
    }
  }
  
  names(covariances) = covariance_names
  names(variances) = variance_names
  names(predictions) = prediction_names
  
  names(metadata) = c("start_time", "stop_time", "duration", 
                      "effective_sample_size", "random_seed", 
                      "n_records", "n_unique_records", "variogram_model",
                      "add_nugget")
  
  output_wrapper <- list(mat_filename, metadata, predictions, variances, covariances, R.Version())
  names(output_wrapper) = c("con", "metadata", "predictions", "variances", "covariances", "version")
  
  do.call(writeMat, output_wrapper) 

  return ("Done")
}


main <- function() {
  
  options(error= traceback, warn=1)
  
  parser <- arg_parser(DESCRIPTION);

  parser <- add_argument(
    parser,
    "records",
    help="A csv file of records to process. A header line specifying x and y columns must be present."
  )
  
  parser <- add_argument(
    parser,
    "-r",
    type="double",
    default=NA,
    help="Specifies the random seed."
  )

  parser <- add_argument(
    parser,
    "-s",
    type="double",
    help = "The minimum x cell centroid for which a value is to be calculated."
  )
  
  parser <- add_argument(
    parser,
    "-t",
    type= "double",
    help = "The minimum y cell centroid for which a value is to be calculated."
  )
  
  parser <- add_argument(
    parser,
    "-m",
    type="integer",
    help="The horizontal resolution of the window for which values are to be calculated."
  )
  
  parser <- add_argument(
    parser,
    "-n",
    type="integer",
    help="The vertical resolution of the window for which values are to be calculated."
  )
  
  parser <- add_argument(
    parser,
    "-d",
    type="double",
    help="Specifying a maximum distance for samples implies local kriging."
  )
  
  parser <- add_argument(
    parser,
    "-o",
    type="character",
    default="",
    help="A directory for storing the output file(s). If not specified the directory of the input file will be used."
  )
  
  parser <- add_argument(
    parser,
    "-c",
    type="character",
    default="Exp",
    help="Specifies the variogram function."
  )
  
  parser <- add_argument(
    parser,
    "-g",
    help="Indicates that a nugget component should be added.",
    flag=TRUE
  )
  
  parser <- add_argument(
    parser,
    "-v",
    help="Only compute the variograms.",
    flag=TRUE
  )
  
  
  argv <- parse_args(parser)
  
  output_directory <- argv$o
  
  records_path <- argv$records
  if (!R.utils::isAbsolutePath(records_path))
    records_path <- normalizePath(records_path, mustWork=FALSE) #file.path(getwd(), records_path),
  
  if (nchar(output_directory) == 0)
    output_directory <- dirname(records_path)
  
  #print(records_path)
  #print(output_directory)
  
  tryCatch(run(records_path, output_directory, argv$r, argv$s, argv$t, argv$m, argv$n, argv$d, argv$c, argv$g, TRUE), finally= print(paste(NAME, "finished.")))
}

#main()
#q(save="no")

records_path <- "/data/holger/LOCALMATLAB/validation_results_final/Kriging/krig_mat_snowflakes_3200/1/krig_mat_snowflakes_3200_1/experiment_data.csv"
output_directory <- "/data/holger/LOCALMATLAB/validation_revision"

records_path <- "/Users/work/MATLAB/krig_mat_snowflakes_3200_1/experiment_data.csv"
output_directory <- "Users/work/MATLAB"

run(records_path, output_directory, 418159781, 1, 1, 220, 210, NA, "Mat", TRUE, TRUE)



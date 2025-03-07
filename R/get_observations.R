#' Observation Process
#'
#' This function simulates an observation process. It accepts the `sim_results`
#' object, which is generated by the [`sim`] function, and applies the virtual
#' ecologist approach on the `N_map` component of the object. The function
#' returns a `data.frame` with the 'observed' abundances.
#'
#' @param sim_data `sim_data` object from [`initialise`] containing simulation
#' parameters
#' @param sim_results `sim_results` object; returned by [`sim`] function
#' @param type character vector of length 1; describes the sampling type
#' (case-sensitive):
#' \itemize{
#'   \item "random_one_layer" - random selection of cells for which abundances
#'   are sampled; the same set of selected cells is used across all time steps.
#'   \item "random_all_layers" - random selection of cells for which abundances
#'   are sampled; a new set of cells is selected for each time step.
#'   \item "from_data" - user-defined selection of cells for which abundances
#'   are sampled; the user is required to provide a `data.frame` containing
#'   three columns: "x", "y" and "time_step".
#'   \item "monitoring_based" - user-defined selection of cells for which
#'   abundances are sampled; the user is required to provide a matrix object
#'   with two columns: "x" and "y"; the abundance from given cell is sampled
#'   by different virtual observers in different time steps; a geometric
#'   distribution ([`rgeom`][stats::rgeom()]) is employed to define whether
#'   a survey will be conducted by the same observer for several years or
#'   not conducted at all.
#' }
#'
#' @param obs_error character vector of length 1; type of the distribution
#' that defines the observation process: "[`rlnorm`][stats::rlnorm()]" (the log
#' normal distribution) or "[`rbinom`][stats::rbinom()]" (the binomial
#' distribution)
#' @param obs_error_param numeric vector of length 1; standard deviation
#' (on a log scale) of the random noise in observation process generated from
#' the log-normal distribution ([`rlnorm`][stats::rlnorm()]) or probability of
#' detection (success) when the binomial distribution
#' ("[`rbinom`][stats::rbinom()]") is used.
#' @param ... other necessary internal parameters:
#' \itemize{
#'   \item `prop`
#'
#'   numeric vector of length 1; proportion of cells to be sampled
#'   (default `prop = 0.1`);
#'   used when `type = "random_one_layer" or "random_all_layers"`,
#'
#'   \item `points`
#'
#'   `data.frame` or `matrix` with 3 numeric columns named "x", "y",
#'   and "time_step" containing coordinates and time steps from which
#'   observations should be obtained; used when `type = "from_data"`,
#'
#'   \item `cells_coords`
#'
#'   `data.frame` or `matrix` with 2 columns named "x" and "y"; survey plots
#'   coordinates; used when `type = "monitoring_based"`
#'
#'   \item `prob`
#'
#'    numeric vector of length 1; a parameter defining the shape of
#'    [`rgeom`][stats::rgeom()] distribution; defines whether an observation
#'    will be made by the same observer for several years, and whether it
#'    will not be made at all (default `prob = 0.3`);
#'    used when `type = "monitoring_based"`
#'
#'   \item `progress_bar`
#'
#'    logical vector of length 1; determines if a progress bar for observation
#'    process should be displayed (default `progress_bar = FALSE`);
#'    used when `type = "monitoring_based"`
#' }
#'
#' @return `data.frame` object with geographic coordinates, time steps,
#' estimated abundance, observation error (if `obs_error_param` is
#' provided), and observer identifiers (if `type = "monitoring_based"`). If `type = "from_data"`, returned object is sorted in the same order as the input `points`.
#'
#' @export
#'
#' @examples
#' \donttest{
#'
#' library(terra)
#' n1_small <- rast(system.file("input_maps/n1_small.tif", package = "rangr"))
#' K_small <- rast(system.file("input_maps/K_small.tif", package = "rangr"))
#'
#' # prepare data
#' sim_data <- initialise(
#'   n1_map = n1_small,
#'   K_map = K_small,
#'   r = log(2),
#'   rate = 1 / 1e3
#' )
#'
#' sim_1 <- sim(obj = sim_data, time = 110, burn = 10)
#'
#' # 1. random_one_layer
#' sample1 <- get_observations(
#'   sim_data,
#'   sim_1,
#'   type = "random_one_layer",
#'   prop = 0.1
#' )
#'
#' # 2. random_all_layers
#' sample2 <- get_observations(
#'   sim_data,
#'   sim_1,
#'   type = "random_all_layers",
#'   prop = 0.15
#' )
#'
#' # 3. from_data
#' sample3 <- get_observations(
#'   sim_data,
#'   sim_1,
#'   type = "from_data",
#'   points = observations_points
#' )
#'
#' # 4. monitoring_based
#' # define observations sites
#' all_points <- xyFromCell(unwrap(sim_data$id), cells(unwrap(sim_data$K_map)))
#' sample_idx <- sample(1:nrow(all_points), size = 20)
#' sample_points <- all_points[sample_idx, ]
#'
#' sample4 <- get_observations(
#'   sim_data,
#'   sim_1,
#'   type = "monitoring_based",
#'   cells_coords = sample_points,
#'   prob = 0.3,
#'   progress_bar = TRUE
#' )
#'
#' # 5. noise "rlnorm"
#' sample5 <- get_observations(sim_data,
#'   sim_1,
#'   type = "random_one_layer",
#'   obs_error = "rlnorm",
#'   obs_error_param = log(1.2)
#' )
#'
#' # 6. noise "rbinom"
#' sample6 <- get_observations(sim_data,
#'   sim_1,
#'   type = "random_one_layer",
#'   obs_error = "rbinom",
#'   obs_error_param = 0.8
#' )
#'
#' }
#'
#' @srrstats {G1.4} uses roxygen documentation
#' @srrstats {G2.0a} documented lengths expectation
#' @srrstats {G2.1a, G2.3, G2.3b, SP2.6} documented types expectation
#' @srrstats {G2.7} points and cells_coords can be a dataframe or matrix
#' @srrstats {SP2.3} load data in spatial formats
#' @srrstats {SP4.1} returned object has the same unit as the input
#' @srrstats {SP4.2} returned values are documented
#'
#'
get_observations <- function(
    sim_data, sim_results, type = c("random_one_layer", "random_all_layers",
    "from_data", "monitoring_based"), obs_error = c("rlnorm", "rbinom"),
    obs_error_param = NULL, ...) {

  #' @srrstats {G2.0, G2.2} assert input length
  #' @srrstats {G2.1, G2.3, G2.3a, G2.6, SP2.7} assert input type

  # arguments validation
  type <- match.arg(type)
  obs_error <- match.arg(obs_error)
  assert_that(inherits(sim_data, "sim_data"))
  assert_that(inherits(sim_results, "sim_results"))
  assert_that((is.numeric(obs_error_param) && length(obs_error_param) == 1) ||
                is.null(obs_error_param),
              msg = "parameter obs_error_param can be set either as NULL or as a single number") #nolint

  # transform N_map to raster based on id
  id <- unwrap(sim_data$id)
  N_rast <- rast(
    sim_results$N_map,
    extent = ext(id),
    crs = crs(id)
  )

  # call one of sampling functions
  if (type %in% c("random_one_layer", "random_all_layers")) {
    # random VE
    out <- get_observations_random(N_rast, type, ...)
  } else if (type == "from_data") {
    # VE based on provided data
    out <- get_observations_from_data(N_rast, ...)
  } else if (type == "monitoring_based") {
    # VE that replicates ecological monitoring process
    out <- get_observations_monitoring_based(N_rast, ...)
  }

  # add noise to the "observations"
  if (!is.null(obs_error_param)) {
    if (obs_error == "rlnorm")
      # the log normal distribution
      out$n <- rlnorm(nrow(out), log(out$n), obs_error_param)
    else if(obs_error == "rbinom")
      # the binomial distribution
      out$n <- rbinom(nrow(out), out$n, obs_error_param)
  }

  return(out)
}



# Internal functions for get_observations function -----------------------------



#' Random Sampling
#'
#' `get_observations` calls this function if sampling type equals to
#' "random_one_layer" or "random_all_layers".
#'
#' @param N_rast [`SpatRaster`][terra::SpatRaster-class] object
#' with abundances for each time step
#' @param prop numeric vector of length 1; proportion of cells to be sampled
#' @inheritParams get_observation
#'
#' @return `data.frame` object with coordinates, time steps, abundances
#' without noise
#'
#'
#' @srrstats {G1.4a} uses roxygen documentation (internal function)
#' @srrstats {G2.0a} documented lengths expectation
#'
#' @noRd
#'
get_observations_random <- function(N_rast, type, prop = 0.1) {

  #' @srrstats {G2.0, G2.2} assert input length
  #' @srrstats {G2.1, G2.3, G2.3a, G2.6} assert input type

  # Validation of arguments

  ## prop
  assert_that(length(prop) == 1)
  assert_that(is.numeric(prop))
  assert_that(prop > 0 && prop <= 1,
              msg = "prop parameter must be greater than 0 but less than or equal to 1")

  # set sample size
  size <- ncell(N_rast) * prop

  # sample
  if (type == "random_one_layer") {
    # the same cells in each layer

    # spatial sample
    out <- spatSample(N_rast, size, xy = TRUE, na.rm = TRUE)
    colnames(out) <- c("x", "y", seq_len(nlyr(N_rast)))

    # reshape from wide to long format
    out <- as.data.frame(reshape(
      out,
      direction = "long",
      varying = list(as.character(seq_len(nlyr(N_rast)))),
      v.names = "n",
      idvar = c("x", "y"),
      timevar = "time_step",
      times = seq_len(nlyr(N_rast))))
    rownames(out) <- seq_len(nrow(out))

  } else if (type == "random_all_layers") {
    # different cells in each layer

    # different spatial sample from each time step
    out <- lapply(
      seq_len(nlyr(N_rast)),
      function(i) {
        N_layer <- N_rast[[i]]
        N_layer_sample <- cbind(
          spatSample(N_layer, size, xy = TRUE, na.rm = TRUE), i)
        colnames(N_layer_sample) <- c("x", "y", "n", "time_step")

        return(N_layer_sample)
      }
    )

    # row bind samples from each time step
    out <- do.call(rbind, out)
  }

  return(out[c("x", "y", "time_step", "n")])
}


#' Sampling Based On Given Data
#'
#' [get_observations] calls this function if sampling type
#' equals to "from_data".
#'
#' @param points `data.frame` or `matrix` with 3 named numeric columns ("x", "y"
#' and "time_step") containing coordinates and time steps from which
#' observations should be obtained`
#' @inheritParams get_observations_random
#'
#' @return `data.frame` object with coordinates, time steps numbers,
#' abundances without noise
#'
#'
#' @srrstats {G1.4a} uses roxygen documentation (internal function)
#'
#' @noRd
#'
get_observations_from_data <- function(N_rast, points) {

  #' @srrstats {G2.0, G2.2} assert input length
  #' @srrstats {G2.1, G2.3, G2.3a, G2.6} assert input type
  #' @srrstats {G2.8} matrix to data.frame
  #' @srrstats {G2.14a} error on missing data

  # Validation of arguments

  ## points
  assert_that(is.data.frame(points) || is.matrix(points))
  points <- as.data.frame(points)
  assert_that(ncol(points) >= 3, msg = "not enough columns in \"points\"")
  assert_that(
    all(c("x", "y", "time_step") %in% names(points)),
    msg = "points parameter should contain columns with the following names: \"x\", \"y\", \"time_step\"")
  assert_that(nrow(points) > 0)

  points <- points[c("x", "y", "time_step")]
  assert_that(
    all(!is.na(points)),
    msg = "missing data found in \"points\"")
  assert_that(
    all(apply(points, 2, is.numeric)),
    msg = "some element of point are not numeric")

  # add order column to restore input row order later
  points$order <- seq_len(nrow(points))

  # sort the points df based on time_step - necessary for the next step
  points <- points[order(points$time_step),]

  # get "observations" from cells given in points dataset
  n <- unlist(lapply(
    seq_len(nlyr(N_rast)),
    function(i) {
      tmp_points <- points[points$time_step == i, ]
      extract(
        N_rast[[i]],
        tmp_points[c("x", "y")])[, 2]
    }
  ))

  # column bind points and "observations"
  out <- cbind(points, n = n)

  # restore initial order of rows
  out <- out[order(out$order),]

  # return only the necessary columns
  out <- out[c("x", "y", "time_step", "n")]
}



#' Sampling That Mimics A Real Survey Programmes
#'
#' [get_observations] calls this function if sampling type
#' equals to "monitoring_based".
#'
#' @param cells_coords matrix object with two columns: "x" and "y"
#' @param prob probability of success in each trial - [stats::rgeom()] parameter
#' @param progress_bar logical vector of length 1; determines if progress bar
#' for observation should be displayed (if `type = "monitoring_based"`)
#' @inheritParams get_observations_random
#'
#' @return `data.frame` object with coordinates, time steps, abundances without
#' noise and observer_id
#'
#'
#' @srrstats {G1.4a} uses roxygen documentation (internal function)
#' @srrstats {G2.0a} documented lengths expectation
#'
#' @noRd
#'
get_observations_monitoring_based <- function(
    N_rast, cells_coords, prob = 0.3, progress_bar = FALSE) {

  #' @srrstats {G2.0, G2.2} assert input length
  #' @srrstats {G2.1, G2.3, G2.3a, G2.6} assert input type
  #' @srrstats {G2.8} matrix to data.frame
  #' @srrstats {G2.14a} error on missing data

  # Validation of arguments

  ## cells_coords
  assert_that(is.data.frame(cells_coords) || is.matrix(cells_coords))
  cells_coords <- as.data.frame(cells_coords)
  assert_that(ncol(cells_coords) == 2)
  assert_that(nrow(cells_coords) > 0)
  assert_that(
    all(!is.na(cells_coords)),
    msg = "missing data found in \"cells_coords\"")
  assert_that(
    all(names(cells_coords) == c("x", "y")),
    msg = "columns in cells_coords parameter should have the following names: \"x\", \"y\"")
  assert_that(
    all(apply(cells_coords, 2, is.numeric)),
    msg = "some element of cells_coords are not numeric")

  # extract number of study sited (cells) and time steps
  ncells <- nrow(cells_coords)
  time_steps <- nlyr(N_rast)

  # prepare data structure with coordinates, time step and column for observer id
  points <- data.frame(
    x = rep(cells_coords[, "x"], each = time_steps),
    y = rep(cells_coords[, "y"], each = time_steps),
    time_step = rep(1:time_steps, ncells),
    obs_id = NA
  )

  # progress bar set up
  if (progress_bar) {
    pb <- txtProgressBar(
      min = 1, max = ncells, style = 3
    )
  }

  # loop through each study site (cell) and assign observers at each time step
  for (i in 1:ncells) {

    # set up time step and id counters
    curr_time_steps <- 1
    curr_id <- 1

    # while in specified time frame
    while (curr_time_steps < time_steps) {

      # how long many time steps one observer will stay on study site (cell) i
      observers_sequence <- rgeom(1, prob)

      if (observers_sequence > 0) {
        # if observers stays in current cell at all

        # if the current observer is the last one for the current cell
        if (curr_time_steps + observers_sequence > time_steps) {
          # adjust the time so that it does not exceed the simulated time steps
          observers_sequence <- time_steps - curr_time_steps
        }

        # calculate row number for current cell and time step
        row_id <- (i - 1) * time_steps + curr_time_steps

        # assign the observer to the study site (cell) for specified time steps
        points$obs_id[row_id:(row_id + observers_sequence - 1)] <-
          rep(paste0("obs", curr_id), observers_sequence)

        # update counters
        curr_time_steps <- curr_time_steps + observers_sequence
        curr_id <- curr_id + 1

      } else {
        # no observation in current cell i at current time step
        curr_time_steps <- curr_time_steps + 1
      }
    }
    # update progress bar
    if (progress_bar) setTxtProgressBar(pb, i)
  }
  # close progress bar
  if (progress_bar) close(pb)

  # remove rows without observers
  points <- points[!is.na(points$obs_id), ]

  # get "observations"
  n <- lapply(
    # for each simulated time step
    seq_len(nlyr(N_rast)),
    function(i) {
      # get cells coordinates
      tmp_points <- points[points$time_step == i, ]
      # get "observations" from cells
      tmp_vals <- extract(
        N_rast[[i]],
        tmp_points[c("x", "y")])[, 2]

      # return coordinates with "observed" values
      cbind(tmp_points, n = tmp_vals)
    }
  )

  # row bind results
  out <- do.call(rbind, n)

  # sort results
  out <- out[order(as.numeric(rownames(out))),]

  return(out)
}

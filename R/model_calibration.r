#' Model validation routine to faciliate model development
#' and quick validation of a (new) model.
#'
#' @param model the model name to be used in optimizing the model
#' @param data dataset generated by the format_phenocam() or
#' format_modis() routines, or adhering to the general model optimization
#' input format.
#' @param method optimization method to use (default = GenSA)
#'    - GenSA :  Generalized Simulated Annealing algorithm
#'    - genoud : GENetic Optimization Using Derivatives
#'    - BayesianTools: various bayesian based optimization tools
#' @param par_ranges a vector of starting parameter values (function specific)
#' defaults to the parameter ranges as provided with the current models
#' and set forth by Basler (2016)
#' @param control list of control parameters to be passed to the optimizer
#' @param plot TRUE / FALSE, plot model fit
#' @param ... additional control parameters to be passed
#' @keywords phenology, model, validation
#' @export
#' @examples
#'
#' \dontrun{
#' model_calibration(model,par_ranges = "parameter_ranges.csv")
#'
#' # estimate will return the best estimated parameter set given the
#' # validation data
#' }

model_calibration = function(
  model = "TT",
  data = phenor::phenocam_DB,
  method = "GenSA",
  control = list(max.call = 2000),
  par_ranges = sprintf("%s/extdata/parameter_ranges.csv",
                       path.package("phenor")),
  plot = TRUE,
  ...
  ){

  # convert to a flat format for speed
  data = flat_format(data)

  # read in parameter ranges
  par_ranges = utils::read.table(par_ranges,
                          header = TRUE,
                          sep = ",")

  # subset the parameter range
  if (!any(par_ranges$model == model)){
    stop("parameters are not specified in the default parameter file.")
  }

  # extract parameter ranges is the model is available
  # in the file provided
  d = par_ranges[par_ranges$model == model,]
  d = d[,!is.na(d[1,])]
  d = d[,3:ncol(d)]
  d = as.matrix(d)

  # optimize paramters
  optim_par = optimize_parameters(
    par = NULL,
    data = data,
    model = model,
    method = method,
    lower = as.numeric(d[1,]),
    upper = as.numeric(d[2,]),
    control = control,
    ...
  )

  # estimate model output using optimized
  # parameters
  out = estimate_phenology(
    data = data,
    model = model,
    par = optim_par$par
  )

  # basic statistics
  RMSE_NULL = sqrt(mean((data$transition_dates - null(data)) ^ 2, na.rm = T))
  RMSE = rmse(par = optim_par$par, data = data, model = model)
  Ac = AICc(measured = data$transition_dates,
            predicted = out,
            k = length(optim_par$par))

  # plot data if requested
  if (plot){
    plot(data$transition_dates,out,
         main = paste0(model,", iterations: ", control$max.call),
         xlab = "onset DOY Measured",
         ylab = "onset DOY Modelled",
         pch = 19,
         tck = 0.02)
    graphics::abline(0,1)
    graphics::legend("topleft",
                     legend = sprintf("RMSE: %s",
                                      round(RMSE)),bty='n')
    graphics::legend("top",
                     legend = sprintf("RMSE NULL: %s",
                                      round(RMSE_NULL)),bty='n')
    graphics::legend("bottomright",
                     legend = sprintf("AICc: %s",
                                      round(Ac$AICc)),bty='n')
  }

  # print summary statistics
  print(summary(stats::lm(data$transition_dates ~ out)))

  # return optimized parameters and stats
  return(list(
    "model" = model,
    "par" = optim_par$par,
    "rmse" = RMSE,
    "rmse_null" = RMSE_NULL,
    "aic" = Ac,
    "bt_output" = optim_par$bt_output
    )
  )
}

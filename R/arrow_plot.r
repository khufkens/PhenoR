#' Generates an arrow plot, plotting differences
#' between two model runs visualized by red and
#' blue arrows indicating the direction of the change.
#'
#' This allows you to explore the effect of model structure
#' on the estimated phenology dates.
#'
#' @param data a structure list generated by model_comparison()
#' @param models models to compare, vector with two model names e.g.
#' c("TT","PTT") (default, first two models in the data file)
#' @param lwd line witdth of the arrows in the plot, change for readability
#' (default = 1.3)
#' @param length length of the arrow head, change for readability
#' (default = 0.03)
#' @keywords phenology, model comparison, plotting, visualization
#' @export
#' @examples
#'
#' \dontrun{
#' arrow_plot(data = model_comparison_data)
#'}

arrow_plot = function(data = NULL,
                      models = NULL,
                      lwd = 1.3,
                      length = 0.03){

  # sanity check, as no defaults are provided
  if (is.null(data)){
    stop("no input data provided")
  }

  # check if there are models to compare
  if(length(names(data$modelled)) < 2){
    stop("only one model found in the data file, check your input")
  }

  if (is.null(models)){
    # grab the site names, only select the first two
    # for comparison (by default, and if available)
    cat("no models specified for comparison, first two are selected \n")
    sites = names(data$modelled)[1:2]
    model_col = c(1,2)
  } else {
      if (length(models)!=2){
        stop("you can only plot the comparison of two models at a time")
      }
      model_col= c(match(models[1],names(data$modelled)),
                   match(models[2],names(data$modelled)))
      if ( NA %in% model_col){
        stop("the specified models are not in the provided dataset")
      }
    sites = models
  }

  # summarize the predicted values (take the mean across runs)
  predicted_values = t(do.call("rbind", lapply(data$modelled, function(x) {
    apply(x$predicted_values, 2, mean)
  })))[,model_col]

  # calculate locations which do not change
  loc = which(apply(predicted_values,1,diff) == 0)

  # calculate ylim ranges, provide some padding to let the
  # plot breath a bit
  max_pred = max(apply(predicted_values,1,max)) + 10
  min_pred = min(apply(predicted_values,1,min)) - 10

  # provide the baseline plot (don't plot values)
  graphics::plot(data$measured,
       predicted_values[,1],
       main = sprintf("Directional change from model: %s to %s",
                      sites[1],sites[2]),
       type = "n",
       ylab = "Estimated values (DOY)",
       xlab = "Measured values (DOY)",
       ylim = c(min_pred, max_pred),
       tck = 0.02)

  # plot a 1:1 line
  graphics::abline(0,1,
         lty = 2)

  # calculate the colours to assign to arrows
  # rising arrows are red, falling arrows are blue
  col = apply(predicted_values,1,diff)
  col = ifelse(col >= 0,
               grDevices::rgb(241,163,64, maxColorValue = 255),
               grDevices::rgb(153,142,195, maxColorValue = 255))

  # set unchanged points colours to transparent
  col[loc] = grDevices::rgb(0,0,0,0)

  # plot points which haven't changed
  graphics::points(data$measured[loc],
                   predicted_values[loc,1],
                   col = grDevices::rgb(0,0,0,0.5),
                   cex = 0.3,
                   pch = 19)

  # plot the arrows with the correct colours
  # limit the length of the arrow head
  # suppress warnings on arrows of zero length
  suppressWarnings(
    graphics::arrows(
         x0 = data$measured,
         y0 = predicted_values[,1],
         x1 = data$measured,
         y1 = predicted_values[,2],
         length = length,
         col = col,
         lwd = lwd)
    )
}

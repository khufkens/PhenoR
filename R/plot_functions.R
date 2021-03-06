#' Generates an arrow plot
#'
#' This plots differences between two model runs visualized by red and
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
#' pr_plot_arrow(data = model_comparison_data)
#'}

pr_plot_arrows = function(
  data,
  models = NULL,
  lwd = 1.3,
  length = 0.03
){

  # sanity check, as no defaults are provided
  if (missing(data)){
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
               "#ef8a62",
               "#67a9cf")

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

#' Model comparison  plotting routine to faciliate model development
#' and quick comparisons of the skill of various models. Add your model
#' to the list in your branch or fork to make this work with novel model
#' formulations.
#'
#' @param data list returned by model_comparison()
#' @param ylab cost function value to annotate y-axis (default = "RMSE (days)")
#' @param names include model names, TRUE / FALSE (default = TRUE)
#' @param ... extra arguments to pass to the function
#' @keywords phenology, model, data, comparison, plotting
#' @export
#' @examples
#'
#' \dontrun{
#' pr_plot_comparison()
#' }

pr_plot_comparison = function(data = NULL,
                                 ylab = "RMSE (days)",
                                 names = TRUE,
                                 ...){

  # trap lack of data
  if (is.null(data)){
    stop("No comparison or reference data ")
  }

  # colours => ugly find solution
  colours = as.data.frame(matrix(
    c("NULL","black",
      "LIN","black",
      "TT","#ef8a62",
      "TTs","#ef8a62",
      "PTT","#ef8a62",
      "PTTs","#ef8a62",
      "M1","#ef8a62",
      "M1s","#ef8a62",
      "AT","#67a9cf",
      "SQ","#67a9cf",
      "SQb","#67a9cf",
      "SM1","#67a9cf",
      "SM1b","#67a9cf",
      "PA","#67a9cf",
      "PAb","#67a9cf",
      "PM1","#67a9cf",
      "PM1b","#67a9cf",
      "UN","#67a9cf",
      "UM1","#67a9cf",
      "SGSI","#67a9cf",
      "AGSI","#67a9cf"
    ),21,2, byrow = TRUE))
  colnames(colours) = c("model","colour")

  # calculate mean / sd RMSE of all model runs
  # (different parameters - by different seeds)
  rmse_stats = lapply(data$modelled,function(x){
    rmse = apply(x$predicted_values,1,function(y){
      sqrt(mean((y - data$measured) ^ 2, na.rm = T))
    })
    return(rmse)
    list("rmse" = mean(rmse,na.rm=TRUE),
         "sd"=stats::sd(rmse,na.rm=TRUE))
  })

  labels = names(rmse_stats)
  col_sel = as.character(colours[which(colours$model %in% labels),2])
  rmse_stats = do.call("cbind",rmse_stats)

  # calculate RMSE null model (single value)
  rmse_null = sqrt(mean((
    data$measured -  rep(round(mean(
      data$measured, na.rm = TRUE
    )), length(data$measured))
  ) ^ 2, na.rm = T))

  # tick settings
  graphics::par(tck = 0.03, lwd = 1.3)

  # list model names
  if (names == 'TRUE'){
    x_names = labels
  } else {
    x_names = rep(" ",ncol(rmse_stats))
  }

  # check for custom ylim values
  dots = list(...)
  if(length(dots)!=0){
    if(names(dots)=="ylim"){
      ylim_val = dots$ylim
    }
  } else {
    ylim_val = c(0, rmse_null + rmse_null * 0.25)
  }

  # create boxplot with stats
  graphics::boxplot(rmse_stats,
                    las = 2,
                    names = x_names,
                    ylim = ylim_val,
                    ylab = ylab,
                    whiskcol = col_sel,
                    staplecol = col_sel,
                    boxcol = col_sel,
                    medcol = col_sel,
                    cex.lab = 1.5,
                    cex.axis = 1.5,
                    outline = FALSE)

  # set a horizontal marker for the baseline NULL model
  graphics::abline(h = rmse_null, lty = 2)
}


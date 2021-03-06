% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/pr_fm_modis.R
\name{pr_fm_modis}
\alias{pr_fm_modis}
\title{Format MODIS MCD12Q2 phenology data}
\usage{
pr_fm_modis(path = tempdir(), phenophase = "Increase", cycle = 1, offset = 264)
}
\arguments{
\item{path}{a path to MODISTools MCD12Q2 phenology dates}

\item{phenophase}{Phenological phase, Increase, Maximum,
Decrease or Minimum (default = Increase)}

\item{cycle}{retrieve data from which cycle, 1th or 2th (default = 1)}

\item{offset}{offset of the time series in DOY (default = 264, sept 21)}
}
\description{
Relies on the MODISTools package to query data. Currently only works
for areas with Daymet coverage (Northern America).
}
\examples{

\dontrun{
modis_data = pr_fm_modis()
}
}
\keyword{model,}
\keyword{phenology,}
\keyword{preprocessing}

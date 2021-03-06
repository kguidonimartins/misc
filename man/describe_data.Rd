% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/describe_data.R
\name{describe_data}
\alias{describe_data}
\title{Describe data}
\usage{
describe_data(data)
}
\arguments{
\item{data}{a data frame}
}
\value{
a skimr object
}
\description{
Describe data
}
\examples{
\dontrun{
nice_data <- data.frame(c1 = c(1, NA), c2 = c(NA, NA))
nice_data \%>\%
  describe_data()
}
}

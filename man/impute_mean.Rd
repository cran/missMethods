% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/impute_location_parameter.R
\name{impute_mean}
\alias{impute_mean}
\title{Mean imputation}
\usage{
impute_mean(ds, type = "columnwise")
}
\arguments{
\item{ds}{A data frame or matrix with missing values.}

\item{type}{One of: "columnwise", "rowwise", "total", "Two-Way" or "Winer"
(see details).}
}
\value{
An object of the same class as \code{ds} with imputed missing values.
}
\description{
Impute an observed mean for the missing values
}
\details{
For every missing value the mean of some observed values is imputed.
The observed values to be used are specified via \code{type}.
For example, \code{type = "columnwise"} (the default) imputes the mean of
the observed values in a column for all missing values in the column.
This is normally meant, if someone speaks of "imputing the mean" or
"mean imputation".

Other options for \code{type} are: "rowwise", "total", "Winer" and
"Two-way".
The option "rowwise" imputes all missing values in a row with the mean of the
observed values in the same row.
"total" will impute every missing value with the mean of all observed values
in \code{ds}.
"Winer" imputes the mean of the rowwise and columnwise mean.
Beland et al. (2016) called this method "Winer" and they attributed the
method to Winer (1971).
"Two-way" imputes the sum of rowwise and columnwise mean minus the total mean.
This method was suggested by D.B Rubin to Bernaards & Sijtsma, K. (2000).
}
\section{A Note for tibble users}{

If you use tibbles and an error like \sQuote{Lossy cast from `value` double
to integer} occurs, you will first need to convert all integer columns
with missing values to double. Another solution is to convert the tibble with
as.data.frame() to a data frame. The data frame will automatically convert
integer columns to double columns, if needed.
}

\examples{
ds <- data.frame(X = 1:20, Y = 101:120)
ds_mis <- delete_MCAR(ds, 0.2)
ds_imp <- impute_mean(ds_mis)
# completely observed columns can be of any type:
ds_mis_char <- cbind(ds_mis, letters[1:20])
ds_imp_char <- impute_mean(ds_mis_char)
}
\references{
Beland, S., Pichette, F., & Jolani, S. (2016). Impact on Cronbach's
\eqn{\alpha}{alpha} of simple treatment methods for missing data.
\emph{The Quantitative Methods for Psychology}, 12(1), 57-73.

Bernaards, C. A., & Sijtsma, K. (2000). Influence of imputation and EM
methods on factor analysis when item nonresponse in questionnaire data is
nonignorable. \emph{Multivariate Behavioral Research}, 35(3), 321-364.

Winer, B. J. (1971). \emph{Statistical principles in experimental design (2ed ed.)}
New York: McGraw-Hill
}
\seealso{
\code{\link{apply_imputation}} the workhorse for this function.

Other location parameter imputation functions: 
\code{\link{impute_median}()},
\code{\link{impute_mode}()}
}
\concept{location parameter imputation functions}

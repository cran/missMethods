% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/impute_location_parameter.R
\name{impute_median}
\alias{impute_median}
\title{Median imputation}
\usage{
impute_median(ds, type = "columnwise", ordered_low = FALSE)
}
\arguments{
\item{ds}{A data frame or matrix with missing values.}

\item{type}{One of: "columnwise", "rowwise", "total", "Two-Way" or "Winer"
(see details).}

\item{ordered_low}{Logical; used for the calculation of the median from
ordered factors (for details see: \link{median.factor}).}
}
\value{
An object of the same class as \code{ds} with imputed missing values.
}
\description{
Impute an observed median value for every missing value
}
\details{
This function behaves exactly like \code{\link{impute_mean}}.
The only difference is that it imputes a median instead of a mean.
All \code{type}s from \code{\link{impute_mean}} are also implemented for
\code{impute_median}.
They are documented in \code{\link{impute_mean}} and
\code{\link{apply_imputation}}.
The function \code{\link[stats]{median}} is used for the calculation of
the median values for imputation.
}
\section{A Note for tibble users}{

If you use tibbles and an error like \sQuote{Lossy cast from `value` double
to integer} occurs, you will first need to convert all integer columns
with missing values to double. Another solution is to convert the tibble with
as.data.frame() to a data frame. The data frame will automatically convert
integer columns to double columns, if needed.
}

\examples{
ds <- data.frame(X = 1:20, Y = ordered(LETTERS[1:20]))
ds_mis <- delete_MCAR(ds, 0.2)
ds_imp <- impute_median(ds_mis)
# completely observed columns can be of any type:
ds_mis_char <- cbind(ds_mis, letters[1:20])
ds_imp_char <- impute_median(ds_mis_char)
}
\references{
Beland, S., Pichette, F., & Jolani, S. (2016). Impact on Cronbach's
\eqn{\alpha}{alpha} of simple treatment methods for missing data.
\emph{The Quantitative Methods for Psychology}, 12(1), 57-73.
}
\seealso{
\code{\link{apply_imputation}} the workhorse for this function.

\code{\link[stats]{median}}, \code{\link{median.factor}}

Other location parameter imputation functions: 
\code{\link{impute_mean}()},
\code{\link{impute_mode}()}
}
\concept{location parameter imputation functions}

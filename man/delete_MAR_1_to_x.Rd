% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/delete_1_to_x.R
\name{delete_MAR_1_to_x}
\alias{delete_MAR_1_to_x}
\title{Create MAR values using MAR1:x}
\usage{
delete_MAR_1_to_x(
  ds,
  p,
  cols_mis,
  cols_ctrl,
  x,
  cutoff_fun = median,
  prop = 0.5,
  use_lpSolve = TRUE,
  ordered_as_unordered = FALSE,
  n_mis_stochastic = FALSE,
  x_stochastic = FALSE,
  add_realized_x = FALSE,
  ...,
  miss_cols,
  ctrl_cols,
  stochastic
)
}
\arguments{
\item{ds}{A data frame or matrix in which missing values will be created.}

\item{p}{A numeric vector with length one or equal to length \code{cols_mis};
the probability that a value is missing.}

\item{cols_mis}{A vector of column names or indices of columns in which
missing values will be created.}

\item{cols_ctrl}{A vector of column names or indices of columns, which
controls the creation of missing values in \code{cols_mis}. Must be of the
same length as \code{cols_mis}.}

\item{x}{Numeric with length one (0 < x < \code{Inf}); odds are 1 to x for
the probability of a value to be missing in group 1 against the probability
of a value to be missing  in group 2 (see details).}

\item{cutoff_fun}{Function that calculates the cutoff values in the
\code{cols_ctrl}.}

\item{prop}{Numeric of length one; (minimum) proportion of rows in group 1
(only used for unordered factors).}

\item{use_lpSolve}{Logical; should lpSolve be used for the determination of
groups, if \code{cols_ctrl[i]} is an unordered factor.}

\item{ordered_as_unordered}{Logical; should ordered factors be treated as
unordered factors.}

\item{n_mis_stochastic}{Logical, should the number of missing values be
stochastic? If \code{n_mis_stochastic = TRUE}, the number of missing values
for a column with missing values \code{cols_mis[i]} is a random variable
with expected value \code{nrow(ds) * p[i]}. If \code{n_mis_stochastic =
FALSE}, the number of missing values will be deterministic. Normally, the
number of missing values for a column with missing values
\code{cols_mis[i]} is \code{round(nrow(ds) * p[i])}. Possible deviations
from this value, if any exists, are documented in Details.}

\item{x_stochastic}{Logical; should the odds be stochastic or deterministic.}

\item{add_realized_x}{Logical; if TRUE the realized odds for cols_mis will
be returned (as attribute).}

\item{...}{Further arguments passed to \code{cutoff_fun}.}

\item{miss_cols}{Deprecated, use \code{cols_mis} instead.}

\item{ctrl_cols}{Deprecated, use \code{cols_ctrl} instead.}

\item{stochastic}{Deprecated, use \code{n_mis_stochastic} instead.}
}
\value{
An object of the same class as \code{ds} with missing values.
}
\description{
Create missing at random (MAR) values using MAR1:x in a data frame or
a matrix
}
\details{
This function creates missing at random (MAR) values in the columns
specified by the argument \code{cols_mis}.
The probability for missing values is controlled by \code{p}.
If \code{p} is a single number, then the overall probability for a value to
be missing will be \code{p} in all columns of \code{cols_mis}.
(Internally \code{p} will be replicated to a vector of the same length as
\code{cols_mis}.
So, all \code{p[i]} in the following sections will be equal to the given
single number \code{p}.)
Otherwise, \code{p} must be of the same length as \code{cols_mis}.
In this case, the overall probability for a value to be missing will be
\code{p[i]} in the column \code{cols_mis[i]}.
The position of the missing values in \code{cols_mis[i]} is controlled by
\code{cols_ctrl[i]}.
The following procedure is applied for each pair of \code{cols_ctrl[i]} and
\code{cols_mis[i]} to determine the positions of missing values:

At first, the rows of \code{ds} are divided into two groups.
Therefore, the \code{cutoff_fun} calculates a cutoff value for
\code{cols_ctrl[i]} (via \code{cutoff_fun(ds[, cols_ctrl[i]], ...)}).
The group 1 consists of the rows, whose values in
\code{cols_ctrl[i]} are below the calculated cutoff value.
If the so defined group 1 is empty, the rows that have a value equal to the
cutoff value will be added to this group (otherwise, these rows will
belong to group 2).
The group 2 consists of the remaining rows, which are not part of group 1.
Now the probabilities for the rows in the two groups are set in the way
that the odds are 1:x against a missing value in \code{cols_mis[i]} for the
rows in group 1 compared to the rows in group 2.
That means, the probability for a value to be missing in group 1 divided by
the probability for a value to be missing in group 2 equals 1 divided
by x.
For example, for two equal sized groups 1 and 2, ideally the number of NAs in
group 1 divided by the number of NAs in group 2 should equal 1 divided by x.
But there are some restrictions, which can lead to some deviations from the
odds 1:x (see below).

If \code{x_stochastic} and \code{n_mis_stochastic} are false (the default),
then exactly \code{round(nrow(ds) * p[i])} values will be set \code{NA} in
column \code{cols_mis[i]}.
To achieve this, it is possible that the true odds differ from 1:x.
The number of observations that are deleted in group 1 and group 2 are
chosen to minimize the absolute difference between the realized odds and 1:x.
Furthermore, if \code{round(nrow(ds) * p[i])} == 0, then no missing value
will be created in \code{cols_mis[i]}.

If \code{x_stochastic} is true, the rows from the two groups will get
sampling weights proportional to 1 (group 1) and x (group 2). If
\code{n_mis_stochastic} is false, these weights are given to
\code{\link{sample}} via the argument \code{prob} and exactly
\code{round(nrow(ds) * p[i])} values will be set \code{NA}. If
\code{n_mis_stochastic} is true, the sampling weights will be scaled and
compared to uniform random numbers. The scaling is done in such a way to get
expected \code{nrow(ds) * p[i]} missing values in \code{cols_mis[i]}.

If \code{p} is high and \code{x} is too high or too low, it is possible that
the odds 1:x and the proportion of missing values \code{p} cannot be
realized together.
For example, if \code{p[i]} = 0.9, then a maximum of \code{x} = 1.25 is
possible (assuming that  exactly 50 \% of the values are below and 50 \% of
the values are above the cutoff value in \code{cols_ctrl[i]}).
If a combination of \code{p} and \code{x} that cannot be realized together
is given to \code{delete_MAR_1_to_x}, then a warning will be generated and
\code{x} will be adjusted in such a way that \code{p} can be realized as
given to the function. The warning can be silenced by setting the option
\code{missMethods.warn.too.high.p} to false.

The argument \code{add_realized_x} controls whether the x of the realized
odds are added to the return value or not.
If \code{add_realized_x = TRUE}, then the realized x values for all
\code{cols_mis} will be added as an attribute to the returned object.
For \code{x_stochastic = TRUE} these realized x will differ from the given
\code{x} most of the time and will change if the function is rerun without
setting a seed.
For \code{x_stochastic = FALSE}, it is also possible that the realized odds
differ (see above). However, the realized odds will be constant over multiple
runs.
}
\section{Treatment of factors}{


If \code{ds[, cols_ctrl[i]]} is an unordered factor, then the concept of a
cutoff value is not meaningful and cannot be applied.
Instead, a combinations of the levels of the unordered factor is searched that
\itemize{
\item{guarantees at least a proportion of \code{prop} rows are in group 1}
\item{minimize the difference between \code{prop} and the proportion of
rows in group 1.}
}
This can be seen as a binary search problem, which is solved by the solver
from the package \code{lpSolve}, if \code{use_lpSolve = TRUE}.
If \code{use_lpSolve = FALSE}, a very simple heuristic is applied.
The heuristic only guarantees that at least a proportion of \code{prop} rows
are in group 1.
The choice \code{use_lpSolve = FALSE} is not recommend and should only be
considered, if the solver of lpSolve fails.

If \code{ordered_as_unordered = TRUE}, then ordered factors will be treated
like unordered factors and the same binary search problem will be solved for
both types of factors.
If \code{ordered_as_unordered = FALSE} (the default), then ordered factors
will be grouped via \code{cutoff_fun} as described in Details.
}

\examples{
ds <- data.frame(X = 1:20, Y = 101:120)
delete_MAR_1_to_x(ds, 0.2, "X", "Y", 3)
# beware of small datasets and x_stochastic = FALSE
attr(delete_MAR_1_to_x(ds, 0.4, "X", "Y", 3, add_realized_x = TRUE), "realized_x")
attr(delete_MAR_1_to_x(ds, 0.4, "X", "Y", 4, add_realized_x = TRUE), "realized_x")
attr(delete_MAR_1_to_x(ds, 0.4, "X", "Y", 5, add_realized_x = TRUE), "realized_x")
attr(delete_MAR_1_to_x(ds, 0.4, "X", "Y", 7, add_realized_x = TRUE), "realized_x")
# p = 0.4 and 20 values -> 8 missing values, possible combinations:
# either 6 above 2 below (x = 3) or
# 7 above and 1 below (x = 7)
# Too high combination of p and x:
tryCatch(delete_MAR_1_to_x(ds, 0.9, "X", "Y", 3), warning = function(w) w)
}
\references{
Santos, M. S., Pereira, R. C., Costa, A. F., Soares, J. P.,
  Santos, J., & Abreu, P. H. (2019). Generating Synthetic Missing Data: A
  Review by Missing Mechanism. \emph{IEEE Access}, 7, 11651-11667
}
\seealso{
\code{\link{delete_MNAR_1_to_x}}

Other functions to create MAR: 
\code{\link{delete_MAR_censoring}()},
\code{\link{delete_MAR_one_group}()},
\code{\link{delete_MAR_rank}()}
}
\concept{functions to create MAR}

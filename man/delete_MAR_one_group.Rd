% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/delete_one_group.R
\name{delete_MAR_one_group}
\alias{delete_MAR_one_group}
\title{Create MAR values by deleting values in one of two groups}
\usage{
delete_MAR_one_group(
  ds,
  p,
  cols_mis,
  cols_ctrl,
  cutoff_fun = median,
  prop = 0.5,
  use_lpSolve = TRUE,
  ordered_as_unordered = FALSE,
  n_mis_stochastic = FALSE,
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

\item{...}{Further arguments passed to \code{cutoff_fun}.}

\item{miss_cols}{Deprecated, use \code{cols_mis} instead.}

\item{ctrl_cols}{Deprecated, use \code{cols_ctrl} instead.}

\item{stochastic}{Deprecated, use \code{n_mis_stochastic} instead.}
}
\value{
An object of the same class as \code{ds} with missing values.
}
\description{
Create missing at random (MAR) values by deleting values in one of two
groups in a data frame or a matrix
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
\code{cols_ctrl[i]} (via \code{cutoff_fun(ds[, cols_ctrl[i]], ...)}.
The group 1 consists of the rows, whose values in
\code{cols_ctrl[i]} are below the calculated cutoff value.
If the so defined group 1 is empty, the rows that are equal to the
cutoff value will be added to this group (otherwise, these rows will
belong to group 2).
The group 2 consists of the remaining rows, which are not part of group 1.
Now one of these two groups is chosen randomly.
In the chosen group, values are deleted in \code{cols_mis[i]}.
In the other group, no missing values will be created in \code{cols_mis[i]}.

If \code{p} is too high, it is possible that a group contains not enough
objects to reach \code{nrow(ds) * p} missing values. In this case, \code{p}
is reduced to the maximum possible value (given the (random) group with
missing data) and a warning is given. Obviously this case will occur
regularly, if \code{p > 0.5}. Therefore, this function should normally not be
called with \code{p > 0.5}. However, this can occur for smaller values
of \code{p}, too (depending on the grouping). The warning can be silenced by
setting the option \code{missMethods.warn.too.high.p} to false.
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
delete_MAR_one_group(ds, 0.2, "X", "Y")
}
\references{
Santos, M. S., Pereira, R. C., Costa, A. F., Soares, J. P.,
  Santos, J., & Abreu, P. H. (2019). Generating Synthetic Missing Data: A
  Review by Missing Mechanism. \emph{IEEE Access}, 7, 11651-11667
}
\seealso{
\code{\link{delete_MNAR_one_group}}

Other functions to create MAR: 
\code{\link{delete_MAR_1_to_x}()},
\code{\link{delete_MAR_censoring}()},
\code{\link{delete_MAR_rank}()}
}
\concept{functions to create MAR}

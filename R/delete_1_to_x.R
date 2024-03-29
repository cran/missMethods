# the workhorse for delete_MAR_1_to_x and delete_MNAR_1_to_x
delete_1_to_x <- function(ds, p, cols_mis, cols_ctrl, x,
                          cutoff_fun = median,
                          prop = 0.5, use_lpSolve = TRUE,
                          ordered_as_unordered = FALSE,
                          n_mis_stochastic = FALSE,
                          x_stochastic = FALSE,
                          add_realized_x = FALSE,
                          warn_p = getOption("missMethods.warn.too.high.p"),
                          ...) {

  # General checking of arguments is done in delete_values().
  # Only special cases are checked here.

  # match cutoff_fun
  cutoff_fun <- match.fun(cutoff_fun)

  # check x
  if (length(x) != 1L || !is.numeric(x)) {
    stop("x must be a single number")
  } else if (x <= 0 || is.infinite(x)) {
    stop("x must be greater than 0 and finite")
  }

  # Check x_stochastic
  stopifnot(is.logical(x_stochastic), length(x_stochastic) == 1L)
  if (!x_stochastic && n_mis_stochastic) {
    warning(
      "x_stochastic is set to TRUE because x_stochastic = FALSE",
      " is only meaningful for n_mis_stochastic = FALSE.",
      " If you want x_stochastic = FALSE, set n_mis_stochastic = FALSE, which is",
      " TRUE right now."
    )
    x_stochastic <- TRUE
  }


  # create missing values -----------------------
  n <- nrow(ds)
  true_odds <- numeric(length(cols_mis))
  for (i in seq_along(cols_mis)) {
    groups <- find_groups(
      ds[, cols_ctrl[i], drop = TRUE], cutoff_fun, prop, use_lpSolve,
      ordered_as_unordered, ...
    )
    if (is.null(groups$g2)) {
      warning("column ", cols_ctrl[i], " is constant, effectively MCAR")
      na_indices <- get_NA_indices(n_mis_stochastic, n = nrow(ds), p = p[i])
    } else if (x_stochastic) {
      prob <- rep(1, nrow(ds))
      prob[groups$g2] <- x
      na_indices <- get_NA_indices(n_mis_stochastic, nrow(ds), p = p[i], prob = prob)
    } else if (!n_mis_stochastic) {
      # calculate p_mis for group 1 and group 2
      nr_g1 <- length(groups$g1)
      nr_g2 <- length(groups$g2)
      p_mis_g1 <- p[i] * n / (nr_g1 + nr_g2 * x)
      p_mis_g2 <- p[i] * n * x / (nr_g1 + nr_g2 * x)
      # check if p_mis_g1 or p_mis_g2 is out of range (>1)
      if (p_mis_g2 > 1) {
        p_mis_g2 <- 1 # setting x = x_max results in p_mis_g2 = 1
        p_mis_g1 <- (p[i] * n - nr_g2) / nr_g1
        x_max <- p_mis_g2 / p_mis_g1
        if (warn_p) {
          warning(
            "p (or x) is too high; x is set to the maximum possible value (", x_max,
            ") to get expected n * p missing values"
          )
        }

      } else if (p_mis_g1 > 1) {
        p_mis_g1 <- 1
        p_mis_g2 <- (p[i] * n - nr_g1) / nr_g2
        x_min <- p_mis_g2 / p_mis_g1
        if (warn_p) {
          warning(
            "p is too high or x to low; x is set to the minimum possible value (", x_min,
            ") to get expected n * p missing values"
          )
        }

      }

      # delete values
      if (n_mis_stochastic) { # n_mis_stochastic = TRUE ------------------
        na_indices_g1 <- get_NA_indices(n_mis_stochastic, p = p_mis_g1, indices = groups$g1)
        na_indices_g2 <- get_NA_indices(n_mis_stochastic, p = p_mis_g2, indices = groups$g2)
      } else { # n_mis_stochastic = FALSE ------------------
        n_mis <- round(p[i] * n)
        n_mis_g1 <- calc_n_mis_g1(nr_g1, p_mis_g1, nr_g2, n_mis, x)
        n_mis_g2 <- n_mis - n_mis_g1

        # sample NA indices
        na_indices_g1 <- get_NA_indices(n_mis_stochastic, n_mis = n_mis_g1, indices = groups$g1)
        na_indices_g2 <- get_NA_indices(n_mis_stochastic, n_mis = n_mis_g2, indices = groups$g2)
      }
      na_indices <- c(na_indices_g1, na_indices_g2)
    } else {
      stop("something went wrong. Please contact maintainer.")
    }
    ds[na_indices, cols_mis[i]] <- NA
    true_odds[i] <- sum(na_indices %in% groups$g1) * length(groups$g2) /
      (length(groups$g1) * sum(na_indices %in% groups$g2))
  }

  if (add_realized_x) {
    realized_x <- 1 / true_odds
    names(realized_x) <- cols_mis
    return(structure(ds, realized_x = realized_x))
  }
  ds
}


check_cols_ctrl_1_to_x <- function(ds, cols_ctrl) {
  # check if cols_ctrl are numeric or ordered factor
  cols_prob <- integer(0)
  for (k in seq_along(cols_ctrl)) {
    if (!(is.ordered(ds[, cols_ctrl[k], drop = TRUE]) |
      is.numeric(ds[, cols_ctrl[k], drop = TRUE]))) {
      cols_prob <- c(cols_prob, cols_ctrl[k])
    }
  }
  if (length(cols_prob) > 0L) {
    stop(
      "all cols_ctrl must be numeric or ordered factors;\n",
      "problematic column(s): ",
      paste(cols_prob, collapse = ", ")
    )
  }
  TRUE
}



#' Create MAR values using MAR1:x
#'
#' Create missing at random (MAR) values using MAR1:x in a data frame or
#' a matrix
#'
#' @template delete
#' @template delete-stochastic
#' @template MAR
#' @template factor-grouping
#'
#' @details
#' At first, the rows of \code{ds} are divided into two groups.
#' Therefore, the \code{cutoff_fun} calculates a cutoff value for
#' \code{cols_ctrl[i]} (via \code{cutoff_fun(ds[, cols_ctrl[i]], ...)}).
#' The group 1 consists of the rows, whose values in
#' \code{cols_ctrl[i]} are below the calculated cutoff value.
#' If the so defined group 1 is empty, the rows that have a value equal to the
#' cutoff value will be added to this group (otherwise, these rows will
#' belong to group 2).
#' The group 2 consists of the remaining rows, which are not part of group 1.
#' Now the probabilities for the rows in the two groups are set in the way
#' that the odds are 1:x against a missing value in \code{cols_mis[i]} for the
#' rows in group 1 compared to the rows in group 2.
#' That means, the probability for a value to be missing in group 1 divided by
#' the probability for a value to be missing in group 2 equals 1 divided
#' by x.
#' For example, for two equal sized groups 1 and 2, ideally the number of NAs in
#' group 1 divided by the number of NAs in group 2 should equal 1 divided by x.
#' But there are some restrictions, which can lead to some deviations from the
#' odds 1:x (see below).
#'
#' If \code{x_stochastic} and \code{n_mis_stochastic} are false (the default),
#' then exactly \code{round(nrow(ds) * p[i])} values will be set \code{NA} in
#' column \code{cols_mis[i]}.
#' To achieve this, it is possible that the true odds differ from 1:x.
#' The number of observations that are deleted in group 1 and group 2 are
#' chosen to minimize the absolute difference between the realized odds and 1:x.
#' Furthermore, if \code{round(nrow(ds) * p[i])} == 0, then no missing value
#' will be created in \code{cols_mis[i]}.
#'
#' If \code{x_stochastic} is true, the rows from the two groups will get
#' sampling weights proportional to 1 (group 1) and x (group 2). If
#' \code{n_mis_stochastic} is false, these weights are given to
#' \code{\link{sample}} via the argument \code{prob} and exactly
#' \code{round(nrow(ds) * p[i])} values will be set \code{NA}. If
#' \code{n_mis_stochastic} is true, the sampling weights will be scaled and
#' compared to uniform random numbers. The scaling is done in such a way to get
#' expected \code{nrow(ds) * p[i]} missing values in \code{cols_mis[i]}.
#'
#' If \code{p} is high and \code{x} is too high or too low, it is possible that
#' the odds 1:x and the proportion of missing values \code{p} cannot be
#' realized together.
#' For example, if \code{p[i]} = 0.9, then a maximum of \code{x} = 1.25 is
#' possible (assuming that  exactly 50 \% of the values are below and 50 \% of
#' the values are above the cutoff value in \code{cols_ctrl[i]}).
#' If a combination of \code{p} and \code{x} that cannot be realized together
#' is given to \code{delete_MAR_1_to_x}, then a warning will be generated and
#' \code{x} will be adjusted in such a way that \code{p} can be realized as
#' given to the function. The warning can be silenced by setting the option
#' \code{missMethods.warn.too.high.p} to false.
#'
#' The argument \code{add_realized_x} controls whether the x of the realized
#' odds are added to the return value or not.
#' If \code{add_realized_x = TRUE}, then the realized x values for all
#' \code{cols_mis} will be added as an attribute to the returned object.
#' For \code{x_stochastic = TRUE} these realized x will differ from the given
#' \code{x} most of the time and will change if the function is rerun without
#' setting a seed.
#' For \code{x_stochastic = FALSE}, it is also possible that the realized odds
#' differ (see above). However, the realized odds will be constant over multiple
#' runs.
#'
#' @param x Numeric with length one (0 < x < \code{Inf}); odds are 1 to x for
#'   the probability of a value to be missing in group 1 against the probability
#'   of a value to be missing  in group 2 (see details).
#' @param cutoff_fun Function that calculates the cutoff values in the
#'   \code{cols_ctrl}.
#' @param add_realized_x Logical; if TRUE the realized odds for cols_mis will
#'   be returned (as attribute).
#' @param prop Numeric of length one; (minimum) proportion of rows in group 1
#'   (only used for unordered factors).
#' @param use_lpSolve Logical; should lpSolve be used for the determination of
#'   groups, if \code{cols_ctrl[i]} is an unordered factor.
#' @param ordered_as_unordered Logical; should ordered factors be treated as
#'   unordered factors.
#' @param x_stochastic Logical; should the odds be stochastic or deterministic.
#' @param ... Further arguments passed to \code{cutoff_fun}.
#'
#' @export
#' @seealso \code{\link{delete_MNAR_1_to_x}}
#'
#' @examples
#' ds <- data.frame(X = 1:20, Y = 101:120)
#' delete_MAR_1_to_x(ds, 0.2, "X", "Y", 3)
#' # beware of small datasets and x_stochastic = FALSE
#' attr(delete_MAR_1_to_x(ds, 0.4, "X", "Y", 3, add_realized_x = TRUE), "realized_x")
#' attr(delete_MAR_1_to_x(ds, 0.4, "X", "Y", 4, add_realized_x = TRUE), "realized_x")
#' attr(delete_MAR_1_to_x(ds, 0.4, "X", "Y", 5, add_realized_x = TRUE), "realized_x")
#' attr(delete_MAR_1_to_x(ds, 0.4, "X", "Y", 7, add_realized_x = TRUE), "realized_x")
#' # p = 0.4 and 20 values -> 8 missing values, possible combinations:
#' # either 6 above 2 below (x = 3) or
#' # 7 above and 1 below (x = 7)
#' # Too high combination of p and x:
#' tryCatch(delete_MAR_1_to_x(ds, 0.9, "X", "Y", 3), warning = function(w) w)
delete_MAR_1_to_x <- function(ds, p, cols_mis, cols_ctrl, x,
                              cutoff_fun = median,
                              prop = 0.5,
                              use_lpSolve = TRUE,
                              ordered_as_unordered = FALSE,
                              n_mis_stochastic = FALSE,
                              x_stochastic = FALSE,
                              add_realized_x = FALSE, ...,
                              miss_cols, ctrl_cols, stochastic) {
  do.call(delete_values, c(
    list(mech_type = "MAR_1_to_x"),
    as.list(environment()), list(...)
  ))
}


#' Create MNAR values using MNAR1:x
#'
#' Create missing not at random (MNAR) values using MNAR1:x in a data frame or
#' a matrix
#'
#'
#' @eval MNAR_documentation("1_to_x")
#'
#' @examples
#' delete_MNAR_1_to_x(ds, 0.2, "X", x = 3)
delete_MNAR_1_to_x <- function(ds, p, cols_mis, x,
                               cutoff_fun = median,
                               prop = 0.5,
                               use_lpSolve = TRUE,
                               ordered_as_unordered = FALSE,
                               n_mis_stochastic = FALSE,
                               x_stochastic = FALSE,
                               add_realized_x = FALSE, ...,
                               miss_cols, stochastic) {
  do.call(delete_values, c(
    list(mech_type = "MNAR_1_to_x"),
    as.list(environment()), list(...)
  ))
}

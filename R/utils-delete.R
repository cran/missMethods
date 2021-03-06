# checking arguments --------------------------------------

# args checking for all mechanisms
# normally called from check_delete_args_MCAR, check_delete_args_MAR or
# check_delete_args_MNAR
check_delete_args <- function(ds, p, cols_mis, stochastic) {
  # check ds ------------------------------------
  if (!is_df_or_matrix(ds)) {
    stop("ds must be a data.frame or a matrix")
  }

  # check p -------------------------------------
  if (is.numeric(p)) {
    if (length(p) != 1L && length(p) != length(cols_mis)) {
      stop("p must be of length 1 or length must equal cols_mis")
    } else {
      if (any(p < 0 | p > 1)) {
        stop("probabilties in p must be between 0 and 1")
      }
    }
  } else {
    stop("p must be numeric")
  }

  # check cols_mis -----------------------------
  if (is.numeric(cols_mis)) {
    if (any(cols_mis < 1 | cols_mis > ncol(ds))) {
      stop("indices in cols_mis must be in 1:ncol(ds)")
    }
  } else if (is.character(cols_mis)) {
    if (!all(cols_mis %in% colnames(ds))) {
      stop("all entries of cols_mis must be in colnames(ds)")
    }
  } else {
    stop("cols_mis must be a vector of column names or indices of ds")
  }

  if (anyDuplicated(cols_mis) != 0) {
    duplicated_cols <- unique(cols_mis[duplicated(cols_mis)])
    warning(
      "there are duplicates in cols_mis:\n", duplicated_cols,
      "\n this may result in a too high percentage of missing values"
    )
  }

  # check stochastic ----------------------------
  if (!is.logical(stochastic)) {
    stop("stochastic must be logical")
  } else if (length(stochastic) != 1L) {
    stop("the length of stochastic must be 1")
  }
}

check_delete_args_MCAR <- function(ds, p, cols_mis, stochastic, p_overall) {
  # general checking
  check_delete_args(
    ds = ds, p = p, cols_mis = cols_mis,
    stochastic = stochastic
  )

  # special case: p_overall
  if (!is.logical(p_overall) | length(p_overall) != 1L) {
    stop("p_overall must be logical of length 1")
  } else if (p_overall & !stochastic & length(p) != 1L) {
    stop("if p_overall = TRUE, then length(p) must be 1")
  }
}

check_delete_args_MAR <- function(ds, p, cols_mis, cols_ctrl, stochastic) {
  # general checking
  check_delete_args(
    ds = ds, p = p, cols_mis = cols_mis,
    stochastic = stochastic
  )


  # check cols_ctrl -----------------------------
  if (!is.null(cols_ctrl)) {
    if (is.numeric(cols_ctrl)) {
      if (any(cols_ctrl < 1 | cols_ctrl > ncol(ds))) {
        stop("indices in cols_ctrl must be in 1:ncol(ds)")
      }
    } else if (is.character(cols_ctrl)) {
      if (!all(cols_ctrl %in% colnames(ds))) {
        stop("all entries of cols_ctrl must be in colnames(ds)")
      }
    } else {
      stop("cols_ctrl must be a vector of column names or indices of ds")
    }
  }
  # no NA in cols_ctrl
  if (any(is.na(ds[, cols_ctrl]))) {
    stop("cols_ctrl must be completely observed; no NAs in ds[, cols_ctrl] allowed")
  }

  if (length(cols_mis) != length(cols_ctrl)) {
    stop("length(cols_mis) must equal length(cols_ctrl)")
  }

  # check if any ctrl_col is in cols_mis
  if (any(cols_ctrl %in% cols_mis)) {
    stop(
      "to ensure MAR no ctrl_col is allowed to be in cols_mis;\n",
      "problematic cols_ctrl:\n",
      paste(cols_ctrl[cols_ctrl %in% cols_mis], collapse = ", ")
    )
  }
}

check_delete_args_MNAR <- function(ds, p, cols_mis, stochastic) {
  # general checking
  check_delete_args(ds = ds, p = p, cols_mis = cols_mis, stochastic = stochastic)
  #  no NA in cols_mis
  if (any(is.na(ds[, cols_mis]))) {
    stop("cols_mis must be completely observed; no NAs in ds[, cols_mis] allowed")
  }
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

# finding groups ------------------------------------------

find_groups <- function(x, cutoff_fun, prop, use_lpSolve,
                        ordered_as_unordered, ...) {
  unique_x <- unique(x)
  nr_unique <- length(unique_x)
  if (nr_unique == 1) {
    warning("grouping not possible, because x is constant")
    groups <- list(g1 = seq_along(x), g2 = NULL)
  } else if (is.factor(x) && (ordered_as_unordered || !is.ordered(x))) {
    groups <- find_groups_by_prop(x, prop = prop, use_lpSolve)
  } else { # not an (unordered) factor and not constant
    cutoff_fun <- match.fun(cutoff_fun)
    groups <- find_groups_by_cutoff_val(x, cutoff_fun(x, ...))
  }
  groups
}

find_groups_by_cutoff_val <- function(x, cutoff_val) {
  # get rows below the cutoff value
  below <- x < cutoff_val
  # get rows greater than or equal to the cutoff value ("above")
  above <- which(!below)
  below <- which(below)
  # cure problem: no values below (but only if cols_ctrl[i] is not constant!)
  if ((length(below) == 0L) && length(unique(x)) != 1L) {
    # instead of only below, now accept below and equal
    below <- x <= cutoff_val
    above <- which(!below) # and above will be only above (not equal anymore)
    below <- which(below)
  }
  list(g1 = below, g2 = above)
}


find_groups_by_prop <- function(x, prop, use_lpSolve = TRUE) {
  ux <- unique(x) # order: first occurring in x
  nr_ux <- tabulate(match(x, ux))
  if (use_lpSolve) {
    if (requireNamespace("lpSolve", quietly = TRUE)) {
      solution <- lpSolve::lp(
        direction = "min", objective.in = nr_ux,
        const.mat = matrix(nr_ux, nrow = 1),
        const.dir = ">=",
        const.rhs = prop * length(x),
        all.bin = TRUE
      )
      if (solution$status == 0) {
        g1_ux <- ux[solution$solution > 0]
      } else {
        stop("lpSolve found no solution")
      }
    } else { # no lpSolve installed
      stop("Package \"lpSolve\" needed. Either install it or use \"use_lpSolve = FALSE\".")
    }
  } else {
    g1_ux <- cumsum(nr_ux) <= ceiling(prop * length(x))
    g1_ux <- ux[g1_ux]
  }
  # g1 should not be empty, but only if there is more than one different value in x
  if (length(g1_ux) == 0L && length(unique(x)) != 1) {
    g1_ux <- ux[1]
  }
  find_groups_by_values(x, g1_ux)
}

find_groups_by_values <- function(x, values) {
  g1 <- x %in% values
  g2 <- which(!g1)
  g1 <- which(g1)
  list(g1 = g1, g2 = g2)
}

# more helpers --------------------------------------------
adjust_p <- function(p, cols_mis) {
  if (length(p) == 1L) {
    p <- rep(p, length(cols_mis))
  }
  p
}

calc_nr_mis_g1 <- function(nr_g1, p_mis_g1,
                           nr_g2, nr_mis, x) {
  if (nr_mis == 0L) {
    nr_mis_g1 <- 0L
  } else if (nr_g2 == 0L) {
    nr_mis_g1 <- nr_mis
  } else {
    nr_mis_g1_ceil <- ceiling(nr_g1 * p_mis_g1)
    nr_mis_g1_floor <- floor(nr_g1 * p_mis_g1)
    odds_ceil <- nr_mis_g1_ceil / nr_g1 /
      ((nr_mis - nr_mis_g1_ceil) / nr_g2)
    odds_floor <- nr_mis_g1_floor / nr_g1 /
      ((nr_mis - nr_mis_g1_floor) / nr_g2)
    if (abs(1 / x - odds_ceil) < abs(1 / x - odds_floor)) {
      nr_mis_g1 <- nr_mis_g1_ceil
    } else {
      nr_mis_g1 <- nr_mis_g1_floor
    }
  }
  nr_mis_g1
}

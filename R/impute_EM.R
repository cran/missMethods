# maxit and criterion are passed to norm::em.norm!
# if EM does not converge: warning
get_EM_parameters <- function(ds, maxits = 1000, criterion = 0.0001) {
  check_for_packages("norm")

  ## Get EM parameters from norm (1. part) ------------------------------------
  # prelim only accepts matrices as input!
  input_for_norm <- norm::prelim.norm(as.matrix(ds))

  iterations <- tryCatch(
    utils::capture.output(EM_parm <- norm::em.norm(
      input_for_norm,
      showits = TRUE,
      maxits = maxits + 1,
      criterion = criterion
    )),
    error = function(cnd) { # if EM crashes, return error
      return(cnd)
    }
  )


  ## Check for EM problems ----------------------------------------------------
  # Check for crash inside of norm
  if (any(class(iterations) == "error")) {
    stop("The EM algorithm of norm produced an error; no imputation was done.",
      "\nError message from norm:", iterations,
      call. = FALSE
    )
  }

  # Check if number of iterations > maxits
  iterations <- iterations[2]
  iterations <- substr(
    iterations, regexpr("[[:digit:]]*\\.\\.\\.$", iterations),
    nchar(iterations) - 3
  )
  iterations <- as.integer(iterations)
  if (iterations > maxits) {
    warning(
      "EM did not converge with maxits = ", maxits,
      ". Some imputation values are maybe unreliable."
    )
  }

  ## Get EM parameters from norm (2. part) ------------------------------------
  EM_parm <- norm::getparam.norm(input_for_norm, EM_parm)

  structure(EM_parm, iterations = iterations)
}


#' EM imputation
#'
#' Impute missing values in a data frame or a matrix using parameters estimated
#' via EM
#'
#' @template impute
#'
#' @details
#'
#' At first parameters are estimated via [norm::em.norm()]. Then these
#' parameters are used in regression like models to impute the missing values.
#' If `stochachstic = FALSE`, the expected values (given the observed values and
#' the estimated parameters via EM) are imputed for the missing values of an
#' object. If `stochastic = TRUE`, residuals from a multivariate normal
#' distribution are added to these expected values.
#'
#' If all values in a row are `NA` or the required part of the covariance matrix
#' for the calculation of the expected values is not invertible, parts of the
#' estimated mean vector will be imputed. If `stochastic = TRUE`, residuals will
#' be added to these values. If `verbose = TRUE`, a message will be given for
#' these rows.
#'
#' @param stochastic Logical; see details.
#' @param maxits Maximum number of iterations for the EM, passed to
#'   [norm::em.norm()].
#' @param criterion If maximum relative difference in parameter estimates is
#'   below this threshold, the EM algorithm stops. Argument is directly passed
#'   to [norm::em.norm()].
#' @param verbose Should messages be given for special cases (see details)?
#'
#' @return The number of EM iterations are added as an attribute (`iterations`).
#'
#' @export
#'
#' @seealso
#' * [norm::em.norm()], which estimates the parameters
#' * [impute_expected_values()], which calculates the imputation values
#'
#'
#' @examples
#' ds_orig <- mvtnorm::rmvnorm(100, rep(0, 7))
#' ds_mis <- delete_MCAR(ds_orig, p = 0.2)
#' ds_imp <- impute_EM(ds_mis, stochastic = FALSE)
#' @md
impute_EM <- function(ds,
                      stochastic = TRUE,
                      maxits = 1000,
                      criterion = 0.0001,
                      verbose = FALSE) {
  EM_parm <- get_EM_parameters(ds, maxits = maxits, criterion = criterion)

  structure(
    impute_expected_values(ds,
      mu = EM_parm$mu,
      S = EM_parm$sigma,
      stochastic = stochastic,
      verbose = verbose
    ),
    iterations = attr(EM_parm, "iterations")
  )
}

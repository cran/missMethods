
test_that("get_EM_parameters() handles norm crashes", {
  expect_error(
    suppressWarnings(get_EM_parameters(data.frame(X = 1:2),
      maxit = factor("a")
    )),
    "The EM algorithm of norm produced an error; no imputation was done"
  )
})

test_that("get_EM_parameters() checks iterations", {
  expect_warning(
    get_EM_parameters(data.frame(X = 1:4, Y = c(NA, NA, NA, 2)), maxits = 2),
    "EM did not converge with maxits = 2."
  )
})


test_that("get_EM_parameters() returns correct values", {
  return_val <- get_EM_parameters(data.frame(X = 1:4, Y = c(1:3, NA)))
  expect_true(is.numeric(attr(return_val, "iterations", TRUE)))
  expect_equal(return_val$mu[1], mean(1:4))
  expect_equal(return_val$sigma[1, 1], var(1:4) * 3 / 4)
  expect_equal(return_val$mu[2], mean(1:4), tolerance = 0.1)
  expect_equal(
    return_val$sigma, matrix(1.25, 2, 2),
    tolerance = 0.1, check.attributes = FALSE
  )
})


test_that("impute_EM() works (basic test)", {
  expect_equal(
    impute_EM(data.frame(X = 1:4, Y = c(1:3, NA)), stochastic = FALSE),
    data.frame(X = 1:4, Y = 1:4),
    tolerance = 0.1, check.attributes = FALSE
  )

  expect_equal(
    impute_EM(data.frame(X = 1:4, Y = c(1:3, NA)), stochastic = TRUE),
    data.frame(X = 1:4, Y = 1:4),
    tolerance = 0.2, check.attributes = FALSE
  )
})

test_that("impute_EM() works with problematic Sigma", {
  ds_imp <- expect_message(
    impute_EM(data.frame(X = 1:5, Y = 11:15, Z = c(21:23, NA, NA)),
      stochastic = FALSE,
      verbose = TRUE
    ),
    "The missing values of following rows were imputed with (parts of) mu: 4, 5",
    fixed = TRUE,
    all = TRUE
  )
  expect_equal(ds_imp,
    data.frame(X = 1:5, Y = 11:15, Z = c(21:23, 22.99986, 22.99986)),
    tolerance = 1e-5, check.attributes = FALSE
  )
})


test_that("impute_EM() works (check output of 100 x 7 matrix)", {
  set.seed(123)
  ds_orig <- mvtnorm::rmvnorm(100, rep(0, 7))
  ds_mis <- delete_MCAR(ds_orig, p = 0.2)
  ds_imp <- impute_EM(ds_mis, stochastic = FALSE)
  ds_imp_stoch <- impute_EM(ds_mis, stochastic = TRUE)
  verify_output(test_path("test-EM-impute.txt"), {
    ds_imp
    ds_imp_stoch
  })
})

test_that("impute_EM() add iterations as attribute", {
  set.seed(123)
  ds_orig <- mvtnorm::rmvnorm(20, rep(0, 3))
  ds_mis <- delete_MCAR(ds_orig, p = 0.2)
  ds_imp <- impute_EM(ds_mis, stochastic = FALSE)
  expect_true(is.numeric(attr(ds_imp, "iterations", TRUE)))
})

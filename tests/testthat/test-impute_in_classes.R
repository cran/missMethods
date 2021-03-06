## impute_in_classes() --------------------------------------------------------
test_that("impute_in_classes() works (basic tests)", {
  expect_equal(
    impute_in_classes(data.frame(X = 1:5, Y = c(NA, 12:15)), "X",
      impute_mean,
      min_obs_per_col = 2
    ),
    data.frame(X = 1:5, Y = c(12.5, 12:15))
  )

  expect_equal(
    impute_in_classes(data.frame(X = c(1, 2, 2, 1, 2), Y = c(NA, 12:15)), "X",
      impute_sRHD,
      min_obs_per_col = 1
    ),
    data.frame(X = c(1, 2, 2, 1, 2), Y = c(14, 12:15))
  )
})

test_that("impute_in_classes() throws an error if cols_class is missing", {
  expect_error(
    impute_in_classes(df_XY_X_mis),
    "cols_class must be specified"
  )
})

test_that("impute_in_classes() pass on arguments to FUN", {
  expect_equal(
    impute_in_classes(data.frame(X = 1:5, Y = c(NA, 12:15)), "X",
      impute_mean,
      min_obs_per_col = 2, type = "total"
    ),
    data.frame(X = 1:5, Y = c(mean(c(1:3, 12, 13)), 12:15))
  )
})


test_that("impute_in_classes() adds imputation classes as attribute", {
  expect_equal(
    impute_in_classes(data.frame(X = 1:5, Y = c(NA, 12:15)), "X",
      impute_mean,
      min_obs_per_col = 2, add_imputation_classes = TRUE
    ),
    structure(data.frame(X = 1:5, Y = c(12.5, 12:15)),
      imputation_classes = list(
        `1_and_2_and_3` = 1:3,
        `4_and_5` = 4:5
      )
    )
  )
})

## impute_hot_deck_in_classes() -----------------------------------------------
test_that("impute_hot_deck_in_classes() works", {
  expect_equal(
    impute_hot_deck_in_classes(data.frame(X = c(1, 2, 2, 1, 2), Y = c(NA, 12:15)),
      "X",
      min_obs_per_col = 1
    ),
    data.frame(X = c(1, 2, 2, 1, 2), Y = c(14, 12:15))
  )

  expect_equal(
    impute_hot_deck_in_classes(data.frame(
      X = c(rep(1, 100), 2, 2),
      Y = c(NA, 102:202),
      Z = c(rep(NA, 99), 300:302)
    ),
    "X",
    type = "sim_comp", min_obs_per_col = 1
    ),
    data.frame(
      X = c(rep(1, 100), 2, 2),
      Y = c(200, 102:202),
      Z = c(rep(300, 99), 300:302)
    )
  )
})

test_that("impute_hot_deck_in_classes() collapses classes for low donor_limit", {
  ds_imp <- impute_hot_deck_in_classes(data.frame(
    X = c(rep(1, 3), rep(2, 3)),
    Y = c(NA, NA, 11L, rep(12L, 3))
  ),
  "X",
  donor_limit = 1, add_imputation_classes = TRUE
  )
  expect_identical(
    attr(ds_imp, "imputation_classes"),
    list(`1_and_2` = 1:6)
  )
  expect_true((ds_imp[1, "Y"] == 11L || ds_imp[1, "Y"] == 12L))
})

test_that("impute_hot_deck_in_classes() does not collapse classes for high donor_limt", {
  ds_imp <- impute_hot_deck_in_classes(data.frame(
    X = c(rep(1, 3), rep(2, 3)),
    Y = c(NA, NA, 11L, rep(12L, 3))
  ),
  "X",
  donor_limit = 2, add_imputation_classes = TRUE
  )
  expect_identical(
    attr(ds_imp, "imputation_classes"),
    list(`1` = 1:3, `2` = 4:6)
  )
  expect_true((ds_imp[1, "Y"] == 11L && ds_imp[2, "Y"] == 11L))
})

## Helpers --------------------------------------------------------------------
test_that("find_classes() check for NA in ds[, cols_class]", {
  expect_error(find_classes(matrix(c(NA, 1), ncol = 2), 1),
    "No NAs in ds[, cols_class] allowed",
    fixed = TRUE
  )
})

test_that("find_classes() works with breaks = Inf and data frames", {
  expect_identical(
    find_classes(df_classes_test, integer()),
    list(everything = 1:5)
  )

  expect_identical(
    find_classes(df_classes_test, "X", breaks = Inf),
    list(`1` = 1:2, `2` = 3:5)
  )

  expect_identical(
    find_classes(df_classes_test, "Y", breaks = Inf),
    list(`3` = c(2:3, 5L), `4` = 4L, `5` = 1L)
  )

  expect_identical(
    find_classes(df_classes_test, c("X", "Y"), breaks = Inf),
    list(`1.3` = 2L, `1.5` = 1L, `2.3` = c(3L, 5L), `2.4` = 4L)
  )
})

test_that("find_classes() works with matrices", {
  expect_identical(
    find_classes(matrix_classes_test, "X"),
    find_classes(df_classes_test, "X")
  )

  expect_identical(
    find_classes(matrix_classes_test, "Y"),
    find_classes(df_classes_test, "Y")
  )

  expect_identical(
    find_classes(matrix_classes_test, c("X", "Y")),
    find_classes(df_classes_test, c("X", "Y"))
  )

  expect_identical(
    find_classes(matrix_classes_test, 1:2),
    find_classes(df_classes_test, c("X", "Y"))
  )
})

test_that("find_classes() works with tibbles", {
  expect_identical(
    find_classes(tbl_classes_test, "X"),
    find_classes(df_classes_test, "X")
  )

  expect_identical(
    find_classes(tbl_classes_test, "Y"),
    find_classes(df_classes_test, "Y")
  )

  expect_identical(
    find_classes(tbl_classes_test, c("X", "Y")),
    find_classes(df_classes_test, c("X", "Y"))
  )

  expect_identical(
    find_classes(tbl_classes_test, 1:2),
    find_classes(df_classes_test, c("X", "Y"))
  )
})

test_that("find_classes() argument breaks works", {
  expect_identical(
    find_classes(df_classes_test, "Y", breaks = 2),
    list(`(3,4]` = c(2L, 3L, 4L, 5L), `(4,5]` = 1L)
  )

  expect_identical(
    find_classes(tbl_classes_test, "Y", breaks = 2),
    find_classes(matrix_classes_test, "Y", breaks = 2)
  )

  expect_identical(
    find_classes(tbl_classes_test, "Y", breaks = 2),
    find_classes(df_classes_test, "Y", breaks = 2)
  )
})

test_that("cut_vector() works with numeric vectors", {

  # Inf breaks
  expect_identical(
    cut_vector(1:10, Inf),
    as.factor(1:10)
  )

  # finite breaks
  expect_identical(
    cut_vector(1:10, 3, use_quantiles = FALSE),
    cut(1:10, 3, ordered_result = TRUE)
  )

  expect_identical(
    length(levels(cut_vector(1:10, 3, use_quantiles = FALSE))),
    3L
  )

  expect_identical(
    cut_vector(1:10, 3, use_quantiles = TRUE),
    cut(1:10,
      breaks = quantile(1:10, seq(from = 0, to = 1, length.out = 4)),
      include.lowest = TRUE, ordered_result = TRUE
    )
  )

  expect_identical(
    length(levels(cut_vector(1:10, 3, use_quantiles = TRUE))),
    3L
  )
})

test_that("cut_vector() works with unordered factor vectors", {
  test_f <- factor(letters[c(1:5, 2:5, 1, 1, 3:4)], ordered = FALSE)

  expect_identical(
    cut_vector(test_f, Inf),
    test_f
  )

  expect_identical(
    cut_vector(test_f, 3),
    factor(c(
      "a_and_c", "b_and_e", "a_and_c", "d", "b_and_e", "b_and_e",
      "a_and_c", "d", "b_and_e", "a_and_c", "a_and_c", "a_and_c", "d"
    ))
  )
})

test_that("cut_vector() works with ordered factor vectors", {
  test_f <- factor(letters[c(1:5, 2:5, 1, 1, 3:4)], ordered = TRUE)

  expect_identical(
    cut_vector(test_f, Inf),
    test_f
  )

  expect_identical(
    cut_vector(test_f, 3),
    ordered(c(
      "a", "b_and_c", "b_and_c", "e_and_d", "e_and_d", "b_and_c", "b_and_c",
      "e_and_d", "e_and_d", "a", "a", "b_and_c", "e_and_d"
    ))
  )
})

test_that("are_classes_okay() works with donor_limit", {
  test_df <- data.frame(X = 1:100, Y = 101:200)
  test_df[1:10, "X"] <- NA
  expect_identical(
    are_classes_okay(test_df, list(1:15, 16:100), donor_limit = Inf, dl_type = "cols_seq"),
    c(TRUE, TRUE)
  )

  expect_identical(
    are_classes_okay(test_df, list(1:15, 16:100), donor_limit = 2, dl_type = "cols_seq"),
    c(TRUE, TRUE)
  )

  expect_identical(
    are_classes_okay(test_df, list(1:15, 16:100), donor_limit = 1, dl_type = "cols_seq"),
    c(FALSE, TRUE)
  )

  expect_identical(
    are_classes_okay(test_df, list(1:12, 16:100), donor_limit = 2, dl_type = "cols_seq"),
    c(FALSE, TRUE)
  )
})

test_that("are_classes_okay() works with min_objs_in_class", {
  test_df <- data.frame(X = 1:100, Y = 101:200)
  test_df[1:10, "X"] <- NA
  expect_identical(
    are_classes_okay(test_df, list(1:15, 16:100), min_objs_in_class = 10),
    c(TRUE, TRUE)
  )

  expect_identical(
    are_classes_okay(test_df, list(1:15, 16:100), min_objs_in_class = 16),
    c(FALSE, TRUE)
  )

  expect_identical(
    are_classes_okay(test_df, list(1:15, 16:100), min_objs_in_class = 99),
    c(FALSE, FALSE)
  )
})


test_that("are_classes_okay() works with min_obs_comp", {
  expect_identical(
    are_classes_okay(data.frame(X = 1:2, Y = c(NA, 1)),
      list(1, 2),
      min_obs_comp = 1
    ),
    c(FALSE, TRUE)
  )

  expect_identical(
    are_classes_okay(data.frame(X = 1:2, Y = c(NA, 2)),
      list(1, 2),
      min_obs_comp = 0
    ),
    c(TRUE, TRUE)
  )

  expect_identical(
    are_classes_okay(data.frame(X = 1:5, Y = c(NA, 12:15)),
      list(1:3, 4:5),
      min_obs_comp = 2
    ),
    c(TRUE, TRUE)
  )
})

test_that("are_classes_okay() works with min_obs_per_col", {
  expect_identical(
    are_classes_okay(data.frame(X = 1:2, Y = c(NA, 1)),
      list(1, 2),
      min_obs_per_col = 1
    ),
    c(FALSE, TRUE)
  )

  expect_identical(
    are_classes_okay(data.frame(X = 1:2, Y = c(NA, 2)),
      list(1, 2),
      min_obs_per_col = 0
    ),
    c(TRUE, TRUE)
  )

  expect_identical(
    are_classes_okay(data.frame(X = 1:5, Y = c(NA, 12:15)),
      list(1:3, 4:5),
      min_obs_per_col = 2
    ),
    c(TRUE, TRUE)
  )

  expect_identical(
    are_classes_okay(data.frame(X = 1:5, Y = c(NA, NA, 13:15)),
      list(1:3, 4:5),
      min_obs_per_col = 2
    ),
    c(FALSE, TRUE)
  )
})


test_that("merge_lvls() works with unorderd factors", {
  test_f <- factor(letters[c(1:5, 2:5, 1, 1, 3:4)], ordered = FALSE)
  levels(test_f) <- merge_lvls(test_f, NULL)
  expect_identical(levels(test_f), c("a", "b_and_e", "c", "d"))
  levels(test_f) <- merge_lvls(test_f, "d")
  expect_identical(levels(test_f), c("d_and_a", "b_and_e", "c"))
})


test_that("merge_lvls() works with orderd factors", {
  test_f <- factor(letters[c(1:5, 2:5, 1, 1, 3:4)], ordered = TRUE)
  levels(test_f) <- merge_lvls(test_f, NULL)
  expect_identical(levels(test_f), c("a", "b_and_c", "d", "e"))
  levels(test_f) <- merge_lvls(test_f, "a")
  expect_identical(levels(test_f), c("a_and_b_and_c", "d", "e"))
  levels(test_f) <- merge_lvls(test_f, "e")
  expect_identical(levels(test_f), c("a_and_b_and_c", "e_and_d"))
  levels(test_f) <- merge_lvls(test_f)
  expect_identical(levels(test_f), c("e_and_d_and_a_and_b_and_c"))
  expect_error(merge_lvls(test_f), "merging only possible for two or more levels")
})

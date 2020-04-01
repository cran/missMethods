# missMethods 0.1.0

## New functions

Functions for the creation of missing values:

* `delete_MAR_censoring()` and `delete_MNAR_censoring()` create missing (not) at random values using a censoring mechanism
* `delete_MAR_one_group()` and `delete_MNAR_one_group()` create missing (not) at random values by deleting values in one of two groups
* `delete_MAR_rank()` and `delete_MNAR_rank()` create missing (not) at random values using a ranking mechanism

Functions for evaluation:

* `evaluate_imputation_parameters()` compares estimated parameters after imputation to true parameters

## New features

* `delete_MAR_1_to_x()` and `delete_MNAR_1_to_x()` can now handle (unordered) factors
* new criteria for `evaluate_imputed_values()` and `evaluate_parameters()`: six forms of NRMSE, nr_equal, nr_NA and precision
* `evaluate_imputed_values()`: add argument `which_cols` to select columns for evaluation. 

## Miscellaneous

* all `delete_` functions now take the same first three arguments: `ds`, `p`, `miss_cols`
* package now on GitHub and CRAN

# missMethods 0.0.1

## Implemented functions

Functions for the creation of missing values:

* `delete_MCAR()` creates missing completely at random values in different ways
* `delete_MAR_1_to_x()` and `delete_MNAR_1_to_x()` create missing (not) at random values using a 1:x mechanism

Functions for imputation:

* `impute_mean()`, `impute_median()`, `impute_mode()` different forms of mean, median and mode imputation
* `impute_sRHD()` simple Random Hot-Deck imputation with the possibility to specify a donor limit
* `apply_imputation()` a function to apply aggregating functions for imputation

Functions for evaluation:

* `evaluate_imputed_values()` compares imputed to true values
* `evaluate_parameters()` compares estimated to true parameters

Miscellaneous:

* `median.factor()` computes medians for ordered factors

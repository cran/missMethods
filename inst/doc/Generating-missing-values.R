## ---- include = FALSE---------------------------------------------------------
knitr::opts_chunk$set(
  collapse = TRUE,
  comment = "#>",
  fig.width = 7, 
  fig.height = 4, 
  fig.align = "center"
)

## ----setup--------------------------------------------------------------------
library(missMethods)
library(ggplot2)

set.seed(123)

make_simple_MDplot <- function(ds_comp, ds_mis) {
  ds_comp$missX <- is.na(ds_mis$X)
  ggplot(ds_comp, aes(x = X, y = Y, col = missX)) +
    geom_point()
}

# generate complete data frame
ds_comp <- data.frame(X = rnorm(100), Y = rnorm(100))

## ----MCAR---------------------------------------------------------------------
ds_mcar <- delete_MCAR(ds_comp, 0.3, "X")
make_simple_MDplot(ds_comp, ds_mcar)

## ----MAR censoring------------------------------------------------------------
ds_mar <- delete_MAR_censoring(ds_comp, 0.3, "X", cols_ctrl = "Y")
make_simple_MDplot(ds_comp, ds_mar)

## ----MAR_1_to_2---------------------------------------------------------------
# x = 2
ds_mar <- delete_MAR_1_to_x(ds_comp, 0.3, "X", cols_ctrl = "Y", x = 2)
make_simple_MDplot(ds_comp, ds_mar)

## ----MAR_1_to_10--------------------------------------------------------------
# x = 10
ds_mar <- delete_MAR_1_to_x(ds_comp, 0.3, "X", cols_ctrl = "Y", x = 10)
make_simple_MDplot(ds_comp, ds_mar)

## ----MNAR censoring-----------------------------------------------------------
ds_mnar <- delete_MNAR_censoring(ds_comp, 0.3, "X")
make_simple_MDplot(ds_comp, ds_mnar)


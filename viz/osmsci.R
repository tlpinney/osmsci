# install.packages("DBI")
# install.packages("ggmap")
# install.packages("maps")
# install.packages("RPresto")
# install.packages("mapproj")


library(ggmap)
library(DBI)
library(tibble)
library(dplyr)

# helper functions
rad2deg <- function(rad) {(rad * 180) / (pi)}
deg2rad <- function(deg) {(deg * pi) / (180)}
tilex2loc <- function(n) { rad2deg(pi * n / 128 - pi) }
tiley2loc <- function(n) { rad2deg(2 * atan(exp(-2 * pi * n / 256 + pi )) - pi / 2) }

densityQuery <- function(con, sql) {
  res <- dbSendQuery(con, sql)
  h <- dbFetch(res, -1)
  h2 <- unlist(h$`_col0`[[1]])
  tiles <- names(h2)
  itiles <- as.integer(tiles)
  ytiles <- itiles %/% 255
  xtiles <- itiles %% 255
  xlocs <- tilex2loc(xtiles)
  ylocs <- tiley2loc(ytiles)
  density <- unname(h2)
  xtile <- itiles %% 256
  ytile <- itiles %/% 256
  d1tiles = 1:65536 - 1
  xmin <- tilex2loc(itiles %% 256)
  xmax <- tilex2loc((itiles + 1) %% 256)
  ymax <- tiley2loc(itiles %/% 256)
  ymin <- tiley2loc((itiles + 256) %/% 256)
  d <- unname(h2)

  tibble(d1tile = itiles, xmin = xmin, xmax = xmax, ymin = ymin, ymax = ymax, d = d)
}



# setup a connection

#con <- dbConnect(
#  RPresto::Presto(),
#  host='http://localhost',
#  port=8080,
#  user=Sys.getenv('USER'),
#  schema='default',
#  catalog='hive',
#  source='planet'
#)

# do a query over density 
#planetd <- densityQuery(con, 'select histogram(tile) from planet where type = \'node\'')

# set up the world data
#world <- map_data("world")

# run some plots

# ggplot() + geom_polygon(data = world, aes(x=long, y = lat, group = group), fill="grey") + geom_rect(data = noded %>% filter(xtile < 255 & d > 10000000) , aes(xmin=xmin, xmax=xmax, ymin=ymin, ymax=ymax, fill=d)) + coord_map("rectangular", par=c(0))

# ggplot() + geom_polygon(data = world, aes(x=long, y = lat, group = group), fill="grey") + geom_rect(data = noded %>% filter(xtile < 255) , aes(xmin=xmin, xmax=xmax, ymin=ymin, ymax=ymax, fill=d)) + coord_map("rectangular", par=c(0))




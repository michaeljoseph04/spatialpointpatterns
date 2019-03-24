#### Introduction to Spatial Point Pattern Analysis ####

#### Counting quadrants ### 

#### Load libraries ####
library(tidyverse)
library(spatstat)
library(sp)
library(rgdal)
library(RColorBrewer)

### Data Import and Cleaning ####

# Download collision csv file from Seattle Department of Transportation
# hosted on the City of Seattle GIS Open Data Portal at:
# http://data-seattlecitygis.opendata.arcgis.com/datasets/5b5c745e0f1f48e7a53acec63a0022ab_0
# The link to the csv I use can be supplied here instead of the filename, but as the file is
# consistently updated, I've downloaded a dataset from March of 2019 and used the file instead,
# which will work if this repo is downloaded.

link <- "https://opendata.arcgis.com/datasets/5b5c745e0f1f48e7a53acec63a0022ab_0.csv" #also provided in the data folder

collisions  <- read.csv(link, stringsAsFactors = FALSE)

# Change a misnamed column name in the csv
names <- colnames(collisions)
names[1] <-"X" 
colnames(collisions) <- names

# Select the collisions we want from the large dataset. We want collisions from 2018.
# We also want to eliminate any unplottable points, which are occasionally found
# within this dataset. 
# Also make the coordinates into a specifically spatial data set, by taking only the first
# columns. Other analyses might select other data.
collisions_coord <- collisions %>%
  select(x = X, y = Y, date = INCDATE) %>%
  mutate(year = substr(date, start = 1, stop = 4)) %>%
  mutate(month = substr(date, start = 6, stop = 7)) %>%
  mutate(day = substr(date, start = 9, stop = 10)) %>%
  arrange(year, month, day) %>%
  filter(year == "2018") %>%
  select(x, y)
collisions <- na.omit(collisions)

# Use spatstat to develop ppp points data. First get the extent of the data and then convert
# this to a window, which we use to convert the spatial data to a ppp.
collisions_coord_b <- bbox(as.matrix(collisions_coord))
wind <- as.owin(list(xrange=c(collisions_coord_b[1,1],collisions_coord_b[1,2]),
                     yrange=c(collisions_coord_b[2,1],collisions_coord_b[2,2])))
collisions_ppp <- as.ppp(collisions_coord, W = wind)

# Determine frequency in quadrants. The initial number of quadrants can be specified.
collision_quad <- quadratcount(collisions_ppp, nx=20, ny=20)

# Create a raster of the quadrant data for plotting outside of spatstat.
collision_raster <- raster(nrow=20, ncol=20)
collision_raster[]<-collision_quad

# Import shapefiles for plotting outside of spatstat.
seattle <- readOGR(dsn=".//data//", layer="seattle_boundaries")
seattle_arterials <- readOGR(dsn=".//data//", layer="seattle_arterials")

# Change the raster's extent to that of the coordinates, which we already have.
raster_extent <- extent(collisions_coord_b[1,1],
                  collisions_coord_b[1,2],
                  collisions_coord_b[2,1],
                  collisions_coord_b[2,2])
collision_raster@extent <- raster_extent

# Plot
pal_b <- rev(brewer.pal(n=10,name="Spectral"))

plot(collision_raster_2,
     main="Collisions per Quadrant in Seattle, 2018",
     col=pal_b,
     axes=FALSE)
plot(seattle, add=TRUE)
plot(seattle_arterials, col="grey25", add=TRUE)
## Spatial Point Patterns

*An Introduction to Spatial Point Pattern Analysis for urban systems analysts in R.*

As an urban planner and policy analyst, I have to do a lot of data analysis of spatial data. But there are few good introductions to the types of analyses which are common and useful, and how to go about them. This brief tutorial and the accompanying code should guide readers through some of this territory, especially for effective urban systems analysis.

Spatial point pattern analysis is a series of methods for understanding the nature of how events occur in space. I will not review many of the fundamental concepts and issues involved in understanding the relationship of points, but I will point out areas where a reader might find inflections in their analysis.

### Exploratory Data Analysis: Quadrant counts

Initially, counts of the frequency within a quadrant are useful for exploratory data analysis or EDA regarding the general spatial distribution of a dataset across a region.

First, we want to load the data, which is simply a set of coordinate points of traffic incidents in Seattle, dating back to 2004.
```
link <- "https://opendata.arcgis.com/datasets/5b5c745e0f1f48e7a53acec63a0022ab_0.csv"  #also provided in the data folder in the repo as collisions.csv
collisions  <- read.csv(link, stringsAsFactors = FALSE)

```
Next, we need to clean the data. There are some odd fields (the X field in particular), and select what we might need most. For this, we can use ddplyr and the tidy data approach to data wrangling:
```
names <- colnames(collisions)
names[1]<-"X"
colnames(collisions) <- names

collisions_coord <- collisions %>%
  select(x = X, y = Y, date = INCDATE) %>%
  mutate(year = substr(date, start = 1, stop = 4)) %>%
  mutate(month = substr(date, start = 6, stop = 7)) %>%
  mutate(day = substr(date, start = 9, stop = 10)) %>%
  arrange(year, month, day) %>%
  filter(year == "2018") %>%
  select(x, y)
collisions_coord <- na.omit(collisions)
```
After simply replacing some column names which were read incorrectly, we use ddplyr to wrangle the data. This involves four steps:
- Wrangling the column names further
- using *mutate* to isolate out the timespan we want from the collision dataset
- filtering for those years (we want all collisions from 2018)
- keeping only the x and y coordinates

At various points, we could have altered this selection process to retain some information, or filtered for many different things which are able to be found in the dataset (which are able to be found under the many columns). For that reason, I have selected very slowly and methodically, with a redundant call to arrange, just to keep things straight as the data is cleaned (many users may want to remove this redundant code). Ultimately, because our focus at the moment is simply the distribution of the events, we are now just focused on the coordinates of all of the recorded collisions in 2018.

A simple call to *plot* would display the information. But in order to analyze the data, we need to use the *spatstat* package. For this, we need to convert it these points to a *ppp* object. A relatively quick and dirty way of doing this for the purposes of EDA is to take the bounds of the dataset with the *sp* package's *bbox* function. A window is then created from these points, and the window passed to the *as.points* function which actually creates the points file.
```
collisions_coord_b <- bbox(as.matrix(collisions_coord))
wind <- as.owin(list(xrange=c(collisions_coord_b[1,1],collisions_coord_b[1,2]),
                     yrange=c(collisions_coord_b[2,1],collisions_coord_b[2,2])))
collisions_ppp <- as.ppp(collisions_coord, W = wind)
```
Now we use the *spatstat* library further for analysis of the count within quadrants, the number of which we specify.
```
collision_quad <- quadratcount(collisions_ppp, nx=20, ny=20)
```

This could be plotted directly, simply with a call like the following:
```
plot(collision_quad)
```
But I also want to exercise more control over the precise dimensions of the quadrants which we are looking at, for the purposes of better EDA. So instead of sticking with *spatstat* here, we will wlso used the *raster* library to create a raster of the quadrant data for plotting. Reasons will become clearer as we refine our exploration of the data.

To do this, we create a new raster and assign it the values determined by the *spatstat* *quadratcount()* function.
```
collision_raster <- raster(nrow=20, ncol=20)
collision_raster[]<-collision_quad
```
Then we change the raster's extent to that of the coordinates, which we already have determined with *bbox* above.
```
raster_extent <- extent(collisions_coord_b[1,1],
                  collisions_coord_b[1,2],
                  collisions_coord_b[2,1],
                  collisions_coord_b[2,2])
collision_raster@extent <- raster_extent
```
To make the plot clearer, we will place two shapefiles (which are in the same CRS), on top of the raster plot. These are a boundary shapefile of the City of Seattle (created through a dissolve of another neighborhood shapefile available in the city's open data portal), and a shapefile of its major arterials (taken by selecting them from the city's roads shapefile). We read these with the *rgdal* package.
```
seattle <- readOGR(dsn=".//data//", layer="seattle_boundaries")
seattle_arterials <- readOGR(dsn=".//data//", layer="seattle_arterials")
```
Now that we have everything, we can plot the data:
```
plot(collision_raster,
     main="Collisions per Quadrant in Seattle, 2018",
     axes=FALSE)
plot(seattle, add=TRUE)
plot(seattle_arterials, col="grey50", add=TRUE)
```
It is important to note several things. First, the areas we have selected are arbitrary. If we wanted, we could establish quadrants as approximations to square miles, with a little more code, and this might prove slightly more illuminating.

![Plot of Quadrant Counts](/images/CPQ_2018.jpeg)

But even if we did this, we would have to encounter a larger problem that brings us closer to the actual difficulties of point pattern analysis, and which I will continue to explain below: this is how the frequency of the points within each quadrant are effectively unable to tell us anything about the actual relationship between the events in these areas, without covariates or the calculation of more specific types of patterns between the points. We are able to see from this initial exploration that collisions occur in the quadrants that overlay the downtown of Seattle, for instance. And while this has some relationship to the actual problems involved in designing and maintaining the infrastructure in this area, it is unclear what types of problems these would be and how they relate to the problems of other areas? Are collisions actually more frequent in Seattle's downtown? In what way?

Further exploration of point patterns will give us some answers...

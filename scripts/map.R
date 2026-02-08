library(tidyverse)
library(sf)

files <- list.files(
  "output/tutorial-1",
  "cluster.*\\.kml$",
  full.names = TRUE
)

nybc <- lapply(files, st_read)

files <- list.files(
  "output/tutorial-1",
  "cluster.*\\.kml$"
)

names(nybc) <- sub("\\.kml$", "", files)

nymap <- tigris::states() |>
  filter(NAME == "New York")

nymap <- st_transform(nymap, crs = st_crs(nybc$cluster1_locations))

ggplot() +
  geom_sf(data = nymap) +
  geom_sf(data = nybc$cluster1_locations) +
  geom_sf(data = nybc$cluster2_locations) +
  geom_sf(data = nybc$cluster3_locations) +
  geom_sf(data = nybc$cluster4_locations) +
  geom_sf(data = nybc$cluster5_locations) +
  geom_sf(data = nybc$cluster6_locations) +
  geom_sf(data = nybc$cluster7_locations) #+
  # geom_sf(data = nybc$locations_outside_clusters)






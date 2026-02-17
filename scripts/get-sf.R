# Get simple features for KC ZCTAs

library(kcData)
library(tidyverse)

kc_zctas <- kcData:::get_raw_sf2("zcta", 2024)

kc_zctas <- kc_zctas |>
  filter(ZCTA5CE20 %in% unique(unlist(geoids$zcta)))

ggplot() +
  geom_sf(data = kc_zctas) +
  geom_sf(
    data = sf_city_2024,
    color = "blue",
    fill = "lightblue",
    alpha = .5
  )

saveRDS(kc_zctas, "data/1-source/kc_zctas.rds")


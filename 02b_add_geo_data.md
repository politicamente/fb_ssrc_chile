02b - Add geo data and generate datasets at the post and candidate
levels
================

### Load libraries

``` r
library(readr)
library(dplyr)
library(here)
```

### Load data posts crowdtangle + politicamente

``` r
fb_data_post  <- read_rds(here("proc", "01_facebook_data_post.rds"))
fb_data_candidate  <- read_rds(here("proc", "01_facebook_data_candidate.rds"))
```

### Load data posts of deployment

1227 posts from politicamente + crowdtangle with geographical data.

``` r
posts_geo_nse <- read_csv(here("proc", "02_posts_deployment_nse.csv"), 
                                col_types = cols(id_post_u = col_character()))
```

### Join data

``` r
posts_geo_select <- posts_geo_nse %>%
  
  select(id_post_u, nse) %>%
  
  distinct(id_post_u, .keep_all = TRUE)
```

### Merge with fb\_data\_posts

``` r
fb_data_post_nse <- fb_data_post %>%
  
  left_join(posts_geo_select, by=c( "id_post"="id_post_u"))
```

### group\_by() candidato and merge fb\_data\_candidates

``` r
posts_geo_candidate <- posts_geo_nse %>%
  
  group_by(candidate) %>%
  
  summarise(mean_nse=mean(nse),
            n_posts_deployment= n())
```

    ## `summarise()` ungrouping output (override with `.groups` argument)

``` r
fb_data_candidate_nse <- fb_data_candidate %>%
  
  left_join(posts_geo_candidate, by="candidate")
```

Replace NA with 0

``` r
fb_data_candidate_nse$n_posts_deployment[is.na(fb_data_candidate_nse$n_posts_deployment)] <- 0
```

### Save data

``` r
write_rds(fb_data_post_nse, here("proc", "02_fb_data_posts_nse.rds"))
write_rds(fb_data_candidate_nse, here("proc", "02_fb_data_candidate_nse.rds"))
```

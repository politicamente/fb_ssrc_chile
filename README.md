# fb_ssrc_chile

**Description:** This repository contains the replication materials for "Campaign types and district types", white paper 1 of the "The role of Facebook in Legislative Campaigns in Chile (2017)" SSRC project. 

**Authors:** Luna, Pérez, Toro, Rosenblatt, Alcatruz, Bro, Cruz, and Escobar

**Version:** 0.2. The following minor corrections were made from v0.1: 
  + Two candidates (out of 80) had to be excluded from k-means clustering, as they are not present in Políticamente's dataset. 
  + Whenever possible, now post messages are retrieved from Políticamente, as Crowdtangle's are sometimes trimmed. This increases the words that serve as input to the structural topic model.

**Replication instructions:** Download/clone this repository and run its scripts in order, maintaining the folder structure (for example, using RStudio and Jupyter Lab).
  + Tested with R 4.0.0. Required packages: `tidyverse`, `here`, `glue`, `sf`, `RColorBrewer`, `tmap`, `tmaptools`, `janitor`, `tidytext`, `stm`, `ggthemes`, `cowplot`, `dplyr`, `readr`, `leaflet`, `here`, `htmlwidgets`, `htmltools`, `webshot`.
  + Tested with Python 3.7.6. Required libraries: `geopandas`, `shapely`, `scipy`, `numpy`, `pandas`.

[Interactive map with deployment of candidates by cluster](https://politicamente.github.io/Deployment_Candidates/) 

## Scripts


- **`01_merge_facebook_data.Rmd`**
  + **Description:** Integrates multiple sources, compiling Facebook data of the 2017 legislative campaigns in Chile at the post and candidate levels.
  + **Inputs:** 
    + `input/facebook_data/df_condor_urls.csv`
    + `input/facebook_data/df_crowdtangle.csv`
    + `input/facebook_data/politicamente_be17_v6_posts-facebook.csv`
    + `input/facebook_data/politicamente_be17_v6_candidatos.csv`
    + `input/facebook_data/politicamente_be17_v6_codificaciones.csv`
  + **Outputs:** 
    + `proc/01_facebook_data_post.rds`
    + `proc/01_facebook_data_candidate.rds`

- **`02a_get_geo_data.ipynb`** and **`02b_add_geo_data.Rmd`**
  + **Description:** Geolocate deployment posts, generating datasets at the post and candidate levels (with geographical information).
  + **Inputs:** 
    + `input/geo_data/ibt_geo.shp`
    + `input/data_deployment/posts_deployment.csv`
    + `proc/01_facebook_data_candidate.rds`
    + `proc/01_facebook_data_post.rds`
  + **Outputs:** 
    + `proc/02_facebook_data_candidate_nse.rds`
    + `proc/02_facebook_data_posts_nse.rds`
    + `proc/02_posts_deployment_nse.csv`
- **`03_analyze_clusters.Rmd`**
  + **Description:** Executes k-means clustering and generates graphs related to them. Also outputs datasets at the post and candidate levels (with clustering information).
  + **Inputs:** 
    + `proc/02_facebook_data_candidate_nse.rds`
    + `proc/02_facebook_data_posts_nse.rds`
  + **Outputs:**
    + `output/03_fig3_clusters_factors.png` 
    + `output/03_fig4_clusters_candidate_vars.png` 
    + `output/03_fig6_clusters_campaign_vars.png`
    + `proc/03_facebook_data_candidate_nse_cl.rds`
    + `proc/03_facebook_data_posts_nse_cl.rds`
- **`04_analyze_geo_data.Rmd`** and **`04b_interactive_deployment_map.Rmd`**
  + **Description:** Generates maps shown in the white paper.
  + **Inputs:** 
    + `proc/03_facebook_data_candidate_nse_cl.rds`
    + `proc/03_facebook_data_posts_nse_cl.rds`
  + **Outputs:** 
    + `output/04_map_c1.png`
    + `output/04_map_c2.png`
    + `output/04_map_c3.png`
    + `output/index.html`
- **`05_estimate_stm.Rmd`**
  + **Description:** Estimates the structural topic model shown in the white paper.
  + **Inputs:** 
    + `input/BDCUT_CL__CSV_UTF8.csv`
    + `proc/03_facebook_data_candidate_nse_cl.rds`
    + `proc/03_facebook_data_posts_nse_cl.rds`
  + **Outputs:** 
    + `output/05_fig7_topics.png`
    + `proc/05_many_models.rds`

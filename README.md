# fb_ssrc_chile

**Description:** This repository contains the replication materials for "Campaign types and district types", white paper 1 of the "The role of Facebook in Legislative Campaigns in Chile (2017)" SSRC project. 

**Authors:** Luna, Pérez, Toro, Rosenblatt, Alcatruz, Bro, Cruz, and Escobar

**Version:** 0.1


## Scripts


- **`01_merge_facebook_data.R`**
  + **Description:** Integrates multiple sources, compiling Facebook data of the 2017 legislative campaigns in Chile at the post and candidate levels.
  + **Inputs:** 
    + `df_condor_urls.csv`
    + `df_crowdtangle.csv`
    + `politicamente_be17_v4_posts-facebook.csv`
    + `politicamente_be17_v5_candidatos.csv`
    + `politicamente_be17_v5_codificaciones.csv`
  + **Outputs:** 
    + `01_facebook_data_post.rds`
    + `01_facebook_data_candidate.rds`

- **`02a_get_geo_data.ipynb`** and **`02b_add_geo_data.R`**
  + **Description:** Geolocate deployment posts, generating datasets at the post and candidate levels (with geographical information).
  + **Inputs:** 
    + `input/geo_data/ibt_geo.shp`
    + `input/data_deployment/posts_deployment.csv`
    + `proc/01_facebook_data_candidate.rds`
    + `proc/01_facebook_data_post.rds`
  + **Outputs:** 
    + `proc/01_facebook_data_candidate_nse.rds`
    + `proc/01_facebook_data_posts_nse.rds`
    + `proc/posts_deployment_nse.csv`
- **`03_analyze_clusters.R`**
  + **Description:** Executes k-means clustering and generates graphs related to them. Also outputs datasets at the post and candidate levels (with clustering information).
  + **Inputs:** 
    + ... (outputs from 02)
  + **Outputs:**
    + `output/03_fig3_clusters_factors.png` 
    + `output/03_fig4_clusters_candidate_vars.png` 
    + `output/03_fig6_clusters_campaign_vars.png`
    + (+ 2 datasets)
- **`04_analyze_geo_data.R`**
  + **Description:** Generates maps shown in the white paper.
  + **Inputs:** 
    + ... (dataset outputs from 03)
  + **Outputs:** 
    + ... (maps)
- **`05_estimate_stm.R`**
  + **Description:** Estimates the structural topic model shown in the white paper.
  + **Inputs:** 
    + ... (dataset outputs from 03)
  + **Outputs:** 
    + `output/05_fig7_topics.png`.

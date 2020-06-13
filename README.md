# fb_ssrc_chile

**Description:** This repository contains the replication materials for "Campaign types and district types", white paper 1 of the "The role of Facebook in Legislative Campaigns in Chile (2017)" SSRC project. 

**Authors:** Luna, Pérez, Toro, Rosenblatt, Alcatruz, Bro, Cruz, and Escobar

**Version:** 0.1


### Scripts


- `01_merge_facebook_data.R`: Integrates multiple sources, compiling Facebook data of the 2017 legislative campaigns in Chile at the post and candidate levels.
	+ Inputs: ...
	+ Outputs: ... (2 datasets)
- `02a_get_geo_data.ipynb` and `02b_add_geo_data`: Geolocate deployment posts, generating datasets at the post and candidate levels (with geographical information).
	+ Inputs: ... (outputs from 01)
	+ Outputs: ... (2 datasets)
- `03_analyze_clusters`: Executes k-means clustering and generates graphs related to them. Also outputs datasets at the post and candidate levels (with clustering information).
	+ Inputs: ... (outputs from 02)
	+ Outputs: ... (graphs + 2 datasets)
- `04_analyze_geo_data`: Generates maps shown in the white paper.
	+ Inputs: ... (dataset outputs from 03)
	+ Outputs: ... (maps)
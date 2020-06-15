


# load libraries
library(readr)
library(dplyr)
library(here)


# load data posts crowdtangle + politicamente 
fb_data_post  <- read_rds(here("proc", "01_facebook_data_post.rds"))
fb_data_candidate  <- read_rds(here("proc", "01_facebook_data_candidate.rds"))


  

# load data posts deployment

posts_geo_nse <- read_csv(here("proc", "02_posts_deployment_nse.csv"), 
                                col_types = cols(id_post_u = col_character()))# 1227 posts from politicamente + crowdtangle with geographical data.
                        

###############################
###############################
#
# Join and merge data 
#
###############################
###############################


posts_geo_select <- posts_geo_nse %>%
  
  select(id_post_u, nse) %>%
  
  distinct(id_post_u, .keep_all = TRUE)




# merge with fb_data_post


fb_data_post_nse <- fb_data_post %>%
  
  left_join(posts_geo_select, by=c( "id_post"="id_post_u"))

# group_by() candidato and merge fb_data_candidates 

posts_geo_candidate <- posts_geo_nse %>%
  
  group_by(candidate) %>%
  
  summarise(mean_nse=mean(nse),
            n_posts_deployment= n())



fb_data_candidate_nse <- fb_data_candidate %>%
  
  left_join(posts_geo_candidate, by="candidate")




# save data 

write_rds(fb_data_post_nse, "proc/02_fb_data_posts_nse.rds")
write_rds(fb_data_candidate_nse, "proc/02_fb_data_candidate_nse.rds")

                     

                        
                        
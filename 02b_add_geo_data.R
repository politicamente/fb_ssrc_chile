


# load libraries
library(readr)
library(dplyr)
library(here)


# load data posts crowdtangle + politicamente 
fb_data_post  <- read_rds(here("proc", "01_facebook_data_post.rds"))
fb_data_candidate  <- read_rds(here("proc", "01_facebook_data_candidate.rds"))


  

# load data posts deployment

post_geo_1 <-  read.csv2(here("input","data_deployment","post_geo1.csv")) # 1169 posts from politicamente
                        
post_geo_2 <- read.csv2(here("input","data_deployment","post_geo2.csv")) # 58 posts from crowdtangle 




###############################
###############################
#
# Join post_geo_1 and post_geo2
#
###############################
###############################

# extract id of posts from variable id that is a combine of id_user and id_post

post_geo_1 <- post_geo_1 %>% 
  
  mutate(id_post_u=sub("^[^_]*_([^_]*).*", "\\1", id))




# Now, merge fb_data_post with post_geo_1 and post_geo_2 

post_geo_1_select <- post_geo_1 %>%
  
  select(candidate,id_post_u,message,loc,lon, lat, nse)

post_geo_2_select <- post_geo_2 %>%
  
  select(candidate,id_post_u,message,loc,lon, lat, nse)


# rbind() to all posts of deployment 


posts_geo_all <- rbind(post_geo_1_select, post_geo_2_select)


# select id_post_u and nse to merge with fb_data_post



posts_geo_select <- posts_geo_all %>%
  
  select(id_post_u, nse) %>%
  
  distinct(id_post_u, .keep_all = TRUE)

# merge with fb_data_post


fb_data_post_nse <- fb_data_post %>%
  
  left_join(posts_geo_select, by=c( "id_post"="id_post_u"))

# group_by() candidato and merge fb_data_candidates 

posts_geo_candidate <- posts_geo_all %>%
  
  group_by(candidate) %>%
  
  summarise(mean_nse=mean(nse))



fb_data_candidate_nse <- fb_data_candidate %>%
  
  left_join(posts_geo_candidate, by="candidate")




# save data 

write_rds(posts_geo_all, "proc/02_posts_deployment.rds")
write_rds(fb_data_post_nse, "proc/02_fb_data_posts_nse.rds")
write_rds(fb_data_candidate_nse, "proc/02_fb_data_candidate_nse.rds")

                     

                        
                        
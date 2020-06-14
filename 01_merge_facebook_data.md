Merge Facebook Data
================

This script integrates multiple sources, compiling Facebook data of the
2017 legislative campaigns in Chile at the post and candidate levels.

1.  `df_crowdtangle`: facebook data from crowdtangle API
2.  `politicamente`: three datasets with post, coding of these posts and
    candidate data
3.  `df_condor_urls`: shared urls by candidates from the condor dataset

<!-- end list -->

``` r
#load packages
library(tidyverse)
```

##### Crowdtangle
``` r
df_crowdtangle <- read_csv("input/facebook_data//df_crowdtangle.csv") %>% 
  mutate(id_post = post_url %>% 
           str_extract("posts/\\d+$") %>% 
           str_remove("posts/"))
```

##### Politicamente

``` r
df_politicamente_posts <- read_csv("input/facebook_data/politicamente_be17_v4_posts-facebook.csv") %>% 
  mutate(id_post = id %>% 
           str_extract("_\\d+$") %>% 
           str_remove("_"))

df_politicamente_codif <- read_csv("input/facebook_data/politicamente_be17_v5_codificaciones.csv")

df_politicamente_cands <- read_csv("input/facebook_data/politicamente_be17_v5_candidatos.csv")
```

``` r
df_politicamente <- df_politicamente_posts %>% 
  left_join(df_politicamente_codif) %>% 
  select(id_post, mensaje_id, facebook_id, everything(), -id) %>% 
  left_join(df_politicamente_cands, by = "facebook_id") %>% 
  select(
    id_post, facebook_id, from_name, created_time, message,
    type, link, matches("_count"),
    matches("^codif_"), 
    candidato:distrito_dip, partido, d_mujer, nacimiento, coalicion, 
    gasto_total, gasto_rrss, gasto_rrss, gasto_rrss_pct, 
    ingreso_total, votos, votos_pct, d_incumbente_gen, d_gano
  ) %>% 
  mutate(d_pol = 1L, d_ct = 0)
```

##### Condor URLs

``` r
df_condor_urls <- read_delim("input/facebook_data/df_condor_urls.csv", 
                          ";", escape_double = FALSE, trim_ws = TRUE)

df_condor_urls <- df_condor_urls %>% 
  mutate(domain = str_remove(parent_domain,"\\..*")) %>% 
  select(domain, link = clean_url, url_headline = share_title, 
         url_blurb = share_main_blurb, contains("feedback"))
```

### Merge Datasets (Post Level)

First, we prepare `df_crowdtangle` data

``` r
df_crowdtangle_std <- df_crowdtangle %>% 
  select(id_post, facebook_id = page_id, from_name = page_name, 
         created_time = time_created, message = post_message,
         type = post_type, link = post_link,
         #new CT variables:
         link_text = post_link_test, link_description, overperforming_score,
         #candidate level
         candidate = candidato, candidate_district,
         coalition = candidate_list, list = lista, party = candidate_party, 
         candidate_birth = nacimiento, d_women = candidate_gender,
         d_incumbent_gen = candidate_incumbent,
         d_elected = candidate_elected, votes = candidate_votes,
         spending_total = candidate_spending,
         # reactions
         comments_count = comments,
         shares_count = shares,
         likes_count = likes,
         love_count = reaction_love,                 
         wow_count = reaction_wow,                 
         haha_count = reaction_haha,                 
         sad_count = reaction_sad,                 
         angry_count = reaction_angry
  ) %>% 
  mutate(created_time = created_time %>% 
           str_remove(" EDT") %>% 
           lubridate::ymd_hms(tz = "EDT") %>% 
           lubridate::with_tz("UTC"),
         candidate_birth = lubridate::ymd(candidate_birth),
         candidate = str_to_upper(candidate),
         d_ct = 1L, d_pol = 0L)
```

Prepare `df_politicamente` data

``` r
df_politicamente <- df_politicamente %>% 
  select(id_post, facebook_id, from_name, created_time, message,
         type, link,
         #new variables from politicamente:
         codif_macro_1, codif_macro_2, codif_micro_1, codif_micro_2,
         candidate_id = candidato_id, candidate_rut = candidato_rut,
         #candidate level:
         candidate = candidato, candidate_district = distrito_dip,
         coalition = coalicion, party = partido, 
         candidate_birth = nacimiento, d_women = d_mujer,
         d_incumbent_gen = d_incumbente_gen,
         d_elected = d_gano, spending_total = gasto_total, 
         spending_socialmedia = gasto_rrss,
         spending_socialmedia_pct = gasto_rrss_pct,
         income_total = ingreso_total, votes = votos, votes_pct = votos_pct,
         d_pol, d_ct,
         #reactions:
         comments_count, shares_count, likes_count, love_count, wow_count,
         haha_count, sad_count, angry_count) 
```

Now we merge the datasets

``` r
df_ct_pt <- bind_rows(df_politicamente, df_crowdtangle_std) %>% 
  select(id_post:link, link_text, link_description, overperforming_score,
         everything()) %>% distinct(id_post, .keep_all = TRUE)

df_urls <- df_ct_pt %>% filter(!is.na(link)) #necessary step to override NAs in merge column
df_urls <- df_urls %>% left_join(df_condor_urls)
df_ct_pt_urls <- df_ct_pt %>% left_join(df_urls)
```

We add two more variables: post lenght and percentage of multimedia
posts per candidate

``` r
variables <- df_ct_pt_urls %>% 
  mutate(d_multimedia = if_else(str_detect(type, "(ideo)|(hoto)"), 1L, 0L)) %>% 
  filter(!is.na(candidate_id)) %>% 
  group_by(candidate_id) %>% 
  summarize(chr_conteo_mediano = median(str_count(str_squish(message)),
                                        na.rm = T),
            porc_multimedia = 100 * mean(d_multimedia, na.rm = T)) %>% 
  ungroup()

df_ct_pt_urls <- left_join(df_ct_pt_urls, variables)
```

Save dataframe

``` r
write_rds(df_ct_pt_urls, "proc/01_facebook_data_post.rds")
```

### Merge Datasets (Candidate Level)
Now we are going to group the data at the candidate level for future
analysis. This dataset only includes candidates competing in the
districts 10, 11 and 13, which are the focus of this paper.

``` r
df_facebook <- read_rds("proc/01_facebook_data_post.rds")  

df_facebook <- df_facebook %>% 
  filter(candidate_district==10 | candidate_district==11 | candidate_district==13) %>%
  mutate_if(is.numeric, function(x) ifelse(is.infinite(x), 0, x))
```

First we summarise number of posts by candidate and then the number of
posts of each type (from codif_macro1) by candidate

``` r
# first we group by candidate

df_facebook_candidate <- df_facebook %>%
  group_by(candidate) %>%
  summarise(n=n())

# then we summarise post type (from codif_macro1 variable) by candidate

df_facebook_A <- df_facebook %>%
  filter(codif_macro_1=='A. Programático') %>%
  group_by(candidate) %>%
  summarise(n_posts_programmatic=n()) 

df_facebook_B <- df_facebook %>%
  filter(codif_macro_1=='B. Campaña') %>%
  group_by(candidate) %>%
  summarise(n_posts_campaign=n()) 

df_facebook_C <- df_facebook %>%
  filter(codif_macro_1=='C. Politics') %>%
  group_by(candidate) %>%
  summarise(n_posts_politics=n()) 

df_facebook_D <- df_facebook %>%
  filter(codif_macro_1=='D. Otros') %>%
  group_by(candidate) %>%
  summarise(n_posts_others=n()) 

#now we join them
df_facebook_all <- df_facebook_candidate %>% #Merge all
  left_join(df_facebook_A, by="candidate") %>%
  left_join(., df_facebook_B, by="candidate") %>%
  left_join(., df_facebook_C, by="candidate") %>%
  left_join(., df_facebook_D, by="candidate")
```

Then we summarise facebook states by candidate

``` r
df_likes <- df_facebook  %>%
  group_by(candidate) %>%
  summarise(sum_likes=sum(likes_count)) 

df_comments <- df_facebook  %>%
  group_by(candidate) %>%
  summarise(sum_comments=sum(comments_count)) 

df_shares <- df_facebook  %>%
  group_by(candidate) %>%
  summarise(sum_shares=sum(shares_count)) 

df_loves <- df_facebook  %>%
  group_by(candidate) %>%
  summarise(sum_loves=sum(love_count)) 

df_haha <- df_facebook  %>%
  group_by(candidate) %>%
  summarise(sum_hahas=sum(haha_count)) 

df_wow <- df_facebook  %>%
  group_by(candidate) %>%
  summarise(sum_wows=sum(wow_count)) 

df_sad <- df_facebook  %>%
  group_by(candidate) %>%
  summarise(sum_sads=sum(sad_count)) 

df_angry <- df_facebook  %>%
  group_by(candidate) %>%
  summarise(sum_angries=sum(angry_count)) 

# merge with the previosu dataset

df_facebook_all <- df_facebook_all %>%
  left_join(., df_likes, by="candidate") %>%
  left_join(., df_angry, by="candidate") %>%
  left_join(., df_comments, by="candidate") %>%
  left_join(., df_haha, by="candidate") %>%
  left_join(., df_loves, by="candidate") %>%
  left_join(., df_sad, by="candidate") %>%
  left_join(., df_wow, by="candidate") %>%
  left_join(., df_shares, by="candidate") 
```

Now we compute the mean of facebook stats for each candidate

``` r
df_likesm <- df_facebook  %>%
  group_by(candidate) %>%
  summarise(mean_likes=mean(likes_count)) 

df_commentsm <- df_facebook  %>%
  group_by(candidate) %>%
  summarise(mean_comments=mean(comments_count)) 

df_sharesm <- df_facebook  %>%
  group_by(candidate) %>%
  summarise(mean_shares=mean(shares_count)) 

df_lovesm <- df_facebook  %>%
  group_by(candidate) %>%
  summarise(mean_loves=mean(love_count)) 

df_haham <- df_facebook  %>%
  group_by(candidate) %>%
  summarise(mean_hahas=mean(haha_count)) 

df_wowm <- df_facebook  %>%
  group_by(candidate) %>%
  summarise(mean_wows=mean(wow_count)) 

df_sadm <- df_facebook  %>%
  group_by(candidate) %>%
  summarise(mean_sads=mean(sad_count)) 

df_angrym <- df_facebook  %>%
  group_by(candidate) %>%
  summarise(mean_angries=mean(angry_count)) 

## Merge
df_facebook_all <- df_facebook_all %>%
  left_join(., df_likesm, by="candidate") %>%
  left_join(., df_angrym, by="candidate") %>%
  left_join(., df_commentsm, by="candidate") %>%
  left_join(., df_haham, by="candidate") %>%
  left_join(., df_lovesm, by="candidate") %>%
  left_join(., df_sadm, by="candidate") %>%
  left_join(., df_wowm, by="candidate") %>%
  left_join(., df_sharesm, by="candidate")
```

The final step is merging with candidate level variables from
`01_merge_facebook_data_post.rds` and save the new candidate level
dataset

``` r
df_facebook <- df_facebook %>% 
  select(candidate, candidate_district,coalition, list, party,
         candidate_birth, d_women, d_incumbent_gen,
         d_elected, votes, spending_total, spending_socialmedia, 
         spending_socialmedia_pct, income_total, votes_pct, candidate_id, candidate_rut)
         
df_facebook_candidate <- df_facebook_all %>% left_join(df_facebook) %>% 
  distinct(candidate, .keep_all = TRUE)

#Save dataframe 
write_rds(df_facebook_candidate, "proc/01_facebook_data_candidate.rds")
```

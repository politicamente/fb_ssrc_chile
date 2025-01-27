01 - Merge Facebook Data
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
library(here)
```

##### Crowdtangle

``` r
df_crowdtangle <- read_csv(here("input", "facebook_data",
                                "df_crowdtangle.csv")) %>% 
  mutate(id_post = post_url %>% 
           str_extract("posts/\\d+$") %>% 
           str_remove("posts/"),
         d_ct = 1,
         d_pol = 0)
```

##### Politicamente

``` r
df_politicamente_posts <- read_csv(
  here("input", "facebook_data", "politicamente_be17_v6_posts-facebook.csv")
) %>% 
  mutate(id_post = id %>% 
           str_extract("_\\d+$") %>% 
           str_remove("_"))

df_politicamente_codif <- read_csv(
  here("input", "facebook_data", "politicamente_be17_v6_codificaciones.csv")
)

df_politicamente_cands <- read_csv(
  here("input", "facebook_data", "politicamente_be17_v6_candidatos.csv")
)

df_politicamente_tweets <- read_csv(
  here("input", "facebook_data", "politicamente_be17_v6_tweets.csv")
) %>% 
  count(twitter_id) %>% 
  rename(n_tweets = n) 
```

``` r
df_politicamente <- df_politicamente_posts %>% 
  left_join(df_politicamente_codif) %>% 
  select(id_post, mensaje_id, facebook_id, everything(), -id) %>% 
  left_join(df_politicamente_cands, by = "facebook_id") %>% 
  left_join(df_politicamente_tweets)  %>% 
  select(id_post, facebook_id, from_name, created_time, message,
    type, link, matches("_count"),
    matches("^codif_"), 
    candidato:distrito_dip, partido, d_mujer, nacimiento, coalicion, 
    gasto_total, gasto_rrss, gasto_rrss, gasto_rrss_pct, 
    ingreso_total, votos, votos_pct, d_incumbente_gen, d_gano, n_tweets) %>% 
  mutate(d_pol = 1, d_ct = 0) 
```

##### Condor URLs

``` r
df_condor_urls <- read_delim(
  here("input", "facebook_data", "df_condor_urls.csv"), 
  ";", escape_double = FALSE, trim_ws = TRUE
)

df_condor_urls <- df_condor_urls %>% 
  mutate(domain = str_remove(parent_domain,"\\..*")) %>% 
  select(domain, link = clean_url, url_headline = share_title, 
         url_blurb = share_main_blurb, contains("feedback"))
```

### Merge Datasets (post level)

First, we prepare `df_crowdtangle` data

``` r
df_crowdtangle_std <- df_crowdtangle %>% 
  select(id_post, facebook_id = page_id, from_name = page_name, 
         created_time = time_created, message = post_message,
         type = post_type, link = post_link,
         #new CT variables:
         link_text = post_link_test, link_description, overperforming_score,
         #candidate level
         candidate = candidate_name, candidate_district,
         coalition = candidate_list, party = candidate_party, 
         candidate_birth = nacimiento, d_female = candidate_gender,
         d_incumbent_gen = candidate_incumbent,
         d_elected = candidate_elected, votes = candidate_votes,
         spending_total = candidate_spending,
         # reactions
         comments_count = comments,
         shares_count = shares,
         likes_count = likes
  ) %>% 
  mutate(created_time = created_time %>% 
           str_remove(" EDT") %>% 
           lubridate::ymd_hms(tz = "EDT") %>% 
           lubridate::with_tz("UTC"),
         candidate_birth = lubridate::ymd(candidate_birth),
         candidate = str_to_upper(candidate),
         d_ct = 1L, d_pol = 0L) %>% 
  mutate(coalition = 
           case_when(coalition == "Chile Vamos" ~ "ChV",
                                    coalition == "Convergencia Democratica" ~ "DC",
                                    coalition == "Frente Amplio" ~ "FA",
                                    coalition == "La Fuerza de la Mayoria" ~ "FdM",
                                    coalition %in% c("Coalicion Regionalista Verde","Independiente","Por todo Chile","Por Todo Chile","PTR","Sumemos","Union Patriotica",NA) ~ "Otro"))
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
         candidate_birth = nacimiento, d_female = d_mujer,
         d_incumbent_gen = d_incumbente_gen,
         d_elected = d_gano, spending_total = gasto_total, 
         spending_socialmedia = gasto_rrss,
         spending_socialmedia_pct = gasto_rrss_pct,
         income_total = ingreso_total, votes = votos, votes_pct = votos_pct,
         d_pol, d_ct,n_tweets,
         #reactions:
         comments_count, shares_count, likes_count)
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
  summarize(median_chr_length = median(str_count(str_squish(message)),
                                        na.rm = T),
            multimedia_perc = 100 * mean(d_multimedia, na.rm = T)) %>% 
  ungroup()

df_ct_pt_urls <- left_join(df_ct_pt_urls, variables)
```

Save dataframe

``` r
write_rds(df_ct_pt_urls, here("proc", "01_facebook_data_post.rds"))
```

### Merge Datasets (candidate level)

Now we are going to group the data at the candidate level for future
analysis. This dataset only includes candidates competing in the
districts 10, 11 and 13, which are the focus of this paper.

``` r
df_facebook <- read_rds(here("proc", "01_facebook_data_post.rds"))

df_facebook <- df_facebook %>% 
  filter(candidate_district==10 | candidate_district==11 | candidate_district==13) %>%
  mutate_if(is.numeric, function(x) ifelse(is.infinite(x), 0, x))
```

First we summarise number of posts by candidate and then the number of
posts of each type (from codif\_macro\_1) by candidate

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

# merge with the previosu dataset

df_facebook_all <- df_facebook_all %>%
  left_join(., df_likes, by="candidate") %>%
  left_join(., df_comments, by="candidate") %>%
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

## Merge
df_facebook_all <- df_facebook_all %>%
  left_join(., df_likesm, by="candidate") %>%
  left_join(., df_commentsm, by="candidate") %>%
  left_join(., df_sharesm, by="candidate")
```

The we merge this with candidate-level variables from
`01_merge_facebook_data_post.rds`

``` r
df_facebook <- df_facebook %>% 
  select(candidate, candidate_district,coalition, party,
         candidate_birth, d_female, d_incumbent_gen,
         d_elected, votes, spending_total, spending_socialmedia, 
         spending_socialmedia_pct, income_total, votes_pct, candidate_id, candidate_rut, n_tweets, d_ct, d_pol)
         
df_facebook_candidate <- df_facebook_all %>% left_join(df_facebook) %>% 
  distinct(candidate, .keep_all = TRUE)

#Clean some data:
df_facebook_candidate <- df_facebook_candidate %>%
   mutate_if(is.integer,as.double) %>%  
    mutate(n_posts_programmatic = if_else(d_pol == 1 & is.na(n_posts_programmatic), 0, n_posts_programmatic),
           n_posts_campaign = if_else(d_pol == 1 & is.na(n_posts_campaign), 0, n_posts_campaign),
           n_posts_others = if_else(d_pol == 1 & is.na(n_posts_others), 0, n_posts_others),
           n_posts_politics = if_else(d_pol == 1 & is.na(n_posts_politics), 0, n_posts_politics))
```

Save dataframe

``` r
write_rds(df_facebook_candidate, here("proc", "01_facebook_data_candidate.rds"))
```

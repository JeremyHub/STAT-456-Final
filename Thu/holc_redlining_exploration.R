library(tidycensus)
library(tidyverse)
library(sf)
library(data.table)

options(tigris_use_cache = TRUE)
census_api_key("19609eb52d1c1d8a6000e796ad5ee4027040605f", overwrite = TRUE, install = TRUE) # to get your own data, you need a Census API key (https://walker-data.com/tidycensus/articles/basic-usage.html)

v19 <-load_variables(2019, "acs5", cache = TRUE)
# highschool_vars <- v19 %>% filter(str_detect(label, "\\shigh school\\s"))
# rent_vars <- v19 %>% filter(str_detect(label, "\\srent\\s"))
# homeownership_vars <- v19 %>% filter(str_detect(label, "\\shomeownership\\s"))

white_var <- v19 %>% filter(str_detect(label, "white"))
black_var <- v19 %>% filter(str_detect(tolower(label), "black"))
race_var <- v19 %>% filter(str_detect(tolower(concept), "^race"))


VARS <- c(Income = "B19013_001", Population = 'B01003_001', Age = "B01002_001", HouseValue = "B25077_001", HouseholdSize = "B25010_001", NumHouse = "B25003_001", NumWithHighSchoolDiploma = "B15003_017", WhitePopulation = "B02001_002", BlackPopulation = "B02001_003", NativePopulation = "B02001_004", AsianPopulation = "B02001_005", TwoOrMoreRaces = "B02001_008") # We can get more variables if we need

# House Value is median value dollars

# Get census data for MN

mn_data_2019 <- get_acs(state = "MN", geography = "tract",
                         variables = VARS, geometry = TRUE, output='wide', survey = "acs5", year = 2019) 

holc <- st_read('shp_plan_historic_holc_appraisal')
manhattan <- st_read('NYManhattan1937')

mn_data_2019 <- mn_data_2019 %>%
  select(- ends_with("M"))

holc <- st_transform(holc, st_crs(mn_data_2019))
holc1 <- st_make_valid(holc)

holc_mn_data <- st_join(mn_data_2019, holc1)

holc %>%
  ggplot(aes(fill=HSG_SCALE), size=0) +
  geom_sf() + 
  scale_size(range = c(2, 12)) +
  labs(fill='Area Type') +
  theme_void()

race_white_per_area <- holc_mn_data %>%
  group_by(HSG_SCALE) %>%
  summarise(avg_race_white_pct = mean(WhitePopulationE/PopulationE, na.rm = TRUE))

race_pct_by_area_cat <- holc_mn_data %>%
  group_by(HSG_SCALE) %>%
  summarise(`White Population` = mean(WhitePopulationE/PopulationE, na.rm = TRUE),
            `Black Population` = mean(BlackPopulationE/PopulationE, na.rm = TRUE),
            `Native Population` = mean(NativePopulationE/PopulationE, na.rm = TRUE),
            `Asian Population` = mean(AsianPopulationE/PopulationE, na.rm = TRUE),
            `Mix Race Population` = mean(TwoOrMoreRacesE/PopulationE, na.rm = TRUE))

area_size <- holc_mn_data %>%
  group_by(HSG_SCALE) %>%
  summarise(size = sum(Shape_Area)) %>% 
  arrange(desc(size))

race_pct_by_area_cat_long <- race_pct_by_area_cat %>%
  pivot_longer(cols=ends_with("Population"), names_to = "pct_type", values_to = "pct")

viz <- race_pct_by_area_cat_long %>%
  filter(! HSG_SCALE %in% c(NA, 'Uncertain')) %>%
  ggplot(aes(x=HSG_SCALE, y=pct, fill=pct_type)) + 
  geom_col(position = "dodge") + 
  scale_x_discrete(labels = function(x) str_wrap(x, width = 4)) +
  labs(x="Type of Area according to Home Owners Loan Corporation (HOLC)", y = "Proportion of Population", fill="Race Type") +
  theme_classic()

viz








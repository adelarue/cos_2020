
sightings = tibble::tribble(
    ~location , ~poke_id, 
    "ORC"     ,        2, 
    "ORC"     ,        1, 
    "Sloan"   ,        1, 
    "Sloan"   ,        4)
    
pokedex = tibble::tribble(
    ~ID, ~name, 
      1, "Bulbasaur", 
      2, "Squirtle", 
      3, "Charmander")

types = tibble::tribble(
    ~name,        ~type, 
    "Bulbasaur" , "Grass", 
    "Bulbasaur" , "Poison", 
    "Squirtle"  , "Water", 
    "Charmander", "Fire")

catch = tibble::tribble(
    ~name,        ~location, ~catch_pct, 
    "Bulbasaur" , "ORC"    ,         50, 
    "Bulbasaur" , "Sloan"  ,         75, 
    "Squirtle"  , "ORC"    ,         90,
    "Squirtle"  , "Sloan"  ,        100,  
    "Pikachu"   , "ORC"    ,         42)

sightings %>% inner_join(pokedex, by = c("poke_id" = "ID"))
sightings %>% left_join(pokedex, by = c("poke_id" = "ID"))
sightings %>% right_join(pokedex, by = c("poke_id" = "ID"))
sightings %>% full_join(pokedex, by = c("poke_id" = "ID"))
sightings %>% semi_join(pokedex, by = c("poke_id" = "ID"))
sightings %>% anti_join(pokedex, by = c("poke_id" = "ID"))

sightings = sightings %>% 
    left_join(pokedex, by = c("poke_id" = "ID")) %>%
    select(-poke_id) %>%
    mutate(name = ifelse(is.na(name), "Pikachu", name))

sightings %>% inner_join(types, by = "name")
sightings %>% left_join(types, by = "name")
sightings %>% left_join(catch, by = c("name", "location"))

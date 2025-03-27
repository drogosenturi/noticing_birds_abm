extensions [table csv rnd]

globals
[
 yards-per-block  ;; how many houses/yards per block, in x dimension
 plant-species-input ;; a list of lists with plant species name and the probability of it occurring per yard; read from input file called SpeciesList.csv
 plant-species-list  ;; list of all plant species in the world, created from plant-species-input list
 mean-richness ;; the mean richness of yards, which is used as a parameter for randomly assigning # of species to each year
 output-file-name ;; used to create output files during behavior space experiments
 num-nursery-species ;; the number of different plant species a nursery has available if there is more than 1 nursery
 ;; globals below are all set on interface
 ;; neighbor-distance ;; the radius in which other patches are considered 'neighbors' and thus influence yard decisions - now a slider on interface
 ;; yard-difference ;; how similar a patch's richness must be to its neighbors for the patch to be happy - now a slider on interface
 ;; happiness-type ;; the algorithm used to determine whether a patch is happy or will change species - now a slider on interface
 ;; num-nurseries ;; the number of plant nurseries on the landscape
 ;; patch-richness-visualization ;; this is a switch that determines whether or not visualizations are shown on the interface; turn off to decrease computation time
 ;; patch-richness-constraints ;; this is a chooser that determines whether the maximum richness of a patch is contrained by random preference or by which block the patch is on
 ;; mimicry ;; this is a switch that determines whether or not patches change their yards to resemble their neighbors; happiness is not calculated if mimicry is off
]

breed [nurseries nursery]  ;; these represent plant nurseries from which patches can get their plants
breed [happy-faces happy-face] ;; just to visualize whether patches are happy

nurseries-own
[
  nursery-plant-list ;; the specific plant species in that particular nursery
]

patches-own
[
  block-number  ;; number ID for block
  patch-richness ;; number of plant species on a patch
  max-richness ;; the upper limit of plant species that could possibly be on a patch
  unscaled-richness ;; this variable is used to create max-richness based on a patch's block
  species-table  ;; table of species in a patch and their abundance; abundance is currently not used
  neighbor-set ;; set of nearby patches that influence yard decisions, based on neighbor-distance
  neighbor-count ;; count of nearby patches that influence yard decisions
  avg-neighbor-richness ;; avg number of plant species in neighbors' yards
  happy?  ;; for a patch, indicates whether plant species richness is similar to nearby patches
  neighbor-species-table ;; table of plant species in neighboring yards (ie, yards within neighbor-set) and the number of neighbors that have that species
  sorted-list ;; list of species in neighboring yards, sorted with most common species first
  my-nursery ;; the nearest plant nursery for a patch, from which it gets its plants
]

to setup
  clear-all
  set yards-per-block 20
  set mean-richness 5

  ;; Read in species list from file, with probability of species being in any yard
  set plant-species-input csv:from-file "SpeciesList.csv"  ;; Read in the file
  set plant-species-input but-first plant-species-input ;; Remove the header line
  set plant-species-list  map first plant-species-input ;; removes all columns but the first one with plant names

  ;; set neighbor-distance 2 ;; set with slider
  ;; set yard-difference 1 ;; set with slider

  setup-nurseries
  setup-blocks
  setup-patches
  if patch-richness-visualization = true [update-color-visualization]

  reset-ticks
end

to setup-nurseries

 ;; create nurseries, give them the "house" shape, and space them evenly across the landscape
  set-default-shape nurseries "building store"
  if num-nurseries > count patches [user-message "too many nurseries"]
  create-ordered-nurseries num-nurseries
  [set size 2
    setxy (max-pxcor / 2) (max-pycor / 2)
    if num-nurseries > 1 [ fd (max-pxcor / 4)]]

 ;; if there is only one nursery on the landscape, it contains all the plants in the world
  if num-nurseries = 1
  [ask nurseries
    [set nursery-plant-list plant-species-input]]

 ;; if there is more than one nursery, each nursery gets 100 plant species
  if num-nurseries > 1
  [ask nurseries
    [ set num-nursery-species 100
      set nursery-plant-list table:make
      foreach rnd:weighted-n-of-list num-nursery-species plant-species-input [ [a-species] -> last a-species]
      [ the-species -> table:put nursery-plant-list (first the-species) (last the-species)]
      ;;last the-species was added to grab the proportion column from the species file
      set nursery-plant-list table:to-list nursery-plant-list
  ]]
end

to setup-blocks
  ;; this procedure creates a grid of city blocks with each yard assigned to a block
  ;; a "block" represents a street segment with the houses on both sides of the street facing each other
  ;; this facilitates analysis of plant diversity at larger scales beyond the yard (ie, gamma diversity)

  ask patches
  [
  let block-x floor (pxcor / yards-per-block)
  let block-y floor (pycor / 2)
  set block-number (100 * block-y) + block-x
  ]

  ;; this is just a visualization to see how patches are assigned to blocks
  ;; need to have patch-richness-visualization set to "off" for this to work
  ;; ask patches [
  ;; set pcolor block-number + 5
  ;; set plabel block-number]

end

to setup-patches
  ;; procedure to assign plant species to each patch and identify the patch's neighbors
  ;; procedure varies based on the patch-richness-constraints setting, which is selected with a chooser

 ;; STEP 1 - each yard is assigned a richness value, i.e., the number of plant species it will have

  if patch-richness-constraints = "off"
  ;; assigns patch richness randomly to yards, with maximum possible richness of 1000 species (essentially no upper limit)
  [ask patches
    [set max-richness 1000
      set patch-richness round random-exponential mean-richness]]

  if patch-richness-constraints = "random"
  ;; first randomly assign a maximum possible richness to each patch
  ;; this simulates people having different preferences or resources that limits the number of plants in their garden
  ;; then a random patch-richness value is drawn that is less than the maximum possible richness
  [ask patches [set max-richness (random 25) + 1
    set patch-richness round random-exponential mean-richness
    while [patch-richness > max-richness] [set patch-richness round random-exponential mean-richness]]]

  if patch-richness-constraints = "by-block"
  ;; this creates a spatial pattern in maximum possible richness, with people on the same block having the same constraint
  ;; this simulates a constraint that is related to socio-economic factors such as income or education
  ;; the code produces a gradient in maximum species richness, with the lowest value on the bottom-left corner of the map

   [ask patches
     ;; first create an unscaled value of max-richness based on the block a patch is in
    [ let block-x floor (pxcor / yards-per-block)
      let block-y floor (pycor / 2)
      set unscaled-richness block-y + block-x ]

    ;; identify the highest and lowest values of unscaled-richness on the landscape
    let max-unscaled-richness max [unscaled-richness] of patches
    let min-unscaled-richness min [unscaled-richness ] of patches

    ;; rescale unscaled-richness to create a max-richess that ranges from 5 - 25
    ask patches
    [ set max-richness
      round ((((unscaled-richness - min-unscaled-richness)/(max-unscaled-richness - min-unscaled-richness)) * 20) + 5)
    ;; draw a richness value that is less than the max-richness value
    set patch-richness round random-exponential mean-richness
      while [patch-richness > max-richness] [set patch-richness round random-exponential mean-richness]]
    ]

  ;; STEP 2 - then each patch finds the nearest plant nursery and sets it to my-nursery
  ask patches
  [set my-nursery min-one-of turtles [distance myself]]

  ;; STEP 3 - then plant species are assigned to each patch, according to which plants are available in their nursery
  ;; species are selected using 'roulette wheel selection', which randomly selects species according to how abundant they are empirically
  ask patches
  [ set species-table table:make
    foreach rnd:weighted-n-of-list patch-richness [nursery-plant-list] of my-nursery [ [a-species] -> last a-species]
    [ the-species -> table:put species-table (first the-species) (1 + random 11)] ;; abundance of each species can be from 1-10 (this is not used in current model)
  ]

  ;; STEP 4 - identifies the neighbors for each patch; these are the nearby yards that will influence yard design choice
  ask patches
  [ set neighbor-set other patches in-radius neighbor-distance
    set neighbor-count count neighbor-set ]

end

to go
  if mimicry = true [calculate-happiness]
  if mimicry = true [change-unhappy-patches]
  if (patch-richness-visualization = true AND mimicry = true) [update-color-visualization]
  if (patch-richness-visualization = true AND mimicry = true) [update-happy-visualization]
  tick
  if mimicry = false [create-output-files stop]
  ifelse (all? patches [happy?])
  [create-output-files stop]
  [if ticks >= 100 [create-output-files stop]]
end

to calculate-happiness
  ;; determines the range of plant richness that will allow each patch to be happy, based on neighbors' richness
  ;; happy patches do not change their yard composition, but unhappy patches will add or remove species to be more similar to their neighbors

  if happiness-type = "equal"
  ;; in this version, patches want to have a similar number of species to their neighbors, whether their neighbors have more or fewer species
  [ ask patches
  [ ;; calculates mean richness in the neighboring patches
    let summed-richness sum [patch-richness] of neighbor-set
    set avg-neighbor-richness round (summed-richness / neighbor-count)
    ;; calculates the range of values within which a patch can be happy
    let happy-min (avg-neighbor-richness - yard-difference) ;; min number of species needed to be happy
     if max-richness < happy-min [set happy-min max-richness] ;; reduce min number of species if max-richness is lower
    let happy-max (avg-neighbor-richness + yard-difference) ;; max number of species to be happy
     if max-richness < happy-max [set happy-max max-richness] ;; reduce max number of species is max-richness is lower
    ;; happy-min and happy-max should both be lower than or equal to max-richness

    ;; patch is happy if its species richness is similar to the rounded average richness of its neighbors
    set happy? (patch-richness <= happy-max AND patch-richness >= happy-min)
  ]]

  if happiness-type = "equal-or-greater"
  ;; in this version, patches want to have either a similar number of species to their neighbors OR more species than their neighbors
  ;; they do not want to have fewer species than their neighbors
  [ ask patches
  [ ;; calculates mean richness in the neighboring patches
    let summed-richness sum [patch-richness] of neighbor-set
    set avg-neighbor-richness round (summed-richness / neighbor-count)

    ;; calculates the minimum number of species with which a patch can be happy
    let happy-min (avg-neighbor-richness - yard-difference)
      if max-richness < happy-min [set happy-min max-richness]

    ;; patch is happy if its species richness is similar to or greater than the rounded average richness of its neighbors
    set happy? (patch-richness >= happy-min AND patch-richness <= max-richness) ;; patches are happy unless they have fewer species than their neighbors
   ]]

  ;; making sure the code works to keep patch richness lower than max-richness
  ask patches
  [if max-richness < patch-richness [user-message (word "patch-richness exceeds max-richness for " self)]]

end

to change-unhappy-patches
  ;; unhappy patches are changed by adding common species or removing rare species
  ;; first, we double check that no unhappy patches have exceeded their maximum allowed richness
  ;; then a table is created to hold the species in each neighbor's yard

  ask patches with [ not happy? ]
  [if patch-richness > max-richness [user-message (word "patch-richness exceeds max-richness for " self)]]

  ;; this procedure counts the number of neighbors with each plant species, to identify the common species
  ask patches with [ not happy? ]
  [ set neighbor-species-table table:make
    foreach plant-species-list
  [ the-species -> let num-neighbors-with-species count neighbor-set with
     [ table:has-key? species-table the-species ]
    table:put neighbor-species-table the-species num-neighbors-with-species]

    let the-table-list table:to-list neighbor-species-table
    let shuffle-list shuffle the-table-list ;; do this so that species order is randomized before sorting
    set sorted-list sort-by [[row1 row2] -> (last row1) > (last row2) ] shuffle-list
  ]

  ask patches with [ not happy? ]
  ;; for patches that are not happy because they have too few species
   [ if (patch-richness < (avg-neighbor-richness - yard-difference))
      ;; create a temporary copy of sorted-list
      [ let temp-sorted-list sorted-list
        ;; remove species from the top of temporary list until you reach a species that current patch does not have
        while [(not empty? temp-sorted-list) and (table:has-key? species-table (first (first temp-sorted-list)))]
        [ set temp-sorted-list but-first temp-sorted-list]
        if not empty? temp-sorted-list
        ;; adds the most common species to patch species-table, with a random abundance
        [ table:put species-table (first (first temp-sorted-list)) (1 + random 11) ]
      ]

  ;; for patches that are not happy because they have too many species
  if (patch-richness > (avg-neighbor-richness + yard-difference))
  [ let temp-sorted-list sorted-list
      while [(not empty? temp-sorted-list) and ( not table:has-key? species-table (first (last temp-sorted-list)))]
      [set temp-sorted-list but-last temp-sorted-list]
      if not empty? temp-sorted-list
      [table:remove species-table (first (last temp-sorted-list)) ] ;; removes least common species from patch
    ]

 ;; update plant richness after changing yard
  set patch-richness table:length species-table
  ]
end

to update-color-visualization
  ;; only if patch-richness-visualization switch is on
     ask patches
    [set pcolor scale-color green patch-richness (max [patch-richness] of patches) 0]
end

to update-happy-visualization
  ;; only if patch-richness-visualization switch is on
    ask patches
    [if happy?
      [sprout-happy-faces 1 [set shape "face happy" set color yellow set size 0.5]]
      if not happy?
      [ask happy-faces-here [die]]]
end

to create-output-files
  ;; Produces output on plant species occurance; each species in each patch is listed separately
  let output-species-list (list ( list "P-xcor" "P-ycor" "patch ID" "Block ID" "Species" "Number in yard" ))
  ask patches
  [ let patch-species-data table:to-list species-table
    foreach patch-species-data [ the-row ->
      set output-species-list lput (list pxcor pycor (word pxcor "_" pycor) block-number (first the-row) (last the-row)) output-species-list ]]
  csv:to-file (word "SpeciesOccurrenceEnd-" behaviorspace-run-number ".csv") output-species-list

  ;; output final patch-richness for each patch
  let output-richness-list (list (list "pxcor" "pycor" "patch ID" "block ID" "patch richness"))
  ask patches
  [ set output-richness-list lput (list pxcor pycor (word pxcor "_" pycor) block-number patch-richness) output-richness-list ]
  csv:to-file (word "PatchRichnessEnd-" behaviorspace-run-number ".csv") output-richness-list

  ;; output number of yards that have each plant species; can be used to produce a species rank-abundance curve
  let species-count table:make
  foreach plant-species-list
  [ the-species -> let num-patches-with-species count patches with
    [ table:has-key? species-table the-species ]
    table:put species-count the-species num-patches-with-species]
    set species-count table:to-list species-count
    csv:to-file (word "NumberOfPatchesWithSpeciesEnd-" behaviorspace-run-number ".csv") species-count
end
@#$#@#$#@
GRAPHICS-WINDOW
360
10
1758
1409
-1
-1
13.95122
1
14
1
1
1
0
0
0
1
0
99
0
99
1
1
1
ticks
30.0

BUTTON
15
15
78
48
NIL
setup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
85
15
162
48
Go
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
0

SLIDER
15
55
160
88
neighbor-distance
neighbor-distance
1
10
2.0
1
1
NIL
HORIZONTAL

SLIDER
170
55
315
88
yard-difference
yard-difference
0
25
2.0
1
1
NIL
HORIZONTAL

CHOOSER
15
95
156
140
happiness-type
happiness-type
"equal" "equal-or-greater"
1

SLIDER
15
145
160
178
num-nurseries
num-nurseries
1
20
1.0
1
1
NIL
HORIZONTAL

PLOT
15
275
215
425
mean patch richness
ticks
mean patch richness
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "if patch-richness-visualization = true [plot mean [patch-richness] of patches]"

MONITOR
380
25
597
70
proportion of patches that are happy
count patches with [happy?] / count patches
3
1
11

CHOOSER
15
185
182
230
patch-richness-constraints
patch-richness-constraints
"off" "random" "by-block"
0

SWITCH
15
235
222
268
patch-richness-visualization
patch-richness-visualization
1
1
-1000

SWITCH
200
185
303
218
mimicry
mimicry
0
1
-1000

@#$#@#$#@
## WHAT IS IT?

This is a model of plant communities in urban and suburban residential neighborhoods. These plant communities are important because they provide many benefits to human residents and also have the potential to provide habitat for wildlife such as birds and pollinators. 

The model was designed to explore the social factors that create spatial patterns in biodiversity in yards and gardens. In particular, the model was originally developed to understand the ecological outcomes of 'mimicry', or neighbors copying each other's yard design. Plant nurseries and socio-economic constraints were also added to the model as other potential sources of spatial patterns in plant communities.

The idea for the model was inspired by empirical patterns of spatial autocorrelation that have been observed in yard vegetation in Chicago, Illinois (USA), and other cities, where yards that are closer together are more similar than yards that are farther apart. The idea is further supported by literature that shows that people want their yards to fit into their neighborhood. See 'Credits and References' below for relevant literature.

Currently, the yard attribute of interest is the number of plant species, or species richness. Residents compare the richness of their yards to the richness of their neighbors' yards. If a resident’s yard is too different from their neighbors, the resident will be unhappy and change their yard to make it more similar. 

The model outputs information about the richness and identity of plant species in each yard. This can be analyzed to look for spatial autocorrelation patterns in yard diversity and to explore relationships between mimicry behaviors, yard diversity, and larger scale diversity. 

**Important terms**

_Richness_ - an ecological term meaning the number of species at a location, similar to "diversity"

_Spatial autocorrelation_ - a spatial pattern where things that are closer together in space are more similar to each other. In this case, patches (i.e., yards) that are closer together are more similar in terms of their plant richness

_Mimicry_ - the idea that people might copy aspects of their neighbors' yards


## HOW IT WORKS

Each patch is an individual yard or garden, owned or managed by a different person. People are implicit in this model and cannot be separated from their gardens. 

This model requires an input file to run ('SpeciesList.csv'). This input file should contain a list of plant species and the proportion of yards that each species occurs in. The input file currently being used includes 397 species. Real species names are not used, but the proportion of yards for each species matches the observed distribution in a study of 870 front yards in Chicago, Illinois (USA).

**Setup Procedure**

At setup, plant nurseries are first created that contain some or all of the ornamental (i.e., intentionally planted) plant species that were observed in a study of Chicago residential neighborhoods. The number of nurseries is determined by a slider. If only one nursery is simulated, it contains all plants in the input file. If more than one nursery is simulated, each nursery gets 100 plant species from the input file. Species are added to nurseries randomly from the SpeciesList.csv file, using 'roulette wheel selection'. The probability of a species being assigned to a nursery is based on the proportion of yards in which that plant was observed, so that more common species are more likely to be available in the nurseries. Nurseries are distributed evenly across the landscape. 

Next, plant species richness is assigned randomly to each patch. In some parameter sets, the value of species richness may be constrained by an upper limit that could be determined randomly or could be spatially determined by neighborhood (block location). Constraints are determined by the patch-richness-constraints chooser.

Each patch identifies its nearest plant nursery, from which it will obtain its plant species. Plant species are then assigned to each yard, according to the richness value of that patch. Plant species are again assigned using the roulette wheel selection, so that more common plant species are more likely to be assigned to yards.

Patches identify their 'neighbors', the set of nearby patches that will influence their yard. The 'neighbor-distance' parameter determines which adjacent patches are considered 'neighbors'. This parameter is set by a slider, and its units are patch radius. Neighbor-distance can range from 0-10 patches (i.e., yards). 

**Go Procedure**

When the mimicry switch is turned on, yards compare their richness to the average richness of their neighbors. They are ‘happy’ if their plant species richness is similar to or greater than (depending on the 'happiness-type') the average richness of their neigbors. 

The 'yard-difference' parameter determines how similar patches want to be to their neighbors. It is determined by a slider and its units are number of species. If 'yard-difference' is set to 2, that means that a patch will be happy if it either has the mean number of species as their neighbors, or the mean +/- 2.

If patches are happy, they do not change their richness. If they are NOT happy, they either add or remove a plant species at each tick, depending on the 'happiness-type' selected. When patches add a species, they add the most common species among their neighbors that is not already present in their yard. When patches remove a species, they remove the species that is least common among their neighbors. 

The 'Happiness-type' parameter determines whether a patch is happy with its current richness. There are two options for happiness-type: equal and equal-or-greater. 'Equal' happiness-type means that patches want to be similar to their neighbors, regardless of whether their neighbors have more or fewer species than them. When equal happiness-type is selected, unhappy patches will add or remove species at each tick to become more similar to their neighbors. 'Equal-or-greater' happiness-type means that patches want to have a similar number of species or MORE species than their neighbors, and they will be happy with either situation. When equal-or-greater happiness-type is selected, unhappy patches will only add more species to be similar to their neighbors and species are never removed from patches.

The model runs until all patches are happy or 100 ticks have passed, whichever comes first.

If the mimicry switch is turned off, yards do not change after the setup procedure and the model only runs for one tick.

**Model Outputs**

The model outputs a number of csv files that can be used to measure spatial autocorrelation and plant diversity. The names of output files end in a number, which allows users to analyze different model runs from behavior space. The following files are produced:

  * NumberOfPatchesWithSpeciesEnd - outputs number of yards that have each plant species at the end of the model run, which can be used to produce a species rank-abundance curve
  * PatchRichnessEnd - outputs patch richness for each patch
  * SpeciesOccurrenceEnd - this lists each species on each patch separately

## HOW TO USE IT

Make sure the input file (SpeciesList.csv) is in the same folder as the model. 

Use the interface items, sliders and chooser, to define model parameters and initial conditions. Click SETUP after setting the parameters by the sliders. Then click GO and observe changes on the landscape. 

To analyze diversity and spatial autocorrelation patterns, the output files can be imported into R. R code is being developed specifically for this purpose. 

## THINGS TO NOTICE

There is a switch on the interface that will allow you to turn visualizations on; the default position is 'off' to increase computational speed. When visualizations are on,  patch richness is shown with shades of green, with darker colors indicating higher richness. Happy patches will be shown with a yellow smiley face. Notice how patch richness and the number of happy patches change over time by observing the map, the plot, and the monitor on the interface. 

As the model runs, we generally see the following trends: (1) yards change their richness, especially in the first few ticks, (2) patch colors become more similar across the world, indicating that patches are copying their neighbors, and (3) the number of happy patches increases. The extent to which this happens, and the number of ticks for which this continues to happen, depends on model parameters. 

With some model parameters, if the model runs long enough, all yards will end up having the exact same richness and patch color. With other parameters, we notice the formation of gradients in richness across the world and/or clusters of high or low richness patches. Other sets of parameters result in persistent spatially-random richness.

## THINGS TO TRY

Try to identify the combinations of neighbor-distance, yard-difference, and happiness-type that result in the strongest spatial autocorrelation patterns, and the combinations of parameters that result in no spatial autocorrelation. 

Change the patch-richness-constraints and see how they affect the model dynamics and the final map.

Try using different input files with different numbers and distributions of plant species. Try initializing the model with different values of mean-richness. How do these initial conditions change patterns of diversity?  

## EXTENDING THE MODEL

It might be more realistic to introduce more heterogeneity into the model. This could be done in various ways:

1. Creating ‘super gardeners’ that add more species to their yard ‘just because’ (ie, not because of mimicry)--particularly species not already in their neighborhood or even in the current landscape. In addition to representing a kind of person who probably really exists, this could be a way to bring new species into the landscape that were not initially assigned to patches. Otherwise, there is currently no mechanism in the model that allows new species to come in once the first species have been assigned at setup.

3. Simulating the process of a home being sold and rebuilt by a developer sometime in the middle of the simulation. Developers often start over with the landscaping. This could also be a mechanism for bringing in new species after model setup

4. Implementing random, low-probability changes to happy patches by adding or removing species. This could represent plants dying or new plants becoming available in the stores

5. Heterogeneity imposed on the block scale could be a good way to represent different kinds of neighborhoods. In addition to maximum species richness (which is already implemented with the patch-richness-constraints chooser), neighbor-distance, yard-difference, or happiness type could all depend on block number. 

Different ways to think about neighbors and social influence:

1. Instead of all neighbors being equal in their influence, the model could use a distance-weighted effect where nearby neighbors have more influence than far neighbors. For example, it could calculate difference between a patch and each neighbor one at a time, and weight each difference by how far away the neighbor is. 
Weighted difference between patch A and patch B = (A richness – B richness)/(distance between A and B)

2. The model could limit ‘neighbors’ to patches on the same block. 

3. Social networks could be created (randomly?) throughout the entire landscape, and patches that are connected in a network could also influence each other’s yard design, even if they are not neighbors

4. Certain patches might be more influential than others. This could be based on social networks (eg, those with more connections) or could be based on geography (eg, corner lots that have more visibility), or something else. 

Introducing wildlife and human-nature feedbacks:

1. Eventually the model will include wildlife, such as bees and birds. These organisms will use the yards as habitat. They might move around the landscape and select locations with more suitable habitat (eg, more plant species) or specific plant species, or they might have different survival and/or reproductive rates based on habitat. 

2.  People/patches can respond to the wildlife by changing their yard vegetation, depending on whether they like or do not like having wildlife in their yards. This will create a feedback loop between people, their yards, and wildlife.

Other ideas for extending the model:

1. Abundance of a plant species is currently not used in the model. It could be incorporated (for example) when selecting which species are added to unhappy yards. Not sure how important this would be for model outcomes, but abundance might be relevant for wildlife.

2. Other yard characteristics can be incorporated, such as vegetation structure. Vegetation structure might be especially important for birds.

## CREDITS AND REFERENCES

**Early conceptualization of this model was inspired by the Segration model cited below:**

Wilensky, U. (1997). NetLogo Segregation model. http://ccl.northwestern.edu/netlogo/models/Segregation. Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

**Spatial autocorrelation in yard vegetation has been documented in several studies. Here are some of them:**

Minor ES, Belaire JA, Davis A, Franco M, Lin M. 2016. Socioeconomics and neighbor mimicry drive yard and neighborhood vegetation patterns. In R.A. Francis, J.D.A. Millington, M.A. Chadwick (Eds.) Urban Landscape Ecology: Science, Policy and Practice. Routledge, New York, NY

Minor ES, Lopez B, Smith A, Johnson P. 2023. Plant communities in Chicago residential neighborhoods show distinct spatial patterns. Landscape and Urban Planning 232, 104663

Zmyslony J, Gagnon D. 1998. Residential management of urban front-yard landscape: a random process? Landscape and Urban Planning 40: 295-307

**Other research has shown that people want their yards to fit in with neighborhood norms. Here are some papers:**

Nassauer JI, Wang Z, Dayrell E. 2009. What will the neighbors think? Cultural norms and ecological design. Landscape and urban planning 92: 282-292

Locke DH, Chowdhury RR, et al. 2018. Social norms, yard care, and the difference
between front and back yard management: examining the landscape mullets concept on
urban residential lands. Society and Natural Resources 31: 1169-1188

**Funding:**

This material is based upon work supported by the National Science Foundation under Grant No. 1911327, "OPUS: MCS: The emergence of large-scale patterns of biodiversity from interactions between people, their yards, and urban wildlife"

Other funding came from the LAS Mid-Career Award from the University of Illinois Chicago

## HOW TO CITE

If you mention this model or the NetLogo software in a publication, we ask that you include the citations below.

For the model itself:
Minor ES, Garcia S, Johnson P. 2023. NetLogo Yards Model. University of Illinois Chicago

Please cite the NetLogo software as:
Wilensky, U. (1999). NetLogo. http://ccl.northwestern.edu/netlogo/. Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

building store
false
0
Rectangle -7500403 true true 30 45 45 240
Rectangle -16777216 false false 30 45 45 165
Rectangle -7500403 true true 15 165 285 255
Rectangle -16777216 true false 120 195 180 255
Line -7500403 true 150 195 150 255
Rectangle -16777216 true false 30 180 105 240
Rectangle -16777216 true false 195 180 270 240
Line -16777216 false 0 165 300 165
Polygon -7500403 true true 0 165 45 135 60 90 240 90 255 135 300 165
Rectangle -7500403 true true 0 0 75 45
Rectangle -16777216 false false 0 0 75 45

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

sheep
false
15
Circle -1 true true 203 65 88
Circle -1 true true 70 65 162
Circle -1 true true 150 105 120
Polygon -7500403 true false 218 120 240 165 255 165 278 120
Circle -7500403 true false 214 72 67
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 83 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -7500403 true false 276 85 285 105 302 99 294 83
Polygon -7500403 true false 219 85 210 105 193 99 201 83

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

wolf
false
0
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -7500403 true true 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -7500403 true true -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.2.2
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
<experiments>
  <experiment name="experiment" repetitions="1" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>mean  [patch-richness] of patches</metric>
    <metric>count patches with [happy?]</metric>
    <enumeratedValueSet variable="yard-difference">
      <value value="0"/>
      <value value="2"/>
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="neighbor-distance">
      <value value="1"/>
      <value value="4"/>
      <value value="8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mean-richness">
      <value value="5"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="experiment-March7-2023" repetitions="10" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>count turtles</metric>
    <enumeratedValueSet variable="mean-richness">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="happiness-type">
      <value value="&quot;equal-or-greater&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="yard-difference">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="yards-per-block">
      <value value="25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="neighbor-distance">
      <value value="1"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="yard_run" repetitions="10" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>count turtles</metric>
    <enumeratedValueSet variable="happiness-type">
      <value value="&quot;equal-or-greater&quot;"/>
      <value value="&quot;equal&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="yard-difference">
      <value value="0"/>
      <value value="1"/>
      <value value="2"/>
      <value value="3"/>
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="neighbor-distance">
      <value value="1"/>
      <value value="3"/>
      <value value="6"/>
      <value value="9"/>
      <value value="12"/>
    </enumeratedValueSet>
  </experiment>
</experiments>
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180
@#$#@#$#@
1
@#$#@#$#@

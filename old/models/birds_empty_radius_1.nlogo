extensions [table csv rnd profiler]

globals
[
 ;; yards-per-block  ;; how many houses/yards per block, in x dimension - now a slider on interface
 block-list ;; list of all blocks in the world - not sure if this is useful
 plant-species-list  ;; list of all plant species in the world, created from plant-species-input list
 plant-species-input ;; a list of lists with species name, probability of occurring per yard; read from input file
 output-file-name ;; used to create output files during behavior space experiments
 ;; neighbor-distance  ;; the radius in which other patches are considered 'neighbors' and thus influence yard decisions - now a slider on interface
 ;; yard-difference ;; how similar a patch's richness must be to its neighbors for the patch to be happy - now a slider on interface
 ;; mean-vegetation-volume ;; the mean richness of yards, which is used as a parameter in random-exponential for assigning # of species to each year - now a slider on interface
 ;; happiness-type ;; the algorithm used to determine whether a patch is happy or will change species - now a slider on interface
]
turtles-own
[
  settled?
]




patches-own
[
  block-number  ;; number code for block
  block-mates ;; other patches on block; agentset
  adjacent-block
  vegetation-volume ;; number of plant species on a patch
  ;block-veg
  habitat
  bird-density
  max-density
  ;;max-richness ;; maximum number of plant species a patch can have; this is stochastically assigned to introduce heterogeneity to the landscape; not used in this version
  species-table  ;; table of species in a patch and their abundance; abundance is currently not used
  neighbor-set ;; set of nearby patches that influence yard decisions, based on neighbor-distance
  neighbor-count ;; count of nearby patches that influence yard decisions
  avg-richness ;; avg number of plant species in neighbors' yards
  happy?  ;; for a patch, indicates whether plant species richness is similar to nearby patches
  neighbor-species-table ;; table of species in neighboring yards (ie, yards within neighbor-set) and the number of neighbors that have that species
  sorted-list ;; list of species in neighboring yards, sorted with most common species first
]

to setup
  clear-all

  ;; Read in species list from file, with probability of species being in any yard
  set plant-species-input csv:from-file "veg_structure_input_1.csv"  ;; Read in the file
  set plant-species-input but-first plant-species-input ;; Remove the header line
  set plant-species-list  map first plant-species-input ;; removes all columns but the first one with plant names

  ;; set neighbor-distance 2 ;; set with slider
  ;; set yard-difference 1 ;; set with slider
  ;; set yards-per-block 25 ;; set with slider

  setup-patches
  setup-blocks
  setup-birds
  reset-ticks
end

to setup-patches ;; procedure to assign plant species to each patch and identify neighbors

  ;; sets yard richness
  ask patches
  [
    loop
    [
    set vegetation-volume round random-exponential mean-vegetation-volume ;; changed "richness" to "vegetation-volume"
    if vegetation-volume <= 16 [ stop ]
    ] ;sets vegetation-volume to a random exponential number of mean-vegetation-volume < 16
    ;; 2.9 is mean of yard richness from empirical data
    set plabel vegetation-volume ;; labels patch richness on interface, turned off for behavior space
  ]

  ask patches
  [set pcolor scale-color green vegetation-volume (max [vegetation-volume] of patches) 0]

  ;; create species-table for each patch (and adds abundance to the table)
  ;; plant species are selected for each yard based on the proportion of yards they are in empirically, which is in the plant-species-input list
  ask patches
  [ set species-table table:make
    foreach rnd:weighted-n-of-list vegetation-volume plant-species-input [ [a-species] -> last a-species]
    [ the-species -> table:put species-table (first the-species) (1 + random 11)] ;; abundance of each species can be from 1-10 (this is not used in current model)
  ]

  ;; identifies the neighbors for each patch; these are the nearby yards that will influence yard design choice
  ask patches
  [
    set neighbor-set other patches in-radius neighbor-distance
    ;; show [ self ] of neighbor-set ;; provides list of neighbors - this is just to test the code
    set neighbor-count count neighbor-set
  ]
  ask patches
  [
    set habitat sum [ vegetation-volume ] of patches in-radius 1 ;;change this as well to calculate veg around raidus of patch
  ]
  ask patches
  [
    set max-density floor ((habitat / 80) * 10)
  ]
end

to setup-blocks
  ;; this procedure creates a grid of city blocks with each yard assigned to a block
  ;; this facilitates analysis of plant diversity at larger scales beyond the yard (ie, gamma diversity)

  ask patches
  [
  let block-x floor (pxcor / (yards-per-block / 2))
    ; yards per block was multiplied by 2 so i divided by 2 and made slider evens only - try to stress test this
  let block-y floor (pycor / 2)
    set block-number (100 * block-y) + block-x
  ;set pcolor block-number + 5
  ;set plabel block-number ;; make landscape size change with yards-per-block
  ]
  ask patches
  [
    set block-mates patches with [block-number = [block-number] of myself] ;; adjusted so block-mates also includes self
  ]
  ;ask patches
  ;[
   ; set adjacent-block ; have to make this so that all adjacent blocks are on the list - goal is for moving window type movement from birds
   ; neighbors with [block-number != [ block-number ] of myself] ; change this to radius rather than trying to make blocks work
    ;patches with [ block-number = [block-number + 100] of myself ]
    ;patches with [ block-number = [block-number - 100] of myself ]
    ;patches with [ block-number = [block-number + 1] of myself ]
    ;patches with [ block-number = [block-number - 1] of myself ]
  ;]
;;add something like bird-density to limit birds per patch
end

to setup-birds
  crt 20
  [
    set size .5
    set color blue
    set settled? 0
    setxy random-xcor random-ycor
  ]
  ask turtles ;checks for suitable-habitat (block veg >10) in radius 1. if so moves to one of those patches and becomes settled
  [
    let suitable-habitat patches in-radius 1 with [ habitat > 10 and bird-density < max-density ]
    if any? suitable-habitat in-radius 1
    [
      set settled? 1
      set color red
      move-to one-of suitable-habitat in-radius 1
    ]
  ]
end

to go
  set-density
  kill-birds
  reproduce
  fledge
  explore
  tick
end

to set-density
  ask patches
  [
    set bird-density count turtles in-radius 1
  ]
end

to kill-birds
  ask turtles with [settled? = 0] ;; if the bird is not settled, it is removed from the model
  [
    die
  ]
end

to reproduce
  ask turtles with [settled? = 1] ;; settled birds hatch 1 if they are settled then begin to explore
  [
    hatch 1

    [
      set color blue
      set settled? 0
    ]
  ]
end

to fledge ;;hatchlings move away from parents
  ask turtles with [ settled? = 0 ] ; hatched turtles move away
  [
    rt random 180
    fd 3
  ]
end


to explore ;;i want birds to look at adjacent blocks to the one they are settled on, see if block-veg is good enough, if not, die
  ;;edit this to combine hatchlings and settled birds
  ask turtles
  [
    let my-habitat [habitat] of patch-here
    let suitable-habitat other patches in-radius 1 with [ habitat > my-habitat and (bird-density < max-density) ]
    if any? suitable-habitat in-radius 1
    [
      set settled? 1
      set color red
      move-to one-of suitable-habitat in-radius 1
    ]
  ]
end










@#$#@#$#@
GRAPHICS-WINDOW
330
55
888
614
-1
-1
50.0
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
10
0
10
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
NIL
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
10.0
1
1
NIL
HORIZONTAL

SLIDER
15
90
160
123
yard-difference
yard-difference
0
10
8.0
1
1
NIL
HORIZONTAL

MONITOR
15
280
162
325
mean vegetation volume
mean  [vegetation-volume] of patches
1
1
11

MONITOR
165
280
317
325
std dev of yard  richness
standard-deviation [vegetation-volume] of patches
1
1
11

SLIDER
15
125
192
158
mean-vegetation-volume
mean-vegetation-volume
1
16
3.0
1
1
NIL
HORIZONTAL

CHOOSER
170
55
311
100
happiness-type
happiness-type
"equal" "equal-or-greater"
1

SLIDER
15
160
160
193
yards-per-block
yards-per-block
2
35
12.0
2
1
NIL
HORIZONTAL

BUTTON
215
135
282
168
Profiler
setup                  ;; set up the model\nprofiler:start         ;; start profiling\nrepeat 20 [go]        ;; run something you want to measure\nprofiler:stop          ;; stop profiling\nprint profiler:report  ;; view the results\nprofiler:reset         ;; clear the data
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

MONITOR
15
215
182
260
count patches with [happy?]
count patches with [happy?]
17
1
11

PLOT
55
360
255
510
distribution of veg-volume
NIL
NIL
0.0
16.0
0.0
500.0
true
false
"" ""
PENS
"default" 1.0 1 -14454117 true "" "histogram [ vegetation-volume ]  of patches"

MONITOR
110
525
187
570
settled birds
count turtles with [ settled? = 0 ]
17
1
11

PLOT
55
580
255
730
settled birds over time
years
settled birds
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot count turtles with [ settled? = 1 ]"

@#$#@#$#@
## WHAT IS IT?

This is a model of ecological communities in urban residential neighborhoods. It was designed to explore how social interactions between neighbors could affect patterns of biodiversity in yards and gardens. In particular, the model was created to understand the ecological outcomes of 'mimicry', or neighbors copying each other's yard design. The idea for the model was inspired by empirical patterns of spatial autocorrelation that have been observed in yard vegetation in Chicago, Illinois (USA), and other cities, where yards that are closer together are more similar than yards that are farther apart. The idea is further supported by literature that shows that people want their yards to fit into their neighborhood. See 'Credits and References' below for relevant literature.

The original model implementation was loosely based on the ‘Segregation’ model in the NetLogo library (Wilensky 1997). However, rather than simulating people moving around a neighborhood, this model simulates how urban or suburban residents might change their yards to resemble their neighbors’ yards. 

Currently, the yard attribute of interest is the number of plant species, or species richness. Residents compare the richness of their yards to the richness of their neighbors' yards. If a resident’s yard is too different from their neighbors, the resident will be unhappy and change their yard to make it more similar. 

The purpose of the model is to output information about the richness and identity of plant species in each yard (i.e., alpha diversity). This can be analyzed to look for spatial autocorrelation patterns in alpha diversity and to explore relationships between mimicry behaviors, alpha diversity, and larger scale (gamma) diversity. 

## HOW IT WORKS

Each patch is an individual yard or garden, owned or managed by a different person. People are implicit in this model and cannot be separated from their gardens. 

This model requires an input file to run ('SpeciesList2.csv'). This input file should be a list of plant species and the proportion of yards that each species occurs in. The input file currently being used includes 397 species. Real species names are not used, but the proportion of yards for each species matches the observed distribution in a study of 870 front yards in Chicago, Illinois (USA).

**Setup Procedure**

At setup, plant species richness is assigned randomly to each patch, based on the slider 'mean-richness'. The value of species richness at each patch is drawn from a random-exponential distribution with a mean equal to the 'mean-richness' parameter, and is rounded to the nearest integer. The mean value from empirical data in Chicago front yards is 5.2 species.

The color of the patch indicates its richness, with darker colors indicating more plant species. Once patch richness has been assigned, the corresponding number of plant species are then assigned to each yard. Species are added randomly from SpeciesList2.csv, using 'roulette wheel selection'. The probability of a species being assigned to a patch is based on the proportion of yards in which it was observed, and species are drawn without replacement. Each species in a yard is randomly assigned an abundance value between 1 and 11; this value is not currently used in the model.

Patches identify their 'neighbors', the set of nearby patches that will influence their yard. The 'neighbor-distance' parameter determines which adjacent patches are considered 'neighbors'. This parameter is set by a slider, and its units are patch radius. Patch radius can range from 0-10 patches (i.e., yards). 

Each yard is assigned to a city block and given a block number. The 'yards-per-block' slider determines the number of patches on the x-axis that comprise a block. Blocks are always two patches high (i.e., on the y-axis), with the exception sometimes of the block at the top of the map. Currently, blocks are used only to calculate larger-scale measures of biodiversity. In future versions, different blocks might have different socio-economic conditions, or yards in the same block might have more influence on each other than yards in different blocks.

**Go Procedure**

Yards compare their richness to the average richness of their neighbors. They are ‘happy’ if their plant species richness is similar to or greater than (depending on the 'happiness-type') the average richness of their neigbors. Yards that are happy show a smiley face.

The 'yard-difference' parameter determines HOW similar patches want to be to their neighbors. It is determined by a slider and its units are number of species. If 'yard-difference' is set to 2, that means that a patch will be happy if it either has the mean number of species as their neighbors, or the mean +/- 2.

If patches are happy, they do not change their richness. If they are NOT happy, they either add or remove a plant species at each tick, depending on the 'happiness-type' selected. When patches add a species, they add the most common species among their neighbors that is not already present in their yard. When patches remove a species, they remove the species that is least common among their neighbors. If there is a tie among most or least common species, the species added or removed is selected randomly.

The 'Happiness-type' parameter determines whether a patch is happy with its current richness. There are two options for happiness-type: equal and equal-or-greater. 'equal' happiness-type means that patches want to be similar to their neighbors, regardless of whether their neighbors have more or fewer species than them. When equal happiness-type is selected, unhappy patches will add or remove species at each tick to become more similar to their neighbors. 'equal-or-greater' happiness-type means that patches want to have a similar number or MORE species than their neighbors, and they will be happy with either situation. When equal-or-greater happiness-type is selected, unhappy patches will only add more species to be similar to their neighbors and species are never removed from patches.


**Model Outputs**

The model outputs a number of csv files that can be used to measure spatial autocorrelation and alpha and gamma diversity. The names of output files end in a number, which allows users to analyze different model runs from behavior space. Just before the number is either 'Start' or "End', which indicates whether the output file was created at setup or at the end of the model run. The purpose of the 'Start' output files is to make sure the model is being set up correctly. Most users will be more interested in the 'End' output files. These include the following files:

  * NumberOfPatchesWithSpeciesEnd - outputs number of yards that have each plant species at the end of the model run, which can be used to produce a species rank-abundance curve
  * PatchRichnessEnd - outputs patch richness (alpha diversity) for each patch
  * SpeciesOccurrenceEnd - this lists each species on each patch separately

## HOW TO USE IT

Use the interface items, sliders and chooser, to define model parameters and initial conditions. The most important of the interface items are the 'happiness-type' chooser, 'neighbor-distance' slider, and 'yard-difference' slider. Click SETUP after setting the parameters by the sliders. Then click GO and observe changes on the landscape. The model runs for 100 timesteps (i.e., ticks) before stopping.

To analyze diversity and spatial autocorrelation patterns, the output files can be imported into R. R code is being developed specifically for this purpose. 

## THINGS TO NOTICE

Notice the patch richness (shown with a patch label) and corresponding color. Notice how the mean and standard deviation of yard richness change over time, as does the number of happy patches.

As the model runs, we generally see the following trends: (1) yards change their richness, especially in the first few ticks, (2) patch colors become more similar across the world, (3) the standard deviation of yard richness declines, (4) the number of happy patches increases. The extent to which this happens, and the number of ticks for which this continues to happen, depends on model parameters. 

With some model parameters, if the model runs long enough, all yards will end up having the exact same richness and patch color. With other parameters, we notice the formation of gradients in richness across the world and/or clusters of high or low richness patches. Other sets of parameters result in persistent spatially-random richness.

## THINGS TO TRY

Try to identify the combinations of neighbor-distance, yard-difference, and happiness-type that result in the strongest spatial autocorrelation patterns, and the combinations of parameters that result in no spatial autocorrelation. 

Try using different input files with different numbers and distributions of plant species. Try initializing the model with different values of mean-richness. How do these initial conditions change patterns of alpha and gamma diversity?  

## EXTENDING THE MODEL

Currently every patch on the landscape follows the same rules at all times. It might be more realistic to introduce more heterogeneity into the model. This could be done in various ways:

1. Randomly assigning each patch/resident a maximum value for species richness, that represents an economic or other kind of constraint on their yard decisions. Patches would not exceed this value even if they weren’t happy. This constraint was included in previous versions of the model and either reduced or removed spatial autocorrelation patterns. It could be handled in a different way than before, such as only assigning some people max values, or making max value a function of which block a patch is on.

2. Creating ‘super gardeners’ that add more species--particularly species not already in their neighborhood or even in the current landscape--to their yard ‘just because’ (ie, not because of mimicry). In addition to representing a kind of person who probably really exists, this could be a way to bring new species into the landscape that were not initially assigned to patches. Otherwise, there is currently no mechanism in the model that allows new species to come in once the first species have been assigned at setup.

3. Simulating the process of a home being sold and rebuilt by a developer sometime in the middle of the simulation. Developers often start over with the landscaping. This could also be a mechanism for bringing in new species after model setup

4. Implementing random, low-probability changes to happy patches by adding or removing species. This could represent plants dying or new plants becoming available in the stores

5. Heterogeneity imposed on the block scale could be a good way to represent different kinds of neighborhoods. For example, maximum species richness (described above), neighbor-distance, yard-difference, or happiness type, could all depend on block number. 

Different ways to think about neighbors and social influence:

1. Instead of all neighbors being equal in their influence, the model could use a distance-weighted effect where near neighbors have more influence than far neighbors. For example, it could calculate difference between a patch and each neighbor one at a time, and weight each difference by how far away the neighbor is. 
Weighted difference between patch A and patch B = (A richness – B richness)/(distance between A and B)

2. The model could limit ‘neighbors’ to patches on the same block. 

3. Social networks could be created (randomly?) throughout the entire landscape, and patches that are connected in a network could also influence each other’s yard design, even if they are not neighbors

4. Certain patches might be more influential than others. This could be based on social networks (eg, those with more connections) or could be based on geography (eg, corner lots that have more visibility), or something else. 

Introducing wildlife and human-nature feedbacks:

1. Eventually the model will include wildlife, such as bees and birds. These organisms will use the yards as habitat. They might move around the landscape and select locations with more suitable habitat (eg, more plant species) or specific plant species, or they might have different survival and/or reproductive rates based on habitat. 

2.  People/patches can respond to the wildlife by changing their yard vegetation, depending on whether they like or do not like having wildlife in their yards. This will create a feedback loop between people, their yards, and wildlife.

Other ideas for extending the model:

1. Abundance of a species is currently not used in the model. It could be incorporated (for example) when selecting which species are added to unhappy yards. Not sure how important this would be for model outcomes, but abundance might be relevant for wildlife.

2. Other yard characteristics can be incorporated, such as vegetation structure. Vegetation structure might be especially important for birds.

## RELATED MODELS

(models in the NetLogo Models Library and elsewhere which are of related interest)

## CREDITS AND REFERENCES

**Early conceptualization of this model was inspired by the Segration model cited below:**

Wilensky, U. (1997). NetLogo Segregation model. http://ccl.northwestern.edu/netlogo/models/Segregation. Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

**Spatial autocorrelation in yard vegetation has been documented in several studies. Here are some of them:**

Minor ES, Belaire JA, Davis A, Franco M, Lin M. 2016. Socioeconomics and neighbor mimicry drive yard and neighborhood vegetation patterns. In R.A. Francis, J.D.A. Millington, M.A. Chadwick (Eds.) Urban Landscape Ecology: Science, Policy and Practice. Routledge, New York, NY

Zmyslony J, Gagnon D. 1998. Residential management of urban front-yard landscape: a random process? Landscape and Urban Planning 40: 295-307

**Other research has shown that people want their yards to fit in with neighborhood norms:**

Nassauer JI, Wang Z, Dayrell E. 2009. What will the neighbors think? Cultural norms and ecological design. Landscape and urban planning 92: 282-292

Locke DH, Chowdhury RR, et al. 2018. Social norms, yard care, and the difference
between front and back yard management: examining the landscape mullets concept on
urban residential lands. Society and Natural Resources 31: 1169-1188

**Funding:**

This material is based upon work supported by the National Science Foundation under Grant No. 1911327, "OPUS: MCS: The emergence of large-scale patterns of biodiversity from interactions between people, their yards, and urban wildlife"

Other funding came from the LAS Mid-Career Award from the University of Illinois at Chicago

## HOW TO CITE

If you mention this model or the NetLogo software in a publication, we ask that you include the citations below.
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
  <experiment name="experiment" repetitions="10" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <enumeratedValueSet variable="yard-difference">
      <value value="0"/>
      <value value="2"/>
      <value value="4"/>
      <value value="6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="neighbor-distance">
      <value value="1"/>
      <value value="2"/>
      <value value="4"/>
      <value value="6"/>
      <value value="8"/>
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mean-richness">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="happiness-type">
      <value value="&quot;equal&quot;"/>
      <value value="&quot;equal-or-greater&quot;"/>
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

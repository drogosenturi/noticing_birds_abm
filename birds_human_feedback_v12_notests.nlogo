;; ver 12: This version is relying on the quartile idea for bird-love that produces a bimodal distribution at its end point
;; version only contains final procedures and not homogeneous testing procedures

extensions [rnd]

globals
[
]

patches-own
[
  vegetation-volume ;; number of vegetation layers in a patch
  habitat ;; the total amount of vegetation in all the patches that comprise the habitat of that patch
  max-bird-density ;; the max number of birds a patch can sustain, based on the amount of vegetation in that patch and the surrounding patches
  bird-density ;; the actual number of birds on a patch
  bird-love ;; residents' perception of birds deciding whether they will actively add vegetation for them or not, range from 0-10
  yard-bird-estimate ;; resident estimate of amount of birds on patch
  veg-change-list ;; list of last 10 veg changes, 0 for no change, 1 for pos change, -1 for neg change
]

turtles-own
[
  settled? ;; value of 0 or 1 based on whether or not a bird is on suitable habitat
]

to setup
  clear-all
  setup-patches
  reset-ticks
end

to setup-patches
  ask patches [
    assign-vegetation ;; sets vegetation-volume to a random exponential number of 2.9
  ]
  ask patches [
    calculate-habitat ;; procedure to determine how many birds can use a patch, based on vegetation in that patch and neighboring patches
    setup-birds-new ;; patches sprout max # of birds
    assign-bird-density ;; assigns all bird-related variables (density, love)
    assign-bird-love ;; assign bird-love to patches based on love-distribution
    assign-colors ;; various color visualizations
  ]
end

to assign-vegetation
  ;; normal assign procedure
  loop [
      set vegetation-volume round random-exponential 2.9
      if vegetation-volume <= 16 [ stop ]
    ]
end

to calculate-habitat
    set habitat sum [ vegetation-volume ] of neighbors
    set max-bird-density round ((habitat / (16 * count neighbors)) * 3)
    set bird-density 0
    set veg-change-list [] ;; create empty list for later
end

to setup-birds-new ;; patches sprout turtles up to max-bird-dens
  sprout one-of (range 0 (max-bird-density + 1)) [
      set size .5
      set color white
      set settled? 0
    ]
end

to assign-bird-density
  set bird-density count turtles-here
end

to assign-bird-love
  loop [
    set bird-love round random-normal 6.9 1.3
    if bird-love >= 0 and bird-love <= 10 [ stop ]
  ]
end

to assign-colors ;; testing and analysis
  ;set pcolor scale-color gray bird-love 10 0 ;;bird love colors
  set pcolor scale-color blue vegetation-volume 16 0 ;; veg volume colors
  ;set plabel (word bird-love "," yard-bird-estimate "," bird-density "," vegetation-volume)
  ;set plabel-color 14
  ;set pcolor gray ;; base color
end

to go
  birds-explore ;; mature birds look for habitat
  birds-reproduce ;; mature birds have chance to reproduce and offspring look for habitat
  kill-birds ;; birds that did not settle die
  calculate-bird-density ;; patches set how many birds are on own patch
  update-bird-estimates ;; updates yard-bird-estimate after birds have moved on the landscape
  change-bird-love ;; changes bird love based on bird estimate
  change-vegetation ;; add or remove vegetation based on values of bird-love and bird estimates
  update-habitat ;; calculate habitat after changing vegetation
  ifelse ticks <= 250 [tick] [stop]
end

to birds-explore
   ask turtles [
    set shape "default"
    ifelse (max-bird-density > 0) and (bird-density <= max-bird-density) [
      settle
      stop
    ]
    [
      disperse
    ]
  ]
end

to birds-reproduce
  ask turtles with [settled? = 1] [
    let reproduce-chance random-float 1 ;; settled birds have chance to hatch 1
    if reproduce-chance > 0.5 [ ;; if reproduce chance is bigger than 0.5, reproduce. Test for optimal value
      hatch 1 [
        set shape "circle"
        set size 0.5
        set color blue
        set settled? 0
        disperse ;; offspring move to suitable habitat within dispersal distance away from parent if possible
      ]
    ]
  ]
end

to settle ;; bird checks current patch for suitable habitat, settles if so
  set settled? 1
  set color orange
  set bird-density count turtles-here
end

to disperse
  ;; birds disperse to suitable habitat within defined radius if not settled or do not stop in previous step
  ;; if there is any suitable habitat, birds move to one of the agentset with minumum distance from self
  let suitable-habitat other patches in-radius 40 with [
    max-bird-density > 0 and bird-density < max-bird-density ]
  ifelse any? suitable-habitat in-radius 40 [
    move-to min-one-of suitable-habitat [distance myself]
    set settled? 1
    set color yellow
    set bird-density count turtles-here
  ]
  [
    set settled? 0
    set shape "face sad"
  ]
end

to kill-birds
  ask turtles [
    if settled? = 0 [
      die
    ]
    if settled? = 1 and random-float 1 < 0.30 [die]
  ]
end

to calculate-bird-density
  ask patches [
    set bird-density count turtles-here
  ]
end

to update-bird-estimates ;; patches estimate bird-density of their own yard depending on the amount of vegetation they have
  ask patches [
    ;; yard bird estimate is bird density on patch + bird density of neigbors multiplied by a factor of your own vegetation volume
    set yard-bird-estimate round ((bird-density + (mean [bird-density] of neighbors)) * (vegetation-volume * ((random-float 1) / 2)))
    ;; if a patch estimates 0, but actually has birds around them, add 1 b/c nobody estimates 0 birds (SEM data)
    if bird-density + mean [bird-density] of neighbors > 0 and yard-bird-estimate = 0 ;; if you and neighbors have no birds, don't add 1
    [ set yard-bird-estimate 1 ]
  ]
end

to change-bird-love
  ;; calculate value that is 1/4 of patches
  let quartile round (count patches * 0.25)
  let patch-list sort-on [yard-bird-estimate] patches ;; ascending order list of patches based on estimate
  ;; subset top and bottom 25%
  let bottom-patches sublist patch-list 0 (quartile - 1)
  let top-patches sublist reverse patch-list 0 (quartile - 1)

  ask patch-set top-patches [
    if random-float 1 <= 0.25 [
      if bird-love < 10 [set bird-love bird-love + 1 ]
    ]
  ]

  ask patch-set bottom-patches [
    if random-float 1 <= 0.25 [
      if bird-love > 0 [set bird-love bird-love - 1]
    ]
  ]
end

to change-vegetation ;; add vegetation based on bird-love, with 5% max chance to add or remove
  ask patches
  [
    ;; increase chance and decrease chance have a maximum of 0.05 (5% chance) at max and min bird love values
    ;; will increase or decrease veg based on calculated chance, and if they get past the random number draw
    ;; if no increase or decrease, record 0 on list for no veg change

    let increase-chance bird-love * .005
    let decrease-chance bird-love * -.005 + 0.05

    if increase-chance > random-float 1 and vegetation-volume < 16 [
      set vegetation-volume vegetation-volume + 1 ;; increase veg volume
      set veg-change-list lput 1 veg-change-list ;; records last 10 changes, 1 for increase
      set pcolor blue ;; to see last change
      if length veg-change-list > 10 [
        set veg-change-list remove-item 0 veg-change-list
      ]
      stop
    ]

    if decrease-chance > random-float 1 and vegetation-volume > 0 [
      set vegetation-volume vegetation-volume - 1 ;; decrease veg volume
      set veg-change-list lput -1 veg-change-list ;; records last 10 changes, -1 for decrease
      set pcolor red ;; to see last change
      if length veg-change-list > 10 [
        set veg-change-list remove-item 0 veg-change-list
      ]
      stop
    ]
    ;; only for patches who didnt increase or decrease
    set veg-change-list lput 0 veg-change-list ;; records last 10 changes, 0 for no change
    if length veg-change-list > 10 [
        set veg-change-list remove-item 0 veg-change-list
      ]
  ]
end

to update-habitat
  ask patches [
    set habitat sum [ vegetation-volume ] of neighbors
    set max-bird-density round ((habitat / (16 * count neighbors)) * 3)
    set pcolor scale-color blue vegetation-volume 16 0
  ]
end
@#$#@#$#@
GRAPHICS-WINDOW
0
10
579
590
-1
-1
19.03333333333334
1
10
1
1
1
0
0
0
1
0
29
0
29
1
1
1
ticks
30.0

BUTTON
182
851
243
884
setup X
let x 0\nwhile [x < 1000000] [setup set x x + 1]
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
585
227
661
272
Birds
count turtles
17
1
11

TEXTBOX
277
943
487
971
love, yard, neighbors, actual, veg
11
0.0
1

BUTTON
160
608
223
641
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
229
608
292
641
NIL
go\n
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

MONITOR
586
279
660
324
patch count
count patches
17
1
11

@#$#@#$#@
## PURPOSE AND PATTERNS

This is a model of bird population dynamics on a landscape of urban residential yards controlled by decision-making human agents. The purpose of this model is to understand the feedback between human attitudes, yard management decisions, and bird populations. Spatial patterns of vegetation density, bird populations, and human attitudes toward birds are all used to understand where and in what direction feedbacks are occurring.

## ENTITIES, STATE VARIABLES, AND SCALE

The entities of this model are birds, yards, and humans. Birds move on the landscape in search of viable habitat in order to survive and reproduce. Birds have two state variables: birds that have found habitat, and birds that are looking for habitat, determined as “settled?” with the values of 0 (not settled) and 1 (settled). 
Yards are habitat for birds. The primary state variable of yards is vegetation-volume, the number of vegetation layers in the yard, which determines how many birds can settle on any specific yard. There can be up to 16 vegetation layers in the yard.

Humans determine whether yard vegetation layers are added, removed, or unchanged. Humans have the state variable of ‘bird-love’, ranging from 0 to 10, in which a higher value makes them more likely to add vegetation to support birds and a lower value makes them more likely to remove vegetation to get rid of birds. 
Humans and yards are not explicitly separate agents but are best described separately for the model concept.


## HOW TO USE IT

Hit setup then hit go! Watch how the birds move and the yards change their vegetation. Darker means more vegetation.

## PROCESS OVERVIEW AND SCHEDULING

Each time-step in this model represents a summer breeding season, no longer than 5 months. With each tick, the model advances to the next year’s breeding season. 
For the go procedure, the model first executes procedures related to the birds. First, ‘birds-explore’, where birds ‘disperse’ on the landscape to find the best habitat with the lowest ‘bird-density’. Next, ‘birds-reproduce’, where birds have a 50% chance to reproduce successfully and the offspring ‘disperse’ away from the parent. ‘Kill-birds’ is executed next, where any bird has a 30% chance to die, and all birds with ‘settled?’ = 0 die. Then, bird-density is calculate with ‘calculate-bird-density’. Next are the processes of human decision-making. First, humans ‘change-bird-love’, increasing it if they see more birds, and decreasing it if there are less sightings of birds. Next, humans ‘change-vegetation’ in their yards, having a higher chance to increase vegetation if they have a higher value of ‘bird-love’, or a higher chance of removing vegetation if they have a lower value of ‘bird-love’. Finally, patches ‘update-habitat’ recalculating their ’habitat’ value based on vegetation addition and removal and the model ticks forward to the next summer breeding season.


## DESIGN CONCEPTS

Basic principles. The ideas of this model are based on the findings of Garfinkel et al. (2024) about feedback loops that exist between human attitudes toward birds, yard wildlife-friendly indices, and bird populations, in addition to the Extinction of Experience (Pyle) and Noticing Nature (Hamlin and Richardson 2022?) feedback cycles. In general, we believe that when people actively see more wildlife, they gain interest in wildlife and look for ways to support them, such as by adding vegetation in their yards to provide habitat. In addition, people have been shown to overestimate birds if they have more vegetation in their gardens (ref?). The ideas of feedbacks between human attitudes, sightings of birds, and yard vegetation as habitat for birds are used in the sub-models determining bird and human behaviors. This model should, ideally, provide insight on how to manage residential yards to support and conserve bird populations.
 
Emergence. The most intriguing emergence in the model are the feedback loops that appear on the landscape: the Extinction of Experience cycle, when there are few birds and low vegetation, and Noticing Nature cycle, where there are many birds and rich vegetation. Output such as the rate of vegetation increase, bird populations, and bird-love value in relation to landscape metrics are some options to investigate this emergence. 

Adaptation. Birds adapt based on the available habitat of yards and the bird-density of the yard. If there is not enough habitat, birds cannot move to that yard, and if there are too many birds, they must disperse, or die. Humans adapt based on bird sightings and attitudes toward birds. If humans see many birds and have good attitudes toward birds, they will plant more vegetation or remove it in the opposite scenario.

Objectives. Bird success is measured by their ability to find habitat and have offspring. In any given year, they may be pushed out of their habitat, have the chance to die, or disperse to a new yard.
Learning. Humans change their attitude toward birds based on how many birds they see. If they see less birds, they will stop planting vegetation for birds. If they see more birds, they will plant more vegetation for birds.
Prediction. Nothing yet.
Sensing. Birds sense patch habitat values and know if they can live on said patch. Humans sense the number of birds on their yard and use their estimate to influence bird-love change.

Interactions. Birds indirectly interact with each other through competition for limited habitat. Bird offspring makes an effort to disperse away from the parent. Humans interact with birds indirectly via their influence on human bird-estimates.
Stochasticity. There are a few stochastic elements in the model. First, settled? = 1 bird survival is based on a 30% chance to die each year. Modeling actual survivorship would be cumbersome to the overall goals of the model. Next, humans estimate bird populations based on actual bird populations multiplied by a random factor. This is due to the fact that real people have been shown to estimate bird populations inaccurately. Humans also decide to increase or decrease vegetation based on a 5% probability at maximum and minimum values of bird-love.

Collectives. Not yet.

Observation. Bird-love values, bird populations by area, vegetation-volume of patches, and the change of these parameters over time in relation to position on the landscape are all outputs that can be used to answer questions with this model. 

## INITIALIZATION

Landscapes may vary in size depending on size of the city or neighborhood you wish to model. Generally, a landscape size that is too small (i.e. less than 100 patches) would fail to reveal different feedbacks occurring on the landscape at once. On the other hand, a landscape that is too large (i.e. 500,000 patches) might be entirely unrealistic for a connected neighborhood.

On setup, setup-patches assigns vegetation-volume values to yards based on an exponential distribution with a variance of 2.9, mimicking the distribution and variance of vegetation layer data collected in Chicago, IL, USA (who collected?). Habitat values are then calculated by the yards. Setup-birds sprouts birds on yards based on the yard habitat value, supporting a maximum of 5 birds. Assign-bird-density counts the number of birds in a yard. Assign-bird-love assigns humans bird-love values based on a normal distribution with a variance of 1.9, representing the distribution and variance of empirical data of human attitudes toward birds collected in Chicago, IL, USA (Belaire).

Initialization of the model is never static – each initialization, while using the same distributions every time, will randomly assign values of bird-love, vegetation-volume, and bird populations to each patch.

## SUBMODELS

Birds-explore. Birds make the decision to move, or not. If the patch they are currently on can support more than 0 birds, and is not above the maximum number of birds, they will settle and stop the procedure. Otherwise, birds disperse.

Disperse. Birds identify potential habitats within their dispersal-distance. Potential habitats are patches that can support 1 or more birds and are not filled to capacity with other birds. If there are multiple habitats identified, the bird will move to the available yard that is closest to them.
Birds-reproduce. Birds that are settled (settled? = 1) will have a 50% chance to hatch 1 turtle with settled? = 0. The offspring will then follow the disperse procedure.

Kill-birds. Remaining birds on the landscape with settled? = 0 will die. In addition, all birds on the landscape will have a 30% chance to die.
Calculate-bird-density. Patches count the number of turtles on their patch for subsequent calculations.

Update-bird-estimates. Humans will now estimate birds randomly based on bird density and a factor of the vegetation volume on their patch. The equation is as follows:
yard-bird-estimate = round ((bird-density + (mean [bird-density] of neighbors)) * (vegetation-volume * ((random-float 1) / estimate-factor)))
Based on empirical data, it is unlikely for anyone to say that there are 0 birds, so people always estimate at least 1 bird, unless there are 0 birds in the surrounding 8 patches.

Change-bird-love. Patches are added to a list sorted in ascending order by their yard-bird-estimate values. The upper and lower quartiles are then determined and have a 15% chance to increase and decrease bird-love, respectively. The maximum bird-love value is 10 and the minimum is 0.

Change-vegetation. Patches have a 5% maximum chance with maximum or minimum bird-love to change or remove vegetation, respectively. For bird-love values between the maximum and minimum, increase and decrease chances are determined on a linear scale as follows:
increase-chance = bird-love * .005
decrease-chance = bird-love * -0.005 + 0.05

If the increase chance wins against a random number, the patch will increase vegetation on increments of 1 with a maximum of 16 and stop. If the decrease chance wins against a random number, the patch will decrease vegetations in increments of 1, bound by 0.

Update-habitat. Patches calculate habitat value to account for any changes in vegetation.



## EXTENDING THE MODEL

* How do results change when yards are small vs. big; rural, suburban, urban

* Changing how birds are shared/observed between neighbors (different scales?)

* add something to downgrade bird-love value 
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
NetLogo 6.4.0
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
<experiments>
  <experiment name="experiment" repetitions="1" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>mean vegetation-volume</metric>
    <enumeratedValueSet variable="mean-vegetation-volume">
      <value value="2"/>
      <value value="3"/>
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="dispersal-distance">
      <value value="1"/>
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="habitat-radius">
      <value value="2"/>
      <value value="3"/>
      <value value="4"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="test1" repetitions="1" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <exitCondition>ticks = 30</exitCondition>
    <metric>mean [vegetation-volume] of patches</metric>
    <metric>mean [habitat] of patches</metric>
    <metric>mean [bird-density] of patches</metric>
    <metric>mean [max-bird-density] of patches</metric>
    <metric>count patches with [bird-love = 0]</metric>
    <metric>count patches with [bird-love = 1]</metric>
    <metric>count patches with [bird-love = 2]</metric>
    <metric>change-count</metric>
    <enumeratedValueSet variable="max-bird">
      <value value="5"/>
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mean-vegetation-volume">
      <value value="3"/>
      <value value="3.5"/>
      <value value="4"/>
      <value value="4.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="dispersal-distance">
      <value value="1"/>
      <value value="2"/>
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="habitat-radius">
      <value value="0"/>
      <value value="1"/>
      <value value="2"/>
      <value value="3"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="sensitivity" repetitions="10" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <postRun>export-world "world.csv"</postRun>
    <timeLimit steps="1000"/>
    <exitCondition>not any? turtles</exitCondition>
    <metric>count turtles</metric>
    <metric>count patches with [bird-love = 0]</metric>
    <metric>count patches with [bird-love = 1]</metric>
    <metric>count patches with [bird-love = 2]</metric>
    <metric>count patches with [bird-love = 3]</metric>
    <metric>count patches with [bird-love = 4]</metric>
    <metric>count patches with [bird-love = 5]</metric>
    <metric>count patches with [bird-love = 6]</metric>
    <metric>count patches with [bird-love = 7]</metric>
    <metric>count patches with [bird-love = 8]</metric>
    <metric>count patches with [bird-love = 9]</metric>
    <metric>count patches with [bird-love = 10]</metric>
    <metric>max [change-count] of patches</metric>
    <metric>mean [change-count] of patches</metric>
    <metric>min [change-count] of patches</metric>
    <metric>max [veg-change] of patches</metric>
    <metric>mean [veg-change] of patches</metric>
    <metric>min [veg-change] of patches</metric>
    <metric>mean [habitat] of patches</metric>
    <steppedValueSet variable="max-bird" first="1" step="1" last="15"/>
    <steppedValueSet variable="mean-vegetation-volume" first="2" step="0.2" last="5"/>
    <steppedValueSet variable="dispersal-distance" first="1" step="1" last="5"/>
    <steppedValueSet variable="habitat-radius" first="1" step="1" last="5"/>
  </experiment>
  <experiment name="debug" repetitions="100" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="1000"/>
    <exitCondition>count turtles = 0</exitCondition>
    <metric>count turtles</metric>
    <enumeratedValueSet variable="max-bird">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mean-vegetation-volume">
      <value value="4.4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="dispersal-distance">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="habitat-radius">
      <value value="2"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="sens_2" repetitions="10" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <exitCondition>ticks = 1001</exitCondition>
    <metric>count turtles</metric>
    <metric>count patches with [pcolor = blue]</metric>
    <metric>count patches with [pcolor = red]</metric>
    <metric>count patches with [pcolor = gray]</metric>
    <metric>mean [vegetation-volume] of patches</metric>
    <metric>sum [veg-up] of patches</metric>
    <metric>sum [veg-down] of patches</metric>
    <metric>mean [bird-love] of patches</metric>
    <metric>mean [max-bird-density] of patches</metric>
    <metric>min [max-bird-density] of patches</metric>
    <metric>max [max-bird-density] of patches</metric>
    <enumeratedValueSet variable="estimate-factor">
      <value value="1"/>
      <value value="2"/>
      <value value="4"/>
      <value value="6"/>
      <value value="8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-bird">
      <value value="5"/>
      <value value="7"/>
      <value value="9"/>
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mean-vegetation-volume">
      <value value="2.9"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="love-change-threshold">
      <value value="0.05"/>
      <value value="0.2"/>
      <value value="0.4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="log-slope">
      <value value="0.01"/>
      <value value="0.05"/>
      <value value="0.1"/>
      <value value="0.15"/>
      <value value="0.2"/>
      <value value="0.25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="love-distribution">
      <value value="6.9"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="dispersal-distance">
      <value value="40"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="habitat-radius">
      <value value="6"/>
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
0
@#$#@#$#@

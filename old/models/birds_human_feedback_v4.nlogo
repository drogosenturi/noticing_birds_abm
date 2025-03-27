;; this version is aiming to see if neighbors can influence each other to like birds more

extensions [rnd]

globals
[
  ;habitat-radius ;; determines how many patches are part of a bird's habitat
  ;dispersal-distance ;; how far a bird can move from its original patch
  ;mean-vegetation-volume ;; empirical value = 2.9
  change-count ;; to keep track of bird-love value changes
]

patches-own
[
  count-patches ;; the number of patches surrounding each patch that are counted as the same habitat - based on habitat-radius
  vegetation-volume ;; number of vegetation layers in a patch
  habitat ;; the total amount of vegetation in all the patches that comprise the habitat of that patch
  max-bird-density ;; the max number of birds a patch can sustain, based on the amount of vegetation in that patch and the surrounding patches
  bird-density ;; the actual number of birds on a patch
  bird-love ;; residents' perception of birds deciding whether they will actively add vegetation for them or not, values 0, 1 or 2 (dislike, neutral, love)
  bird-smart ;; determines residents' accuracy of estimating birds at the yard and neighborhood scales, values 0 or 1 (not smart or smart)
  yard-bird-estimate ;; an estimate of amount of birds in patch, by patch
  neighbor-bird-estimate ;; estimate of birds in a defined neighborhood (currently 'neighbors' primitive, by each patch)
  neighbor-bird-count ;; actual count of birds in the neighborhood
]

turtles-own
[
  settled? ;; value of 0 or 1 based on whether or not a bird is on suitable habitat
]

to setup
  clear-all
  setup-patches
  setup-birds
  assign-bird-variables
  reset-ticks
end

to setup-patches

  ;; procedure for setting veg volume
  ;; sets vegetation-volume to a random exponential number of mean-vegetation-volume < 16

  ask patches
  [
    loop
    [
      set vegetation-volume round random-exponential mean-vegetation-volume
      if vegetation-volume <= 16 [ stop ]
    ]
   ]

  ;; procedure to determine how many birds can use a patch, based on vegetation in that patch and surrounding patches
  ask patches
  [
    set count-patches count patches in-radius habitat-radius ;; the number of surrounding patches used to calculate max bird density on a patch
    ;; give own yard more weight by adding mean of neighbors
    set habitat sum [ vegetation-volume ] of patches in-radius habitat-radius
    ;set pcolor scale-color blue vegetation-volume 16 0
    ;; slider to experiment with diff max bird-density?
    set max-bird-density floor ((habitat / (16 * count-patches)) * max-bird)
    set bird-density 0
  ]
end

to setup-birds
  crt count patches * 2
  [
    set size .5
    set color white
    set settled? 0
    setxy random-xcor random-ycor
    pen-down
  ]
  ask patches
  [
    set bird-density count turtles-here
  ]
end

to assign-bird-variables
  ;; assign probabilities to values of bird-love
  let bird-love-weights
  [
    [ 0 .10 ]
    [ 1 .85 ]
    [ 2 .05 ]
  ]
  ;; assign each patch a value of bird-love (weighted) and bird-smart
  ask patches
  [
    set bird-love first rnd:weighted-one-of-list bird-love-weights [ [p] -> last p ]
    set bird-smart random 2
    ;set plabel (word bird-smart "," bird-love "," yard-bird-estimate "," neighbor-bird-estimate "," bird-density "," vegetation-volume)
    set plabel-color 14
  ]
  ;; testing w/ color
  ask patches with [bird-love = 1]
  [
    set pcolor gray
  ]
  ask patches with [bird-love = 0]
  [
    set pcolor white
  ]
  ask patches with [bird-love = 2]
  [
    set pcolor black
  ]
end

to go
  birds-explore
  birds-reproduce
  kill-birds
  calculate-bird-density
  update-estimates ;; updates yard estimates after birds have moved on the landscape
  change-bird-love
  add-remove-vegetation ;; add or remove vegetation based on values of bird-love and bird estimates
  testing
  tick
end

to birds-explore
   ask turtles
  [
    set shape "default"
    if max-bird-density > 0 and bird-density <= max-bird-density ; bird checks current patch for suitable habitat, settles if so
    [
      set settled? 1
      set color red
      stop ; Birds have a 5% chance to move onto the next step ; test for effect
    ]
    ;; birds disperse to suitable habitat within defined radius if not settled or do not stop in previous step
    let suitable-habitat other patches in-radius dispersal-distance with [max-bird-density > 0 and bird-density < max-bird-density]
    if any? suitable-habitat in-radius dispersal-distance
    [
      move-to one-of suitable-habitat
      set settled? 1
      set color yellow
      set bird-density count turtles-here ;; this works properly and prevents birds from exceeding max-bird-density of patch
    ]
  ]
end

to birds-reproduce
  ask turtles with [settled? = 1] ;; settled birds hatch 1
  [
    ;; chance to reproduce? related to density of birds?
    hatch 1
    [
      set shape "circle"
      set size 0.5
      set color blue
      set settled? 0
      pen-down
      ;; offspring move to suitable habitat within dispersal distance away from parent if possible
      let suitable-habitat other patches in-radius dispersal-distance with [max-bird-density > 0 and bird-density < max-bird-density]
      if any? suitable-habitat in-radius dispersal-distance
      [
        move-to one-of suitable-habitat
        set settled? 1
        set color green
        set bird-density count turtles-here
      ]
    ]
  ]
end

to kill-birds
  ask turtles
  [
   if settled? = 0 [die]
   if settled? = 1 and random-float 1 < 0.30 [die]
  ]
end

to calculate-bird-density
  ask patches
  [
    set bird-density count turtles-here
    set neighbor-bird-count sum [bird-density] of neighbors
  ]
  cd
end

to update-estimates ;; neighbor-bird-estimate is divided by the count of neighbors to normalize the comparison of yard-bird-estimate to neighbor-bird-estimate when adding or removing vegetation
  ask patches with [bird-smart = 0]
  [
    set neighbor-bird-estimate round ((neighbor-bird-count / count neighbors) * random-float 2.50) ; estimate can be anywhere from 0% - 250% accurate
    set yard-bird-estimate round (bird-density * random-float 2.50)
  ]

  ask patches with [bird-smart = 1]
  [
    set neighbor-bird-estimate round ((neighbor-bird-count / count neighbors) * ((random-float 0.4) + 0.8)) ; estimate can be 80% to 120% accurate in increments of 1%
    set yard-bird-estimate round (bird-density * ((random-float 0.4) + 0.8))
  ]
end

to change-bird-love
  ;; patches who hate birds have a 1% weighted chance to be influenced by their neighbors
  ask patches with [ bird-love = 0 ]
  [
    let influencers neighbors with [bird-love = 2]
    if any? influencers
    [
      if random-float 1.0 >= (.90 - (.01 * count influencers))
      [
        set bird-love bird-love + 1
        set change-count change-count + 1
        stop
      ]
    ]
  ]
  ;; patches who are neutral have a .1% weighted chance to be influenced by their neighbors
  ask patches with [ bird-love = 1]
  [
    let influencers neighbors with [bird-love = 2]
    if any? influencers
    [
      if random-float 1.0 >= (.99 - (.01 * count influencers))
      [
        set bird-love bird-love + 1
        set change-count change-count + 1
      ]
    ]
  ]
  ;; have a chance to downgrade your bird-love value due to random occurence based on surrounding birds
  ask patches with [bird-love > 0 and vegetation-volume < 8]
  [
    if bird-density >= (max-bird-density - 1)
    [ if random-float 1 > .99
      [
        set bird-love bird-love - 1
        set change-count change-count + 1
      ]
    ]
  ]
end

to add-remove-vegetation ;; add vegetation if you love birds and you don't have enough in your yard
  ;; add vegetation if you love birds and you don't have enough in your yard, remove if you hate birds - update habitat variable
  ask patches with [bird-love = 2 and vegetation-volume < 16]
  [
    ifelse yard-bird-estimate < neighbor-bird-estimate ;; consider adding a weight to own yard bird estimate (-1?)
    [ if random-float 1 > .50 [set vegetation-volume vegetation-volume + 1 ] ]
    [ if random-float 1 > .80 [set vegetation-volume vegetation-volume + 1 ] ]
  ]
  ;; remove vegetation if you hate birds
  ask patches with [ bird-love = 0 and vegetation-volume > 0 ]
  [
    if yard-bird-estimate > (neighbor-bird-estimate)
    [ set vegetation-volume vegetation-volume - 1 ]
  ]
  ;; update habitat variable
  ask patches
  [
    set habitat sum [ vegetation-volume ] of patches in-radius habitat-radius
    set max-bird-density floor ((habitat / (16 * count-patches)) * max-bird)
    ;set pcolor scale-color blue vegetation-volume 16 0
  ]
end

to testing
  ask patches
  [
    ;set plabel (word bird-smart "," bird-love "," yard-bird-estimate "," neighbor-bird-estimate "," bird-density "," vegetation-volume)
    set plabel (word bird-density "," max-bird-density "," vegetation-volume)
    set plabel-color 14
  ]
  ;; testing colors
  ask patches with [bird-love = 1]
  [
    set pcolor gray
  ]
  ask patches with [bird-love = 0]
  [
    set pcolor white
  ]
  ask patches with [bird-love = 2]
  [
    set pcolor black
  ]
  print change-count
end
@#$#@#$#@
GRAPHICS-WINDOW
369
31
1444
1107
-1
-1
34.42
1
10
1
1
1
0
0
0
1
-15
15
-15
15
0
0
1
ticks
30.0

SLIDER
19
37
191
70
habitat-radius
habitat-radius
0
10
3.0
1
1
NIL
HORIZONTAL

BUTTON
28
165
91
198
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
99
165
162
198
NIL
go
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
249
630
332
675
Birds
count turtles
17
1
11

SLIDER
19
79
191
112
dispersal-distance
dispersal-distance
1
5
3.0
1
1
NIL
HORIZONTAL

SLIDER
14
121
207
154
mean-vegetation-volume
mean-vegetation-volume
1
16
4.1
.1
1
NIL
HORIZONTAL

TEXTBOX
473
622
683
650
smart, love, yard, neighbors, actual, veg
11
0.0
1

PLOT
22
507
222
657
mean-vegetation over time
time
mean veg volume
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot mean [vegetation-volume] of patches"

BUTTON
53
204
157
237
NIL
birds-explore
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
46
243
165
276
NIL
birds-reproduce\n
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
65
283
140
316
die :(
kill-birds\ncalculate-bird-density
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
43
322
176
355
residents estimate
update-estimates
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
30
365
193
398
add/remove vegetation
add-remove-vegetation\ntick
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
25
402
197
435
max-bird
max-bird
0
15
10.0
1
1
NIL
HORIZONTAL

BUTTON
172
164
235
197
go 30
ifelse ticks <= 30 [go] [stop]
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
255
164
325
197
go 100
ifelse ticks <= 100 [go] [stop]
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

@#$#@#$#@
## WHAT IS IT?

(a general understanding of what the model is trying to show or explain)

## HOW IT WORKS

(what rules the agents use to create the overall behavior of the model)

## HOW TO USE IT

(how to use the model, including a description of each of the items in the Interface tab)

## THINGS TO NOTICE

(suggested things for the user to notice while running the model)

## THINGS TO TRY

(suggested things for the user to try to do (move sliders, switches, etc.) with the model)

## EXTENDING THE MODEL

* How do results change when yards are small vs. big; rural, suburban, urban

* Changing how birds are shared/observed between neighbors (different scales?)

* add something to downgrade bird-love value 

## NETLOGO FEATURES

(interesting or unusual features of NetLogo that the model uses, particularly in the Code tab; or where workarounds were needed for missing features)

## RELATED MODELS

(models in the NetLogo Models Library and elsewhere which are of related interest)

## CREDITS AND REFERENCES

(a reference to the model's URL on the web if it has one, as well as any other necessary credits, citations, and links)
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

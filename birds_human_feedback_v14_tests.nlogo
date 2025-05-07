extensions [rnd]

globals
[
  ;habitat-radius ;; determines how many patches are part of a bird's habitat
  ;dispersal-distance ;; how far a bird can move from its original patch
  ;mean-vegetation-volume ;; empirical value = 2.9, used in setup only
  ;max-bird ;; sets the maximum amount of birds possible on a single patch - used to calculate max-bird-density - set to 3
  ;love-distribution ;; distribution of bird-love on setup based on empirical data from Belaire
  ;change-chance ;; the number the random-float change chance is compared to. Correlates to % chance to change bird love
  increase-count ;; keep track of bird-love increase (remove in final)
  decrease-count ;; to keep track of bird-love decrease
  adults
  fledglings
  babies
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
  veg-changes ;; sum of veg-change-list, showing whether patch veg is changing positively or negative for past 5 years
]

turtles-own
[
  settled? ;; value of 0 or 1 based on whether or not a bird is on suitable habitat
  age
]

to setup
  clear-all
  setup-patches
  reset-ticks
  go
end

to setup-patches
  ask patches [
    assign-vegetation ;; sets vegetation-volume to a random exponential number of mean-vegetation-volume < 16
  ]
  ask patches [
    calculate-habitat ;; procedure to determine how many birds can use a patch, based on vegetation in that patch and neighboring patches
    setup-birds ;; patches sprout max # of birds
    assign-bird-density ;; assigns all bird-related variables (density, love)
    assign-bird-love ;; assign bird-love to patches based on love-distribution
    assign-colors ;; various color visualizations
  ]
end

to assign-vegetation
  ;; normal assign procedure
  loop [
      set vegetation-volume round random-exponential 3 ;; random-exponential 3 matches empirical distribution of 1000 chicago yards
      if vegetation-volume <= 16 [ stop ]
    ]
end

to calculate-habitat
    set habitat sum [ vegetation-volume ] of neighbors
    set max-bird-density round ((habitat / (16 * count neighbors)) * 3) ;; 3 is decided value of max-bird
    set bird-density 0
    set veg-change-list [] ;; create empty list for later
end

to setup-birds ;; patches sprout turtles up to max-bird-dens
  sprout one-of (range 0 (max-bird-density + 1)) [
      set size .5
      set color white
    set settled? 1
    set age random 4
    ]
end

to assign-bird-density
  set bird-density count turtles-here
end

to assign-bird-love
  loop [
    set bird-love round random-normal 6.9 1.3 ; empircal love-distribution is 6.9 variance 1.3
    if bird-love >= 0 and bird-love <= 10 [ stop ]
  ]
end

to assign-colors ;; testing and analysis
  ;set pcolor scale-color gray bird-love 10 0 ;;bird love colors
  ;set pcolor scale-color 66 vegetation-volume 16 0 ;; veg volume colors
  ;set plabel (word bird-love "," yard-bird-estimate "," bird-density "," vegetation-volume)
  ;set plabel-color 14
  ;set pcolor gray ;; base color
end


to go
  birds-explore ;; mature birds look for habitat
  kill-birds ;; birds that did not settle die
  birds-reproduce ;; mature birds have chance to reproduce and offspring look for habitat
  calculate-bird-density ;; patches set how many birds are on own patch
  update-bird-estimates ;; updates yard-bird-estimate after birds have moved on the landscape
  change-bird-love ;; changes bird love based on bird estimate
  change-vegetation ;; add or remove vegetation based on values of bird-love and bird estimates
  update-habitat ;; calculate habitat after changing vegetation
  visual ;; colors/labels for testing
  ifelse count turtles = 0 or ticks >= max-tick [
    stop
  ]
  [tick]
end

to birds-explore
  ask turtles with [age = 1] [
  ; if offspring live past first dispersal, they become adults
    set shape "default"
  ]
  ask turtles with [shape = "circle"] [
    disperse-fledglings
    stop
  ]
  ask turtles with [shape = "default"] [
    set size 0.75
    set color red
    if random-float 1 < .05 [
      ;disperse-adults
    ]
  ]
end

to disperse-fledglings
  let suitable-habitat other patches in-radius (max-pycor / random-float 2) with [
    max-bird-density > 0 and bird-density < max-bird-density
  ]
  ifelse any? suitable-habitat [
    move-to max-one-of suitable-habitat [distance myself]
    settle
  ]
  [ set color yellow ]
end

to disperse-adults ;; remove? doesn't really affect the model
  let suitable-habitat other patches in-radius 2 with [ ;; make this so they stay on the same patch or VERY close
    max-bird-density > 0 and bird-density < max-bird-density
  ]
  if any? suitable-habitat [
    move-to min-one-of suitable-habitat [distance myself]
    settle
    set color yellow
  ]
end

to settle ;; bird checks current patch for suitable habitat, settles if so
  set settled? 1
  set bird-density count turtles-here
end

to kill-birds
  ask turtles [
    if age > 3 [die]
    ifelse settled? = 0 [
      die
    ]
    [ set age age + 1 ]
  ]
end

to birds-reproduce
  ask turtles with [shape = "default"] [
    hatch offspring [
      set shape "circle"
      set size 0.25
      set color blue
      set settled? 0
      set age 0
    ]
  ]
end

to calculate-bird-density
  ask patches [
    set bird-density count turtles-here with [settled? = 1]
  ]
end

to update-bird-estimates
  ;; patches estimate bird-density of their own yard depending on the amount of vegetation they have -- NO LONGER IMPLEMENTED
  ask patches [
    ;; yard bird estimate is bird density on patch + bird density of neigbors
    ifelse weighted-estimate [
      set yard-bird-estimate round ((bird-density + (mean [bird-density] of neighbors)) * (vegetation-volume * (random-float 1)))
    ]
    [ set yard-bird-estimate round ((bird-density + (mean [bird-density] of neighbors))) ]
    ;; if a patch estimates 0, but actually has birds around them, add 1 b/c nobody estimates 0 birds (SEM data)
    if bird-density + mean [bird-density] of neighbors > 0 and yard-bird-estimate = 0 ;; if you and neighbors have no birds, don't add 1
    [ set yard-bird-estimate 1 ]
  ]
end

to change-bird-love
  ;; calculate value that is 1/4 of patches
  let quartile round (count patches * quartile-size)
  let patch-list sort-on [yard-bird-estimate] patches ;; ascending order list of patches based on estimate
  ;; subset top and bottom 25%
  let bottom-patches sublist patch-list 0 (quartile - 1)
  let top-patches sublist reverse patch-list 0 (quartile - 1)

  ask patch-set top-patches [
    if random-float 1 <= change-chance [
      if bird-love < 10 [set bird-love bird-love + 1 set increase-count increase-count + 1]
    ]
  ]

  ask patch-set bottom-patches [
    if random-float 1 <= change-chance [
      if bird-love > 0 [set bird-love bird-love - 1 set decrease-count decrease-count + 1]
    ]
  ]
end

to change-vegetation ;; add vegetation based on bird-love, with 5% max chance to add or remove
  ask patches
  [
    ;; increase chance and decrease chance have a maximum of 0.05 (5% chance) at max and min bird love values
    ;; will increase or decrease veg based on calculated chance, and if they get past the random number draw
    ;; if no increase or decrease, record 0 on list for no veg change

    let increase-chance bird-love * veg-chance
    let decrease-chance bird-love * (veg-chance * (-1)) + (10 * veg-chance)

    if increase-chance > random-float 1 and vegetation-volume < 16 [
      let number random 3
      ifelse (vegetation-volume + number) < 16 [
        set vegetation-volume vegetation-volume + number ;; increase veg volume dont make this arbitrary!
      ]
      [ set vegetation-volume 16 ]
      set veg-change-list lput 1 veg-change-list ;; records last 10 changes, 1 for increase
      ;set pcolor blue ;; to see last change
      if length veg-change-list > 10 [
        set veg-change-list remove-item 0 veg-change-list
      ]
      stop
    ]

    if decrease-chance > random-float 1 and vegetation-volume > 0 [
      let number random 3
      ifelse vegetation-volume >= number [
        set vegetation-volume vegetation-volume - number
      ]
      [ set vegetation-volume 0 ]
      set veg-change-list lput -1 veg-change-list ;; records last 10 changes, -1 for decrease
      ;set pcolor red ;; to see last change
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
    set habitat sum [ vegetation-volume ] of neighbors ;patches in-radius habitat-radius
    set max-bird-density round ((habitat / (16 * count neighbors)) * 3) ;; 3 is decided value of max-bird
    set veg-changes sum veg-change-list ; record simple metric for + or - veg change over past 5 years
  ]
end

to visual ;; colors/labels for testing
  ask patches [
    ;set plabel (word bird-love "," yard-bird-estimate "," neighbor-bird-estimate "," bird-density "," vegetation-volume)
    ;set plabel (word bird-density "," max-bird-density "," vegetation-volume)
    ;set plabel-color 14
    ;; The following categories are a result of a TSNE analysis that grouped patches based on yard variables
    ;; NN
    if bird-density >= 1 and yard-bird-estimate >= 1 and bird-love > 6 and habitat >= 25 and vegetation-volume >= 2 and veg-changes >= 0 [
      set pcolor green
      stop
    ]
    ;; EoE
    if bird-density = 0 and yard-bird-estimate <= 1 and bird-love < 4 and habitat <= 25 and vegetation-volume <= 2 and veg-changes <= 0 [
      set pcolor 16 ; red
      stop
    ]
    ;; POTENTIAL NN
    if bird-density = 0 and yard-bird-estimate >= 1 and bird-love > 4 and veg-changes >= 0 [
      set pcolor 85 ; cyan
      stop
    ]
    ;; RISK OF EoE
    if bird-density = 0 and yard-bird-estimate <= 1 and bird-love < 6 and veg-changes <= 0 [
      set pcolor 126 ;violet
      stop
    ]
  ]
  ;; testing colors
  ask patches [
    ;set pcolor scale-color 66 vegetation-volume 16 0
    ;set pcolor scale-color violet sum veg-change-list 5 -5 ;; color for veg list
    ;set pcolor scale-color gray bird-love 10 0
  ]
  set adults count turtles with [age > 1]
  set fledglings count turtles with [age = 1]
  set babies count turtles with [age = 0]
end
@#$#@#$#@
GRAPHICS-WINDOW
613
14
1119
521
-1
-1
19.92
1
10
1
1
1
0
1
1
1
0
24
0
24
0
0
1
ticks
30.0

BUTTON
686
528
749
561
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
1480
20
1556
65
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

PLOT
2
473
294
717
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
1477
154
1581
187
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
1477
226
1596
259
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
1477
190
1552
223
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
611
566
681
599
go 500
ifelse ticks <= 500 [go] [stop]
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

PLOT
295
250
610
481
bird-love by patch
NIL
patch count
0.0
11.0
0.0
10.0
true
false
"" "histogram [bird-love] of patches"
PENS
"default" 1.0 1 -16777216 true "" ""

BUTTON
612
528
675
561
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

PLOT
1
244
292
473
mean bird density
time
mean bird dens
0.0
10.0
0.0
3.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot mean [bird-density] of patches"

BUTTON
695
565
758
598
go 1k
ifelse ticks <= 1000 [go] [stop]
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

PLOT
0
13
292
240
total birds over time
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot count turtles"

SLIDER
762
558
935
591
change-chance
change-chance
0
1
0.25
.01
1
NIL
HORIZONTAL

BUTTON
657
603
720
636
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

PLOT
298
483
603
724
bird-density by patch
NIL
NIL
0.0
4.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 1 -16777216 true "" "histogram [bird-density] of patches"

MONITOR
1481
72
1555
117
patch count
count patches
17
1
11

SLIDER
763
592
935
625
offspring
offspring
0
4
1.0
1
1
NIL
HORIZONTAL

SLIDER
761
628
933
661
quartile-size
quartile-size
0
.50
0.25
0.01
1
NIL
HORIZONTAL

SLIDER
762
664
934
697
veg-chance
veg-chance
0
0.1
0.015
0.001
1
NIL
HORIZONTAL

PLOT
295
15
603
250
veg volume of patches
NIL
NIL
0.0
17.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 1 -16777216 true "" "histogram [vegetation-volume] of patches"

SLIDER
762
522
934
555
max-tick
max-tick
0
100
100.0
1
1
NIL
HORIZONTAL

MONITOR
665
643
715
688
NIL
ticks
17
1
11

PLOT
1132
459
1484
684
nestlings
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot babies"

PLOT
1130
20
1473
221
adults
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot adults"

PLOT
1134
226
1476
452
fledglings
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot fledglings"

TEXTBOX
946
521
1131
623
------------- KEY ---------------\nGreen = Noticing Nature (NN)\nCyan = Potential NN\nRed = Extinction of Experience (EoE)\nMagenta = Risk of EoE
14
0.0
0

TEXTBOX
1480
130
1630
148
bird test procedures\n
11
0.0
1

SWITCH
944
639
1102
672
weighted-estimate
weighted-estimate
0
1
-1000

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
  <experiment name="clustering" repetitions="10" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <postRun>export-world (word "result" behaviorspace-run-number".csv")</postRun>
    <enumeratedValueSet variable="change-chance">
      <value value="0.05"/>
    </enumeratedValueSet>
    <steppedValueSet variable="max-bird" first="3" step="1" last="5"/>
    <enumeratedValueSet variable="mean-vegetation-volume">
      <value value="3"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="clustering_2" repetitions="10" runMetricsEveryStep="true">
    <setup>setup
export-world (word "start" behaviorspace-run-number".csv")</setup>
    <go>go</go>
    <postRun>export-world (word "end" behaviorspace-run-number".csv")</postRun>
    <exitCondition>ticks = 100</exitCondition>
    <metric>count turtles</metric>
    <metric>mean [vegetation-volume] of patches</metric>
    <metric>mean [bird-density] of patches</metric>
    <metric>mean [bird-love] of patches</metric>
    <metric>mean [yard-bird-estimate] of patches</metric>
    <enumeratedValueSet variable="change-chance">
      <value value="0.25"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="calibration_bios594" repetitions="1" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>count patches with [pcolor = green]</metric>
    <metric>count patches with [pcolor = 16]</metric>
    <metric>count patches with [pcolor = 85]</metric>
    <metric>count patches with [pcolor = 126]</metric>
    <steppedValueSet variable="change-chance" first="0.1" step="0.05" last="0.35"/>
    <steppedValueSet variable="max-tick" first="25" step="25" last="100"/>
    <steppedValueSet variable="veg-chance" first="0.005" step="0.005" last="0.02"/>
    <enumeratedValueSet variable="offspring">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="quartile-size">
      <value value="0.25"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="bird-est_sens_bios594" repetitions="10" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>count patches with [pcolor = green]</metric>
    <metric>count patches with [pcolor = 16]</metric>
    <metric>count patches with [pcolor = 85]</metric>
    <metric>count patches with [pcolor = 126]</metric>
    <enumeratedValueSet variable="change-chance">
      <value value="0.25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-tick">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="veg-chance">
      <value value="0.015"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="offspring">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="weighted-estimate">
      <value value="false"/>
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="quartile-size">
      <value value="0.25"/>
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

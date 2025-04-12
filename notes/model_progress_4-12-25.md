######	Noticing Birds ######
# MODEL UPDATES
I adjusted the setup procedure to include one tick of the go procedure.
Previously, the bird population would shoot up on the first tick because
birds are reproducing for the first time in the model. Instead of
rewriting how the setup procudure is structured to make birds
reproduce on setup, I just added the go procedure to the setup procedure,
resolving this issue of the dramatic increase in bird population on the
first tick.

I adjusted the kill-birds procedure. Previously, I had a death
rate of around 50% which led to very unstable bird populations and
making it seem as though patch variables were entirely unrelated to 
bird populations. Before that, I had a lower death rate of about 35%,
and the bird population would grow exponentially, seemingly unrelated
to bird-love and vegetation volume. Now, I added a turtles-own variable
called "age" that increases by 1 every tick and birds die with the
following logic:
`if the bird's age > 3, the bird dies
I should find peer-reviewed articles to back this up, but it seems
like general knowledge that songbirds live about 3-5 years in general.
This new kill-birds procedure allows for predictable population control
of the birds, which should be much better for testing and measuring
the patterns that we actually care about, such as the relationship
between bird populations and vegetation-volume.

I added a patches-own variable called veg-changes. This variable is
calculated at the end of each tick as:
`veg-changes = the sum of veg-change-list
veg-change-list is a list of vegetation changes for each patch in the
past 5 ticks. If a patch adds veg, it puts a +1 in the list, if it 
removes veg, it puts a -1 in the list, and a 0 for no change. The sum
of the numbers in this list should show in which direction patches have
changed their vegetation for the past 5 years. This could be another way
to quantify the NN versus EoE cycles.

I am working on a testing version of the model for the purpose of cali-
bration. I added sliders for most parameters that were decided by
'common-sense', rather than empirical data:
`max-ticks: # of ticks that model stops at
`offspring: # of offspring settled birds will have
`quartile-size: how many patches have the chance to change veg
`veg-chance: chance that patches in quartile size will change veg

# Future directions
Calibrate the model based on the parameters listed above. See 
'proposed experiments' in calibration.pdf.

Determine ways to quantify NN vs EoE. Some current ideas include:
`meeting a certain threshold of veg-changes, habitat, bird-love,
	and bird-density.
`Use clumpiness metrics to classify groups of patches that have
	birds + veg bersus patches with no birds + low veg

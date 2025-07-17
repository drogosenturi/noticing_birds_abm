import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns

ticks = "~/netlogo_models/experiments_7-15/snapshot120_true.csv"#ticks.csv"
data = pd.read_csv(ticks)

data = data.rename(columns={'[run number]': 'run'})
data = data.rename(columns={'sum [veg-changes] of patches': 'total_veg_changes'})

no_mimic = data.loc[data['run'] == 1]
mimic = data.loc[data['run'] == 2]

ax = sns.scatterplot(no_mimic, x = '[step]', y = 'total_veg_changes')
ax = sns.scatterplot(mimic, x = '[step]', y = 'total_veg_changes')
ax.legend(labels = data['mimicry'])

ax = sns.scatterplot(no_mimic, x = '[step]', y = 'mean [vegetation-volume] of patches')
ax = sns.scatterplot(mimic, x = '[step]', y = 'mean [vegetation-volume] of patches')
ax.legend(labels = data['mimicry'])
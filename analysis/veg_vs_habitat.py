import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns

raw = "~/netlogo_models/experiments_9-9/meanveg_meanhabitat.csv"
data = pd.read_csv(raw)

data = data.rename(columns={'mean [vegetation-volume] of patches': 'Mean Vegetation Volume'})
data = data.rename(columns={'mean [habitat] of patches': 'Mean Habitat'})

sns.set_style("ticks")
sns.scatterplot(data, x = 'Mean Vegetation Volume', y = 'Mean Habitat', color='purple')
sns.despine()
plt.show()


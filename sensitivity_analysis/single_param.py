######## SINGLE PARAMETER SENSITIVITY ANALYSIS 5-07-25 FOR NOTICING BIRDS ########
import pandas as pd
from scipy.stats import ttest_ind
import seaborn as sns
import numpy as np
import matplotlib.pyplot as plt

file = 'bird-est_sens_bios594-table.csv'
data = pd.read_csv(file, header=0)
data = data.rename(columns={'count patches with [pcolor = 16]':'EoE'})

exp = data[data["weighted-estimate"]==True]
control = data[data["weighted-estimate"]==False]

ttest = ttest_ind(control["EoE"], exp["EoE"])

fig = plt.figure()
ax = fig.add_subplot()
sns_boxplot = sns.boxplot(x=data['weighted-estimate'],y=data.EoE,
                          palette='mako',ax=ax)
sns_boxplot.set(ylabel="# of patches in EoE")
legend = sns_boxplot.legend(loc='upper right', fontsize = '10', frameon=True, 
                   framealpha=0.3, facecolor='0.7', title='p = 3.306\nstatistic=7.83',
                   title_fontsize='10',borderpad=0.3)
plt.show()
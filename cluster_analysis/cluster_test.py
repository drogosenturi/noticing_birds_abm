##########  check for multicollinearity btwn variables then throw into t-sne    #############
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns
from sklearn.preprocessing import StandardScaler
from sklearn.manifold import TSNE

# pull in the 10 test files
file1 = "cleaned/3_3_1.csv"
file2 = "cleaned/3_3_2.csv"
file3 = "cleaned/3_3_3.csv"
file4 = "cleaned/3_3_4.csv"
file5 = "cleaned/3_3_5.csv"
file6 = "cleaned/3_3_6.csv"
file7 = "cleaned/3_3_7.csv"
file8 = "cleaned/3_3_8.csv"
file9 = "cleaned/3_3_9.csv"
file10 = "cleaned/3_3_10.csv"
file_list = [file1,file2,file3,file4,file5,file6,file7,file8,file9,file10]

def clean(file):
    df_list = []
    for i in file:
        data = pd.read_csv(i)
        data[["pycor"]] = data[["pycor"]].astype(str)
        data[["pxcor"]] = data[["pxcor"]].astype(str)
        data["patch"] = data["pxcor"] + data["pycor"]
        data = data.drop(columns=["pycor","pxcor",'pcolor','plabel','plabel-color',
                                  'veg-change-list','patch','max-bird-density',
                                  'yard-bird-estimate','bird-love'])
        df_list.append(data)
    print(df_list)
    cat = pd.concat((df_list))
    means = cat.groupby(level=0).mean()
    return means
final = clean(file_list)

# Scale
scaler = StandardScaler().set_output(transform="pandas")
data_scaled = scaler.fit_transform(final)

#correlation
corr = data_scaled.corr()
print(corr)
sns.heatmap(corr,cmap='crest')
plt.show()
'''
max bird | habitat = 85%
bird-love | veg-vol = 71%
bird-dens | yard-bird = 78%

'''
# bird-density related to estimate (0.7) bird-love related to veg (0.6)

# t-sne
tsne = TSNE(perplexity=25,max_iter=1000).fit_transform(data_scaled)
print(tsne)
final['tsne1'] = tsne[:,0]
final['tsne2'] = tsne[:,1]
# plot
sns.set_theme(style='whitegrid')
palette = sns.cubehelix_palette(start=2, rot=0, dark=0, light=.95,
                                as_cmap=True)
# bird-dens
ax = sns.scatterplot(data=final,x="tsne1",y='tsne2',hue='bird-density',
                palette=palette,edgecolor= "0.4") #str 0.0 - 1.0 is grayscale
legend = ax.legend(loc='upper right', fontsize = '10', frameon=True, 
                   framealpha=0.3, facecolor='0.7', title='Birds in yard',
                   title_fontsize='10',borderpad=0.3)
plt.show()
'''
# carrying capacity
ax = sns.scatterplot(data=final,x="tsne1",y='tsne2',hue='max-bird-density',
                palette=palette,edgecolor= "0.4") #str 0.0 - 1.0 is grayscale
legend = ax.legend(loc='upper right', fontsize = '10', frameon=True, 
                   framealpha=0.3, facecolor='0.7', title='K',
                   title_fontsize='10',borderpad=0.3)
plt.show()
'''
'''
# yard-bird-estimate
ax = sns.scatterplot(data=final,x="tsne1",y='tsne2',hue='yard-bird-estimate',
                palette=palette,edgecolor= "0.4") #str 0.0 - 1.0 is grayscale
legend = ax.legend(loc='upper right', fontsize = '10', frameon=True, 
                   framealpha=0.3, facecolor='0.7', title='Bird Estimate',
                   title_fontsize='10',borderpad=0.3)
plt.show()
'''
'''
# bird-love
ax = sns.scatterplot(data=final,x="tsne1",y='tsne2',hue='bird-love',
                palette=palette,edgecolor= "0.4") #str 0.0 - 1.0 is grayscale
legend = ax.legend(loc='upper right', fontsize = '10', frameon=True, 
                   framealpha=0.3, facecolor='0.7', title='Attitude',
                   title_fontsize='10',borderpad=0.3)
plt.show()
'''
# habitat
ax = sns.scatterplot(data=final,x="tsne1",y='tsne2',hue='habitat',
                palette=palette,edgecolor= "0.4") #str 0.0 - 1.0 is grayscale
legend = ax.legend(loc='upper right', fontsize = '10', frameon=True, 
                   framealpha=0.3, facecolor='0.7', title='Habitat',
                   title_fontsize='10',borderpad=0.3)
plt.show()

# veg-vol
ax = sns.scatterplot(data=final,x="tsne1",y='tsne2',hue='vegetation-volume',
                palette=palette,edgecolor= "0.4") #str 0.0 - 1.0 is grayscale
legend = ax.legend(loc='upper right', fontsize = '10', frameon=True, 
                   framealpha=0.3, facecolor='0.7', title='Vegetation',
                   title_fontsize='10',borderpad=0.3)
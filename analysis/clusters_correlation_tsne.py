##########  check for multicollinearity btwn variables then throw into t-sne    #############
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns
from sklearn.preprocessing import StandardScaler
from sklearn.manifold import TSNE

# pull in the 10 test files
file1 = "~/netlogo_models/data/cluster_data/3_3_1.csv"
file2 = "~/netlogo_models/data/cluster_data/3_3_2.csv"
file3 = "~/netlogo_models/data/cluster_data/3_3_3.csv"
file4 = "~/netlogo_models/data/cluster_data/3_3_4.csv"
file5 = "~/netlogo_models/data/cluster_data/3_3_5.csv"
file6 = "~/netlogo_models/data/cluster_data/3_3_6.csv"
file7 = "~/netlogo_models/data/cluster_data/3_3_7.csv"
file8 = "~/netlogo_models/data/cluster_data/3_3_8.csv"
file9 = "~/netlogo_models/data/cluster_data/3_3_9.csv"
file10 = "~/netlogo_models/data/cluster_data/3_3_10.csv"
file_list = [file1,file2,file3,file4,file5,file6,file7,file8,file9,file10]

'''
# function to concatenate each dataframe and take average
# USELESS BECAUSE SPATIAL EXPLICITNESS CHANGES EVERY TIME
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
'''
data = pd.read_csv(file_list[9])
data[["pycor"]] = data[["pycor"]].astype(str)
data[["pxcor"]] = data[["pxcor"]].astype(str)
data["patch"] = data["pxcor"] + data["pycor"]
data = data.drop(columns=["pycor","pxcor",'pcolor','plabel','plabel-color',
                            'veg-change-list','patch'])
 
# Veg-volume + habitat -> bird-density
# veg volume is a bimodal dist
#X = pd.DataFrame(data[["bird-density","yard-bird-estimate"]])
X = data.drop(columns=['bird-density'])
Y = data['bird-density']

# Scale
scaler = StandardScaler().set_output(transform="pandas")
data_scaled = scaler.fit_transform(data)

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
palette = sns.color_palette("rocket")
# PCA
from sklearn.decomposition import PCA
pca = PCA(n_components=3) # used 6 initially
pcafit = pca.fit(data_scaled)
perc = pcafit.explained_variance_ratio_
print("explained variance: ",perc)
pca_trans = pca.fit_transform(data_scaled)
# plot to show PCA feature importance
perc_x = range(1,len(perc)+1)
plt.plot(perc_x,perc,"ro--")
plt.xlabel("Number of Components")
plt.ylabel("Explained variance")
plt.show()

# PCA plot in 3D since 3 components are important
data["PC1"] = pca_trans[:,0]
data["PC2"] = pca_trans[:,1]
data["PC3"] = pca_trans[:,2]
##bird density
fig = plt.figure()
ax = fig.add_subplot(projection='3d')
scatter = ax.scatter(data["PC1"],data["PC2"],data["PC3"], c=data["bird-density"],
           cmap="crest")
ax.legend(*scatter.legend_elements(),title='bird density')
ax.set_xlabel("PC1")
ax.set_ylabel("PC2")
ax.set_zlabel("PC3")
plt.show()
## attitudes/vegetation difficult to interpret no grouping pattern
fig = plt.figure()
ax = fig.add_subplot(projection='3d')
scatter = ax.scatter(data["PC1"],data["PC2"],data["PC3"],
                     c=data["yard-bird-estimate"], cmap="crest")
ax.legend(*scatter.legend_elements(),title='bird estimate')
ax.set_xlabel("PC1")
ax.set_ylabel("PC2")
ax.set_zlabel("PC3")
plt.show()

# PC feature importance
##PC1
x_ticks = ["Vegetation volume", "Habitat", "K", "Bird density","Attitudes",
           "Bird population estimate"]
groups = ['PC1','PC2','PC3']
df = pd.DataFrame(pcafit.components_, index=groups,columns=x_ticks)
#make it long so that seaborn can plot it
df_long = df.reset_index().melt(id_vars='index',
                                var_name='variable',
                                value_name='Explained variance')
df_long = df_long.rename(columns={'index': 'PCA'})
ax = sns.barplot(data=df_long,x="variable",y='Explained variance',
                 hue='PCA',palette='mako')
plt.xlabel('')
plt.xticks(rotation=45)
plt.tight_layout()
plt.legend(loc='lower right')
plt.show()

# t-sne
tsne = TSNE(perplexity=40,max_iter=1000, learning_rate=500).fit_transform(data_scaled)
print(tsne)
data['tsne1'] = tsne[:,0]
data['tsne2'] = tsne[:,1]
# plot
sns.set_theme(style='whitegrid')
palette = sns.cubehelix_palette(start=2, rot=0, dark=0, light=.95,
                                as_cmap=True)
#palette = sns.color_palette("crest",as_cmap=True)
# bird-dens
ax = sns.scatterplot(data=data,x="tsne1",y='tsne2',hue='bird-density',
                palette=palette,edgecolor= "0.4") #str 0.0 - 1.0 is grayscale
legend = ax.legend(loc='upper right', fontsize = '10', frameon=True, 
                   framealpha=0.3, facecolor='0.7', title='Birds in yard',
                   title_fontsize='10',borderpad=0.3)
plt.show()

# carrying capacity
ax = sns.scatterplot(data=data,x="tsne1",y='tsne2',hue='max-bird-density',
                palette=palette,edgecolor= "0.4") #str 0.0 - 1.0 is grayscale
legend = ax.legend(loc='upper right', fontsize = '10', frameon=True, 
                   framealpha=0.3, facecolor='0.7', title='K',
                   title_fontsize='10',borderpad=0.3)
plt.show()

# yard-bird-estimate
ax = sns.scatterplot(data=data,x="tsne1",y='tsne2',hue='yard-bird-estimate',
                palette=palette,edgecolor= "0.4") #str 0.0 - 1.0 is grayscale
legend = ax.legend(loc='upper right', fontsize = '10', frameon=True, 
                   framealpha=0.3, facecolor='0.7', title='Bird Estimate',
                   title_fontsize='10',borderpad=0.3)
plt.show()

# bird-love
palette3 = ["#e5f5f9","#99d8c9","#2ca25f"]
data['bird-love-cnd'] = pd.cut(data['bird-love'],[0,3,6,10],
                                   labels=["poor","neutral","good"])
ax = sns.scatterplot(data=data,x="tsne1",y='tsne2',hue='bird-love-cnd',
                palette=palette3,edgecolor= "0.4") #str 0.0 - 1.0 is grayscale
legend = ax.legend(loc='upper right', fontsize = '10', frameon=True, 
                   framealpha=0.3, facecolor='0.7', title='Attitude',
                   title_fontsize='10',borderpad=0.3)
plt.show()

# habitat
'''
palette3 = ["#e5f5f9","#99d8c9","#2ca25f"]
data['habitat_condensed'] = pd.cut(data['habitat'],[0,50,100,150],
                                   labels=["0-50","50-100","100-150"])
'''
palette2 = ["#e5f5f9","#2ca25f"]
data['habitat_condensed'] = pd.cut(data['habitat'],[0,64,150],
                                   labels=["0-64","64-150"]) # 64 is the value for patches to have 1 bird
ax = sns.scatterplot(data=data,x="tsne1",y='tsne2',hue='habitat_condensed',
                palette=palette2,edgecolor= "0.4") #str 0.0 - 1.0 is grayscale
legend = ax.legend(loc='upper right', fontsize = '10', frameon=True, 
                   framealpha=0.3, facecolor='0.7', title='Habitat',
                   title_fontsize='10',borderpad=0.3)
plt.show()

# veg-vol
palette5 = ["#edf8fb","#b2e2e2","#66c2a4","#2ca25f","#006d2c"]
data['veg-vol-cnd'] = pd.cut(data['vegetation-volume'],[0,3,6,9,12,15],
                                   labels=["0-3","3-6","6-9","9-12","12-15"])
ax = sns.scatterplot(data=data,x="tsne1",y='tsne2',hue='veg-vol-cnd',
                palette=palette5,edgecolor= "0.4") #str 0.0 - 1.0 is grayscale
legend = ax.legend(loc='upper right', fontsize = '10', frameon=True, 
                   framealpha=0.3, facecolor='0.7', title='Vegetation',
                   title_fontsize='10',borderpad=0.3)

# with k-means
from sklearn.cluster import KMeans
from sklearn import metrics
kmeans = KMeans(n_clusters = 2)
fit = kmeans.fit(X)
data["labels"] = kmeans.labels_
centroids = kmeans.cluster_centers_
silhouette = metrics.silhouette_score(X, data["labels"],metric='sqeuclidean')
print("score: ",silhouette)

palette3 = ["#e5f5f9","#99d8c9","#2ca25f"]
ax = sns.scatterplot(data=data,x="tsne1",y='tsne2',hue='labels',
                palette=palette2,edgecolor= "0.4") #str 0.0 - 1.0 is grayscale
legend = ax.legend(loc='upper right', fontsize = '10', frameon=True, 
                   framealpha=0.3, facecolor='0.7', title='K Clusters',
                   title_fontsize='10',borderpad=0.3)
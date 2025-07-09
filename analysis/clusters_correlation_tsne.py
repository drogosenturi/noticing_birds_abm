##########  check for multicollinearity btwn variables then throw into t-sne    #############
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns
from sklearn.preprocessing import StandardScaler
from sklearn.manifold import TSNE

# true/false denotes mimicry on/off
end = "~/netlogo_models/experiments_7-3/snapshot60_true.csv"

data = pd.read_csv(end)
data[["pycor"]] = data[["pycor"]].astype(str)
data[["pxcor"]] = data[["pxcor"]].astype(str)
data["patch"] = data["pxcor"] + data["pycor"]
data = data.drop(columns=["pycor","pxcor",'pcolor','plabel','plabel-color',
                            'veg-change-list','patch','avg-neighbor-richness',
                            'happy?'])
 
# Veg-volume + habitat -> bird-density
# veg volume is a bimodal dist
#X = pd.DataFrame(data[["bird-density","yard-bird-estimate"]])
X = pd.DataFrame(data) #.drop(columns=['bird-density'])
Y = data['bird-density']

# Scale
scaler = StandardScaler().set_output(transform="pandas")
data_scaled = scaler.fit_transform(data)

#correlation
corr = data_scaled.corr()
print(corr)
sns.heatmap(corr,cmap='mako_r')
plt.show()
'''
max bird | habitat = 85%
bird-love | veg-vol = 71%
bird-dens | yard-bird = 78%

'''
# bird-density related to estimate (0.7) bird-love related to veg (0.6)
palette = sns.cubehelix_palette(start=2, rot=0, dark=0, light=.95,
                                as_cmap=True)
#palette = sns.color_palette("crest",as_cmap=True)
palette2 = ["#e5f5f9","#2ca25f"]
palette3 = ["#e5f5f9","#99d8c9","#2ca25f"]
palette5 = ["#edf8fb","#b2e2e2","#66c2a4","#2ca25f","#006d2c"]
# PCA
from sklearn.decomposition import PCA
pca = PCA(n_components=2) # used 6 initially
pcafit = pca.fit(data_scaled)
perc = pcafit.explained_variance_ratio_
print("explained variance: ",perc)
pca_trans = pca.fit_transform(data_scaled)
# plot to show PCA component importance
perc_x = range(1,len(perc)+1)
plt.plot(perc_x,perc,"ro--")
plt.xlabel("Number of Components")
plt.ylabel("Explained variance")
plt.show()

# PCA plot
data["PC1"] = pca_trans[:,0]
data["PC2"] = pca_trans[:,1]
#data["PC3"] = pca_trans[:,2]
data['bird-love-cnd'] = pd.cut(data['bird-love'],[-1,3,6,10],
                                   labels=["poor","neutral","good"])
##bird density
fig = plt.figure()
#ax = fig.add_subplot(projection='3d') #for 3d plot
ax = fig.add_subplot()
ax = sns.scatterplot(data=data,x="PC1",y="PC2",edgecolors='0.4',
                     hue=data["bird-love-cnd"],palette='crest')
legend = ax.legend(loc='upper right', fontsize = '10', frameon=True, 
                   framealpha=0.3, facecolor='0.7', title='attitude',
                   title_fontsize='10',borderpad=0.3)
ax.set_xlabel("PC1")
ax.set_ylabel("PC2")
#ax.set_zlabel("PC3")
plt.show()

# PC feature importance

##PC1
x_ticks = ["Veg volume", "Habitat", "K", "Bird density","Attitudes",
           "Bird estimate","veg changes"]
groups = ['PC1','PC2']#['PC1','PC2','PC3']
df = pd.DataFrame(abs(pcafit.components_), index=groups,columns=x_ticks)
#make it long so that seaborn can plot it
df_long = df.reset_index().melt(id_vars='index',
                                var_name='variable',
                                value_name='Explained variance')
df_long = df_long.rename(columns={'index': 'PCA'})
ax = sns.barplot(data=df_long,x="variable",y='Explained variance',
                 hue='PCA',palette='mako')
plt.xlabel('')
plt.xticks(rotation=15)
plt.tight_layout()
plt.legend(loc='upper left')
plt.show()

#---------- t-sne -------------
tsne = TSNE(perplexity=35).fit_transform(data_scaled)
print(tsne)
data['tsne1'] = tsne[:,0]
data['tsne2'] = tsne[:,1]
# plot
sns.set_theme(style='whitegrid')
palette = sns.cubehelix_palette(start=2, rot=0, dark=0, light=.95,
                                as_cmap=True)
#palette = sns.color_palette("crest",as_cmap=True)
palette2 = ["#7bccc4","#0868ac"]
palette3 = ["#e5f5f9","#99d8c9","#2ca25f"]
palette5 = ["#edf8fb","#b2e2e2","#66c2a4","#2ca25f","#006d2c"]
palette6 = ["#f0f9e8","#ccebc5","#a8ddb5","#7bccc4","#43a2ca","#0868ac"]

# bird-dens
ax = sns.scatterplot(data=data,x="tsne1",y='tsne2',hue='bird-density',
                palette='mako_r',edgecolor= "0.4") #str 0.0 - 1.0 is grayscale
legend = ax.legend(loc='upper right', fontsize = '10', frameon=True, 
                   framealpha=0.3, facecolor='0.7', title='Birds in yard',
                   title_fontsize='10',borderpad=0.3)
plt.show()

# carrying capacity
ax = sns.scatterplot(data=data,x="tsne1",y='tsne2',hue='max-bird-density',
                palette='mako_r',edgecolor= "0.4") #str 0.0 - 1.0 is grayscale
legend = ax.legend(loc='upper right', fontsize = '10', frameon=True, 
                   framealpha=0.3, facecolor='0.7', title='max-bird',
                   title_fontsize='10',borderpad=0.3)
plt.show()

# yard-bird-estimate
data['bird-est-cnd'] = pd.cut(data['yard-bird-estimate'],[0,5,10,15,20,100],
                                labels=['0-5','6-10','11-15','16-20','20+'])
ax = sns.scatterplot(data=data,x="tsne1",y='tsne2',hue='bird-est-cnd',
                palette=palette5,edgecolor= "0.4") #str 0.0 - 1.0 is grayscale
legend = ax.legend(loc='upper right', fontsize = '10', frameon=True, 
                   framealpha=0.3, facecolor='0.7', title='Bird Estimate',
                   title_fontsize='10',borderpad=0.3)
plt.show()

# bird-love
data['bird-love-cnd'] = pd.cut(data['bird-love'],[-1,3,6,10],
                                   labels=["poor","neutral","good"])
ax = sns.scatterplot(data=data,x='tsne1',y='tsne2',hue='bird-love-cnd',
                palette=palette3,edgecolor= "0.4") #str 0.0 - 1.0 is grayscale
legend = ax.legend(loc='upper right', fontsize = '10', frameon=True, 
                   framealpha=0.3, facecolor='0.7', title='Attitude',
                   title_fontsize='10',borderpad=0.3)
plt.show()

# habitat
'''
data['habitat_condensed'] = pd.cut(data['habitat'],[0,50,100,150],
                                   labels=["0-50","50-100","100-150"])
'''

data['habitat_condensed'] = pd.cut(data['habitat'],[0,25,50,75,100,150],
                                   labels=["0-25","26-50","51-75",
                                           "76-100","101-150"]) # 64 is the value for patches to have 1 bird
ax = sns.scatterplot(data=data,x="tsne1",y='tsne2',hue='habitat_condensed',
                palette='mako_r',edgecolor= "0.2") #str 0.0 - 1.0 is grayscale
legend = ax.legend(loc='upper right', fontsize = '10', frameon=True, 
                   framealpha=0.3, facecolor='0.7', title='Habitat',
                   title_fontsize='10',borderpad=0.3)
plt.show()

# veg-vol
data['veg-vol-cnd'] = pd.cut(data['vegetation-volume'],[-1,4,8,12,16],
                             labels=["0-4","5-8","9-12","12-16"])
ax = sns.scatterplot(data=data,x='tsne1',y='tsne2',hue='veg-vol-cnd',
                     palette='mako_r',edgecolor= "0.2") #str 0.0 - 1.0 is grayscale
legend = ax.legend(loc='upper right', fontsize = '10', frameon=True, 
                   framealpha=0.3, facecolor='0.7', title='Vegetation',
                   title_fontsize='10',borderpad=0.3)
plt.show()

# veg-changes
ax = sns.scatterplot(data=data,x="tsne1",y='tsne2',hue='veg-changes',
                     palette='mako_r',edgecolor="0.2")
legend = ax.legend(loc='upper right', fontsize = '10', frameon=True, 
                   framealpha=0.3, facecolor='0.7', title='Veg changes',
                   title_fontsize='10',borderpad=0.3)
plt.show()

# with k-means
from sklearn.cluster import KMeans
from sklearn import metrics
kmeans = KMeans(n_clusters = 2)
fit = kmeans.fit(X)
data["labels"] = kmeans.labels_
centroids = kmeans.cluster_centers_
silhouette = metrics.silhouette_score(X, data["labels"],metric='sqeuclidean')
print("score: ",silhouette)
# decision boundaries attempt
'''
x_min, x_max = tsne[:,0].min()-1, tsne[:,0].max()+1
y_min, y_max = tsne[:,1].min()-1, tsne[:,1].max()+1
xx, yy = np.meshgrid(np.linspace(x_min, x_max, 100), 
                     np.linspace(y_min, y_max, 100))

from sklearn.neighbors import NearestNeighbors
nbrs = NearestNeighbors(n_neighbors=1).fit(tsne)
_,mesh_indices = nbrs.kneighbors(np.c_[xx.ravel(), yy.ravel()])
mesh_predictions = fit.labels_[mesh_indices.flatten()]

plt.contourf(xx, yy, mesh_predictions.reshape(xx.shape),
             alpha=0.3, levels=len(np.unique(fit.labels_))-1,
             colors=sns.color_palette('bright'))
'''
ax = sns.scatterplot(data=data,x="tsne1",y='tsne2',hue='labels',
                palette="mako",edgecolor= "0.4") #str 0.0 - 1.0 is grayscale

'''
plt.scatter(fit.cluster_centers_[:,0], fit.cluster_centers_[:,1],
            marker='X',s=50,color='red',linewidth=1,label='Centroids')
'''
legend = ax.legend(loc='upper right', fontsize = '10', frameon=True, 
                   framealpha=0.3, facecolor='0.7', title='K Clusters',
                   title_fontsize='10',borderpad=0.3)
plt.show()
'''
# pairplot
sns.pairplot(data, hue='labels',palette='mako',
             plot_kws={'alpha':0.7,'edgecolor':'k'})
plt.show
'''
# decision tree
from sklearn.model_selection import train_test_split
from sklearn import tree

Y = data['labels']
X_test, X_train, Y_test, Y_train = train_test_split(
    X, Y, test_size=0.3, stratify=Y
)

clf = tree.DecisionTreeClassifier(max_depth=3)
clf = clf.fit(X_train,Y_train)
print("Test accuracy", clf.score(X_test,Y_test))
fig = plt.figure()
fig, axes = plt.subplots(nrows = 1,ncols=1,figsize=(6,6),dpi=1200)
tree.plot_tree(clf, feature_names=X.columns.values, filled=True)
plt.show()

'''
rules for NN, EoE, potential NN, potential EoE
NN:
    birds >= 1
    K >=1
    Estimate >= 1
    attitude = good
    habitat >= 25
    veg >= 2
    veg change >= 0
EoE:
    birds = 0
    K = 0
    estimate <= 1
    attitude = poor
    habitat <= 25
    vegetation <= 2
    veg change > 0
Potential NN:
    birds = 0
    K >= 0
    estimate >= 1
    attitude = neutral, good
    habitat = any
    vegetation = any
    veg changes >= 0
Risk of EoE:
    birds = 0
    K >= 0
    estimate <= 1
    attitude = neutral, poor
    habitat = any
    vegetation = any
    veg changes <= 0

'''
'''
According to k-means:
NN:
    habitat min 35
    max-bird-density >= 1
    veg-changes min -2
    max-bird min 1
    yard-bird-est min 1
    bird-love any
    yard-veg any
EoE:
    habitat max 39
    max-bird-density < 1
    veg-changes max 3
    max-bird max 1
    yard-bird-est max 2
    bird-love any
    yard-veg any
'''
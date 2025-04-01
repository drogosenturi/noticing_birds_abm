import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns
from sklearn.cluster import KMeans
from sklearn.manifold import TSNE
from sklearn.model_selection import train_test_split
from sklearn.model_selection import cross_val_score
from sklearn.preprocessing import StandardScaler
from sklearn import metrics

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

data = pd.read_csv(file_list[5])
data[["pycor"]] = data[["pycor"]].astype(str)
data[["pxcor"]] = data[["pxcor"]].astype(str)
data["patch"] = data["pxcor"] + data["pycor"]
data = data.drop(columns=["pycor","pxcor",'pcolor','plabel','plabel-color',
                            'veg-change-list','patch'])
# there is a problem with the data structure of X
scaler = StandardScaler().set_output(transform='pandas')
X = scaler.fit_transform(data)

kmeans = KMeans(n_clusters = 5)
fit = kmeans.fit(X)
data["labels"] = kmeans.labels_
centroids = kmeans.cluster_centers_
silhouette = metrics.silhouette_score(X, data["labels"],metric='sqeuclidean')
print("score: ",silhouette)

## TSNE
model = TSNE(perplexity=40, learning_rate=1000)

transformed_centroids = model.fit_transform(X)
print(transformed_centroids)

plt.scatter(transformed_centroids[:,0],transformed_centroids[:,1], c=data["labels"])
plt.show()
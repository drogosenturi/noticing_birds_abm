class Processing:
    def readIn(file):
        import pandas as pd
        import numpy as np
        from sklearn.preprocessing import StandardScaler
        data = pd.read_csv(file)
        data[["pycor"]] = data[["pycor"]].astype(str)
        data[["pxcor"]] = data[["pxcor"]].astype(str)
        data["patch"] = data["pxcor"] + data["pycor"]
        data = data.drop(columns=["pycor","pxcor",'pcolor','plabel','plabel-color',
                                    'veg-change-list','patch', 'veg-changes',
                                    'happy?','max-bird-density', 'avg-neighbor-richness'])
        # scaling
        scaler = StandardScaler().set_output(transform="pandas")
        data_scaled = scaler.fit_transform(data)
        return data, data_scaled

class Clustering:
    def kMeans(data, clusters):
        from sklearn.cluster import KMeans
        from sklearn import metrics
        X = data
        kmeans = KMeans(n_clusters = clusters)
        kmeans.fit(X)
        data["labels"] = kmeans.labels_
        silhouette = metrics.silhouette_score(X, data["labels"],metric='sqeuclidean')
        print("score: ", silhouette)
        return data, silhouette
    
    def decisionTree(data):
        from sklearn.model_selection import train_test_split
        from sklearn import tree
        import matplotlib.pyplot as plt
        import seaborn as sns
        import pandas as pd

        X = pd.DataFrame(data[['vegetation-volume','habitat','bird-density','bird-love',
                 'yard-bird-estimate']])
        Y = pd.DataFrame(data[['labels']])
        X_test, X_train, Y_test, Y_train = train_test_split(
            X, Y, test_size=0.3, stratify=Y)

        clf = tree.DecisionTreeClassifier(max_depth=3)
        clf = clf.fit(X_train,Y_train)
        print("Test accuracy", clf.score(X_test,Y_test))
        fig = plt.figure()
        fig, axes = plt.subplots(nrows = 1,ncols=1,figsize=(6,6),dpi=1200)
        tree.plot_tree(clf, feature_names=X.columns.values, filled=True)
        plt.show()

class DimensionalityReduction:

    def PCA(data):
        print('input data should be scaled')
        import pandas as pd
        import matplotlib.pyplot as plt
        import seaborn as sns
        from sklearn.decomposition import PCA
        pca = PCA(n_components=2) # used 6 initially
        pcafit = pca.fit(data)
        perc = pcafit.explained_variance_ratio_
        print("explained variance: ",perc)
        pca_trans = pca.fit_transform(data)

        # plot to show PCA component importance
        perc_x = range(1,len(perc)+1)
        plt.plot(perc_x,perc,"ro--")
        plt.xlabel("Number of Components")
        plt.ylabel("Explained variance")
        plt.show()

        # PC feature importance
        x_ticks = ["Veg volume", "Habitat", "K", "Bird density","Attitudes",
           "Bird estimate","veg changes"]
        groups = ['PC1','PC2']
        df = pd.DataFrame(abs(pcafit.components_), index=groups,columns=x_ticks)
        #make it long so that seaborn can plot it
        df_long = df.reset_index().melt(id_vars='index',
                                        var_name='variable',
                                        value_name='Explained variance')
        df_long = df_long.rename(columns={'index': 'PCA'})
        sns.barplot(data=df_long,x="variable",y='Explained variance',
                        hue='PCA',palette='mako')
        plt.xlabel('')
        plt.xticks(rotation=15)
        plt.tight_layout()
        plt.legend(loc='upper left')
        plt.show()

        data["PC1"] = pca_trans[:,0]
        data["PC2"] = pca_trans[:,1]
        return data
    
    def tSNE(data, data_scaled):
        print('you should use standard scaled data')
        from sklearn.manifold import TSNE
        tsne = TSNE(perplexity=35).fit_transform(data_scaled)
        print(tsne)
        data['tsne1'] = tsne[:,0]
        data['tsne2'] = tsne[:,1]
        return data

class Plots:
    def __init__(self):
        import seaborn as sns
        self.palette = sns.cubehelix_palette(start=2, rot=0, dark=0, light=.95,
                                as_cmap=True)
        #palette = sns.color_palette("crest",as_cmap=True)
        self.palette2 = ["#7bccc4","#0868ac"]
        self.palette3 = ["#e5f5f9","#99d8c9","#2ca25f"]
        self.palette5 = ["#edf8fb","#b2e2e2","#66c2a4","#2ca25f","#006d2c"]
        self.palette6 = ["#f0f9e8","#ccebc5","#a8ddb5","#7bccc4","#43a2ca","#0868ac"]
        
    def tsneK(data):
        import pandas as pd
        import matplotlib.pyplot as plt
        import seaborn as sns
        ax = sns.scatterplot(data=data,x="tsne1",y='tsne2',hue='labels',
                        palette='mako_r',edgecolor= "0.2") #str 0.0 - 1.0 is grayscale
        ax.legend(loc='upper right', fontsize = '10', frameon=True, 
                        framealpha=0.3, facecolor='0.7', title='Habitat',
                        title_fontsize='10',borderpad=0.3)
        plt.show()

    def pcaBirdDens(data):
        import pandas as pd
        import matplotlib.pyplot as plt
        import seaborn as sns
        data['bird-love-cnd'] = pd.cut(data['bird-love'],[-1,3,6,10],
                                        labels=["poor","neutral","good"])
        fig = plt.figure()
        ax = fig.add_subplot()
        ax = sns.scatterplot(data=data,x="PC1",y="PC2",edgecolors='0.4',
                            hue=data["bird-love-cnd"],palette='crest')
        ax.legend(loc='upper right', fontsize = '10', frameon=True, 
                        framealpha=0.3, facecolor='0.7', title='attitude',
                        title_fontsize='10',borderpad=0.3)
        ax.set_xlabel("PC1")
        ax.set_ylabel("PC2")
        plt.show()
    
    def xgShap(feature_importance, shap_values, title, r2):
        import pandas as pd
        import matplotlib.pyplot as plt
        import seaborn as sns
        import shap

        fig = plt.figure(layout='constrained',figsize=(8,6))
        #FI plot
        ax = fig.add_subplot(211)
        sns.barplot(data=feature_importance, x='FI', y=feature_importance.index, 
                    color='#8b76f3',width=0.5)
        plt.suptitle(title,x=0.56,fontsize=14,fontweight='semibold')
        plt.yticks(fontsize=14)
        plt.ylabel('')
        plt.xlabel('Predicting K Clusters', fontsize=14,x=0.45)
        ax.text(x=0.25,y=0,s = f'R2 = {r2}')
        #SHAP plot
        ax = fig.add_subplot(212)
        shap.plots.beeswarm(shap_values,show=False, color=plt.get_cmap("cool"),
                            plot_size=None,ax=ax)
        plt.xlabel('SHAP',x=0.45)
        plt.show()
        return fig

class Predictions:
    def xgBoost(data):
        # predict KMeans clusters with XGBoost at different timesteps
        from xgboost import XGBRegressor
        from sklearn.model_selection import train_test_split
        from sklearn.model_selection import cross_val_score
        from sklearn.preprocessing import LabelEncoder
        from sklearn.preprocessing import StandardScaler
        from sklearn import metrics
        import pandas as pd
        import shap
        
        # set up data
        X = pd.DataFrame(data[['vegetation-volume','habitat','bird-density','bird-love',
                 'yard-bird-estimate']])
        Y = pd.DataFrame(data[['labels']])
        X_train, X_test, Y_train, Y_test = train_test_split(X, Y, test_size = 0.2, stratify=Y)
        scaler = StandardScaler().fit(X_train)
        X_train = scaler.transform(X_train)
        X_test = scaler.transform(X_test)
        le = LabelEncoder()
        Y_train = le.fit_transform(Y_train)

        # gbm model
        gbm = XGBRegressor()#n_estimators=2,max_depth=2,learning_rate=1)

        # cross validation
        gbm_scores = cross_val_score(gbm, X_train, Y_train)
        print("CV R2: {0} (+/- {1})".format(round(gbm_scores.mean(),2),
                                            round((gbm_scores.std() * 2),2)))
        
        # test final model
        gbm.fit(X_train,Y_train) # fit the model
        gbm_predict = gbm.predict(X_test) # predict with the model
        # metrics for the model
        r2 = round(metrics.r2_score(Y_test, gbm_predict), 2)
        mae = metrics.mean_absolute_error(Y_test, gbm_predict)
        feature_importance = pd.DataFrame(gbm.feature_importances_, index=X.columns, columns=['FI'])
        # shap explanations
        explainer = shap.Explainer(gbm)
        shap_values = explainer(X)
        return r2, mae, feature_importance, shap_values


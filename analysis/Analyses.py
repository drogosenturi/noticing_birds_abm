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
                                    'veg-change-list','patch',
                                    'happy?','max-bird-density'])
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
    
    def decisionTreeK(data):
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

        clf = tree.DecisionTreeClassifier(max_depth=1)
        clf = clf.fit(X_train,Y_train)
        print("Test accuracy", clf.score(X_test,Y_test))
        
        # extract threshold and values of first split
        n_nodes = clf.tree_.node_count
        children_left = clf.tree_.children_left
        children_right = clf.tree_.children_right
        feature = clf.tree_.feature
        threshold = clf.tree_.threshold
        values = clf.tree_.value
        for i in range(n_nodes):
            print("node #:", i,"\n","% of yards:", values[i],"\n",
                    "feature name:", X.columns.values[feature[i]],"\n", "threshold:", threshold[i],
                    "\n","left:", children_left[i],"\n", "right:",children_right[i])
        habitat_threshold = threshold[0]
        # plot
        fig = plt.figure()
        fig, axes = plt.subplots(nrows = 1,ncols=1,figsize=(3,4),dpi=500)
        tree.plot_tree(clf, feature_names=X.columns.values, filled=True)
        plt.show()
        return habitat_threshold
    
    def decisionTreeVeg(datax, datay):
        print('use mimicry = false')
        from sklearn.model_selection import train_test_split
        from sklearn import tree
        import matplotlib.pyplot as plt
        import seaborn as sns
        import pandas as pd

        X = pd.DataFrame(datax[['vegetation-volume','habitat','bird-density','bird-love',
                 'yard-bird-estimate', 'avg-neighbor-richness']])
        Y = pd.DataFrame(datay[['veg-changes']])
        X_test, X_train, Y_test, Y_train = train_test_split(
            X, Y, test_size=0.3)

        clf = tree.DecisionTreeRegressor(criterion='squared_error',max_depth=4,min_samples_leaf=50)
        clf = clf.fit(X_train,Y_train)
        print("Test accuracy", clf.score(X_test,Y_test))
        
        # plot
        fig = plt.figure()
        fig, axes = plt.subplots(nrows = 1,ncols=1,figsize=(20,12),dpi=800)
        tree.plot_tree(clf, feature_names=X.columns.values, fontsize=7, filled=True)
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
                        framealpha=0.3, facecolor='0.7', title='K-cluster',
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

        ## combo plot
        # fig, axes = plt.subplots(2,1, constrained_layout = True)
        # sns.set_theme(font_scale=1.5)
        # sns.barplot(data=feature_importance, x='FI', y=feature_importance.index,
        #              color='#8b76f3',width=0.5, ax=axes[0])
        # shap.plots.beeswarm(shap_values,show=False, color=plt.get_cmap("cool"),
        #                     plot_size=None, ax=axes[1])
        # axes[0].set_xlabel("Feature Importance",size=13)
        # axes[0].set_ylabel(None)
        # axes[0].tick_params(axis='y',labelsize=13)
        ## single SHAP plot
        #SHAP plot
        fig = plt.figure()
        ax = fig.add_subplot()
        shap.plots.beeswarm(shap_values,show=False, color=plt.get_cmap("cool"),
                            plot_size=None)
        ax.set_xlabel('SHAP',x=0.45)
        plt.savefig("plots/final_plots/longitudinal/final.png", bbox_inches='tight',dpi=600)
        plt.close()

        fig1 = plt.figure()
        ax1 = fig1.add_subplot()
        shap.plots.scatter(shap_values[:,"vegetation-volume"])
        return ax

class Predictions:
    def xgBoost_KMeans(datax,datay):
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
        X = pd.DataFrame(datax[['vegetation-volume','habitat','bird-density','bird-love',
                 'yard-bird-estimate','avg-neighbor-richness', 'veg-changes']])
        Y = pd.DataFrame(datay[['labels']])
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
    
    def xgBoost_long(data,train_start,train_end,pred):#vegChange(data_x,data_y):
        from xgboost import XGBRegressor
        from sklearn.model_selection import train_test_split
        from sklearn.model_selection import cross_val_score
        from sklearn.preprocessing import LabelEncoder
        from sklearn.preprocessing import StandardScaler
        from sklearn import metrics
        import pandas as pd
        import shap
        
        # set up data
        # X = pd.DataFrame(data_x[['vegetation-volume','avg-neighbor-richness','bird-density','bird-love',
        #          'yard-bird-estimate', 'habitat']])
        # Y = pd.DataFrame(data_y[['veg-changes']])
        # to get the # of years you want it's 5 * # of years columns w/o avg-neighbor
        X = data.iloc[0:,train_start:train_end]
        # r2 = 97 @ 20 years of training
        X = X[X.columns.drop(list(X.filter(regex='habitat')))]
        Y = data[pred]

        X_train, X_test, Y_train, Y_test = train_test_split(X, Y, test_size = 0.2)
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
    
    # def xgBoost_long(data):
    #     from xgboost import XGBRegressor
    #     from sklearn.model_selection import train_test_split
    #     from sklearn.model_selection import cross_val_score
    #     from sklearn.preprocessing import LabelEncoder
    #     from sklearn.preprocessing import StandardScaler
    #     from sklearn import metrics
    #     import pandas as pd
    #     import shap

    #     # to get the # of years you want it's 7 * # of years columns
    #     # make Y explicit by name - just habitat, or the whole model?
    #     X = data.iloc[0:,0:140]
    #     Y = data["habitat59"]

class Stats:
    def tTest(data):
        import pandas as pd
        import numpy as np
        from scipy.stats import mannwhitneyu
        import matplotlib.pyplot as plt

        cluster0 = data.loc[data['labels'] == 0]
        cluster1 = data.loc[data['labels'] == 1]
        cluster0 = cluster0.sample(1000)
        cluster1 = cluster1.sample(1000)
        fig = plt.figure(constrained_layout = True, figsize=(8,6))

        print('vegetation volume')
        t_stat, p_val = mannwhitneyu(cluster0['vegetation-volume'], cluster1['vegetation-volume'])
        print(f'U: {t_stat}', f'p-val: {p_val}\n')
        if p_val < 0.001:
            p_val = "***"
        ax = fig.add_subplot(321)
        x = [cluster0['vegetation-volume'], cluster1['vegetation-volume']]
        plt.title('vegetation-volume')
        
        ax.text(x=0, y=0, s= p_val)
        plt.boxplot(x, labels = ["NN","EoE"])

        print('habitat')
        t_stat, p_val = mannwhitneyu(cluster0['habitat'], cluster1['habitat'])
        
        print(f'U: {t_stat}', f'p-val: {p_val}\n')
        if p_val < 0.001:
            p_val = "***"
        ax = fig.add_subplot(322)
        x = [cluster0['habitat'], cluster1['habitat']]
        plt.title('habitat')
        
        ax.text(x=0, y=0, s= p_val)
        plt.boxplot(x, labels = ["NN","EoE"])

        print('bird-density')
        t_stat, p_val = mannwhitneyu(cluster0['bird-density'], cluster1['bird-density'])
        
        print(f'U: {t_stat}', f'p-val: {p_val}\n')
        if p_val < 0.001:
            p_val = "***"
        ax = fig.add_subplot(323)
        x = [cluster0['bird-density'], cluster1['bird-density']]
        plt.title('bird-density')
        
        ax.text(x=0, y=0, s= p_val)
        plt.boxplot(x, labels = ["NN","EoE"])

        print('bird-love')
        t_stat, p_val = mannwhitneyu(cluster0['bird-love'], cluster1['bird-love'])
        
        print(f'U: {t_stat}', f'p-val: {p_val}\n')
        if p_val < 0.001:
            p_val = "***"
        ax = fig.add_subplot(324)
        x = [cluster0['bird-love'], cluster1['bird-love']]
        plt.title('bird-love')
        
        ax.text(x=0, y=0, s= p_val)

        plt.boxplot(x, labels = ["NN","EoE"])

        print('yard-bird-estimate')
        t_stat, p_val = mannwhitneyu(cluster0['yard-bird-estimate'], cluster1['yard-bird-estimate'])
        
        print(f'U: {t_stat}', f'p-val: {p_val}\n')
        if p_val < 0.001:
            p_val = "***"
        ax = fig.add_subplot(325)
        x = [cluster0['yard-bird-estimate'], cluster1['yard-bird-estimate']]
        plt.title('yard-bird-estimate')

        ax.text(x=0, y=0, s= p_val)

        plt.boxplot(x, labels = ["NN","EoE"])

        print('avg-neighbor-richness')
        t_stat, p_val = mannwhitneyu(cluster0['avg-neighbor-richness'], cluster1['avg-neighbor-richness'])
        
        print(f'U: {t_stat}', f'p-val: {p_val}\n')
        if p_val < 0.001:
            p_val = "***"
        ax = fig.add_subplot(326)
        x = [cluster0['avg-neighbor-richness'], cluster1['avg-neighbor-richness']]
        plt.title('avg-neighbor-richness')
        ax.text(x=0, y=0, s= p_val)
        plt.boxplot(x, labels = ["NN","EoE"])
        return plt.show()

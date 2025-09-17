from Analyses import Processing, Clustering, DimensionalityReduction, Predictions, Plots, Stats
from os import listdir


def runCART(filey):#, filey, title):
    #datax, data_scaledx = Processing.readIn(filex)
    datay, data_scaledy = Processing.readIn(filey)

    clusters = 2
    data, s_score = Clustering.kMeans(datay, clusters)
    # clusters = 3
    # data, s_score = Clustering.kMeans(datay, clusters)
    # clusters = 4
    # data, s_score = Clustering.kMeans(datay, clusters)
    # clusters = 5
    # data, s_score = Clustering.kMeans(datay, clusters)
    # clusters = 6
    #data, s_score = Clustering.kMeans(datay, clusters)

    tsne = DimensionalityReduction.tSNE(data, data_scaledy)
    Plots.tsneK(tsne)
    #threshold = Clustering.decisionTreeK(datay)

    #r2, mae, feature_importance, shap = Predictions.xgBoost_KMeans(datax, datay)
    #Plots.xgShap(feature_importance, shap, title, r2)
    return #threshold

def runVegChanges(filex,filey): # this is defunct
    data_x, data_scaled_x = Processing.readIn(filex)
    data_y, data_scaled_y = Processing.readIn(filey)
    ### XGBOOST/SHAP ###
    # r2, mae, feature_importance, shap = Predictions.xgBoost_vegChange(data_x,data_y)
    # title = "veg-change prediction"
    # Plots.xgShap(feature_importance, shap, title, r2)

    ### CART ###
    Clustering.decisionTreeVeg(data_x, data_y)

def runStats(file):
    # process data and calculate k-means clusters
    data, data_Scaled = Processing.readIn(file)
    clusters = 2
    data, s_score = Clustering.kMeans(data, clusters)
    # mann whitney
    Stats.tTest(data)
    return data

#### READ IN ####
path = "/home/sokui/netlogo_models/experiments_9-9/results/clean/"
data_list = []
# make list of files at tick150 with mimicry = true
for f in listdir(path):
    if f.endswith('true.csv') & f.startswith('tick150'):
        data_list.append(path + f)

#### clusters and decision tree ####
for i in data_list:
    runCART(i)

###### Mann-whitney ######
#data = runStats(data_list[5])


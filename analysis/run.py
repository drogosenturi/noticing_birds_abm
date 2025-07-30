from Analyses import Processing, Clustering, DimensionalityReduction, Predictions, Plots, Stats
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns
from os import listdir


def runCART(filey):#, filey, title):
    #datax, data_scaledx = Processing.readIn(filex)
    datay, data_scaledy = Processing.readIn(filey)

    # 2 clusters is best at 0.71, 3 and 4 are ~0.60
    clusters = 2
    data, s_score = Clustering.kMeans(datay, clusters)

    #DimensionalityReduction.tSNE(datay, data_scaledy)
    #Plots.tsneK(datay)
    threshold = Clustering.decisionTreeK(datay)

    #r2, mae, feature_importance, shap = Predictions.xgBoost_KMeans(datax, datay)
    #Plots.xgShap(feature_importance, shap, title, r2)
    return threshold

def runVegChanges(filex,filey):
    data_x, data_scaled_x = Processing.readIn(filex)
    data_y, data_scaled_y = Processing.readIn(filey)
    ### XGBOOST/SHAP ###
    # r2, mae, feature_importance, shap = Predictions.xgBoost_vegChange(data_x,data_y)
    # title = "veg-change prediction"
    # Plots.xgShap(feature_importance, shap, title, r2)

    ### CART ###
    Clustering.decisionTreeVeg(data_x, data_y)

def runStats(file):
    data, data_Scaled = Processing.readIn(file)

    clusters = 2
    data, s_score = Clustering.kMeans(data, clusters)
    Stats.tTest(data)
    return data


### MIMICRY: TRUE ###
path = "/home/sokui/netlogo_models/experiments_7-22/clean/"
data_list = []
# make list of files at tick150 with mimicry = true
for f in listdir(path):
    if f.endswith('true.csv') & f.startswith('tick150'):
        data_list.append(path + f)

#runCART(tick60, tick120, 'tick 60')

### MIMICRY: FALSE ###
data_list = []
for f in listdir(path):
    if f.endswith('true.csv') & f.startswith('tick150'):
        data_list.append(path + f)

#runVegChanges(tick50,tick60)
# thresholds = []
# for i in data_list:
#     thresholds.append(runCART(i))

data = runStats(data_list[5])
# output w/ clusters
# data.to_csv('~/tick150_true_clusters.csv')

# filex = path + "tick140_run15_true.csv"
# filey = path + "tick150_run15_true.csv"
# runVegChanges(filex,filey) 

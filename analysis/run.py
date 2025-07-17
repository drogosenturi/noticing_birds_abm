from Analyses import Processing, Clustering, DimensionalityReduction, Predictions, Plots
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns


def runStats(filex, filey, title):
    datax, data_scaledx = Processing.readIn(filex)
    datay, data_scaledy = Processing.readIn(filey)

    # 2 clusters is best at 0.71, 3 and 4 are ~0.60
    clusters = 2
    data, s_score = Clustering.kMeans(datay, clusters)

    #DimensionalityReduction.tSNE(datay, data_scaledy)
    #Plots.tsneK(datay)
    Clustering.decisionTree(datay)

    r2, mae, feature_importance, shap = Predictions.xgBoost_KMeans(datax, datay)
    Plots.xgShap(feature_importance, shap, title, r2)

def runVegChanges(filex,filey):
    data_x, data_scaled_x = Processing.readIn(filex)
    data_y, data_scaled_y = Processing.readIn(filey)

    r2, mae, feature_importance, shap = Predictions.xgBoost_vegChange(data_x,data_y)
    title = "veg-change prediction"
    Plots.xgShap(feature_importance, shap, title, r2)

### MIMICRY: TRUE ###
end = "~/netlogo_models/experiments_7-15/endtrue.csv"
start = "~/netlogo_models/experiments_7-15/snapshot0_true.csv"
tick20 = "~/netlogo_models/experiments_7-15/snapshot20_true.csv"
tick40 = "~/netlogo_models/experiments_7-15/snapshot40_true.csv"
tick50 = "~/netlogo_models/experiments_7-15/snapshot50_true.csv"
tick60 = "~/netlogo_models/experiments_7-15/snapshot60_true.csv"
tick70 = "~/netlogo_models/experiments_7-15/snapshot70_true.csv"
tick80 = "~/netlogo_models/experiments_7-15/snapshot80_true.csv"
tick100 = "~/netlogo_models/experiments_7-15/snapshot100_true.csv"
tick120 = "~/netlogo_models/experiments_7-15/snapshot120_true.csv"
tick140 = "~/netlogo_models/experiments_7-15/snapshot140_true.csv"
tick150 = "~/netlogo_models/experiments_7-15/snapshot150_true.csv"

runVegChanges(tick140,tick150)
runStats(tick60, tick120, 'tick 60')

### MIMICRY: FALSE ###
end = "~/netlogo_models/experiments_7-15/endfalse.csv"
start = "~/netlogo_models/experiments_7-15/snapshot0_false.csv"
tick20 = "~/netlogo_models/experiments_7-15/snapshot20_false.csv"
tick40 = "~/netlogo_models/experiments_7-15/snapshot40_false.csv"
tick50 = "~/netlogo_models/experiments_7-15/snapshot50_false.csv"
tick60 = "~/netlogo_models/experiments_7-15/snapshot60_false.csv"
tick70 = "~/netlogo_models/experiments_7-15/snapshot70_false.csv"
tick80 = "~/netlogo_models/experiments_7-15/snapshot80_false.csv"
tick100 = "~/netlogo_models/experiments_7-15/snapshot100_false.csv"
tick120 = "~/netlogo_models/experiments_7-15/snapshot120_false.csv"

runVegChanges(tick50,tick60)
runStats()

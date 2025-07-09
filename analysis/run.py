from Analyses import Processing, Clustering, DimensionalityReduction, Predictions, Plots
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns

end = "~/netlogo_models/experiments_7-3/endtrue.csv"
start = "~/netlogo_models/experiments_7-3/snapshot0_true.csv"
tick20 = "~/netlogo_models/experiments_7-3/snapshot20_true.csv"
tick40 = "~/netlogo_models/experiments_7-3/snapshot40_true.csv"
tick60 = "~/netlogo_models/experiments_7-3/snapshot60_true.csv"
tick80 = "~/netlogo_models/experiments_7-3/snapshot80_true.csv"
tick100 = "~/netlogo_models/experiments_7-3/snapshot100_true.csv"
tick120 = "~/netlogo_models/experiments_7-3/snapshot120_true.csv"

data, data_scaled = Processing.readIn(end)

# 2 clusters is best at 0.71, 3 and 4 are ~0.60
clusters = 2
data, s_score = Clustering.kMeans(data, clusters)
data_k = data['labels']
DimensionalityReduction.tSNE(data, data_scaled)
Plots.tsneK(data)
Clustering.decisionTree(data)

file_list = [start, tick20, tick40, tick60, tick80, tick100, tick120]
titles = ['start', 'tick20', 'tick40', 'tick60', 'tick80', 'tick100', 'tick120']
y = 0
fig = []
for i in file_list:
    data, data_scaled = Processing.readIn(i)
    data['labels'] = data_k
    r2, mae, feature_importance, shap = Predictions.xgBoost(data)
    title = titles[y]
    fig.append(Plots.xgShap(feature_importance, shap, title, r2))
    y += 1

import pandas as pd
import sys
import numpy as np
from os import listdir
from Analyses import Predictions, Plots

def cleaner(file, n):
    data = pd.read_csv(file)
    data[["pycor"]] = data[["pycor"]].astype(str)
    data[["pxcor"]] = data[["pxcor"]].astype(str)
    data["patch"] = data["pxcor"] + data["pycor"]
    data = data.drop(columns=["pycor","pxcor",'pcolor','plabel','plabel-color',
                                'veg-change-list','patch', 'veg-changes', 'avg-neighbor-richness',
                                'happy?','max-bird-density', 'happy-min', 'happy-max'])
    for series_name, series in data.items():
        data = data.rename(columns={series_name: series_name + str(n)})
    return data

path = "/home/sokui/netlogo_models/experiments_8-29/results/clean/"
data_list = []
# make list of files at tick150 with mimicry = true
for f in listdir(path):
    data_list.append(path + f)

# make the first df
n = 20
main = cleaner(data_list[0], n)
del data_list[0]
n += 1

# iterate files thru cleaner and append to main
for file in data_list:
    data = cleaner(file, n)
    main = pd.concat([main, data], axis=1)
    n += 1

# to get the # of years you want it's 5 * # of years
start_train = 100 # year 20
end_train = 125 # year 45
predict = "habitat80"
r2, mae, feature_importance, shap_values = Predictions.xgBoost_long(main, start_train, end_train, predict)
# print results to console
print(f"R^2 = {r2}\nMAE = {mae}")
# combine the feature importance of each predictor
summed_FI = pd.DataFrame({"FI": 0}, index=['vegetation-volume','bird-density','bird-love',
                 'yard-bird-estimate']) # removed avg-neighbor-richness and habitat for now
summed_FI.loc['vegetation-volume'] = sum(feature_importance.filter(regex="vegetation-volume", axis="index")['FI'])
summed_FI.loc['bird-density'] = sum(feature_importance.filter(regex="bird-density", axis="index")['FI'])
summed_FI.loc['bird-love'] = sum(feature_importance.filter(regex="bird-love", axis="index")['FI'])
summed_FI.loc['yard-bird-estimate'] = sum(feature_importance.filter(regex="yard-bird-estimate", axis="index")['FI'])

# trying to summarize SHAP
columns = ['vegetation-volume60','bird-density60','bird-love60','yard-bird-estimate60',
'vegetation-volume61','bird-density61','bird-love61','yard-bird-estimate61',
'vegetation-volume62','bird-density62','bird-love62','yard-bird-estimate62',
'vegetation-volume63','bird-density63','bird-love63','yard-bird-estimate63',
'vegetation-volume64','bird-density64','bird-love64','yard-bird-estimate64']

shapframe = pd.DataFrame(shap_values.values, columns=columns)
shapdata = pd.DataFrame(shap_values.data, columns = columns)

summedShap = pd.DataFrame(columns=['vegetation-volume','bird-density','bird-love',
                 'yard-bird-estimate'])
summedShap['vegetation-volume'] = shapframe.filter(regex="vegetation-volume").sum(1)
summedShap['bird-density'] = shapframe.filter(regex="bird-density").sum(1)
summedShap['bird-love'] = shapframe.filter(regex="bird-love").sum(1)
summedShap['yard-bird-estimate'] = shapframe.filter(regex="yard-bird-estimate").sum(1)
newshap = summedShap.values
print(newshap)
summedData = pd.DataFrame(columns=['vegetation-volume','bird-density','bird-love',
                 'yard-bird-estimate'])
summedData['vegetation-volume'] = shapdata.filter(regex="vegetation-volume").mean(1)
summedData['bird-density'] = shapdata.filter(regex="bird-density").mean(1)
summedData['bird-love'] = shapdata.filter(regex="bird-love").mean(1)
summedData['yard-bird-estimate'] = shapdata.filter(regex="yard-bird-estimate").mean(1)
newShapData = summedData.values
print(newShapData)
import shap
import matplotlib.pyplot as plt
import seaborn as sns
shap_explain = shap.Explanation(
        values = newshap,
        base_values=shap_values.base_values,
        data=newShapData,
        feature_names=summedShap.columns.tolist()
        )
#shap.summary_plot(shap_explain)
#shapframe.to_csv("/home/sokui/shap.csv")
#shapdata.to_csv("/home/sokui/shapdata.csv")

plot = Plots.xgShap(summed_FI, shap_explain, "trained year 60 - 65 | predicting habitat at year 90", r2)

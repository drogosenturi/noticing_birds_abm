import pandas as pd
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
start_train = 200 # year 40
end_train = 225 # year 45
predict = "habitat70"
r2, mae, feature_importance, shap_values = Predictions.xgBoost_long(main, start_train, end_train, predict)

summed_FI = pd.DataFrame({"FI": 0}, index=['vegetation-volume','bird-density','bird-love',
                 'yard-bird-estimate']) # removed avg-neighbor-richness and habitat for now
summed_FI.loc['vegetation-volume'] = sum(feature_importance.filter(regex="vegetation-volume", axis="index")['FI'])
#summed_FI.loc['habitat'] = sum(feature_importance.filter(regex="habitat", axis="index")['FI'])
summed_FI.loc['bird-density'] = sum(feature_importance.filter(regex="bird-density", axis="index")['FI'])
summed_FI.loc['bird-love'] = sum(feature_importance.filter(regex="bird-love", axis="index")['FI'])
summed_FI.loc['yard-bird-estimate'] = sum(feature_importance.filter(regex="yard-bird-estimate", axis="index")['FI'])
#summed_FI.loc['avg-neighbor-richness'] = sum(feature_importance.filter(regex="avg-neighbor-richness", axis="index")['FI'])
#summed_FI.loc['veg-changes'] = sum(feature_importance.filter(regex="veg-changes", axis="index")['FI'])
# figure out how to summarize shap values like FI values above
plot = Plots.xgShap(summed_FI, shap_values, "trained year 60 - 65 | predicting habitat at year 90", r2)
'''
Checking feature importance for each part of the NN cycle
Conclusion: yard-bird estimate seems overly important for
    most estimates. When trying to predict bird density, yard
    -bird-estimate exaplins 100% of the data. XGBoost may not
    be ideal here unless we determine a better variable to predict.
'''
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns
from xgboost import XGBRegressor
from sklearn.model_selection import train_test_split
from sklearn.model_selection import cross_val_score
from sklearn.preprocessing import LabelEncoder
from sklearn.preprocessing import StandardScaler
from sklearn import metrics
import shap

# pull in the 10 test files
file1 = "~/netlogo_models/data/cluster_data/4-10-25/run1_clean.csv"
file2 = "~/netlogo_models/data/cluster_data/4-10-25/run2_clean.csv"
'''
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
'''
# function to concatenate each dataframe and take average
# USELESS BECAUSE SPATIAL EXPLICITNESS CHANGES EVERY TIME

data = pd.read_csv(file2)
data[["pycor"]] = data[["pycor"]].astype(str)
data[["pxcor"]] = data[["pxcor"]].astype(str)
data["patch"] = data["pxcor"] + data["pycor"]
data = data.drop(columns=["pycor","pxcor",'pcolor','plabel','plabel-color',
                            'veg-change-list','patch'])
 
# Veg-volume + habitat -> bird-density
# veg volume is a bimodal dist
X = pd.DataFrame(data[["bird-density","yard-bird-estimate","max-bird-density"]])
#X = data.drop(columns=['bird-density'])
Y = data['bird-love']
#plt.xlabel("habitat value")
#plt.ylabel("bird density by patch")
#plt.scatter(X,Y) # perfectly correlated as expect R2 = 1
#plt.savefig('plots/habitat_bird-dens.png')
le = LabelEncoder()

X_train, X_test, Y_train, Y_test = train_test_split(X, Y, test_size = 0.2,
                                                    stratify=Y)
#scaling
scaler = StandardScaler().fit(X_train)
X_train = scaler.transform(X_train)
X_test = scaler.transform(X_test)
#Y_train = le.fit_transform(Y_train)

# gbm model
gbm = XGBRegressor(n_estimators=2,max_depth=2,learning_rate=1)
# cross validation
gbm_scores = cross_val_score(gbm, X_train, Y_train)
print("CV R2: {0} (+/- {1})".format(round(gbm_scores.mean(),2),
                                    round((gbm_scores.std() * 2),2)))
# fit
model = gbm.fit(X_train,Y_train)
# predict
gbm_predict = gbm.predict(X_test)
gbm_r2 = metrics.r2_score(Y_test, gbm_predict)
gbm_mae = metrics.mean_absolute_error(Y_test, gbm_predict)
print("Gradient Boosting: {0}".format(gbm_predict.round(2))) #Because gbm_predict is a numpy array, we can use ".round(2)"
print("Gradient Boosting R2: {0}".format(round(gbm_r2,2)))
print("Gradient Boosting MAE: {0}".format(round(gbm_mae,2)))
print("")

#feature importance
FI = pd.DataFrame(gbm.feature_importances_, index=X.columns, columns=['FI'])
plt.ylabel('')
sns.barplot(data=FI, x='FI', y=FI.index)
plt.show()

# shap
explainer = shap.Explainer(model, X)
shap_values = explainer(X)
shap_train = explainer(X_train) 
shap_test = explainer(X_test)

shap.plots.beeswarm(shap_values)
plt.show()
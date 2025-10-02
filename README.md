<h1 align="center"><b>Noticing Birds</b></h1>

<p align="center"><img src="https://noticing-birds.spinup.show/noticing_birds_landscape.gif" /></p>  

*Noticing Birds* is an agent-based model written in [NetLogo](https://www.netlogo.org/). It simulates 
how urban landowners adjust the vegetation in their yards in response to wild bird populations based on 
their attitudes toward nature, their pre-existing vegetation, and their neighbors vegetation.

### Try it out!
First, [download NetLogo 6.4.0](https://ccl.northwestern.edu/netlogo/oldversions.shtml).  
  
Then, download the `noticing_birds_mimicry.nlogo` file in this repository. Launch the NetLogo application, open the model file, 
`setup`, and `Go`! This is how the model runs with the default calibration. Feel free to play with the sliders 
to see how the landscape changes.

## Data Analysis

### XGBoost and SHAP

To predict how yards' vegetation will look in the future, we trained an XGBoost model and used 
SHAP to interpret it. This is the result of an XGBoost trained to predict habitat values 30 years into the 
future with only 5 years of vegetation change data:
![SHAP analysis of XGBoost output predicting habitat at year 90 based on vegetation volume data from years 40-45](https://noticing-birds.spinup.show/final.png)  
Vegetation volume is the best predictor of a yard's future habitat value and yards with higher values of vegetation volume have a larger, positive impact on 
the model outcome.  

Authors: Nikolas Ballut, Megan Garfinkel, Emily Minor

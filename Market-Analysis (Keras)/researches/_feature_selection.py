# -*- coding: utf-8 -*-
###############################################################################
#                                                                             #
#   Market Analysis System                                                    #
#   https://www.mql5.com/ru/users/terentyev23                                 #
#                                                                             #
#   M A R K E T   A N A L Y S I S   S C R I P T   W I T H   K E R A S         #
#                                                                             #
#   Aleksey Terentyev                                                         #
#   terentew.aleksey@ya.ru                                                    #
#                                                                             #
###############################################################################
"""The script uses several methods for selecting parameters and displays the results on the graphs."""

import numpy as np

import sys
sys.path.append('E:\Projects\market-analysis-system\Market-Analysis (Keras)')
from mas.data import get_deltas_from_ohlc, get_delta
from mas.data import get_diff, get_log_diff
from mas.data import get_sigmoid_to_zero
from mas.data import data_preview

from statsmodels.nonparametric.smoothers_lowess import lowess

from mas.classes import signal_to_class2, class2_to_signal
from mas.classes import signal_to_class3, class3_to_signal

import matplotlib.pyplot as plt


"""Load data."""
path = 'C:/Users/Alexey/AppData/Roaming/MetaQuotes/Terminal/287469DEA9630EA94D0715D755974F1B/MQL4/Files/ML-Assistant/'
symbol = 'EURUSD1440'
file_x = path + symbol + '_x.csv'
file_y = path + symbol + '_y.csv'

data = np.genfromtxt(file_x, delimiter=';')
data_out = np.genfromtxt(file_y, delimiter=';')

print('data_x shape: ', data.shape)
print('data_y shape: ', data_out.shape)


"""Transform data."""
delta_prices = get_deltas_from_ohlc(data, 7)
derivative1 = get_diff(data[:, 7], 1)
derivative2 = get_diff(data[:, 8], 1)
derivative3 = get_diff(data[:, 9], 1)
derivative4 = get_diff(data[:, 10], 1)
logdiff1 = get_log_diff(data[:, 7])
logdiff2 = get_log_diff(data[:, 8])
logdiff3 = get_log_diff(data[:, 9])
logdiff4 = get_log_diff(data[:, 10])
sigmoid1 = get_sigmoid_to_zero(data[:, 7])
sigmoid2 = get_sigmoid_to_zero(data[:, 8])
sigmoid3 = get_sigmoid_to_zero(data[:, 9])
sigmoid4 = get_sigmoid_to_zero(data[:, 10])
lowess1 = lowess(data[:, 10], range(data.shape[0]), return_sorted=False, frac= 1./100)
lowess2 = lowess(data[:, 10], range(data.shape[0]), return_sorted=False, frac= 1./250)
lowess3 = lowess(data[:, 10], range(data.shape[0]), return_sorted=False, frac= 1./250, it=0)
detrend_close1 = data[:, 10] - data[:, 11]
detrend_close2 = data[:, 10] - lowess3

delta_ema1 = get_delta(data, 4, 5)
delta_ema2 = get_delta(data, 6, 7)
derivative_ema1 = get_diff(data[:, 11])
derivative_ema2 = get_diff(data[:, 12])
derivative_ema3 = get_diff(data[:, 13])
derivative_ema4 = get_diff(data[:, 14])
logdiff_ema1 = get_log_diff(data[:, 11])
sigmoid_ema = get_sigmoid_to_zero(data[:, 11])

data_x = np.array([data[:, 0], data[:, 1], data[:, 2], data[:, 3], data[:, 4], data[:, 5], data[:, 6], # time data [0,6]
                    data[:, 7], data[:, 8], data[:, 9], data[:, 10], # prices data [7, 10]
                    delta_prices[:, 0], delta_prices[:, 1], delta_prices[:, 2], # price deltas [11, 16]
                    delta_prices[:, 3], delta_prices[:, 4], delta_prices[:, 5],
                    derivative1, derivative2, derivative3, derivative4,
                    logdiff1, logdiff2, logdiff3, logdiff4,
                    sigmoid1, sigmoid2, sigmoid3, sigmoid4,
                    lowess1, lowess2, lowess3,
                    detrend_close1, detrend_close2,
                    data[:, 11], data[:, 12], data[:, 13], data[:, 14], # ema data
                    delta_ema1, delta_ema2,
                    derivative_ema1, derivative_ema2, derivative_ema3, derivative_ema4,
                    logdiff_ema1, sigmoid_ema,
                    data[:, 15], data[:, 16], # macd
                    data[:, 17], data[:, 18], data[:, 19], # atr, cci, rsi
                    data[:, 20], data[:, 21] # usdx, eurx
                  ]).swapaxes(0, 1)

sigmoid_y = get_sigmoid_to_zero(data_out)
data_y = signal_to_class2(data_out)


"""Plot data"""
idx_start = -100
idx_stop = -1
# plot prices
plt.plot(data[idx_start:, 8])
plt.plot(data[idx_start:, 9])
plt.plot(data[idx_start:, 10])
plt.legend(['high', 'low', 'close'], loc='best')
plt.show()
# plot deltas
plt.plot(delta_prices[idx_start:, 0])
plt.plot(delta_prices[idx_start:, 1])
plt.plot(delta_prices[idx_start:, 2])
plt.plot(delta_prices[idx_start:, 3])
plt.plot(delta_prices[idx_start:, 4])
plt.plot(delta_prices[idx_start:, 5])
plt.legend(['o-c', 'h-l', 'h-o', 'h-c', 'o-l', 'c-l'], loc='best')
plt.show()
# plot derivatives
plt.plot(derivative1[idx_start:])
plt.plot(derivative2[idx_start:])
plt.plot(derivative3[idx_start:])
plt.plot(derivative4[idx_start:])
plt.legend(['open', 'high', 'low', 'close'], loc='best')
plt.show()
# plot log derivatives
plt.plot(logdiff1[idx_start:])
plt.plot(logdiff2[idx_start:])
plt.plot(logdiff3[idx_start:])
plt.plot(logdiff4[idx_start:])
plt.legend(['open', 'high', 'low', 'close'], loc='best')
plt.show()
# plot sigmoids
plt.plot(sigmoid1[idx_start:])
plt.plot(sigmoid2[idx_start:])
plt.plot(sigmoid3[idx_start:])
plt.plot(sigmoid4[idx_start:])
plt.legend(['open', 'high', 'low', 'close'], loc='best')
plt.show()
# plot lowess
_start, _stop = 2000, 2100
plt.plot(data[_start:_stop, 10])
plt.plot(lowess1[_start:_stop])
plt.plot(lowess2[_start:_stop])
plt.plot(lowess3[_start:_stop])
plt.legend(['close', 'lowess 1/100', 'lowess 1/250', 'lowess 1/250 it=0'], loc='best')
plt.show()
# plot comparison
plt.plot(delta_prices[idx_start:, 0])
plt.plot(derivative4[idx_start:])
plt.plot(logdiff4[idx_start:])
plt.plot(detrend_close1[idx_start:])
plt.plot(detrend_close2[idx_start:])
plt.legend(['delta open-close', 'close derivative 1', 'close log diff', 'close - ema 13', 'close - lowess'], loc='best')
plt.show()
# # plot data y
# sigm_y = sigmoid_y / 10
# plt.plot(sigm_y)
# plt.show()

# plot ema
plt.plot(data[idx_start:, 11])
plt.plot(data[idx_start:, 12])
plt.plot(data[idx_start:, 13])
plt.plot(data[idx_start:, 14])
plt.legend(['13', '26', '65', '130'], loc='best')
plt.show()

# plot macd
plt.plot(data[idx_start:, 15])
plt.plot(data[idx_start:, 16])
plt.legend(['line', 'hist'], loc='best')
plt.show()

# plot atr
plt.plot(data[idx_start:, 17])
plt.show()

# plot cci
plt.plot(data[idx_start:, 18])
plt.show()

# plot rsi
plt.plot(data[idx_start:, 19])
plt.show()

# plot indexes
plt.plot(data[idx_start:, 20])
plt.plot(data[idx_start:, 21])
plt.legend(['usdx', 'eurx'], loc='best')
plt.show()


"""Chi-square."""
from sklearn.feature_selection import chi2
from sklearn.feature_selection import SelectKBest

# x_chi = SelectKBest(chi2, k=10).fit_transform(np.abs(data_x), data_y)
kbest = SelectKBest(chi2, k=20).fit(np.abs(data_x), data_out)
kbest.scores_
kbest.pvalues_
plt.plot(kbest.scores_)
plt.show()
plt.plot(kbest.pvalues_)
plt.show()

"""Recursive feature elimination."""
from sklearn.feature_selection import RFE
from sklearn.linear_model import LinearRegression

# select 10 the most informative features
# x_rfe = RFE(LinearRegression(), 10).fit_transform(data_x, data_y)
selector = RFE(LinearRegression(), 20).fit(data_x, data_out)
selector.support_
selector.ranking_
plt.plot(selector.support_)
plt.plot(selector.ranking_)
plt.show()


"""Ridge regression (L2)."""
from sklearn.linear_model import Ridge

clr = Ridge(alpha=0.1)
clr.fit(data_x, data_out)
clr.coef_
plt.plot(clr.coef_)
plt.show()


"""Lasso regression (L1)."""
from sklearn.linear_model import Lasso

cll = Lasso(alpha=0.01)
cll.fit(data_x, data_out)
cll.coef_
plt.plot(cll.coef_)
plt.show()


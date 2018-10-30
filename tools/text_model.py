#!./myenv/bin/python

import sys
import numpy as np
import tensorflow as tf
from tensorflow import keras

def load_data(datafile, labelsfile):
    data = np.genfromtxt(datafile, delimiter='\t', dtype=int)
    labels = np.genfromtxt(labelsfile, dtype=int)
    order = np.argsort(np.random.random(labels.shape))
    return data[order], labels[order]

data, labels = load_data(sys.argv[1], sys.argv[2])

nwords = data.max()
ncat = labels.max()
print("training data: {}, labels: {}".format(len(data), len(labels)))
print("vocabulary: {}, distinct labels: {}".format(nwords, ncat))

model = keras.Sequential([
    keras.layers.Embedding(nwords, 16),
    keras.layers.GlobalAveragePooling1D(),
    keras.layers.Dense(16, activation=tf.nn.relu),
    keras.layers.Dense(ncat, activation=tf.nn.softmax)
])

model.compile(
    optimizer='adam',
    loss='sparse_categorical_crossentropy',
    metrics=['accuracy']
)

model.fit(data, labels, validation_split=0.3)
model.save_weights(sys.argv[3])



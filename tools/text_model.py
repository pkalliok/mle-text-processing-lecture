#!./myenv/bin/python

import numpy as np
import tensorflow as tf
from tensorflow import keras
from tensorflow.python.framework.errors_impl import NotFoundError

def load_data(datafile, labelsfile):
    data = np.genfromtxt(datafile, delimiter='\t', dtype=int)
    labels = np.genfromtxt(labelsfile, dtype=int)
    order = np.argsort(np.random.random(labels.shape))
    return data[order], labels[order] - 1

def report_data(data, labels):
    print("training data: {}, labels: {}".format(len(data), len(labels)))
    print("vocabulary: {}, categories: {}".format(data.max(), labels.max()+1))

def text_model(nwords, ncat):
    model = keras.Sequential([
        keras.layers.Embedding(nwords, ncat*16),
        keras.layers.GlobalAveragePooling1D(),
        keras.layers.Dense(ncat*16, activation=tf.nn.relu),
        keras.layers.Dense(ncat, activation=tf.nn.softmax)])
    model.compile(
        optimizer='adam',
        loss='sparse_categorical_crossentropy',
        metrics=['accuracy'])
    return model

def maybe_load_weights(model, checkpoint_name):
    try: model.load_weights(checkpoint_name)
    except NotFoundError: print("No old weights found, starting new model")

def train_model(model, data, labels):
    model.fit(data, labels,
        batch_size=512,
        epochs=int(len(data)/200),
        validation_split=0.2)

def report_model(model):
    print("Predictions:")
    print(model.predict(data[:10]))
    print("Actual labels:")
    print(labels[:10])

def main(args):
    data, labels = load_data(args[2], args[3])
    report_data(data, labels)
    model = text_model(data.max() + 1, labels.max() + 1)
    maybe_load_weights(model, args[1])
    train_model(model, data, labels)
    model.save_weights(args[1])

if __name__ == '__main__':
    import sys
    main(sys.argv)


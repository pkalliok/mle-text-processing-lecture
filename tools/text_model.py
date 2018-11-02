#!./myenv/bin/python

from math import sqrt
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

def load_state(modelname, datafile, labelfile):
    data, labels = load_data(datafile, labelfile)
    report_data(data, labels)
    # WARNING: the text model is built on the shape of the data.  If you
    # are updating the model with data that has a different shape
    # (different number of labels and/or words), everything will go BOOM
    # because load_weights only works when the model structure is
    # exactly the same.
    model = text_model(data.max() + 1, labels.max() + 1)
    maybe_load_weights(model, modelname)
    return model, data, labels

def train_model(model, data, labels):
    model.fit(data, labels,
        batch_size=512,
        epochs=int(4000/sqrt(len(data))),
        validation_split=0.2)

def report_model(model, data, labels):
    print("Predictions:")
    print(model.predict(data[:10]))
    print("Actual labels:")
    print(labels[:10])

def learn(modelname, datafile, labelfile):
    model, data, labels = load_state(modelname, datafile, labelfile)
    train_model(model, data, labels)
    model.save_weights(modelname)

def predict(modelname, datafile, labelfile):
    model, data, labels = load_state(modelname, datafile, labelfile)
    report_model(model, data, labels)

def read_sample_from_stdin():
    return np.array([int(w) for w in input("> ").split()], ndmin=2)

def classify(modelname, nwords, ncat):
    model = text_model(int(nwords) + 1, int(ncat))
    maybe_load_weights(model, modelname)
    sample = read_sample_from_stdin()
    print("Probabilities of categories:")
    print(model.predict(sample))

handlers = {
    'learn': learn,
    'show-predictions': predict,
    'classify': classify,
}

def main(args):
    try: handlers[args[1]](*args[2:])
    except KeyError:
        print("No such action '{}', try one of: {}"
                .format(args[1], tuple(handlers.keys())))

if __name__ == '__main__':
    import sys
    main(sys.argv)



crypto = require 'server/crypto'
Promise = require 'bluebird'

cryptoKey = 'This should be a sufficiently long encryption key. For testing.'

describe 'crypto', ->

  it 'can encrypt and decrypt information', ->

    texts = []

    for i in [0...100]

      texts[i] = String.fromCharCode Math.floor Math.random() * 256
      texts[i] += texts[i - 1] if i > 0

    ciphertexts = []
    ciphertextsPromise = null

    runs ->

      ciphertexts = for text in texts

        crypto.encrypt text, cryptoKey

      ciphertextsPromise = Promise.all ciphertexts

    waitsFor -> ciphertextsPromise.isFulfilled()

    deciphertexts = []
    deciphertextsPromise = null

    runs ->

      ciphertexts = ciphertextsPromise.inspect().value()

      deciphertexts = for ciphertext in ciphertexts

        crypto.decrypt ciphertext, cryptoKey

      deciphertextsPromise = Promise.all deciphertexts

    waitsFor -> deciphertextsPromise.isFulfilled()

    runs ->

      deciphertexts = deciphertextsPromise.inspect().value()

      for text, i in texts

        expect(text).toBe deciphertexts[i]

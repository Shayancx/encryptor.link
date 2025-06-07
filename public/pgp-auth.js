const PgpAuth = {
  async generateKey(name, email, passphrase) {
    try {
      const { privateKey, publicKey, key } = await openpgp.generateKey({
        type: 'rsa',
        rsaBits: 2048,
        userIDs: [{ name, email }],
        passphrase
      });
      const fingerprint = key.getFingerprint().toUpperCase();
      localStorage.setItem(`pgp_private_${fingerprint}`, privateKey);
      return { publicKey, fingerprint };
    } catch (e) {
      console.error('Key generation error', e);
      throw new Error('Failed to generate key');
    }
  },

  async signNonce(fingerprint, nonce, passphrase) {
    const armoredPrivate = localStorage.getItem(`pgp_private_${fingerprint}`);
    if (!armoredPrivate) throw new Error('Private key not found');
    const privateKey = await openpgp.decryptKey({
      privateKey: await openpgp.readPrivateKey({ armoredKey: armoredPrivate }),
      passphrase
    });
    const signed = await openpgp.sign({
      message: await openpgp.createMessage({ text: nonce }),
      signingKeys: privateKey,
      detached: true,
      format: 'armored'
    });
    return signed;
  },

  validatePublicKey: async function(key) {
    try {
      await openpgp.readKey({ armoredKey: key });
      return true;
    } catch (e) {
      return false;
    }
  }
};

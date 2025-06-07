const PgpAuth = (() => {
  async function generateKey(name, email, passphrase) {
    const { privateKey, publicKey } = await openpgp.generateKey({
      type: 'rsa',
      rsaBits: 2048,
      userIDs: [{ name, email }],
      passphrase
    });
    const encrypted = await openpgp.encrypt({
      message: await openpgp.createMessage({ text: privateKey }),
      passwords: [passphrase],
      format: 'armored'
    });
    localStorage.setItem('pgp_private', encrypted);
    localStorage.setItem('pgp_public', publicKey);
    return publicKey;
  }

  async function signNonce(nonce, passphrase) {
    const encrypted = localStorage.getItem('pgp_private');
    if (!encrypted) throw new Error('No private key');
    const message = await openpgp.readMessage({ armoredMessage: encrypted });
    const { data: priv } = await openpgp.decrypt({ message, passwords: [passphrase] });
    const privateKey = await openpgp.readPrivateKey({ armoredKey: priv });
    const decrypted = await openpgp.decryptKey({ privateKey, passphrase });
    return await openpgp.sign({ message: await openpgp.createMessage({ text: nonce }), signingKeys: decrypted, format: 'armored' });
  }

  function storedPublicKey() {
    return localStorage.getItem('pgp_public');
  }

  return { generateKey, signNonce, storedPublicKey };
})();

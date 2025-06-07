async function signChallenge(privateKeyArmored, passphrase, nonce) {
  const { readPrivateKey, decryptKey, sign } = openpgp;
  const privateKey = await readPrivateKey({ armoredKey: privateKeyArmored });
  const decrypted = await decryptKey({ privateKey, passphrase });
  const signed = await sign({ message: await openpgp.createMessage({ text: nonce }), signingKeys: decrypted, detached: true });
  return signed;
}

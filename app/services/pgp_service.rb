require "gpgme"

class PgpService
  def self.valid_public_key?(ascii_key)
    crypto = GPGME::Crypto.new
    ctx = GPGME::Ctx.new
    import_result = ctx.import(ascii_key)
    import_result.imported > 0
  rescue GPGME::Error => e
    Rails.logger.error("PGP validation error: #{e.message}")
    false
  end

  def self.verify_signature(public_key, data, signature)
    GPGME::Crypto.new.verify(signature, signed_text: data, key: public_key) do |sig|
      return sig.valid?
    end
  rescue GPGME::Error => e
    Rails.logger.error("PGP signature verify error: #{e.message}")
    false
  end

  def self.fingerprint(ascii_key)
    ctx = GPGME::Ctx.new
    result = ctx.import(ascii_key)
    result.imports.first&.fpr
  rescue GPGME::Error => e
    Rails.logger.error("PGP fingerprint error: #{e.message}")
    nil
  end

  def self.encrypt(public_key, data)
    result = GPGME::Key.import(public_key)
    fpr = result.imports.first&.fpr
    return nil unless fpr
    key = GPGME::Key.find(:public, fpr).first
    crypto = GPGME::Crypto.new(armor: true)
    crypto.encrypt(data, recipients: key, always_trust: true).to_s
  rescue GPGME::Error => e
    Rails.logger.error("PGP encrypt error: #{e.message}")
    nil
  end
end

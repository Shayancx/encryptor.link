require 'gpgme'

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
end

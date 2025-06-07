class PgpRegistrationsController < ApplicationController
  def new
    @public_key = ""
  end

  def create
    @public_key = params[:pgp_public_key]
    unless PgpService.valid_public_key?(@public_key)
      flash[:alert] = "Invalid PGP key"
      render :new, status: :unprocessable_entity and return
    end
    code = SecureRandom.hex(4)
    encrypted = PgpService.encrypt(@public_key, code)
    unless encrypted
      flash[:alert] = "Failed to encrypt challenge"
      render :new, status: :unprocessable_entity and return
    end
    session[:pgp_registration] = {
      "public_key" => @public_key,
      "code_hash" => Digest::SHA256.hexdigest(code),
      "message" => encrypted
    }
    @encrypted_message = encrypted
    render :challenge
  end

  def verify
    data = session[:pgp_registration]
    unless data
      redirect_to register_path, alert: "Registration expired" and return
    end
    if Digest::SHA256.hexdigest(params[:code].to_s.strip) == data["code_hash"]
      account = Account.create!(pgp_public_key: data["public_key"])
      session.delete(:pgp_registration)
      rodauth.account_from_id(account.id)
      rodauth.login("pgp")
      redirect_to root_path
    else
      @encrypted_message = data["message"]
      flash.now[:alert] = "Invalid code"
      render :challenge, status: :unprocessable_entity
    end
  end
end

class PgpRegistrationsController < ApplicationController
  def new
    @public_key = ''
  end

  def create
    public_key = params[:pgp_public_key]
    unless PgpService.valid_public_key?(public_key)
      flash[:alert] = 'Invalid PGP key'
      render :new, status: :unprocessable_entity and return
    end
    account = Account.create!(pgp_public_key: public_key)
    rodauth.account_from_id(account.id)
    rodauth.login('pgp')
    redirect_to root_path
  end
end

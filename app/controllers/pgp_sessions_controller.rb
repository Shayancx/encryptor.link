class PgpSessionsController < ApplicationController
  def new
  end

  def create
    account = Account.find_by(pgp_fingerprint: params[:fingerprint])
    head :unauthorized and return unless account

    challenge = account.account_pgp_challenges.find_by(nonce: params[:nonce])
    head :unauthorized and return unless challenge && challenge.expires_at.future?

    if PgpService.verify_signature(account.pgp_public_key, challenge.nonce, params[:signature])
      challenge.destroy
      rodauth.account_from_id(account.id)
      rodauth.login('pgp')
      render json: { logged_in: true }
    else
      head :unauthorized
    end
  end
end

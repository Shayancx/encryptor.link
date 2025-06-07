class PgpChallengesController < ApplicationController
  private def current_account
    return rodauth.account if rodauth.logged_in?
    Account.find_by(pgp_fingerprint: params[:fingerprint])
  end

  def create
    account = current_account
    head :not_found and return unless account

    challenge = account.account_pgp_challenges.create!
    render json: { nonce: challenge.nonce }
  end

  def verify
    account = current_account
    head :not_found and return unless account
    challenge = account.account_pgp_challenges.find_by(nonce: params[:nonce])
    head :unauthorized and return unless challenge && challenge.expires_at.future?

    if PgpService.verify_signature(account.pgp_public_key, challenge.nonce, params[:signature])
      challenge.destroy
      render json: { verified: true }
    else
      render json: { verified: false }, status: :unauthorized
    end
  end
end

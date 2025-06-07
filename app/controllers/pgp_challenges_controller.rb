class PgpChallengesController < ApplicationController
  before_action -> { rodauth.require_account }

  private def current_account
    rodauth.account
  end

  def create
    challenge = current_account.account_pgp_challenges.create!
    render json: { nonce: challenge.nonce }
  end

  def verify
    challenge = current_account.account_pgp_challenges.find_by(nonce: params[:nonce])
    head :unauthorized and return unless challenge && challenge.expires_at.future?

    if PgpService.verify_signature(current_account.pgp_public_key, challenge.nonce, params[:signature])
      challenge.destroy
      render json: { verified: true }
    else
      render json: { verified: false }, status: :unauthorized
    end
  end
end

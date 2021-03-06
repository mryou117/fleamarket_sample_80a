class TransactionsController < ApplicationController
  before_action :set_item
  before_action :move_to_index

  def buy
    credit_card = CreditCard.where(user_id: current_user.id).first
    if credit_card.blank?
    else
      Payjp.api_key = ENV["PAYJP_PRIVATE_KEY"]
      customer = Payjp::Customer.retrieve(credit_card.customer_id)
      @default_credit_card_information = customer.cards.retrieve(credit_card.card_id)
    end
  end

  def done
    unless request.referer&.include?("/buy")
      redirect_to action: :buy
    else
      card = current_user.credit_card
      Payjp.api_key = ENV["PAYJP_PRIVATE_KEY"]
      Payjp::Charge.create(
      amount: @item.price, 
      customer: card.customer_id, 
      currency: 'jpy', 
      )
      if @item.update(buyer_id: current_user.id)
        flash[:notice] = '購入しました。'
      else
        flash[:alert] = '購入に失敗しました。'
        redirect_to controller: "transactions", action: 'buy'
      end
    end
  end



  private

  def set_item
    @item = Item.find(params[:id])
  end

  def move_to_index
    if @item.buyer_id.present?
      redirect_to root_path
    end
  end

end
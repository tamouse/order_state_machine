class PaymentMethod < ActiveRecord::Base
  belongs_to :order

  def declined!
    update_attributes(declined: true)
  end

  def accepted!
    update_attributes(declined: false)
  end

  def accepted?
    ! declined?
  end

end

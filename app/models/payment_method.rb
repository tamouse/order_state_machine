class PaymentMethod < ActiveRecord::Base
  belongs_to :order
end

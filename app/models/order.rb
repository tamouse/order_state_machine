class Order < ActiveRecord::Base
  has_one :payment_method
  has_many :shipments

  include AASM

  aasm whiny_transitions: false do
    state :pending, initial: true
    state :ready
    state :shipping
    state :settling
    state :settled

    # Failure States
    state :auth_failed
    state :payment_failed

    event :ready_order do
      transitions from: :pending, to: :ready do
        guard {self.valid?(:ready_to_order)}
      end
    end

    event :place_order do
      transitions from: :ready, to: :shipping do
        guard {submit_order}
        after {puts "notify user of order"}
      end
      transitions from: :ready, to: :auth_failed do
        after {puts "notify admin & user of authorization failure"}
      end
    end

    event :shipping_completed do
      transitions from: :shipping, to: :settling do
        guard {shipments.all_shipped?}
        after {puts "notify user of completed shipments"}
      end
    end

    event :settle_charges do
      transitions from: :settling, to: :settled do
        guard {settle_charge}
        after {puts "notify user of charges settled"}
      end
      transitions from: :shipping, to: :payment_failed do
        after {puts "notify admin of failed payment"}
      end
    end

    event :new_payment_method do
      transitions from: :auth_failed, to: :pending
      transitions from: :payment_failed, to: :settled
    end
  end

  validates_presence_of :payment_method, on: :ready_to_order
  validates_presence_of :shipments, on: :ready_to_order

  def submit_order
    false
  end

  def settle_charge
    false
  end
end

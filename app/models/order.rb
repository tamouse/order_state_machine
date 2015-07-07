class Order < ActiveRecord::Base
  has_one :payment_method
  has_many :shipments

  include AASM

  aasm whiny_transitions: false do
    state :pending, initial: true
    state :ready
    # we might want another state in here for authorized
    state :shipping
    state :settling
    state :settled

    # Failure States
    state :auth_failed
    state :settlement_failed

    event :ready_order do
      transitions from: :pending, to: :ready do
        guard {self.valid?(:ready_to_order)}
      end
    end

    event :place_order do
      transitions from: :ready, to: :shipping do
        # assumes the only failure here is the payment auth, which is
        # why we probably want an authorized state before
        # this. Otherwise, we may need to have additional
        # pseudo-states like `declined?` and `submitted?` on the
        # order.
        guard {submit_order}
        after { "notify user of order"}
      end
      transitions from: :ready, to: :auth_failed do
        after { "notify admin & user of authorization failure"}
      end
    end

    event :shipping_completed do
      transitions from: :shipping, to: :settling do
        guard {shipments.all_shipped?}
        after { "notify user of completed shipments"}
      end
    end

    event :settle_charges do
      transitions from: :settling, to: :settled do
        guard {settle_charge}
        after { "notify user of charges settled"}
      end
      transitions from: :settling, to: :settlement_failed do
        after { "notify admin of failed payment"}
      end
    end

    event :apply_new_payment_method do
      transitions from: :auth_failed, to: :ready
      transitions from: :settlement_failed, to: :settling
    end

    event :rerun_charge do
      transitions from: :settlement_failed, to: :settled do
        guard {charge_with_settlement}
        after { "notify user of charges settled"}
      end
      transitions from: :settlement_failed, to: :settlement_failed do
        after { "notify admin of failed payment"}
      end
    end
  end

  validates_presence_of :payment_method, on: :ready_to_order
  validates_presence_of :shipments, on: :ready_to_order

  def submit_order
    # return value determined in tests
  end

  def settle_charge
    # return value determined in tests
  end

  def charge_with_settlement
    # return value determine in tests
  end
end

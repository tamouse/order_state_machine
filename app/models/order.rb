class Order < ActiveRecord::Base
  has_one :payment_method
  has_one :shipping_address
  has_many :shipments

  include AASM

  aasm whiny_transitions: false do
    state :pending, initial: true
    state :has_shipping_address
    state :has_shipments
    state :has_shipping_options
    state :has_payment_method
    state :payment_method_validated
    state :ready_to_order
    state :payment_authorized
    state :ordered
    state :shipped
    state :payment_settled

    # Failure States
    state :shipment_quote_failed
    state :payment_declined
    state :authorization_failed
    state :order_failed
    state :settlement_failed

    event :advance do
      transitions from: :pending,                  to: :has_shipping_address do
        guard {shipping_address.present?}
      end
      transitions from: :has_shipping_address,     to: :has_shipments do
        guard {self.build_shipments}
      end
      transitions from: :has_shipping_address,     to: :shipment_quote_failed
      transitions from: :has_shipments,            to: :has_shipping_options do
        guard {self.set_shipping_options}
      end
      transitions from: :has_shipping_options,     to: :has_payment_method do
        guard {self.payment_method.present?}
      end
      transitions from: :has_payment_method,       to: :ready_to_order do
        guard {self.valid?(:ready_to_order)}
      end
      transitions from: :ready_to_order,           to: :payment_authorized do
        guard {self.authorize_charge}
      end
      transitions from: :ready_to_order,           to: :authorization_failed
      transitions from: :payment_authorized,       to: :ordered do
        guard {self.submit_order}
      end
      transitions from: :payment_authorized,       to: :order_failed
      transitions from: :ordered,                  to: :shipped do
        guard {self.all_shipped?}
      end
      transitions from: :shipped,                  to: :payment_settled do
        guard {self.settle_charge}
      end
      transitions from: :shipped,                  to: :settlement_failed
    end

    event :edit_shipping_address do
      transitions from: [:pending, :has_shipping_address, :has_shipments, :has_shipping_options, :has_payment_method, :ready_to_order], to: :pending do
        after {self.invalidate_shipping}
      end

    end

    event :edit_shipping_options do
      transitions from: [:ready_to_order, :has_payment_method, :has_shipping_options, :has_shipments], to: :has_shipments
    end

    event :edit_payment_method do
      transitions from: [:authorization_failed, :ready_to_order, :has_payment_method, :payment_declined], to: :has_payment_method
      transitions from: :settlement_failed, to: :payment_settled do
        guard {self.recharge(order_total)}
      end
    end
  end

  validates_presence_of :shipping_address, :shipments, :payment_method, on: :ready_to_order
  validate :valid_payment_method, on: :ready_to_order

  def all_shipped?
    shipments.all_shipped?
  end

  def authorize_charge
    # return value determined in tests
  end

  def build_shipments
    # return value determined in tests
  end

  def recharge
    # return value determine in tests
  end

  def set_shipping_options
    # return value determined in tests
  end

  def settle_charge
    # return value determined in tests
  end

  def submit_order
    # return value determined in tests
  end

  def valid_payment_method
    if payment_method.blank?
      errors.add(:payment_method, 'missing')
    elsif payment_method.declined?
      errors.add(:payment_method, 'declined')
    end
  end

end

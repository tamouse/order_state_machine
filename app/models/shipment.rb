class Shipment < ActiveRecord::Base
  belongs_to :order

  def self.all_shipped?
    self.all.all? {|s| s.shipped? }
  end

  def mark_shipped
    update_attributes(shipped_at: Time.now, shipped: true)
  end
end

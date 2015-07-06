require 'rails_helper'

RSpec.describe Order, type: :model do
  describe "state machine" do
    let(:order) {Order.create}
    describe "ready order" do
      context "when order is not ready to order" do
        it "will fail to transition to :ready state" do
          order.ready_order
          expect(order.ready?).to be false
          expect(order.pending?).to be true
        end
      end
      context "when order is ready to order" do
        it "will transition to :ready state" do
          order.create_payment_method
          order.shipments.create
          order.ready_order
          expect(order.ready?).to be true
          expect(order.pending?).to be false
        end
      end
    end

    describe "place order" do
      let(:order) do
        o=Order.create
        o.create_payment_method
        o.shipments.create
        o
      end

      context "when placing order fails" do
        it "will fail to transition to :shipping state" do
          expect(order).to receive(:submit_order).and_return(false)
          order.place_order
          expect(order).to be_auth_failed, "Order state: #{order.aasm_state}"
          expect(order).not_to be_shipping, "Order state: #{order.aasm_state}"
        end
      end

      context "when placing order succeeds" do
        it "will transitions to :shipping state" do
          expect(order).to receive(:submit_order).and_return(true)
          order.place_order
          expect(order).not_to be_auth_failed, "Order state: #{order.aasm_state}"
          expect(order).to be_shipping, "Order state: #{order.aasm_state}"
        end
      end
    end
  end
end

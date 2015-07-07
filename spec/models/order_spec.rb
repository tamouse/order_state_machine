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
        o.ready_order
        o
      end

      context "when placing order fails" do
        it "will fail to transition to :shipping state" do
          expect(order).to be_ready
          expect(order).to receive(:submit_order).and_return(false)
          order.place_order
          expect(order).to be_auth_failed, "Order state: #{order.aasm_state}"
          expect(order).not_to be_shipping, "Order state: #{order.aasm_state}"
        end
      end

      context "when placing order succeeds" do
        it "will transitions to :shipping state" do
          expect(order).to be_ready
          expect(order).to receive(:submit_order).and_return(true)
          order.place_order
          expect(order).not_to be_auth_failed, "Order state: #{order.aasm_state}"
          expect(order).to be_shipping, "Order state: #{order.aasm_state}"
        end
      end
    end

    describe "shipping completed" do

      let(:order) do
        o=Order.create
        o.create_payment_method
        o.shipments.create
        o.shipments.create
        o.ready_order
        o
      end

      before do
        expect(order).to receive(:submit_order).and_return(true)
        order.place_order
      end

      context "when no shipments shipped of 2" do
        it "will fail to transition to :settling state" do
          order.shipping_completed
          expect(order).to be_shipping, "Order state: #{order.aasm.current_state}"
          expect(order).not_to be_settling, "Order state: #{order.aasm.current_state}"
        end
      end

      context "when one shipments shipped of 2" do
        it "will fail to transition to :settling state" do
          order.shipments.first.mark_shipped
          order.shipping_completed
          expect(order).to be_shipping, "Order state: #{order.aasm.current_state}"
          expect(order).not_to be_settling, "Order state: #{order.aasm.current_state}"
        end
      end

      context "when 2 shipments shipped of 2" do
        it "will transition to :settling state" do
          order.shipments.first.mark_shipped
          order.shipments.last.mark_shipped
          order.shipping_completed
          expect(order).not_to be_shipping, "Order state: #{order.aasm.current_state}"
          expect(order).to be_settling, "Order state: #{order.aasm.current_state}"
        end
      end
    end

    describe "settle charges" do
      let(:order) do
        o=Order.create
        o.create_payment_method
        o.shipments.create
        o.ready_order
        o
      end

      before do
        expect(order).to receive(:submit_order).and_return(true)
        order.place_order
        order.shipments.first.mark_shipped
        order.shipping_completed
      end

      context "when charge settlement fails" do
        it "will fail to transition to :settled state" do
          expect(order).to receive(:settle_charge).and_return(false)
          order.settle_charges
          expect(order).to be_settlement_failed, "Order state: #{order.aasm.current_state}"
          expect(order).not_to be_settled, "Order state: #{order.aasm.current_state}"
        end
      end

      context "when charge settlement fails" do
        it "will transition to :settled state" do
          expect(order).to receive(:settle_charge).and_return(true)
          order.settle_charges
          expect(order).not_to be_settlement_failed, "Order state: #{order.aasm.current_state}"
          expect(order).to be_settled, "Order state: #{order.aasm.current_state}"
        end
      end
    end

    describe "apply new payment method to auth_failed" do
      let(:order) do
        o=Order.create
        o.create_payment_method
        o.shipments.create
        o.ready_order
        o
      end

      before do
        expect(order).to receive(:submit_order).and_return(false)
        order.place_order
      end

      it "will transition from auth_failed to ready" do
        expect(order).to be_auth_failed
        order.apply_new_payment_method
        expect(order).to be_ready, "Order state: #{order.aasm.current_state}"
        expect(order).not_to be_auth_failed, "Order state: #{order.aasm.current_state}"
      end
    end

    describe "apply new payment method to settlement_failed" do
      let(:order) do
        o=Order.create
        o.create_payment_method
        o.shipments.create
        o.ready_order
        o
      end

      before do
        expect(order).to receive(:submit_order).and_return(true)
        expect(order).to receive(:settle_charge).and_return(false)
        order.place_order
        order.shipments.first.mark_shipped
        order.shipping_completed
        order.settle_charges
      end

      it "will transition from settlement_failed to settling" do
        expect(order).to be_settlement_failed, "Order state: #{order.aasm.current_state}"
        order.apply_new_payment_method
        expect(order).to be_settling, "Order state: #{order.aasm.current_state}"
        expect(order).not_to be_settlement_failed, "Order state: #{order.aasm.current_state}"
      end
    end

    describe "re-run charge on :settlement_failed" do
      let(:order) do
        o=Order.create
        o.create_payment_method
        o.shipments.create
        o.ready_order
        o
      end

      before do
        expect(order).to receive(:submit_order).and_return(true)
        expect(order).to receive(:settle_charge).and_return(false)
        order.place_order
        order.shipments.first.mark_shipped
        order.shipping_completed
        order.settle_charges
      end

      context "when rerunning charge fails" do
        it "will fail to transition to :settled" do
          expect(order).to be_settlement_failed, "Order state: #{order.aasm.current_state}"
          expect(order).to receive(:charge_with_settlement).and_return(false)
          order.rerun_charge
          expect(order).not_to be_settled, "Order state: #{order.aasm.current_state}"
          expect(order).to be_settlement_failed, "Order state: #{order.aasm.current_state}"
        end
      end

      context "when rerunning charge succeeds" do
        it "will transition to :settled" do
          expect(order).to be_settlement_failed, "Order state: #{order.aasm.current_state}"
          expect(order).to receive(:charge_with_settlement).and_return(true)
          order.rerun_charge
          expect(order).to be_settled, "Order state: #{order.aasm.current_state}"
          expect(order).not_to be_settlement_failed, "Order state: #{order.aasm.current_state}"
        end
      end
    end
  end
end

require 'rails_helper'

RSpec.describe Order, type: :model do
  describe "state machine" do
    describe "advance pending" do
      let(:order) {Order.create}
      context "when shipping address is NOT present" do
        it "will not advance to has_shipping_address" do
          expect(order).to be_pending, "Order state: #{order.aasm.current_state}"
          order.advance
          expect(order).to be_pending, "Order state: #{order.aasm.current_state}"
        end
      end
      context "when shipping address present" do
        it "will advance to has_shipping_address" do
          order.create_shipping_address(zip: "55401")
          expect(order).to be_pending, "Order state: #{order.aasm.current_state}"
          order.advance
          expect(order).to be_has_shipping_address, "Order state: #{order.aasm.current_state}"
        end
      end
    end
    describe "advance has_shipping_address" do
      let(:order) do
        o = Order.create
        o.create_shipping_address(zip: "55401")
        o.advance
        o
      end

      context "when build_shipments does NOT work" do
        it "will not advance to has_shipments" do
          expect(order).to receive(:build_shipments).and_return(false)
          order.shipments.destroy_all
          expect(order).to be_has_shipping_address, "Order state: #{order.aasm.current_state}"
          order.advance
          expect(order).to be_shipment_quote_failed, "Order state: #{order.aasm.current_state}"
        end
      end
      context "when build_shipments works" do
        it "will advance to has_shipments" do
          expect(order).to receive(:build_shipments).and_return(true)
          order.shipments.create
          expect(order).to be_has_shipping_address, "Order state: #{order.aasm.current_state}"
          order.advance
          expect(order).to be_has_shipments, "Order state: #{order.aasm.current_state}"
        end
      end
    end
    describe "advance has_shipments" do
      let(:order) do
        o = Order.create
        o.create_shipping_address(zip: "55401")
        o.advance               # to has_shipping_address
        o
      end

      before do
        allow(order).to receive(:build_shipments).and_return(true)
        order.shipments.create
        order.advance               # to has_shipments
      end

      context "when shipping options are NOT set" do
        it "will not advance to has_shipping_options" do
          expect(order).to receive(:set_shipping_options).and_return(false)
          expect(order).to be_has_shipments, "Order state: #{order.aasm.current_state}"
          order.advance
          expect(order).to be_has_shipments, "Order state: #{order.aasm.current_state}"
        end
      end
      context "when shipping options ARE set" do
        it "will advance to has_shipping_options" do
          expect(order).to receive(:set_shipping_options).and_return(true)
          expect(order).to be_has_shipments, "Order state: #{order.aasm.current_state}"
          order.advance
          expect(order).to be_has_shipping_options, "Order state: #{order.aasm.current_state}"
        end
      end
    end
    describe "advance has_shipping_options" do
      let(:order) do
        o = Order.create
        o.create_shipping_address(zip: "55401")
        o.advance               # to has_shipping_address
        o
      end

      before do
        allow(order).to receive(:build_shipments).and_return(true)
        order.shipments.create
        order.advance            # to has_shipments
        allow(order).to receive(:set_shipping_options).and_return(true)
        order.advance            # to has_shipping_options
      end

      context "when there is no payment method" do
        it "will not advance to has_payment_method" do
          # expect(order).to receive(:payment_method).and_return(nil)
          expect(order).to be_has_shipping_options, "Order state: #{order.aasm.current_state}"
          order.advance
          expect(order).to be_has_shipping_options, "Order state: #{order.aasm.current_state}"
        end
      end
      context "when there IS a payment method" do
        it "will not advance to has_payment_method" do
          order.create_payment_method
          expect(order).to be_has_shipping_options, "Order state: #{order.aasm.current_state}"
          order.advance
          expect(order).to be_has_payment_method, "Order state: #{order.aasm.current_state}"
        end
      end
    end
    describe "advance has_payment_method" do
      let(:order) do
        o = Order.create
        o.create_shipping_address(zip: "55401")
        o.advance               # to has_shipping_address
        o
      end

      before do
        allow(order).to receive(:build_shipments).and_return(true)
        order.shipments.create
        order.advance           # to has_shipments
        allow(order).to receive(:set_shipping_options).and_return(true)
        order.advance           # to has_shipping_options
        order.create_payment_method
        order.advance           # to has_payment_method
      end

      context "when order is NOT ready to be placed" do
        it "will NOT advance to ready_to_order" do
          order.payment_method.declined!
          expect(order).to be_has_payment_method, "Order state: #{order.aasm.current_state}"
          order.advance
          expect(order).to be_has_payment_method, "Order state: #{order.aasm.current_state}"
        end
      end
      context "when order ID ready to be placed" do
        it "will NOT advance to ready_to_order" do
          order.payment_method.accepted!
          expect(order).to be_has_payment_method, "Order state: #{order.aasm.current_state}"
          order.advance
          expect(order).to be_ready_to_order, "Order state: #{order.aasm.current_state}, errors: #{order.errors.messages.inspect}"
        end
      end
    end
    describe "advance ready_to_order" do
      let(:order) do
        o = Order.create
        o.create_shipping_address(zip: "55401")
        o.advance               # to has_shipping_address
        o
      end

      before do
        allow(order).to receive(:build_shipments).and_return(true)
        order.shipments.create
        order.advance           # to has_shipments
        allow(order).to receive(:set_shipping_options).and_return(true)
        order.advance           # to has_shipping_options
        order.create_payment_method
        order.advance           # to has_payment_method
        order.payment_method.accepted!
        order.advance           # to ready_to_order
      end

      context "when payment authorization FAILS" do
        it "will advance to :authorization_failed" do
          expect(order).to receive(:authorize_charge).and_return(false)
          expect(order).to be_ready_to_order, "Order state: #{order.aasm.current_state}"
          order.advance
          expect(order).to be_authorization_failed, "Order state: #{order.aasm.current_state}"
        end
      end
      context "when payment authorization SUCCEEDS" do
        it "will advance to payment_authorized" do
          expect(order).to receive(:authorize_charge).and_return(true)
          expect(order).to be_ready_to_order, "Order state: #{order.aasm.current_state}"
          order.advance
          expect(order).to be_payment_authorized, "Order state: #{order.aasm.current_state}"
        end
      end
    end
    describe "advance payment_authorized" do
      let(:order) do
        o = Order.create
        o.create_shipping_address(zip: "55401")
        o.advance               # to has_shipping_address
        o
      end

      before do
        allow(order).to receive(:build_shipments).and_return(true)
        order.shipments.create
        order.advance           # to has_shipments
        allow(order).to receive(:set_shipping_options).and_return(true)
        order.advance           # to has_shipping_options
        order.create_payment_method
        order.advance           # to has_payment_method
        order.payment_method.accepted!
        order.advance           # to ready_to_order
        allow(order).to receive(:authorize_charge).and_return(true)
        order.advance           # to payment_authorized
      end

      context "when submitting order FAILS" do
        it "will advance to :order_failed" do
          expect(order).to receive(:submit_order).and_return(false)
          expect(order).to be_payment_authorized, "Order state: #{order.aasm.current_state}"
          order.advance
          expect(order).to be_order_failed, "Order state: #{order.aasm.current_state}"
        end
      end
      context "when submitting order SUCCEEDS" do
        it "will advance to :ordered" do
          expect(order).to receive(:submit_order).and_return(true)
          expect(order).to be_payment_authorized, "Order state: #{order.aasm.current_state}"
          order.advance
          expect(order).to be_ordered, "Order state: #{order.aasm.current_state}"
        end
      end
    end
    describe "advance ordered" do
      let(:order) do
        o = Order.create
        o.create_shipping_address(zip: "55401")
        o.advance               # to has_shipping_address
        o
      end

      before do
        allow(order).to receive(:build_shipments).and_return(true)
        order.shipments.create
        order.advance           # to has_shipments
        allow(order).to receive(:set_shipping_options).and_return(true)
        order.advance           # to has_shipping_options
        order.create_payment_method
        order.advance           # to has_payment_method
        order.payment_method.accepted!
        order.advance           # to ready_to_order
        allow(order).to receive(:authorize_charge).and_return(true)
        order.advance           # to payment_authorized
        allow(order).to receive(:submit_order).and_return(true)
        order.advance           # to ordered
      end

      context "when some shipments are NOT shipped yet" do
        it "will NOT advance to :shipped" do
          expect(order).to receive(:all_shipped?).and_return(false)
          expect(order).to be_ordered, "Order state: #{order.aasm.current_state}"
          order.advance
          expect(order).to be_ordered, "Order state: #{order.aasm.current_state}"
        end
      end
      context "when all shipments are shipped" do
        it "will advance to :shipped" do
          expect(order).to receive(:all_shipped?).and_return(true)
          expect(order).to be_ordered, "Order state: #{order.aasm.current_state}"
          order.advance
          expect(order).to be_shipped, "Order state: #{order.aasm.current_state}"
        end
      end
    end
    describe "advance shipped" do
      let(:order) do
        o = Order.create
        o.create_shipping_address(zip: "55401")
        o.advance               # to has_shipping_address
        o
      end

      before do
        allow(order).to receive(:build_shipments).and_return(true)
        order.shipments.create
        order.advance           # to has_shipments
        allow(order).to receive(:set_shipping_options).and_return(true)
        order.advance           # to has_shipping_options
        order.create_payment_method
        order.advance           # to has_payment_method
        order.payment_method.accepted!
        order.advance           # to ready_to_order
        allow(order).to receive(:authorize_charge).and_return(true)
        order.advance           # to payment_authorized
        allow(order).to receive(:submit_order).and_return(true)
        order.advance           # to ordered
        allow(order).to receive(:all_shipped?).and_return(true)
        order.advance           # to shipped
      end

      context "when settlement FAILS" do
        it "will advance to :settlement_failed" do
          expect(order).to receive(:settle_charge).and_return(false)
          expect(order).to be_shipped, "Order state: #{order.aasm.current_state}"
          order.advance
          expect(order).to be_settlement_failed, "Order state: #{order.aasm.current_state}"
        end
      end
      context "when settlement SUCCEEDS" do
        it "will advance to :payment_settled" do
          expect(order).to receive(:settle_charge).and_return(true)
          expect(order).to be_shipped, "Order state: #{order.aasm.current_state}"
          order.advance
          expect(order).to be_payment_settled, "Order state: #{order.aasm.current_state}"
        end
      end
    end
    describe "edit_shipping_address" do
      context "when valid state" do

      end
      context "when invalid state" do

      end
    end
    describe "edit_shipping_options" do
      context "when valid state" do

      end
      context "when invalid state" do

      end
    end
    describe "edit_payment_method" do
      context "before order placed" do

      end
      context "after order placed" do

      end
    end
  end
end

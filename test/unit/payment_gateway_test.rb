require 'test_helper'

class PaymentGatewayTest < ActiveSupport::TestCase
  context "Order when completed with existing payment" do
    setup do
      @order = create_complete_order
      @order.checkout.update_attribute("state", "complete")

      #only want one line item for ease of testing
      @order.line_items.destroy_all
      Factory(:line_item, :order => @order, :variant => Factory(:variant), :quantity => 2, :price => 100.00)
      @order.reload
      @order.save

      @checkout.payment.update_attributes(:payable => @order, :amount => @order.total)

      #make sure totals get recalculated
      @order.reload
      @order.save

      @order.complete!
      @order.update_totals!
      @order.pay!
    end

    context "and an additional credit is added" do
      setup do
        @credit = Factory(:credit, :amount => 2.00, :order => @order)
        @order.update_totals!
        @order.reload
      end

      # should_change("@order.state", :from => "paid", :to => "credit_owed") { @order.state }

      context "and an existing payment source is credited" do
        setup do
          @checkout.payment.txns.create(:txn_type => CreditcardTxn::TxnType::AUTHORIZE, :response_code => "123")
          @checkout.payment.source.credit(@checkout.payment)
          @order.reload
        end
        should_change("@order.state", :from => "credit_owed", :to => "paid") { @order.state }
      end

    end

  end

end
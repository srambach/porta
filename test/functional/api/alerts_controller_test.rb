require 'test_helper'

class Api::AlertsControllerTest < ActionController::TestCase

  test "get index should filter by account_id, cinstance_id and fulltext" do
    provider = Factory(:provider_account)


    login_provider provider


    buyer1 = Factory(:simple_buyer, :provider_account => provider)
    buyer2 = Factory(:simple_buyer, :provider_account => provider)

    plan = Factory(:simple_application_plan, :issuer => provider.default_service)

    cinstance1 = Factory(:simple_cinstance, :plan => plan, :user_account => buyer1)
    cinstance2 = Factory(:simple_cinstance, :plan => plan, :user_account => buyer2)


    Factory(:limit_alert, account: provider, cinstance: cinstance1)
    Factory(:limit_alert, account: provider, cinstance: cinstance2)

    get :index
    assert_equal 2, assigns(:alerts).count

    get :index, account_id: buyer1.id

    alerts = assigns(:alerts)

    assert_equal 1, alerts.count
    assert_equal buyer1, alerts.first.cinstance.buyer_account


    get :index, cinstance_id: cinstance2.id
    alerts = assigns(:alerts)
    assert_equal 1, alerts.count
    assert_equal cinstance2, alerts.first.cinstance

    Account.expects(:search_ids).with(buyer1.name).returns([buyer1.id])

    get :index, search: {account: { query: buyer1.name} }
    alerts = assigns(:alerts)

    assert_equal 1, alerts.count
    assert_equal buyer1, alerts.first.cinstance.buyer_account
  end
end

require "test_helper"

class HomeControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get root_url
    assert_response :success
  end

  test "displays app name" do
    get root_url
    assert_match "Health Wallet", response.body
  end

  test "shows bottom navigation to patients and imports" do
    get root_url

    assert_select ".global-footer-nav a[href=?]", patients_path, text: "Patients"
    assert_select ".global-footer-nav a[href=?]", laboratory_imports_path, text: "Imports"
  end
end

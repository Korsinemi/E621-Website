# frozen_string_literal: true

require "test_helper"

class UserNameChangeRequestsControllerTest < ActionDispatch::IntegrationTest
  context "The user name change requests controller" do
    setup do
      @user = create(:privileged_user)
      @admin = create(:admin_user)
    end

    context "new action" do
      should "render" do
        get_auth new_user_name_change_request_path, @user
        assert_response :success
      end

      should "render for a user with a currently invalid username" do
        @user.update_columns(name: "12345")
        get_auth new_user_name_change_request_path, @user
        assert_response :success
      end
    end

    context "create action" do
      should "work" do
        post_auth user_name_change_requests_path, @user, params: { user_name_change_request: { desired_name: "zun" } }
        change_request = UserNameChangeRequest.last
        assert_redirected_to user_name_change_request_path(change_request)
        assert_equal("zun", @user.reload.name)
      end

      should "work for a user with a currently invalid name" do
        @user.update_columns(name: "12345")
        post_auth user_name_change_requests_path, @user, params: { user_name_change_request: { desired_name: "zun" } }
        change_request = UserNameChangeRequest.last
        assert_redirected_to user_name_change_request_path(change_request)
        assert_equal("zun", @user.reload.name)
      end
    end

    context "show action" do
      setup do
        as(@user) do
          @change_request = UserNameChangeRequest.create!(
            user_id: @user.id,
            original_name: @user.name,
            desired_name: "abc",
            change_reason: "hello",
          )
        end
      end

      should "render" do
        get_auth user_name_change_request_path(@change_request), @user
        assert_response :success
      end

      context "when the current user is not an admin and does not own the request" do
        should "fail" do
          @another_user = create(:user)
          get_auth user_name_change_request_path(@change_request), @another_user
          assert_response :forbidden
        end
      end
    end

    context "for actions restricted to admins" do
      context "index action" do
        should "render" do
          get_auth user_name_change_requests_path, @admin
          assert_response :success
        end
      end
    end
  end
end

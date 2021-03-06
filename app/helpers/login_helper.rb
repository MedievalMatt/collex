##########################################################################
# Copyright 2007 Applied Research in Patacriticism and the University of Virginia
# 
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
##########################################################################

module LoginHelper
#  def my_account_link(params)
#    cls = params[:class] || ''
#    text = params[:text] || "my account"
#     link_to_function text, "var dlg = new SignInDlg(); dlg.show('my_account', '#{session[:user][:username]}', '#{session[:user][:email]}');", :class => cls
#  end
  
  def sign_in_link(params)
    cls = params[:class] || ''
    text = params[:text] || "LOG IN"
    link_to_function text, "var dlg = new SignInDlg(); dlg.show('sign_in');", :class => cls
  end
  
  def sign_up_link(params)
    cls = params[:class] || ''
    text = params[:text] || "Create new account"
    link_to_function text, "var dlg = new SignInDlg(); dlg.show('create_account');", :class => cls
  end
end

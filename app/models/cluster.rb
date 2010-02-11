##########################################################################
# Copyright 2009 Applied Research in Patacriticism and the University of Virginia
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

class Cluster < ActiveRecord::Base
	has_many :exhibits
	has_many :discussion_threads
	belongs_to :group
  belongs_to :image#, :dependent=>:destroy

	def get_visibility()
		return self.visibility
	end

	def get_friendly_visibility_string()
		list = get_friendly_visibility_list()
		vis = get_visibility()
		list.each { |item|
			return item[:text] if item[:value] == vis
		}
		return ""	# this should never happen
	end

	def get_friendly_visibility_list()
		return [ { :value => 'everyone', :text =>	'Everyone' }, { :value => 'administrators', :text =>	'Administrators only' }]
	end
end

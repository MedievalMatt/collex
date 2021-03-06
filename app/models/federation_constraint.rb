# ------------------------------------------------------------------------
#     Copyright 2009 Applied Research in Patacriticism and the University of Virginia
# 
#     Licensed under the Apache License, Version 2.0 (the "License");
#     you may not use this file except in compliance with the License.
#     You may obtain a copy of the License at
# 
#         http://www.apache.org/licenses/LICENSE-2.0
# 
#     Unless required by applicable law or agreed to in writing, software
#     distributed under the License is distributed on an "AS IS" BASIS,
#     WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#     See the License for the specific language governing permissions and
#     limitations under the License.
# ----------------------------------------------------------------------------

class FederationConstraint < Constraint
	def to_solr_expression
		"federation:#{value}"
	end

	# used for creating fragment cache keys
#	def to_s
#		identifier = "#{field}_#{value}".downcase.gsub(/\W/,'_')
#		"#{operator}#{identifier}"
#	end
end

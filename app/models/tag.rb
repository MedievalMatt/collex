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

class Tag < ActiveRecord::Base
  #has_many :taggings, :dependent => :destroy
  #has_many :interpretations, :through => :taggings
  #has_and_belongs_to_many :cached_documents
  has_many :tagassigns 
  has_many :collected_items, :through => :tagassigns 

  validates_uniqueness_of :name

end

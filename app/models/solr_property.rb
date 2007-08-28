class SolrProperty < SolrBaseModel
  belongs_to :solr_resource
  
  column :name,  :string
  column :value, :string
    
  def ==(other)
    return false if other.nil?
    self.name == other.name and self.value == other.value
  end
  
end

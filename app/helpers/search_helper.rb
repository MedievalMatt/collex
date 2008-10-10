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

module SearchHelper
  private
  def get_collected_item(hit)
    return nil if session[:user] == nil
    user = User.find_by_username(session[:user][:username])
    item = CollectedItem.get(user, hit['uri'])
    return item
  end
  
  public
  
  def draw_pagination(curr_page, num_pages, destination_hash)
    html = ""

    # If there's only one page, don't show any pagination
    if num_pages == 1
      return ""
    end
    
    # Show only a maximum of 11 items, with the current item centered if possible.
    # First figure out the start and end points we want to display.
    if num_pages < 11
      first = 1
      last = num_pages
    else
      first = curr_page - 5
      last = curr_page + 5
      if first < 1
        first = 1
        last = first + 10
      end
      if last > num_pages
        last = num_pages
        first = last - 10
      end
    end
    
    if first > 1
      destination_hash[:page] = 1
      html += link_to("first", destination_hash) + "&nbsp;&nbsp;"
    end

    if curr_page > 1
      destination_hash[:page] = (curr_page - 1)
      html += link_to("<<", destination_hash) + "&nbsp;&nbsp;"
    end

    for pg in first..last do
      if pg == curr_page
        html += "<span class='paginate-current'>#{pg}</span>"
      else
        destination_hash[:page] = pg
        html += link_to("#{pg}", destination_hash )
      end
      html += "&nbsp;&nbsp;"
    end 
    
    if curr_page < num_pages
      destination_hash[:page] = (curr_page + 1)
      html += link_to( ">>", destination_hash) + "&nbsp;&nbsp;"
    end
    
    if last < num_pages
      destination_hash[:page] = num_pages
      html += link_to("last", destination_hash) + "&nbsp;&nbsp;"
    end

    return html
  end

  def genre_data_link( genre_data )
    if genre_data[:exists]
      html = "&rarr; #{h genre_data[:value]} (#{number_with_delimiter(genre_data[:count])})&nbsp;"
      html += link_to "[remove]", { :controller => 'search', :action => "remove_genre", :value => genre_data[:value] }, { :method => :post } 
      return html
    else
      link_to "#{h genre_data[:value]} (#{number_with_delimiter(genre_data[:count])})", {:controller=>"search", :action => 'add_facet', :field => 'genre', :value => genre_data[:value]}, { :method => :post } 
    end

  end
  
  def site_category_subtotal(facet_category)    
    count = 0
    facet_category.sorted_children.each { |child| 
      if child.children.size > 0 
        count = count + site_category_subtotal(child)
      else
        count = count + site_object_count(child.value)
      end    
    }    
    count
  end
    
  def mark_as_checked_freeculture()
    session[:selected_freeculture] ? 'checked="checked"' : ''  
  end
  
  def mark_as_checked_resource( facet )
    session[:selected_resource_facets].include?(facet) ? 'checked="checked"' : ''
  end
  
  def gray_if_zero( count )
    count==0 ? 'class="grayed-out-resource"' : ''
  end
    
  def site_object_count(code)
    @results['facets']['archive'][code].to_i
  end
  
  def site_category_heading( category_name, category_id, initial_state = :closed )
    display_none = 'style="display:none"'
    label = "<span id=\"cat_#{category_id}_closed\" #{initial_state == :open ? display_none : ''} class=\"site-category-toggle\">"
    label << link_to_function('&#x25BA;',"toggleCategory('#{category_id}')")
    label << "</span>"
    label << "<span id=\"cat_#{category_id}_opened\" #{initial_state == :closed ? display_none : ''} class=\"site-category-toggle\">"
    label << link_to_function('&#x25BC;', "toggleCategory('#{category_id}')")
    label << "</span>"
    label << category_name
  end
  
  def result_is_collected(hit)
    return get_collected_item(hit) != nil
  end
  
  def add_tag_if_present(hit)
    item = get_collected_item(hit)
    return "" if item == nil

    str = ""
    tags = item.tags
    if tags != nil
      str = "<ul style='list-style-type: none;'><li>Collected On: #{item.updated_at}</li>\n"
      tags.each {|t|
        str += "<li>x&nbsp;#{tags.name}</li>\n"
      }
      str += "<a href='#'>Add a tag</a>\n"
      str += "</ul>\n"
    end
    return str
  end

  def has_annotation(hit)
    item = get_collected_item(hit)
    return false if item == nil
    
    return  item.annotation != nil && item.annotation != ""
  end
  
  def get_annotation(hit)
    item = get_collected_item(hit)
    return "" if item == nil
    return "" if item.annotation == nil
    note = h(item.annotation)
    note = note.gsub("\n", "<br />")
    return note
  end

  def get_result_date(hit)
    
  end
  
  def get_result_annotation(hit)
    
  end
  
  def result_has_annotation(hit)
    
  end
  
  def get_result_tags(hit)
    
  end
  
  def get_saved_searches
    user = User.find_by_username(session[:user][:username])
    return user.searches.find(:all)
  end
  
  def create_saved_search_link(s)
    link_to s.name, {:controller=>"search", :action => 'apply_saved_search', :username => session[:user][:username], :name => s.name}
  end

  def create_remove_saved_search_link(s)
    link_to "[remove]", {:controller=>"search", :action => 'remove_saved_search', :username => session[:user][:username], :id => s.id}
  end
  
  def has_constraints?
    return session[:constraints].length != 0
  end
end

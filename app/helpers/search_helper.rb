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
      html += link_to("first", destination_hash, :class => 'nav_link') + "&nbsp;&nbsp;"
    end

    if curr_page > 1
      destination_hash[:page] = (curr_page - 1)
      html += link_to("<<", destination_hash, :class => 'nav_link') + "&nbsp;&nbsp;"
    end

    for pg in first..last do
      if pg == curr_page
        html += "<span class='current_serp'>#{pg}</span>"
      else
        destination_hash[:page] = pg
        html += link_to("#{pg}", destination_hash, :class => 'nav_link' )
      end
      html += "&nbsp;&nbsp;"
    end 
    
    if curr_page < num_pages
      destination_hash[:page] = (curr_page + 1)
      html += link_to( ">>", destination_hash, :class => 'nav_link') + "&nbsp;&nbsp;"
    end
    
    if last < num_pages
      destination_hash[:page] = num_pages
      html += link_to("last", destination_hash, :class => 'nav_link') + "&nbsp;&nbsp;"
    end

    return html
  end

  def resource_is_in_constraints?(resource)
    constraints = session[:constraints]
    constraints.each {|constraint|
      if constraint[:field] == 'archive' && constraint[:type] == 'FacetConstraint' && constraint[:value] == resource.value
        return true
      end
    }
    return false
  end
  
  def site_is_in_constraints?(site_value)
    constraints = session[:constraints]
    constraints.each {|constraint|
      if constraint[:field] == 'archive' && constraint[:type] == 'FacetConstraint' && constraint[:value] == site_value
        return true
      end
    }
    return false
  end
  
  def resource_data_link( resource )
    #     <form id="add-constraint" method="post" action="/search/constrain_resources">
    object_count = site_object_count(resource.value)
    if object_count != 0
      display_str = "#{h(resource.display_name)} (#{pluralize( object_count, 'object' )})"
      if resource_is_in_constraints?(resource)
        html = "<li><span class='resource_list_selected'>&rarr; #{display_str}</span>&nbsp;"
        html += link_to "[remove]", { :controller => 'search', :action => "constrain_resources", :resource => resource.value, :remove => true }, { :method => :post, :class => 'nav_link' } 
        html += "</li>"
        return html
      else
        link = link_to display_str, {:controller=>"search", :action => 'constrain_resources', :resource => resource.value }, { :method => :post, :class => 'nav_link' }
        return "<li>#{link}</li>"
      end
    else
      return ""
    end
  
#    if resource_data[:exists]
#      html = "&rarr; #{h genre_data[:value]} (#{number_with_delimiter(genre_data[:count])})&nbsp;"
#      html += link_to "[remove]", { :controller => 'search', :action => "remove_genre", :value => genre_data[:value] }, { :method => :post } 
#      return html
#    else
#      link_to "#{h genre_data[:value]} (#{number_with_delimiter(genre_data[:count])})", {:controller=>"search", :action => 'add_facet', :field => 'genre', :value => genre_data[:value]}, { :method => :post } 
#    end

  end
  
  def free_culture_is_in_constraints?
    constraints = session[:constraints]
    constraints.each {|constraint|
      if constraint[:type] == 'FreeCultureConstraint' 
        return true
      end
    }
    return false
  end
  
  def free_culture_link(count)
    display_str = "Free Culture Only (#{pluralize(count, 'object')})"
    if free_culture_is_in_constraints?
      html = "<li><span class='resource_list_selected'>&rarr; #{display_str}</span>&nbsp;"
      html += link_to "[remove]", { :controller => 'search', :action => "constrain_freeculture", :remove => true }, { :method => :post, :class => 'nav_link' } 
      html += "</li>"
      return html
    else
      link = link_to display_str, {:controller=>"search", :action => 'constrain_freeculture' }, { :method => :post, :class => 'nav_link' }
      return "<li>#{link}</li>"
    end
  end
  
  def genre_data_link( genre_data )
    if genre_data[:exists]
      html = "<span class='resource_list_selected'>&rarr; #{h genre_data[:value]} (#{pluralize(genre_data[:count], 'object')})</span>&nbsp;"
      html += link_to "[remove]", { :controller => 'search', :action => "remove_genre", :value => genre_data[:value] }, { :method => :post, :class => 'nav_link' } 
      return html
    else
      link_to "#{h genre_data[:value]} (#{pluralize(genre_data[:count], 'object')})", {:controller=>"search", :action => 'add_facet', :field => 'genre', :value => genre_data[:value]}, { :method => :post, :class => 'nav_link' } 
    end

  end
  
  def site_subtotal(facet_category)    
    count = 0
    if facet_category['type'] == nil
      facet_category.sorted_children.each { |child| 
        if child.children.size > 0 
          count = count + site_subtotal(child)
        else
          count = count + site_object_count(child.value)
        end    
      }
    else
      count = site_object_count(facet_category.value)
    end
    return count
  end
    
  def is_constrained_by_child(resource)
    constraints = session[:constraints]
    resource_constraint = ""
    constraints.each {|constraint|
      if constraint[:field] == 'archive' && constraint[:type] == 'FacetConstraint'
        resource_constraint = constraint[:value]
      end
    }
    return false if resource_constraint == ""
    
    resource.children.each {|child|
      return true if child['value'] == resource_constraint
    }
    
    return false
  end
  
#  def mark_as_checked_freeculture()
#    session[:selected_freeculture] ? 'checked="checked"' : ''  
#  end
#  
#  def mark_as_checked_resource( facet )
#    session[:selected_resource_facets].include?(facet) ? 'checked="checked"' : ''
#  end
  
  def gray_if_zero( count )
    count==0 ? 'class="grayed-out-resource"' : ''
  end
    
  def site_object_count(code)
    @results['facets']['archive'][code].to_i
  end
  
#  def site_category_heading( category_name, category_id, initial_state = :closed )
#    display_none = 'style="display:none"'
#    label = "<span id=\"cat_#{category_id}_closed\" #{initial_state == :open ? display_none : ''} class=\"site-category-toggle\">"
#    label << link_to_function('&#x25BA; ' + category_name,"toggleCategory('#{category_id}')", { :class => 'nav_link'})
#    label << "</span>"
#    label << "<span id=\"cat_#{category_id}_opened\" #{initial_state == :closed ? display_none : ''} class=\"site-category-toggle\">"
#    label << link_to_function('&#x25BC; ' + category_name, "toggleCategory('#{category_id}')", { :class => 'nav_link' })
#    label << "</span>"
#  '<tr><td><img src="images/arrow_dn.gif" /> Collections</td><td class="num_objects">1,131</td></tr>'
#  end
  
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
      str += "<a class='modify_link' href='#'>Add a tag</a>\n"
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
    note = item.annotation
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
  
  def encodeForUri(str)
    value = str.gsub('%', '%25')
    value = value.gsub('#', '%23')
    value = value.gsub('&', '%26')
    value = value.gsub(/\?/, '%3f')
    value = value.gsub('.', '%2e')
    value = value.gsub('"', '%22')
    value = value.gsub("'", '%27')
    value = value.gsub("<", '%3c')
    value = value.gsub(">", '%3e')
    value = value.gsub("\\", '%5c')
    return value
  end
  
  def create_saved_search_url(user_name, search_name)
    "/search/saved?user=#{user_name}&name=#{encodeForUri(search_name)}"
  end
  
  def create_saved_search_permalink(s)
    base_url = 'http://' + request.host_with_port()
    permalink_id = "permalink_#{encodeForUri(h(s))}"
    return "<a id='#{permalink_id}' class='nav_link' href='#' onclick='showString(\"#{permalink_id}\", \"#{base_url}#{create_saved_search_url(session[:user][:username], s)}\"); return false;'><img src='/images/link.jpg' title=\"Click here to get a permanent link for this saved search.\" alt=\"\"/></a>"
  end

  def create_saved_search_link(s)
    return "<a class='nav_link' href='#{create_saved_search_url(session[:user][:username], s.name)}'>#{h(s.name)}</a>"
    #link_to s.name, {:controller=>"search", :action => 'apply_saved_search', :username => session[:user][:username], :name => s.name }, :class => 'nav_link'
  end

  def create_remove_saved_search_link(s)
    link_to "[remove]", { :action => 'remove_saved_search', :username => session[:user][:username], :id => s.id}, :class => 'modify_link', :confirm => "Are you sure you want to remove this saved search?"
  end
  
  def has_constraints?
    return session[:constraints].length != 0
  end
  
  def format_constraint(constraint)
    ret = {}
    value_display = constraint.value
    if constraint.field=="archive"
      if site(constraint.value)
        value_display = site(constraint.value)['description']
      end
    end
    
    ret[:not] = constraint.inverted
    if constraint.is_a?(FreeCultureConstraint)
      ret[:title] ="Free Culture"
      ret[:value] = 'Only resources that are freely available in their full form'
    elsif constraint.is_a?(ExpressionConstraint)
      ret[:title] ="Keyword"
      ret[:value] = constraint.value
    elsif constraint.is_a?(FacetConstraint) && constraint[:field] == 'genre'
      ret[:title] ="Genre"
      ret[:value] = value_display
    elsif constraint.is_a?(FacetConstraint) && constraint[:field] == 'title'
      ret[:title] ="Title"
      ret[:value] = value_display
    elsif constraint.is_a?(FacetConstraint) && constraint[:field] == 'year'
      ret[:title] ="Year"
      ret[:value] = value_display
    elsif constraint.is_a?(FacetConstraint) && constraint[:field] == 'author'
      ret[:title] ="Author"
      ret[:value] = value_display
    elsif constraint.is_a?(FacetConstraint) && constraint[:field] == 'editor'
      ret[:title] ="Editor"
      ret[:value] = value_display
    elsif constraint.is_a?(FacetConstraint) && constraint[:field] == 'publisher'
      ret[:title] ="Publisher"
      ret[:value] = value_display
    elsif constraint.is_a?(FacetConstraint)
      ret[:title] ="Resource"
      ret[:value] = value_display
    else
      return nil
    end
    return ret
  end
  
  def result_row_item(type, hit, key, label, is_hidden)
    if !hit[key]
      return ""
    end
    
    cls = is_hidden ? "class='hidden'" : ""
    
    if type == :separate_lines
      # multiple items on separate lines
      str = ""
      hit[key].each_with_index do |item, i|
        str += "<tr #{cls}>\n"
        str += "\t<td class='search_result_data_label' valign='top'>"
        str += label + ":" if i < 1
        str += "</td>\n"
        str += "\t<td valign='top' width='100%'>"
        str += h(item)
        str += "</td>\n"
        str += "</tr>\n"
      end

    elsif type == :single_item
      # single item
      str = "<tr #{cls}>\n"
      str += "\t<td class='search_result_data_label' valign='top'>"
      str += label + ":"
      str += "</td>\n"
      str += "\t<td valign='top' width='100%'>"
      str += h(hit[key])
      str += "</td>\n"
      str += "</tr>\n"

    elsif type == :multiple_item
      # multiple item, one line
      str = "<tr #{cls}>\n"
      str += "\t<td class='search_result_data_label' valign='top'>"
      str += label + ":"
      str += "</td>\n"
      str += "\t<td valign='top' width='100%'>"
      str += h(hit[key].join('; '))
      str += "</td>\n"
      str += "</tr>\n"
    end
    return str
  end
  
  ##############################
  # Helpers for the facet tree that shows resources
  # These are called either in edit mode or normal mode
  # For the administrator page or the search page.
  def site_selector(site, indent, is_edit_mode, is_category, parent_id, start_hidden, is_found )
    display_name = site.display_name
    id = site.id
    value = site['value']
    
    # This is one line in the resources.
    # If edit mode: don't show # objects, show value instead.
    # if category, put in arrow for expand/collapse
    html = "<tr class='#{parent_id}#{ ' hidden' if start_hidden }#{ ' limit_to_selected' if site_is_in_constraints?(value) }'><td class='limit_to_lvl#{indent}'>\n"
    if is_category
      html += "<a id='site_opened_#{id}' #{'class=hidden' if start_hidden} href='#' onclick='open_tree(event, \"#{id}\"); return false;'><img src='/images/arrow.gif' /></a>"
      html += "<a id='site_closed_#{id}' #{'class=hidden' if !start_hidden} href='#' onclick='close_tree(event, \"#{id}\"); return false;'><img src='/images/arrow_dn.gif' /></a>\n"
    end
    
    if is_edit_mode
       if is_found
        html += display_name
      else
        html += "<b>Not found: " + display_name + "</b>"
      end
      html += " [#{value}]" if !is_category
      html += "</td><td class='num_objects'>#{'Yes' if site.carousel_include == 1}</td><td class='edit_delete_col'>"
      if is_found
        html += "<a href='#' class='modify_link' onclick='new EditFacetDialog(\"edit_site_list\", \"/admin/facet_tree/edit_facet\", \"#{value}\", \"/admin/facet_tree/get_categories\", \"/admin/facet_tree/get_resource_details\"); return false;'>[edit]</a>"
        html += "<a href='#' class='modify_link' onclick='new DeleteFacetDialog(\"edit_site_list\", \"/admin/facet_tree/delete_facet\", \"#{value}\", #{is_category}); return false;'>[delete]</a>"
      else
        html += "<a class='modify_link' href='#' onclick='new RemoveSiteDlg(\"edit_site_list\", \"/admin/facet_tree/remove_site\", \"#{value}\"); return false;'>[remove]</a>"
      end
    else # not edit mode
      total = site_subtotal(site)
      if is_category
        html += "<a href='#' onclick='toggle_tree(event, \"#{id}\"); return false;' class='nav_link  limit_to_category' >" + display_name + "</a></td><td class='num_objects'>#{number_with_delimiter(total)}"
      else
        if site_is_in_constraints?(value)
          html += display_name + "</td><td class='num_objects'>#{number_with_delimiter(total)}"
        else
          onclick = "var f = document.createElement('form'); f.style.display = 'none'; this.parentNode.appendChild(f); f.method = 'POST'; f.action = this.href;f.submit();return false;"
          html += "<a href='/collex/constrain_resources?resource=#{value}' class='nav_link' onclick=\"#{onclick}\" >" + display_name + "</a></td><td class='num_objects'>#{number_with_delimiter(total)}"
        end
      end
    end
    html += "</td></tr>\n"
    return html
  end
  
  def genre_selector( genre_data )
    if genre_data[:exists]
      html = "<tr class='limit_to_selected'><td>#{h genre_data[:value]}"
    else
      html = "<tr><td class='limit_to_lvl1'>" + link_to("#{h genre_data[:value]}", {:controller=>"search", :action => 'add_facet', :field => 'genre', :value => genre_data[:value]}, { :method => :post, :class => 'nav_link' })
    end
    html += "</td><td class='num_objects'>#{number_with_delimiter(genre_data[:count])}</td></tr>"
    return html
  end

  def free_culture_selector(count)
    if free_culture_is_in_constraints?
      html = "<tr class='limit_to_selected'><td>Free Culture Only"
    else
      html = "<tr><td class='limit_to_lvl1'>" + link_to("Free Culture Only", {:controller=>"search", :action => 'constrain_freeculture' }, { :method => :post, :class => 'nav_link' })
    end
    html += "</td><td class='num_objects'>#{number_with_delimiter(count)}</td></tr>"
    return html
  end
end

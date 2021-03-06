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

class ResultsController < ApplicationController
  
  MIN_ITEMS_PER_PAGE = 30
  
  #   def details
  #      setup_ajax_calls(params)
  #
  #      render :partial => 'result_row', :locals => { :page => @page, :index => @index, :hit => @hit }
  #  end
  
  def collect
	  if request.request_method != 'POST'
		  render_422
		  return
	  end
    # Only collect if the item isn't already collected and if there is a user logged in.
    # This would normally be the case, but there are strange effects if the user is logged in two browsers, or if the user's session was idle too long.
    locals = setup_ajax_calls(params, false)
    if locals[:is_error] == nil
      CollectedItem.collect_item(locals[:user], locals[:uri], locals[:hit]) unless locals[:user] == nil || locals[:uri] == nil
    end
    
    partial = params[:partial]
    if partial == '/results/result_row'
			locals[:hit]['text'] = locals[:full_text] if locals[:full_text] && locals[:full_text].length > 0
      render :partial => partial, :locals => { :index => locals[:index], :hit => locals[:hit], :has_exhibits => locals[:has_exhibits], :add_border => true }
    elsif partial == '/forum/attachment'
      render :partial => partial, :locals => { :comment => DiscussionComment.find(locals[:index]) }
    end
  end
  
  def uncollect
	  if request.request_method != 'POST'
		  render_422
		  return
	  end
    partial = params[:partial]
		if partial != '/results/result_row' && partial != '/forum/attachment'
			render :text => 'Bad parameters in call to uncollect', :status => :bad_request
		else
			locals = setup_ajax_calls(params, true)
			CollectedItem.remove_collected_item(user, locals[:uri]) unless locals[:user] == nil || locals[:uri] == nil

			if partial == '/results/result_row'
				locals[:hit]['text'] = locals[:full_text] if locals[:full_text] && locals[:full_text].length > 0
				render :partial => partial, :locals => { :index => locals[:index], :hit => locals[:hit], :has_exhibits => locals[:has_exhibits], :add_border => true }
			elsif partial == '/forum/attachment'
				render :partial => partial, :locals => { :comment => DiscussionComment.find(locals[:index]) }
			end
		end
  end
  
  # Add tags to an item. Multiple tags can be added by using a comma to separate them. The item
  # need not be collected. Several pieces of data must be in the call params: tag_info, user and uri
  #
  def add_tag( should_render = true)
	  
	  # only accept this call from a POST action
	  if request.request_method != 'POST'
		  render_422
		  return
	  end
	  
	  # grab call params
	  is_cached = CachedResource.exists( params[:uri] ) 
    locals = setup_ajax_calls(params, is_cached)
    tag_info = params[:tag]
    user = locals[:user]
    uri = locals[:uri]
    
    # pass them along to the tag model for addition
    Tag.add(user, uri, tag_info)
   
    if should_render
  		locals[:hit]['text'] = locals[:full_text] if locals[:full_text] && locals[:full_text].length > 0
      render :partial => 'result_row', :locals => { :index => locals[:index], :hit => locals[:hit] }
    end
  end
  
  # Remove a tag from the uri specified resource
  #
  def remove_tag
	  if request.request_method != 'POST'
		  render_422
		  return
	  end
    locals = setup_ajax_calls(params, true)
    tag = params[:tag]
    Tag.remove(locals[:user], locals[:uri], tag) unless locals[:user] == nil || locals[:uri] == nil
    
		locals[:hit]['text'] = locals[:full_text] if locals[:full_text] && locals[:full_text].length > 0
    render :partial => 'result_row', :locals => { :index => locals[:index], :hit => locals[:hit] }
  end
  
  def set_annotation
	  if request.request_method != 'POST'
		  render_422
		  return
	  end
    locals = setup_ajax_calls(params, true)
    note = params[:note]
    CollectedItem.set_annotation(locals[:user], locals[:uri], note) unless locals[:user] == nil || locals[:uri] == nil
    
		locals[:hit]['text'] = locals[:full_text] if locals[:full_text] && locals[:full_text].length > 0
    render :partial => 'result_row', :locals => { :index => locals[:index], :hit => locals[:hit] }
  end
  
  def bulk_add_tag
	  if request.request_method != 'POST'
		  render_422
		  return
	  end
    tag = params['tag']
    uris = params['uris']
    
    user = session[:user] ? User.find_by_username(session[:user][:username]) : nil
    
    if uris != nil && user != nil && tag != nil && tag['name'].length > 0
	    uris = uris.split("\t")
      uris.each{ |uri|
        params['uri'] = uri
        add_tag false # false so this call will not attempt to render
      }
	end
	  redirect_with_page(request, params)
  end
  
  def bulk_collect
	  if request.request_method != 'POST'
		  render_422
		  return
	  end
	  
	 bulk_tag = params[:bulk_tag_text]
    user = session[:user] ? User.find_by_username(session[:user][:username]) : nil
    if user != nil && params[:bulk_collect] != nil
      uris = params[:bulk_collect]
      uris.each do | key,uri |
        CollectedItem.collect_item(user, uri, nil)
        if bulk_tag != nil && bulk_tag.length > 0
            Tag.add(user, uri, {'name' => bulk_tag} ) 
        end
      end
    end

		redirect_with_page(request, params)
  end
  
  # uncollect a set of items in bulk. The items to be uncollected
  # are contained in the bulk_collect form post
  def bulk_uncollect
    
    # Only allow this to be called from a POST action
    if request.request_method != 'POST'
      render_422
      return
    end
    
    user = session[:user] ? User.find_by_username(session[:user][:username]) : nil
    if user != nil && params[:bulk_collect] != nil
      uris = params[:bulk_collect]
      uris.each do |key,uri|
        CollectedItem.remove_collected_item(user, uri)
      end
    end

	# refresh the posed page with the new collection
	redirect_with_page(request, params)
  end
	
  def resend_exhibited_objects
    # This is to update the section after a change elsewhere on the page
    render :partial => 'exhibited_objects', :locals => { :current_user_id => user.id }
  end

  private
	def redirect_with_page(request, params)
		target = request.env["HTTP_REFERER"]
		if params['page']
			target += target.include?('?') ? '&' : '?'
			target += "page=#{params['page']}"
		end
		redirect_to(target)
	end

  def encode_for_uri(str) # TODO-PER: this is in a helper, so it can't be called from a controller, so we are just repeating it.
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
  public

  # edit the name of an existing tag
  #
  def edit_tag
	  if request.request_method != 'POST'
		  render_422
		  return
	  end
	  
    user = session[:user] ? User.find_by_username(session[:user][:username]) : nil
    if user != nil
      old_name = params[:old_name]
      new_name = params[:new_name]
      
      tagged_items = CachedResource.get_hits_for_tag(old_name, user)
      
      tagged_items.each do |item|
        Tag.rename(user, item['uri'], old_name, new_name)
      end
    end
    
    back = request.env["HTTP_REFERER"]
    back = back.gsub(encode_for_uri(old_name), Tag.normalize_tag_name(encode_for_uri(new_name)) )
    redirect_to back
  end
  
  def remove_all_tags
	  if request.request_method != 'POST'
		  render_422
		  return
	  end
    user = session[:user] ? User.find_by_username(session[:user][:username]) : nil
    if user != nil
      tag = params[:tag]
      
      tagged_items = CachedResource.get_hits_for_tag(tag, user)
      
      tagged_items.each { |item|
        Tag.remove(user, item['uri'], tag)
      }
  
    end
    back = request.env["HTTP_REFERER"]
    back = back.split('?')[0] + '?view=all_collected'
    redirect_to back
  end

  def add_object_to_exhibit
	  if request.request_method != 'POST'
		  render_422
		  return
	  end
    locals = setup_ajax_calls(params, true)
    exhibit_name = params[:exhibit]
    if locals[:user] != nil
      exhibit = Exhibit.find_by_user_id_and_title(locals[:user].id, exhibit_name)
      if exhibit == nil
        # TODO-PER: HACK! I don't know why, but sometimes the exhibit name comes back with quotes encrypted. If we can't find the exhibit
        # with this name, then try unencrypting it and trying again. (It is possible that this was just a cached file in the user's browser.)
        name = exhibit_name.gsub("&quot;", '"')
        exhibit = Exhibit.find_by_title_and_user_id(name, locals[:user].id)
#        arr = exhibit_name.split("")
#        str = '/' + h(arr.join('.')) + "/<br />"
#        arr = name.split("")
#        str += '/' + h(arr.join('.')) + "/<br />"
#        exes = Exhibit.find(:all, :conditions => ["user_id = ?", locals[:user].id])
#        exes.each {|ex|
#          arr = ex.title.split("")
#          str += '/' + h(arr.join('.')) + "/<br />"
#        }
#        locals[:hit]['warning'] = str
      end
      ExhibitObject.add(exhibit.id, locals[:uri])
			exhibit.bump_last_change()
    end

    partial = params[:partial]
    if partial == 'result_row'
			locals[:hit]['text'] = locals[:full_text] if locals[:full_text] && locals[:full_text].length > 0
      render :partial => partial, :locals => { :index => locals[:index], :hit => locals[:hit], :has_exhibits => locals[:has_exhibits], :add_border => true }
    elsif partial == '/forum/attachment'
      render :partial => partial, :locals => { :comment => DiscussionComment.find(locals[:index]) }
    end
  end
  
  def redraw_result_row_for_popup_buttons
    hit = get_from_cache(params[:uri])
    render :partial => 'result_row_for_popup_buttons', :locals => { :hit => hit, :index => params[:index], :partial => params[:partial], :target_el => params[:target_el] }
  end

  private
  def setup_ajax_calls(params, is_in_cache)
    # expire the fragment caches for the clouds related to this user
    #expire_timeout_fragment( %r{/cloud/#{session[:user][:username]}_user} )    
    ret = {}
    
    session[:items_per_page] ||= MIN_ITEMS_PER_PAGE
    ret[:user] = session[:user] ? User.find_by_username(session[:user][:username]) : nil
    if is_in_cache
      ret[:hit] = get_from_cache(params[:uri])
#      ret[:hit]['title'][0] = '[cache]' + ret[:hit]['title'][0]
    else
	    begin
      ret[:hit] = get_from_solr(params[:uri])
	    rescue Catalog::Error => e
		    ret[:hit] = nil
		end
      if ret[:hit] == nil
        ret[:is_error] = true
        ret[:hit] = get_from_cache(params[:uri])
        ret[:hit] = {} if ret[:hit] == nil
        ret[:hit]['title'] = 'Note: This object no longer exists in the index'
      end
#      bytes = ''
#      ret[:hit]['title'][0].each_byte { |c|
#        bytes += c > 127 ? "[#{c}] " : "#{c} "
#      }
#      ret[:hit]['title'][0] = '[solr]' + ret[:hit]['title'][0] + bytes
    end
    if params[:full_text] && params[:full_text].length > 0
      ret[:hit]['text'] = params[:full_text].strip	# get rid of all the extra characters around the text we want
			ret[:hit]['text'] = ret[:hit]['text'].gsub('%3f', '?').gsub('%25', '%').gsub('%26', '&')
			ret[:hit]['text'] = ret[:hit]['text'].gsub("<EM>", "<em>").gsub("</EM>", "</em>")	# correct for IE returning capital tags.
			ret[:full_text] = ret[:hit]['text']
    end
    ret[:uri] = params[:uri]
    ret[:index] = params[:row_num].to_i 

    if ret[:user] != nil
      ret[:has_exhibits] = (Exhibit.find_by_user_id(ret[:user].id) != nil)
    else
      ret[:has_exhibits] = false
    end
    return ret
  end
  
  def get_from_solr(uri)
    @solr = Catalog.factory_create(session[:use_test_index] == "true") if @solr == nil
#    begin
			return @solr.get_object( uri )
#		rescue  Net::HTTPServerException => e
#			return nil
#		end
#    return nil
  end

  def get_from_cache(uri)
    return CachedResource.get_hit_from_uri(uri)
  end
end

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

module DiscussionThreadsHelper
  def toggle_discussion_topic( topic_num, item_id_prefix, toggle_function, initial_state )
    display_none = 'style="display:none"'
    label = ""
    
    label << "<span id=\"#{item_id_prefix}_#{topic_num}_closed\" #{initial_state == :open ? display_none : ''} >"
    label << link_to_function(closed_char(),"#{toggle_function}('#{item_id_prefix}_#{topic_num}')", { :class => 'modify_link' })
    label << "</span>\n"
    label << "<span id=\"#{item_id_prefix}_#{topic_num}_opened\" #{initial_state == :closed ? display_none : ''} >"
    label << link_to_function(opened_char(), "#{toggle_function}('#{item_id_prefix}_#{topic_num}')", { :class => 'modify_link'})
    label << "</span>\n"
    return label
  end
  
  def get_user_link(user)
    if user.class == Fixnum
      user = User.find(user)
    end
    if user.link != nil && user.link != ""
      link_to(user.fullname, user.link, :class => 'ext_link', :target => '_blank')
    else
      user.fullname
    end
  end
  
  def make_ext_link(url)
    str = h(url)
    if url.index("http") != 0  # if the link doesn't start ith http, then we'll add it.
      url = "http://" + url
    end
    return "<a class='ext_link' target='_blank' href='#{url}'>#{str}</a>"
  end
  
  def make_edit_link(comment, is_main)
    html = "<a href='#' class='nav_link' onclick=\"new ForumReplyDlg({" +
      "comment_id: #{comment.id},"
    if is_main # only the main comment has a title.
      html += "title: '#{DiscussionThread.find(comment.discussion_thread_id).get_title()}',"
    end
    html += "obj_type: #{comment.comment_type}," +
      "reply: 'comment_body_#{comment.id}'," +
      "nines_obj_list: '#{comment.cached_resource_id && comment.cached_resource_id > 0 ? CachedResource.find(comment.cached_resource_id).uri : ''}'," +
      "exhibit_list: 'id_#{comment.exhibit_id}'," +
      "inet_thumbnail: '#{comment.image_url}'," +
      "inet_url: '#{comment.link_url}'," +
      "ajax_div: 'comment_id_#{comment.id}'," +
      "submit_url: '/forum/edit_existing_comment'," +
      "populate_exhibit_url: '/forum/get_exhibit_list'," +
      "populate_nines_obj_url: '/forum/get_nines_obj_list'," +
      "progress_img: '#{PROGRESS_SPINNER_PATH}'," +
      "logged_in: true }); return false;\">[edit]</a>"
    return html
  end
  
  def get_user_picture(user_id, type)
    placeholder = "/images/forum_generic_user.gif"
    user = User.find_by_id(user_id)
    return placeholder if user == nil
    return placeholder if user.image == nil
    return placeholder if user.image.public_filename == nil

    full_size_path = user.image.public_filename
    file_path = user.image.public_filename(type)
  
    if File.exists?("#{RAILS_ROOT}/public/#{file_path}")
      return file_path
    elsif File.exists?("#{RAILS_ROOT}/public/#{full_size_path}")
      return full_size_path
    else
      return placeholder
    end
  end
  
  def is_new_post(tim)
    return tim > (Time.now - 86400*1)
  end
  
  def comment_time_format(tim)
    return tim.getlocal().strftime("%b %d, %Y %I:%M%p")
  end

  def comment_time_format_relative(tim)
    return time_ago_in_words(tim) + " ago"
  end

  def sort_topics(by_date, topics)
    if by_date
      topics = topics.sort {|a,b| 
        if b[:date] && a[:date] # if there are posts in both items, then compare the dates.
          b[:date] <=> a[:date]
        elsif !b[:date] && !a[:date]  # if there are posts in neither item, then compare alpha
          a[:topic_rec].topic <=> b[:topic_rec].topic
        elsif a[:date]  # if there are posts in only one item, then that item is sorted first
          -1
        else
          1
        end
      }
    else
      topics = topics.sort {|a,b| a[:topic_rec].topic <=> b[:topic_rec].topic }
    end
    return topics
  end
  
  def get_comment_header_info(comment)
    title = DiscussionThread.find(comment.discussion_thread_id).get_title()
    if comment.get_type() == "comment"
      thumbnail = nil #get_user_picture(comment.user_id, :thumb)
      link = nil
      caption = nil
    elsif comment.get_type() == "nines_object"
      hit = CachedResource.get_hit_from_resource_id(comment.cached_resource_id)
      thumbnail = get_image_url(CachedResource.get_thumbnail_from_hit_no_site(hit))
      link = hit["url"] ? hit["url"][0] : nil
      caption = hit['title'] ? CachedResource.fix_char_set(hit['title'][0]) : ""
    elsif comment.get_type() == "nines_exhibit"
      exhibit = Exhibit.find(comment.exhibit_id)
      thumbnail = exhibit.thumbnail
      link = get_exhibit_url(exhibit)
      caption = exhibit.title
    elsif comment.get_type() == "inet_object"
      thumbnail = comment.image_url
      link = comment.link_url
      caption = comment.link_url
    else
      title = "ERROR: ill-formed comment. (Comment type #{ comment.comment_type } is unknown)"
      thumbnail = nil
      link = nil
      caption = nil
    end
    thread = DiscussionThread.find(comment.discussion_thread_id)
    last_comment = thread.discussion_comments[thread.discussion_comments.length-1]
    return { :title => title, :thumbnail => thumbnail, :author => User.find(comment.user_id), :link => link, :caption => caption,
      :last_comment_author => User.find(last_comment.user_id), :last_comment_time => last_comment.updated_at }
  end
  
  def forum_title_with_tooltip(title, comment)
    comment = strip_tags(comment) if comment != nil
    abbrev_comment = ""
    abbrev_comment = comment.slice(0,100) if comment != nil
    abbrev_comment += '...' if abbrev_comment != comment
    abbrev_title = title.slice(0,60)
    abbrev_title = abbrev_title + "..." if title.length > 60
    "#{abbrev_title}<span><div class='discussion_title_tooltip_title'>#{title}</div>#{abbrev_comment}</span>"
  end
end

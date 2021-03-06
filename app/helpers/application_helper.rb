# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper

  #-------------------------------------------------------------------
  def tabs
    @current_tab ||= :home
    Setting[:tabs].each { |tab| tab[:active] = (tab[:text].downcase.to_sym == @current_tab) }
  end
  
  #----------------------------------------------------------------------------
  def tabless_layout?
    %w(authentications passwords).include?(controller.controller_name) ||
    ((controller.controller_name == "users") && (%w(create new).include?(controller.action_name)))
  end

  #----------------------------------------------------------------------------
  def show_flash(options = { :container => nil, :sticky => false })
    [:error, :warning, :info, :notice].each do |type|
      if flash[type]
        id = "flash_#{type}"
        html = content_tag(:p, h(flash[type]), :class => "flash_#{type}", :id => (options[:container] ? nil : id))
        return html << content_tag(:script, "crm.flash('#{options[:container] || id}', #{options[:sticky]})", :type => "text/javascript")
      end
    end
    nil
  end

  #----------------------------------------------------------------------------
  def subtitle(id, hidden = true, text = id.to_s.split("_").last.capitalize)
    content_tag("div",
      link_to_remote("<small>#{ hidden ? "&#9658;" : "&#9660;" }</small> #{text}",
        :url => url_for(:controller => :home, :action => :toggle, :id => id),
        :before => "crm.flip_subtitle(this)"
      ), :class => "subtitle")
  end

  #----------------------------------------------------------------------------
  def inline(id, url, options = {})
    content_tag("div", link_to_inline(id, url, options), :class => options[:class] || "title_tools")
  end

  #----------------------------------------------------------------------------
  def link_to_inline(id, url, options = {})
    text = options[:text] || id.to_s.titleize
    text = (arrow_for(id) << "&nbsp;" << text) unless options[:plain]
    related = (options[:related] ? ", related: '#{options[:related]}'" : "")

    link_to_remote(text,
      :url    => url,
      :method => :get,
      :with   => "{ cancel: Element.visible('#{id}')#{related} }"
    )
  end

  #----------------------------------------------------------------------------
  def arrow_for(id)
    content_tag(:abbr, "&#9658;", :id => "#{id}_arrow")
  end

  #----------------------------------------------------------------------------
  def link_to_edit(model)
    name = model.class.name.downcase
    link_to_remote("Edit",
      :method => :get,
      :url    => send("edit_#{name}_path", model),
      :with   => "{ previous: crm.find_form('edit_#{name}') }"
    )
  end

  #----------------------------------------------------------------------------
  def link_to_delete(model)
    name = model.class.name.downcase
    link_to_remote("Delete!",
      :method => :delete,
      :url    => send("#{name}_path", model),
      :before => visual_effect(:highlight, dom_id(model), :startcolor => "#ffe4e1")
    )
  end

  #----------------------------------------------------------------------------
  def link_to_cancel(url)
    link_to_remote("Cancel", :url => url, :method => :get, :with => "{ cancel: true }")
  end

  #----------------------------------------------------------------------------
  def link_to_close(url)
    content_tag("div", "x",
      :class => "close", :title => "Close form",
      :onmouseover => "this.style.background='lightsalmon'",
      :onmouseout => "this.style.background='lightblue'",
      :onclick => remote_function(:url => url, :method => :get, :with => "{ cancel: true }")
    )
  end

  #----------------------------------------------------------------------------
  def jumpbox(current)
    [ :campaigns, :accounts, :leads, :contacts, :opportunities ].inject([]) do |html, controller|
      html << link_to_function(controller.to_s.capitalize, "crm.jumper('#{controller}')", :class => (controller == current ? "selected" : ""))
    end.join(" | ")
  end

  #----------------------------------------------------------------------------
  def styles_for(*models)
    render :partial => "common/inline_styles", :locals => { :models => models }
  end

  #----------------------------------------------------------------------------
  def hidden;    { :style => "display:none;"       }; end
  def exposed;   { :style => "display:block;"      }; end
  def invisible; { :style => "visibility:hidden;"  }; end
  def visible;   { :style => "visibility:visible;" }; end

  #----------------------------------------------------------------------------
  def hidden_if(you_ask)
    you_ask ? hidden : exposed
  end

  #----------------------------------------------------------------------------
  def invisible_if(you_ask)
    you_ask ? invisible : visible
  end

  #----------------------------------------------------------------------------
  def highlightable(id = nil, use_hide_and_show = false)
    if use_hide_and_show
      show = (id ? "$('#{id}').show()" : "")
      hide = (id ? "$('#{id}').hide()" : "")
    else
      show = (id ? "$('#{id}').style.visibility='visible'" : "")
      hide = (id ? "$('#{id}').style.visibility='hidden'" : "")
    end
    {
      :onmouseover => "this.style.background='seashell'; #{show}",
      :onmouseout  => "this.style.background='white'; #{hide}"
    }
  end

  #----------------------------------------------------------------------------
  def confirm_delete(model)
    question = %(<span class="warn">Are you sure you want to delete this #{model.class.to_s.downcase}?</span>)
    yes = link_to("Yes", model, :method => :delete)
    no = link_to_function("No", "$('menu').update($('confirm').innerHTML)")
    update_page do |page|
      page << "$('confirm').update($('menu').innerHTML)"
      page[:menu].replace_html "#{question} #{yes} : #{no}"
    end
  end

  #----------------------------------------------------------------------------
  def spacer(width = 10)
    image_tag "1x1.gif", :width => width, :height => 1, :alt => nil
  end

  #----------------------------------------------------------------------------
  def time_ago(whenever)
    distance_of_time_in_words(Time.now, whenever) << " ago"
  end

  #----------------------------------------------------------------------------
  def refresh_sidebar(action = nil, shake = nil)
    update_page do |page|
      page[:sidebar].replace_html :partial => "layouts/sidebar", :locals => { :action => action }
      if shake
        page[shake].visual_effect :shake, :duration => 0.4, :distance => 3
      end
    end
  end

  # Display web presence mini-icons for Contact or Lead.
  #----------------------------------------------------------------------------
  def web_presence_icons(person)
    [ :blog, :linkedin, :facebook, :twitter ].inject([]) do |links, site|
      url = person.send(site)
      unless url.blank?
        links << link_to(image_tag("#{site}.gif", :size => "15x15"), url, :popup => true, :title => "Open #{url} in a new window")
      end
      links
    end.join("\n")
  end

  # Ajax helper to refresh current index page once the user selects an option.
  #----------------------------------------------------------------------------
  def redraw(option, value, url = nil)
    remote_function(
      :url       => url || send("redraw_#{controller.controller_name}_path"),
      :with      => "{ #{option}: '#{value}' }",
      :condition => "$('#{option}').innerHTML != '#{value}'",
      :loading   => "$('#{option}').update('#{value}'); $('loading').show()",
      :complete  => "$('loading').hide()"
    )
  end

end

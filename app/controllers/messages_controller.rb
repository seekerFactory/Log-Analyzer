class MessagesController < ApplicationController
  before_filter :do_scoping

  filter_access_to :all

  # XXX ELASTIC clean up triple-duplicated quickfilter shit
  def do_scoping
    if params[:host_id]
      @scoping = :host
      block_access_for_non_admins

      @host = Host.find(:first, :conditions => {:host=> params[:host_id]})
      if params[:filters].blank?
        @messages = MessageGateway.all_of_host_paginated(@host.host, params[:page])
      else
        @additional_filters = Quickfilter.extract_additional_fields_from_request(params[:filters])
        @messages = MessageGateway.all_by_quickfilter(params[:filters], params[:page], :hostname => @host.host)
        @quickfilter_result_count = @messages.total_result_count
      end
      @total_count = @messages.total_result_count
      allmessage_ids(@messages) 
    elsif params[:stream_id]
      @scoping = :stream
      @stream = Stream.find_by_id(params[:stream_id])
      @is_favorited = current_user.favorite_streams.include?(params[:stream_id])

      # Check streams for reader.
      block_access_for_non_admins if !@stream.accessable_for_user?(current_user)
      
      if params[:filters].blank?
        @messages = MessageGateway.all_of_stream_paginated(@stream.id, params[:page])
        @total_count = @messages.total_result_count
      else
        @additional_filters = Quickfilter.extract_additional_fields_from_request(params[:filters])
        @messages = MessageGateway.all_by_quickfilter(params[:filters], params[:page], :stream_id => @stream.id)
        @quickfilter_result_count = @messages.total_result_count
        @total_count = MessageGateway.stream_count(@stream.id) # XXX ELASTIC Possibly read cached from first all_paginated result?!
      end
      allmessage_ids(@messages) 
    else
      @scoping = :messages
      unless (params[:action] == "show")
        block_access_for_non_admins
      end

      if params[:filters].blank?
        @messages = MessageGateway.all_paginated(params[:page])
        @total_count = @messages.total_result_count
      else
        @additional_filters = Quickfilter.extract_additional_fields_from_request(params[:filters])
        @messages = MessageGateway.all_by_quickfilter(params[:filters], params[:page])
        @quickfilter_result_count = @messages.total_result_count
        @total_count = MessageGateway.total_count # XXX ELASTIC Possibly read cached from first all_paginated result?!
      end
      allmessage_ids(@messages) 
    end
  rescue Tire::Search::SearchRequestFailed
      flash[:error] = "Syntax error in search query or empty index."
      @messages = MessageResult.new
      @total_count = 0
      @quickfilter_result_count = @messages.total_result_count
  end

  # Not possible to do this via before_filter because of scope decision by params hash
  def block_access_for_non_admins
#    if current_user.role != "admin"
# changed to super admins only
    if (current_user.role != "admin" )
      flash[:error] = "You have no access rights for this section."
      redirect_to :controller => "streams", :action => "index"
    end
  end
  def block_access_for_non_superadmins
#    if current_user.role != "admin"
# changed to super admins only
    if !(current_user.role == "admin" and current_user.super == 1)
      flash[:error] = "You have no access rights for this section."
      redirect_to :controller => "streams", :action => "index"
    end
  end

  def allmessage_ids(messages)
      msgids = [] 
      messages.each do |message|
        msgids.push(message.id) 
      end
      @msgids = msgids
  end 

  public
  def index
    @has_sidebar = true
    @load_flot = true
    @use_backtotop = true

    if ::Configuration.allow_version_check
      @last_version_check = current_user.last_version_check
    end
  end

  def show
    @has_sidebar = true
    @load_flot = true

    @message = MessageGateway.retrieve_by_id(params[:id])
    @terms = MessageGateway.analyze(@message.message)

    unless @message.accessable_for_user?(current_user)
      block_access_for_non_admins
    end

    @comments = Messagecomment.all_matched(@message)

    if params[:partial]
      render :partial => "full_message"
      return
    end
  end

  def destroy
    render :status => :forbidden, :text => "forbidden" and return if !::Configuration.allow_deleting

    if MessageGateway.delete_message(params[:id])
      flash[:notice] = "Message has been deleted."
    else
      flash[:error] = "Could not delete message."
    end

    redirect_to :action => "index"
  end

  def showrange
    @has_sidebar = true
    @load_flot = true
    @use_backtotop = true

    @from = Time.at(params[:from].to_i-Time.now.utc_offset)
    @to = Time.at(params[:to].to_i-Time.now.utc_offset)

    @messages = MessageGateway.all_in_range(params[:page], @from.to_i, @to.to_i)
    @total_count = @messages.total_result_count
  end

  def getexport
    pagenum = params[:pagenumber]

    messageids = params[:msgids]
#    Rails.logger.error "for messageids  =====>#{messageids}"

#    messages = MessageGateway.all_paginated(pagenum)
#    messages = MessageGateway.all_of_stream_paginated(@stream.id, params[:page])

#    filename = "/home/seeker/loaders/grayweb/tmp/message.txt"

#Rails.root.join(&quot;tmp/message.txt&quot

    filename = Rails.root.join("tmp/message.txt")
    Rails.logger.error "Test Rails.root  =====>#{filename}"

   # directory = "/home/seeker/loaders/grayweb/tmp"

#    f = File.open(filename, "w")
    f = File.open(filename, "w")
    f.sync = true
    count = 1
    messageids.each do |id| 
      message = MessageGateway.retrieve_by_id(id)
      f.write("#{count}  ID: ")
      f.write(message.id)
      f.write("\t")
      f.write("DATE: ")
      f.write(message.uniform_date_string)
      f.write("\t")
      f.write("MESSAGE: ")
      f.write(message.message)
      f.write("\n")
      count += 1
    end
   
   send_file filename, :type => 'plain/text', filename => filename

  end

  def getcompletemessage
    message = Message.find params[:id]
    render :text => CGI.escapeHTML(message.message)
  end

end

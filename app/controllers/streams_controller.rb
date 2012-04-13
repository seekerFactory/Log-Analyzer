class StreamsController < ApplicationController
  filter_access_to :all
  before_filter :load_stream, :except => [ :index, :create ]

  def show
    @stream = Stream.find_by_id(params[:id])
    redirect_to stream_messages_path(@stream)
  end

  def index
    @new_stream = Stream.new

    if current_user.role_symbols.include? :admin
      @all_streams = Stream.all
    else
      @all_streams = current_user.streams
    end

    @streams_with_no_category = Array.new

    # Sort streams in own array if they have no category. Done here to avoid confusion
    # in reader/admin rights decision above
    @all_streams.each do |stream|
      if (stream.streamcategory_id.blank? or stream.streamcategory_id == 0 or !Streamcategory.exists?(:conditions => {"_id" => stream.streamcategory_id}))
        @streams_with_no_category << stream
      end
    end
  end

  def showrange
    render :status => :forbidden if !@stream.accessable_for_user?(current_user)

    @has_sidebar = true
    @load_flot = true

    begin
      @from = Time.at(params[:from].to_i-Time.now.utc_offset)
      @to = Time.at(params[:to].to_i-Time.now.utc_offset)
    rescue
      flash[:error] = "Missing or invalid range parameters."
    end

    @messages = MessageGateway.all_in_range(params[:page], @from.to_i, @to.to_i, :stream_id => @stream.id)
    @total_count = @messages.total_result_count
  end

  def rules
    @new_rule = Streamrule.new
  end

  def forward
    @new_forwarder = Forwarder.new
  end

  def analytics
    @load_flot = true
  end

  def settings
  end

  def setdescription
    @stream.description = params[:description]

    if @stream.save
      flash[:notice] = "Description has been saved."
    else
      flash[:error] = "Could not save description."
    end
    redirect_to stream_messages_path(params[:id])
  end

  def togglefavorited
    if !@stream.favorited?(current_user)
      current_user.favorite_streams << @stream
    else
      # SHITSTORM BEGIN
      user_ids = @stream.favorited_stream_ids
      user_ids = Array.new if !user_ids.is_a?(Array)
      user_ids.delete(current_user.id)
      @stream.favorited_stream_ids = user_ids
      @stream.save

      stream_ids = current_user.favorite_stream_ids
      stream_ids = Array.new if !stream_ids.is_a?(Array)
      stream_ids.delete(@stream.id)
      current_user.favorite_stream_ids = stream_ids
      current_user.save
      # SHITSTORM END
    end

    # Intended to be called via AJAX only.
    render :text => ""
  end

  def togglealarmactive
    if @stream.alarm_active
      @stream.alarm_active = false
    else
      @stream.alarm_active = true
    end

    @stream.save

    # Intended to be called via AJAX only.
    render :text => ""
  end

  def togglealarmforce
    @stream = Stream.find_by_id(params[:id])
    if @stream.alarm_force
      @stream.alarm_force = false
    else
      @stream.alarm_force = true
    end

    @stream.save

    # Intended to be called via AJAX only.
    render :text => ""
  end

  def setalarmvalues
    @stream = Stream.find_by_id(params[:id])

    unless params[:limit].blank? or params[:timespan].blank?
      @stream.alarm_limit = params[:limit]
      @stream.alarm_timespan = params[:timespan]

      if @stream.save
        flash[:notice] = "Alarm settings updated."
      else
        flash[:error] = "Could not update alarm settings."
      end
    else
        flash[:error] = "Could not update alarm settings: Missing parameters."
    end

    redirect_to settings_stream_path(@stream)
  end

  def create
    @new_stream = Stream.new params[:stream]
    @new_stream.disabled = true
    if @new_stream.save
      flash[:notice] = "Stream has been created"
      redirect_to rules_stream_path(@new_stream)
    else
      flash[:error] = "Could not create stream"
      redirect_to streams_path
    end
  end

  def rename
    @stream.title = params[:title]

    if @stream.save
      flash[:notice] = "Stream has been renamed."
    else
      flash[:error] = "Could not rename stream."
    end

    redirect_to settings_stream_path(@stream)
  end

  def addcolumn
    @stream.additional_columns << params[:column]
    duplicates = @stream.additional_columns.uniq!

    if duplicates
      flash[:error] = "Column '#{params[:column]}' already exists."
    elsif @stream.save
      flash[:notice] = "Added additional column."
    else
      flash[:error] = "Could not add additional column."
    end

    redirect_to settings_stream_path(@stream)
  end

  def removecolumn
    deleted_column = @stream.additional_columns.delete(params[:column])

    if deleted_column.nil?
      flash[:error] = "Column '#{params[:column]}' doesn't exist."
    elsif @stream.save
      flash[:notice] = "Removed additional column '#{params[:column]}'."
    else
      flash[:error] = "Could not remove column '#{params[:column]}'."
    end

    redirect_to settings_stream_path(@stream)
  end

  # This should now really be changed to /update soon.
  def categorize
    @stream = Stream.find_by_id params[:stream_id]

    if params[:streamcategory_id] == "0"
      # Reset to "no category".
      @stream.streamcategory_id = nil
    else
      @stream.streamcategory_id = params[:streamcategory_id]
    end

    if @stream.save
      flash[:notice] = "Stream has been categorized."
    else
      flash[:error] = "Could not categorize stream."
    end

    redirect_to settings_stream_path(@stream)
  end

  def toggledisabled
    @stream = Stream.find_by_id params[:id]
    if @stream.disabled.blank?
      @stream.disabled = true
    else
      @stream.disabled = !@stream.disabled
    end
    @stream.save
    redirect_to stream_path(@stream)
  end

  def clone
    if params[:title].blank?
      flash[:error] = "Missing parameter: Title of new stream"
      redirect_to streams_path and return
    end

    original = Stream.find_by_id(params[:id])
    @new_stream = Stream.new

    @new_stream.title = params[:title]
    @new_stream.streamrules = original.streamrules
    @new_stream.disabled = true
    @new_stream.save

    redirect_to stream_path(@new_stream)
  end

  def destroy
    @stream = Stream.find_by_id params[:id]
    if @stream.destroy
      flash[:notice] = "Stream has been deleted"
    else
      flash[:error] = "Could not delete stream"
    end

    redirect_to streams_path
  end

  def subscribe
    current_user.subscribed_streams << @stream
    render :json => {:status => :success}
  end

  def unsubscribe
    # SHITSTORM BEGIN
    user_ids = @stream.subscriber_ids
    user_ids = Array.new if !user_ids.is_a?(Array)
    user_ids.delete(current_user.id)
    @stream.subscriber_ids = user_ids
    @stream.save

    stream_ids = current_user.subscribed_stream_ids
    stream_ids = Array.new if !stream_ids.is_a?(Array)
    stream_ids.delete(@stream.id)
    current_user.subscribed_stream_ids = stream_ids
    current_user.save
    # SHITSTORM END

    render :json => {:status => :success}
  end

  def togglesubscription
    @stream.subscribed?(current_user) ? unsubscribe : subscribe
  end

  def shortname
    if params[:shortname].blank?
      flash[:error] = "No short name given"
      redirect_to settings_stream_path(@stream)
      return
    end

    @stream.shortname = params[:shortname]

    if @stream.save
      flash[:notice] = "Short name has been set."
    else
      flash[:error] = "Coult not set short name!"
    end

    redirect_to settings_stream_path(@stream)
  end

  def related
    if params[:related_streams_matcher].blank?
      flash[:error] = "No matcher given"
      redirect_to settings_stream_path(@stream)
      return
    end

    @stream.related_streams_matcher = params[:related_streams_matcher]

    if @stream.save
      flash[:notice] = "Related streams matcher has been set."
    else
      flash[:error] = "Coult not set related streams matcher! Make sure that the regular expression is valid."
    end

    redirect_to settings_stream_path(@stream)
  end

  protected
  def load_stream
    @stream = Stream.find_by_id params["id"]
    render :text => "Not accessible for your user.", :status => :forbidden and return if !@stream.accessable_for_user?(current_user)
  end
end

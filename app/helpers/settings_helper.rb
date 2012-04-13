module SettingsHelper

  def settings_tabs
    # lol this tab shit sucks: http://jira.graylog2.org/browse/WEBINTERFACE-43
    return [] unless @has_settings_tabs

    tabs = [
      ["General", settings_path],
      ["Message retention time", retentiontime_index_path],
      ["Message comments", messagecomments_path],
      ["Filtered terms", filteredterms_path],
    ]

    tabs << ["Version check", versioncheck_index_path] if Configuration.allow_version_check

    tabs
  end

end

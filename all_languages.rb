#!/bin/ruby
# frozen_string_literal: true

########
# Vars #
########
output_file = "/tmp/all_repository_languages.csv" # File to create when the report is generated

#####################
# Create the header #
#####################
header = %w[owner_name
            name
            primary_language
            languages
            archived
            created_at
            updated_at
            pushed_at]

############################
# Add to header if enabled #``
############################
header << "anonymous_access_enabled?" if GitHub.anonymous_git_access_enabled?

###########################
# Generate the CSV report #
###########################
CSV.open(output_file, "wb") do |csv|
  # Write the header
  csv << header
  anonymous_git_access_repo_ids = Repository.with_anonymous_git_access.pluck(:id).to_set
  # Write the individual user info
  # Create a hash of languages and their ids
  language_hash = {}
  # Build a hash of languages and their ids
  Language.find_each do |l|
    language_hash[l.id] = l.language_name.name
  end

  Repository.find_each do |r|
    # go to next repo if owner.type is User
    next if r&.owner.type == "User"
    ###################################################
    # Need to build variables for the specific format #
    ###################################################
    owner = r.owner || r.owner.login
    name = r.name
    archived = r.archived?
    created_time = r.created_at&.strftime("%Y-%m-%dT%H:%M:%SZ")
    pushed_time = r.pushed_at&.strftime("%Y-%m-%dT%H:%M:%SZ")
    updated_time = r.updated_at&.strftime("%Y-%m-%dT%H:%M:%SZ")
    primary_language = r.primary_language_name
    language_ids = r.languages.map(&:language_name_id).join(":")
    languages = language_ids.split(":").map { |id| language_hash[id.to_i] }.join(":")

    ############################################
    # set the value to N/A if the value is nil #
    ############################################
    owner = "N/A" if owner.nil? || owner.blank?
    name = "N/A" if name.nil? || name.blank?
    archived = "N/A" if archived.nil?
    pushed_time = "N/A" if pushed_time.nil? || pushed_time.blank?
    updated_time = "N/A" if updated_time.nil? || updated_time.blank?
    created_time = "N/A" if created_time.nil? || created_time.blank?
    primary_language = "N/A" if primary_language.nil? || primary_language.blank?
    languages = "N/A" if languages.nil? || languages.blank?

    ###############################
    # Set up the rows for the CSV #
    ###############################
    row = [owner,
           name,
           primary_language,
           languages,
           archived,
           created_time,
           updated_time,
           pushed_time]
    row << anonymous_git_access_repo_ids.include?(r.id) if GitHub.anonymous_git_access_enabled?
    csv << row
  end
end

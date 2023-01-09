# frozen_string_literal: true
#
# This script will fetch the alerts for all the repositories in all the
# organizations and store them in a CSV file.
#
# Usage:
#   1) Copy this file to your GHES appliance
#   2) Run: ghe-console -y
#   3) GitHub[production] (main):002:0> include Api::App::SecretScanningHelpers
#   4) load "<path to script>/get_secret_alerts.rb"
#
# Output:
#   CSV file with the alerts for all the repositories in all the organizations
#
# Compatibility:
#   GHES 3.2+
#
include Api::App::SecretScanningHelpers

def fetch_secret_alerts
  begin
    # File where the report will be stored
    report_path = "/tmp/secrets_report_#{Time.now.strftime("%Y%m%d%H%M%S")}.csv"
    # Get list of organizations
    CSV.open(report_path, "w") do |csv|
      csv << [
        "organization",
        "repository",
        "token_type",
        "token_signature",
        "token_slug",
        "commit_oid",
        "path",
        "created_at",
        "resolved?",
        "reopened?",
        "is_custom?",
        "resolved_at",
        "resolution",
        "resolver"
      ]
      # Iterate over all the orgs
      Organization.find_each do |org|
        # Get the repositories for the org in batches of 100
        org.repositories.in_batches(of: 100) do |batch|
          batch.each do |repo|
            # Get the alerts for the repo
            alert = get_alerts_for_repo(repo, nil, nil, nil, nil)
            if alert.present?
              # Iterate over the alerts retrieved
              alert.each do |a|
                if a.is_a?(GitHub::TokenScanning::Service::Token)
                  csv << [
                    "#{org.name}",
                    "#{repo.name}",
                    "#{a.token.token_type}",
                    "#{a.token.token_signature}",
                    "#{a.token.slug}",
                    "#{a.token.first_location.commit_oid if a.token.first_location}",
                    "#{a.token.first_location.path if a.token.first_location}",
                    "#{a.created_at}",
                    "#{a.resolved?}",
                    "#{a.reopened?}",
                    "#{a.is_custom?}",
                    "#{a.resolved_at}",
                    "#{a.resolution}",
                    "#{a.resolver.login if a.resolver}"
                  ]
                end
              end
            end
          end
        end
      end
    end
    puts "Report generated successfully at: #{report_path}"
  rescue
    puts "Failed to generate the report successfully!"
    puts "Contact GitHub Professional Services."
  end
end

# Call the method to get the report
fetch_secret_alerts

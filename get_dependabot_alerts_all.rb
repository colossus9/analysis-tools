# frozen_string_literal: true
#
# This script will fetch the dependabot alerts for all the repositories
# in all the organizations and store them in a CSV file.
#
# Usage:
#   1) Copy this file to your GHES appliance
#   2) Run: ghe-console -y
#   3) load "<path to script>/get_dependabot_alerts_all.rb"
#
# Output:
#   CSV file with the dependabot alerts for all the repositories in all the organizations
#
# Compatibility:
#   GHES 3.1+
#

def fetch_dependabot_alerts
  begin
    # File where the report will be stored
    report_path = "/tmp/dependabot_alerts_report_#{Time.now.strftime("%Y%m%d%H%M%S")}.csv"
    # Get list of organizations
    CSV.open(report_path, "w") do |csv|
      csv << [
        "organization",
        "repository",
        "created_at",
        "affected_depedencies",
        "fixed_in_version",
        "vulnerable_version",
        "vulnerable_manifest_path",
        "cve_id",
        "updated_at",
        "last_detected_at",
        "dismissed_at",
        "dismissed_by",
        "dismiss_reason",
      ]
      # Iterate over all the orgs
      Organization.find_each do |org|
        # Get the repositories for the org in batches of 100
        org.repositories.in_batches(of: 100) do |batch|
          batch.each do |repo|
            # Get the alerts for the repo
            alerts = repo.repository_vulnerability_alerts
            # Iterate over the alerts retrieved
            alerts.each do |a|
                # Get the affected library / dependency
                vulnerability = VulnerableVersionRange.find_by_id(a.vulnerable_version_range_id)
                details = Vulnerability.find_by_id(a.vulnerability_id)
                dismisser_user = User.find_by_id(a.dismisser_id).login unless a.dismisser_id.nil?
                csv << [
                  "#{org.name}",
                  "#{repo.name}",
                  "#{a.created_at}",
                  "#{vulnerability.affects}",
                  "#{vulnerability.fixed_in}",
                  "#{vulnerability.requirements}",
                  "#{a.vulnerable_manifest_path}",
                  "#{details.cve_id}",
                  "#{a.updated_at}",
                  "#{a.last_detected_at}",
                  "#{a.dismissed_at}",
                  "#{dismisser_user}",
                  "#{a.dismiss_reason}"
                ]
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
fetch_dependabot_alerts

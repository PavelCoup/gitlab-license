require "openssl"
require "gitlab/license"

# Generate a key pair. You should do this only once.
key_pair = OpenSSL::PKey::RSA.generate(2048)

# Write it to a file to use in the license generation application.
File.open("license_key", "w") { |f| f.write(key_pair.to_pem) }

# Extract the public key.
public_key = key_pair.public_key
# Write it to a file to ship along with the main application.
File.open("license_key.pub", "w") { |f| f.write(public_key.to_pem) }

# In the license generation application, load the private key from a file.
private_key = OpenSSL::PKey::RSA.new File.read("license_key")
Gitlab::License.encryption_key = private_key

# Build a new license.
license = Gitlab::License.new

# License information to be rendered as a table in the admin panel.
# E.g.: "This instance of GitLab Enterprise Edition is licensed to:"
# Specific keys don't matter, but there needs to be at least one.
license.licensee = {
  "Name"    => "Douwe Maan",
  "Company" => "GitLab B.V.",
  "Email"   => "douwe@gitlab.com"
}

# The date the license starts.
# Required.
license.starts_at         = Date.new(2023, 4, 24)
# The date the license expires.
# Not required, to allow lifetime licenses.
license.expires_at        = Date.new(2025, 4, 23)

# The below dates are hardcoded in the license so that you can play with the
# period after which there are "repercussions" to license expiration.

# The date admins will be notified about the license's pending expiration.
# Not required.
license.notify_admins_at  = Date.new(2025, 4, 19)

# The date regular users will be notified about the license's pending expiration.
# Not required.
license.notify_users_at   = Date.new(2025, 4, 23)

# The date "changes" like code pushes, issue or merge request creation
# or modification and project creation will be blocked.
# Not required.
license.block_changes_at  = Date.new(2025, 5, 7)

# Restrictions bundled with this license.
# Not required, to allow unlimited-user licenses for things like educational organizations.
license.restrictions  = {
  # The maximum allowed number of active users.
  # Not required.
  active_user_count: 1000,
  plan: "ultimate", 
  id: rand(1000..99999999)
  # We don't currently have any other restrictions, but we might in the future.
}

puts "License:"
puts license

# Export the license, which encrypts and encodes it.
data = license.export

puts "Exported license:"
puts data

# Write the license to a file to send to a customer.
File.open("GitLabBV.gitlab-license", "w") { |f| f.write(data) }


# In the customer's application, load the public key from a file.
public_key = OpenSSL::PKey::RSA.new File.read("license_key.pub")
Gitlab::License.encryption_key = public_key

# Read the license from a file.
data = File.read("GitLabBV.gitlab-license")

# Import the license, which decodes and decrypts it.
$license = Gitlab::License.import(data)

puts "Imported license:"
puts $license

# Quit if the license is invalid
unless $license
  raise "The license is invalid."
end

# Quit if the active user count exceeds the allowed amount:
# if $license.restricted?(:active_user_count)
#   active_user_count = User.active.count
#   if active_user_count > $license.restrictions[:active_user_count]
#     raise "The active user count exceeds the allowed amount!"
#   end
# end

# Show admins a message if the license is about to expire.
if $license.notify_admins?
  puts "The license is due to expire on #{$license.expires_at}."
end

# Show users a message if the license is about to expire.
if $license.notify_users?
  puts "The license is due to expire on #{$license.expires_at}."
end

# Block pushes when the license expired two weeks ago.
module Gitlab
  class GitAccess
    # ...
    def check(cmd, changes = nil)
      if $license.block_changes?
        return build_status_object(false, "License expired")
      end

      # Do other Git access verification
      # ...
    end
    # ...
  end
end

# Show information about the license in the admin panel.
puts "This instance of GitLab Enterprise Edition is licensed to:"
$license.licensee.each do |key, value|
  puts "#{key}: #{value}"
end

if $license.expired?
  puts "The license expired on #{$license.expires_at}"
elsif $license.will_expire?
  puts "The license will expire on #{$license.expires_at}"
else
  puts "The license will never expire."
end

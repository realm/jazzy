# Warn when there is a big PR
warn("Big PR") if lines_of_code > 500

# Don't let testing shortcuts get into master by accident
(modified_files + added_files - %w(Dangerfile)).each do |file|
  next unless File.file?(file)
  contents = File.read(file)
  if file.start_with?('spec')
    fail("`xit` or `fit` left in tests (#{file})") if contents =~ /^\w*[xf]it/
    fail("`fdescribe` left in tests (#{file})") if contents =~ /^\w*fdescribe/
  end
end

# Sometimes its a README fix, or something like that - which isn't relevant for
# including in a CHANGELOG for example
has_app_changes = !modified_files.grep(/lib/).empty?
has_test_changes = !modified_files.grep(/spec/).empty?

# Add a CHANGELOG entry for app changes
if !modified_files.include?("CHANGELOG.md") && has_app_changes
  fail("Please include a CHANGELOG entry. \nYou can find it at [CHANGELOG.md](https://github.com/realm/jazzy/blob/master/CHANGELOG.md).")
  message "Note, we hard-wrap at 80 chars and use 2 spaces after the last line."
end

# Non-trivial amounts of app changes without tests
if lines_of_code > 50 && has_app_changes && !has_test_changes
    warn "This PR may need tests."    
end

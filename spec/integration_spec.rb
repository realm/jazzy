
# ------------------------------------ #
#  Jazzy Integration tests             #
# ------------------------------------ #

#-----------------------------------------------------------------------------#

# The following integrations tests are based on file comparison.
#
# 1.  For each test there is a folder with a `before` and `after` subfolders.
# 2.  The contents of the before folder are copied to the `TMP_DIR` folder and
#     then the given arguments are passed to the `JAZZY_BINARY`.
# 3.  After the jazzy command completes the execution the each file in the
#     `after` subfolder is compared to the contents of the temporary
#     directory.  If the contents of the file do not match an error is
#     registered.
#
# Notes:
#
# - The output of the jazzy command is saved in the `execution_output.txt` file
#   which should be added to the `after` folder to test the Jazzy UI.
# - To create a new test, just create a before folder with the environment to
#   test, copy it to the after folder and run the tested pod command inside.
#   Then just add the tests below this files with the name of the folder and
#   the arguments.
#
# Rationale:
#
# - Have a way to track precisely the evolution of the artifacts (and of the
#   UI) produced by jazzy (git diff of the after folders).
# - Allow uses to submit pull requests with the environment necessary to
#   reproduce an issue.
# - Have robust tests which don't depend on the programmatic interface of
#   Jazzy. These tests depend only the binary and its arguments an thus are
#   suitable for testing Jazzy regardless of the implementation (they could even
#   work for a Swift one)

#-----------------------------------------------------------------------------#

# @return [Pathname] The root of the repo.
#
ROOT = Pathname.new(File.expand_path('../../', __FILE__)) unless defined? ROOT
$:.unshift((ROOT + 'spec').to_s)

require 'rubygems'
require 'bundler/setup'
require 'pretty_bacon'
require 'colored'
require 'CLIntegracon'

require 'cocoapods'
Pod::Config.instance.silent = true
Pod::Command::Setup.invoke

CLIntegracon.configure do |c|
  c.spec_path = ROOT + 'spec/integration_specs'
  c.temp_path = ROOT + 'tmp'

  # Ignore certain OSX files
  c.ignores '.DS_Store'
  c.ignores '.git'
  c.ignores /^(?!(docs\/|execution_output.txt))/
  c.ignores '*.tgz'

  # Transform produced databases to csv
  c.transform_produced '**/*.dsidx' do |path|
    File.open("#{path}.csv", 'w') do |file|
      file.write `sqlite3 -header -csv #{path} "select * from searchIndex;"`
    end
  end
  # Now that we're comparing the CSV, we don't care about the binary
  c.ignores '**/*.dsidx'

  c.hook_into :bacon
end

describe_cli 'jazzy' do

  subject do |s|
    s.executable = "ruby #{ROOT + 'bin/jazzy'}"
    s.environment_vars = {
      'JAZZY_FAKE_DATE'            => 'YYYY-MM-DD',
      'JAZZY_FAKE_VERSION'         => 'X.X.X',
      'COCOAPODS_SKIP_UPDATE_MESSAGE' => 'TRUE',
    }
    s.default_args = []
    s.replace_path ROOT.to_s, 'ROOT'
  end

  describe 'jazzy' do
    describe 'Creates docs with a module name, author name, project URL, ' \
      'xcodebuild options, and github info' do
      behaves_like cli_spec 'document_alamofire',
                            '-m Alamofire -a Alamofire ' \
                            '-u https://nshipster.com/alamofire ' \
                            '-x -project,Alamofire.xcodeproj,-dry-run ' \
                            '-g https://github.com/Alamofire/Alamofire ' \
                            '--github-file-prefix https://github.com/' \
                            'Alamofire/Alamofire/blob/swift-2.0 ' \
                            '--module-version swift-2.0 ' \
                            '-r http://static.realm.io/jazzy_demo/Alamofire/ ' \
                            '--skip-undocumented'
    end

    describe 'Creates Realm Swift docs' do
      realm_version = ''
      Dir.chdir(ROOT + 'spec/integration_specs/document_realm_swift/before') do
        realm_version = `./build.sh get-version`.chomp
        `REALM_SWIFT_VERSION=2.0 ./build.sh set-swift-version`
      end
      behaves_like cli_spec 'document_realm_swift',
                            '--author Realm ' \
                            '--author_url "https://realm.io" ' \
                            '--github_url ' \
                            'https://github.com/realm/realm-cocoa ' \
                            '--github-file-prefix https://github.com/realm/' \
                            "realm-cocoa/tree/v#{realm_version} " \
                            '--module RealmSwift ' \
                            "--module-version #{realm_version} " \
                            '--root-url https://realm.io/docs/swift/' \
                            "#{realm_version}/api/ " \
                            '--xcodebuild-arguments ' \
                            '"-project,RealmSwift.xcodeproj,-dry-run" ' \
                            '--template-directory "docs/templates/swift" '
    end

    # describe 'Creates docs for a podspec with dependencies and subspecs' do
    #   behaves_like cli_spec 'document_moya_podspec',
    #                         '--podspec=Moya.podspec'
    # end

    describe 'Creates docs for Swift project with a variety of contents' do
      behaves_like cli_spec 'misc_jazzy_features',
                            '-m MiscJazzyFeatures -a Realm ' \
                            '-u https://github.com/realm/jazzy ' \
                            '-g https://github.com/realm/jazzy ' \
                            '-x -dry-run ' \
                            '--min-acl private'
    end
  end
end

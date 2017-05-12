#-- Bootstrap --------------------------------------------------------------#

desc 'Initializes your working copy to run the specs'
task :bootstrap do
  if system('which bundle')
    title 'Installing gems'
    sh 'bundle install'

    title 'Updating submodules'
    sh 'git submodule update --init --recursive'
  else
    $stderr.puts "\033[0;31m" \
      "[!] Please install the bundler gem manually:\n" \
      '    $ [sudo] gem install bundler' \
      "\e[0m"
    exit 1
  end
end

begin
  require 'bundler/gem_tasks'
  require 'fileutils'

  task default: :spec

  #-- Specs ------------------------------------------------------------------#

  desc 'Run specs'
  task :spec do
    title 'Running Unit Tests'
    files = FileList['spec/*_spec.rb']
      .exclude('spec/integration_spec.rb').shuffle.join(' ')
    sh "bundle exec bacon #{files}"
    sh 'bundle exec bacon spec/integration_spec.rb'

    Rake::Task['rubocop'].invoke
  end

  desc 'Rebuilds integration fixtures'
  task :rebuild_integration_fixtures do
    title 'Running Integration tests'
    sh 'rm -rf spec/integration_specs/tmp'
    puts `bundle exec bacon spec/integration_spec.rb`

    title 'Storing fixtures'
    # Copy the files to the files produced by the specs to the after folders
    FileList['tmp/*'].each do |source|
      destination = "spec/integration_specs/#{source.gsub('tmp/', '')}/after"
      if File.exist?(destination)
        sh "rm -rf #{destination}"
        sh "mv #{source} #{destination}"
      end
    end

    # Remove files not used for the comparison
    # To keep the git diff clean
    files_glob = 'spec/integration_specs/*/after/{*,.*}'
    files_to_delete = FileList[files_glob]
      .exclude('**/.', '**/..')
      .exclude('spec/integration_specs/*/after/*docs',
               'spec/integration_specs/*/after/execution_output.txt')
      .include('**/*.dsidx')
      .include('**/*.tgz')
    files_to_delete.each do |file_to_delete|
      sh "rm -rf '#{file_to_delete}'"
    end

    puts
    puts 'Integration fixtures updated, see `spec/integration_specs`'
  end

  #-- RuboCop ----------------------------------------------------------------#

  require 'rubocop/rake_task'
  RuboCop::RakeTask.new(:rubocop)

  #-- SourceKitten -----------------------------------------------------------#

  desc 'Vendors SourceKitten'
  task :sourcekitten do
    sk_dir = 'SourceKitten'
    Dir.chdir(sk_dir) do
      `swift build -c release -Xswiftc -static-stdlib`
    end
    build_dir = "#{sk_dir}/.build/release"
    FileUtils.cp_r Dir["#{build_dir}/{sourcekitten,*.dylib}"], 'bin'
    Dir["#{build_dir}/*.dylib"].each do |file|
      system 'install_name_tool', '-change', File.expand_path(file),
             "@loader_path/#{File.basename(file)}", 'bin/sourcekitten'
    end
    system 'install_name_tool', '-delete_rpath',
           (Pathname(`xcrun -find swift`) + '../../lib/swift/macosx').to_s,
           'bin/sourcekitten'
  end

rescue LoadError, NameError => e
  $stderr.puts "\033[0;31m" \
    '[!] Some Rake tasks haven been disabled because the environment' \
    ' couldn’t be loaded. Be sure to run `rake bootstrap` first.' \
    "\e[0m"
  $stderr.puts e.message
  $stderr.puts e.backtrace
  $stderr.puts
end

#-- Helpers ------------------------------------------------------------------#

def title(title)
  cyan_title = "\033[0;36m#{title}\033[0m"
  puts
  puts '-' * 80
  puts cyan_title
  puts '-' * 80
  puts
end

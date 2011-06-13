desc "zip"
task :zip do
  dirname = File.basename( File.dirname(File.expand_path(__FILE__)))
  zipname = dirname + ".zip"
  sh "zip -r #{zipname} README.md autoload doc plugin -x doc/tags"
end

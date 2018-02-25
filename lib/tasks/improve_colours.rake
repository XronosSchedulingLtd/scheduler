namespace :improve_colours do
  task :all_users => :environment do
    messages = Array.new
    User.all.each do |u|
      message = u.improve_colours
      messages << message unless message.nil?
    end
    puts messages.join("\n")
  end
end

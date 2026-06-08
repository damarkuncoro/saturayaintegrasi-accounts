puts "Middleware stack:"
Rails.application.middleware.each do |m|
  puts " - #{m.name}"
end

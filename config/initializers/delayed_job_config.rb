Delayed::Worker.sleep_delay = 10
Delayed::Worker.max_attempts = 1
Delayed::Worker.read_ahead = 1
Delayed::Worker.logger = Logger.new(File.join(Rails.root, 'log', 'delayed_job.log'))

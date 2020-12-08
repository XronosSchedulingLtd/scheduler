require "rails/code_statistics"

task stats: :more_stats

task :more_stats do
  %w[Services].each_with_index do |type, i|
    STATS_DIRECTORIES.insert i + 5, [type, "app/#{type.downcase}"]
    STATS_DIRECTORIES.insert i * 2 + 12, ["#{type} tests", "test/#{type.downcase}"]
    CodeStatistics::TEST_TYPES << "#{type} tests"
  end
end

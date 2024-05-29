# frozen_string_literal: true

class VimFormatter
  RSpec::Core::Formatters.register self, :example_failed, :close

  def initialize(output)
    @output = output
  end

  def example_failed(notification)
    @output << format(notification) + "\n"
  end

  def close(notification)
    @output << "finished\n"
  end

  private

  def format(notification)
    example_location = notification.example.location
    expect_location = extract_expect_location(notification.exception.backtrace, example_location)
    message = notification.exception.message.gsub("\n", "\\n")
    # remove all color term codes of the message

    message = message.gsub(/\e\[\d+m/, '')

    rtn = "%s: %s" % [expect_location || example_location, message]
    rtn.gsub("\n", ' ')
  end

  def extract_expect_location(backtrace, example_location)
    if example_location[0..1] == "./"
      example_location = example_location[2..]
    end

    example_location_line = example_location.split(':').last
    example_location_file = example_location.split(':').first

    backtrace_lines = backtrace.select { |line| line.include?(example_location_file) }

    return nil if backtrace_lines.empty?

    sorted_backtrace_lines = backtrace_lines.sort do |a, b|
      a.split(':')[1].to_i <=> b.split(':')[1].to_i
    end

    backtrace_line = sorted_backtrace_lines.select { |line| line.split(':')[1].to_i > example_location_line.to_i }.first

    return nil unless backtrace_line

    example_file = example_location.split(':').first

    match = backtrace_line.match(/(.+_spec\.rb):(\d+)/)
    return nil unless match

    backtrace_file = match[1]
    backtrace_line_number = match[2]

    if File.basename(example_file) == File.basename(backtrace_file)
      relative_path = Pathname.new(backtrace_file).relative_path_from(Pathname.new(Dir.pwd)).to_s
      "#{relative_path}:#{backtrace_line_number}"
    end
  rescue StandardError => e
    # do nothing
  end
end

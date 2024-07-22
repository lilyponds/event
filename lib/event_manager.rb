require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'

def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5, '0')[0..4]
end

def legislators_by_zipcode(zip)
  civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
  civic_info.key = 'AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw'
  zipcode = clean_zipcode(zip)
  begin
    legislators = civic_info.representative_info_by_address(
      address: zipcode,
      levels: 'country',
      roles: %w[legislatorUpperBody legislatorLowerBody]
    ).officials
    legislator_names = legislators.map do |legislator|
      legislator.name
    end
    legislator_formatted = legislator_names.join(',')
  rescue StandardError
    'You can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials'
  end
  legislator_formatted
end

def save_thank_you_letter(id, form_letter)
  Dir.mkdir('output') unless Dir.exist?('output')
  filename = "output/thanks_#{id}.html"
  File.open(filename, 'w') do |file|
    file.puts form_letter
  end
end

template_letter = File.read('form_letter.erb')
erb_template = ERB.new template_letter

puts 'Event Manager Initialized!'
contents = CSV.open('event_attendees.csv',
                    headers: true,
                    header_converters: :symbol)

contents.each do |row|
  id = row[0]
  legislators = legislators_by_zipcode(row[:zipcode])
  name = row[:first_name]
  form_letter = erb_template.result(binding)
  save_thank_you_letter(id, form_letter)
end

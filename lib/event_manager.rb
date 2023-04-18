require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'

def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5,"0")[0..4]
end

def clean_phone_number(phone_number)
    phone_number.gsub!(/()[-., ]/, '')
    return phone_number if phone_number.length == 10
    return phone_number[1..10] if phone_number.length == 11 && phone_number[0] == 1

    'Invalid number'
end

def legislators_by_zipcode(zip)
  civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
  civic_info.key = 'AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw'

  begin
    civic_info.representative_info_by_address(
      address: zip,
      levels: 'country',
      roles: ['legislatorUpperBody', 'legislatorLowerBody']
    ).officials
  rescue
    'You can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials'
  end
end

def save_thank_you_letter(id,form_letter)
  Dir.mkdir('output') unless Dir.exist?('output')

  filename = "output/thanks_#{id}.html"

  File.open(filename, 'w') do |file|
    file.puts form_letter
  end
end

def open_csv
  CSV.open(
      'event_attendees.csv',
      headers: true,
      header_converters: :symbol
    )
end

def registration_day_mode
  contents = open_csv
  reg_day_array = []
  contents.each do |row|
      reg_date = row[:regdate]
      reg_day = Time.strptime(reg_date, '%M/%d/%y %k:%M').strftime('%A')
      reg_day_array.push(reg_day)
  end
  most_common_day = reg_day_array.reduce(Hash.new(0)) do |hash, day|
      hash[day] += 1
      hash
  end
  most_common_day.max_by { |_k, v| v }[0]
end

def registration_hour_mode
  contents = open_csv
  reg_hour_array = []
  contents.each do |row|
      reg_date = row[:regdate]
      reg_hour = Time.strptime(reg_date, '%M/%d/%y %k:%M').strftime('%k')
      reg_hour_array.push(reg_hour)
  end
  most_common_hour = reg_hour_array.reduce(Hash.new(0)) do |hash, hour|
      hash[hour] += 1
      hash
  end
  most_common_hour.max_by { |_k, v| v }[0]
end

puts 'EventManager initialized.'

contents = CSV.open(
    'event_attendees.csv',
    headers: true,
    header_converters: :symbol
  )
  
  template_letter = File.read('form_letter.erb')
  erb_template = ERB.new template_letter
  
  contents.each do |row|
    id = row[0]
    name = row[:first_name]
    zipcode = clean_zipcode(row[:zipcode])
    phone = clean_phone_number(row[:homephone])
    legislators = legislators_by_zipcode(zipcode)
  
    form_letter = erb_template.result(binding)
  
    save_thank_you_letter(id,form_letter)
end

puts "\nThe most common hour of registration is: #{registration_hour_mode}:00"

puts "\nThe most common registration day is: #{registration_day_mode}"
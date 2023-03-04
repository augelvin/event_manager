require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'
require 'time'
require 'date'

def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5,"0")[0..4]
end

def clean_phone_number(phone_number)
  phone_number.slice!('(')
  phone_number.slice!(')')
  phone_number.slice!('.')
  phone_number.slice!('-')
  phone_number.slice!(' ')
  phone_number.slice!('.')
  phone_number.slice!('-')
  phone_number.slice!(' ')

  if phone_number.length == 10
    phone_number
  elsif phone_number.length == 11 && phone_number[0] == 1
    phone_number.slice!(1..10)
  else
    phone_number = 'bad'
  end

  phone_number
end

def clean_hour(date)
  time = Date._strptime(date, '%m/%d/%Y %H:%M')
  time[:hour]
end

def day(date)
  time = Date._strptime(date, '%m/%d/%Y %H:%M')
  day = Date.new(time[:year], time[:mon], time[:mday]).wday
  day_name(day)
end

def day_name(day_n)
  if day_n == 0
    'Sunday'
  elsif day_n == 1
    'Monday'
  elsif day_n == 2
    'Tuesday'
  elsif day_n == 3
    'Wednesday'
  elsif day_n == 4
    'Thursday'
  elsif day_n == 5
    'Friday'
  elsif day_n == 6
    'Saturday'
  end
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

puts 'EventManager initialized.'

contents = CSV.open(
  'event_attendees.csv',
  headers: true,
  header_converters: :symbol
)

template_letter = File.read('form_letter.erb')
erb_template = ERB.new template_letter
phone_numbers = []
reg_hours = []
reg_days = []

contents.each do |row|
  id = row[0]
  name = row[:first_name]
  zipcode = clean_zipcode(row[:zipcode])
  legislators = legislators_by_zipcode(zipcode)
  phone_numbers << clean_phone_number(row[:homephone])
  reg_hours << clean_hour(row[:regdate])
  reg_days << day(row[:regdate])

  form_letter = erb_template.result(binding)

  save_thank_you_letter(id,form_letter)
end

puts phone_numbers
puts reg_hours.tally
puts reg_days.tally

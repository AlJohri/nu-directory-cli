#!/usr/bin/env ruby

require 'mechanize'
require 'net/https'
require 'optparse'

# Errors #
QUERY_LIMIT_EXCEEDED = "Query Size Limit Exceeded"
NO_MATCHED = "No matches to your searches"

options = {}

optparse = OptionParser.new do |opts|
	opts.banner = "Usage: directory.rb [options]"
	options[:simple] = true
	options[:advanced] = false;
	opts.on( '-s', '--simple', 'simple' ) do ; options[:simple] == true; end
	opts.on( '-a', '--advanced', 'advanced' ) do ; options[:advanced] == true; options[:simple] == false; end	
	opts.on( '-n', '--name NAME', 'name' ) do |name|; options[:name] = name; end
	opts.on( '-e', '--email EMAIL', 'email' ) do |email|; options[:email] = email; end
	opts.on( '-p', '--phone PHONE', 'phone' ) do |phone|; options[:phone] = phone; end  
	opts.on( '-i', '--netid ID', 'netid' ) do |netid|; options[:netid] = netid; end
	opts.on( '-d', '--department DEPARTMENT', 'department' ) do |department|; options[:department] = department; end
	opts.on( '-f', '--first_name FIRST_NAME', 'first_name' ) do |first_name|; options[:first_name] = first_name; end  
	opts.on( '-l', '--last_name LAST_NAME', 'last_name' ) do |last_name|; options[:last_name] = last_name; end
	opts.on( '-h', '--help', 'Display this screen' ) do; puts opts; exit; end
end

optparse.parse!
 
def parse(str)
	encoding_options = {
	  :invalid           => :replace,  	# Replace invalid byte sequences
	  :undef             => :replace,  	# Replace anything not defined in ASCII
	  :replace           => ' ',				# Use a blank for those replacements
	  :universal_newline => true				# Always break lines with \n (option removed in 1.9.3-p194+)
	}

	if str
		return str.to_s.encode(Encoding.find('ASCII'), encoding_options).strip()
	else
		return ""
	end
end

beginning = Time.now
agent = Mechanize.new
page = agent.get('http://directory.northwestern.edu/?a=1')
directory_form = page.form('phadv')
directory_form.set_fields(:name => options[:name])
directory_form.set_fields(:email => options[:email])
directory_form.set_fields(:phone => options[:phone])
directory_form.set_fields(:netid => options[:netid])
directory_form.set_fields(:first_name => options[:first_name])
directory_form.set_fields(:last_name => options[:last_name])
directory_form.set_fields(:department => options[:department])
#directory_form.radiobutton_with(:name => 'affiliations').check
#directory_form.radiobuttons.first.check
#pp directory_form

page = agent.submit(directory_form, directory_form.buttons.first)
doc = page.parser

numPeopleStr = doc.xpath("//div[@id='blank']/div[1]").text

if numPeopleStr.include? QUERY_LIMIT_EXCEEDED
	abort(QUERY_LIMIT_EXCEEDED)
elsif numPeopleStr.include? NO_MATCHED
	abort(NO_MATCHED)
else
	numPeople = numPeopleStr.match(/[0-9]+/)[0].to_i
end

i = 0
doc.xpath("//div[@id='blank']/table[1]/tr").each{ |x|
	i += 1
	if i != 1 && i!=numPeople+2
		puts "#{$i}========================="

		url = parse(x.xpath("td[1]/a[1]/@href").first)

		# Simple Data #
		if options[:simple] 
			name = parse(x.xpath("td[1]/b").text)
			email = parse(x.xpath("td[1]/a[2]/@href").first).sub("mailto:", "")
			phone = parse(x.xpath("td[2]").text)
			address = parse(x.xpath("td[3]").text)

			if name and name.length > 0; puts name end
			if email and email.length > 0; puts email; end
			if phone and phone.length > 0; puts phone; end
			if address and address.length > 0; puts address; end

		# Advanced Data #
		elsif options[:advanced]
			page = agent.get(url)
			doc = page.parser
			data = doc.xpath("//div[@id='blank']/div[2]/table[1]/tr[2]/td[1]/table[1]/tr")

			person = Hash.new()
			(1..10).each { |y|
				if data[y] != nil and data[y].text =~ /(.*): (.*)/
					person[$1] = $2
				end
			}
			pp person
		end
	end
}

puts "Time elapsed: #{Time.now - beginning} seconds."






####################################################################################################

=begin

  #<Mechanize::Form
   {name "phadv"}
   {method "POST"}
   {action "http://directory.northwestern.edu/?a=1"}
   {fields
    [hidden:0x3fbfde028ab8 type: hidden name: form_type value: advanced]
    [text:0x3fbfde028658 type: text name: name value: ]
    [text:0x3fbfde02ceb0 type: text name: email value: ]
    [text:0x3fbfde02c938 type: text name: phone value: ]
    [text:0x3fbfde02c3ac type: text name: netid value: ]
    [text:0x3fbfde02b95c type: text name: first_name value: ]
    [text:0x3fbfde0315c8 type: text name: last_name value: ]
    [text:0x3fbfde0312d0 type: text name: department value: ]
    [hidden:0x3fbfde030f24 type: hidden name: a value: 1]}
   {radiobuttons
    [radiobutton:0x3fbfde028180 type: radio name: affiliations value: ]
    [radiobutton:0x3fbfde027ba4 type: radio name: affiliations value: student]
    [radiobutton:0x3fbfde003934 type: radio name: affiliations value: employee]
    [radiobutton:0x3fbfde00340c type: radio name: affiliations value: organization]}
   {checkboxes}
   {file_uploads}
   {buttons [submit:0x3fbfde030b78 type: submit name: doit value: Query]}>}>	
=end


#http://directory.northwestern.edu/?pq=name%3datul&a=1
#http://directory.northwestern.edu/?pq=email%3Datuljohri2015&a=1

####################################################################################################

require 'crawler_rocks'
require 'json'
require 'iconv'
require 'pry'

class FengChiaUniversityCrawler

	def initialize year: nil, term: nil, update_progress: nil, after_each: nil

		@year = year-1911
		@term = term
		@update_progress_proc = update_progress
		@after_each_proc = after_each

		@query_url = 'http://sdsweb.oit.fcu.edu.tw/coursequest/condition.jsp'
		@ic = Iconv.new('utf-8//IGNORE//translit', 'big5')
	end

	def courses
		@courses = []

		r = RestClient.post(@query_url, {
			"userID" => "guest",
			"userPW" => "guest",
			"Button2" => "%B5n%A4J",
			})

		@query_url = "http://sdsweb.oit.fcu.edu.tw/coursequest/advancelist.jsp"
		r = RestClient.post(@query_url, {
			"yms_year" => "#{@year}",
			"yms_smester" => "#{@term}",
			"week" => "0",
			"start" => "0",
			"end" => "0",
			"submit1" => "%ACd++%B8%DF",
			}, {"Cookie" => "JSESSIONID=#{r.cookies["JSESSIONID"]}"})
		doc = Nokogiri::HTML(@ic.iconv(r))

		doc.css('table tr:not(:first-child)').each do |tr|
			data = []
			for i in 0..tr.css('td').count - 1
				data[i] = tr.css('td')[i].text
			end

			course = {
				year: @year,
				term: @term,
				general_code: data[0],
				name: data[1],
				department_term: data[2],
				credits: data[3],
				mid_exam: data[4],
				final_exam: data[5],
				exam_early: data[6],
				department: data[7],
				day: data[8],
				limit_people: data[9],
				course_type: data[10],
				note: data[11],
				}

			@after_each_proc.call(course: course) if @after_each_proc

			@courses << course
		end
		# binding.pry
		@courses
	end

end

# crawler = FengChiaUniversityCrawler.new(year: 2015, term: 1)
# File.write('courses.json', JSON.pretty_generate(crawler.courses()))

require 'selenium-webdriver'

class Coffee
	attr_reader :name, :id, :intensity, :price, :url

	def initialize **args
		@name = args[:name].to_s
		@id = args[:id].to_i
		@intensity = args[:intensity].to_i
		@price = args[:price].to_f
		@url = args[:url].to_s
	end

	def self.import s
		unless !!(s =~ (/^;.+;\d{1,2};\d{1,2};\d{1,2}\.\d{1,2};https:\/\/nespresso.co.il\/(?:.+);$/))
			throw ArgumentError, "Invalid coffee export code" 
		end

		a = s[1..-1].split(';')
		return Coffee.new(name: a[0], id: a[1], intensity: a[2], price: a[3], url: a[4])
	end

	def par_eql? coffee
		throw TypeError unless coffee.class == Coffee

		arr1 = self.to_h
		arr2 = coffee.to_h

		positive_match, negative_match = nil

		arr1.each do |k1, v1|
			arr2.each do |k2, v2|
				if k1 == k2 && v1 == v2
					positive_match = true
				elsif k1 == k2 && v1 == (v2 || "" || 0)
					negative_match = true
				end
			end
		end

		if positive_match && !negative_match
			return true
		else
			return false
		end
	end

	def name= name
		@name = name.to_s
	end

	def id= id
		@id = id.to_i
	end

	def intensity= intensity
		@intensity = intensity.to_i
	end

	def price= price
		@price = price.to_f
	end

	def url= url
		@url = url.to_s
	end

	def to_s
		"#{@name.reverse} ~ intensity: #{@intensity}, price: #{@price}, id: #{@id}, url: #{@url.slice! 'https://nespresso.co.il'}"
	end

	def to_h
		return {name: @name, id: @id, intensity: @intensity, price: @price, url: @url}
	end

	def export
		";#{@name};#{@id};#{@intensity};#{@price};#{@url};"
	end
end
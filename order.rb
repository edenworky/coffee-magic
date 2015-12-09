require_relative 'coffee'

class Order
	attr_reader :order

	def initialize coffees = {}
		@order = coffees
	end

	def self.import s
		throw ArgumentError, "Invalid order export code" unless !!(s =~ (/^\{.*}$/))
		return Order.new(Hash[eval(s).collect{|k,v| [Coffee.import(k), v]}])
	end

	def [] i
		throw TypeError unless i.class == Fixnum
		return @order.keys[i]
	end

	def search_by args={}
		matches = []
		c1 = Coffee.new

		if args[:coffee]
			c1 = args[:coffee]
		else
			c1.name = args[:name]
			c1.id = args[:id].to_i
			c1.intensity = args[:intensity].to_i
			c1.price = args[:price].to_f
			c1.url = args[:url]
		end

		@order.keys.each do |c2|
			matches << c2 if c1.par_eql? c2
		end

		return matches
	end

	def is_empty?
		@order.length < 1
	end

	def add coffee, amount=0
		if coffee.kind_of? Coffee
			@order.store coffee, amount
		else
			raise TypeError, "Argument is not a coffee"
		end
	end

	def remove args, amount
		if @order.length > 0
			should_remove = nil

			@order.keys.each do |k|
				should_remove = k if k.par_eql? == Coffee.new(args)
			end

			raise ArgumentError, "No order for this ID found" unless should_remove

			@order[should_remove] -= amount
			
			@order.delete should_remove if @order[should_remove] <= 0
		end			
	end

	def total_capsules
		amount = 0
		
		if @order.length > 0
			@order.values.each do |v|
				amount += v * 10
			end
		end

		return amount
	end

	def total_cost
		price = 0

		if @order.length > 0
			@order.each do |k, v|
				price += k.price * v
			end
		end

		return price
	end

	def to_s
		s = ""

		if @order.length > 0
			@order.each do |k, v|
				s << "#{v} -- #{k.to_s}\n"
			end

			s << "\nTotal of #{total_capsules} capsules for #{total_cost} ILS."
		else
			s << "Empty order."
		end

		return s
	end

	def export
		return Hash[@order.collect{|k,v| [k.export, v]}].to_s
	end

	def export! filename='default'
		File::write "#{filename}.order", Hash[@order.collect{|k,v| [k.export, v]}].to_s
end
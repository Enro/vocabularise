
module VocabulariSe
	class RequestHandler

		# six hours
		DURATION_SHORT = :short
		# two days
		DURATION_NORMAL = :normal
		# seven week
		DURATION_LONG = :long

		#inspired by YARD::Handlers::Base
		# cf https://github.com/lsegal/yard/blob/master/lib/yard/handlers/base.rb

		class << self
			def clear_subclasses
				@@subclasses = []
			end

			def subclasses
				@@subclasses ||= []
			end

			def inherited subclass
				@@subclasses ||= []
				@@subclasses << subclass
			end

			def handles *matches
				(@handlers ||= []).push(*matches)
			end

			def handles? handle
				@handlers.include? handle
				#raise NotImplementedError, "override #handles? in a subclass"
			end

			def cache_result duration
				mod = Module.new
				mod.send(:define_method, :cache_duration, Proc.new { duration })
				include mod
			end

			def no_cache_result
				mod = Module.new
				mod.send(:define_method, :cache_duration, Proc.new { 0 })
				include mod
			end

			def handlers
				@handlers ||= []
			end

			def process &block
				mod = Module.new
				mod.send(:define_method, :process, &block)
				include mod
			end


		end

		def initialize config, crawler 
			@config = config
			@crawler = crawler
			@store_result ||= false
		end

		def cache_duration
			raise NotImplementedError, "#{self} did not implement a #store_result method for handling."
		end

		def process handle, query, priority
			raise NotImplementedError, "#{self} did not implement a #process method for handling."
		end

	end

end 

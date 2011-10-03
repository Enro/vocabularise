

require 'dm-core'
require 'dm-validations'

module VocabulariSe

	# a queue entry
	class CrawlerQueueEntry
		include DataMapper::Resource

		property :id, Serial
		property :cquery,   String, :unique_index => :u1
		property :handler, String, :unique_index => :u1
		property :priority, Integer, :default => 0
		property :created_at, Integer, :required => true                        

		validates_uniqueness_of :cquery, :scope => :handler
	end

	class CrawlerQueue
		#
		# FIXME: do something for priority

		class EmptyQueueError < RuntimeError ; end


		def initialize

		end

		def include? handler, query
			req = {
				:handler => handler,
			   	:cquery => query
			}
			resp = CrawlerQueueEntry.first req
			return (not resp.nil?)
		end


		def push handler, query, priority=nil
			CrawlerQueueEntry.transaction do
				now = Time.now
				req_find = {
					:handler => handler,
					:cquery => query
				}
				req_create = {
					:handler => handler,
					:cquery => query,
					:created_at => now.to_i
				}
				req_create[:priority] = priority.to_i unless priority.nil?
				resp = CrawlerQueueEntry.first_or_create req_find, req_create
				resp.save
			end
		end


		def first
			req = { 
				:order => [:priority.desc, :created_at.asc, :id.asc]
			}
			resp = CrawlerQueueEntry.first req
			return resp.handler, resp.cquery, resp.priority
		end


		def shift
			req = { 
				:order => [:priority.desc, :created_at.asc, :id.asc]
			}
			resp = CrawlerQueueEntry.first req
			if resp then resp.destroy
			else raise EmptyQueueError
			end
			return self
		end


		def pop
			handler, query, priority = nil, nil, nil
			CrawlerQueueEntry.transaction do
				handler, query, priority = self.first
				shift
			end
			return handler, query, priority
		end

		def each &blk
			now = Time.now
			resp = CrawlerQueueEntry.all
			resp.each do |x| 
				yield x 
			end
			raise RuntimeError
		end

		def empty!
			CrawlerQueueEntry.transaction do
				resp = CrawlerQueueEntry.all
				resp.each { |x| x.destroy }
			end
		end

		def empty?
			return (size == 0)
		end

		def size
			return CrawlerQueueEntry.count
		end
	end
end

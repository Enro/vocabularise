
require 'wikipedia'

require 'vocabularise/wikipedia_handler'
require 'vocabularise/mendeley_handler'
require 'vocabularise/request_handler'

module VocabulariSe

	HANDLE_INTERNAL_RELATED_TAGS = "internal:related_tags"
	HANDLE_INTERNAL_RELATED_TAGS_MENDELEY = "internal:related_tags:mendeley"
	HANDLE_INTERNAL_RELATED_TAGS_WIKIPEDIA = "internal:related_tags:wikipedia"

	HANDLE_INTERNAL_RELATED_DOCUMENTS = "internal:related_docs"


	#
	#
	#
	class InternalRelatedTags < RequestHandler

		handles HANDLE_INTERNAL_RELATED_TAGS
		cache_result DURATION_NORMAL

		# @arg "tag" (mandatory)
		# @arg "limit" (optional)
		process do |handle, query, priority|
			@debug = true
			rdebug "handle = %s, query = %s, priority = %s " % \
				[ handle, query.inspect, priority ]
			raise ArgumentError, "no 'tag' found" unless query.include? 'tag'
			intag = query['tag']
			raise ArgumentError, "'tag' must not be nil" if intag.nil?
			inlimit = query['limit'].to_i
			inlimit ||= 0

			tags = Hash.new 0

			rdebug "try mendeley"
			# try mendeley
			if tags.empty? then
				mendeley_related = @crawler.request \
					HANDLE_INTERNAL_RELATED_TAGS_MENDELEY,
					{ "tag" => intag, "limit" => inlimit }

				tags.merge!( mendeley_related ) do |key,oldval,newval|
					oldval + newval
				end
			end
			rdebug tags.inspect

			rdebug "try wikipedia"
			# try wikipedia
			if tags.empty? then
				wikipedia_related = @crawler.request \
					HANDLE_INTERNAL_RELATED_TAGS_WIKIPEDIA,
					{ "tag" => intag, "limit" => inlimit }

				# backup for broken cache
				if wikipedia_related.kind_of? Array then
					wikipedia_related = Hash[*wikipedia_related.collect { |t|
						[t, 1]
					}.flatten]
				end

				tags.merge!( wikipedia_related ) do |key,oldval,newval|
					oldval + newval
				end
			end
			# or fail

			# FIXME: cleanup common tags
			tags.delete(intag)
			rdebug "result tags = %s" % tags.inspect
			return tags
		end
	end


	#
	#
	#
	class InternalRelatedTagsMendeley < RequestHandler

		handles HANDLE_INTERNAL_RELATED_TAGS_MENDELEY
		cache_result DURATION_NORMAL

		process do |handle, query, priority|
			@debug = true
			rdebug "handle = %s, query = %s, priority = %s " % \
				[ handle, query.inspect, priority ]
			raise ArgumentError, "no 'tag' found" unless query.include? 'tag'
			intag = query['tag']
			raise ArgumentError, "'tag' must not be nil" if intag.nil?
			inlimit = query['limit'].to_i
			inlimit ||= 0

			tags = Hash.new 0

			# may fail
			documents = @crawler.request \
				HANDLE_MENDELEY_DOCUMENT_SEARCH_TAGGED,
				{ "tag" => intag, "limit" => inlimit }

			documents.each do |doc|
				document_tags = doc.tags
				rdebug "Merge document tags"
				rdebug "common tags : %s" % tags.inspect
				rdebug "   doc tags : %s" % document_tags.inspect
				document_tags.each do |tag|
					words = tag.split(/\s+/)
					if words.length > 1 then
						words.each { |w| tags[w] += 1 }
					else
						tags[tag] += 1
					end
				end
				rdebug "merged tags : %s" % tags.inspect
			end

			# FIXME: cleanup mendeley-specific tags
			# remove tags with non alpha characters
			tags.keys.each do |tag|
				tags.delete(tag) if tag.strip =~ /:/ ;
			end
			return tags
		end
	end


	#
	#
	#
	class InternalRelatedTagsWikipedia < RequestHandler

		handles HANDLE_INTERNAL_RELATED_TAGS_WIKIPEDIA
		cache_result DURATION_NORMAL

		# @arg "tag" (mandatory)
		# @arg "limit" (optional)
		process do |handle, query, priority|
			@debug = true
			rdebug "handle = %s, query = %s, priority = %s " % \
				[ handle, query.inspect, priority ]
			raise ArgumentError, "no 'tag' found" unless query.include? 'tag'
			intag = query['tag']
			raise ArgumentError, "'tag' must not be nil" if intag.nil?
			inlimit = query['limit'].to_i
			inlimit ||= 0
			# FIXME: do something with limit

			rdebug "intag = %s" % intag
			tags = Hash.new 0

			page_json = @crawler.request \
				HANDLE_WIKIPEDIA_REQUEST_PAGE,
				{ "page" => intag }

			page = Wikipedia::Page.new page_json
			return tags if page.nil? 
			return tags if page.links.nil? 

			page.links.each do |tag|
				# prevent modification on a frozen string
				ftag = tag.dup

				# cleanup wikipedia semantics for links categories
				ftag.gsub!(/ \(.*\)$/,'')
				tags[ftag] += 1
			end				

			return tags
		end
	end


	#
	#
	#
	class InternalRelatedDocuments < RequestHandler
		handles HANDLE_INTERNAL_RELATED_DOCUMENTS
		cache_result DURATION_NORMAL

		# @arg "tag" (mandatory)
		# @arg "limit" (optional)
		process do |handle, query, priority|
			@debug = true
			rdebug "handle = %s, query = %s, priority = %s " % \
				[ handle, query.inspect, priority ]
			raise ArgumentError, "no 'tag_list' found" unless query.include? 'tag_list'
			tag_list = query['tag_list']

			rdebug "tag_list = %s" % tag_list

			documents = []
			tag_list.each do |tag|
				rdebug "current tag = %s" % tag_list
				tag_docs = @crawler.request HANDLE_MENDELEY_DOCUMENT_SEARCH_TAGGED,
					{ "tag" => tag }

				if documents.empty? then
					documents = tag_docs
				else
					documents = documents.select{ |doc| tag_docs.include? doc }
				end
				#rdebug "documents = %s" % documents.inspect
			end
			return documents
		end
	end
end

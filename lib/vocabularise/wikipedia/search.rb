
require 'open-uri'

module VocabulariSe ; module Wikipedia
	#
	# A simple mixin adding Search request to Wikipedia class from
	# wikipedia-client gem
	#
	module Search

		# http://en.wikipedia.org/w/api.php?action=query&list=search&srsearch=decibel%20AND%20sound
		def search( expr, options = {} )
			request( {                                                                
				:action => "query",                                            
				:list => "search",
				:srsearch => expr
			}.merge( options ) )
		end
	end

end ; end

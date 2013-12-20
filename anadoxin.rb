require 'xmlrpc/client'
require 'optparse'

class AdxRpcClient
	def initialize(user,pass)
		@user = user
		@pass = pass
		@conn = XMLRPC::Client.new("anadoxin.org", "/blog/xmlrpc.php")
	end

	def request(funcname, *args)
		@conn.call(funcname, @user, @pass, *args)
	end

	def rawRequest(funcname, *args)
		@conn.call(funcname, args)
	end
end

class ListAction
	def initialize(rpc, options)
		@rpc = rpc
		@options = options
	end

	def getComments()
		scope = @options[:commentScope]
		count = @options[:count]
		offset = @options[:offset]

		scope = 'all' if not scope or (scope != 'approved' && scope != 'unapproved')

		data = @rpc.request("a1.commentControl", "list", scope, count, offset)
		raise RuntimeError if not data

		data
	end

	def listComments()
		data = getComments()

		if @options[:printIds]
			listCommentsDumpIds(data)
		else
			listCommentsNormal(data)
		end
	end

	def listCommentsDumpIds(data)
		puts(data["data"].map { |item| item["cid"] }.join(','))
	end

	def listCommentsNormal(data)
		puts("Comments: #{data['count']}")
		data["data"].each do |item|
			puts("Comment ID: #{item["cid"]}, subject: '#{item["subject"]}'")
		end
	end

	def listPosts()
	end

	def list()
		domain = @options[:domain]
		return listComments if domain == 'comment'
		return listPosts if domain == 'post'
		raise RuntimeError
	end
end

class RemoveAction
	def initialize(rpc, options)
		@rpc = rpc
		@options = options
		@list = ListAction.new(rpc, options)
	end

	def remove()
		if @options[:domain] == 'comment'
			return removeListedComments() if not @options[:id]
			return removeProvidedComments() if @options[:id]
			raise RuntimeError
		else
			raise RuntimeError
		end
	end

	def removeListedComments()
		data = @list.getComments()

		data["data"].each do |item|
			id = item["cid"].to_i
			data = @rpc.request("a1.commentRemove", item["cid"].to_i)
			if data["ret"] == true and data["id"].to_i == id
				puts("Removed comment #{id}.")
			else
				puts("Error removing comment #{id}.")
			end
		end
	end

	def removeProvidedComments()
		raise RuntimeError
	end
end

require_relative 'creds'

options = {
	:action => nil,
	:domain => nil,
	:count => 10,
	:offset => 0,
	:printIds => false
}

optparse = OptionParser.new do |opts|
	opts.on('-l', '--list', 'Action: List') do |v|
		options[:action] = 'list'
	end

	opts.on('--print-ids', 'Print only IDs (for pasting purposes)') do |v|
		options[:printIds] = true
	end

	opts.on('-r', '--remove=id', 'Action: Remove') do |id|
		options[:action] = 'remove'
		options[:id] = id
	end

	opts.on('--remove-listed', 'Action: Remove') do |d|
		options[:action] = 'remove'
		options[:id] = nil
	end

	opts.on('-a', '--approve=id', 'Action: Approve') do |id|
		options[:action] = 'approve'
		options[:id] = id
	end

	opts.on('-c', '--comment', 'Domain: comments') do |v|
		options[:domain] = 'comment'
	end

	opts.on('--unapproved', 'Process only unapproved comments') do |v|
		options[:commentScope] = 'unapproved'
	end

	opts.on('--approved', 'Process only approved comments') do |v|
		options[:commentScope] = 'approved'
	end

	opts.on('--count=count', 'Get <count> items') do |c|
		options[:count] = c.to_i
	end

	opts.on('--offset=offset', 'Offset <offset>') do |offset|
		options[:offset] = offset.to_i
	end

	opts.on('-i', '--ids=range', 'Argument: id range') do |range|
		options[:range] = range
	end
end

optparse.parse!($*)
rpc = AdxRpcClient.new(USERNAME, PASSWORD)

if options[:action] == 'list'
	lister = ListAction.new(rpc, options)
	exit(true == lister.list ? 0 : 1)
elsif options[:action] == 'remove'
	remover = RemoveAction.new(rpc, options)
	exit(true == remover.remove ? 0 : 1)
end

=begin
exit(0)

server = XMLRPC::Client.new("anadoxin.org", "/blog/xmlrpc.php")

if options[:action] == 'list'
	if options[:domain] == 'comment'
		if options[:commentScope] == 'unapproved'
			scope = 'unapproved'
		elsif options[:commentScope] == 'approved'
			scope = 'approved'
		else
			scope = 'all'
		end

		data = server.call("a1.commentControl", USERNAME, PASSWORD, "list", scope, options[:count].to_i, options[:offset].to_i)
		if not options[:printIds]
			puts("Comments: #{data['count']}")
			data["data"].each do |item|
				puts("Comment ID: #{item["cid"]}, subject: '#{item["subject"]}'")
			end
		else
			puts(data["data"].map { |item| item["cid"] }.join(','))
		end
	else
		puts("Unknown domain in 'list' option!")
	end
elsif options[:action] == 'remove'
	options[:id].split(',').each do |id|
		next if id.size == 0

		data = server.call("a1.commentRemove", USERNAME, PASSWORD, id.to_i)
		if data['ret'] == true and data['id'].to_i == id.to_i
			puts("Removed comment #{id}.")
		else
			puts("Error removing comment #{id}.")
			puts(data.inspect)
		end
	end
elsif options[:action] == 'approve'
	options[:id].split(',').each do |id|
		next if id.size == 0
		data = server.call("a1.commentApprove", USERNAME, PASSWORD, id.to_i)
		if data['ret'] == true and data['id'].to_i == id.to_i
			puts("Approved comment #{id}.")
		else
			puts("Error approving comment #{id}.")
			puts(data.inspect)
		end
	end
else
	puts("Unknown action!")
end

exit(0)
#result = server.call("local.testMethod", "teststr")
#
#result.each do |item|
#	puts("Comment ID: #{item['cid']}")
#	puts("Comment subject: '#{item['subject']}'")
#	puts("Comment body:")
#	puts(item['body'])
#	puts("-- ")
#	print("(A)ccept, (I)gnore, (R)emove? ")
#	break
#end
=end

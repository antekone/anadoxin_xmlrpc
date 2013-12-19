require 'xmlrpc/client'
require 'optparse'

require_relative 'creds'

options = {
	:action => nil,
	:domain => nil,
	:count => 1,
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
		options[:count] = c
	end

	opts.on('--offset=offset', 'Offset <offset>') do |offset|
		options[:offset] = offset
	end

	opts.on('-i', '--ids=range', 'Argument: id range') do |range|
		options[:range] = range
	end
end

optparse.parse!($*)

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

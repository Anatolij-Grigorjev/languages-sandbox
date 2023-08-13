## blobs sync divider job

NUM_KEYS_PER_SYNC = 3

def perform(before_time)
	raise ArgumentError, 'time limit not specified as arg!' unless before_time

	Logger.debug("Starting dividing blobs older than #{before_time} into jobs at #{Time.utc.now}")

	flat_list = localized_blob_keys(before_time)
	Logger.debug("fetched #{flat_list.size} records from before #{before_time}")
	service_groups = grouped_by_service(flat_list)
	Logger.debug("""
		divided blob keys into groups:
		#{service_groups.map { |service_name, keys| "service #{service_name}: #{keys.size} blobs\n" }}
	""")
	chunked_service_groups = chunk_service_groups(service_groups)
	Logger.debug("""
		sending sync jobs to queue:
		#{chunked_service_groups.map { |service_name, chunked_keys| "service #{service_name}: #{chunked_keys.size} jobs\n" }}
		""")
	total_jobs = 0
	chunked_service_groups.each do |service_name, keys_sets|
		keys_sets.each do |keys_set|
			BlobSyncJob.perform_async(service_name, keys_set)
			total_jobs += 1
		end
	end
	Logger.debug("Finished putting #{total_jobs} sync jobs on queue at #{Time.utc.now}")
end

private

def localized_blob_keys(before_time)
	ActiveRecord::Blob
	.where('created_at < ?', before_time)
	.pluck(:key, :service_name)
end

def grouped_by_service(flat_list)
	flat_list
	.group_by { |key_service_pair| key_service_pair[1] }
	.map { |service, pairs_list| [service, pairs_list.map(&:first)] }
	.to_h
end

def chunk_service_groups(service_groups)
	service_groups
	.map { |service, keys| [service, keys.each_slice(NUM_KEYS_PER_SYNC).to_a] }
	.to_h
end



## BlobSyncJob

SOURCE_SERVICE = :ceph_failover

def perform(service_name, blob_keys)
	source_service = ActiveStorage::Blob.services.fetch(SOURCE_SERVICE)
	destination_service = ActiveStorage::Blob.services.fetch(service_name.to_sym)
	source_service.bucket = destination_service.bucket
	runners = []
	blob_keys.each do |key|
		runners << Thread.new do
			unless source_service.exists?(key)
				Logger.debug("Did not find blob #{key} in #{source_service.endpoint}")
				return
			end
			source_service.open(key) do |file|
				destination_service.upload(key, file)
				Logger.debug("Uploaded blob #{key} to #{destination_service.endpoint}")
			end
		end
	end
	runners.map(&:join)
end
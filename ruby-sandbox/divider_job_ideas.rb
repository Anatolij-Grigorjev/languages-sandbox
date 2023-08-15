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
	.pluck(:service_name, :key, :checksum)
end

def grouped_by_service(flat_list)
	flat_list
	.group_by { |service_key_checksum| service_key_checksum.first }
	.map { |service, blob_tuples| [service, blob_tuples.map { |tuple| tuple.slice(1..2) } ] }
	.to_h
end

def chunk_service_groups(service_groups)
	service_groups
	.map { |service, key_checksum| [service, key_checksum.each_slice(NUM_KEYS_PER_SYNC).to_a] }
	.to_h
end


## BlobSyncJobTests
let(:source_service_config) { {} }
let(:source_service) { double(ActiveStorage::Service) }
let(:destination_service) { double(ActiveStorage::Service) }
let(:opened_file) { 'blahblah' }
let(:key) { 'key' }
let(:checksum) { '00E0' }
allow(Rails.active_storage.configs).to receive(:[]).with(SOURCE_SERVICE).and_return(source_service_config)
allow(Aws::S3Service).to receive(:new).and_return(source_service)
allow(ActiveStorage::Blob.services).to receive(:fetch).with(destination).and_return(destination_service)
allow(source_service).to receive(:open).with(key, anything).and_yield(opened_file)

expect(destination_service).to receive(:upload).with(key, opened_file, hash_including(checksum: checksum))
subject

## BlobSyncJob

SOURCE_SERVICE = :ceph_failover

def perform(service_name, blob_keys_with_checksum)
	destination_service = ActiveStorage::Blob.services.fetch(service_name.to_sym)
	source_service = failover_service_with_bucket(destination_service.bucket.name)
	
	runners = []
	blob_keys_with_checksum.each do |key_checksum|
		key, checksum = *key_checksum
		runners << Thread.new do
			unless source_service.exists?(key)
				Logger.debug("Did not find blob #{key} in #{source_service.endpoint}")
				return
			end
			source_service.open(key, checksum: checksum) do |file|
				destination_service.upload(key, file, checksum: checksum)
				Logger.debug("Uploaded blob #{key} to #{destination_service.endpoint}")
			end
		end
	end
	runners.map(&:join)
end

private

def failover_service_with_bucket(bucket_name)
	failover_config = Rails.active_storage.configs[:failover]
	Aws::S3::Credentials = ...
	Aws::S3Service.new(bucket_name, failover_config)
end
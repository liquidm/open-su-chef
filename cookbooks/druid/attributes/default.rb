default[:druid][:git][:repository]                  = "https://github.com/apache/druid"
default[:druid][:git][:revision]                    = "0.19.0"


default[:druid][:core_extensions]                   = %w{
                                                        druid-datasketches
                                                        druid-hdfs-storage
                                                        druid-s3-extensions
                                                        druid-histogram
                                                        druid-kafka-indexing-service
                                                        statsd-emitter
                                                      }

default[:druid][:extensions]                        = "postgresql-metadata-storage"

default[:druid][:cluster]                           = "druid"

default[:druid][:zookeeper][:cluster]               = node[:druid][:cluster]
default[:druid][:zookeeper][:root]                  = "/druid"
default[:druid][:zookeeper][:timeout]               = 15000
default[:druid][:zookeeper][:discovery]             = "/discoveryPath"

default[:druid][:database][:type]                   = "postgresql"
default[:druid][:database][:uri]                    = "jdbc:postgresql://master.postgresql-druid.service.consul:5432/druid"
default[:druid][:database][:user]                   = "druid"
default[:druid][:database][:password]               = "diurd"

default[:druid][:hadoop][:version]                  = node[:hadoop2][:version]

default[:druid][:storage][:hdfs]                    = "hdfs://druid/indexer"

default[:druid][:cache][:numThreads]                = node[:cpu][:total]-2
default[:druid][:cache][:caffeineSize]              = 8589934592
default[:druid][:cache][:memcache_cluster]          = node.consul_dc

default[:druid][:mergeBufferSize]                   = 536870912
default[:druid][:init_heap_occupancy]               = 30
default[:druid][:heap_waste_percent]                = 10

default[:druid][:historical][:service]              = "#{node[:druid][:cluster]}/historical"
default[:druid][:historical][:tier]                 = node.consul_dc
default[:druid][:historical][:priority]             = 0
default[:druid][:historical][:port]                 = 8082
default[:druid][:historical][:nice]                 = -1
default[:druid][:historical][:oom_score]            = -1
default[:druid][:historical][:numThreads]           = node[:cpu][:total]-2
default[:druid][:historical][:numMergeBuffers]      = node[:druid][:historical][:numThreads]
default[:druid][:historical][:mergeBufferSize]      = node[:druid][:mergeBufferSize]
default[:druid][:historical][:mx]                   = "#{(0.25 * node[:druid][:historical][:numThreads]).ceil + (node[:druid][:cache][:caffeineSize]/1024/1024/1024) + 1}g"
default[:druid][:historical][:dm]                   = "#{((node[:druid][:historical][:mergeBufferSize] * (node[:druid][:historical][:numThreads] + node[:druid][:historical][:numMergeBuffers] + 1)) / 1024 / 1024 / 1024).ceil + 4}g"
default[:druid][:historical][:max_new_size]         = "#{node[:druid][:historical][:mx].to_i / 2}g"
default[:druid][:historical][:storageSize]          = 1000000000

default[:druid][:middleManager][:service]           = "#{node[:druid][:cluster]}/middleManager"
default[:druid][:middleManager][:category]          = node.consul_dc
default[:druid][:middleManager][:port]              = 8091
default[:druid][:middleManager][:nice]              = 10
default[:druid][:middleManager][:oom_score]         = 10
default[:druid][:middleManager][:worker]            = node[:cpu][:total] / 4
default[:druid][:middleManager][:numThreads]        = 3
default[:druid][:middleManager][:numMergeBuffers]   = 1
default[:druid][:middleManager][:mergeBufferSize]   = 52428800
default[:druid][:middleManager][:mx]                = "128m"
default[:druid][:middleManager][:dm]                = "#{((node[:druid][:middleManager][:mergeBufferSize] * (node[:druid][:middleManager][:numThreads] + node[:druid][:middleManager][:numMergeBuffers] + 1)) / 1024 / 1024 / 1024).ceil + 4}g"
default[:druid][:middleManager][:max_new_size]      = "#{node[:druid][:middleManager][:mx].to_i / 2}m"
default[:druid][:middleManager][:task_dir]          = "/var/app/druid/storage/tmp/middleManager/task"

default[:druid][:indexer][:service]                 = "#{node[:druid][:cluster]}/indexer"
default[:druid][:indexer][:category]                = node.consul_dc
default[:druid][:indexer][:tier]                    = node.consul_dc
default[:druid][:indexer][:port]                    = 8072
default[:druid][:indexer][:nice]                    = -2
default[:druid][:indexer][:oom_score]               = -2
default[:druid][:indexer][:worker]                  = node[:cpu][:total] / 2
default[:druid][:indexer][:numThreads]              = node[:cpu][:total] / 2
default[:druid][:indexer][:mergeBufferSize]         = node[:druid][:mergeBufferSize]
default[:druid][:indexer][:numMergeBuffers]         = node[:druid][:indexer][:numThreads]
default[:druid][:indexer][:mx]                      = "#{node[:druid][:indexer][:numThreads] + (node[:druid][:cache][:caffeineSize]/1024/1024/1024)}g"
default[:druid][:indexer][:dm]                      = "#{((node[:druid][:indexer][:mergeBufferSize] * (node[:druid][:indexer][:numThreads] + node[:druid][:indexer][:numMergeBuffers] + 1)) / 1024 / 1024 / 1024).ceil + 4}g"
default[:druid][:indexer][:max_new_size]            = "#{node[:druid][:indexer][:mx].to_i / 2}m"
default[:druid][:indexer][:task_dir]                = "/var/app/druid/storage/tmp/indexer/task"

default[:druid][:coordinator][:service]             = "#{node[:druid][:cluster]}/coordinator"
default[:druid][:coordinator][:overlord_service]    = node[:druid][:cluster]
default[:druid][:coordinator][:port]                = 8081
default[:druid][:coordinator][:nice]                = -3
default[:druid][:coordinator][:oom_score]           = -3
default[:druid][:coordinator][:mx]                  = "24g"
default[:druid][:coordinator][:dm]                  = "128m"
default[:druid][:coordinator][:max_new_size]        = "5g"
default[:druid][:coordinator][:numThreads]          = 2

default[:druid][:broker][:service]                  = node[:druid][:cluster]
default[:druid][:broker][:port]                     = 8080
default[:druid][:broker][:tier]                     = "highestPriority"
default[:druid][:broker][:nice]                     = -3
default[:druid][:broker][:oom_score]                = -3
default[:druid][:broker][:numThreads]               = [6, node[:cpu][:total]].min
default[:druid][:broker][:numMergeBuffers]          = node[:druid][:broker][:numThreads]
default[:druid][:broker][:mergeBufferSize]          = node[:druid][:mergeBufferSize]
default[:druid][:broker][:mx]                       = "#{node[:druid][:broker][:numThreads] + (node[:druid][:cache][:caffeineSize]/1024/1024/1024) + 1}g"
default[:druid][:broker][:dm]                       = "#{((node[:druid][:broker][:mergeBufferSize] * (node[:druid][:broker][:numThreads] + node[:druid][:broker][:numMergeBuffers] + 1)) / 1024 / 1024 / 1024).ceil + 1}g"
default[:druid][:broker][:max_new_size]             = "#{node[:druid][:broker][:mx].to_i / 2}m"

default[:druid][:router][:service]                  = "#{node[:druid][:cluster]}/router"
default[:druid][:router][:port]                     = 8070
default[:druid][:router][:nice]                     = 3
default[:druid][:router][:oom_score]                = 3
default[:druid][:router][:mx]                       = "1g"
default[:druid][:router][:dm]                       = "128m"
default[:druid][:router][:max_new_size]             = "128m"
default[:druid][:router][:numThreads]               = 1

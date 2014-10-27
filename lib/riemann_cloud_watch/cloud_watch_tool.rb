module Riemann
  class CloudWatchMetric
    attr_reader :name, :dimensions, :timestamp, :stat_type, :unit, :value, :opts
    
    def initialize(name, dimensions, stat_type, timestamp, value, opts = {})
      @name = name
      @dimensions = dimensions
      @stat_type = stat_type
      @timestamp = timestamp
      @value = value
      @opts = opts
    end
  end

  module CloudWatchTool

    require 'riemann/tools'
            
    def self.included(base)
      
      base.send :include, Riemann::Tools

      require 'fog'
      require 'time'

      base.instance_eval do
        opt :fog_credentials_file, "Fog credentials file", :type => String
        opt :fog_credential, "Fog credentials to use", :type => String, :default => 'default'
        opt :aws_access, "AWS Access Key", :type => String
        opt :aws_secret, "AWS Secret Key", :type => String
        opt :aws_region, "AWS Region", :type => String, :default => "eu-west-1"
        opt :include_metrics, "Only query these metrics", :type => :strings
        opt :delay, "Query this many seconds behind", :type => Integer, :default => 60
  
        def metrics(metrics)
         @all_metrics=metrics        
        end
        
        def all_metrics
          @all_metrics
        end
        
        def aws_namespace(namespace)
          @namespace=namespace
        end

        def namespace
          @namespace
        end
                      
        def generates_riemann_event(&block)
          raise "no block specified riemann_event" unless block_given?
          @riemann_event = Proc.new
        end
        
        def riemann_event
          @riemann_event
        end
      end
    end
    
      
    def selected_metrics
      self.class.all_metrics.select {|k,v| options[:include_metrics].nil? || options[:include_metrics].include?(k) }
    end
    
    def next_time_block
      now = Time.now.utc
      @start_time = @end_time.nil? ? (now - options[:interval] - options[:delay]) : @end_time
      @end_time = now - options[:delay]
    end
  
    def metric_base
      # every options[:interval] seconds, collect options[:interval] seconds worth of data
            
      # start_time = (Time.now.utc - options[:interval]).iso8601
      # end_time = Time.now.utc.iso8601      
      
      # The base query that all metrics would get
      {
        "Namespace" => self.class.namespace,
        "StartTime" => @start_time.iso8601,
        "EndTime" => @end_time.iso8601,
        "Period" => 60,
      }
    end
    
    def connection_params
      if options[:fog_credentials_file]
        Fog.credentials_path = options[:fog_credentials_file]
        Fog.credential = options[:fog_credential].to_sym
        { :region => options[:aws_region] }
      elsif options[:aws_access_key_id] && options[:aws_secret_access_key_id]
        {
          :aws_access_key_id => options[:aws_access],
          :aws_secret_access_key => options[:aws_secret],
          :region => options[:aws_region]
        }
      else 
        { :use_iam_profile => true, :region => options[:aws_region] }
      end
    end
    
    def connection
      @connection ||= Fog::AWS::CloudWatch.new connection_params
    end
    
    def dimensions(opts)
      opts[:dimensions] || []
    end
    
    def cw_dimensions(opts)
      (dimensions(opts)).map do |key, value|
        { "Name" => key, "Value" => value }        
      end              
    end
    
    def merged_options(metric_type, opts)
      merged_options = metric_base.merge(self.class.all_metrics[metric_type])
      merged_options["MetricName"] = metric_type
      merged_options["Dimensions"] = cw_dimensions(opts)
      merged_options
    end
  
    def send_metrics(opts = {}) 
      selected_metrics.keys.sort.each do |metric_type|
        
        request = merged_options(metric_type, opts)        
        result = connection.get_metric_statistics(request)

        # Maybe we didn't get any data
        next if result.body["GetMetricStatisticsResult"]["Datapoints"].empty?

        # Expect multiple data points
        result.body["GetMetricStatisticsResult"]["Datapoints"].sort { |a,b| a['Timestamp'] <=> b['Timestamp']}.each do |datapoint|
          unit      = datapoint["Unit"]
          timestamp = datapoint["Timestamp"].to_i

          datapoint.keys.sort.each do |stat_type|
            next if stat_type == "Unit" || stat_type == "Timestamp" 

            metric_value = datapoint[stat_type]
            
            metric = CloudWatchMetric.new metric_type, dimensions(opts), stat_type, timestamp, metric_value, (opts[:opts] || {})
            event = instance_exec(metric, &self.class.riemann_event) 
            
            #puts "#{event.inspect}"  
            report(event)
          end
        end
      end
    end
    

  end
end
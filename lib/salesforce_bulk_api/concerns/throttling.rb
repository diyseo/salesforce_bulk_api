module SalesforceBulkApi::Concerns
  module Throttling

    def throttles
      @throttles.dup
    end

    def add_throttle(&throttling_callback)
      @throttles ||= []
      @throttles << throttling_callback
    end

    def set_status_throttle(limit_seconds)
      set_throttle_limit_in_seconds(limit_seconds)
    end

    def set_throttle_limit_in_seconds(limit_seconds)
      add_throttle do |details|
        limit_log = get_limit_log(Time.now - limit_seconds)
        key = extract_constraint_key_from(details, [:http_method, :path])
        last_request = limit_log[key]

        if !last_request.nil? && details[:path] == :get
          seconds_since_last_request = Time.now.to_f - last_request.to_f
          need_to_wait_seconds = limit_seconds - seconds_since_last_request
          sleep(need_to_wait_seconds) if need_to_wait_seconds > 0
        end

        limit_log[key] = Time.now
      end
    end

    private

    def extract_constraint_key_from(details, throttle_by_keys)
      hash = {}
      throttle_by_keys.each { |k| hash[k] = details[k] }
      hash
    end

    def get_limit_log(prune_older_than)
      @limits ||= Hash.new(0)

      @limits.delete_if do |k, v|
        v < prune_older_than
      end

      @limits
    end

    def throttle(details={})
      (@throttles || []).each do |callback|
        args = [details]
        args = args[0..callback.arity]
        callback.call(*args)
      end
    end

  end
end

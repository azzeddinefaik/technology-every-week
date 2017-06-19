#
# Fluentd
#
#    Licensed under the Apache License, Version 2.0 (the "License");
#    you may not use this file except in compliance with the License.
#    You may obtain a copy of the License at
#
#        http://www.apache.org/licenses/LICENSE-2.0
#
#    Unless required by applicable law or agreed to in writing, software
#    distributed under the License is distributed on an "AS IS" BASIS,
#    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#    See the License for the specific language governing permissions and
#    limitations under the License.
#

require 'fluent/parser'
require 'socket'

module Fluent
    class LumenMultilineParser < Parser
      Plugin.register_parser('lumen_multiline', self)

      config_param :format_firstline, :string, default: nil
      config_param :time_format, :string, default: "%b %d %H:%M:%S"
      RegexpParser = Fluent::TextParser::RegexpParser
      TimeParser = Fluent::TextParser::TimeParser
      # regex to split message to get stacktrace.
      REGEXP_MSG_STCK = /Stack\strace|#0/
      # max number of format set to 20
      FORMAT_MAX_NUM = 20

      def configure(conf)
        super

        formats = parse_formats(conf).compact.map { |f| f[1..-2] }.join
        begin
          @regex = Regexp.new(formats, Regexp::MULTILINE)
          if @regex.named_captures.empty?
            raise "No named captures"
          end
          @parser = RegexpParser.new(@regex, conf)
          @time_parser = TimeParser.new(@time_format)
        rescue => e
          raise ConfigError, "Invalid regexp '#{formats}': #{e}"
        end

        if @format_firstline
          check_format_regexp(@format_firstline, 'format_firstline')
          @firstline_regex = Regexp.new(@format_firstline[1..-2])
        end
      end

      def parse(text, &block)
        #m2 = @parser.call(text, &block)
        # define records
        time = nil
        record = {}
        # match regex (all formats)
        m = @regex.match(text)
        # loop over returned value from matched regex. e.g /(?<key>.*)/  => m = [{"key"=> "MATCHED VALUE"}].
        m.names.each { |name|
          if value = m[name]
            # switch cases
            case name
            when "app_message"
             if m["level"] === 'ERROR' || m["level"] === 'WARNING' || m["level"] === 'DEBUG'
                  # split with REGEX to get stacktrace.
                  r = value.split(REGEXP_MSG_STCK,2)
                  record['app_message'] = r[0]
                  unless r[1].nil? || r[1] == 0
                    record['stack'] = r[1]
                  end
             else
                record['app_message'] = value
             end
            when "time"
              time = @mutex.synchronize { @time_parser.parse(value.gsub(/ +/, ' ')) }
              record[name] = value if @keep_time_key
            else
              record[name] = value
            end
          end
        }
       if @estimate_current_event
         time ||= Engine.now
       end
       record['host_ip'] = get_host_ip()
       record['host_name'] = get_host_name()
       yield time, record
      end

      def has_firstline?
        !!@format_firstline
      end

      def firstline?(text)
        @firstline_regex.match(text)
      end
      def get_host_ip
             ip=Socket.ip_address_list.detect{|intf| intf.ipv4_private?}
             return ip.ip_address if ip
      end
      def get_host_name
             host_name=Socket.gethostname
             return host_name
      end
      private

      def parse_formats(conf)
        check_format_range(conf)

        prev_format = nil
        (1..FORMAT_MAX_NUM).map { |i|
          format = conf["format#{i}"]
          if (i > 1) && prev_format.nil? && !format.nil?
            raise ConfigError, "Jump of format index found. format#{i - 1} is missing."
          end
          prev_format = format
          next if format.nil?

          check_format_regexp(format, "format#{i}")
          format
        }
      end

      def check_format_range(conf)
        invalid_formats = conf.keys.select { |k|
          m = k.match(/^format(\d+)$/)
          m ? !((1..FORMAT_MAX_NUM).include?(m[1].to_i)) : false

        }
        unless invalid_formats.empty?
          raise ConfigError, "Invalid formatN found. N should be 1 - #{FORMAT_MAX_NUM}: " + invalid_formats.join(",")
        end
      end

      def check_format_regexp(format, key)
        if format[0] == '/' && format[-1] == '/'
          begin
            Regexp.new(format[1..-2], Regexp::MULTILINE)
          rescue => e
            raise ConfigError, "Invalid regexp in #{key}: #{e}"
          end
        else
          raise ConfigError, "format should be Regexp, need //, in #{key}: '#{format}'"
        end
      end
    end
end
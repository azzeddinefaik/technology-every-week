  require_relative 'helper'
  require 'fluent/test'
  require 'fluent/parser'

  module ParserTest

  class LumenMultilineParserTest < ::Test::Unit::TestCase
    include Fluent

    def create_parser(conf)
      parser = Fluent::Plugin.new_parser('lumen_multiline')
      parser.configure(conf)
      parser
    end

    def test_configure_with_invalid_params
      [{'format100' => '/(?<msg>.*)/'}, {'format1' => '/(?<msg>.*)/', 'format3' => '/(?<msg>.*)/'}, 'format1' => '/(?<msg>.*)'].each { |config|
        assert_raise(ConfigError) {
          create_parser(config)
        }
      }
    end

    def test_parse
      parser = create_parser('format_firstline'=>'/(^\[(?<date>.*)\])?\s*lumen.(?<level>(ERROR|INFO|WARNING|DEBUG))?:\s(?<exception>exception)?(?<path>\s\'.*\'\s(with\smessage\s))?((with\smessage\s)?(?<message>(.*)))/','format1' => '/(^\[(?<date>.*)\])?\s*lumen.(?<level>(ERROR|INFO|WARNING|DEBUG))?:\s(?<exception>exception)?(?<path>\s\'.*\'\s(with\smessage\s))?((with\smessage\s)?(?<message>(.*)))/','format2'=>'/.*/')
      parser.parse(<<EOS.chomp) { |time, record|
[2016-05-11 09:52:34] lumen.ERROR: exception gdfgdfg with message Call to undefined method in
Stack trace:
\#0  ExceptionHandler::handleByCode(500, '{"status":500,"...')
EOS

        assert_equal(
        {"date"=>"2016-05-11 09:52:34",
          "exception"=>"exception",
          "level"=>"ERROR",
          "message"=>
            " gdfgdfg with message Call to undefined method in\nStack trace:\n",
          "stack"=>
            " ExceptionHandler::handleByCode(500, '{\"status\":500,\"...')"
         }, record)
      }

    end

    def test_parse_without_firstline
      parser = create_parser('format1' => '/(^\[(?<date>.*)\])?\s*lumen.(?<level>(ERROR|INFO|WARNING|DEBUG))?:\s(?<exception>exception)?(?<path>\s\'.*\'\s(with\smessage\s))?((with\smessage\s)?(?<message>(.*)))/','format2'=>'/.*/')
      parser.parse(<<EOS.chomp) { |time, record|
[2016-05-11 09:52:34] lumen.ERROR: exception gdfgdfg with message Call to undefined method in
Stack trace:
\#0 GuzzleHandler.php(154): Payment\ExceptionHandler::handleByCode(500, '{"status":500,"...')
EOS

      assert_equal(
      {"date"=>"2016-05-11 09:52:34",
        "exception"=>"exception",
        "level"=>"ERROR",
        "message"=>
          " gdfgdfg with message Call to undefined method in\nStack trace:\n",
        "stack"=>
          " GuzzleHandler.php(154): PaymentExceptionHandler::handleByCode(500, '{\"status\":500,\"...')"
       }, record)
    }
    end

  end
 end

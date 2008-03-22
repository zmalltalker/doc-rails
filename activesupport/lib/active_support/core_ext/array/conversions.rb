require 'builder'

module ActiveSupport #:nodoc:
  module CoreExtensions #:nodoc:
    module Array #:nodoc:
      module Conversions
        # Converts the array to a comma-separated sentence where the last element is joined by the connector word. Options:
        # * <tt>:connector</tt> - The word used to join the last element in arrays with two or more elements (default: "and")
        # * <tt>:skip_last_comma</tt> - Set to true to return "a, b and c" instead of "a, b, and c".
        def to_sentence(options = {})
          options.assert_valid_keys(:connector, :skip_last_comma)
          options.reverse_merge! :connector => 'and', :skip_last_comma => false
          options[:connector] = "#{options[:connector]} " unless options[:connector].nil? || options[:connector].strip == ''

          case length
            when 0
              ""
            when 1
              self[0].to_s
            when 2
              "#{self[0]} #{options[:connector]}#{self[1]}"
            else
              "#{self[0...-1].join(', ')}#{options[:skip_last_comma] ? '' : ','} #{options[:connector]}#{self[-1]}"
          end
        end

        # Calls <tt>to_param</tt> on all its elements and joins the result with
        # slashes. This is used by <tt>url_for</tt> in Action Pack. 
        def to_param
          map(&:to_param).join '/'
        end

        # Converts an array into a string suitable for use as a URL query string, using the given <tt>key</tt> as the
        # param name.
        #
        # ==== Example:
        #   ['Rails', 'coding'].to_query('hobbies') => "hobbies%5B%5D=Rails&hobbies%5B%5D=coding"
        def to_query(key)
          collect { |value| value.to_query("#{key}[]") } * '&'
        end

        def self.included(base) #:nodoc:
          base.class_eval do
            alias_method :to_default_s, :to_s
            alias_method :to_s, :to_formatted_s
          end
        end
        
        # Converts a collection of elements into a formatted string by calling to_s on all elements and joining them.
        # Blog.find(:all).to_formatted_s => "First PostSecond PostThird Post"
        # Adding in the :db argument as the format yields a prettier output:
        # Blog.find(:all).to_formatted_s(:db) => "First Post,Second Post,Third Post"
        def to_formatted_s(format = :default)
          case format
            when :db
              if respond_to?(:empty?) && self.empty?
                "null"
              else
                collect { |element| element.id }.join(",")
              end
            else
              to_default_s
          end
        end
        
        # Returns a string that represents this array in XML by sending
        # <tt>to_xml</tt> to each element.
        #
        # All elements are expected to respond to <tt>to_xml</tt>, if any of
        # them does not an exception is raised.
        #
        # The root node reflects the class name of the first element in plural
        # if all elements belong to the same type and that's not <tt>Hash</tt>.
        # Otherwise the root element is "records".
        #
        # Root children have as node name the one of the root singularized.
        #
        # Example:
        #
        #   [{:foo => 1, :bar => 2}, {:baz => 3}].to_xml
        #
        #   <?xml version="1.0" encoding="UTF-8"?>
        #   <records type="array">
        #     <record>
        #       <bar type="integer">2</bar>
        #       <foo type="integer">1</foo>
        #     </record>
        #     <record>
        #       <baz type="integer">3</baz>
        #     </record>
        #   </records>
        #
        # The +options+ hash is passed downwards:
        #
        #   [Message.find(:first)].to_xml(:skip_types => true)
        #
        #   <?xml version="1.0" encoding="UTF-8"?>
        #   <messages>
        #     <message>
        #       <created-at>2008-03-07T09:58:18+01:00</created-at>
        #       <id>1</id>
        #       <name>1</name>
        #       <updated-at>2008-03-07T09:58:18+01:00</updated-at>
        #       <user-id>1</user-id>
        #     </message>
        #   </messages>
        #
        def to_xml(options = {})
          raise "Not all elements respond to to_xml" unless all? { |e| e.respond_to? :to_xml }

          options[:root]     ||= all? { |e| e.is_a?(first.class) && first.class.to_s != "Hash" } ? first.class.to_s.underscore.pluralize : "records"
          options[:children] ||= options[:root].singularize
          options[:indent]   ||= 2
          options[:builder]  ||= Builder::XmlMarkup.new(:indent => options[:indent])

          root     = options.delete(:root).to_s
          children = options.delete(:children)

          if !options.has_key?(:dasherize) || options[:dasherize]
            root = root.dasherize
          end

          options[:builder].instruct! unless options.delete(:skip_instruct)

          opts = options.merge({ :root => children })

          xml = options[:builder]
          if empty?
            xml.tag!(root, options[:skip_types] ? {} : {:type => "array"})
          else
            xml.tag!(root, options[:skip_types] ? {} : {:type => "array"}) {
              yield xml if block_given?
              each { |e| e.to_xml(opts.merge!({ :skip_instruct => true })) }
            }
          end
        end

      end
    end
  end
end

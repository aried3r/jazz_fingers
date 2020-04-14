module JazzFingers
  class Prompt
    OBJECT_INSTANCE = /#<(.+)>/

    def initialize(options = {})
      @colored = options.fetch(:colored)
      @separator = options.fetch(:separator)
      @application_name = options.fetch(:application_name)
    end

    def colored?
      @colored
    end

    def red_text(text)
      return text.to_s unless colored?

      "\001\e[0;31m\002#{text}\001\e[0m\002"
    end

    def blue_text(text)
      return text.to_s unless colored?

      "\001\e[0;34m\002#{text}\001\e[0m\002"
    end

    def bold_text(text)
      return text.to_s unless colored?

      "\001\e[1m\002#{text}\001\e[0m\002"
    end

    def separator
      red_text(@separator)
    end

    # Return the current Pry context
    #
    # When the Pry context is `"main"` or `"nil"`, use the application name from
    # the JazzFingers config. Examples: "(my_rails_app_name)", "(jazz_fingers)".
    #
    # When in the context of an object instance, use the abbreviated object
    # path. Example: "(#<Pry::Prompt>)", "(#<...::ModuleName::ClassName>)"
    #
    # Fall back to the raw context provided by Pry.view_clip.
    # Example: "(Pry::Prompt)"
    def context(module_name = "main")
      name =
        case module_name
        when "main", "nil"
          @application_name
        when OBJECT_INSTANCE
          abbreviated_context(module_name)
        else
          module_name
        end

      blue_text("(#{name})")
    end

    def line_number(pry)
      if pry.respond_to? :input_ring
        bold_text(pry.input_ring.size)
      else
        bold_text(pry.input_array.size)
      end
    end

    # Abbreviate the object path for object instances to a maximum length of
    # `max_length` so the prompt doesn't overflow.
    #
    # Examples:
    #   In:  #<Class1::Class2::Class3::Class4::Class5>
    #   Out: #<...Class2::Class3::Class4::Class5>
    #
    #   In:  #<Class1::Class2>
    #   Out: #<Class1::Class2>
    #
    #   In:  #<NoPathJustASingleLongClassName>
    #   Out: #<NoPathJustASingleLongClassName>
    def abbreviated_context(object_label, max_length: 20)
      object_path = object_label[OBJECT_INSTANCE, 1]
      object_path_components = object_path.split("::")
      return object_label if object_path_components.length == 1

      object_path_length = object_path_components.map(&:length).sum
      return object_label if object_path_length < max_length

      tail = object_path_components.drop_while do |component|
        (object_path_length -= component.length) > max_length
      end

      ["#<...", tail.join("::"), ">"].join
    end

    def separators
      [separator, "*"]
    end

    def template(module_name, pry, separator)
      format(
        "%<ruby>s %<context>s[%<line>s] %<separator>s ",
        ruby: RUBY_VERSION,
        context: context(module_name),
        line: line_number(pry),
        separator: separator
      )
    end
  end
end

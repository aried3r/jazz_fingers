ENV['HOME'] ||= '/dev/null'

require 'pry'
require 'pry-byebug'
require 'readline'
require 'forwardable'

module JazzFingers
  autoload :Configuration, 'jazz_fingers/configuration'
  autoload :Input, 'jazz_fingers/input'
  autoload :Print, 'jazz_fingers/print'
  autoload :Prompt, 'jazz_fingers/prompt'
  autoload :VERSION, 'jazz_fingers/version'

  class << self
    extend Forwardable

    def_delegators :config, :awesome_print?, :coolline?

    def print
      @print ||= Print.config
    end

    def prompt
      @prompt ||=
        Prompt.new(
          colored: config.colored_prompt,
          separator: config.prompt_separator,
          application_name: config.application_name
        )
    end

    # Add JazzFingers prompt to the Pry::Prompt hash to enable changing it with
    # `change-prompt`.
    #
    # Return the Pry::Prompt object.
    def jazz_fingers_prompt
      return Pry::Prompt[:jazz_fingers] if Pry::Prompt[:jazz_fingers]

      Pry::Prompt.add(
        :jazz_fingers,
        "JazzFingers prompt",
        prompt.separators
      ) do |context, _nesting, pry, separator|
        prompt.template(Pry.view_clip(context), pry, separator)
      end

      Pry::Prompt[:jazz_fingers]
    end

    def input
      @input ||= Input.config
    end

    def configure
      yield @config ||= Configuration.new
      setup!
    end

    def config
      @config ||= Configuration.new
    end

    def setup!
      Pry.print = print if JazzFingers.awesome_print?
      Pry.prompt = jazz_fingers_prompt
      Pry.input = input if JazzFingers.coolline?
      Pry.config.should_load_plugins = false
      Pry.commands.alias_command('c', 'continue')
      Pry.commands.alias_command('s', 'step')
      Pry.commands.alias_command('n', 'next')

      true
    end
  end
end

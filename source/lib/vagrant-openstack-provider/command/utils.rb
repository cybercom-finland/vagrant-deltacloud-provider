require 'terminal-table'

module VagrantPlugins
  module Deltacloud
    module Command
      module Utils
        def display_item_list(env, items)
          rows = []
          items.each do |item|
            rows << [item.id, item.name]
          end
          display_table(env, %w(Id Name), rows)
        end

        def display_table(env, headers, rows)
          table = Terminal::Table.new headings: headers, rows: rows
          env[:ui].info("\n#{table}")
        end
      end
    end
  end
end

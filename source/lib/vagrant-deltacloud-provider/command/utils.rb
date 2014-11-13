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

        def get_ip_address(env)
          details = env[:deltacloud_client].get_instance_details(env, env[:machine].id)
          details.ip_address
        end
      end
    end
  end
end

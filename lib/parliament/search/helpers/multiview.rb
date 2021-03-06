module Parliament
  module Search
    module Helpers
      # Makes Sinatra support multiple view paths.
      # Usage:
      #
      #     class Main < Sinatra::Base
      #       register Sinatra::MultiView
      #
      #       get '/' do
      #         locals = { :name => current_user.name }
      #
      #         # Instead of `haml 'home', {}, locals`
      #         show 'home', {}, locals
      #       end
      #
      #       # Optional: look in many paths
      #       set :view_paths, [ './views/', './theme/views/' ]
      #
      #       # Optional: restrict searching to these formats
      #       set :view_formats, [ :erb, :haml ]
      #
      #       # Optional: Default options for anything using show()
      #       set :view_options, { :layout => true }
      #     end
      #
      module MultiView
        def self.registered(app)
          unless app.respond_to?(:view_formats)
            app.set :view_formats, [ :haml ]
          end

          app.helpers Helpers
        end

        module Helpers
          # Works like haml() (or any other template helper), except:
          #
          # - Tries many engines
          # - Tries many view paths, as set in your app's :view_paths
          # - Tries many templates, if you pass it an array
          # - Layouts don't have to use the same engine as the view
          # - In addition to `settings.haml`, it also checks settings.view_options
          # - Can't pass data onto it (doesn't make sense!), the `template` parameter
          #   is always assumed to be a template name
          #
          # Examples:
          #
          #     show 'default', {}, :item => @item
          #     show ['page/default', 'default']
          #     show 'default', { :layout => 'layout' }, { :item => @item }
          #     show 'css/chrome', { :view_formats => [ :sass, :less ], :layout => false }
          #
          def show(templates, options={}, locals={}, &block)
            # Merge app-level options.
            options = settings.view_options.merge(options) if settings.respond_to?(:view_options)

            # Find the template file (try many paths and formats)
            puts 'GET TEMPLATE FROM #SHOW'
            template, format = find_template(templates)
            return nil  if template.nil?

            # Save for later
            layout = options.delete :layout

            puts 'RENDERING TEMPLATE FROM #SHOW'
            ret = render(format, template, options, locals)

            # The default Sinatra layouting assumes that the layout will be the
            # same format as the actual page. Let's fix it so that the layout
            # can be anything else.
            if layout
              puts 'GETTING LAYOUT FROM #SHOW'
              layout, layout_format = find_template(layout)
              return ret  if layout.nil?

              puts 'RENDING LAYOUT FROM #SHOW'
              return render(format, layout) { ret }
            end

            ret
          end

          # Finds a template file.
          # Returns: a tuple of the template filename and the format.
          def find_template(templates, formats=nil, other=nil)
            puts "TEMPLATES: #{templates}"
            puts "FORMATS: #{formats}"
            puts "OTHER: #{other}"

            if other
              formats = nil
            end

            paths       = settings.view_paths  if settings.respond_to?(:view_paths)
            paths     ||= settings.views || './views'
            templates   = [templates].flatten
            formats   ||= settings.view_formats

            templates.each do |template|
              puts '---------'
              puts 'SEARCHING FOR TEMPLATE: '+template
              paths.each do |path|
                puts '-- SEARCHING WITHIN PATH: '+path

                formats.each do |format|
                  puts '---- SEARCHING FOR FORMAT: '+format.to_s
                  tpl = template_for(template, format, path) or next
                  return [tpl, format]
                end
              end
            end

            nil #Fail
          end

          # Returns the file contents of a given template path and format.
          #
          # Example:
          #
          #     template_for('app/views/layout', 'haml')
          #
          def template_for(template, format, path)
            fname = File.join(path.to_s, "#{template}.#{format}")
            return nil  unless File.exists?(fname)

            File.open(fname) { |f| f.read }
          end

          def partial(templates, locals={})
            show(templates, {:layout => false}, locals)
          end

          # def css(fname)
          #   options = { :layout => false, :view_formats => [ :less, :sass, :scss ] }
          #   show "css/#{fname}", options
          # end
        end
      end
    end
  end
end

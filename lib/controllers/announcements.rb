module Moka
  module Controllers
    module Announcements
      include Moka::Models

      def self.registered(app)
        app.get '/announcements' do
          authentication_required

          view :announcements
        end

        app.post '/announcements/identica' do
          authentication_required

          unless env['identica']
            error_set(:text, 'Posting announcements on identi.ca is not supported.')
          end

          unless error_set?
            if params[:text].size > 140
              error_set(:text, 'Message length is limited to 140 characters.')
            end
          end

          unless error_set?
            if env['identica'].group.nil?
              status = params[:text]
            else
              status = "#{params[:text]} !#{env['identica'].group}"
            end

            env['identica'].post(status)
          end

          view :announcements
        end
      end
    end
  end
end

require "picasa/api/base"

module Picasa
  module API
    class Photo < Base
      # Creates photo for given album
      #
      # @param [String] album_id album id
      # @param [Hash] options request parameters
      # @option options [String] :file_path path to photo file, rest of required attributes might be guessed based on file (i.e. "/home/john/Images/me.png")
      # @option options [String] :title title of photo
      # @option options [String] :summary summary of photo
      # @option options [String] :binary binary data (i.e. File.open("my-photo.png", "rb").read)
      # @option options [String] :content_type ["image/jpeg", "image/png", "image/bmp", "image/gif"] content type of given image
      def create(album_id, params = {})
        file = params[:file_path] ? File.new(params.delete(:file_path)) : File::Null.new
        params[:boundary]     ||= "===============PicasaRubyGem=="
        params[:title]        ||= file.name || raise(ArgumentError.new("title must be specified"))
        params[:binary]       ||= file.binary || raise(ArgumentError.new("binary must be specified"))
        params[:content_type] ||= file.content_type || raise(ArgumentError.new("content_type must be specified"))

        template = Template.new(:new_photo, params)
        headers = auth_header.merge({"Content-Type" => "multipart/related; boundary=\"#{params[:boundary]}\""})

        path = "/data/feed/api/user/#{user_id}/albumid/#{album_id}"
        response = Connection.new.post(path: path, body: template.render, headers: headers)

        Presenter::Photo.new(response.parsed_response["entry"])
      end
      
      
      def update_metadata(album_id, photo_id, params={})
        path = "/data/entry/api/user/#{user_id}/albumid/#{album_id}/photoid/#{photo_id}"
        #
        data = Connection.new.get(path: path, headers: auth_header)
        x = Presenter::Photo.new(data.parsed_response["entry"])
        #puts x
        #puts x.parsed_body
        #puts x.parsed_body['link'].to_yaml #.find { |z| z['rel']=='edit '}
        path = x.parsed_body['link'][4]['href']
        
        template = Template.new(:photo, params)
              # '/data/entry/api/user/userID/albumid/albumID/photoid/photoID'
        #path = "/data/entry/api/user/#{user_id}/albumid/#{album_id}/photoid/#{photo_id}"
        #puts template.render
        headers = auth_header.merge({"Content-Type" => "application/xml"})
        headers = headers.merge({"If-Match"=> "*"})
        
        response = Connection.new.patch(path: path, body: template.render, headers: headers)
        Presenter::Photo.new(response.parsed_response["entry"])
        
      end
      
      
      def update(album_id, photo_id, params={})
      file = params[:file_path] ? File.new(params.delete(:file_path)) : File::Null.new
      params[:boundary]     ||= "===============PicasaRubyGem=="
      params[:title]        ||= file.name || raise(ArgumentError.new("title must be specified"))
      params[:binary]       ||= file.binary || raise(ArgumentError.new("binary must be specified"))
      params[:content_type] ||= file.content_type || raise(ArgumentError.new("content_type must be specified"))
      headers = auth_header.merge({"Content-Type" => "multipart/related; boundary=\"#{params[:boundary]}\""})
      template = Template.new(:new_photo, params)

      headers = headers.merge({"If-Match"=> "*"})
      path = "/data/media/api/user/#{user_id}/albumid/#{album_id}/photoid/#{photo_id}"
      response = Connection.new.put(path: path, body: template.render, headers: headers)
      Presenter::Photo.new(response.parsed_response["entry"])
      end

      # Destroys given photo
      #
      # @param [String] album_id album id
      # @param [String] photo_id photo id
      # @param [Hash] options request parameters
      # @option options [String] :etag destroys only when ETag matches - protects before destroying other client changes
      #
      # @return [true]
      # @raise [NotFoundError] raised when album or photo cannot be found
      # @raise [PreconditionFailedError] raised when ETag does not match
      def destroy(album_id, photo_id, options = {})
        headers = auth_header.merge({"If-Match" => options.fetch(:etag, "*")})
        path = "/data/entry/api/user/#{user_id}/albumid/#{album_id}/photoid/#{photo_id}"
        Connection.new.delete(path: path, headers: headers)
        true
      end
      alias :delete :destroy
    end
  end
end

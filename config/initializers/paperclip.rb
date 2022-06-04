# REMOVE AFTER FIX
# https://github.com/thoughtbot/paperclip/issues/1706#issuecomment-67125980
Paperclip::Attachment.default_options[:use_timestamp] = false 

# https://github.com/thoughtbot/paperclip/wiki/Attachment-downloaded-from-a-URL
Paperclip::UriAdapter.register


module Paperclip
  class MediaTypeSpoofDetector

    def supplied_type_mismatch?
      supplied_media_type.present? && !media_types_from_name.include?(supplied_media_type)
    end

    def supplied_media_type
      @content_type.split("/").last
    end

    def media_types_from_name
      @media_types_from_name ||= content_types_from_name.collect(&:sub_type)
    end

    def calculated_media_type
      @calculated_media_type ||= calculated_content_type.split("/").last.split(';').first
    end

  end
end
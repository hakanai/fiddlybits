require 'ostruct'

class EncodingsController < ApplicationController
  def encode
    @encodings = Fiddlybits::Encoding.find_all

    @form = OpenStruct.new(params[:form])
    @form.data ||= ''
    @form.type ||= 'text'

    data = @form.data
    if !data.blank? && @form.type == 'hex'
      data = Fiddlybits::Hex.hex_to_binary(data)
    end

    if !data.blank? && !@form.encoding.blank?
      @encoding = Fiddlybits::Encoding.find_by_name(@form.encoding) || (redirect_to(root_path); return)
      @result = @form.data.blank? ? nil : @encoding.encode(data)
    end
  end

  def decode
    @encodings = Fiddlybits::Encoding.find_all

    @form = OpenStruct.new(params[:form])
    @form.data ||= ''
    @form.type ||= 'text'

    if !@form.data.blank? && !@form.encoding.blank?
      @encoding = Fiddlybits::Encoding.find_by_name(@form.encoding) || (redirect_to(root_path); return)
      begin
        @result = @encoding.decode(@form.data)
      rescue Fiddlybits::InvalidEncoding => e
        flash[:error] = "Cannot decode that data using #{@encoding.human_name}!"
        return
      end
  
      if @form.type == 'hex'
        @result = Fiddlybits::Hex.binary_to_hex(@result)
      end
    end
  end
end

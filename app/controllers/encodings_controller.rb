require 'ostruct'

class EncodingsController < ApplicationController
  before_filter :load_encoding, :except => [ :index ]

  def index
    @encodings = Fiddlybits::Encoding.find_all
  end

  def show
  end

  def encode
    @form = OpenStruct.new(params[:form])
    @form.data ||= ''
    @form.type ||= 'text'

    data = @form.data
    if !data.blank? && @form.type == 'hex'
      data = Fiddlybits::Hex.hex_to_binary(data)
    end

    if !data.blank?
      @result = @form.data.blank? ? nil : @encoding.encode(data)
    end
  end

  def decode
    @form = OpenStruct.new(params[:form])
    @form.data ||= ''
    @form.type ||= 'text'

    if !@form.data.blank?
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

  def load_encoding
    @encoding = Fiddlybits::Encoding.find_by_name(params[:id]) || redirect_to(root_path)
  end
end

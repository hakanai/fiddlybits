class CharsetsController < ApplicationController
  def index
    @charsets = Fiddlybits::CharsetRegistry.find_all
  end

  def show
    @charset = charset_from_params || return
  end

  def show_table
    @charset = charset_from_params || return
  end

  def decode
    @charset = charset_from_params || return
    @form = OpenStruct.new(params[:form])

    if !@form.data.blank?
      data = @form.data
      if @form.type == 'hex'
        data = Fiddlybits::Hex.hex_to_binary(data)
      end

      @result = @charset.decode(data)
    end
  end

private

  def charset_from_params
    Fiddlybits::CharsetRegistry.find_by_name(params[:charset]) || (redirect_to(:action => 'index'); nil)
  end
end

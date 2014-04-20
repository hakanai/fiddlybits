class CharsetsController < ApplicationController
  def decode
    @form = OpenStruct.new(params[:form])
    @charsets = Fiddlybits::CharsetRegistry.find_all

    @charset = nil
    if !@form[:charset].blank?
      @charset = Fiddlybits::CharsetRegistry.find_by_name(@form[:charset]) || (redirect_to(root_path); return)
    end

    if !@form.data.blank?
      data = @form.data
      if @form.type == 'hex'
        data = Fiddlybits::Hex.hex_to_binary(data)
      end

      @result = @charset.decode(data)
    end
  end
end

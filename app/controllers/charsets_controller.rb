class CharsetsController < ApplicationController
  before_filter :load_charset, :except => [ :index ]

  def index
    @charsets = Fiddlybits::CharsetRegistry.find_all
  end

  def show
  end

  def show_table
    raise NotImplementedError if @charset.min_bytes_per_char != @charset.max_bytes_per_char

    @table = []
    @headers = []
    if @charset.min_bytes_per_char == 1
      @axis = 'Nibble'
      (0..15).each do |y|
        row = []
        @headers[y] = "%X" % y
        (0..15).each do |x|
          bytes = [y * 16 + x]
          data = @charset.decode(bytes)
          raise NotImplementedError if data.size > 1 # I don't think this should happen
          fragment = data[0]
          row[x] = fragment if fragment.is_a?(Fiddlybits::Charset::DecodedData)
        end
        @table[y] = row
      end
    elsif @charset.min_bytes_per_char == 2
      @axis = 'Byte'
      @table = []
      (0..255).each do |y|
        row = []
        @headers[y] = "%02X" % y
        (0..255).each do |x|
          bytes = [y,x]
          data = @charset.decode(bytes)
          raise NotImplementedError if data.size > 1 # I don't think this should happen
          fragment = data[0]
          row[x] = fragment if fragment.is_a?(Fiddlybits::Charset::DecodedData)
        end
        @table[y] = row
      end
    else
      raise NotImplementedError
    end

    @rows = []
    @cols = []
    @table.each_with_index do |row, y|
      if row
        present = false
        row.each_with_index do |cell, x|
          if cell
            @cols << x if !@cols.include?(x)
            present = true
          end
        end
        if present
          @rows << y if !@rows.include?(y)
        end
      end
    end
    @cols.sort! # @rows will already be in order
  end

  def decode
    @form = OpenStruct.new(params[:form])
    @form.type ||= 'text'

    if !@form.data.blank?
      data = @form.data
      if @form.type == 'hex'
        data = Fiddlybits::Hex.hex_to_binary(data)
      end

      @result = @charset.decode(data)
    end
  end

  def load_charset
    @charset = Fiddlybits::CharsetRegistry.find_by_name(params[:id]) || redirect_to(:action => 'index')
  end

private

  def charset_from_params
  end
end

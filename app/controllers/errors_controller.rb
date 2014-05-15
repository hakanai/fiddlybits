class ErrorsController < ApplicationController

  def show
    @code = code
    render @code.to_s
  end

private

  def code
    params[:code] || 500
  end

end

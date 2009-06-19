# -*- coding: utf-8 -*-
class RedirectController < ApplicationController
  unloadable

  def index
    @target = params[:url].join('/')
    @target = @target + '/' if /(\/$)/ =~ request.path

    if @target =~ /^https?:\/\/.+/i
      @meta = true
    end

    render :file=>"#{RAILS_ROOT}/public/404.html", :status => '404 Not Found' and return if @target.length == 0
    render :layout => false
  end
end

module ApplicationHelper
  def nav_link_class(path)
    active = request.path.start_with?(path)
    "transition #{active ? 'text-white' : 'text-slate-400 hover:text-white'}"
  end

  def chf(amount)
    "CHF #{sprintf('%.2f', amount.to_f)}"
  end

  def showtime_date(time)
    I18n.l(time, format: "%a., %-d. %b %Y")
  end
end

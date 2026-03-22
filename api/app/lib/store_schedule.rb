module StoreSchedule
  def self.open?
    now       = Time.current.in_time_zone("America/Argentina/Buenos_Aires")
    open_days = (Setting["open_days"] || "4,5,6,0").split(",").map(&:to_i)
    opening   = Setting["opening_time"] || "20:00"
    closing   = Setting["closing_time"] || "00:00"

    return false unless open_days.include?(now.wday)

    open_h, open_m   = opening.split(":").map(&:to_i)
    close_h, close_m = closing.split(":").map(&:to_i)

    open_time  = now.change(hour: open_h, min: open_m)
    close_time = if close_h < open_h
      (now + 1.day).change(hour: close_h, min: close_m)
    else
      now.change(hour: close_h, min: close_m)
    end

    now.between?(open_time, close_time)
  end
end

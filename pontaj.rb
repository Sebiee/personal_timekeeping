require 'date'

class String
  def black;          "\e[30m#{self}\e[0m" end
  def red;            "\e[31m#{self}\e[0m" end
  def green;          "\e[32m#{self}\e[0m" end
  def brown;          "\e[33m#{self}\e[0m" end
  def blue;           "\e[34m#{self}\e[0m" end
  def magenta;        "\e[35m#{self}\e[0m" end
  def cyan;           "\e[36m#{self}\e[0m" end
  def gray;           "\e[37m#{self}\e[0m" end

  def bg_black;       "\e[40m#{self}\e[0m" end
  def bg_red;         "\e[41m#{self}\e[0m" end
  def bg_green;       "\e[42m#{self}\e[0m" end
  def bg_brown;       "\e[43m#{self}\e[0m" end
  def bg_blue;        "\e[44m#{self}\e[0m" end
  def bg_magenta;     "\e[45m#{self}\e[0m" end
  def bg_cyan;        "\e[46m#{self}\e[0m" end
  def bg_gray;        "\e[47m#{self}\e[0m" end

  def bold;           "\e[1m#{self}\e[22m" end
  def italic;         "\e[3m#{self}\e[23m" end
  def underline;      "\e[4m#{self}\e[24m" end
  def blink;          "\e[5m#{self}\e[25m" end
  def reverse_color;  "\e[7m#{self}\e[27m" end
end

def business_days_between(date1, date2)
  count = 0
  (date1..date2).each{|d| count+=1 if (1..5).include?(d.wday)}
  count
end

def saturdays_between(date1, date2)
  count = 0
  (date1..date2).each{|d| count+=1 if d.saturday?}
  count
end

def time_diff(elapsed_seconds)
  #to_i.abs

  # days = elapsed_seconds / 86400
  # elapsed_seconds -= days * 86400

  hours = elapsed_seconds / 3600
  elapsed_seconds -= hours * 3600

  minutes = elapsed_seconds / 60
  elapsed_seconds -= minutes * 60

  seconds = elapsed_seconds

  #   "#{days} Days #{hours.to_s.rjust(2, "0")}:#{minutes.to_s.rjust(2, "0")} Min #{seconds.to_s.rjust(2, "0")} Sec"
  "#{hours.to_s.rjust(3, " ")} Hrs #{minutes.to_s.rjust(2, " ")} Min #{seconds.to_s.rjust(2, " ")} Sec"
end

def get_total_for_day(filename)
  date_numbers = filename.split("/")[1].split("_").reject(&:empty?)
  date = Date.new(date_numbers[0].to_i, date_numbers[1].to_i, date_numbers[2].to_i)

  times = File.read(filename).split("\n")
  total = 0
  (0..times.size-1).step(2) do |idx|
    if idx+1 > times.size-1
      total += (Time.now - DateTime.parse(times[idx]).to_time)
      break
    end
    total += (DateTime.parse(times[idx+1]).to_time - DateTime.parse(times[idx]).to_time)
  end

  weekend_bonus = begin
    File.readlines(File.join(File.dirname(filename),"weekend_bonus")).map(&:chomp).collect!(&:to_i)
  rescue Errno::ENOENT
    []
  end

  if weekend_bonus.include?(date_numbers[2].to_i)
    if total > 4 * 60 * 60
      total = 8 * 60 * 60
    else
      total = 4 * 60 * 60
    end
  end

  # This is a paid holiday
  holidays = begin
    File.readlines(File.join(File.dirname(filename),"holidays")).map(&:chomp).collect!(&:to_i)
  rescue Errno::ENOENT
    []
  end
  # puts holidays
  if holidays.include?(date_numbers[2].to_i)
    total += 4 * 60 * 60
  end
  # This is a paid day off
  free_days = begin
    File.readlines(File.join(File.dirname(filename),"free_days")).map(&:chomp).collect!(&:to_i)
  rescue Errno::ENOENT
    []
  end

  if free_days.include?(date_numbers[2].to_i)
    total += 4 * 60 * 60
  end

  return total.to_i.abs
end

def show_working_time_status_for_day(filename, show_intervals = true)
  date_numbers = filename.split("/")[1].split("_").reject(&:empty?)

  date = Date.new(date_numbers[0].to_i, date_numbers[1].to_i, date_numbers[2].to_i)
  if show_intervals
    puts("======= Working Time Status ====== \n\n")
  end
  times = File.read(filename).split("\n")

  if times.size.odd?
    if show_intervals
      puts("                          ".bg_green.black)
      puts("=== You are checked in ===".bg_green.black)
      puts("                          \n\n".bg_green.black)
    end
  else
    if show_intervals
      puts("                              ".bg_red)
      puts("=== You are not checked in ===".bg_red)
      puts("                              \n\n".bg_red)
    end
  end
  total = 0
  (0..times.size-1).step(2) do |idx|
    if idx+1 > times.size-1
      total += (Time.now - DateTime.parse(times[idx]).to_time)
      if show_intervals
        puts("= Working interval ##{(idx/2)+1}: #{DateTime.parse(times[idx]).strftime("%Y/%m/%d %H:%M:%S")} - #{DateTime.now.strftime("%Y/%m/%d %H:%M:%S")} (Current time)")
      end
      break
    end
    if show_intervals
      puts("= Working interval ##{(idx/2)+1}: #{DateTime.parse(times[idx]).strftime("%Y/%m/%d %H:%M:%S")} - #{DateTime.parse(times[idx+1]).strftime("%Y/%m/%d %H:%M:%S")}")
    end
    total += (DateTime.parse(times[idx+1]).to_time - DateTime.parse(times[idx]).to_time)
  end

  weekend_bonus = begin
    File.readlines(File.join(File.dirname(filename),"weekend_bonus")).map(&:chomp).collect!(&:to_i)
  rescue Errno::ENOENT
    []
  end

  if weekend_bonus.include?(date_numbers[2].to_i)
    if total > 4 * 60 * 60
      total_weekend_bonus = 8 * 60 * 60 - total
    else
      total_weekend_bonus = 4 * 60 * 60 - total
    end
    total = total + total_weekend_bonus
  end

  # This is a paid holiday
  holidays = begin
    File.readlines(File.join(File.dirname(filename),"holidays")).map(&:chomp).collect!(&:to_i)
  rescue Errno::ENOENT
    []
  end

  if holidays.include?(date_numbers[2].to_i)
    total += 4 * 60 * 60
  end

  # This is a paid day off
  free_days = begin
    File.readlines(File.join(File.dirname(filename),"free_days")).map(&:chomp).collect!(&:to_i)
  rescue Errno::ENOENT
    []
  end

  if free_days.include?(date_numbers[2].to_i)
    total += 4 * 60 * 60
  end

  if show_intervals
    puts("=== Today you worked for #{time_diff(total.to_i.abs)}")
  else
    if total_weekend_bonus
      puts("=== #{date.strftime("%B %d")}: "+"#{time_diff(total.to_i.abs)} (weekend bonus)".bg_green.black)
    else
      puts("=== #{date.strftime("%B %d")}: #{time_diff(total.to_i.abs)}")
    end
  end
  total.to_i.abs
end

def insert_check
  filename = get_current_day_filename
  checkTime = DateTime.now
  File.write(filename, "#{checkTime}\n", mode: "a")
  count = %x(wc -l #{filename}).to_i
  if count.even?
    puts("\n                                                    ".bg_red)
    puts("Sucessfully checked out at #{checkTime}".bg_red)
    puts("                                                    ".bg_red)
  else
    puts("\n                                                   ".bg_green.black)
    puts("Sucessfully checked in at #{checkTime}".bg_green.black)
    puts("                                                   ".bg_green.black)
  end
end

def get_current_day_filename
  # Create month dir if not exists
  today = Date.today.strftime("%Y_%m_%d");
  cMonth = Date.today.strftime("%Y_%m");
  Dir.mkdir(cMonth) unless Dir.exist?(cMonth)

  "#{cMonth}/#{today}"
end

def get_worked_hours_for_month(date)
  first_day_of_month = Date.new(date.year, date.month, 1)
  last_day_of_month = Date.new(date.year, date.month, -1)
  month_dir = first_day_of_month.strftime("%Y_%m")
  total = 0
  (first_day_of_month..last_day_of_month).each do |d|
    day = d.strftime("%Y_%m_%d")
    begin
      tmp, tmp_original = get_total_for_day("#{month_dir}/#{day}")
    rescue Errno::ENOENT
      tmp = 0
    end
    total += tmp
  end
  total
end

# Worked time in month + any previously not reported time
def get_total_for_month(d)

  hours_not_reported = 0
  previous_month_reported_hours = 0
  (1..d.month).each do |previous_month|
    previous_date = Date.new(d.year, previous_month, 1)
    previous_month_dir = previous_date.strftime("%Y_%m")
    previous_month_worked_hours = get_worked_hours_for_month(previous_date)
    previous_month_reported_hours = begin
      File.read("#{previous_month_dir}/hours_reported").to_i*60*60
    rescue Errno::ENOENT
      previous_month_worked_hours
    end
    hours_not_reported += previous_month_worked_hours - previous_month_reported_hours
  end

  previous_month_reported_hours + hours_not_reported
end

def show_working_time_status_for_month(date, show_needed_hours=false)
  if date < Date.today
    day = -1
  elsif date == Date.today
    day = Date.today.day
  else
    puts "Cannot show working time for a month in the future"
    return -1
  end

  last_day_of_month = Date.new(date.year, date.month, day)
  current_month_dir = last_day_of_month.strftime("%Y_%m")
  if !Dir.exist?(current_month_dir)
    puts "No data for month #{last_day_of_month.strftime("%B %Y")}"
    return 1
  end

  puts("======= Working Time Status for #{last_day_of_month.strftime("%B %Y")} ====== \n\n")
  first_day_of_month = Date.new(date.year, date.month, 1)

  # Determine hours worked this month
  hours_worked_this_month = 0
  (first_day_of_month..last_day_of_month).each do |date|
    day = date.strftime("%Y_%m_%d")
    begin
      tmp, tmp_original = show_working_time_status_for_day("#{current_month_dir}/#{day}", false)
    rescue Errno::ENOENT
      puts("=== No data for #{day}. No such file #{current_month_dir}/#{day}")
      tmp = 0
      tmp_original = 0
    end
    hours_worked_this_month += tmp
  end

  # Determine hours not reported last month
  hours_not_reported_last_month = 0
  if date.month > 1
    last_month_dir = first_day_of_month.prev_month(1).strftime("%Y_%m")
    if Dir.exist?(last_month_dir)
      last_month_total = get_total_for_month(
        Date.new(date.year, date.month-1, 1)
      )

      last_month_reported = begin
        File.read("#{last_month_dir}/hours_reported").to_i*60*60
      rescue Errno::ENOENT
        puts("=== No hours_reported file in dir #{last_month_dir}")
        last_month_total
      end
      hours_not_reported_last_month = last_month_total - last_month_reported
    end
  end

  hours_bonus = begin
    File.read("#{current_month_dir}/hours_bonus").to_i*60*60
  rescue Errno::ENOENT
    0
  end

  # Determinte total hours availble for this month
  hours_total = hours_worked_this_month + hours_not_reported_last_month + hours_bonus

  # Determine hours reported this month
  hours_reported_current_month = begin
    File.read("#{current_month_dir}/hours_reported").to_i*60*60
  rescue Errno::ENOENT
    puts("=== No hours_reported file in dir #{current_month_dir}")
    hours_worked_this_month
  end

  # Determine hours to be reported next month
  hours_to_report_next_month = hours_total - hours_reported_current_month

  puts("=== #{"Worked this month:".to_s.rjust(24, " ")} #{time_diff(hours_worked_this_month)}".bg_blue)
  puts("=== #{"Not reported last month:".to_s.rjust(24, " ")} #{time_diff(hours_not_reported_last_month)}".bg_blue)
  if hours_bonus > 0
    puts("=== #{"Bonus hours this month:".to_s.rjust(24, " ")} #{time_diff(hours_bonus)}".bg_blue)
  end
  puts("=== #{"Total:".to_s.rjust(24, " ")} #{time_diff(hours_total)}".bg_blue)
  puts("")
  if Date.today.month != date.month
    puts("=== #{"Reported this month:".to_s.rjust(23, " ")} #{time_diff(hours_reported_current_month)}".bg_blue)
    puts("=== #{"Add to next month:".to_s.rjust(23, " ")} #{time_diff(hours_to_report_next_month)}".bg_blue)
    puts("")
  end

  # Calculate needed hours
  if show_needed_hours
    puts("\n")
    required_seconds = hours_reported_current_month
    worked_seconds = hours_total
    needed_seconds = required_seconds - worked_seconds
    puts("You want to work " + "#{required_seconds/60/60}h".bg_cyan.black + " this month")
    puts("To achieve your goal you have to work "+"#{time_diff(needed_seconds)}".bg_cyan.black + " more")

    last_day_of_month = Date.new(Date.today.year, Date.today.month, -1)
    puts("The last day of this month will be #{last_day_of_month}")

    remaining_workdays = business_days_between(Date.today, last_day_of_month)
    puts("There are "+"#{remaining_workdays}".bg_cyan.black+" more working days this month (excluding present day)")

    days_off = begin
      d = File.read("#{current_month_dir}/days_off").split("\n")
      total = 0
      (0..d.size-1).step(1) do |idx|
        if Date.parse(d[idx]) > Date.today
          total += 1
        end
      end
      total
    rescue Errno::ENOENT
      0
    end
    puts("You'll have "+"#{days_off}".bg_cyan.black+" days off this month")

    remaining_saturdays = saturdays_between(Date.today, last_day_of_month)
    puts("There are " + "#{remaining_saturdays}".bg_cyan.black + " more saturdays this month")

    if remaining_workdays > 0
      seconds_each_workday = needed_seconds / (remaining_workdays - days_off)
      puts("\nYou should work "+"#{time_diff(seconds_each_workday)}".bg_green.black+" each workday (excluding today)")
      puts("or")
    end
    seconds_each_workday = needed_seconds / (remaining_workdays - days_off + remaining_saturdays)
    puts("You should work "+"#{time_diff(seconds_each_workday)}".bg_green.black+" each workday and saturday")
  end
end

case ARGV[0]
when 'i'
  insert_check
  puts("")
end

case ARGV[0]
when "t"
  show_working_time_status_for_month(Date.today, true)
when "tt"
  print("Enter the number of the month to get working status for: ")
  month = $stdin.gets.to_i
  puts("")
  if month > 12 || month < 1
    puts("Invalid month. Enter value between 1 and 12")
    exit -1
  end
  show_working_time_status_for_month(Date.new(Date.today.year, month.to_i, Date.today.day))
when "ttt"
  print("Enter the year to get working status for: ")
  year = $stdin.gets.to_i
  puts("")
  if year > Date.today.year || year < 2023
    puts("Invalid year. Enter value between 2023 and #{Date.today.year}")
    exit -1
  end
  month = 1
  while month <= 12 && show_working_time_status_for_month(Date.new(year, month, 1)) != -1
    month += 1
  end
else
  show_working_time_status_for_day(get_current_day_filename)
end

puts("\nPress any key to exit...")
$stdin.gets
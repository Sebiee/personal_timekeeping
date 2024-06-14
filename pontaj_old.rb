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

def show_working_time_status_for_day(filename, show_intervals = true)
  date_numbers = filename.split("/")[1].split("_").reject(&:empty?)
  # puts(date_numbers)
  date = Date.new(date_numbers[0].to_i, date_numbers[1].to_i, date_numbers[2].to_i)
  if show_intervals
    puts("======= Working Time Status ====== \n\n")
  end
  times = File.read(filename).split("\n")
  # if times.empty?
  #   puts("No check for today")
  #   return 0
  # end
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
  total_original = 0
  if File.exists?("#{filename}.original")
    times = File.read("#{filename}.original").split("\n")
    (0..times.size-1).step(2) do |idx|
      if idx+1 > times.size-1
        total_original += (Time.now - DateTime.parse(times[idx]).to_time)
        break
      end
      total_original += (DateTime.parse(times[idx+1]).to_time - DateTime.parse(times[idx]).to_time)
    end
  end
  if show_intervals
    puts("=== Today you worked for #{time_diff(total.to_i.abs)}")
  else
    if total_original > 0
      puts("=== #{date.strftime("%B %d")}: #{time_diff(total.to_i.abs)} (Original: #{time_diff(total_original.to_i.abs)})")
    else
      puts("=== #{date.strftime("%B %d")}: #{time_diff(total.to_i.abs)}")
    end
  end
  if total_original == 0
    total_original = total
  end
  return total.to_i.abs, total_original.to_i.abs
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

def show_working_time_status_for_month(month, show_needed_hours=false)
  if month < Date.today.month
    day = -1
  elsif Date.today.month == month
    day = Date.today.day
  else
    puts "Cannot show working time for a month in the future"
    return -1
  end
  d = Date.new(Date.today.year, month, day)
  if !Dir.exist?(d.strftime("%Y_%m"))
    puts "No data for month #{d.strftime("%B")}"
    return -1
  end
  month = d.strftime("%Y_%m")
  total = 0
  total_original = 0
  added_from_last_month = 0
  to_add_next_month = 0
  puts("======= Working Time Status for #{d.strftime("%B %Y")} ====== \n\n")
  (Date.new(d.year, d.month, 1)..Date.new(d.year, d.month, d.day)).each do |date|
    day = date.strftime("%Y_%m_%d")
    begin
      tmp, tmp_original = show_working_time_status_for_day("#{month}/#{day}", false)
    rescue Errno::ENOENT
      puts("=== No data for #{day}. No such file #{month}/#{day}")
      tmp = 0
      tmp_original = 0
    end
    total += tmp
    total_original += tmp_original
    if tmp_original < tmp # we added from last month
      added_from_last_month += tmp - tmp_original
    elsif tmp_original > tmp # we'll add to next month
      to_add_next_month += tmp_original - tmp
    end
  end
  puts("=== #{"Worked this month:".to_s.rjust(24, " ")} #{time_diff(total_original)}".bg_blue)
  puts("=== #{"Not reported last month:".to_s.rjust(24, " ")} #{time_diff(added_from_last_month)}".bg_blue)
  puts("=== #{"Total:".to_s.rjust(24, " ")} #{time_diff(total_original+added_from_last_month)}".bg_blue)
  puts("")
  puts("=== #{"Report this month:".to_s.rjust(23, " ")} #{time_diff(total)}".bg_blue)
  puts("=== #{"Add to next month:".to_s.rjust(23, " ")} #{time_diff(to_add_next_month)}".bg_blue)
  puts("")

  # if added_from_last_month > 0
  #   puts("=== #{"Added from last month:".to_s.rjust(23, " ")} #{time_diff(added_from_last_month)}".bg_blue)
  # # end
  # # if total_original != total
  #   puts("=== #{"Effectively worked this month:".to_s.rjust(23, " ")} #{time_diff(total_original)}".bg_blue)
  # # end
  # puts("=== #{"Total to report:".to_s.rjust(23, " ")} #{time_diff(total)} (Effective+LastM)".bg_blue)
  # # if to_add_next_month > 0
  #   puts("=== #{"To add next month:".to_s.rjust(23, " ")} #{time_diff(to_add_next_month)} (Not included in any from above)".bg_blue)
  # end

  # Calculate needed hours
  if show_needed_hours
    puts("\n")
    required_seconds = 100 * 60 * 60
    worked_seconds = total
    needed_seconds = required_seconds - worked_seconds
    puts("You want to work " + "#{required_seconds/60/60}h".bg_cyan.black + " this month")
    puts("To achieve your goal you have to work "+"#{time_diff(needed_seconds)}".bg_cyan.black + " more")

    last_day_of_month = Date.new(Date.today.year, Date.today.month, -1)
    puts("The last day of this month will be #{last_day_of_month}")

    remaining_workdays = business_days_between(Date.today, last_day_of_month)
    puts("There are "+"#{remaining_workdays}".bg_cyan.black+" more working days this month (excluding present day)")

    remaining_saturdays = saturdays_between(Date.today, last_day_of_month)
    puts("There are " + "#{remaining_saturdays}".bg_cyan.black + " more saturdays this month")

    seconds_each_workday = needed_seconds / remaining_workdays
    puts("\nYou should work "+"#{time_diff(seconds_each_workday)}".bg_green.black+" each workday (excluding today)")
    puts("or")
    seconds_each_workday = needed_seconds / (remaining_workdays + remaining_saturdays)
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
  show_working_time_status_for_month(Date.today.month, true)
when "tt"
  print("Enter the number of the month to get working status for: ")
  month = $stdin.gets.to_i
  puts("")
  if month > 12 || month < 1
    puts("Invalid month. Enter value between 1 and 12")
    exit -1
  end
  show_working_time_status_for_month(month.to_i)
when "ttt"
  month = 2
  while show_working_time_status_for_month(month) != -1
    month += 1
  end
else
  show_working_time_status_for_day(get_current_day_filename)
end

puts("\nPress any key to exit...")
$stdin.gets
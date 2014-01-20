#!/usr/bin/ruby
#
# (c) Peter Boros - Percona
#
# 

slowlog_file = "mysql56_mastertest.log"

inside_slowlog = false

current_schema = ''
current_slowlog_event = ''
original_slowlog=File.open(slowlog_file, 'r')

original_slowlog.each { |line|
  if not inside_slowlog
    if line =~ /# User@Host/
      inside_slowlog = true
      current_slowlog_event += line
    end
  else
    if line =~ /# User@Host/
      inside_slowlog = false
      slowlog_file=File.open("mysql56_mastertest.log.#{current_schema}", 'a+')
      slowlog_file.write(current_slowlog_event)
      slowlog_file.close

      current_slowlog_event = ''
      current_schema = ''
      redo
    else
      if line =~ / Schema: /
        current_schema=line.split(' ')[4]
      end
      current_slowlog_event += line
    end
  end
}

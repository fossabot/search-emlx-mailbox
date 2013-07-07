require 'ruby-progressbar'

class Email < ActiveRecord::Base
  EXTENSION = "emlx"

  class << self

    @progress_bar_enabled = true
    def progress_bar(size)
      @progress_bar_enabled ?
          ProgressBar.create(title: 'Email Import', total: size, throttle_rate: 0.1) :
          nil
    end

    def disable_progress_bar!
      @progress_bar_enabled = false
    end
  end


  def self.from_file(filename)
    content = File.read(filename).encode!('UTF-8', 'UTF-8', :invalid => :replace, :replace => '').unpack("C*").pack("U*")
    email = self.new
    email.header, email.body = content.split(/\n\n/, 2)
    email.subject = email.header.scan(/.*\n[Ss]ubject: ([^\n]*)/).try(:last).try(:first)
    email.to = email.header.scan(/.*\n[tT][oO]: ([^\n]*)/).try(:last).try(:first)
    email.from = email.header.scan(/.*\n[fF]rom: ([^\n]*)/).try(:last).try(:first)
    email.cc = email.header.scan(/.*\n[cC][cC]: ([^\n]*)/).try(:last).try(:first)
    email.received = Time.parse(email.header.scan(/.*\n[dD]ate: ([^\n]*)/).try(:last).try(:first))
    email
  end

  def self.create_from_dir(folder)
    pattern = File.join(folder, "**", "*.#{EXTENSION}")
    files = Dir.glob(pattern)
    pb = self.progress_bar(files.size)
    files.each do |file|
      self.from_file(file).save!
      pb.increment if pb
    end
    pb.finish if pb
  end
end

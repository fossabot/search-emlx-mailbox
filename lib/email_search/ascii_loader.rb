module EmailSearch
  class AsciiLoader < Struct.new(:path, :email)
    def initialize(*args)
      super
      return if File.size(path) > EmailSearch::MAX_FILE_SIZE
      content = File.read(path).encode!('UTF-8', 'UTF-8', :invalid => :replace, :replace => '').unpack("C*").pack("U*")

      email = Email.new
      email.header, email.body = content.split(/\n\n/, 2)
      email.subject = email.header.scan(/^subject:\s+([^\n]*)/i).try(:last).try(:first)
      email.to = email.header.scan(/^to:\s+([^\n]*)/i).try(:last).try(:first)
      email.from = email.header.scan(/^from:\s+([^\n]*)/i).try(:last).try(:first)
      email.cc = email.header.scan(/^cc:\s+([^\n]*)/i).try(:last).try(:first)
      email.file_name = path.scan(%r{.*/([^\/]+)}).last.first
      time_string = email.header.scan(/^date:\s+([^\n]*)/i).try(:last).try(:first)
      email.received = Time.parse(time_string) rescue nil
      self.email = email
      self
    rescue Exception => e
      puts "exception processing file #{path}"
      raise e
    end

  end
end

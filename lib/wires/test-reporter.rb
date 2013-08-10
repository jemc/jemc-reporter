gem     'minitest-reporters'
require 'minitest/reporters'

require 'ansi/code'
require 'pp'




module Wires; module Test; class Reporter
  include Minitest::Reporter
  
  attr_accessor :color, :columns, :max_tests
  
  def initialize(options = {})
    # @detailed_skip = options.fetch(:detailed_skip, true)
    # @slow_count = options.fetch(:slow_count, 0)
    # @slow_suite_count = options.fetch(:slow_suite_count, 0)
    # @fast_fail = options.fetch(:fast_fail, false)
    # @test_times = []
    # @suite_times = []
    @color = options.fetch(:color) do
      output.tty? && (
        ENV["TERM"] =~ /^screen|color/ ||
        ENV["EMACS"] == "t"
      )
    end
    
    @columns = ENV['COLUMNS'] || `tput cols`.to_i || 80
    
  end
  
  def before_suites(suites, type)
    puts
    # puts "# Running #{type}s:"
    # puts
    
    self.max_tests = suites.map{|x| x.test_methods.size}.max
    
    for suite in suites do
      
      class << suite
        attr_accessor :reporter
        attr_accessor :tests
      end
      
      suite.reporter = self
      
      suite.tests = Hash.new
      suite.tests[:pass]  = []
      suite.tests[:fail]  = []
      suite.tests[:error] = []
      suite.tests[:skip]  = []
      
      def suite.suffix
        dig = reporter.max_tests.to_s.size
        groups = [:pass, :fail, :error]
        colors = [:green,:red,:magenta]
        
        (' ' + groups
          .map { |x| self.tests[x].size }
          .map { |x,e| (x > 0) ? ("%0#{dig}d" % x) : dig.times.map{' '}.join }
          .each_with_index
          .map { |x,i| reporter.send(colors[i], x) }
          .join('/'))
      end
      
      def suite.suffix_size
        ANSI::Code.uncolor(self.suffix).size
      end
      
    end
    
  end
  
  def before_suite(suite)
    return if suite.test_methods.size <= 0
    length = @columns-suite.test_methods.size-suite.suffix_size
    print str_fit(suite.name, length-1)+' '
    
  end
  
  def after_suite(suite)
    return if suite.test_methods.size <= 0
    puts suite.suffix
    suite.tests[:fail].each  { |x| failure_show(*x) }
    suite.tests[:error].each { |x|   error_show(*x) }
  end
  
  def after_suites(suites, type)
    puts
    # puts "# Done running #{type}s."
    # puts
  end
  
  def pass(suite, test, test_runner)
    print green('.')
    suite.tests[:pass]  << [test, test_runner.exception]
  end
  
  def skip(suite, test, test_runner)
    print blue('s')
    suite.tests[:pass]  << [test, test_runner.exception]
  end
  
  def failure(suite, test, test_runner)
    print red('F')
    suite.tests[:fail]  << [test, test_runner.exception]
  end
  
  def error(suite, test, test_runner)
    print magenta('E')
    suite.tests[:error] << [test, test_runner.exception]
  end
  
  def failure_show(test, exc)
    pre  = black('>')+red('>')+bold(red('>'))+' '
    pre_size  = ANSI::Code.uncolor(pre).size
    
    puts pre+red(str_fit(test, @columns-pre_size))
    
    pre = pre_size.times.map{' '}.join + 'in '
    pre_size  = ANSI::Code.uncolor(pre).size
    puts pre+str_fit(runner.location(exc), @columns-pre_size)
  end
  
  def error_show(test, exc)
    
  end
  
# private
  
  # [:black, :red, :green, :yellow, :blue, :magenta, :cyan, :white]
  for color in ANSI::Code.colors+[:bold]
    eval <<-CODE

  def #{color}(string)
    @color ? ANSI::Code.#{color}(string) : string
  end

CODE
  end
  
  # Pad or truncate a string intelligently
  def str_fit(str, length, keep: :both, align: :left, pad:' ', mid:'...')
    
    str = str.to_s
    
    raise ArgumentError, "Keyword argument :keep must be :head, :tail, or :both."\
      unless [:head, :tail, :both].include? keep
    
    raise ArgumentError, "Keyword argument :align must be :left, :right, or :center."\
      unless [:left, :right, :center].include? align
    
    length = [0,length-1].max
    diff = length - str.size
    
    # Return padded string if length is the same or to be increased
    
    if diff>=0
      padstr = diff.times.map{pad}.join[0..diff]
      case align
      when :left
        return str + padstr
      when :right
        return padstr + str
      when :center
        
        return padstr[0...(padstr.size/2)] + str + padstr[0...(padstr.size-(padstr.size/2))]
      end
    end
    
    # Return truncated midstring if length is the same or smaller than mid's size
    return mid[0...length] if length<=mid.size
    
    boundary_re = /((?<=[a-zA-Z])(?![a-zA-Z]))|((?<![a-zA-Z])(?=[a-zA-Z]))/
    
    indices = str.to_enum(:scan, boundary_re).map{$`.size}-[0,str.size]
    # p indices
    
    # Collect pairs of indices closest to desired diff
    nearest = [[str.size,0,str.size]]
    for x in indices
      x = 0 if keep==:tail
      for y in indices
        y = str.size if keep==:head
        if (y>x)
          candidate = [(y-x+diff-mid.size).abs,(y-x+diff-mid.size),x,y]
          
          if nearest[0][0]> candidate[0]
            nearest = [candidate]
          elsif nearest[0][0]==candidate[0]
            nearest << candidate
          end
          
        end
      end
    end
    nearest.uniq!
    
    # Choose the most appropriate pair of indices from nearest
    case keep
    when :both
      nearest.sort!{|a,b| (str.size-(a[2]+a[3])).abs <=> (str.size-(b[2]+b[3])).abs}
    when :tail
      nearest.reverse!
    end
    nearest = nearest.first
    
    if nearest[0]!=0
      case keep
      when :both
        nearest[2]+=(nearest[1]/2)
        nearest[3]-=(nearest[1]-(nearest[1]/2))
      when :head
        nearest[2]+=nearest[1]
      when :tail
        nearest[3]-=nearest[1]
      end
      if    nearest[2]<0
        nearest[2]+=(0-nearest[2])
        nearest[3]+=(0-nearest[2])
      elsif nearest[3]>str.size
        nearest[3]+=(str.size-nearest[2])
        nearest[3]+=(str.size-nearest[2])
      end
      
      nearest[1]=(y-x+diff-mid.size)
      nearest[0]=nearest[1].abs
    end
    
    return str[0...nearest[2]]+mid+str[nearest[3]..str.size]
    
  end
  
end end end

Minitest::Reporters.use! Wires::Test::Reporter.new
# Minitest::Reporters.use! Minitest::Reporters::SpecReporter.new

# p ANSI::Code.methods-Module.instance_methods
# p ANSI::Code.colors
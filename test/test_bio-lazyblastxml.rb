require "pp"
require 'helper'

class TestReport < MiniTest::Unit::TestCase
  def setup
    @blast_filename = 'test/data/test.blastout.xml'
    @report = Bio::LazyBlast::Report.new(@blast_filename)
  end

  def test_report_creation
    assert_kind_of Bio::LazyBlast::Report, @report, "Creating a new Report should return a report object"
  end

  def test_report_enumeration
    assert_equal 2, @report.count, "Calling #count on the report object should return the number of iterations"
  end

  def test_report_iteration
    assert @report.all?{|iteration| iteration.is_a? Bio::LazyBlast::Report::Iteration}, "All of the objects yielded by the report object should be a type of Bio::LazyBlast::Report::Iteration"
  end

  def test_report_instance_values
    first_iteration = @report.first
    assert_equal 1, first_iteration.num
    assert_equal 'test', first_iteration.query_def
    assert_equal 'lcl|1_0', first_iteration.query_id
    assert_equal 16, first_iteration.query_len
  end

end

class TestIteration < MiniTest::Unit::TestCase
  def setup
    @blast_filename = 'test/data/test.blastout.xml'
    @report = Bio::LazyBlast::Report.new(@blast_filename)
  end

  def test_iteration_creation
    @iteration = @report.first
    assert_kind_of Bio::LazyBlast::Report::Iteration, @iteration
    assert_equal 'blastp', @report.program
    assert_equal 'blastp 2.2.21 [Jun-14-2009]', @report.version
    assert_equal 'db.fasta', @report.db
    assert_equal 'BLOSUM62', @report.parameters['matrix']
    assert_equal 10, @report.parameters['expect']
    assert_equal 11, @report.parameters['gap-open']
    assert_equal 1, @report.parameters['gap-extend']
    assert_equal 'F', @report.parameters['filter']
  end

  def test_example_usage
    outstring = ''
    @report.each_iteration do |iteration|
      outstring << "Query: %s\n" % iteration.query_def
      iteration.each_hit do |hit|
        outstring << "     | hit:  %s\n" % hit.definition
        hit.each_hsp do |hsp|
          outstring << "          | hsp: %s\n" % hsp.evalue
        end
      end
    end
    final_string = <<-teststring
Query: test
Query: SNOT_00028.1|EAT91523.1
     | hit:  SNOT_00028.1|EAT91523.1
          | hsp: 0.0
     | hit:  SNOT_00009.1|EAT91504.1
          | hsp: 4.05209
     | hit:  SNOT_00532.1|EAT92027.1
          | hsp: 5.33653
     | hit:  SNOT_00418.1|EAT91913.1
          | hsp: 6.35851
teststring
    assert_equal final_string, outstring
  end
end

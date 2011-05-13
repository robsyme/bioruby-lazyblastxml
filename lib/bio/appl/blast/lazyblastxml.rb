require "libxml"

class Enumerator
  def lazy_select(&block)
    Enumerator.new do |yielder|
      self.each do |val|
        yielder.yield(val) if block.call(val)
      end
    end
  end

  def lazy_reject(&block)
    Enumerator.new do |yielder|
      self.each do |val|
        yielder.yield(val) unless block.call(val)
      end
    end
  end

  def lazy_map(&block)
    Enumerator.new do |yielder|
      self.each do |value|
        yielder.yield(block.call(value))
      end
    end
  end
end

module Bio
  class LazyBlast
    class Report

      class Iteration
        attr_reader   :statistics
        attr_accessor :num
        attr_accessor :message
        attr_accessor :query_id
        attr_accessor :query_def
        attr_accessor :query_len

        def find_nodes_named(*names)
          @nodes.lazy_select{|reader| names.include?(reader.name)}
        end

        def next_node_named(*names)
          find_nodes_named(*names).next
        end

        def next_value_named(*names)
          next_node_named(*names).read_inner_xml
        end

        def setup_hits(xml_reader)
          @reader = xml_reader
          hits_finished = false
          @nodes = Enumerator.new do |yielder|
            while @reader.read and !(@reader.name == "Iteration_hits" and @reader.node_type == LibXML::XML::Reader::TYPE_END_ELEMENT) and !(@reader.value == "No hits found")
              yielder << @reader if @reader.node_type == LibXML::XML::Reader::TYPE_ELEMENT
            end
          end
        end

        def hits
          Enumerator.new do |yielder|
            find_nodes_named("Hit").each do |reader|
              hit = Hit.new
              hit.num = next_value_named("Hit_num").to_i
              hit.hit_id = next_value_named("Hit_id")
              hit.definition = next_value_named("Hit_def")
              hit.accession = next_value_named("Hit_accession")
              hit.len = next_value_named("Hit_len")
              hit.setup_hsps(@reader)

              yielder << hit
            end
          end
        end
        
        class Hit
          attr_accessor :num
          attr_accessor :hit_id
          attr_accessor :len
          attr_accessor :definition
          attr_accessor :accession

          def find_nodes_named(*names)
            @nodes.lazy_select{|reader| names.include?(reader.name)}
          end

          def next_node_named(*names)
            find_nodes_named(*names).next
          end

          def next_value_named(*names)
            next_node_named(*names).read_inner_xml
          end

          def setup_hsps(xml_reader)
            @reader = xml_reader
            @nodes = Enumerator.new do |yielder|
              while @reader.read and !(@reader.name == "Hit_hsps" and @reader.node_type == LibXML::XML::Reader::TYPE_END_ELEMENT)
                yielder << @reader if @reader.node_type == LibXML::XML::Reader::TYPE_ELEMENT
              end
            end
          end

          def hsps
            Enumerator.new do |yielder|
              find_nodes_named("Hsp").each do |reader|
                hsp = Hsp.new
                hsp.num = next_value_named("Hsp_num").to_i
                hsp.bit_score = next_value_named("Hsp_bit-score").to_f
                hsp.evalue = next_value_named("Hsp_evalue").to_f
                hsp.query_from = next_value_named("Hsp_query-from").to_i
                hsp.query_to = next_value_named("Hsp_query-to").to_i
                hsp.hit_from = next_value_named("Hsp_hit-from").to_i
                hsp.hit_to = next_value_named("Hsp_hit-to").to_i
                hsp.query_frame = next_value_named("Hsp_query-frame").to_i
                hsp.hit_frame = next_value_named("Hsp_hit-frame").to_i
                hsp.identity = next_value_named("Hsp_positive").to_i
                hsp.align_len = next_value_named("Hsp_align-len").to_i
                hsp.qseq = next_value_named("Hsp_qseq").to_i
                hsp.hseq = next_value_named("Hsp_hseq").to_i
                hsp.midline = next_value_named("Hsp_midline").to_i

                yielder << hsp
              end
            end
          end
          
          class Hsp
            attr_accessor :num
            attr_accessor :bit_score
            attr_accessor :evalue
            attr_accessor :query_from
            attr_accessor :query_to
            attr_accessor :hit_from
            attr_accessor :hit_to
            attr_accessor :query_frame
            attr_accessor :hit_frame
            attr_accessor :identity
            attr_accessor :positive
            attr_accessor :gaps
            attr_accessor :align_len
            attr_accessor :density
            attr_accessor :qseq
            attr_accessor :hseq
            attr_accessor :midline
            attr_accessor :percent_identity
            attr_accessor :mismatch_count
          end

        end

      end
      
      attr_reader :reader

      def initialize(filename)
        @reader = LibXML::XML::Reader.file(filename)
        @nodes = Enumerator.new do |yielder|
          while @reader.read 
            yielder << @reader if @reader.node_type == LibXML::XML::Reader::TYPE_ELEMENT
          end
        end
      end

      def find_nodes_named(*names)
        @nodes.lazy_select{|reader| names.include?(reader.name)}
      end

      def next_node_named(*names)
        find_nodes_named(*names).next
      end

      def next_value_named(*names)
        next_node_named(*names).read_inner_xml
      end

      def iterations
        Enumerator.new do |yielder|
          find_nodes_named("Iteration").each do |reader|
            iteration = Iteration.new
            iteration.num = next_value_named("Iteration_iter-num").to_i
            iteration.query_id = next_value_named("Iteration_query-ID")
            iteration.query_def = next_value_named("Iteration_query-def")
            iteration.query_len = next_value_named("Iteration_query-len").to_i
            iteration.setup_hits(@reader)

            yielder << iteration
          end
        end
      end
      
    end
  end
end

require "libxml"

module Bio
  class LazyBlast
    class Report
      include Enumerable
      attr_reader :reader, :program, :version, :db, :query_id, :query_def, :query_len, :parameters

      def initialize(filename)
        @reader = LibXML::XML::Reader.file(filename)
        @nodes = Enumerator.new do |yielder|
          while @reader.read 
            yielder << @reader if @reader.node_type == LibXML::XML::Reader::TYPE_ELEMENT
          end
        end
        setup_report_values
      end

      def setup_report_values
        @parameters = Hash.new
        @nodes.each do |node|
          return node if node.name == "BlastOutput_iterations"
          case node.name
          when 'BlastOutput_program'
            @program = node.read_inner_xml
          when 'BlastOutput_version'
            @version = node.read_inner_xml
          when 'BlastOutput_db'
            @db = node.read_inner_xml
          when 'BlastOutput_query-ID'
            @query_id = node.read_inner_xml
          when 'BlastOutput_query-def'
            @query_def = node.read_inner_xml
          when 'BlastOutput_query-len'
            @query_len = node.read_inner_xml.to_i
          when 'Parameters_matrix'
            @parameters['matrix'] = node.read_inner_xml
          when 'Parameters_expect'
            @parameters['expect'] = node.read_inner_xml.to_i
          when 'Parameters_gap-open'
            @parameters['gap-open'] = node.read_inner_xml.to_i
          when 'Parameters_gap-extend'
            @parameters['gap-extend'] = node.read_inner_xml.to_i
          when 'Parameters_filter'
            @parameters['filter'] = node.read_inner_xml
          end
        end
      end
      
      def each
        @nodes.each{|node| yield Iteration.new(node) if node.name == "Iteration"}
      end
      alias :each_iteration :each

      class Iteration
        include Enumerable
        attr_reader :num, :query_id, :query_def, :query_len, :message, :parameters

        def initialize(reader)
          @nodes = Enumerator.new do |yielder|
            until (reader.name == "Iteration" and reader.node_type == LibXML::XML::Reader::TYPE_END_ELEMENT) or !reader.read
              yielder << reader if reader.node_type == LibXML::XML::Reader::TYPE_ELEMENT
            end
          end
          setup_iteration_values
        end

        def setup_iteration_values
          @nodes.each do |node|
            return node if node.name == 'Iteration_hits'
            case node.name
            when 'Iteration_iter-num'
              @num = node.read_inner_xml.to_i
            when 'Iteration_query-ID'
              @query_id = node.read_inner_xml
            when 'Iteration_query-def'
              @query_def = node.read_inner_xml
            when 'Iteration_query-len'
              @query_len = node.read_inner_xml.to_i
            when 'Iteration_message'
              @message = node.read_inner_xml
            end
          end
        end

        def each
          @nodes.each{|node| yield Hit.new(node) if node.name == "Hit"}
        end
        alias :each_hit :each
        
        class Hit
          include Enumerable
          attr_reader :num, :hit_id, :len, :definition, :accession

          def initialize(reader)
            @nodes = Enumerator.new do |yielder|
              until (reader.name == "Hit" and reader.node_type == LibXML::XML::Reader::TYPE_END_ELEMENT) or !reader.read
                yielder << reader if reader.node_type == LibXML::XML::Reader::TYPE_ELEMENT
              end
            end
            setup_hit_values
          end

          def setup_hit_values
            @nodes.each do |node|
              return node if node.name == 'Hit_hsps'
              case node.name
              when 'Hit_num'
                @num = node.read_inner_xml.to_i
              when 'Hit_id'
                @hit_id = node.read_inner_xml.to_i
              when 'Hit_def'
                @definition = node.read_inner_xml
              when 'Hit_accession'
                @accession = node.read_inner_xml
              when 'Hit_len'
                @len = node.read_inner_xml
              end
            end
          end
          
          def each
            @nodes.each{|node| yield Hsp.new(node) if node.name == "Hsp"}
          end
          alias :each_hsp :each
          
          class Hsp
            attr_reader :num, :bit_score, :evalue, :query_from, :query_to, :hit_from, :hit_to, :query_frame, :hit_frame, :identity, :positive, :gaps, :align_len, :density, :qseq, :hseq, :midline, :percent_identity, :mismatch_count

            def initialize(reader)
              @nodes = Enumerator.new do |yielder|
                until (reader.name == "Hsp" and reader.node_type == LibXML::XML::Reader::TYPE_END_ELEMENT) or !reader.read
                  yielder << reader if reader.node_type == LibXML::XML::Reader::TYPE_ELEMENT
                end
              end
              setup_hsp_values
            end

            def setup_hsp_values
              @nodes.each do |node|
                case node.name
                when 'Hsp_num'
                  @num = node.read_inner_xml.to_i
                when 'Hsp_bit-score'
                  @bit_score = node.read_inner_xml.to_f
                when 'Hsp_evalue'
                  @evalue = node.read_inner_xml.to_f
                when 'Hsp_query-from'
                  @query_from = node.read_inner_xml.to_i
                when 'Hsp_query-to'
                  @query_to = node.read_inner_xml.to_i
                when 'Hsp_query-frame'
                  @query_frame = node.read_inner_xml.to_i
                when 'Hsp_hit-frame'
                  @hit_frame = node.read_inner_xml.to_i
                when 'Hsp_identity'
                  @identity = node.read_inner_xml.to_i
                when 'Hsp_positive'
                  @positive = node.read_inner_xml.to_i
                when 'Hsp_align-len'
                  @align_len = node.read_inner_xml.to_i
                when 'Hsp_qseq'
                  @qseq = node.read_inner_xml
                when 'Hsp_hseq'
                  @hseq = node.read_inner_xml
                when 'Hsp_midline'
                  @midline = node.read_inner_xml
                end
              end
            end
          end
        end
      end
    end
  end
end

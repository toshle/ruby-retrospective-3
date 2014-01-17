module Asm
  module NumberOperations
    def cmp(register, value)
      @instructions << [:cmp, register, value]
    end

    def mov(destination_register, source)
      @instructions << [:'=', destination_register, source]
    end

    def inc(destination_register, source = 1)
      @instructions << [:'+', destination_register, source]
    end

    def dec(destination_register, source = 1)
      @instructions << [:'-', destination_register, source]
    end
  end

  module Jumps
    def label(label_name)
      @labels[label_name] = @instructions.length
    end

    def jmp(label)
      @instructions << [:jmp, label]
    end

    def je(label)
      @instructions << [:je, :==, label]
    end

    def jne(label)
      @instructions << [:jne, :'!=', label]
    end

    def jl(label)
      @instructions << [:jl, :<, label]
    end

    def jle(label)
      @instructions << [:jle, :<=, label]
    end

    def jg(label)
      @instructions << [:jg,:>, label]
    end

    def jge(label)
      @instructions << [:jge, :>=, label]
    end
  end

  class Assembler
    include NumberOperations
    include Jumps

    def initialize
      @compare_result = nil
      @instructions = []
      @labels       = {}
      @registers    = {ax: 0, bx: 0, cx: 0, dx: 0}
    end

    def method_missing(method, *args)
      method
    end

    def execute(label = 0)
      @instructions.drop(label).each do |instruction, destination, source|
        source = @registers[source] if @registers.keys.include?(source)

        if instruction == :'='
          @registers[destination] = source
        else
          perform_instruction(instruction, destination, source)
        end

        break if [:jmp, :je, :jne, :jl, :jle, :jg, :jge].include?(instruction)
      end
      @registers.to_a.map { |element| element.drop(1) }.flatten
    end

    private

    def perform_instruction(instruction, destination, source)
      case instruction
        when :jmp
          execute(@labels[destination] || destination)
        when :cmp
          @compare_result = @registers[destination] - source
        when :je, :jne, :jl, :jle, :jg, :jge
          execute(@labels[source] || source) if @compare_result.send(destination, 0)
        else
          @registers[destination] = @registers[destination].send(instruction, source)
      end
    end
  end

  def self.asm(&block)
    program = Assembler.new
    program.instance_eval(&block)
    program.execute
  end
end
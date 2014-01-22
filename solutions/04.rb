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

    def method_missing(method, *args)
      method
    end
  end

  module Jumps
    JUMPS = [:jmp, :je, :jne, :jl, :jle, :jg, :jge].freeze

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
      @jumped       = false
    end

    def label(label_name)
      @labels[label_name] = @instructions.length
    end

    def execute(label = 0)
      @instructions.drop(label).each do |instruction, target, source|
        source = @registers[source] if @registers.keys.include?(source)
        perform_instruction(instruction, target, source)
        break if JUMPS.include?(instruction) and @jumped
      end
      @registers.to_a.map { |element| element.drop(1) }.flatten
    end

    private

    def jump(instruction, target, source)
      @jumped = false
      flag = instruction == :jmp ? 0 : @compare_result
      if flag.send(target, 0)
        @jumped = true
        execute(@labels[source] || source)
      end
    end

    def arithmetic(instruction, target, source)
      instructions = [:'=', :cmp] + JUMPS
      unless instructions.include? instruction
        @registers[target] = @registers[target].send(instruction, source)
      end
    end

    def compare(instruction, target, source)
      source = @registers[source] || source
      if instruction == :cmp
        @compare_result = @registers[target] - source
      end
    end

    def perform_instruction(instruction, target, source)
      @registers[target] = source if instruction == :'='
      compare(instruction, target, source)
      arithmetic(instruction, target, source)
      jump(instruction, :==, target) if instruction == :jmp
      jump(instruction, target, source) if (JUMPS - [:jmp]).include? instruction
    end
  end

  def self.asm(&block)
    program = Assembler.new
    program.instance_eval(&block)
    program.execute
  end
end
class Integer < Numeric
  def prime?
    return false if self < 2
    2.upto(pred).all? { |divisor| self % divisor != 0 }
  end

  def prime_factors
    return [] if abs == 1
    factor = (2..abs).find { |divisor| self % divisor == 0 }
    [factor].concat((abs / factor).prime_factors)
  end

  def harmonic
    1.upto(self).map { |number| Rational(1, number) }.reduce(&:+)
  end

  def digits
    abs.to_s.chars.map(&:to_i)
  end
end

class Array
  def frequencies
    recurrences = Hash.new(0)
    each { |key| recurrences[key] += 1 }
    return recurrences
  end

  def average
    reduce(&:+).to_f  / length unless empty?
  end

  def drop_every(n)
    each_slice(n).map { |slice| slice.take(n - 1) }.reduce(&:+) or []
  end

  def combine_with(other)
    result = []

    if size > other.size
      0.upto(other.size - 1).each { |i| result += [self[i]] + [other[i]] }
      result += self.drop(result.size - 1)
    else
      0.upto(size - 1).each { |i| result += [self[i]] + [other[i]] }
      result += other.drop(result.size - 1)
    end
  end
end
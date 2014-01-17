class Integer < Numeric
  def prime?
    (2...self).map { |divisor| self % divisor != 0 }.all? if self > 0
  end

  def prime_factors
    return [] if self.abs == 1

    factor = (2..self.abs).find { |divisor| self % divisor == 0 }
    [factor].concat((self.abs / factor).prime_factors)

  end

  def harmonic
    return 1.to_r if self == 1
    #sum = 1 / self.to_r + 1 / (self - 1).harmonic
    1.upto(self).inject { |sum, addition| sum.to_r + (1/addition.to_r) }
  end

  def digits
    return [self.abs] if self.abs < 10

    (self.abs / 10).digits.concat [self.abs % 10]
  end
end

class Array
  def frequencies
    recurrences = Hash.new(0)

    each { |key| recurrences[key] += 1 }

    return recurrences
  end

  def average
    inject { |sum, addition| sum + addition }.to_f  / length
  end

  def drop_every(n)
    result = []
    result.replace self

    (n - 1).step(result.size - 1, n - 1) { |i| result.delete_at i }

    return result
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
# frozen_string_literal: true

class Cart
  def subtotal(items)
    items.sum
  end

  def shipping(total)
    return 0 if total > 100

    (total > 50) ? 5 : 10
  end
end

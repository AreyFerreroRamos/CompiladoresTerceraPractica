function pow(a::Float64, n::Int32)::Float64
    acum = a
    i = 1
    for i in 1:n
        acum = acum * a
    end
    return acum
end

result = pow(2.0, 4)
i = 1
total = (1.0 + 2 * 3) - i
while total < 1000.0
    if i % 2 == 1
        total = total * 2
    else
        total = total + 1
    end
    #j = -i
    if total > 666.6 || total == 500.0
        i = i + 1
    end
end
total
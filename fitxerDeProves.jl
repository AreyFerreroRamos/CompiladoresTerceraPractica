function swap(v::Tensor{Int32})
 temp = v[1]
 v[1] = v[2]
 v[2] = temp
 end

 function mean(a::Float64, b::Float64)::Float64
 return (a + b) / 2
 end

 v = [1, 2, 3, 4]
 swap(v)
 x = 10.0 + 7.0
 i = 1
 z = x + mean(x - 7, v[3 + i] * 3.5)

while i < 3 || 2 == 2 && 3 > i
    3 + 4
end

for var in 1:5
    3 + 4
end

for var in 1:i:7
    3 + 4
end

if i>0
    1
elseif (i<0)
    2
elseif (i==0)
    3
elseif (i>=0)
    4
elseif (i>=0)
    5
else
    6
end

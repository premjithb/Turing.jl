using Stats, Distributions, Turing
using Gadfly

import Gadfly.ElementOrFunction

# First add a method to the basic Gadfly.plot function for QQPair types (generated by Distributions.qqbuild())
Gadfly.plot(qq::QQPair, elements::ElementOrFunction...) = Gadfly.plot(x=qq.qx, y=qq.qy, Geom.point, Theme(highlight_width=0px), elements...)

# Now some shorthand functions
qqplot(x, y, elements::ElementOrFunction...) = Gadfly.plot(qqbuild(x, y), elements...)
qqnorm(x, elements::ElementOrFunction...) = qqplot(Normal(), x, Guide.xlabel("Theoretical Normal quantiles"), Guide.ylabel("Observed quantiles"), elements...)


@model gdemo2(x, bkstep) = begin
    y = similar(x)
    if bkstep == false
        # Forward Sample
        s ~ InverseGamma(2,3)
        m ~ Normal(0,sqrt(s))
        y[1] ~ Normal(m, sqrt(s))
        y[2] ~ Normal(m, sqrt(s))
    elseif bkstep == true
        # Backward Step 1: theta ~ theta | x
        s ~ InverseGamma(2,3)
        m ~ Normal(0,sqrt(s))
        x[1] ~ Normal(m, sqrt(s))
        x[2] ~ Normal(m, sqrt(s))
        # Backward Step 2: x ~ x | theta
        y[1] ~ Normal(m, sqrt(s))
        y[2] ~ Normal(m, sqrt(s))
    end
    return s, m, y
end

fw = PG(20, 3000)
# bk = Gibbs(10, PG(10,10, :s, :y), HMC(1, 0.25, 5, :m));
bk = PG(20,10);

s = @sample(gdemo2([1.5, 2], false), fw);
describe(s)

N = 300
x = [s[:y][1]...]
s_bk = Array{Turing.Chain}(N)

for i = 1:N
    s_bk[i] = @sample(gdemo2(x, true), bk);
    x = [s_bk[i][:y][1]...];
end

s2 = vcat(s_bk...);
describe(s2)


qqplot(s[:m], s2[:m])
qqplot(s[:s], s2[:s])
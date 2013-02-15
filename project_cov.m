function w = project_cov(q)

global x

w =  [q(1:2)*x*x'*q(1:2)' + q(3:4)*x*x'*q(3:4)'];
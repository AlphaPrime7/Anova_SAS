#a function to calculate type1error rate
def numbcomp(x):
    nc=(x*(x-1))/2
    return nc

def toerr(a,c): #a=alpha(0.05) and c = # of comparisons from numbcomp
    print("The type 1 error rate is:")
    t1err = 1-((1-a)**c)
    return t1err

def Bonfer_alpha(a,x):# a = alpha, x = # of levels
    new_alpha = a/x
    return new_alpha

print(toerr(0.05,numbcomp(3)))
print(Bonfer_alpha(0.05,3))


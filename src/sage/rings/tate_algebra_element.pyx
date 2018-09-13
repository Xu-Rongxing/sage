from sage.structure.element import coerce_binop
from sage.structure.richcmp import op_EQ, op_NE, op_LT, op_GT, op_LE, op_GE

from sage.structure.element cimport Element
from sage.structure.element cimport MonoidElement
from sage.structure.element cimport CommutativeAlgebraElement

from sage.rings.infinity import Infinity
from sage.rings.integer_ring import ZZ
from sage.rings.rational_field import QQ

from sage.rings.polynomial.polydict cimport PolyDict
from sage.rings.polynomial.polydict cimport ETuple
from sage.rings.padics.padic_generic_element cimport pAdicGenericElement


cdef class TateAlgebraTerm(MonoidElement):
    r"""
    Class for Tate algebra terms

    A term in `R{X_1,\dots,X_n}` is the product of a coefficient in `R` and a
    monomial in the variables `X_1,\dots,X_n`.

    Those terms form a partially ordered monoid, with term multiplication and the
    term order of the parent Tate algebra.

    INPUT:

    - ``coeff`` - the coefficient of the term, in `R`

    - ``exponent`` - a tuple of length ``n`` giving the exponents of the monomial part of the term
    
    EXAMPLES::

        sage: R = Zp(2, print_mode='digits',prec=10); R
        2-adic Ring with capped relative precision 10
        sage: A.<x,y> = TateAlgebra(R); A
        Tate Algebra in x (val >= 0), y (val >= 0) over 2-adic Ring with capped relative precision 10
        sage: T = A.monoid_of_terms(); T
        Monoid of terms in x (val >= 0), y (val >= 0) over 2-adic Ring with capped relative precision 10
        sage: T(2,(1,1))
        (...00000000010)*x*y
        sage: T(0,(1,1))
        (0)*x*y

    """
    def __init__(self, parent, coeff, exponent=None):
        """
        Initialize a Tate algebra term

        INPUT:

        - ``coeff`` - the coefficient of the term, in `R`

        - ``exponent`` - a tuple of length ``n`` giving the exponents of the monomial part of the term

        EXAMPLES::

            sage: R = Zp(2, print_mode='digits',prec=10); R
            2-adic Ring with capped relative precision 10
            sage: A.<x,y> = TateAlgebra(R); A
            Tate Algebra in x (val >= 0), y (val >= 0) over 2-adic Ring with capped relative precision 10
            sage: T = A.monoid_of_terms(); T
            Monoid of terms in x (val >= 0), y (val >= 0) over 2-adic Ring with capped relative precision 10
            sage: T(2,(1,1))
            (...00000000010)*x*y
            sage: T(0,(1,1))
            (0)*x*y

        """
        MonoidElement.__init__(self, parent)
        field = parent.base_ring().fraction_field()
        if isinstance(coeff, TateAlgebraElement):
            coeff = coeff.leading_term()
        if isinstance(coeff, TateAlgebraTerm):
            if coeff.parent().variable_names() != self._parent.variable_names():
                raise ValueError("The variable names do not match")
            self._coeff = field((<TateAlgebraTerm>coeff)._coeff)
            self._exponent = (<TateAlgebraTerm>coeff)._exponent
        else:
            if coeff.is_zero():
                raise ValueError("A term cannot be zero")
            self._coeff = field(coeff)
            self._exponent = ETuple([0] * parent.ngens())
        if exponent is not None:
            if not isinstance(exponent, ETuple):
                exponent = ETuple(exponent)
            self._exponent = self._exponent.eadd(exponent)
        if len(self._exponent) != parent.ngens():
            raise ValueError("The length of the exponent does not match the number of variables")
        for i in self._exponent.nonzero_positions():
            if self._exponent[i] < 0:
                raise ValueError("Only nonnegative exponents are allowed")

    cdef TateAlgebraTerm _new_c(self):
        r"""
        ???
        """
        cdef TateAlgebraTerm ans = TateAlgebraTerm.__new__(TateAlgebraTerm)
        ans._parent = self._parent
        return ans

    def _repr_(self):
        r"""
        Give a printable representation of the Tate algebra term

        EXAMPLES::

            sage: R = Zp(2, print_mode='digits',prec=10); R
            2-adic Ring with capped relative precision 10
            sage: A.<x,y> = TateAlgebra(R); A
            Tate Algebra in x (val >= 0), y (val >= 0) over 2-adic Ring with capped relative precision 10
            sage: T = A.monoid_of_terms(); T
            Monoid of terms in x (val >= 0), y (val >= 0) over 2-adic Ring with capped relative precision 10
            sage: T(2,(1,1)) # indirect doctest
            (...00000000010)*x*y
            sage: print(T(0,(1,1))) # indirect doctest
            (0)*x*y
            sage: T(2,(1,0)) # indirect doctest
            (...00000000010)*x

        
        """
        parent = self._parent
        s = "(%s)" % self._coeff
        for i in range(parent._ngens):
            if self._exponent[i] == 1:
                s += "*%s" % parent._names[i]
            elif self._exponent[i] > 1:
                s += "*%s^%s" % (parent._names[i], self._exponent[i])
        return s

    def coefficient(self):
        r"""
        Return the coefficient of the Tate algebra term

        EXAMPLES::

            sage: R = Zp(2, print_mode='digits',prec=10); R
            2-adic Ring with capped relative precision 10
            sage: A.<x,y> = TateAlgebra(R); A
            Tate Algebra in x (val >= 0), y (val >= 0) over 2-adic Ring with capped relative precision 10
            sage: T = A.monoid_of_terms(); T
            Monoid of terms in x (val >= 0), y (val >= 0) over 2-adic Ring with capped relative precision 10
            sage: t = T(2,(1,1))
            sage: t.coefficient()
            ...00000000010
        
        """
        return self._coeff

    def exponent(self):
        r"""
        Return the exponents of the Tate algebra term

        EXAMPLES::

            sage: R = Zp(2, print_mode='digits',prec=10); R
            2-adic Ring with capped relative precision 10
            sage: A.<x,y> = TateAlgebra(R); A
            Tate Algebra in x (val >= 0), y (val >= 0) over 2-adic Ring with capped relative precision 10
            sage: T = A.monoid_of_terms(); T
            Monoid of terms in x (val >= 0), y (val >= 0) over 2-adic Ring with capped relative precision 10
            sage: t = T(2,(1,1))
            sage: t.exponent()
            (1, 1)
        
        """

        return self._exponent

    cpdef _mul_(self, other):
        r"""
        Multiply the Tate algebra term with another term

        INPUT:

        - ``other`` - a Tate algebra term to multiply with

        EXAMPLES::

            sage: R = Zp(2, print_mode='digits',prec=10); R
            2-adic Ring with capped relative precision 10
            sage: A.<x,y> = TateAlgebra(R); A
            Tate Algebra in x (val >= 0), y (val >= 0) over 2-adic Ring with capped relative precision 10
            sage: T = A.monoid_of_terms(); T
            Monoid of terms in x (val >= 0), y (val >= 0) over 2-adic Ring with capped relative precision 10
            sage: s = T(2,(1,1)); s
            (...00000000010)*x*y
            sage: t = T(3,(2,1)); t
            (...0000000011)*x^2*y
            sage: s*t  # indirect doctest
            (...00000000110)*x^3*y^2
        
        """
        cdef TateAlgebraTerm ans = self._new_c()
        ans._exponent = self._exponent.eadd((<TateAlgebraTerm>other)._exponent)
        ans._coeff = self._coeff * (<TateAlgebraTerm>other)._coeff
        return ans

    #cdef int _cmp_(self, other) except -2:
    #    cdef TateAlgebraTerm s = <TateAlgebraTerm>self
    #    cdef TateAlgebraTerm o = <TateAlgebraTerm>other
    #    c = -cmp(s._valuation_c(), o._valuation_c())
    #    if c: return c
    #    skey = s._parent.term_order().sortkey
    #    c = cmp(skey(s._exponent), skey(o._exponent))
    #    if c: return c
    #    return cmp(s._coeff, o._coeff)

    cpdef _richcmp_(self, other, int op):
        r"""
        Compare the Tate algebra term with another

        The term `a*X^A` is smaller than the term `b*X^B` if `a` has larger
        valuation than `b`, or if `a` and `b` have the same valuation and `A` is
        smaller than `B` for the Tate algebra monomial order.

        INPUT:

        - ``other`` - a Tate algebra term to compare with

        EXAMPLES::

            sage: R = Zp(2, print_mode='digits',prec=10); R
            2-adic Ring with capped relative precision 10
            sage: A.<x,y> = TateAlgebra(R); A
            Tate Algebra in x (val >= 0), y (val >= 0) over 2-adic Ring with capped relative precision 10
            sage: T = A.monoid_of_terms(); T
            Monoid of terms in x (val >= 0), y (val >= 0) over 2-adic Ring with capped relative precision 10
            sage: T.term_order()
            Degree reverse lexicographic term order
            sage: s = T(1,(2,2)); s
            (...0000000001)*x^2*y^2
            sage: t = T(1,(1,3)); t
            (...0000000001)*x*y^3
            sage: s < t # indirect doctest
            False
            sage: s > t # indirect doctest
            True

        ..TODO:: fix this
        
            sage: ss = T(3,(2,2)); ss
            (...0000000011)*x^2*y^2
            sage: s < ss # indirect doctest
            False
            sage: s > ss # indirect doctest
            False
        
        """
        cdef TateAlgebraTerm s = <TateAlgebraTerm>self
        cdef TateAlgebraTerm o = <TateAlgebraTerm>other
        if op == op_EQ:
            return s._coeff == o._coeff and s._exponent == o._exponent
        if op == op_NE:
            return s._coeff != o._coeff or s._exponent != o._exponent
        c = -cmp(s._valuation_c(), o._valuation_c())
        if not c:
            skey = s._parent.term_order().sortkey
            c = cmp(skey(s._exponent), skey(o._exponent))
        if op == op_LT:
            return c < 0
        if op == op_LE:
            return c <= 0
        if op == op_GT:
            return c > 0
        if op == op_GE:
            return c >= 0

    cpdef TateAlgebraTerm monic(self):
        cdef TateAlgebraTerm ans = self._new_c()
        ans._coeff = self._parent.base_ring().fraction_field()(1)
        ans._exponent = self._exponent
        return ans

    def valuation(self):
        return ZZ(self._valuation_c())

    cdef long _valuation_c(self):
        return (<pAdicGenericElement>self._coeff).valuation_c() - <long>self._exponent.dotprod(self._parent._log_radii)

    @coerce_binop
    def is_coprime_with(self, other):
        for i in range(self._parent.ngens()):
            if self._exponent[i] > 0 and other.exponent()[i] > 0:
                return False
        if self._parent.base_ring().is_field():
            return True
        else:
            return self.valuation() == 0 or other.valuation() == 0

    @coerce_binop
    def gcd(self, other):
        return self._gcd_c(other)

    cdef TateAlgebraTerm _gcd_c(self, TateAlgebraTerm other):
        cdef TateAlgebraTerm ans = self._new_c()
        ans._exponent = self._exponent.emin(other._exponent)
        if self._coeff.valuation() < other._coeff.valuation():
            ans._coeff = self._coeff
        else:
            ans._coeff = other._coeff
        return ans

    @coerce_binop
    def lcm(self, other):
        return self._lcm_c(other)

    cdef TateAlgebraTerm _lcm_c(self, TateAlgebraTerm other):
        cdef TateAlgebraTerm ans = self._new_c()
        ans._exponent = self._exponent.emax(other._exponent)
        if self._coeff.valuation() < other._coeff.valuation():
            ans._coeff = other._coeff
        else:
            ans._coeff = self._coeff
        return ans

    @coerce_binop
    def is_divisible_by(self, other, integral=False):
        return (<TateAlgebraTerm?>other)._divides_c(self, integral)
    @coerce_binop
    def divides(self, other, integral=False):
        return self._divides_c(other, integral)

    cdef bint _divides_c(self, TateAlgebraTerm other, bint integral):
        parent = self._parent
        if (integral or not parent.base_ring().is_field()) and self.valuation() > other.valuation():
            return False
        for i in range(parent._ngens):
            if self._exponent[i] > other._exponent[i]:
                return False
        return True

    @coerce_binop
    def __floordiv__(self, other):
        parent = self.parent()
        if not parent.base_ring().is_field() and self.valuation() < other.valuation():
            raise ValueError("The division is not exact")
        for i in range(parent._ngens):
            if self.exponent()[i] < other.exponent()[i]:
                raise ValueError("The division is not exact")
        return (<TateAlgebraTerm>self)._floordiv_c(<TateAlgebraTerm>other)

    cdef TateAlgebraTerm _floordiv_c(self, TateAlgebraTerm other):
        cdef TateAlgebraTerm ans = self._new_c()
        ans._exponent = self.exponent().esub(other.exponent())
        ans._coeff = self._coeff / other._coeff
        return ans


cdef class TateAlgebraElement(CommutativeAlgebraElement):
    r"""
    Define the class for Tate series, elements of Tate algebras.

    Given a complete discrete valuation ring `R`, variables `X_1,\dots,X_k`
    and convergence radii `r_,\dots, r_n` in `\mathbb{R}_{>0}`, a Tate series is an
    element of the Tate algebra `R{X_1,\dots,X_k}`, that is a power series with
    coefficients `a_{i_1,\dots,i_n}` in `R` and such that
    `|a_{i_1,\dots,i_n}|*r_1^{-i_1}*\dots*r_n^{-i_n}` tends to 0 as
    `i_1,\dots,i_n` go towards infinity.

    INPUT:

    - ???


    """
    def __init__(self, parent, x, prec=None, reduce=True):
        r"""
        Initialize a Tate algebra element

        TESTS::

        
        """
        cdef TateAlgebraElement xc
        CommutativeAlgebraElement.__init__(self, parent)
        self._prec = Infinity
        if isinstance(x, TateAlgebraElement):
            xc = <TateAlgebraElement>x
            xparent = x.parent()
            if xparent is parent:
                self._poly = xc._poly
                self._prec = xc._prec
            elif xparent.variable_names() == parent.variable_names():
                ratio = parent._base.absolute_e() / xparent.base_ring().absolute_e()
                for i in range(parent.ngens()):
                    if parent.log_radii()[i] > xparent.log_radii()[i] * ratio:
                        raise ValueError("Cannot restrict to a bigger domain")
                self._poly = xc._poly
                if xc._prec is not Infinity:
                    self._prec = (xc._prec * ratio).ceil()
            else:
                raise TypeError("Variable names do not match")
        elif isinstance(x, TateAlgebraTerm):
            xparent = x.parent()
            if xparent.variable_names() == parent.variable_names():
                ratio = parent._base.absolute_e() / xparent.base_ring().absolute_e()
                for i in range(parent.ngens()):
                    if parent.log_radii()[i] > xparent.log_radii()[i] * ratio:
                        raise ValueError("Cannot restrict to a bigger domain")
                self._poly = PolyDict({(<TateAlgebraTerm>x)._exponent: (<TateAlgebraTerm>x)._coeff})
        else:
            poly = parent._polynomial_ring(x)
            self._poly = PolyDict(poly.dict())
        if prec is not None:
            self._prec = min(self._prec, prec)
        self._normalize()
        self._terms = None

    cdef TateAlgebraElement _new_c(self):
        cdef TateAlgebraElement ans = TateAlgebraElement.__new__(TateAlgebraElement)
        ans._parent = self._parent
        ans._is_normalized = False
        return ans

    cdef _normalize(self):
        self._is_normalized = True
        if self._prec is Infinity: return
        cdef int v
        for (e,c) in self._poly.__repn.iteritems():
            v = (<ETuple>self._parent._log_radii).dotprod(<ETuple>e)
            self._poly.__repn[e] = self._poly.__repn[e].add_bigoh((self._prec - v).ceil())

    def _repr_(self):
        r"""
        Return a printable representation of a Tate series

        The terms are ordered with decreasing term order (increasing valuation of the coefficients, then the monomial order of the parent algebra).

        EXAMPLES::
        
            sage: R = Zp(2, 10, print_mode='digits'); R
            2-adic Ring with capped relative precision 10
            sage: A.<x,y> = TateAlgebra(R); A
            Tate Algebra in x, y over 2-adic Ring with capped relative precision 10
            sage: x + 2*x^2 + x^3
            (...0000000001)*x^3 + (...0000000001)*x + (...00000000010)*x^2
            sage: A(x+2*x^2+x^3,prec=5)
            (...00001)*x^3 + (...00001)*x + (...00010)*x^2 + O(2^5)

        """        
        base = self._parent.base_ring()
        nvars = self._parent.ngens()
        vars = self._parent.variable_names()
        s = ""
        for t in self.terms():
            if t.valuation() >= self._prec:
                continue
            s += " + %s" % t
        if self._prec is not Infinity:
            # Only works with padics...
            s += " + %s" % base.change(show_prec="bigoh")(0, self._prec)
        if s == "":
            return "0"
        return s[3:]

    def polynomial(self):
        r"""
        Return a polynomial representation of the Tate series.

        For series which are not polynomials, the output corresponds to ???
        """
        # TODO: should we make sure that the result is reduced in some cases?
        return self._parent._polynomial_ring(self._poly)

    cpdef _add_(self, other):
        r"""
        Add a Tate series to the Tate series

        The precision of the output is adjusted to the minimum of both precisions.

        EXAMPLES::

            sage: R = Zp(2, 10, print_mode='digits'); R
            2-adic Ring with capped relative precision 10
            sage: A.<x,y> = TateAlgebra(R); A
            Tate Algebra in x, y over 2-adic Ring with capped relative precision 10
            sage: f = x + 2*x^2 + x^3; f
            (...0000000001)*x^3 + (...0000000001)*x + (...00000000010)*x^2
            sage: g = A(x + 2*y^2,prec=5); g
            (...00001)*x + (...00010)*y^2 + O(2^5)
            sage: h=f+g; h # indirect doctest
            (...00001)*x^3 + (...00010)*x^2 + (...00010)*y^2 + (...00010)*x + O(2^5)

        ::

            sage: f.precision_absolute()
            +Infinity
            sage: g.precision_absolute()
            5
            sage: h.precision_absolute()
            5
        """
        # TODO: g = x + 2*y^2 + O(2^5) fails coercing O(2^5) into R, is that normal? If we force conversion with R(O(2^5)) the result is a Tate series with precision infinity... it's understandable but confusing, no? 
        cdef TateAlgebraElement ans = self._new_c()
        ans._poly = self._poly + (<TateAlgebraElement>other)._poly
        ans._prec = min(self._prec, (<TateAlgebraElement>other)._prec)
        if self._prec != (<TateAlgebraElement>other)._prec:
            ans._normalize()
        return ans

    cpdef _neg_(self):
        r"""
        Return the opposite of the Tate series

        EXAMPLES::

            sage: R = Zp(2, 10, print_mode='digits'); R
            2-adic Ring with capped relative precision 10
            sage: A.<x,y> = TateAlgebra(R); A
            Tate Algebra in x, y over 2-adic Ring with capped relative precision 10
            sage: f = x + 2*x^2 + x^3; f
            (...0000000001)*x^3 + (...0000000001)*x + (...00000000010)*x^2
            sage: -f # indirect doctest
            (...1111111111)*x^3 + (...1111111111)*x + (...11111111110)*x^2
        """
        cdef TateAlgebraElement ans = self._new_c()
        ans._poly = -self._poly
        ans._prec = self._prec
        return ans

    cpdef _sub_(self, other):
        r"""
        Return the difference of the Tate series and another

        The precision of the output is adjusted to the minimum of both precisions.

        EXAMPLES::

            sage: R = Zp(2, 10, print_mode='digits'); R
            2-adic Ring with capped relative precision 10
            sage: A.<x,y> = TateAlgebra(R); A
            Tate Algebra in x, y over 2-adic Ring with capped relative precision 10
            sage: f = x + 2*x^2 + x^3; f
            (...0000000001)*x^3 + (...0000000001)*x + (...00000000010)*x^2
            sage: g = A(x + 2*y^2,prec=5); g
            (...00001)*x + (...00010)*y^2 + O(2^5)
            sage: h=f-g; h # indirect doctest
            (...00001)*x^3 + (...00010)*x^2 + (...00010)*y^2 + (...00010)*x + O(2^5)

        ::

            sage: f.precision_absolute()
            +Infinity
            sage: g.precision_absolute()
            5
            sage: h.precision_absolute()
            5
        """
        cdef TateAlgebraElement ans = self._new_c()
        ans._poly = self._poly - (<TateAlgebraElement>other)._poly
        ans._prec = min(self._prec, (<TateAlgebraElement>other)._prec)
        if self._prec != (<TateAlgebraElement>other)._prec:
            ans._normalize()
        return ans

    cpdef _mul_(self, other):
        r"""
        Return the product of the Tate series and another.

        The precision is adjusted to match the best precision on the output.

        EXAMPLES::

            sage: R = Zp(2, 10, print_mode='digits'); R
            2-adic Ring with capped relative precision 10
            sage: A.<x,y> = TateAlgebra(R); A
            Tate Algebra in x, y over 2-adic Ring with capped relative precision 10
            sage: f = 2*x + 4*x^2 + 2*x^3; f
            (...00000000010)*x^3 + (...00000000010)*x + (...000000000100)*x^2
            g = A(x + 2*x^2, prec=5); g
            (...00001)*x + (...00010)*x^2 + O(2^5)
            sage: h = f*g; h # indirect doctest
            (...001010)*x^4 + (...000010)*x^2 + (...000100)*x^5 + (...001000)*x^3 + O(2^6)

        ::

            sage: f.precision_absolute()
            +Infinity
            sage: g.precision_absolute()
            5
            sage: h.precision_absolute()
            6
        """
        cdef TateAlgebraElement ans = self._new_c()
        a = self._prec + (<TateAlgebraElement>other).valuation()
        b = self.valuation() + (<TateAlgebraElement>other)._prec
        ans._poly = self._poly * (<TateAlgebraElement>other)._poly
        ans._prec = min(a, b)
        #ans._normalize()
        return ans

    cpdef _lmul_(self, Element right):
        r"""
        Multiply the series by an element of the base ring.

        EXAMPLES::

            sage: R = Zp(2, print_mode='digits',prec=10)
            sage: A.<x,y> = TateAlgebra(R)
            sage: f = x + 2*x^2 + x^3; f
            (...0000000001)*x^3 + (...0000000001)*x + (...00000000010)*x^2
            sage: R(2)*f # indirect doctest
            (...00000000010)*x^3 + (...00000000010)*x + (...000000000100)*x^2
            sage: R(6)*f # indirect doctest
            (...00000000110)*x^3 + (...00000000110)*x + (...000000001100)*x^2

        """
        cdef TateAlgebraElement ans = self._new_c()
        ans._poly = self._poly.scalar_lmult(right)
        ans._prec = self._prec + (<pAdicGenericElement>self._parent._base(right)).valuation_c()
        return ans

    cdef _term_mul_c(self, TateAlgebraTerm term):
        r"""
        Multiply the series by a Tate term

        EXAMPLES::

            sage: R = Zp(2, print_mode='digits',prec=10); R
            2-adic Ring with capped relative precision 10
            sage: A.<x,y> = TateAlgebra(R); A
            Tate Algebra in x (val >= 0), y (val >= 0) over 2-adic Ring with capped relative precision 10
            sage: t = (3*x^2).terms()[0]; t
            (...0000000011)*x^2
            sage: f = x^4 + 4*x*y + 1; f
            (...0000000001)*x^4 + (...0000000001) + (...000000000100)*x*y
            sage: t*f # indirect doctest
            (...0000000011)*x^6 + (...0000000011)*x^2 + (...000000001100)*x^3*y
        
        """
        cdef TateAlgebraElement ans = self._new_c()
        ans._poly = self._poly.term_lmult(term._exponent, term._coeff)
        ans._prec = self._prec + term._valuation_c()
        return ans

    cdef _positive_lshift_c(self, n):
        r"""
        Multiply the series by the positive `n`'th power of the uniformizer of
        the base ring.
        
        INPUT::

        - ``n`` - a non-negative integer


        EXAMPLES::

            sage: A.<x,y> = TateAlgebra(R)
            sage: f = x + 2*x^2 + x^3; f
            (...0000000001)*x^3 + (...0000000001)*x + (...00000000010)*x^2
            sage: f << 2 # indirect doctest
            (...000000000100)*x^3 + (...000000000100)*x + (...0000000001000)*x^2

        """
        
        cdef dict coeffs = { }
        cdef ETuple e
        cdef Element c
        cdef TateAlgebraElement ans = self._new_c()
        for (e,c) in self._poly.__repn.iteritems():
            coeffs[e] = c << n
        ans._poly = PolyDict(coeffs, self._poly.__zero)
        ans._prec = self._prec + n
        return ans

    cdef _lshift_c(self, n):
        r"""
        Multiply the series by the `n`'th power of the uniformizer of the base ring.

        INPUT::

        - ``n`` - an integer (not necessarily non-negative)


        EXAMPLES::

            sage: A.<x,y> = TateAlgebra(R)
            sage: f = x + 2*x^2 + x^3; f
            (...0000000001)*x^3 + (...0000000001)*x + (...00000000010)*x^2
            sage: f << 2 # indirect doctest
            (...000000000100)*x^3 + (...000000000100)*x + (...0000000001000)*x^2

        If the base ring is not a field and we're shifting by a negative number
        of digits, the result is truncated -- that is, the output is the result
        of the integer division of the Tate series by `\pi^n`.

            sage: f << -1 # indirect doctest
            (...0000000001)*x^2

        """
        cdef dict coeffs = { }
        cdef ETuple e
        cdef Element c
        cdef TateAlgebraElement ans = self._new_c()
        parent = self._parent
        base = parent.base_ring()
        if base.is_field():
            for (e,c) in self._poly.__repn.iteritems():
                coeffs[e] = c << n
            ans._prec = self._prec + n
        else:
            field = base.fraction_field()
            ngens = parent.ngens()
            for (e,c) in self._poly.__repn.iteritems():
                minval = ZZ(e.dotprod(<ETuple>parent._log_radii)).ceil()
                coeffs[e] = field(base(c) >> (minval-n)) << minval
            ans._prec = max(ZZ(0), self._prec - n)
        ans._poly = PolyDict(coeffs, self._poly.__zero)
        return ans

    def __lshift__(self, n):
        r"""
        Multiply the series by the `n`'th power of the uniformizer `\pi`.

        INPUT::

        - ``n`` - an integer (not necessarily non-negative)


        EXAMPLES::

            sage: A.<x,y> = TateAlgebra(R)
            sage: f = x + 2*x^2 + x^3; f
            (...0000000001)*x^3 + (...0000000001)*x + (...00000000010)*x^2
            sage: f << 2 # indirect doctest
            (...000000000100)*x^3 + (...000000000100)*x + (...0000000001000)*x^2

        If the base ring is not a field and we're shifting by a negative number
        of digits, the result is truncated -- that is, the output is the result
        of the integer division of the Tate series by `\pi^n`.

            sage: f << -1 # indirect doctest
            (...0000000001)*x^2
        """
        return (<TateAlgebraElement>self)._lshift_c(n)

    def __rshift__(self, n):
        r"""
        Divide the series by the `n`'th power of the uniformizer `\pi`.

        If the base ring is not a field and ``n`` is positive, the result is
        truncated -- that is, the output is the result of the integer division
        of the Tate series by `\pi^n`.


        INPUT:

        - ``n`` - an integer (not necessarily non-negative)


        EXAMPLES::

            sage: A.<x,y> = TateAlgebra(R)
            sage: f = x + 2*x^2 + x^3; f
            (...0000000001)*x^3 + (...0000000001)*x + (...00000000010)*x^2
            sage: f >> -2 # indirect doctest
            (...000000000100)*x^3 + (...000000000100)*x + (...0000000001000)*x^2
            sage: f >> 1 # indirect doctest
            (...0000000001)*x^2
        """
        return (<TateAlgebraElement>self)._lshift_c(-n)

    def is_zero(self, prec=None):
        r"""
        Test whether the Tate algebra is 0.

        INPUT:

        - ``prec`` - (default: None) an integer which, if specifies, determines the precision of the test.

        EXAMPLES::

            sage: f = x + 2*x^2 + x^3; f
            (...0000000001)*x^3 + (...0000000001)*x + (...00000000010)*x^2
            sage: f.is_zero()
            False
            sage: g = f << 4; g
            (...00000000010000)*x^3 + (...00000000010000)*x + (...000000000100000)*x^2
            sage: g.is_zero()
            False
            sage: g.is_zero(5)
            False
            sage: g.is_zero(4)
            True
        
        """
        if prec is None:
            prec = self._prec
        return self.valuation() >= prec

    def __eq__(self, other):
        r"""
        Test whether the Tate algebra is equal to another

        INPUT:

        - ``other`` - the Tate algebra to compare with

        EXAMPLES::

            sage: R = Zp(2, print_mode='digits',prec=10); R
            2-adic Ring with capped relative precision 10
            sage: A.<x,y> = TateAlgebra(R); A
            Tate Algebra in x (val >= 0), y (val >= 0) over 2-adic Ring with capped relative precision 10
            sage: f = x^4 + 4*x*y + 1; f
            (...0000000001)*x^4 + (...0000000001) + (...000000000100)*x*y
            sage: g = f + 2
            sage: f == g # indirect doctest
            False
            sage: f == (g-2) # indirect doctest
            True

        """
        return (self - other).is_zero()

    def inverse_of_unit(self):
        r"""
        Returns the inverse of the Tate series if invertible.

        EXAMPLES::

            sage: R = Zp(2, print_mode='digits',prec=10); R
            2-adic Ring with capped relative precision 10
            sage: A.<x,y> = TateAlgebra(R); A
            Tate Algebra in x (val >= 0), y (val >= 0) over 2-adic Ring with capped relative precision 10
            sage: f = A(1); f
            (...0000000001)
            sage: f.inverse_of_unit()
            (...0000000001) + O(2^10)
            sage: f = 2*x +1; f
            (...0000000001) + (...00000000010)*x
            sage: f.inverse_of_unit()
            (...0000000001) + (...1111111110)*x + (...0000000100)*x^2 + (...1111111000)*x^3 + (...0000010000)*x^4 + (...1111100000)*x^5 + (...0001000000)*x^6 + (...1110000000)*x^7 + (...0100000000)*x^8 + (...1000000000)*x^9 + O(2^10)
            sage: f = 1+x; f
            (...0000000001)*x + (...0000000001)
            sage: f.inverse_of_unit()
            Traceback (most recent call last)
            ...        
            ValueError: This series in not invertible
        
        """
        if not self.is_unit():
            raise ValueError("This series in not invertible")
        t = self.leading_term()
        c = t.coefficient()
        parent = self._parent
        v, c = c.val_unit()
        cap = parent.precision_cap()
        inv = parent(c.inverse_of_unit(), prec=cap)
        x = self.add_bigoh(cap)
        prec = 1
        while prec < cap:
            prec *= 2
            inv = 2*inv - self*inv*inv
        return inv << v

    def is_unit(self):
        r"""
        Test whether the Tate series is invertible.

        EXAMPLES::

            sage: R = Zp(2, print_mode='digits',prec=10); R
            2-adic Ring with capped relative precision 10
            sage: A.<x,y> = TateAlgebra(R); A
            Tate Algebra in x (val >= 0), y (val >= 0) over 2-adic Ring with capped relative precision 10
            sage: f = 1; f
            1
            sage: f = A(1); f
            (...0000000001)
            sage: f.is_unit()
            True
            sage: f = 2*x +1; f
            (...0000000001) + (...000000000100)*x
            sage: f.is_unit()
            True
            sage: f = 1+x; f
            (...00000000010)*x + (...0000000001)
            sage: f.is_unit()
            False

        """
        if self.is_zero():
            return False
        t = self.leading_term()
        if max(t.exponent()) != 0:
            return False
        base = self.base_ring()
        if not base.is_field() and t.valuation() > 0:
            return False
        return True

    def restriction(self, log_radii):
        r"""
        Restrict the Tate series to a series converging on a smaller domain

        INPUT:

        - ``log_radii`` - the logs of the wanted convergence radii (see the
          definition of the class for the possible specifications)

        EXAMPLES::

            sage: R = Zp(2,prec=10,print_mode='digits'); R
            2-adic Ring with capped relative precision 10
            sage: A.<x,y> = TateAlgebra(R); A
            Tate Algebra in x (val >= 0), y (val >= 0) over 2-adic Ring with capped relative precision 10
            sage: f = x + 2*x^2
            sage: f.restriction(-1)
            (...0000000001)*x + (...00000000010)*x^2
            sage: g = f.restriction(-1)
            sage: g.parent()
            Tate Algebra in x (val >= 1), y (val >= 1) over 2-adic Ring with capped relative precision 10
          
        """
        parent = self._parent
        from sage.rings.tate_algebra import TateAlgebra
        ring = TateAlgebra(self.base_ring(), parent.variable_names(), log_radii, parent.precision_cap(), parent.term_order())
        return ring(self)

    def terms(self):
        r"""
        Return the sorted list of terms of a Tate series

        EXAMPLES::

            sage: R = Zp(2,prec=10,print_mode='digits'); R
            2-adic Ring with capped relative precision 10
            sage: A.<x,y> = TateAlgebra(R); A
            Tate Algebra in x (val >= 0), y (val >= 0) over 2-adic Ring with capped relative precision 10
            sage: f = x + 2*x^2
            sage: f.terms()
            [(...0000000001)*x, (...00000000010)*x^2]
        """
        if not self._is_normalized:
            self._normalize()
            self._terms = None
        return self._terms_c()

    cdef list _terms_c(self):
        if self._terms is not None:
            return self._terms
        cdef TateAlgebraTerm oneterm = self._parent._oneterm
        cdef TateAlgebraTerm term
        self._terms = []
        for (e,c) in self._poly.__repn.iteritems():
            term = oneterm._new_c()
            term._coeff = c
            term._exponent = e
            if term.valuation() < self._prec:
                self._terms.append(term)
        self._terms.sort(reverse=True)
        return self._terms

    def monomials(self):
        if not self._is_normalized:
            self._normalize()
        cdef TateAlgebraTerm oneterm = self._parent._oneterm
        cdef TateAlgebraTerm term
        monomials = []
        for (e,c) in self._poly.__repn.iteritems():
            term = oneterm._new_c()
            term._coeff = oneterm._coeff
            term._exponent = e
            monomials.append(term)
        return monomials

    def coefficients(self):
        r"""
        Return the list of coefficients of the Tate series

        EXAMPLES::

            sage: R = Zp(2,prec=10,print_mode='digits'); R
            2-adic Ring with capped relative precision 10
            sage: A.<x,y> = TateAlgebra(R); A
            Tate Algebra in x (val >= 0), y (val >= 0) over 2-adic Ring with capped relative precision 10
            sage: f = x + 2*x^2
            sage: f.coefficients()
            [...0000000001, ...00000000010]

        """
        return [ t.coefficient() for t in self.terms() ]

    def add_bigoh(self, n):
        r"""
        Truncate the Tate series to `O(\pi^n)` where `\pi` is the uniformizer

        EXAMPLES::

            sage: R = Zp(2,prec=10,print_mode='digits'); R
            2-adic Ring with capped relative precision 10
            sage: A.<x,y> = TateAlgebra(R); A
            Tate Algebra in x (val >= 0), y (val >= 0) over 2-adic Ring with capped relative precision 10
            sage: f = (x + 2*x^2) << 5; f
            (...000000000100000)*x + (...0000000001000000)*x^2
            sage: g = f.add_bigoh(5); g
            O(2^5)
            sage: g = f.add_bigoh(6); g
            (...100000)*x + O(2^6)
            sage: g.precision_absolute()
            6
            sage: g.parent().precision_cap()
            10

        """
        return self._parent(self, prec=n)

    def precision_absolute(self):
        r"""
        Return the precision with which terms of the Tate series is known

        If a term is not part of the terms of the series, then the valuation of
        its coefficient is at least the absolute precision.

        However, individual coefficients may be known with more or less
        precision.

        EXAMPLES::
        
            sage: R = Zp(2,prec=10,print_mode='digits'); R
            2-adic Ring with capped relative precision 10
            sage: A.<x,y> = TateAlgebra(R); A
            Tate Algebra in x (val >= 0), y (val >= 0) over 2-adic Ring with capped relative precision 10
            sage: f = x + 2*x^2; f
            (...0000000001)*x + (...00000000010)*x^2
            sage: f.precision_absolute()
            +Infinity
            sage: g = f.add_bigoh(5); g
            (...00001)*x + (...00010)*x^2 + O(2^5)
            sage: g.precision_absolute()
            5

        The absolute precision may be higher than the precision of the known
        coefficients.

            sage: g = f.add_bigoh(20); g
            (...0000000001)*x + (...00000000010)*x^2 + O(2^20)
            sage: g.precision_absolute()
            20
            sage: g.parent().base_ring().precision_cap()
            10

        """
        return self._prec

    cpdef valuation(self):
        r"""
        Return the valuation of the Tate series

        The valuation of a Tate series `f` over a discrete valuation ring `R`
        with uniformizer `\pi`, is the min of the valuations of the coefficients
        of `f`.  Equivalently, it is the largest `n` such that `\pi^n` divides
        `f` in the integer ring of `R`.  Equivalently, it is the valuation of
        the leading coefficient of `f`.

        EXAMPLES::

            sage: R = Zp(2, print_mode='digits',prec=10); R
            2-adic Ring with capped relative precision 10
            sage: A.<x,y> = TateAlgebra(R); A
            Tate Algebra in x (val >= 0), y (val >= 0) over 2-adic Ring with capped relative precision 10
            sage: f = x^4 + 4*x*y + 1; f
            (...0000000001)*x^4 + (...0000000001) + (...000000000100)*x*y
            sage: f.valuation()
            0
            sage: g = 2*f; g
            (...00000000010)*x^4 + (...00000000010) + (...0000000001000)*x*y
            sage: g.valuation()
            1

        If the base ring is a field, the valuation may be negative. The
        valuation is non-negative if and only if all coefficients of the series
        are integers.

            sage: A.<x,y> = TateAlgebra(R.fraction_field()); A
            Tate Algebra in x (val >= 0), y (val >= 0) over 2-adic Field with capped relative precision 10
            sage: f = x^4 + 4*x*y + 1; f
            (...0000000001)*x^4 + (...0000000001) + (...000000000100)*x*y
            sage: g = f*(1/2); g
            (...000000000.1)*x^4 + (...000000000.1) + (...00000000010)*x*y
            sage: g.valuation()
            -1
        """
        cdef TateAlgebraTerm t
        cdef list terms = self._terms_c()
        if terms:
            return min(terms[0].valuation(), self._prec)
        else:
            return self._prec

    def precision_relative(self):
        """
        Return the relative precision of the Tate series

        The relative precision is defined as the difference between the absolute
        precision and the valuation of the series.

        EXAMPLES::

            sage: R = Zp(2, print_mode='digits',prec=10); R
            2-adic Ring with capped relative precision 10
            sage: A.<x,y> = TateAlgebra(R.fraction_field()); A
            Tate Algebra in x (val >= 0), y (val >= 0) over 2-adic Field with capped relative precision 10
            sage: f = x^4 + 4*x*y + 1; f
            (...0000000001)*x^4 + (...0000000001) + (...000000000100)*x*y
            sage: f.precision_absolute()
            +Infinity
            sage: f.precision_relative()
            +Infinity
            sage: g = f.add_bigoh(5)
            sage: g.precision_absolute()
            5
            sage: g.valuation()
            0
            sage: g.precision_relative()
            5
            sage: h = g + 1/2 ; h
            (...00001.1) + (...00001)*x^4 + (...00100)*x*y + O(2^5)
            sage: h.precision_absolute()
            5
            sage: h.valuation()
            -1
            sage: h.precision_relative()
            6
        """
        return self._prec - self.valuation()

    def leading_term(self):
        r"""
        Return the leading term of the Tate series

        The leading term of a series is the largest term for the order relation
        defined as follows: `a \cdot X^A < b \cdot X^B \iff \mathrm{val}(a) <
        \mathrm{val}(b)` or `\mathrm{val}(a) = \mathrm{val}(b)` and `A < B` for
        the monomial order of the Tate algebra.

        EXAMPLES::

            sage: R = Zp(2, print_mode='digits',prec=10); R
            2-adic Ring with capped relative precision 10
            sage: A.<x,y> = TateAlgebra(R); A
            Tate Algebra in x (val >= 0), y (val >= 0) over 2-adic Ring with capped relative precision 10
            sage: f = x^4 + x*y + 1; f
            (...0000000001)*x^4 + (...0000000001)*x*y + (...0000000001)
            sage: f.leading_term()
            (...0000000001)*x^4
            sage: g = f + x^4; g
            (...0000000001)*x*y + (...0000000001) + (...0000000010)*x^4
            sage: g.leading_coefficient()
            ...0000000001
        """
        # TODO: Examples showing that the order may change when restricting
        terms = self.terms()
        if terms:
            return terms[0]
        else:
            raise ValueError("zero has no leading term")

    def leading_coefficient(self):
        """
        Return the leading coefficient of the Tate series

        The leading coefficient of a series is the coefficient of its leading term.

        EXAMPLES::

            sage: R = Zp(2, print_mode='digits',prec=10); R
            2-adic Ring with capped relative precision 10
            sage: A.<x,y> = TateAlgebra(R); A
            Tate Algebra in x (val >= 0), y (val >= 0) over 2-adic Ring with capped relative precision 10
            sage: f = x^4 + x*y + 1; f
            (...0000000001)*x^4 + (...0000000001)*x*y + (...0000000001)
            sage: f.leading_coefficient()
            ...0000000001
            sage: g = f + x^4; g
            (...0000000001)*x*y + (...0000000001) + (...0000000010)*x^4
            sage: g.leading_coefficient()
            ...0000000001
        
        """
        terms = self.terms()
        if terms:
            return terms[0].coefficient()
        else:
            return self.base_ring()(0)

    def leading_monomial(self):
        terms = self.terms()
        if terms:
            return terms[0].monic()
        else:
            raise ValueError("zero has no leading monomial")

    cpdef monic(self):
        r"""
        Make the Tate series monic

        The Tate series is multiplied by the inverse of its leading
        coefficient. The output is a monic series, that is a series with leading
        coefficient 1.

        By definition of the leading term, if the series had integer
        coefficients, so does its monic counterpart.

        EXAMPLES::

            sage: R = Zp(2, print_mode='digits',prec=10); R
            2-adic Ring with capped relative precision 10
            sage: A.<x,y> = TateAlgebra(R); A
            Tate Algebra in x (val >= 0), y (val >= 0) over 2-adic Ring with capped relative precision 10
            sage: f = 2*x*y + 4*x^4 + 6; f
            (...00000000010)*x*y + (...00000000110) + (...000000000100)*x^4
            sage: f.valuation()
            1
            sage: f.leading_coefficient()
            ...00000000010
            sage: g = f.monic(); g
            (...0000000001)*x*y + (...0000000011) + (...00000000010)*x^4
            sage: g.leading_coefficient()
            ...0000000001
            sage: g.valuation()
            0
        
        """
        cdef TateAlgebraElement ans = self._new_c()
        c = self.leading_coefficient()
        ans._poly = self._poly.scalar_lmult(~c)
        ans._prec = self._prec - c.valuation()
        return ans

    def weierstrass_degree(self):
        r"""
        Return the Weierstrass degree of the Tate series

        The Weierstrass degree is the total degree of the polynomial defined by the
        terms with least valuation in the series.

        EXAMPLES::

            sage: R = Zp(2, print_mode='digits',prec=10); R
            2-adic Ring with capped relative precision 10
            sage: A.<x,y> = TateAlgebra(R); A
            Tate Algebra in x (val >= 0), y (val >= 0) over 2-adic Ring with capped relative precision 10
            sage: f = x*y + 2*x^4 + y; f
            (...0000000001)*x*y + (...0000000001)*y + (...00000000010)*x^4
            sage: f.valuation()
            0
            sage: f.residue(1)
            x*y + y
            sage: f.weierstrass_degree()
            2
        
        """
        v = self.valuation()
        return self.residue(v+1).degree()

    def degree(self):
        r"""
        Return the Weierstrass degree of the Tate series

        The Weierstrass degree is the total degree of the polynomial defined by
        the terms with least valuation in the series.

        EXAMPLES::

            sage: R = Zp(2, print_mode='digits',prec=10); R
            2-adic Ring with capped relative precision 10
            sage: A.<x,y> = TateAlgebra(R); A
            Tate Algebra in x (val >= 0), y (val >= 0) over 2-adic Ring with capped relative precision 10
            sage: f = x*y + 2*x^4 + y; f
            (...0000000001)*x*y + (...0000000001)*y + (...00000000010)*x^4
            sage: f.valuation()
            0
            sage: f.residue(1)
            x*y + y
            sage: f.degree()
            2
        
        """
        
        return self.weierstrass_degree()

    def weierstrass_degrees(self):
        r"""
        Return the Weierstrass degrees of the Tate series

        The Weierstrass degrees are the partial degrees of the polynomial
        defined by the terms with least valuation in the series.

        EXAMPLES::

            sage: R = Zp(2, print_mode='digits',prec=10); R
            2-adic Ring with capped relative precision 10
            sage: A.<x,y> = TateAlgebra(R); A
            Tate Algebra in x (val >= 0), y (val >= 0) over 2-adic Ring with capped relative precision 10
            sage: f = x^2 + y^2 + 2*x^3 + y; f
            (...0000000001)*x^2 + (...0000000001)*y^2 + (...0000000001)*y + (...00000000010)*x^3
            sage: f.valuation()
            0
            sage: f.residue(1)
            x^2 + y^2 + y
            sage: f.weierstrass_degrees()
            (2, 2)
        
        """
        v = self.valuation()
        return self.residue(v+1).degrees()

    def degrees(self):
        r"""
        Return the Weierstrass degrees of the Tate series

        The Weierstrass degrees are the partial degrees of the polynomial
        defined by the terms with least valuation in the series.

        EXAMPLES::

            sage: R = Zp(2, print_mode='digits',prec=10); R
            2-adic Ring with capped relative precision 10
            sage: A.<x,y> = TateAlgebra(R); A
            Tate Algebra in x (val >= 0), y (val >= 0) over 2-adic Ring with capped relative precision 10
            sage: f = x^2 + y^2 + 2*x^3 + y; f
            (...0000000001)*x^2 + (...0000000001)*y^2 + (...0000000001)*y + (...00000000010)*x^3
            sage: f.valuation()
            0
            sage: f.residue(1)
            x^2 + y^2 + y
            sage: f.weierstrass_degrees()
            (2, 2)
            sage: f.degrees()
            (2, 2)
        
        """

        return self.weierstrass_degrees()

    def residue(self, n=None):
        r"""
        Return the residue of the Tate series in some quotient of the base ring

        If `\pi` is the uniformizer of the base ring `R`, the `n`'th residue of
        a series `f` is the image of `f` in `A / \pi^n A`.

        If `n=1`, the output is a polynomial with coefficients in the residue
        field. Otherwise, it is a polynomial with coefficients in the ring `R /
        \pi^n R`.

        Note that by definition of Tate series, the output is always a polynomial.

        INPUT:

        - ``n`` - (default: 1) the power of the uniformizer defining the modulo

        EXAMPLES::

            sage: R = Zp(2, print_mode='digits',prec=10); R
            2-adic Ring with capped relative precision 10
            sage: A.<x,y> = TateAlgebra(R); A
            Tate Algebra in x (val >= 0), y (val >= 0) over 2-adic Ring with capped relative precision 10
            sage: f = x^2 + y^2 + 2*x^3 + y; f
            (...0000000001)*x^2 + (...0000000001)*y^2 + (...0000000001)*y + (...00000000010)*x^3
            sage: f.valuation()
            0
            sage: f.residue()
            x^2 + y^2 + y
            sage: f.residue().parent()
            Multivariate Polynomial Ring in x, y over Ring of integers modulo 2
            sage: f.residue(2)
            2*x^3 + x^2 + y^2 + y
            sage: f.residue(2).parent()
            Multivariate Polynomial Ring in x, y over Ring of integers modulo 4


        The residue can only be computed for series with non-negative valuation.
        
            sage: A.<x,y> = TateAlgebra(R.fraction_field()); A
            Tate Algebra in x (val >= 0), y (val >= 0) over 2-adic Field with capped relative precision 10
            sage: f = x^2 + y^2 + 2*x^3 + y; f
            (...0000000001)*x^2 + (...0000000001)*y^2 + (...0000000001)*y + (...00000000010)*x^3
            sage: f.residue()
            x^2 + y^2 + y
            sage: g = f >> 2; g
            (...00000000.01)*x^2 + (...00000000.01)*y^2 + (...00000000.01)*y + (...000000000.1)*x^3
            sage: g.residue()
            Traceback (most recent call last)
            ...
            ValueError: element must have non-negative valuation in order to compute residue.

        The residue is not implemented for series with convergence radius different from 1.

            sage: A.<x,y> = TateAlgebra(R, log_radii=(2,-1)); A
            Tate Algebra in x (val >= -2), y (val >= 1) over 2-adic Ring with capped relative precision 10
            sage: f = x^2 + y^2 + 2*x^3 + y; f
            (...00000000010000)*x^2 + (...00000000.01)*y^2 + (...000000000.1)*y + (...00000000010000000)*x^3
            sage: f.residue()
            Traceback (most recent call last)
            ...
            NotImplementedError: Residues are only implemented for radius 1

        """
        for r in self._parent.log_radii():
            if r != 0:
                raise NotImplementedError("Residues are only implemented for radius 1")
        if n is None:
            Rn = self.base_ring().residue_field()
        else:
            try:
                Rn = self.base_ring().residue_ring(n)
            except (AttributeError, NotImplementedError):
                Rn = self.base_ring().change(field=False, type="fixed-mod", prec=n)
        poly = self._parent._polynomial_ring(self._poly)
        return poly.change_ring(Rn)

    cdef TateAlgebraElement _mod_c(TateAlgebraElement self, list divisors):
        # TODO: ???
    
        cdef dict coeffs = { }
        cdef TateAlgebraElement f = self._new_c()
        cdef TateAlgebraTerm lt
        cdef list ltds = [ (<TateAlgebraElement>d)._terms_c()[0] for d in divisors ]
        cdef list terms = self._terms_c()
        cdef int index = 0

        f._poly = PolyDict(self._poly.__repn)
        f._prec = self._prec
        while len(terms) > index:
            lt = terms[index]
            if lt._valuation_c() >= f._prec:
                break
            for i in range(len(divisors)):
                if (<TateAlgebraTerm>ltds[i])._divides_c(lt, integral=True):
                    factor = lt._floordiv_c(<TateAlgebraTerm>ltds[i])
                    f = f - (<TateAlgebraElement>divisors[i])._term_mul_c(factor)
                    terms = f._terms_c()
                    index = 0
                    break
            else:
                if coeffs.has_key(lt._exponent):
                    coeffs[lt._exponent] += lt._coeff
                else:
                    coeffs[lt._exponent] = lt._coeff
                del f._poly.__repn[lt._exponent]
                index += 1
        f._poly += PolyDict(coeffs, self._poly.__zero)
        f._terms = None
        return f

    def __mod__(self, divisors):
        if not isinstance(divisors, (list, tuple)):
            divisors = [ divisors ]
        r = (<TateAlgebraElement>self)._mod_c(divisors)
        return r

    def __floordiv__(self, divisors):
        raise NotImplementedError
        q, _ = self.quo_rem(divisors)
        if not isinstance(divisors, (list, tuple)):
            return q[0]
        else:
            q, _ = self.quo_rem(divisors)
            return q

    def reduce(self, I):
        g = I.groebner_basis()
        return self.quo_rem(g)

    @coerce_binop
    def Spoly(self, other):
        try:
            return self._Spoly_c(other)
        except IndexError:
            raise ValueError("Cannot compute the S-polynomial of zero")

    cdef TateAlgebraElement _Spoly_c(self, TateAlgebraElement other):
        cdef TateAlgebraTerm st = self._terms_c()[0]
        cdef TateAlgebraTerm ot = other._terms_c()[0]
        cdef TateAlgebraTerm t = st._lcm_c(ot)
        return self._term_mul_c(t._floordiv_c(st)) - other._term_mul_c(t._floordiv_c(ot))

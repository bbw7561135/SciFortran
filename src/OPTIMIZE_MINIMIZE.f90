  include "optimize_cgfit_routines.f90"
  MODULE MINIMIZE
    USE CGFIT_FUNC_INTERFACE
    USE CGFIT_ROUTINES
    USE DERIVATE, only:f_dgradient
    implicit none
    private
    interface fmin_cg
       module procedure fmin_cg_df,fmin_cg_f
    end interface fmin_cg
    public :: fmin_cg


  contains

    !+-------------------------------------------------------------------+
    !     PURPOSE  : Minimize the Chi^2 distance using conjugate gradient
    !     Adapted by FRPRM subroutine from NumRec (10.6)
    !     Given a starting point P that is a vector of length N, 
    !     the Fletcher-Reeves-Polak-Ribiere minimisation is performed 
    !     n a functin FUNC,using its gradient as calculated by a 
    !     routine DFUNC. The convergence tolerance on the function 
    !     value is input as FTOL.  
    !     Returned quantities are: 
    !     - P (the location of the minimum), 
    !     - ITER (the number of iterations that were performed), 
    !     - FRET (the minimum value of the function). 
    !     The routine LINMIN is called to perform line minimisations.
    !     Minimisation routines: DFPMIN, LINMIN, MNBRAK, BRENT and F1DIM
    !     come from Numerical Recipes.
    !+-------------------------------------------------------------------+
    subroutine fmin_cg_df(p,f,df,iter,fret,ftol,itmax,type)
      procedure(cgfit_func)                :: f
      procedure(cgfit_fjac)                :: df
      real(8), dimension(:), intent(inout) :: p
      integer, intent(out)                 :: iter
      real(8), intent(out)                 :: fret
      real(8),optional                     :: ftol
      real(8)                              :: ftol_
      integer, optional                    :: itmax,type
      integer                              :: itmax_,type_
      real(8), parameter                   :: eps=1.d-9
      integer                              :: its
      real(8)                              :: dgg,fp,gam,gg
      real(8), dimension(size(p))          :: g,h,xi
      !
      if(associated(func))nullify(func) ; func=>f
      if(associated(dfunc))nullify(dfunc) ; dfunc=>df
      !
      ftol_=1.d-12
      itmax_=500
      type_=0
      if(present(ftol))then
         ftol_=ftol
         write(*,"(A,ES9.2)")"CG: ftol updated to:",ftol
      endif
      if(present(itmax))then
         itmax_=itmax
         write(*,"(A,I5)")"CG: itmax updated to:",itmax
      endif
      if(present(type))then
         type_=type
         write(*,"(A,I3)")"CG: type update to:",type
      endif
      !
      fp=func(p)
      xi=dfunc(p)
      g=-xi
      h=g
      xi=h
      do its=1,itmax_
         iter=its
         call linmin(p,xi,fret)
         if (2.0*abs(fret-fp) <= ftol_*(abs(fret)+abs(fp)+eps)) return
         !fp=fret
         fp = func(p) !========modification=======
         xi = dfunc(p)        
         gg=dot_product(g,g)
         select case(type_)
         case (1)
            dgg=dot_product(xi,xi)   !fletcher-reeves.
         case default             
            dgg=dot_product(xi+g,xi)  !polak-ribiere
         end select
         if (gg == 0.0) return
         gam=dgg/gg
         g=-xi
         h=g+gam*h
         xi=h
      end do
      write(*,*)"CG: MatIter",itmax_," exceeded."
      return
    end subroutine fmin_cg_df

    subroutine fmin_cg_f(p,f,iter,fret,ftol,itmax,type)
      procedure(cgfit_func)                :: f
      real(8), dimension(:), intent(inout) :: p
      integer, intent(out)                 :: iter
      real(8), intent(out)                 :: fret
      real(8),optional                     :: ftol
      real(8)                              :: ftol_
      integer, optional                    :: itmax,type
      integer                              :: itmax_,type_
      real(8), parameter                   :: eps=1.d-9
      integer                              :: its
      real(8)                              :: dgg,fp,gam,gg
      real(8), dimension(size(p))          :: g,h,xi
      !
      if(associated(func))nullify(func) ; func=>f
      !
      ftol_=1.d-12
      itmax_=500
      type_=0
      if(present(ftol))then
         ftol_=ftol
         write(*,"(A,ES9.2)")"CG: ftol updated to:",ftol
      endif
      if(present(itmax))then
         itmax_=itmax
         write(*,"(A,I5)")"CG: itmax updated to:",itmax
      endif
      if(present(type))then
         type_=type
         write(*,"(A,I3)")"CG: type update to:",type
      endif
      !
      fp=func(p)
      xi=f_dgradient(func,size(p),p)
      g=-xi
      h=g
      xi=h
      do its=1,itmax_
         iter=its
         call linmin(p,xi,fret)
         if (2.0*abs(fret-fp) <= ftol_*(abs(fret)+abs(fp)+eps)) return
         !fp=fret
         fp = func(p) !========modification=======
         xi = f_dgradient(func,size(p),p)        
         gg=dot_product(g,g)
         select case(type_)
         case (1)
            dgg=dot_product(xi,xi)   !fletcher-reeves.
         case default             
            dgg=dot_product(xi+g,xi)  !polak-ribiere
         end select
         if (gg == 0.0) return
         gam=dgg/gg
         g=-xi
         h=g+gam*h
         xi=h
      end do
      write(*,*)"CG: MatIter",itmax_," exceeded."
      return
    end subroutine fmin_cg_f

  END MODULE MINIMIZE

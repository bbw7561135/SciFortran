!###############################################################
!     PROGRAM  : MPT_FUNX_SOPT
!     TYPE     : Module
!     PURPOSE  : Contains common routines
!     AUTHORS  : Adriano Amaricci
!###############################################################
module MPT_SOPT
  USE IPT_VARS_GLOBAL
  implicit none
  private

  real(8),dimension(:),allocatable    :: A0m,A0p,P1,P2
  integer,allocatable,dimension(:,:)  :: iy_m_ix
  complex(8),dimension(:),allocatable :: fg0,sigma
  real(8),dimension(:),allocatable    :: wr
  real(8)                             :: n,n0,xmu0
  integer,save                        :: loop=1

  public :: solve_mpt_sopt

contains



  !+-------------------------------------------------------------------+
  !PURPOSE  : 
  !+-------------------------------------------------------------------+
  function solve_mpt_sopt(fg0_,wr_,n_,n0_,xmu0_) result(sigma_)
    complex(8),dimension(-L:L) :: fg0_,sigma_
    real(8)                    :: n_,n0_,xmu0_,wr_(-L:L)
    if(loop==1) then
       if(.not.allocated(fg0))allocate(fg0(-L:L))
       if(.not.allocated(sigma))allocate(sigma(-L:L))
       if(.not.allocated(wr))allocate(wr(-L:L))
       call get_frequency_index
    endif
    fg0=fg0_ ; n=n_ ; n0=n0_ ; xmu0=xmu0_ ; wr_=wr ; fmesh=abs(wr(2)-wr(1))
    call simpurity
    sigma_=sigma
    loop=loop+1
  end function solve_mpt_sopt
  !******************************************************************
  !******************************************************************
  !******************************************************************


  !+-------------------------------------------------------------------+
  !PURPOSE  : Create an array of the indices y-x for a faster evaluation
  !+-------------------------------------------------------------------+
  subroutine get_frequency_index()
    integer :: ix,iy,iz
    if(.not.allocated(iy_m_ix))allocate(iy_m_ix(-L:L,-L:L))
    iy_m_ix=0
    do ix=-L,L
       do iy=-L,L
          iz = iy - ix 
          if(iz<-L .OR. iz> L) iz=-L-10 !out of range-> if(iz>-L)
          iy_m_ix(iy,ix)=iz
       enddo
    enddo
    if(.not.allocated(A0m))allocate(A0m(-L:L))
    if(.not.allocated(A0p))allocate(A0p(-L:L))
    if(.not.allocated(P1)) allocate(P1(-L:L))
    if(.not.allocated(P2)) allocate(P2(-L:L))
  end subroutine get_frequency_index
  !******************************************************************
  !******************************************************************
  !******************************************************************





  !+-------------------------------------------------------------------+
  !PURPOSE  : Evaluate the 2^nd-order perturbation theory self-energy
  !+-------------------------------------------------------------------+
  subroutine Simpurity
    real(8) :: A,B
    A=0.d0 ; B=0.d0
    call getAs
    call getPolarization
    call Sopt
    call get_A
    call get_B
    sigma = U*(n-0.5d0) + A*sigma/(1.d0-B*sigma)
  contains
    subroutine get_A
      real(8) :: A1,A2
      A1=n*(1.d0-n)
      A2=n0*(1.d0-n0)
      A=A1/A2
    end subroutine get_A
    subroutine get_B
      real(8) :: B1,B2
      B1 = (xmu0-xmu) + U*(1.d0-2.d0*n)
      B2 = n0*(1.d0-n0)*U**2
      B=B1/B2
    end subroutine get_B
  end subroutine Simpurity
  !******************************************************************
  !******************************************************************
  !******************************************************************







  !+-------------------------------------------------------------------+
  !PURPOSE  : 
  !+-------------------------------------------------------------------+
  subroutine getAs
    integer :: i
    real(8) :: dos
    do i=-L,L       
       dos=-dimag(fg0(i))/pi
       A0p(i) = dos*fermi(wr(i),beta)
       A0m(i) = dos*(1.d0-fermi(wr(i),beta))
    enddo
  end subroutine getAs
  !******************************************************************
  !******************************************************************
  !******************************************************************





  !+-------------------------------------------------------------------+
  !PURPOSE  : 
  !+-------------------------------------------------------------------+
  subroutine getPolarization
    integer :: ix,iy,iz
    real(8) :: sum1,sum2
    do ix=-L,L
       sum1=zero
       sum2=zero
       do iy=-L,L
          iz= iy_m_ix(iy,ix)
          if(iz>-L)then
             sum1=sum1 + A0m(iy)*A0p(iz)
             sum2=sum2 + A0p(iy)*A0m(iz)
          endif
       enddo
       P1(ix)=sum1*fmesh
       P2(ix)=sum2*fmesh
    enddo
  end subroutine getPolarization
  !******************************************************************
  !******************************************************************
  !******************************************************************




  !+-------------------------------------------------------------------+
  !PROGRAM  : SIMPURITY
  !TYPE     : function
  !PURPOSE  : Evaluate the 2^nd-order perturbation theory self-energy
  !+-------------------------------------------------------------------+
  subroutine Sopt
    integer :: ix,iy,iz
    real(8) :: sum1,sum2
    real(8),dimension(-L:L) :: reS,imS
    do ix=-L,L
       sum1=zero
       sum2=zero
       do iy=-L,L
          iz= iy_m_ix(iy,ix)
          if(iz>-L)then
             sum1=sum1+A0p(iy)*P1(iz)*fmesh
             sum2=sum2+A0m(iy)*P2(iz)*fmesh
          end if
       enddo
       imS(ix)=-(U**2)*(sum1+sum2)*pi
    enddo
    reS = kronig(imS,wr,size(ImS))
    sigma = reS + xi*imS
  end subroutine Sopt
  !******************************************************************
  !******************************************************************
  !******************************************************************




end module MPT_SOPT



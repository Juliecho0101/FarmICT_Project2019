--#미경산우 
declare @farm_no int 
set @farm_no = 38 


select 
		 a.LIFE_NUMBER
		 ,ANI_ID as 개체번호 
		,datediff(month,BIRTH_DATE,getdate()) as 월령
		,a.BIRTH_DATE as 생년월일
		,b.max_수정일자 as 마지막수정일
		,datediff(day,b.max_수정일자,getdate()) as 임신기간 
		,b.수정횟수
		,datediff(month,BIRTH_DATE,b.min_수정일자) as 수정개시월령 
		,dateadd(day,280,b.max_수정일자) as 분만예정일
from T4C.ANIMAL  as a 
left outer join (select 
								LIFE_NUMBER
								,LAC_NUMBER
								,min(INSEMINATION_DATE) as min_수정일자
								,max(INSEMINATION_NUMBER) as 수정횟수
								,max(INSEMINATION_DATE) as max_수정일자 
								from T4C.INSEMINATION
								where FARM_NO = @farm_no
								group by LIFE_NUMBER, LAC_NUMBER
								) as b
						on a.LIFE_NUMBER = b.LIFE_NUMBER
where FARM_NO=@farm_no and LAST_LAC_NUMBER=0 and KEEP =1 and ACTIVE=1 and DELETED=0 



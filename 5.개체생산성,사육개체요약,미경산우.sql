--#�̰��� 
declare @farm_no int 
set @farm_no = 38 


select 
		 a.LIFE_NUMBER
		 ,ANI_ID as ��ü��ȣ 
		,datediff(month,BIRTH_DATE,getdate()) as ����
		,a.BIRTH_DATE as �������
		,b.max_�������� as ������������
		,datediff(day,b.max_��������,getdate()) as �ӽűⰣ 
		,b.����Ƚ��
		,datediff(month,BIRTH_DATE,b.min_��������) as �������ÿ��� 
		,dateadd(day,280,b.max_��������) as �и�������
from T4C.ANIMAL  as a 
left outer join (select 
								LIFE_NUMBER
								,LAC_NUMBER
								,min(INSEMINATION_DATE) as min_��������
								,max(INSEMINATION_NUMBER) as ����Ƚ��
								,max(INSEMINATION_DATE) as max_�������� 
								from T4C.INSEMINATION
								where FARM_NO = @farm_no
								group by LIFE_NUMBER, LAC_NUMBER
								) as b
						on a.LIFE_NUMBER = b.LIFE_NUMBER
where FARM_NO=@farm_no and LAST_LAC_NUMBER=0 and KEEP =1 and ACTIVE=1 and DELETED=0 



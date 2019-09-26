--# ��ü���꼺 > ��ü�����꼺
declare @farm_no int , @AniId varchar(30)
set @farm_no = 38
set @AniId =  '101'

; with group_dim as (    ---�����ϼ� group �� �߰� 
select t1.*,
t2.ANI_ID  
, FAT_PERCENTAGE*MILK_DAY_PRODUCTION/100 as fat 
, PROTEIN_PERCENTAGE*MILK_DAY_PRODUCTION/100 as protein 
, LACTOSE_PERCENTAGE*MILK_DAY_PRODUCTION/100 as lactose
,(case when DAY_IN_MILK <= 60 then '<=60' else 
					 case when DAY_IN_MILK <=120 then '<=120' else 
											 case when DAY_IN_MILK <=200 then '<=200' else
																	 case when DAY_IN_MILK <=305 then '<=305' else '>305' 
																	 end
											end
					 end 
	end )  as DimGroup 
from T4C.DAYPRODUCTION as t1 
  left outer join T4C.ANIMAL as t2   on t1.FARM_NO = t2.FARM_NO and t1.LIFE_NUMBER = t2.LIFE_NUMBER  
where t1.FARM_NO = @farm_no and t2.ANI_ID=@AniId and   LAC_NUMBER >0
  ),
 con_feed as (    --��ü�� ���Ļ�� TOTAL, REST, INTAKE (��� �з� other �� �� ����) 
  select 
  t3.LIFE_NUMBER
  ,t4.ANI_ID
  ,t3.FEED_DATE
  ,sum(TOTAL) as con_total
  ,sum(REST) as con_rest 
  ,sum(INTAKE) as con_intake 
  from T4C.FEED_AMOUNT_NEW as t3 
	left outer join T4C.ANIMAL as t4  on t3.FARM_NO = t4.FARM_NO and t3.LIFE_NUMBER =t4.LIFE_NUMBER
  where t3.FARM_NO= @farm_no and t4.ANI_ID=@AniId and  FEED_TYPE = 'Concentrate'
  group by t3.LIFE_NUMBER, t4.ANI_ID , FEED_DATE
  ),
 calving as (
select  
 LIFE_NUMBER
,LAG(LAC_NUMBER,1,NULL) over  (partition by LIFE_NUMBER order by CALVING_NO) as pre_lac_number 
,LAG(CALVING_DATE,1,null) over (partition by LIFE_NUMBER order by CALVING_NO) as pre_calving_date 
,LAG(DRYOFF_DATE,1,null) over (partition by LIFE_NUMBER order by CALVING_NO) as pre_dry_off
,LAC_NUMBER
,CALVING_DATE
,DRYOFF_DATE
from T4C.CALVING 
where FARM_NO = @farm_no 
) ,
ins_calving as ( 
  select 
  t1.LIFE_NUMBER
  ,t1.pre_lac_number
  ,t1.pre_calving_date
  ,t2.ins_no as ����Ƚ��  
  ,t2.ins_date
  ,t1.LAC_NUMBER
  ,t1.CALVING_DATE
  ,datediff(day,t1.pre_calving_date,t1.CALVING_DATE) as �и�����
  ,datediff(day,t2.ins_date, t1.CALVING_DATE) as �ӽűⰣ 
  ,datediff(day,t1.pre_dry_off, t1.CALVING_DATE) as �����Ⱓ
  from calving as t1 
 left outer join (      select 
											LIFE_NUMBER
											,LAC_NUMBER
											,max(INSEMINATION_NUMBER)  as ins_no
											,max(INSEMINATION_DATE) as ins_date 
											from T4C.INSEMINATION
											where FARM_NO = @farm_no
											group by LIFE_NUMBER, LAC_NUMBER
											--order by LIFE_NUMBER, LAC_NUMBER
								) as t2      
								on t1.LIFE_NUMBER = t2.LIFE_NUMBER and t1.pre_lac_number= t2.LAC_NUMBER
) ,
    roll as  (
	select  
				a.LIFE_NUMBER
		        ,a.LAC_NUMBER 
				,a.DimGroup
				,sum(a.MILK_DAY_PRODUCTION) as ����������
				,avg(a.MILK_DAY_PRODUCTION) as ���������
				,count(a.DATE) as �������ϼ�   ------------------------------------
				,avg(b.MDPMILKINGS) as �������Ƚ��
				,avg(a.AVERAGE_WEIGHT) as ���ü�� 
				,sum(c.con_intake) as �ѳ��Ļ�ἷ�뷮
				,avg(c.con_intake) as ��ճ��Ļ�ἷ�뷮
				,sum(a.fat)/sum(a.MILK_DAY_PRODUCTION)*100 as ������
				,sum(a.protein)/sum(a.MILK_DAY_PRODUCTION)*100 as ���ܹ�
				,sum(a.lactose)/sum(a.MILK_DAY_PRODUCTION)*100 as ����
				,avg(a.SCC) as ü����
from  group_dim as a  -- �����Ϸɸ��� ���������� ������ subtotal�� �ʿ���. 
left outer join T4C.DAYPRODUCTIONSQUALITY as b
					 on a.FARM_NO=b.FARM_NO and a.LIFE_NUMBER=b.LIFE_NUMBER and a.DATE =b.DATE 
left outer join con_feed as c 
					on a.LIFE_NUMBER = c.LIFE_NUMBER and a.DATE = c.FEED_DATE 
left outer join [T4C].[RUMINATION] as d
					on a.FARM_NO=d.FARM_NO and a.LIFE_NUMBER = d.LIFE_NUMBER and a.DATE = convert(date,d.RUMINATION_DATETIME,23) 
group by ROLLUP(a.LIFE_NUMBER, a.LAC_NUMBER, DimGroup)  --order by a.LAC_NUMBER, DimGroup
)
select 
 tt1.����������
,tt1.���������
,tt1.�������ϼ�
,tt2.�и�����
,tt2.�ӽűⰣ
,tt2.����Ƚ��
,tt2.�����Ⱓ
,tt1.�������Ƚ��
,tt1.���ü��
,tt1.�ѳ��Ļ�ἷ�뷮
,tt1.��ճ��Ļ�ἷ�뷮
,tt1.ü����
,tt1.������
,tt1.���ܹ�
,tt1.����
from roll as tt1 
left outer join ins_calving as tt2 
					on tt1.LIFE_NUMBER = tt2.LIFE_NUMBER and tt1.LAC_NUMBER = tt2.LAC_NUMBER 


/*
---------------------------------------------------------�׷��� 
-- # ��ü���꼺, ��ü�� ���꼺, �����Ϸ�

--���� 
select 
 a.FARM_NO
,a.LIFE_NUMBER
,b.ANI_ID 
,a.DAY_IN_MILK
,a.LAC_NUMBER
,a.MILK_DAY_PRODUCTION
from T4C.DAYPRODUCTION as a 
 left outer join T4C.ANIMAL as b 
					on a.FARM_NO = b.FARM_NO and a.LIFE_NUMBER = b.LIFE_NUMBER
where a.FARM_NO = @farm_no and b.ANI_ID = @AniId

--x �� DAY_IN_MILK , Y��  MILK_DAY_PRODUCTION    ��Ʈ �� ���� :  LAC_NUMBER 

--����
select 
 a.FARM_NO
,a.LIFE_NUMBER
,b.ANI_ID 
,a.DAY_IN_MILK
,a.LAC_NUMBER
,a.RUMINATION_MINUTES
from T4C.RUMINATION as a 
 left outer join T4C.ANIMAL as b 
					on a.FARM_NO = b.FARM_NO and a.LIFE_NUMBER = b.LIFE_NUMBER
where a.FARM_NO = @farm_no and b.ANI_ID = @AniId

--ü��
select 
 a.FARM_NO
,a.LIFE_NUMBER
,b.ANI_ID 
,a.DAY_IN_MILK
,a.LAC_NUMBER
,a.AVERAGE_WEIGHT
from T4C.DAYPRODUCTION as a 
 left outer join T4C.ANIMAL as b 
					on a.FARM_NO = b.FARM_NO and a.LIFE_NUMBER = b.LIFE_NUMBER
where a.FARM_NO = @farm_no and b.ANI_ID = @AniId

--���Ļ�ἷ�뷮 (�հ�)
    --��ü�� ���Ļ�� TOTAL, REST, INTAKE (��� �з� other �� �� ����)

  select 
   a.LIFE_NUMBER
  ,b.ANI_ID
  ,a.FEED_DATE
  ,a.LAC_NUMBER
  ,a.DAY_IN_MILK
  --,sum(a.TOTAL) as con_total
  --,sum(a.REST) as con_rest 
  ,sum(a.INTAKE) as con_intake 
  from T4C.FEED_AMOUNT_NEW as a 
   left outer join T4C.ANIMAL as b 
					on a.FARM_NO = b.FARM_NO and a.LIFE_NUMBER = b.LIFE_NUMBER
  where a.FARM_NO= @farm_no and b.ANI_ID=@AniId and  a.FEED_TYPE = 'Concentrate'
  group by a.LIFE_NUMBER, b.ANI_ID, a.FEED_DATE,a.LAC_NUMBER, a.DAY_IN_MILK

--������
select 
 a.FARM_NO
,a.LIFE_NUMBER
,b.ANI_ID 
,a.DAY_IN_MILK
,a.LAC_NUMBER
,a.FAT_PERCENTAGE 
from T4C.DAYPRODUCTION as a 
 left outer join T4C.ANIMAL as b 
					on a.FARM_NO = b.FARM_NO and a.LIFE_NUMBER = b.LIFE_NUMBER
where a.FARM_NO = @farm_no and b.ANI_ID = @AniId

--���ܹ�
select 
 a.FARM_NO
,a.LIFE_NUMBER
,b.ANI_ID 
,a.DAY_IN_MILK
,a.LAC_NUMBER
,a.PROTEIN_PERCENTAGE 
from T4C.DAYPRODUCTION as a 
 left outer join T4C.ANIMAL as b 
					on a.FARM_NO = b.FARM_NO and a.LIFE_NUMBER = b.LIFE_NUMBER
where a.FARM_NO = @farm_no and b.ANI_ID = @AniId

--ü���� 
select 
 a.FARM_NO
,a.LIFE_NUMBER
,b.ANI_ID 
,a.DAY_IN_MILK
,a.LAC_NUMBER
,a.SCC
from T4C.DAYPRODUCTION as a 
 left outer join T4C.ANIMAL as b 
					on a.FARM_NO = b.FARM_NO and a.LIFE_NUMBER = b.LIFE_NUMBER
where a.FARM_NO = @farm_no and b.ANI_ID = @AniId


-- # ��ü���꼺, ��ü�� ���꼺, ��������

--� �׷��� �׷������� �� ������ ���ߵ�.   (���̿ø� �׷��� ?  ǻ����Ʈ�� �̷��� ����? ) 

*/
declare @date_s date, @date_f date,  @farm_no int 
set @date_s= '2019-07-10'
set @date_f= '2019-07-15'
set @farm_no = 38

--#�챺���꼺 > �Ϻ� ���꼺 > ���꼺 ���  --���� ������ ��ú����� ���庰 ���� ���� ������ (SCC ��ü�� �κи� �����Ͽ���.)
-- 2019.07.24 fat, protein, lactose ����� ����( �ܼ� ��տ��� ����*����%)  

select 
			a.FARM_NO
			,a.DATE
			,sum(MILK_DAY_PRODUCTION) as ������
			--,FPCM
			,avg(MILK_DAY_PRODUCTION) as �δ����� 
			,count(MILK_DAY_PRODUCTION) as �����μ�
			,sum(a.fat)/sum(MILK_DAY_PRODUCTION)*100 as ������
			,sum(a.protein)/sum(MILK_DAY_PRODUCTION)*100 as ���ܹ�
			,sum(a.lactose)/sum(MILK_DAY_PRODUCTION)*100 as ����
			,sum(a.fat)/sum(a.protein) as 'F/P ratio'
			,avg(a.SCC) as 'SCC ���' 
			,sum(case when a.SCC < 200 then 1 else 0 end) as 'SCC 20�� �̸� ��ü��'
			,sum(case when a.SCC >= 200 and a.SCC<350 then 1 else 0 end) as 'SCC 20��-35��' 
			,sum(case when a.SCC >= 350 and a.SCC <500 then 1 else 0 end) as 'SCC 35��-50��'
			,sum(case when a.SCC >= 500 then 1 else 0 end) as 'SCC 50�� �̻� ��ü��'  
			,avg(b.RUMINATION_MINUTES) as ����
			,avg(c.INTAKE) as �����̷�
			,avg(c.REST)as ����ܷ�
			,avg(a.AVERAGE_WEIGHT) as ü��
			,avg(d.MDPMILKINGS) as ����
			,avg(d.MDPREFUSALS) as ����
			,avg(d.MDPFAILURES) as ���� 
from (select *
			,MILK_DAY_PRODUCTION*FAT_PERCENTAGE/100 as fat
			,MILK_DAY_PRODUCTION*PROTEIN_PERCENTAGE/100 as protein
			,MILK_DAY_PRODUCTION*LACTOSE_PERCENTAGE/100 as lactose 
			 from [T4C].[DAYPRODUCTION] 
			 )as a 
left outer join [T4C].[RUMINATION] as b
					on a.FARM_NO=b.FARM_NO and a.LIFE_NUMBER = b.LIFE_NUMBER and a.DATE = convert(date,b.RUMINATION_DATETIME,23) 
left outer join 
					(select 
					FARM_NO
					,LIFE_NUMBER
					,FEED_DATE 
					,sum(TOTAL) as TOTAL 
					,sum(REST) as REST
					,sum(INTAKE)as INTAKE 
					from [T4C].[FEED_AMOUNT_NEW] 
					where FARM_NO = @farm_no
					group by FARM_NO,LIFE_NUMBER, FEED_DATE
					) as c 
					on a.FARM_NO=c.FARM_NO and a.LIFE_NUMBER = c.LIFE_NUMBER and a.DATE = c.FEED_DATE
left outer join [T4C].[DAYPRODUCTIONSQUALITY] as d 
					 on a.FARM_NO=d.FARM_NO and a.LIFE_NUMBER=d.LIFE_NUMBER and a.DATE =d.DATE 

where a.FARM_NO = @farm_no and a.DATE >= @date_s and a.DATE <= @date_f
group by a.FARM_NO, a.DATE 
order by DATE desc 


--#�챺���꼺 > �Ϻ� ���꼺 > �����챺 Ư��   -- ������ ��ú���� ������ �׸� 
declare @date_s date, @date_f date,  @farm_no int 
set @date_s= '2019-07-10'
set @date_f= '2019-07-15'
set @farm_no = 41

; with MilkingCow as ( 
select 
			a.FARM_NO
			,a.DATE
			,count(a.LIFE_NUMBER) as �������μ� 
			,avg(a.LAC_NUMBER) as ��ջ���
			,avg(a.DAY_IN_MILK) as ��������Ϸ�
from T4C.DAYPRODUCTION as a
where a.FARM_NO = @farm_no and a.DATE >= @date_s and a.DATE <= @date_f
group by a.FARM_NO, a.DATE
) ,
 calving_1 as ( 
select 
				FARM_NO
				,LIFE_NUMBER
				,LAG(LAC_NUMBER,1, NULL) over (partition by FARM_NO, LIFE_NUMBER order by CALVING_NO) as pre_LAC_NUMBER -- CALVING_DATE�� �����ϴ� ���� �� ������ ?
				,LAC_NUMBER
				,LAG(CALVING_DATE,1, NULL) over (partition by FARM_NO, LIFE_NUMBER order by CALVING_NO) as pre_CALVING_DATE
				,CALVING_DATE
				from T4C.CALVING
				where FARM_NO = @farm_no and LAC_NUMBER >0
				),
calving_2 as( 
	select 
	FARM_NO
	,LIFE_NUMBER
	,pre_LAC_NUMBER
	,LAC_NUMBER
	,pre_CALVING_DATE
	,CALVING_DATE
	,datediff(day,pre_CALVING_DATE, CALVING_DATE)  as interval_calving 
	from calving_1
	where pre_LAC_NUMBER > 0
	),
calving_3 as ( 
select 
CALVING_DATE
,avg(interval_calving) as ��պи�����
from calving_2
group by CALVING_DATE 
)

select 
a.*
,b.�и��μ�
,d.��պи�����
,c.�����μ�
from MilkingCow as a 
left outer join (
								select 
								FARM_NO
								,CALVING_DATE
								,count(CALVING_NO) as �и��μ�
								from T4C.CALVING 
								where FARM_NO = @farm_no
								group by FARM_NO, CALVING_DATE  
								) as b 
				on a.DATE = b.CALVING_DATE
left outer join (
								select 
								FARM_NO
								,INSEMINATION_DATE
								,count(INSEMINATION_DATE) as �����μ� 
								from T4C.INSEMINATION
								where FARM_NO = @farm_no
								group by FARM_NO, INSEMINATION_DATE 
								) as c 
				on a.DATE = c.INSEMINATION_DATE  
left outer join calving_3  as d 
				on a.DATE = d.CALVING_DATE
--order by a.DATE  -- �ӵ��� ������  �� �� ;  



--#�챺���꼺 > �Ϻ� ���꼺 > �κ�����
select 
DEVICE_ADDRESS as �κ��ּ�
,convert(date,ROBOT_DATE,23) as �κ���¥
,NUMBER_OF_COWS as ��ü�� 
,MILKING_PER_COW as ��ü��_����Ƚ��
,TOTAL_MILK_WITH_FAILED as ��������_�������� 
,TOTAL_MILK_SEPARATED as �и�������
,MILK_PER_COW as ��ü������
,MILK_PER_MILK as ���������� 
,NUMBER_OF_MILKINGS as ����Ƚ��
,NUMBER_OF_FAILURES as ����Ƚ��
,NUMBER_OF_REFUSALS as ����Ƚ��
, CONVERT(varchar(5),TIME_MILKING/3600)+':'+CONVERT(varchar(5),TIME_MILKING%3600/60) as �����ð�
, CONVERT(varchar(5),TIME_FREE/3600)+':'+CONVERT(varchar(5),TIME_FREE%3600/60) as �����ð�
,PERC_MILING as �����ð�����
,PERC_FEE as �����ð����� ----------------------------------------�����ð������̸���? 
,NUMBER_OF_COW_FEED as �����̰�ü��
,NUMBER_OF_FEED_VISITS as ���湮Ƚ��
,FEED1 as ���1
,FEED2 as ���2
,FEED3 as ���3
,FEED4 as ���4
,FEED5 as ���5
from T4C.ROBOTPERFORMANCE_NEW
where FARM_NO = @farm_no and ROBOT_DATE >= @date_s and ROBOT_DATE <= @date_f
ORDER BY ROBOT_DATE, DEVICE_ADDRESS
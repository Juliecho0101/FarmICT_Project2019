declare @date_s date, @date_f date,  @farm_no int 
set @date_s= '2019-07-10'
set @date_f= '2019-07-15'
set @farm_no = 38

--#우군생산성 > 일별 생산성 > 생산성 요약  --기존 관리자 대시보드의 농장별 요약과 거의 동일함 (SCC 개체수 부분만 수정하였음.)
-- 2019.07.24 fat, protein, lactose 계산방법 변경( 단순 평균에서 유량*지방%)  

select 
			a.FARM_NO
			,a.DATE
			,sum(MILK_DAY_PRODUCTION) as 총유량
			--,FPCM
			,avg(MILK_DAY_PRODUCTION) as 두당유량 
			,count(MILK_DAY_PRODUCTION) as 착유두수
			,sum(a.fat)/sum(MILK_DAY_PRODUCTION)*100 as 유지방
			,sum(a.protein)/sum(MILK_DAY_PRODUCTION)*100 as 유단백
			,sum(a.lactose)/sum(MILK_DAY_PRODUCTION)*100 as 유당
			,sum(a.fat)/sum(a.protein) as 'F/P ratio'
			,avg(a.SCC) as 'SCC 평균' 
			,sum(case when a.SCC < 200 then 1 else 0 end) as 'SCC 20만 미만 개체수'
			,sum(case when a.SCC >= 200 and a.SCC<350 then 1 else 0 end) as 'SCC 20만-35만' 
			,sum(case when a.SCC >= 350 and a.SCC <500 then 1 else 0 end) as 'SCC 35만-50만'
			,sum(case when a.SCC >= 500 then 1 else 0 end) as 'SCC 50만 이상 개체수'  
			,avg(b.RUMINATION_MINUTES) as 반추
			,avg(c.INTAKE) as 사료급이량
			,avg(c.REST)as 사료잔량
			,avg(a.AVERAGE_WEIGHT) as 체중
			,avg(d.MDPMILKINGS) as 착유
			,avg(d.MDPREFUSALS) as 거절
			,avg(d.MDPFAILURES) as 실패 
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


--#우군생산성 > 일별 생산성 > 착유우군 특성   -- 관리자 대시보드와 동일한 항목 
declare @date_s date, @date_f date,  @farm_no int 
set @date_s= '2019-07-10'
set @date_f= '2019-07-15'
set @farm_no = 41

; with MilkingCow as ( 
select 
			a.FARM_NO
			,a.DATE
			,count(a.LIFE_NUMBER) as 총착유두수 
			,avg(a.LAC_NUMBER) as 평균산차
			,avg(a.DAY_IN_MILK) as 평균착유일령
from T4C.DAYPRODUCTION as a
where a.FARM_NO = @farm_no and a.DATE >= @date_s and a.DATE <= @date_f
group by a.FARM_NO, a.DATE
) ,
 calving_1 as ( 
select 
				FARM_NO
				,LIFE_NUMBER
				,LAG(LAC_NUMBER,1, NULL) over (partition by FARM_NO, LIFE_NUMBER order by CALVING_NO) as pre_LAC_NUMBER -- CALVING_DATE로 정렬하는 것이 더 나은가 ?
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
,avg(interval_calving) as 평균분만간격
from calving_2
group by CALVING_DATE 
)

select 
a.*
,b.분만두수
,d.평균분만간격
,c.수정두수
from MilkingCow as a 
left outer join (
								select 
								FARM_NO
								,CALVING_DATE
								,count(CALVING_NO) as 분만두수
								from T4C.CALVING 
								where FARM_NO = @farm_no
								group by FARM_NO, CALVING_DATE  
								) as b 
				on a.DATE = b.CALVING_DATE
left outer join (
								select 
								FARM_NO
								,INSEMINATION_DATE
								,count(INSEMINATION_DATE) as 수정두수 
								from T4C.INSEMINATION
								where FARM_NO = @farm_no
								group by FARM_NO, INSEMINATION_DATE 
								) as c 
				on a.DATE = c.INSEMINATION_DATE  
left outer join calving_3  as d 
				on a.DATE = d.CALVING_DATE
--order by a.DATE  -- 속도가 느려짐  ㅡ ㅡ ;  



--#우군생산성 > 일별 생산성 > 로봇성능
select 
DEVICE_ADDRESS as 로봇주소
,convert(date,ROBOT_DATE,23) as 로봇날짜
,NUMBER_OF_COWS as 개체수 
,MILKING_PER_COW as 개체당_착유횟수
,TOTAL_MILK_WITH_FAILED as 총착유량_실패포함 
,TOTAL_MILK_SEPARATED as 분리된유량
,MILK_PER_COW as 개체당유량
,MILK_PER_MILK as 착유당유량 
,NUMBER_OF_MILKINGS as 착유횟수
,NUMBER_OF_FAILURES as 실패횟수
,NUMBER_OF_REFUSALS as 거절횟수
, CONVERT(varchar(5),TIME_MILKING/3600)+':'+CONVERT(varchar(5),TIME_MILKING%3600/60) as 착유시간
, CONVERT(varchar(5),TIME_FREE/3600)+':'+CONVERT(varchar(5),TIME_FREE%3600/60) as 여유시간
,PERC_MILING as 착유시간비율
,PERC_FEE as 여유시간비율 ----------------------------------------여유시간비율이맞음? 
,NUMBER_OF_COW_FEED as 사료급이개체수
,NUMBER_OF_FEED_VISITS as 사료방문횟수
,FEED1 as 사료1
,FEED2 as 사료2
,FEED3 as 사료3
,FEED4 as 사료4
,FEED5 as 사료5
from T4C.ROBOTPERFORMANCE_NEW
where FARM_NO = @farm_no and ROBOT_DATE >= @date_s and ROBOT_DATE <= @date_f
ORDER BY ROBOT_DATE, DEVICE_ADDRESS
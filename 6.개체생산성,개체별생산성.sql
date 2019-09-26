--# 개체생산성 > 개체별생산성
declare @farm_no int , @AniId varchar(30)
set @farm_no = 38
set @AniId =  '101'

; with group_dim as (    ---비유일수 group 열 추가 
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
 con_feed as (    --개체별 농후사료 TOTAL, REST, INTAKE (사료 분류 other 인 것 제외) 
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
  ,t2.ins_no as 수정횟수  
  ,t2.ins_date
  ,t1.LAC_NUMBER
  ,t1.CALVING_DATE
  ,datediff(day,t1.pre_calving_date,t1.CALVING_DATE) as 분만간격
  ,datediff(day,t2.ins_date, t1.CALVING_DATE) as 임신기간 
  ,datediff(day,t1.pre_dry_off, t1.CALVING_DATE) as 건유기간
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
				,sum(a.MILK_DAY_PRODUCTION) as 누적산유량
				,avg(a.MILK_DAY_PRODUCTION) as 일평균유량
				,count(a.DATE) as 총착유일수   ------------------------------------
				,avg(b.MDPMILKINGS) as 평균착유횟수
				,avg(a.AVERAGE_WEIGHT) as 평균체중 
				,sum(c.con_intake) as 총농후사료섭취량
				,avg(c.con_intake) as 평균농후사료섭취량
				,sum(a.fat)/sum(a.MILK_DAY_PRODUCTION)*100 as 유지방
				,sum(a.protein)/sum(a.MILK_DAY_PRODUCTION)*100 as 유단백
				,sum(a.lactose)/sum(a.MILK_DAY_PRODUCTION)*100 as 유당
				,avg(a.SCC) as 체세포
from  group_dim as a  -- 비유일령마다 보여주지만 산차별 subtotal이 필요함. 
left outer join T4C.DAYPRODUCTIONSQUALITY as b
					 on a.FARM_NO=b.FARM_NO and a.LIFE_NUMBER=b.LIFE_NUMBER and a.DATE =b.DATE 
left outer join con_feed as c 
					on a.LIFE_NUMBER = c.LIFE_NUMBER and a.DATE = c.FEED_DATE 
left outer join [T4C].[RUMINATION] as d
					on a.FARM_NO=d.FARM_NO and a.LIFE_NUMBER = d.LIFE_NUMBER and a.DATE = convert(date,d.RUMINATION_DATETIME,23) 
group by ROLLUP(a.LIFE_NUMBER, a.LAC_NUMBER, DimGroup)  --order by a.LAC_NUMBER, DimGroup
)
select 
 tt1.누적산유량
,tt1.일평균유량
,tt1.총착유일수
,tt2.분만간격
,tt2.임신기간
,tt2.수정횟수
,tt2.건유기간
,tt1.평균착유횟수
,tt1.평균체중
,tt1.총농후사료섭취량
,tt1.평균농후사료섭취량
,tt1.체세포
,tt1.유지방
,tt1.유단백
,tt1.유당
from roll as tt1 
left outer join ins_calving as tt2 
					on tt1.LIFE_NUMBER = tt2.LIFE_NUMBER and tt1.LAC_NUMBER = tt2.LAC_NUMBER 


/*
---------------------------------------------------------그래프 
-- # 개체생산성, 개체별 생산성, 착유일령

--유량 
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

--x 축 DAY_IN_MILK , Y축  MILK_DAY_PRODUCTION    차트 색 구분 :  LAC_NUMBER 

--반추
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

--체중
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

--농후사료섭취량 (합계)
    --개체별 농후사료 TOTAL, REST, INTAKE (사료 분류 other 인 것 제외)

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

--유지방
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

--유단백
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

--체세포 
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


-- # 개체생산성, 개체별 생산성, 산차기준

--어떤 그래프 그려야할지 좀 생각해 봐야됨.   (바이올린 그래프 ?  퓨전차트에 이런게 있음? ) 

*/
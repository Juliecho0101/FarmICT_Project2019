
----일평균 착유정보, 사료급이정보 항목 -- 

declare @date_s date, @date_f date, @aniid  int
set @date_s = '2019-01-01'
set @date_f = '2019-05-31'


;with lac_tb as (
   select
      c.FARM_NAME
	  ,b.FARM_NO
	  ,LacAniId
	  ,b.AniUserNumber
	  ,b.AniName
      ,LacNumber
      ,LacCalvingDate
      ,LEAD(LacCalvingDate, 1, getdate()) OVER (PARTITION BY a.farm_no, LacAniId ORDER BY LacNumber) nextLacCalvingDate
   from lely_collect_farm_RemLactation a
    left outer join lely_collect_farm_HemAnimal  as b on a.LacAniId=b.AniId and a.FARM_NO=b.FARM_NO
	left outer join LELY_COLLECT_FARM as c on a.FARM_NO=c.FARM_NO
	where LacNumber>0
	)

select
목장명, 개체시스템번호, 개체사용자번호, 산차, 착유일자,분만후일령,  
착유횟수, 거절횟수, 실패횟수, 일평균유량, 유지방, 유단백, 유당, 체세포, 일평균체중, 체중_smooth_wt,
급이_농후사료,급이_글리세롤등, 일평균반추, HealthIndex
from 
		(
		 select
		t1.FARM_NO 
		,t1.FARM_NAME as 목장명
		,t1.LacAniId as 개체시스템번호
		,t1.AniUserNumber as 개체사용자번호
		,t1.AniName as 개체이름
		,t1.LacNumber as 산차
		,convert(date, t2.MdpProductionDate, 112) as 착유일자
		,datediff(dd, t1.LacCalvingDate, t2.MdpProductionDate) as 분만후일령
		,MdpDayProduction as 일평균유량
   		,MdpMilkings as 착유횟수
		,MdpRefusals as 거절횟수
		,MdpFailures as 실패횟수
		,MdpFatPercentage as 유지방
		,MdpProteinPercentage as 유단백
		,MdpLactosePercentage as 유당
		,MdpSCC as 체세포
		,MdpAverageWeight as 일평균체중
		,MdpSmoothedWeight as 체중_smooth_wt
		from lac_tb t1, lely_collect_farm_PrmMilkDayProduction  t2
		where t1.LacAniId = t2.MdpAniId and t2.MdpProductionDate >= t1.LacCalvingDate and t2.MdpProductionDate < t1.nextLacCalvingDate
		and t2.MdpProductionDate between @date_s and @date_f and t1.FARM_NO=t2.FARM_NO
		) tt1						
        left outer join 	-- 사료, 사료타입(농후, 글리세롤(기타))으로 구분함
					(
					select
					cc.FARM_NO
					,FadAniId
					,convert(date, FadDate, 112)  fad_date
					,sum(case when aa.FeeFtyId=2 then FadTotalItake else null end) as 급이_농후사료
					,sum(case when aa.FeeFtyId=4 then FadTotalItake else null end) as 급이_글리세롤등
					FROM lely_collect_farm_PrmFeedAppliedDaily as cc
					left outer join LELY_COLLECT_FARM_LimFeed as aa on aa.FARM_NO=cc.FARM_NO and aa.FeeId=FadFeeId
					where FadDate>=@date_s and FadDate<=@date_f 
					group by cc.FARM_NO, FadAniId, FadDate
					) feed on feed.FadAniId=tt1.개체시스템번호 and feed.fad_date=tt1.착유일자 and tt1.FARM_NO=feed.FARM_NO
		 left outer join -- 활동량은 일평균이 의미없다고 생각되어 제외함, 22시의 값을 기준으로 함
					(
					 select
					 FARM_NO, AscAniId, convert(date,AscCellTime,113) as asc_date, AscTotalRuminationTime as 일평균반추, AscHealthIndex100 as HealthIndex
					 from LELY_COLLECT_FARM_PrmActivityScr  where  datepart(hh, AscCellTime) =22 
					  ) activityscr on activityscr.AscAniId=tt1.개체시스템번호 and activityscr.asc_date=tt1.착유일자 and activityscr.FARM_NO=tt1.FARM_NO 
 order by 목장명, 개체시스템번호, 착유일자
  


  
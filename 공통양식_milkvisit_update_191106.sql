
/** 
-- 장비 방문건으로 변경함. 착유방문건만 필요하면 하단에 milk_visit 조건 처리
-- 코스믹스등의 장비방문건은 방문결과에 etc로 처리했음
-- 사료는 농후사료와 그외 사료 합계 (g) 으로 조회함
**/

declare @date_s date, @date_f date, @aniid  int
set @date_s = '2014-01-01'
set @date_f = '2019-10-31'


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
   where b.farm_no >20 and b.farm_no <30 and LacNumber>0
)

SELECT
목장명, 장비번호 , 장비이름,개체시스템번호 , 개체사용자번호, 개체이름
,LacNumber as 산차, datediff(d, LacCalvingDate, 착유일자) as 분만후일령
,착유일자, 방문시간, 종료시간, 방문간격, 로봇체류시간,방문결과,
유량, 유량_M, 유량_exp, 유지방, 유단백, 유당,cellcount ,최대착유속도, 우유온도
,전도도_좌앞, 전도도_좌뒤, 전도도_우앞, 전도도_우뒤
,체세포_좌앞, 체세포_좌뒤, 체세포_우앞, 체세포_우뒤
,Pre_TreatmentTime, ConnectTime, Post_TreatmentTtime, Milk_Time
,젖내림시간_좌앞, 젖내림시간_좌뒤, 젖내림시간_우앞, 젖내림시간_우뒤
,착유시간_좌앞, 착유시간_좌뒤, 착유시간_우앞, 착유시간_우뒤
,(select Cconame from LELY_COLLECT_CODE_LimColorCode where CcoLdeItemId=색상코드1_좌앞) +
 (select Cconame from LELY_COLLECT_CODE_LimColorCode where CcoLdeItemId=색상코드2_좌앞) as 색상_좌앞
,(select Cconame from LELY_COLLECT_CODE_LimColorCode where CcoLdeItemId=색상코드1_좌뒤) +
(select Cconame from LELY_COLLECT_CODE_LimColorCode where CcoLdeItemId=색상코드2_좌뒤) as 색상_좌뒤
,(select Cconame from LELY_COLLECT_CODE_LimColorCode where CcoLdeItemId=색상코드1_우앞) +
(select Cconame from LELY_COLLECT_CODE_LimColorCode where CcoLdeItemId=색상코드2_우앞) as 색상_우앞
,(select Cconame from LELY_COLLECT_CODE_LimColorCode where CcoLdeItemId=색상코드1_우뒤) +
(select Cconame from LELY_COLLECT_CODE_LimColorCode where CcoLdeItemId=색상코드2_우뒤) as 색상_우뒤
,사료급이_농후, 사료급이_기타


FROM 
(
SELECT 
     FARM.FARM_NAME AS 목장명
    ,device.DevAddress as 장비번호
    ,device.DevName as 장비이름
     ,a.DviAniId  as 개체시스템번호
    ,ani.AniUserNumber as 개체사용자번호
    ,ani.AniName as 개체이름
    ,convert(date, a.DviDayDate,113) as 착유일자
     ,a.DviIntervalTime as 방문간격
    ,a.DviStartTime as 방문시간
    ,a.DviEndTime as 종료시간
    ,(case when a.DviMilkVisit=0 then 'etc' else  case when a.DviRefusal=1 then 'refusal' else case when DviFailure=1 then 'failure' else 'succ' end end end) as 방문결과
    , datediff(ss, a.DviStartTime , a.DviEndTime) as 로봇체류시간
    ,MviPreTreatmentTime as Pre_TreatmentTime
    ,MviConnectTime as ConnectTime
    ,MviPostTreatmentTime as Post_TreatmentTtime
    ,MviMilkDuration as Milk_Time
         
     ,b.MviMilkYield as 유량
      ,b.MviMilkYieldMAvg as 유량_M
     ,b.MviMilkYieldExp as 유량_exp
      ,b.MviMilkFat as 유지방
     ,b.MviMilkProtein as 유단백
     ,b.MviMilkLactose as 유당
     ,b.MviCellCountUdder as cellcount
     ,b.MviMilkSpeedMax as 최대착유속도
     ,b.MviMilkTemperature as 우유온도  


     ,FeedIntake_t2 as 사료급이_농후
     ,FeedIntake_te  as 사료급이_기타
     
     ,  b.MviLFDeadMilkTime  as 젖내림시간_좌앞
      ,  b.MviLRDeadMilkTime  as 젖내림시간_좌뒤
     ,  b.MviRFDeadMilkTime  as 젖내림시간_우앞
      , b.MviRRDeadMilkTime  as 젖내림시간_우뒤
     
     ,  b.MviLFMilkTime  as 착유시간_좌앞
      ,  b.MviLRMilkTime  as 착유시간_좌뒤
     ,  b.MviRFMilkTime  as 착유시간_우앞
     ,  b.MviRRMilkTime  as 착유시간_우뒤
      
     ,b.MviLFSCC as 체세포_좌앞
     ,b.MviLRSCC as 체세포_좌뒤
     ,b.MviRFSCC as 체세포_우앞
     ,b.MviRRSCC as 체세포_우뒤

     ,b.MviLFConductivity as 전도도_좌앞
     ,b.MviLRConductivity as 전도도_좌뒤
     ,b.MviRFConductivity as 전도도_우앞
     ,b.MviRRConductivity as 전도도_우뒤
      
     ,case when MviLFColourCodeName is not null  and charindex(']',MviLFColourCodeName) =2 then NULL else
      case when MviLFColourCodeName is not null  and charindex(']',MviLFColourCodeName) =6 
                     then substring(MviLFColourCodeName, 2,4) else null end end  as 색상코드1_좌앞
      ,case when MviLFColourCodeName is not null  and charindex('[',MviLFColourCodeName) =1 
                     then substring(MviLFColourCodeName, charindex(']',MviLFColourCodeName)+2 ,4) else
      case when MviLFColourCodeName is not null and charindex('[',MviLFColourCodeName) <>1  
                     then right(MviLFColourCodeName, 4) else null end end  as 색상코드2_좌앞

     ,case when MviLRColourCodeName is not null  and charindex(']',MviLRColourCodeName) =2 then NULL else
      case when MviLRColourCodeName is not null  and charindex(']',MviLRColourCodeName) =6 
                     then substring(MviLRColourCodeName, 2,4) else null end end  as 색상코드1_좌뒤
      ,case when MviLRColourCodeName is not null  and charindex('[',MviLRColourCodeName) =1 
                     then substring(MviLRColourCodeName, charindex(']',MviLRColourCodeName)+2 ,4) else
      case when MviLRColourCodeName is not null and charindex('[',MviLRColourCodeName) <>1  
                     then right(MviLRColourCodeName, 4) else null end end  as 색상코드2_좌뒤

     ,case when MviRFColourCodeName is not null  and charindex(']',MviRFColourCodeName) =2 then NULL else
      case when MviRFColourCodeName is not null  and charindex(']',MviRFColourCodeName) =6 
                     then substring(MviRFColourCodeName, 2,4) else null end end  as 색상코드1_우앞
      ,case when MviRFColourCodeName is not null  and charindex('[',MviRFColourCodeName) =1 
                     then substring(MviRFColourCodeName, charindex(']',MviRFColourCodeName)+2 ,4) else
      case when MviRFColourCodeName is not null and charindex('[',MviRFColourCodeName) <>1  
                     then right(MviRFColourCodeName, 4) else null end end  as 색상코드2_우앞

     ,case when MviRRColourCodeName is not null  and charindex(']',MviRRColourCodeName) =2 then NULL else
      case when MviRRColourCodeName is not null  and charindex(']',MviRRColourCodeName) =6 
                     then substring(MviRRColourCodeName, 2,4) else null end end  as 색상코드1_우뒤
      ,case when MviRRColourCodeName is not null  and charindex('[',MviRRColourCodeName) =1 
                     then substring(MviRRColourCodeName, charindex(']',MviRRColourCodeName)+2 ,4) else
      case when MviRRColourCodeName is not null and charindex('[',MviRRColourCodeName) <>1  
                     then right(MviRRColourCodeName, 4) else null end end  as 색상코드2_우뒤
   
  FROM LELY_COLLECT_FARM_PrmDeviceVisit as a  
  left outer join  LELY_COLLECT_FARM_PrmMilkVisit as b on a.DviId=b.MviDviId AND A.FARM_NO=B.FARM_NO
  left outer join (
                     select
                     aa.FARM_NO,aa.FviDviId,  
                     sum(case when bb.feeftyid=2 then fviintake else null end) as FeedIntake_t2,
                     sum(case when bb.feeftyid<>2 then fviintake else null end) as FeedIntake_te
                     from LELY_COLLECT_FARM_PrmDeviceVisit as tt 
                     inner join LELY_COLLECT_FARM_PrmFeedVisit as aa  on tt.FARM_NO=aa.FARM_NO and tt.DviId=aa.FviDviId
                     inner join LELY_COLLECT_FARM_LimFeed as bb on aa.FviFeeId=bb.FeeId and aa.FARM_NO=bb.FARM_NO 
                     where tt.DviDayDate  between @date_s and @date_f
                      group by aa.FARM_NO, aa.FviDviId
                     ) as c on a.dviid=c.FviDviId and a.FARM_NO=c.FARM_NO
  left outer join LELY_COLLECT_FARM_DemDevice as device on a.DviDevId=device.DevId AND A.FARM_NO=device.FARM_NO
  left outer join LELY_COLLECT_FARM_HemAnimal as ani on a.DviAniId=ani.AniId AND A.FARM_NO=ani.FARM_NO
  left outer join  LELY_COLLECT_FARM AS FARM ON A.FARM_NO=FARM.FARM_NO

 where 
  a.DviDayDate between @date_s and @date_f
 --and a.DviMilkVisit=1
 
 ) T1 , lac_tb T2 
 where t1.목장명=T2.FARM_NAME and T1.개체시스템번호=T2.LacAniId and  착유일자>=LacCalvingDate and 착유일자<nextLacCalvingDate

 order by 목장명, 개체시스템번호, 방문시간
  


  
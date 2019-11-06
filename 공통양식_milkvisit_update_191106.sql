
/** 
-- ��� �湮������ ������. �����湮�Ǹ� �ʿ��ϸ� �ϴܿ� milk_visit ���� ó��
-- �ڽ��ͽ����� ���湮���� �湮����� etc�� ó������
-- ���� ���Ļ��� �׿� ��� �հ� (g) ���� ��ȸ��
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
�����, ����ȣ , ����̸�,��ü�ý��۹�ȣ , ��ü����ڹ�ȣ, ��ü�̸�
,LacNumber as ����, datediff(d, LacCalvingDate, ��������) as �и����Ϸ�
,��������, �湮�ð�, ����ð�, �湮����, �κ�ü���ð�,�湮���,
����, ����_M, ����_exp, ������, ���ܹ�, ����,cellcount ,�ִ������ӵ�, �����µ�
,������_�¾�, ������_�µ�, ������_���, ������_���
,ü����_�¾�, ü����_�µ�, ü����_���, ü����_���
,Pre_TreatmentTime, ConnectTime, Post_TreatmentTtime, Milk_Time
,�������ð�_�¾�, �������ð�_�µ�, �������ð�_���, �������ð�_���
,�����ð�_�¾�, �����ð�_�µ�, �����ð�_���, �����ð�_���
,(select Cconame from LELY_COLLECT_CODE_LimColorCode where CcoLdeItemId=�����ڵ�1_�¾�) +
 (select Cconame from LELY_COLLECT_CODE_LimColorCode where CcoLdeItemId=�����ڵ�2_�¾�) as ����_�¾�
,(select Cconame from LELY_COLLECT_CODE_LimColorCode where CcoLdeItemId=�����ڵ�1_�µ�) +
(select Cconame from LELY_COLLECT_CODE_LimColorCode where CcoLdeItemId=�����ڵ�2_�µ�) as ����_�µ�
,(select Cconame from LELY_COLLECT_CODE_LimColorCode where CcoLdeItemId=�����ڵ�1_���) +
(select Cconame from LELY_COLLECT_CODE_LimColorCode where CcoLdeItemId=�����ڵ�2_���) as ����_���
,(select Cconame from LELY_COLLECT_CODE_LimColorCode where CcoLdeItemId=�����ڵ�1_���) +
(select Cconame from LELY_COLLECT_CODE_LimColorCode where CcoLdeItemId=�����ڵ�2_���) as ����_���
,������_����, ������_��Ÿ


FROM 
(
SELECT 
     FARM.FARM_NAME AS �����
    ,device.DevAddress as ����ȣ
    ,device.DevName as ����̸�
     ,a.DviAniId  as ��ü�ý��۹�ȣ
    ,ani.AniUserNumber as ��ü����ڹ�ȣ
    ,ani.AniName as ��ü�̸�
    ,convert(date, a.DviDayDate,113) as ��������
     ,a.DviIntervalTime as �湮����
    ,a.DviStartTime as �湮�ð�
    ,a.DviEndTime as ����ð�
    ,(case when a.DviMilkVisit=0 then 'etc' else  case when a.DviRefusal=1 then 'refusal' else case when DviFailure=1 then 'failure' else 'succ' end end end) as �湮���
    , datediff(ss, a.DviStartTime , a.DviEndTime) as �κ�ü���ð�
    ,MviPreTreatmentTime as Pre_TreatmentTime
    ,MviConnectTime as ConnectTime
    ,MviPostTreatmentTime as Post_TreatmentTtime
    ,MviMilkDuration as Milk_Time
         
     ,b.MviMilkYield as ����
      ,b.MviMilkYieldMAvg as ����_M
     ,b.MviMilkYieldExp as ����_exp
      ,b.MviMilkFat as ������
     ,b.MviMilkProtein as ���ܹ�
     ,b.MviMilkLactose as ����
     ,b.MviCellCountUdder as cellcount
     ,b.MviMilkSpeedMax as �ִ������ӵ�
     ,b.MviMilkTemperature as �����µ�  


     ,FeedIntake_t2 as ������_����
     ,FeedIntake_te  as ������_��Ÿ
     
     ,  b.MviLFDeadMilkTime  as �������ð�_�¾�
      ,  b.MviLRDeadMilkTime  as �������ð�_�µ�
     ,  b.MviRFDeadMilkTime  as �������ð�_���
      , b.MviRRDeadMilkTime  as �������ð�_���
     
     ,  b.MviLFMilkTime  as �����ð�_�¾�
      ,  b.MviLRMilkTime  as �����ð�_�µ�
     ,  b.MviRFMilkTime  as �����ð�_���
     ,  b.MviRRMilkTime  as �����ð�_���
      
     ,b.MviLFSCC as ü����_�¾�
     ,b.MviLRSCC as ü����_�µ�
     ,b.MviRFSCC as ü����_���
     ,b.MviRRSCC as ü����_���

     ,b.MviLFConductivity as ������_�¾�
     ,b.MviLRConductivity as ������_�µ�
     ,b.MviRFConductivity as ������_���
     ,b.MviRRConductivity as ������_���
      
     ,case when MviLFColourCodeName is not null  and charindex(']',MviLFColourCodeName) =2 then NULL else
      case when MviLFColourCodeName is not null  and charindex(']',MviLFColourCodeName) =6 
                     then substring(MviLFColourCodeName, 2,4) else null end end  as �����ڵ�1_�¾�
      ,case when MviLFColourCodeName is not null  and charindex('[',MviLFColourCodeName) =1 
                     then substring(MviLFColourCodeName, charindex(']',MviLFColourCodeName)+2 ,4) else
      case when MviLFColourCodeName is not null and charindex('[',MviLFColourCodeName) <>1  
                     then right(MviLFColourCodeName, 4) else null end end  as �����ڵ�2_�¾�

     ,case when MviLRColourCodeName is not null  and charindex(']',MviLRColourCodeName) =2 then NULL else
      case when MviLRColourCodeName is not null  and charindex(']',MviLRColourCodeName) =6 
                     then substring(MviLRColourCodeName, 2,4) else null end end  as �����ڵ�1_�µ�
      ,case when MviLRColourCodeName is not null  and charindex('[',MviLRColourCodeName) =1 
                     then substring(MviLRColourCodeName, charindex(']',MviLRColourCodeName)+2 ,4) else
      case when MviLRColourCodeName is not null and charindex('[',MviLRColourCodeName) <>1  
                     then right(MviLRColourCodeName, 4) else null end end  as �����ڵ�2_�µ�

     ,case when MviRFColourCodeName is not null  and charindex(']',MviRFColourCodeName) =2 then NULL else
      case when MviRFColourCodeName is not null  and charindex(']',MviRFColourCodeName) =6 
                     then substring(MviRFColourCodeName, 2,4) else null end end  as �����ڵ�1_���
      ,case when MviRFColourCodeName is not null  and charindex('[',MviRFColourCodeName) =1 
                     then substring(MviRFColourCodeName, charindex(']',MviRFColourCodeName)+2 ,4) else
      case when MviRFColourCodeName is not null and charindex('[',MviRFColourCodeName) <>1  
                     then right(MviRFColourCodeName, 4) else null end end  as �����ڵ�2_���

     ,case when MviRRColourCodeName is not null  and charindex(']',MviRRColourCodeName) =2 then NULL else
      case when MviRRColourCodeName is not null  and charindex(']',MviRRColourCodeName) =6 
                     then substring(MviRRColourCodeName, 2,4) else null end end  as �����ڵ�1_���
      ,case when MviRRColourCodeName is not null  and charindex('[',MviRRColourCodeName) =1 
                     then substring(MviRRColourCodeName, charindex(']',MviRRColourCodeName)+2 ,4) else
      case when MviRRColourCodeName is not null and charindex('[',MviRRColourCodeName) <>1  
                     then right(MviRRColourCodeName, 4) else null end end  as �����ڵ�2_���
   
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
 where t1.�����=T2.FARM_NAME and T1.��ü�ý��۹�ȣ=T2.LacAniId and  ��������>=LacCalvingDate and ��������<nextLacCalvingDate

 order by �����, ��ü�ý��۹�ȣ, �湮�ð�
  


  
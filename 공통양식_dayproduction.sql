
----����� ��������, ���������� �׸� -- 

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
�����, ��ü�ý��۹�ȣ, ��ü����ڹ�ȣ, ����, ��������,�и����Ϸ�,  
����Ƚ��, ����Ƚ��, ����Ƚ��, ���������, ������, ���ܹ�, ����, ü����, �����ü��, ü��_smooth_wt,
����_���Ļ��,����_�۸����ѵ�, ����չ���, HealthIndex
from 
		(
		 select
		t1.FARM_NO 
		,t1.FARM_NAME as �����
		,t1.LacAniId as ��ü�ý��۹�ȣ
		,t1.AniUserNumber as ��ü����ڹ�ȣ
		,t1.AniName as ��ü�̸�
		,t1.LacNumber as ����
		,convert(date, t2.MdpProductionDate, 112) as ��������
		,datediff(dd, t1.LacCalvingDate, t2.MdpProductionDate) as �и����Ϸ�
		,MdpDayProduction as ���������
   		,MdpMilkings as ����Ƚ��
		,MdpRefusals as ����Ƚ��
		,MdpFailures as ����Ƚ��
		,MdpFatPercentage as ������
		,MdpProteinPercentage as ���ܹ�
		,MdpLactosePercentage as ����
		,MdpSCC as ü����
		,MdpAverageWeight as �����ü��
		,MdpSmoothedWeight as ü��_smooth_wt
		from lac_tb t1, lely_collect_farm_PrmMilkDayProduction  t2
		where t1.LacAniId = t2.MdpAniId and t2.MdpProductionDate >= t1.LacCalvingDate and t2.MdpProductionDate < t1.nextLacCalvingDate
		and t2.MdpProductionDate between @date_s and @date_f and t1.FARM_NO=t2.FARM_NO
		) tt1						
        left outer join 	-- ���, ���Ÿ��(����, �۸�����(��Ÿ))���� ������
					(
					select
					cc.FARM_NO
					,FadAniId
					,convert(date, FadDate, 112)  fad_date
					,sum(case when aa.FeeFtyId=2 then FadTotalItake else null end) as ����_���Ļ��
					,sum(case when aa.FeeFtyId=4 then FadTotalItake else null end) as ����_�۸����ѵ�
					FROM lely_collect_farm_PrmFeedAppliedDaily as cc
					left outer join LELY_COLLECT_FARM_LimFeed as aa on aa.FARM_NO=cc.FARM_NO and aa.FeeId=FadFeeId
					where FadDate>=@date_s and FadDate<=@date_f 
					group by cc.FARM_NO, FadAniId, FadDate
					) feed on feed.FadAniId=tt1.��ü�ý��۹�ȣ and feed.fad_date=tt1.�������� and tt1.FARM_NO=feed.FARM_NO
		 left outer join -- Ȱ������ ������� �ǹ̾��ٰ� �����Ǿ� ������, 22���� ���� �������� ��
					(
					 select
					 FARM_NO, AscAniId, convert(date,AscCellTime,113) as asc_date, AscTotalRuminationTime as ����չ���, AscHealthIndex100 as HealthIndex
					 from LELY_COLLECT_FARM_PrmActivityScr  where  datepart(hh, AscCellTime) =22 
					  ) activityscr on activityscr.AscAniId=tt1.��ü�ý��۹�ȣ and activityscr.asc_date=tt1.�������� and activityscr.FARM_NO=tt1.FARM_NO 
 order by �����, ��ü�ý��۹�ȣ, ��������
  


  
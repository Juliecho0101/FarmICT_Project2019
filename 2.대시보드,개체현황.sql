--# ��ú��� > ��ü��Ȳ
declare @farm_no int 
set @farm_no = 38

; with cow_status as(
SELECT
A.FARM_NO,
A.USER_NUMBER,
A.PRODUCT_STATUS_NAME AS PROD_N,
A.REPRODUCT_STATUS_NAME AS REPROD_N,
LAST_LAC_NUMBER, 
CONVERT(DATE, CALVING_DATE,113) AS CalvingDate,
DATEDIFF(DD, CALVING_DATE, GETDATE()) AS DayInMiking,
CONVERT(DATE, INS_DATE) AS InsDate,
DATEDIFF(DD, INS_DATE, GETDATE() ) AS DayInPregnance,
DATEDIFF(DD, DATEADD(DD, 280,INS_DATE) ,GETDATE()) AS D_DAY,
CONVERT(DATE,DRYOFF_DATE,113) AS DRYDATE,
DATEDIFF(DD, DRYOFF_DATE, GETDATE() ) AS DayInDry
FROM T4C.ANIMAL AS A  
INNER JOIN T4C.CALVING AS LAC ON  A.LIFE_NUMBER=LAC.LIFE_NUMBER AND A.FARM_NO=LAC.FARM_NO AND A.LAST_LAC_NUMBER=LAC.LAC_NUMBER
LEFT OUTER JOIN 
            (SELECT FARM_NO,LIFE_NUMBER, LAC_NUMBER, MAX(INSEMINATION_DATE) AS INS_DATE 
            FROM T4C.INSEMINATION GROUP BY FARM_NO, LIFE_NUMBER, LAC_NUMBER
            ) AS INS ON A.LIFE_NUMBER=INS.LIFE_NUMBER AND A.FARM_NO=INS.FARM_NO AND A.LAST_LAC_NUMBER=INS.LAC_NUMBER
WHERE 
A.KEEP=1 and a.DELETED=0 AND A.ACTIVE=1 
AND A.FARM_NO =@farm_no
)

select 
sum(case when PROD_N = 'In Lactation' and REPROD_N = 'pregnant' then 1 else 0 end) as '������_����_�ӽ�'
,sum(case when PROD_N = 'In Lactation' and REPROD_N = 'inseminated' then 1 else 0 end) as '������_����_����'
,sum(case when PROD_N = 'In Lactation' and ( REPROD_N = 'open' or REPROD_N='open cylic') then 1 else 0 end) as '������_����_����'
,sum(case when  PROD_N = 'Dry Off' and REPROD_N = 'pregnant' then 1 else 0 end) as '������'
,sum(case when PROD_N = 'Young Stock' and REPROD_N  != 'never inseminated' then 1 else 0 end) as '�̰���_����O' 
,sum(case when PROD_N = 'Young Stock' and REPROD_N ='never inseminated' then 1 else 0 end) as '�̰���_����X'
from cow_status

/*
�׷��� ;   �̰���/ ������/ ������ ������

�̰��� :  x �� D_DAY , y��  DayInPregnance 
������ : x�� DayInMilking , y��: DayInPregnance      ���� : PROD_N ='In Lactation'  pregnant , inseminated ,    open/ open cylic
������ :  x��  ,y�� : DayInPrenance
*/
--if OBJECT_ID(N'Proc_Test', N'P') is not null
--begin
--	drop procedure Proc_Test;
--end
--go



----1. init variables & Procedure
--create procedure Proc_Test
--         @StartDate datetime = '2010-1-1',
--         @EndDate datetime ='2011-7-1',
--         @SumAmount decimal output,
--         @SumCount int output,
--         @BizType char(2) output
--as
--begin

----2. Check Input
--if(@StartDate is null or @EndDate is null)
--begin 
--      raiserror(N'Input params cannot be empty in Proc_Test',16,1);
--end		 

declare @StartDate datetime;
declare @EndDate datetime;
set @StartDate = '2011-01-01';
set @EndDate = '2011-07-01';


--3. Input Config Table
exec dbo.xprcFile
'MerchantName	BizType	OpenAccountDate	MerchantNo	ContractNo	Channel	BranchOffice
�ɿڿ��֣����ϣ��������޹�˾1�����ۣ�	�����̻�	20110511	808080450104703	DK-101002	����	�����������޹�˾���Ϸֹ�˾
����ͳһ��ҵʳƷ���޹�˾�����ʴ��ۣ�	�����̻�	20110513	808080450104718	DK-101002	����	�����������޹�˾���Ϸֹ�˾
���Ͻݻ�ͨ��ó���޹�˾-�ݣ����ʴ��ۣ�	�����̻�	20110526	808080450104759	DK-101002	����	�����������޹�˾���Ϸֹ�˾
�й��ƶ��������޹�˾�����ֹ�˾�����ۣ�	�����̻�	20110511	808080450104702	DK-101002	����	�����������޹�˾���Ϸֹ�˾
����������˹С������������ι�˾�����ۣ�	�����̻�	20110408	808080450104576	DK-110401	����	�����������޹�˾�����ֹ�˾
�ɿڿ��������������������޹�˾[����]	�����̻�	20110523	808080450104748	DK-110507	����	�����������޹�˾�����ֹ�˾
��Ұ�������缼�������������޹�˾	ORA �̻�	20110531	606060450100151	OL-110307	����	���������������޹�˾
�Ϸ�ͨ�����з������޹�˾��Ԥ��Ȩ��	����֧���̻�	20110524	808080510004754	OL-110340	����	�����������޹�˾���շֹ�˾
����ͯҼ������Ƽ����޹�˾	����֧���̻�	20110415	808080580004597	OL-110412	����	���������������޹�˾
���������ô�ҩ�����޹�˾	����֧���̻�	20110421	808080580004611	OL-110416	����	���������������޹�˾
һ��������������Ϣ�������޹�˾	����֧���̻�	20110421	808080580004612	OL-110417	����	���������������޹�˾
����ҽҩ�����������޹�˾��B2B��	����֧���̻�	20110526	808080580104761	OL-110516	����	���������������޹�˾
����ҽҩ�����������޹�˾��B2C��	����֧���̻�	20110526	808080580104760	OL-110516	����	���������������޹�˾
��������ʱ�������������޹�˾�����ֹ�˾	����֧���̻�	20110408	808080580104567	ORA-110402	����	�����������޹�˾�����ֹ�˾
�����к�����������˼��ѵѧУ	ORA �̻�	20110519	606060430100147	ORA-110404	����	���������������޹�˾
�����к�����������˼��ѵѧУ�����ۣ�	�����̻�	20110503	808080430104681	ORA-110404	����	���������������޹�˾
���쿭����ʵҵ���޹�˾�����۶��ڣ�	�����̻�	20110524	808080580104752	ORA-110407	����	�����������޹�˾����ֹ�˾
�������ֹ������Ĺ������޹�˾�����۶��ڣ�	�����̻�	20110524	808080580104753	ORA-110408	����	�����������޹�˾����ֹ�˾
������˰��������С��������޹�˾	�����̻�	20110128	808080450104340	Q-110103	����	�����������޹�˾�����ֹ�˾
����ʡ����ʳƷ���޹�˾ɽ���ֹ�˾	����֧���̻�	20110127	808080450104339	tq-101101	����	�����������޹�˾ɽ���ֹ�˾
������¹���մ������޹�˾	����֧���̻�	20110120	808080510104289	tq-101217	����	�����������޹�˾���Ϸֹ�˾
���ټң����ʳƷ���޹�˾	����֧���̻�	20110425	808080580104628	TQ-110402	����	�����������޹�˾���ֹ�˾
�������Ŀ�����Ƽ����޹�˾	����֧���̻�	20110530	808080450104780	TQ-110501	����	�����������޹�˾���Ϸֹ�˾
��������������������޹�˾	����֧���̻�	20110530	808080520104777	TQ-110502	����	�����������޹�˾���Ϸֹ�˾
';

select 
	MerchantName,
	BizType,
	CONVERT(datetime, OpenAccountDate) as OpenAccountDate,
	MerchantNo,
	ContractNo,
	Channel,
	BranchOffice
into
	#ConfigInput
from
	xlsContainer;




--4 Get SumAccount & SumCount from table(FactDailyTrans,Table_OraTransSum)

--4.1 Get FactDailyTrans SumAmount & SunCount
select 
      Merchants.MerchantNo,
      SUM(FDailyTran.SucceedTransAmount) as SumAmount,
      SUM(FDailyTran.SucceedTransCount) as SumCount
into
    #TemFactDaily
from
    #ConfigInput Merchants
    inner join
    FactDailyTrans FDailyTran
    on
      Merchants.MerchantNo = FDailyTran.MerchantNo     
where
    FDailyTran.DailyTransDate >= @StartDate
and
    FDailyTran.DailyTransDate < @EndDate
group by
    Merchants.MerchantNo;
    

--4.2 Get Table_OraTransSum SumAmount & SumCount
select
    Merchants.MerchantNo,
    SUM(OraTranSum.TransAmount) as SumAmount,
    SUM(OraTranSum.TransCount) as SumCount
into 
    #TemOra
from
    #ConfigInput Merchants
    inner join
    Table_OraTransSum OraTranSum
    on
    Merchants.MerchantNo = OraTranSum.MerchantNo
where
    OraTranSum.CPDate >= @StartDate
and
    OraTranSum.CPDate < @EndDate  
group by
    Merchants.MerchantNo;

     
--4.3 Get All SumAmount & SumCount
select * into #Temp from #TemFactDaily
union all
select * from #TemOra;
select 
	Merchants.*,
	isnull(Temp.SumAmount,0) SumAmount,
	isnull(Temp.SumCount,0) SumCount
into
	#MerchantsWithSum
from
	#ConfigInput Merchants
	left join
	#Temp Temp
	on
		Temp.MerchantNo = Merchants.MerchantNo;
--select
--      AllMerchants.*,
--      (ISNULL(TFDaily.SumAmount1,0) + ISNULL(TOra.SumAmount2,0)) as SumAmount,
--      (ISNULL(TFDaily.SumCount1,0) + ISNULL(TOra.SumCount2,0)) as SumCount
--into
--     #MerchantsWithSum
--from
--    #Config AllMerchants
--    left join
--    #TemFactDaily TFDaily
--    on
--      AllMerchants.MerchantNo = TFDaily.MerchantNo
--    left join
--    #TemOra TOra
--    on 
--      AllMerchants.MerchantNo = TOra.MerchantNo




--5 Caculate Average Sum
select
      MerWithSum.ContractNo,
      CONVERT(decimal,SUM(MerWithSum.SumAmount))/(DATEDIFF(month,MAX(MerWithSum.OpenAccountDate),@EndDate)-1) AvgAmount
into 
    #TemAvg
from
    #MerchantsWithSum MerWithSum
group by
    MerWithSum.ContractNo;



--6 Classified Merchants Level
select
      Merchants.MerchantName,
      Merchants.BizType,
      Merchants.OpenAccountDate,
      Merchants.MerchantNo,
      Merchants.ContractNo,
      Merchants.Channel,
      Merchants.BranchOffice,
      CONVERT(decimal,Merchants.SumAmount)/100 as SumAmount,
      Merchants.SumCount,
      CONVERT(decimal,TAvg.AvgAmount)/100 as AvgAmount,
      case when
               CONVERT(decimal,TAvg.AvgAmount)/100 >= 200000.00
      then 
           N'B'
      else
           N'C'
      end MerchantType      
from 
    #MerchantsWithSum Merchants
    inner join
    #TemAvg TAvg
    on
      Merchants.ContractNo = TAvg.ContractNo;
    

--7 Drop Temporary Tables    
drop table #ConfigInput
drop table #TemFactDaily
drop table #TemOra
drop table #MerchantsWithSum
drop table #TemAvg
drop table #Temp
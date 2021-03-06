if OBJECT_ID(N'Proc_QuerySalesAreaChart', N'P') is not null
begin
	drop procedure Proc_QuerySalesAreaChart;
end
go

create procedure Proc_QuerySalesAreaChart
	@StartDate datetime = '2011-04-01',
	@PeriodUnit nchar(4) = N'周',
	@EndDate datetime = '2011-05-31'
as
begin

--1. Check input
if (@StartDate is null or ISNULL(@PeriodUnit, N'') = N'' or (@PeriodUnit = N'自定义' and @EndDate is null))
begin
	raiserror(N'Input params cannot be empty in Proc_QuerySalesAreaChart', 16, 1);
end

--2. Prepare StartDate and EndDate
declare @CurrStartDate datetime;
declare @CurrEndDate datetime;
declare @PrevStartDate datetime;
declare @PrevEndDate datetime;
declare @LastYearStartDate datetime;
declare @LastYearEndDate datetime;
declare @ThisYearRunningStartDate datetime;
declare @ThisYearRunningEndDate datetime;

if(@PeriodUnit = N'周')
begin
    set @CurrStartDate = @StartDate;
    set @CurrEndDate = DATEADD(week, 1, @StartDate);
    set @PrevStartDate = DATEADD(week, -1, @CurrStartDate);
    set @PrevEndDate = @CurrStartDate;
    set @LastYearStartDate = DATEADD(year, -1, @CurrStartDate); 
    set @LastYearEndDate = DATEADD(year, -1, @CurrEndDate);
end
else if(@PeriodUnit = N'月')
begin
    set @CurrStartDate = @StartDate;
    set @CurrEndDate = DATEADD(MONTH, 1, @StartDate);
    set @PrevStartDate = DATEADD(MONTH, -1, @CurrStartDate);
    set @PrevEndDate = @CurrStartDate;
    set @LastYearStartDate = DATEADD(year, -1, @CurrStartDate); 
    set @LastYearEndDate = DATEADD(year, -1, @CurrEndDate);
end
else if(@PeriodUnit = N'季度')
begin
    set @CurrStartDate = @StartDate;
    set @CurrEndDate = DATEADD(QUARTER, 1, @StartDate);
    set @PrevStartDate = DATEADD(QUARTER, -1, @CurrStartDate);
    set @PrevEndDate = @CurrStartDate;
    set @LastYearStartDate = DATEADD(year, -1, @CurrStartDate); 
    set @LastYearEndDate = DATEADD(year, -1, @CurrEndDate);
end
else if(@PeriodUnit = N'半年')
begin
    set @CurrStartDate = @StartDate;
    set @CurrEndDate = DATEADD(QUARTER, 2, @StartDate);
    set @PrevStartDate = DATEADD(QUARTER, -2, @CurrStartDate);
    set @PrevEndDate = @CurrStartDate;
    set @LastYearStartDate = DATEADD(year, -1, @CurrStartDate); 
    set @LastYearEndDate = DATEADD(year, -1, @CurrEndDate);
end
else if(@PeriodUnit = N'年')
begin
    set @CurrStartDate = @StartDate;
    set @CurrEndDate = DATEADD(YEAR, 1, @StartDate);
    set @PrevStartDate = DATEADD(YEAR, -1, @CurrStartDate);
    set @PrevEndDate = @CurrStartDate;
    set @LastYearStartDate = DATEADD(year, -1, @CurrStartDate); 
    set @LastYearEndDate = DATEADD(year, -1, @CurrEndDate);
end
else if(@PeriodUnit = N'自定义')
begin
    set @CurrStartDate = @StartDate;
    set @CurrEndDate = DateAdd(day,1,@EndDate);
    set @PrevStartDate = DATEADD(DAY, -1*datediff(day,@CurrStartDate,@CurrEndDate), @CurrStartDate);
    set @PrevEndDate = @CurrStartDate;
    set @LastYearStartDate = DATEADD(year, -1, @CurrStartDate); 
    set @LastYearEndDate = DATEADD(year, -1, @CurrEndDate);
end
set @ThisYearRunningStartDate = CONVERT(char(4), YEAR(@CurrStartDate)) + '-01-01';
set @ThisYearRunningEndDate = @CurrEndDate;

--3. Get Data
--3.1 Get Current Data
With CurrCMCData as
(
	select
		MerchantNo,
		SUM(SucceedTransAmount) as CurrSucceedAmount
	from
		FactDailyTrans
	where
		DailyTransDate >= @CurrStartDate
		and
		DailyTransDate < @CurrEndDate
	group by
		MerchantNo
),
CurrORAData as
(
	select
		MerchantNo,
		SUM(Table_OraTransSum.TransAmount) as CurrSucceedAmount
	from
		dbo.Table_OraTransSum
	where
		Table_OraTransSum.CPDate >= @CurrStartDate
		and
		Table_OraTransSum.CPDate < @CurrEndDate
	group by
		MerchantNo
)
select
	coalesce(CurrCMCData.MerchantNo, CurrORAData.MerchantNo) MerchantNo,
	ISNULL(CurrCMCData.CurrSucceedAmount, 0) + ISNULL(CurrORAData.CurrSucceedAmount, 0) CurrSucceedAmount
into
	#CurrData
from
	CurrCMCData
	full outer join
	CurrORAData
	on
		CurrCMCData.MerchantNo = CurrORAData.MerchantNo;
		
--3.1 Get Previous Data
With PrevCMCData as
(
	select
		MerchantNo,
		SUM(SucceedTransAmount) as PrevSucceedAmount
	from
		FactDailyTrans
	where
		DailyTransDate >= @PrevStartDate
		and
		DailyTransDate < @PrevEndDate
	group by
		MerchantNo
),
PrevORAData as
(
	select
		MerchantNo,
		SUM(Table_OraTransSum.TransAmount) as PrevSucceedAmount
	from
		dbo.Table_OraTransSum
	where
		Table_OraTransSum.CPDate >= @PrevStartDate
		and
		Table_OraTransSum.CPDate < @PrevEndDate
	group by
		MerchantNo
)
select
	coalesce(PrevCMCData.MerchantNo, PrevORAData.MerchantNo) MerchantNo,
	ISNULL(PrevCMCData.PrevSucceedAmount, 0) + ISNULL(PrevORAData.PrevSucceedAmount, 0) PrevSucceedAmount
into
	#PrevData
from
	PrevCMCData
	full outer join
	PrevORAData
	on
		PrevCMCData.MerchantNo = PrevORAData.MerchantNo;


--3.1 Get the last year Data
With LastYearCMCData as
(
	select
		MerchantNo,
		SUM(SucceedTransAmount) as LastYearSucceedAmount
	from
		FactDailyTrans
	where
		DailyTransDate >= @LastYearStartDate
		and
		DailyTransDate < @LastYearEndDate
	group by
		MerchantNo
),
LastYearORAData as
(
	select
		MerchantNo,
		SUM(Table_OraTransSum.TransAmount) as LastYearSucceedAmount
	from
		dbo.Table_OraTransSum
	where
		Table_OraTransSum.CPDate >= @LastYearStartDate
		and
		Table_OraTransSum.CPDate < @LastYearEndDate
	group by
		MerchantNo
)
select
	coalesce(LastYearCMCData.MerchantNo, LastYearORAData.MerchantNo) MerchantNo,
	ISNULL(LastYearCMCData.LastYearSucceedAmount, 0) + ISNULL(LastYearORAData.LastYearSucceedAmount, 0) LastYearSucceedAmount
into
	#LastYearData
from
	LastYearCMCData
	full outer join
	LastYearORAData
	on
		LastYearCMCData.MerchantNo = LastYearORAData.MerchantNo;
		
--6. Get Result
--6.1 Convert Currency Rate
update
	CD
set
	CD.CurrSucceedAmount = CD.CurrSucceedAmount * CR.CurrencyRate
from
	#CurrData CD
	inner join
	Table_SalesCurrencyRate CR
	on
		CD.MerchantNo = CR.MerchantNo;
		
update
	PD
set
	PD.PrevSucceedAmount = PD.PrevSucceedAmount * CR.CurrencyRate
from
	#PrevData PD
	inner join
	Table_SalesCurrencyRate CR
	on
		PD.MerchantNo = CR.MerchantNo;
		
update
	LYD
set
	LYD.LastYearSucceedAmount = LYD.LastYearSucceedAmount * CR.CurrencyRate
from
	#LastYearData LYD
	inner join
	Table_SalesCurrencyRate CR
	on
		LYD.MerchantNo = CR.MerchantNo;
		
--6.2 Get Final Result
select 
	Sales.Area,
	Convert(decimal,sum(isnull(Curr.CurrSucceedAmount,0)))/1000000 CurrAmount,
	CONVERT(decimal,sum(isnull(Prev.PrevSucceedAmount,0)))/1000000 PrevAmount,
	CONVERT(decimal,sum(isnull(LastYear.LastYearSucceedAmount,0)))/1000000 lastYearAmount 
from
	dbo.Table_SalesDeptConfiguration Sales
	left join
	#CurrData Curr
	on
		Sales.MerchantNo = Curr.MerchantNo
	left join
	#PrevData Prev
	on
		Sales.MerchantNo = Prev.MerchantNo
	left join
	#LastYearData LastYear
	on
		Sales.MerchantNo = LastYear.MerchantNo
group by 
	Sales.Area
having
	convert(decimal, sum(isnull(Curr.CurrSucceedAmount,0)))/1000000 > 0.01
order by
	CurrAmount DESC;

--7. Clear temp table
drop table #CurrData;
drop table #PrevData;
drop table #LastYearData;
end 
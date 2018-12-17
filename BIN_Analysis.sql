/*-- Analyzing Drop in US price and removal of unicef --*/


-- Members who started after Sept 3

Set @start= '2018-08-01 00:00:00';
Set @end_date= '2018-08-31 23:59:59';

Set @start= '2018-08-27 00:00:00';
Set @end_date= '2018-09-02 23:59:59';

DROP TABLE IF EXISTS stat_queries.checking_us_price;
CREATE TABLE stat_queries.checking_us_price as
select * from stat_queries.track_members_infos where start_date between UNIX_TIMESTAMP(@start) and UNIX_TIMESTAMP(@end_date) 
and country_code = 'MX' and is_trial_member =1 and processor_id <>15;
CREATE INDEX MBM_IDX USING BTREE ON stat_queries.checking_us_price (member_id); 

select * from stat_queries.checking_us_price;

-- Adding trx data
DROP TABLE IF EXISTS stat_queries.checking_us_price_trx;
CREATE TABLE stat_queries.checking_us_price_trx as
select
a.member_id, a.start_date, a.country_code,
b.transaction_id,
  b.type,
  b.issue_date,
  b.amount_paid,
  b.status as status_transaction,
  b.origin,
  b.rebill_no,
  b.recur_no,
  b.type_dispute,
  b.dispute_date,
  b.amount_dispute,
  b.tag,
  b.processor_id
from
stat_queries.checking_us_price a
left join
stat_queries.as_transactions_v2 b
on a.member_id=b.member_id;

select * from stat_queries.checking_us_price_trx;

select * from stat_queries.checking_us_price_trx where origin = 'recurring' and status_transaction = 'success' and type in ('sale','capture');


select
c.Nbr_members,
ROUND(b.Nbr_Disputes30/a.Nbr_Settlements,4)*100 AS Dispute_Rate30
from
(
select 
country_code, 
COUNT(DISTINCT transaction_id) as Nbr_Settlements
from
 stat_queries.checking_us_price_trx
 where type IN ('sale','capture') AND
      STATUS_TRANSACTION = 'success'
 group by country_code ) a
 left join
 (
 select 
country_code,
COUNT(DISTINCT transaction_id) as Nbr_Disputes30
from
 stat_queries.checking_us_price_trx
 where type_dispute IS NOT NULL 
      and DATEDIFF(DISPUTE_DATE,ISSUE_DATE) <= 36
 group by country_code ) b
 on a.country_code=b.country_code
 left join
 (
select 
country_code, 
COUNT(DISTINCT member_id) as Nbr_members
from
 stat_queries.checking_us_price_trx
  group by country_code ) c
 on a.country_code=c.country_code;

select * from stat_queries.as_transactions_v2;

select * from stat_queries.as_mastercard_members_v0 ;

--
-- BIN selection

Set @start= '2018-10-01 00:00:00';
Set @end_date= '2018-10-21 23:59:59';


select * from track_members_infos where start_date between  UNIX_TIMESTAMP(@start) and UNIX_TIMESTAMP(@end_date) ;

select
LEFT(X.CREDIT_CARD_NUMBER,6) AS 'CC_BIN',
-- count(A.member_id),
count(transaction_id)
FROM stat_queries.track_members_infos A
LEFT JOIN stat_queries.as_transactions_v2 B ON A.MEMBER_ID = B.MEMBER_ID
LEFT JOIN jomedia_gateway.reel_gateway_members X ON A.MEMBER_ID = X.ID
-- where A.start_date between  UNIX_TIMESTAMP(@start) and UNIX_TIMESTAMP(@end_date) and LEFT(X.CREDIT_CARD_NUMBER,6) in(415231,402918,410039)
where B.issue_date between  @start and @end_date and LEFT(X.CREDIT_CARD_NUMBER,6) in(415231,402918,410039)
and B.status = 'success' and B.type in('sale','capture')
group by CC_BIN;
/*
CC bin  sett
402918	936
410039	1279
415231	6856
*/

select ppp_list_id, from_unixtime(start_date), from_unixtime(end_date), ppp from jomedia_gateway.ppp_pricing where country_code = 'MX' and ppp_list_id <> 12;


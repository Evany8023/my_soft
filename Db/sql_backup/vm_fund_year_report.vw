create or replace view smzj.vm_fund_year_report as
select
  t.product_no,
  t.goal,
  t.strategy ,
  t.standard ,
  t.feature ,
  t.brief ,
  t.report_period ,
  t.product_name,
  t.create_date ,
  t.update_date,
  c.cp_name as comname ,
  c.insti_code as comcode,
  dbms_lob.substr(t.introduction,2000 ,1 ) as introduction1  ,
  dbms_lob.substr(t.introduction,2000 ,2001 ) as introduction2  ,
  dbms_lob.substr(t.introduction,2000 ,4001 ) as introduction3  ,
  dbms_lob.substr(t.introduction,2000 ,6001 ) as introduction4  ,
  dbms_lob.substr(t.introduction,2000 ,8001 ) as introduction5  ,
  dbms_lob.substr(t.introduction,2000 ,10001 ) as introduction6  ,
  dbms_lob.substr(t.introduction,2000 ,12001 ) as introduction7

    from busi_year_report t inner join  busi_company c on c.id=t.cp_id where t.is_delete='0';


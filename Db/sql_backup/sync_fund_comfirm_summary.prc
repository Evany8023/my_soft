create or replace procedure smzj.sync_fund_comfirm_summary is
  -- *************************************************************************
-- SYSTEM:      托管服务平台
-- SUBSYS:       私募之家
-- PROGRAM:      sync_fund_comfirm_summary
-- RELATED TAB:
-- SUBPROG:
-- REFERENCE:
-- DESCRIPTION:  直销交易汇总确认
-- INPUT:
-- OUTPUT:
-- RETURN:       0    正常返回
--               -1   数据库错误
-- AUTHOR:       庞作青
-- CREATE DATE:  2016-01-25
-- VERSION:
-- EDIT HISTORY:
-- *************************************************************************
  v_msg   varchar2(4000);
begin
  execute immediate 'truncate table busi_fund_trade_summary';

  insert into busi_fund_trade_summary(PT_ID,apply_date,busi_type,apply_money_summary,apply_share_summary)
           select t.pt_id,to_char(t.sheet_create_time,'yyyymmdd'),'1'|| ltrim(t.business_type,'0') ,
           sum(case t.business_type when '020' then replace(t.apply_amount,',','') when '022' then replace(t.apply_amount,',','') else '0' end) as apply_amount,
           sum(case t.business_type when '024' then replace(t.apply_share,',','')  else '0' end) as apply_share
           from busi_sheet t,busi_product p  where t.is_delete='0' and t.pt_id=p.id and p.is_delete='0' and t.business_type in('020','022','024')
           group by t.pt_id,to_char(t.sheet_create_time,'yyyymmdd'),t.business_type;

update busi_fund_trade_summary s set (s.product_name,s.cp_id,s.pt_id,s.pt_no,s.CP_NO )=
(select p.name,p.cp_id,p.id,p.product_no,c.insti_code from Busi_Product p inner join busi_company c on c.id=p.cp_id where p.id=s.pt_id)
where exists( select p.id from Busi_Product p where p.id=s.pt_id);
--确认日期



-- 确认份额，确认金额,申购，赎回,
update busi_fund_trade_summary s set (s.confirm_money_summary,s.confirm_share_summary,NETVAL,comfirm_date) =(
 select
  sum( replace(c.confirm_amount,',','')) as apply_amount,
 sum( replace(c.confirm_share,',','')  ) as apply_share,
  max(c.unit_net_val),
  to_char(max(c.confirm_date),'yyyymmdd')
  from busi_trading_confirm c
  where c.pt_no=s.pt_no and c.business_type=s.busi_type and s.apply_date=c.apply_date and c.return_code='0000' and c.insti_code=s.cp_no
  and c.business_type in('122','124')
  group by   c.pt_no ,c.business_type ,c.apply_date
)
where exists(
 select c.pt_no from busi_trading_confirm c where c.pt_no=s.pt_no and c.business_type in('122','124')  and s.apply_date=c.apply_date and c.return_code='0000' and c.insti_code=s.cp_no
);
commit;
--更新认购金额，认购份额
update busi_fund_trade_summary s set (s.confirm_money_summary,s.confirm_share_summary,comfirm_date) =(
 select
  sum( replace(c.confirm_amount,',','')) as apply_amount,
 sum( replace(c.confirm_share,',','')  ) as apply_share,
  to_char(max(c.confirm_date),'yyyymmdd')
  from busi_trading_confirm c
  where c.pt_no=s.pt_no  and s.apply_date=c.apply_date and c.return_code='0000' and c.insti_code=s.cp_no
  and c.business_type in('130')
  group by   c.pt_no ,c.business_type ,c.apply_date
)
where exists(
 select c.pt_no from busi_trading_confirm c where c.pt_no=s.pt_no and c.business_type in('130')  and c.return_code='0000' and c.insti_code=s.cp_no
) and s.busi_type='120';

--认购净值
update busi_fund_trade_summary s set (NETVAL) =(
 select facevalue from zsta.fundinfo@ta_dblink t where t.fundcode=s.pt_no
)
where exists(
 select facevalue from zsta.fundinfo@ta_dblink t where t.fundcode=s.pt_no
) and s.busi_type='120';

--
--更新交收预估未做完

update busi_fund_trade_summary s set s.exchange_date =(
 select
 case s.busi_type
   when '122' then
     getnextworkday(s.apply_date,t.sgjsts)
   when '124' then
     getnextworkday(s.apply_date,t.shjsts)
   end
  from  zsta.jscsb@ta_dblink t where t.fundcode=s.pt_no and rownum=1

)
where exists(
 select t.fundcode from  zsta.jscsb@ta_dblink t where t.fundcode=s.pt_no
);
-- 认购交手时间
update busi_fund_trade_summary s set s.exchange_date =
(select getnextworkday(s.apply_date,1) from dual) where s.busi_type='120';



  v_msg :='同步成功！';
  insert into t_fund_job_running_log(job_name,job_running_log) values('直销交易汇总确认',v_msg);
  commit;
exception
    when others then
      v_msg :='同步失败，原因：'|| sqlcode || ':' || sqlerrm ||dbms_utility.format_error_stack;
      rollback;
      insert into t_fund_job_running_log(job_name,job_running_log) values('直销交易汇总确认',v_msg);
      commit;

end sync_fund_comfirm_summary;
/


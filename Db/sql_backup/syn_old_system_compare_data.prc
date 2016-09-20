create or replace procedure smzj.syn_old_system_compare_data is


---- *************************************************************************
-- SUBSYS:     托管服务
-- PROGRAM:      syn_old_system_compare_data
-- RELATED TAB:
-- SUBPROG:
-- REFERENCE:
-- AUTHOR:       pangzq
-- DESCRIPTION:  每天早上对比前一天数据的是否同步完毕
-- CREATE DATE:  2015-10-23
-- VERSION:
-- EDIT HISTORY:
-- *************************************************************************

v_msg varchar2(4000);--返回信息
v_job_log_name varchar2(60) :='syn_old_system_compare_data';


v_last_work_day varchar2(8 char);
v_new_jy_count  integer;
v_old_jy_count  integer;

v_new_kh_count  integer;
v_old_kh_count  integer;

v_new_yhzh_count  integer;
v_old_yhzh_count  integer;

v_new_jy_number  number;
v_new_old_number  number;
begin
--前一天工作日日期
select max(t.rq) into v_last_work_day from zsta.rlb@ta_dblink t where t.gzr='1' and  t.rq < to_char(sysdate,'yyyymmdd');
 -- 交易
 select count(*) into v_new_jy_count  from busi_sheet t where to_char(t.sheet_create_time,'yyyymmdd')=v_last_work_day and t.old_sys_id is not null;
 select count(1) into v_old_jy_count from t_fund_trade@newone t,t_fund_cust@newone c where t.cust_id=c.id and t.is_delete=0 and t.isvalid=1  and t.trade_sqrq=v_last_work_day;
 
 -- 开户
 select count(1) into v_new_kh_count from busi_investor_detail t where t.old_sys_id is not null and to_char(t.create_date,'yyyymmdd')=v_last_work_day;
 select count(1) into  v_old_kh_count  from t_fund_khsq@newone t,t_fund_cust@newone  c  where t.cust_id=c.id and t.is_delete=0 and t.sqrq=v_last_work_day;
  
 --银行账号
 
 select count(1) into v_new_yhzh_count from busi_bind_bank_card t where to_char(t.bind_date,'yyyymmdd') = v_last_work_day and t.old_sys_id is not null;
 select count(1) into v_old_yhzh_count   from t_fund_account@newone t,t_fund_cust@newone c
 where t.cust_id=c.id and t.is_delete=0 and t.isvalid=1 and t.acc_sqrq=v_last_work_day;

v_msg:= v_last_work_day || '  新交易数：' || v_new_jy_count || '  老交易数: ' || v_old_jy_count ;
v_msg:=v_msg || '   新开户数：' || v_new_kh_count || '  老开户数: ' || v_old_kh_count ;
v_msg:=v_msg || '  新银行数：' || v_new_yhzh_count || '  老系统银行数: ' || v_old_yhzh_count ;

-- 成交额 份额同步
select  sum( to_number(replace(t.apply_share,',',''),'9999999999999.99')) into v_new_jy_number   from busi_sheet t where t.business_type='024' and t.old_sys_id is not null and to_char(t.create_date,'yyyymmdd')=v_last_work_day;
select  sum( to_number(replace(t.trade_sqfe,',',''),'9999999999999.99')) into v_new_old_number   from  t_fund_trade@newone t,t_fund_cust@newone c where t.cust_id=c.id and t.is_delete=0 and t.isvalid=1  and t.trade_sqrq=v_last_work_day and t.trade_type_code='024';
v_msg:=v_msg || '  新赎回额：' || v_new_jy_number || '  老系赎回额: ' || v_new_old_number ;
-- 认购成交金额

select  sum( to_number(replace(t.apply_amount,',',''),'9999999999999.99')) into v_new_jy_number   from busi_sheet t where t.business_type='020' and t.old_sys_id is not null and to_char(t.create_date,'yyyymmdd')=v_last_work_day;
select  sum( to_number(replace(t.trade_sqje,',',''),'9999999999999.99')) into v_new_old_number   from  t_fund_trade@newone t,t_fund_cust@newone c where t.cust_id=c.id and t.is_delete=0 and t.isvalid=1  and t.trade_sqrq=v_last_work_day and t.trade_type_code='020';
v_msg:=v_msg || '  新认购额：' || v_new_jy_number || '  老认购回额: ' || v_new_old_number ;
-- 申购成交金额
select  sum( to_number(replace(t.apply_amount,',',''),'9999999999999.99')) into v_new_jy_number   from busi_sheet t where t.business_type='022' and t.old_sys_id is not null and to_char(t.create_date,'yyyymmdd')=v_last_work_day;
select  sum( to_number(replace(t.trade_sqje,',',''),'9999999999999.99')) into v_new_old_number   from  t_fund_trade@newone t,t_fund_cust@newone c where t.cust_id=c.id and t.is_delete=0 and t.isvalid=1  and t.trade_sqrq=v_last_work_day and t.trade_type_code='022';
v_msg:=v_msg || '  新认购额：' || v_new_jy_number || '  老认购回额: ' || v_new_old_number ;








insert into t_fund_job_running_log(job_name,job_running_log) values(v_job_log_name,v_msg);
commit;

exception
     when others then

     rollback;
     v_msg:='新老系统同步数据比对成功'||sqlcode||':'||sqlerrm  ||dbms_utility.format_error_stack ;
     insert into t_fund_job_running_log(job_name,job_running_log) values(v_job_log_name,v_msg);
     commit;

end syn_old_system_compare_data;
/


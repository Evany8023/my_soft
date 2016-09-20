create or replace procedure smzj.syn_old_system_compare_data is


---- *************************************************************************
-- SUBSYS:     �йܷ���
-- PROGRAM:      syn_old_system_compare_data
-- RELATED TAB:
-- SUBPROG:
-- REFERENCE:
-- AUTHOR:       pangzq
-- DESCRIPTION:  ÿ�����϶Ա�ǰһ�����ݵ��Ƿ�ͬ�����
-- CREATE DATE:  2015-10-23
-- VERSION:
-- EDIT HISTORY:
-- *************************************************************************

v_msg varchar2(4000);--������Ϣ
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
--ǰһ�칤��������
select max(t.rq) into v_last_work_day from zsta.rlb@ta_dblink t where t.gzr='1' and  t.rq < to_char(sysdate,'yyyymmdd');
 -- ����
 select count(*) into v_new_jy_count  from busi_sheet t where to_char(t.sheet_create_time,'yyyymmdd')=v_last_work_day and t.old_sys_id is not null;
 select count(1) into v_old_jy_count from t_fund_trade@newone t,t_fund_cust@newone c where t.cust_id=c.id and t.is_delete=0 and t.isvalid=1  and t.trade_sqrq=v_last_work_day;
 
 -- ����
 select count(1) into v_new_kh_count from busi_investor_detail t where t.old_sys_id is not null and to_char(t.create_date,'yyyymmdd')=v_last_work_day;
 select count(1) into  v_old_kh_count  from t_fund_khsq@newone t,t_fund_cust@newone  c  where t.cust_id=c.id and t.is_delete=0 and t.sqrq=v_last_work_day;
  
 --�����˺�
 
 select count(1) into v_new_yhzh_count from busi_bind_bank_card t where to_char(t.bind_date,'yyyymmdd') = v_last_work_day and t.old_sys_id is not null;
 select count(1) into v_old_yhzh_count   from t_fund_account@newone t,t_fund_cust@newone c
 where t.cust_id=c.id and t.is_delete=0 and t.isvalid=1 and t.acc_sqrq=v_last_work_day;

v_msg:= v_last_work_day || '  �½�������' || v_new_jy_count || '  �Ͻ�����: ' || v_old_jy_count ;
v_msg:=v_msg || '   �¿�������' || v_new_kh_count || '  �Ͽ�����: ' || v_old_kh_count ;
v_msg:=v_msg || '  ����������' || v_new_yhzh_count || '  ��ϵͳ������: ' || v_old_yhzh_count ;

-- �ɽ��� �ݶ�ͬ��
select  sum( to_number(replace(t.apply_share,',',''),'9999999999999.99')) into v_new_jy_number   from busi_sheet t where t.business_type='024' and t.old_sys_id is not null and to_char(t.create_date,'yyyymmdd')=v_last_work_day;
select  sum( to_number(replace(t.trade_sqfe,',',''),'9999999999999.99')) into v_new_old_number   from  t_fund_trade@newone t,t_fund_cust@newone c where t.cust_id=c.id and t.is_delete=0 and t.isvalid=1  and t.trade_sqrq=v_last_work_day and t.trade_type_code='024';
v_msg:=v_msg || '  ����ض' || v_new_jy_number || '  ��ϵ��ض�: ' || v_new_old_number ;
-- �Ϲ��ɽ����

select  sum( to_number(replace(t.apply_amount,',',''),'9999999999999.99')) into v_new_jy_number   from busi_sheet t where t.business_type='020' and t.old_sys_id is not null and to_char(t.create_date,'yyyymmdd')=v_last_work_day;
select  sum( to_number(replace(t.trade_sqje,',',''),'9999999999999.99')) into v_new_old_number   from  t_fund_trade@newone t,t_fund_cust@newone c where t.cust_id=c.id and t.is_delete=0 and t.isvalid=1  and t.trade_sqrq=v_last_work_day and t.trade_type_code='020';
v_msg:=v_msg || '  ���Ϲ��' || v_new_jy_number || '  ���Ϲ��ض�: ' || v_new_old_number ;
-- �깺�ɽ����
select  sum( to_number(replace(t.apply_amount,',',''),'9999999999999.99')) into v_new_jy_number   from busi_sheet t where t.business_type='022' and t.old_sys_id is not null and to_char(t.create_date,'yyyymmdd')=v_last_work_day;
select  sum( to_number(replace(t.trade_sqje,',',''),'9999999999999.99')) into v_new_old_number   from  t_fund_trade@newone t,t_fund_cust@newone c where t.cust_id=c.id and t.is_delete=0 and t.isvalid=1  and t.trade_sqrq=v_last_work_day and t.trade_type_code='022';
v_msg:=v_msg || '  ���Ϲ��' || v_new_jy_number || '  ���Ϲ��ض�: ' || v_new_old_number ;








insert into t_fund_job_running_log(job_name,job_running_log) values(v_job_log_name,v_msg);
commit;

exception
     when others then

     rollback;
     v_msg:='����ϵͳͬ�����ݱȶԳɹ�'||sqlcode||':'||sqlerrm  ||dbms_utility.format_error_stack ;
     insert into t_fund_job_running_log(job_name,job_running_log) values(v_job_log_name,v_msg);
     commit;

end syn_old_system_compare_data;
/


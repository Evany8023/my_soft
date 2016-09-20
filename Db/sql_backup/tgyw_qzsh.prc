create or replace procedure smzj.tgyw_qzsh(c_result out sys_refcursor) is

---- *************************************************************************
-- SUBSYS:     托管服务
-- PROGRAM:      tgyw_qzsh
-- RELATED TAB:
-- SUBPROG:
-- REFERENCE:
-- AUTHOR:       liujian
-- DESCRIPTION:  强制赎回
  
-- CREATE DATE:  2015-10-23
-- VERSION:
-- EDIT HISTORY: 
-- *************************************************************************


v_count integer;
v_m_count integer;
v_id  varchar2(32  char);
v_msg   varchar2(4000);
v_job_name varchar2(100) :='tgyw_qzsh';
v_current_date  varchar2(8 char);  
v_sqrq  busi_product_qzsh.apply_date %type;
v_fund_code varchar2(16);
v_m_fund_code varchar2(16);
v_ya_day varchar2(20);
v_export_day varchar2(20);
v_djzh varchar2(19 char);
v_cust_id varchar2(19 char);


  cursor m_fund_m_cur  is select t.id,t.son_pt_no,t.parent_pt_no,t.apply_date,
                          decode(f.APPLYTYPE,'0','T+1','N', 'T+' || to_char(f.DELAYCFMDAYS) , '2' , '直销压单'  , f.APPLYTYPE),decode(f.APPLYTYPE,'0','1','N',to_char(f.DELAYCFMDAYS) , '2' , '2' )
                          from busi_product_qzsh t 
                          inner join zsta.fundextrainfo@ta_dblink f on t.parent_pt_no=f.FUNDCODE
                          where to_char(t.apply_date,'yyyyMMdd') >= (select rq  from (select rank() over(order by t.rq desc) as NUMS, t.rq from zsta.rlb@ta_dblink t  where t.rq < to_char(sysdate,'yyyyMMdd') and t.gzr = '1') where NUMS =10);
  
begin
 select count(*) into v_count from t_fund_job_status t where t.job_en_name = v_job_name and t.job_status = 1;
 
   if v_count > 0  then
    v_msg :='任务执行中，不允许重复执行，返回！';
    insert into t_fund_job_running_log(job_name,job_running_log) values(v_job_name,v_msg);
    open c_result for select 'faile' as res, v_msg as msg from dual;
    return;
  end if;
  
  --锁定
   select count(*) into v_count from t_fund_job_status t where t.job_en_name = v_job_name;
   if v_count > 0 then
      update t_fund_job_status t set t.job_status = 1 where t.job_en_name = v_job_name;
    else
      insert into t_fund_job_status(JOB_EN_NAME,JOB_CN_NAME,JOB_STATUS) values('tgyw_qzsh', '强制赎回','1');
    end if;
  commit;
  select to_char(sysdate,'yyyyMMdd') into v_current_date from dual;

  open m_fund_m_cur;
  loop
    fetch m_fund_m_cur into v_id, v_fund_code,v_m_fund_code,v_sqrq,v_ya_day ,v_m_count;
      if m_fund_m_cur%notfound then
        exit;
      end if;
      --t.delay_day,v_m_count,
      select t.SON_REGIST_ACC,t.cust_no into v_djzh,v_cust_id  from busi_pt_zm_relation t where t.son_pt_no=v_fund_code and t.parent_pt_no= v_m_fund_code;
      v_m_count:=v_m_count-1;
      if  v_m_count < 1 then
        select to_char(v_sqrq,'yyyyMMdd') into v_export_day from dual; 
      else 
        select rq into v_export_day from (select rank() over(order by t.rq asc) as NUMS, t.rq from zsta.rlb@ta_dblink t where t.rq > to_char(v_sqrq,'yyyyMMdd') and t.gzr = '1')  
        where NUMS = v_m_count;
        end if;
        
      update busi_product_qzsh t set t.export_date= v_export_day,t.export_desc =v_ya_day,t.regist_account=v_djzh,t.cust_no=v_cust_id  where t.id=v_id;
  end loop;
  close m_fund_m_cur;
  commit; 
 
  --释放
  update t_fund_job_status t set t.job_status = 0 where t.job_en_name = v_job_name;
    v_msg :='同步成功！   ' ||     v_current_date;
   insert into t_fund_job_running_log(job_name,job_running_log) values(v_job_name,v_msg);
    open c_result for select 'success' as res, v_msg as msg from dual;
  commit;

exception
    when others then
      rollback;
      v_msg :='同步失败，原因：' || to_char(v_sqrq,'yyyyMMdd') || '     '  || sqlcode || ':' || sqlerrm || '  ' || v_m_fund_code || ' ' || v_fund_code|| '   '  ||v_sqrq ||'  count:' ||v_m_count|| ':ya '  ||v_ya_day||   dbms_utility.format_error_backtrace() ;
      insert into t_fund_job_running_log(job_name,job_running_log) values(v_job_name,v_msg);
     update t_fund_job_status t set t.job_status = 0 where t.job_en_name = v_job_name;
     open c_result for select 'faile' as res, v_msg as msg from dual;
end tgyw_qzsh;
/


create or replace procedure smzj.quick_fedeem_summary
-- *************************************************************************
-- SYSTEM:       中登系统
-- SUBSYS:       TA子系统
-- PROGRAM:      quick_fedeem_summary
-- RELATED TAB:
-- SUBPROG:
-- REFERENCE:
-- DESCRIPTION:   每天汇总上一个工作日的不同产品的金额、份额、费用
-- INPUT:
-- OUTPUT:
-- RETURN:       0    正常返回
--               -1   数据库错误
-- AUTHOR:       xiaxiaonan
-- CREATE DATE:  2015-12-2
-- VERSION:
-- EDIT HISTORY: 
-- *************************************************************************
is
    v_msg varchar2(1000  char );
    v_job_name varchar2(100):= 'quick_fedeem_summary';
    summary_date  varchar2(20 char);
    v_product_id  varchar2(50 char);     --产品id
    v_com_id      varchar2(50 char);      --公司id
    v_product_no   varchar2(50 char);     --产品编号
    v_product_name  varchar2(50 char);    --产品名称     
    v_count    integer;                  --汇总金额
    v_share  varchar2(20 char);          --汇总份额
    v_fee  varchar2(20 char);            --汇总费用
    v_busi_type varchar2(20 char);       --业务类型
    v_isdelete  varchar2(1 char);        --是否删除
    v_sheet_no  varchar2(32 char);       --增加sheet_no解决快速赎回日志报错   

--取前一个工作日不同的产品id
cursor data_cur  is 
select  f.pt_id,f.company_id,f.pt_no,f.business_type,f.is_delete from BUSI_QUICK_SHEET f
where to_char(f.confirm_date,'yyyymmdd') = summary_date;


begin 
   select max(t.rq) into summary_date from t_rlb_jjzt t where t.rq < to_char(sysdate,'yyyymmdd') and gzr='1';

    open data_cur ;
    loop
        fetch data_cur into v_product_id,v_com_id,v_product_no,v_busi_type,v_isdelete;
        if data_cur%notfound then
          exit;
        end if;
         
        
        select count(*) into v_count from busi_quickredeem_summary_sheet f where
        to_char(f.confirm_date,'yyyymmdd')=summary_date and pt_id = v_product_id;
        
        if v_count>0 then
          exit;
         end if;
         
         --取汇总金额，汇总份额，汇总费用，根据产品id和确认日期分组
         select sum(amount),sum(apply_share),sum(procedure_fee) into v_count,v_share,v_fee from BUSI_QUICK_SHEET f 
         where  to_char(f.confirm_date,'yyyymmdd')=summary_date 
         group by f.PT_ID ;
         
         --根据产品编号取产品名称
         select cp_name into v_product_name from busi_product where id =  v_product_id;
         
        --增加sheet_no解决快速赎回日志报错
         select (substr(to_char(sysdate,'yyyyMMddhh24mmss'),0,14) || cast(dbms_random.value(10000000,99999999) as int)) into v_sheet_no from dual;
        insert into BUSI_QUICKREDEEM_SUMMARY_SHEET
        values (sys_guid(),v_sheet_no,v_product_id,v_com_id,v_product_no,v_product_name,v_count,v_share,v_fee,to_date(summary_date,'yyyymmdd'),v_busi_type,'0');
        
   
    end loop;
    close data_cur;
     
    insert into t_fund_job_running_log(job_name,job_running_log) values(v_job_name,'同步成功');
    commit;
    
EXCEPTION
    when others then
         if data_cur%isopen then
            close data_cur;
        end if;
        
        rollback;
        v_msg :='同步失败，原因：' || sqlcode || ':' || sqlerrm ||' '|| SUBSTR(DBMS_UTILITY.FORMAT_ERROR_BACKTRACE,1,500);
        insert into t_fund_job_running_log(job_name,job_running_log) values(v_job_name,v_msg);
        commit;
  
end quick_fedeem_summary;
/


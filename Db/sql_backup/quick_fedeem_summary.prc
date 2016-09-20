create or replace procedure smzj.quick_fedeem_summary
-- *************************************************************************
-- SYSTEM:       �е�ϵͳ
-- SUBSYS:       TA��ϵͳ
-- PROGRAM:      quick_fedeem_summary
-- RELATED TAB:
-- SUBPROG:
-- REFERENCE:
-- DESCRIPTION:   ÿ�������һ�������յĲ�ͬ��Ʒ�Ľ��ݶ����
-- INPUT:
-- OUTPUT:
-- RETURN:       0    ��������
--               -1   ���ݿ����
-- AUTHOR:       xiaxiaonan
-- CREATE DATE:  2015-12-2
-- VERSION:
-- EDIT HISTORY: 
-- *************************************************************************
is
    v_msg varchar2(1000  char );
    v_job_name varchar2(100):= 'quick_fedeem_summary';
    summary_date  varchar2(20 char);
    v_product_id  varchar2(50 char);     --��Ʒid
    v_com_id      varchar2(50 char);      --��˾id
    v_product_no   varchar2(50 char);     --��Ʒ���
    v_product_name  varchar2(50 char);    --��Ʒ����     
    v_count    integer;                  --���ܽ��
    v_share  varchar2(20 char);          --���ܷݶ�
    v_fee  varchar2(20 char);            --���ܷ���
    v_busi_type varchar2(20 char);       --ҵ������
    v_isdelete  varchar2(1 char);        --�Ƿ�ɾ��
    v_sheet_no  varchar2(32 char);       --����sheet_no������������־����   

--ȡǰһ�������ղ�ͬ�Ĳ�Ʒid
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
         
         --ȡ���ܽ����ܷݶ���ܷ��ã����ݲ�Ʒid��ȷ�����ڷ���
         select sum(amount),sum(apply_share),sum(procedure_fee) into v_count,v_share,v_fee from BUSI_QUICK_SHEET f 
         where  to_char(f.confirm_date,'yyyymmdd')=summary_date 
         group by f.PT_ID ;
         
         --���ݲ�Ʒ���ȡ��Ʒ����
         select cp_name into v_product_name from busi_product where id =  v_product_id;
         
        --����sheet_no������������־����
         select (substr(to_char(sysdate,'yyyyMMddhh24mmss'),0,14) || cast(dbms_random.value(10000000,99999999) as int)) into v_sheet_no from dual;
        insert into BUSI_QUICKREDEEM_SUMMARY_SHEET
        values (sys_guid(),v_sheet_no,v_product_id,v_com_id,v_product_no,v_product_name,v_count,v_share,v_fee,to_date(summary_date,'yyyymmdd'),v_busi_type,'0');
        
   
    end loop;
    close data_cur;
     
    insert into t_fund_job_running_log(job_name,job_running_log) values(v_job_name,'ͬ���ɹ�');
    commit;
    
EXCEPTION
    when others then
         if data_cur%isopen then
            close data_cur;
        end if;
        
        rollback;
        v_msg :='ͬ��ʧ�ܣ�ԭ��' || sqlcode || ':' || sqlerrm ||' '|| SUBSTR(DBMS_UTILITY.FORMAT_ERROR_BACKTRACE,1,500);
        insert into t_fund_job_running_log(job_name,job_running_log) values(v_job_name,v_msg);
        commit;
  
end quick_fedeem_summary;
/


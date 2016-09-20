create or replace procedure smzj.SYNC_PRODUCT_INFO
-- *************************************************************************
-- SYSTEM:       �е�ϵͳ
-- SUBSYS:       TA��ϵͳ
-- PROGRAM:      SYNC_PRODUCT_INFO
-- RELATED TAB:
-- SUBPROG:
-- REFERENCE:
-- DESCRIPTION:  ͬ��˽ļ��Ʒ��Ϣ
-- INPUT:
-- OUTPUT:
-- RETURN:       0    ��������
--               -1   ���ݿ����
-- AUTHOR:       luoyuan
-- CREATE DATE:  2015-07-29
-- VERSION:
-- EDIT HISTORY: 
-- *************************************************************************
AS
    v_fund_count integer;
    v_is_gswcp integer; --�Ƿ��Ǹ�ˮλ��Ʒ
    --v_sql      varchar2(100):= 'truncate table Busi_Product';
    v_msg      varchar2(100);
    v_job_name varchar2(100):= 'ͬ����Ʒ��Ϣ';
    v_fundcode Busi_Product.Product_No%type;
    v_fundstatus Busi_Product.Publish_Status%type;             --����״̬
    n_minsubsamountbyindi number(16,2);                        --�״��Ϲ���ͽ��
    n_minbidsamountbyindi number(16,2);                        --�״��깺��ͽ��
    n_minappbidsamountbyindi number(16,2);                        --׷���깺��ͽ��
    v_count integer;
    v_rlb_count integer;
    v_comp_name varchar(100 char);

    cursor fundinfo_cur is select t.fundcode,t.fundstatus from zsta.fundinfo@TA_DBLINK t;
   
    --vd_Publish_Date Busi_Product.Publish_Date % type;
BEGIN
    --execute immediate v_sql;
    open fundinfo_cur;
        loop
            fetch fundinfo_cur into v_fundcode,v_fundstatus;
            if fundinfo_cur % notfound then
               exit;
            end if;
            select count(*) into v_fund_count from Busi_Product t where t.product_no = v_fundcode;
            if v_fund_count > 0 then
               --��Ʒ״̬            
  
                             
               --�Ƿ��Ǹ�ˮλ��Ʒ
               select count(*) into v_is_gswcp from zsta.ut_sm_cpcsxx@TA_DBLINK where cpdm = v_fundcode;
       
                             
               --�Ϲ���㡢�깺��㣬׷���깺����
               begin
                   select t.minsubsamountbyindi,t.minbidsamountbyindi,t.minappbidsamountbyindi into n_minsubsamountbyindi,n_minbidsamountbyindi,n_minappbidsamountbyindi 
                     from zsta.fundlimit@TA_DBLINK t
                    where t.fundcode = v_fundcode;
               exception 
                   when no_data_found then
                       --�Ҳ�������Ϊ100��
                       n_minsubsamountbyindi := 1000000;
                       n_minbidsamountbyindi := 1000000;
                       n_minappbidsamountbyindi := 1000000;
               end;
               
               n_minsubsamountbyindi := nvl(n_minsubsamountbyindi, 1000000);
               n_minbidsamountbyindi := nvl(n_minbidsamountbyindi, 1000000);
               n_minappbidsamountbyindi := nvl(n_minappbidsamountbyindi, 1000000);
               
               v_comp_name :=null;
               select count(1) into v_count from Busi_Product p ,Busi_Company c  where c.id=p.cp_id and p.product_no=v_fundcode;
               if v_count  > 0 then
                 select c.cp_name into v_comp_name from Busi_Product p ,Busi_Company c  where c.id=p.cp_id and p.product_no=v_fundcode;
                 
               end if ;
               select count(1) into v_rlb_count from  t_rlb_jjzt  t where t.jjdm=v_fundcode and t.rq =to_char(sysdate ,'yyyymmdd');
               if v_rlb_count > 0 then
                 select  t.jjzt into  v_fundstatus  from t_rlb_jjzt  t where t.jjdm=v_fundcode and t.rq =to_char(sysdate ,'yyyymmdd')   ;
               end if;
                 
               
                        
               update Busi_Product t 
                  set t.start_price = to_char(n_minsubsamountbyindi),--�Ϲ����
                      t.plus_start_price = to_char(n_minappbidsamountbyindi),--׷���깺����
                      t.Publish_Status = v_fundstatus,
                      t.is_gsw_fund = case when v_is_gswcp > 0 then 1 else 0 end,
                      t.update_by = 'userjob',
                      t.update_date = sysdate ,
                      t.cp_name=v_comp_name
                where t.product_no = v_fundcode;
            end if;
        end loop;
    close fundinfo_cur;
    commit;
    
    update Busi_Product t set t.Publish_Status='9' where to_char(t.update_date,'yyyymmdd') <  to_char(sysdate,'yyyymmdd');
    
    v_msg :='ͬ���ɹ�';
    insert into t_fund_job_running_log(job_name,job_running_log) values(v_job_name,v_msg);
    
    
    commit;
EXCEPTION
  when others then
    rollback;
    v_msg :='ͬ��ʧ�ܣ�ԭ��' || sqlcode || ':' || sqlerrm ||' '|| SUBSTR(DBMS_UTILITY.FORMAT_ERROR_BACKTRACE,1,500) || v_fundcode;
    insert into t_fund_job_running_log(job_name,job_running_log) values(v_job_name,v_msg);
    commit;
end SYNC_PRODUCT_INFO;
/


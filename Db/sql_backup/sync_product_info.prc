create or replace procedure smzj.SYNC_PRODUCT_INFO
-- *************************************************************************
-- SYSTEM:       中登系统
-- SUBSYS:       TA子系统
-- PROGRAM:      SYNC_PRODUCT_INFO
-- RELATED TAB:
-- SUBPROG:
-- REFERENCE:
-- DESCRIPTION:  同步私募产品信息
-- INPUT:
-- OUTPUT:
-- RETURN:       0    正常返回
--               -1   数据库错误
-- AUTHOR:       luoyuan
-- CREATE DATE:  2015-07-29
-- VERSION:
-- EDIT HISTORY: 
-- *************************************************************************
AS
    v_fund_count integer;
    v_is_gswcp integer; --是否是高水位产品
    --v_sql      varchar2(100):= 'truncate table Busi_Product';
    v_msg      varchar2(100);
    v_job_name varchar2(100):= '同步产品信息';
    v_fundcode Busi_Product.Product_No%type;
    v_fundstatus Busi_Product.Publish_Status%type;             --发行状态
    n_minsubsamountbyindi number(16,2);                        --首次认购最低金额
    n_minbidsamountbyindi number(16,2);                        --首次申购最低金额
    n_minappbidsamountbyindi number(16,2);                        --追加申购最低金额
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
               --产品状态            
  
                             
               --是否是高水位产品
               select count(*) into v_is_gswcp from zsta.ut_sm_cpcsxx@TA_DBLINK where cpdm = v_fundcode;
       
                             
               --认购起点、申购起点，追加申购限制
               begin
                   select t.minsubsamountbyindi,t.minbidsamountbyindi,t.minappbidsamountbyindi into n_minsubsamountbyindi,n_minbidsamountbyindi,n_minappbidsamountbyindi 
                     from zsta.fundlimit@TA_DBLINK t
                    where t.fundcode = v_fundcode;
               exception 
                   when no_data_found then
                       --找不到就设为100万
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
                  set t.start_price = to_char(n_minsubsamountbyindi),--认购起点
                      t.plus_start_price = to_char(n_minappbidsamountbyindi),--追加申购限制
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
    
    v_msg :='同步成功';
    insert into t_fund_job_running_log(job_name,job_running_log) values(v_job_name,v_msg);
    
    
    commit;
EXCEPTION
  when others then
    rollback;
    v_msg :='同步失败，原因：' || sqlcode || ':' || sqlerrm ||' '|| SUBSTR(DBMS_UTILITY.FORMAT_ERROR_BACKTRACE,1,500) || v_fundcode;
    insert into t_fund_job_running_log(job_name,job_running_log) values(v_job_name,v_msg);
    commit;
end SYNC_PRODUCT_INFO;
/


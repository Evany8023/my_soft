create or replace procedure smzj.syn_old_system_jy_data is
v_msg varchar2(4000);--返回信息
v_sql varchar2(1000);--拼接sql
v_job_log_name varchar2(60) :='syn_old_system_jy_data';

v_bzxx             VARCHAR2(1000 CHAR);--备注
v_trade_fhbl     VARCHAR2(255 CHAR);--创建时间
v_trade_fhfs    VARCHAR2(255 CHAR);--创建人
v_trade_jesh      VARCHAR2(255 CHAR);
v_trade_sqdh        VARCHAR2(255 CHAR);
v_trade_sqfe      VARCHAR2(255 CHAR);
v_trade_sqje         VARCHAR2(255 CHAR);
v_trade_sqrq         VARCHAR2(255 CHAR);
v_trade_sqsj      VARCHAR2(255 CHAR);
v_trade_sxfy        VARCHAR2(255 CHAR);  
v_trade_type         VARCHAR2(255 CHAR);
v_fund_id          NUMBER(19);
v_trade_ysqh       VARCHAR2(255 CHAR);
v_trade_ysqs          VARCHAR2(255 CHAR);
v_trade_zdsh       VARCHAR2(255 CHAR);                        
v_trade_fhfs_code    VARCHAR2(255 CHAR);    
v_trade_jesh_code      VARCHAR2(255 CHAR);     
v_trade_type_code      VARCHAR2(255 CHAR);    
v_create_date      TIMESTAMP(6);
v_create_user      VARCHAR2(255 CHAR);
v_jgbm  VARCHAR2(255 CHAR);     
v_idcard           VARCHAR2(255 CHAR);        
v_idtypecode       VARCHAR2(255 CHAR); 
v_djzh             VARCHAR2(255 CHAR);  
v_jy_id varchar(16 char);  --交易id

v_cust_id varchar(35 char);
v_generate_id  varchar(35 char);
v_product_id  varchar(35 char);
v_product_code  varchar(35 char);
v_comid varchar(35 char);
v_count  integer;
v_m_count  integer;
v_dou_count  integer;
v_yhzh_count  integer;
v_work_day varchar(10 char);
v_max_date date;
account_cur    SYS_REFCURSOR;
v_import_day date;
v_OLD_MANAGER integer;



begin

select max(t.sheet_create_time) into v_max_date from BUSI_SHEET t;
 if v_max_date is null then
    v_work_day:='20130101';
  else 
    select to_char(sysdate-10,'yyyymmdd') into v_work_day from dual;
  end if;
--交易
v_sql:='select t.id, t.create_date,t.trade_bzxx,t.trade_fhbl,t.trade_fhfs,t.trade_jesh,t.trade_sqdh,t.trade_sqfe,t.trade_sqje,t.trade_sqrq,t.trade_sqsj
    ,t.trade_sxfy,t.trade_type,t.trade_ysqh,t.trade_ysqs,t.trade_zdsh,t.fund_id,t.create_user,t.trade_fhfs_code,t.trade_jesh_code,t.trade_type_code,t.jgbm ,
    c.idcard,c.idtypecode,c.djzh 
   from t_fund_trade@newone t,t_fund_cust@newone c  
   where t.cust_id=c.id and t.is_delete=0 and t.isvalid=1   and t.trade_sqrq>='||v_work_day;  
open account_cur for v_sql ;
loop
  fetch account_cur into v_jy_id, v_create_date,v_bzxx,v_trade_fhbl,v_trade_fhfs,v_trade_jesh,v_trade_sqdh,v_trade_sqfe,v_trade_sqje,v_trade_sqrq,v_trade_sqsj,
                v_trade_sxfy,   v_trade_type,  v_trade_ysqh,  v_trade_ysqs, v_trade_zdsh, v_fund_id,v_create_user,v_trade_fhfs_code,v_trade_jesh_code,v_trade_type_code,v_jgbm,
                v_idcard,v_idtypecode,v_djzh;
       if account_cur%notfound then
          exit;
       end if;
       
      select count(1) into v_OLD_MANAGER from  t_FUND_OLD_MANAGER m where  m.fundcode=v_jgbm;
      if v_OLD_MANAGER < 1 then
       
            select to_date(v_trade_sqrq ||v_trade_sqsj ,'yyyyMMddHH24:MI:SS')  into v_import_day from dual;
              v_cust_id:=null;
            select count(1) into v_count from busi_investor_credit c where c.credit_no=v_idcard and c.credit_type=v_idtypecode;
            if v_count >0 then
               select c.id into v_cust_id from busi_investor_credit c where c.credit_no=v_idcard and c.credit_type=v_idtypecode;
            end if;
            
            select count(1) into v_m_count from busi_company  c where c.insti_code=v_jgbm;
            if v_m_count> 0 then
              select c.id into v_comid from busi_company  c where c.insti_code=v_jgbm;
            end if;
            
            select count(1) into v_yhzh_count from busi_product t ,t_fund_info@newone info where info.fund_code=t.product_no and info.id=v_fund_id;
            if v_yhzh_count =1 then
               select t.id,t.product_no into  v_product_id ,v_product_code  from busi_product t ,t_fund_info@newone info where info.fund_code=t.product_no and info.id=v_fund_id;
            end if;
            
            v_trade_sqje:=replace(v_trade_sqje,',','');
            if isnumeric(v_trade_sqje)=0 then 
              v_trade_sqje:=null;
            end if;
            
             select count(*) into v_dou_count from BUSI_SHEET t where t.old_sys_id= v_jy_id;
            
            if v_cust_id is not null and v_comid is not null and v_product_id is not null and v_dou_count < 1 then

                        
                      select lower(SYS_GUID()) into v_generate_id  from dual;
                      insert into BUSI_SHEET(id,sheet_no,pt_id,pt_no,dt_id,bank_card_id,sheet_create_time,amount,manager_contract_status,investor_contract_status,trustee_contract_status
                      ,fund_is_receive,investor_message,status,is_examine,examine_by,examine_date,create_by,create_date,business_type,company_id,credit_id,manager_fund_confirm,remark
                      ,apply_amount,apply_share,bonus_way,bonus_rate,procedure_fee,design_redeem,original_apply_no,huge_sum_redeem,original_apply_count,OLD_SYS_ID)
                      
                      values(v_generate_id,v_trade_sqdh,v_product_id,v_product_code,null,null,v_import_day,to_number(v_trade_sqje,'9999999999999.99'),'1', '1','1',
                      '1',null, '1','1','oldsys',sysdate,v_create_user,v_import_day,v_trade_type_code,v_comid,v_cust_id,'1',v_bzxx,
                     v_trade_sqje ,v_trade_sqfe,v_trade_fhfs,v_trade_fhbl,v_trade_sxfy,v_trade_zdsh,v_trade_ysqh,v_trade_jesh,v_trade_ysqs,v_jy_id);
              
              elsif v_dou_count> 0 then
              
              update BUSI_SHEET t set t.sheet_no=v_trade_sqdh ,t.pt_id=v_product_id,t.pt_no=v_product_code,t.sheet_create_time=v_import_day,
              t.amount=to_number(v_trade_sqje,'9999999999999.99'),t.business_type=v_trade_type_code,t.create_date=v_import_day,t.company_id=v_comid,
              t.credit_id=v_cust_id,t.apply_amount=v_trade_sqje,t.apply_share=v_trade_sqfe,t.bonus_way=v_trade_fhfs,t.bonus_rate=v_trade_fhbl,
              t.procedure_fee=v_trade_sxfy,t.design_redeem=v_trade_zdsh,t.original_apply_no=v_trade_ysqh,t.huge_sum_redeem=v_trade_jesh,t.original_apply_count=v_trade_ysqs
              where t.old_sys_id=v_jy_id;
                        
    
            
            end if;
      
      
      end if;
      
          
end loop;
close    account_cur;


v_msg:='老数据同步成功,交易！';
insert into t_fund_job_running_log(job_name,job_running_log) values(v_job_log_name,v_msg);
commit;

delete from busi_sheet st where st.old_sys_id in ( select t.old_sys_id from Busi_Sheet t where t.old_sys_id is not null  and t.sheet_create_time > (sysdate -10 )
and  not exists (select tr.id from t_Fund_Trade@newone tr where tr.id=t.old_sys_id ) ) ;
commit;
exception
     when others then
         if account_cur%isopen then
            close account_cur;
        end if;

     rollback;
     DBMS_OUTPUT.put_line('sqlcode : '||sqlcode);
     DBMS_OUTPUT.put_line('sqlerror : '||sqlerrm);
     v_msg:='老数据同步'||sqlcode||':'||sqlerrm  ||dbms_utility.format_error_stack || v_trade_sqje;
     insert into t_fund_job_running_log(job_name,job_running_log) values(v_job_log_name,v_msg);
     commit;

end syn_old_system_jy_data;
/


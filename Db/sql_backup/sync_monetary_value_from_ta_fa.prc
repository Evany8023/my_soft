create or replace procedure smzj.sync_monetary_value_from_ta_fa AS

  v_msg   varchar2(4000);
  v_date      date;
  v_create_date varchar2(16);
  v_fund_id   varchar2(32);
  v_fund_clr  varchar2(32);
    v_fund_name  varchar2(200);
  v_fund_code varchar2(16);
    v_fund_com_id varchar2(32);
 cursor fundinfo_cur is
    select t.id,t.publish_date, t.product_no,t.cp_id,t.id,t.name
      from Busi_Product t
      inner join busi_product_add  a on t.id=a.PRODUCT_ID
     where t.is_validate=1
       and t.is_examine=1 and t.is_delete = 0 
       and  a.FUND_TYPE='1'
       and t.PUBLIC_NET_PERIOD <> '0';

begin


  select to_date('20140901','yyyymmdd') into v_date from dual;
  select to_char(sysdate,'yyyymmdd') into v_create_date from dual;

  open  fundinfo_cur;
  loop
    fetch fundinfo_cur into v_fund_id,v_fund_clr, v_fund_code,v_fund_com_id,v_fund_id,v_fund_name;
    if fundinfo_cur%notfound then
      exit;
    end if;

    delete from busi_public_netval  v where v.product_no=v_fund_code;
    delete from busi_tz_netval  v where v.product_no=v_fund_code;
    delete busi_mgr_netval v where v.product_no=v_fund_code;

   insert into busi_public_netval (id,product_no,net_val_date,ten_thousand_income,return_rate,product_name,pt_id,cp_id)
      select ID_SEQ.nextVal,a.fundcode,to_date( a.tradedate,'yyyymmdd' ),a.mwfsy,a.qrnhsyl,v_fund_name,v_fund_id,v_fund_com_id from v_fundnav@wbdb_link a
       where a.nav is not null and a.fundcode = v_fund_code and  a.tradedate >= '20150101';

   insert into busi_tz_netval (id,product_no,net_val_date,ten_thousand_income,return_rate,product_name,pt_id,cp_id)
      select ID_SEQ.nextVal,a.fundcode,to_date( a.tradedate,'yyyymmdd' ),a.mwfsy,a.qrnhsyl,v_fund_name,v_fund_id,v_fund_com_id from v_fundnav@wbdb_link a
       where a.nav is not null and a.fundcode = v_fund_code and  a.tradedate >= '20150101';
       
  insert into busi_mgr_netval (id,product_no,net_val_date,ten_thousand_income,return_rate,product_name,pt_id,cp_id)
      select ID_SEQ.nextVal,a.fundcode,to_date( a.tradedate,'yyyymmdd' ),a.mwfsy,a.qrnhsyl,v_fund_name,v_fund_id,v_fund_com_id from v_fundnav@wbdb_link a
       where a.nav is not null and a.fundcode = v_fund_code and  a.tradedate >= '20150101';

   end loop;
   close fundinfo_cur;
  --释放
 

  v_msg :='同步成功！';
  insert into t_fund_job_running_log(job_name,job_running_log) values('货币列表净值同步定时任务',v_msg);
 commit;
  exception
    when others then
          rollback;
      v_msg :='同步失败，原因：'|| sqlcode || ':' || sqlerrm ;
      insert into t_fund_job_running_log(job_name,job_running_log) values('货币列表净值同步定时任务',v_msg||dbms_utility.format_error_backtrace() );
      commit;

end sync_monetary_value_from_ta_fa;
/


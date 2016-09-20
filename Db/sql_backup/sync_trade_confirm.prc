create or replace procedure smzj."SYNC_TRADE_CONFIRM" as

---- *************************************************************************
-- SUBSYS:     净值数据同步服务
-- PROGRAM:      sync_trade_confirm
-- RELATED TAB:
-- SUBPROG:
-- REFERENCE:
-- AUTHOR:       sunyang
-- DESCRIPTION:  每日早上7点同步净值信息
-- CREATE DATE:  2015年12月11日16:55:10
-- VERSION:
-- EDIT HISTORY:
-- *************************************************************************



 v_msg   varchar2(1000);
 v_job_name varchar2(100):= '同步净值数据';

 v_open_date varchar2(20);  -- 开放日期
 v_busi_date varchar2(20); -- 交收日期
 v_today varchar2(30); -- 现在的时间
 cur_ptno SYNC_TRADE_DATA.PT_NO%type; -- 产品代码
 
 v_ptname varchar2(100); -- 产品名称
 v_nav_date varchar2(20);   --最近开放日期
 v_unit_val number(10,4); -- 单位净值
 v_confirm_amount number; -- 申购确认总金额
 v_confirm_share number; -- 赎回确认总份额
 v_ransom_money number;  -- 预估赎回金额
 v_busi_money number;    -- 预交准备交收资金
 
 
 cursor cur_pro  is 
 select m.jjdm,m.rq ,t.nav from   (select rl.jjdm,rl.rq,  row_number() over(partition by  rl.jjdm order by rl.rq desc) rn from t_rlb_jjzt rl 
      where rl.jjzt in('0','5','6') and rl.gzr = '1'  and rl.rq <to_char(sysdate,'yyyyMMdd') ) m,
      v_fundnav@wbdb_link t 
      where m.rn =1 and t.tradedate=m.rq and t.fundcode=m.jjdm;


BEGIN
  delete SYNC_TRADE_DATA;
 
  
   
   v_today := to_char(sysdate,'yyyy-MM-dd hh24:mi:ss'); -- 数据同步时间
   
  
    open cur_pro;
    loop
      fetch cur_pro into cur_ptno,v_nav_date,v_unit_val;
      
      if cur_pro%notfound then
        exit;
      end if;
    
           
       begin
             -- 产品名称
             select  p.name into v_ptname from Busi_Product p where p.product_no = cur_ptno;
        exception   when no_data_found then
          v_ptname:=null;
        end;
        if v_ptname is not null then
          
         -- 交收日期
           select min(rq) into v_busi_date from t_rlb_jjzt rl where rl.rq >to_char(sysdate,'yyyyMMdd') and 
            rl.gzr = '1' and  rl.jjdm=cur_ptno;
                   
               --上一个开放日    
           select max(rq) into v_open_date from t_rlb_jjzt rl where rl.rq <to_char(sysdate,'yyyyMMdd') and 
            rl.gzr = '1' and  rl.jjdm=cur_ptno;
              
             -- 申购确认总金额
            select round(sum(confirm_amount),4) into v_confirm_amount from 
            busi_trading_confirm where business_type = '122' and pt_no = cur_ptno and apply_date=v_open_date; 
                
            -- 赎回确认总份额
            select round(sum(confirm_share),4) into v_confirm_share from 
            busi_trading_confirm where business_type = '124' and pt_no = cur_ptno and apply_date=v_open_date;
                
            -- 预估赎回金额
            v_ransom_money := round((v_confirm_share*v_unit_val),4);
                
            -- 预交准备交收资金
            if (v_ransom_money-v_confirm_amount)>0 then
              v_busi_money := round((v_ransom_money-v_confirm_amount),4);
            else
              v_busi_money := 0;
            end if;

            insert into SYNC_TRADE_DATA
            (pt_no,pt_name,unit_net_val,apply_all_amount,confirm_share,
            open_date,busi_date,hope_ransom,hope_busi_money,sync_date)
            values
            (cur_ptno,v_ptname,v_unit_val,v_confirm_amount,v_confirm_share,
            v_open_date,v_busi_date,v_ransom_money,v_busi_money,v_today);
                  
                  
            end if;
              

 
  
  end loop;
  close cur_pro;
   v_msg:='同步预交收成功';
        insert into t_fund_job_running_log (JOB_NAME,job_running_log) values (v_job_name,v_msg);
        
  commit;

  exception
    when others then
        rollback;
        v_msg:=sqlcode||':'||sqlerrm ||'   '|| dbms_utility.format_error_backtrace() || cur_ptno;
        insert into t_fund_job_running_log (JOB_NAME,job_running_log) values (v_job_name,v_msg);
       commit;
end sync_trade_confirm;
/


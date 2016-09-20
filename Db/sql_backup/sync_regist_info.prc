CREATE OR REPLACE PROCEDURE SMZJ.SYNC_REGIST_INFO
-- *************************************************************************
-- SYSTEM:       中登系统
-- SUBSYS:       TA子系统
-- PROGRAM:      SYNC_REGIST_INFO
-- RELATED TAB:
-- SUBPROG:
-- REFERENCE:
-- DESCRIPTION:  定时增量同步客户登记账号到证件表
-- INPUT:
-- OUTPUT:
-- RETURN:       0    正常返回
--               -1   数据库错误
-- AUTHOR:       徐鹏飞
-- CREATE DATE:  2016-02-23
-- VERSION:
-- EDIT HISTORY: 
-- *************************************************************************
IS 
    v_msg                        varchar2(1000);
    v_job_name                   varchar2(100):= '同步客户登记账号信息';
    
    v_cust_count                 integer;                       --客户个数

    v_zjhm            Busi_Investor_Credit.Credit_No%type;      --证件号码
    v_zjlx            Busi_Investor_Credit.Credit_Type%type;    --证件类型
    v_djzh            Busi_Investor_Credit.Regist_Account%type; --登记账号
    
    cursor custinfo_cur is select t.djzh,t.zjhm,t.zjlx from zsta.uv_xx_khxx_sm@TA_DBLINK t 
                            inner join BUSI_INVESTOR_CREDIT c on t.zjhm=c.CREDIT_NO and t.zjlx=c.credit_type 
                           where c.REGIST_ACCOUNT is null and c.is_delete=0;
                           
    cursor custinfo_cur2 is  select t.taaccountid as djzh, t.certificateno as zjhm, case t.invtp when '1' then '0' when '0' then '1' end || t.certificatetype as zjlx from zsta.c_ack_acct_zd@TA_DBLINK t 
                            inner join BUSI_INVESTOR_CREDIT c on t.certificateno=c.CREDIT_NO and case t.invtp when '1' then '0' when '0' then '1' end || t.certificatetype=c.credit_type 
                           where c.REGIST_ACCOUNT is null and c.is_delete=0;

begin        --增量同步客户登记账号到证件表开始     
    open custinfo_cur;
        loop
            fetch custinfo_cur into v_djzh,v_zjhm,v_zjlx;
            if custinfo_cur%notfound then
               exit;
            end if;
    
            select count(1) into v_cust_count from Busi_Investor_Credit t where  t.credit_no=v_zjhm and t.credit_type = v_zjlx and t.REGIST_ACCOUNT is null;

            if v_cust_count=1 then
                  update Busi_Investor_Credit t set t.regist_account=v_djzh where  t.credit_no = v_zjhm  and t.credit_type = v_zjlx; 
            elsif v_cust_count >1 then
                  v_msg := '同步客户信息时，存在重复的用户：，证件号码:' || v_zjhm;
                  insert into t_fund_job_running_log (job_name, job_running_log) values (v_job_name, v_msg);
            end if;
      end loop;
      close custinfo_cur;
      
      
      open custinfo_cur2;
        loop
            fetch custinfo_cur2 into v_djzh,v_zjhm,v_zjlx;
            if custinfo_cur2%notfound then
               exit;
            end if;
    
            select count(1) into v_cust_count from Busi_Investor_Credit t where  t.credit_no=v_zjhm and t.credit_type = v_zjlx and t.REGIST_ACCOUNT is null;

            if v_cust_count=1 then
                  update Busi_Investor_Credit t set t.regist_account=v_djzh where  t.credit_no = v_zjhm  and t.credit_type = v_zjlx; 
            elsif v_cust_count >1 then
                  v_msg := '同步客户信息时，存在重复的用户：，证件号码:' || v_zjhm;
                  insert into t_fund_job_running_log (job_name, job_running_log) values (v_job_name, v_msg);
            end if;
      end loop;
      close custinfo_cur2;
      
      

v_msg :='同步成功';
 insert into t_fund_job_running_log(job_name,job_running_log) values(v_job_name,v_msg);
commit;

EXCEPTION
    when others then
        if custinfo_cur%isopen then
            close custinfo_cur;
        end if;
        rollback;
        
        if custinfo_cur2%isopen then
            close custinfo_cur;
        end if;
        rollback;
        
        
        v_msg :='同步失败，原因：' || sqlcode || ':' || sqlerrm || SUBSTR(DBMS_UTILITY.FORMAT_ERROR_BACKTRACE,1,500);
        insert into t_fund_job_running_log(job_name,job_running_log) values(v_job_name,v_msg);
        commit;
end SYNC_REGIST_INFO;
/


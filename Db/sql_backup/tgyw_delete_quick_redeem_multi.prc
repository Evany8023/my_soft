CREATE OR REPLACE PROCEDURE SMZJ.TGYW_DELETE_QUICK_REDEEM_MULTI (p_batchid in  varchar2,p_fundid in  varchar2, p_compid in varchar2,p_isMgr in varchar2,p_mgrId in varchar2,flag out varchar2,msg out varchar2 ) is
---- *************************************************************************
-- SUBSYS:     托管服务
-- PROGRAM:      TGYW_PT_DELETE_TRADE_DATA
-- RELATED TAB:
-- AUTHOR:       刘石磊
-- DESCRIPTION:
--     删除快速赎回
-- CREATE DATE:  2016-06-13 
-- VERSION:
-- EDIT HISTORY:
-- *************************************************************************

  v_job_name varchar2(100) :='TGYW_DELETE_QUICK_REDEEM_BATCH';
  v_ch_job_name varchar2(100) :='批量删除快速赎回数据';
  v_msg varchar2(4000);--返回信息
  v_flag integer :=0;--标志本地证件号码对应的名称与TA的名称是否一致
  ve_Exception   EXCEPTION;
  v_zjlb varchar2(50);--证件类别
  v_zjhm varchar2(50);--证件代码
  v_productId varchar2(50);--产品Id
  v_appDate date; --申请日期
  v_cust_id varchar2(32 char );
  v_count integer :=0;
  v_sql varchar2(2014);
  type myrefcur  is  ref  cursor;
  sh_quick_data_cur myrefcur;

begin

  if trim(p_compid) is null  or  trim(p_compid) is null then
            v_flag := '9999';
            v_msg  := '基金产品,基金公司必填';
            raise ve_Exception;
   end if;

   select count(*) into v_count from t_fund_job_status t where t.job_en_name = v_job_name;
   if v_count < 1 then
     insert into t_fund_job_status(job_en_name,job_cn_name) values(v_job_name,v_ch_job_name);
   end if;

   select count(*) into v_count from t_fund_job_status t where t.job_en_name = v_job_name and t.job_status=1;
   if v_count > 0  then
      v_msg :='任务执行中不允许重复执行，请稍候再试！';
      insert into t_fund_job_running_log(job_name,job_running_log) values('',v_msg);
       raise ve_Exception;
    end if;



  update t_fund_job_status t set t.job_status = 1 where t.job_en_name = v_job_name;
  v_sql:='select p.apply_date,p.product_id,credit_no,p.CREDIT_TYPE_NO from Busi_Batch_Quick_Redeem_Tmp p';
  
    --表示二级管理员
  if p_isMgr=0 then
    v_sql:=v_sql||' join busi_product_authorization a on a.product_id=p.product_id'; 
  end if;

    v_sql:=v_sql||' where p.status=1 and p.batch_number_id='''||p_batchid||'''';
  
  if p_fundid is not null then
    v_sql:=v_sql||' and p.product_id='''||p_fundid||'''';
  end if;

  if p_isMgr=0 then
    v_sql:=v_sql||' and a.mgr_id='''||p_mgrId||''''; 
  end if;
  
  
  open sh_quick_data_cur for v_sql;
   loop
   fetch sh_quick_data_cur into v_appDate,v_productId,v_zjhm,v_zjlb;
   exit when  sh_quick_data_cur%notfound;
             --开户数据根据导入的客户证件和证件类型（机构、产品信息和申请日期）删除
              select count(t.id) into  v_count from Busi_Investor_Credit  t ,busi_credit_company  cc where
               cc.credit_id=t.id and  t.credit_no =v_zjhm and t.credit_type=v_zjlb and 
               cc.company_id=p_compid  and t.is_delete=0;
               v_cust_id:=null;
               
               if v_count > 0 then
                     select t.id into  v_cust_id from Busi_Investor_Credit  t ,busi_credit_company  cc,busi_product info where 
                                   cc.credit_id=t.id and cc.company_id=info.cp_id and  t.credit_no =v_zjhm and t.credit_type=v_zjlb and 
                                   cc.company_id=p_compid and info.id=v_productId and t.is_delete=0;
                         
                     delete from  Busi_Quick_Sheet t where t.credit_id= v_cust_id and t.pt_id=v_productId and t.business_type='024' and to_char(t.sheet_create_time,'yyyy-mm-dd')=to_char(v_appDate,'yyyy-mm-dd');
                  
               end if ;
           --删除指定用户下的数据
           delete from Busi_Batch_Quick_Redeem_Tmp t where   t.company_id=p_compid and t.batch_number_id=p_batchid and t.product_id=v_productId  and t.status=1;
   end loop;
  close sh_quick_data_cur;
  
 
  update t_fund_job_status t set t.job_status = 0 where t.job_en_name = v_job_name;
  commit;
  flag:='000';
   msg  := '删除客户导入 快速赎回 数据导成功';
  insert into t_fund_job_running_log(job_name,job_running_log) values(v_job_name,msg);

EXCEPTION
    WHEN ve_exception then
        if sh_quick_data_cur%isopen then 
        close sh_quick_data_cur;
        end if;
        rollback;
          flag:=v_flag;
           msg  := '删除客户导入 快速赎回 数据导失败：'||sqlerrm;
          insert into t_fund_job_running_log(job_name,job_running_log) values(v_job_name,msg);
        RETURN;
    WHEN OTHERS THEN
        if sh_quick_data_cur%isopen then 
        close sh_quick_data_cur;
        end if;
        rollback;
          flag:='1000';
           msg  := '删除客户导入 快速赎回 数据导失败：' || v_msg || '   '   || sqlerrm;
         insert into t_fund_job_running_log(job_name,job_running_log) values(v_job_name,msg);
        return;

end TGYW_DELETE_QUICK_REDEEM_MULTI;
/


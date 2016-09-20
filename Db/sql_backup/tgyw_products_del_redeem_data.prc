CREATE OR REPLACE PROCEDURE SMZJ.tgyw_products_del_Redeem_data (p_fundid in  varchar2,
                                                     p_compid in varchar2,
                                                     p_ismgr in varchar2,  --是否一级管理人
                                                     p_mgrid in varchar2,  --管理人ID
                                                     todaydate in varchar2,
                                                     flag out varchar2,
                                                     msg out varchar2 ) is
---- *************************************************************************
-- SUBSYS:     托管服务
-- PROGRAM:      tgyw_products_del_Redeem_data
-- RELATED TAB:
-- AUTHOR:       卢雅琴
-- DESCRIPTION:
--    delete all data   , p_fundid   , p_compid , todaydate
-- CREATE DATE:  2016-06-07
-- VERSION:
-- EDIT HISTORY:
-- *************************************************************************

  v_job_name varchar2(100) :='tgyw_products_del_Redeem_data';
  v_ch_job_name varchar2(100) :='多产品录单批量删除赎回';
  v_msg varchar2(4000);--返回信息
  v_flag integer :=0;--标志本地证件号码对应的名称与TA的名称是否一致
  ve_Exception   EXCEPTION;
  v_zjlb varchar2(50);--证件类别
  v_zjhm varchar2(50);--证件代码
  v_cust_id varchar2(32 char );
  v_count integer :=0;
  v_product_id busi_batch_redeem_tmp.product_id%type; --产品id
  v_apply_date busi_batch_redeem_tmp.apply_date%type; --申请日期
  v_id busi_batch_redeem_tmp.id%type ;--临时表id
  v_sql varchar2(2014);--数据集SQL
  type myrefcur  is  ref  cursor;
  sh_data_cur myrefcur;  --定义赎回数据游标


begin
    --不是一级管理员
    if (p_ismgr is not null and p_ismgr='0') then
    v_sql:='select t.id,t.credit_no,t.credit_type_no,t.PRODUCT_ID,t.apply_date from Busi_Batch_Redeem_Tmp t join busi_product_authorization pa on t.product_id = pa.product_id
    where t.company_id='''||p_compid||''' and pa.mgr_id='''||p_mgrid||''' and t.BATCH_NUMBER_ID like '''|| todaydate||'%'' and t.status=1';
    else
    v_sql:='select t.id,t.credit_no,t.credit_type_no,t.PRODUCT_ID,t.apply_date from Busi_Batch_Redeem_Tmp t
    where t.company_id='''||p_compid||''' and t.BATCH_NUMBER_ID like '''|| todaydate||'%'' and t.status=1';
    end if;
    
    --产品id为空
    if p_fundid is not null then
      v_sql:=v_sql|| ' and t.product_id =''' ||p_fundid || '''';
    end if;

  if trim(p_compid) is null or trim(todaydate) is null then
            v_flag := '9999';
            v_msg  := '基金公司和日期必填';
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

  --产品id为空
  if p_fundid is null then
  -- 删除批量导入赎回
  open sh_data_cur for v_sql;
   loop
      fetch sh_data_cur into v_id,v_zjhm, v_zjlb,v_product_id,v_apply_date ;
          if sh_data_cur%notfound then
               exit;
           end if;
             --开户数据根据导入的客户证件和证件类型（机构、产品信息和申请日期）删除
              select count(t.id) into  v_count from Busi_Investor_Credit  t ,busi_credit_company  cc  where cc.credit_id=t.id and  t.credit_no =v_zjhm and t.credit_type=v_zjlb and
               cc.company_id=p_compid  and t.is_delete=0;
               v_cust_id:=null;

               if v_count > 0 then
                     select t.id into  v_cust_id from Busi_Investor_Credit  t ,busi_credit_company  cc,busi_product info where
                                   cc.credit_id=t.id and cc.company_id=info.cp_id and  t.credit_no =v_zjhm and t.credit_type=v_zjlb and
                                   cc.company_id=p_compid and info.id=v_product_id and t.is_delete=0;

                     delete from  busi_sheet t where t.credit_id= v_cust_id  and t.business_type='024' and  to_char(t.sheet_create_time,'yyyyMMdd')=to_char(v_apply_date,'yyyyMMdd') ;

               end if ;
       delete from Busi_Batch_Redeem_Tmp t where t.id=v_id;

   end loop;


  close sh_data_cur;

   update t_fund_job_status t set t.job_status = 0 where t.job_en_name = v_job_name;


  flag:='000';
   msg  := '删除客户导入赎回数据导成功';
  insert into t_fund_job_running_log(job_name,job_running_log) values(v_job_name,msg||'  ,' || todaydate);
  --产品id不为空
  else
   open sh_data_cur for v_sql;
   loop
      fetch sh_data_cur into v_id,v_zjhm, v_zjlb,v_product_id,v_apply_date ;
          if sh_data_cur%notfound then
               exit;
           end if;
             --开户数据根据导入的客户证件和证件类型（机构、产品信息和申请日期）删除
              select count(t.id) into  v_count from Busi_Investor_Credit  t ,busi_credit_company  cc  where cc.credit_id=t.id and  t.credit_no =v_zjhm and t.credit_type=v_zjlb and
               cc.company_id=p_compid  and t.is_delete=0;
               v_cust_id:=null;

               if v_count > 0 then
                     select t.id into  v_cust_id from Busi_Investor_Credit  t ,busi_credit_company  cc,busi_product info where
                                   cc.credit_id=t.id and cc.company_id=info.cp_id and  t.credit_no =v_zjhm and t.credit_type=v_zjlb and
                                   cc.company_id=p_compid and info.id=p_fundid and t.is_delete=0;

                     delete from  busi_sheet t where t.credit_id= v_cust_id and t.pt_id=p_fundid and t.business_type='024' and to_char(t.sheet_create_time,'yyyyMMdd')=to_char(v_apply_date,'yyyyMMdd') ;

               end if ;
     delete from Busi_Batch_Redeem_Tmp t where t.id=v_id;

   end loop;


  close sh_data_cur;

   update t_fund_job_status t set t.job_status = 0 where t.job_en_name = v_job_name;


  flag:='000';
   msg  := '删除客户导入赎回数据导成功';
  insert into t_fund_job_running_log(job_name,job_running_log) values(v_job_name,msg||'  ,' || p_fundid || '  ,' || todaydate);
end if;

 commit;


EXCEPTION
    WHEN ve_exception then
        rollback;

          if sh_data_cur%isopen   then
           close sh_data_cur;
         end if;

          flag:=v_flag;
           msg  := '删除客户导入赎回数据导失败：'||todaydate ||'   ' ||sqlerrm;
          insert into t_fund_job_running_log(job_name,job_running_log) values(v_job_name,msg|| '  ,' || todaydate);
           commit;
        RETURN;
    WHEN OTHERS THEN
        rollback;
          if sh_data_cur%isopen   then
           close sh_data_cur;
         end if;

          flag:='1000';
           msg  := '删除客户导入赎回数据导失败：' || v_msg || '   '   || sqlerrm;
         insert into t_fund_job_running_log(job_name,job_running_log) values(v_job_name,msg || '  ,' || todaydate);
          commit;
        return;

end tgyw_products_del_Redeem_data;
/


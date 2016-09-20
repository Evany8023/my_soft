CREATE OR REPLACE PROCEDURE SMZJ.tgyw_delete_rgsg_data_simple (
                                                          p_batch_number_id in varchar2,
                                                          p_fundid in  varchar2, 
                                                          p_compid in varchar2, 
                                                          todaydate in varchar2,
                                                          p_is_mgr in varchar2,
                                                          p_mgr_id in varchar2,
                                                          flag out varchar2,
                                                          msg out varchar2 ) is
---- *************************************************************************
-- SUBSYS:     托管服务
-- PROGRAM:      tgyw_delete_rgsg_data_new
-- RELATED TAB:
-- AUTHOR:       guxu
-- DESCRIPTION:
--    delete all data   , p_fundid   , p_compid , todaydate
-- CREATE DATE:  2016-04-11
-- VERSION:
-- EDIT HISTORY:
-- *************************************************************************

  v_job_name varchar2(100) :='tgyw_delete_rgsg_data_simple';
  v_ch_job_name varchar2(100) :='批量删除简易认申购数据';
  v_msg varchar2(4000);--返回信息
  v_flag integer :=0;--标志本地证件号码对应的名称与TA的名称是否一致
  ve_Exception   EXCEPTION;
  v_zjlb varchar2(50);--证件类别
  v_zjhm varchar2(50);--证件代码
  v_credit_id varchar2(32 char );
  v_fundid varchar2(50);--产品id

  v_count integer :=0;
  v_jy_count integer :=0;
  v_count_one_fund integer :=0;
  v_kh_count integer;
  v_kh_count2        pls_integer :=0;
  v_count1          integer :=0;
  v_yestoday date;
  v_count_jy integer :=0;

  v_sale_data   varchar2(2014);
  type myrefcur is ref cursor;
  sale_data_cur myrefcur;
  v_apply_date varchar2(50);--申请日期
  

begin

  if trim(p_batch_number_id) is null  or  trim(p_compid) is null or trim(todaydate) is null then
            v_flag := '9999';
            v_msg  := '批次号、基金公司和日期必填';
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
  select to_date(to_char(sysdate-1,'yyyymmdd')||' 235959','yyyymmdd HH24:mi:ss')into v_yestoday  from dual;

  if p_is_mgr is not null and p_is_mgr='0' then
     v_sale_data:='select t.credit_no,t.credit_type_code,t.product_id,to_char(t.apply_date,'||'''yyyy-MM-dd'''||') from  busi_sale_data t join busi_product p on t.product_id=p.id join busi_product_authorization pa on p.id = pa.product_id where t.company_id=''' ||p_compid || ''' and pa.mgr_id = ''' || p_mgr_id ||''' and  to_char(t.create_date,'||'''yyyy-MM-dd'''||')=''' ||todaydate || ''' and t.status=1 and t.batch_number_id=''' ||p_batch_number_id || '''';
  else
     v_sale_data:='select t.credit_no,t.credit_type_code,t.product_id,to_char(t.apply_date,'||'''yyyy-MM-dd'''||') from  busi_sale_data t where t.company_id=''' ||p_compid || ''' and to_char(t.create_date,'||'''yyyy-MM-dd'''||')=''' ||todaydate || ''' and t.status=1 and t.batch_number_id=''' ||p_batch_number_id || '''';
  end if;
  
  if p_fundid is not null and p_fundid!='-1' then
      v_sale_data:=v_sale_data|| ' and  t.product_id=''' ||p_fundid || '''';
  end if;


  open sale_data_cur for v_sale_data;
   loop
      fetch sale_data_cur into v_zjhm ,v_zjlb,v_fundid,v_apply_date;
       if sale_data_cur%notfound then
               exit;
        end if;
         --开户数据根据导入的客户证件和证件类型（机构、产品信息和申请日期）删除

             select count(t.id) into  v_count from Busi_Investor_Credit  t ,busi_credit_company  cc,busi_product info where
               cc.credit_id=t.id and cc.company_id=info.cp_id and  t.credit_no =v_zjhm and t.credit_type=v_zjlb and
               cc.company_id=p_compid and info.id=v_fundid and t.is_delete=0;
            v_credit_id:=null;
          if v_count >0 then

                select t.id into  v_credit_id  from Busi_Investor_Credit  t ,busi_credit_company  cc,busi_product info where
                                                   cc.credit_id=t.id and cc.company_id=info.cp_id and  t.credit_no =v_zjhm and t.credit_type=v_zjlb and
                                                   cc.company_id=p_compid and info.id=v_fundid and t.is_delete=0;

          v_kh_count:=0;
          v_count1:=0;
          v_jy_count:=0;
          v_count_jy:=0;

          -- 当天开户
          select count(1) into v_kh_count from  Busi_Investor_Credit f  where f.id=v_credit_id  and f.create_date >v_yestoday;
          --只在一个公司开户
          select count(*) into v_count1 from Busi_Credit_Company cc     where cc.credit_id=v_credit_id and cc.company_id <> p_compid;
          -- 买个一次产品
          select count(*)  into v_count_one_fund from ( select count(1) from  Busi_Sheet t where t.credit_id=v_credit_id  and   t.business_type in('020','022') and t.is_delete='0'   group by  id  );
          --删除和公司关联关系，本公司只有一个本产品关联，可以删除

          --仅仅买了一个产品，且产品是本产品
          if v_kh_count =1 and v_count1  =0   and  v_count_one_fund< 2 then
               delete  from Busi_Investor_Credit f where f.id=v_credit_id and   to_char(f.create_date,'yyyy-mm-dd')=todaydate;
          end if ;

        select count(1) into  v_jy_count from  Busi_Credit_Company cc     where cc.credit_id=v_credit_id and cc.company_id=p_compid;
        select count(*)  into v_count_jy from ( select count(1) from  Busi_Sheet t where t.credit_id=v_credit_id and t.company_id=p_compid   and   t.business_type in('020','022')  and t.is_delete='0'   group by  id  );
        if v_jy_count= 1   and v_count_jy=1 then
             delete from Busi_Credit_Company t where t.credit_id=v_credit_id and t.company_id=p_compid and t.sqrq> v_yestoday;
        end if;

        --删除 开户祥情的 带上sheet_no 确认是本订单创建的才可以删除
         select count(*)  into v_count_jy from ( select count(1) from  Busi_Sheet t where t.credit_id=v_credit_id and t.company_id= p_compid  and   t.business_type in('020','022') and t.is_delete='0'   group by  id  );
         select count(*)  into v_kh_count2 from ( select count(1) from  Busi_Investor_Detail t where  t.company_id=p_compid and t.credit_id=v_credit_id and  t.is_delete='0' and  t.create_date >v_yestoday  );
        if  v_count_jy <2 and v_kh_count2 <2 then
            delete  from  Busi_Investor_Detail t  where t.company_id=p_compid and t.credit_id=v_credit_id and  t.is_delete='0' and   to_char(t.create_date,'yyyy-mm-dd')=v_apply_date ;
        end if;

        delete  from  busi_sheet t where t.credit_id=v_credit_id and t.pt_id=v_fundid and t.company_id=p_compid  and   t.business_type in('020','022')  and to_char(t.sheet_create_time,'yyyy-mm-dd')=v_apply_date ;

    end if ;
   end loop;

  close sale_data_cur;

  if p_fundid is not null and p_fundid!='-1' then
      -- 删除导入数据
    delete busi_sale_data t where t.company_id=p_compid and t.product_id= p_fundid and  to_char(t.create_date,'yyyy-mm-dd')=todaydate and t.status=1 and t.batch_number_id=p_batch_number_id;
  else
    -- 删除导入数据
      delete busi_sale_data t where t.company_id=p_compid and to_char(t.create_date,'yyyy-mm-dd')=todaydate and t.status=1 and t.batch_number_id=p_batch_number_id;
  end if;


   update t_fund_job_status t set t.job_status = 0 where t.job_en_name = v_job_name;

  commit;
  flag:='000';
  msg  := '删除客户导入申购认购数据导成功'  ;
  insert into t_fund_job_running_log(job_name,job_running_log) values(v_job_name,msg||'  ,' || p_batch_number_id || '  ,' || todaydate);
 commit;


EXCEPTION
    WHEN ve_exception then
        rollback;
         if sale_data_cur%isopen   then
           close sale_data_cur;
         end if;

          flag:=v_flag;
           msg  := '删除客户导入申购认购数据导失败：'||todaydate ||'   ' ||sqlerrm;
          insert into t_fund_job_running_log(job_name,job_running_log) values(v_job_name,msg||'  ,' || p_batch_number_id || '  ,' || todaydate);
           commit;
        RETURN;
    WHEN OTHERS THEN
        rollback;

         if sale_data_cur%isopen   then
           close sale_data_cur;
         end if;


          flag:='1000';
          msg  := '删除客户导入申购认购数据导失败：' || v_msg || '   '   || sqlerrm;
          insert into t_fund_job_running_log(job_name,job_running_log) values(v_job_name,msg||'  ,' || p_batch_number_id || '  ,' || todaydate);
           commit;
        return;

end tgyw_delete_rgsg_data_simple;
/


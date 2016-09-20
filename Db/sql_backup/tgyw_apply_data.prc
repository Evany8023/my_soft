create or replace procedure smzj.tgyw_apply_data(apply_date in varchar2, c_result out sys_refcursor) is

---- *************************************************************************
-- SUBSYS:     托管服务
-- PROGRAM:      tgyw_apply_data
-- RELATED TAB:
-- SUBPROG:
-- REFERENCE:
-- AUTHOR:       liujian
-- DESCRIPTION:  运营外包后台管理中“申请数据管理”菜单下新增一列“汇总信息表”
 --- 列表内容包括：申请日期，机构代码，机构名称，产品代码，产品名称，认购总金额，申购总金额，赎回总份额，TA、平台参数状态核对，TA确认日。  -
  --- 对于直销压单的产品，T日申请的数据不显示在当日申请日期的菜单下，显示在T+1申请日期的汇总信息表中。
  
-- CREATE DATE:  2015-10-23
-- VERSION:
-- EDIT HISTORY: 
-- *************************************************************************

v_count integer;

v_msg   varchar2(4000);
v_job_name varchar2(100) :='tgyw_apply_data' ;
v_job_log_name varchar2(100) :='tgyw_apply_data :' || '申请数据' ;
v_fund_id  varchar2(32);
v_fund_com_id  varchar2(32);
v_fund_com_code    busi_company.insti_code%type;
v_fund_com_name   busi_company.cp_name%type;

v_fund_code varchar2(16);
v_fund_compare_result varchar2(16);
v_currenr_date  varchar2(8);
v_fund_clr  busi_product.publish_date%type;
v_fund_sgje busi_apply_data.pt_sgje%type;
v_fund_rgje busi_apply_data.pt_rgje%type;
v_fund_shfe busi_apply_data.pt_shfe%type;

v_fund_total_sgje busi_apply_data.pt_sgje%type :=0;
v_fund_total_rgje busi_apply_data.pt_rgje%type :=0;
v_fund_total_shfe busi_apply_data.pt_shfe%type :=0;

v_fund_name busi_product.name%type;
v_fundstatus      varchar2(50); --基金状态
v_fundstatuscode  varchar2(50); --基金状态代码
v_fund_pt_status      varchar2(50); --基金状态
v_fund_pt_statuscode  varchar2(50); --基金状态代码
v_ya_day varchar2(32);
v_year_day  varchar2(32);  -- 直销压单的状态
v_id varchar2(32);

   
  
cursor fundinfo_cur is select pt.id,pt.publish_date, pt.product_no, pt.publish_status,pt.name ,pt.cp_id  from busi_product pt  where   
exists(select sh.pt_id from busi_sheet sh where to_char(sh.SHEET_CREATE_TIME,'yyyy-MM-dd') = apply_date and  pt.id = sh.pt_id and sh.is_delete='0' );
  
begin
 select count(*) into v_count from t_fund_job_status t where t.job_en_name = v_job_name and t.job_status = 1;
 
   if v_count > 0  then
    v_msg :='任务执行中，不允许重复执行，返回！';
    insert into t_fund_job_running_log(job_name,job_running_log) values(v_job_log_name,v_msg);
     open c_result for select 'faile' as res, v_msg as msg from dual;
    return;
  end if;
  
  --锁定
   select count(*) into v_count from t_fund_job_status t where t.job_en_name = v_job_name;
   if v_count > 0 then
      update t_fund_job_status t set t.job_status = 1 where t.job_en_name = v_job_name;
    else
      insert into t_fund_job_status(JOB_EN_NAME,JOB_CN_NAME,JOB_STATUS) values('tgyw_apply_data', '重新生成申请数据','1');
    end if;
   
    commit;
    v_currenr_date := replace(apply_date, '-', '');
   delete from busi_apply_data ad where to_char(ad.apply_date,'yyyyMMdd')=v_currenr_date;
  open fundinfo_cur;
  loop
    fetch fundinfo_cur into v_fund_id,v_fund_clr, v_fund_code, v_fund_pt_statuscode ,v_fund_name,v_fund_com_id;
    if fundinfo_cur%notfound then
      exit;
    end if;
 
    
    
     --取压单
     v_ya_day:='未设置';
     select count(*) into v_count from zsta.fundextrainfo@ta_dblink t where  t.FUNDCODE=v_fund_code;
    if v_count >0 then
        select  decode(t.APPLYTYPE,'0','T+1','N', 'T+' || to_char(DELAYCFMDAYS) , '2' , '直销压单'  , t.APPLYTYPE), t.APPLYTYPE into v_ya_day,v_year_day from zsta.fundextrainfo@ta_dblink t where  t.FUNDCODE=v_fund_code; 
        if v_year_day ='2' then  --直销压单,对于直销压单的 平台的状态要取13日的状态 TA取14号的状态,
                       select getpreworkday(v_currenr_date)      into v_currenr_date from dual;
                 select count(1) into v_count from  t_rlb_jjzt t where t.rq = v_currenr_date and t.jjdm = v_fund_code;
                 if v_count > 0 then
                    select t.jjzt into v_fund_pt_statuscode from  t_rlb_jjzt t where t.rq = v_currenr_date and t.jjdm = v_fund_code;
                 end if;
          end if ; 
     end if;
     
    select d.label into v_fund_pt_status from sys_dict d where d.type = 'product_status' and d.value=v_fund_pt_statuscode;
    

    
    select nvl(sum(to_number(replace(t.APPLY_SHARE,',',''),'9999999999990.0000')),'') into v_fund_shfe from  busi_sheet t inner join BUSI_INVESTOR_CREDIT c on c.id=t.credit_id where to_char(t.SHEET_CREATE_TIME,'yyyy-MM-dd') = apply_date and t.is_delete =0 and t.BUSINESS_TYPE='024' and  t.pt_id=v_fund_id;
    select nvl(sum(to_number(replace(t.APPLY_AMOUNT,',',''),'9999999999990.0000')),'') into v_fund_rgje from  busi_sheet t inner join BUSI_INVESTOR_CREDIT c on c.id=t.credit_id where to_char(t.SHEET_CREATE_TIME,'yyyy-MM-dd') = apply_date and t.is_delete =0 and t.BUSINESS_TYPE='020' and t.pt_id=v_fund_id;
    select nvl(sum(to_number(replace(t.APPLY_AMOUNT,',',''),'9999999999990.0000')),'') into v_fund_sgje from  busi_sheet t inner join BUSI_INVESTOR_CREDIT c on c.id=t.credit_id where to_char(t.SHEET_CREATE_TIME,'yyyy-MM-dd') = apply_date and t.is_delete =0 and t.BUSINESS_TYPE='022' and  t.pt_id=v_fund_id;
    select t.insti_code,t.cp_name into v_fund_com_code ,v_fund_com_name from busi_company t where t.id= v_fund_com_id;
    if trim (v_fund_shfe ) is not  null or  trim (v_fund_rgje ) is not null  or  trim (v_fund_sgje ) is not null  then 
      
          select count(*) into v_count  from zsta.uv_xx_parm@ta_dblink t,zsta.uv_xx_fundstatus@ta_dblink a where t.pmky = 'FUNDSTATUS' and t.pmco = a.jjzt and a.rq=v_currenr_date and  a.jjdm = v_fund_code ;
           v_fundstatuscode:='-1';
           v_fundstatus:='未设置';
           if v_count>0 then 
                   select nvl(t.pmco,''), nvl(t.pmnm,'') into v_fundstatuscode, v_fundstatus from zsta.uv_xx_parm@ta_dblink t,zsta.uv_xx_fundstatus@ta_dblink a where t.pmky = 'FUNDSTATUS'
           and t.pmco = a.jjzt and a.rq=v_currenr_date and  a.jjdm = v_fund_code ;
          end if;

           v_fund_compare_result:='一致';
           if v_fundstatuscode!=v_fund_pt_statuscode then
                v_fund_compare_result:='不一致';
            end if;
          select sys_guid() into v_id from dual;
          insert into busi_apply_data(id,cp_no,cp_name,pt_no,pt_name,pt_rgje,pt_sgje,pt_shfe,ta_pt_compare,ta_status,pt_status,ta_confirm_status,born_date,CREATE_DATE,apply_date) 
          values(v_id,v_fund_com_code,v_fund_com_name,v_fund_code,v_fund_name,v_fund_rgje,v_fund_sgje,v_fund_shfe,v_fund_compare_result,v_fundstatus,v_fund_pt_status,v_ya_day,v_currenr_date,sysdate,to_date(apply_date,'yyyy-MM-dd'));
         if trim (v_fund_sgje ) is not  null then
            v_fund_total_sgje:=v_fund_total_sgje+v_fund_sgje;
         end if ;
         
          if trim (v_fund_rgje ) is not  null  then
            v_fund_total_rgje:=v_fund_total_rgje+v_fund_rgje;
         end if ;
         
          if trim (v_fund_shfe ) is not  null then
              v_fund_total_shfe:=v_fund_total_shfe+v_fund_shfe;
         end if ;
       
          
          
    end if ;
    
  
  end loop;
  close fundinfo_cur;
  commit;


     insert into busi_apply_data(id,cp_no,cp_name,pt_no,pt_name,pt_rgje,pt_sgje,pt_shfe,ta_pt_compare,ta_status,pt_status,ta_confirm_status,born_date,CREATE_DATE,apply_date) 
          values(sys_guid(),'HZ','统计汇总',null,'统计汇总',v_fund_total_rgje,v_fund_total_sgje,v_fund_total_shfe,null,null,null,null,to_char(sysdate ,'yyyyMMdd'),sysdate,to_date(apply_date,'yyyy-MM-dd'));


 
    --释放
  update t_fund_job_status t set t.job_status = 0 where t.job_en_name = v_job_name;
    v_msg :='同步成功！   ' || replace(apply_date, '-', '');
     open c_result for select 'success' as res, v_msg as msg from dual;
   insert into t_fund_job_running_log(job_name,job_running_log) values(v_job_log_name,v_msg);
  commit;


exception
    when others then
      rollback;
      v_msg :='同步失败，原因：' || replace(apply_date, '-', '') || '     '  || sqlcode || ':' || sqlerrm || '  ' ||v_fund_code || ' ' ||v_fund_name  || dbms_utility.format_error_backtrace();
      update t_fund_job_status t set t.job_status = 0 where t.job_en_name = v_job_name;
     insert into t_fund_job_running_log(job_name,job_running_log) values(v_job_log_name,v_msg);
     open c_result for select 'faile' as res, v_msg as msg from dual; 
  
end tgyw_apply_data;
/


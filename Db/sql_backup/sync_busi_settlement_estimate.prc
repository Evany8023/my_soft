create or replace procedure smzj.sync_busi_settlement_estimate is
  -- *************************************************************************
-- SYSTEM:      托管服务平台
-- SUBSYS:       私募之家
-- PROGRAM:      sync_busi_settlement_estimate
-- RELATED TAB:
-- SUBPROG:
-- REFERENCE:
-- DESCRIPTION:  交收预估数据,每天凌晨4点同步
-- INPUT:
-- OUTPUT:
-- RETURN:       0    正常返回
--               -1   数据库错误
-- AUTHOR:       卢雅琴
-- CREATE DATE:  2016-04-05
-- VERSION:
-- EDIT HISTORY:
-- *************************************************************************
  v_msg   varchar2(4000);
  v_max_pre_day varchar2(200);             --最大日期（字符型）

begin
  execute immediate 'truncate table BUSI_SETTLEMENT_ESTIMATE';
  select getPreWorkDayByAdvance(to_char(sysdate,'yyyymmdd') ,'15') into v_max_pre_day from dual;
  --插入直销数据（根据产品代码，业务类型，和申请日期分组）
  insert into BUSI_SETTLEMENT_ESTIMATE(id,pt_no,business_type,apply_date,apply_all_amount,apply_all_share)
           select sys_guid(),t.pt_no,t.business_type,to_char(t.sheet_create_time,'yyyymmdd'),
           sum(case t.business_type when '020' then replace(t.apply_amount,',','') when '022' then replace(t.apply_amount,',','') else '' end) as apply_all_amount,
           sum(case t.business_type when '024' then replace(t.apply_share,',','')  else '' end) as apply_all_share
           from busi_sheet t
           where t.is_delete='0'
           and t.business_type in ('020','022','024')
           and to_char(sheet_create_time,'yyyymmdd') > v_max_pre_day
           --申请日期大于T-N日。表示还未确认的申请
           and to_char(t.sheet_create_time,'yyyymmdd')>= (select getPreWorkDayByAdvance(to_char(sysdate,'yyyymmdd'),decode(c.APPLYTYPE,'0','1','N',to_char(DELAYCFMDAYS),'2', '2')) from zsta.fundextrainfo@ta_dblink c where c.fundcode=t.pt_no)
           group by t.pt_no,to_char(t.sheet_create_time,'yyyymmdd'),t.business_type;


  --更新直销数据的产品名，公司id，产品id
  update BUSI_SETTLEMENT_ESTIMATE s set (s.pt_name,s.cp_id,s.pt_id )=
  (select p.name,p.cp_id,p.id from Busi_Product p where p.product_no=s.pt_no)
  where exists( select p.id from Busi_Product p where p.product_no=s.pt_no);

  --更新直销机构编码，机构名称
  update BUSI_SETTLEMENT_ESTIMATE s set (s.insti_code,s.insti_name)=
  (select cp.insti_code,'直销' from busi_company cp where cp.id=s.cp_id)
  where exists( select cp.id from busi_company cp where cp.id=s.cp_id);

  --插入代销数据
  insert into BUSI_SETTLEMENT_ESTIMATE(id,pt_no,business_type,apply_date,insti_code,apply_all_amount,apply_all_share)
           select sys_guid(), ut.FUNDCODE,ut.BUSINESSCODE,ut.transactiondate,ut.oorgno,
           sum(case ut.BUSINESSCODE when '020' then ut.APPLICATIONAMOUNT when '022' then ut.APPLICATIONAMOUNT else null end) as apply_all_amount,
           sum(case ut.BUSINESSCODE when '024' then ut.APPLICATIONVOL  else null end) as apply_all_share
           from ut_t_typt_03_his ut
           where ut.transactiondate > v_max_pre_day 
           and ut.BUSINESSCODE in ('020','022','024')
           and ut.transactiondate>= (select getPreWorkDayByAdvance(to_char(sysdate,'yyyymmdd'),decode(c.APPLYTYPE,'0','1','N',to_char(DELAYCFMDAYS),'2', '2')) from zsta.fundextrainfo@ta_dblink c where c.fundcode=ut.FUNDCODE)
           group by ut.FUNDCODE,ut.BUSINESSCODE,ut.transactiondate,ut.oorgno;


  --更新代销数据的产品名，公司id，产品id
  update BUSI_SETTLEMENT_ESTIMATE s set (s.pt_name,s.cp_id,s.pt_id )=
  (select p.name,p.cp_id,p.id from Busi_Product p where p.product_no=s.pt_no)
  where
  exists( select * from BUSI_SETTLEMENT_ESTIMATE s where s.pt_name is null)
  and exists( select p.id from Busi_Product p where p.product_no=s.pt_no);


  --更新代销数据的机构名称
  update BUSI_SETTLEMENT_ESTIMATE s set s.insti_name=
  (select ta_com.name from TA_ALL_COMPANY ta_com where ta_com.code=s.insti_code)
  where
  s.insti_name is null
  and exists( select ta_com.name from TA_ALL_COMPANY ta_com where ta_com.code=s.insti_code);


  --更新预估交收日期(预估交收日期可以理解为确认日期)
  update BUSI_SETTLEMENT_ESTIMATE s set (s.estimate_settlement_date) =(
   select
   case s.business_type
      when '020' then
      getnextworkday(s.apply_date,'1')
      when '022' then
      getnextworkday(s.apply_date,ta.sgjsts)
      when '024' then
      getnextworkday(s.apply_date,ta.shjsts)
   end
  from  zsta.jscsb@ta_dblink ta where ta.fundcode=s.pt_no and ta.distributedcode=s.insti_code
  )
  where exists(
  select ta.fundcode from  zsta.jscsb@ta_dblink ta where ta.fundcode=s.pt_no and ta.distributedcode=s.insti_code
  );


  --更新净值日净值
  update busi_settlement_estimate s set (s.latest_net_val,s.latest_net_val_date)=(
   select v.NAV,v.TRADEDAY from V_BUSI_FUND_VALUES_ORDER v where  v.fundcode=s.pt_no and  v.tradeday <= s.apply_date and rownum=1 
  )where s.business_type in('024','022')
  and exists ( select v.fundcode from V_BUSI_FUND_VALUES_ORDER v where  v.fundcode=s.pt_no and  v.tradeday <= s.apply_date and rownum=1 );


  --更新预估赎回金额
  update busi_settlement_estimate s set s.estimate_sh_share=s.apply_all_share*s.latest_net_val where s.business_type='024';



  v_msg :='同步成功！';
  insert into t_fund_job_running_log(job_name,job_running_log) values('交收预估数据',v_msg);
         commit;
  exception
    when others then
      v_msg :='同步失败，原因：'|| sqlcode || ':' || sqlerrm ||dbms_utility.format_error_stack;
      rollback;
      insert into t_fund_job_running_log(job_name,job_running_log) values('交收预估数据',v_msg);
      commit;

end sync_busi_settlement_estimate;
/


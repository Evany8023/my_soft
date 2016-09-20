CREATE OR REPLACE PROCEDURE SMZJ.SYNC_FUND_ESTIMATE_HIS
-- *************************************************************************
-- SYSTEM:       中登系统
-- SUBSYS:       TA子系统
-- PROGRAM:      SYNC_FUND_ESTIMATE_HIS
-- RELATED TAB:
-- SUBPROG:
-- REFERENCE:
-- DESCRIPTION: 同步交收预估历史数据信息，每天凌晨3点同步
-- INPUT:
-- OUTPUT:
-- RETURN:       0    正常返回
--               -1   数据库错误
-- AUTHOR:       徐鹏飞
-- CREATE DATE:  2016-04-06
-- VERSION:
-- EDIT HISTORY:
-- *************************************************************************
IS
    v_msg                        varchar2(1000);
    v_current_date               varchar2(8 char);           --今天日期,字符串形式
    v_estimate_count             integer;                    --交收预估中数据条数

    v_pt_id                      busi_settlement_estimate.pt_id%type;
    v_pt_no                      busi_settlement_estimate.pt_no%type;
    v_pt_name                    busi_settlement_estimate.pt_name%type;
    v_business_type              busi_settlement_estimate.business_type%type;
    v_apply_date                 busi_settlement_estimate.apply_date%type;
    v_insti_code                 busi_settlement_estimate.insti_code%type;
    v_ta_business_type           varchar2(20 char);           --TA业务类型
    v_count                      integer;
    v_confirm_date               varchar2(8 char);     --确认日期
    v_net_val                    number;               --最大净值

    cursor m_estimate_cur is select m.pt_id,m.pt_no,m.pt_name,
                                    case m.business_type  when '020' then '130' when '022' then '122' when '024' then '124' end ta_business_type,
                                    m.business_type, m.apply_date,m.insti_code
                             from busi_settlement_estimate m
                             where (select getnextworkday(m.apply_date,decode(c.applytype,'0','1','N',to_char(c.delaycfmdays)))
                                    from zsta.fundextrainfo@ta_dblink c where c.fundcode=m.pt_no)< (select to_char(sysdate,'yyyyMMdd') from dual);

begin
    select to_char(sysdate,'yyyyMMdd') into v_current_date from dual;
        open m_estimate_cur;
        loop
        fetch m_estimate_cur into v_pt_id, v_pt_no,v_pt_name,v_ta_business_type,v_business_type,v_apply_date ,v_insti_code;
          if m_estimate_cur%notfound then
            exit;
          end if;

          --查看交易确认中同一产品，同一申请日期，同一销售机构，同一业务类型，在交易确认表中有几条数据
          select count(1) into v_count from  busi_trading_confirm c where c.apply_date=v_apply_date and c.pt_no=v_pt_no and c.business_type=v_ta_business_type and c.insti_code=v_insti_code;
          --查看同一产品，同一申请日期，同一销售机构，同一业务类型，在交收预估历史表中有几条数据
          select count(1) into v_estimate_count  from busi_fund_estimate_his eh
              where eh.apply_date=v_apply_date and eh.pt_no=v_pt_no and eh.business_type=v_business_type and  eh.insti_code=v_insti_code;

          --历史表不存在该记录做插入操作
          if v_count>0 and v_estimate_count=0 then
            insert into busi_fund_estimate_his (id,pt_no,pt_name,business_type,apply_date,hope_trade_date,insti_code,insti_name,cp_id)
               select sys_guid(),b.pt_no,b.pt_name,
                       b.business_type,
                       b.apply_date,b.estimate_settlement_date, b.insti_code,b.insti_name,b.cp_id
              from busi_settlement_estimate b
              where b.apply_date=v_apply_date and b.pt_no=v_pt_no and b.business_type=v_business_type and  b.insti_code=v_insti_code
                    and (select getnextworkday(b.apply_date,decode(c.applytype,'0','2','N',to_char(delaycfmdays+1)))
                          from zsta.fundextrainfo@ta_dblink c where c.fundcode=b.pt_no)>= v_current_date;
          end if;
          --对历史表做更新操作
          v_confirm_date:=null;v_net_val:=null;
          --获取确认日期
          select max(to_char(c.confirm_date,'yyyyMMdd')) into v_confirm_date
            from busi_trading_confirm c
          where c.apply_date=v_apply_date and c.pt_no=v_pt_no and c.insti_code=v_insti_code and c.business_type=v_ta_business_type;
          --获取最大净值
          select max(c.unit_net_val) into v_net_val
            from busi_trading_confirm c
          where c.apply_date=v_apply_date and c.pt_no=v_pt_no and c.insti_code=v_insti_code and c.business_type = v_ta_business_type;

        --更新确认份额，确认金额，确认日期，开放日净值
        update busi_fund_estimate_his h set (h.confirm_share,h.confirm_amount,h.UNIT_NET_VAL,h.confirm_date) =(
                    select sum(c.confirm_share) sharesum,sum(c.confirm_amount) amountsum,v_net_val,v_confirm_date
                    from busi_trading_confirm c
                    where c.apply_date=v_apply_date and c.pt_no=v_pt_no and c.business_type=v_ta_business_type and c.insti_code=v_insti_code
                    group by c.apply_date,c.pt_no,c.business_type,c.insti_code
                )
                where exists (select 1 from busi_fund_estimate_his eh where eh.apply_date=v_apply_date and eh.pt_no=v_pt_no
                              and eh.business_type=v_business_type and eh.insti_code=v_insti_code)
               and h.apply_date=v_apply_date and h.pt_no=v_pt_no and h.business_type=v_business_type and  h.insti_code=v_insti_code;
                                  
                              
                              
        --更新赎回的赎回金额
        update busi_fund_estimate_his eh set eh.hope_ransom=eh.confirm_share*eh.unit_net_val where eh.business_type='024';

   end loop;
   close m_estimate_cur;

  v_msg :='同步成功！';
  insert into t_fund_job_running_log(job_name,job_running_log) values('交收预估历史数据同步',v_msg);
  commit;
  exception
    when others then
      v_msg :='同步失败，原因：'|| sqlcode || ':' || sqlerrm ||dbms_utility.format_error_stack;
      rollback;
      insert into t_fund_job_running_log(job_name,job_running_log) values('交收预估历史数据同步',v_msg);
      commit;
END SYNC_FUND_ESTIMATE_HIS;
/


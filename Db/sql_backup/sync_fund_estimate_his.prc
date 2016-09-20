CREATE OR REPLACE PROCEDURE SMZJ.SYNC_FUND_ESTIMATE_HIS
-- *************************************************************************
-- SYSTEM:       �е�ϵͳ
-- SUBSYS:       TA��ϵͳ
-- PROGRAM:      SYNC_FUND_ESTIMATE_HIS
-- RELATED TAB:
-- SUBPROG:
-- REFERENCE:
-- DESCRIPTION: ͬ������Ԥ����ʷ������Ϣ��ÿ���賿3��ͬ��
-- INPUT:
-- OUTPUT:
-- RETURN:       0    ��������
--               -1   ���ݿ����
-- AUTHOR:       ������
-- CREATE DATE:  2016-04-06
-- VERSION:
-- EDIT HISTORY:
-- *************************************************************************
IS
    v_msg                        varchar2(1000);
    v_current_date               varchar2(8 char);           --��������,�ַ�����ʽ
    v_estimate_count             integer;                    --����Ԥ������������

    v_pt_id                      busi_settlement_estimate.pt_id%type;
    v_pt_no                      busi_settlement_estimate.pt_no%type;
    v_pt_name                    busi_settlement_estimate.pt_name%type;
    v_business_type              busi_settlement_estimate.business_type%type;
    v_apply_date                 busi_settlement_estimate.apply_date%type;
    v_insti_code                 busi_settlement_estimate.insti_code%type;
    v_ta_business_type           varchar2(20 char);           --TAҵ������
    v_count                      integer;
    v_confirm_date               varchar2(8 char);     --ȷ������
    v_net_val                    number;               --���ֵ

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

          --�鿴����ȷ����ͬһ��Ʒ��ͬһ�������ڣ�ͬһ���ۻ�����ͬһҵ�����ͣ��ڽ���ȷ�ϱ����м�������
          select count(1) into v_count from  busi_trading_confirm c where c.apply_date=v_apply_date and c.pt_no=v_pt_no and c.business_type=v_ta_business_type and c.insti_code=v_insti_code;
          --�鿴ͬһ��Ʒ��ͬһ�������ڣ�ͬһ���ۻ�����ͬһҵ�����ͣ��ڽ���Ԥ����ʷ�����м�������
          select count(1) into v_estimate_count  from busi_fund_estimate_his eh
              where eh.apply_date=v_apply_date and eh.pt_no=v_pt_no and eh.business_type=v_business_type and  eh.insti_code=v_insti_code;

          --��ʷ�����ڸü�¼���������
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
          --����ʷ�������²���
          v_confirm_date:=null;v_net_val:=null;
          --��ȡȷ������
          select max(to_char(c.confirm_date,'yyyyMMdd')) into v_confirm_date
            from busi_trading_confirm c
          where c.apply_date=v_apply_date and c.pt_no=v_pt_no and c.insti_code=v_insti_code and c.business_type=v_ta_business_type;
          --��ȡ���ֵ
          select max(c.unit_net_val) into v_net_val
            from busi_trading_confirm c
          where c.apply_date=v_apply_date and c.pt_no=v_pt_no and c.insti_code=v_insti_code and c.business_type = v_ta_business_type;

        --����ȷ�Ϸݶȷ�Ͻ�ȷ�����ڣ������վ�ֵ
        update busi_fund_estimate_his h set (h.confirm_share,h.confirm_amount,h.UNIT_NET_VAL,h.confirm_date) =(
                    select sum(c.confirm_share) sharesum,sum(c.confirm_amount) amountsum,v_net_val,v_confirm_date
                    from busi_trading_confirm c
                    where c.apply_date=v_apply_date and c.pt_no=v_pt_no and c.business_type=v_ta_business_type and c.insti_code=v_insti_code
                    group by c.apply_date,c.pt_no,c.business_type,c.insti_code
                )
                where exists (select 1 from busi_fund_estimate_his eh where eh.apply_date=v_apply_date and eh.pt_no=v_pt_no
                              and eh.business_type=v_business_type and eh.insti_code=v_insti_code)
               and h.apply_date=v_apply_date and h.pt_no=v_pt_no and h.business_type=v_business_type and  h.insti_code=v_insti_code;
                                  
                              
                              
        --������ص���ؽ��
        update busi_fund_estimate_his eh set eh.hope_ransom=eh.confirm_share*eh.unit_net_val where eh.business_type='024';

   end loop;
   close m_estimate_cur;

  v_msg :='ͬ���ɹ���';
  insert into t_fund_job_running_log(job_name,job_running_log) values('����Ԥ����ʷ����ͬ��',v_msg);
  commit;
  exception
    when others then
      v_msg :='ͬ��ʧ�ܣ�ԭ��'|| sqlcode || ':' || sqlerrm ||dbms_utility.format_error_stack;
      rollback;
      insert into t_fund_job_running_log(job_name,job_running_log) values('����Ԥ����ʷ����ͬ��',v_msg);
      commit;
END SYNC_FUND_ESTIMATE_HIS;
/


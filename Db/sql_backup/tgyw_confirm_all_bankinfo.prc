create or replace procedure smzj."TGYW_CONFIRM_ALL_BANKINFO"  (p_compid in varchar2,flag out varchar2,msg out varchar2 ) is

---- *************************************************************************
-- SUBSYS:       �йܷ���
-- PROGRAM:      TGYW_CONFIRM_ALL_BANKINFO
-- RELATED TAB:
-- SUBPROG:
-- REFERENCE:
-- AUTHOR:       ����
-- DESCRIPTION:  һ��ȷ�������˺�

-- CREATE DATE:  2016-04-15
-- VERSION:
-- EDIT HISTORY:
-- *************************************************************************

v_job_name                    varchar2(100):= 'һ��ȷ�������˺�';
v_apply_no                    busi_bind_bank_card_match.apply_no %type;--������
v_credit_id                   busi_bind_bank_card_match.credit_id %type;--֤��ID
v_pt_id                       busi_bind_bank_card_match.product_id %type;--��ƷID
v_company_id                  busi_bind_bank_card_match.company_id %type;--��˾ID
v_account_no                  busi_bind_bank_card_match.account_no %type;--���п���
v_match_id                    busi_bind_bank_card_match.id %type;--ƥ���¼ID
v_bank_card_id                busi_bind_bank_card.id %type;--�����п�ID
v_exist_bank_card_id          busi_bind_bank_card.id %type;--�Ѵ��ڵ����п�ID

v_bank_card_count             integer;--�����˻�����
v_back_bank_card_count        integer;--��������˻�����

--һ��ȷ�ϵķ�ΧΪ���ù���������ķ�ȷ�ϵ�Ψһƥ��ļ�¼
cursor bank_cur  is select t.apply_no,t.credit_id,t.product_id,t.company_id,t.account_no,t.id  from busi_bind_bank_card_match t inner join busi_investor_credit c on c.id=t.credit_id where  t.confirm_status='0' and t.match_status='1' and t.company_id=p_compid
and t.bank_no is not null;

begin
    open bank_cur;
      loop
       fetch bank_cur into v_apply_no ,v_credit_id,v_pt_id,v_company_id,v_account_no,v_match_id;
       if bank_cur%notfound then
        exit;
       end if;
       --�����жϸÿͻ��ò�Ʒ�¸������˻��Ƿ��Ѵ���
       v_bank_card_count:=0;
       select count(*) into v_bank_card_count from busi_bind_bank_card t where t.credit_id=v_credit_id and t.product_id=v_pt_id and t.company_id=v_company_id and t.account_no=v_account_no and t.is_delete='0';
       --����������˻�������
       if v_bank_card_count=0 then
           v_back_bank_card_count:=0;
           select count(*) into v_back_bank_card_count from busi_bind_bank_card b where b.credit_id=v_credit_id and b.product_id=v_pt_id and b.company_id=v_company_id and b.is_back_account='1' and b.is_delete='0';
           --�����������طֺ��˻�,����Ϊ�µ�����˻�
           if v_back_bank_card_count=0 then
             select sys_guid() into v_bank_card_id from dual;
             insert into busi_bind_bank_card(id,credit_id,user_name, bank_no, bank_name,open_bank_name, province_id,province_name, city_id, city_name, account_no,product_id, company_id, apply_no, bind_date, create_date,create_by, is_back_account,link_bank_no,remark)
             select v_bank_card_id,m.credit_id,m.user_name,m.bank_no,m.bank_name,m.open_bank_name,m.province_id,m.province_name,m.city_id,m.city_name,m.account_no,m.product_id,
             m.company_id,m.apply_no,sysdate,sysdate,'system','1','',m.remark
             from busi_bind_bank_card_match m where m.id=v_match_id;--����������˻�
             update busi_sheet sh set sh.bank_card_id=v_bank_card_id where sh.sheet_no=trim(v_apply_no);--���¶���bank_card_id
             update busi_bind_bank_card_match bm set bm.confirm_status='1' where bm.id=trim(v_match_id);--����״̬Ϊ��ȷ��
           else
             --����Ѿ�������طֺ��˻�,��ȡ����������˻�
             update busi_bind_bank_card bc set bc.is_back_account='0' where bc.credit_id=v_credit_id and bc.product_id=v_pt_id and bc.company_id=v_company_id and bc.is_back_account='1';
             select sys_guid() into v_bank_card_id from dual;
             insert into busi_bind_bank_card(id,credit_id,user_name, bank_no, bank_name,open_bank_name, province_id,province_name, city_id, city_name, account_no,product_id, company_id, apply_no, bind_date, create_date,create_by, is_back_account,link_bank_no,remark)
             select v_bank_card_id,m.credit_id,m.user_name,m.bank_no,m.bank_name,m.open_bank_name,m.province_id,m.province_name,m.city_id,m.city_name,m.account_no,m.product_id,
             m.company_id,m.apply_no,sysdate,sysdate,'system','1','',m.remark
             from busi_bind_bank_card_match m where m.id=v_match_id; --����������˻�
             update busi_sheet sh set sh.bank_card_id=v_bank_card_id where sh.sheet_no=trim(v_apply_no);--���¶���bank_card_id
             update busi_bind_bank_card_match bm set bm.confirm_status='1' where bm.id=trim(v_match_id);--����״̬Ϊ��ȷ��
           end if;
       --����������˻��Ѿ�����
       else
           select bbc.id into v_exist_bank_card_id from busi_bind_bank_card bbc where bbc.credit_id=v_credit_id and bbc.product_id=v_pt_id and bbc.company_id=v_company_id and bbc.account_no=v_account_no and bbc.is_delete='0' and rownum=1;
            v_back_bank_card_count:=0;
           select count(*) into v_back_bank_card_count from busi_bind_bank_card b where b.credit_id=v_credit_id and b.product_id=v_pt_id and b.company_id=v_company_id and b.is_back_account='1' and b.is_delete='0';
            --�����������طֺ��˻�,���޸�Ϊ�µ�����˻�
           if v_back_bank_card_count=0 then
             update busi_bind_bank_card bc set bc.is_back_account='1' where bc.id=trim(v_exist_bank_card_id);
             update busi_sheet sh set sh.bank_card_id=v_exist_bank_card_id where sh.sheet_no=trim(v_apply_no);--���¶���bank_card_id
             update busi_bind_bank_card_match bm set bm.confirm_status='1' where bm.id=trim(v_match_id);--����״̬Ϊ��ȷ��
           else
            --����Ѿ�������طֺ��˻�,��ȡ����������˻�
             update busi_bind_bank_card bc set bc.is_back_account='0' where bc.credit_id=v_credit_id and bc.product_id=v_pt_id and bc.company_id=v_company_id and bc.is_back_account='1';
             update busi_bind_bank_card b set b.is_back_account='1' where b.id=trim(v_exist_bank_card_id);
             update busi_sheet sh set sh.bank_card_id=v_exist_bank_card_id where sh.sheet_no=trim(v_apply_no);--���¶���bank_card_id
             update busi_bind_bank_card_match bm set bm.confirm_status='1' where bm.id=trim(v_match_id);--����״̬Ϊ��ȷ��
            end if;
       end if;
      end loop;
     close bank_cur;
     flag:='000';
     msg  := 'һ��ȷ�������˻��ɹ�'  ;
     insert into t_fund_job_running_log(job_name,job_running_log) values(v_job_name,msg||'  ,' || p_compid || sysdate);
     commit;

    EXCEPTION
    when others then
        if bank_cur%isopen then
            close bank_cur;
        end if;
        rollback;
        flag:='1000';
        msg :='һ��ȷ�������˻�ʧ�ܣ�ԭ��' || sqlcode || ':' || sqlerrm || SUBSTR(DBMS_UTILITY.FORMAT_ERROR_BACKTRACE,1,500);
        insert into t_fund_job_running_log(job_name,job_running_log) values(v_job_name,msg||'  ,' || p_compid || sysdate);
        commit;

end TGYW_CONFIRM_ALL_BANKINFO;
/


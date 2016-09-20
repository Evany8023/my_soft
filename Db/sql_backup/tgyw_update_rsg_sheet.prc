create or replace procedure smzj.tgyw_update_rsg_sheet(p_sheet_id in varchar2, --�������
                                            p_apply_date in varchar2, --��������
                                            p_cp_id  in varchar2, -- ��˾ID
                                            p_pt_id in varchar2, --��ƷID
                                            p_credit_id in varchar2,--֤��id
                                            p_detail_id in varchar2,--������id
                                            p_bank_card_id in varchar2, -- ���п�ID
                                            p_sheet_busi_type in varchar2, -- ����ҵ������
                                            p_amount in varchar2, --�������
                                            p_sheet_remark in varchar2, -- ������ע

                                            c_result out sys_refcursor) is
---- *************************************************************************
-- SUBSYS:     �йܷ���
-- PROGRAM:      tgyw_update_rsg_sheet
-- RELATED TAB:
-- SUBPROG:
-- REFERENCE:
-- INPUT:
-- OUTPUT:
-- RETURN:       0    ��������
--               -1   ���ݿ����
-- AUTHOR:       ¬����
-- DESCRIPTION:  �޸���/�깺������������
-- CREATE DATE:  2016-01-13
-- VERSION:
-- EDIT HISTORY:
-- *************************************************************************
 v_job_name varchar2(100) :='tgyw_update_rsg_sheet';
 v_msg varchar2(1000); --������Ϣ

 v_credit_id varchar2(32); --֤��ID
 v_start_price busi_product.start_price%type; --���깺���
 v_plus_start_price busi_product.plus_start_price%type;  --׷���깺���
 v_is_limit_buy busi_product.is_limit_buy%type; --���깺�Ƿ�������
 v_buy_count number; --�������
 v_buy_amount number; --����������
 v_limit_amount number; --���ƽ��
 v_pt_no  varchar2(16); -- ��Ʒ���
 v_flag integer :=0;--ҵ�����������Ϊ1���ع�����
 v_current_date date; --��ǰʱ��
 v_son_buy_monther varchar2(50 char); --����ĸ����ֵ

begin

    select to_date(p_apply_date||to_char(sysdate,'HH24:MI:SS'),'yyyy-mm-ddHH24:MI:SS') into v_current_date from dual;

    --��Ͷĸ¼�����жϿ�ʼ
    select child_buy_or_sale_prarent(p_credit_id,p_pt_id,'01',p_sheet_id) into v_son_buy_monther from dual;

    if v_son_buy_monther='true' then
        v_flag := '1';
        v_msg := 'Ͷ�����깺�ӻ��𣬻��Զ������ӻ����깺ĸ���������ظ�¼��';
        open c_result for select 'faile' as res, v_msg as msg  from dual;
        return;
    elsif v_son_buy_monther <> 'true' and  v_son_buy_monther <> 'false' then
        insert into t_fund_job_running_log (JOB_NAME,job_running_log) values ('����ĸ����',v_son_buy_monther || '    '||p_credit_id || '    '|| p_pt_id || '  '||  p_sheet_id   || '    '||  v_current_date );
        commit;
    end  if;

    --��Ͷĸ¼�����жϽ���

    --�����Ƿ����������ʼ
    select count(1) into v_buy_count from busi_sheet t where t.credit_id=p_credit_id and t.pt_id=p_pt_id and t.id <>p_sheet_id  and to_char(t.sheet_create_time,'yyyy-MM-dd') = p_apply_date  and t.is_delete='0';
    if v_buy_count>0 then
        v_flag := '1';
        v_msg := '�Ѿ��Ϲ����깺����ع��˲�Ʒ,�����ٴ�����';
        open c_result for select 'faile' as res, v_msg as msg  from dual;
        return;
    end if;

    --�����Ƿ������������

    select pt.start_price,pt.plus_start_price, pt.is_limit_buy,product_no into v_start_price, v_plus_start_price, v_is_limit_buy,v_pt_no from busi_product pt where pt.id = p_pt_id;
     --���깺��������Ƶ�ʱ��
    if v_is_limit_buy=1 then
       --�Ϲ���ͽ��
       if p_sheet_busi_type='020' then       -- �Ϲ�
            if v_start_price is null  then
               v_start_price:='1000000';
            end if;
           select to_number(p_amount,'9999999999999999.9999') into v_buy_amount from dual;
           select to_number(v_start_price,'9999999999999999.9999') into v_limit_amount from dual;
           if v_buy_amount < v_limit_amount then
               v_flag := 1;
               v_msg := '�Ϲ�����С�ڣ�'|| v_start_price ||'Ԫ';
           end if;
       end if;

      --�깺��ͽ��
      if p_sheet_busi_type ='022' then
         if v_start_price is null  then
               v_start_price:='1000000';
         end if;
         select count(1) into v_buy_count from busi_sheet t where t.credit_id=v_credit_id and t.pt_id=p_pt_id and t.business_type = p_sheet_busi_type  and  t.is_delete='0';
         --�깺���깺��׷���깺���ж�
         if v_buy_count < 1 then
            select to_number(p_amount,'9999999999999999.9999') into v_buy_amount from dual;
            select to_number(v_start_price,'9999999999999999.9999') into v_limit_amount from dual;
            if v_buy_amount < v_limit_amount then
              v_flag := 1;
              v_msg := '�깺����С�ڣ�'|| v_start_price ||'Ԫ';
            end if;
         else
             if v_plus_start_price is not null then
                             select to_number(p_amount,'9999999999999999.9999') into v_buy_amount from dual;
                             select to_number(v_plus_start_price,'9999999999999999.9999') into v_limit_amount from dual;
                             if v_buy_amount < v_limit_amount then
                              v_flag := 1;
                              v_msg := '׷���깺���ܵ���'||v_limit_amount||'Ԫ';
                            end if;

             end if;
         end if;

      end if;
     end if;

     if v_flag <> 1 then
       update busi_sheet set update_date = v_current_date,pt_id=p_pt_id,pt_no=v_pt_no,apply_amount=p_amount,credit_id=p_credit_id,BANK_CARD_ID=p_bank_card_id,DT_ID=p_detail_id,REMARK=p_sheet_remark where id = p_sheet_id;

    end if;

    if v_flag = 1 then
        rollback;
        open c_result for select 'faile' as res, v_msg as msg  from dual;
    else
        v_msg := '�޸Ķ����ɹ�';
        open c_result for select 'success' as res, v_msg as msg  from dual;
        commit;
    end if;
    return;

    exception
        when others then
        begin
            rollback;
            DBMS_OUTPUT.put_line('sqlcode : '||sqlcode);
            DBMS_OUTPUT.put_line('sqlerror : '||sqlerrm);
            v_msg:= sqlcode||':'||sqlerrm ||'   '|| dbms_utility.format_error_backtrace() || v_start_price || p_pt_id;
            insert into t_fund_job_running_log (JOB_NAME,job_running_log) values (v_job_name,v_msg);
            open c_result for select v_job_name as flag, 'faile' as res, v_msg as msg from dual;
            commit;
            return;
        end ;
end tgyw_update_rsg_sheet;
/


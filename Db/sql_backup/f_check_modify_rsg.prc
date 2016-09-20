create or replace procedure smzj.f_check_modify_rsg(
                                            p_apply_date in varchar2, --��������
                                            p_pt_id in varchar2, --��ƷID
                                            p_credit_id varchar2, --֤��ID
                                            p_sheet_busi_type in varchar2, -- ����ҵ������
                                            p_amount in varchar2,  --�������
                                            c_result out sys_refcursor
                                            ) is
    ---- *************************************************************************
    -- SUBSYS:     ������ϵͳ
    -- PROGRAM:      f_check_modify_rsg
    -- RELATED TAB:
    -- SUBPROG:  {p_msg=, p_result=fail, p_credit_id=24DBABBB958E4DC2E050FE0AD8FD78BB, p_apply_date=2015-11-20, p_sheet_busi_type=022, p_amount=1000000, p_pt_id=922ca79b728c4ad0859a3bcbad590382}
    -- REFERENCE:
    -- AUTHOR:       Dornan
    -- DESCRIPTION:  �޸Ķ���ʱ���
    -- CREATE DATE:  2015-11-20
    -- VERSION:
    -- EDIT HISTORY:
    -- *************************************************************************
     v_start_price busi_product.start_price%type; --���깺���
     v_plus_start_price busi_product.plus_start_price%type;  --׷���깺���
     v_is_limit_buy busi_product.is_limit_buy%type; --���깺�Ƿ�������
     v_buy_count  number; --�������
     v_buy_amount number; --����������
     v_limit_amount number; --���ƽ��
     v_pt_no  varchar2(16); -- ��Ʒ���
     v_flag integer :=0;--ҵ�����������Ϊ1���ع�����
     p_msg varchar2(200);--������Ϣ


begin

    select pt.start_price,pt.plus_start_price, pt.is_limit_buy,product_no into v_start_price, v_plus_start_price, v_is_limit_buy,v_pt_no from busi_product pt where pt.id = p_pt_id;
    --���깺��������Ƶ�ʱ��
    if v_is_limit_buy<>1 then
        open c_result for select 'success' as flag , p_msg as msg from dual;
        return;
    end if;

    --�Ϲ���ͽ��
    if p_sheet_busi_type='020' then       -- �Ϲ�
         select to_number(p_amount,'9999999999999999.9999') into v_buy_amount from dual;
         select to_number(v_start_price,'9999999999999999.9999') into v_limit_amount from dual;
         if v_buy_amount < v_limit_amount then
             v_flag := 1;
             p_msg := '�Ϲ�����С�ڣ�'|| v_start_price ||'Ԫ';
         end if;
    end if;

    --�깺��ͽ��
    if p_sheet_busi_type ='022' then
        if v_start_price is null  then
             v_start_price:='1000000';
        end if;

        --ͨ���ж��Ƿ������ǰ���깺���ж��Ƿ���׷��
        select count(1) into v_buy_count from busi_sheet t where t.credit_id=p_credit_id and t.pt_id=p_pt_id and t.business_type = p_sheet_busi_type  and  t.sheet_create_time < to_date(p_apply_date,'yyyy-MM-dd') and t.is_delete='0';
        --�깺���깺��׷���깺���ж�
        if v_buy_count < 1 then
            select to_number(p_amount,'9999999999999999.9999') into v_buy_amount from dual;
            select to_number(v_start_price,'9999999999999999.9999') into v_limit_amount from dual;
            if v_buy_amount < v_limit_amount then
              v_flag := 1;
              p_msg := '�깺����С�ڣ�'|| v_start_price ||'Ԫ';
            end if;
        else
            select to_number(p_amount,'9999999999999999.9999') into v_buy_amount from dual;
            select to_number(v_plus_start_price,'9999999999999999.9999') into v_limit_amount from dual;
            if v_buy_amount < v_limit_amount then
              v_flag := 1;
              p_msg := '׷���깺���ܵ���'||v_limit_amount||'Ԫ';
            end if;
        end if;
    end if;


    if v_flag = 1 then
        open c_result for select 'fail' as flag , p_msg as msg from dual;
    else
        open c_result for select 'success' as flag , p_msg as msg from dual;
    end if;
    return;
    exception
        when others then
        begin
            DBMS_OUTPUT.put_line('sqlcode : '||sqlcode);
            DBMS_OUTPUT.put_line('sqlerror : '||sqlerrm);
            p_msg:= sqlcode||':'||sqlerrm ||'   '|| dbms_utility.format_error_backtrace() || v_start_price || p_pt_id;
            open c_result for select 'fail' as flag , p_msg as msg from dual;
            return;
        end ;
end f_check_modify_rsg;
/


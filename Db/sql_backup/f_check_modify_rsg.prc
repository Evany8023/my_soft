create or replace procedure smzj.f_check_modify_rsg(
                                            p_apply_date in varchar2, --申请日期
                                            p_pt_id in varchar2, --产品ID
                                            p_credit_id varchar2, --证件ID
                                            p_sheet_busi_type in varchar2, -- 订单业务类型
                                            p_amount in varchar2,  --订单金额
                                            c_result out sys_refcursor
                                            ) is
    ---- *************************************************************************
    -- SUBSYS:     管理人系统
    -- PROGRAM:      f_check_modify_rsg
    -- RELATED TAB:
    -- SUBPROG:  {p_msg=, p_result=fail, p_credit_id=24DBABBB958E4DC2E050FE0AD8FD78BB, p_apply_date=2015-11-20, p_sheet_busi_type=022, p_amount=1000000, p_pt_id=922ca79b728c4ad0859a3bcbad590382}
    -- REFERENCE:
    -- AUTHOR:       Dornan
    -- DESCRIPTION:  修改订单时检查
    -- CREATE DATE:  2015-11-20
    -- VERSION:
    -- EDIT HISTORY:
    -- *************************************************************************
     v_start_price busi_product.start_price%type; --认申购起点
     v_plus_start_price busi_product.plus_start_price%type;  --追加申购起点
     v_is_limit_buy busi_product.is_limit_buy%type; --认申购是否做限制
     v_buy_count  number; --购买次数
     v_buy_amount number; --订单购买金额
     v_limit_amount number; --限制金额
     v_pt_no  varchar2(16); -- 产品编号
     v_flag integer :=0;--业务处理结果，如果为1，回滚事物
     p_msg varchar2(200);--返回信息


begin

    select pt.start_price,pt.plus_start_price, pt.is_limit_buy,product_no into v_start_price, v_plus_start_price, v_is_limit_buy,v_pt_no from busi_product pt where pt.id = p_pt_id;
    --认申购额度做限制的时候
    if v_is_limit_buy<>1 then
        open c_result for select 'success' as flag , p_msg as msg from dual;
        return;
    end if;

    --认购最低金额
    if p_sheet_busi_type='020' then       -- 认购
         select to_number(p_amount,'9999999999999999.9999') into v_buy_amount from dual;
         select to_number(v_start_price,'9999999999999999.9999') into v_limit_amount from dual;
         if v_buy_amount < v_limit_amount then
             v_flag := 1;
             p_msg := '认购金额不能小于：'|| v_start_price ||'元';
         end if;
    end if;

    --申购最低金额
    if p_sheet_busi_type ='022' then
        if v_start_price is null  then
             v_start_price:='1000000';
        end if;

        --通过判断是否存在以前的申购来判断是否是追加
        select count(1) into v_buy_count from busi_sheet t where t.credit_id=p_credit_id and t.pt_id=p_pt_id and t.business_type = p_sheet_busi_type  and  t.sheet_create_time < to_date(p_apply_date,'yyyy-MM-dd') and t.is_delete='0';
        --申购分申购和追加申购的判断
        if v_buy_count < 1 then
            select to_number(p_amount,'9999999999999999.9999') into v_buy_amount from dual;
            select to_number(v_start_price,'9999999999999999.9999') into v_limit_amount from dual;
            if v_buy_amount < v_limit_amount then
              v_flag := 1;
              p_msg := '申购金额不能小于：'|| v_start_price ||'元';
            end if;
        else
            select to_number(p_amount,'9999999999999999.9999') into v_buy_amount from dual;
            select to_number(v_plus_start_price,'9999999999999999.9999') into v_limit_amount from dual;
            if v_buy_amount < v_limit_amount then
              v_flag := 1;
              p_msg := '追加申购金额不能低于'||v_limit_amount||'元';
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


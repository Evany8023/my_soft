create or replace procedure smzj.tgyw_update_rsg_sheet(p_sheet_id in varchar2, --订单编号
                                            p_apply_date in varchar2, --申请日期
                                            p_cp_id  in varchar2, -- 公司ID
                                            p_pt_id in varchar2, --产品ID
                                            p_credit_id in varchar2,--证件id
                                            p_detail_id in varchar2,--开户表id
                                            p_bank_card_id in varchar2, -- 银行卡ID
                                            p_sheet_busi_type in varchar2, -- 订单业务类型
                                            p_amount in varchar2, --订单金额
                                            p_sheet_remark in varchar2, -- 订单备注

                                            c_result out sys_refcursor) is
---- *************************************************************************
-- SUBSYS:     托管服务
-- PROGRAM:      tgyw_update_rsg_sheet
-- RELATED TAB:
-- SUBPROG:
-- REFERENCE:
-- INPUT:
-- OUTPUT:
-- RETURN:       0    正常返回
--               -1   数据库错误
-- AUTHOR:       卢雅琴
-- DESCRIPTION:  修改认/申购订单【订单表】
-- CREATE DATE:  2016-01-13
-- VERSION:
-- EDIT HISTORY:
-- *************************************************************************
 v_job_name varchar2(100) :='tgyw_update_rsg_sheet';
 v_msg varchar2(1000); --错误信息

 v_credit_id varchar2(32); --证件ID
 v_start_price busi_product.start_price%type; --认申购起点
 v_plus_start_price busi_product.plus_start_price%type;  --追加申购起点
 v_is_limit_buy busi_product.is_limit_buy%type; --认申购是否做限制
 v_buy_count number; --购买次数
 v_buy_amount number; --订单购买金额
 v_limit_amount number; --限制金额
 v_pt_no  varchar2(16); -- 产品编号
 v_flag integer :=0;--业务处理结果，如果为1，回滚事物
 v_current_date date; --当前时间
 v_son_buy_monther varchar2(50 char); --子买母返回值

begin

    select to_date(p_apply_date||to_char(sysdate,'HH24:MI:SS'),'yyyy-mm-ddHH24:MI:SS') into v_current_date from dual;

    --子投母录单做判断开始
    select child_buy_or_sale_prarent(p_credit_id,p_pt_id,'01',p_sheet_id) into v_son_buy_monther from dual;

    if v_son_buy_monther='true' then
        v_flag := '1';
        v_msg := '投资人申购子基金，会自动触发子基金申购母基金，请勿重复录单';
        open c_result for select 'faile' as res, v_msg as msg  from dual;
        return;
    elsif v_son_buy_monther <> 'true' and  v_son_buy_monther <> 'false' then
        insert into t_fund_job_running_log (JOB_NAME,job_running_log) values ('子买母问题',v_son_buy_monther || '    '||p_credit_id || '    '|| p_pt_id || '  '||  p_sheet_id   || '    '||  v_current_date );
        commit;
    end  if;

    --子投母录单做判断结束

    --订单是否已申请过开始
    select count(1) into v_buy_count from busi_sheet t where t.credit_id=p_credit_id and t.pt_id=p_pt_id and t.id <>p_sheet_id  and to_char(t.sheet_create_time,'yyyy-MM-dd') = p_apply_date  and t.is_delete='0';
    if v_buy_count>0 then
        v_flag := '1';
        v_msg := '已经认购、申购、赎回过此产品,不能再次申请';
        open c_result for select 'faile' as res, v_msg as msg  from dual;
        return;
    end if;

    --订单是否已申请过结束

    select pt.start_price,pt.plus_start_price, pt.is_limit_buy,product_no into v_start_price, v_plus_start_price, v_is_limit_buy,v_pt_no from busi_product pt where pt.id = p_pt_id;
     --认申购额度做限制的时候
    if v_is_limit_buy=1 then
       --认购最低金额
       if p_sheet_busi_type='020' then       -- 认购
            if v_start_price is null  then
               v_start_price:='1000000';
            end if;
           select to_number(p_amount,'9999999999999999.9999') into v_buy_amount from dual;
           select to_number(v_start_price,'9999999999999999.9999') into v_limit_amount from dual;
           if v_buy_amount < v_limit_amount then
               v_flag := 1;
               v_msg := '认购金额不能小于：'|| v_start_price ||'元';
           end if;
       end if;

      --申购最低金额
      if p_sheet_busi_type ='022' then
         if v_start_price is null  then
               v_start_price:='1000000';
         end if;
         select count(1) into v_buy_count from busi_sheet t where t.credit_id=v_credit_id and t.pt_id=p_pt_id and t.business_type = p_sheet_busi_type  and  t.is_delete='0';
         --申购分申购和追加申购的判断
         if v_buy_count < 1 then
            select to_number(p_amount,'9999999999999999.9999') into v_buy_amount from dual;
            select to_number(v_start_price,'9999999999999999.9999') into v_limit_amount from dual;
            if v_buy_amount < v_limit_amount then
              v_flag := 1;
              v_msg := '申购金额不能小于：'|| v_start_price ||'元';
            end if;
         else
             if v_plus_start_price is not null then
                             select to_number(p_amount,'9999999999999999.9999') into v_buy_amount from dual;
                             select to_number(v_plus_start_price,'9999999999999999.9999') into v_limit_amount from dual;
                             if v_buy_amount < v_limit_amount then
                              v_flag := 1;
                              v_msg := '追加申购金额不能低于'||v_limit_amount||'元';
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
        v_msg := '修改订单成功';
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


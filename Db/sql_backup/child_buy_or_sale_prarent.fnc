CREATE OR REPLACE FUNCTION SMZJ.child_buy_or_sale_prarent (
     v_p_credit_id IN VARCHAR2, -- 子产品作为投资者的id
     v_p_fund_id IN VARCHAR2, -- 产品代码 S20001等
      v_p_busi_type IN VARCHAR2, --业务类型类型 01 认购申购 ，02 赎回，03 快速赎回
      v_p_sheet_id IN VARCHAR2
 )
 RETURN VARCHAR2

 -- *************************************************************************
-- SYSTEM:       私募之间
-- PROGRAM:      child_Buy_or_sale_prarent
-- DESCRIPTION:
-- RETURN:       true 证明有买卖
--               false   证明没有买卖
--               其他 ，错误信息
-- AUTHOR:       庞作青
-- CREATE DATE:  2015-12-23
-- VERSION:v1.0
-- EDIT HISTORY:
-- *************************************************************************

 IS
  v_count integer;
  v_buy_count integer;
  v_fund_id varchar(32 char);
  v_fund_code varchar(32 char);
  v_trriger_no varchar(32 char);
 v_open_record varchar(32 char);
 BEGIN
   if (trim(v_p_credit_id) is null) or (trim(v_p_fund_id) is null) or (trim(v_p_busi_type) is null) then
     return '输入参数有空值';
   end if;
   select count(1) into v_count from Busi_Investor_Credit c,busi_pt_zm_relation zm where c.id=v_p_credit_id and c.is_delete='0'
    and zm.son_regist_acc=c.regist_account and zm.parent_pt_id= v_p_fund_id and zm.son_regist_acc is not null;
    if v_count < 1 then
      return 'false';
    end if;

    select zm.trigger_no,zm.son_pt_no into v_trriger_no,v_fund_code from Busi_Investor_Credit c,busi_pt_zm_relation zm where c.id=v_p_credit_id and c.is_delete='0'
    and zm.son_regist_acc=c.regist_account and zm.parent_pt_id= v_p_fund_id and zm.son_regist_acc is not null;

    select p.id, CASE a.OPEN_RECORD WHEN '1' THEN '1' ELSE '0' END AS OPEN_RECORD into v_fund_id,v_open_record from busi_product p left join busi_product_add a on p.id=a.product_id where p.product_no=v_fund_code and p.is_delete='0' and rownum =1;
    if v_open_record > '0' then
     return 'false';
    end if;


   -- 认购，申购
    if v_p_busi_type='01' and (v_trriger_no='0' or v_trriger_no='1') then
      if v_p_sheet_id is not null then
         select count(1) into v_buy_count from Busi_Sheet t where t.pt_id=v_p_fund_id and t.credit_id=v_p_credit_id and t.is_delete='0' and t.business_type in ('020','022') and t.id <> v_p_sheet_id;
      else
          select count(1) into v_buy_count from Busi_Sheet t where t.pt_id=v_p_fund_id and t.credit_id=v_p_credit_id and t.is_delete='0' and t.business_type in ('020','022');
      end if;


     if v_buy_count > 0 then
        return 'true';
      else
        return 'false';
      end if;


    end if;
    --赎回
   v_buy_count:=0;
   if v_p_busi_type='02' and (v_trriger_no='0' or v_trriger_no='2')  then
      if v_p_sheet_id is not null then
         select count(1) into v_buy_count from Busi_Sheet t where t.pt_id=v_p_fund_id and t.credit_id=v_p_credit_id and t.is_delete='0' and t.business_type ='024' and t.id <> v_p_sheet_id;
      else
          select count(1) into v_buy_count from Busi_Sheet t where t.pt_id=v_p_fund_id and t.credit_id=v_p_credit_id and t.is_delete='0' and t.business_type ='024';
      end if;

     if v_buy_count > 0 then
        return 'true';
      else
        return 'false';
      end if;


   end if;
   --快速赎回
   v_buy_count:=0;
   if v_p_busi_type='03' and (v_trriger_no='0' or v_trriger_no='2' ) then

     if v_p_sheet_id is not null then
         select count(1) into v_buy_count from busi_quick_sheet t where t.pt_id=v_p_fund_id and t.credit_id=v_p_credit_id and t.is_delete='0' and t.business_type='024' and t.id <> v_p_sheet_id;
      else
          select count(1) into v_buy_count from busi_quick_sheet t where t.pt_id=v_p_fund_id and t.credit_id=v_p_credit_id and t.is_delete='0' and t.business_type='024' ;
      end if;

     if v_buy_count > 0 then
        return 'true';
      else
        return 'false';
      end if;

   end if;

   return '';

exception
     when others then
     return sqlcode||':'||sqlerrm ||'   '|| dbms_utility.format_error_backtrace() || v_p_credit_id || v_p_fund_id;
END;
/


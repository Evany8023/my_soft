CREATE OR REPLACE PROCEDURE SMZJ."F_DELETE_RSG_NEW" (
                                          p_sheet_id  in varchar2, --证件ID
                                          p_cp_id     in varchar2, --公司ID
                                          p_today     in varchar2, -- 今天
                                          c_result out sys_refcursor
                                         ) is
    ---- *************************************************************************
    -- SUBSYS:     管理人系统
    -- PROGRAM:      f_delete_rsg_new
    -- RELATED TAB:
    -- SUBPROG:   {p_cp_id=2056928fd9e0cdfee0500000000056da, p_today=2015-12-11, p_sheet_id=2699630F4A67C383E050FE0AD8FD3458}
    -- REFERENCE:
    -- AUTHOR:       卢雅琴
    -- DESCRIPTION:  删除订单（简易版录的单，去掉银行账号相关逻辑）
    -- CREATE DATE:  2016-04-12
    -- VERSION:
    -- EDIT HISTORY:
    -- *************************************************************************

     v_flag pls_integer :=0;     --业务处理结果，如果为1，回滚事物
     v_msg varchar2(200);        --返回信息
     v_sheet_no    varchar(32);  -- 订单编号
     ve_exception   EXCEPTION;
     dt_begintime     date:=sysdate;        --删除操作开始执行时间
     v_overDateFlag   char(1);             -- 是当天的可以删除标志
     v_dt_id          varchar(32);       -- 开户祥情ID
     v_pt_id          varchar2(32);      --产品ID
     v_bank_card_id   varchar(32);         -- 银行卡ID
     v_credit_id       varchar(32);      -- 证件ID
     v_kh_count        pls_integer :=0;
     v_count1          pls_integer :=0;
     v_kh_count2        pls_integer :=0;
     v_jy_count        pls_integer :=0;
     v_count_one_fund  pls_integer :=0;
     v_count_jy varchar(32);
     v_yestoday date;

begin
     v_flag:=0;
    if trim(p_sheet_id) is null  or  trim(p_cp_id) is null or trim(p_today) is null then
        v_flag := 1;
        v_msg  := '订单ID,公司ID和当天日期必填';
        raise ve_exception;
    end if;
       select to_date(to_char(sysdate-1,'yyyymmdd')||' 235959','yyyymmdd HH24:mi:ss')into v_yestoday  from dual;
    begin
          select decode(sign(trunc(SHEET_CREATE_TIME)-trunc(dt_begintime)),-1,'1','0'),dt_id,bank_card_id,credit_id, pt_id, sheet_no into v_overDateFlag,v_dt_id,v_bank_card_id,v_credit_id,v_pt_id,v_sheet_no  from busi_sheet   where
          id = p_sheet_id and  COMPANY_ID=p_cp_id and SHEET_CREATE_TIME > v_yestoday;
    exception  when no_data_found then
        v_flag := 1;
        v_msg:= '删除失败，原因是订单记录不存在!';
        raise ve_exception;
    end;

    if  v_flag<>1 then

        v_kh_count:=0;
        v_count1:=0;
        v_jy_count:=0;


         --删除临时表sql
        delete from busi_sale_data d  where exists (select 1 from busi_sheet s inner join busi_investor_credit c on s.credit_id = c.id  where s.id = p_sheet_id  and s.company_id = p_cp_id and s.pt_id = d.product_id  and c.credit_type = d.credit_type_code  and c.credit_no = d.credit_no and to_char(s.SHEET_CREATE_TIME, 'yyyyMMdd') =  to_char(d.apply_date, 'yyyyMMdd') and d.status = 1);

        -- 当天开户
        select count(1) into v_kh_count from  Busi_Investor_Credit f  where f.id=v_credit_id  and f.create_date >v_yestoday;
        --只在一个公司开户
        select count(*) into v_count1 from Busi_Credit_Company cc     where cc.credit_id=v_credit_id and cc.company_id <> p_cp_id;
        -- 买个一次产品
        select count(*)  into v_count_one_fund from ( select count(1) from  Busi_Sheet t where t.credit_id=v_credit_id and   t.business_type in('020','022') and t.is_delete='0'   group by  id  );
        --删除和公司关联关系，本公司只有一个本产品关联，可以删除

        --仅仅买了一个产品，且产品是本产品
        if v_kh_count =1 and v_count1  =0   and  v_count_one_fund< 2 then
             delete  from Busi_Investor_Credit f where f.id=v_credit_id and  f.create_date >v_yestoday;
        end if ;


        select count(1) into  v_jy_count from  Busi_Credit_Company cc     where cc.credit_id=v_credit_id and cc.company_id=p_cp_id;
        select count(*)  into v_count_jy from ( select count(1) from  Busi_Sheet t where t.credit_id=v_credit_id and t.company_id=p_cp_id and t.id<>p_sheet_id  and   t.business_type in('020','022') and t.is_delete='0'   group by  id  );
        if v_jy_count= 1   and v_count_jy=0 then
             delete from Busi_Credit_Company t where t.credit_id=v_credit_id and t.company_id=p_cp_id;
        end if;

        --删除 开户祥情的 带上sheet_no 确认是本订单创建的才可以删除
         select count(*)  into v_count_jy from ( select count(1) from  Busi_Sheet t where t.credit_id=v_credit_id and t.company_id= p_cp_id  and t.is_delete='0'   group by  id  );
         select count(*)  into v_kh_count2 from ( select count(1) from  Busi_Investor_Detail t where  t.company_id=p_cp_id and t.credit_id=v_credit_id and  t.is_delete='0' and  t.create_date >v_yestoday  );
        if  v_count_jy <2 and v_kh_count2 <2 then
            delete  from  Busi_Investor_Detail t  where t.company_id=p_cp_id and t.credit_id=v_credit_id and  t.is_delete='0' and t.create_date >v_yestoday;
        end if;
        
        --删除  交易
          delete  from  busi_sheet t where id=p_sheet_id and t.company_id=p_cp_id  and  to_char(t.sheet_create_time,'yyyy-mm-dd')=p_today ;
    end if;

    if v_flag = 1 then
        open c_result for select 'fail' as flag , v_msg as msg from dual;
        rollback;
    else
        v_msg:= '删除订单成功';
        open c_result for select 'success' as flag , v_msg as msg from dual;
        commit;
    end if;
    return;

exception
    when ve_exception then
    begin
        rollback;
        open c_result for select 'fail' as flag , v_msg as msg from dual;
        return;
    end;
    when others then
    begin
        rollback;
        v_msg:= '删除订单失败';
        open c_result for select 'fail' as flag , v_msg as msg from dual;
        return;
    end ;
end f_delete_rsg_new;
/


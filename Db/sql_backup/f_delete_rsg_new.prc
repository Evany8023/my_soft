CREATE OR REPLACE PROCEDURE SMZJ."F_DELETE_RSG_NEW" (
                                          p_sheet_id  in varchar2, --֤��ID
                                          p_cp_id     in varchar2, --��˾ID
                                          p_today     in varchar2, -- ����
                                          c_result out sys_refcursor
                                         ) is
    ---- *************************************************************************
    -- SUBSYS:     ������ϵͳ
    -- PROGRAM:      f_delete_rsg_new
    -- RELATED TAB:
    -- SUBPROG:   {p_cp_id=2056928fd9e0cdfee0500000000056da, p_today=2015-12-11, p_sheet_id=2699630F4A67C383E050FE0AD8FD3458}
    -- REFERENCE:
    -- AUTHOR:       ¬����
    -- DESCRIPTION:  ɾ�����������װ�¼�ĵ���ȥ�������˺�����߼���
    -- CREATE DATE:  2016-04-12
    -- VERSION:
    -- EDIT HISTORY:
    -- *************************************************************************

     v_flag pls_integer :=0;     --ҵ�����������Ϊ1���ع�����
     v_msg varchar2(200);        --������Ϣ
     v_sheet_no    varchar(32);  -- �������
     ve_exception   EXCEPTION;
     dt_begintime     date:=sysdate;        --ɾ��������ʼִ��ʱ��
     v_overDateFlag   char(1);             -- �ǵ���Ŀ���ɾ����־
     v_dt_id          varchar(32);       -- ��������ID
     v_pt_id          varchar2(32);      --��ƷID
     v_bank_card_id   varchar(32);         -- ���п�ID
     v_credit_id       varchar(32);      -- ֤��ID
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
        v_msg  := '����ID,��˾ID�͵������ڱ���';
        raise ve_exception;
    end if;
       select to_date(to_char(sysdate-1,'yyyymmdd')||' 235959','yyyymmdd HH24:mi:ss')into v_yestoday  from dual;
    begin
          select decode(sign(trunc(SHEET_CREATE_TIME)-trunc(dt_begintime)),-1,'1','0'),dt_id,bank_card_id,credit_id, pt_id, sheet_no into v_overDateFlag,v_dt_id,v_bank_card_id,v_credit_id,v_pt_id,v_sheet_no  from busi_sheet   where
          id = p_sheet_id and  COMPANY_ID=p_cp_id and SHEET_CREATE_TIME > v_yestoday;
    exception  when no_data_found then
        v_flag := 1;
        v_msg:= 'ɾ��ʧ�ܣ�ԭ���Ƕ�����¼������!';
        raise ve_exception;
    end;

    if  v_flag<>1 then

        v_kh_count:=0;
        v_count1:=0;
        v_jy_count:=0;


         --ɾ����ʱ��sql
        delete from busi_sale_data d  where exists (select 1 from busi_sheet s inner join busi_investor_credit c on s.credit_id = c.id  where s.id = p_sheet_id  and s.company_id = p_cp_id and s.pt_id = d.product_id  and c.credit_type = d.credit_type_code  and c.credit_no = d.credit_no and to_char(s.SHEET_CREATE_TIME, 'yyyyMMdd') =  to_char(d.apply_date, 'yyyyMMdd') and d.status = 1);

        -- ���쿪��
        select count(1) into v_kh_count from  Busi_Investor_Credit f  where f.id=v_credit_id  and f.create_date >v_yestoday;
        --ֻ��һ����˾����
        select count(*) into v_count1 from Busi_Credit_Company cc     where cc.credit_id=v_credit_id and cc.company_id <> p_cp_id;
        -- ���һ�β�Ʒ
        select count(*)  into v_count_one_fund from ( select count(1) from  Busi_Sheet t where t.credit_id=v_credit_id and   t.business_type in('020','022') and t.is_delete='0'   group by  id  );
        --ɾ���͹�˾������ϵ������˾ֻ��һ������Ʒ����������ɾ��

        --��������һ����Ʒ���Ҳ�Ʒ�Ǳ���Ʒ
        if v_kh_count =1 and v_count1  =0   and  v_count_one_fund< 2 then
             delete  from Busi_Investor_Credit f where f.id=v_credit_id and  f.create_date >v_yestoday;
        end if ;


        select count(1) into  v_jy_count from  Busi_Credit_Company cc     where cc.credit_id=v_credit_id and cc.company_id=p_cp_id;
        select count(*)  into v_count_jy from ( select count(1) from  Busi_Sheet t where t.credit_id=v_credit_id and t.company_id=p_cp_id and t.id<>p_sheet_id  and   t.business_type in('020','022') and t.is_delete='0'   group by  id  );
        if v_jy_count= 1   and v_count_jy=0 then
             delete from Busi_Credit_Company t where t.credit_id=v_credit_id and t.company_id=p_cp_id;
        end if;

        --ɾ�� ��������� ����sheet_no ȷ���Ǳ����������Ĳſ���ɾ��
         select count(*)  into v_count_jy from ( select count(1) from  Busi_Sheet t where t.credit_id=v_credit_id and t.company_id= p_cp_id  and t.is_delete='0'   group by  id  );
         select count(*)  into v_kh_count2 from ( select count(1) from  Busi_Investor_Detail t where  t.company_id=p_cp_id and t.credit_id=v_credit_id and  t.is_delete='0' and  t.create_date >v_yestoday  );
        if  v_count_jy <2 and v_kh_count2 <2 then
            delete  from  Busi_Investor_Detail t  where t.company_id=p_cp_id and t.credit_id=v_credit_id and  t.is_delete='0' and t.create_date >v_yestoday;
        end if;
        
        --ɾ��  ����
          delete  from  busi_sheet t where id=p_sheet_id and t.company_id=p_cp_id  and  to_char(t.sheet_create_time,'yyyy-mm-dd')=p_today ;
    end if;

    if v_flag = 1 then
        open c_result for select 'fail' as flag , v_msg as msg from dual;
        rollback;
    else
        v_msg:= 'ɾ�������ɹ�';
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
        v_msg:= 'ɾ������ʧ��';
        open c_result for select 'fail' as flag , v_msg as msg from dual;
        return;
    end ;
end f_delete_rsg_new;
/


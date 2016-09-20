create or replace procedure smzj.tgyw_confirm_bank_account(
      p_compid    in  varchar2,   --公司id
      p_batchid   in  varchar2,   --导入excel文件的批次
      p_ptcount   in  varchar2,   --需处理产品个数
      p_mgrname   in  varchar2,   --管理人名
      p_mgrid     in  varchar2,   --管理人id
      p_ismgr     in  varchar2,   --是否一级管理员
      p_ids       in  varchar2,   --BUSI_BANK_DATA_TEMP表中id集合
      c_result out sys_refcursor  --返回的结果集，抛出错误将错误放到游标中
)
-- *************************************************************************
-- SYSTEM:       中登系统
-- SUBSYS:       TA子系统
-- PROGRAM:      tgyw_confirm_bank_account
-- RELATED TAB:
-- SUBPROG:
-- REFERENCE:
-- DESCRIPTION:  银行账号批量编辑，管理人确认银行账号
-- INPUT:
-- OUTPUT:
-- RETURN:       0    正常返回
--               -1   数据库错误
-- AUTHOR:       徐鹏飞
-- CREATE DATE:  2016-05-05
-- VERSION:
-- EDIT HISTORY:
-- *************************************************************************
as
      v_msg                        varchar2(1000);
      v_job_name                   varchar2(100) :='tgyw_confirm_bank_account';
      ve_exception                 exception;
      v_hascount                   integer;                                     --是否存在已确认得数据

      v_temp_id                    varchar(32);                                 --银行账号临时表中id
      v_investor_name              busi_bank_data_temp.investor_name%type;      --投资人姓名
      v_credit_type                busi_bank_data_temp.credit_type_code%type;   --投资人证件类型
      v_credit_no                  busi_bank_data_temp.credit_no%type;          --投资人证件号码
      v_account_no                 busi_bank_data_temp.bank_accunt_no%type;     --投资人银行账号
      v_account_name               busi_bank_data_temp.bank_account_name%type;  --投资人银行户名
      v_open_bank_name             busi_bank_data_temp.open_bank_name%type;     --投资人开户行名
      v_province_name              busi_bank_data_temp.province_name%type;      --省份名
      v_city_name                  busi_bank_data_temp.city_name%type;          --城市名
      v_product_no                 busi_bank_data_temp.product_no%type;         --产品代码
      v_apply_date                 busi_bank_data_temp.apply_date%type;         --申请日期
      v_bank_no                    busi_bank_data_temp.bank_no%type;            --银行编号
      v_bank_name                  busi_bank_data_temp.bank_name%type;          --银行名称
      v_is_back_account            busi_bank_data_temp.is_back_account%type;    --是否赎回分红账号
      v_ptid                       varchar2(32);                                --产品id
      v_credit_id                  varchar2(32);                                --busi_investor_credit表中id
      v_table_id                   varchar2(32);                                --busi_bind_bank_card表中id
      v_city_code                  varchar2(16);                                --城市代码
      v_province_code              varchar2(16);                                --省份代码
      v_apply_no                   varchar2(32);                                 --申请单号
      v_bind_date                  date;                                        --绑卡时间

      v_check_investor_name        busi_bank_data_temp.investor_name%type;      --投资人姓名
      v_check_credit_type          busi_bank_data_temp.credit_type_code%type;   --投资人证件类型
      v_check_credit_no            busi_bank_data_temp.credit_no%type;          --投资人证件号码
      v_check_ptno                 varchar(32);                                 --产品id
      v_investor_name_ta           busi_bank_data_temp.investor_name%type;      --投资人姓名
      v_flag                       integer :=0;                                 --标志本地证件号码对应的名称与TA的名称是否一致
      v_kh_count                   integer;                                     --是否存在客户表busi_investor_credit中
      v_count                      integer;                                     --本系统中某用户是否存在导入的银行账号
      v_count_bak                  integer;                                     --赎回分红账号
      v_product_count              integer;                                     --是否是该管理人管理的产品
      v_row_count                  integer;                                     --产品，人，银行账号，作为一个维度的记录数
      v_sql                        varchar2(2014);                              --记录SQL语句
      v_sql_data                   varchar2(2014);                              --数据集SQL
      v_sql_check                  varchar2(2014);                              --校验SQL
      v_sql_batch_check            varchar2(2014);                              --校验产品是否在该批次下

      type myrefcur  is  ref  cursor;
      data_cur_check myrefcur;
      data_cur myrefcur;
--      cursor data_cur  is select t.id,t.investor_name,t.credit_type_code,t.credit_no,t.bank_accunt_no,t.bank_account_name,t.open_bank_name,t.province_name,
--                                 t.city_name,t.product_no,t.apply_date,t.bank_no,t.bank_name,t.is_back_account,p.id ptId
--                          from busi_bank_data_temp t inner join busi_product p on t.product_no=p.product_no and t.company_id=p.CP_ID
--                          where t.id in (p_ids) and t.company_id=p_compid and t.batch_number_id=p_batchid and t.status=0 and t.is_delete=0 and p.is_delete=0;

--      cursor data_cur_check;
--     cursor data_cur_check  is select t.investor_name,t.credit_type_code,t.credit_no,t.product_no
--                          from busi_bank_data_temp t
--                          where t.id in (p_ids) and t.batch_number_id=p_batchid and t.status=0 and t.is_delete=0;
BEGIN
    -- 参数控制
    if p_compid is null  then
        v_msg  := '需要指定公司id';
        raise ve_exception;
    end if;
    if p_batchid is null  then
        v_msg  := '需要指定批次';
        raise ve_exception;
    end if;
    if p_ids is null  then
        v_msg  := '需要导入数据的临时表中的id';
        raise ve_exception;
    end if;
    if p_mgrname is null or p_mgrid is null or p_ismgr is null then
        v_msg  := '管理员相关信息有误';
        raise ve_exception;
    end if;
    execute immediate 'select count(1) from busi_bank_data_temp t where t.company_id='''||p_compid||''' and t.batch_number_id='''||p_batchid||''' and t.id in ( '||p_ids||') and t.status=1' into v_hascount;
    if v_hascount>0 then
      v_flag :=1;
      v_msg :='存在已确认得数据，请检查后重新确认';
      open c_result for select 'faile' as res, v_msg as msg  from dual;
      return;
    end if;
    --检查产品是否在该批次下
    execute immediate 'select count(1) from busi_bank_data_temp t where t.batch_number_id='''||p_batchid||''' and t.id in ( '||p_ids||') and t.status=0' into v_hascount;
    if p_ptcount>v_hascount then
      v_flag :=1;
      v_msg :='该记录与批次不对应，请检查后再确认';
      open c_result for select 'faile' as res, v_msg as msg  from dual;
      return;
    end if;
    --标志本地证件号码对应的名称与TA的名称是否一致,及该产品是否属于该管理人所管理的产品
    v_sql_check:='select t.investor_name,t.credit_type_code,t.credit_no,t.product_no
                          from busi_bank_data_temp t
                          where t.batch_number_id='''||p_batchid||''' and t.id in ( '||p_ids||') and t.status=0 and t.is_delete=0';
    open data_cur_check for v_sql_check;
    loop
        fetch data_cur_check into v_check_investor_name ,v_check_credit_type,v_check_credit_no,v_check_ptno;
        if data_cur_check%notfound then
            exit;
        end if;
--        dbms_output.put_line('ids记录数 : '||v_check_credit_no);
        begin
             select t.name into v_investor_name_ta  from busi_investor_credit t where  t.credit_type= v_check_credit_type and t.credit_no = v_check_credit_no and t.is_delete='0';
        exception
            when others then
            v_investor_name_ta :='';
        end;

        if v_investor_name_ta is not null and v_investor_name_ta <> v_check_investor_name then
             v_flag :=1;
             v_msg := v_msg||'证件号码('|| v_check_credit_no||')对应的投资人姓名('|| v_check_investor_name ||')与平台('||v_investor_name_ta||')不匹配,请确认客户姓名和证件号码;<br>';
        end if ;

        --检查该产品是否是该管理人所管理的产品
        if p_ismgr=0 then
          select count(1) into v_product_count from busi_product s inner join busi_product_authorization pa on s.id = pa.product_id
          where pa.mgr_id=p_mgrid and s.product_no=v_check_ptno and s.CP_ID=p_compid and s.is_delete='0';
          if v_product_count=0 then
             v_flag :=1;
             v_msg := v_msg||'投资人('|| v_check_investor_name ||')与产品代码('|| v_check_ptno||')不匹配,请确认产品代码;<br>';
          end if;
        else
          select count(1) into v_product_count from busi_product s where s.product_no=v_check_ptno and s.CP_ID=p_compid and s.is_delete='0';
          if v_product_count=0 then
             v_flag :=1;
             v_msg := v_msg||'投资人('|| v_check_investor_name ||')与产品代码('|| v_check_ptno||')不匹配,请确认产品代码;<br>';
          end if;
        end if;
    end loop;
    close data_cur_check;
    if v_flag = 1 then
        open c_result for select v_job_name as flag,'faile' as res, v_msg as msg  from dual;
        return ;
    end if ;
    --测试ids代码开始--------------------------------------------------------------------
--    select count(1) into v_count from busi_bank_data_temp t where t.id in (p_ids);
--    EXECUTE IMMEDIATE 'select count(1) from busi_bank_data_temp t where t.id  in ( '||p_ids||')' INTO v_count;
--    dbms_output.put_line('ids记录数 : '||v_count);
    --测试ids代码结束--------------------------------------------------------------------
    --1.获取需要确认的数据
    v_sql_data:='select t.id,t.investor_name,t.credit_type_code,t.credit_no,t.bank_accunt_no,t.bank_account_name,t.open_bank_name,t.province_name,
               t.city_name,t.product_no,t.apply_date,t.bank_no,t.bank_name,t.is_back_account,p.id ptId
        from busi_bank_data_temp t inner join busi_product p on t.product_no=p.product_no and t.company_id=p.CP_ID
        where t.id in ( '||p_ids||') and t.company_id='''||p_compid||''' and t.batch_number_id='''||p_batchid||''' and t.status=0 and t.is_delete=0 and p.is_delete=0';
    open data_cur  for v_sql_data;
    loop
        fetch data_cur into v_temp_id,v_investor_name,v_credit_type,v_credit_no,v_account_no,v_account_name,v_open_bank_name,v_province_name,v_city_name,v_product_no,
                            v_apply_date,v_bank_no,v_bank_name,v_is_back_account,v_ptid;
        if data_cur%notfound then
          exit;
        end if;
        --判断该客户是否开过户
        select count(1) into v_kh_count from busi_investor_credit t where t.credit_type = v_credit_type and t.credit_no = v_credit_no and t.is_delete='0';
        --如果不存在客户，
        if v_kh_count=0 then
           v_flag :=1;
           v_msg := v_msg||'客户('||v_investor_name||')证件号码('|| v_credit_no||')没有开过户，请确认;<br>';
        --存在客户
        else
       --获取投资人busi_investor_credit表中id
           select t.id into v_credit_id from busi_investor_credit t
                where t.is_delete = '0' and t.credit_type = v_credit_type and t.credit_no = v_credit_no;
           select count(1) into v_count from busi_credit_company c where  c.company_id = p_compid and c.credit_id=v_CREDIT_ID;
           if v_count=0 then
                v_flag:='1';
                v_msg := v_msg||'客户('||v_INVESTOR_NAME||')不属于该管理人;<br>';
           end if;
           --校验导入的银行账号是否与本系统中已经存在的银行账号重复
--           select count(1) into v_count from busi_bind_bank_card t inner join busi_investor_credit c on t.credit_id=c.id
--           inner join busi_product p on t.product_id=p.id AND p.product_no=v_product_no
--                where t.bank_no=v_bank_no and t.account_no=v_account_no and c.credit_no=v_credit_no and c.credit_type=v_credit_type and t.is_delete='0' and c.is_delete='0';
           --产品，人，银行账号，做为一个维度
           select count(1) into v_row_count from busi_bind_bank_card t inner join busi_investor_credit c on t.credit_id=c.id inner join busi_product p on t.product_id=p.id
                where t.bank_no=v_bank_no and t.account_no=v_account_no and c.credit_no=v_credit_no and c.credit_type=v_credit_type and p.product_no=v_product_no
                and t.is_delete='0' and c.is_delete='0' and p.is_delete='0';

           if v_row_count>0 then
              --赎回分红账号可以从0变成1，不能从1变成0
              select count(1) into v_count_bak from busi_bind_bank_card t inner join busi_investor_credit c on t.credit_id=c.id
                    where t.bank_no=v_bank_no and t.account_no=v_account_no and c.credit_no=v_credit_no and c.credit_type=v_credit_type and t.is_back_account=v_is_back_account
                    and t.is_delete='0' and c.is_delete='0' and t.product_id=v_ptid;
              if v_count_bak>0 then
--                v_flag :=1;
--                v_msg := v_msg||'客户('||v_investor_name||')，已经开过此银行账号，不需要再次导入确认;<br>';
                  --修改20160516，直接确认不提示客户，可与最下面的else和在一起
                  update busi_bank_data_temp t set t.status='1' where t.id=v_temp_id;
              --同一个银行账号，同一个产品，同一个人，原来是非赎回分红账号，导入的文件后是赎回分红账号，更新用户的赎回的赎回分红账户
              elsif v_count_bak=0 and v_is_back_account=1 then
                 --先更新原来的赎回分红账号为非赎回分红账户
                  update busi_bind_bank_card b set b.is_delete='1' where b.is_back_account='1' and b.is_delete='0' and b.product_id=v_ptid and exists(
                      select  1 from busi_investor_credit c where c.credit_no=v_credit_no and c.credit_type=v_credit_type and c.is_delete = '0');
                 --更新现在的账户为赎回分红账户
                 update busi_bind_bank_card t set t.is_back_account=1,t.investor_identify_flag='1' where t.bank_no=v_bank_no and t.is_delete='0' and t.account_no=v_account_no and exists(
                 select 1 from busi_investor_credit c where c.credit_no=v_credit_no and c.credit_type=v_credit_type);
                 update busi_bank_data_temp t set t.status='1' where t.id=v_temp_id;
              else
                 update busi_bank_data_temp t set t.status='1' where t.id=v_temp_id;
              end if;
           else


             --如果是赎回分红账号,将之前该产品的赎回分红账号设置成非赎回分红账号
             if v_is_back_account=1 then
                update busi_bind_bank_card b set b.is_delete='1' where b.is_back_account='1' and b.product_id=v_ptid and b.credit_id=v_credit_id and b.is_delete='0';
             end if;

             if (v_province_name is not null) then
                  select id,name into v_province_code,v_province_name from busi_region where name = v_province_name and parent_id is null and rownum=1; --获取省份ID
             end if;
             if (v_city_name is not null) then
                  select id,name into v_city_code,v_city_name from busi_region where NAME = v_city_name and parent_id is not null and rownum=1;     --获取城市id
             end if;
             --生成申请单号和表id，绑卡日期
             select (substr(to_char(sysdate,'yyyyMMddhh24mmss'),0,14) || cast(dbms_random.value(10000000,99999999) as int)),sys_guid(),
                  to_date(v_apply_date ||to_char(sysdate,'HH24:MI:SS' ),'yyyy-MM-ddHH24:MI:SS') into v_apply_no,v_table_id,v_bind_date from dual;
             --将银行账号插入到busi_bind_bank_card表中
             insert into busi_bind_bank_card(id,credit_id,user_name,bank_no,bank_name,open_bank_name,province_id,province_name,city_id,city_name,
                                   account_no,product_id,company_id,apply_no,bind_date,create_date, create_by,is_back_account,Investor_Identify_Flag)
                            values (v_table_id,v_credit_id,v_investor_name,v_bank_no,v_bank_name,v_open_bank_name,v_province_code,v_province_name,v_city_code,v_city_name,
                            v_account_no,v_ptid,p_compid,v_apply_no,v_bind_date,sysdate,p_mgrname,v_is_back_account,'1');
             --更新状态为已确认
             update busi_bank_data_temp t set t.status='1' where t.id=v_temp_id;
           end if;

        end if;
    end loop;
    close data_cur;

    if v_flag = 1 then
      rollback;
      open c_result for select 'faile' as res, v_msg as msg  from dual;
      return ;
    end if ;

    v_msg :='确认银行账号成功';
    open c_result for select 'success' as res, v_msg as msg from dual;
    commit;

    EXCEPTION
    WHEN ve_exception then
        rollback;
        DBMS_OUTPUT.put_line('sqlcode : '||sqlcode);
        DBMS_OUTPUT.put_line('sqlerror : '||sqlerrm);
        v_msg:=sqlcode||':'||sqlerrm;
        insert into t_fund_job_running_log(job_name,job_running_log) values(v_job_name,v_msg||dbms_utility.format_error_backtrace());
        commit;
        open c_result for select 'faile' as res, v_msg as msg from dual;
        return;
    WHEN OTHERS THEN
        rollback;
        DBMS_OUTPUT.put_line('sqlcode : '||sqlcode);
        DBMS_OUTPUT.put_line('sqlerror : '||sqlerrm);
        v_msg:=sqlcode||':'||sqlerrm;
        insert into t_fund_job_running_log(job_name,job_running_log) values(v_job_name,v_msg||dbms_utility.format_error_backtrace());
        commit;
        open c_result for select 'faile' as res, v_msg as msg from dual;
        return;

END TGYW_CONFIRM_BANK_ACCOUNT;
/


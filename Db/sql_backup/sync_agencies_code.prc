CREATE OR REPLACE PROCEDURE SMZJ.SYNC_AGENCIES_CODE
-- *************************************************************************
-- SYSTEM:       中登系统
-- SUBSYS:       TA子系统
-- PROGRAM:      SYNC_ACCT_ALL_INFO
-- RELATED TAB:
-- SUBPROG:
-- REFERENCE:
-- DESCRIPTION:  同步TA中所有代销私募产品的代销机构信息
-- INPUT:
-- OUTPUT:
-- RETURN:       0    正常返回
--               -1   数据库错误
-- AUTHOR:       xiaxn
-- CREATE DATE:  2016-03-18
-- VERSION:
-- EDIT HISTORY:
-- *************************************************************************
is
    code                         varchar2(20);        --代销机构代码
    v_count                      number;                --判断私募之家中是否已存在该销售机构
    v_count1                     number;   
    v_recvdirectory              varchar2(100);         --接收目录
    v_name                       varchar2(100);         --销售机构名字
    v_kzm                       varchar2(20);          --文件扩展名
    v_msg                        varchar2(1000);         
    v_job_name                   varchar2(100):= '同步TA中所有代销私募产品的代销机构信息';

cursor agencies_code is 
select distinct(distributor) from zsta.ut_产品_销售商表@ta_dblink ut where exists (
select fundcode from zsta.fundinfo@ta_dblink  f where nvl(managercode,'88') <> '88' and f.fundcode = ut.fundcode) 
and distributor  in( 
select distributorcode from zsta.distributor@ta_dblink where sywj_kzm <> '.xls' or sywj_kzm is null );



begin        --同步客户信息开始
   open  agencies_code;
   loop
         fetch agencies_code into code;
         if agencies_code%notfound then
            exit;
         end if;
         
         select count(*) into v_count from distributor where distributorcode = code;
         if v_count=0 then    --说明私募之家中没有该销售机构，则插入
            select substr(recvdirectory,8),SYWJ_KZM,distributorname into v_recvdirectory,v_kzm,v_name from zsta.distributor@ta_dblink 
            where distributorcode = code;
          
            insert into distributor(distributorcode,receivepath,fileextension,distributortype,distributorname) values
            (code,v_recvdirectory,v_kzm,'1',v_name);
            
            --TA中新增销售机构时，ex_seat表会相应变化。也需要同步
            select count(*) into v_count1 from ex_seat where tcode = code;
            if v_count1 = 0 then    --说明ex_seat表中没有该销售机构信息
                insert into ex_seat t 
                select * from zsta.ex_seat@ta_dblink ta where ta.tcode = code;
             
            end if;
            
          end if;
          
    end loop;
          
v_msg :='同步TA中所有代销私募产品的代销机构信息成功';
 insert into t_fund_job_running_log(job_name,job_running_log) values(v_job_name,v_msg);
commit;

EXCEPTION
    when others then
 
        rollback;

        v_msg :='同步失败，原因：' || sqlcode || ':' || sqlerrm || SUBSTR(DBMS_UTILITY.FORMAT_ERROR_BACKTRACE,1,500);
        insert into t_fund_job_running_log(job_name,job_running_log) values(v_job_name,v_msg);
        commit;
end SYNC_AGENCIES_CODE;
/


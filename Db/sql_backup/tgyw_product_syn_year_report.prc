create or replace procedure smzj.TGYW_PRODUCT_SYN_YEAR_REPORT(

      p_compid    in  varchar2,   --公司id

      p_mgrname   in  varchar2,   --管理人名称

      p_mgrid     in  varchar2,   --管理人id

      current_report_date  in  varchar2   --当前年报日期

)

as

---- *************************************************************************

-- SUBSYS:     托管服务

-- PROGRAM:      TGYW_PRODUCT_SYN_YEAR_REPORT

-- RELATED TAB:

-- SUBPROG:

-- REFERENCE:

-- AUTHOR:

-- DESCRIPTION: (年报信息)

-- CREATE DATE:  2016-06-23

-- VERSION:

-- EDIT HISTORY:

-- *************************************************************************

v_today          date;      --当天日期

v_job_name       varchar2(100):='TGYW_PRODUCT_SYN_YEAR_REPORT';

v_msg            varchar2(1000);

type MyRefCurA IS  REF CURSOR RETURN BUSI_PRODUCT%RowType;

vRefCurA  MyRefCurA;

vTempA  vRefCurA%RowType;

begin

  select sysdate into v_today from dual;

  if p_compid <> '0' then

         open vRefCurA for  select p1.*

            from BUSI_PRODUCT p1

            where p1.IS_CURRENT_YEAR_REPORT = '1' and  p1.is_delete = '0' and p1.cp_id =p_compid

            and p1.id not in(select p.id

            from BUSI_PRODUCT p,BUSI_YEAR_REPORT y

            where y.PRODUCT_NO = p.PRODUCT_NO and p.IS_CURRENT_YEAR_REPORT = '1' and y.is_delete = '0' and p.is_delete = '0' and y.report_period =current_report_date and p.cp_id =p_compid);

        loop

          fetch vRefCurA into vTempA;

           if vRefCurA%notfound then

                exit;

            end if;

             insert into BUSI_YEAR_REPORT(id,product_no,product_name,cp_id,mgr_id,report_period,status,is_delete,HISTORY_STATUS,create_by,create_date)

             values(sys_guid(),vTempA.PRODUCT_NO,vTempA.name,vTempA.cp_id,p_mgrid,current_report_date,'0','0','0',p_mgrname,v_today);

      end loop;

      close vRefCurA;

  end if;

  if p_compid = '0' then

         open vRefCurA for  select p1.*

            from BUSI_PRODUCT p1

            where p1.IS_CURRENT_YEAR_REPORT = '1' and  p1.is_delete = '0'

            and p1.id not in(select p.id

            from BUSI_PRODUCT p,BUSI_YEAR_REPORT y

            where y.PRODUCT_NO = p.PRODUCT_NO and p.IS_CURRENT_YEAR_REPORT = '1' and y.is_delete = '0' and p.is_delete = '0' and y.report_period =current_report_date);

        loop

          fetch vRefCurA into vTempA;

           if vRefCurA%notfound then

                exit;

            end if;

             insert into BUSI_YEAR_REPORT(id,product_no,product_name,cp_id,mgr_id,report_period,status,is_delete,HISTORY_STATUS,create_by,create_date)

             values(sys_guid(),vTempA.PRODUCT_NO,vTempA.name,vTempA.cp_id,p_mgrid,current_report_date,'0','0','0',p_mgrname,v_today);

      end loop;

      close vRefCurA;

  end if;

  insert into t_fund_job_running_log(job_name,job_running_log) values(v_job_name,'同步成功');

  commit;



EXCEPTION

    when others then

        if vRefCurA%isopen then

            close vRefCurA;

        end if;

        rollback;

        v_msg:='同步失败，原因：'||':'||sqlcode||':'||sqlerrm ||'   '|| dbms_utility.format_error_backtrace();

        insert into t_fund_job_running_log(job_name,job_running_log) values(v_job_name,v_msg);

        commit;



end TGYW_PRODUCT_SYN_YEAR_REPORT;
/


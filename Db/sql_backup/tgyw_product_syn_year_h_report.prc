create or replace procedure smzj.TGYW_PRODUCT_SYN_YEAR_H_REPORT(

      p_compid    in  varchar2,   --公司id

      p_mgrname   in  varchar2,   --管理人名称

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

-- DESCRIPTION: (处理历史年报信息)

-- CREATE DATE:  2016-06-23

-- VERSION:

-- EDIT HISTORY:

-- *************************************************************************

v_today          date;               --当前日期

v_job_name       varchar2(100):='TGYW_PRODUCT_SYN_YEAR_H_REPORT';

v_msg            varchar2(1000);

type MyRefCurA IS  REF CURSOR RETURN BUSI_YEAR_REPORT%RowType;

vRefCurA  MyRefCurA;

vTempA  vRefCurA%RowType;



begin

  select sysdate into v_today from dual;

  if p_compid <> '0' then

      open vRefCurA for  select y.*

      from BUSI_YEAR_REPORT y

      where  y.is_delete = '0' and  y.cp_id =p_compid and  y.report_period =current_report_date;

      loop

          fetch vRefCurA into vTempA;

           if vRefCurA%notfound then

                exit;

            end if;



         update BUSI_YEAR_REPORT set HISTORY_STATUS='1',UPDATE_DATE=v_today,UPDATE_BY=p_mgrname  where  id=vTempA.id;

      end loop;

      close vRefCurA;

  end if;



  if p_compid = '0' then

      open vRefCurA for  select y.*

      from BUSI_YEAR_REPORT y

      where  y.is_delete = '0' and  y.report_period =current_report_date;

      loop

          fetch vRefCurA into vTempA;

           if vRefCurA%notfound then

                exit;

            end if;

         update BUSI_YEAR_REPORT set HISTORY_STATUS='1',UPDATE_DATE=v_today,UPDATE_BY=p_mgrname  where  id=vTempA.id;

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



end TGYW_PRODUCT_SYN_YEAR_H_REPORT;
/


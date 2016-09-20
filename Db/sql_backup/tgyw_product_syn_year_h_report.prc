create or replace procedure smzj.TGYW_PRODUCT_SYN_YEAR_H_REPORT(

      p_compid    in  varchar2,   --��˾id

      p_mgrname   in  varchar2,   --����������

      current_report_date  in  varchar2   --��ǰ�걨����

)

as

---- *************************************************************************

-- SUBSYS:     �йܷ���

-- PROGRAM:      TGYW_PRODUCT_SYN_YEAR_REPORT

-- RELATED TAB:

-- SUBPROG:

-- REFERENCE:

-- AUTHOR:

-- DESCRIPTION: (������ʷ�걨��Ϣ)

-- CREATE DATE:  2016-06-23

-- VERSION:

-- EDIT HISTORY:

-- *************************************************************************

v_today          date;               --��ǰ����

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

  insert into t_fund_job_running_log(job_name,job_running_log) values(v_job_name,'ͬ���ɹ�');

  commit;



EXCEPTION

    when others then

        if vRefCurA%isopen then

            close vRefCurA;

        end if;

        rollback;

        v_msg:='ͬ��ʧ�ܣ�ԭ��'||':'||sqlcode||':'||sqlerrm ||'   '|| dbms_utility.format_error_backtrace();

        insert into t_fund_job_running_log(job_name,job_running_log) values(v_job_name,v_msg);

        commit;



end TGYW_PRODUCT_SYN_YEAR_H_REPORT;
/


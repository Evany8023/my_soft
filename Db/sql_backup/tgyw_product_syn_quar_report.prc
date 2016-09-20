create or replace procedure smzj.TGYW_PRODUCT_SYN_QUAR_REPORT(

      p_compid    in  varchar2,   --公司id

      p_mgrname   in  varchar2,   --管理人名称

      p_mgrid     in  varchar2,   --管理人id

      current_report_date  in  varchar2,   --当前季报日期

      p_begin_date  in  varchar2   --产品截止日期

)

as

---- *************************************************************************

-- SUBSYS:     托管服务

-- PROGRAM:      TGYW_PRODUCT_SYN_QUAR_REPORT

-- RELATED TAB:

-- SUBPROG:

-- REFERENCE:

-- AUTHOR:

-- DESCRIPTION:(季报信息)

-- CREATE DATE:  2016-06-23

-- VERSION:

-- EDIT HISTORY:

-- *************************************************************************

v_today          date;      --当天日期

v_time_difference varchar2(100);      --产品成立日期与今天的时间差

v_job_name       varchar2(100):='TGYW_PRODUCT_SYN_QUAR_REPORT';

v_msg            varchar2(1000);

type MyRefCurA IS  REF CURSOR RETURN BUSI_PRODUCT%RowType;

vRefCurA  MyRefCurA;

vTempA  vRefCurA%RowType;

v_product_count                  integer; -- 未清盘的产品数量

v_clrq          date;      --成立日期



--取当前公司下本季产品





begin

  select sysdate into v_today from dual;

  if p_compid <> '0' then

  open vRefCurA for  select p1.*

        from BUSI_PRODUCT p1

        where p1.IS_CURRENT_QUAR_REPORT = '1' and  p1.is_delete = '0' and p1.cp_id =p_compid

        and p1.id not in(select p.id

        from BUSI_PRODUCT p,BUSI_QUARTERLY_REPORT y

        where y.PRODUCT_NO = p.PRODUCT_NO and p.IS_CURRENT_QUAR_REPORT = '1' and y.is_delete = '0' and p.is_delete = '0' and y.report_period =current_report_date and p.cp_id =p_compid)

         union

        select p1.*

        from BUSI_PRODUCT p1

        where  p1.is_delete = '0' and p1.cp_id =p_compid  and (p1.PUBLISH_STATUS = '0' or p1.PUBLISH_STATUS= '6' )

        and p1.id not in(select p.id

        from BUSI_PRODUCT p,BUSI_QUARTERLY_REPORT y

        where y.PRODUCT_NO = p.PRODUCT_NO and y.is_delete = '0' and p.is_delete = '0' and y.report_period =current_report_date and p.cp_id =p_compid);

  loop

      fetch vRefCurA into vTempA;

       if vRefCurA%notfound then

            exit;

        end if;

        -- 如果状态为1，即为本季产品

        if vTempA.IS_CURRENT_QUAR_REPORT = '1'  then

          insert into BUSI_QUARTERLY_REPORT(id,product_no,product_name,cp_id,mgr_id,report_period,status,is_delete,HISTORY_STATUS,create_by,create_date)

           values(sys_guid(),vTempA.PRODUCT_NO,vTempA.name,vTempA.cp_id,p_mgrid,current_report_date,'0','0','0',p_mgrname,v_today);

    end if;

     -- 如果状态为0，且当季成立满两个月的产品需出具月报，即当季第二个月第一个自然日及之前成立的产品，且当前仍在可用期的产品
    select count(*) into v_product_count from tgyyzx.v_ysmzj_xmxx@yy_dblimk m where m.vc_xmdm=vTempA.PRODUCT_NO and m.d_xmbh_qtime is null;

    if  vTempA.IS_CURRENT_QUAR_REPORT = '0'  and v_product_count>0 then

         select yp.d_xmbh_ctime into v_clrq from tgyyzx.v_ysmzj_xmxx@yy_dblimk yp where yp.vc_xmdm=vTempA.PRODUCT_NO and yp.d_xmbh_qtime is null and rownum=1;
         v_time_difference :=0;


          SELECT (trunc(to_date(p_begin_date,'yyyy-MM-dd')) -  trunc(v_clrq)) into v_time_difference from dual;

       if v_time_difference >= 60 then

         insert into BUSI_QUARTERLY_REPORT(id,product_no,product_name,cp_id,mgr_id,report_period,status,is_delete,HISTORY_STATUS,create_by,create_date)

         values(sys_guid(),vTempA.PRODUCT_NO,vTempA.name,vTempA.cp_id,p_mgrid,current_report_date,'0','0','0',p_mgrname,v_today);

        end if;

    end if;

  end loop;

  close vRefCurA;

end if;



if p_compid = '0' then

  open vRefCurA for  select p1.*

        from BUSI_PRODUCT p1

        where p1.IS_CURRENT_QUAR_REPORT = '1' and  p1.is_delete = '0'

        and p1.id not in(select p.id

        from BUSI_PRODUCT p,BUSI_QUARTERLY_REPORT y

        where y.PRODUCT_NO = p.PRODUCT_NO and p.IS_CURRENT_QUAR_REPORT = '1' and y.is_delete = '0' and p.is_delete = '0' and y.report_period =current_report_date )

         union

        select p1.*

        from BUSI_PRODUCT p1

        where  p1.is_delete = '0'  and (p1.PUBLISH_STATUS = '0' or p1.PUBLISH_STATUS= '6' )

        and p1.id not in(select p.id

        from BUSI_PRODUCT p,BUSI_QUARTERLY_REPORT y

        where y.PRODUCT_NO = p.PRODUCT_NO and y.is_delete = '0' and p.is_delete = '0' and y.report_period =current_report_date );

  loop

      fetch vRefCurA into vTempA;

       if vRefCurA%notfound then

            exit;

        end if;

     -- 如果状态为1，即为本季产品

        if vTempA.IS_CURRENT_QUAR_REPORT = '1'  then

          insert into BUSI_QUARTERLY_REPORT(id,product_no,product_name,cp_id,mgr_id,report_period,status,is_delete,HISTORY_STATUS,create_by,create_date)

           values(sys_guid(),vTempA.PRODUCT_NO,vTempA.name,vTempA.cp_id,p_mgrid,current_report_date,'0','0','0',p_mgrname,v_today);

    end if;

     -- 如果状态为0，且当季成立满两个月的产品需出具月报，即当季第二个月第一个自然日及之前成立的产品，且当前仍在可用期的产品
      select count(*) into v_product_count from tgyyzx.v_ysmzj_xmxx@yy_dblimk m where m.vc_xmdm=vTempA.PRODUCT_NO and m.d_xmbh_qtime is null;

    if  vTempA.IS_CURRENT_QUAR_REPORT = '0'  and v_product_count>0 then
      select yp.d_xmbh_ctime into v_clrq from tgyyzx.v_ysmzj_xmxx@yy_dblimk yp where yp.vc_xmdm=vTempA.PRODUCT_NO and yp.d_xmbh_qtime is null and rownum=1;

         v_time_difference :=0;

        SELECT (trunc(to_date(p_begin_date,'yyyy-MM-dd')) -  trunc( v_clrq)) into v_time_difference from dual;

       if v_time_difference >= 60 then

          insert into BUSI_QUARTERLY_REPORT(id,product_no,product_name,cp_id,mgr_id,report_period,status,is_delete,HISTORY_STATUS,create_by,create_date)

          values(sys_guid(),vTempA.PRODUCT_NO,vTempA.name,vTempA.cp_id,p_mgrid,current_report_date,'0','0','0',p_mgrname,v_today);

        end if;

    end if;

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



end TGYW_PRODUCT_SYN_QUAR_REPORT;
/


create or replace procedure smzj.TGYW_PRODUCT_SYN_QUAR_REPORT(

      p_compid    in  varchar2,   --��˾id

      p_mgrname   in  varchar2,   --����������

      p_mgrid     in  varchar2,   --������id

      current_report_date  in  varchar2,   --��ǰ��������

      p_begin_date  in  varchar2   --��Ʒ��ֹ����

)

as

---- *************************************************************************

-- SUBSYS:     �йܷ���

-- PROGRAM:      TGYW_PRODUCT_SYN_QUAR_REPORT

-- RELATED TAB:

-- SUBPROG:

-- REFERENCE:

-- AUTHOR:

-- DESCRIPTION:(������Ϣ)

-- CREATE DATE:  2016-06-23

-- VERSION:

-- EDIT HISTORY:

-- *************************************************************************

v_today          date;      --��������

v_time_difference varchar2(100);      --��Ʒ��������������ʱ���

v_job_name       varchar2(100):='TGYW_PRODUCT_SYN_QUAR_REPORT';

v_msg            varchar2(1000);

type MyRefCurA IS  REF CURSOR RETURN BUSI_PRODUCT%RowType;

vRefCurA  MyRefCurA;

vTempA  vRefCurA%RowType;

v_product_count                  integer; -- δ���̵Ĳ�Ʒ����

v_clrq          date;      --��������



--ȡ��ǰ��˾�±�����Ʒ





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

        -- ���״̬Ϊ1����Ϊ������Ʒ

        if vTempA.IS_CURRENT_QUAR_REPORT = '1'  then

          insert into BUSI_QUARTERLY_REPORT(id,product_no,product_name,cp_id,mgr_id,report_period,status,is_delete,HISTORY_STATUS,create_by,create_date)

           values(sys_guid(),vTempA.PRODUCT_NO,vTempA.name,vTempA.cp_id,p_mgrid,current_report_date,'0','0','0',p_mgrname,v_today);

    end if;

     -- ���״̬Ϊ0���ҵ��������������µĲ�Ʒ������±����������ڶ����µ�һ����Ȼ�ռ�֮ǰ�����Ĳ�Ʒ���ҵ�ǰ���ڿ����ڵĲ�Ʒ
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

     -- ���״̬Ϊ1����Ϊ������Ʒ

        if vTempA.IS_CURRENT_QUAR_REPORT = '1'  then

          insert into BUSI_QUARTERLY_REPORT(id,product_no,product_name,cp_id,mgr_id,report_period,status,is_delete,HISTORY_STATUS,create_by,create_date)

           values(sys_guid(),vTempA.PRODUCT_NO,vTempA.name,vTempA.cp_id,p_mgrid,current_report_date,'0','0','0',p_mgrname,v_today);

    end if;

     -- ���״̬Ϊ0���ҵ��������������µĲ�Ʒ������±����������ڶ����µ�һ����Ȼ�ռ�֮ǰ�����Ĳ�Ʒ���ҵ�ǰ���ڿ����ڵĲ�Ʒ
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



end TGYW_PRODUCT_SYN_QUAR_REPORT;
/


create or replace procedure smzj.tgyw_hwlnetval (

    v_regs         in  varchar2,         --�û��Ǽ��˺�
    v_comid        in  varchar2,         --��˾id
    v_ptno         in  varchar2,         --��Ʒ����
    v_highstatus   in  varchar2,         --��ˮλ״̬(1��ÿ����¶һ�죬2��ȫ����¶)
    v_startdate    in  varchar2,         --��ʼ����
    v_enddate      in  varchar2,         --��������
    v_yfbz         in  varchar2,         --�Ƿ����ҵ������

    --��ҳ��Ϣ
    pi_pageNo      in  int,              --��ǰҳ
    pi_pageSize    in  int ,             --ÿҳ��ʾ��¼��
--    pi_totlePage   in  int ,             --��ҳ��

    po_returncode  out varchar2,         --�������
    po_returnmsg   out varchar2,         --������Ϣ
    po_sumno       out int,              --�ܼ�¼��
    po_currPage    out int,              --�����ĵ�ǰҳ
    po_refcur      out  sys_refcursor    -- ���ؼ�¼��
)

-- *************************************************************************
-- SYSTEM:       �е�ϵͳ
-- SUBSYS:       TA��ϵͳ
-- PROGRAM:      TGYW_HWLNETVAL
-- RELATED TAB:
-- SUBPROG:
-- REFERENCE:
-- DESCRIPTION:  Ͷ���߸�ˮλ��ѯ
-- INPUT:
-- OUTPUT:
-- RETURN:       0    ��������
--               -1   ���ݿ����
-- AUTHOR:       ������
-- CREATE DATE:  2016-04-29
-- VERSION:
-- EDIT HISTORY:
-- *************************************************************************
as
    v_msg                     varchar2(1000);
    ve_exception              exception;
    v_firstday                varchar(10);        --���µ�һ��
    v_today                   varchar(10);        --��������
    vc_sql                    varchar2(2014);     --sql���
    vc_p_sql                  varchar2(2014);     --��ҳ���sql

    vn_qsh                    int;               --��ʼ�к�
    vn_jsh                    int;               --�����к�
--    v_pi_pageNo               int;              --�����ǰҳ
BEGIN
    -- ��������
    if v_regs is null  then
        v_msg  := '��Ҫָ���û��Ǽ��˺�';
        raise ve_exception;
    end if;
    if v_comid is null  then
        v_msg  := '��Ҫָ���û�������˾id';
        raise ve_exception;
    end if;
    if v_ptno is null  then
        v_msg  := '��Ҫָ����Ʒ����';
        raise ve_exception;
    end if;
    if v_highstatus!=1 and v_highstatus!=2 then
        v_msg  := '��Ҫָ����Ʒ��ˮλ״̬';
        raise ve_exception;
    end if;
    --��ѯ���ݿ�ʼ
    --ƴ�Ӹ�ˮλ״̬Ϊÿ����¶һ�ε�SQL���
    if v_highstatus=1 then
        --��ѯ�������һ�������գ��ͱ��µ�һ��,��������
--        select max(rq) into v_maxday from zsta_tgpt.rlb@ta_dblink t where t.gzr='1' and t.rq like to_char(sysdate,'yyyyMM')||'%';
        select to_char(sysdate,'yyyyMM')||'01',to_char(sysdate,'yyyyMMdd') into v_firstday,v_today from dual;
        --1.ƴ������������ѯSQL���inner join busi_investor_credit cr on cr.regist_account = gsw.djzh
        vc_sql:='select n.KHMC,n.CREDIT_NO,n.QMFE,n.QRRQ,n.DWJZ,n.GZRQ,n.JTBZ  YFBZ,n.PRO_NAME,n.KHBH,n.CPDM,n.fundType,n.ptId from
          (
                         select max(rq) as rq from zsta.rlb@ta_dblink where   gzr = 1 group by substr(rq, 1, 6)
            ) m inner join
           (
              select gsw.KHMC,gsw.CREDIT_NO,gsw.QMFE,gsw.QRRQ,gsw.DWJZ,gsw.GZRQ,gsw.JTBZ,gsw.PRO_NAME,gsw.KHBH,gsw.CPDM,gsw.pro_id ptId,CASE padd.FUND_TYPE WHEN '||'''1'''||' THEN '||'''1'''||' ELSE '||'''0'''||' END AS fundType
                    from  t_gswjz_info gsw
                    inner join busi_product pr on pr.product_no = gsw.cpdm and pr.is_delete = 0 and pr.cp_id=''' ||v_comid|| ''' and pr.is_delete = 0 and gsw.sourcetype=0 and pr.is_show_invetstor=1

                    left join busi_product_add padd on pr.ID=padd.PRODUCT_ID
                    where pr.high_status = 1 and gsw.cpdm = ''' ||v_ptno|| ''' and gsw.djzh in ('||v_regs||')';

         if trim(v_yfbz) is not null and v_yfbz=1 then
           vc_sql:=vc_sql || ' and gsw.JTBZ =''' ||v_yfbz || '''';
         end if;
         if trim(v_yfbz) is not null and v_yfbz=0 then
           vc_sql:=vc_sql || 'and (gsw.JTBZ =0 or gsw.JTBZ  =2)';
         end if;

         vc_sql:=vc_sql || ') n on  m.rq = n.GZRQ ';

         if trim(v_startdate) is not null then
            vc_sql:=vc_sql || ' and n.qrrq >=''' ||v_startdate || '''';
         end if;
         if trim(v_enddate) is not null then
             vc_sql:=vc_sql || ' and n.qrrq <=''' ||v_enddate || '''';
         end if;
         vc_sql:=vc_sql || ' and n.gzrq <''' ||v_firstday || '''';    --��ʼ���ںͽ������ڶ����ܴ��ڱ��µ�һ��
--         if v_today--            vc_sql:=vc_sql || ' and n.GZRQ<''' ||v_firstday|| '''';
--         end if;
    end if;
    --ƴ�Ӹ�ˮλ״̬Ϊȫ����¶��SQL��俪ʼ
    if v_highstatus=2 then
        vc_sql:='select n.KHMC,n.CREDIT_NO,n.QMFE,n.QRRQ,n.DWJZ,n.GZRQ,n.JTBZ YFBZ,n.PRO_NAME,n.pro_id ptId,
                CASE padd.FUND_TYPE WHEN '||'''1'''||' THEN '||'''1'''||' ELSE '||'''0'''||' END AS fundType
                from  t_gswjz_info n
                join busi_product pr on pr.product_no = n.cpdm

                left join busi_product_add padd on pr.ID=padd.PRODUCT_ID
           where
                 pr.high_status = 2 and pr.is_delete = 0 and pr.is_show_invetstor=1 and n.sourcetype=0 and pr.cp_id=''' ||v_comid|| '''
           and n.cpdm = ''' ||v_ptno|| '''
           and n.djzh  in ('||v_regs||') ';
        if trim(v_startdate) is not null then
           vc_sql:=vc_sql || ' and n.QRRQ >=''' ||v_startdate || '''';
         end if;
         if trim(v_enddate) is not null then
           vc_sql:=vc_sql || ' and n.QRRQ <=''' ||v_enddate || '''';
         end if;
         if trim(v_yfbz) is not null and v_yfbz=1 then
           vc_sql:=vc_sql || ' and n.JTBZ =''' ||v_yfbz || '''';
         end if;
         if trim(v_yfbz) is not null and v_yfbz=0 then
           vc_sql:=vc_sql || ' and (n.JTBZ =0 or n.JTBZ =2)';
         end if;
    end if;

    --ƴ������������ѯSQL������

    --2.��ӷ�ҳ��Ϣ
         --�ܼ�¼��
         vc_p_sql:='begin select count(1) into :out from ('||vc_sql||'); end;';
         execute immediate vc_p_sql using out po_sumno;

         --���㷵�ؼ�¼��
         if pi_pageNo is null and pi_pageSize is null then
            vn_qsh :=1;
            vn_jsh :=po_sumNo;
          elsif pi_pageno > 0 and pi_pagesize > 0 then
            if ((pi_pageno-1)*pi_pagesize) > po_sumno then
              po_currPage:=1;
            else
              po_currPage:=pi_pageno;
            end if;

            vn_qsh :=(po_currpage-1) * pi_pagesize + 1;
            vn_jsh :=po_currPage * pi_pagesize;
          end if;
         --ƴ�ӷ�ҳ���SQL���
         vc_p_sql :='select * from ( select temp.*, rownum row_id from ('||vc_sql|| 'order by n.CPDM,n.QRRQ DESC,n.GZRQ DESC) temp where rownum <= '|| vn_jsh ||') where row_id >='||vn_qsh;
         po_returncode :='0000';
         po_returnmsg :='Ͷ���߸�ˮλ��Ϣ��ѯ�ɹ���';
         insert into T_FUND_JOB_RUNNING_LOG(JOB_NAME,JOB_RUNNING_LOG) values(v_msg, v_regs);
        --���ؽ����
   open po_refcur for vc_p_sql;

    EXCEPTION
    WHEN ve_exception then
        rollback;
         v_msg:='ʧ��'||sqlerrm || sqlcode;
         insert into T_FUND_JOB_RUNNING_LOG(JOB_NAME,JOB_RUNNING_LOG) values(v_msg|| v_regs ,vc_p_sql);
        vc_sql := 'select 1 KHMC,2 CREDIT_NO,3 QMFE,4 QRRQ,5 DWJZ,6 GZRQ,7 YFBZ,8 PRO_NAME,9 KHBH,10 CPDM,11 fundType,12 ptId from dual where 1=2';
        COMMIT;
        open po_refcur for vc_sql;
        RETURN;
    WHEN OTHERS THEN
        ROLLBACK;
         v_msg:='ʧ��'||sqlerrm || sqlcode;
         insert into T_FUND_JOB_RUNNING_LOG(JOB_NAME,JOB_RUNNING_LOG) values(v_msg,vc_p_sql);
         COMMIT;

        vc_sql := 'select 1 KHMC,2 CREDIT_NO,3 QMFE,4 QRRQ,5 DWJZ,6 GZRQ,7 YFBZ,8 PRO_NAME,9 KHBH,10 CPDM,11 fundType,12 ptId from dual where 1=2';
        open po_refcur for vc_sql;
        return;
        commit;
END TGYW_HWLNETVAL;
/


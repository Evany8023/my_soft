CREATE OR REPLACE PROCEDURE SMZJ.TGYW_INVESTOR_REPORT (

--v_regist       in  varchar2,         --�û��Ǽ��˺�
v_regs           in  varchar2,         --�Ǽ��˺ż����ַ���
v_ptNo         in  varchar2,         --��Ʒ����
v_reportType   in  varchar2,         --��¶����
v_year         in  varchar2,         --��¶���
v_comid        in  varchar2,         --��˾id
--��ҳ��Ϣ
pi_pageNo      in  int,              --��ǰҳ
pi_pageSize    in  int ,             --ÿҳ��ʾ��¼��
--pi_totlePage   in  int ,             --��ҳ��

po_returncode  out varchar2,         --�������
po_returnmsg   out varchar2,         --������Ϣ
po_sumNo       out int,              --�ܼ�¼��
po_currPage    out int,              --�����ĵ�ǰҳ
po_refcur      out  sys_refcursor    -- ���ؼ�¼��

)
-- *************************************************************************
-- SYSTEM:       �е�ϵͳ
-- SUBSYS:       TA��ϵͳ
-- PROGRAM:      TGYW_INVESTOR_REPORT
-- RELATED TAB:
-- SUBPROG:
-- REFERENCE:
-- DESCRIPTION:  ��ѯ��Ͷ������¶���û�����
-- INPUT:
-- OUTPUT:
-- RETURN:       0    ��������
--               -1   ���ݿ����
-- AUTHOR:       ������
-- CREATE DATE:  2016-03-08
-- VERSION:
-- EDIT HISTORY:
-- *************************************************************************
as
v_msg                        varchar2(1000);
ve_exception EXCEPTION;
vc_sql         varchar2(2014);     --sql���
vc_p_sql       varchar2(2014);     --��ҳ���sql
v_insert_sql   varchar2(2014);     --��¼SQL���
vn_cnt         integer;

vn_qsh         int;               --��ʼ�к�
vn_jsh         int;               --�����к�

begin
        -- ��������
    if v_regs is null  then
        v_msg  := '��Ҫָ���û��Ǽ��˺�';
        raise ve_exception;
    end if;
    if v_comid is null  then
        v_msg  := '��Ҫָ���û�������˾id';
        raise ve_exception;
    end if;

    -- ��ʱ���Ƿ����
    vc_sql := 'begin select count(0) into :out from user_tables where TABLE_NAME = upper(''BUSI_INVESTOR_REPORT_TMP''); end;';
    execute immediate vc_sql using out vn_cnt;
    if vn_cnt > 0 then
        execute immediate 'truncate table BUSI_INVESTOR_REPORT_TMP'; -- ɾ������
     else
        vc_sql := 'create global temporary table BUSI_INVESTOR_REPORT_TMP
                   (
                  PT_ID VARCHAR2(32 BYTE),
                  PT_NAME VARCHAR2(100 BYTE),
                  PT_NO VARCHAR2(32 BYTE),
                  CP_ID VARCHAR2(32 BYTE),
                  REGIST_ACCOUNT VARCHAR2(16 BYTE),
                  STRAT_DATE DATE,
                  END_DATE DATE,
                  SHOW_REPORT_STATUE CHAR(1 BYTE) DEFAULT 2,
                  SHOW_FLAG CHAR(1 BYTE) DEFAULT 0
                   ) on commit preserve rows;';
           Execute Immediate vc_sql;
    end if;

        --1.1.1.Ŀǰ�޳ֲ֣��ݶ��������޼�¼,�ȱ��濪ʼ���ڣ���������ͨ��update������--������ĸ��Ʒ���������Ӳ�Ʒ
--        insert into busi_investor_report_tmp (pt_id,pt_name,pt_no,cp_id,regist_account,strat_date,SHOW_REPORT_STATUE)
--
--         select g.productid,c.PT_NAME,c.PT_NO,p.CP_ID,c.REGIST_ACCOUNT,c.CONFIRM_DATE,p.show_report_statue from (select * from(select c1.pt_no,c1.PT_NAME,c1.REGIST_ACCOUNT,c1.CONFIRM_DATE,
--                    row_number() over(partition by c1.pt_no order by c1.confirm_date) num
--                    from busi_trading_confirm c1 where c1.regist_account=v_regist and c1.sourcetype='0') rn where rn.num=1) c
--                    inner join busi_product p on p.product_no=c.pt_no
--                    inner join v_product_grad g on p.id=g.id
--                  where c.REGIST_ACCOUNT=v_regist and  p.is_show_invetstor='1' and p.is_delete='0' and p.cp_id=v_comid and p.show_report_statue!=0
--                  and not EXISTS (select 1 from BUSI_SHARE_BALANCE b where b.REGIST_ACCOUNT=c.REGIST_ACCOUNT and b.PT_NO=c.PT_NO);

        --1.1.2.ͨ��updat�����½�������--��ʱ�ȷ�һ��----------------------
--       update busi_investor_report_tmp t set t.end_date=
--       (select c.CONFIRM_DATE from (select * from(select c1.pt_no,c1.REGIST_ACCOUNT,c1.CONFIRM_DATE,c1.INSTI_CODE,
--            row_number() over(partition by c1.pt_no order by c1.confirm_date desc) num
--            from busi_trading_confirm c1 where c1.regist_account=v_regist and c1.sourcetype='0') rn where rn.num=1) c
--        where t.REGIST_ACCOUNT=v_regist and c.REGIST_ACCOUNT=t.REGIST_ACCOUNT and c.PT_NO=t.PT_NO
--          and not exists (select 1 from busi_share_balance b where b.regist_account=c.regist_account and b.pt_no=c.pt_no and b.INSTI_CODE=c.INSTI_CODE)
--        );

        --1.2.Ŀǰ�гֲ֣��ݶ��������м�¼��
--        insert into busi_investor_report_tmp (pt_id,pt_name,pt_no,cp_id,regist_account,strat_date,end_date,show_report_statue,show_flag)
--           select g.productid,g.name,b.PT_NO,bp.cp_id,b.REGIST_ACCOUNT,c.CONFIRM_DATE,sysdate,bp.show_report_statue,'1' from BUSI_SHARE_BALANCE b
--            inner join (select * from (select row_number() over(partition by con.pt_no order by con.confirm_date) as num,
--                con.pt_no,con.regist_account,con.confirm_date from busi_trading_confirm con where con.regist_account=v_regist and con.sourcetype='0') rn where rn.num=1)
--              c on c.REGIST_ACCOUNT=b.REGIST_ACCOUNT and c.PT_NO=b.PT_NO
--            inner join busi_product bp on b.pt_id=bp.id and bp.is_delete='0' and bp.cp_id=v_comid and bp.is_show_invetstor='1' and bp.SHOW_REPORT_STATUE=1
--            inner join v_product_grad g on bp.id=g.id
--            where b.REGIST_ACCOUNT=v_regist;
          --session��ȫ��������Ǽ��˺�,distinctȥ��
          v_insert_sql:='insert into busi_investor_report_tmp (pt_id,pt_name,pt_no,cp_id,strat_date,end_date,show_report_statue,show_flag)
           select distinct g.productid,g.name,b.PT_NO,bp.cp_id,c.CONFIRM_DATE,sysdate,bp.show_report_statue,1 from BUSI_SHARE_BALANCE b
            inner join (select * from (select row_number() over(partition by con.pt_no order by con.confirm_date) as num,
                con.pt_no,con.regist_account,con.confirm_date from busi_trading_confirm con where con.regist_account in ('||v_regs||') and con.sourcetype=0) rn where rn.num=1)
              c on c.REGIST_ACCOUNT=b.REGIST_ACCOUNT and c.PT_NO=b.PT_NO
            inner join busi_product bp on b.pt_id=bp.id and bp.is_delete=0 and bp.cp_id='''||v_comid||''' and bp.is_show_invetstor=1 and bp.SHOW_REPORT_STATUE=1
            inner join v_product_grad g on bp.id=g.id
            where b.REGIST_ACCOUNT in ('||v_regs||')';
          --����ִ�в������
--          dbms_output.put_line('����v_insert_sql:'||v_insert_sql);
          EXECUTE IMMEDIATE v_insert_sql;
                 
        COMMIT;

        --2.1��ѯ��Ҫ�Ľ��
        vc_sql:='select mr.id reportId,
                mr.PT_NAME productName,
                mr.PT_NO productNo,
                mr.REPORT_TYPE reportType,
                mr.REPORT_YEAR reportYear,
                to_char(mr.CREATE_DATE,'||'''YYYY-MM-DD'''||') releaseDate,
                mr.REPORT_TITLE reportTitle,
                mr.file_url fileUrl,
                mr.file_name fileName,
                mr.REPORT_CONTENT reportContent
                from BUSI_INVESTOR_REPORT_TMP t inner join BUSI_MGR_REPORT mr on t.PT_ID=mr.PT_ID
                where mr.WORK_DAY between to_char(t.STRAT_DATE,'||'''yyyyMMdd'''||') and to_char(t.END_DATE,'||'''yyyyMMdd'''||')
                      and mr.IS_SEND=1 and mr.is_delete=0
                      and (t.SHOW_REPORT_STATUE=2 or (t.SHOW_REPORT_STATUE=1 and t.SHOW_FLAG=1)) ';
--        --2.2ƴ�Ӳ�ѯ����
         if trim(v_ptNo) is not null then
            vc_sql:=vc_sql || ' and mr.PT_NO =''' ||v_ptNo || '''';
         end if;
         if trim(v_reportType) is not null then
            vc_sql:=vc_sql || ' and mr.REPORT_TYPE =''' ||v_reportType || '''';
         end if;
         if trim(v_year) is not null then
            vc_sql:=vc_sql || ' and mr.REPORT_YEAR =''' ||v_year || '''';
         end if;

         --3.��ӷ�ҳ��Ϣ
         --�ܼ�¼��
         vc_p_sql:='begin select count(1) into :out from ('||vc_sql||'); end;';
         execute immediate vc_p_sql using out po_sumNo;
         --���㷵�ؼ�¼��
         if pi_pageNo is null and pi_pageSize is null then
            vn_qsh :=1;
            vn_jsh :=po_sumNo;
          elsif pi_pageNo > 0 and pi_pageSize > 0 then
            if ((pi_pageno-1)*pi_pagesize) > po_sumno then
              po_currPage:=1;
            else
              po_currPage:=pi_pageno;
            end if;

            vn_qsh :=(po_currpage-1) * pi_pagesize + 1;
            vn_jsh :=po_currPage * pi_pagesize;
          end if;
         --ƴ�ӷ�ҳ���SQL���
         vc_p_sql :='select * from ( select temp.*, rownum row_id from ('||vc_sql|| 'order by mr.create_date desc) temp where rownum <= '|| vn_jsh ||') where row_id >='||vn_qsh;
        commit;
           po_returncode :='0000';
         po_returnmsg :='Ͷ���߱����ѯ�ɹ���';
        --���ؽ����
--        dbms_output.put_line('��ѯvc_sql:'||vc_sql);
   open po_refcur for vc_p_sql;

EXCEPTION
    WHEN ve_exception then
        rollback;
         v_msg:='ʧ��'||sqlerrm || sqlcode;
         insert into T_FUND_JOB_RUNNING_LOG(JOB_NAME,JOB_RUNNING_LOG) values(v_msg|| v_regs ,dbms_utility.format_error_backtrace());
        vc_sql := 'select mr.id reportId,
                mr.PT_NAME productName,
                mr.PT_NO productNo,
                mr.REPORT_TYPE reportType,
                mr.REPORT_YEAR reportYear,
                to_char(mr.CREATE_DATE,'||'''YYYY-MM-DD'''||') releaseDate,
                mr.REPORT_TITLE reportTitle,
                mr.file_url fileUrl,
                mr.file_name fileName,
                mr.REPORT_CONTENT reportContent  from BUSI_MGR_REPORT mr where 1 = 2';
        COMMIT;
        open po_refcur for vc_sql;
        RETURN;
    WHEN OTHERS THEN
        ROLLBACK;
         v_msg:='ʧ��'||sqlerrm || sqlcode;
         insert into T_FUND_JOB_RUNNING_LOG(JOB_NAME,JOB_RUNNING_LOG) values(v_msg,dbms_utility.format_error_backtrace());
        COMMIT;

        vc_sql := 'select mr.id reportId,
                mr.PT_NAME productName,
                mr.PT_NO productNo,
                mr.REPORT_TYPE reportType,
                mr.REPORT_YEAR reportYear,
                to_char(mr.CREATE_DATE,'||'''YYYY-MM-DD'''||') releaseDate,
                mr.REPORT_TITLE reportTitle,
                mr.file_url fileUrl,
                mr.file_name fileName,
                mr.REPORT_CONTENT reportContent  from BUSI_MGR_REPORT mr where 1 = 2';
        open po_refcur for vc_sql;
        return;
        commit;

END TGYW_INVESTOR_REPORT;
/


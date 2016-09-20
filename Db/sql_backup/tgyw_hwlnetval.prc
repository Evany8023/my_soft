create or replace procedure smzj.tgyw_hwlnetval (

    v_regs         in  varchar2,         --用户登记账号
    v_comid        in  varchar2,         --公司id
    v_ptno         in  varchar2,         --产品代码
    v_highstatus   in  varchar2,         --高水位状态(1：每月披露一天，2：全部披露)
    v_startdate    in  varchar2,         --开始日期
    v_enddate      in  varchar2,         --结束日期
    v_yfbz         in  varchar2,         --是否计提业绩报酬

    --分页信息
    pi_pageNo      in  int,              --当前页
    pi_pageSize    in  int ,             --每页显示记录数
--    pi_totlePage   in  int ,             --总页数

    po_returncode  out varchar2,         --错误代码
    po_returnmsg   out varchar2,         --错误信息
    po_sumno       out int,              --总记录数
    po_currPage    out int,              --计算后的当前页
    po_refcur      out  sys_refcursor    -- 返回记录集
)

-- *************************************************************************
-- SYSTEM:       中登系统
-- SUBSYS:       TA子系统
-- PROGRAM:      TGYW_HWLNETVAL
-- RELATED TAB:
-- SUBPROG:
-- REFERENCE:
-- DESCRIPTION:  投资者高水位查询
-- INPUT:
-- OUTPUT:
-- RETURN:       0    正常返回
--               -1   数据库错误
-- AUTHOR:       徐鹏飞
-- CREATE DATE:  2016-04-29
-- VERSION:
-- EDIT HISTORY:
-- *************************************************************************
as
    v_msg                     varchar2(1000);
    ve_exception              exception;
    v_firstday                varchar(10);        --本月第一天
    v_today                   varchar(10);        --当天日期
    vc_sql                    varchar2(2014);     --sql语句
    vc_p_sql                  varchar2(2014);     --分页相关sql

    vn_qsh                    int;               --起始行号
    vn_jsh                    int;               --结束行号
--    v_pi_pageNo               int;              --计算后当前页
BEGIN
    -- 参数控制
    if v_regs is null  then
        v_msg  := '需要指定用户登记账号';
        raise ve_exception;
    end if;
    if v_comid is null  then
        v_msg  := '需要指定用户所属公司id';
        raise ve_exception;
    end if;
    if v_ptno is null  then
        v_msg  := '需要指定产品代码';
        raise ve_exception;
    end if;
    if v_highstatus!=1 and v_highstatus!=2 then
        v_msg  := '需要指定产品高水位状态';
        raise ve_exception;
    end if;
    --查询数据开始
    --拼接高水位状态为每月披露一次的SQL语句
    if v_highstatus=1 then
        --查询本月最后一个工作日，和本月第一天,当天日期
--        select max(rq) into v_maxday from zsta_tgpt.rlb@ta_dblink t where t.gzr='1' and t.rq like to_char(sysdate,'yyyyMM')||'%';
        select to_char(sysdate,'yyyyMM')||'01',to_char(sysdate,'yyyyMMdd') into v_firstday,v_today from dual;
        --1.拼接搜索条件查询SQL语句inner join busi_investor_credit cr on cr.regist_account = gsw.djzh
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
         vc_sql:=vc_sql || ' and n.gzrq <''' ||v_firstday || '''';    --开始日期和结束日期都不能大于本月第一天
--         if v_today--            vc_sql:=vc_sql || ' and n.GZRQ<''' ||v_firstday|| '''';
--         end if;
    end if;
    --拼接高水位状态为全部披露的SQL语句开始
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

    --拼接搜索条件查询SQL语句结束

    --2.添加分页信息
         --总记录数
         vc_p_sql:='begin select count(1) into :out from ('||vc_sql||'); end;';
         execute immediate vc_p_sql using out po_sumno;

         --计算返回记录数
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
         --拼接分页后的SQL语句
         vc_p_sql :='select * from ( select temp.*, rownum row_id from ('||vc_sql|| 'order by n.CPDM,n.QRRQ DESC,n.GZRQ DESC) temp where rownum <= '|| vn_jsh ||') where row_id >='||vn_qsh;
         po_returncode :='0000';
         po_returnmsg :='投资者高水位信息查询成功！';
         insert into T_FUND_JOB_RUNNING_LOG(JOB_NAME,JOB_RUNNING_LOG) values(v_msg, v_regs);
        --返回结果集
   open po_refcur for vc_p_sql;

    EXCEPTION
    WHEN ve_exception then
        rollback;
         v_msg:='失败'||sqlerrm || sqlcode;
         insert into T_FUND_JOB_RUNNING_LOG(JOB_NAME,JOB_RUNNING_LOG) values(v_msg|| v_regs ,vc_p_sql);
        vc_sql := 'select 1 KHMC,2 CREDIT_NO,3 QMFE,4 QRRQ,5 DWJZ,6 GZRQ,7 YFBZ,8 PRO_NAME,9 KHBH,10 CPDM,11 fundType,12 ptId from dual where 1=2';
        COMMIT;
        open po_refcur for vc_sql;
        RETURN;
    WHEN OTHERS THEN
        ROLLBACK;
         v_msg:='失败'||sqlerrm || sqlcode;
         insert into T_FUND_JOB_RUNNING_LOG(JOB_NAME,JOB_RUNNING_LOG) values(v_msg,vc_p_sql);
         COMMIT;

        vc_sql := 'select 1 KHMC,2 CREDIT_NO,3 QMFE,4 QRRQ,5 DWJZ,6 GZRQ,7 YFBZ,8 PRO_NAME,9 KHBH,10 CPDM,11 fundType,12 ptId from dual where 1=2';
        open po_refcur for vc_sql;
        return;
        commit;
END TGYW_HWLNETVAL;
/


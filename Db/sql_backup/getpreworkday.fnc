CREATE OR REPLACE FUNCTION SMZJ.getPreWorkDay(workday in varchar2)
 RETURN VARCHAR2
 IS
  predaywork varchar2(16);
 BEGIN
  select rq into predaywork from ( select rank() over(order by t.rq desc) as NUMS ,t.rq from  zsta.rlb@ta_dblink  t where t.rq <workday and t.gzr='1' ) where NUMS=1 ;
  RETURN predaywork;
 END;
/


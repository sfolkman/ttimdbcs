
set serveroutput on;

-- create a user
create or replace procedure setuserprivs_createuser
(
	username varchar2,
	userpwd  varchar2
)
as
begin
  declare
  err_num pls_integer;
  err_msg varchar2(256);

  begin
    execute immediate 'create user '||username||' identified by '||userpwd;
    exception
        when others then
	    err_num := SQLCODE;
	    err_msg := substr(SQLERRM, 1, 256);
      	    dbms_output.put_line('setuserprivs createuser error: '||err_num||': '||err_msg);
  end;
end;
/
show errors;


-- revoke all object privileges from revokefrom where owner = sowner
create or replace procedure setuserprivs_revokeobjects
(       revokefrom    varchar2,
	sowner        varchar2
)
as
begin
  declare
  err_num pls_integer;
  err_msg varchar2(256);
  regranted exception;
  pragma exception_init(regranted,-57000);
  cursor rcursor is
  select   grantee, 
           table_name, 
	   privilege 
    from   sys.dba_tab_privs 
   where   owner = sowner;   
  type revokelisttbl is table of rcursor%rowtype;
  revokelist revokelisttbl;

  begin
       open  rcursor;
       fetch rcursor bulk collect into revokelist;
       close rcursor;
       for rndx in 1 .. revokelist.count loop
	 begin
         if revokefrom = revokelist(rndx).grantee then
	 begin
       	    dbms_output.put_line('revoke '||revokelist(rndx).privilege||
	        ' on '||sowner||'.'||revokelist(rndx).table_name||
		' from '|| revokelist(rndx).grantee);
       	    execute immediate 'revoke '||revokelist(rndx).privilege||
	        ' on '||sowner||'.'||revokelist(rndx).table_name||
		' from '|| revokelist(rndx).grantee;
	    exception
	    when others then
	      err_num := SQLCODE;
	      err_msg := substr(SQLERRM, 1, 256);
      	      dbms_output.put_line('revoke error: '||err_num||': '||err_msg);
	 end;
	 end if;
       end;
       end loop;
  end;
end;
/
show errors;


create or replace procedure setuserprivs_readonly
(       grantto       varchar2,
        sowner        varchar2
)
as
begin
   declare
   myobj varchar2(61);
   mytyp varchar2(30);
   err_num pls_integer;
   err_msg varchar2(256);
   regranted exception;
   pragma exception_init(regranted,-57000);
   cursor pcursor is
   select   owner,
            object_name,
            object_type
    from    sys.all_objects
    where   owner = sowner;
   type privlisttbl is table of pcursor%rowtype;
   privlist privlisttbl;

   begin
       setuserprivs_revokeobjects(grantto, sowner);

       -- now grant privs to existing objects
       open  pcursor;
       fetch pcursor bulk collect into privlist;
       close pcursor;
       for indx in 1 .. privlist.count
       loop begin
--         dbms_output.put_line(privlist(indx).owner||'.'||
--	                      privlist(indx).object_name||
--			      ' '||privlist(indx).object_type);
         myobj := privlist(indx).owner||'.'||privlist(indx).object_name;
	 mytyp := privlist(indx).object_type;
	 if mytyp = 'PROCEDURE' then
	    dbms_output.put_line('grant execute on '||myobj||' to '||grantto||'; --type='||mytyp);
	    execute immediate 'grant execute on '||myobj||' to '||grantto;
	 else 
	    dbms_output.put_line('grant select on '||myobj||' to '||grantto||'; --type='||mytyp);
            execute immediate 'grant select on '||myobj||' to '||grantto;
         end if;
	 exception
	    when regranted then
	      null;
	      -- err_num := SQLCODE;
	      -- err_msg := substr(SQLERRM, 1, 256);
      	      -- dbms_output.put_line('regranted error: '||err_msg);
	    when others then
	      err_num := SQLCODE;
	      err_msg := substr(SQLERRM, 1, 256);
      	      dbms_output.put_line(err_num||': '||err_msg);
       end; -- [loop] begin
       end loop;
       -- do this last so user can't login until privs granted
       execute immediate 'grant create session to '||grantto;
       exception
           when regranted then
	      null; -- err_num := SQLCODE; -- expected
           when others then
       	      err_num := SQLCODE;
	      err_msg := substr(SQLERRM, 1, 256);
      	      dbms_output.put_line(err_num||': '||err_msg);
   end;
end;
/
show errors;

create or replace procedure setuserprivs_readwrite
(       grantto       varchar2,
        sowner        varchar2
)
as
begin
   declare
   myobj varchar2(61);
   mytyp varchar2(30);
   err_num pls_integer;
   err_msg varchar2(256);
   regranted exception;
   pragma exception_init(regranted,-57000);
   cursor pcursor is
   select   owner,
            object_name,
            object_type
    from    sys.all_objects
    where   owner = sowner;
   type privlisttbl is table of pcursor%rowtype;
   privlist privlisttbl;


   begin
       setuserprivs_revokeobjects(grantto, sowner);

       -- now grant privs on existing objects
       open  pcursor;
       fetch pcursor bulk collect into privlist;
       close pcursor;

       execute immediate 'revoke all privileges from '||grantto;
       for indx in 1 .. privlist.count
       loop begin
         dbms_output.put_line(privlist(indx).owner||'.'||
	                      privlist(indx).object_name||
			      ' '||privlist(indx).object_type);
         myobj := privlist(indx).owner||'.'||privlist(indx).object_name;
	 mytyp := privlist(indx).object_type;
         dbms_output.put_line('grant all on '||myobj||' to '||grantto||'; --type='||mytyp);
         execute immediate 'grant all on '||myobj||' to '||grantto;
	 case mytyp
	 when 'TABLE' then
           dbms_output.put_line('revoke index,references on '||myobj||' from '||grantto||'; --type='||mytyp);
	   execute immediate 'revoke index,references on '||myobj||' from '||grantto;
         when 'MATERIALIZED VIEW' then
           dbms_output.put_line('revoke index,references on '||myobj||' from '||grantto||'; --type='||mytyp);
	   execute immediate 'revoke index,references on '||myobj||' from '||grantto;
	 else 
	   null; -- err_num := 0; -- do nothing	   
         end case;
	 exception
	    when regranted then
	      err_num := SQLCODE;
	      -- err_msg := substr(SQLERRM, 1, 256);
      	      dbms_output.put_line('regranted error: '||err_num||': '||err_msg);
	    when others then
	      err_num := SQLCODE;
	      err_msg := substr(SQLERRM, 1, 256);
      	      dbms_output.put_line('other: '||err_num||': '||err_msg);
       end; -- [loop] begin
       end loop;
       execute immediate 'grant create session to '||grantto;
       exception
           when regranted then
	      null; -- err_num := SQLCODE; -- expected
           when others then
       	      err_num := SQLCODE;
	      err_msg := substr(SQLERRM, 1, 256);
      	      dbms_output.put_line(err_num||': '||err_msg);
   end;
end;
/
show errors;

create or replace procedure setuserprivs_revokeallprivs
(loser        varchar2)
as
begin
    declare
    err_num pls_integer;
    err_msg varchar2(256);

    begin
       dbms_output.put_line('revoke all privileges from '||loser);
       execute immediate 'revoke all privileges from '||loser;
       exception
	   when others then
	     err_num := SQLCODE;
             err_msg := substr(SQLERRM, 1, 256);
	     dbms_output.put_line('revokeallprivs exception: '||err_num||': '||err_msg);
    end;
end;
/
show errors;

create or replace procedure setuserprivs_allbutadmin
(grantto       varchar2)
as
begin
   declare
   err_num pls_integer;
   err_msg varchar2(256);
   regranted exception;
   pragma exception_init(regranted,-57000);
   cursor pcursor is
   select   name
     from   sys.system_privilege_map;
   type privlisttbl is table of pcursor%rowtype;
   privlist privlisttbl;

   begin
       -- it may be more secure to grant all the privs individually, with create session last.
       -- consider whether public synonym should be special case
       setuserprivs_revokeallprivs(grantto);
       open  pcursor;
       fetch pcursor bulk collect into privlist;
       close pcursor;
       for indx in 1 .. privlist.count
       loop begin
         case  privlist(indx).name
	 -- 'blacklist' privs basically ignored
         when 'ADMIN' then null ;
	 when 'CREATE SESSION' then null ; 
	 when 'CREATE ANY DIRECTORY' then null ; -- not implemented
	 when 'DROP ANY DIRECTORY' then null ; -- not implemented
	 else
           dbms_output.put_line('grant '||privlist(indx).name||' to '||grantto);
 	   execute immediate 'grant '||privlist(indx).name||' to '||grantto;
	 end case; 
	 exception
	   when others then
	     err_num := SQLCODE;
             err_msg := substr(SQLERRM, 1, 256);
	     dbms_output.put_line('allbutadmin exception: '||err_num||': '||err_msg);
       end; -- loop begin
       end loop;
       dbms_output.put_line('grant create session to '||grantto);
       execute immediate 'grant create session to '||grantto;
       exception
           when regranted then
	      err_num := SQLCODE; -- expected
           when others then
       	      err_num := SQLCODE; -- expected
	      -- err_msg := substr(SQLERRM, 1, 256);
      	      -- dbms_output.put_line(err_num||': '||err_msg);
   end;
end;
/
show errors;

begin
setuserprivs_readwrite('NC','HESTIA');
end;
/

begin
setuserprivs_readonly('NB9','HESTIA');
end;
/

begin
setuserprivs_allbutadmin('TEST');
end;
/

begin
setuserprivs_createuser('DOGUS','M32T8S');
end;
/

begin
setuserprivs_allbutadmin('DOGUS');
end;
/

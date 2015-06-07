delimiter ;;
drop procedure if exists readkey;;
create procedure readkey(in _key longtext)
begin
	set tx_isolation='READ-UNCOMMITTED';
	set @key := _key, @parent := 1, @id = null;

	while length(@key) > 0 do
		set @part := substring(@key, 1, instr(@key, '.'));
		set @key = replace(@key, @part, '');
        set @part := replace(@part, '.', '');
        if length(@part) = 0 then
			set @part = @key;
            set @key = '';
        end if;
        set @id := null;
        select id into @id
        from okeys 
        where parent = @parent
			and csname = crc32(@part) 
            and name = @part;
        set @parent := @id;
	end while;
    
    drop table if exists res;
    create temporary table res (id bigint unsigned primary key) engine=memory;
    drop table if exists res2;
    create temporary table res2 (id bigint unsigned primary key) engine=memory;
    drop table if exists res3;
    create temporary table res3 (id bigint unsigned primary key) engine=memory;

    set sql_safe_updates := 0;

	insert res
    select id
    from okeys
    where @id in (id, parent);
        
    while row_count() > 0 do
		set @oldrows := @rows;
        
        delete from res2;
        insert res2
        select id
        from res;

        delete from res3;
        insert res3
        select id
        from res;
        
        insert res
        select k.id
        from okeys k
        inner join res2 r
			on r.id = k.parent
		where k.id not in (
			select id
            from res3
		);
    end while;

    set sql_safe_updates := 1;
    
    select id, parent, name, type, number, string
    from okeys
    where id in (
		select id
        from res
	);

    drop table if exists res;
    drop table if exists res2;
    drop table if exists res3;
end
;;


delimiter ;
call readkey('foo');


drop table if exists okeys;
create table if not exists okeys (
	id bigint unsigned primary key auto_increment,
	parent bigint unsigned, 
	name nvarchar(255) not null,
	csname integer unsigned not null,
	type enum('NaN','Infinity','-Infinity','true','false','number','string','object','array', 'null'), 
	number float,
	string longtext
);

alter table okeys add foreign key (parent) references okeys(id) on delete cascade;

-- create index ix_okeys_parent_csname on okeys(parent, csname);
create index ix_okeys_id_parent on okeys(id, parent);
create unique index ix_okeys_parent_name on okeys(parent, name(255));

set @parent = null, @name = 'root', @type = 'object', @number = null, @string = null;
insert okeys (parent, name, csname, type, number, string)
values (@parent, @name, crc32(@name), @type, @number, @string);

delimiter ;;
drop procedure if exists readkey;;
create procedure readkey(in _key longtext)
begin
	set tx_isolation='READ-COMMITTED';
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
            and k.type != 'undefined'
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

drop procedure if exists writekey;;
create procedure writekey(in _key longtext, type nvarchar(9), number float, string longtext)
begin
	set tx_isolation='READ-COMMITTED';
	set @key := _key, @parent := 1, @id = 0, @type = type, @number = number, @string = string;

	while length(@key) > 0 do
		set @part := substring(@key, 1, instr(@key, '.'));
		set @key = replace(@key, @part, '');
        set @part := replace(@part, '.', '');
        if length(@part) = 0 then
			set @part = @key;
            set @key = '';
        end if;
        set @id := 0;
        while @id = 0 do 
			select id into @id
			from okeys 
			where parent = @parent
				and csname = crc32(@part) 
				and name = @part;
			if @id = 0 then
				insert ignore okeys(parent, name, csname, type, number, string)
				values (@parent, @part, crc32(@part), 'object', null, null);
				set @id := last_insert_id();
			end if;
		end while;
        set @parent := @id;
	end while;
  
	update okeys
    set type = 'undefined'
    where parent = @id;

	update okeys
    set type = @type, number = @number, string = @string
    where id = @id;
end
;;

drop procedure if exists search;;
create procedure search(in _key nvarchar(255), in _string longtext, in _number float) begin
	drop table if exists res;
	create temporary table res (parent bigint unsigned, name nvarchar(1024) not null) engine=memory;

	set sql_safe_updates := 0;

	insert res
	select parent, name
	from okeys
	where csname = crc32(_key)
		and name = _key
		and (
			string = _string 
            or number = _number
		);

	while row_count() > 0 do
		update res r
		inner join okeys o
			on o.id = r.parent
		set r.name = concat(o.name,'.', r.name), r.parent = o.parent
		where r.parent != 1;
	end while;

	set sql_safe_updates := 1;
		
	select name
	from res;

	drop table if exists res;
end;;

delimiter ;

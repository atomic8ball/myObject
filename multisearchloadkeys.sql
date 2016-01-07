delimiter ;;
drop procedure if exists multisearchload;;
create procedure multisearchload(in _keys longtext, in _string longtext, in _number float, in _depth tinyint) begin
	drop table if exists searchkeys;
	create temporary table searchkeys(_key nvarchar(128) not null, csname integer unsigned not null) engine = memory;
	drop table if exists searchres;
	create temporary table searchres(parent bigint unsigned, name nvarchar(1024) not null) engine = memory;
	drop table if exists alphasearchres;
	create temporary table alphasearchres(name nvarchar(1024) not null) engine = memory;
	drop table if exists loadkeys;
	create temporary table loadkeys(loadkey nvarchar(1024) not null) engine = memory;
	
	set sql_safe_updates := 0;
	
	set @keys := _keys;
	while length(@keys) > 0 do
		set @key := substring(@keys, 1, instr(@keys, '|'));
		set @keys = replace(@keys, @key, '');
		set @key := replace(@key, '|', '');
        if length(@key) = 0 then
			set @key = @keys;
            set @keys = '';
        end if;
		insert searchkeys
		values(@key, crc32(@key));
	end while;
	
    insert searchres
    select parent, name
    from okeys o
    inner join searchkeys s
		on s.csname = o.csname
		and s._key = o.name
	where o.string = _string
		or o.number = _number;
		
	while row_count() > 0 do
		update searchres r
		inner join okeys o
			on o.id = r.parent
		set r.name = concat(o.name,'.', r.name), r.parent = o.parent
		where r.parent != 1;
	end while;
	
	insert alphasearchres
	select name
	from searchres
	order by name;
    
    select name
    from alphasearchres;
    
    if _depth != 0 then
		set @name = 'true';
    
		while length(@name) > 0 do
			set @name = '';
			set @depth = _depth;
			select name into @name
			from alphasearchres
			limit 1;
			if @depth < 0 then
				set @length = 0, @lengthtest = @name, @lengthtestpart = '';
				while length(@lengthtest) > 0 do
					set @lengthtestpart = substring(@lengthtest, 1, instr(@lengthtest, '.'));
					set @lengthtest = replace(@lengthtest, @lengthtestpart, '');
					set @lengthtestpart = replace(@lengthtestpart, '.', '');
					if length(@lengthtestpart) = 0 then
						set @lengthtestpart = @lengthtest;
						set @lengthtest = '';
					end if;
					set @length = @length + 1;
				end while;
				set @depth = @length + _depth + 1;
			end if;
            set @i = 0, @tempkey = @name, @loadkey = '';
            while @i < @depth and length(@tempkey) > 0 do
				set @keypart = substring(@tempkey, 1, instr(@tempkey, '.'));
				set @tempkey = replace(@tempkey, @keypart, '');
				set @keypart = replace(@keypart, '.', '');
				if length(@keypart) = 0 then
					set @keypart = @tempkey;
					set @tempkey = '';
				end if;
				if length(@loadkey) > 0 then
					set @loadkey = concat(@loadkey, '.', @keypart);
				else
					set @loadkey = @keypart;
				end if;
                set @i = @i + 1;
            end while;
            if length(@loadkey) > 0 then
				insert loadkeys
				value(@loadkey);
 			end if;
			set sql_safe_updates := 0;
			delete from alphasearchres
			where name = @name;
		end while;
		
		select loadkey
		from loadkeys;
		
		set @loadkey = 'dummy';
		while length(@loadkey) > 0 do
			set @loadkey = '';
			select loadkey into @loadkey
			from loadkeys
			limit 1;
			if length(@loadkey) > 0 then
				call readkey(@loadkey);
			end if;
			set sql_safe_updates := 0;
			delete from loadkeys
			where loadkey = @loadkey;
		end while;
    end if;
    
    set sql_safe_updates := 1;
    
    drop table if exists searchkeys;
    drop table if exists searchres;
    drop table if exists alphasearchres;
    drop table if exists loadkeys;
    
end;;
delimiter ;

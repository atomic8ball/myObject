drop table okeys;

create table if not exists okeys (
	id bigint unsigned primary key auto_increment,
	parent bigint unsigned, 
	name nvarchar(255) not null,
	csname integer unsigned not null,
	type nvarchar(9) not null,
	number float,
	string longtext
);

alter table okeys add foreign key (parent) references okeys(id) on delete cascade;

create index ix_okeys_parent_csname on okeys(parent, csname);
create index ix_okeys_id_parent on okeys(id, parent);
create unique index ix_okeys_parent_name on okeys(parent, name(255));

set @parent = null, @name = 'root', @type = 'object', @number = null, @string = null;
insert okeys (parent, name, csname, type, number, string)
values (@parent, @name, crc32(@name), @type, @number, @string);
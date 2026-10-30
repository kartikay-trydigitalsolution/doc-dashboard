-- public.users definition

-- Drop table

-- DROP TABLE public.users;

CREATE TABLE public.users (
	id uuid NOT NULL,
	sub uuid NULL,
	username varchar NULL,
	onboarded bool DEFAULT false NULL,
	status public."user_status" NULL,
	date_of_birth date NULL,
	shim_score int2 NULL,
	weight numeric(5, 2) DEFAULT NULL::numeric NULL,
	weight_unit public.weight_unit NULL,
	height numeric(5, 2) DEFAULT NULL::numeric NULL,
	height_unit public.height_unit NULL,
	bmi numeric(5, 2) DEFAULT NULL::numeric NULL,
	diabetes bool NULL,
	diabetes_comments varchar NULL,
	hypertension bool NULL,
	hypertension_comments varchar NULL,
	tobacco bool NULL,
	tobacco_comments varchar NULL,
	alcohol bool NULL,
	alcohol_comments varchar NULL,
	prescription_drugs bool NULL,
	prescription_drugs_comments varchar NULL,
	recreational_drugs bool NULL,
	recreational_drugs_comments varchar NULL,
	personal_comments varchar NULL,
	best_score numeric(4, 2) DEFAULT NULL::numeric NULL,
	best_score_record_id uuid NULL,
	best_score_record_started_at timestamptz NULL,
	last_open_app_at date NULL,
	last_upload_at date NULL,
	last_upload_record_id uuid NULL,
	last_upload_cluster_count int2 NULL,
	statistics_uploads_count int4 NULL,
	deleted_at timestamp NULL,
	last_upload_timestamp_at timestamp NULL,
	enrolled bool DEFAULT false NULL,
	uf_climax bool DEFAULT false NULL,
	res_id uuid DEFAULT uuid_generate_v7() NULL,
	CONSTRAINT users_pkey PRIMARY KEY (id)
);
CREATE INDEX users_last_open_app_at_idx ON public.users USING btree (last_open_app_at);
CREATE INDEX users_last_upload_at_idx ON public.users USING btree (last_upload_at);
CREATE INDEX users_last_upload_timestamp_at_idx ON public.users USING btree (last_upload_timestamp_at);




-- public.records definition

-- Drop table

-- DROP TABLE public.records;

CREATE TABLE public.records (
	id uuid NOT NULL,
	"userId" uuid NULL,
	started_at timestamptz NULL,
	started_at_unix_timestamp int8 NULL,
	"timeZoneOffsetMinutes" int2 NULL,
	duration int4 NULL,
	sex_count int2 NULL,
	sex_rating int2 NULL,
	recreational_drugs bool NULL,
	slept bool DEFAULT false NULL,
	solo_count int2 NULL,
	consumed_alcohol_units int2 NULL,
	inserted_at_unix_timestamp int8 NULL,
	score numeric NULL,
	fw_version int2 NULL,
	app_version varchar NULL,
	preprocess_sql_inserted_at timestamp NULL,
	"_replicated" bool NULL,
	clusters_marked_by_user int2 NULL,
	sid bigserial NOT NULL,
	deleted_at timestamp NULL,
	recording_area numeric NULL,
	personal_comments varchar(262144) DEFAULT NULL::character varying NULL,
	prescription_drugs_array jsonb NULL,
	CONSTRAINT records_id_idx UNIQUE (id),
	CONSTRAINT records_pkey PRIMARY KEY (sid)
);
CREATE INDEX "records_userId_started_at_idx" ON public.records USING btree ("userId", started_at);


-- public.performance_data definition

-- Drop table

-- DROP TABLE public.performance_data;

CREATE TABLE public.performance_data (
	user_id uuid NOT NULL,
	updated_at timestamp NOT NULL,
	erectile_fitness_score numeric(4, 2) DEFAULT NULL::numeric NULL,
	avg_firmness_score numeric(4, 2) DEFAULT NULL::numeric NULL,
	avg_nocturnal_firmness_score numeric(4, 2) DEFAULT NULL::numeric NULL,
	record_count int2 NULL,
	avg_erections_per_week numeric NULL,
	avg_duration numeric NULL,
	total_erections int2 NULL,
	solo_sex_count int2 NULL,
	nocturnal_count int2 NULL,
	avg_nocturnal_erections_per_week numeric NULL,
	avg_nocturnal_erections numeric(4, 2) DEFAULT NULL::numeric NULL,
	avg_firmness_score__nocturnal numeric(4, 2) NULL,
	avg_firmness_score__sex_solo numeric(4, 2) NULL,
	avg_total_duration__nocturnal int4 NULL,
	avg_total_duration__sex_solo int4 NULL,
	avg_count__nocturnal numeric(4, 2) NULL,
	avg_count__sex_solo numeric(4, 2) DEFAULT NULL::numeric NULL,
	duration_of_sex_solo_erections_in_seconds int4 NULL,
	duration_of_sleep_erections_in_seconds int4 NULL,
	"performance_data_trigger" public."performance_data_trigger" NULL,
	record_sid int8 NULL,
	CONSTRAINT performance_data_pkey PRIMARY KEY (user_id, updated_at),
	CONSTRAINT performance_data_record_sid_fkey FOREIGN KEY (record_sid) REFERENCES public.records(sid)
);


-- public."recordsResults" definition

-- Drop table

-- DROP TABLE public."recordsResults";

CREATE TABLE public."recordsResults" (
	"cluster" int2 NOT NULL,
	"start" timestamp NULL,
	"end" timestamp NULL,
	global_best_score numeric NULL,
	firmness numeric NULL,
	erection_class public.erection_class NULL,
	record_sid int8 NOT NULL,
	CONSTRAINT "recordsResults_pkey" PRIMARY KEY (record_sid, cluster),
	CONSTRAINT "FK_recordsResults_records_by_sid" FOREIGN KEY (record_sid) REFERENCES public.records(sid) ON DELETE CASCADE
);



-- DROP TYPE public.height_unit;

CREATE TYPE public.height_unit AS ENUM (
	'CM',
	'IN');

-- DROP TYPE public."user_status";

CREATE TYPE public."user_status" AS ENUM (
	'active',
	'deleted');

-- DROP TYPE public.weight_unit;

CREATE TYPE public.weight_unit AS ENUM (
	'KG',
	'LB');


-- DROP TYPE public.erection_class;

CREATE TYPE public.erection_class AS ENUM (
	'SEX',
	'SOLO',
	'SLEEP',
	'UNKNOWN',
	'FALSE',
	'MORNING',
	'OTHER');

-- DROP TYPE public."performance_data_trigger";

CREATE TYPE public."performance_data_trigger" AS ENUM (
	'post_insert_record',
	'refresh',
	'sync_record');
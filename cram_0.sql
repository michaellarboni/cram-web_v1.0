--
-- PostgreSQL database dump
--

SET statement_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;

--
-- Name: plpgsql; Type: EXTENSION; Schema: -; Owner: 
--

CREATE EXTENSION IF NOT EXISTS plpgsql WITH SCHEMA pg_catalog;


--
-- Name: EXTENSION plpgsql; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION plpgsql IS 'PL/pgSQL procedural language';


SET search_path = public, pg_catalog;

--
-- Name: createuserversion(); Type: FUNCTION; Schema: public; Owner: cram
--

CREATE FUNCTION createuserversion() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
begin
  insert into userversion values(new.userrid, 0) ;
  return null;
end;
$$;


ALTER FUNCTION public.createuserversion() OWNER TO cram;

--
-- Name: find_main_project(integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION find_main_project(integer) RETURNS integer
    LANGUAGE plpgsql
    AS $_$
declare 
   prj  integer;
   prjp integer;
begin
   select projectid,projectparentid into prj,prjp from project where projectid=$1;
   if prj is null then return NULL;
   end if;
   if prjp is null then return prj;
   end if;
   return find_main_project(prjp);
end ; 
$_$;


ALTER FUNCTION public.find_main_project(integer) OWNER TO postgres;

--
-- Name: find_main_project(integer, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION find_main_project(integer, integer) RETURNS integer
    LANGUAGE plpgsql
    AS $_$
declare 
   i_userrid ALIAS FOR $1 ;
   i_projectid  ALIAS FOR $2;
   prj  integer;
   prjp integer;
   usr  integer;
begin
   select P.projectid, P.projectparentid, M.userrid 
   into prj, prjp, usr
   from project as P
   left join manager as M on (P.projectid = M.projectid and userrid = i_userrid) 
   where P.projectid=i_projectid;
   --
   if prj is null then return NULL;
   end if;
   if usr is not null then return prj;
   end if;
   if prjp is null then return NULL;
   end if;
   return find_main_project(i_userrid, prjp);
end ; 
$_$;


ALTER FUNCTION public.find_main_project(integer, integer) OWNER TO postgres;

--
-- Name: full_projectname(integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION full_projectname(integer) RETURNS character varying
    LANGUAGE plpgsql
    AS $_$
declare 
   prj  integer;
   prjp integer;
   prjname varchar;
begin
   select projectid,projectparentid,projectname
   into prj,prjp,prjname from project where projectid=$1;
   if prj is null then return '';
   end if;
   if prjp is null then return prjname;
   end if;
   return full_projectname(prjp)||'.'||prjname;
end ; 
$_$;


ALTER FUNCTION public.full_projectname(integer) OWNER TO postgres;

--
-- Name: isparent(integer, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION isparent(integer, integer) RETURNS boolean
    LANGUAGE plpgsql
    AS $_$
declare 
   prjp integer;
begin
   select projectparentid into prjp from project where projectid=$2;
   if $2 = $1 then return true;
   end if;
   if prjp = $1 then return true;
   end if;
   if prjp is null then return false;
   end if;
   return isparent($1, prjp);
end ; 
$_$;


ALTER FUNCTION public.isparent(integer, integer) OWNER TO postgres;

--
-- Name: removemanagerproject(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION removemanagerproject() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
begin
  delete from manager where projectid=old.projectid ;
  return old;
end;
$$;


ALTER FUNCTION public.removemanagerproject() OWNER TO postgres;

--
-- Name: upd_project(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION upd_project() RETURNS void
    LANGUAGE plpgsql
    AS $$
declare 
	id_prj integer;
	id_prj_p integer;
	prj_name varchar;
	prj_p_name varchar;
	new_id_prj_p integer;
	i integer;
begin
    for id_prj, id_prj_p, prj_name in
        select projectid, projectparentid,  projectname 
        from project 
        where projectname like '%.%'
    loop
        i := 1;
        new_id_prj_p := 0;
        
        while (true) 
        loop
            prj_p_name := split_part( substring(prj_name from '#"%#".%' for '#'), '.', i );
            if prj_p_name = '' then EXIT ;
            end if;
            
            select projectid into id_prj_p
            from project 
            where projectname= prj_p_name;
            
            if id_prj_p is null then
                insert into project(projectname) values (prj_p_name) 
                returning projectid into id_prj_p;
            end if;
            
            if i = 1 then 
               new_id_prj_p := id_prj_p;
            elsif i > 1 then
                update project set projectparentid= new_id_prj_p where projectid = id_prj_p;
                new_id_prj_p := id_prj_p;
            end if;
            i := i + 1 ; 
        end loop;
        update project set 
            projectparentid = new_id_prj_p, 
            projectname = substring(prj_name from '%.#"%#"' for '#') 
        where projectid = id_prj;
    end loop;      
end;
$$;


ALTER FUNCTION public.upd_project() OWNER TO postgres;

SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: activity; Type: TABLE; Schema: public; Owner: cram; Tablespace: 
--

CREATE TABLE activity (
    activityid integer NOT NULL,
    activityname character varying(128) NOT NULL
);


ALTER TABLE public.activity OWNER TO cram;

--
-- Name: activity_activityid_seq; Type: SEQUENCE; Schema: public; Owner: cram
--

CREATE SEQUENCE activity_activityid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.activity_activityid_seq OWNER TO cram;

--
-- Name: activity_activityid_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: cram
--

ALTER SEQUENCE activity_activityid_seq OWNED BY activity.activityid;


--
-- Name: activityuser; Type: TABLE; Schema: public; Owner: cram; Tablespace: 
--

CREATE TABLE activityuser (
    userrid integer NOT NULL,
    activityid integer NOT NULL
);


ALTER TABLE public.activityuser OWNER TO cram;

--
-- Name: cramuser; Type: TABLE; Schema: public; Owner: cram; Tablespace: 
--

CREATE TABLE cramuser (
    userrid integer NOT NULL,
    username character varying(128) NOT NULL,
    userpwd character varying(128) NOT NULL,
    userstatut character varying(20) NOT NULL,
    userdatestatut date DEFAULT ('now'::text)::date NOT NULL,
    useradmin boolean DEFAULT false NOT NULL,
    userstartdate date DEFAULT ('now'::text)::date NOT NULL,
    usersynchrodate date
);


ALTER TABLE public.cramuser OWNER TO cram;

--
-- Name: cramuser_userrid_seq; Type: SEQUENCE; Schema: public; Owner: cram
--

CREATE SEQUENCE cramuser_userrid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.cramuser_userrid_seq OWNER TO cram;

--
-- Name: cramuser_userrid_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: cram
--

ALTER SEQUENCE cramuser_userrid_seq OWNED BY cramuser.userrid;


--
-- Name: manager; Type: TABLE; Schema: public; Owner: cram; Tablespace: 
--

CREATE TABLE manager (
    userrid integer NOT NULL,
    projectid integer NOT NULL
);


ALTER TABLE public.manager OWNER TO cram;

--
-- Name: project; Type: TABLE; Schema: public; Owner: cram; Tablespace: 
--

CREATE TABLE project (
    projectid integer NOT NULL,
    projectname character varying(128) NOT NULL,
    projectenddate date,
    projectparentid integer
);


ALTER TABLE public.project OWNER TO cram;

--
-- Name: project_projectid_seq; Type: SEQUENCE; Schema: public; Owner: cram
--

CREATE SEQUENCE project_projectid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.project_projectid_seq OWNER TO cram;

--
-- Name: project_projectid_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: cram
--

ALTER SEQUENCE project_projectid_seq OWNED BY project.projectid;


--
-- Name: projectuser; Type: TABLE; Schema: public; Owner: cram; Tablespace: 
--

CREATE TABLE projectuser (
    userrid integer NOT NULL,
    projectid integer NOT NULL
);


ALTER TABLE public.projectuser OWNER TO cram;

--
-- Name: task; Type: TABLE; Schema: public; Owner: cram; Tablespace: 
--

CREATE TABLE task (
    activityid integer,
    projectid integer,
    userrid integer NOT NULL,
    taskdate date NOT NULL,
    taskam character(2) NOT NULL,
    taskdayoff boolean DEFAULT false NOT NULL,
    taskcomment character varying(500)
);


ALTER TABLE public.task OWNER TO cram;

--
-- Name: team; Type: TABLE; Schema: public; Owner: cram; Tablespace: 
--

CREATE TABLE team (
    teamid integer NOT NULL,
    leader integer NOT NULL,
    label character varying(30)
);


ALTER TABLE public.team OWNER TO cram;

--
-- Name: team_teamid_seq; Type: SEQUENCE; Schema: public; Owner: cram
--

CREATE SEQUENCE team_teamid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.team_teamid_seq OWNER TO cram;

--
-- Name: team_teamid_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: cram
--

ALTER SEQUENCE team_teamid_seq OWNED BY team.teamid;


--
-- Name: teamuser; Type: TABLE; Schema: public; Owner: cram; Tablespace: 
--

CREATE TABLE teamuser (
    teamid integer NOT NULL,
    userrid integer NOT NULL
);


ALTER TABLE public.teamuser OWNER TO cram;

--
-- Name: userversion; Type: TABLE; Schema: public; Owner: cram; Tablespace: 
--

CREATE TABLE userversion (
    userrid integer NOT NULL,
    centralversion integer NOT NULL
);


ALTER TABLE public.userversion OWNER TO cram;

--
-- Name: version; Type: TABLE; Schema: public; Owner: cram; Tablespace: 
--

CREATE TABLE version (
    tablename character varying(50) NOT NULL,
    centralversion integer NOT NULL
);


ALTER TABLE public.version OWNER TO cram;

--
-- Name: versionappli; Type: TABLE; Schema: public; Owner: cram; Tablespace: 
--

CREATE TABLE versionappli (
    numversion integer NOT NULL,
    dateversion date NOT NULL,
    compatible boolean NOT NULL,
    message character varying,
    version character varying DEFAULT '0.3'::character varying NOT NULL
);


ALTER TABLE public.versionappli OWNER TO cram;

--
-- Name: activityid; Type: DEFAULT; Schema: public; Owner: cram
--

ALTER TABLE ONLY activity ALTER COLUMN activityid SET DEFAULT nextval('activity_activityid_seq'::regclass);


--
-- Name: userrid; Type: DEFAULT; Schema: public; Owner: cram
--

ALTER TABLE ONLY cramuser ALTER COLUMN userrid SET DEFAULT nextval('cramuser_userrid_seq'::regclass);


--
-- Name: projectid; Type: DEFAULT; Schema: public; Owner: cram
--

ALTER TABLE ONLY project ALTER COLUMN projectid SET DEFAULT nextval('project_projectid_seq'::regclass);


--
-- Name: teamid; Type: DEFAULT; Schema: public; Owner: cram
--

ALTER TABLE ONLY team ALTER COLUMN teamid SET DEFAULT nextval('team_teamid_seq'::regclass);


--
-- Data for Name: activity; Type: TABLE DATA; Schema: public; Owner: cram
--

COPY activity (activityid, activityname) FROM stdin;
74	Admin. support
68	AIT
86	AIT Contrôle-Commande
87	Ait Electronique/Détecteurs
88	AIT instrument
89	AIT instrument & étalonnages
90	AIT Mécanique
91	AIT Optique
92	AIT Vibrations
93	AIT Vide/Thermique
75	Architecte Mécano-thermique
94	Archivage
76	Assistance Projet
95	Calculs FEM
77	Chef de Projet
78	Conception & Calcul optique
96	Conception Ctrl/électronique instrument
97	Conception/Design AIT
98	Conception/Design mécanique
99	Conception/Design Vide/Theermique
79	Contrôle Projet
100	Contrôle/Métrologie mécanique
101	Contrôle/Métrologie optique
58	Documentation
102	Dépouillement des données
103	Fabrication mécanique
104	Fabrication optique
55	INFO.Analysis
70	INFO.Data Management
56	INFO.Deployment
69	INFO.Design
57	INFO.Development
63	INFO.Infrastructure
71	INFO.Maintenance
73	INFO.Simulation
61	INFO.Testing
80	Ingénieur AQ/AP
81	Ingénieur Système
82	Interfaces
66	Management
67	Meeting
105	Métrologie composants & contrôle
59	Other
72	Research
83	Responsable AIT
84	Responsable AQ/AP
85	Responsable Produit
106	Réalisation contrôle instrument
60	Teaching
62	Training
107	TTT
\.


--
-- Name: activity_activityid_seq; Type: SEQUENCE SET; Schema: public; Owner: cram
--

SELECT pg_catalog.setval('activity_activityid_seq', 107, true);


--
-- Data for Name: activityuser; Type: TABLE DATA; Schema: public; Owner: cram
--

COPY activityuser (userrid, activityid) FROM stdin;
16	55
16	57
16	73
16	61
16	72
26	81
26	77
19	58
19	55
19	70
19	56
19	69
19	57
19	63
19	71
28	55
28	70
28	57
28	61
28	67
28	62
8	58
8	70
8	56
8	57
8	63
8	71
27	68
27	58
27	66
8	61
8	67
8	59
8	62
29	68
19	61
19	67
19	59
19	60
19	62
29	58
29	55
29	70
29	56
29	69
29	57
29	63
29	71
13	70
13	57
13	58
24	58
24	55
24	70
24	69
29	73
29	61
26	66
26	67
26	59
23	58
23	57
23	71
23	61
24	57
24	71
24	73
24	61
24	66
24	67
24	59
24	72
24	60
24	62
30	58
30	102
30	55
30	70
30	56
30	69
30	57
30	73
30	67
30	59
30	72
30	62
34	57
20	58
20	55
20	70
20	56
20	57
20	63
20	71
20	61
22	58
22	55
22	70
22	56
22	69
22	57
22	63
9	58
9	55
9	57
22	71
22	61
22	66
22	67
22	59
22	72
22	60
17	58
17	55
17	70
17	56
17	57
17	63
17	71
17	61
6	68
6	58
6	55
6	70
6	56
6	69
6	57
6	63
6	71
6	61
6	66
6	67
6	59
6	72
6	60
6	62
9	67
18	58
18	55
18	56
18	57
18	71
18	61
18	66
18	67
18	59
18	72
17	67
17	59
20	67
20	59
20	60
10	77
18	60
18	62
10	58
10	55
10	70
10	56
10	57
10	63
10	71
25	68
25	58
10	73
10	81
10	67
25	66
25	67
25	59
25	72
25	60
25	62
22	62
20	62
33	57
10	60
32	55
32	56
32	69
32	57
32	61
32	67
5	58
5	55
5	70
5	56
5	69
15	55
15	69
15	57
15	73
14	58
14	55
14	70
14	56
14	69
14	57
14	71
14	61
14	66
14	67
14	59
14	60
35	55
15	67
15	59
15	72
15	62
35	57
35	71
5	57
5	63
5	71
5	61
5	67
5	59
5	72
5	62
31	55
31	57
31	67
31	59
31	72
31	60
1	56
1	61
11	58
11	55
11	70
11	56
11	69
11	57
11	63
11	71
11	61
11	66
11	67
4	58
4	55
4	70
4	56
4	69
4	57
4	63
4	71
4	61
4	66
4	67
4	59
4	72
4	60
4	62
11	59
11	62
\.


--
-- Data for Name: cramuser; Type: TABLE DATA; Schema: public; Owner: cram
--

COPY cramuser (userrid, username, userpwd, userstatut, userdatestatut, useradmin, userstartdate, usersynchrodate) FROM stdin;
24	dvibert	0ab02ffd9a9a8828f47938e0095298b5	valid	2012-12-05	f	2012-11-01	2013-04-29
27	egrassi	35d8a4d3349bbb6a59dc147921153545	valid	2013-02-04	f	2013-02-04	2013-02-04
2	emartins	b19340b462c0e22509ebc270d4ccd25f	valid	2012-10-01	f	2012-10-01	2012-11-05
1	emds	0d3dda60cbf9718c31d6c332b736c914	valid	2012-11-05	f	2013-04-03	2015-04-03
16	epagot	3185f8f292314d765d11ed2fe9739961	valid	2012-10-25	f	2012-10-25	2013-07-05
19	fagneray	556526aec2525bbcf248ef3a8381ad30	valid	2012-10-26	f	2012-10-01	2014-04-07
9	gleleu	dc4aa651b6284c1fe2deaf70409f3e75	valid	2011-09-01	f	2012-10-01	2013-05-14
34	jbardagi	77e175cd9eb8a001246ef021a7145e4d	valid	2014-04-07	f	2013-11-01	2014-04-07
10	jclamber	783c5e8605defac878453dddd3d90f18	valid	2012-10-10	f	2012-10-10	2013-07-23
6	napostolakos	00f80b9c1bcf643df8127f543b317970	valid	2012-10-05	f	2012-10-01	2013-04-29
29	obenbella	a25752e966026a8cc6adea6f4fc94d0a	valid	2013-05-21	f	2013-05-21	2013-06-26
30	pmege	2596802134ce9bce9bb8df0af99869aa	valid	2013-10-04	f	2013-09-02	2013-10-07
14	pychabau	2f1c66932f0e534a5d79e14e4e586627	valid	2012-10-23	f	2012-10-23	2014-08-18
13	sconseil	1633c933967cda15ffb4229e300595f3	valid	2012-10-23	f	2012-11-01	2013-01-16
20	sgimenez	5e71715b1a35a21f6d58e22c97ca266d	valid	2012-10-26	f	2012-10-15	2014-06-06
15	srodionov	dd0f131dee88629b406762c08800ab1f	valid	2012-10-25	f	2012-10-25	2015-01-26
11	jcmeunie	b422e330dc5c1e9b0d2508fa108538f0	valid	2012-09-12	t	2012-09-12	2015-07-24
8	yroehlly	1f76d44db361252f7fdceaf1dd6decc6	valid	2012-10-08	f	2012-10-01	2015-07-24
5	tfenouillet	458dd59987ae84fe28dd768bb2d06ca9	valid	2012-10-09	f	2012-10-09	2015-08-18
4	csurace	0e7f53d3c431d0ef24091518385bee73	valid	2012-10-01	f	2012-10-01	2015-05-28
7	vlebrun	845f4746ae0a2ea614c7a0f0b1937623	valid	2012-10-09	f	2012-10-09	\N
31	ejullo	1fc84c2394e30232c32d3ae3ea2a288f	valid	2013-10-14	f	2013-10-01	2015-07-06
21	admin	0e7f53d3c431d0ef24091518385bee73	valid	2012-11-27	t	2012-11-27	\N
32	aavdjian	50abc6995754add220524ea6b7175023	valid	2014-01-24	f	2014-01-13	2014-01-28
35	agross	cd8c6ca0d4d126d03fffd361ebb270bb	valid	2014-04-09	f	2014-04-09	2014-08-29
17	bboclet	edc01499f3267142db91c1560e083779	valid	2012-10-25	f	2012-10-25	2014-04-04
22	cmoreau	7649d09e38f820b9370e9ff702b1e1f5	valid	2012-12-04	f	2012-11-01	2014-04-08
23	cpeillon	be2ab74b9e6aa92b87cc6af54597ae7d	valid	2012-12-04	f	2012-12-04	2014-04-08
25	crossin	7f6ee317e071c191525962c7d8fed9bd	valid	2013-01-18	f	2013-01-01	2013-06-07
33	cvidal	43376067ae5abc96dbd97b76de8ee3b4	valid	2014-04-07	f	2014-01-01	2014-04-07
18	dbeniell	3f792a0338fd5c626e40410db9de17de	valid	2012-10-25	f	2012-10-01	2013-05-16
28	dbrevot	c7735dd50e0b566190da692ab31b34e0	valid	2013-04-25	f	2013-04-01	2013-07-05
26	dlemigna	434e605e99ff13a76f9d49e06eb4f488	valid	2013-02-02	f	2013-02-01	2013-02-04
\.


--
-- Name: cramuser_userrid_seq; Type: SEQUENCE SET; Schema: public; Owner: cram
--

SELECT pg_catalog.setval('cramuser_userrid_seq', 35, true);


--
-- Data for Name: manager; Type: TABLE DATA; Schema: public; Owner: cram
--

COPY manager (userrid, projectid) FROM stdin;
4	96
22	131
22	127
4	145
24	138
11	133
11	97
27	130
11	67
14	67
4	63
11	63
4	64
11	64
4	65
4	78
4	79
4	92
4	80
4	81
4	82
4	83
22	136
26	68
11	143
4	70
18	99
26	85
4	89
25	123
26	94
4	144
11	144
26	105
4	88
11	137
22	135
11	74
4	75
22	132
\.


--
-- Data for Name: project; Type: TABLE DATA; Schema: public; Owner: cram
--

COPY project (projectid, projectname, projectenddate, projectparentid) FROM stdin;
96	AMADEUS	\N	\N
131	ANIS	2015-04-01	\N
127	BddP	\N	\N
145	BigData	\N	\N
138	BINGO	\N	\N
128	CFHTLS	\N	\N
133	CHEOPS	\N	\N
97	CIGALE	\N	\N
125	CNRS	\N	\N
130	COL	\N	\N
90	Conferences	\N	\N
67	CoRoT	\N	\N
66	COSMOS	\N	\N
63	CRAM	\N	\N
106	DynamiqueGalaxies	\N	\N
129	ERC-Early	\N	\N
64	ETC-42	\N	\N
103	EUCLID	\N	\N
91	NISP	\N	103
65	SGS	\N	103
78	OULE3	\N	65
79	OUPHZ	\N	65
92	OUSIM	\N	65
80	OUSIR	\N	65
81	OUSPE	\N	65
82	SDC	\N	65
83	SYSTEM	\N	65
100	CODEEN	\N	83
104	SYSTEM	\N	103
136	FabryPerot	\N	\N
68	FIREBALL	\N	\N
69	GALEX	\N	\N
143	GAZPAR	2015-10-01	\N
139	HELP	\N	\N
70	Herschel	\N	\N
98	HeDaM	\N	70
99	ICC	\N	70
85	LAM	\N	\N
119	Administration	\N	85
89	CeSAM	\N	85
109	COSMO	\N	85
110	DynamiqueGalaxies	\N	85
121	Essais	\N	85
115	LOOM	\N	85
122	LPI	\N	85
123	Mecanique	\N	85
111	MIS	\N	85
118	Optique	\N	85
112	PASI	\N	85
113	PDG	\N	85
116	PSEG	\N	85
124	Quallité	\N	85
114	SysSol	\N	85
71	LASCO	\N	\N
86	METIS	\N	\N
87	OPTIQUE	\N	\N
94	Metrology	\N	87
95	OGSE	\N	87
72	OSIRIS	\N	\N
84	OTHER	\N	\N
144	OV	\N	\N
105	PFS	\N	\N
88	GS	\N	105
93	SPS	\N	105
137	PLATO	\N	\N
73	SITools	\N	\N
135	SO5	\N	\N
74	SPHERE	\N	\N
75	SPICA	\N	\N
140	SPINE	\N	\N
76	SPIROU	\N	\N
134	SVOM	\N	\N
101	ULTRAVISTA	\N	\N
126	Université	\N	\N
141	VIA-LACTEA	\N	\N
102	VUDS	\N	\N
77	VVDS	\N	\N
132	zCOSMOS	\N	\N
\.


--
-- Name: project_projectid_seq; Type: SEQUENCE SET; Schema: public; Owner: cram
--

SELECT pg_catalog.setval('project_projectid_seq', 145, true);


--
-- Data for Name: projectuser; Type: TABLE DATA; Schema: public; Owner: cram
--

COPY projectuser (userrid, projectid) FROM stdin;
26	85
22	131
26	105
26	93
26	74
22	127
22	128
10	63
10	85
10	89
10	110
10	84
22	125
22	66
22	67
22	90
22	129
22	136
22	69
22	70
22	98
22	85
22	89
22	71
32	63
9	64
9	65
9	92
9	82
9	83
9	70
9	85
9	89
32	89
16	71
32	84
22	84
22	73
22	135
22	74
22	101
22	126
22	102
22	77
22	132
24	80
24	81
24	68
24	69
24	89
27	125
27	84
28	70
24	71
19	131
19	125
19	67
24	72
19	85
19	89
19	84
24	84
19	73
19	69
19	98
13	89
13	68
13	69
14	133
14	67
14	81
14	68
14	85
14	89
14	71
14	84
14	105
35	64
35	74
29	63
6	64
6	103
6	92
6	81
6	82
6	83
6	84
25	125
25	91
25	68
25	123
25	134
18	89
18	90
18	70
18	99
18	84
17	71
17	73
23	71
30	138
30	68
30	89
33	105
33	84
15	85
15	109
20	131
20	128
20	125
20	66
20	129
20	136
20	139
20	98
20	89
20	84
20	73
20	101
20	102
20	132
15	89
15	110
15	115
15	111
15	112
15	114
15	72
15	84
31	125
31	92
31	126
8	139
34	70
4	96
4	145
4	133
4	125
1	63
1	89
4	63
4	90
4	64
4	91
4	65
4	92
4	80
4	81
4	82
4	83
4	85
4	89
4	84
4	144
4	105
4	88
4	137
4	134
4	126
4	141
11	145
11	133
11	97
11	63
11	67
11	90
11	64
11	103
11	65
11	81
11	82
11	143
11	139
11	85
11	119
11	89
11	84
11	144
11	137
11	74
5	125
5	66
5	67
5	90
5	103
5	91
5	65
5	82
5	83
5	100
5	104
5	68
5	69
5	70
5	99
5	85
5	89
5	115
5	116
5	71
5	95
5	84
5	74
5	76
\.


--
-- Data for Name: task; Type: TABLE DATA; Schema: public; Owner: cram
--

COPY task (activityid, projectid, userrid, taskdate, taskam, taskdayoff, taskcomment) FROM stdin;
56	65	9	2012-10-09	pm	f	
66	82	9	2012-10-10	am	f	ggstre ezzzzcs 
55	91	9	2012-10-10	pm	f	ggg
56	63	2	2012-10-08	am	f	préparation de la base de données
56	63	2	2012-10-08	pm	f	mise en place de la version 0 pour test
57	63	2	2012-10-01	am	f	Code de l'authentification LDap
57	63	2	2012-10-01	pm	f	Code de l'authentification LDap
57	63	2	2012-10-02	am	f	Code du Summary Tab
57	63	2	2012-10-02	pm	f	Code du Summary Tab
57	63	2	2012-10-03	am	f	Code de l'Admin Tab
57	63	2	2012-10-03	pm	f	Code de l'Admin Tab
57	63	2	2012-10-04	am	f	Code de l'Admin Tab
57	63	2	2012-10-04	pm	f	Code de l'Admin Tab
61	63	2	2012-10-05	am	f	tests pour la mise en place de la version 0
61	63	2	2012-10-05	pm	f	tests pour la mise en place de la version 0
61	63	4	2012-10-08	am	f	test V0
66	65	4	2012-10-08	pm	f	remlplissage CRAM
55	63	4	2012-10-01	am	f	analyse fonctionnement
55	63	4	2012-10-01	pm	f	analyse fonctionnement
66	65	4	2012-10-02	am	f	preparation des retours et organisation SGS LAM
67	65	4	2012-10-02	pm	f	reunion Euclid France, Euclid LAM
55	96	4	2012-10-03	am	f	preparation données, Wiki
66	89	4	2012-10-03	pm	f	Gestion personnel
67	85	4	2012-10-04	am	f	CPCS
66	89	4	2012-10-04	pm	f	PFI  / Roehlly
55	70	4	2012-10-05	pm	f	projet Bulles
67	65	4	2012-10-05	am	f	preparation meeting mardi
55	83	5	2012-10-11	am	f	Sonar installation
56	83	5	2012-10-11	pm	f	Sonar
63	83	5	2012-10-12	am	f	Sonar and jenkins configuration
63	89	5	2012-10-12	pm	f	\N
\N	\N	5	2012-10-15	am	t	
\N	\N	5	2012-10-15	pm	t	
63	89	5	2012-10-16	am	f	Redmine task
63	66	5	2012-10-16	pm	f	System management
57	64	6	2012-10-09	pm	f	\N
63	64	6	2012-10-09	am	f	\N
57	64	6	2012-10-05	pm	f	\N
57	64	6	2012-10-08	am	f	\N
57	89	10	2012-10-10	am	f	\N
61	85	5	2012-10-09	am	f	CRAM
63	85	5	2012-10-09	pm	f	serveur de projets virtuel
56	83	5	2012-10-10	am	f	installation et test jenkins
56	83	5	2012-10-10	pm	f	installation et test jemkins
67	65	4	2012-10-09	am	f	OU-SWG Meeting Paris
67	65	4	2012-10-09	pm	f	OU-SWG Meeting Paris
67	65	4	2012-10-10	am	f	OU-SWG Meeting Paris
67	65	4	2012-10-10	pm	f	OU-SWG Meeting Paris
66	89	4	2012-10-11	am	f	Management of team
66	89	4	2012-10-11	pm	f	Preparation of insertion of LASCO Team
57	84	8	2012-10-09	am	f	Simulateur d'Observations Spatiales
57	97	8	2012-10-09	pm	f	\N
57	84	8	2012-10-08	am	f	Simulateur d'Observations Spatiales
57	97	8	2012-10-08	pm	f	\N
57	97	8	2012-10-10	am	f	\N
67	97	8	2012-10-10	pm	f	\N
57	97	8	2012-10-11	am	f	\N
57	97	8	2012-10-11	pm	f	\N
56	63	11	2012-10-08	am	f	deployment 
71	63	11	2012-10-08	pm	f	LDAP java trustStore
61	63	11	2012-10-09	am	f	DB conf / pb name resolution
56	63	11	2012-10-09	pm	f	\N
71	74	11	2012-10-10	am	f	DRH 0.12.5
58	65	11	2012-10-10	pm	f	look at documentation
67	67	11	2012-10-11	am	f	SED & PPMXL
58	67	11	2012-10-11	pm	f	SED
67	65	11	2012-10-12	am	f	DM catalog
56	63	11	2012-10-04	pm	f	BD & packaging
56	63	11	2012-10-05	am	f	BD & packaging
\N	\N	11	2012-09-12	am	t	\N
\N	\N	11	2012-09-12	pm	t	\N
\N	\N	11	2012-09-20	am	t	\N
57	97	8	2012-10-12	am	f	
57	97	8	2012-10-12	pm	f	\N
57	97	8	2012-10-15	am	f	\N
57	97	8	2012-10-15	pm	f	\N
57	97	8	2012-10-16	am	f	\N
71	84	8	2012-10-16	pm	f	Piwik, test optimisation python...
59	82	5	2012-10-17	am	f	guillaume task
57	97	8	2012-10-17	am	f	
57	97	8	2012-10-17	pm	f	
63	89	5	2012-10-17	pm	f	Sonar & Jenkins Interaction and Test on ETC
63	89	5	2012-10-18	am	f	\N
56	63	2	2012-10-22	am	f	mise en place de la version 2 pour tests
57	63	2	2012-10-19	pm	f	gestion des connexions / déconnexions
57	63	2	2012-10-19	am	f	gestion des connexions / déconnexions
57	63	2	2012-10-18	pm	f	gestion des connexions / déconnexions
57	63	2	2012-10-18	am	f	gestion des connexions / déconnexions
57	63	2	2012-10-17	pm	f	gestion de l'export Excel
57	63	2	2012-10-17	am	f	gestion de l'export Excel
57	63	2	2012-10-16	pm	f	gestion de l'export Excel
57	63	2	2012-10-16	am	f	gestion de l'export Excel
57	63	2	2012-10-15	pm	f	tab Project Management (Manager)
57	63	2	2012-10-15	am	f	tab Project Management (Manager)
57	63	2	2012-10-12	pm	f	tab Project Management (Manager)
57	63	2	2012-10-12	am	f	tab Project Management (Manager)
57	63	2	2012-10-11	pm	f	Problème d'un changement de pwd
57	63	2	2012-10-11	am	f	Suppression et annulation
57	63	2	2012-10-10	pm	f	Copier/coller
57	63	2	2012-10-10	am	f	Proposition de sauvegarde
57	63	2	2012-10-09	pm	f	Ajout des restore possibles
57	63	2	2012-10-09	am	f	Problème de connexion pour certains users
63	89	5	2012-10-18	pm	f	Sonar Configuration
63	89	5	2012-10-19	am	f	Sonar C++ configuration
71	67	5	2012-10-19	pm	f	corotlbu disk et copie
63	89	5	2012-10-22	am	f	Sonar C++ configuration
63	85	5	2012-10-22	pm	f	cluster
63	89	5	2012-10-23	am	f	Sonar final test
\N	\N	8	2012-10-19	pm	t	
\N	\N	8	2012-10-19	am	t	
57	97	8	2012-10-18	pm	f	
57	97	8	2012-10-18	am	f	
57	97	8	2012-10-23	am	f	
57	97	8	2012-10-22	pm	f	
57	97	8	2012-10-22	am	f	
66	89	4	2012-10-23	pm	f	management contrat
66	89	4	2012-10-23	am	f	management contrat
59	65	4	2012-10-22	pm	f	preparation meeting
66	89	4	2012-10-22	am	f	management contrat
55	64	4	2012-10-19	pm	f	test et analyse
67	92	4	2012-10-19	am	f	lien SGS-OUSIM et requirement
55	64	4	2012-10-18	pm	f	test et analyse
55	64	4	2012-10-18	am	f	test et analyse
55	64	4	2012-10-17	pm	f	test et analyse
55	64	4	2012-10-17	am	f	test et analyse
55	64	4	2012-10-16	pm	f	test et analyse
55	64	4	2012-10-16	am	f	test et analyse
66	89	4	2012-10-15	pm	f	management contrat
66	89	4	2012-10-15	am	f	management contrat
59	65	4	2012-10-12	pm	f	preparation mission
55	65	4	2012-10-12	am	f	OU organisation
57	85	10	2012-10-23	pm	f	Dynamique des galaxies
57	85	10	2012-10-23	am	f	Dynamique des galaxies
67	97	8	2012-10-24	pm	f	
57	97	8	2012-10-24	am	f	
57	97	8	2012-10-23	pm	f	
67	65	4	2012-10-25	am	f	OU-SWG meeting - Rome
67	65	4	2012-10-24	pm	f	EUCLID-SGS Organisation meeting
67	65	4	2012-10-24	am	f	EUCLID-SGS Organisation meeting
57	97	8	2012-10-25	pm	f	
57	97	8	2012-10-25	am	f	
67	97	8	2012-10-05	pm	f	
57	97	8	2012-10-05	am	f	
70	98	8	2012-10-04	pm	f	
70	98	8	2012-10-04	am	f	
57	97	8	2012-10-03	pm	f	
57	97	8	2012-10-03	am	f	
57	97	8	2012-10-02	pm	f	
57	97	8	2012-10-02	am	f	
57	97	8	2012-10-01	pm	f	
57	97	8	2012-10-01	am	f	
57	70	9	2012-10-25	pm	f	passage de relais a Dominique sur cartes de temperatures
55	65	9	2012-10-25	am	f	
55	65	9	2012-10-24	pm	f	
67	70	9	2012-10-24	am	f	suivi stage dbrevot
55	65	9	2012-10-23	pm	f	
55	65	9	2012-10-23	am	f	
55	65	9	2012-10-22	pm	f	
55	65	9	2012-10-22	am	f	
55	65	9	2012-10-19	pm	f	
55	65	9	2012-10-19	am	f	
57	84	10	2012-10-26	am	f	Dynamique des galaxies
55	84	10	2012-10-25	pm	f	Dynamique des galaxies
57	84	10	2012-10-25	am	f	
57	66	20	2012-12-10	pm	f	Développement framework
60	84	20	2012-10-24	am	f	Préparation pour ANR développement Web pour les ASR
57	67	19	2012-10-23	am	f	Mise à jour ExoDat : bug d'authentification dans les web services
\N	\N	19	2012-10-22	pm	t	
\N	\N	19	2012-10-22	am	t	
\N	\N	19	2012-10-19	pm	t	
\N	\N	19	2012-10-19	am	t	
57	67	19	2012-10-05	pm	f	Développement SiTools2 pour nouvelle version ExoDat
57	67	19	2012-10-05	am	f	Développement SiTools2 pour nouvelle version ExoDat
57	67	19	2012-10-04	pm	f	Développement SiTools2 pour nouvelle version ExoDat
57	67	19	2012-10-04	am	f	Développement SiTools2 pour nouvelle version ExoDat
57	67	19	2012-10-03	pm	f	Développement SiTools2 pour nouvelle version ExoDat
57	67	19	2012-10-03	am	f	Développement SiTools2 pour nouvelle version ExoDat
57	67	19	2012-10-02	pm	f	Développement SiTools2 pour nouvelle version ExoDat
57	67	19	2012-10-02	am	f	Développement SiTools2 pour nouvelle version ExoDat
57	67	19	2012-10-01	pm	f	Développement SiTools2 pour nouvelle version ExoDat
57	67	19	2012-10-01	am	f	Développement SiTools2 pour nouvelle version ExoDat
60	84	19	2012-10-25	pm	f	Présentation jQuery dans la formation développement web pour les ASR
60	84	19	2012-10-25	am	f	Présentation jQuery dans la formation développement web pour les ASR
60	84	19	2012-10-24	pm	f	Préparation TP jQuery formation développement web pour les ASR
60	84	19	2012-10-18	pm	f	Préparation TP jQuery formation développement web pour les ASR
60	84	19	2012-10-18	am	f	Préparation TP jQuery formation développement web pour les ASR
57	67	19	2012-10-17	pm	f	Développement logiciel nettoyage PPMXL
57	67	19	2012-10-17	am	f	Développement logiciel nettoyage PPMXL
67	65	4	2012-10-26	pm	f	OU-SWG meeting - Rome
67	65	4	2012-10-26	am	f	OU-SWG meeting - Rome
67	65	4	2012-10-25	pm	f	OU-SWG meeting - Rome
57	84	20	2012-10-26	pm	f	Développement PHP systèmes d'information
57	84	20	2012-10-26	am	f	Développement PHP systèmes d'information
60	84	20	2012-10-25	pm	f	ANR Développement Web pour les ASR
60	84	20	2012-10-25	am	f	ANR Développement Web pour les ASR
57	84	20	2012-10-24	pm	f	developpement pour systèmes d'information
57	84	20	2012-10-23	pm	f	Développement pour les systèmes d'information
57	84	20	2012-10-23	am	f	Développement pour les systèmes d'information
60	84	20	2012-10-22	pm	f	Préparation pour ANR Développement Web pour les ASR
57	84	20	2012-10-19	pm	f	Developpement pour le SI VUDS
70	84	20	2012-10-19	am	f	Modification BdD VUDS
60	84	20	2012-10-18	pm	f	Préparation pour ANR Développement Web pour les ASR
60	84	20	2012-10-18	am	f	Préparation pour ANR Développement Web pour les ASR
70	84	20	2012-10-17	pm	f	Developpement script insertion BdD VUDS
70	84	20	2012-10-17	am	f	Developpement script modification BdD VUDS
60	84	20	2012-10-22	am	f	Préparation pour ANR développement Web pour les ASR
57	89	19	2012-10-23	pm	f	Développement php pour systeme d'information
57	89	19	2012-10-24	am	f	Développement php pour systeme d'information
57	84	20	2012-10-16	pm	f	Développment SI VUDS
57	84	20	2012-10-16	am	f	Développment SI VUDS
57	84	20	2012-10-15	pm	f	Développment SI VUDS
57	84	20	2012-10-15	am	f	Développment SI VUDS
67	67	19	2012-10-16	pm	f	Reunion ExoDat
57	89	19	2012-10-16	am	f	Développement php pour systeme d'information
57	89	19	2012-10-15	pm	f	Développement php pour systeme d'information
56	67	19	2012-10-12	pm	f	Déploiement de la préproduction pour nouvelle version ExoDat
56	67	19	2012-10-12	am	f	Déploiement de la préproduction pour nouvelle version ExoDat
56	67	19	2012-10-11	pm	f	Déploiement de la préproduction pour nouvelle version ExoDat
56	67	19	2012-10-11	am	f	Déploiement de la préproduction pour nouvelle version ExoDat
57	89	19	2012-10-10	pm	f	Développement php pour systeme d'information
57	89	19	2012-10-10	am	f	Développement php pour systeme d'information
57	89	19	2012-10-09	pm	f	Développement php pour systeme d'information
57	89	19	2012-10-09	am	f	Développement php pour systeme d'information
57	89	19	2012-10-08	am	f	Développement php pour systeme d'information
70	67	11	2012-10-25	pm	f	SED target run
61	67	11	2012-10-25	am	f	SED target run
67	97	11	2012-10-24	pm	f	
57	67	11	2012-10-24	am	f	SED target run
56	63	11	2012-10-23	am	f	
56	63	11	2012-10-22	pm	f	
70	74	11	2012-10-22	am	f	
57	67	11	2012-10-19	pm	f	SED target
55	67	11	2012-10-19	am	f	SED target
59	64	11	2012-10-18	pm	f	
57	74	11	2012-10-18	am	f	TDB
57	74	11	2012-10-17	pm	f	TDB
57	74	11	2012-10-17	am	f	TDB
57	74	11	2012-10-16	pm	f	TDB
56	74	11	2012-10-16	am	f	TDB
55	74	11	2012-10-15	pm	f	TDB SI django
55	74	11	2012-10-15	am	f	SI django
61	63	11	2012-10-12	pm	f	
71	74	11	2012-10-26	pm	f	AITAS Missing data file
71	74	11	2012-10-26	am	f	AITAS Missing data file
71	74	11	2012-10-23	pm	f	AITAS
71	74	11	2012-09-19	pm	f	AITAS concurrent Scan_dirAITAS 
62	83	11	2012-10-05	pm	f	
55	89	11	2012-10-04	am	f	VO DataService
55	89	11	2012-10-03	pm	f	
70	67	11	2012-10-03	am	f	LRc03
62	83	11	2012-10-02	pm	f	
62	83	11	2012-10-02	am	f	
55	74	11	2012-10-01	pm	f	TDB SI django
55	74	11	2012-10-01	am	f	
55	65	9	2012-10-26	pm	f	
55	65	9	2012-10-26	am	f	
62	67	5	2012-10-26	pm	f	Pastis deployment on ppfb
56	67	5	2012-10-26	am	f	Pastis svn projects 
63	89	5	2012-10-25	pm	f	Aigle
63	89	5	2012-10-25	am	f	Aigle
63	89	5	2012-10-24	pm	f	Sonar C++
63	89	5	2012-10-24	am	f	Sonar C++
63	89	5	2012-10-23	pm	f	Sonar c++
57	97	8	2012-10-29	am	f	
57	97	8	2012-10-26	pm	f	
57	97	8	2012-10-26	am	f	
63	97	8	2012-10-29	pm	f	
57	63	2	2012-10-29	pm	f	Travail sur les sous projets
57	63	2	2012-10-29	am	f	Travail sur les sous projets
57	63	2	2012-10-26	pm	t	
57	63	2	2012-10-26	am	t	
57	63	2	2012-10-25	pm	f	Travail sur les sous projets
57	63	2	2012-10-25	am	f	Travail sur les sous projets
57	63	2	2012-10-24	pm	f	Travail sur les sous projets
57	63	2	2012-10-24	am	f	Optimisation des frames
57	63	2	2012-10-23	pm	f	Optimisation des frames
57	63	2	2012-10-23	am	f	Enregistrement automatique
57	63	2	2012-10-22	pm	f	correction urgente d'un bug au démarrage
57	63	2	2012-10-30	pm	f	gestion des activités en jtree
57	63	2	2012-10-30	am	f	fin de gestion des projets et sous projets
67	99	18	2012-10-31	pm	f	
55	99	18	2012-10-31	am	f	
67	70	18	2012-10-30	pm	f	
55	70	18	2012-10-30	am	f	
57	99	18	2012-10-29	pm	f	
56	99	18	2012-10-29	am	f	
55	99	18	2012-10-26	pm	f	
55	99	18	2012-10-26	am	f	
55	99	18	2012-10-25	pm	f	pouf
67	70	18	2012-10-25	am	f	
67	99	18	2012-10-24	pm	f	
67	70	18	2012-10-24	am	f	David
55	99	18	2012-10-23	pm	f	pouf
55	99	18	2012-10-23	am	f	pouf
55	99	18	2012-10-22	pm	f	pouf
55	99	18	2012-10-22	am	f	pouf
67	99	18	2012-10-19	pm	f	pouf
67	99	18	2012-10-19	am	f	pouf
67	99	18	2012-10-18	pm	f	pouf
67	99	18	2012-10-18	am	f	pouf
67	99	18	2012-10-17	pm	f	pouf
67	99	18	2012-10-17	am	f	pouf
67	99	18	2012-10-16	pm	f	pouf
67	99	18	2012-10-16	am	f	pouf
67	99	18	2012-10-15	pm	f	pouf
67	99	18	2012-10-15	am	f	pouf
67	70	18	2012-10-12	pm	f	cecilia
67	70	18	2012-10-12	am	f	pouf
67	99	18	2012-10-11	pm	f	
67	99	18	2012-10-11	am	f	
57	89	19	2012-10-08	pm	f	Développement php pour systeme d'information
57	89	19	2012-10-15	am	f	Développement php pour systeme d'information
57	66	20	2013-01-04	pm	f	Decoupage Fits
57	66	20	2013-01-04	am	f	Decoupage Fits
57	66	20	2013-01-07	pm	f	Decoupage Fits
57	66	20	2013-01-07	am	f	Decoupage Fits
57	66	20	2013-01-08	pm	f	Decoupage Fits
67	99	18	2012-10-10	pm	f	
67	99	18	2012-10-10	am	f	
67	99	18	2012-10-09	pm	f	
67	99	18	2012-10-09	am	f	
67	99	18	2012-10-08	pm	f	
67	99	18	2012-10-08	am	f	
58	99	18	2012-10-05	pm	f	
58	70	18	2012-10-05	am	f	
67	99	18	2012-10-04	pm	f	
58	70	18	2012-10-04	am	f	
67	99	18	2012-10-03	pm	f	
58	70	18	2012-10-03	am	f	
58	99	18	2012-10-02	pm	f	
58	99	18	2012-10-02	am	f	
67	99	18	2012-10-01	pm	f	
58	99	18	2012-10-01	am	f	
57	97	8	2012-10-31	pm	f	
57	97	8	2012-10-31	am	f	
67	97	8	2012-10-30	pm	f	
57	97	8	2012-10-30	am	f	
\N	\N	4	2012-11-02	pm	t	
\N	\N	4	2012-11-02	am	t	
\N	\N	4	2012-11-01	pm	t	
\N	\N	4	2012-11-01	am	t	
\N	\N	4	2012-10-31	pm	t	
\N	\N	4	2012-10-31	am	t	
59	84	4	2012-10-30	pm	f	jury concours
59	84	4	2012-10-30	am	f	jury concours
59	84	4	2012-10-29	pm	f	jury concours
66	89	4	2012-10-29	am	f	
57	63	2	2012-10-31	am	f	Gestion des sous projets
57	63	2	2012-10-31	pm	f	Gestion des sous projets
\N	\N	2	2012-11-01	am	t	
\N	\N	2	2012-11-01	pm	t	
\N	\N	2	2012-11-02	am	t	
\N	\N	2	2012-11-02	pm	t	
\N	\N	8	2012-11-02	pm	t	
\N	\N	8	2012-11-02	am	t	
\N	\N	8	2012-11-01	pm	t	
\N	\N	8	2012-11-01	am	t	
63	89	5	2012-11-05	pm	f	cluster MAUI 
63	89	5	2012-11-05	am	f	cluster
\N	\N	5	2012-11-02	pm	t	
\N	\N	5	2012-11-02	am	t	
\N	\N	5	2012-11-01	pm	t	
\N	\N	5	2012-11-01	am	t	
63	89	5	2012-10-31	pm	f	Mathematica
63	89	5	2012-10-31	am	f	Aigle
63	89	5	2012-10-30	pm	f	redmine
63	89	5	2012-10-30	am	f	Redmine cleanup
63	89	5	2012-10-29	pm	f	cluster
63	89	5	2012-10-29	am	f	cluster
57	97	8	2012-11-05	am	f	
67	82	5	2012-11-07	am	f	
57	89	5	2012-11-06	pm	f	git for redmine
63	89	5	2012-11-06	am	f	cluster
59	83	5	2012-11-08	pm	f	reunion tel A.Diaz sur Sonar
63	89	5	2012-11-08	am	f	
57	97	8	2012-11-07	pm	f	
57	97	8	2012-11-07	am	f	
67	80	4	2013-01-28	am	f	Garage days
70	84	8	2012-11-09	pm	f	guVics
57	97	8	2012-11-09	am	f	
57	97	8	2012-11-08	pm	f	
57	97	8	2012-11-08	am	f	
55	65	9	2012-11-09	pm	f	
55	65	9	2012-11-09	am	f	
55	65	9	2012-11-08	pm	f	
67	70	9	2012-11-08	am	f	
57	97	8	2012-11-12	pm	f	
57	97	8	2012-11-12	am	f	
61	63	4	2012-11-12	pm	f	test implementation CRAM
55	84	4	2012-11-12	am	f	analyse projet OCEVU-WISH
\N	\N	4	2012-11-09	pm	t	
\N	\N	4	2012-11-09	am	t	
59	84	4	2012-11-08	pm	f	concours IRHC
59	84	4	2012-11-08	am	f	concours IRHC
\N	\N	4	2012-11-07	pm	t	
\N	\N	4	2012-11-07	am	t	
\N	\N	4	2012-11-06	pm	t	
\N	\N	4	2012-11-06	am	t	
\N	\N	4	2012-11-05	pm	t	
\N	\N	4	2012-11-05	am	t	
63	89	5	2012-11-14	pm	f	cluster optimisation
57	64	6	2012-11-14	pm	f	Plugin for automatic SNR calculation of CMC catalog
67	97	8	2012-11-13	pm	f	
57	97	8	2012-11-13	am	f	
57	64	6	2012-11-13	am	f	Feature #329: making central pixel calculation optional
57	64	6	2012-11-12	am	f	Plugin for automatic SNR calculation of CMC catalog
63	89	5	2012-11-14	am	f	cluster maui amelioration
63	89	5	2012-11-13	pm	f	reprise apres panne ( montages nfs afp)
63	89	5	2012-11-13	am	f	reprise apres panne ( RAIDs error)
63	89	5	2012-11-12	pm	f	reprise apres panne lamwws
63	89	5	2012-11-12	am	f	reprise apres panne
57	100	5	2012-11-09	pm	f	EUCLID.SDC-FR.CODEEN jenkins/sonar connection
57	100	5	2012-11-09	am	f	EUCLID.SDC-FR.CODEEN jenkins/sonar connection
69	100	5	2012-11-07	pm	f	EUCLID.SDC-FR.CODEEN Sonar experimentation
57	97	8	2012-11-14	pm	f	
67	84	8	2012-11-14	am	f	
57	97	8	2012-11-16	pm	f	
57	97	8	2012-11-16	am	f	
57	97	8	2012-11-15	pm	f	
57	97	8	2012-11-15	am	f	
57	97	8	2012-11-19	pm	f	
57	97	8	2012-11-19	am	f	
57	97	8	2012-11-06	pm	f	
57	97	8	2012-11-06	am	f	
57	97	8	2012-11-05	pm	f	
57	64	6	2012-11-14	am	f	Feature #329: making central pixel calculation optional
\N	\N	8	2012-11-21	am	t	
57	97	8	2012-11-20	pm	f	
57	97	8	2012-11-20	am	f	
67	97	8	2012-11-22	pm	f	
70	98	8	2012-11-22	am	f	
57	97	8	2012-11-21	pm	f	
63	89	5	2012-11-27	am	f	cluster et license
63	89	5	2012-11-26	pm	f	cluster
71	89	5	2012-11-26	am	f	serveurs et stations
\N	\N	5	2012-11-23	pm	t	
57	64	6	2012-11-05	am	f	Double Gaussian PSF
57	64	6	2012-11-07	pm	f	Plugin for automatic SNR calculation of CMC catalog
57	64	6	2012-11-07	am	f	Plugin for automatic SNR calculation of CMC catalog
\N	\N	6	2012-11-08	pm	t	
\N	\N	6	2012-11-08	am	t	
57	64	6	2012-11-09	pm	f	Plugin for automatic SNR calculation of CMC catalog
57	64	6	2012-11-09	am	f	Plugin for automatic SNR calculation of CMC catalog
57	64	6	2012-11-12	pm	f	Plugin for automatic SNR calculation of CMC catalog
67	83	6	2012-11-16	pm	f	IAL videoconf / OU-SIM data model teleconf
57	64	6	2012-11-16	am	f	Plugin for automatic SNR calculation of CMC catalog
57	64	6	2012-11-19	pm	f	Plugin for automatic SNR calculation of CMC catalog
57	64	6	2012-11-19	am	f	Plugin for automatic SNR calculation of CMC catalog
\N	\N	5	2012-11-23	am	t	
\N	\N	5	2012-11-22	pm	t	
\N	\N	5	2012-11-22	am	t	
\N	\N	5	2012-11-21	pm	t	
\N	\N	5	2012-11-21	am	t	
\N	\N	5	2012-11-20	pm	t	
\N	\N	5	2012-11-20	am	t	
69	100	5	2012-11-19	pm	f	workers
63	89	5	2012-11-19	am	f	cluster and stations
63	89	5	2012-11-16	pm	f	projets.oamp.fr crash
63	89	5	2012-11-16	am	f	cluster maui optimizing
56	100	5	2012-11-15	pm	f	sonar and jenkins plugins management
63	100	5	2012-11-15	am	f	sonar and jenkins update
70	84	8	2012-11-26	pm	f	
57	97	8	2012-11-26	am	f	
57	97	8	2012-11-23	pm	f	
57	97	8	2012-11-23	am	f	
66	89	4	2012-11-27	am	f	Gestion CDD
66	89	4	2012-11-26	pm	f	Gestion CDD
66	89	4	2012-11-26	am	f	Gestion CDD
67	96	4	2012-11-23	pm	f	Meeting Montpellier - Data Mining
67	96	4	2012-11-23	am	f	Meeting Montpellier - Data Mining
67	96	4	2012-11-22	pm	f	Meeting Montpellier - Data Mining
67	96	4	2012-11-22	am	f	Meeting Montpellier - Data Mining
67	90	4	2012-11-21	pm	f	Scientific Data Preservation
67	90	4	2012-11-21	am	f	Scientific Data Preservation
67	90	4	2012-11-20	pm	f	Scientific Data Preservation
67	90	4	2012-11-20	am	f	Scientific Data Preservation
66	89	4	2012-11-19	pm	f	Gestion CDD
66	89	4	2012-11-19	am	f	Gestion CDD
66	89	4	2012-11-16	pm	f	Gestion CDD
66	89	4	2012-11-16	am	f	Gestion CDD
70	96	4	2012-11-15	pm	f	préparation données AMADEUS
70	96	4	2012-11-15	am	f	préparation données AMADEUS
66	88	4	2012-11-14	pm	f	teleconférence PFS
66	80	4	2012-11-14	am	f	teleconférence EUCLID-SIR/SPE
66	65	4	2012-11-13	pm	f	preparation EUCLID-meeting
66	65	4	2012-11-13	am	f	preparation EUCLID-meeting
57	97	8	2012-11-27	pm	f	
57	97	8	2012-11-27	am	f	
56	91	5	2012-11-27	pm	f	
61	63	4	2012-11-27	pm	f	
\N	\N	13	2012-11-21	am	t	
57	69	13	2012-11-27	pm	f	QA - Sélection des régions pour chaque champ
57	69	13	2012-11-27	am	f	QA - Sélection des régions pour chaque champ
\N	\N	19	2012-10-29	pm	t	
\N	\N	19	2012-10-29	am	t	
\N	\N	19	2012-10-30	pm	t	
\N	\N	19	2012-10-30	am	t	
\N	\N	19	2012-10-31	pm	t	
\N	\N	19	2012-10-31	am	t	
\N	\N	19	2012-11-01	pm	t	
\N	\N	19	2012-11-01	am	t	
\N	\N	19	2012-11-02	pm	t	
\N	\N	19	2012-11-02	am	t	
70	67	19	2012-11-05	pm	f	Crossmatch ancillaries data
70	67	19	2012-11-05	am	f	Crossmatch ancillaries data
70	67	19	2012-11-06	pm	f	Crossmatch ancillaries data
70	67	19	2012-11-06	am	f	Crossmatch ancillaries data
70	67	19	2012-11-07	pm	f	Crossmatch ancillaries data
57	66	20	2013-01-08	am	f	Decoupage Fits
57	66	20	2013-01-09	pm	f	Decoupage Fits
70	67	19	2012-11-07	am	f	Crossmatch ancillaries data
57	66	20	2013-01-09	am	f	Decoupage Fits
57	66	20	2013-01-10	pm	f	Decoupage Fits
67	66	20	2013-01-10	am	f	Bilan projets
57	67	19	2012-11-27	pm	f	LIens CDS depuis ID ancillaries data
70	67	19	2012-11-27	am	f	Crossmatch ancillaries data (a_t_hub)
57	102	20	2013-01-11	pm	f	Bug Lidia
57	97	8	2012-11-28	pm	f	
57	97	8	2012-11-28	am	f	
55	89	5	2012-11-28	pm	f	fortran bug in g77 and ifort for G Lemaitre
63	89	5	2012-11-28	am	f	cluster pb node08
58	100	5	2012-11-29	pm	f	presentation reunion 04.12
63	89	5	2012-11-29	am	f	virtual machine
63	89	5	2012-11-30	pm	f	projets.oamp.fr update 2,1
58	100	5	2012-11-30	am	f	presentation 04.12
57	97	8	2012-11-29	pm	f	
57	97	8	2012-11-29	am	f	
67	84	8	2012-11-30	pm	f	
57	97	8	2012-11-30	am	f	
66	89	4	2012-11-28	pm	f	gestion CDDs
66	89	4	2012-11-28	am	f	gestion CDDs
67	84	4	2012-11-29	pm	f	Virtual Observatory Worshop - videoconf
67	84	4	2012-11-29	am	f	Virtual Observatory Worshop - videoconf
66	89	4	2012-11-30	pm	f	gestion CDDs
66	89	4	2012-11-30	am	f	gestion CDDs
66	65	4	2012-12-03	pm	f	preparation management
\N	\N	4	2012-12-03	am	t	
66	65	4	2012-12-04	pm	f	preparation management
58	69	13	2012-11-30	pm	f	
57	69	13	2012-11-30	am	f	Background in rt mode
\N	\N	13	2012-12-03	pm	t	
\N	\N	13	2012-12-03	am	t	
\N	\N	8	2012-12-03	pm	t	
57	84	8	2012-12-03	am	f	
57	97	8	2012-12-04	pm	f	
57	97	8	2012-12-04	am	f	
\N	\N	9	2012-10-30	pm	t	
\N	\N	9	2012-10-30	am	t	
\N	\N	9	2012-10-31	pm	t	
\N	\N	9	2012-10-31	am	t	
\N	\N	9	2012-11-01	pm	t	
\N	\N	9	2012-11-01	am	t	
\N	\N	9	2012-11-02	pm	t	
\N	\N	9	2012-11-02	am	t	
\N	\N	9	2012-11-05	pm	t	
\N	\N	9	2012-11-05	am	t	
\N	\N	9	2012-11-06	pm	t	
\N	\N	9	2012-11-06	am	t	
\N	\N	9	2012-11-07	pm	t	
\N	\N	9	2012-11-07	am	t	
67	65	9	2012-11-16	am	f	
67	70	9	2012-11-20	pm	f	
\N	65	9	2012-11-23	pm	t	
\N	65	9	2012-11-23	am	t	
67	65	9	2012-11-30	am	f	
67	84	10	2012-11-29	pm	f	Jury de recrutement IR cdd labex OT-MED
57	84	10	2012-11-29	am	f	
55	84	10	2012-12-04	pm	f	
57	84	10	2012-12-04	am	f	dynam
71	84	10	2012-12-03	pm	f	
71	84	10	2012-12-03	am	f	system dynam
57	67	19	2012-11-26	am	f	Développement php pour systeme d'information ExoDat
57	67	19	2012-11-26	pm	f	Développement php pour systeme d'information ExoDat
57	89	19	2012-11-14	am	f	Développement php pour systeme d'information
57	67	19	2012-11-28	am	f	Développement php pour systeme d'information ExoDat
57	67	19	2012-11-28	pm	f	Développement php pour systeme d'information ExoDat
55	65	9	2012-11-12	pm	f	
55	65	9	2012-11-12	am	f	
55	65	9	2012-11-13	pm	f	
55	65	9	2012-11-13	am	f	
55	65	9	2012-11-14	pm	f	
55	65	9	2012-11-14	am	f	
55	65	9	2012-11-15	pm	f	
55	65	9	2012-11-15	am	f	
55	65	9	2012-11-16	pm	f	
55	65	9	2012-11-19	pm	f	
55	65	9	2012-11-19	am	f	
55	65	9	2012-11-20	am	f	
55	65	9	2012-11-21	pm	f	
55	65	9	2012-11-21	am	f	
55	65	9	2012-11-22	pm	f	
55	65	9	2012-11-22	am	f	
55	65	9	2012-11-26	pm	f	
55	65	9	2012-11-26	am	f	
55	65	9	2012-11-27	pm	f	
55	65	9	2012-11-27	am	f	
55	65	9	2012-11-28	pm	f	
55	65	9	2012-11-28	am	f	
55	65	9	2012-11-29	pm	f	
55	65	9	2012-11-29	am	f	
55	65	9	2012-11-30	pm	f	
57	66	20	2013-01-11	am	f	Developpement Framework
57	66	20	2013-01-14	pm	f	Developpement Framework
57	66	20	2013-01-14	am	f	Developpement Framework
57	66	20	2013-01-15	pm	f	Developpement Framework
57	66	20	2013-01-15	am	f	Developpement Framework
61	102	20	2013-01-16	pm	f	Spectro
55	66	20	2013-01-16	am	f	Developpement Framework
58	89	19	2012-11-29	pm	f	Documentation API php pour systeme d'information
58	89	19	2012-11-29	am	f	Documentation API php pour systeme d'information
57	67	19	2012-11-30	pm	f	Développement page de synthèse CoRoT ExoDat
57	67	19	2012-11-30	am	f	Développement page de synthèse CoRoT ExoDat
57	67	19	2012-12-03	pm	f	Développement page de synthèse CoRoT ExoDat
57	67	19	2012-12-03	am	f	Développement page de synthèse CoRoT ExoDat
55	66	20	2013-01-17	am	f	Developpement Framework
\N	\N	20	2013-01-18	pm	t	
\N	\N	20	2013-01-18	am	t	
55	66	20	2013-01-21	pm	f	Developpement Framework
\N	\N	11	2012-11-08	pm	t	
\N	\N	11	2012-11-08	am	t	
\N	\N	11	2012-11-09	pm	t	
\N	\N	11	2012-11-09	am	t	
67	89	11	2012-11-26	pm	f	OVF interfaces
67	89	11	2012-11-26	am	f	OVF interfaces
56	63	11	2012-11-27	pm	f	
56	63	11	2012-11-27	am	f	
67	74	11	2012-11-28	pm	f	Workshop Deep Imaging surveys
55	74	11	2012-11-28	am	f	Deep Imaging surveys
70	74	11	2012-11-29	pm	f	Deep iamging surveys
70	74	11	2012-11-29	am	f	Deep iamging surveys
70	74	11	2012-11-30	pm	f	Deep iamging surveys
70	74	11	2012-11-30	am	f	Deep iamging surveys
70	74	11	2012-12-03	pm	f	Deep iamging surveys
55	89	11	2012-12-03	am	f	VO TAP
56	89	11	2012-12-04	pm	f	VO TAP
71	89	11	2012-12-04	am	f	VO DAL
55	66	20	2013-01-21	am	f	Developpement Framework
55	66	20	2013-01-22	pm	f	Developpement Framework
55	66	20	2013-01-22	am	f	Developpement Framework
57	66	20	2013-01-23	pm	f	Developpement Framework
57	66	20	2013-01-23	am	f	Developpement Framework
57	66	20	2013-01-24	pm	f	Developpement Framework
57	67	19	2012-10-26	pm	f	Developpement systéme d'information ExoDat
60	84	19	2012-11-21	pm	f	Presentation jQuery formation delegation CNRS
67	67	19	2012-11-21	am	f	CoRoT GT2S au LAM
70	67	19	2012-11-22	pm	f	crossmatch ancillaries data creation table hub via jointure sql
70	67	19	2012-11-22	am	f	crossmatch ancillaries data creation table hub via jointure sql
70	67	19	2012-11-23	pm	f	crossmatch ancillaries data creation table hub via jointure sql
70	67	19	2012-11-23	am	f	crossmatch ancillaries data creation table hub via jointure sql
57	89	20	2012-11-30	am	f	Développement SI
57	89	20	2012-11-29	pm	f	Développement SI
57	89	20	2012-11-29	am	f	Développement SI
\N	\N	20	2012-11-27	pm	t	
\N	\N	20	2012-11-27	am	t	
\N	\N	20	2012-11-26	pm	t	
\N	\N	20	2012-11-26	am	t	
56	102	20	2012-11-20	pm	f	Déploiement VUDS
56	102	20	2012-11-20	am	f	Déploiement VUDS
57	102	20	2012-11-19	pm	f	Développement VUDS
57	102	20	2012-11-19	am	f	Développement VUDS
57	89	20	2012-11-30	pm	f	Développement SI
60	84	20	2012-11-21	pm	f	Présentation jQuery délégation CNRS
57	102	20	2012-11-16	pm	f	Développement SI VUDS
57	102	20	2012-11-16	am	f	Développement SI VUDS
57	89	20	2012-11-15	pm	f	Développement SI
57	89	20	2012-11-15	am	f	Développement SI
57	89	20	2012-11-14	pm	f	Développement SI
57	89	20	2012-11-14	am	f	Développement SI
57	102	20	2012-11-13	pm	f	Développement SI VUDS
57	102	20	2012-11-13	am	f	Développement SI VUDS
57	102	20	2012-11-12	pm	f	Développement SI VUDS
57	102	20	2012-11-12	am	f	Développement SI VUDS
70	102	20	2012-11-09	pm	f	BdD VUDS
70	102	20	2012-11-09	am	f	BdD VUDS
57	89	20	2012-11-08	pm	f	Développement SI
57	89	20	2012-11-08	am	f	Développement SI
57	102	20	2012-11-07	pm	f	Développement SI VUDS
57	102	20	2012-11-07	am	f	Développement SI VUDS
57	89	20	2012-11-06	pm	f	Développement SI
69	83	6	2012-12-04	am	f	Data Model - FITS proposal
70	128	20	2012-11-21	am	f	BdD CFHTLS
57	67	19	2012-10-26	am	f	Developpement systeme d'information ExoDat
55	67	19	2012-12-04	pm	f	Analyse framework
55	67	19	2012-12-04	am	f	Analyse framework
59	83	6	2012-12-03	pm	f	Tools - Commenting Maven with C++
69	83	6	2012-12-03	am	f	Data Model - FITS proposal
69	83	6	2012-12-04	pm	f	Data Model - FITS proposal
70	128	20	2012-11-22	pm	f	BdD CFHTLS
57	128	20	2012-11-22	am	f	Developpement SI CFHTLS
57	128	20	2012-11-23	pm	f	Développement CFHTLS
57	128	20	2012-11-23	am	f	Developpement SI CFHTLS
56	128	20	2012-11-28	pm	f	Deploiement SI CFHTLS
56	128	20	2012-11-28	am	f	Deploiement SI CFHTLS
57	89	20	2012-11-06	am	f	Développement SI
57	89	20	2012-11-05	pm	f	Développement SI
57	89	20	2012-11-05	am	f	Développement SI
\N	\N	20	2012-11-02	pm	t	
\N	\N	20	2012-11-02	am	t	
\N	\N	20	2012-11-01	pm	t	
\N	\N	20	2012-11-01	am	t	
\N	\N	6	2012-11-01	pm	t	
\N	\N	6	2012-11-01	am	t	
\N	\N	6	2012-11-02	pm	t	
\N	\N	6	2012-11-02	am	t	
57	66	20	2013-01-24	am	f	Developpement Framework
57	64	6	2012-11-05	pm	f	Plugin for automatic SNR calculation of CMC catalog
57	66	20	2013-01-25	pm	f	Developpement Framework
57	64	6	2012-11-06	pm	f	Plugin for automatic SNR calculation of CMC catalog
57	64	6	2012-11-06	am	f	Plugin for automatic SNR calculation of CMC catalog
57	66	20	2013-01-25	am	f	Developpement Framework
67	80	4	2013-01-28	pm	f	Garage days
57	64	6	2012-11-13	pm	f	Feature #329: making central pixel calculation optional
57	64	6	2012-11-15	pm	f	Feature #356: implementation of 1D convolution of the PSF and SBP
57	64	6	2012-11-15	am	f	Feature #356: implementation of 1D convolution of the PSF and SBP
57	64	6	2012-11-20	pm	f	Plugin for automatic SNR calculation of CMC catalog
57	64	6	2012-11-20	am	f	Plugin for automatic SNR calculation of CMC catalog
57	64	6	2012-11-21	pm	f	Feature #356: implementation of 1D convolution of the PSF and SBP
59	84	6	2012-11-21	am	f	French lesson
57	64	6	2012-11-22	pm	f	Feature #356: implementation of 1D convolution of the PSF and SBP
58	64	6	2012-11-22	am	f	Updated the Calculation Method document
69	83	6	2012-11-23	pm	f	Data Model
69	83	6	2012-11-23	am	f	Data Model
69	83	6	2012-11-26	pm	f	Data Model
69	83	6	2012-11-26	am	f	Data Model
69	83	6	2012-11-27	pm	f	Data Model
69	83	6	2012-11-27	am	f	Data Model
69	83	6	2012-11-28	pm	f	Data Model
59	84	6	2012-11-28	am	f	French lesson
69	83	6	2012-11-29	pm	f	Data Model
69	83	6	2012-11-29	am	f	Data Model
69	83	6	2012-11-30	am	f	Data Model
67	83	6	2012-11-30	pm	f	IAL videoconf / Data Model
66	65	4	2012-12-04	am	f	
70	69	13	2012-12-04	pm	f	Copie des données T07 sur le cluster
70	69	13	2012-12-04	am	f	Lancement W1 sur le cluster
\N	\N	24	2012-11-01	pm	t	
\N	\N	24	2012-11-01	am	t	
\N	\N	24	2012-11-02	pm	t	
\N	\N	24	2012-11-02	am	t	
\N	\N	24	2012-11-05	pm	t	
\N	\N	24	2012-11-05	am	t	
\N	\N	24	2012-11-06	pm	t	
\N	\N	24	2012-11-06	am	t	
\N	\N	24	2012-11-07	pm	t	
\N	\N	24	2012-11-07	am	t	
\N	\N	24	2012-11-08	pm	t	
\N	\N	24	2012-11-08	am	t	
\N	\N	24	2012-11-09	pm	t	
\N	\N	24	2012-11-09	am	t	
\N	\N	24	2012-11-12	pm	t	
\N	\N	24	2012-11-12	am	t	
\N	\N	24	2012-11-13	pm	t	
\N	\N	24	2012-11-13	am	t	
\N	\N	24	2012-11-14	pm	t	
\N	\N	24	2012-11-14	am	t	
\N	\N	24	2012-11-15	pm	t	
55	69	24	2012-12-05	am	f	test lbfgsb algo
\N	\N	24	2012-11-15	am	t	
66	69	24	2012-11-16	pm	f	point Simon Conseil
55	69	24	2012-11-16	am	f	run blvs & qr
66	71	24	2012-11-19	pm	f	Christelle Peillon Solar Tomo
57	69	24	2012-11-19	am	f	
57	69	24	2012-11-20	pm	f	
60	84	24	2012-11-20	am	f	Eric Jullo, positive linear leastsquare solution & covariance 
62	69	24	2012-11-21	pm	f	biblio optimisation contrainte
62	69	24	2012-11-21	am	f	biblio optimisation contrainte
62	69	24	2012-11-22	pm	f	utilisation l-bfgs-b
62	69	24	2012-11-22	am	f	biblio optimisation contrainte
57	69	24	2012-11-23	pm	f	
57	69	24	2012-11-23	am	f	emphot: fit to Xu et al  2005 model for FUV
57	69	24	2012-11-26	pm	f	
57	69	24	2012-11-26	am	f	
57	69	24	2012-11-27	pm	f	
57	69	24	2012-11-27	am	f	
57	69	24	2012-11-28	pm	f	mise en oeuvre lbfgsb in emphot
57	69	24	2012-11-28	am	f	mise en oeuvre lbfgsb in emphot
57	69	24	2012-11-29	pm	f	mise en oeuvre lbfgsb in emphot
57	69	24	2012-11-29	am	f	mise en oeuvre lbfgsb in emphot
57	69	24	2012-11-30	pm	f	mise en oeuvre lbfgsb in emphot
57	69	24	2012-11-30	am	f	modif lbfgsb p utilisation lapack (mkl)
57	69	24	2012-12-03	pm	f	mise en oeuvre lbfgsb in emphot
57	69	24	2012-12-03	am	f	modif lbfgsb p utilisation lapack (mkl)
67	71	24	2012-12-04	pm	f	SolarTomo
57	69	24	2012-12-04	am	f	mise en oeuvre lbfgsb in emphot
59	125	22	2012-11-05	pm	f	Jury PFI
59	125	22	2012-11-05	am	f	Jury PFI
59	125	22	2012-11-06	pm	f	Jury PFI
59	125	22	2012-11-06	am	f	Jury PFI
59	125	22	2012-11-07	pm	f	Jury PFI
59	125	22	2012-11-07	am	f	Jury PFI
59	125	22	2012-11-08	pm	f	Jury PFI
59	125	22	2012-11-08	am	f	Jury PFI
59	125	22	2012-11-09	pm	f	Jury PFI
59	125	22	2012-11-09	am	f	Jury PFI
\N	\N	22	2012-11-12	pm	t	
\N	\N	22	2012-11-12	am	t	
\N	\N	22	2012-11-13	pm	t	
\N	\N	22	2012-11-13	am	t	
\N	\N	22	2012-11-14	pm	t	
\N	\N	22	2012-11-14	am	t	
\N	\N	22	2012-11-15	pm	t	
\N	\N	22	2012-11-15	am	t	
\N	\N	22	2012-11-16	pm	t	
\N	\N	22	2012-11-16	am	t	
\N	\N	22	2012-11-19	pm	t	
\N	\N	22	2012-11-19	am	t	
\N	\N	22	2012-11-20	pm	t	
\N	\N	22	2012-11-20	am	t	
\N	\N	22	2012-11-21	pm	t	
\N	\N	22	2012-11-22	pm	t	
\N	\N	22	2012-11-22	am	t	
\N	\N	22	2012-11-23	pm	t	
\N	\N	22	2012-11-23	am	t	
\N	\N	22	2012-11-26	pm	t	
\N	\N	22	2012-11-26	am	t	
\N	\N	22	2012-11-29	pm	t	
\N	\N	22	2012-11-29	am	t	
\N	\N	22	2012-11-30	pm	t	
\N	\N	22	2012-11-30	am	t	
\N	\N	22	2012-12-03	pm	t	
\N	\N	22	2012-12-03	am	t	
\N	\N	22	2012-12-04	pm	t	
\N	\N	22	2012-12-04	am	t	
57	67	19	2012-11-08	pm	f	Developpement systeme d'information ExoDat
57	67	19	2012-11-08	am	f	Developpement systeme d'information ExoDat
57	67	19	2012-11-09	pm	f	Developpement systeme d'information ExoDat
57	67	19	2012-11-09	am	f	Developpement systeme d'information ExoDat
70	67	19	2012-11-12	pm	f	Base de données ExoDat
70	67	19	2012-11-12	am	f	Base de données ExoDat
70	67	19	2012-11-13	pm	f	Base de données ExoDat
70	67	19	2012-11-13	am	f	Base de données ExoDat
57	89	19	2012-11-14	pm	f	Développement php pour systeme d'information
56	73	20	2013-01-17	pm	f	Developpement Framework
57	89	19	2012-11-15	pm	f	Développement php pour systeme d'information
57	89	19	2012-11-15	am	f	Développement php pour systeme d'information
57	89	19	2012-11-16	pm	f	Développement php pour systeme d'information
57	89	19	2012-11-16	am	f	Développement php pour systeme d'information
57	89	19	2012-11-19	pm	f	Développement php pour systeme d'information
57	89	19	2012-11-19	am	f	Développement php pour systeme d'information
57	89	19	2012-11-20	pm	f	Développement php pour systeme d'information
57	89	19	2012-11-20	am	f	Développement php pour systeme d'information
57	110	15	2012-12-05	pm	f	g3chem project (reading yields_data and compute metals ejection directly in C++)
57	66	20	2012-10-29	pm	f	
57	110	15	2012-12-04	pm	f	g3chem project
57	110	15	2012-12-04	am	f	g3chem project
73	110	15	2012-12-03	pm	f	"sunrise" project (making first spectrums)
73	110	15	2012-12-03	am	f	"sunrise" project (making first spectrums)
57	84	10	2012-12-05	pm	f	
57	84	10	2012-12-05	am	f	dynam
57	66	20	2012-10-29	am	f	
67	85	4	2012-12-06	am	f	CPCS
57	110	15	2012-12-06	am	f	g3chem project (yield_data)
57	97	8	2012-12-05	pm	f	
67	97	8	2012-12-05	am	f	
57	97	8	2012-12-06	pm	f	
57	97	8	2012-12-06	am	f	
57	110	15	2012-12-06	pm	f	g3chem + meeting about it
61	63	4	2012-12-06	pm	f	
66	70	4	2012-12-05	pm	f	
59	96	4	2012-12-05	am	f	gestion MASTODONS - WEB
57	97	8	2012-12-07	pm	f	
57	97	8	2012-12-07	am	f	
57	97	8	2012-12-10	pm	f	
57	97	8	2012-12-10	am	f	
67	100	5	2012-12-03	pm	f	deplacement
67	100	5	2012-12-03	am	f	Preparation
67	100	5	2012-12-04	pm	f	
67	100	5	2012-12-04	am	f	
67	100	5	2012-12-05	pm	f	retour et mise en ligne
63	89	5	2012-12-05	am	f	cluster
59	89	5	2012-12-06	pm	f	fortran research
55	89	5	2012-12-06	am	f	code error
63	69	5	2012-12-07	pm	f	new bingo server
57	89	5	2012-12-07	am	f	redmine optimisation 
69	89	5	2012-12-10	pm	f	fortran REAL
63	67	5	2012-12-10	am	f	corotscalc
63	89	5	2012-12-11	pm	f	maj
59	84	5	2012-12-11	am	f	webserver lam
71	63	11	2012-11-20	pm	f	
71	74	11	2012-11-20	am	f	AITAS
70	74	11	2012-11-23	pm	f	TDB 
71	63	11	2012-11-23	am	f	
\N	\N	11	2012-12-10	pm	t	
67	65	11	2012-12-10	am	f	
56	89	11	2012-12-11	pm	f	VO 
61	63	11	2012-12-11	am	f	
57	110	15	2012-12-10	pm	f	
57	110	15	2012-12-10	am	f	g3chem
57	97	8	2012-12-11	pm	f	
57	97	8	2012-12-11	am	f	
57	69	13	2012-12-10	pm	f	Mise en place du SI en local
58	69	13	2012-12-10	am	f	
57	69	13	2012-12-11	pm	f	SI Galex
57	69	13	2012-12-11	am	f	SI Galex
58	69	13	2012-12-12	pm	f	
57	69	13	2012-12-12	am	f	SI
57	97	8	2012-12-12	pm	f	
57	97	8	2012-12-12	am	f	
58	69	13	2012-12-13	pm	f	
58	69	13	2012-12-13	am	f	
57	72	15	2012-12-11	pm	f	some small issues with lbfgs_project
57	110	15	2012-12-11	am	f	g3chem
\N	\N	15	2012-12-12	pm	t	
57	66	20	2012-10-30	pm	f	
73	110	15	2012-12-13	pm	f	g3chem
57	110	15	2012-12-13	am	f	g3chem
57	110	15	2012-12-14	am	f	g3chem
57	66	20	2012-10-30	am	f	
62	85	15	2012-12-05	am	f	cours de france
67	110	15	2012-12-07	pm	f	wint Nikos Prantzos about g3chem
67	110	15	2012-12-07	am	f	wint Nikos Prantzos about g3chem
57	66	20	2012-10-31	pm	f	
62	85	15	2012-12-12	am	f	cours de france
57	115	15	2012-10-25	pm	f	some minor issues
57	115	15	2012-10-25	am	f	some minor issues
57	72	15	2012-10-26	pm	f	lbfgs
57	72	15	2012-10-26	am	f	lbfgs
57	72	15	2012-10-29	pm	f	lbfgs
57	72	15	2012-10-29	am	f	lbfgs
57	72	15	2012-10-30	pm	f	lbfgs
57	72	15	2012-10-30	am	f	lbfgs
57	72	15	2012-10-31	pm	f	lbfgs
57	72	15	2012-10-31	am	f	
57	72	15	2012-11-01	pm	f	lbfgs prject
57	72	15	2012-11-01	am	f	lbfgs prject
57	72	15	2012-11-02	pm	f	
57	72	15	2012-11-02	am	f	
57	72	15	2012-11-05	pm	f	
57	72	15	2012-11-05	am	f	
57	72	15	2012-11-06	pm	f	
57	72	15	2012-11-06	am	f	
57	72	15	2012-11-07	pm	f	
57	72	15	2012-11-07	am	f	
57	72	15	2012-11-08	pm	f	
57	72	15	2012-11-08	am	f	
57	72	15	2012-11-09	pm	f	
57	72	15	2012-11-09	am	f	
57	72	15	2012-11-12	pm	f	
57	72	15	2012-11-12	am	f	
57	72	15	2012-11-13	pm	f	
57	72	15	2012-11-13	am	f	
\N	\N	15	2012-11-14	pm	t	
57	110	15	2012-11-14	am	f	
57	110	15	2012-11-15	pm	f	
57	110	15	2012-11-15	am	f	
57	110	15	2012-11-16	pm	f	
57	66	20	2012-10-31	am	f	
67	67	22	2013-01-28	am	f	
57	110	15	2012-11-16	am	f	
57	110	15	2012-11-19	pm	f	
57	110	15	2012-11-19	am	f	
57	110	15	2012-11-20	pm	f	
57	110	15	2012-11-20	am	f	
57	110	15	2012-11-21	pm	f	
62	85	15	2012-11-21	am	f	cours de france
57	110	15	2012-11-22	pm	f	
57	110	15	2012-11-22	am	f	
57	110	15	2012-11-23	pm	f	
57	110	15	2012-11-23	am	f	
57	110	15	2012-11-26	pm	f	
57	110	15	2012-11-26	am	f	
57	110	15	2012-11-27	pm	f	
57	110	15	2012-11-27	am	f	
57	110	15	2012-11-28	pm	f	
62	85	15	2012-11-28	am	f	cours de france
57	110	15	2012-11-29	pm	f	
57	110	15	2012-11-29	am	f	
57	110	15	2012-11-30	pm	f	
57	110	15	2012-11-30	am	f	
57	110	15	2012-12-14	pm	f	g3chem   (researching)
67	84	8	2012-12-13	pm	f	
57	97	8	2012-12-13	am	f	
57	97	8	2012-12-14	pm	f	
57	97	8	2012-12-14	am	f	
57	97	8	2012-12-17	pm	f	
57	97	8	2012-12-17	am	f	
57	97	8	2012-12-18	pm	f	
67	97	8	2012-12-18	am	f	
67	84	8	2012-12-19	pm	f	
70	84	8	2012-12-19	am	f	Travail sur Virgo pour Alessandro.
66	70	4	2012-12-07	pm	f	Gestion projet Herschel
67	65	4	2012-12-07	am	f	Organisation 
55	65	4	2012-12-10	pm	f	organisation - LAM
55	65	4	2012-12-10	am	f	OU-SIM-EMA
55	65	4	2012-12-11	pm	f	OUSIM-EMA
67	65	4	2012-12-11	am	f	organisation LAM
66	65	4	2012-12-12	pm	f	OUSIR-OUSIM dev
71	89	4	2012-12-12	am	f	GEstion formation
55	65	4	2012-12-13	pm	f	OU-SIM-EMA
67	65	4	2012-12-13	am	f	AGILE
67	85	4	2012-12-14	pm	f	Question Centrale 5
55	65	4	2012-12-14	am	f	OU-SIM-EMA
66	89	4	2012-12-17	pm	f	organisation formation
67	83	4	2012-12-17	am	f	preparation SGS SYSTEM Team Meeting
67	83	4	2012-12-18	pm	f	SGS-SYSTEM Team Meeting - Paris
67	83	4	2012-12-18	am	f	SGS-SYSTEM Team Meeting - Paris
67	83	4	2012-12-19	pm	f	SGS-SYSTEM Team Meeting - Paris
67	83	4	2012-12-19	am	f	SGS-SYSTEM Team Meeting - Paris
67	89	4	2012-12-20	pm	f	
66	89	4	2012-12-20	am	f	Gestion
57	110	15	2012-12-17	pm	f	
57	110	15	2012-12-17	am	f	
57	110	15	2012-12-18	pm	f	
62	85	15	2012-12-18	am	f	cours de France 
57	110	15	2012-12-19	pm	f	
57	110	15	2012-12-19	am	f	
67	85	15	2012-12-20	pm	f	annual CESAM meeting
57	110	15	2012-12-20	am	f	
73	110	15	2012-12-21	pm	f	
73	110	15	2012-12-21	am	f	
67	84	8	2012-12-20	pm	f	
67	90	8	2012-12-20	am	f	
70	84	8	2012-12-21	pm	f	
70	84	8	2012-12-21	am	f	
55	67	5	2012-12-12	pm	f	ppfb usage
69	85	5	2012-12-12	am	f	lam.fr
70	71	5	2012-12-13	pm	f	
70	68	5	2012-12-13	am	f	
70	67	5	2012-12-14	pm	f	
70	67	5	2012-12-14	am	f	
59	104	5	2012-12-17	pm	f	preparation meeting
59	104	5	2012-12-17	am	f	preparation meeting
67	104	5	2012-12-18	pm	f	
67	104	5	2012-12-18	am	f	
67	104	5	2012-12-19	pm	f	
67	104	5	2012-12-19	am	f	
67	89	5	2012-12-20	pm	f	
63	89	5	2012-12-20	am	f	
63	89	5	2012-12-21	pm	f	
71	89	5	2012-12-21	am	f	
\N	\N	5	2012-12-24	pm	t	
\N	\N	5	2012-12-24	am	t	
\N	\N	5	2012-12-25	pm	t	
\N	\N	5	2012-12-25	am	t	
\N	\N	5	2012-12-26	pm	t	
\N	\N	5	2012-12-26	am	t	
\N	\N	5	2012-12-27	pm	t	
\N	\N	5	2012-12-27	am	t	
\N	\N	5	2012-12-28	pm	t	
\N	\N	5	2012-12-28	am	t	
\N	\N	5	2012-12-31	pm	t	
\N	\N	5	2012-12-31	am	t	
\N	\N	5	2013-01-01	pm	t	
\N	\N	5	2013-01-01	am	t	
\N	\N	8	2012-12-24	pm	t	
\N	\N	8	2012-12-24	am	t	
\N	\N	8	2012-12-25	pm	t	
\N	\N	8	2012-12-25	am	t	
\N	\N	8	2012-12-26	pm	t	
\N	\N	8	2012-12-26	am	t	
\N	\N	8	2012-12-27	pm	t	
\N	\N	8	2012-12-27	am	t	
\N	\N	8	2012-12-28	pm	t	
\N	\N	8	2012-12-28	am	t	
\N	\N	8	2012-12-31	pm	t	
\N	\N	8	2012-12-31	am	t	
\N	\N	8	2013-01-01	pm	t	
\N	\N	8	2013-01-01	am	t	
57	97	8	2013-01-28	pm	f	
62	89	8	2013-01-03	pm	f	
56	97	8	2013-01-03	am	f	
63	89	5	2013-01-02	pm	f	
63	89	5	2013-01-02	am	f	
61	100	5	2013-01-03	pm	f	
63	89	5	2013-01-03	am	f	
\N	\N	5	2013-01-04	pm	t	
\N	\N	5	2013-01-04	am	t	
\N	\N	8	2013-01-04	pm	t	
\N	\N	8	2013-01-04	am	t	
63	97	8	2013-01-08	am	f	
\N	\N	15	2012-12-24	pm	t	
\N	\N	15	2012-12-24	am	t	
\N	\N	15	2012-12-25	pm	t	
\N	\N	15	2012-12-25	am	t	
\N	\N	15	2012-12-26	pm	t	
\N	\N	15	2012-12-26	am	t	
\N	\N	15	2012-12-27	pm	t	
\N	\N	15	2012-12-27	am	t	
\N	\N	15	2012-12-28	pm	t	
\N	\N	15	2012-12-28	am	t	
\N	\N	15	2012-12-31	pm	t	
\N	\N	15	2012-12-31	am	t	
\N	\N	15	2013-01-01	pm	t	
\N	\N	15	2013-01-01	am	t	
\N	\N	15	2013-01-02	pm	t	
\N	\N	15	2013-01-02	am	t	
\N	\N	15	2013-01-03	pm	t	
\N	\N	15	2013-01-03	am	t	
\N	\N	15	2013-01-04	pm	t	
\N	\N	15	2013-01-04	am	t	
57	110	15	2013-01-07	pm	f	g3chem
57	110	15	2013-01-07	am	f	g3chem
57	110	15	2013-01-08	am	f	
66	89	4	2012-12-21	pm	f	preparation CeSAM - congés
66	89	4	2012-12-21	am	f	preparation CeSAM - congés
\N	\N	4	2012-12-24	pm	t	
\N	\N	4	2012-12-24	am	t	
\N	\N	4	2012-12-25	pm	t	
\N	\N	4	2012-12-25	am	t	
57	89	8	2013-01-07	pm	f	
57	89	8	2013-01-07	am	f	
\N	\N	4	2012-12-26	pm	t	
\N	\N	4	2012-12-26	am	t	
\N	\N	4	2012-12-27	pm	t	
\N	\N	4	2012-12-27	am	t	
\N	\N	4	2012-12-28	pm	t	
\N	\N	4	2012-12-28	am	t	
\N	\N	4	2012-12-31	pm	t	
\N	\N	4	2012-12-31	am	t	
\N	\N	4	2013-01-01	pm	t	
\N	\N	4	2013-01-01	am	t	
\N	\N	4	2013-01-02	pm	t	
\N	\N	4	2013-01-02	am	t	
66	89	4	2013-01-03	pm	f	reprise
66	89	4	2013-01-03	am	f	reprise
66	65	4	2013-01-04	pm	f	AGILE
66	65	4	2013-01-04	am	f	AGILE
55	96	4	2013-01-07	pm	f	lien avec PREDON - PREDON teleconf
66	89	4	2013-01-07	am	f	reorganisation taches
66	89	4	2013-01-08	pm	f	reorganisation taches
55	89	4	2013-01-08	am	f	organisation
\N	\N	8	2013-01-09	pm	t	
\N	\N	8	2013-01-09	am	t	
67	84	8	2013-01-10	am	f	
57	110	15	2013-01-08	pm	f	g3chem
57	110	15	2013-01-09	pm	f	g3chem
62	85	15	2013-01-09	am	f	cours de france
73	110	15	2013-01-10	am	f	g3chem
57	109	15	2013-01-10	pm	f	studing possibility to apply emcee to lenstool
57	109	15	2013-01-11	pm	f	studing possibility to apply emcee to lenstool
57	109	15	2013-01-11	am	f	studing possibility to apply emcee to lenstool
57	97	8	2013-01-28	am	f	
58	100	5	2013-01-07	pm	f	NEXUS
63	89	5	2013-01-07	am	f	
63	89	5	2013-01-08	pm	f	
69	100	5	2013-01-08	am	f	NEXUS
69	100	5	2013-01-09	pm	f	NEXUS
55	100	5	2013-01-09	am	f	NEXUS
71	89	5	2013-01-10	pm	f	
\N	\N	5	2013-01-10	am	t	
\N	\N	5	2013-01-11	pm	t	
\N	\N	5	2013-01-11	am	t	
71	89	5	2013-01-14	pm	f	
67	80	4	2013-01-29	am	f	Garage days
59	89	8	2013-01-02	pm	f	
67	80	4	2013-01-29	pm	f	Garage days
59	89	8	2013-01-02	am	f	
67	83	4	2013-01-30	am	f	Science Team Meeting
67	65	4	2013-01-15	am	f	LAM EUCLID meeting
67	83	4	2013-01-30	pm	f	Science Team Meeting
66	65	4	2013-01-31	am	f	preparation documents
57	89	8	2013-01-08	pm	f	
66	65	4	2013-01-31	pm	f	
57	89	8	2013-01-10	pm	f	
57	97	8	2013-01-31	pm	f	
57	89	8	2013-01-11	pm	f	
57	89	8	2013-01-11	am	f	
57	89	8	2013-01-14	pm	f	
57	89	8	2013-01-14	am	f	
57	89	8	2013-01-15	pm	f	
57	89	8	2013-01-15	am	f	
55	96	4	2013-01-09	pm	f	preparation ANR
55	96	4	2013-01-09	am	f	preparation ANR
\N	\N	13	2013-01-01	pm	t	
\N	\N	13	2013-01-01	am	t	
\N	\N	13	2013-01-02	pm	t	
\N	\N	13	2013-01-02	am	t	
\N	\N	13	2013-01-03	pm	t	
\N	\N	13	2013-01-03	am	t	
\N	\N	13	2013-01-04	pm	t	
\N	\N	13	2013-01-04	am	t	
57	69	13	2013-01-07	pm	f	SI - docs & amélioration pages QA
57	69	13	2013-01-07	am	f	SI - docs & amélioration pages QA
57	69	13	2013-01-08	pm	f	SI - docs & amélioration pages QA
57	69	13	2013-01-08	am	f	SI - docs & amélioration pages QA
57	69	13	2013-01-09	pm	f	SI - docs & amélioration pages QA
57	69	13	2013-01-09	am	f	SI - docs & amélioration pages QA
\N	\N	13	2013-01-10	pm	t	
\N	\N	13	2013-01-10	am	t	
57	69	13	2013-01-11	pm	f	
57	69	13	2013-01-11	am	f	
57	69	13	2013-01-14	pm	f	
57	69	13	2013-01-14	am	f	Amélioration plots simu
57	69	13	2013-01-15	pm	f	Amélioration plots simu
57	69	13	2013-01-15	am	f	Amélioration plots simu
57	69	13	2013-01-16	pm	f	Amélioration plots simu
55	65	9	2012-12-03	pm	f	
55	65	9	2012-12-03	am	f	
55	65	9	2012-12-04	pm	f	
55	65	9	2012-12-04	am	f	
\N	\N	9	2012-12-05	pm	t	
\N	\N	9	2012-12-05	am	t	
55	65	9	2012-12-06	pm	f	
55	65	9	2012-12-06	am	f	
55	65	9	2012-12-07	pm	f	
55	65	9	2012-12-07	am	f	
57	65	9	2012-12-10	pm	f	
57	65	9	2012-12-10	am	f	
57	65	9	2012-12-11	pm	f	
57	65	9	2012-12-11	am	f	
57	65	9	2012-12-12	pm	f	
57	65	9	2012-12-12	am	f	
57	65	9	2012-12-13	pm	f	
57	65	9	2012-12-13	am	f	
57	65	9	2012-12-14	pm	f	
57	65	9	2012-12-14	am	f	
57	65	9	2012-12-17	pm	f	
57	65	9	2012-12-17	am	f	
67	65	9	2012-12-18	pm	f	
67	65	9	2012-12-18	am	f	
67	65	9	2012-12-19	pm	f	
67	65	9	2012-12-19	am	f	
67	89	9	2012-12-20	pm	f	
58	65	9	2012-12-20	am	f	
\N	\N	9	2012-12-21	pm	t	
\N	\N	9	2012-12-21	am	t	
\N	\N	9	2012-12-24	pm	t	
\N	\N	9	2012-12-24	am	t	
\N	\N	9	2012-12-25	pm	t	
\N	\N	9	2012-12-25	am	t	
\N	\N	9	2012-12-26	pm	t	
\N	\N	9	2012-12-26	am	t	
\N	\N	9	2012-12-27	pm	t	
\N	\N	9	2012-12-27	am	t	
\N	\N	9	2012-12-28	pm	t	
\N	\N	9	2012-12-28	am	t	
\N	\N	9	2012-12-31	pm	t	
\N	\N	9	2012-12-31	am	t	
\N	\N	9	2013-01-01	pm	t	
\N	\N	9	2013-01-01	am	t	
\N	\N	9	2013-01-02	pm	t	
\N	\N	9	2013-01-02	am	t	
\N	\N	9	2013-01-03	pm	t	
\N	\N	9	2013-01-03	am	t	
57	65	9	2013-01-04	pm	f	
\N	\N	9	2013-01-04	am	t	
57	65	9	2013-01-07	pm	f	
57	65	9	2013-01-07	am	f	
57	65	9	2013-01-08	pm	f	
57	65	9	2013-01-08	am	f	
57	65	9	2013-01-09	pm	f	
57	65	9	2013-01-09	am	f	
57	65	9	2013-01-10	pm	f	
57	65	9	2013-01-10	am	f	
57	65	9	2013-01-11	pm	f	
57	65	9	2013-01-11	am	f	
57	89	9	2013-01-14	pm	f	Fabry Perot MAJ donnes de Henri Plana
57	89	9	2013-01-14	am	f	Fabry Perot MAJ donnes de Henri Plana
57	89	9	2013-01-15	pm	f	Fabry Perot MAJ donnes de Henri Plana
57	89	9	2013-01-15	am	f	Fabry Perot MAJ donnes de Henri Plana
57	70	9	2013-01-16	pm	f	Lise De Harveng production carte de temperature manquantes
57	70	9	2013-01-16	am	f	Lise De Harveng production carte de temperature manquantes
73	110	15	2013-01-14	pm	f	g3chem
57	109	15	2013-01-14	am	f	emcee for lenstool
57	109	15	2013-01-15	pm	f	emcee for lenstool
57	109	15	2013-01-15	am	f	emcee for lenstool
57	109	15	2013-01-16	pm	f	emcee for lenstool
73	110	15	2013-01-16	am	f	some general work
70	67	19	2012-12-17	pm	f	Mise à jour corot_id dans o_t_hub
70	67	19	2012-12-17	am	f	Mise à jour corot_id dans o_t_hub
70	67	19	2012-12-18	pm	f	Mise à jour corot_id dans o_t_hub
70	67	19	2012-12-18	am	f	Mise à jour corot_id dans o_t_hub
70	67	19	2012-12-19	pm	f	Mise à jour corot_id dans o_t_hub
70	67	19	2012-12-19	am	f	Mise à jour corot_id dans o_t_hub
67	89	19	2012-12-20	pm	f	
57	89	19	2012-12-20	am	f	
\N	\N	19	2012-12-21	pm	t	
\N	\N	19	2012-12-21	am	t	
\N	\N	19	2012-12-24	pm	t	
\N	\N	19	2012-12-24	am	t	
\N	\N	19	2012-12-25	pm	t	
\N	\N	19	2012-12-25	am	t	
\N	\N	19	2012-12-26	pm	t	
\N	\N	19	2012-12-26	am	t	
\N	\N	19	2012-12-27	pm	t	
\N	\N	19	2012-12-27	am	t	
\N	\N	19	2012-12-28	pm	t	
\N	\N	19	2012-12-28	am	t	
\N	\N	19	2012-12-31	pm	t	
\N	\N	19	2012-12-31	am	t	
\N	\N	19	2013-01-01	pm	t	
\N	\N	19	2013-01-01	am	t	
\N	\N	19	2013-01-02	pm	t	
\N	\N	19	2013-01-02	am	t	
\N	\N	19	2013-01-03	pm	t	
\N	\N	19	2013-01-03	am	t	
\N	\N	19	2013-01-04	pm	t	
\N	\N	19	2013-01-04	am	t	
66	89	4	2013-01-10	pm	f	presentation
66	65	4	2013-01-10	am	f	preparation
67	96	4	2013-01-11	pm	f	meeting ANR PREDON
67	96	4	2013-01-11	am	f	meeting ANR PREDON
61	63	4	2013-01-14	pm	f	
55	88	4	2013-01-14	am	f	Data Spectrum Analysis
55	65	4	2013-01-15	pm	f	
61	63	4	2013-01-16	pm	f	
61	96	4	2013-01-16	am	f	
57	71	23	2012-12-04	pm	f	
57	71	23	2012-12-04	am	f	tomographie
57	71	23	2012-12-05	pm	f	
57	71	23	2012-12-05	am	f	
57	71	23	2012-12-06	pm	f	
57	71	23	2012-12-06	am	f	
57	71	23	2012-12-07	pm	f	
57	71	23	2012-12-07	am	f	
57	71	23	2012-12-10	pm	f	
57	71	23	2012-12-10	am	f	
57	71	23	2012-12-11	pm	f	
57	71	23	2012-12-11	am	f	
57	71	23	2012-12-12	pm	f	
57	71	23	2012-12-12	am	f	
57	71	23	2012-12-13	pm	f	
57	71	23	2012-12-13	am	f	
57	71	23	2012-12-14	pm	f	
57	71	23	2012-12-14	am	f	
57	71	23	2012-12-17	pm	f	
57	71	23	2012-12-17	am	f	
57	71	23	2012-12-18	pm	f	
57	71	23	2012-12-18	am	f	
57	71	23	2012-12-19	pm	f	
57	71	23	2012-12-19	am	f	
57	71	23	2012-12-20	pm	f	
57	71	23	2012-12-20	am	f	
57	71	23	2012-12-21	pm	f	
57	71	23	2012-12-21	am	f	
57	71	23	2012-12-24	pm	f	
57	71	23	2012-12-24	am	f	
57	71	23	2012-12-25	pm	f	
57	71	23	2012-12-25	am	f	
57	71	23	2012-12-26	pm	f	
57	71	23	2012-12-26	am	f	
57	71	23	2012-12-27	pm	f	
57	71	23	2012-12-27	am	f	
57	71	23	2012-12-28	pm	f	
57	71	23	2012-12-28	am	f	
57	71	23	2012-12-31	pm	f	
57	71	23	2012-12-31	am	f	
57	71	23	2013-01-01	pm	f	
57	71	23	2013-01-01	am	f	
57	71	23	2013-01-02	pm	f	
57	71	23	2013-01-02	am	f	
57	71	23	2013-01-03	pm	f	
57	71	23	2013-01-03	am	f	
57	71	23	2013-01-04	pm	f	
57	71	23	2013-01-04	am	f	
71	71	23	2013-01-07	pm	f	
71	71	23	2013-01-07	am	f	
71	71	23	2013-01-08	pm	f	
71	71	23	2013-01-08	am	f	
71	71	23	2013-01-09	pm	f	
71	71	23	2013-01-09	am	f	
\N	\N	19	2013-01-11	pm	t	
\N	\N	19	2013-01-11	am	t	
57	67	19	2013-01-14	pm	f	Developpement Framework
57	67	19	2013-01-14	am	f	Developpement Framework
57	67	19	2013-01-15	pm	f	Developpement Framework
57	67	19	2013-01-15	am	f	Developpement Framework
57	67	19	2013-01-16	pm	f	Developpement Framework
55	67	19	2012-12-05	pm	f	Analyse framework
55	67	19	2012-12-05	am	f	Analyse framework
55	67	19	2012-12-06	pm	f	Analyse framework
55	67	19	2012-12-06	am	f	Analyse framework
55	67	19	2012-12-07	pm	f	Analyse framework
55	67	19	2012-12-07	am	f	Analyse framework
57	67	19	2012-12-10	pm	f	Developpement SI
57	67	19	2012-12-10	am	f	Developpement SI
57	67	19	2012-12-11	pm	f	Developpement SI
57	67	19	2012-12-11	am	f	Developpement SI
57	67	19	2012-12-12	pm	f	Developpement SI
57	67	19	2012-12-12	am	f	Developpement SI
57	67	19	2012-12-13	pm	f	Developpement SI
57	67	19	2012-12-13	am	f	Developpement SI
57	67	19	2012-12-14	pm	f	Developpement SI
57	67	19	2012-12-14	am	f	Developpement SI
61	67	19	2013-01-08	pm	f	Test unitaire Framework
61	67	19	2013-01-08	am	f	Test unitaire Framework
61	67	19	2013-01-09	pm	f	Test unitaire Framework
61	67	19	2013-01-09	am	f	Test unitaire Framework
61	67	19	2013-01-10	pm	f	Test unitaire Framework
71	71	23	2013-01-10	pm	f	
71	71	23	2013-01-10	am	f	
71	71	23	2013-01-11	pm	f	
71	71	23	2013-01-11	am	f	
57	71	23	2013-01-14	pm	f	
57	71	23	2013-01-14	am	f	
57	71	23	2013-01-15	pm	f	
57	71	23	2013-01-15	am	f	
58	71	23	2013-01-16	pm	f	
57	71	23	2013-01-16	am	f	
\N	\N	8	2013-01-16	pm	t	
\N	\N	8	2013-01-16	am	t	
57	102	20	2012-12-03	pm	f	Développement VUDS
57	102	20	2012-12-03	am	f	Développement VUDS
57	102	20	2012-12-04	pm	f	Développement VUDS
57	102	20	2012-12-04	am	f	Développement VUDS
70	102	20	2012-12-05	pm	f	Développement VUDS
70	102	20	2012-12-05	am	f	Développement VUDS
57	102	20	2012-12-06	pm	f	Développement VUDS
57	102	20	2012-12-06	am	f	Développement VUDS
\N	\N	20	2012-12-24	pm	t	
\N	\N	20	2012-12-24	am	t	
\N	\N	20	2012-12-25	pm	t	
\N	\N	20	2012-12-25	am	t	
\N	\N	20	2012-12-26	pm	t	
\N	\N	20	2012-12-26	am	t	
\N	\N	20	2012-12-27	pm	t	
\N	\N	20	2012-12-27	am	t	
\N	\N	20	2012-12-28	pm	t	
\N	\N	20	2012-12-28	am	t	
\N	\N	20	2012-12-31	pm	t	
\N	\N	20	2012-12-31	am	t	
\N	\N	20	2013-01-01	pm	t	
\N	\N	20	2013-01-01	am	t	
\N	\N	20	2013-01-02	pm	t	
\N	\N	20	2013-01-02	am	t	
\N	\N	20	2013-01-03	pm	t	
\N	\N	20	2013-01-03	am	t	
\N	\N	14	2013-01-02	pm	t	
\N	\N	14	2013-01-02	am	t	
\N	\N	14	2013-01-03	pm	t	
\N	\N	14	2013-01-03	am	t	
\N	\N	14	2013-01-04	pm	t	
\N	\N	14	2013-01-04	am	t	
70	67	14	2013-01-07	pm	f	
70	67	14	2013-01-07	am	f	
57	67	14	2013-01-08	pm	f	
57	67	14	2013-01-08	am	f	
58	67	14	2013-01-09	pm	f	
57	67	14	2013-01-09	am	f	
57	67	14	2013-01-10	pm	f	
67	71	14	2013-01-10	am	f	
71	67	14	2013-01-11	pm	f	
71	67	14	2013-01-11	am	f	
57	67	14	2013-01-14	pm	f	
57	67	14	2013-01-14	am	f	
56	67	14	2013-01-15	pm	f	
71	67	14	2013-01-15	am	f	
67	67	14	2013-01-16	pm	f	
59	84	14	2013-01-16	am	f	Visite medicale
57	66	20	2012-12-07	pm	f	Développement framework
57	66	20	2012-12-07	am	f	Développement framework
57	66	20	2012-12-10	am	f	Développement framework
57	66	20	2012-12-11	pm	f	Développement framework
57	66	20	2012-12-11	am	f	Développement framework
57	66	20	2012-12-17	pm	f	Découpage Fits
57	66	20	2012-12-17	am	f	Découpage Fits
57	66	20	2012-12-18	pm	f	Découpage Fits
57	66	20	2012-12-18	am	f	Découpage Fits
57	66	20	2012-12-19	pm	f	Découpage Fits
57	66	20	2012-12-19	am	f	Découpage Fits
57	66	20	2012-12-20	pm	f	Découpage Fits
57	66	20	2012-12-20	am	f	Découpage Fits
57	66	20	2012-12-21	pm	f	Découpage Fits
57	66	20	2012-12-21	am	f	Découpage Fits
57	129	22	2013-01-14	pm	f	site
57	129	22	2013-01-14	am	f	site
61	127	22	2013-01-29	am	f	
56	128	20	2012-12-12	am	f	Développement CFHTLS
56	128	20	2012-12-13	pm	f	Développement CFHTLS
56	128	20	2012-12-13	am	f	Développement CFHTLS
56	128	20	2012-12-14	pm	f	Développement CFHTLS
56	128	20	2012-12-14	am	f	Développement CFHTLS
66	85	22	2012-12-19	pm	f	NOEL LABO
57	97	8	2013-01-17	pm	f	
\N	\N	22	2012-11-02	pm	t	
\N	\N	22	2012-11-02	am	t	
\N	\N	22	2012-11-21	am	t	
\N	\N	22	2012-11-27	pm	t	
\N	\N	22	2012-11-27	am	t	
\N	\N	22	2012-11-28	pm	t	
\N	\N	22	2012-11-28	am	t	
\N	\N	22	2012-12-05	pm	t	
\N	\N	22	2012-12-05	am	t	
\N	\N	22	2012-12-06	pm	t	
\N	\N	22	2012-12-06	am	t	
\N	\N	22	2012-12-07	pm	t	
\N	\N	22	2012-12-07	am	t	
\N	\N	22	2012-12-10	pm	t	
\N	\N	22	2012-12-10	am	t	
\N	\N	22	2012-12-11	pm	t	
\N	\N	22	2012-12-11	am	t	
\N	\N	22	2012-12-12	pm	t	
\N	\N	22	2012-12-12	am	t	
\N	\N	22	2012-12-13	pm	t	
\N	\N	22	2012-12-13	am	t	
\N	\N	22	2012-12-14	pm	t	
\N	\N	22	2012-12-14	am	t	
57	77	22	2012-12-17	pm	f	
57	77	22	2012-12-17	am	f	
57	77	22	2012-12-18	pm	f	
57	77	22	2012-12-18	am	f	
\N	\N	22	2012-12-19	am	t	
57	77	22	2012-12-20	pm	f	
57	77	22	2012-12-20	am	f	
57	77	22	2012-12-21	pm	f	
57	77	22	2012-12-21	am	f	
\N	\N	22	2012-12-24	pm	t	
\N	\N	22	2012-12-24	am	t	
\N	\N	22	2012-12-25	pm	t	
\N	\N	22	2012-12-26	pm	t	
\N	\N	22	2012-12-26	am	t	
\N	\N	22	2012-12-27	pm	t	
\N	\N	22	2012-12-27	am	t	
\N	\N	22	2012-12-28	pm	t	
\N	\N	22	2012-12-28	am	t	
\N	\N	22	2012-12-31	pm	t	
\N	\N	22	2012-12-31	am	t	
\N	\N	22	2013-01-01	pm	t	
\N	\N	22	2013-01-01	am	t	
\N	\N	22	2013-01-02	am	t	
\N	\N	22	2013-01-03	pm	t	
\N	\N	22	2013-01-03	am	t	
56	77	22	2013-01-04	pm	f	fichiers download
55	77	22	2013-01-07	pm	f	pb de spectro
55	77	22	2013-01-07	am	f	pb de spectro
58	77	22	2013-01-08	pm	f	
58	77	22	2013-01-08	am	f	
58	77	22	2013-01-09	pm	f	
\N	\N	22	2013-01-09	am	t	
\N	\N	22	2013-01-10	pm	t	
\N	\N	22	2013-01-11	pm	t	
66	89	22	2013-01-11	am	f	planning projets
61	102	22	2013-01-15	pm	f	upload RawData
61	102	22	2013-01-16	pm	f	pb d'affichage spectres
\N	\N	22	2013-01-16	am	t	
57	102	22	2013-01-17	am	f	
70	98	8	2013-01-17	am	f	
57	97	8	2013-01-18	pm	f	
57	97	8	2013-01-18	am	f	
66	123	25	2013-01-18	am	f	
69	91	25	2013-01-18	pm	f	
67	97	8	2013-01-21	pm	f	
57	97	8	2013-01-21	am	f	
57	97	8	2013-01-22	pm	f	
57	89	8	2013-01-22	am	f	
55	100	5	2013-01-14	am	f	
55	100	5	2013-01-15	pm	f	
63	85	5	2013-01-15	am	f	
63	85	5	2013-01-16	pm	f	
55	83	5	2013-01-16	am	f	
71	89	5	2013-01-17	pm	f	
63	89	5	2013-01-17	am	f	
\N	\N	5	2013-01-18	pm	t	
\N	\N	5	2013-01-18	am	t	
59	100	5	2013-01-21	pm	f	
55	100	5	2013-01-21	am	f	
67	103	5	2013-01-22	pm	f	
71	89	5	2013-01-22	am	f	
67	67	19	2013-01-10	am	f	Bilan projet
\N	\N	8	2013-01-29	pm	t	
56	100	5	2013-01-23	pm	f	
56	100	5	2013-01-23	am	f	test rpm
57	109	15	2013-01-17	pm	f	emcee
73	110	15	2013-01-17	am	f	chemic
57	109	15	2013-01-18	pm	f	emcee
57	109	15	2013-01-18	am	f	emcee
57	109	15	2013-01-21	pm	f	emcee
57	109	15	2013-01-21	am	f	emcee
57	109	15	2013-01-22	pm	f	emcee
59	85	15	2013-01-22	am	f	titre de sejour
73	109	15	2013-01-23	pm	f	emcee
62	85	15	2013-01-23	am	f	cours de france
57	89	8	2013-01-23	pm	f	
57	89	8	2013-01-23	am	f	
57	70	9	2013-01-17	pm	f	
57	70	9	2013-01-17	am	f	
\N	\N	9	2013-01-18	pm	t	
\N	\N	9	2013-01-18	am	t	
57	65	9	2013-01-21	pm	f	
57	70	9	2013-01-21	am	f	
57	65	9	2013-01-22	pm	f	
67	65	9	2013-01-22	am	f	
57	65	9	2013-01-23	pm	f	
57	65	9	2013-01-23	am	f	
57	65	9	2013-01-24	pm	f	
57	65	9	2013-01-24	am	f	
57	65	9	2013-01-25	pm	f	
67	89	9	2013-01-25	am	f	Reunion migration Fabry Perot
66	89	4	2013-01-17	am	f	reunion CPCS
67	65	4	2013-01-17	pm	f	teleconf
61	63	4	2013-01-18	am	f	test v0.4
61	63	4	2013-01-18	pm	f	test v0.4
66	89	4	2013-01-21	am	f	GEstion NOEMI - entrevue RIEU
66	89	4	2013-01-21	pm	f	GEstion NOEMI - entrevue RIEU
66	65	4	2013-01-22	am	f	Reunion LAM - EUCLID
66	89	4	2013-01-22	pm	f	entrevues responsble stage
66	65	4	2013-01-23	am	f	Creation Redmine Site
66	65	4	2013-01-23	pm	f	Creation Redmine Site
66	65	4	2013-01-24	am	f	Creation Redmine Site
66	89	4	2013-01-24	pm	f	GEstion NOEMI - entrevue RIEU
66	65	4	2013-01-25	am	f	Reunion OUSPE - OLF-MS
66	96	4	2013-01-25	pm	f	commentaires Document financements
\N	\N	8	2013-01-29	am	t	
66	85	26	2013-02-01	pm	f	
57	97	8	2013-01-31	am	f	
\N	\N	8	2013-02-01	pm	t	
\N	\N	8	2013-02-01	am	t	
\N	\N	6	2012-12-24	pm	t	
\N	\N	6	2012-12-24	am	t	
\N	\N	6	2012-12-25	pm	t	
\N	\N	6	2012-12-25	am	t	
\N	\N	6	2012-12-26	pm	t	
\N	\N	6	2012-12-26	am	t	
\N	\N	6	2012-12-27	pm	t	
\N	\N	6	2012-12-27	am	t	
\N	\N	6	2012-12-28	pm	t	
\N	\N	6	2012-12-28	am	t	
57	67	19	2013-01-16	am	f	Developpement Framework
\N	\N	6	2012-12-31	pm	t	
\N	\N	6	2012-12-31	am	t	
61	67	19	2013-01-07	pm	f	Test unitaire Framework
61	67	19	2013-01-07	am	f	Test unitaire Framework
\N	\N	6	2013-01-01	pm	t	
57	97	8	2013-01-24	pm	f	
57	97	8	2013-01-24	am	f	
57	97	8	2013-01-25	pm	f	
57	97	8	2013-01-25	am	f	
\N	\N	6	2013-01-01	am	t	
\N	\N	22	2012-11-01	pm	t	
57	92	6	2013-01-02	pm	f	Emission Lines SNR plugin
\N	\N	22	2012-11-01	am	t	
57	92	6	2013-01-02	am	f	Emission Lines SNR plugin
57	92	6	2013-01-03	pm	f	Emission Lines SNR plugin
57	83	6	2013-01-03	am	f	FITS Data Model
57	83	6	2013-01-04	pm	f	FITS Data Model
57	83	6	2013-01-04	am	f	FITS Data Model
57	92	6	2013-01-07	pm	f	TIPS Data Model
57	92	6	2013-01-07	am	f	TIPS Data Model
57	92	6	2013-01-08	pm	f	Emission Lines SNR plugin
57	92	6	2013-01-08	am	f	TIPS Data Model
57	92	6	2013-01-09	pm	f	TIPS Data Model
59	84	6	2013-01-09	am	f	French lesson
57	83	6	2013-01-10	pm	f	FITS Data Model
57	92	6	2013-01-10	am	f	Emission Lines SNR plugin
57	92	6	2013-01-11	pm	f	TIPS Data Model
57	92	6	2013-01-11	am	f	Emission Lines SNR plugin
\N	\N	6	2013-01-14	pm	t	
\N	\N	6	2013-01-14	am	t	
\N	\N	6	2013-01-15	pm	t	
\N	\N	6	2013-01-15	am	t	
\N	\N	6	2013-01-16	pm	t	
\N	\N	6	2013-01-16	am	t	
\N	\N	6	2013-01-17	pm	t	
\N	\N	6	2013-01-17	am	t	
\N	\N	6	2013-01-18	pm	t	
\N	\N	6	2013-01-18	am	t	
67	83	6	2013-01-21	pm	f	Teleconf with Delouis/Nizar about FITS data model
69	92	6	2013-01-21	am	f	TIPS Data Model
67	83	6	2013-01-29	pm	f	ST Meeting - London
67	83	6	2013-01-30	pm	f	ST Meeting - London
67	83	6	2013-01-30	am	f	ST Meeting - London
67	83	6	2013-01-31	pm	f	ST Meeting - London
67	83	6	2013-01-31	am	f	ST Meeting - London
57	64	6	2013-02-04	pm	f	Bug #473 - Template spectra are plotted wrongly
57	64	6	2013-02-04	am	f	Feature #474 - Zodiacal noise as a function
67	83	6	2012-12-18	pm	f	ST Meeting - Paris
67	83	6	2012-12-18	am	f	ST Meeting - Paris
67	83	6	2012-12-19	pm	f	ST Meeting - Paris
67	83	6	2012-12-19	am	f	ST Meeting - Paris
\N	\N	22	2012-12-25	am	t	
56	89	22	2013-01-25	pm	f	analyse de la migration Fabry Perot
57	97	8	2013-01-30	pm	f	
57	97	8	2013-01-30	am	f	
57	77	22	2013-01-30	pm	f	
\N	\N	22	2013-01-30	am	t	
\N	\N	22	2013-01-31	pm	t	
\N	\N	22	2013-01-31	am	t	
56	102	22	2013-02-01	pm	f	
61	102	22	2013-02-01	am	f	
57	65	9	2013-01-28	pm	f	
56	77	22	2013-01-02	pm	f	fichiers download
57	65	9	2013-01-28	am	f	
57	65	9	2013-01-29	pm	f	
57	65	9	2013-01-29	am	f	
57	65	9	2013-01-30	pm	f	
57	65	9	2013-01-30	am	f	
56	77	22	2013-01-04	am	f	fichiers download
57	65	9	2013-01-31	pm	f	
57	65	9	2013-01-31	am	f	
67	103	6	2013-01-22	am	f	Reunion mensuelle LAM SGS
57	83	6	2013-01-23	pm	f	FITS Data Model
59	84	6	2013-01-23	am	f	French lesson
57	83	6	2013-01-24	pm	f	Python bindings for FITS data model
66	89	22	2013-01-10	am	f	planning projets
57	83	6	2013-01-24	am	f	Python bindings for FITS data model
57	92	6	2013-01-25	pm	f	TIPS Data Model
57	92	6	2013-01-25	am	f	TIPS Data Model
67	64	6	2013-01-28	pm	f	WISH plugin - meeting with Denis Burgarella
69	83	6	2013-01-28	am	f	FITS Data Model
\N	\N	22	2013-01-15	am	t	
67	64	6	2013-01-29	am	f	WISH plugin - meeting with Olivier Guyon
\N	\N	22	2013-01-18	pm	t	
\N	\N	22	2013-01-18	am	t	
56	102	22	2013-01-21	am	f	
67	73	22	2013-01-22	pm	f	SiTools2 + NOEMI
\N	\N	22	2013-01-22	am	t	
\N	\N	22	2013-01-23	pm	t	
\N	\N	22	2013-01-23	am	t	
67	89	22	2013-01-24	pm	f	NOEMI
67	89	22	2013-01-25	am	f	Fabry Perot
69	83	6	2013-02-01	pm	f	Data Model
57	83	6	2013-02-01	am	f	Data Model
58	84	27	2013-02-04	am	f	
57	83	6	2012-12-05	pm	f	FITS Data Model
57	83	6	2012-12-05	am	f	FITS Data Model
57	64	6	2012-12-06	pm	f	Bugs fixing
57	64	6	2012-12-06	am	f	Bugs fixing
57	83	6	2012-12-07	pm	f	FITS Data Model
67	103	6	2012-12-07	am	f	Reunion mensuelle LAM SGS
57	83	6	2012-12-10	pm	f	FITS Data Model
67	83	6	2012-12-10	am	f	CCB Meeting teleconf
57	64	6	2012-12-11	pm	f	Bugs fixing
57	64	6	2012-12-11	am	f	Bugs fixing
69	92	6	2012-12-12	pm	f	TIPS Data Model
69	92	6	2012-12-12	am	f	TIPS Data Model
67	92	6	2012-12-13	pm	f	EMA OU-SIM integration meeting - Marseille
67	92	6	2012-12-13	am	f	EMA OU-SIM integration meeting - Marseille
67	92	6	2012-12-14	pm	f	EMA OU-SIM integration meeting - Marseille
67	92	6	2012-12-14	am	f	EMA OU-SIM integration meeting - Marseille
67	92	6	2012-12-17	pm	f	Meeting with Julien
57	92	6	2012-12-17	am	f	Emission Lines SNR plugin
57	83	6	2012-12-20	pm	f	FITS Data Model
57	83	6	2012-12-20	am	f	FITS Data Model
57	92	6	2012-12-21	pm	f	Emission Lines SNR plugin
57	92	6	2012-12-21	am	f	Emission Lines SNR plugin
57	92	6	2013-01-22	pm	f	TIPS Data Model
56	100	5	2013-01-24	pm	f	
56	83	5	2013-01-24	am	f	
\N	\N	5	2013-01-25	pm	t	
\N	\N	5	2013-01-25	am	t	
63	67	5	2013-01-28	pm	f	
63	69	5	2013-01-28	am	f	
56	100	5	2013-01-29	pm	f	
56	100	5	2013-01-29	am	f	
63	89	5	2013-01-30	pm	f	
63	89	5	2013-01-30	am	f	
56	100	5	2013-01-31	pm	f	
56	100	5	2013-01-31	am	f	
\N	\N	5	2013-02-01	pm	t	
56	100	5	2013-02-01	am	f	
67	84	5	2013-02-04	pm	f	
63	89	5	2013-02-04	am	f	
57	109	15	2013-01-24	pm	f	emcee
57	109	15	2013-01-24	am	f	emcee
55	110	15	2013-01-25	pm	f	
55	110	15	2013-01-25	am	f	ICA
55	110	15	2013-01-28	pm	f	ICA
55	110	15	2013-01-28	am	f	ICA
55	110	15	2013-01-29	pm	f	ICA
55	110	15	2013-01-29	am	f	ICA
\N	\N	15	2013-01-30	pm	t	
62	85	15	2013-01-30	am	f	cours de france
57	110	15	2013-01-31	pm	f	ICA
57	110	15	2013-01-31	am	f	ICA
57	110	15	2013-02-01	pm	f	ICA
57	110	15	2013-02-01	am	f	ICA
57	110	15	2013-02-04	pm	f	ICA
57	110	15	2013-02-04	am	f	ICA
70	102	22	2013-02-04	am	f	
57	97	8	2013-02-04	pm	f	
57	97	8	2013-02-04	am	f	
57	66	20	2013-01-28	pm	f	Developpement Framework
57	66	20	2013-01-28	am	f	Developpement Framework
57	66	20	2013-01-29	pm	f	Developpement Framework
57	66	20	2013-01-29	am	f	Developpement Framework
57	66	20	2013-01-30	pm	f	Developpement Framework
57	66	20	2013-01-30	am	f	Developpement Framework
70	102	20	2013-01-31	pm	f	
70	89	20	2013-01-31	am	f	Deploiement base Lasco
57	66	20	2013-02-01	pm	f	Developpement Framework
57	66	20	2013-02-01	am	f	Developpement Framework
61	66	20	2013-02-04	pm	f	Selenium
61	66	20	2013-02-04	am	f	Selenium
61	66	20	2013-02-05	pm	f	Selenium
61	66	20	2013-02-05	am	f	Selenium
56	128	20	2012-12-12	pm	f	Développement CFHTLS
57	97	8	2013-02-05	pm	f	
58	131	22	2013-01-21	pm	f	API framework
58	131	22	2013-01-24	am	f	API framework
57	131	22	2013-01-29	pm	f	
57	131	22	2013-02-04	pm	f	
67	67	19	2013-01-17	pm	f	Thumbnails étoiles CoRoT 400
57	67	19	2013-01-17	am	f	Developpement framework SI
57	67	19	2013-01-18	pm	f	Developpement framework SI
57	67	19	2013-01-18	am	f	Developpement framework SI
56	73	19	2013-01-21	pm	f	Deploiement SiTools2 lasco
57	67	19	2013-01-21	am	f	Developpement datatable
57	67	19	2013-01-22	pm	f	Developpement datatable
57	67	19	2013-01-22	am	f	Developpement datatable
57	67	19	2013-01-23	pm	f	Developpement datatable
57	67	19	2013-01-23	am	f	Developpement framework SI
57	67	19	2013-01-24	pm	f	Developpement framework SI
57	67	19	2013-01-24	am	f	Developpement framework SI
57	67	19	2013-01-25	pm	f	Developpement framework SI
57	67	19	2013-01-25	am	f	Developpement framework SI
57	67	19	2013-01-28	pm	f	MAJ SI exodat avec la nouvelle version du framework
67	67	19	2013-01-28	am	f	Réunion CoRoT avec l'équipe PASI
57	67	19	2013-01-29	pm	f	Codage JSON serialize framework SI
57	67	19	2013-01-29	am	f	Codage JSON serialize framework SI
57	67	19	2013-01-30	pm	f	Codage JSON serialize framework SI
61	67	19	2013-01-30	am	f	Test unitaire JSON serialize framework SI
61	67	19	2013-01-31	pm	f	Test unitaire JSON serialize framework SI
61	67	19	2013-01-31	am	f	Test unitaire JSON serialize framework SI
57	67	19	2013-02-01	pm	f	MAJ SI exodat avec la nouvelle version du framework
57	67	19	2013-02-01	am	f	Developpement datatable
70	67	19	2013-02-04	pm	f	MAJ étoiles CoRoT pyc
70	67	19	2013-02-04	am	f	MAJ étoiles CoRoT pyc
57	67	19	2013-02-05	pm	f	MAJ SI exodat avec la nouvelle version du framework
57	67	19	2013-02-05	am	f	MAJ SI exodat avec la nouvelle version du framework
57	97	8	2013-02-05	am	f	
67	83	6	2013-02-05	pm	f	Teleconf for Data Model binding
58	64	6	2013-02-05	am	f	WISH plugin
57	97	8	2013-02-06	pm	f	
57	97	8	2013-02-06	am	f	
69	64	6	2013-02-06	pm	f	WISH plugin - AO support
59	84	6	2013-02-06	am	f	French lesson
57	89	22	2013-02-05	pm	f	
67	85	22	2013-02-05	am	f	web LAM
62	89	22	2013-02-06	pm	f	ajax
57	102	22	2013-02-06	am	f	
59	84	6	2013-02-07	am	f	French lesson
57	97	8	2013-02-07	pm	f	
57	89	8	2013-02-07	am	f	
57	64	6	2013-02-07	pm	f	WISH plugin
62	89	22	2013-02-07	pm	f	Ajax, JQuery
70	102	22	2013-02-07	am	f	
57	64	6	2013-02-08	am	f	WISH plugin
57	64	6	2013-02-08	pm	f	WISH plugin
57	97	8	2013-02-08	pm	f	
57	97	8	2013-02-08	am	f	
57	97	8	2013-02-11	pm	f	
57	97	8	2013-02-11	am	f	
57	67	19	2013-02-06	pm	f	MAJ SI ExoDat : nouvelle version framework + datatable
57	67	19	2013-02-06	am	f	MAJ SI ExoDat : nouvelle version framework + datatable
57	67	19	2013-02-07	pm	f	MAJ SI ExoDat : nouvelle version framework + datatable
57	67	19	2013-02-07	am	f	MAJ SI ExoDat : nouvelle version framework + datatable
57	67	19	2013-02-08	pm	f	MAJ SI ExoDat : nouvelle version framework + datatable
57	67	19	2013-02-08	am	f	MAJ SI ExoDat : nouvelle version framework + datatable
57	67	19	2013-02-11	pm	f	MAJ SI ExoDat : nouvelle version framework + datatable
56	67	19	2013-02-11	am	f	Déploiement CoRoT exodat sur xapps2 pre-prod
67	67	19	2013-02-12	pm	f	Reunion CoRoT ExoDat
70	67	19	2013-02-12	am	f	Ajout des étoiles Cilia exo100 simple
57	67	19	2013-02-13	pm	f	Rebranche framework + exodat sur master git
57	67	19	2013-02-13	am	f	Framework : ajout fonctionnalités metadata
57	66	20	2013-02-06	pm	f	Développement Framework
57	66	20	2013-02-06	am	f	Développement Framework
57	66	20	2013-02-07	pm	f	Développement Framework
57	66	20	2013-02-07	am	f	Développement Framework
\N	\N	20	2013-02-08	pm	t	
\N	\N	20	2013-02-08	am	t	
60	66	20	2013-02-11	pm	f	Ajax
56	89	20	2013-02-11	am	f	Déploiement Exodat
57	66	20	2013-02-12	pm	f	Développement Framework
57	102	20	2013-02-12	am	f	Développement SI
57	102	20	2013-02-13	pm	f	Développement SI
57	102	20	2013-02-13	am	f	Développement SI
62	89	22	2013-02-11	pm	f	AJAX
56	67	22	2013-02-11	am	f	
56	127	22	2013-02-12	pm	f	
67	67	22	2013-02-12	am	f	
61	127	22	2013-02-13	pm	f	
\N	\N	14	2012-12-21	pm	t	
\N	\N	14	2012-12-21	am	t	
\N	\N	14	2012-12-24	pm	t	
\N	\N	14	2012-12-24	am	t	
\N	\N	14	2012-12-25	pm	t	
\N	\N	14	2012-12-25	am	t	
\N	\N	14	2012-12-26	pm	t	
\N	\N	14	2012-12-26	am	t	
\N	\N	14	2012-12-27	pm	t	
\N	\N	14	2012-12-27	am	t	
\N	\N	14	2012-12-28	pm	t	
\N	\N	14	2012-12-28	am	t	
\N	\N	14	2012-12-31	pm	t	
\N	\N	14	2012-12-31	am	t	
\N	\N	14	2013-01-01	pm	t	
\N	\N	14	2013-01-01	am	t	
57	67	14	2013-01-17	pm	f	Pipeline N2
57	67	14	2013-01-17	am	f	Pipeline N2
57	67	14	2013-01-18	pm	f	Pipeline N2
57	67	14	2013-01-18	am	f	Pipeline N2
57	67	14	2013-01-21	pm	f	Pipeline N2
57	67	14	2013-01-21	am	f	Pipeline N2
\N	\N	14	2013-01-22	pm	t	
\N	\N	14	2013-01-22	am	t	
\N	\N	14	2013-01-23	pm	t	
\N	\N	14	2013-01-23	am	t	
\N	\N	14	2013-01-24	pm	t	
\N	\N	14	2013-01-24	am	t	
66	67	14	2013-01-25	pm	f	
57	67	14	2013-01-25	am	f	Pipeline N2
57	67	14	2013-01-28	pm	f	Pipeline N2
57	67	14	2013-01-28	am	f	Pipeline N2
57	67	14	2013-01-29	pm	f	Pipeline N2
57	67	14	2013-01-29	am	f	Pipeline N2
57	67	14	2013-01-30	pm	f	Pipeline N2
57	67	14	2013-01-30	am	f	Pipeline N2
57	67	14	2013-01-31	pm	f	Pipeline N2
57	67	14	2013-01-31	am	f	Pipeline N2
57	67	14	2013-02-01	pm	f	Pipeline N2
57	67	14	2013-02-01	am	f	Pipeline N2
66	67	14	2013-02-04	pm	f	
56	67	14	2013-02-04	am	f	Deploiement du pipeline N2 LESIA
60	89	14	2013-02-07	pm	f	Preparation atelier astro universite
60	89	14	2013-02-07	am	f	Preparation atelier astro universite
60	89	14	2013-02-08	pm	f	Atelier astro universite
60	89	14	2013-02-08	am	f	Preparation atelier astro universite
69	67	14	2013-02-11	pm	f	Exodat
66	67	14	2013-02-11	am	f	Exodat
67	81	14	2013-02-12	pm	f	
67	81	14	2013-02-12	am	f	
67	81	14	2013-02-13	pm	f	
67	81	14	2013-02-13	am	f	
66	67	14	2013-02-14	pm	f	
60	89	14	2013-02-14	am	f	Stagiaires 3eme
59	67	14	2012-10-23	pm	f	
59	67	14	2012-10-23	am	f	
59	67	14	2012-10-24	pm	f	
59	67	14	2012-10-24	am	f	
59	67	14	2012-10-25	pm	f	
59	67	14	2012-10-25	am	f	
59	67	14	2012-10-26	pm	f	
59	67	14	2012-10-26	am	f	
59	67	14	2012-10-29	pm	f	
59	67	14	2012-10-29	am	f	
59	67	14	2012-10-30	pm	f	
59	67	14	2012-10-30	am	f	
59	67	14	2012-10-31	pm	f	
59	67	14	2012-10-31	am	f	
59	67	14	2012-11-01	pm	f	
59	67	14	2012-11-01	am	f	
59	67	14	2012-11-02	pm	f	
59	67	14	2012-11-02	am	f	
59	67	14	2012-11-05	pm	f	
59	67	14	2012-11-05	am	f	
59	67	14	2012-11-06	pm	f	
57	131	22	2013-02-08	pm	f	
57	131	22	2013-02-08	am	f	API Admin
\N	\N	22	2013-02-13	am	t	
59	67	14	2012-11-06	am	f	
59	67	14	2012-11-07	pm	f	
59	67	14	2012-11-07	am	f	
59	67	14	2012-11-08	pm	f	
59	67	14	2012-11-08	am	f	
59	67	14	2012-11-09	pm	f	
59	67	14	2012-11-09	am	f	
59	67	14	2012-11-12	pm	f	
59	67	14	2012-11-12	am	f	
59	67	14	2012-11-13	pm	f	
59	67	14	2012-11-13	am	f	
59	67	14	2012-11-14	pm	f	
59	67	14	2012-11-14	am	f	
59	67	14	2012-11-15	pm	f	
59	67	14	2012-11-15	am	f	
59	67	14	2012-11-16	pm	f	
59	67	14	2012-11-16	am	f	
59	67	14	2012-11-19	pm	f	
59	67	14	2012-11-19	am	f	
59	67	14	2012-11-20	pm	f	
59	67	14	2012-11-20	am	f	
59	67	14	2012-11-21	pm	f	
59	67	14	2012-11-21	am	f	
59	67	14	2012-11-22	pm	f	
59	67	14	2012-11-22	am	f	
59	67	14	2012-11-23	pm	f	
59	67	14	2012-11-23	am	f	
59	67	14	2012-11-26	pm	f	
59	67	14	2012-11-26	am	f	
59	67	14	2012-11-27	pm	f	
59	67	14	2012-11-27	am	f	
59	67	14	2012-11-28	pm	f	
59	67	14	2012-11-28	am	f	
59	67	14	2012-11-29	pm	f	
59	67	14	2012-11-29	am	f	
59	67	14	2012-11-30	pm	f	
59	67	14	2012-11-30	am	f	
59	67	14	2012-12-03	pm	f	
59	67	14	2012-12-03	am	f	
59	67	14	2012-12-04	pm	f	
59	67	14	2012-12-04	am	f	
59	67	14	2012-12-05	pm	f	
59	67	14	2012-12-05	am	f	
59	67	14	2012-12-06	pm	f	
59	67	14	2012-12-06	am	f	
59	67	14	2012-12-07	pm	f	
59	67	14	2012-12-07	am	f	
59	67	14	2012-12-10	pm	f	
59	67	14	2012-12-10	am	f	
59	67	14	2012-12-11	pm	f	
59	67	14	2012-12-11	am	f	
59	67	14	2012-12-12	pm	f	
59	67	14	2012-12-12	am	f	
59	67	14	2012-12-13	pm	f	
59	67	14	2012-12-13	am	f	
59	67	14	2012-12-14	pm	f	
59	67	14	2012-12-14	am	f	
59	67	14	2012-12-17	pm	f	
59	67	14	2012-12-17	am	f	
59	67	14	2012-12-18	pm	f	
59	67	14	2012-12-18	am	f	
59	67	14	2012-12-19	pm	f	
59	67	14	2012-12-19	am	f	
59	67	14	2012-12-20	pm	f	
59	67	14	2012-12-20	am	f	
70	67	14	2013-02-05	pm	f	
70	67	14	2013-02-05	am	f	
70	67	14	2013-02-06	pm	f	
70	67	14	2013-02-06	am	f	
70	67	19	2013-02-14	pm	f	Etoiles exo 100 manquantes
70	67	19	2013-02-14	am	f	Etoiles exo 100 manquantes
\N	\N	15	2013-02-05	pm	t	
\N	\N	15	2013-02-05	am	t	
\N	\N	15	2013-02-06	pm	t	
\N	\N	15	2013-02-06	am	t	
\N	\N	15	2013-02-07	pm	t	
\N	\N	15	2013-02-07	am	t	
\N	\N	15	2013-02-08	pm	t	
\N	\N	15	2013-02-08	am	t	
\N	\N	15	2013-02-11	pm	t	
\N	\N	15	2013-02-11	am	t	
\N	\N	15	2013-02-12	pm	t	
\N	\N	15	2013-02-12	am	t	
62	85	15	2013-02-13	am	f	cours de france
57	110	15	2013-02-14	pm	f	ICA
62	85	15	2013-02-14	am	f	cours de france (additional lesson)
57	110	15	2013-02-13	pm	f	
62	89	8	2013-02-12	pm	f	Formation "Analyses Multifactorielles"
62	89	8	2013-02-12	am	f	Formation "Analyses Multifactorielles"
62	89	8	2013-02-13	pm	f	Formation "Analyses Multifactorielles"
62	89	8	2013-02-13	am	f	Formation "Analyses Multifactorielles"
62	89	8	2013-02-14	pm	f	Formation "Analyses Multifactorielles"
62	89	8	2013-02-14	am	f	Formation "Analyses Multifactorielles"
57	89	8	2013-02-15	pm	f	
57	97	8	2013-02-15	am	f	
57	97	8	2013-02-18	pm	f	
57	97	8	2013-02-18	am	f	
61	97	8	2013-02-19	pm	f	
57	97	8	2013-02-19	am	f	
61	97	8	2013-02-20	am	f	
57	97	8	2013-02-20	pm	f	
57	97	8	2013-02-21	pm	f	
57	97	8	2013-02-21	am	f	
67	97	8	2013-02-22	pm	f	
70	98	8	2013-02-22	am	f	
55	65	4	2013-02-01	am	f	dossier finance LAM
55	65	4	2013-02-01	pm	f	dossier finance LAM
67	89	4	2013-02-04	am	f	Communication BOTTI
60	85	4	2013-02-04	pm	f	Lune et l'autre
55	83	4	2013-02-05	pm	f	Data Model
69	64	4	2013-02-06	pm	f	AO - Fusco
67	85	4	2013-02-07	am	f	CPCS
67	88	4	2013-02-08	am	f	data reduction pipeline
55	88	4	2013-02-11	am	f	data reduction pipeline
55	88	4	2013-02-11	pm	f	data reduction pipeline
62	65	4	2013-02-12	am	f	AGILE meeting-CNES
62	65	4	2013-02-12	pm	f	AGILE meeting-CNES
62	65	4	2013-02-13	am	f	AGILE meeting-CNES
62	65	4	2013-02-13	pm	f	AGILE meeting-CNES
\N	\N	4	2013-02-14	am	t	
\N	\N	4	2013-02-14	pm	t	
55	85	4	2013-02-15	am	f	Acces cluster projet
55	80	4	2013-02-15	pm	f	AGILE
\N	\N	4	2013-02-18	am	t	
\N	\N	4	2013-02-18	pm	t	
\N	\N	4	2013-02-19	am	t	
\N	\N	4	2013-02-19	pm	t	
\N	\N	4	2013-02-20	am	t	
\N	\N	4	2013-02-20	pm	t	
\N	\N	4	2013-02-21	am	t	
\N	\N	4	2013-02-21	pm	t	
\N	\N	4	2013-02-22	am	t	
\N	\N	4	2013-02-22	pm	t	
66	89	4	2013-02-25	am	f	organisation stage
66	65	4	2013-02-25	pm	f	preparation delivrables EUCLID
55	65	4	2013-02-05	am	f	AGILE
55	64	4	2013-02-06	am	f	preparation AO
55	96	4	2013-02-07	pm	f	preparation ANR
55	88	4	2013-02-08	pm	f	
\N	\N	15	2013-02-20	pm	t	
67	97	8	2013-02-25	pm	f	
\N	\N	8	2013-02-25	am	t	
62	85	15	2013-02-20	am	f	cours de france
57	112	15	2013-02-25	pm	f	pastis
57	112	15	2013-02-25	am	f	pastis
57	110	15	2013-02-15	pm	f	
57	110	15	2013-02-15	am	f	ICA
57	110	15	2013-02-18	pm	f	ICA
57	110	15	2013-02-18	am	f	ICA
57	110	15	2013-02-19	pm	f	ICA
57	110	15	2013-02-19	am	f	ICA
73	110	15	2013-02-21	pm	f	thinmodels
57	110	15	2013-02-21	am	f	ICA
67	112	15	2013-02-22	pm	f	pastis
57	110	15	2013-02-22	am	f	ICA
\N	\N	19	2013-02-18	pm	t	
\N	\N	19	2013-02-18	am	t	
\N	\N	19	2013-02-19	pm	t	
\N	\N	19	2013-02-19	am	t	
\N	\N	19	2013-02-20	pm	t	
\N	\N	19	2013-02-20	am	t	
\N	\N	19	2013-02-21	pm	t	
\N	\N	19	2013-02-21	am	t	
\N	\N	19	2013-02-22	pm	t	
\N	\N	19	2013-02-22	am	t	
\N	\N	19	2013-02-25	pm	t	
\N	\N	19	2013-02-25	am	t	
57	67	19	2013-02-15	pm	f	Framework codage recherche par liste
57	67	19	2013-02-15	am	f	Framework codage recherche par liste
57	102	20	2013-02-14	pm	f	Développement SI
57	102	20	2013-02-14	am	f	Développement SI
\N	\N	20	2013-02-15	pm	t	
57	102	20	2013-02-15	am	f	Développement SI
\N	\N	20	2013-02-18	pm	t	
\N	\N	20	2013-02-18	am	t	
\N	\N	20	2013-02-19	pm	t	
\N	\N	20	2013-02-19	am	t	
\N	\N	20	2013-02-20	pm	t	
\N	\N	20	2013-02-20	am	t	
\N	\N	20	2013-02-21	pm	t	
\N	\N	20	2013-02-21	am	t	
\N	\N	20	2013-02-22	pm	t	
\N	\N	20	2013-02-22	am	t	
57	66	20	2013-02-25	pm	f	Développement SI
57	66	20	2013-02-25	am	f	Développement SI
57	66	20	2013-02-26	pm	f	Développement SI
57	66	20	2013-02-26	am	f	Développement SI
55	67	14	2013-02-18	pm	f	Pipeline detection corot (data model)
55	67	14	2013-02-18	am	f	Pipeline detection corot (data model)
57	67	14	2013-02-19	pm	f	Pipeline detection corot (data model)
57	67	14	2013-02-19	am	f	Pipeline detection corot (data model)
55	67	14	2013-02-20	pm	f	Time series
55	67	14	2013-02-20	am	f	Time series
55	67	14	2013-02-21	pm	f	Time series
55	67	14	2013-02-21	am	f	Time series
55	67	14	2013-02-22	pm	f	Time series
55	67	14	2013-02-22	am	f	Time series
57	97	8	2013-02-26	pm	f	
70	98	8	2013-02-26	am	f	
57	89	8	2013-02-27	pm	f	
57	97	8	2013-02-27	am	f	
\N	\N	15	2013-02-27	pm	t	
\N	\N	15	2013-02-27	am	t	
\N	\N	8	2013-02-28	pm	t	
\N	\N	8	2013-02-28	am	t	
\N	\N	8	2013-03-01	pm	t	
\N	\N	8	2013-03-01	am	t	
66	65	4	2013-03-04	am	f	management LAM
66	89	4	2013-03-04	pm	f	preparation reunion DIR
57	89	8	2013-03-04	pm	f	
57	89	8	2013-03-04	am	f	
57	97	8	2013-03-05	pm	f	
67	89	8	2013-03-05	am	f	
57	89	8	2013-03-06	pm	f	
57	97	8	2013-03-06	am	f	
67	85	8	2013-03-07	pm	f	
63	89	8	2013-03-07	am	f	
57	112	15	2013-02-26	pm	f	pastis
57	112	15	2013-02-26	am	f	pastis
57	110	15	2013-02-28	pm	f	
57	110	15	2013-02-28	am	f	ICA
57	110	15	2013-03-01	pm	f	ICA
57	110	15	2013-03-01	am	f	ICA
57	112	15	2013-03-04	pm	f	pastis
57	112	15	2013-03-04	am	f	pastis
57	110	15	2013-03-05	pm	f	potential
57	110	15	2013-03-05	am	f	potential
57	110	15	2013-03-06	pm	f	potential
57	110	15	2013-03-06	am	f	potential
57	110	15	2013-03-07	pm	f	potential
57	110	15	2013-03-07	am	f	potential
57	110	15	2013-03-08	pm	f	potential
57	112	15	2013-03-08	am	f	pastis
63	89	8	2013-03-08	pm	f	
57	89	8	2013-03-08	am	f	
57	65	9	2013-02-01	pm	f	
57	65	9	2013-02-01	am	f	
57	65	9	2013-02-04	pm	f	
57	65	9	2013-02-04	am	f	
57	65	9	2013-02-05	pm	f	
57	65	9	2013-02-05	am	f	
57	65	9	2013-02-06	pm	f	
57	65	9	2013-02-06	am	f	
57	65	9	2013-02-07	pm	f	
57	65	9	2013-02-07	am	f	
57	65	9	2013-02-08	pm	f	
57	65	9	2013-02-08	am	f	
57	65	9	2013-02-11	pm	f	
57	65	9	2013-02-11	am	f	
57	65	9	2013-02-12	pm	f	
57	65	9	2013-02-12	am	f	
57	65	9	2013-02-13	pm	f	
57	65	9	2013-02-13	am	f	
57	65	9	2013-02-14	pm	f	
57	65	9	2013-02-14	am	f	
57	65	9	2013-02-15	pm	f	
57	65	9	2013-02-15	am	f	
57	65	9	2013-02-18	pm	f	
57	65	9	2013-02-18	am	f	
67	65	9	2013-02-19	pm	f	
67	65	9	2013-02-19	am	f	
67	65	9	2013-02-20	pm	f	
67	65	9	2013-02-20	am	f	
\N	\N	9	2013-02-21	pm	t	
57	65	9	2013-02-21	am	f	
57	65	9	2013-02-22	pm	f	
57	65	9	2013-02-22	am	f	
\N	\N	22	2013-02-14	pm	t	
57	102	22	2013-02-14	am	f	
70	127	22	2013-02-15	pm	f	
70	127	22	2013-02-15	am	f	
\N	\N	22	2013-02-18	pm	t	
\N	\N	22	2013-02-18	am	t	
\N	\N	22	2013-02-19	pm	t	
\N	\N	22	2013-02-19	am	t	
\N	\N	22	2013-02-20	pm	t	
\N	\N	22	2013-02-20	am	t	
\N	\N	22	2013-02-21	pm	t	
\N	\N	22	2013-02-21	am	t	
\N	\N	22	2013-02-22	am	t	
\N	\N	22	2013-02-25	pm	t	
\N	\N	22	2013-02-25	am	t	
\N	\N	22	2013-02-26	pm	t	
\N	\N	22	2013-02-26	am	t	
55	127	22	2013-02-27	pm	f	
\N	\N	22	2013-02-27	am	t	
70	127	22	2013-02-28	pm	f	
\N	\N	22	2013-03-01	pm	t	
56	127	22	2013-03-04	pm	f	
61	127	22	2013-03-04	am	f	
60	125	22	2013-03-05	pm	f	préparation formation JQuery
67	89	22	2013-03-05	am	f	réunion CeSAM/dir
\N	\N	22	2013-03-06	am	t	
57	65	9	2013-02-25	pm	f	
57	65	9	2013-02-25	am	f	
57	65	9	2013-02-26	pm	f	
57	65	9	2013-02-26	am	f	
57	65	9	2013-02-27	pm	f	
57	65	9	2013-02-27	am	f	
57	65	9	2013-02-28	pm	f	
57	65	9	2013-02-28	am	f	
57	64	6	2013-02-11	am	f	Feature #580 (Export images as FITS) / Bug #577
71	64	6	2013-02-18	pm	f	Bug# 590 (Incorrect background calculation)
67	83	6	2013-02-19	am	f	System team meeting - ESAC
67	83	6	2013-02-19	pm	f	System team meeting - ESAC
69	83	6	2013-03-12	am	f	Review of Groningen meeting
59	64	6	2013-03-12	pm	f	Actions #627 and #628 of WISH plugin
57	71	17	2013-03-15	am	f	Added table for detected polarised triplets/quadruplets. Started editing f_polsel to account for thoses changes.
66	89	4	2013-02-26	am	f	Review pour reuion
66	89	4	2013-02-26	pm	f	Review pour reuion
66	89	4	2013-02-27	am	f	Review pour reuion
66	89	4	2013-02-27	pm	f	Review pour reuion
66	65	4	2013-02-28	am	f	AGILE
66	89	4	2013-02-28	pm	f	Review pour reuion
55	64	4	2013-03-01	am	f	Adaptive Optics
57	110	15	2013-03-11	pm	f	
57	110	15	2013-03-11	am	f	potential
57	110	15	2013-03-12	pm	f	potential
57	92	6	2013-02-11	pm	f	Euclid TIPS
67	81	6	2013-02-12	am	f	Agile development meeting
67	81	6	2013-02-12	pm	f	Agile development meeting
67	81	6	2013-02-13	am	f	Agile development meeting
67	81	6	2013-02-13	pm	f	Agile development meeting
59	84	6	2013-02-14	am	f	French lesson
67	83	6	2013-02-14	pm	f	IAL-EMA integration teleconf
57	92	6	2013-02-15	am	f	Euclid TIPS
57	92	6	2013-02-15	pm	f	Euclid TIPS
57	64	6	2013-02-18	am	f	WISH PLUGIN
67	83	6	2013-02-20	am	f	System team meeting - ESAC
67	83	6	2013-02-20	pm	f	System team meeting - ESAC
67	83	6	2013-02-21	am	f	Catalog DM meeting - ESAC
67	83	6	2013-02-21	pm	f	Catalog DM meeting - ESAC
69	83	6	2013-02-22	am	f	Data model
69	83	6	2013-02-22	pm	f	Data model
57	64	6	2013-02-25	am	f	WISH Plugin - Modificationfor multiple sources per slit
57	64	6	2013-02-25	pm	f	WISH Plugin - Modificationfor multiple sources per slit
57	64	6	2013-02-26	am	f	WISH Plugin - Modificationfor multiple sources per slit
57	64	6	2013-02-26	pm	f	WISH Plugin - Modificationfor multiple sources per slit
57	64	6	2013-02-27	am	f	WISH Plugin - Modificationfor multiple sources per slit
57	64	6	2013-02-27	pm	f	WISH Plugin - Modificationfor multiple sources per slit
69	83	6	2013-02-28	am	f	TIPS / IAL / EAS integration
69	83	6	2013-02-28	pm	f	TIPS / IAL / EAS integration
57	92	6	2013-03-05	pm	f	Euclid TIPS
67	92	6	2013-03-07	pm	f	OU-SIM/EMA Workshop - Groningen
67	83	6	2013-03-08	am	f	OU-SIM/EMA Workshop - Groningen
67	83	6	2013-03-08	pm	f	OU-SIM/EMA Workshop - Groningen
67	83	6	2013-03-11	am	f	Updating Christian with Groningen results
69	83	6	2013-03-11	pm	f	Review of Groningen meeting
55	96	4	2013-03-01	pm	f	finalisation
67	89	4	2013-03-05	am	f	CeSAM-DIR
\N	\N	4	2013-03-05	pm	t	
55	65	4	2013-03-06	pm	f	AGILE OUSPE
67	85	4	2013-03-07	am	f	AG
62	90	4	2013-03-07	pm	f	web cof datamanagement
66	89	4	2013-03-08	am	f	management
59	89	4	2013-03-08	pm	f	repet stage Brevot
55	65	4	2013-03-11	am	f	feedback de system team meeting
55	65	4	2013-03-11	pm	f	feedback de system team meeting
55	65	4	2013-03-12	am	f	Financial support
55	65	4	2013-03-12	pm	f	Financial support
\N	\N	4	2013-03-06	am	t	
63	89	8	2013-03-11	pm	f	
63	89	8	2013-03-11	am	f	
\N	\N	8	2013-03-12	am	t	
71	71	17	2013-03-12	am	f	Fixed database polarized images.
71	71	17	2013-03-12	pm	f	Replaced 29 corrupted images in archives, added antoinelin workstation to backuppc.
57	71	17	2013-03-13	am	f	Attempted detection of rebindex 1 triplets of polarised images in dev db.
57	71	17	2013-03-13	pm	f	Applied detection in production database, updated documentation.
55	71	16	2013-03-14	pm	f	
55	71	16	2013-03-14	am	f	
58	71	17	2013-03-14	am	f	Updated documentation about pipeline installation.
67	71	17	2013-03-14	pm	f	
63	89	8	2013-03-12	pm	f	
59	89	8	2013-03-13	pm	f	
63	89	8	2013-03-13	am	f	
63	89	8	2013-03-14	pm	f	
63	89	8	2013-03-14	am	f	
57	110	15	2013-03-12	am	f	potential
57	110	15	2013-03-13	pm	f	potential
57	110	15	2013-03-13	am	f	potential
57	110	15	2013-03-14	pm	f	potential
57	112	15	2013-03-14	am	f	pastis
57	110	15	2013-03-15	pm	f	potential
57	110	15	2013-03-15	am	f	potential
57	89	8	2013-03-15	pm	f	
57	89	8	2013-03-15	am	f	
56	77	22	2013-03-06	pm	f	
55	131	22	2013-03-07	am	f	
60	125	22	2013-03-08	pm	f	
60	125	22	2013-03-08	am	f	
61	89	22	2013-03-11	am	f	
56	102	22	2013-03-12	pm	f	Framework ANIS
56	102	22	2013-03-12	am	f	Framework ANIS
56	66	22	2013-03-13	pm	f	Framework ANIS : Abell & coma
69	83	6	2013-03-01	am	f	TIPS / IAL / EAS integration
69	83	6	2013-03-01	pm	f	TIPS / IAL / EAS integration
57	92	6	2013-03-04	am	f	Euclid TIPS
57	92	6	2013-03-04	pm	f	Euclid TIPS
67	84	6	2013-03-05	am	f	Reunion annuelle CeSAM-Direction
57	92	6	2013-03-06	am	f	Euclid TIPS
57	92	6	2013-03-06	pm	f	Euclid TIPS
57	89	8	2013-03-18	pm	f	
57	89	8	2013-03-18	am	f	
57	89	8	2013-03-19	pm	f	
57	89	8	2013-03-19	am	f	
69	103	5	2013-02-05	pm	f	
69	103	5	2013-02-05	am	f	
69	103	5	2013-02-06	pm	f	
69	103	5	2013-02-06	am	f	
71	89	5	2013-02-07	pm	f	
63	89	5	2013-02-07	am	f	
\N	\N	5	2013-02-08	pm	t	
\N	\N	5	2013-02-08	am	t	
\N	\N	5	2013-02-11	pm	t	
\N	\N	5	2013-02-11	am	t	
\N	\N	5	2013-02-12	pm	t	
\N	\N	5	2013-02-12	am	t	
67	103	5	2013-02-13	pm	f	
67	103	5	2013-02-13	am	f	
67	103	5	2013-02-14	pm	f	
67	103	5	2013-02-14	am	f	
\N	\N	5	2013-02-15	pm	t	
\N	\N	5	2013-02-15	am	t	
\N	\N	5	2013-02-18	pm	t	
\N	\N	5	2013-02-18	am	t	
\N	\N	5	2013-02-19	pm	t	
\N	\N	5	2013-02-19	am	t	
67	103	5	2013-02-20	pm	f	
67	103	5	2013-02-20	am	f	
67	103	5	2013-02-21	pm	f	
67	103	5	2013-02-21	am	f	
\N	\N	5	2013-02-22	pm	t	
\N	\N	5	2013-02-22	am	t	
\N	\N	5	2013-02-25	pm	t	
\N	\N	5	2013-02-25	am	t	
56	89	5	2013-02-26	pm	f	
71	89	5	2013-02-26	am	f	
63	89	5	2013-02-27	pm	f	
63	89	5	2013-02-27	am	f	
63	89	5	2013-02-28	pm	f	
63	89	5	2013-02-28	am	f	
57	89	5	2013-03-01	pm	f	
57	89	5	2013-03-01	am	f	
57	89	5	2013-03-04	pm	f	
57	89	5	2013-03-04	am	f	
57	89	5	2013-03-05	pm	f	
57	89	5	2013-03-05	am	f	
57	89	5	2013-03-06	pm	f	
57	89	5	2013-03-06	am	f	
57	89	5	2013-03-07	pm	f	
57	89	5	2013-03-07	am	f	
57	89	5	2013-03-08	pm	f	
57	89	5	2013-03-08	am	f	
63	89	5	2013-03-11	pm	f	
63	89	5	2013-03-11	am	f	
63	89	5	2013-03-12	pm	f	
63	89	5	2013-03-12	am	f	
63	89	5	2013-03-13	pm	f	
63	89	5	2013-03-13	am	f	
63	89	5	2013-03-14	pm	f	
63	89	5	2013-03-14	am	f	
63	89	5	2013-03-15	pm	f	
63	89	5	2013-03-15	am	f	
63	89	5	2013-03-18	pm	f	
63	89	5	2013-03-18	am	f	
63	89	5	2013-03-19	pm	f	
63	89	5	2013-03-19	am	f	
63	89	5	2013-03-20	pm	f	
63	89	5	2013-03-20	am	f	
72	71	16	2013-03-18	am	f	
72	71	16	2013-03-18	pm	f	
\N	\N	16	2013-03-19	am	t	
\N	\N	16	2013-03-19	pm	t	
57	71	16	2013-03-20	am	f	
57	71	16	2013-03-20	pm	f	
57	71	17	2013-03-15	pm	f	More editing and testing of f_polsel.
63	71	17	2013-03-20	am	f	Planning storage expansion, requested quotations.
57	71	17	2013-03-20	pm	f	More editing and testing of f_polsel.
57	71	17	2013-03-21	am	f	More editing and testing of f_polsel.
71	63	11	2013-03-21	am	f	
71	63	11	2013-03-21	pm	f	
70	74	11	2013-03-20	am	f	
70	74	11	2013-03-20	pm	f	catalogue AO
\N	\N	11	2013-02-25	am	t	
\N	\N	11	2013-02-25	pm	t	
\N	\N	11	2013-02-26	am	t	
\N	\N	11	2013-02-26	pm	t	
\N	\N	11	2013-02-27	am	t	
\N	\N	11	2013-02-27	pm	t	
\N	\N	11	2013-02-28	am	t	
\N	\N	11	2013-02-28	pm	t	
\N	\N	8	2013-03-20	pm	t	
57	89	8	2013-03-20	am	f	
57	89	8	2013-03-21	pm	f	
57	89	8	2013-03-21	am	f	
\N	\N	8	2013-03-22	pm	t	
\N	\N	8	2013-03-22	am	t	
57	89	8	2013-03-25	am	f	
55	131	22	2013-01-17	pm	f	API Admin framework
58	131	22	2013-01-28	pm	f	API ADMINSI
55	133	4	2013-03-13	am	f	Preparation WP
55	133	4	2013-03-13	pm	f	Meeting CAUP
55	81	4	2013-03-14	am	f	meeting OUSPE - Z detection
55	134	4	2013-03-14	pm	f	Define the SVOM contribution from CeSAM
55	133	4	2013-03-15	am	f	Preparation WP
55	133	4	2013-03-15	pm	f	Define the  contribution from CAUP and CeSAM
66	89	4	2013-03-18	am	f	SO5
66	89	4	2013-03-18	pm	f	CDDs APEC
67	81	4	2013-03-19	am	f	OUSPE-AGILE
67	81	4	2013-03-19	pm	f	OUSPE-AGILE
66	89	4	2013-03-20	am	f	SO5
55	134	4	2013-03-20	pm	f	Define the SVOM contribution from CeSAM
55	81	4	2013-03-21	am	f	OUSPE-AGILE
55	81	4	2013-03-21	pm	f	OUSPE-AGILE
\N	\N	4	2013-03-22	am	t	
55	81	4	2013-03-22	pm	f	OUSPE-AGILE
55	133	4	2013-03-25	am	f	Define the  contribution from CAUP and CeSAM
55	81	4	2013-03-25	pm	f	OUSPE-AGILE
55	81	4	2013-03-26	am	f	OUSPE-AGILE
66	89	4	2013-03-26	pm	f	CDDs
66	84	4	2013-03-27	am	f	Recherche financement PREDON - ANR - AMIDEX
59	65	4	2013-03-27	pm	f	preparation mission
67	97	8	2013-03-25	pm	f	
57	97	8	2013-03-26	pm	f	
55	131	22	2013-03-07	pm	f	
\N	\N	22	2013-03-13	am	t	
56	66	22	2013-03-14	am	f	Framework ANIS : Abell & coma
56	69	22	2013-03-15	pm	f	Framework ANIS
59	89	22	2013-03-15	am	f	GIT
56	66	22	2013-03-18	pm	f	
56	67	22	2013-03-18	am	f	Mise en prod nouveau ExoDat
56	132	22	2013-03-19	pm	f	
70	132	22	2013-03-19	am	f	configuration ANIS
67	89	22	2013-03-20	pm	f	
\N	\N	22	2013-03-20	am	t	
57	102	22	2013-03-21	pm	f	
69	89	22	2013-03-21	am	f	SO5
56	128	22	2013-03-22	pm	f	
70	128	22	2013-03-22	am	f	
56	66	22	2013-03-25	pm	f	Abell496
69	77	22	2013-03-25	am	f	
56	128	22	2013-03-26	pm	f	new CFHTLS
56	66	22	2013-03-26	am	f	new Abell
57	132	22	2013-03-27	pm	f	new SI
\N	\N	22	2013-03-27	am	t	
57	97	8	2013-03-26	am	f	
57	97	8	2013-03-27	pm	f	
57	97	8	2013-03-27	am	f	
71	71	17	2013-03-21	pm	f	Reinstalled lascolin6.
57	71	17	2013-03-22	am	f	Committed last changes to f_polsel, ran it on production database.
56	71	17	2013-03-22	pm	f	Ported database changes to antoinelin.
70	71	17	2013-03-28	am	f	Exported fits simulation file to csv ASCII for 2012/11/13 eclipse, 
67	71	17	2013-03-28	pm	f	
57	97	8	2013-03-28	pm	f	
57	97	8	2013-03-28	am	f	
57	71	16	2013-03-21	am	f	
57	71	16	2013-03-21	pm	f	
57	71	16	2013-03-22	am	f	
57	71	16	2013-03-22	pm	f	
57	71	16	2013-03-25	am	f	
57	71	16	2013-03-25	pm	f	
57	71	16	2013-03-26	am	f	
57	71	16	2013-03-26	pm	f	
57	71	16	2013-03-27	am	f	
57	71	16	2013-03-27	pm	f	
57	71	16	2013-03-28	am	f	
57	71	16	2013-03-28	pm	f	
57	71	16	2013-03-29	am	f	
57	71	16	2013-03-29	pm	f	
67	71	17	2013-03-29	am	f	
57	97	8	2013-03-29	pm	f	
57	97	8	2013-03-29	am	f	
57	71	17	2013-03-29	pm	f	Reviewing pipeline procedures for rollangl calculations.
70	71	17	2013-04-02	am	f	Started pipeline run until 08/10/2012.
57	71	17	2013-04-02	pm	f	Reviewing pipeline procedures for roll angle calculation.
\N	\N	8	2013-04-01	pm	t	
\N	\N	8	2013-04-01	am	t	
57	97	8	2013-04-02	pm	f	
57	97	8	2013-04-02	am	f	
57	71	17	2013-04-03	am	f	Edited pipeline procedures for roll angle calculations.
57	71	17	2013-04-03	pm	f	Edited pipeline procedures for roll angle calculations.
70	71	17	2013-04-04	am	f	Worked on latest pipeline run.
57	71	17	2013-04-04	pm	f	Corrections on image rate plotting procedures.
57	97	8	2013-04-03	pm	f	
57	97	8	2013-04-03	am	f	
67	97	8	2013-04-04	pm	f	
\N	\N	8	2013-04-04	am	t	
57	89	8	2013-04-05	pm	f	
57	89	8	2013-04-05	am	f	
57	89	8	2013-04-08	pm	f	
57	89	8	2013-04-08	am	f	
57	71	17	2013-04-08	am	f	Reworked imrate, pbrate, tbrate, mbrate plotting procedures.
57	71	17	2013-04-08	pm	f	Reworked imrate, pbrate, tbrate, mbrate plotting procedures.
57	71	17	2013-04-09	am	f	Working on rollangle new procedures.
71	71	17	2013-04-09	pm	f	Reinstalled lascolin9.
55	71	16	2013-04-01	am	f	
55	71	16	2013-04-01	pm	f	
55	71	16	2013-04-02	am	f	
55	71	16	2013-04-02	pm	f	
55	71	16	2013-04-03	am	f	
57	71	16	2013-04-03	pm	f	
57	71	16	2013-04-04	am	f	
57	71	16	2013-04-04	pm	f	
57	71	16	2013-04-05	am	f	
57	71	16	2013-04-05	pm	f	
57	71	16	2013-04-08	am	f	
57	71	16	2013-04-08	pm	f	
57	71	16	2013-04-09	am	f	
57	71	16	2013-04-09	pm	f	
57	65	9	2013-03-01	am	f	
57	65	9	2013-03-01	pm	f	
57	65	9	2013-03-04	am	f	
57	65	9	2013-03-04	pm	f	
57	65	9	2013-03-05	am	f	
57	65	9	2013-03-05	pm	f	
57	65	9	2013-03-06	am	f	
57	65	9	2013-03-06	pm	f	
57	65	9	2013-03-07	am	f	
57	65	9	2013-03-07	pm	f	
57	65	9	2013-03-08	am	f	
57	65	9	2013-03-08	pm	f	
57	65	9	2013-03-11	am	f	
57	65	9	2013-03-11	pm	f	
57	65	9	2013-03-12	am	f	
57	65	9	2013-03-12	pm	f	
57	65	9	2013-03-13	am	f	
57	65	9	2013-03-13	pm	f	
57	65	9	2013-03-14	am	f	
57	65	9	2013-03-14	pm	f	
57	65	9	2013-03-15	am	f	
57	65	9	2013-03-15	pm	f	
57	65	9	2013-03-18	am	f	
57	65	9	2013-03-18	pm	f	
67	65	9	2013-03-19	am	f	
67	65	9	2013-03-19	pm	f	
67	65	9	2013-03-20	am	f	
67	65	9	2013-03-20	pm	f	
57	65	9	2013-03-21	am	f	
57	65	9	2013-03-21	pm	f	
57	65	9	2013-03-22	am	f	
57	65	9	2013-03-22	pm	f	
57	65	9	2013-03-25	am	f	
57	65	9	2013-03-25	pm	f	
57	65	9	2013-03-26	am	f	
57	65	9	2013-03-26	pm	f	
57	65	9	2013-03-27	am	f	
57	65	9	2013-03-27	pm	f	
57	65	9	2013-03-28	am	f	
57	65	9	2013-03-28	pm	f	
57	65	9	2013-03-29	am	f	
57	65	9	2013-03-29	pm	f	
57	71	17	2013-04-10	am	f	Working on rollangle new procedures.
61	71	17	2013-04-10	pm	f	Testing and debugging new rollangle procedures.
57	71	17	2013-04-11	pm	f	Working on rollangle new procedures.
66	89	22	2013-03-28	pm	f	VAE Stef
70	132	22	2013-03-28	am	f	paramétrage SI zCosmos
\N	\N	22	2013-03-29	pm	t	
66	89	22	2013-03-29	am	f	VAE Stef
\N	\N	22	2013-04-01	pm	t	
\N	\N	22	2013-04-01	am	t	
70	132	22	2013-04-02	pm	f	paramétrage SI zCosmos
70	132	22	2013-04-02	am	f	paramétrage SI zCosmos
70	132	22	2013-04-03	pm	f	paramétrage SI zCosmos
66	89	22	2013-04-03	am	f	VAE François
66	89	22	2013-04-04	pm	f	VAE François
57	131	22	2013-04-04	am	f	Page detail
\N	\N	22	2013-04-05	pm	t	
58	131	22	2013-04-05	am	f	
57	102	22	2013-04-08	pm	f	
67	67	22	2013-04-08	am	f	Avancement SI Exodat
56	128	22	2013-04-09	pm	f	
67	66	22	2013-04-09	am	f	Xmm-Lss
70	77	22	2013-04-10	pm	f	
\N	\N	22	2013-04-10	am	t	
56	131	22	2013-04-11	am	f	API ADMIN
57	64	6	2013-04-03	am	f	Bug fixing for datasets
57	64	6	2013-04-03	pm	f	Bug fixing for datasets
72	110	15	2013-04-19	am	f	bulge
61	63	4	2013-03-29	am	f	test CRAM
61	63	4	2013-03-29	pm	f	test CRAM
\N	\N	4	2013-04-01	am	t	
\N	\N	4	2013-04-01	pm	t	
62	84	4	2013-04-02	am	f	reunion jury de concours interne CNRS
62	84	4	2013-04-02	pm	f	reunion jury de concours interne CNRS
55	65	4	2013-04-03	am	f	Agilité reunion agile pour OUSPE
\N	\N	4	2013-04-03	pm	t	
55	65	4	2013-04-04	am	f	Agilité reunion agile pour OUSPE
55	83	4	2013-04-04	pm	f	Gestion IAL
59	85	4	2013-04-05	am	f	Gestion CDDs/stages
55	83	4	2013-04-05	pm	f	Gestion IAL
55	65	4	2013-04-08	am	f	Agilité reunion agile pour OUSPE
62	84	4	2013-04-08	pm	f	reunion  président de jury
62	84	4	2013-04-09	am	f	president de jury de concours
62	84	4	2013-04-09	pm	f	president de jury de concours
62	84	4	2013-04-10	am	f	president de jury de concours
62	84	4	2013-04-10	pm	f	president de jury de concours
55	81	4	2013-03-28	am	f	Agilité reunion agile pour OUSPE
55	81	4	2013-03-28	pm	f	preparation OUSPE-AGILE -Remeber the future
57	109	15	2013-04-05	pm	f	
57	109	15	2013-04-05	am	f	g_ampli -3
57	109	15	2013-04-08	pm	f	g_ampli -3
57	109	15	2013-04-08	am	f	g_ampli -3
73	110	15	2013-04-12	pm	f	
73	110	15	2013-04-12	am	f	bulge project
57	110	15	2013-03-18	am	f	potential
57	110	15	2013-03-18	pm	f	potential
57	110	15	2013-03-19	am	f	potential
57	110	15	2013-03-19	pm	f	potential
55	112	15	2013-03-20	am	f	pastis
55	112	15	2013-03-20	pm	f	pastis
57	110	15	2013-03-21	am	f	potential
57	110	15	2013-03-21	pm	f	potential
57	112	15	2013-03-22	am	f	pastis
57	112	15	2013-03-22	pm	f	
57	112	15	2013-03-25	am	f	
57	110	15	2013-03-25	pm	f	potential
57	110	15	2013-03-26	am	f	potential
57	110	15	2013-03-26	pm	f	potential
67	112	15	2013-03-27	am	f	Cilia
57	110	15	2013-03-27	pm	f	potential
57	110	15	2013-03-28	am	f	potential
57	110	15	2013-03-28	pm	f	potential
57	110	15	2013-03-29	am	f	potential
57	110	15	2013-03-29	pm	f	potential
57	110	15	2013-04-01	am	f	potential
57	110	15	2013-04-01	pm	f	potential
57	110	15	2013-04-02	am	f	potential
57	110	15	2013-04-02	pm	f	potential
57	110	15	2013-04-03	am	f	potential
57	110	15	2013-04-03	pm	f	potential
73	110	15	2013-04-04	am	f	bulge project
73	110	15	2013-04-04	pm	f	bulge project
73	110	15	2013-04-09	am	f	bulge project
73	110	15	2013-04-09	pm	f	bulge project
73	110	15	2013-04-10	am	f	bulge project
73	110	15	2013-04-10	pm	f	bulge project
73	110	15	2013-04-11	am	f	bulge project
73	110	15	2013-04-11	pm	f	bulge project
57	115	15	2013-04-15	am	f	
57	115	15	2013-04-15	pm	f	etkflocal_boucle_f3
57	71	17	2013-04-11	am	f	Working on rollangle new procedures.
57	71	17	2013-04-12	am	f	Working on rollangle new procedures.
57	71	17	2013-04-12	pm	f	Working on rollangle new procedures.
57	71	17	2013-04-15	am	f	Working on rollangle new procedures.
57	71	17	2013-04-15	pm	f	Working on rollangle new procedures.
57	71	17	2013-04-16	am	f	Working on rollangle new procedures.
57	71	17	2013-04-16	pm	f	Working on rollangle new procedures.
57	97	8	2013-04-09	pm	f	
57	97	8	2013-04-09	am	f	
70	98	8	2013-04-10	pm	f	
57	89	8	2013-04-10	am	f	
57	89	8	2013-04-11	pm	f	
57	89	8	2013-04-11	am	f	
57	89	8	2013-04-12	pm	f	
57	89	8	2013-04-12	am	f	
57	97	8	2013-04-15	pm	f	
59	84	8	2013-04-15	am	f	
57	97	8	2013-04-16	pm	f	
\N	\N	8	2013-04-16	am	t	
73	110	15	2013-04-16	am	f	potential
73	110	15	2013-04-16	pm	f	bulge
57	110	15	2013-04-17	am	f	
57	110	15	2013-04-17	pm	f	potential
67	115	15	2013-04-18	am	f	keek-off
73	110	15	2013-04-18	pm	f	
57	71	17	2013-04-18	am	f	Cleaning and integrating new roll angle procedures.
57	71	17	2013-04-18	pm	f	Documentation of new roll angle procedures.
67	71	17	2013-04-19	am	f	
73	110	15	2013-04-19	pm	f	nfw x h93
57	97	8	2013-04-17	pm	f	
57	97	8	2013-04-17	am	f	
57	97	8	2013-04-18	pm	f	
\N	\N	8	2013-04-18	am	t	
57	97	8	2013-04-19	pm	f	
57	97	8	2013-04-19	am	f	
57	97	8	2013-04-22	am	f	
57	115	15	2013-04-22	am	f	f3.2
73	110	15	2013-04-22	pm	f	bulge
67	110	15	2013-04-23	am	f	
57	112	15	2013-04-23	pm	f	cilia
57	97	8	2013-04-22	pm	f	
57	97	8	2013-04-23	pm	f	
57	97	8	2013-04-23	am	f	
57	71	17	2013-04-22	am	f	Working on pipeline rates plots.
57	71	17	2013-04-22	pm	f	Working on pipeline rates plots.
57	71	17	2013-04-23	am	f	Working on pipeline rates plots.
57	71	17	2013-04-23	pm	f	Working on pipeline rates plots.
59	71	17	2013-04-24	am	f	Academic defense.
63	71	17	2013-04-24	pm	f	Requested new quotes for pipeline expansion hardware.
67	89	22	2013-04-12	am	f	SO5
57	77	22	2013-04-15	pm	f	exportFile
66	89	22	2013-04-15	am	f	
67	128	22	2013-04-16	pm	f	
57	77	22	2013-04-17	pm	f	
70	77	22	2013-04-17	am	f	
70	77	22	2013-04-18	pm	f	
70	77	22	2013-04-18	am	f	
70	77	22	2013-04-19	pm	f	
70	77	22	2013-04-19	am	f	
69	77	22	2013-04-22	pm	f	
67	89	22	2013-04-22	am	f	
69	77	22	2013-04-23	am	f	
71	71	17	2013-04-25	am	f	Updating & cleaning workstations and servers.
57	112	15	2013-04-24	am	f	potential
57	110	15	2013-04-24	pm	f	
57	115	15	2013-04-25	am	f	
\N	\N	8	2013-04-24	pm	t	
\N	\N	8	2013-04-24	am	t	
70	98	8	2013-04-25	am	f	
\N	\N	5	2013-04-01	am	t	
\N	\N	5	2013-04-01	pm	t	
55	71	16	2013-04-10	am	f	
55	71	16	2013-04-10	pm	f	
55	71	16	2013-04-11	am	f	
55	71	16	2013-04-11	pm	f	
61	71	16	2013-04-12	am	f	
61	71	16	2013-04-12	pm	f	
61	71	16	2013-04-15	am	f	
61	71	16	2013-04-15	pm	f	
57	71	16	2013-04-16	am	f	
57	71	16	2013-04-16	pm	f	
57	71	16	2013-04-17	am	f	
55	71	16	2013-04-17	pm	f	
55	71	16	2013-04-18	am	f	
55	71	16	2013-04-18	pm	f	
55	71	16	2013-04-19	am	f	
63	89	5	2013-03-26	am	f	cluster
63	89	5	2013-03-26	pm	f	cluster
63	89	5	2013-03-27	am	f	cluster
63	89	5	2013-03-27	pm	f	cluster
63	89	5	2013-03-28	am	f	cluster
63	89	5	2013-03-28	pm	f	cluster
63	89	5	2013-03-29	am	f	cluster
63	89	5	2013-03-29	pm	f	cluster
56	70	5	2013-04-02	am	f	Montage
55	100	5	2013-04-02	pm	f	git
55	100	5	2013-04-03	am	f	git
55	100	5	2013-04-03	pm	f	git
55	100	5	2013-04-04	am	f	git
55	100	5	2013-04-04	pm	f	git
55	100	5	2013-04-05	am	f	git
55	100	5	2013-04-05	pm	f	git
71	85	5	2013-04-08	am	f	
71	85	5	2013-04-08	pm	f	
56	85	5	2013-04-09	am	f	people
56	85	5	2013-04-09	pm	f	people
67	100	5	2013-04-10	am	f	
56	85	5	2013-04-10	pm	f	people
56	85	5	2013-04-11	am	f	people
56	85	5	2013-04-11	pm	f	gitlab
56	85	5	2013-04-12	am	f	gitlab
55	85	5	2013-04-12	pm	f	lam.fr
55	85	5	2013-04-15	am	f	lam.fr
55	85	5	2013-04-15	pm	f	lam.fr
55	85	5	2013-04-16	am	f	lam.fr
55	85	5	2013-04-16	pm	f	lam.fr
55	85	5	2013-04-17	am	f	lam.fr
55	85	5	2013-04-17	pm	f	lam.fr
56	85	5	2013-04-18	am	f	lam.fr
56	85	5	2013-04-18	pm	f	lam.fr
63	89	5	2013-04-19	am	f	
55	100	5	2013-04-19	pm	f	gitolite
59	103	5	2013-04-22	am	f	administration
61	66	5	2013-04-22	pm	f	pandora.ez
59	103	5	2013-04-23	am	f	
56	66	5	2013-04-23	pm	f	pandora.ez
56	85	5	2013-04-24	am	f	lam alias sites
56	85	5	2013-04-24	pm	f	lam alias sites
56	85	5	2013-04-25	am	f	lam alias sites
57	70	28	2013-04-01	am	f	Téléchargement/organisation des données MALT 90/HI-GALAnalyse de régions HII
57	70	28	2013-04-01	pm	f	Téléchargement/organisation des données MALT 90/HI-GALAnalyse de régions HII
57	70	28	2013-04-02	am	f	Téléchargement/organisation des données MALT 90/HI-GALAnalyse de régions HII
57	70	28	2013-04-02	pm	f	Téléchargement/organisation des données MALT 90/HI-GALAnalyse de régions HII
57	70	28	2013-04-03	am	f	Téléchargement/organisation des données MALT 90/HI-GALAnalyse de régions HII
57	70	28	2013-04-03	pm	f	Téléchargement/organisation des données MALT 90/HI-GALAnalyse de régions HII
57	70	28	2013-04-04	am	f	Téléchargement/organisation des données MALT 90/HI-GAL
57	70	28	2013-04-04	pm	f	Téléchargement/organisation des données MALT 90/HI-GAL
57	70	28	2013-04-05	am	f	Téléchargement/organisation des données MALT 90/HI-GAL
57	70	28	2013-04-05	pm	f	Téléchargement/organisation des données MALT 90/HI-GAL
57	70	28	2013-04-08	am	f	Préparation de données test pour formation Cassis
57	70	28	2013-04-08	pm	f	Préparation de données test pour formation Cassis
62	70	28	2013-04-09	am	f	Formation Cassis à IRAP (Toulouse)
62	70	28	2013-04-09	pm	f	Formation Cassis à IRAP (Toulouse)
62	70	28	2013-04-10	am	f	Formation Cassis à IRAP (Toulouse)
62	70	28	2013-04-10	pm	f	Formation Cassis à IRAP (Toulouse)
57	70	28	2013-04-11	am	f	Automatisation du fitting de spectres moléculaires par Cassis
57	70	28	2013-04-11	pm	f	Automatisation du fitting de spectres moléculaires par Cassis
57	70	28	2013-04-12	am	f	Automatisation du fitting de spectres moléculaires par Cassis
57	70	28	2013-04-12	pm	f	Automatisation du fitting de spectres moléculaires par Cassis
57	70	28	2013-04-15	am	f	Automatisation du fitting de spectres moléculaires par Cassis
57	70	28	2013-04-15	pm	f	Automatisation du fitting de spectres moléculaires par Cassis
57	70	28	2013-04-16	am	f	Automatisation du fitting de spectres moléculaires par Cassis
57	70	28	2013-04-16	pm	f	Automatisation du fitting de spectres moléculaires par Cassis
57	70	28	2013-04-17	am	f	Automatisation du fitting de spectres moléculaires par Cassis
57	70	28	2013-04-17	pm	f	Automatisation du fitting de spectres moléculaires par Cassis
57	70	28	2013-04-18	am	f	Automatisation du fitting de spectres moléculaires par Cassis
57	70	28	2013-04-18	pm	f	Automatisation du fitting de spectres moléculaires par Cassis
57	70	28	2013-04-19	am	f	Préparation de résultats préléminaires de fitting Cassis sur des régions test
57	70	28	2013-04-19	pm	f	Préparation de résultats préléminaires de fitting Cassis sur des régions test
57	70	28	2013-04-22	am	f	Préparation de résultats préléminaires de fitting Cassis sur des régions test
57	70	28	2013-04-22	pm	f	Préparation de résultats préléminaires de fitting Cassis sur des régions test
57	70	28	2013-04-23	am	f	Automatisation du fitting de spectres moléculaires par Cassis
67	70	28	2013-04-23	pm	f	Réunion de validation de l'utilisation de Cassis pour la suite du projet
57	70	28	2013-04-24	am	f	Automatisation du fitting de spectres moléculaires par Cassis
57	70	28	2013-04-24	pm	f	Automatisation du fitting de spectres moléculaires par Cassis
57	70	28	2013-04-25	am	f	Automatisation du fitting de spectres moléculaires par Cassis
57	70	28	2013-04-25	pm	f	Automatisation du fitting de spectres moléculaires par Cassis
67	85	4	2013-04-11	am	f	CPCS
55	81	4	2013-04-11	pm	f	AGILE Stories
55	81	4	2013-04-12	am	f	AGILE Stories
59	85	4	2013-04-12	pm	f	Licences IDL - reunion commerciaux
\N	\N	4	2013-04-15	am	t	
\N	\N	4	2013-04-15	pm	t	
\N	\N	4	2013-04-16	am	t	
\N	\N	4	2013-04-16	pm	t	
\N	\N	4	2013-04-17	am	t	
\N	\N	4	2013-04-17	pm	t	
\N	\N	4	2013-04-18	am	t	
\N	\N	4	2013-04-18	pm	t	
\N	\N	4	2013-04-19	am	t	
\N	\N	4	2013-04-19	pm	t	
66	89	4	2013-04-22	am	f	preparation Meeting
66	89	4	2013-04-22	pm	f	preparation Meeting
55	83	4	2013-04-23	am	f	analyse preparation reunion equipe system
55	83	4	2013-04-23	pm	f	analyse preparation reunion equipe system
55	83	4	2013-04-24	am	f	analyse preparation reunion equipe system
55	83	4	2013-04-24	pm	f	analyse preparation reunion equipe system
66	89	4	2013-04-25	am	f	Stagiaires
66	89	4	2013-04-25	pm	f	Dossier concours et gestion CDDs
55	65	4	2013-04-26	am	f	PTF
55	65	4	2013-04-26	pm	f	PTF
55	91	9	2012-10-05	pm	f	hjk
58	89	9	2012-10-15	am	f	Voyonrs voir 
57	65	9	2013-04-01	am	f	
57	65	9	2013-04-01	pm	f	
57	65	9	2013-04-02	am	f	
57	65	9	2013-04-02	pm	f	
57	65	9	2013-04-03	am	f	
57	65	9	2013-04-03	pm	f	
57	65	9	2013-04-04	am	f	
57	65	9	2013-04-04	pm	f	
57	65	9	2013-04-05	am	f	
57	65	9	2013-04-05	pm	f	
57	65	9	2013-04-08	am	f	
57	65	9	2013-04-08	pm	f	
57	65	9	2013-04-09	am	f	
57	65	9	2013-04-09	pm	f	
57	65	9	2013-04-10	am	f	
57	65	9	2013-04-10	pm	f	
57	65	9	2013-04-11	am	f	
57	65	9	2013-04-11	pm	f	
57	65	9	2013-04-12	am	f	
57	65	9	2013-04-12	pm	f	
\N	\N	9	2013-04-15	am	t	
\N	\N	9	2013-04-15	pm	t	
\N	\N	9	2013-04-16	am	t	
\N	\N	9	2013-04-16	pm	t	
\N	\N	9	2013-04-17	am	t	
\N	\N	9	2013-04-17	pm	t	
\N	\N	9	2013-04-18	am	t	
\N	\N	9	2013-04-18	pm	t	
\N	\N	9	2013-04-19	am	t	
\N	\N	9	2013-04-19	pm	t	
\N	\N	9	2013-04-22	am	t	
\N	\N	9	2013-04-22	pm	t	
\N	\N	9	2013-04-23	am	t	
\N	\N	9	2013-04-23	pm	t	
\N	\N	9	2013-04-24	am	t	
\N	\N	9	2013-04-24	pm	t	
57	65	9	2013-04-25	am	f	
57	65	9	2013-04-25	pm	f	
57	65	9	2013-04-26	am	f	
57	65	9	2013-04-26	pm	f	
\N	\N	14	2013-03-08	pm	t	
\N	\N	14	2013-03-08	am	t	
\N	\N	14	2013-03-25	pm	t	
\N	\N	14	2013-03-25	am	t	
\N	\N	14	2013-03-26	pm	t	
\N	\N	14	2013-03-26	am	t	
\N	\N	14	2013-03-27	pm	t	
\N	\N	14	2013-03-27	am	t	
\N	\N	14	2013-03-28	pm	t	
\N	\N	14	2013-03-28	am	t	
\N	\N	14	2013-03-29	pm	t	
\N	\N	14	2013-03-29	am	t	
\N	\N	14	2013-04-01	pm	t	
\N	\N	14	2013-04-01	am	t	
\N	\N	14	2013-04-02	pm	t	
\N	\N	14	2013-04-02	am	t	
60	89	14	2013-04-10	am	f	Stagiaires College
\N	\N	19	2013-03-25	pm	t	
\N	\N	19	2013-03-25	am	t	
\N	\N	19	2013-03-26	pm	t	
\N	\N	19	2013-03-26	am	t	
\N	\N	19	2013-03-27	pm	t	
\N	\N	19	2013-03-27	am	t	
\N	\N	19	2013-03-28	pm	t	
\N	\N	19	2013-03-28	am	t	
\N	\N	19	2013-03-29	pm	t	
\N	\N	19	2013-03-29	am	t	
\N	\N	19	2013-04-01	pm	t	
\N	\N	19	2013-04-01	am	t	
70	67	19	2013-04-15	pm	f	Mise à jour base de données ExoDat livraison bulge
70	67	19	2013-04-15	am	f	Mise à jour base de données ExoDat livraison bulge
70	67	19	2013-04-16	pm	f	Mise à jour base de données ExoDat livraison bulge
70	67	19	2013-04-16	am	f	Mise à jour base de données ExoDat livraison bulge
70	67	19	2013-04-17	pm	f	Mise à jour base de données ExoDat livraison bulge
70	67	19	2013-04-17	am	f	Mise à jour base de données ExoDat livraison bulge
70	67	19	2013-04-18	pm	f	Mise à jour base de données ExoDat livraison bulge
70	67	19	2013-04-18	am	f	Mise à jour base de données ExoDat livraison bulge
70	67	19	2013-04-19	pm	f	Mise à jour base de données ExoDat livraison bulge
70	67	19	2013-04-19	am	f	Mise à jour base de données ExoDat livraison bulge
57	67	19	2013-04-26	pm	f	Instance ANIS ExoDat
57	67	19	2013-04-26	am	f	Instance ANIS ExoDat
57	71	17	2013-04-25	pm	f	Working on new SoHO orbit procedures.
57	71	17	2013-04-26	am	f	Working on new SoHO orbit procedures.
57	71	17	2013-04-26	pm	f	Working on new SoHO orbit procedures.
67	67	19	2013-04-08	am	f	Reunion avancement ExoDat
70	67	19	2013-03-14	am	f	Mise à jour ExoDat contamination C1
57	67	19	2013-03-11	pm	f	Instance ANIS ExoDat
57	67	19	2013-03-11	am	f	Instance ANIS ExoDat
57	67	19	2013-03-12	pm	f	Instance ANIS ExoDat
57	67	19	2013-03-12	am	f	Instance ANIS ExoDat
57	67	19	2013-03-13	pm	f	Instance ANIS ExoDat
57	67	19	2013-03-13	am	f	Instance ANIS ExoDat
57	67	19	2013-03-14	pm	f	Instance ANIS ExoDat
57	67	19	2013-03-15	pm	f	Instance ANIS ExoDat
57	67	19	2013-03-15	am	f	Instance ANIS ExoDat
66	89	22	2013-04-11	pm	f	dossier Concours Interne SG&FA
57	67	19	2013-02-26	am	f	Developpement ANIS
57	67	19	2013-02-27	pm	f	Developpement ANIS
57	67	19	2013-02-27	am	f	Developpement ANIS
57	67	19	2013-04-25	pm	f	Developpement finding-charts
67	89	19	2013-03-18	pm	f	Reunion APEC
56	67	19	2013-03-18	am	f	Déploiement instance ANIS ExoDat serveur production
67	89	19	2013-04-22	am	f	CeSAM chat, présentation ANIS
56	67	19	2013-04-24	pm	f	Livraison du bugle CoRoT
70	98	8	2013-04-25	pm	f	
70	98	8	2013-04-26	pm	f	
70	98	8	2013-04-26	am	f	
73	110	15	2013-04-25	pm	f	
57	112	15	2013-04-26	am	f	cilia
73	110	15	2013-04-26	pm	f	bulge
\N	\N	22	2013-02-22	pm	t	
57	131	22	2013-02-28	am	f	
70	102	22	2013-03-01	am	f	
56	128	22	2013-03-11	pm	f	Framework ANIS
57	131	22	2013-03-14	pm	f	API ANIS, upd nouvelles fonctionnalités 
60	125	19	2013-03-08	am	f	jQueryUI
59	89	19	2013-04-02	pm	f	Dossier VAE
59	89	19	2013-04-02	am	f	Dossier VAE
59	89	19	2013-04-03	pm	f	Dossier VAE
59	89	19	2013-04-03	am	f	Dossier VAE
59	89	19	2013-04-04	pm	f	Dossier VAE
59	89	19	2013-04-04	am	f	Dossier VAE
59	89	19	2013-04-05	pm	f	Dossier VAE
59	89	19	2013-04-05	am	f	Dossier VAE
57	67	19	2013-03-04	am	f	Développement ANIS
57	67	19	2013-03-05	pm	f	Développement ANIS
57	131	19	2013-03-19	pm	f	Développement ANIS
57	131	19	2013-03-19	am	f	Développement ANIS
57	131	19	2013-03-20	pm	f	Développement ANIS
57	131	19	2013-03-20	am	f	Développement ANIS
57	131	19	2013-03-21	pm	f	Développement ANIS
57	131	19	2013-03-21	am	f	Développement ANIS
57	131	19	2013-03-22	pm	f	Développement ANIS
57	131	19	2013-03-22	am	f	Développement ANIS
57	131	19	2013-04-08	pm	f	Développement ANIS
57	131	19	2013-04-09	pm	f	Développement ANIS
57	131	19	2013-04-09	am	f	Développement ANIS
57	131	19	2013-04-10	pm	f	Développement ANIS
57	131	19	2013-04-10	am	f	Développement ANIS
59	89	19	2013-04-11	pm	f	Dossier concours interne
59	89	19	2013-04-11	am	f	Dossier concours interne
59	89	19	2013-04-12	pm	f	Dossier concours interne
59	89	19	2013-04-12	am	f	Dossier concours interne
59	89	19	2013-04-23	am	f	Papier VAE
59	89	19	2013-04-24	am	f	Papier VAE
59	89	19	2013-04-25	am	f	Papier VAE
57	67	19	2013-02-28	pm	f	Développement ANIS
57	67	19	2013-02-28	am	f	Développement ANIS
57	67	19	2013-03-01	pm	f	Développement ANIS
57	67	19	2013-03-01	am	f	Développement ANIS
57	67	19	2013-03-04	pm	f	Développement ANIS
57	67	19	2013-03-05	am	f	Développement ANIS
57	67	19	2013-03-06	pm	f	Développement ANIS
57	67	19	2013-03-06	am	f	Développement ANIS
57	67	19	2013-03-07	pm	f	Développement ANIS
57	67	19	2013-03-07	am	f	Développement ANIS
57	67	19	2013-04-22	pm	f	Developpement finding-charts
57	67	19	2013-04-23	pm	f	Developpement finding-charts
70	77	22	2013-04-12	pm	f	
57	77	22	2013-04-16	am	f	data description
57	128	22	2013-04-23	pm	f	
58	131	22	2013-04-24	pm	f	
70	128	22	2013-04-24	am	f	
58	131	22	2013-04-25	pm	f	
67	131	22	2013-04-25	am	f	Instance Sphere
70	102	22	2013-04-26	pm	f	
70	102	22	2013-04-26	am	f	
60	125	19	2013-03-08	pm	f	jQueryUI
57	67	19	2013-02-26	pm	f	Developpement ANIS
57	66	20	2013-02-27	pm	f	ANIS
57	66	20	2013-02-27	am	f	ANIS
57	66	20	2013-02-28	pm	f	ANIS
57	66	20	2013-02-28	am	f	ANIS
57	66	20	2013-03-01	pm	f	ANIS
57	66	20	2013-03-01	am	f	ANIS
57	66	20	2013-03-04	pm	f	ANIS
57	66	20	2013-03-04	am	f	ANIS
57	66	20	2013-03-05	pm	f	ANIS
57	66	20	2013-03-05	am	f	ANIS
57	66	20	2013-03-06	pm	f	ANIS
57	66	20	2013-03-06	am	f	ANIS
60	125	20	2013-03-07	pm	f	Prepa cours jQuery
60	125	20	2013-03-07	am	f	Prepa cours jQuery
60	125	20	2013-03-08	pm	f	
60	125	20	2013-03-08	am	f	
57	66	20	2013-03-11	pm	f	ANIS
57	66	20	2013-03-11	am	f	ANIS
57	66	20	2013-03-12	pm	f	ANIS
57	66	20	2013-03-12	am	f	ANIS
57	66	20	2013-03-13	pm	f	ANIS
57	66	20	2013-03-13	am	f	ANIS
70	66	20	2013-03-14	pm	f	Galex
70	66	20	2013-03-14	am	f	Galex
56	66	20	2013-03-15	pm	f	Galex
57	66	20	2013-03-15	am	f	Galex
67	89	20	2013-03-18	pm	f	Apec
70	66	20	2013-03-18	am	f	CFHTLS
57	66	20	2013-03-19	pm	f	CFHTLS
57	66	20	2013-03-19	am	f	CFHTLS
56	66	20	2013-03-20	pm	f	CFHTLS
56	66	20	2013-03-20	am	f	CFHTLS
71	89	20	2013-03-21	pm	f	GIT
71	89	20	2013-03-21	am	f	GIT
57	102	20	2013-03-22	pm	f	Gestion des requetes ANIS
57	102	20	2013-03-22	am	f	Gestion des requetes ANIS
57	102	20	2013-03-25	pm	f	Gestion des requetes ANIS
57	102	20	2013-03-25	am	f	Gestion des requetes ANIS
57	102	20	2013-03-26	pm	f	Gestion des requetes ANIS
57	102	20	2013-03-26	am	f	Gestion des requetes ANIS
59	89	20	2013-03-27	pm	f	Dossier VAE
59	89	20	2013-03-27	am	f	Dossier VAE
59	89	20	2013-03-28	pm	f	Dossier VAE
59	89	20	2013-03-28	am	f	Dossier VAE
\N	\N	20	2013-03-29	pm	t	
59	89	20	2013-03-29	am	f	Dossier VAE
57	66	20	2013-04-01	pm	f	Gestion des images
57	66	20	2013-04-01	am	f	Gestion des images
70	132	20	2013-04-02	pm	f	
70	132	20	2013-04-02	am	f	
70	132	20	2013-04-03	pm	f	
70	132	20	2013-04-03	am	f	
70	66	20	2013-04-04	pm	f	FabryPerot Sitools1
70	66	20	2013-04-04	am	f	FabryPerot Sitools1
57	66	20	2013-04-05	pm	f	
57	66	20	2013-04-05	am	f	
57	131	20	2013-04-08	pm	f	Reecriture des controlleurs
57	131	20	2013-04-08	am	f	Reecriture des controlleurs
57	131	20	2013-04-09	pm	f	Reecriture des controlleurs
67	66	20	2013-04-09	am	f	Xmm-Lss
57	131	20	2013-04-10	pm	f	Reecriture des controlleurs
57	131	20	2013-04-10	am	f	Reecriture des controlleurs
59	89	20	2013-04-11	pm	f	Dossier concours interne
59	89	20	2013-04-11	am	f	Dossier concours interne
59	89	20	2013-04-12	pm	f	Dossier concours interne
59	89	20	2013-04-12	am	f	Dossier concours interne
\N	\N	20	2013-04-15	pm	t	
\N	\N	20	2013-04-15	am	t	
\N	\N	20	2013-04-16	pm	t	
\N	\N	20	2013-04-16	am	t	
\N	\N	20	2013-04-17	pm	t	
\N	\N	20	2013-04-17	am	t	
\N	\N	20	2013-04-18	pm	t	
\N	\N	20	2013-04-18	am	t	
\N	\N	20	2013-04-19	pm	t	
\N	\N	20	2013-04-19	am	t	
57	131	20	2013-04-22	pm	f	
67	89	20	2013-04-22	am	f	Prepa cesam chat
57	131	20	2013-04-23	pm	f	
59	89	20	2013-04-23	am	f	Dossier concours interne pb papiers
57	131	20	2013-04-24	pm	f	
59	89	20	2013-04-24	am	f	Dossier concours interne pb papiers
57	131	20	2013-04-25	pm	f	
59	89	20	2013-04-25	am	f	Dossier concours interne pb papiers
57	66	20	2013-04-26	pm	f	Script insertion images
57	131	20	2013-04-26	am	f	Debug
66	89	4	2013-04-29	am	f	
\N	\N	24	2013-01-01	am	t	
\N	\N	24	2013-01-01	pm	t	
59	69	24	2013-01-02	am	f	
59	69	24	2013-01-02	pm	f	
\N	\N	24	2013-01-03	am	t	
\N	\N	24	2013-01-03	pm	t	
\N	\N	24	2013-01-04	am	t	
\N	\N	24	2013-01-04	pm	t	
59	71	24	2013-01-07	am	f	
59	71	24	2013-01-07	pm	f	
59	69	24	2013-01-08	am	f	
59	69	24	2013-01-08	pm	f	
59	69	24	2013-01-09	am	f	
59	69	24	2013-01-09	pm	f	
59	69	24	2013-01-10	am	f	
59	69	24	2013-01-10	pm	f	
59	69	24	2013-01-11	am	f	
59	69	24	2013-01-11	pm	f	
59	71	24	2013-01-14	am	f	
59	71	24	2013-01-14	pm	f	
59	69	24	2013-01-15	am	f	
59	69	24	2013-01-15	pm	f	
59	69	24	2013-01-16	am	f	
59	69	24	2013-01-16	pm	f	
59	69	24	2013-01-17	am	f	
59	69	24	2013-01-17	pm	f	
59	69	24	2013-01-18	am	f	
59	69	24	2013-01-18	pm	f	
59	71	24	2013-01-21	am	f	
59	71	24	2013-01-21	pm	f	
59	69	24	2013-01-22	am	f	
59	69	24	2013-01-22	pm	f	
59	69	24	2013-01-23	am	f	
59	69	24	2013-01-23	pm	f	
59	69	24	2013-01-24	am	f	
59	69	24	2013-01-24	pm	f	
59	69	24	2013-01-25	am	f	
59	69	24	2013-01-25	pm	f	
\N	\N	24	2013-01-28	am	t	
59	71	24	2013-01-28	pm	f	
59	69	24	2013-01-29	am	f	
59	69	24	2013-01-29	pm	f	
59	69	24	2013-01-30	am	f	
59	69	24	2013-01-30	pm	f	
59	69	24	2013-01-31	am	f	
59	69	24	2013-01-31	pm	f	
59	69	24	2013-02-01	am	f	
59	69	24	2013-02-01	pm	f	
59	71	24	2013-02-04	am	f	
59	71	24	2013-02-04	pm	f	
59	69	24	2013-02-05	am	f	
59	69	24	2013-02-05	pm	f	
59	69	24	2013-02-06	am	f	
59	69	24	2013-02-06	pm	f	
59	69	24	2013-02-07	am	f	
59	69	24	2013-02-07	pm	f	
59	69	24	2013-02-08	am	f	
59	69	24	2013-02-08	pm	f	
59	71	24	2013-02-11	am	f	
59	71	24	2013-02-11	pm	f	
59	81	24	2013-02-12	am	f	
59	81	24	2013-02-12	pm	f	
59	81	24	2013-02-13	am	f	
59	81	24	2013-02-13	pm	f	
59	69	24	2013-02-14	am	f	
59	81	24	2013-02-14	pm	f	
59	69	24	2013-02-15	am	f	
59	69	24	2013-02-15	pm	f	
\N	\N	24	2013-02-18	am	t	
\N	\N	24	2013-02-18	pm	t	
\N	\N	24	2013-02-19	am	t	
\N	\N	24	2013-02-19	pm	t	
\N	\N	24	2013-02-20	am	t	
\N	\N	24	2013-02-20	pm	t	
\N	\N	24	2013-02-21	am	t	
\N	\N	24	2013-02-21	pm	t	
\N	\N	24	2013-02-22	am	t	
\N	\N	24	2013-02-22	pm	t	
59	71	24	2013-02-25	am	f	
59	84	24	2013-02-25	pm	f	pcigale
59	69	24	2013-02-26	am	f	
59	69	24	2013-02-26	pm	f	
59	69	24	2013-02-27	am	f	
59	69	24	2013-02-27	pm	f	
59	69	24	2013-02-28	am	f	
59	69	24	2013-02-28	pm	f	
59	69	24	2013-03-01	am	f	
59	69	24	2013-03-01	pm	f	
59	71	24	2013-03-04	am	f	
59	71	24	2013-03-04	pm	f	
59	89	24	2013-03-05	am	f	
59	69	24	2013-03-05	pm	f	
59	69	24	2013-03-06	am	f	
59	69	24	2013-03-06	pm	f	
59	69	24	2013-03-07	am	f	
59	69	24	2013-03-07	pm	f	
59	69	24	2013-03-08	am	f	
59	69	24	2013-03-08	pm	f	
\N	\N	24	2013-03-11	am	t	
\N	\N	24	2013-03-11	pm	t	
\N	\N	24	2013-03-12	am	t	
\N	\N	24	2013-03-12	pm	t	
59	69	24	2013-03-13	am	f	
59	69	24	2013-03-13	pm	f	
59	69	24	2013-03-14	am	f	
59	81	24	2013-03-14	pm	f	
59	69	24	2013-03-15	am	f	
59	69	24	2013-03-15	pm	f	
59	71	24	2013-03-18	am	f	
59	71	24	2013-03-18	pm	f	
59	69	24	2013-03-19	am	f	
59	69	24	2013-03-19	pm	f	
59	69	24	2013-03-20	am	f	
59	69	24	2013-03-20	pm	f	
59	69	24	2013-03-21	am	f	
59	81	24	2013-03-21	pm	f	
59	69	24	2013-03-22	am	f	
59	69	24	2013-03-22	pm	f	
59	71	24	2013-03-25	am	f	
59	71	24	2013-03-25	pm	f	
59	69	24	2013-03-26	am	f	
59	69	24	2013-03-26	pm	f	
59	69	24	2013-03-27	am	f	
59	69	24	2013-03-27	pm	f	
59	69	24	2013-03-28	am	f	
59	81	24	2013-03-28	pm	f	
59	69	24	2013-03-29	am	f	
\N	\N	24	2013-03-29	pm	t	
\N	\N	24	2013-04-01	am	t	
\N	\N	24	2013-04-01	pm	t	
59	71	24	2013-04-02	am	f	
59	69	24	2013-04-02	pm	f	
59	69	24	2013-04-03	am	f	
59	69	24	2013-04-03	pm	f	
59	69	24	2013-04-04	am	f	
59	81	24	2013-04-04	pm	f	
59	69	24	2013-04-05	am	f	
59	69	24	2013-04-05	pm	f	
59	71	24	2013-04-08	am	f	
59	71	24	2013-04-08	pm	f	
59	69	24	2013-04-09	am	f	
59	69	24	2013-04-09	pm	f	
59	69	24	2013-04-10	am	f	
59	69	24	2013-04-10	pm	f	
59	69	24	2013-04-11	am	f	
59	81	24	2013-04-11	pm	f	
59	69	24	2013-04-12	am	f	
59	69	24	2013-04-12	pm	f	
59	71	24	2013-04-15	am	f	
59	71	24	2013-04-15	pm	f	
59	69	24	2013-04-16	am	f	
59	69	24	2013-04-16	pm	f	
59	69	24	2013-04-17	am	f	
59	69	24	2013-04-17	pm	f	
59	69	24	2013-04-18	am	f	
59	81	24	2013-04-18	pm	f	
59	81	24	2013-04-19	am	f	
59	81	24	2013-04-19	pm	f	
\N	\N	24	2013-04-22	am	t	
\N	\N	24	2013-04-22	pm	t	
\N	\N	24	2013-04-23	am	t	
\N	\N	24	2013-04-23	pm	t	
\N	\N	24	2013-04-24	am	t	
\N	\N	24	2013-04-24	pm	t	
\N	\N	24	2013-04-25	am	t	
\N	\N	24	2013-04-25	pm	t	
\N	\N	24	2013-04-26	am	t	
\N	\N	24	2013-04-26	pm	t	
67	92	6	2013-03-07	am	f	OU-SIM/EMA Workshop - Groningen
69	83	6	2013-03-13	am	f	Data Model
69	83	6	2013-03-13	pm	f	Data Model
57	64	6	2013-03-14	am	f	WISH plugin
67	83	6	2013-03-14	pm	f	Teleconf with Martin/Marco
69	83	6	2013-03-15	am	f	Data Model
69	83	6	2013-03-15	pm	f	Data Model
57	64	6	2013-03-18	am	f	Bug fixing
67	84	6	2013-03-18	pm	f	Meeting with APEC representatives
67	83	6	2013-03-19	am	f	ST Meeting - Paris IAP
67	83	6	2013-03-19	pm	f	ST Meeting - Paris IAP
67	83	6	2013-03-20	am	f	ST Meeting - Paris IAP
67	83	6	2013-03-20	pm	f	ST Meeting - Paris IAP
57	64	6	2013-03-21	am	f	WISH plugin
57	64	6	2013-03-21	pm	f	WISH plugin
67	92	6	2013-03-22	am	f	OU-SIM technical implementation teleconf
57	64	6	2013-03-22	pm	f	Bug #686 / WISH plugin
57	64	6	2013-03-25	am	f	Bug #686 / other small bugs
57	64	6	2013-03-25	pm	f	Bug #686 / other small bugs
69	83	6	2013-03-26	am	f	Task Intefraces in Data Model
69	83	6	2013-03-26	pm	f	Task Intefraces in Data Model
69	83	6	2013-03-27	am	f	Task Intefraces in Data Model
69	83	6	2013-03-27	pm	f	Task Intefraces in Data Model
69	83	6	2013-03-28	am	f	Task Intefraces in Data Model
67	83	6	2013-03-28	pm	f	teleconf with Martin
69	92	6	2013-03-29	am	f	Data Model
69	83	6	2013-03-29	pm	f	Data Model
69	92	6	2013-04-01	am	f	Data Model
57	64	6	2013-04-01	pm	f	Bug fixing
67	92	6	2013-04-02	am	f	teleconf with Christophe/Eric
57	64	6	2013-04-02	pm	f	Plot drag and drop support for cubes
57	64	6	2013-04-04	am	f	Bug #721
57	64	6	2013-04-04	pm	f	Bug #721
57	64	6	2013-04-05	am	f	Bug #463
57	64	6	2013-04-05	pm	f	Feature #631
57	64	6	2013-04-08	am	f	Bug #468
57	64	6	2013-04-08	pm	f	Bug #468
57	64	6	2013-04-09	am	f	Bug fixing
57	64	6	2013-04-09	pm	f	Bug fixing
57	83	6	2013-04-10	am	f	DataContainer finder tool
57	83	6	2013-04-10	pm	f	DataContainer finder tool
69	83	6	2013-04-11	am	f	Data Model
69	83	6	2013-04-11	pm	f	Data Model
69	83	6	2013-04-12	am	f	Data Model
69	83	6	2013-04-12	pm	f	Data Model
57	64	6	2013-04-15	am	f	Feature #745
57	64	6	2013-04-15	pm	f	Feature #745
57	64	6	2013-04-16	am	f	Feature #745
57	64	6	2013-04-16	pm	f	Feature #745
57	64	6	2013-04-17	am	f	Feature #745
57	64	6	2013-04-17	pm	f	Feature #745
57	64	6	2013-04-18	am	f	Bug fixing
57	64	6	2013-04-18	pm	f	Bug fixing
57	64	6	2013-04-19	am	f	Bug fixing
57	64	6	2013-04-19	pm	f	Bug fixing
57	83	6	2013-04-22	am	f	FITS description in XML files
57	83	6	2013-04-22	pm	f	FITS description in XML files
57	83	6	2013-04-23	am	f	FITS description in XML files
57	83	6	2013-04-23	pm	f	FITS description in XML files
57	83	6	2013-04-24	am	f	FITS description in XML files
57	83	6	2013-04-24	pm	f	FITS description in XML files
67	83	6	2013-04-25	am	f	ST Meeting - Garching
67	83	6	2013-04-25	pm	f	ST Meeting - Garching
69	83	6	2013-04-26	am	f	Data Model
69	83	6	2013-04-26	pm	f	Data Model
69	83	6	2013-04-29	am	f	Data Model
67	83	6	2013-04-29	pm	f	TIPS/IAL/EMA integration teleconf
58	67	14	2013-04-22	pm	f	Preparation au redemarrage corot (ou pas)
66	67	14	2013-04-22	am	f	N2 Giovanni
58	67	14	2013-04-23	pm	f	Preparation au redemarrage corot (ou pas)
58	67	14	2013-04-23	am	f	Preparation au redemarrage corot (ou pas)
66	67	14	2013-04-25	pm	f	
67	67	14	2013-04-25	am	f	
58	67	14	2013-04-26	pm	f	Preparation au redemarrage corot (ou pas)
58	67	14	2013-04-26	am	f	Preparation au redemarrage corot (ou pas)
58	67	14	2013-04-29	pm	f	Preparation au redemarrage corot (ou pas)
66	89	4	2013-04-29	pm	f	
57	67	14	2013-04-03	pm	f	
57	67	14	2013-04-03	am	f	
66	67	14	2013-04-04	am	f	
57	67	14	2013-04-05	am	f	
57	67	14	2013-04-08	pm	f	
57	67	14	2013-04-08	am	f	
57	67	14	2013-04-09	pm	f	
57	67	14	2013-04-09	am	f	
57	67	14	2013-04-10	pm	f	
57	67	14	2013-04-11	pm	f	
57	67	14	2013-04-11	am	f	
57	67	14	2013-04-12	pm	f	
57	67	14	2013-04-12	am	f	
58	67	14	2013-04-15	pm	f	Preparation au redemarrage corot (ou pas)
58	67	14	2013-04-15	am	f	Preparation au redemarrage corot (ou pas)
58	67	14	2013-04-16	pm	f	Preparation au redemarrage corot (ou pas)
58	67	14	2013-04-16	am	f	Preparation au redemarrage corot (ou pas)
58	67	14	2013-04-17	pm	f	Preparation au redemarrage corot (ou pas)
58	67	14	2013-04-17	am	f	Preparation au redemarrage corot (ou pas)
58	67	14	2013-04-18	pm	f	Preparation au redemarrage corot (ou pas)
58	67	14	2013-04-18	am	f	Preparation au redemarrage corot (ou pas)
58	67	14	2013-04-19	pm	f	Preparation au redemarrage corot (ou pas)
58	67	14	2013-04-19	am	f	Preparation au redemarrage corot (ou pas)
67	133	14	2013-04-04	pm	f	CHEOPS
67	133	14	2013-04-05	pm	f	CHEOPS
67	133	14	2013-04-24	pm	f	CHEOPS
59	133	14	2013-04-24	am	f	CHEOPS (test PSF fitting)
57	71	17	2013-04-29	am	f	Working on new SoHO orbit procedures.
57	71	17	2013-04-29	pm	f	Working on new SoHO orbit procedures.
56	99	18	2013-04-25	pm	f	
56	99	18	2013-04-25	am	f	
67	99	18	2013-04-24	pm	f	
58	84	18	2013-04-24	am	f	
58	84	18	2013-04-23	pm	f	
58	84	18	2013-04-23	am	f	
58	84	18	2013-04-22	pm	f	
58	84	18	2013-04-22	am	f	
\N	\N	18	2013-04-19	pm	t	
\N	\N	18	2013-04-19	am	t	
\N	\N	18	2013-04-18	pm	t	
\N	\N	18	2013-04-18	am	t	
67	99	18	2013-04-17	pm	f	
67	70	18	2013-04-16	pm	f	
58	84	18	2013-04-16	am	f	
58	84	18	2013-04-15	pm	f	
58	84	18	2013-04-15	am	f	
58	84	18	2013-04-12	pm	f	
58	84	18	2013-04-12	am	f	
58	84	18	2013-04-11	pm	f	
58	84	18	2013-04-11	am	f	
62	90	18	2013-04-10	pm	f	
62	90	18	2013-04-10	am	f	
62	90	18	2013-04-09	pm	f	
62	90	18	2013-04-09	am	f	
67	99	18	2013-04-08	pm	f	
55	99	18	2013-04-08	am	f	
55	99	18	2013-04-05	pm	f	
67	90	18	2013-04-05	am	f	
67	99	18	2013-04-04	pm	f	
55	99	18	2013-04-04	am	f	
67	99	18	2013-04-03	pm	f	
67	70	18	2013-04-03	am	f	
57	70	18	2013-04-02	pm	f	
57	70	18	2013-04-02	am	f	
57	70	18	2013-04-01	pm	f	
57	70	18	2013-04-01	am	f	
57	70	18	2013-03-29	pm	f	
\N	\N	18	2013-03-29	am	t	
57	70	18	2013-03-28	pm	f	
57	70	18	2013-03-28	am	f	
67	99	18	2013-03-27	pm	f	
67	99	18	2013-03-27	am	f	
67	99	18	2013-03-26	pm	f	
67	99	18	2013-03-26	am	f	
67	99	18	2013-03-25	pm	f	
67	99	18	2013-03-25	am	f	
56	99	18	2013-03-22	pm	f	
56	99	18	2013-03-22	am	f	
67	99	18	2013-03-21	pm	f	
67	70	18	2013-03-21	am	f	
67	99	18	2013-03-20	pm	f	
56	99	18	2013-03-20	am	f	
56	99	18	2013-03-19	pm	f	
56	99	18	2013-03-19	am	f	
56	99	18	2013-03-18	pm	f	
56	99	18	2013-03-18	am	f	
71	99	18	2013-03-15	pm	f	
58	67	14	2013-04-29	am	f	Preparation au redemarrage corot (ou pas)
71	99	18	2013-03-15	am	f	
62	70	18	2013-03-14	pm	f	
67	90	18	2013-03-14	am	f	
67	99	18	2013-03-13	pm	f	
67	70	18	2013-03-13	am	f	
67	99	18	2013-03-12	pm	f	
55	99	18	2013-03-12	am	f	
55	99	18	2013-03-11	pm	f	
55	99	18	2013-03-11	am	f	
67	99	18	2013-03-08	pm	f	
67	70	18	2013-03-08	am	f	
67	99	18	2013-03-07	pm	f	
66	84	18	2013-03-07	am	f	
67	99	18	2013-03-06	pm	f	
67	70	18	2013-03-06	am	f	
55	99	18	2013-03-05	pm	f	
67	89	18	2013-03-05	am	f	
57	70	18	2013-03-04	pm	f	
57	70	18	2013-03-04	am	f	
57	70	18	2013-03-01	pm	f	
57	70	18	2013-03-01	am	f	
57	70	18	2013-02-28	pm	f	
57	70	18	2013-02-28	am	f	
67	99	18	2013-02-27	pm	f	
57	70	18	2013-02-27	am	f	
\N	\N	18	2013-02-26	pm	t	
\N	\N	18	2013-02-26	am	t	
\N	\N	18	2013-02-25	pm	t	
\N	\N	18	2013-02-25	am	t	
61	99	18	2013-02-22	pm	f	
61	99	18	2013-02-22	am	f	
61	99	18	2013-02-21	pm	f	
67	99	18	2013-02-21	am	f	
67	99	18	2013-02-20	pm	f	
61	99	18	2013-02-20	am	f	
\N	\N	18	2013-02-19	pm	t	
\N	\N	18	2013-02-19	am	t	
\N	\N	18	2013-02-18	pm	t	
\N	\N	18	2013-02-18	am	t	
71	99	18	2013-02-15	pm	f	
71	99	18	2013-02-15	am	f	
62	70	18	2013-02-14	pm	f	
55	70	18	2013-02-14	am	f	
67	99	18	2013-02-13	pm	f	
55	70	18	2013-02-13	am	f	
55	70	18	2013-02-12	pm	f	
55	70	18	2013-02-12	am	f	
55	70	18	2013-02-11	pm	f	
55	70	18	2013-02-11	am	f	
55	70	18	2013-02-08	pm	f	
67	90	18	2013-02-08	am	f	
67	99	18	2013-02-07	pm	f	
58	99	18	2013-02-07	am	f	
67	99	18	2013-02-06	pm	f	
55	99	18	2013-02-06	am	f	
55	99	18	2013-02-05	pm	f	
55	99	18	2013-02-05	am	f	
55	99	18	2013-02-04	pm	f	
55	99	18	2013-02-04	am	f	
55	99	18	2013-02-01	pm	f	
55	99	18	2013-02-01	am	f	
55	99	18	2013-01-31	pm	f	
55	99	18	2013-01-31	am	f	
67	99	18	2013-01-30	pm	f	
67	70	18	2013-01-30	am	f	
58	99	18	2013-01-29	pm	f	
58	99	18	2013-01-29	am	f	
58	99	18	2013-01-28	pm	f	
58	99	18	2013-01-28	am	f	
58	99	18	2013-01-25	pm	f	
58	99	18	2013-01-25	am	f	
58	99	18	2013-01-24	pm	f	
58	99	18	2013-01-24	am	f	
58	99	18	2013-01-23	pm	f	
58	99	18	2013-01-23	am	f	
58	99	18	2013-01-22	pm	f	
58	99	18	2013-01-22	am	f	
58	99	18	2013-01-21	pm	f	
58	99	18	2013-01-21	am	f	
58	99	18	2013-01-18	pm	f	
58	99	18	2013-01-18	am	f	
58	99	18	2013-01-17	pm	f	
58	99	18	2013-01-17	am	f	
67	99	18	2013-01-16	pm	f	
55	99	18	2013-01-16	am	f	
67	99	18	2013-01-15	pm	f	
57	70	18	2013-01-15	am	f	
56	70	18	2013-01-14	pm	f	
61	99	18	2013-01-14	am	f	
61	99	18	2013-01-11	pm	f	
61	99	18	2013-01-11	am	f	
67	99	18	2013-01-10	pm	f	
57	70	18	2013-01-10	am	f	
67	99	18	2013-01-09	pm	f	
57	70	18	2013-01-09	am	f	
57	70	18	2013-01-08	pm	f	
57	70	18	2013-01-08	am	f	
57	70	18	2013-01-07	pm	f	
57	70	18	2013-01-07	am	f	
\N	\N	18	2013-01-04	pm	t	
\N	\N	18	2013-01-04	am	t	
\N	\N	18	2013-01-03	pm	t	
\N	\N	18	2013-01-03	am	t	
\N	\N	18	2013-01-02	pm	t	
\N	\N	18	2013-01-02	am	t	
\N	\N	18	2013-01-01	pm	t	
\N	\N	18	2013-01-01	am	t	
\N	\N	18	2012-12-31	pm	t	
\N	\N	18	2012-12-31	am	t	
\N	\N	18	2012-12-28	pm	t	
\N	\N	18	2012-12-28	am	t	
\N	\N	18	2012-12-27	pm	t	
\N	\N	18	2012-12-27	am	t	
\N	\N	18	2012-12-26	pm	t	
\N	\N	18	2012-12-26	am	t	
\N	\N	18	2012-12-25	pm	t	
\N	\N	18	2012-12-25	am	t	
\N	\N	18	2012-12-24	pm	t	
\N	\N	18	2012-12-24	am	t	
58	70	18	2012-12-21	pm	f	
58	70	18	2012-12-21	am	f	
67	89	18	2012-12-20	pm	f	
67	89	18	2012-12-20	am	f	
67	99	18	2012-12-19	pm	f	
67	70	18	2012-12-19	am	f	
55	70	18	2012-12-18	pm	f	
55	70	18	2012-12-18	am	f	
57	70	18	2012-12-17	pm	f	
57	70	18	2012-12-17	am	f	
67	89	18	2012-12-14	pm	f	
67	70	18	2012-12-14	am	f	
67	99	18	2012-12-13	pm	f	
67	89	18	2012-12-13	am	f	
67	99	18	2012-12-12	pm	f	
67	99	18	2012-12-12	am	f	
55	70	18	2012-12-11	pm	f	
55	70	18	2012-12-11	am	f	
55	70	18	2012-12-10	pm	f	
55	70	18	2012-12-10	am	f	
56	99	18	2012-12-07	pm	f	
56	99	18	2012-12-07	am	f	
67	99	18	2012-12-06	pm	f	
57	70	18	2012-12-06	am	f	
67	99	18	2012-12-05	pm	f	
57	70	18	2012-12-05	am	f	
57	99	18	2012-12-04	pm	f	
55	70	18	2012-12-04	am	f	
58	70	18	2012-12-03	pm	f	
67	70	18	2012-12-03	am	f	
\N	\N	18	2012-11-30	pm	t	
\N	\N	18	2012-11-30	am	t	
61	99	18	2012-11-29	pm	f	
55	90	18	2012-11-29	am	f	
67	99	18	2012-11-28	pm	f	
55	99	18	2012-11-28	am	f	
55	99	18	2012-11-27	pm	f	
55	99	18	2012-11-27	am	f	
58	99	18	2012-11-26	pm	f	
67	70	18	2012-11-26	am	f	
\N	\N	18	2012-11-23	pm	t	
\N	\N	18	2012-11-23	am	t	
58	99	18	2012-11-22	pm	f	
61	99	18	2012-11-22	am	f	
67	99	18	2012-11-21	pm	f	
61	99	18	2012-11-21	am	f	
\N	\N	18	2012-11-20	pm	t	
67	70	18	2012-11-20	am	f	
55	70	18	2012-11-19	pm	f	
67	70	18	2012-11-19	am	f	
55	99	18	2012-11-16	pm	f	
57	99	18	2012-11-16	am	f	
67	99	18	2012-11-15	pm	f	
71	99	18	2012-11-15	am	f	
67	99	18	2012-11-14	pm	f	
55	99	18	2012-11-14	am	f	
55	99	18	2012-11-13	pm	f	
55	70	18	2012-11-13	am	f	
57	70	18	2012-11-12	pm	f	
57	70	18	2012-11-12	am	f	
57	70	18	2012-11-09	pm	f	
55	99	18	2012-11-09	am	f	
55	99	18	2012-11-08	pm	f	
67	70	18	2012-11-08	am	f	
67	99	18	2012-11-07	pm	f	
55	70	18	2012-11-07	am	f	
55	70	18	2012-11-06	pm	f	
55	70	18	2012-11-06	am	f	
67	99	18	2012-11-05	pm	f	
71	99	18	2012-11-05	am	f	
\N	\N	18	2012-11-02	pm	t	
\N	\N	18	2012-11-02	am	t	
67	99	18	2012-11-01	pm	f	
71	99	18	2012-11-01	am	f	
57	97	8	2013-04-29	pm	f	
57	98	8	2013-04-29	am	f	
57	98	8	2013-04-30	pm	f	
57	97	8	2013-04-30	am	f	
70	102	22	2013-04-29	pm	f	
57	102	22	2013-04-29	am	f	
70	102	22	2013-04-30	pm	f	
67	85	22	2013-04-30	am	f	CL
\N	\N	22	2013-05-01	pm	t	
\N	\N	22	2013-05-01	am	t	
71	63	11	2013-03-26	pm	f	
\N	\N	11	2013-04-26	pm	t	
\N	\N	11	2013-04-29	am	t	
\N	\N	11	2013-04-29	pm	t	
\N	\N	11	2013-04-30	am	t	
\N	\N	11	2013-04-30	pm	t	
\N	\N	11	2013-05-01	am	t	
\N	\N	11	2013-05-01	pm	t	
\N	\N	15	2013-05-01	am	t	
\N	\N	15	2013-05-01	pm	t	
57	112	15	2013-05-02	am	f	cilia
73	110	15	2013-05-02	pm	f	
57	112	15	2013-04-29	am	f	cilia
57	112	15	2013-04-29	pm	f	cilia
57	110	15	2013-04-30	am	f	
73	110	15	2013-04-30	pm	f	bulge
58	67	14	2013-04-30	pm	f	Preparation au redemarrage corot (ou pas)
58	67	14	2013-04-30	am	f	Preparation au redemarrage corot (ou pas)
\N	\N	14	2013-05-01	pm	t	
\N	\N	14	2013-05-01	am	t	
67	81	14	2013-05-02	pm	f	Sprint 0
67	81	14	2013-05-02	am	f	Sprint 0
67	81	14	2013-05-03	pm	f	Sprint 0
67	81	14	2013-05-03	am	f	Sprint 0
57	102	20	2013-04-29	pm	f	Dévelopement SI
57	102	20	2013-04-29	am	f	Dévelopement SI
57	102	20	2013-04-30	pm	f	Dévelopement SI
57	102	20	2013-04-30	am	f	Dévelopement SI
\N	\N	20	2013-05-01	pm	t	
\N	\N	20	2013-05-01	am	t	
57	102	20	2013-05-02	pm	f	Dévelopement SI
57	102	20	2013-05-02	am	f	Dévelopement SI
57	102	20	2013-05-03	pm	f	Dévelopement SI
57	102	20	2013-05-03	am	f	Dévelopement SI
57	67	19	2013-04-29	pm	f	Developpement ExoDat mise à jour Avril
57	67	19	2013-04-29	am	f	Developpement ExoDat mise à jour Avril
57	67	19	2013-04-30	pm	f	Developpement ExoDat mise à jour Avril
57	67	19	2013-04-30	am	f	Developpement ExoDat mise à jour Avril
\N	\N	19	2013-05-01	pm	t	
\N	\N	19	2013-05-01	am	t	
57	67	19	2013-05-02	pm	f	Developpement ExoDat mise à jour Avril
57	67	19	2013-05-02	am	f	Developpement ExoDat mise à jour Avril
56	67	19	2013-05-03	pm	f	
56	67	19	2013-05-03	am	f	
\N	\N	8	2013-05-01	pm	t	
\N	\N	8	2013-05-01	am	t	
70	98	8	2013-05-02	pm	f	
70	98	8	2013-05-02	am	f	
70	98	8	2013-05-03	pm	f	
70	98	8	2013-05-03	am	f	
70	102	22	2013-05-02	pm	f	
70	102	22	2013-05-02	am	f	
56	102	22	2013-05-03	pm	f	
70	102	22	2013-05-03	am	f	
61	131	22	2013-05-06	pm	f	tests fonctionnels
61	131	22	2013-05-06	am	f	tests fonctionnels
57	97	8	2013-05-06	pm	f	
57	98	8	2013-05-06	am	f	
57	71	17	2013-05-02	am	f	Working on first method for SoHO orbit procedures.
57	71	17	2013-05-02	pm	f	Working on first method for SoHO orbit procedures.
57	71	17	2013-05-03	am	f	Working on first method for SoHO orbit procedures.
57	71	17	2013-05-03	pm	f	Working on first method for SoHO orbit procedures.
57	71	17	2013-05-06	am	f	Working on first method for SoHO orbit procedures.
57	71	17	2013-05-06	pm	f	Working on second method for SoHO orbit procedures.
57	71	17	2013-05-07	am	f	Validation and cleanup of new SoHO orbit procedures.
58	71	17	2013-05-07	pm	f	Documentation of new SoHO orbit procedures.
71	71	17	2013-04-19	pm	f	General servers & workstations maintenance
\N	\N	22	2013-05-07	pm	t	
70	132	22	2013-05-07	am	f	
73	110	15	2013-05-03	am	f	
57	112	15	2013-05-03	pm	f	cilia
57	112	15	2013-05-06	am	f	
57	115	15	2013-05-06	pm	f	minor f3.2
57	115	15	2013-05-07	am	f	minor f3.2
73	110	15	2013-05-07	pm	f	
56	97	8	2013-05-07	pm	f	
57	98	8	2013-05-07	am	f	
\N	\N	15	2013-05-08	am	t	
\N	\N	15	2013-05-08	pm	t	
\N	\N	15	2013-05-09	am	t	
\N	\N	15	2013-05-09	pm	t	
\N	\N	15	2013-05-10	am	t	
\N	\N	15	2013-05-10	pm	t	
\N	\N	22	2013-05-08	pm	t	
\N	\N	22	2013-05-08	am	t	
\N	\N	22	2013-05-09	pm	t	
\N	\N	22	2013-05-09	am	t	
\N	\N	22	2013-05-10	pm	t	
\N	\N	22	2013-05-10	am	t	
69	135	22	2013-05-13	pm	f	
63	89	22	2013-05-13	am	f	
57	70	28	2013-04-26	am	f	automatisation fitting de spectres moléculaires par Cassis
57	70	28	2013-04-26	pm	f	automatisation fitting de spectres moléculaires par Cassis
57	70	28	2013-04-29	am	f	automatisation fitting de spectres moléculaires par Cassis
\N	\N	22	2013-05-15	am	t	
57	70	28	2013-04-29	pm	f	automatisation fitting de spectres moléculaires par Cassis
57	70	28	2013-04-30	am	f	automatisation fitting de spectres moléculaires par Cassis
57	70	28	2013-04-30	pm	f	automatisation fitting de spectres moléculaires par Cassis
57	70	28	2013-05-02	am	f	automatisation fitting de spectres moléculaires par Cassis
63	89	22	2013-06-03	am	f	
57	70	28	2013-05-02	pm	f	automatisation fitting de spectres moléculaires par Cassis
57	70	28	2013-05-03	am	f	automatisation fitting de spectres moléculaires par Cassis
57	70	28	2013-05-03	pm	f	automatisation fitting de spectres moléculaires par Cassis
57	70	28	2013-05-06	am	f	automatisation fitting de spectres moléculaires par Cassis
57	70	28	2013-05-06	pm	f	automatisation fitting de spectres moléculaires par Cassis
57	70	28	2013-05-07	am	f	automatisation fitting de spectres moléculaires par Cassis
57	70	28	2013-05-07	pm	f	automatisation fitting de spectres moléculaires par Cassis
57	70	28	2013-05-13	am	f	automatisation fitting de spectres moléculaires par Cassis
57	70	28	2013-05-13	pm	f	automatisation fitting de spectres moléculaires par Cassis
57	70	28	2013-05-14	am	f	automatisation fitting de spectres moléculaires par Cassis
57	70	28	2013-05-14	pm	f	automatisation fitting de spectres moléculaires par Cassis
57	65	9	2013-04-29	am	f	
57	65	9	2013-04-29	pm	f	
57	65	9	2013-04-30	am	f	
57	65	9	2013-04-30	pm	f	
\N	\N	8	2013-05-08	pm	t	
\N	\N	8	2013-05-08	am	t	
\N	\N	8	2013-05-09	pm	t	
\N	\N	8	2013-05-09	am	t	
\N	\N	8	2013-05-10	pm	t	
\N	\N	8	2013-05-10	am	t	
67	97	8	2013-05-13	pm	f	
57	98	8	2013-05-13	am	f	
\N	\N	8	2013-05-14	pm	t	
\N	\N	8	2013-05-14	am	t	
71	71	17	2013-05-13	am	f	Maintenance, cleanup on stations & servers.
71	71	17	2013-05-13	pm	f	Maintenance, cleanup on stations & servers.
63	71	17	2013-05-14	am	f	Configuring  & adding new drives for lascopg (pipeline expansion).
63	71	17	2013-05-14	pm	f	Configuring  & adding new drives for lascopg (pipeline expansion).
71	63	11	2013-05-16	am	f	supprimer les appels au Java Cryptography Extension
58	133	11	2013-05-15	am	f	établir les premiers requirements pour CIS/
58	133	11	2013-05-15	pm	f	établir les premiers requirements pour CIS/
63	71	17	2013-05-15	am	f	Restoring data on lascopg.
63	71	17	2013-05-15	pm	f	Restoring data on lascopg.
71	71	17	2013-05-16	am	f	General maintenance on stations after lascopg downtime.
67	71	17	2013-05-16	pm	f	
\N	\N	18	2013-04-17	am	t	
67	99	18	2013-05-14	am	f	
67	70	18	2013-05-14	pm	f	
67	99	18	2013-05-15	pm	f	
57	115	15	2013-05-13	am	f	
57	115	15	2013-05-13	pm	f	
57	115	15	2013-05-14	am	f	
57	115	15	2013-05-14	pm	f	
57	112	15	2013-05-15	am	f	
57	112	15	2013-05-15	pm	f	
73	110	15	2013-05-16	am	f	
73	110	15	2013-05-16	pm	f	
\N	\N	8	2013-05-15	pm	t	
\N	\N	8	2013-05-15	am	t	
\N	\N	8	2013-05-16	pm	t	
\N	\N	8	2013-05-16	am	t	
\N	\N	8	2013-05-17	pm	t	
70	98	8	2013-05-17	am	f	
\N	\N	14	2013-05-06	pm	t	
\N	\N	14	2013-05-06	am	t	
\N	\N	14	2013-05-07	pm	t	
\N	\N	14	2013-05-07	am	t	
\N	\N	14	2013-05-08	pm	t	
\N	\N	14	2013-05-08	am	t	
\N	\N	14	2013-05-09	pm	t	
\N	\N	14	2013-05-09	am	t	
\N	\N	14	2013-05-10	pm	t	
\N	\N	14	2013-05-10	am	t	
67	133	14	2013-05-13	pm	f	SOC meeting
66	67	14	2013-05-13	am	f	
71	67	14	2013-05-14	pm	f	
71	67	14	2013-05-14	am	f	
58	133	14	2013-05-15	pm	f	WP11 definition
58	133	14	2013-05-15	am	f	WP11 definition
67	67	14	2013-05-16	pm	f	Exodat P.Bordé
55	67	14	2013-05-16	am	f	
56	67	14	2013-05-17	pm	f	
71	67	14	2013-05-17	am	f	
\N	\N	14	2013-05-20	pm	t	
\N	\N	14	2013-05-20	am	t	
57	71	16	2013-04-19	pm	f	
57	71	16	2013-04-22	am	f	
57	71	16	2013-04-22	pm	f	
57	71	16	2013-04-23	am	f	
57	71	16	2013-04-23	pm	f	
57	71	16	2013-04-24	am	f	
57	71	16	2013-04-24	pm	f	
72	71	16	2013-04-25	am	f	
72	71	16	2013-04-25	pm	f	
57	71	16	2013-04-26	am	f	
57	71	16	2013-04-26	pm	f	
57	71	16	2013-04-29	am	f	
57	71	16	2013-04-29	pm	f	
57	71	16	2013-04-30	am	f	
57	71	16	2013-04-30	pm	f	
57	71	16	2013-05-01	am	f	
57	71	16	2013-05-01	pm	f	
57	71	16	2013-05-02	am	f	
57	71	16	2013-05-02	pm	f	
57	71	16	2013-05-03	am	f	
57	71	16	2013-05-03	pm	f	
57	71	16	2013-05-06	am	f	
57	71	16	2013-05-06	pm	f	
61	71	16	2013-05-07	am	f	
61	71	16	2013-05-07	pm	f	
61	71	16	2013-05-08	am	f	
61	71	16	2013-05-08	pm	f	
61	71	16	2013-05-09	am	f	
61	71	16	2013-05-09	pm	f	
61	71	16	2013-05-10	am	f	
61	71	16	2013-05-10	pm	f	
61	71	16	2013-05-13	am	f	
61	71	16	2013-05-13	pm	f	
61	71	16	2013-05-14	am	f	
61	71	16	2013-05-14	pm	f	
72	71	16	2013-05-15	am	f	
72	71	16	2013-05-15	pm	f	
72	71	16	2013-05-16	am	f	
72	71	16	2013-05-16	pm	f	
72	71	16	2013-05-17	am	f	
72	71	16	2013-05-17	pm	f	
72	71	16	2013-05-20	am	f	
72	71	16	2013-05-20	pm	f	
72	71	16	2013-05-21	am	f	
72	71	16	2013-05-21	pm	f	
\N	\N	8	2013-05-20	pm	t	
\N	\N	8	2013-05-20	am	t	
57	97	8	2013-05-21	am	f	
70	132	22	2013-05-14	pm	f	ANIS-Admin
70	132	22	2013-05-14	am	f	ANIS-Admin
61	102	22	2013-05-15	pm	f	
67	133	11	2013-05-13	pm	f	interface CIS + requirement SOC WP#11
71	67	11	2013-05-16	pm	f	
57	77	22	2013-05-16	pm	f	slider
69	77	22	2013-05-16	am	f	pages db
69	77	22	2013-05-17	pm	f	pages projets
69	77	22	2013-05-17	am	f	pages projets
\N	\N	22	2013-05-20	pm	t	
\N	\N	22	2013-05-20	am	t	
70	102	22	2013-05-21	pm	f	
60	89	22	2013-05-21	am	f	Accueil stagiaire
61	131	20	2013-05-06	pm	f	Creation des tests fonctionnels
61	131	20	2013-05-06	am	f	Creation des tests fonctionnels
61	131	20	2013-05-07	pm	f	Creation des tests fonctionnels
61	131	20	2013-05-07	am	f	Creation des tests fonctionnels
\N	\N	20	2013-05-08	pm	t	
\N	\N	20	2013-05-08	am	t	
\N	\N	20	2013-05-09	pm	t	
\N	\N	20	2013-05-09	am	t	
\N	\N	20	2013-05-10	pm	t	
\N	\N	20	2013-05-10	am	t	
57	102	20	2013-05-13	pm	f	Gestion double requete
57	102	20	2013-05-13	am	f	Gestion double requete
70	84	20	2013-05-14	pm	f	Creation Bdd galex-emphot
57	131	20	2013-05-14	am	f	Gestion des images
\N	\N	20	2013-05-15	pm	t	
\N	\N	20	2013-05-15	am	t	
\N	\N	20	2013-05-16	pm	t	
\N	\N	20	2013-05-16	am	t	
\N	\N	20	2013-05-17	pm	t	
\N	\N	20	2013-05-17	am	t	
\N	\N	20	2013-05-20	pm	t	
\N	\N	20	2013-05-20	am	t	
70	84	20	2013-05-21	pm	f	Mise a jour de la base galex-emhot
57	102	20	2013-05-21	am	f	Dev SI
61	131	19	2013-05-06	pm	f	tests fonctionnels template-si
61	131	19	2013-05-06	am	f	tests fonctionnels template-si
61	131	19	2013-05-07	pm	f	tests fonctionnels template-si
61	131	19	2013-05-07	am	f	tests fonctionnels template-si
\N	\N	19	2013-05-08	pm	t	
\N	\N	19	2013-05-08	am	t	
\N	\N	19	2013-05-09	pm	t	
\N	\N	19	2013-05-09	am	t	
\N	\N	19	2013-05-10	pm	t	
\N	\N	19	2013-05-10	am	t	
61	131	19	2013-05-13	pm	f	tests fonctionnels template-si
61	131	19	2013-05-13	am	f	tests fonctionnels template-si
61	131	19	2013-05-14	pm	f	tests fonctionnels template-si
61	131	19	2013-05-14	am	f	tests fonctionnels template-si
57	67	19	2013-05-15	pm	f	Refonte datatables
57	67	19	2013-05-15	am	f	Refonte datatables
\N	\N	19	2013-05-16	pm	t	
\N	\N	19	2013-05-16	am	t	
\N	\N	19	2013-05-17	pm	t	
\N	\N	19	2013-05-17	am	t	
\N	\N	19	2013-05-20	pm	t	
\N	\N	19	2013-05-20	am	t	
67	67	19	2013-05-21	pm	f	
57	67	19	2013-05-21	am	f	Refonte datatables
57	67	19	2013-05-22	pm	f	Refonte datatables
57	67	19	2013-05-22	am	f	Refonte datatables
61	74	11	2013-05-13	am	f	ANIS test
61	74	11	2013-05-14	am	f	ANIS Test
62	89	11	2013-05-17	am	f	
61	63	11	2013-05-17	pm	f	
67	89	11	2013-05-21	pm	f	monitoring IT internship
56	63	11	2013-05-22	am	f	Tagging version 0.5.1
70	63	11	2013-05-22	pm	f	
\N	\N	11	2013-05-20	am	t	
\N	\N	11	2013-05-20	pm	t	
56	89	11	2013-05-21	am	f	
63	71	17	2013-05-21	am	f	Setting up new workstations, replacements for lascolin1 & 8.
63	71	17	2013-05-21	pm	f	Setting up new workstations, replacements for lascolin1 & 8.
63	71	17	2013-05-22	am	f	Setting up new workstations, replacements for lascolin1 & 8.
63	71	17	2013-05-22	pm	f	Setting up new workstations, replacements for lascolin1 & 8.
57	98	8	2013-05-21	pm	f	
57	98	8	2013-05-22	pm	f	
57	98	8	2013-05-22	am	f	
57	98	8	2013-05-23	pm	f	
57	97	8	2013-05-23	am	f	
57	98	8	2013-05-24	pm	f	
57	98	8	2013-05-24	am	f	
70	71	17	2013-05-23	am	f	Restored data on lascolin1 in prevision of guillaume's work.
70	71	17	2013-05-23	pm	f	Restored data on lascolin1 in prevision of Guillaume's work.
63	71	17	2013-05-24	am	f	Re-purposed old user station : lascolin5
63	71	17	2013-05-24	pm	f	Re-purposed old user station : lascolin5
57	71	17	2013-05-27	am	f	Uniformised plotpbrate with the others rate plotting procedures.
73	110	15	2013-05-17	am	f	
73	110	15	2013-05-17	pm	f	
73	110	15	2013-05-20	am	f	
73	110	15	2013-05-20	pm	f	
57	112	15	2013-05-21	am	f	
57	112	15	2013-05-21	pm	f	
57	112	15	2013-05-22	am	f	cilia
57	112	15	2013-05-22	pm	f	cilia
57	115	15	2013-05-23	am	f	
57	115	15	2013-05-23	pm	f	
57	115	15	2013-05-24	am	f	writing for poster
57	115	15	2013-05-24	pm	f	
73	110	15	2013-05-27	am	f	
67	110	15	2013-05-27	pm	f	meeting
57	97	8	2013-05-27	pm	f	
57	98	8	2013-05-27	am	f	
69	77	22	2013-05-22	pm	f	
\N	\N	22	2013-05-22	am	t	
60	136	22	2013-05-23	pm	f	
67	136	22	2013-05-23	am	f	
\N	\N	22	2013-05-24	pm	t	
67	89	22	2013-05-24	am	f	plato
70	102	22	2013-05-27	pm	f	
57	102	22	2013-05-27	am	f	
57	71	17	2013-05-27	pm	f	Comitted new plot rates.
55	71	17	2013-05-28	am	f	Proof read documentation for new equalization procedures.
57	71	17	2013-05-28	pm	f	Working on new equalization procedures.
70	132	22	2013-05-28	pm	f	
70	132	22	2013-05-28	am	f	paramétrage ANIS
57	98	8	2013-05-28	pm	f	
57	97	8	2013-05-28	am	f	
57	112	15	2013-05-28	am	f	
73	110	15	2013-05-28	pm	f	bulge
73	110	15	2013-05-29	am	f	bulge
73	110	15	2013-05-29	pm	f	bulge
57	71	17	2013-05-29	am	f	Working on new egalisation procedures.
57	71	17	2013-05-29	pm	f	Working on new egalisation procedures.
57	71	17	2013-05-30	am	f	Working on new egalisation procedures.
57	71	17	2013-05-30	pm	f	Working on new egalisation procedures, added autoupdating for ancillary data, solved network problems. (VLANs)
57	98	8	2013-05-29	pm	f	
57	97	8	2013-05-29	am	f	
67	98	8	2013-05-30	pm	f	
57	98	8	2013-05-30	am	f	
57	98	8	2013-05-31	pm	f	
67	97	8	2013-05-31	am	f	
56	98	8	2013-06-03	pm	f	
56	98	8	2013-06-03	am	f	
70	132	22	2013-05-29	pm	f	
\N	\N	22	2013-05-29	am	t	
70	102	22	2013-05-30	pm	f	
66	98	22	2013-05-30	am	f	
69	131	22	2013-05-31	pm	f	
69	131	22	2013-05-31	am	f	
\N	\N	22	2013-06-03	pm	t	
69	131	22	2013-06-04	pm	f	
\N	\N	22	2013-06-04	am	t	
57	112	15	2013-05-30	am	f	cilia
57	112	15	2013-05-30	pm	f	cilia
67	110	15	2013-05-31	am	f	cilia
73	110	15	2013-05-31	pm	f	bulge
57	112	15	2013-06-03	am	f	cilia
73	110	15	2013-06-03	pm	f	
73	110	15	2013-06-04	am	f	
59	85	15	2013-06-04	pm	f	
59	89	8	2013-06-04	am	f	
59	89	8	2013-06-04	pm	f	
57	71	17	2013-05-20	am	f	Working on new egalisation procedures.
57	71	17	2013-05-20	pm	f	Working on new egalisation procedures.
59	125	4	2013-05-21	am	f	preparation Jury
59	125	4	2013-05-21	pm	f	Jury
70	71	17	2013-06-03	am	f	Running statistics on lasco database. (Estimating number of images concerned by morphological reconstruction of missing blocks).
57	71	17	2013-06-03	pm	f	Running statistics on lasco database. (Estimating number of images concerned by morphological reconstruction of missing blocks).
57	71	17	2013-06-04	am	f	Reworking SoHO roll retrieval procedures to use FITS input.
70	71	17	2013-05-31	am	f	Working on egalisation procedures.
57	71	17	2013-05-31	pm	f	Working on egalisation procedures.
\N	\N	8	2013-06-05	am	t	
57	98	8	2013-06-05	pm	f	
57	71	17	2013-06-04	pm	f	Reworking SoHO roll retrieval procedures to use FITS input.
57	71	17	2013-06-05	am	f	Reworking SoHO roll retrieval procedures to use FITS input.
57	71	17	2013-06-05	pm	f	Reworking SoHO roll retrieval procedures to use FITS input.
57	71	17	2013-06-06	am	f	Committed reworked SoHO roll procedures.
67	85	4	2013-04-30	am	f	CL
55	81	4	2013-04-30	pm	f	AGILE
\N	\N	4	2013-05-01	am	t	
\N	\N	4	2013-05-01	pm	t	
55	81	4	2013-05-02	am	f	AGILE
55	81	4	2013-05-02	pm	f	AGILE
55	81	4	2013-05-03	am	f	AGILE
55	81	4	2013-05-03	pm	f	AGILE
55	89	4	2013-05-06	am	f	SO5
55	89	4	2013-05-06	pm	f	SO5
55	81	4	2013-05-07	am	f	AGILE
55	81	4	2013-05-07	pm	f	AGILE - Reunion France
\N	\N	4	2013-05-08	am	t	
\N	\N	4	2013-05-08	pm	t	
\N	\N	4	2013-05-09	am	t	
\N	\N	4	2013-05-09	pm	t	
\N	\N	4	2013-05-10	am	t	
\N	\N	4	2013-05-10	pm	t	
67	65	4	2013-05-13	am	f	Science meeting - Leiden
67	65	4	2013-05-13	pm	f	Science meeting - Leiden
67	65	4	2013-05-14	am	f	Science meeting - Leiden
67	65	4	2013-05-14	pm	f	Science meeting - Leiden
67	65	4	2013-05-15	am	f	Science meeting - Leiden
67	65	4	2013-05-15	pm	f	Science meeting - Leiden
67	65	4	2013-05-16	am	f	Science meeting - Leiden
67	65	4	2013-05-16	pm	f	Science meeting - Leiden
59	84	4	2013-05-17	am	f	Jury de concours - CNRS
59	85	4	2013-05-17	pm	f	Gestion Depart - CDD
\N	\N	4	2013-05-20	am	t	
\N	\N	4	2013-05-20	pm	t	
59	84	4	2013-05-22	am	f	Jury de concours - CNRS
59	84	4	2013-05-22	pm	f	Jury de concours - CNRS
59	84	4	2013-05-23	am	f	Jury de concours - CNRS
59	84	4	2013-05-23	pm	f	Jury de concours - CNRS
55	81	4	2013-06-03	am	f	AGILE
55	81	4	2013-06-03	pm	f	AGILE
57	98	8	2013-06-06	am	f	
57	97	8	2013-06-06	pm	f	
66	65	4	2013-05-27	am	f	GEstion CDD
55	84	4	2013-05-27	pm	f	Projet WIsh
67	133	4	2013-05-28	pm	f	
67	133	4	2013-05-29	am	f	
67	133	4	2013-05-29	pm	f	Information
55	85	4	2013-05-30	am	f	preparation reunion CNES
55	85	4	2013-05-30	pm	f	preparation reunion CNES
67	96	4	2013-05-31	am	f	2nd year meeting
67	96	4	2013-05-31	pm	f	2nd year meeting
67	65	4	2013-06-04	am	f	Ground Segment meeting
67	65	4	2013-06-04	pm	f	Ground Segment meeting
67	75	4	2013-06-05	am	f	Ground Segment meeting
67	75	4	2013-06-05	pm	f	Ground Segment meeting
67	85	4	2013-06-06	am	f	CPCS
67	89	4	2013-06-06	pm	f	EAA
67	85	4	2013-05-24	pm	f	interclassement
67	81	4	2013-05-28	am	f	AGILE daily meeting
55	137	4	2013-05-24	am	f	Analyse de la charge
70	132	22	2013-06-05	pm	f	
\N	\N	22	2013-06-05	am	t	
66	136	22	2013-06-06	pm	f	
56	66	22	2013-06-06	am	f	Mise en prod Abell & COMA
66	89	22	2013-06-07	pm	f	concours interne François
66	89	22	2013-06-07	am	f	concours interne François
57	71	17	2013-06-06	pm	f	Creating a program to overlay database star references informations on lvl 0.5 images, for control purposes.
57	71	17	2013-06-07	am	f	Creating a program to overlay database star references informations on lvl 0.5 images, for control purposes.
67	71	17	2013-06-07	pm	f	Judith & Claire 's presentations.
\N	\N	15	2013-06-05	am	t	
\N	\N	15	2013-06-05	pm	t	
73	110	15	2013-06-06	am	f	
73	110	15	2013-06-06	pm	f	
73	110	15	2013-06-07	am	f	
67	110	15	2013-06-07	pm	f	
57	97	8	2013-06-07	am	f	
67	84	8	2013-06-07	pm	f	
57	97	8	2013-06-10	am	f	
57	97	8	2013-06-10	pm	f	
73	110	15	2013-06-10	am	f	
73	110	15	2013-06-10	pm	f	bulge
57	71	17	2013-06-10	am	f	Working on new Lascomission/ARTEMIS unified website.
57	71	17	2013-06-10	pm	f	Working on new Lascomission/ARTEMIS unified website.
57	71	17	2013-06-11	am	f	Working on new Lascomission/ARTEMIS unified website.
57	71	17	2013-06-11	pm	f	Working on new Lascomission/ARTEMIS unified website.
57	71	17	2013-06-12	am	f	Working on new Lascomission/ARTEMIS unified website.
57	71	17	2013-06-12	pm	f	Working on new Lascomission/ARTEMIS unified website.
57	71	17	2013-06-13	am	f	Working on updated egalisation/normalisation procedures.
67	71	17	2013-06-13	pm	f	
56	98	8	2013-06-11	am	f	
57	98	8	2013-06-11	pm	f	
\N	\N	8	2013-06-12	am	t	
\N	\N	8	2013-06-12	pm	t	
57	98	8	2013-06-13	am	f	
57	98	8	2013-06-13	pm	f	
57	98	8	2013-06-14	am	f	
67	97	8	2013-06-14	pm	f	
57	98	8	2013-06-17	am	f	
57	98	8	2013-06-17	pm	f	
70	84	20	2013-05-22	pm	f	Ajout de catalogues dans la BDD XMMLSS
70	84	20	2013-05-22	am	f	Ajout de catalogues dans la BDD XMMLSS
67	136	20	2013-05-23	pm	f	Reunion nouvel SI
57	102	20	2013-05-23	am	f	Extraction des spectres
57	131	20	2013-05-24	pm	f	Datatables
57	131	20	2013-05-24	am	f	Datatables
57	102	20	2013-05-27	pm	f	Dev SI
57	102	20	2013-05-27	am	f	Dev SI
57	102	20	2013-05-28	pm	f	Dev SI
57	102	20	2013-05-28	am	f	Dev SI
57	131	20	2013-05-29	pm	f	Datatables
57	131	20	2013-05-29	am	f	Datatables
57	131	20	2013-05-30	pm	f	Datatables
57	131	20	2013-05-30	am	f	Datatables
\N	\N	20	2013-05-31	pm	t	
\N	\N	20	2013-05-31	am	t	
56	84	20	2013-06-03	pm	f	Mise en prod Galex-emphot
57	102	20	2013-06-03	am	f	Dev SI
57	102	20	2013-06-04	pm	f	Dev SI
57	102	20	2013-06-04	am	f	Dev SI
57	102	20	2013-06-05	pm	f	Dev SI
57	102	20	2013-06-05	am	f	Dev SI
57	102	20	2013-06-06	pm	f	Dev SI
57	102	20	2013-06-06	am	f	Dev SI
\N	\N	20	2013-06-07	pm	t	
\N	\N	20	2013-06-07	am	t	
57	131	20	2013-06-10	pm	f	Dev export images
57	131	20	2013-06-10	am	f	Dev export images
57	131	20	2013-06-11	pm	f	Dev export images
57	131	20	2013-06-11	am	f	Dev export images
57	131	20	2013-06-12	pm	f	Dev export images
57	131	20	2013-06-12	am	f	Dev export images
57	131	20	2013-06-13	pm	f	Dev page detail
57	131	20	2013-06-13	am	f	Dev page detail
57	131	20	2013-06-14	pm	f	Dev page detail
57	131	20	2013-06-14	am	f	Dev page detail
56	66	20	2013-06-17	pm	f	Mise à jour et deploiement Coma
56	66	20	2013-06-17	am	f	Mise à jour et deploiement Abell496
66	89	22	2013-06-10	pm	f	Prépa concours FA
70	102	22	2013-06-10	am	f	
66	89	22	2013-06-11	pm	f	Prépa concours FA
66	89	22	2013-06-11	am	f	Prépa concours FA
\N	\N	22	2013-06-12	pm	t	
66	89	22	2013-06-12	am	f	Prépa concours FA
59	89	22	2013-06-13	pm	f	EA
56	77	22	2013-06-13	am	f	
56	66	22	2013-06-14	pm	f	Upgrade Abell, Coma
57	77	22	2013-06-14	am	f	
70	102	22	2013-06-17	pm	f	
70	102	22	2013-06-17	am	f	
70	102	22	2013-06-18	pm	f	
61	102	22	2013-06-18	am	f	
57	71	17	2013-06-18	am	f	Integration of cosmic filtering procedures.
57	71	17	2013-06-18	pm	f	Integration of cosmic filtering procedures.
57	98	8	2013-06-18	am	f	
56	98	8	2013-06-18	pm	f	
57	98	8	2013-06-19	am	f	
\N	\N	8	2013-06-19	pm	t	
57	71	17	2013-06-19	am	f	Parallelization of cosmic filtering procedure.
57	71	17	2013-06-19	pm	f	Parallelization of cosmic filtering procedure.
57	71	17	2013-06-20	am	f	Outputting statistics and graphics for article.
57	71	17	2013-06-20	pm	f	Started cosmic filtering, writing level_09 on all images.
63	89	5	2013-04-25	pm	f	
63	89	5	2013-04-26	am	f	
63	89	5	2013-04-26	pm	f	
63	89	5	2013-04-29	am	f	
63	89	5	2013-04-29	pm	f	
\N	\N	5	2013-04-30	am	t	
\N	\N	5	2013-04-30	pm	t	
\N	\N	5	2013-05-01	am	t	
\N	\N	5	2013-05-01	pm	t	
\N	\N	5	2013-05-02	am	t	
\N	\N	5	2013-05-02	pm	t	
\N	\N	5	2013-05-03	am	t	
\N	\N	5	2013-05-03	pm	t	
\N	\N	5	2013-05-06	am	t	
\N	\N	5	2013-05-06	pm	t	
\N	\N	5	2013-05-07	am	t	
\N	\N	5	2013-05-07	pm	t	
\N	\N	5	2013-05-08	am	t	
\N	\N	5	2013-05-08	pm	t	
\N	\N	5	2013-05-09	am	t	
\N	\N	5	2013-05-09	pm	t	
\N	\N	5	2013-05-10	am	t	
\N	\N	5	2013-05-10	pm	t	
\N	\N	5	2013-05-13	am	t	
\N	\N	5	2013-05-13	pm	t	
63	89	5	2013-05-14	am	f	
63	89	5	2013-05-14	pm	f	
63	89	5	2013-05-15	am	f	
63	89	5	2013-05-15	pm	f	
63	89	5	2013-05-16	am	f	
63	89	5	2013-05-16	pm	f	
\N	\N	5	2013-05-17	am	t	
\N	\N	5	2013-05-17	pm	t	
61	104	5	2013-05-20	am	f	
71	89	5	2013-05-20	pm	f	
71	69	5	2013-05-21	am	f	
63	89	5	2013-05-21	pm	f	
71	89	5	2013-05-22	am	f	
57	89	5	2013-05-22	pm	f	
57	89	5	2013-05-23	am	f	
57	89	5	2013-05-23	pm	f	
57	89	5	2013-05-24	am	f	
55	85	5	2013-05-24	pm	f	
55	85	5	2013-05-27	am	f	
55	85	5	2013-05-27	pm	f	
55	85	5	2013-05-28	am	f	
55	85	5	2013-05-28	pm	f	
55	85	5	2013-05-29	am	f	
55	85	5	2013-05-29	pm	f	
55	85	5	2013-05-30	am	f	
55	85	5	2013-05-30	pm	f	
57	85	5	2013-05-31	am	f	
57	85	5	2013-05-31	pm	f	
57	85	5	2013-06-03	am	f	
57	85	5	2013-06-03	pm	f	
57	85	5	2013-06-04	am	f	
57	85	5	2013-06-04	pm	f	
57	85	5	2013-06-05	am	f	
57	85	5	2013-06-05	pm	f	
57	71	17	2013-06-14	pm	f	Working on equalization/normalisation procedures.
57	71	17	2013-06-17	am	f	Integration of equalization/normalisation procedures.
57	71	17	2013-06-17	pm	f	Integration of equalization/normalisation procedures.
57	85	5	2013-06-06	am	f	
57	85	5	2013-06-06	pm	f	
57	85	5	2013-06-07	am	f	
57	85	5	2013-06-07	pm	f	
57	85	5	2013-06-10	am	f	
57	85	5	2013-06-10	pm	f	
71	85	5	2013-06-11	am	f	
71	85	5	2013-06-11	pm	f	
71	85	5	2013-06-12	am	f	
71	85	5	2013-06-12	pm	f	
57	85	5	2013-06-13	am	f	PFS site
57	85	5	2013-06-13	pm	f	PFS site
57	85	5	2013-06-14	am	f	PFS site
57	85	5	2013-06-14	pm	f	PFS site
57	85	5	2013-06-17	am	f	PFS site
57	85	5	2013-06-17	pm	f	PFS site
57	85	5	2013-06-18	am	f	PFS site
57	85	5	2013-06-18	pm	f	PFS site
57	85	5	2013-06-19	am	f	PFS site
57	85	5	2013-06-19	pm	f	Redmine
57	85	5	2013-06-20	am	f	Redmine
57	85	5	2013-06-20	pm	f	Redmine
57	85	5	2013-06-21	am	f	Redmine
57	85	5	2013-06-21	pm	f	Redmine
73	110	15	2013-06-11	am	f	bulge
73	110	15	2013-06-11	pm	f	bulge
57	112	15	2013-06-12	am	f	cilia
57	112	15	2013-06-12	pm	f	cilia
57	110	15	2013-06-13	am	f	bulge
57	110	15	2013-06-13	pm	f	bulge
57	110	15	2013-06-14	am	f	bulge
73	110	15	2013-06-14	pm	f	bulge
73	110	15	2013-06-17	am	f	bulge
73	110	15	2013-06-17	pm	f	bulge
73	110	15	2013-06-18	am	f	bulge
57	110	15	2013-06-18	pm	f	potential
57	110	15	2013-06-19	am	f	bulge
67	115	15	2013-06-19	pm	f	compas
73	110	15	2013-06-20	am	f	bulge
57	112	15	2013-06-20	pm	f	cilia
72	110	15	2013-06-21	am	f	answer to referee
73	110	15	2013-06-21	pm	f	answer to referee
57	110	15	2013-06-24	am	f	run_it v2.1
72	110	15	2013-06-24	pm	f	answer to referee
57	84	10	2012-12-06	am	f	
67	85	10	2013-06-19	pm	f	ANR Compass
57	110	10	2013-06-24	am	f	
57	110	10	2013-06-24	pm	f	
55	63	29	2013-05-28	am	f	
55	63	29	2013-05-28	pm	f	
55	63	29	2013-05-29	am	f	
55	63	29	2013-05-29	pm	f	
55	63	29	2013-05-30	am	f	
55	63	29	2013-05-30	pm	f	
55	63	29	2013-05-31	am	f	
55	63	29	2013-05-31	pm	f	
55	63	29	2013-06-03	am	f	
55	63	29	2013-06-03	pm	f	
57	63	29	2013-06-04	am	f	
57	63	29	2013-06-04	pm	f	
57	63	29	2013-06-05	am	f	
57	63	29	2013-06-05	pm	f	
57	63	29	2013-06-06	am	f	
57	63	29	2013-06-06	pm	f	
57	63	29	2013-06-07	am	f	
57	63	29	2013-06-07	pm	f	
57	63	29	2013-06-10	am	f	
57	63	29	2013-06-10	pm	f	
57	63	29	2013-06-11	am	f	
57	63	29	2013-06-11	pm	f	
57	63	29	2013-06-12	am	f	
57	63	29	2013-06-12	pm	f	
57	63	29	2013-06-13	am	f	
57	63	29	2013-06-13	pm	f	
57	63	29	2013-06-14	am	f	
57	63	29	2013-06-14	pm	f	
57	63	29	2013-06-17	am	f	
57	63	29	2013-06-17	pm	f	
57	63	29	2013-06-18	am	f	
57	63	29	2013-06-18	pm	f	
57	63	29	2013-06-19	am	f	
57	63	29	2013-06-19	pm	f	
57	63	29	2013-06-20	am	f	
57	63	29	2013-06-20	pm	f	
57	63	29	2013-06-21	am	f	
57	63	29	2013-06-21	pm	f	
57	63	29	2013-06-24	am	f	
57	63	29	2013-06-24	pm	f	
57	63	29	2013-06-25	am	f	
57	63	29	2013-06-25	pm	f	
57	63	29	2013-06-26	am	f	
57	63	29	2013-06-26	pm	f	
57	71	17	2013-06-24	am	f	Working on equalization/normalisation procedures.
57	71	17	2013-06-24	pm	f	Working on equalization/normalisation procedures.
57	71	17	2013-06-25	am	f	Working on equalization/normalisation procedures.
56	71	17	2013-06-25	pm	f	Working on equalization/normalisation procedures, launched new unified LASCO website.
57	71	17	2013-06-26	am	f	Reworking star detection to work on normalized images.
57	71	17	2013-06-26	pm	f	Reworking star detection to work on normalized images.
57	110	10	2013-06-25	am	f	
63	110	10	2013-06-25	pm	f	
57	110	10	2013-06-26	am	f	
57	110	10	2013-06-26	pm	f	
73	110	15	2013-06-25	am	f	bulge
57	115	15	2013-06-25	pm	f	bulge
72	110	15	2013-06-26	am	f	
57	115	15	2013-06-26	pm	f	
57	115	15	2013-06-27	am	f	local ETKF
57	115	15	2013-06-27	pm	f	local ETKF
70	102	22	2013-06-19	pm	f	
\N	\N	22	2013-06-19	am	t	
70	102	22	2013-06-20	pm	f	
70	102	22	2013-06-20	am	f	
70	102	22	2013-06-21	pm	f	
70	102	22	2013-06-21	am	f	
70	102	22	2013-06-24	pm	f	
70	102	22	2013-06-24	am	f	
70	77	22	2013-06-25	pm	f	
70	77	22	2013-06-25	am	f	
\N	\N	22	2013-06-26	pm	t	
57	132	22	2013-06-26	am	f	
\N	\N	22	2013-06-27	pm	t	
57	132	22	2013-06-27	am	f	
56	77	22	2013-06-28	pm	f	
70	77	22	2013-06-28	am	f	
\N	\N	8	2013-06-20	am	t	
\N	\N	8	2013-06-20	pm	t	
\N	\N	8	2013-06-21	am	t	
\N	\N	8	2013-06-21	pm	t	
\N	\N	8	2013-06-24	am	t	
\N	\N	8	2013-06-24	pm	t	
\N	\N	8	2013-06-25	am	t	
\N	\N	8	2013-06-25	pm	t	
\N	\N	8	2013-06-26	am	t	
\N	\N	8	2013-06-26	pm	t	
57	97	8	2013-06-27	am	f	
67	97	8	2013-06-27	pm	f	
57	97	8	2013-06-28	am	f	
57	97	8	2013-06-28	pm	f	
57	71	17	2013-06-14	am	f	Working on equalization/normalisation procedures.
57	71	17	2013-06-21	pm	f	Working on equalization/normalisation procedures.
57	71	17	2013-06-21	am	f	Working on equalization/normalisation procedures.
57	71	17	2013-06-27	am	f	Test running equalization/normalisation procedures.
57	71	17	2013-06-27	pm	f	Test running equalization/normalisation procedures.
57	71	17	2013-06-28	am	f	Test running equalization/normalisation procedures.
57	71	17	2013-06-28	pm	f	Test running equalization/normalisation procedures.
57	71	17	2013-07-01	am	f	Test running equalization/normalisation procedures.
57	97	8	2013-07-01	am	f	
57	97	8	2013-07-01	pm	f	
57	97	8	2013-07-02	am	f	
70	98	8	2013-07-02	pm	f	
70	102	22	2013-07-01	pm	f	
56	77	22	2013-07-01	am	f	
70	102	22	2013-07-02	pm	f	
70	102	22	2013-07-02	am	f	
\N	\N	22	2013-07-03	pm	t	
56	77	22	2013-07-03	am	f	
56	77	22	2013-07-04	am	f	
57	71	17	2013-07-01	pm	f	Test running equalization/normalisation procedures.
57	71	17	2013-07-02	am	f	Working on equalization/normalisation procedures.
57	71	17	2013-07-02	pm	f	Working on equalization/normalisation procedures.
57	71	17	2013-07-03	am	f	Generating graphes for next publication.
67	71	17	2013-07-03	pm	f	
57	71	17	2013-07-04	am	f	Generating graphes for next publication.
56	71	17	2013-07-04	pm	f	Generating graphes for next publication, deploying database to lascolin5.
55	96	4	2013-06-17	am	f	PREDON
55	96	4	2013-06-17	pm	f	PREDON
55	64	4	2013-06-18	am	f	Reunion passage de compétences
55	81	4	2013-06-18	pm	f	analyse
60	89	4	2013-06-19	am	f	Stagiaires et Etudiants
55	96	4	2013-06-19	pm	f	PREDON
66	85	4	2013-06-20	am	f	ITA
66	85	4	2013-06-20	pm	f	ITA
55	64	4	2013-06-21	am	f	Reunion passage de compétences
55	65	4	2013-06-21	pm	f	PTF
66	85	4	2013-06-24	am	f	ITA
66	85	4	2013-06-24	pm	f	ITA
66	85	4	2013-06-25	am	f	ITA
66	85	4	2013-06-25	pm	f	ITA
55	64	4	2013-06-26	am	f	Reunion passage de compétences
55	64	4	2013-06-26	pm	f	Reunion passage de compétences
55	64	4	2013-06-27	am	f	Reunion passage de compétences
67	105	4	2013-06-27	pm	f	DRP
67	81	4	2013-06-28	am	f	AGILE
67	81	4	2013-06-28	pm	f	AGILE
67	96	4	2013-07-01	am	f	reunion Paris MASTODONS
67	96	4	2013-07-01	pm	f	reunion Paris MASTODONS
67	96	4	2013-07-02	am	f	reunion Paris MASTODONS
67	96	4	2013-07-02	pm	f	reunion Paris MASTODONS
55	65	4	2013-07-03	am	f	PTF
55	65	4	2013-07-03	pm	f	PTF
55	134	4	2013-07-04	am	f	preparation reunion 9/07
66	65	4	2013-07-04	pm	f	preparation CRAM
55	134	4	2013-06-07	am	f	Segment sol
55	134	4	2013-06-07	pm	f	Segment sol
59	125	4	2013-06-10	am	f	Jury concours
59	125	4	2013-06-10	pm	f	Jury concours
59	125	4	2013-06-11	am	f	Jury concours
59	125	4	2013-06-11	pm	f	Jury concours
66	89	4	2013-06-12	am	f	EAA
67	85	4	2013-06-12	pm	f	Pytheas - CS
67	81	4	2013-06-13	am	f	scrum
66	89	4	2013-06-13	pm	f	EAA
\N	\N	4	2013-06-14	am	t	
66	89	4	2013-06-14	pm	f	EAA
\N	\N	8	2013-07-03	am	t	
\N	\N	8	2013-07-03	pm	t	
57	89	8	2013-07-04	am	f	
70	98	8	2013-07-04	pm	f	
73	110	15	2013-06-28	am	f	bulge
67	110	15	2013-06-28	pm	f	group meting and some discussion
73	110	15	2013-07-01	am	f	bulge
57	112	15	2013-07-01	pm	f	cilia
57	112	15	2013-07-02	am	f	cilia
57	112	15	2013-07-02	pm	f	cilia
57	112	15	2013-07-03	am	f	cilia
57	112	15	2013-07-03	pm	f	pastis
73	110	15	2013-07-04	am	f	bulge project
73	112	15	2013-07-04	pm	f	cilia with pastis
61	71	16	2013-05-22	am	f	
61	71	16	2013-05-22	pm	f	
61	71	16	2013-05-23	am	f	
61	71	16	2013-05-23	pm	f	
61	71	16	2013-05-24	am	f	
61	71	16	2013-05-24	pm	f	
61	71	16	2013-05-27	am	f	
61	71	16	2013-05-27	pm	f	
61	71	16	2013-05-28	am	f	
61	71	16	2013-05-28	pm	f	
61	71	16	2013-05-29	am	f	
61	71	16	2013-05-29	pm	f	
61	71	16	2013-05-30	am	f	
73	71	16	2013-05-30	pm	f	
73	71	16	2013-05-31	am	f	
61	71	16	2013-05-31	pm	f	
61	71	16	2013-06-03	am	f	
61	71	16	2013-06-03	pm	f	
61	71	16	2013-06-04	am	f	
61	71	16	2013-06-04	pm	f	
61	71	16	2013-06-05	am	f	
61	71	16	2013-06-05	pm	f	
61	71	16	2013-06-06	am	f	
61	71	16	2013-06-06	pm	f	
72	71	16	2013-06-07	am	f	
72	71	16	2013-06-07	pm	f	
72	71	16	2013-06-10	am	f	
72	71	16	2013-06-10	pm	f	
72	71	16	2013-06-11	am	f	
72	71	16	2013-06-11	pm	f	
72	71	16	2013-06-12	am	f	
72	71	16	2013-06-12	pm	f	
72	71	16	2013-06-13	am	f	
72	71	16	2013-06-13	pm	f	
72	71	16	2013-06-14	am	f	
72	71	16	2013-06-14	pm	f	
72	71	16	2013-06-17	am	f	
72	71	16	2013-06-17	pm	f	
72	71	16	2013-06-18	am	f	
72	71	16	2013-06-18	pm	f	
72	71	16	2013-06-19	am	f	
72	71	16	2013-06-19	pm	f	
72	71	16	2013-06-20	am	f	
72	71	16	2013-06-20	pm	f	
72	71	16	2013-06-21	am	f	
72	71	16	2013-06-21	pm	f	
72	71	16	2013-06-24	am	f	
72	71	16	2013-06-24	pm	f	
72	71	16	2013-06-25	am	f	
72	71	16	2013-06-25	pm	f	
72	71	16	2013-06-26	am	f	
72	71	16	2013-06-26	pm	f	
72	71	16	2013-06-27	am	f	
72	71	16	2013-06-27	pm	f	
72	71	16	2013-06-28	am	f	
72	71	16	2013-06-28	pm	f	
72	71	16	2013-07-01	am	f	
72	71	16	2013-07-01	pm	f	
72	71	16	2013-07-02	am	f	
72	71	16	2013-07-02	pm	f	
72	71	16	2013-07-03	am	f	
72	71	16	2013-07-03	pm	f	
72	71	16	2013-07-04	am	f	
72	71	16	2013-07-04	pm	f	
72	71	16	2013-07-05	am	f	
72	71	16	2013-07-05	pm	f	
57	110	10	2013-07-03	am	f	
57	110	10	2013-07-03	pm	f	
57	110	10	2013-07-04	am	f	
57	110	10	2013-07-04	pm	f	
77	89	10	2013-07-05	am	f	
57	110	10	2013-07-05	pm	f	
57	67	19	2013-05-23	pm	f	Refonte datatbles
57	67	19	2013-05-23	am	f	Refonte datatbles
57	67	19	2013-05-24	pm	f	Refonte datatbles
57	67	19	2013-05-24	am	f	Refonte datatbles
57	67	19	2013-05-27	pm	f	Refonte datatbles
57	67	19	2013-05-27	am	f	Refonte datatbles
57	67	19	2013-05-28	pm	f	Refonte datatbles
57	67	19	2013-05-28	am	f	Refonte datatbles
57	67	19	2013-05-29	pm	f	Refonte datatbles
57	67	19	2013-05-29	am	f	Refonte datatbles
57	67	19	2013-05-30	pm	f	Refonte datatbles
57	67	19	2013-05-30	am	f	Refonte datatbles
57	67	19	2013-05-31	pm	f	Refonte datatbles
57	67	19	2013-05-31	am	f	Refonte datatbles
57	67	19	2013-06-03	pm	f	
57	67	19	2013-06-03	am	f	
57	67	19	2013-06-04	pm	f	
57	67	19	2013-06-04	am	f	
57	67	19	2013-06-05	pm	f	
57	67	19	2013-06-05	am	f	
57	67	19	2013-06-06	pm	f	
57	67	19	2013-06-06	am	f	
57	67	19	2013-06-07	pm	f	
57	67	19	2013-06-07	am	f	
62	89	19	2013-06-10	pm	f	Preparation concours interne CNRS
62	89	19	2013-06-10	am	f	Preparation concours interne CNRS
62	89	19	2013-06-11	pm	f	Preparation concours interne CNRS
62	89	19	2013-06-11	am	f	Preparation concours interne CNRS
62	89	19	2013-06-12	pm	f	Preparation concours interne CNRS
62	89	19	2013-06-12	am	f	Preparation concours interne CNRS
67	125	19	2013-06-13	pm	f	Concours interne CNRS
67	125	19	2013-06-13	am	f	Concours interne CNRS
57	67	19	2013-06-14	pm	f	ExoDat developpement (MAJ template-si)
57	67	19	2013-06-14	am	f	ExoDat developpement (MAJ template-si)
57	67	19	2013-06-17	pm	f	ExoDat developpement (MAJ template-si)
57	67	19	2013-06-17	am	f	ExoDat developpement (MAJ template-si)
57	67	19	2013-06-18	pm	f	ExoDat developpement (MAJ template-si)
57	67	19	2013-06-18	am	f	ExoDat developpement (MAJ template-si)
57	67	19	2013-06-19	pm	f	ExoDat developpement (MAJ template-si)
57	67	19	2013-06-19	am	f	ExoDat developpement (MAJ template-si)
57	67	19	2013-06-20	pm	f	ExoDat developpement (MAJ template-si)
57	67	19	2013-06-20	am	f	ExoDat developpement (MAJ template-si)
57	67	19	2013-06-21	pm	f	ExoDat developpement (MAJ template-si)
57	67	19	2013-06-21	am	f	ExoDat developpement (MAJ template-si)
\N	\N	19	2013-06-24	pm	t	
\N	\N	19	2013-06-24	am	t	
\N	\N	19	2013-06-25	pm	t	
\N	\N	19	2013-06-25	am	t	
\N	\N	19	2013-06-26	pm	t	
\N	\N	19	2013-06-26	am	t	
\N	\N	19	2013-06-27	pm	t	
\N	\N	19	2013-06-27	am	t	
\N	\N	19	2013-06-28	pm	t	
\N	\N	19	2013-06-28	am	t	
57	67	19	2013-07-01	pm	f	ExoDat developpement MAJ Juillet
57	67	19	2013-07-01	am	f	ExoDat developpement MAJ Juillet
56	67	19	2013-07-02	pm	f	ExoDat deploiement MAJ Juillet
70	89	19	2013-07-02	am	f	Migration PostgreSQL 9.2
70	89	19	2013-07-03	pm	f	Migration PostgreSQL 9.2
70	89	19	2013-07-03	am	f	Migration PostgreSQL 9.2
70	89	19	2013-07-04	pm	f	Migration PostgreSQL 9.2
70	89	19	2013-07-04	am	f	Migration PostgreSQL 9.2
70	89	19	2013-07-05	pm	f	Migration PostgreSQL 9.2
70	89	19	2013-07-05	am	f	Migration PostgreSQL 9.2
70	71	17	2013-07-05	am	f	Created new export on lascopg for contributions, downloading and db indexing newest images.
57	70	28	2013-05-15	am	f	analyse de spectrométrie moléculaire MALT90
57	70	28	2013-05-15	pm	f	analyse de spectrométrie moléculaire MALT90
57	70	28	2013-05-16	am	f	analyse de spectrométrie moléculaire MALT90
57	70	28	2013-05-16	pm	f	analyse de spectrométrie moléculaire MALT90
57	70	28	2013-05-17	am	f	analyse de spectrométrie moléculaire MALT90
57	70	28	2013-05-17	pm	f	analyse de spectrométrie moléculaire MALT90
57	70	28	2013-05-20	am	f	analyse de spectrométrie moléculaire MALT90
57	70	28	2013-05-20	pm	f	analyse de spectrométrie moléculaire MALT90
57	70	28	2013-05-21	am	f	analyse de spectrométrie moléculaire MALT90
57	70	28	2013-05-21	pm	f	analyse de spectrométrie moléculaire MALT90
57	70	28	2013-05-22	am	f	analyse de spectrométrie moléculaire MALT90
57	70	28	2013-05-22	pm	f	analyse de spectrométrie moléculaire MALT90
57	70	28	2013-05-23	am	f	analyse de spectrométrie moléculaire MALT90
57	70	28	2013-05-23	pm	f	analyse de spectrométrie moléculaire MALT90
57	70	28	2013-05-24	am	f	analyse de spectrométrie moléculaire MALT90
57	70	28	2013-05-24	pm	f	analyse de spectrométrie moléculaire MALT90
57	70	28	2013-05-27	am	f	analyse de spectrométrie moléculaire MALT90
57	70	28	2013-05-27	pm	f	analyse de spectrométrie moléculaire MALT90
57	71	23	2013-02-18	am	f	
57	71	23	2013-02-19	pm	f	
57	71	23	2013-02-19	am	f	
57	71	23	2013-02-20	pm	f	
57	70	28	2013-05-28	am	f	analyse de spectrométrie moléculaire MALT90
57	70	28	2013-05-28	pm	f	analyse de spectrométrie moléculaire MALT90
57	70	28	2013-05-29	am	f	analyse de spectrométrie moléculaire MALT90
57	70	28	2013-05-29	pm	f	analyse de spectrométrie moléculaire MALT90
57	70	28	2013-05-30	am	f	analyse de spectrométrie moléculaire MALT90
57	70	28	2013-05-30	pm	f	analyse de spectrométrie moléculaire MALT90
57	70	28	2013-05-31	am	f	analyse de spectrométrie moléculaire MALT90
57	70	28	2013-05-31	pm	f	analyse de spectrométrie moléculaire MALT90
57	70	28	2013-06-03	am	f	analyse de spectrométrie moléculaire MALT90
57	70	28	2013-06-03	pm	f	analyse de spectrométrie moléculaire MALT90
57	70	28	2013-06-04	am	f	analyse de spectrométrie moléculaire MALT90
57	70	28	2013-06-04	pm	f	analyse de spectrométrie moléculaire MALT90
57	70	28	2013-06-05	am	f	analyse de spectrométrie moléculaire MALT90
57	70	28	2013-06-05	pm	f	analyse de spectrométrie moléculaire MALT90
57	70	28	2013-06-06	am	f	analyse de spectrométrie moléculaire MALT90
57	70	28	2013-06-06	pm	f	analyse de spectrométrie moléculaire MALT90
57	70	28	2013-06-07	am	f	analyse de spectrométrie moléculaire MALT90
57	70	28	2013-06-07	pm	f	analyse de spectrométrie moléculaire MALT90
57	70	28	2013-06-10	am	f	analyse de spectrométrie moléculaire MALT90
57	70	28	2013-06-10	pm	f	analyse de spectrométrie moléculaire MALT90
57	70	28	2013-06-11	am	f	analyse de spectrométrie moléculaire MALT90
57	70	28	2013-06-11	pm	f	analyse de spectrométrie moléculaire MALT90
57	70	28	2013-06-12	am	f	analyse de spectrométrie moléculaire MALT90
57	70	28	2013-06-12	pm	f	analyse de spectrométrie moléculaire MALT90
57	70	28	2013-06-13	am	f	analyse de spectrométrie moléculaire MALT90
57	70	28	2013-06-13	pm	f	analyse de spectrométrie moléculaire MALT90
57	70	28	2013-06-14	am	f	analyse de spectrométrie moléculaire MALT90
57	70	28	2013-06-14	pm	f	analyse de spectrométrie moléculaire MALT90
57	70	28	2013-06-17	am	f	analyse de spectrométrie moléculaire MALT90
57	70	28	2013-06-17	pm	f	analyse de spectrométrie moléculaire MALT90
57	70	28	2013-06-18	am	f	analyse de spectrométrie moléculaire MALT90
57	70	28	2013-06-18	pm	f	analyse de spectrométrie moléculaire MALT90
57	70	28	2013-06-19	am	f	analyse de spectrométrie moléculaire MALT90
57	70	28	2013-06-19	pm	f	analyse de spectrométrie moléculaire MALT90
57	70	28	2013-06-20	am	f	analyse de spectrométrie moléculaire MALT90
57	70	28	2013-06-20	pm	f	analyse de spectrométrie moléculaire MALT90
57	70	28	2013-06-21	am	f	analyse de spectrométrie moléculaire MALT90
57	70	28	2013-06-21	pm	f	analyse de spectrométrie moléculaire MALT90
57	70	28	2013-06-24	am	f	analyse de spectrométrie moléculaire MALT90
57	70	28	2013-06-24	pm	f	analyse de spectrométrie moléculaire MALT90
57	70	28	2013-06-25	am	f	analyse de spectrométrie moléculaire MALT90
57	70	28	2013-06-25	pm	f	analyse de spectrométrie moléculaire MALT90
57	70	28	2013-06-26	am	f	analyse de spectrométrie moléculaire MALT90
57	70	28	2013-06-26	pm	f	analyse de spectrométrie moléculaire MALT90
57	70	28	2013-06-27	am	f	analyse de spectrométrie moléculaire MALT90
57	70	28	2013-06-27	pm	f	analyse de spectrométrie moléculaire MALT90
57	70	28	2013-06-28	am	f	analyse de spectrométrie moléculaire MALT90
57	70	28	2013-06-28	pm	f	analyse de spectrométrie moléculaire MALT90
57	70	28	2013-07-01	am	f	analyse de spectrométrie moléculaire MALT90
57	70	28	2013-07-01	pm	f	analyse de spectrométrie moléculaire MALT90
57	70	28	2013-07-02	am	f	analyse de spectrométrie moléculaire MALT90
57	70	28	2013-07-02	pm	f	analyse de spectrométrie moléculaire MALT90
57	70	28	2013-07-03	am	f	analyse de spectrométrie moléculaire MALT90
57	70	28	2013-07-03	pm	f	analyse de spectrométrie moléculaire MALT90
57	70	28	2013-07-04	am	f	analyse de spectrométrie moléculaire MALT90
57	70	28	2013-07-04	pm	f	analyse de spectrométrie moléculaire MALT90
57	70	28	2013-07-05	am	f	analyse de spectrométrie moléculaire MALT90
57	70	28	2013-07-05	pm	f	analyse de spectrométrie moléculaire MALT90
57	71	23	2013-01-17	pm	f	
57	71	23	2013-01-17	am	f	
57	71	23	2013-01-18	pm	f	
57	71	23	2013-01-18	am	f	
57	71	23	2013-01-21	pm	f	
57	71	23	2013-01-21	am	f	
57	71	23	2013-01-22	pm	f	
57	71	23	2013-01-22	am	f	
57	71	23	2013-01-23	pm	f	
57	71	23	2013-01-23	am	f	
57	71	23	2013-01-24	pm	f	
57	71	23	2013-01-24	am	f	
57	71	23	2013-01-25	pm	f	
57	71	23	2013-01-25	am	f	
57	71	23	2013-01-28	pm	f	
57	71	23	2013-01-28	am	f	
57	71	23	2013-01-29	pm	f	
57	71	23	2013-01-29	am	f	
57	71	23	2013-01-30	pm	f	
57	71	23	2013-01-30	am	f	
57	71	23	2013-01-31	pm	f	
57	71	23	2013-01-31	am	f	
57	71	23	2013-02-01	pm	f	
57	71	23	2013-02-01	am	f	
57	71	23	2013-02-04	pm	f	
57	71	23	2013-02-04	am	f	
57	71	23	2013-02-05	pm	f	
57	71	23	2013-02-05	am	f	
57	71	23	2013-02-06	pm	f	
57	71	23	2013-02-06	am	f	
57	71	23	2013-02-07	pm	f	
57	71	23	2013-02-07	am	f	
57	71	23	2013-02-08	pm	f	
57	71	23	2013-02-08	am	f	
57	71	23	2013-02-11	pm	f	
57	71	23	2013-02-11	am	f	
57	71	23	2013-02-12	pm	f	
57	71	23	2013-02-12	am	f	
57	71	23	2013-02-13	pm	f	
57	71	23	2013-02-13	am	f	
57	71	23	2013-02-14	pm	f	
57	71	23	2013-02-14	am	f	
57	71	23	2013-02-15	pm	f	
57	71	23	2013-02-15	am	f	
57	71	23	2013-02-18	pm	f	
57	71	23	2013-02-20	am	f	
57	71	23	2013-02-21	pm	f	
57	71	23	2013-02-21	am	f	
57	71	23	2013-02-22	pm	f	
57	71	23	2013-02-22	am	f	
57	71	23	2013-02-25	pm	f	
57	71	23	2013-02-25	am	f	
57	71	23	2013-02-26	pm	f	
57	71	23	2013-02-26	am	f	
57	71	23	2013-02-27	pm	f	
57	71	23	2013-02-27	am	f	
57	71	23	2013-02-28	pm	f	
57	71	23	2013-02-28	am	f	
57	71	23	2013-03-01	pm	f	
57	71	23	2013-03-01	am	f	
57	71	23	2013-03-04	pm	f	
57	71	23	2013-03-04	am	f	
57	71	23	2013-03-05	pm	f	
57	71	23	2013-03-05	am	f	
57	71	23	2013-03-06	pm	f	
57	71	23	2013-03-06	am	f	
57	71	23	2013-03-07	pm	f	
57	71	23	2013-03-07	am	f	
57	71	23	2013-03-08	pm	f	
57	71	23	2013-03-08	am	f	
57	71	23	2013-03-11	pm	f	
57	71	23	2013-03-11	am	f	
57	71	23	2013-03-12	pm	f	
57	71	23	2013-03-12	am	f	
57	71	23	2013-03-13	pm	f	
57	71	23	2013-03-13	am	f	
57	71	23	2013-03-14	pm	f	
57	71	23	2013-03-14	am	f	
57	71	23	2013-03-15	pm	f	
57	71	23	2013-03-15	am	f	
57	71	23	2013-03-18	pm	f	
57	71	23	2013-03-18	am	f	
57	71	23	2013-03-19	pm	f	
57	71	23	2013-03-19	am	f	
57	71	23	2013-03-20	pm	f	
57	71	23	2013-03-20	am	f	
57	71	23	2013-03-21	pm	f	
57	71	23	2013-03-21	am	f	
57	71	23	2013-03-22	pm	f	
57	71	23	2013-03-22	am	f	
57	71	23	2013-03-25	pm	f	
57	71	23	2013-03-25	am	f	
57	71	23	2013-03-26	pm	f	
57	71	23	2013-03-26	am	f	
57	71	23	2013-03-27	pm	f	
57	71	23	2013-03-27	am	f	
57	71	23	2013-03-28	pm	f	
57	71	23	2013-03-28	am	f	
57	71	23	2013-03-29	pm	f	
57	71	23	2013-03-29	am	f	
57	71	23	2013-04-01	pm	f	
57	71	23	2013-04-01	am	f	
57	71	23	2013-04-02	pm	f	
57	71	23	2013-04-02	am	f	
57	71	23	2013-04-03	pm	f	
57	71	23	2013-04-03	am	f	
57	71	23	2013-04-04	pm	f	
57	71	23	2013-04-04	am	f	
57	71	23	2013-04-05	pm	f	
57	71	23	2013-04-05	am	f	
57	71	23	2013-04-08	pm	f	
57	71	23	2013-04-08	am	f	
57	71	23	2013-04-09	pm	f	
57	71	23	2013-04-09	am	f	
57	71	23	2013-04-10	pm	f	
57	71	23	2013-04-10	am	f	
57	71	23	2013-04-11	pm	f	
57	71	23	2013-04-11	am	f	
57	71	23	2013-04-12	pm	f	
57	71	23	2013-04-12	am	f	
57	71	23	2013-04-15	pm	f	
57	71	23	2013-04-15	am	f	
57	71	23	2013-04-16	pm	f	
57	71	23	2013-04-16	am	f	
57	71	23	2013-04-17	pm	f	
57	71	23	2013-04-17	am	f	
57	71	23	2013-04-18	pm	f	
57	71	23	2013-04-18	am	f	
57	71	23	2013-04-19	pm	f	
57	71	23	2013-04-19	am	f	
57	71	23	2013-04-22	pm	f	
57	71	23	2013-04-22	am	f	
57	71	23	2013-04-23	pm	f	
57	71	23	2013-04-23	am	f	
57	71	23	2013-04-24	pm	f	
57	71	23	2013-04-24	am	f	
57	71	23	2013-04-25	pm	f	
57	71	23	2013-04-25	am	f	
57	71	23	2013-04-26	pm	f	
57	71	23	2013-04-26	am	f	
57	71	23	2013-04-29	pm	f	
57	71	23	2013-04-29	am	f	
57	71	23	2013-04-30	pm	f	
57	71	23	2013-04-30	am	f	
57	71	23	2013-05-01	pm	f	
57	71	23	2013-05-01	am	f	
57	71	23	2013-05-02	pm	f	
57	71	23	2013-05-02	am	f	
57	71	23	2013-05-03	pm	f	
57	71	23	2013-05-03	am	f	
57	71	23	2013-05-06	pm	f	
57	71	23	2013-05-06	am	f	
57	71	23	2013-05-07	pm	f	
57	71	23	2013-05-07	am	f	
57	71	23	2013-05-08	pm	f	
57	71	23	2013-05-08	am	f	
57	71	23	2013-05-09	pm	f	
57	71	23	2013-05-09	am	f	
57	71	23	2013-05-10	pm	f	
57	71	23	2013-05-10	am	f	
57	71	23	2013-05-13	pm	f	
57	71	23	2013-05-13	am	f	
57	71	23	2013-05-14	pm	f	
57	71	23	2013-05-14	am	f	
57	71	23	2013-05-15	pm	f	
57	71	23	2013-05-15	am	f	
57	71	23	2013-05-16	pm	f	
57	71	23	2013-05-16	am	f	
57	71	23	2013-05-17	pm	f	
57	71	23	2013-05-17	am	f	
57	71	23	2013-05-20	pm	f	
57	71	23	2013-05-20	am	f	
57	71	23	2013-05-21	pm	f	
57	71	23	2013-05-21	am	f	
57	71	23	2013-05-22	pm	f	
57	71	23	2013-05-22	am	f	
57	71	23	2013-05-23	pm	f	
57	71	23	2013-05-23	am	f	
57	71	23	2013-05-24	pm	f	
57	71	23	2013-05-24	am	f	
57	71	23	2013-05-27	pm	f	
57	71	23	2013-05-27	am	f	
57	71	23	2013-05-28	pm	f	
57	71	23	2013-05-28	am	f	
57	71	23	2013-05-29	pm	f	
57	71	23	2013-05-29	am	f	
57	71	23	2013-05-30	pm	f	
57	71	23	2013-05-30	am	f	
57	71	23	2013-05-31	pm	f	
57	71	23	2013-05-31	am	f	
57	71	23	2013-06-03	pm	f	
57	71	23	2013-06-03	am	f	
57	71	23	2013-06-04	pm	f	
57	71	23	2013-06-04	am	f	
57	71	23	2013-06-05	pm	f	
57	71	23	2013-06-05	am	f	
57	71	23	2013-06-06	pm	f	
57	71	23	2013-06-06	am	f	
57	71	23	2013-06-07	pm	f	
57	71	23	2013-06-07	am	f	
57	71	23	2013-06-10	pm	f	
57	71	23	2013-06-10	am	f	
57	71	23	2013-06-11	pm	f	
57	71	23	2013-06-11	am	f	
57	71	23	2013-06-12	pm	f	
57	71	23	2013-06-12	am	f	
57	71	23	2013-06-13	pm	f	
57	71	23	2013-06-13	am	f	
57	71	23	2013-06-14	pm	f	
57	71	23	2013-06-14	am	f	
57	71	23	2013-06-17	pm	f	
57	71	23	2013-06-17	am	f	
57	71	23	2013-06-18	pm	f	
57	71	23	2013-06-18	am	f	
57	71	23	2013-06-19	pm	f	
57	71	23	2013-06-19	am	f	
57	71	23	2013-06-20	pm	f	
57	71	23	2013-06-20	am	f	
57	71	23	2013-06-21	pm	f	
57	71	23	2013-06-21	am	f	
57	71	23	2013-06-24	pm	f	
57	71	23	2013-06-24	am	f	
57	71	23	2013-06-25	pm	f	
57	71	23	2013-06-25	am	f	
57	71	23	2013-06-26	pm	f	
57	71	23	2013-06-26	am	f	
57	71	23	2013-06-27	pm	f	
57	71	23	2013-06-27	am	f	
57	71	23	2013-06-28	pm	f	
57	71	23	2013-06-28	am	f	
57	71	23	2013-07-01	pm	f	
57	71	23	2013-07-01	am	f	
57	71	23	2013-07-02	pm	f	
57	71	23	2013-07-02	am	f	
57	71	23	2013-07-03	pm	f	
57	71	23	2013-07-03	am	f	
57	71	23	2013-07-04	pm	f	
57	71	23	2013-07-04	am	f	
57	71	23	2013-07-05	pm	f	
57	71	23	2013-07-05	am	f	
70	98	8	2013-07-05	am	f	
67	97	8	2013-07-05	pm	f	
63	71	17	2013-07-05	pm	f	Carrdates bug solving on lascolin2 (contributions update).
58	71	17	2013-07-08	am	f	Documenting new pipeline procedures.
58	71	17	2013-07-08	pm	f	Documenting new pipeline procedures.
57	97	8	2013-07-08	am	f	
57	97	8	2013-07-08	pm	f	
69	77	22	2013-07-04	pm	f	
70	102	22	2013-07-05	pm	f	
70	102	22	2013-07-05	am	f	
69	132	22	2013-07-08	pm	f	
70	132	22	2013-07-08	am	f	
69	132	22	2013-07-09	pm	f	
69	132	22	2013-07-09	am	f	
69	66	22	2013-07-10	pm	f	
69	66	22	2013-07-10	am	f	
61	71	17	2013-07-10	pm	f	Testing new missing blocks correction python porcedure.
57	97	8	2013-07-09	am	f	
57	97	8	2013-07-09	pm	f	
57	97	8	2013-07-10	am	f	
57	97	8	2013-07-10	pm	f	
63	74	11	2013-07-09	am	f	
55	74	11	2013-07-09	pm	f	DIVA 
57	64	11	2013-07-10	am	f	Plugin Fabry-Perot
57	64	11	2013-07-10	pm	f	Plugin Fabry-Perot
57	64	11	2013-07-11	am	f	Plugin Fabry-Perot
57	64	11	2013-07-11	pm	f	Plugin Fabry-Perot
\N	\N	11	2013-07-03	am	t	
\N	\N	11	2013-07-03	pm	t	
56	63	11	2013-07-12	pm	f	
62	64	11	2013-07-02	am	f	
55	74	11	2013-07-08	am	f	DIVA
55	74	11	2013-07-08	pm	f	DIVA
71	63	11	2013-07-12	am	f	bug JNLP
70	71	17	2013-07-10	am	f	Reworking graphes for next publication.
70	71	17	2013-07-11	am	f	Reworking graphes for next publication.
57	71	17	2013-07-11	pm	f	Ended downloading and inserting latest images in lasco db, cleanup on lascodev.
70	71	17	2013-07-12	am	f	Reworking graphes for next publication.
71	71	17	2013-07-12	pm	f	Maintenance on lascohd (kernel panic recovery, updated shares).
57	97	8	2013-07-11	am	f	
57	97	8	2013-07-11	pm	f	
57	97	8	2013-07-12	am	f	
57	97	8	2013-07-12	pm	f	
57	71	17	2013-07-09	am	f	Integrating new missing blocks correction python porcedure.
57	71	17	2013-07-09	pm	f	Integrating new missing blocks correction python procedure.
57	71	17	2013-07-15	am	f	Working on a new procedures to prevent remote download errors in images.
57	71	17	2013-07-15	pm	f	Working on a new procedures to prevent remote download errors in images.
70	89	19	2013-07-08	pm	f	Developpement pg_log_capture
70	89	19	2013-07-08	am	f	Developpement pg_log_capture
70	89	19	2013-07-09	pm	f	Developpement pg_log_capture
70	89	19	2013-07-09	am	f	Developpement pg_log_capture
70	89	19	2013-07-10	pm	f	Developpement pg_log_capture
70	89	19	2013-07-10	am	f	Developpement pg_log_capture
\N	\N	19	2013-07-11	pm	t	
\N	\N	19	2013-07-11	am	t	
\N	\N	19	2013-07-12	pm	t	
\N	\N	19	2013-07-12	am	t	
70	89	19	2013-07-15	pm	f	Migration PostgreSQL 9.2
70	89	19	2013-07-15	am	f	Migration PostgreSQL 9.2
70	89	19	2013-07-16	pm	f	Migration PostgreSQL 9.2
70	89	19	2013-07-16	am	f	Migration PostgreSQL 9.2
57	131	20	2013-06-18	pm	f	Module de telechargement des images
57	131	20	2013-06-18	am	f	Module de telechargement des images
57	131	20	2013-06-19	pm	f	Module de telechargement des images
57	131	20	2013-06-19	am	f	Module de telechargement des images
57	131	20	2013-06-20	pm	f	Module de telechargement des images
57	131	20	2013-06-20	am	f	Module de telechargement des images
57	66	20	2013-06-21	pm	f	HST-Cosmos bascule sous ANIS
57	66	20	2013-06-21	am	f	HST-Cosmos bascule sous ANIS
57	66	20	2013-06-24	pm	f	HST-Cosmos bascule sous ANIS
57	66	20	2013-06-24	am	f	HST-Cosmos bascule sous ANIS
57	66	20	2013-06-25	pm	f	HST-Cosmos bascule sous ANIS
57	66	20	2013-06-25	am	f	HST-Cosmos bascule sous ANIS
57	66	20	2013-06-26	pm	f	HST-Cosmos bascule sous ANIS
57	66	20	2013-06-26	am	f	HST-Cosmos bascule sous ANIS
57	66	20	2013-06-27	pm	f	HST-Cosmos bascule sous ANIS
57	136	20	2013-06-27	am	f	Page de detail
\N	\N	20	2013-06-28	pm	t	
\N	\N	20	2013-06-28	am	t	
56	66	20	2013-07-01	pm	f	Deploiement base VVDS
57	136	20	2013-07-01	am	f	Resolveur de nom
56	136	20	2013-07-02	pm	f	
70	89	20	2013-07-02	am	f	Migration des serveurs BdD en version 9.2
70	89	20	2013-07-03	pm	f	Migration des serveurs BdD en version 9.2
70	89	20	2013-07-03	am	f	Migration des serveurs BdD en version 9.2
70	89	20	2013-07-04	pm	f	Migration des serveurs BdD en version 9.2
70	89	20	2013-07-04	am	f	Migration des serveurs BdD en version 9.2
70	89	20	2013-07-05	pm	f	Migration des serveurs BdD en version 9.2
70	89	20	2013-07-05	am	f	Migration des serveurs BdD en version 9.2
\N	\N	20	2013-07-08	pm	t	
\N	\N	20	2013-07-08	am	t	
\N	\N	20	2013-07-09	pm	t	
\N	\N	20	2013-07-09	am	t	
\N	\N	20	2013-07-10	pm	t	
\N	\N	20	2013-07-10	am	t	
\N	\N	20	2013-07-11	pm	t	
\N	\N	20	2013-07-11	am	t	
\N	\N	20	2013-07-12	pm	t	
\N	\N	20	2013-07-12	am	t	
70	89	20	2013-07-15	pm	f	Migration des serveurs BdD en version 9.2
70	89	20	2013-07-15	am	f	Migration des serveurs BdD en version 9.2
70	89	20	2013-07-16	pm	f	Migration des serveurs BdD en version 9.2
70	89	20	2013-07-16	am	f	Migration des serveurs BdD en version 9.2
69	132	22	2013-07-11	pm	f	ANIS
69	132	22	2013-07-11	am	f	ANIS
69	132	22	2013-07-12	pm	f	ANIS
69	132	22	2013-07-12	am	f	ANIS
69	66	22	2013-07-15	pm	f	HST-COSMOS sous ANIS
69	66	22	2013-07-15	am	f	HST-COSMOS sous ANIS
69	66	22	2013-07-16	pm	f	HST-COSMOS sous ANIS
69	66	22	2013-07-16	am	f	HST-COSMOS sous ANIS
70	77	22	2013-07-17	am	f	
\N	\N	15	2013-07-05	am	t	
\N	\N	15	2013-07-05	pm	t	
\N	\N	15	2013-07-08	am	t	
\N	\N	15	2013-07-08	pm	t	
\N	\N	15	2013-07-09	am	t	
\N	\N	15	2013-07-09	pm	t	
\N	\N	15	2013-07-10	am	t	
\N	\N	15	2013-07-10	pm	t	
\N	\N	15	2013-07-11	am	t	
\N	\N	15	2013-07-11	pm	t	
\N	\N	15	2013-07-12	am	t	
\N	\N	15	2013-07-12	pm	t	
\N	\N	15	2013-07-15	am	t	
\N	\N	15	2013-07-15	pm	t	
\N	\N	15	2013-07-16	am	t	
\N	\N	15	2013-07-16	pm	t	
\N	\N	15	2013-07-17	am	t	
\N	\N	15	2013-07-17	pm	t	
\N	\N	15	2013-07-18	am	t	
\N	\N	15	2013-07-18	pm	t	
73	110	15	2013-07-19	am	f	bulge
73	112	15	2013-07-19	pm	f	silia&PASTIS
73	110	15	2013-07-22	am	f	bulge
73	112	15	2013-07-22	pm	f	silia&PASTIS
63	110	10	2013-07-16	am	f	
56	89	10	2013-07-16	pm	f	p.mollitor
56	89	10	2013-07-17	am	f	v.perret
57	89	10	2013-07-17	pm	f	v. perret
63	110	10	2013-07-18	am	f	
63	110	10	2013-07-18	pm	f	
73	110	10	2013-07-19	am	f	
57	89	10	2013-07-19	pm	f	unsio
73	110	10	2013-07-22	am	f	
57	89	10	2013-07-22	pm	f	unsio
73	110	10	2013-07-23	am	f	
57	89	10	2013-07-23	pm	f	
\N	\N	22	2013-07-17	pm	t	
70	77	22	2013-07-18	pm	f	
70	77	22	2013-07-18	am	f	
69	66	22	2013-07-19	pm	f	HST-COSMOS
69	66	22	2013-07-19	am	f	HST-COSMOS
69	66	22	2013-07-22	pm	f	HST-COSMOS
69	66	22	2013-07-22	am	f	HST-COSMOS
69	66	22	2013-07-23	pm	f	HST-COSMOS
69	66	22	2013-07-23	am	f	HST-COSMOS
69	135	22	2013-07-24	pm	f	
\N	\N	22	2013-07-24	am	t	
69	66	22	2013-07-25	pm	f	XMM-LSS
69	66	22	2013-07-25	am	f	XMM-LSS
69	66	22	2013-07-26	pm	f	XMM-LSS
69	66	22	2013-07-26	am	f	XMM-LSS
57	102	22	2013-07-29	pm	f	
70	102	22	2013-07-29	am	f	
70	102	22	2013-07-30	am	f	
63	89	5	2013-06-24	am	f	
63	89	5	2013-06-24	pm	f	
55	89	5	2013-06-25	am	f	
55	89	5	2013-06-25	pm	f	
69	89	5	2013-06-26	am	f	
69	89	5	2013-06-26	pm	f	
63	89	5	2013-06-27	am	f	
63	89	5	2013-06-27	pm	f	
63	89	5	2013-06-28	am	f	
63	89	5	2013-06-28	pm	f	
\N	\N	5	2013-07-01	am	t	
\N	\N	5	2013-07-01	pm	t	
\N	\N	5	2013-07-02	am	t	
\N	\N	5	2013-07-02	pm	t	
\N	\N	5	2013-07-03	am	t	
\N	\N	5	2013-07-03	pm	t	
\N	\N	5	2013-07-04	am	t	
\N	\N	5	2013-07-04	pm	t	
\N	\N	5	2013-07-05	am	t	
\N	\N	5	2013-07-05	pm	t	
\N	\N	5	2013-07-08	am	t	
\N	\N	5	2013-07-08	pm	t	
\N	\N	5	2013-07-09	am	t	
\N	\N	5	2013-07-09	pm	t	
\N	\N	5	2013-07-10	am	t	
\N	\N	5	2013-07-10	pm	t	
\N	\N	5	2013-07-11	am	t	
\N	\N	5	2013-07-11	pm	t	
\N	\N	5	2013-07-12	am	t	
\N	\N	5	2013-07-12	pm	t	
63	89	5	2013-07-15	am	f	
63	89	5	2013-07-15	pm	f	
63	89	5	2013-07-16	am	f	
63	89	5	2013-07-16	pm	f	
63	89	5	2013-07-17	am	f	
63	89	5	2013-07-17	pm	f	
56	116	5	2013-07-18	am	f	
56	116	5	2013-07-18	pm	f	
63	89	5	2013-07-19	am	f	
63	89	5	2013-07-19	pm	f	
71	89	5	2013-07-22	am	f	
71	89	5	2013-07-22	pm	f	
71	115	5	2013-07-23	am	f	
59	100	5	2013-07-23	pm	f	
59	100	5	2013-07-24	am	f	
59	100	5	2013-07-24	pm	f	
59	100	5	2013-07-25	am	f	
59	100	5	2013-07-25	pm	f	
63	89	5	2013-07-26	am	f	
63	89	5	2013-07-26	pm	f	
71	89	5	2013-07-29	am	f	
71	89	5	2013-07-29	pm	f	
69	89	5	2013-07-30	am	f	
69	89	5	2013-07-30	pm	f	
69	89	5	2013-07-31	am	f	
69	89	5	2013-07-31	pm	f	
55	89	5	2013-08-01	am	f	
55	89	5	2013-08-01	pm	f	
\N	\N	8	2013-07-15	am	t	
\N	\N	8	2013-07-15	pm	t	
\N	\N	8	2013-07-16	am	t	
\N	\N	8	2013-07-16	pm	t	
\N	\N	8	2013-07-17	am	t	
\N	\N	8	2013-07-17	pm	t	
\N	\N	8	2013-07-18	am	t	
\N	\N	8	2013-07-18	pm	t	
\N	\N	8	2013-07-19	am	t	
\N	\N	8	2013-07-19	pm	t	
\N	\N	8	2013-07-22	am	t	
\N	\N	8	2013-07-22	pm	t	
\N	\N	8	2013-07-23	am	t	
\N	\N	8	2013-07-23	pm	t	
\N	\N	8	2013-07-24	am	t	
\N	\N	8	2013-07-24	pm	t	
\N	\N	8	2013-07-25	am	t	
\N	\N	8	2013-07-25	pm	t	
\N	\N	8	2013-07-26	am	t	
\N	\N	8	2013-07-26	pm	t	
\N	\N	8	2013-07-29	am	t	
\N	\N	8	2013-07-29	pm	t	
\N	\N	8	2013-07-30	am	t	
\N	\N	8	2013-07-30	pm	t	
\N	\N	8	2013-07-31	am	t	
\N	\N	8	2013-07-31	pm	t	
\N	\N	8	2013-08-01	am	t	
\N	\N	8	2013-08-01	pm	t	
\N	\N	8	2013-08-02	am	t	
\N	\N	8	2013-08-02	pm	t	
\N	\N	8	2013-08-05	am	t	
\N	\N	8	2013-08-05	pm	t	
\N	\N	8	2013-08-06	am	t	
\N	\N	8	2013-08-06	pm	t	
67	89	15	2013-07-29	am	f	AGI-2013 Beijing
67	89	15	2013-07-29	pm	f	AGI-2013 Beijing
67	89	15	2013-07-30	am	f	AGI-2013 Beijing
67	89	15	2013-07-30	pm	f	AGI-2013 Beijing
67	89	15	2013-07-31	am	f	AGI-2013 Beijing
67	89	15	2013-07-31	pm	f	AGI-2013 Beijing
67	89	15	2013-08-01	am	f	AGI-2013 Beijing
67	89	15	2013-08-01	pm	f	AGI-2013 Beijing
67	89	15	2013-08-02	am	f	AGI-2013 Beijing
67	89	15	2013-08-02	pm	f	AGI-2013 Beijing
67	89	15	2013-08-05	am	f	AGI-2013 Beijing
67	89	15	2013-08-05	pm	f	AGI-2013 Beijing
55	112	15	2013-08-08	am	f	corot-22
55	112	15	2013-08-08	pm	f	corot-22
73	110	15	2013-07-23	am	f	bulge
73	110	15	2013-07-23	pm	f	bulge
73	110	15	2013-07-24	am	f	bulge
57	110	15	2013-07-24	pm	f	bulge
57	112	15	2013-07-25	am	f	cilia
57	112	15	2013-07-25	pm	f	cilia
67	112	15	2013-07-26	am	f	cilia
55	112	15	2013-07-26	pm	f	cilia
67	89	15	2013-08-06	am	f	AGI-2013 Beijing
67	89	15	2013-08-06	pm	f	AGI-2013 Beijing
73	110	15	2013-08-07	am	f	bulge project
55	110	15	2013-08-07	pm	f	bulge project
57	110	15	2013-08-09	am	f	gadget3 chemical
73	110	15	2013-08-09	pm	f	gadget3 chemical
73	110	15	2013-08-12	am	f	bulge project
67	110	15	2013-08-12	pm	f	with lia about bulge project
\N	\N	8	2013-08-07	am	t	
\N	\N	8	2013-08-07	pm	t	
\N	\N	8	2013-08-08	am	t	
\N	\N	8	2013-08-08	pm	t	
\N	\N	8	2013-08-09	am	t	
\N	\N	8	2013-08-09	pm	t	
57	98	8	2013-08-12	am	f	
57	98	8	2013-08-12	pm	f	
70	98	8	2013-08-13	am	f	
70	98	8	2013-08-13	pm	f	
67	112	15	2013-08-13	am	f	pastis
57	110	15	2013-08-13	pm	f	gadget3_chemical
73	110	15	2013-08-14	am	f	bulge project
73	110	15	2013-08-14	pm	f	gadget3 chemical
\N	\N	4	2013-07-08	am	t	
\N	\N	4	2013-07-08	pm	t	
\N	\N	4	2013-07-09	am	t	
\N	\N	4	2013-07-09	pm	t	
\N	\N	4	2013-07-10	am	t	
\N	\N	4	2013-07-10	pm	t	
\N	\N	4	2013-07-11	am	t	
\N	\N	4	2013-07-11	pm	t	
\N	\N	4	2013-07-12	am	t	
\N	\N	4	2013-07-12	pm	t	
\N	\N	4	2013-07-15	am	t	
\N	\N	4	2013-07-15	pm	t	
\N	\N	4	2013-07-16	am	t	
\N	\N	4	2013-07-16	pm	t	
\N	\N	4	2013-07-17	am	t	
\N	\N	4	2013-07-17	pm	t	
\N	\N	4	2013-07-18	am	t	
\N	\N	4	2013-07-18	pm	t	
\N	\N	4	2013-07-19	am	t	
\N	\N	4	2013-07-19	pm	t	
\N	\N	4	2013-07-22	am	t	
\N	\N	4	2013-07-22	pm	t	
\N	\N	4	2013-07-23	am	t	
\N	\N	4	2013-07-23	pm	t	
\N	\N	4	2013-07-24	am	t	
\N	\N	4	2013-07-24	pm	t	
\N	\N	4	2013-07-25	am	t	
\N	\N	4	2013-07-25	pm	t	
\N	\N	4	2013-07-26	am	t	
\N	\N	4	2013-07-26	pm	t	
\N	\N	4	2013-07-29	am	t	
\N	\N	4	2013-07-29	pm	t	
\N	\N	4	2013-07-30	am	t	
\N	\N	4	2013-07-30	pm	t	
\N	\N	4	2013-07-31	am	t	
\N	\N	4	2013-07-31	pm	t	
\N	\N	4	2013-08-01	am	t	
\N	\N	4	2013-08-01	pm	t	
\N	\N	4	2013-08-02	am	t	
\N	\N	4	2013-08-02	pm	t	
66	89	4	2013-07-05	am	f	recrutement CDD
66	89	4	2013-07-05	pm	f	recrutement CDD
66	89	4	2013-08-05	am	f	recrutement CDD
66	89	4	2013-08-05	pm	f	recrutement CDD
66	89	4	2013-08-06	am	f	recrutement CDD
66	89	4	2013-08-06	pm	f	recrutement CDD
66	89	4	2013-08-07	am	f	recrutement CDD
66	89	4	2013-08-07	pm	f	recrutement CDD
66	81	4	2013-08-08	am	f	Sprint Agile
55	64	4	2013-08-08	pm	f	reprise N. Apostolakos
55	64	4	2013-08-09	am	f	reprise N. Apostolakos
55	64	4	2013-08-09	pm	f	reprise N. Apostolakos
66	81	4	2013-08-12	am	f	Sprint Agile
55	64	4	2013-08-12	pm	f	reprise N. Apostolakos
55	64	4	2013-08-13	am	f	reprise N. Apostolakos
55	64	4	2013-08-13	pm	f	reprise N. Apostolakos
55	64	4	2013-08-14	am	f	reprise N. Apostolakos
66	89	4	2013-08-14	pm	f	Documents CDDs
\N	\N	4	2013-08-15	am	t	
\N	\N	4	2013-08-15	pm	t	
\N	\N	4	2013-08-16	am	t	
\N	\N	4	2013-08-16	pm	t	
66	65	4	2013-08-19	am	f	preparation Documentation LAM
66	65	4	2013-08-19	pm	f	preparation Documentation LAM
70	98	8	2013-08-14	am	f	
70	98	8	2013-08-14	pm	f	
\N	\N	8	2013-08-15	am	t	
\N	\N	8	2013-08-15	pm	t	
\N	\N	8	2013-08-16	am	t	
\N	\N	8	2013-08-16	pm	t	
59	89	8	2013-08-19	am	f	
59	89	8	2013-08-19	pm	f	
70	98	8	2013-08-20	am	f	
70	98	8	2013-08-20	pm	f	
63	85	5	2013-08-02	am	f	
63	85	5	2013-08-02	pm	f	
63	85	5	2013-08-05	am	f	
63	85	5	2013-08-05	pm	f	
63	85	5	2013-08-06	am	f	
63	85	5	2013-08-06	pm	f	
63	85	5	2013-08-07	am	f	
63	85	5	2013-08-07	pm	f	
63	85	5	2013-08-08	am	f	
63	85	5	2013-08-08	pm	f	
\N	\N	5	2013-08-09	am	t	
\N	\N	5	2013-08-09	pm	t	
\N	\N	5	2013-08-12	am	t	
\N	\N	5	2013-08-12	pm	t	
\N	\N	5	2013-08-13	am	t	
\N	\N	5	2013-08-13	pm	t	
\N	\N	5	2013-08-14	am	t	
\N	\N	5	2013-08-14	pm	t	
\N	\N	5	2013-08-15	am	t	
\N	\N	5	2013-08-15	pm	t	
\N	\N	5	2013-08-16	am	t	
\N	\N	5	2013-08-16	pm	t	
71	89	5	2013-08-19	am	f	
56	89	5	2013-08-19	pm	f	
56	89	5	2013-08-20	am	f	
63	115	5	2013-08-20	pm	f	
63	115	5	2013-08-21	am	f	
63	89	5	2013-08-21	pm	f	
69	85	5	2013-08-22	am	f	
69	85	5	2013-08-22	pm	f	
59	89	5	2013-08-23	am	f	
70	98	8	2013-08-21	am	f	
57	98	8	2013-08-21	pm	f	
67	97	8	2013-08-22	am	f	
70	98	8	2013-08-22	pm	f	
57	97	8	2013-08-23	am	f	
57	98	8	2013-08-23	pm	f	
\N	\N	20	2013-07-29	am	t	
\N	\N	20	2013-07-29	pm	t	
\N	\N	20	2013-07-30	am	t	
\N	\N	20	2013-07-30	pm	t	
\N	\N	20	2013-07-31	am	t	
\N	\N	20	2013-07-31	pm	t	
\N	\N	20	2013-08-01	am	t	
\N	\N	20	2013-08-01	pm	t	
\N	\N	20	2013-08-02	am	t	
\N	\N	20	2013-08-02	pm	t	
\N	\N	20	2013-08-05	am	t	
\N	\N	20	2013-08-05	pm	t	
\N	\N	20	2013-08-06	am	t	
\N	\N	20	2013-08-06	pm	t	
\N	\N	20	2013-08-07	am	t	
\N	\N	20	2013-08-07	pm	t	
\N	\N	20	2013-08-08	am	t	
\N	\N	20	2013-08-08	pm	t	
\N	\N	20	2013-08-09	am	t	
\N	\N	20	2013-08-09	pm	t	
\N	\N	20	2013-08-12	am	t	
\N	\N	20	2013-08-12	pm	t	
\N	\N	20	2013-08-13	am	t	
\N	\N	20	2013-08-13	pm	t	
\N	\N	20	2013-08-14	am	t	
\N	\N	20	2013-08-14	pm	t	
\N	\N	20	2013-08-15	am	t	
\N	\N	20	2013-08-15	pm	t	
\N	\N	20	2013-08-16	am	t	
\N	\N	20	2013-08-16	pm	t	
\N	\N	20	2013-08-19	am	t	
\N	\N	20	2013-08-19	pm	t	
\N	\N	20	2013-08-20	am	t	
\N	\N	20	2013-08-20	pm	t	
\N	\N	20	2013-08-21	am	t	
\N	\N	20	2013-08-21	pm	t	
\N	\N	20	2013-08-22	am	t	
\N	\N	20	2013-08-22	pm	t	
\N	\N	20	2013-08-23	am	t	
\N	\N	20	2013-08-23	pm	t	
\N	\N	19	2013-07-29	am	t	
\N	\N	19	2013-07-29	pm	t	
\N	\N	19	2013-07-30	am	t	
\N	\N	19	2013-07-30	pm	t	
\N	\N	19	2013-07-31	am	t	
\N	\N	19	2013-07-31	pm	t	
\N	\N	19	2013-08-01	am	t	
\N	\N	19	2013-08-01	pm	t	
\N	\N	19	2013-08-02	am	t	
\N	\N	19	2013-08-02	pm	t	
\N	\N	19	2013-08-05	am	t	
\N	\N	19	2013-08-05	pm	t	
\N	\N	19	2013-08-06	am	t	
\N	\N	19	2013-08-06	pm	t	
\N	\N	19	2013-08-07	am	t	
\N	\N	19	2013-08-07	pm	t	
\N	\N	19	2013-08-08	am	t	
\N	\N	19	2013-08-08	pm	t	
\N	\N	19	2013-08-09	am	t	
\N	\N	19	2013-08-09	pm	t	
\N	\N	19	2013-08-12	am	t	
\N	\N	19	2013-08-12	pm	t	
\N	\N	19	2013-08-13	am	t	
\N	\N	19	2013-08-13	pm	t	
\N	\N	19	2013-08-14	am	t	
\N	\N	19	2013-08-14	pm	t	
\N	\N	19	2013-08-15	am	t	
\N	\N	19	2013-08-15	pm	t	
\N	\N	19	2013-08-16	am	t	
\N	\N	19	2013-08-16	pm	t	
\N	\N	19	2013-08-19	am	t	
\N	\N	19	2013-08-19	pm	t	
\N	\N	19	2013-08-20	am	t	
\N	\N	19	2013-08-20	pm	t	
70	89	20	2013-07-17	pm	f	Migration BDD en version 9.2
70	89	20	2013-07-17	am	f	Migration BDD en version 9.2
70	89	20	2013-07-18	pm	f	Migration BDD en version 9.2
70	89	20	2013-07-18	am	f	Migration BDD en version 9.2
70	89	20	2013-07-19	pm	f	Migration BDD en version 9.2
70	89	20	2013-07-19	am	f	Migration BDD en version 9.2
57	131	20	2013-07-22	pm	f	Decoupage d'images par liste
57	131	20	2013-07-22	am	f	Decoupage d'images par liste
57	131	20	2013-07-23	pm	f	Decoupage d'images par liste
57	131	20	2013-07-23	am	f	Decoupage d'images par liste
57	131	20	2013-07-24	pm	f	Decoupage d'images par liste
57	131	20	2013-07-24	am	f	Decoupage d'images par liste
57	131	20	2013-07-25	pm	f	Recherche par nom
57	131	20	2013-07-25	am	f	Recherche par nom
57	131	20	2013-07-26	pm	f	Recherche par nom
57	131	20	2013-07-26	am	f	Recherche par nom
70	89	19	2013-07-17	am	f	Migration PostgreSQL server 9.2
70	89	19	2013-07-17	pm	f	Migration PostgreSQL server 9.2
70	89	19	2013-07-18	am	f	Migration PostgreSQL server 9.2
70	89	19	2013-07-18	pm	f	Migration PostgreSQL server 9.2
70	89	19	2013-07-19	am	f	Migration PostgreSQL server 9.2
70	89	19	2013-07-19	pm	f	Migration PostgreSQL server 9.2
57	67	19	2013-07-22	am	f	Developpement ANIS
57	67	19	2013-07-22	pm	f	Developpement ANIS
57	67	19	2013-07-23	am	f	Developpement ANIS
57	67	19	2013-07-23	pm	f	Developpement ANIS
57	67	19	2013-07-24	am	f	Developpement ANIS
57	67	19	2013-07-24	pm	f	Developpement ANIS
57	67	19	2013-07-25	am	f	Developpement ANIS
57	67	19	2013-07-25	pm	f	Developpement ANIS
57	67	19	2013-07-26	am	f	Developpement ANIS
57	67	19	2013-07-26	pm	f	Developpement ANIS
57	67	19	2013-08-21	am	f	Developpement rendu personnalisé colonne datatables
57	67	19	2013-08-21	pm	f	Developpement rendu personnalisé colonne datatables
57	67	19	2013-08-22	am	f	Developpement rendu personnalisé colonne datatables
57	67	19	2013-08-22	pm	f	Developpement rendu personnalisé colonne datatables
57	67	19	2013-08-23	am	f	Developpement rendu personnalisé colonne datatables
57	67	19	2013-08-23	pm	f	Developpement rendu personnalisé colonne datatables
57	67	19	2013-08-26	am	f	
57	67	19	2013-08-26	pm	f	
57	71	17	2013-08-19	am	f	
57	98	8	2013-09-06	am	f	
57	71	17	2013-08-19	pm	f	Working on new lasco website (w3c compliance).
57	71	17	2013-08-20	am	f	Working on new lasco website (w3c compliance).
57	71	17	2013-08-20	pm	f	Working on new lasco website (w3c compliance).
71	71	17	2013-08-21	am	f	Working on normalization and equalization procedures.
71	71	17	2013-08-21	pm	f	Working on normalization and equalization procedures.
57	71	17	2013-08-22	am	f	Working on normalization and equalization procedures.
57	71	17	2013-08-22	pm	f	Working on normalization and equalization procedures.
57	71	17	2013-08-23	am	f	Working on centralized calls file for the new pipeline.
57	71	17	2013-08-23	pm	f	Working on centralized calls file for the new pipeline.
57	71	17	2013-08-26	am	f	Working on centralized calls file for the new pipeline.
57	71	17	2013-08-26	pm	f	Working on centralized calls file for the new pipeline.
57	71	17	2013-08-27	am	f	Working on normalization and equalization procedures.
57	71	17	2013-08-27	pm	f	Working on normalization and equalization procedures.
70	98	8	2013-08-26	am	f	
57	98	8	2013-08-26	pm	f	
57	98	8	2013-08-27	am	f	
57	98	8	2013-08-27	pm	f	
\N	\N	15	2013-08-15	am	t	
\N	\N	15	2013-08-15	pm	t	
\N	\N	15	2013-08-16	am	t	
\N	\N	15	2013-08-16	pm	t	
\N	\N	15	2013-08-19	am	t	
\N	\N	15	2013-08-19	pm	t	
\N	\N	15	2013-08-20	am	t	
\N	\N	15	2013-08-20	pm	t	
\N	\N	15	2013-08-21	am	t	
\N	\N	15	2013-08-21	pm	t	
\N	\N	15	2013-08-22	am	t	
\N	\N	15	2013-08-22	pm	t	
\N	\N	15	2013-08-23	am	t	
\N	\N	15	2013-08-23	pm	t	
\N	\N	15	2013-08-26	am	t	
73	110	15	2013-08-26	pm	f	bulge project
73	110	15	2013-08-27	am	f	bulge project
55	72	15	2013-08-27	pm	f	point cloud algorithm 
57	98	8	2013-08-28	am	f	
57	98	8	2013-08-28	pm	f	
57	98	8	2013-08-29	am	f	
57	98	8	2013-08-29	pm	f	
63	89	5	2013-08-23	pm	f	
71	89	5	2013-08-26	am	f	
71	89	5	2013-08-26	pm	f	
56	115	5	2013-08-27	am	f	
61	115	5	2013-08-27	pm	f	
55	115	5	2013-08-28	am	f	
63	89	5	2013-08-28	pm	f	
71	89	5	2013-08-29	am	f	
63	89	5	2013-08-29	pm	f	
56	104	5	2013-08-30	am	f	
56	104	5	2013-08-30	pm	f	
71	89	5	2013-09-02	am	f	
61	104	5	2013-09-02	pm	f	
72	110	15	2013-08-28	am	f	bulge
72	110	15	2013-08-28	pm	f	bulge
73	110	15	2013-08-29	am	f	bulge
73	110	15	2013-08-29	pm	f	bulge
57	112	15	2013-08-30	am	f	fitgauss
57	112	15	2013-08-30	pm	f	fitgauss
57	112	15	2013-09-02	am	f	fitgauss
57	112	15	2013-09-02	pm	f	fitgauss
66	89	4	2013-08-27	am	f	preparation dossier CDDs
66	89	4	2013-08-27	pm	f	preparation dossier CDDs
55	81	4	2013-08-28	am	f	ANalysis
55	81	4	2013-08-28	pm	f	ANalysis
60	85	4	2013-08-29	am	f	jury de concours
60	85	4	2013-08-29	pm	f	jury de concours
55	81	4	2013-08-30	am	f	ANalysis
55	81	4	2013-08-30	pm	f	ANalysis
66	89	4	2013-09-02	am	f	preparation demande financement
66	89	4	2013-09-02	pm	f	preparation demande financement
55	81	4	2013-09-03	am	f	UML design
55	81	4	2013-09-03	pm	f	UML design
55	81	4	2013-09-04	am	f	UML design
66	89	4	2013-09-04	pm	f	entretien CDD
66	65	4	2013-09-05	am	f	Prepa reunion EUCLID
66	89	4	2013-09-05	pm	f	entretien CDD
59	125	4	2013-08-20	am	f	préparation Jury
55	81	4	2013-08-20	pm	f	Analysis AGILE
59	125	4	2013-08-21	am	f	préparation Jury
60	125	4	2013-08-21	pm	f	préparation examen G4
60	125	4	2013-08-22	am	f	préparation examen G4
55	81	4	2013-08-22	pm	f	Analysis AGILE
60	125	4	2013-08-23	am	f	préparation examen G4
60	125	4	2013-08-23	pm	f	préparation examen G4
55	81	4	2013-08-26	am	f	Analysis AGILE
55	81	4	2013-08-26	pm	f	Analysis AGILE
57	71	17	2013-08-28	am	f	Working on normalization and equalization procedures.
57	71	17	2013-08-28	pm	f	Working on normalization and equalization procedures.
57	71	17	2013-08-29	am	f	Working on normalization and equalization procedures.
57	71	17	2013-08-29	pm	f	Working on normalization and equalization procedures.
57	71	17	2013-08-30	am	f	Working on normalization and equalization procedures.
67	71	17	2013-08-30	pm	f	
57	71	17	2013-09-02	am	f	Working on new cosmic filtering procedures.
57	71	17	2013-09-02	pm	f	Working on new cosmic filtering procedures.
57	71	17	2013-09-03	am	f	Working on new cosmic filtering procedures.
57	71	17	2013-09-03	pm	f	Working on new cosmic filtering procedures.
70	71	17	2013-09-04	am	f	Running cosmic filtering on all images.
70	71	17	2013-09-04	pm	f	Running cosmic filtering on all images.
70	71	17	2013-09-05	am	f	Running cosmic filtering on all images.
70	71	17	2013-09-05	pm	f	Running cosmic filtering on all images.
70	71	17	2013-09-06	am	f	Running cosmic filtering on all images.
70	71	17	2013-09-06	pm	f	Running cosmic filtering on all images.
55	100	5	2013-09-03	am	f	
55	100	5	2013-09-03	pm	f	
63	66	5	2013-09-04	am	f	
63	66	5	2013-09-04	pm	f	
55	85	5	2013-09-05	am	f	
55	85	5	2013-09-05	pm	f	
71	66	5	2013-09-06	am	f	
71	66	5	2013-09-06	pm	f	
71	66	5	2013-09-09	am	f	
71	66	5	2013-09-09	pm	f	
57	98	8	2013-08-30	am	f	
57	98	8	2013-08-30	pm	f	
57	98	8	2013-09-02	am	f	
57	98	8	2013-09-02	pm	f	
\N	\N	8	2013-09-03	am	t	
\N	\N	8	2013-09-03	pm	t	
\N	\N	8	2013-09-04	am	t	
\N	\N	8	2013-09-04	pm	t	
57	98	8	2013-09-05	am	f	
57	98	8	2013-09-05	pm	f	
57	98	8	2013-09-06	pm	f	
57	98	8	2013-09-09	am	f	
57	98	8	2013-09-09	pm	f	
57	98	8	2013-09-10	am	f	
57	98	8	2013-09-10	pm	f	
55	72	4	2013-09-06	am	f	Analyse des travaux et estimation 
66	89	4	2013-09-06	pm	f	CDDs
66	89	4	2013-09-09	am	f	CDDs
55	81	4	2013-09-09	pm	f	Analysis
66	89	4	2013-09-10	am	f	Status of projects
66	89	4	2013-09-10	pm	f	CDDs
57	131	19	2013-08-27	am	f	Page erreur personnalisable (500 + 404) + fixed bugs
57	131	19	2013-08-27	pm	f	Page erreur personnalisable (500 + 404) + fixed bugs
57	131	19	2013-08-28	am	f	Page erreur personnalisable (500 + 404) + fixed bugs
57	131	19	2013-08-28	pm	f	Page erreur personnalisable (500 + 404) + fixed bugs
57	131	19	2013-08-29	am	f	Page erreur personnalisable (500 + 404) + fixed bugs
57	131	19	2013-08-29	pm	f	Page erreur personnalisable (500 + 404) + fixed bugs
57	131	19	2013-08-30	am	f	Page erreur personnalisable (500 + 404) + fixed bugs
57	131	19	2013-08-30	pm	f	Page erreur personnalisable (500 + 404) + fixed bugs
57	67	19	2013-09-02	am	f	ANIS : Développement export VO + fixed bugs
57	67	19	2013-09-02	pm	f	ANIS : Développement export VO + fixed bugs
57	67	19	2013-09-03	am	f	ANIS : Développement export VO + fixed bugs
57	67	19	2013-09-03	pm	f	ANIS : Développement export VO + fixed bugs
57	67	19	2013-09-04	am	f	ANIS : Développement export VO + fixed bugs
57	67	19	2013-09-04	pm	f	ANIS : Développement export VO + fixed bugs
57	67	19	2013-09-05	am	f	ANIS : Développement export VO + fixed bugs
57	67	19	2013-09-05	pm	f	ANIS : Développement export VO + fixed bugs
57	67	19	2013-09-06	am	f	ANIS : Développement export VO + fixed bugs
57	67	19	2013-09-06	pm	f	ANIS : Développement export VO + fixed bugs
57	89	19	2013-09-09	am	f	Dev SI (FabryPerot...)
57	89	19	2013-09-09	pm	f	Dev SI (FabryPerot...)
59	67	19	2013-09-10	am	f	Préparation slides REVEX 2013
59	67	19	2013-09-10	pm	f	Préparation slides REVEX 2013
59	67	19	2013-09-11	am	f	Préparation slides REVEX 2013
57	89	19	2013-09-11	pm	f	Dev SI (FabryPerot...)
70	102	20	2013-08-26	am	f	Ajout de catalogues d'images
70	102	20	2013-08-26	pm	f	Ajout de catalogues d'images
71	131	20	2013-08-27	am	f	Correction de bugs
71	131	20	2013-08-27	pm	f	Correction de bugs
71	131	20	2013-08-28	am	f	Correction de bugs
71	131	20	2013-08-28	pm	f	Correction de bugs
\N	\N	20	2013-08-29	am	t	
\N	\N	20	2013-08-29	pm	t	
\N	\N	20	2013-08-30	am	t	
\N	\N	20	2013-08-30	pm	t	
57	102	20	2013-09-02	am	f	
57	102	20	2013-09-02	pm	f	
57	102	20	2013-09-03	am	f	
57	102	20	2013-09-03	pm	f	
57	131	20	2013-09-04	am	f	
57	131	20	2013-09-04	pm	f	
57	131	20	2013-09-05	am	f	
57	131	20	2013-09-05	pm	f	
61	131	20	2013-09-06	am	f	
61	131	20	2013-09-06	pm	f	
63	89	20	2013-09-09	am	f	
63	89	20	2013-09-09	pm	f	
63	89	20	2013-09-10	am	f	
63	89	20	2013-09-10	pm	f	
57	136	20	2013-09-11	am	f	
61	136	20	2013-09-11	pm	f	
73	110	15	2013-09-03	am	f	bulge project
73	110	15	2013-09-03	pm	f	bulge project
57	115	15	2013-09-04	am	f	local ETKF
57	115	15	2013-09-04	pm	f	local ETKF
57	72	15	2013-09-05	am	f	surface reconstruction
67	115	15	2013-09-05	pm	f	local ETKF
67	72	15	2013-09-06	am	f	Rosetta
57	72	15	2013-09-06	pm	f	surface reconstruction
73	110	15	2013-09-09	am	f	bulge project
57	72	15	2013-09-09	pm	f	surface reconstruction (interface to PCL)
57	115	15	2013-09-10	am	f	Local ETKF (speed tests)
55	115	15	2013-09-10	pm	f	Local ETKF (speed tests)
55	115	15	2013-09-11	am	f	ETKF speed tests
57	115	15	2013-09-11	pm	f	ETKF speed tests
61	71	23	2013-07-08	pm	f	
61	71	23	2013-07-08	am	f	
61	71	23	2013-07-09	pm	f	
61	71	23	2013-07-09	am	f	
61	71	23	2013-07-10	pm	f	
61	71	23	2013-07-10	am	f	
61	71	23	2013-07-11	pm	f	
61	71	23	2013-07-11	am	f	
61	71	23	2013-07-12	pm	f	
61	71	23	2013-07-12	am	f	
61	71	23	2013-07-15	pm	f	
61	71	23	2013-07-15	am	f	
61	71	23	2013-07-16	pm	f	
61	71	23	2013-07-16	am	f	
61	71	23	2013-07-17	pm	f	
61	71	23	2013-07-17	am	f	
61	71	23	2013-07-18	pm	f	
61	71	23	2013-07-18	am	f	
61	71	23	2013-07-19	pm	f	
61	71	23	2013-07-19	am	f	
61	71	23	2013-07-22	pm	f	
61	71	23	2013-07-22	am	f	
61	71	23	2013-07-23	pm	f	
61	71	23	2013-07-23	am	f	
61	71	23	2013-07-24	pm	f	
61	71	23	2013-07-24	am	f	
61	71	23	2013-07-25	pm	f	
61	71	23	2013-07-25	am	f	
61	71	23	2013-07-26	pm	f	
61	71	23	2013-07-26	am	f	
61	71	23	2013-07-29	pm	f	
61	71	23	2013-07-29	am	f	
61	71	23	2013-07-30	pm	f	
61	71	23	2013-07-30	am	f	
61	71	23	2013-07-31	pm	f	
61	71	23	2013-07-31	am	f	
61	71	23	2013-08-01	pm	f	
61	71	23	2013-08-01	am	f	
61	71	23	2013-08-02	pm	f	
61	71	23	2013-08-02	am	f	
61	71	23	2013-08-05	pm	f	
61	71	23	2013-08-05	am	f	
61	71	23	2013-08-06	pm	f	
61	71	23	2013-08-06	am	f	
61	71	23	2013-08-07	pm	f	
61	71	23	2013-08-07	am	f	
61	71	23	2013-08-08	pm	f	
61	71	23	2013-08-08	am	f	
61	71	23	2013-08-09	pm	f	
61	71	23	2013-08-09	am	f	
61	71	23	2013-08-12	pm	f	
61	71	23	2013-08-12	am	f	
61	71	23	2013-08-13	pm	f	
61	71	23	2013-08-13	am	f	
61	71	23	2013-08-14	pm	f	
61	71	23	2013-08-14	am	f	
61	71	23	2013-08-15	pm	f	
61	71	23	2013-08-15	am	f	
61	71	23	2013-08-16	pm	f	
61	71	23	2013-08-16	am	f	
61	71	23	2013-08-19	pm	f	
61	71	23	2013-08-19	am	f	
61	71	23	2013-08-20	pm	f	
61	71	23	2013-08-20	am	f	
61	71	23	2013-08-21	pm	f	
61	71	23	2013-08-21	am	f	
61	71	23	2013-08-22	pm	f	
61	71	23	2013-08-22	am	f	
61	71	23	2013-08-23	pm	f	
61	71	23	2013-08-23	am	f	
61	71	23	2013-08-26	pm	f	
61	71	23	2013-08-26	am	f	
61	71	23	2013-08-27	pm	f	
61	71	23	2013-08-27	am	f	
61	71	23	2013-08-28	pm	f	
61	71	23	2013-08-28	am	f	
61	71	23	2013-08-29	pm	f	
61	71	23	2013-08-29	am	f	
61	71	23	2013-08-30	pm	f	
61	71	23	2013-08-30	am	f	
61	71	23	2013-09-02	pm	f	
61	71	23	2013-09-02	am	f	
61	71	23	2013-09-03	pm	f	
61	71	23	2013-09-03	am	f	
61	71	23	2013-09-04	pm	f	
61	71	23	2013-09-04	am	f	
61	71	23	2013-09-05	pm	f	
61	71	23	2013-09-05	am	f	
61	71	23	2013-09-06	pm	f	
61	71	23	2013-09-06	am	f	
61	71	23	2013-09-09	pm	f	
61	71	23	2013-09-09	am	f	
61	71	23	2013-09-10	pm	f	
61	71	23	2013-09-10	am	f	
61	71	23	2013-09-11	pm	f	
61	71	23	2013-09-11	am	f	
61	71	23	2013-09-12	pm	f	
61	71	23	2013-09-12	am	f	
57	97	8	2013-09-11	am	f	
57	97	8	2013-09-11	pm	f	
67	85	8	2013-09-12	am	f	Journée du LAM
67	85	8	2013-09-12	pm	f	Journée du LAM
67	97	8	2013-09-13	am	f	
63	98	8	2013-09-13	pm	f	
55	115	15	2013-09-12	am	f	local etkf (flops/speed)
57	115	15	2013-09-12	pm	f	local etkf (flops/speed)
67	115	15	2013-09-13	am	f	compas (job interview + discussing )
55	115	15	2013-09-13	pm	f	local etkf (flops/speed)
67	97	8	2013-09-16	am	f	
71	98	8	2013-09-16	pm	f	
55	115	15	2013-09-16	am	f	writing text for proceding + making tests
67	110	15	2013-09-16	pm	f	bulge project.... discussion with Lia
55	115	15	2013-09-17	pm	f	writing text for proceding + making tests
\N	\N	11	2013-09-11	am	t	
\N	\N	11	2013-09-11	pm	t	
\N	\N	11	2013-09-12	am	t	
\N	\N	11	2013-09-12	pm	t	
58	133	11	2013-09-13	am	f	
58	133	11	2013-09-13	pm	f	
67	133	11	2013-09-16	am	f	SOC meeting #2
67	133	11	2013-09-16	pm	f	SOC meeting #2
67	133	11	2013-09-17	am	f	SOC meeting #2
67	133	11	2013-09-17	pm	f	SOC meeting #2
67	97	8	2013-09-17	am	f	
57	98	8	2013-09-17	pm	f	
57	97	8	2013-09-18	am	f	
57	97	8	2013-09-18	pm	f	
57	97	8	2013-09-19	am	f	
57	97	8	2013-09-19	pm	f	
57	71	17	2013-09-09	pm	f	Working on sandwich missing blocks reconstruction method.
57	71	17	2013-09-10	am	f	Working on sandwich missing blocks reconstruction method.
57	71	17	2013-09-10	pm	f	Working on sandwich missing blocks reconstruction method.
57	71	17	2013-09-11	am	f	Working on sandwich missing blocks reconstruction method.
57	71	17	2013-09-11	pm	f	Working on sandwich missing blocks reconstruction method.
57	71	17	2013-09-12	am	f	Working on sandwich missing blocks reconstruction method.
57	71	17	2013-09-12	pm	f	Working on sandwich missing blocks reconstruction method.
57	71	17	2013-09-13	am	f	Working on sandwich missing blocks reconstruction method.
57	71	17	2013-09-13	pm	f	Working on sandwich missing blocks reconstruction method.
57	71	17	2013-09-16	am	f	Working on polarized missing blocks reconstruction method.
57	71	17	2013-09-16	pm	f	Working on polarized missing blocks reconstruction method.
57	71	17	2013-09-17	am	f	Working on polarized missing blocks reconstruction method.
57	71	17	2013-09-17	pm	f	Working on polarized missing blocks reconstruction method.
57	71	17	2013-09-18	am	f	Working on polarized missing blocks reconstruction method.
57	71	17	2013-09-18	pm	f	Working on polarized missing blocks reconstruction method.
57	71	17	2013-09-19	am	f	Working on polarized missing blocks reconstruction method.
57	71	17	2013-09-19	pm	f	Working on polarized missing blocks reconstruction method.
57	71	17	2013-09-20	am	f	Working on polarized missing blocks reconstruction method.
57	71	17	2013-09-20	pm	f	Working on polarized missing blocks reconstruction method.
59	97	8	2013-09-20	am	f	
59	97	8	2013-09-20	pm	f	
73	110	15	2013-09-17	am	f	bulge project
55	115	15	2013-09-18	am	f	local ETKF
55	115	15	2013-09-18	pm	f	local ETKF
55	112	15	2013-09-19	am	f	emcee + pastis 
67	110	15	2013-09-19	pm	f	bulge project
57	115	15	2013-09-20	am	f	multi local ETKF
55	115	15	2013-09-20	pm	f	proceeding preparation
56	98	8	2013-09-23	am	f	
63	66	5	2013-09-10	am	f	
63	66	5	2013-09-10	pm	f	
63	66	5	2013-09-11	am	f	
63	66	5	2013-09-11	pm	f	
67	85	5	2013-09-12	am	f	
67	85	5	2013-09-12	pm	f	
63	89	5	2013-09-13	am	f	
63	89	5	2013-09-13	pm	f	
63	89	5	2013-09-16	am	f	
63	89	5	2013-09-16	pm	f	
55	65	5	2013-09-17	am	f	
55	65	5	2013-09-17	pm	f	
\N	\N	5	2013-09-18	am	t	
\N	\N	5	2013-09-18	pm	t	
55	65	5	2013-09-19	am	f	
67	65	5	2013-09-19	pm	f	
63	66	5	2013-09-20	am	f	
63	66	5	2013-09-20	pm	f	
70	69	5	2013-09-23	am	f	
55	104	5	2013-09-23	pm	f	
73	110	15	2013-09-23	am	f	bulge project
55	115	15	2013-09-23	pm	f	multi local ETKF (pistons)
67	97	8	2013-09-23	pm	f	
55	115	15	2013-09-24	am	f	architectures
73	115	15	2013-09-24	pm	f	architectures
57	115	15	2013-09-25	am	f	pistons
67	110	15	2013-09-25	pm	f	future chemical
55	110	15	2013-09-26	am	f	bulge
73	110	15	2013-09-26	pm	f	bulge
67	115	15	2013-09-27	pm	f	pistons
67	110	15	2013-09-27	am	f	chemical
73	110	15	2013-09-30	am	f	bulge
72	115	15	2013-09-30	pm	f	discussion with Morgan about local ETKF
73	115	15	2013-10-01	am	f	multi local ETKF
57	115	15	2013-10-01	pm	f	multi Local ETKF
58	133	11	2013-09-23	am	f	
58	133	11	2013-10-01	am	f	
71	64	11	2013-10-01	pm	f	
71	64	11	2013-10-02	am	f	
58	133	11	2013-10-02	pm	f	
58	133	11	2013-10-03	am	f	
67	133	11	2013-10-03	pm	f	
67	89	30	2013-09-02	am	f	Accueil au Laboratoire
67	89	30	2013-09-02	pm	f	Accueil au Laboratoire
67	89	30	2013-09-03	am	f	Acceuil Laboratoire connexion sur poste simon
67	89	30	2013-09-03	pm	f	 Mise en place mail / connexion internet
72	138	30	2013-09-04	am	f	Lecture article de Suzuki et al. 2005
72	138	30	2013-09-04	pm	f	Lecture article de Lee et al. 2010
72	138	30	2013-09-05	am	f	Lecture article de Paris et al 2011
58	138	30	2013-09-05	pm	f	Recherche documentaire: Probabilités, Statistiques et Analyse Multicritères,   Benjamin Rouaud.  
58	138	30	2013-09-06	am	f	Recherche documentaire: Applied Multivariate Statistical Analysis Volfgang Härdle
58	138	30	2013-09-06	pm	f	Recherche documentaire: PCA, Second Edition, Jolliffe, Springer-Verlag  
56	138	30	2013-09-09	am	f	Mise en place de Python et des modules scipy, astropy 
72	138	30	2013-09-09	pm	f	Lecture ESO Ultra-Violet Advanced Data Products I (EUDAP) Data set Zafar, Poppling,Péroux
62	138	30	2013-09-10	am	f	Lecture ESO Ultra-Violet Advanced Data Products (EUDAP) II The ESO UVES advanced data products quasar sample II. Cosmological evolution of the neutral gas  Zafar Péroux  
70	138	30	2013-09-10	pm	f	Récupération EUADP data sample réduit par Zafar
62	138	30	2013-09-11	am	f	Relecture Python Scripting for Computational Science
56	138	30	2013-09-11	pm	f	Mise en place support  Python Scripting for Computational Science (Hans Petter Langtangen)
70	138	30	2013-09-12	am	f	Consultation MétatDonnées (Excel) de EUADP d 
57	138	30	2013-09-12	pm	f	Production d'une BDD EUADP structurée sous python
67	68	30	2013-09-13	am	f	Présentation Ressources informatiques Bruno Millard,  Thomas Fenouillet 
67	138	30	2013-09-13	pm	f	Présentation du sample EUADP par Céline Péroux
58	138	30	2013-09-16	am	f	Lecture de la norme the 3.0 FITS standard (officielle et article AA)  
57	138	30	2013-09-16	pm	f	Lecture de la documentation The pyFITS  Handbook
57	138	30	2013-09-17	am	f	Production d'un module d'import de FITS de l'EUADP sample: FITSIO.py 
57	138	30	2013-09-17	pm	f	Test de performance d'imports FITS de EUADP sample (memory mapped / not memory mapped)
57	138	30	2013-09-18	am	f	Production d'un module d'import FITS par tranche de spectres redshiftés: READPORTS.py
58	138	30	2013-09-18	pm	f	Production d'une BDD EUADP structurée, (EUADP).py: Class Entry
57	138	30	2013-09-19	am	f	Production d'une BDD EUADP structurée, (EUDAP.py): module python Excel
62	138	30	2013-09-19	pm	f	Production d'une BDD EUADP structurée (EUDAP.py): MetaData Pattern matching and regexps
57	138	30	2013-09-20	am	f	Production d'un BDD EUDAP structurée: Log du pattern matching. Comparaison avec la Métatable non structurée
57	138	30	2013-09-20	pm	f	Import et Serialisation python de la BDD EUDAP structurée (EUADP.py): CPickle python module
58	138	30	2013-09-23	am	f	Import et Serialisation python de la BDD EUDAP (EUADP.py): Définition des c hemins d'accès aux données primaires EUDAPPATH.py
57	138	30	2013-09-23	pm	f	Consultation de la BDD (EUADP): Implémentation d'un itérateur sur la class Entry
58	138	30	2013-09-24	am	f	 Lecture de la documentation du module python MatplotLib
57	138	30	2013-09-24	pm	f	Visualisation de la BDD EUDAP structurée: implémentation de Renderers Graphiques  
57	138	30	2013-09-25	am	f	Visualisation de la BDD EUDAP structurée: Classe de base BaseRenderer 
57	138	30	2013-09-25	pm	f	Visualisation de la BDD EUDAP structurée: Classe dérivée ObsRenderer pour visualisation des spectres dans le référentiel du Laboratoire 
57	138	30	2013-09-26	am	f	Visualisation de la BDD EUDAP structurée: Classe dérivée RestRenderer pour visualisation des spectres dans le référentiel redshifté du quasar  
57	138	30	2013-09-26	pm	f	Débogage du Module de visualisation: RENDERERs.py  
57	138	30	2013-09-27	am	f	Script de visualisation rapide de la BDD structurée EUDAP : QUICKSHOW.py
102	138	30	2013-09-27	pm	f	Définition des corrections cosmétiques  EUDAP pour PCA
102	138	30	2013-09-30	am	f	Stratégies d'analyse PCA pour EUDAP; Réunion Céline Péroux, Didier Vibert
69	138	30	2013-09-30	pm	f	Préparation EUADP / PCA: Rebinnage des spectres à la Résolution du Sloan Digital Sky Survey 
69	138	30	2013-10-01	am	f	Rebinnage EUADP / SDSS: Implémentation du module SMOOTHERS.py
69	138	30	2013-10-01	pm	f	Rebinnage EUADP / SDSS: Implémentation de classe GaussianSmoother.py
72	138	30	2013-10-02	am	f	Rebinnage EUADP / SDSS: Développement du Formalisme -  Rebinnage de spectres de quasars dans un régime limité par le bruit de photons
72	138	30	2013-10-02	pm	f	Rebinnage EUADP / SDSS: Développement du Formalisme -  Rebinnage de spectres de quasars dans un régime limité par le bruit de photons
57	138	30	2013-10-03	am	f	Rebinnage EUADP/SDSS: Classe d'Estimateur du rapport Signal à Bruit SNRGlobal.py
57	138	30	2013-10-03	pm	f	Rebinnage EUADP/SDSS: Classe d'Estimateur du rapport Signal à Bruit SNRLocal.py
55	138	30	2013-10-04	am	f	Rebinnage EUADP/SDSS: Nécessité de Flaggage et réjection des outliers 
62	138	30	2013-10-04	pm	f	Documentation du module python Masked arrays: Tableaux masqués / flaggés
57	115	15	2013-10-02	am	f	local ETKF
\N	\N	15	2013-10-02	pm	t	
73	115	15	2013-10-03	am	f	local ETKF
55	115	15	2013-10-03	pm	f	local ETKF
57	115	15	2013-10-04	am	f	local ETKF
73	110	15	2013-10-04	pm	f	bulge
57	138	30	2013-10-07	am	f	Mise en place d'un rapport de log pour le calcul du SNR local
57	131	22	2013-07-30	pm	f	
57	131	22	2013-07-31	pm	f	
57	131	22	2013-07-31	am	f	
\N	\N	22	2013-08-01	pm	t	
\N	\N	22	2013-08-01	am	t	
\N	\N	22	2013-08-02	pm	t	
\N	\N	22	2013-08-02	am	t	
\N	\N	22	2013-08-05	pm	t	
\N	\N	22	2013-08-05	am	t	
\N	\N	22	2013-08-06	pm	t	
\N	\N	22	2013-08-06	am	t	
\N	\N	22	2013-08-07	pm	t	
\N	\N	22	2013-08-07	am	t	
\N	\N	22	2013-08-08	pm	t	
\N	\N	22	2013-08-08	am	t	
\N	\N	22	2013-08-09	pm	t	
\N	\N	22	2013-08-09	am	t	
\N	\N	22	2013-08-12	pm	t	
\N	\N	22	2013-08-12	am	t	
\N	\N	22	2013-08-13	pm	t	
\N	\N	22	2013-08-13	am	t	
\N	\N	22	2013-08-14	pm	t	
\N	\N	22	2013-08-14	am	t	
\N	\N	22	2013-08-15	pm	t	
\N	\N	22	2013-08-15	am	t	
\N	\N	22	2013-08-16	pm	t	
\N	\N	22	2013-08-16	am	t	
\N	\N	22	2013-08-19	pm	t	
\N	\N	22	2013-08-19	am	t	
\N	\N	22	2013-08-20	pm	t	
\N	\N	22	2013-08-20	am	t	
60	89	22	2013-08-21	pm	f	Accueil stagiaire
\N	\N	22	2013-08-21	am	t	
\N	\N	22	2013-08-22	pm	t	
\N	\N	22	2013-08-22	am	t	
\N	\N	22	2013-08-23	pm	t	
\N	\N	22	2013-08-23	am	t	
70	77	22	2013-08-26	pm	f	
70	102	22	2013-08-26	am	f	
57	102	22	2013-08-27	pm	f	
\N	\N	22	2013-08-28	pm	t	
70	102	22	2013-08-29	am	f	
57	77	22	2013-08-30	pm	f	
56	77	22	2013-08-30	am	f	
57	131	22	2013-09-02	pm	f	
57	131	22	2013-09-02	am	f	
57	131	22	2013-09-03	pm	f	
57	131	22	2013-09-03	am	f	
56	131	22	2013-09-04	pm	f	
\N	\N	22	2013-09-04	am	t	
57	77	22	2013-09-05	pm	f	
67	85	22	2013-09-05	am	f	CL
70	77	22	2013-09-06	pm	f	
67	98	22	2013-09-06	am	f	
70	102	22	2013-09-09	pm	f	
70	102	22	2013-09-09	am	f	
67	89	22	2013-09-11	pm	t	Préparation talk CeSAM
67	85	22	2013-09-12	pm	f	Journée du LAM
67	85	22	2013-09-12	am	f	Journée du LAM
63	131	22	2013-09-13	pm	f	
63	131	22	2013-09-13	am	f	
57	69	22	2013-09-16	pm	f	
57	69	22	2013-09-16	am	f	
56	69	22	2013-09-17	pm	f	
56	69	22	2013-09-17	am	f	
\N	\N	22	2013-09-18	am	t	
70	102	22	2013-09-19	pm	f	
70	102	22	2013-09-19	am	f	
70	102	22	2013-09-20	pm	f	
70	102	22	2013-09-20	am	f	
70	102	22	2013-09-24	pm	f	
70	102	22	2013-09-25	pm	f	
\N	\N	22	2013-09-25	am	t	
\N	\N	22	2013-09-26	pm	t	
\N	\N	22	2013-09-26	am	t	
59	89	22	2013-10-07	am	f	
57	138	30	2013-10-07	pm	f	Hiérarchie de Classes de Flag spectre/bruit EUADP (module FLAGGER.py)  ThresholdFlagger 
70	98	22	2013-10-07	pm	f	DR2
57	102	22	2013-10-08	pm	f	
70	98	22	2013-10-08	am	f	DR2
57	102	22	2013-10-09	pm	f	
\N	\N	22	2013-10-09	am	t	
70	98	22	2013-10-10	pm	f	DR2
58	89	22	2013-10-10	am	f	proceeding ADASS
70	98	22	2013-10-11	pm	f	DR2
70	98	22	2013-10-11	am	f	DR2
67	89	22	2013-09-27	pm	f	
67	89	22	2013-09-27	am	f	ADASS XXIII
67	89	22	2013-09-30	pm	f	ADASS XXIII
67	89	22	2013-09-30	am	f	ADASS XXIII
67	89	22	2013-10-01	pm	f	ADASS XXIII
67	89	22	2013-10-01	am	f	ADASS XXIII
67	89	22	2013-10-02	pm	f	ADASS XXIII
67	89	22	2013-10-02	am	f	ADASS XXIII
67	89	22	2013-10-03	pm	f	ADASS XXIII
67	89	22	2013-10-03	am	f	ADASS XXIII
67	89	22	2013-10-04	pm	f	ADASS XXIII
67	89	22	2013-10-04	am	f	ADASS XXIII
57	71	17	2013-09-09	am	f	
57	71	17	2013-09-23	am	f	
57	71	17	2013-09-23	pm	f	
57	71	17	2013-09-24	am	f	
57	71	17	2013-09-24	pm	f	
57	71	17	2013-09-25	am	f	
57	71	17	2013-09-25	pm	f	
57	71	17	2013-09-26	am	f	
57	71	17	2013-09-26	pm	f	
57	71	17	2013-09-27	am	f	
57	71	17	2013-09-27	pm	f	
70	71	17	2013-09-30	am	f	
70	71	17	2013-09-30	pm	f	
70	71	17	2013-10-01	am	f	
70	71	17	2013-10-01	pm	f	
57	71	17	2013-10-02	am	f	
57	71	17	2013-10-02	pm	f	
57	71	17	2013-10-03	am	f	
57	71	17	2013-10-03	pm	f	
57	71	17	2013-10-04	am	f	
57	71	17	2013-10-04	pm	f	
57	71	17	2013-10-07	am	f	
57	71	17	2013-10-07	pm	f	
57	71	17	2013-10-08	am	f	
57	71	17	2013-10-08	pm	f	
71	71	17	2013-10-09	am	f	
71	71	17	2013-10-09	pm	f	
71	71	17	2013-10-10	am	f	
71	71	17	2013-10-10	pm	f	
71	71	17	2013-10-11	am	f	
71	71	17	2013-10-11	pm	f	
57	71	17	2013-10-14	am	f	
57	71	17	2013-10-14	pm	f	
67	92	31	2013-10-18	am	f	
57	115	15	2013-10-07	am	f	local ETKF
57	115	15	2013-10-07	pm	f	local ETKF
57	115	15	2013-10-08	am	f	local ETKF
57	115	15	2013-10-08	pm	f	local ETKF
57	110	15	2013-10-09	am	f	chemestry
\N	\N	15	2013-10-09	pm	t	
\N	\N	15	2013-10-10	am	t	
\N	\N	15	2013-10-10	pm	t	
58	89	22	2013-08-28	am	f	Abstract ANIS
58	89	22	2013-09-10	pm	f	Préparation talk CeSAM
58	89	22	2013-09-10	am	f	Préparation talk CeSAM
58	89	22	2013-09-11	am	f	Préparation talk CeSAM
58	89	22	2013-09-18	pm	f	Poster ADASS & proceeding
58	89	22	2013-09-23	pm	f	Poster ADASS & proceeding
58	89	22	2013-09-23	am	f	Poster ADASS & proceeding
58	89	22	2013-09-24	am	f	Poster ADASS & proceeding
\N	\N	15	2013-10-11	am	t	
\N	\N	15	2013-10-11	pm	t	
\N	\N	15	2013-10-14	am	t	
57	110	15	2013-10-14	pm	f	chemestry
57	110	15	2013-10-15	am	f	chemestry
57	110	15	2013-10-15	pm	f	chemestry
57	110	15	2013-10-16	am	f	chemestry
57	110	15	2013-10-16	pm	f	chemestry
57	110	15	2013-10-17	am	f	chemestry
57	110	15	2013-10-17	pm	f	chemestry
57	110	15	2013-10-18	am	f	chemestry
57	110	15	2013-10-18	pm	f	chemestry
57	97	8	2013-09-24	am	f	
56	98	8	2013-09-24	pm	f	
\N	\N	8	2013-09-25	am	t	
\N	\N	8	2013-09-25	pm	t	
67	85	8	2013-09-26	am	f	
67	85	8	2013-09-26	pm	f	
67	85	8	2013-09-27	am	f	
67	85	8	2013-09-27	pm	f	
67	85	8	2013-09-30	am	f	
67	85	8	2013-09-30	pm	f	
\N	\N	5	2013-09-27	am	t	
\N	\N	5	2013-09-27	pm	t	
\N	\N	5	2013-09-30	am	t	
\N	\N	5	2013-09-30	pm	t	
\N	\N	5	2013-10-01	am	t	
\N	\N	5	2013-10-01	pm	t	
\N	\N	5	2013-10-02	am	t	
\N	\N	5	2013-10-02	pm	t	
\N	\N	5	2013-10-03	am	t	
\N	\N	5	2013-10-03	pm	t	
\N	\N	5	2013-10-04	am	t	
\N	\N	5	2013-10-04	pm	t	
56	66	5	2013-09-24	am	f	EZ
56	66	5	2013-09-24	pm	f	EZ
56	66	5	2013-09-25	am	f	EZ
56	66	5	2013-09-25	pm	f	EZ
56	66	5	2013-09-26	am	f	EZ
56	66	5	2013-09-26	pm	f	EZ
55	83	5	2013-10-07	am	f	
55	83	5	2013-10-07	pm	f	
55	83	5	2013-10-08	am	f	
67	90	5	2013-10-08	pm	f	
67	90	5	2013-10-09	am	f	
67	90	5	2013-10-09	pm	f	
55	69	5	2013-10-10	am	f	
69	69	5	2013-10-10	pm	f	
71	89	5	2013-10-11	am	f	
71	89	5	2013-10-11	pm	f	
59	89	5	2013-10-14	am	f	
59	89	5	2013-10-14	pm	f	
63	89	5	2013-10-15	am	f	
63	89	5	2013-10-15	pm	f	
67	90	5	2013-10-16	am	f	
67	90	5	2013-10-16	pm	f	
55	89	5	2013-10-17	am	f	
55	89	5	2013-10-17	pm	f	
63	89	5	2013-10-18	am	f	
63	89	5	2013-10-18	pm	f	
63	89	5	2013-10-21	am	f	
63	89	5	2013-10-21	pm	f	
56	89	5	2013-10-22	am	f	EZ
56	89	5	2013-10-22	pm	f	EZ
55	85	5	2013-10-23	am	f	
55	85	5	2013-10-23	pm	f	
69	89	5	2013-10-24	am	f	
63	89	5	2013-10-24	pm	f	
71	89	5	2013-10-25	am	f	
67	115	15	2013-10-21	am	f	COMPAS
73	110	15	2013-10-21	pm	f	untop chemistry
73	110	15	2013-10-22	am	f	untop chemistry
57	110	15	2013-10-22	pm	f	untop chemistry
73	110	15	2013-10-23	am	f	untop chemistry
57	110	15	2013-10-23	pm	f	untop chemistry
57	110	15	2013-10-24	am	f	untop chemistry
57	110	15	2013-10-24	pm	f	untop chemistry
57	110	15	2013-10-25	am	f	untop chemistry
67	115	15	2013-10-25	pm	f	COMPAS
55	85	5	2013-10-25	pm	f	
63	89	5	2013-10-28	am	f	
63	89	5	2013-10-28	pm	f	
67	110	15	2013-10-28	am	f	discussion with Lia about chemistry project + bulge project
57	110	15	2013-10-28	pm	f	chemistry
57	110	15	2013-10-29	am	f	chemistry
67	115	15	2013-10-29	pm	f	local ETKF (reunion + discussion)
72	110	15	2013-10-30	am	f	bar project
72	110	15	2013-10-30	pm	f	bar project
55	110	15	2013-10-31	am	f	bar project
73	110	15	2013-10-31	pm	f	bar project
57	102	20	2013-09-12	am	f	
57	102	20	2013-09-12	pm	f	
57	102	20	2013-09-13	am	f	
57	102	20	2013-09-13	pm	f	
57	102	20	2013-09-16	am	f	
57	102	20	2013-09-16	pm	f	
57	102	20	2013-09-17	am	f	
57	102	20	2013-09-17	pm	f	
57	102	20	2013-09-18	am	f	
57	102	20	2013-09-18	pm	f	
57	102	20	2013-09-19	am	f	
57	102	20	2013-09-19	pm	f	
57	102	20	2013-09-20	am	f	
57	102	20	2013-09-20	pm	f	
67	89	20	2013-09-23	am	f	Préparation poster ADASS
67	89	20	2013-09-23	pm	f	Préparation poster ADASS
67	89	20	2013-09-24	am	f	Préparation poster ADASS
67	89	20	2013-09-24	pm	f	Préparation poster ADASS
\N	\N	20	2013-09-25	am	t	
\N	\N	20	2013-09-25	pm	t	
\N	\N	20	2013-09-26	am	t	
\N	\N	20	2013-09-26	pm	t	
67	89	20	2013-09-27	am	f	ADASS
67	89	20	2013-09-27	pm	f	ADASS
67	89	20	2013-09-30	am	f	ADASS
67	89	20	2013-09-30	pm	f	ADASS
67	89	20	2013-10-01	am	f	ADASS
67	89	20	2013-10-01	pm	f	ADASS
67	89	20	2013-10-02	am	f	ADASS
67	89	20	2013-10-02	pm	f	ADASS
67	89	20	2013-10-03	am	f	ADASS
67	89	20	2013-10-03	pm	f	ADASS
67	89	20	2013-10-04	am	f	ADASS
67	89	20	2013-10-04	pm	f	ADASS
\N	\N	20	2013-10-07	am	t	
\N	\N	20	2013-10-07	pm	t	
\N	\N	20	2013-10-08	am	t	
\N	\N	20	2013-10-08	pm	t	
\N	\N	20	2013-10-09	am	t	
\N	\N	20	2013-10-09	pm	t	
59	89	20	2013-10-10	am	f	Dossier Concours
59	89	20	2013-10-10	pm	f	Dossier Concours
\N	\N	20	2013-10-11	am	t	
\N	\N	20	2013-10-11	pm	t	
57	102	20	2013-10-14	am	f	
57	102	20	2013-10-14	pm	f	
57	102	20	2013-10-15	am	f	
57	102	20	2013-10-15	pm	f	
57	102	20	2013-10-16	am	f	
57	102	20	2013-10-16	pm	f	
57	102	20	2013-10-17	am	f	
57	102	20	2013-10-17	pm	f	
57	102	20	2013-10-18	am	f	
57	102	20	2013-10-18	pm	f	
\N	\N	20	2013-10-21	am	t	
\N	\N	20	2013-10-21	pm	t	
\N	\N	20	2013-10-22	am	t	
\N	\N	20	2013-10-22	pm	t	
\N	\N	20	2013-10-23	am	t	
\N	\N	20	2013-10-23	pm	t	
\N	\N	20	2013-10-24	am	t	
\N	\N	20	2013-10-24	pm	t	
\N	\N	20	2013-10-25	am	t	
\N	\N	20	2013-10-25	pm	t	
57	66	20	2013-10-28	am	f	Preparation migration du SI XMMLSS
57	66	20	2013-10-28	pm	f	Preparation migration du SI XMMLSS
57	66	20	2013-10-29	am	f	Preparation migration du SI XMMLSS
57	66	20	2013-10-29	pm	f	Preparation migration du SI XMMLSS
57	66	20	2013-10-30	am	f	Preparation migration du SI XMMLSS
57	66	20	2013-10-30	pm	f	Preparation migration du SI XMMLSS
57	66	20	2013-10-31	am	f	Preparation migration du SI XMMLSS
57	66	20	2013-10-31	pm	f	Preparation migration du SI XMMLSS
\N	\N	20	2013-11-01	am	t	
\N	\N	20	2013-11-01	pm	t	
57	102	20	2013-11-04	am	f	
57	102	20	2013-11-04	pm	f	
73	110	15	2013-11-01	am	f	bulge
73	110	15	2013-11-01	pm	f	bulge
73	110	15	2013-11-04	am	f	bulge
73	110	15	2013-11-04	pm	f	bulge
\N	\N	4	2013-10-21	am	t	
\N	\N	4	2013-10-21	pm	t	
67	96	4	2013-10-22	am	f	telecon 
\N	\N	4	2013-10-22	pm	t	
67	85	4	2013-10-23	am	f	CS Pytheas
\N	\N	4	2013-10-23	pm	t	
\N	\N	4	2013-10-24	am	t	
\N	\N	4	2013-10-24	pm	t	
\N	\N	4	2013-10-25	am	t	
\N	\N	4	2013-10-25	pm	t	
67	81	4	2013-10-28	am	f	OUSPE
67	81	4	2013-10-28	pm	f	OUSPE
67	81	4	2013-10-29	am	f	OUSPE
67	81	4	2013-10-29	pm	f	OUSPE
67	81	4	2013-10-30	am	f	OUSPE
67	81	4	2013-10-30	pm	f	OUSPE
67	81	4	2013-10-31	am	f	OUSPE sprint 0
67	81	4	2013-10-31	pm	f	OUSPE sprint 0
\N	\N	4	2013-11-01	am	t	
\N	\N	4	2013-11-01	pm	t	
66	89	4	2013-11-04	am	f	accueil CDDs
66	89	4	2013-11-04	pm	f	accueil  ACCESUD
66	133	4	2013-11-05	am	f	preparation anpower
66	89	4	2013-11-05	pm	f	
55	105	4	2013-10-07	am	f	controle commande
55	105	4	2013-10-07	pm	f	controle commande
55	81	4	2013-10-08	am	f	UML
55	81	4	2013-10-08	pm	f	UML
67	65	4	2013-10-09	am	f	Garage days
67	65	4	2013-10-09	pm	f	Garage days
67	65	4	2013-10-10	am	f	Garage days
67	65	4	2013-10-10	pm	f	Garage days
67	65	4	2013-10-11	am	f	Garage days
67	65	4	2013-10-11	pm	f	Garage days
55	105	4	2013-10-14	am	f	DRP
55	81	4	2013-10-14	pm	f	UML
55	105	4	2013-10-15	am	f	controle commande
55	105	4	2013-10-15	pm	f	controle commande
55	65	4	2013-10-16	am	f	AGILE 
55	65	4	2013-10-16	pm	f	AGILE 
67	85	4	2013-10-17	am	f	reunion clacul OTEMED
66	85	4	2013-10-17	pm	f	circulaire campagne emploi
55	81	4	2013-10-18	am	f	UML
55	81	4	2013-10-18	pm	f	UML
67	81	4	2013-09-30	am	f	preparation sprint
67	81	4	2013-09-30	pm	f	preparation sprint
66	89	4	2013-10-01	am	f	accueil CDDs
66	89	4	2013-10-01	pm	f	accueil CDDs
55	81	4	2013-10-02	am	f	redshift measurement
55	81	4	2013-10-02	pm	f	redshift measurement
66	85	4	2013-10-03	am	f	reunion CPCS
55	81	4	2013-10-03	pm	f	redshift measurement
55	81	4	2013-10-04	am	f	redshift measurement
55	81	4	2013-10-04	pm	f	redshift measurement
55	134	4	2013-09-11	am	f	preparation reunion CNES
55	81	4	2013-09-11	pm	f	Z measurement
59	85	4	2013-09-12	am	f	journée du LAM
59	85	4	2013-09-12	pm	f	journée du LAM
55	81	4	2013-09-13	am	f	Z measurement
55	81	4	2013-09-13	pm	f	Z measurement
55	133	4	2013-09-16	am	f	preparation meeting
55	133	4	2013-09-16	pm	f	preparation meeting
55	133	4	2013-09-17	am	f	preparation meeting
55	89	4	2013-09-17	pm	f	reunion stockage
55	133	4	2013-09-18	am	f	preparation meeting
55	133	4	2013-09-18	pm	f	preparation meeting
55	81	4	2013-09-19	am	f	Z measurement
55	81	4	2013-09-19	pm	f	Z measurement
55	81	4	2013-09-20	am	f	Z measurement
55	81	4	2013-09-20	pm	f	Z measurement
55	81	4	2013-09-23	am	f	Z measurement
55	67	4	2013-09-23	pm	f	etude des evolutions
55	67	4	2013-09-24	am	f	etude des evolutions
55	81	4	2013-09-24	pm	f	Z measurement
55	67	4	2013-09-25	am	f	etude des evolutions
55	81	4	2013-09-25	pm	f	Z measurement
59	84	4	2013-09-26	am	f	dossier de carriere concours
59	84	4	2013-09-26	pm	f	dossier de carriere concours
59	84	4	2013-09-27	am	f	dossier de carriere concours
59	84	4	2013-09-27	pm	f	dossier de carriere concours
57	67	19	2013-09-12	am	f	Developpement ExoDat
57	67	19	2013-09-12	pm	f	Developpement ExoDat
57	67	19	2013-09-13	am	f	Developpement ExoDat
57	67	19	2013-09-13	pm	f	Developpement ExoDat
57	67	19	2013-09-16	am	f	Developpement ExoDat
57	67	19	2013-09-16	pm	f	Developpement ExoDat
57	67	19	2013-09-17	am	f	Developpement ExoDat
57	67	19	2013-09-17	pm	f	Developpement ExoDat
57	67	19	2013-09-18	am	f	Developpement ExoDat
57	67	19	2013-09-18	pm	f	Developpement ExoDat
57	67	19	2013-09-19	am	f	Developpement ExoDat
57	67	19	2013-09-19	pm	f	Developpement ExoDat
67	89	19	2013-09-20	am	f	Preparation du poster ADASS XXIII
67	89	19	2013-09-20	pm	f	Preparation du poster ADASS XXIII
67	67	19	2013-09-23	am	f	Reunion avancement ExoDat
67	89	19	2013-09-23	pm	f	Preparation du poster ADASS XXIII
67	89	19	2013-09-24	am	f	Preparation du poster ADASS XXIII
67	89	19	2013-09-24	pm	f	Preparation du poster ADASS XXIII
\N	\N	19	2013-09-25	am	t	
\N	\N	19	2013-09-25	pm	t	
67	89	19	2013-09-26	am	f	ADASS XXIII
67	89	19	2013-09-26	pm	f	ADASS XXIII
67	89	19	2013-09-27	am	f	ADASS XXIII
67	89	19	2013-09-27	pm	f	ADASS XXIII
67	89	19	2013-09-30	am	f	ADASS XXIII
67	89	19	2013-09-30	pm	f	ADASS XXIII
67	89	19	2013-10-01	am	f	ADASS XXIII
67	89	19	2013-10-01	pm	f	ADASS XXIII
67	89	19	2013-10-02	am	f	ADASS XXIII
67	89	19	2013-10-02	pm	f	ADASS XXIII
67	89	19	2013-10-03	am	f	ADASS XXIII
67	89	19	2013-10-03	pm	f	ADASS XXIII
67	89	19	2013-10-04	am	f	ADASS XXIII
67	89	19	2013-10-04	pm	f	ADASS XXIII
\N	\N	19	2013-10-07	am	t	
\N	\N	19	2013-10-07	pm	t	
\N	\N	19	2013-10-08	am	t	
\N	\N	19	2013-10-08	pm	t	
\N	\N	19	2013-10-09	am	t	
\N	\N	19	2013-10-09	pm	t	
59	89	19	2013-10-10	am	f	Dossier concours
59	89	19	2013-10-10	pm	f	Dossier concours
\N	\N	19	2013-10-11	am	t	
\N	\N	19	2013-10-11	pm	t	
57	67	19	2013-10-14	am	f	Developpement ExoDat
57	67	19	2013-10-14	pm	f	Developpement ExoDat
57	67	19	2013-10-15	am	f	Fixed bug Frédéric Baudin
57	67	19	2013-10-15	pm	f	Fixed bug Frédéric Baudin
57	67	19	2013-10-16	am	f	Developpement ExoDat
57	67	19	2013-10-16	pm	f	Developpement ExoDat
57	67	19	2013-10-17	am	f	Fixed bug PipelineN2 webservice + corotid 500005483 manquante
57	67	19	2013-10-17	pm	f	Fixed bug PipelineN2 webservice + corotid 500005483 manquante
57	67	19	2013-10-18	am	f	Fixed bug PipelineN2 webservice + corotid 500005483 manquante
57	67	19	2013-10-18	pm	f	Fixed bug PipelineN2 webservice + corotid 500005483 manquante
70	67	19	2013-10-21	am	f	Page de synthese (Planetes + spectres) + page synthese runs
70	67	19	2013-10-21	pm	f	Page de synthese (Planetes + spectres) + page synthese runs
70	67	19	2013-10-22	am	f	Page de synthese (Planetes + spectres) + page synthese runs
70	67	19	2013-10-22	pm	f	Page de synthese (Planetes + spectres) + page synthese runs
57	67	19	2013-10-23	am	f	Page de synthese (Planetes + spectres) + page synthese runs
57	67	19	2013-10-23	pm	f	Page de synthese (Planetes + spectres) + page synthese runs
57	67	19	2013-10-24	am	f	Page de synthese (Planetes + spectres) + page synthese runs
57	67	19	2013-10-24	pm	f	Page de synthese (Planetes + spectres) + page synthese runs
57	67	19	2013-10-25	am	f	Page de synthese (Planetes + spectres) + page synthese runs
57	67	19	2013-10-25	pm	f	Page de synthese (Planetes + spectres) + page synthese runs
57	67	19	2013-10-28	am	f	Page de synthese (Planetes + spectres) + page synthese runs
57	67	19	2013-10-28	pm	f	Page de synthese (Planetes + spectres) + page synthese runs
57	67	19	2013-10-29	am	f	Page de synthese (Planetes + spectres) + page synthese runs
57	67	19	2013-10-29	pm	f	Page de synthese (Planetes + spectres) + page synthese runs
57	67	19	2013-10-30	am	f	Page de synthese (Planetes + spectres) + page synthese runs
57	67	19	2013-10-30	pm	f	Page de synthese (Planetes + spectres) + page synthese runs
57	67	19	2013-10-31	am	f	Page de synthese (Planetes + spectres) + page synthese runs
57	67	19	2013-10-31	pm	f	Page de synthese (Planetes + spectres) + page synthese runs
\N	\N	19	2013-11-01	am	t	
\N	\N	19	2013-11-01	pm	t	
\N	\N	19	2013-11-04	am	t	
\N	\N	19	2013-11-04	pm	t	
\N	\N	19	2013-11-05	am	t	
\N	\N	19	2013-11-05	pm	t	
57	131	19	2013-11-06	am	f	Developpement filtres individuels
57	131	19	2013-11-06	pm	f	Developpement filtres individuels
57	92	31	2013-11-07	am	f	
57	92	31	2013-11-07	pm	f	
70	71	17	2013-11-07	am	f	Extracting & sorting Gabon eclipse data
70	71	17	2013-11-07	pm	f	Extracting & sorting Gabon eclipse data
70	71	17	2013-11-08	am	f	Sorting Gabon Eclipse data
69	85	5	2013-10-29	am	f	
69	85	5	2013-10-29	pm	f	
69	85	5	2013-10-30	am	f	
69	85	5	2013-10-30	pm	f	
69	85	5	2013-10-31	am	f	
69	85	5	2013-10-31	pm	f	
\N	\N	5	2013-11-01	am	t	
\N	\N	5	2013-11-01	pm	t	
71	85	5	2013-11-04	am	f	
71	85	5	2013-11-04	pm	f	
69	85	5	2013-11-05	am	f	
69	85	5	2013-11-05	pm	f	
69	85	5	2013-11-06	am	f	
69	85	5	2013-11-06	pm	f	
69	85	5	2013-11-07	am	f	
69	85	5	2013-11-07	pm	f	
\N	\N	5	2013-11-11	am	t	
\N	\N	5	2013-11-11	pm	t	
55	85	4	2013-11-06	am	f	demande Lise de Harveng Python
55	85	4	2013-11-06	pm	f	demande Lise de Harveng Python
55	85	4	2013-11-07	am	f	demande Lise de Harveng Python
55	65	4	2013-11-07	pm	f	
55	85	4	2013-11-08	am	f	demande Lise de Harveng Python
55	85	4	2013-11-08	pm	f	demande Lise de Harveng Python
\N	\N	4	2013-11-11	am	t	
\N	\N	4	2013-11-11	pm	t	
67	65	4	2013-11-12	am	f	Organisation Group meeting (Telecon)
67	65	4	2013-11-12	pm	f	Organisation Group meeting (Telecon)
\N	\N	15	2013-11-05	am	t	
\N	\N	15	2013-11-05	pm	t	
\N	\N	15	2013-11-06	am	t	
\N	\N	15	2013-11-06	pm	t	
\N	\N	15	2013-11-07	am	t	
\N	\N	15	2013-11-07	pm	t	
\N	\N	15	2013-11-08	am	t	
\N	\N	15	2013-11-08	pm	t	
\N	\N	15	2013-11-11	am	t	
\N	\N	15	2013-11-11	pm	t	
\N	\N	15	2013-11-12	am	t	
\N	\N	15	2013-11-12	pm	t	
67	110	15	2013-11-13	am	f	discussion with Lia (bulge + chemical projects)
67	115	15	2013-11-13	pm	f	discussion with morgan (local ETKF)
72	110	15	2013-11-14	am	f	thinking about new article (bulge project)
72	110	15	2013-11-14	pm	f	thinking about new article (bulge project)
58	89	22	2013-08-27	am	f	Abstract Data
58	89	22	2013-08-29	pm	f	Abstract ANIS & DATA
\N	\N	22	2013-10-28	pm	t	
70	102	22	2013-10-28	am	f	
\N	\N	22	2013-10-29	pm	t	
70	102	22	2013-10-29	am	f	
70	102	22	2013-10-30	pm	f	
\N	\N	22	2013-10-30	am	t	
\N	\N	22	2013-10-31	pm	t	
70	102	22	2013-10-31	am	f	
\N	\N	22	2013-11-01	pm	t	
\N	\N	22	2013-11-01	am	t	
57	102	22	2013-11-04	pm	f	
57	102	22	2013-11-04	am	f	
57	102	22	2013-11-05	pm	f	
57	102	22	2013-11-05	am	f	
57	102	22	2013-11-06	pm	f	
\N	\N	22	2013-11-06	am	t	
56	102	22	2013-11-07	pm	f	
56	102	22	2013-11-07	am	f	
\N	\N	22	2013-11-08	pm	t	
70	102	22	2013-11-08	am	f	
\N	\N	22	2013-11-11	pm	t	
\N	\N	22	2013-11-11	am	t	
70	102	22	2013-11-12	pm	f	
70	102	22	2013-11-12	am	f	
\N	\N	22	2013-11-13	am	t	
\N	\N	22	2013-11-14	pm	t	
\N	\N	22	2013-11-14	am	t	
56	102	22	2013-11-15	am	f	
\N	\N	22	2013-10-16	am	t	
69	102	22	2013-10-21	pm	f	ANIS
69	102	22	2013-10-21	am	f	ANIS
69	102	22	2013-10-22	pm	f	ANIS
69	102	22	2013-10-22	am	f	ANIS
69	102	22	2013-10-23	pm	f	ANIS
\N	\N	22	2013-10-23	am	t	
69	102	22	2013-10-24	pm	f	ANIS
69	102	22	2013-10-24	am	f	ANIS
69	102	22	2013-10-25	pm	f	ANIS
69	102	22	2013-10-25	am	f	ANIS
67	89	22	2013-11-13	pm	f	
58	89	22	2013-11-15	pm	f	
69	85	5	2013-11-08	am	f	
63	85	5	2013-11-08	pm	f	
63	85	5	2013-11-12	am	f	
63	85	5	2013-11-12	pm	f	
63	85	5	2013-11-13	am	f	
63	85	5	2013-11-13	pm	f	
63	85	5	2013-11-14	am	f	
63	85	5	2013-11-14	pm	f	
63	85	5	2013-11-15	am	f	
63	85	5	2013-11-15	pm	f	
56	89	5	2013-11-18	am	f	
63	89	5	2013-11-18	pm	f	
67	126	4	2013-11-13	am	f	new generation of videos
67	84	4	2013-11-13	pm	f	PREDON - MASTODONS
67	84	4	2013-11-14	am	f	PREDON - MASTODONS
67	84	4	2013-11-14	pm	f	PREDON - MASTODONS
67	84	4	2013-11-15	am	f	PREDON - MASTODONS
66	89	4	2013-11-15	pm	f	Meeting N. Morin
55	81	4	2013-11-18	am	f	meeting agile
55	81	4	2013-11-18	pm	f	redshift
66	89	4	2013-11-19	am	f	CDDs
66	89	4	2013-11-19	pm	f	CDDs
67	92	31	2013-11-13	am	f	
67	92	31	2013-11-13	pm	f	
67	92	31	2013-11-14	am	f	
67	92	31	2013-11-14	pm	f	
57	92	31	2013-11-15	pm	f	
57	92	31	2013-11-18	pm	f	
57	92	31	2013-11-19	am	f	
57	92	31	2013-11-19	pm	f	
58	89	22	2013-10-14	pm	f	proceeding ADASS
58	89	22	2013-10-14	am	f	proceeding ADASS
58	89	22	2013-10-15	pm	f	proceeding ADASS
58	89	22	2013-10-15	am	f	proceeding ADASS
57	132	22	2013-10-16	pm	f	
57	132	22	2013-10-17	pm	f	
57	66	22	2013-10-17	am	f	
57	66	22	2013-10-18	pm	f	
57	66	22	2013-10-18	am	f	
59	89	22	2013-11-18	pm	f	demenagement
59	89	22	2013-11-18	am	f	demenagement
70	102	22	2013-11-19	pm	f	
70	102	22	2013-11-19	am	f	
\N	\N	22	2013-11-20	pm	t	
\N	\N	22	2013-11-20	am	t	
62	125	22	2013-11-21	pm	f	Formation jury EPR
58	131	22	2013-11-21	am	f	
56	131	22	2013-11-22	pm	f	
57	131	22	2013-11-22	am	f	
71	89	5	2013-11-19	am	f	
71	89	5	2013-11-19	pm	f	
69	100	5	2013-11-20	am	f	
69	100	5	2013-11-20	pm	f	
\N	\N	5	2013-11-21	am	t	
\N	\N	5	2013-11-21	pm	t	
63	85	5	2013-11-22	am	f	
63	85	5	2013-11-22	pm	f	
71	89	5	2013-11-25	am	f	
71	89	5	2013-11-25	pm	f	
73	110	15	2013-11-15	am	f	bulge
73	110	15	2013-11-15	pm	f	bulge
57	115	15	2013-11-18	am	f	local ETKF
57	115	15	2013-11-18	pm	f	local ETKF
57	115	15	2013-11-19	am	f	local ETKF
57	115	15	2013-11-19	pm	f	local ETKF
57	115	15	2013-11-20	am	f	local ETKF
59	85	15	2013-11-20	pm	f	medical examination
57	115	15	2013-11-21	am	f	local ETKF
73	110	15	2013-11-21	pm	f	bulge
57	115	15	2013-11-22	am	f	local ETKF
57	115	15	2013-11-22	pm	f	local ETKF
57	115	15	2013-11-25	am	f	local ETKF
57	115	15	2013-11-25	pm	f	local ETKF
73	110	15	2013-11-26	am	f	bulge
57	115	15	2013-11-26	pm	f	local ETKF
73	110	15	2013-11-27	am	f	bulge
73	110	15	2013-11-27	pm	f	bulge
72	110	15	2013-11-28	am	f	bulge article
72	110	15	2013-11-28	pm	f	bulge article
72	110	15	2013-11-29	am	f	bulge article
67	115	15	2013-11-29	pm	f	useless teleconf.... 
57	102	22	2013-11-25	pm	f	
57	102	22	2013-11-25	am	f	
70	102	22	2013-11-26	pm	f	
57	102	22	2013-11-26	am	f	
70	102	22	2013-11-27	pm	f	
\N	\N	22	2013-11-27	am	t	
58	131	22	2013-11-28	pm	f	
58	131	22	2013-11-28	am	f	
58	131	22	2013-11-29	pm	f	
58	131	22	2013-11-29	am	f	
57	131	22	2013-12-02	pm	f	
57	131	22	2013-12-02	am	f	
57	115	15	2013-12-02	am	f	ETKFLOCAL
57	115	15	2013-12-02	pm	f	ETKFLOCAL
73	110	15	2013-12-03	am	f	bulge
73	110	15	2013-12-03	pm	f	bulge
72	110	15	2013-12-04	am	f	bulge
72	110	15	2013-12-04	pm	f	bulge
72	110	15	2013-12-05	am	f	bulge
57	115	15	2013-12-05	pm	f	local ETKF small changes
57	115	15	2013-12-06	am	f	local ETKF small changes
73	110	15	2013-12-06	pm	f	bulge
56	89	22	2013-12-03	pm	f	
56	89	22	2013-12-03	am	f	bascule en prod
57	131	22	2013-12-04	pm	f	
\N	\N	22	2013-12-04	am	t	
57	131	22	2013-12-05	pm	f	
57	131	22	2013-12-05	am	f	
59	85	22	2013-12-06	pm	f	Noel
59	85	22	2013-12-06	am	f	Noel
67	92	31	2013-12-16	pm	f	
\N	\N	15	2013-12-09	am	t	
\N	\N	15	2013-12-09	pm	t	
\N	\N	15	2013-12-10	am	t	
\N	\N	15	2013-12-10	pm	t	
\N	\N	15	2013-12-11	am	t	
\N	\N	15	2013-12-11	pm	t	
\N	\N	15	2013-12-12	am	t	
\N	\N	15	2013-12-12	pm	t	
73	110	15	2013-12-13	am	f	bulge
73	110	15	2013-12-13	pm	f	bulge
72	110	15	2013-12-16	am	f	gas article some stuff
67	115	15	2013-12-16	pm	f	point about prevous week
57	131	22	2013-12-09	pm	f	
58	131	22	2013-12-09	am	f	
55	98	22	2013-12-10	pm	f	HRS
70	98	22	2013-12-10	am	f	HRS
57	102	22	2013-12-11	pm	f	
\N	\N	22	2013-12-11	am	t	
59	85	22	2013-12-12	pm	f	course NOEL LAM
69	131	22	2013-12-12	am	f	
\N	\N	22	2013-12-13	pm	t	
\N	\N	22	2013-12-13	am	t	
70	102	22	2013-12-16	pm	f	
57	131	22	2013-12-16	am	f	
\N	\N	22	2013-12-17	pm	t	
56	66	22	2013-12-17	am	f	Coma & ABELL sous ANIS
59	85	22	2013-12-18	pm	f	NOEL LAM
\N	\N	22	2013-12-18	am	t	
56	132	22	2013-12-19	pm	f	zCOSMOS sous ANIS
56	66	22	2013-12-19	am	f	HSTCOSMOS sous ANIS
\N	\N	22	2013-12-20	pm	t	
70	98	22	2013-12-20	am	f	HRS
73	110	15	2013-12-17	am	f	bulge
73	110	15	2013-12-17	pm	f	bulge
73	110	15	2013-12-18	am	f	bulge
67	115	15	2013-12-18	pm	f	discussion about local ETKF
67	110	15	2013-12-19	am	f	discussion about future
73	110	15	2013-12-19	pm	f	bulge jade
73	110	15	2013-12-20	am	f	bulge jade
\N	\N	15	2013-12-20	pm	t	
\N	\N	15	2013-12-23	am	t	
\N	\N	15	2013-12-23	pm	t	
\N	\N	15	2013-12-24	am	t	
\N	\N	15	2013-12-24	pm	t	
\N	\N	15	2013-12-25	am	t	
\N	\N	15	2013-12-25	pm	t	
\N	\N	15	2013-12-26	am	t	
\N	\N	15	2013-12-26	pm	t	
\N	\N	15	2013-12-27	am	t	
\N	\N	15	2013-12-27	pm	t	
\N	\N	15	2013-12-30	am	t	
\N	\N	15	2013-12-30	pm	t	
\N	\N	15	2013-12-31	am	t	
\N	\N	15	2013-12-31	pm	t	
\N	\N	15	2014-01-01	am	t	
\N	\N	15	2014-01-01	pm	t	
73	110	15	2014-01-02	am	f	bulge
73	110	15	2014-01-02	pm	f	bulge
73	110	15	2014-01-03	am	f	bulge
73	110	15	2014-01-03	pm	f	bulge
57	115	15	2014-01-06	am	f	local ETKF small fix and discussion
57	110	15	2014-01-06	pm	f	for bulge project
\N	\N	5	2013-12-20	am	t	
\N	\N	5	2013-12-20	pm	t	
\N	\N	5	2013-12-23	am	t	
\N	\N	5	2013-12-23	pm	t	
\N	\N	5	2013-12-24	am	t	
\N	\N	5	2013-12-24	pm	t	
\N	\N	5	2013-12-25	am	t	
\N	\N	5	2013-12-25	pm	t	
\N	\N	5	2013-12-26	am	t	
\N	\N	5	2013-12-26	pm	t	
\N	\N	5	2013-12-27	am	t	
\N	\N	5	2013-12-27	pm	t	
\N	\N	5	2013-12-30	am	t	
\N	\N	5	2013-12-30	pm	t	
\N	\N	5	2013-12-31	am	t	
\N	\N	5	2013-12-31	pm	t	
\N	\N	5	2014-01-01	am	t	
\N	\N	5	2014-01-01	pm	t	
\N	\N	5	2014-01-02	am	t	
\N	\N	5	2014-01-02	pm	t	
\N	\N	5	2014-01-03	am	t	
\N	\N	5	2014-01-03	pm	t	
\N	\N	5	2014-01-06	am	t	
\N	\N	5	2014-01-06	pm	t	
\N	\N	14	2014-01-01	am	t	
\N	\N	14	2014-01-01	pm	t	
\N	\N	14	2014-01-02	am	t	
\N	\N	14	2014-01-02	pm	t	
\N	\N	14	2014-01-03	am	t	
\N	\N	14	2014-01-03	pm	t	
59	84	14	2014-01-06	am	f	Retour de vacances - Tri des mails, reprise des activités... etc
59	89	14	2014-01-06	pm	f	Activités stagiaire Francois Gilbert / Sebastien Piednoir
66	67	14	2014-01-07	am	f	Revue des activités pour 2014
55	81	14	2014-01-07	pm	f	Architecture ZMQ du pipeline EUCLID
55	105	14	2014-01-08	am	f	
67	89	14	2014-01-08	pm	f	
55	67	14	2014-01-09	am	f	Pascal Guterman / indicateurs de qualités Susana & José
59	84	14	2014-01-09	pm	f	Comment creer un bundle Mac pour le CRAM
\N	\N	11	2014-01-01	am	t	
\N	\N	11	2014-01-01	pm	t	
55	74	11	2014-01-02	am	f	TDB
55	74	11	2014-01-02	pm	f	TDB
55	67	11	2014-01-03	am	f	Conta C1
55	67	11	2014-01-03	pm	f	Conta C1
62	84	11	2014-01-06	am	f	Conduite de Projet
62	84	11	2014-01-06	pm	f	Conduite de Projet
62	84	11	2014-01-07	am	f	Conduite de Projet
62	84	11	2014-01-07	pm	f	Conduite de Projet
62	84	11	2014-01-08	am	f	Conduite de Projet
62	84	11	2014-01-08	pm	f	Conduite de Projet
62	84	11	2014-01-09	am	f	Conduite de Projet
62	84	11	2014-01-09	pm	f	Conduite de Projet
55	133	11	2014-01-10	am	f	
62	84	11	2014-01-10	pm	f	Formation Anglais
66	63	11	2014-01-13	am	f	Accueil Alexandra Avdjian
\N	\N	22	2013-12-23	pm	t	
\N	\N	22	2013-12-23	am	t	
\N	\N	22	2013-12-24	pm	t	
\N	\N	22	2013-12-24	am	t	
\N	\N	22	2013-12-25	pm	t	
\N	\N	22	2013-12-25	am	t	
\N	\N	22	2013-12-26	pm	t	
\N	\N	22	2013-12-26	am	t	
\N	\N	22	2013-12-27	pm	t	
\N	\N	22	2013-12-27	am	t	
\N	\N	22	2013-12-30	pm	t	
\N	\N	22	2013-12-30	am	t	
\N	\N	22	2013-12-31	pm	t	
\N	\N	22	2013-12-31	am	t	
\N	\N	22	2014-01-01	pm	t	
\N	\N	22	2014-01-01	am	t	
\N	\N	22	2014-01-02	pm	t	
\N	\N	22	2014-01-02	am	t	
\N	\N	22	2014-01-03	pm	t	
\N	\N	22	2014-01-03	am	t	
58	131	22	2014-01-06	pm	f	
58	131	22	2014-01-06	am	f	
57	66	22	2014-01-07	pm	f	
57	66	22	2014-01-07	am	f	
67	89	22	2014-01-08	pm	f	
\N	\N	22	2014-01-08	am	t	
\N	\N	22	2014-01-09	pm	t	
69	102	22	2014-01-09	am	f	
\N	\N	22	2014-01-10	pm	t	
69	102	22	2014-01-10	am	f	
63	89	22	2014-01-13	am	f	
\N	\N	11	2013-12-23	am	t	
\N	\N	11	2013-12-23	pm	t	
\N	\N	11	2013-12-24	am	t	
\N	\N	11	2013-12-24	pm	t	
\N	\N	11	2013-12-25	am	t	
\N	\N	11	2013-12-25	pm	t	
\N	\N	11	2013-12-26	am	t	
\N	\N	11	2013-12-26	pm	t	
\N	\N	11	2013-12-27	am	t	
\N	\N	11	2013-12-27	pm	t	
\N	\N	11	2013-12-30	am	t	
\N	\N	11	2013-12-30	pm	t	
\N	\N	11	2013-12-31	am	t	
\N	\N	11	2013-12-31	pm	t	
67	139	11	2014-01-13	pm	f	
73	110	15	2014-01-07	am	f	bulge project
73	110	15	2014-01-07	pm	f	bulge project
57	115	15	2014-01-08	am	f	compass KALMAN 
57	115	15	2014-01-08	pm	f	compass KALMAN
73	110	15	2014-01-09	am	f	bulge project
73	110	15	2014-01-09	pm	f	bulge project
57	115	15	2014-01-10	am	f	KALMAN
57	115	15	2014-01-10	pm	f	local ETKF
73	110	15	2014-01-13	am	f	discussion with lia
55	115	15	2014-01-13	pm	f	installation of magma/cula etc and analysis
55	115	15	2014-01-14	am	f	installation of magma/cula etc and analysis
55	115	15	2014-01-14	pm	f	installation of magma/cula etc and analysis
57	115	15	2014-01-15	am	f	KALMAN
57	115	15	2014-01-15	pm	f	architecture of bc_KALMAN it1
57	115	15	2014-01-16	am	f	architecture of bc_KALMAN it1
57	115	15	2014-01-16	pm	f	
\N	\N	15	2014-01-17	am	t	
73	110	15	2014-01-17	pm	f	bulge
57	71	17	2014-01-06	am	f	Working on new missing blocks procedures.
57	71	17	2014-01-06	pm	f	Working on new missing blocks procedures.
57	71	17	2014-01-07	am	f	Working on new missing blocks procedures.
57	71	17	2014-01-07	pm	f	Working on new missing blocks procedures.
57	71	17	2014-01-08	am	f	Working on new missing blocks procedures.
57	71	17	2014-01-08	pm	f	Working on new missing blocks procedures.
71	71	17	2014-01-09	am	f	Server maintenance.
71	71	17	2014-01-09	pm	f	Server maintenance.
57	71	17	2014-01-10	am	f	Working on new missing blocks procedures.
57	71	17	2014-01-10	pm	f	Working on new missing blocks procedures.
57	71	17	2014-01-13	am	f	Working on new missing blocks procedures.
57	71	17	2014-01-13	pm	f	Working on new missing blocks procedures.
63	71	17	2014-01-14	am	f	New stations installation and configuration.
63	71	17	2014-01-14	pm	f	New stations installation and configuration.
57	71	17	2014-01-15	am	f	Working on new separation and inversion procedures.
57	71	17	2014-01-15	pm	f	Working on new separation and inversion procedures.
57	71	17	2014-01-16	am	f	Working on new separation and inversion procedures.
57	71	17	2014-01-16	pm	f	Working on new separation and inversion procedures.
57	71	17	2014-01-17	am	f	Working on new separation and inversion procedures.
57	71	17	2014-01-17	pm	f	Working on new separation and inversion procedures.
57	71	17	2014-01-20	am	f	Working on new separation and inversion procedures.
57	71	17	2014-01-20	pm	f	Working on new separation and inversion procedures.
57	71	17	2014-01-21	am	f	Working on new separation and inversion procedures.
57	71	17	2014-01-21	pm	f	Working on new separation and inversion procedures.
57	71	17	2014-01-22	am	f	Working on new separation and inversion procedures.
57	71	17	2014-01-22	pm	f	Working on new separation and inversion procedures.
67	125	22	2014-01-15	pm	f	
67	125	22	2014-01-15	am	f	
57	77	22	2014-01-20	pm	f	
55	77	22	2014-01-20	am	f	
70	77	22	2014-01-21	pm	f	
70	77	22	2014-01-21	am	f	
70	77	22	2014-01-22	pm	f	
\N	\N	22	2014-01-22	am	t	
55	63	32	2014-01-13	am	f	Découverte du projet
\N	\N	31	2014-01-06	pm	t	
\N	\N	31	2014-01-09	pm	t	
\N	\N	31	2014-01-13	pm	t	
\N	\N	31	2014-01-16	pm	t	
\N	\N	31	2014-01-22	am	t	
\N	\N	31	2014-01-22	pm	t	
\N	\N	31	2014-01-27	pm	t	
57	63	32	2014-01-28	am	f	
\N	\N	15	2014-01-20	am	t	
\N	\N	15	2014-01-20	pm	t	
\N	\N	15	2014-01-21	am	t	
\N	\N	15	2014-01-21	pm	t	
\N	\N	15	2014-01-22	am	t	
\N	\N	15	2014-01-22	pm	t	
\N	\N	15	2014-01-23	am	t	
\N	\N	15	2014-01-23	pm	t	
\N	\N	15	2014-01-24	am	t	
\N	\N	15	2014-01-24	pm	t	
\N	\N	15	2014-01-27	am	t	
72	110	15	2014-01-27	pm	f	bulge profect
72	110	15	2014-01-28	am	f	bulge project
57	115	15	2014-01-28	pm	f	KALMAN
73	110	15	2014-01-29	am	f	bar
73	110	15	2014-01-29	pm	f	bar
57	115	15	2014-01-30	am	f	interface KALMAN
57	115	15	2014-01-30	pm	f	interface KALMAN
73	110	15	2014-01-31	am	f	bar instability
73	110	15	2014-01-31	pm	f	bar instability
67	81	4	2013-11-20	am	f	reunion OUSPE
67	81	4	2013-11-20	pm	f	reunion OUSPE
55	105	4	2013-11-21	am	f	Analyse des pipelines
55	105	4	2013-11-21	pm	f	Analyse des pipelines
67	80	4	2013-11-22	am	f	reunion OUSIR
67	80	4	2013-11-22	pm	f	reunion OUSIR 
55	81	4	2013-11-25	am	f	Analyse proto
67	85	4	2013-11-25	pm	f	reunion valorisation
55	70	4	2013-11-26	am	f	Analyse cartes 
67	85	4	2013-11-26	pm	f	CS OSU
70	89	4	2013-11-27	am	f	finalisation budget
70	89	4	2013-11-27	pm	f	finalisation budget
55	105	4	2013-11-28	am	f	Analyse des pipelines
67	81	4	2013-11-28	pm	f	reunion OUSPE
55	81	4	2013-11-29	am	f	Analyse proto
55	81	4	2013-11-29	pm	f	Analyse proto
55	81	4	2013-12-02	am	f	Analyse proto
55	81	4	2013-12-02	pm	f	Analyse proto
67	89	4	2013-12-03	am	f	SGI - Big data
67	89	4	2013-12-03	pm	f	SGI - Big data
67	65	4	2013-12-04	am	f	EUCLID-France
67	65	4	2013-12-04	pm	f	EUCLID-France
67	65	4	2013-12-05	am	f	EUCLID-France
67	65	4	2013-12-05	pm	f	EUCLID-France
67	65	4	2013-12-06	am	f	EUCLID-France
67	65	4	2013-12-06	pm	f	EUCLID-France
55	65	4	2013-12-09	am	f	EUCLID-System
55	65	4	2013-12-09	pm	f	EUCLID-System
55	105	4	2013-12-10	am	f	Analyse des pipelines
55	105	4	2013-12-10	pm	f	Analyse des pipelines
66	133	4	2013-12-11	am	f	Analyse dossiers postdoc
66	133	4	2013-12-11	pm	f	Analyse dossiers postdoc
55	105	4	2013-12-12	am	f	Analyse des pipelines
67	81	4	2013-12-12	pm	f	reunion OUSPE
55	105	4	2013-12-13	am	f	Analyse des pipelines
55	105	4	2013-12-13	pm	f	Analyse des pipelines
55	105	4	2013-12-16	am	f	Analyse des pipelines
67	81	4	2013-12-16	pm	f	reunion OUSPE
55	89	4	2013-12-17	am	f	SO5
55	89	4	2013-12-17	pm	f	SO5
55	89	4	2013-12-18	am	f	SO5
\N	\N	4	2013-12-18	pm	t	
\N	\N	4	2013-12-19	am	t	
67	81	4	2013-12-19	pm	f	reunion OUSPE
\N	\N	4	2013-12-20	am	t	
\N	\N	4	2013-12-20	pm	t	
\N	\N	4	2013-12-23	am	t	
\N	\N	4	2013-12-23	pm	t	
\N	\N	4	2013-12-24	am	t	
\N	\N	4	2013-12-24	pm	t	
\N	\N	4	2013-12-25	am	t	
\N	\N	4	2013-12-25	pm	t	
\N	\N	4	2013-12-26	am	t	
\N	\N	4	2013-12-26	pm	t	
\N	\N	4	2013-12-27	am	t	
\N	\N	4	2013-12-27	pm	t	
\N	\N	4	2013-12-30	am	t	
\N	\N	4	2013-12-30	pm	t	
\N	\N	4	2013-12-31	am	t	
\N	\N	4	2013-12-31	pm	t	
\N	\N	4	2014-01-01	am	t	
\N	\N	4	2014-01-01	pm	t	
66	89	4	2014-01-02	am	f	Gestion des budgets
66	89	4	2014-01-02	pm	f	Gestion des budgets
66	89	4	2014-01-03	am	f	Gestion des budgets
66	89	4	2014-01-03	pm	f	Gestion des budgets
66	89	4	2014-01-06	am	f	Gestion des CDDs
66	89	4	2014-01-06	pm	f	Gestion des CDDs
55	65	4	2014-01-07	am	f	preparation des nouveaux delivrables
55	65	4	2014-01-07	pm	f	preparation des nouveaux delivrables
55	65	4	2014-01-08	am	f	preparation des nouveaux delivrables
55	65	4	2014-01-08	pm	f	preparation des nouveaux delivrables
67	85	4	2014-01-09	am	f	CS OSU
67	89	4	2014-01-09	pm	f	Réunion FIREBALL-Mege
66	89	4	2014-01-10	am	f	Gestion des CDDs
66	89	4	2014-01-10	pm	f	Gestion des CDDs
67	81	4	2014-01-13	am	f	reunion mi parcours
67	81	4	2014-01-13	pm	f	reunion mi parcours
67	80	4	2014-01-14	am	f	Meeting Milan
67	80	4	2014-01-14	pm	f	Meeting Milan
67	80	4	2014-01-15	am	f	Meeting Milan
67	80	4	2014-01-15	pm	f	Meeting Milan
55	88	4	2014-01-16	am	f	gestion pipeline
67	81	4	2014-01-16	pm	f	reunion 
55	88	4	2014-01-17	am	f	gestion pipeline
55	88	4	2014-01-17	pm	f	gestion pipeline
55	88	4	2014-01-20	am	f	gestion pipeline
66	89	4	2014-01-20	pm	f	Gestion des CDDs
66	89	4	2014-01-21	am	f	Gestion des CDDs
66	89	4	2014-01-21	pm	f	Gestion des CDDs
67	96	4	2014-01-22	am	f	preparation presentation pour projets MASTODONS Paris
67	96	4	2014-01-22	pm	f	preparation presentation pour projets MASTODONS Paris
67	96	4	2014-01-23	am	f	presentation pour projets MASTODONS Paris
67	96	4	2014-01-23	pm	f	presentation pour projets MASTODONS Paris
67	96	4	2014-01-24	am	f	presentation pour projets MASTODONS Paris
67	96	4	2014-01-24	pm	f	presentation pour projets MASTODONS Paris
55	65	4	2014-01-27	am	f	preparation des nouveaux delivrables
55	65	4	2014-01-27	pm	f	preparation des nouveaux delivrables
55	96	4	2014-01-28	am	f	preparation data for data mining
55	65	4	2014-01-28	pm	f	preparation des nouveaux delivrables
66	89	4	2014-01-29	am	f	Gestion des CDDs
55	65	4	2014-01-29	pm	f	Gestion pipeline 0MQ
\N	\N	4	2014-01-30	am	t	
67	81	4	2014-01-30	pm	f	reunion 
55	65	4	2014-01-31	am	f	preparation des nouveaux delivrables
55	65	4	2014-01-31	pm	f	preparation des nouveaux delivrables
55	65	4	2014-02-03	am	f	preparation des nouveaux delivrables
55	65	4	2014-02-03	pm	f	Reunion de fin de sprint
56	102	20	2013-11-05	am	f	
56	102	20	2013-11-05	pm	f	
56	102	20	2013-11-06	am	f	
56	102	20	2013-11-06	pm	f	
56	102	20	2013-11-07	am	f	
56	102	20	2013-11-07	pm	f	
57	102	20	2013-11-08	am	f	
57	102	20	2013-11-08	pm	f	
\N	\N	20	2013-11-11	am	t	
\N	\N	20	2013-11-11	pm	t	
57	131	20	2013-11-12	am	f	
57	131	20	2013-11-12	pm	f	
57	131	20	2013-11-13	am	f	
57	131	20	2013-11-13	pm	f	
57	131	20	2013-11-14	am	f	
57	131	20	2013-11-14	pm	f	
57	102	20	2013-11-15	am	f	
57	102	20	2013-11-15	pm	f	
57	102	20	2013-11-18	am	f	
57	102	20	2013-11-18	pm	f	
57	102	20	2013-11-19	am	f	
57	102	20	2013-11-19	pm	f	
57	128	20	2013-11-20	am	f	
56	128	20	2013-11-20	pm	f	
70	102	20	2013-11-21	am	f	
70	102	20	2013-11-21	pm	f	
57	131	20	2013-11-22	am	f	
57	131	20	2013-11-22	pm	f	
57	131	20	2013-11-25	am	f	
57	131	20	2013-11-25	pm	f	
57	131	20	2013-11-26	am	f	
57	131	20	2013-11-26	pm	f	
57	131	20	2013-11-27	am	f	
57	131	20	2013-11-27	pm	f	
57	131	20	2013-11-28	am	f	
57	131	20	2013-11-28	pm	f	
57	131	20	2013-11-29	am	f	
57	131	20	2013-11-29	pm	f	
57	102	20	2013-12-02	am	f	
57	102	20	2013-12-02	pm	f	
57	102	20	2013-12-03	am	f	
57	102	20	2013-12-03	pm	f	
71	102	20	2013-12-04	am	f	
71	102	20	2013-12-04	pm	f	
71	102	20	2013-12-05	am	f	
71	102	20	2013-12-05	pm	f	
57	131	20	2013-12-06	am	f	
57	131	20	2013-12-06	pm	f	
57	131	20	2013-12-09	am	f	
57	131	20	2013-12-09	pm	f	
57	131	20	2013-12-10	am	f	
57	131	20	2013-12-10	pm	f	
57	131	20	2013-12-11	am	f	
57	131	20	2013-12-11	pm	f	
57	131	20	2013-12-12	am	f	
57	131	20	2013-12-12	pm	f	
57	131	20	2013-12-13	am	f	
57	131	20	2013-12-13	pm	f	
57	131	20	2013-12-16	am	f	
57	131	20	2013-12-16	pm	f	
57	131	20	2013-12-17	am	f	
57	131	20	2013-12-17	pm	f	
57	131	20	2013-12-18	am	f	
57	131	20	2013-12-18	pm	f	
57	131	20	2013-12-19	am	f	
57	131	20	2013-12-19	pm	f	
57	131	20	2013-12-20	am	f	
57	131	20	2013-12-20	pm	f	
\N	\N	20	2013-12-23	am	t	
\N	\N	20	2013-12-23	pm	t	
\N	\N	20	2013-12-24	am	t	
\N	\N	20	2013-12-24	pm	t	
\N	\N	20	2013-12-25	am	t	
\N	\N	20	2013-12-25	pm	t	
\N	\N	20	2013-12-26	am	t	
\N	\N	20	2013-12-26	pm	t	
\N	\N	20	2013-12-27	am	t	
\N	\N	20	2013-12-27	pm	t	
\N	\N	20	2013-12-30	am	t	
\N	\N	20	2013-12-30	pm	t	
\N	\N	20	2013-12-31	am	t	
\N	\N	20	2013-12-31	pm	t	
\N	\N	20	2014-01-01	am	t	
\N	\N	20	2014-01-01	pm	t	
\N	\N	20	2014-01-02	am	t	
\N	\N	20	2014-01-02	pm	t	
\N	\N	20	2014-01-03	am	t	
\N	\N	20	2014-01-03	pm	t	
57	131	20	2014-01-06	am	f	
57	131	20	2014-01-06	pm	f	
57	131	20	2014-01-07	am	f	
57	131	20	2014-01-07	pm	f	
\N	\N	20	2014-01-08	am	t	
\N	\N	20	2014-01-08	pm	t	
57	131	20	2014-01-09	am	f	
57	131	20	2014-01-09	pm	f	
57	131	20	2014-01-10	am	f	
57	131	20	2014-01-10	pm	f	
57	131	20	2014-01-13	am	f	
57	131	20	2014-01-13	pm	f	
57	131	20	2014-01-14	am	f	
57	131	20	2014-01-14	pm	f	
57	131	20	2014-01-15	am	f	
57	131	20	2014-01-15	pm	f	
57	131	20	2014-01-16	am	f	
57	131	20	2014-01-16	pm	f	
57	131	20	2014-01-17	am	f	
57	131	20	2014-01-17	pm	f	
57	102	20	2014-01-20	am	f	
57	102	20	2014-01-20	pm	f	
57	102	20	2014-01-21	am	f	
57	102	20	2014-01-21	pm	f	
57	102	20	2014-01-22	am	f	
57	102	20	2014-01-22	pm	f	
57	102	20	2014-01-23	am	f	
57	102	20	2014-01-23	pm	f	
57	102	20	2014-01-24	am	f	
57	102	20	2014-01-24	pm	f	
57	102	20	2014-01-27	am	f	
57	102	20	2014-01-27	pm	f	
57	102	20	2014-01-28	am	f	
57	102	20	2014-01-28	pm	f	
57	102	20	2014-01-29	am	f	
57	102	20	2014-01-29	pm	f	
70	102	20	2014-01-30	am	f	
70	102	20	2014-01-30	pm	f	
70	102	20	2014-01-31	am	f	
70	102	20	2014-01-31	pm	f	
57	131	20	2014-02-03	am	f	
57	131	20	2014-02-03	pm	f	
57	131	20	2014-02-04	am	f	
57	131	20	2014-02-04	pm	f	
57	131	19	2013-11-07	am	f	Developpement filtres individuels
57	131	19	2013-11-07	pm	f	Developpement filtres individuels
57	131	19	2013-11-08	am	f	Developpement filtres individuels
57	131	19	2013-11-08	pm	f	Developpement filtres individuels
\N	\N	19	2013-11-11	am	t	
\N	\N	19	2013-11-11	pm	t	
57	131	19	2013-11-12	am	f	Developpement filtres individuels
57	131	19	2013-11-12	pm	f	Developpement filtres individuels
57	131	19	2013-11-13	am	f	Developpement filtres individuels
57	131	19	2013-11-13	pm	f	Developpement filtres individuels
57	131	19	2013-11-14	am	f	Developpement filtres individuels
57	131	19	2013-11-14	pm	f	Developpement filtres individuels
57	131	19	2013-11-15	am	f	Developpement filtres individuels
57	131	19	2013-11-15	pm	f	Developpement filtres individuels
57	131	19	2013-11-18	am	f	Developpement filtres individuels
57	131	19	2013-11-18	pm	f	Developpement filtres individuels
57	131	19	2013-11-19	am	f	Developpement filtres individuels
57	131	19	2013-11-19	pm	f	Developpement filtres individuels
57	131	19	2013-11-20	am	f	Developpement filtres individuels
57	131	19	2013-11-20	pm	f	Developpement filtres individuels
57	131	19	2013-11-21	am	f	Developpement filtres individuels
57	131	19	2013-11-21	pm	f	Developpement filtres individuels
67	67	19	2013-11-22	am	f	Reunion avancement
57	131	19	2013-11-22	pm	f	Developpement filtres individuels
57	131	19	2013-11-25	am	f	Developpement filtres individuels
57	131	19	2013-11-25	pm	f	Developpement filtres individuels
57	131	19	2013-11-26	am	f	Developpement filtres individuels
57	131	19	2013-11-26	pm	f	Developpement filtres individuels
57	131	19	2013-11-27	am	f	Developpement filtres individuels
57	131	19	2013-11-27	pm	f	Developpement filtres individuels
57	131	19	2013-11-28	am	f	Developpement filtres individuels
57	131	19	2013-11-28	pm	f	Developpement filtres individuels
57	131	19	2013-11-29	am	f	Developpement filtres individuels
57	131	19	2013-11-29	pm	f	Developpement filtres individuels
57	131	19	2013-12-02	am	f	Developpement filtres individuels
57	131	19	2013-12-02	pm	f	Developpement filtres individuels
57	131	19	2013-12-03	am	f	Developpement filtres individuels
57	131	19	2013-12-03	pm	f	Developpement filtres individuels
57	131	19	2013-12-04	am	f	Developpement filtres individuels
57	131	19	2013-12-04	pm	f	Developpement filtres individuels
57	131	19	2013-12-05	am	f	Developpement filtres individuels
57	131	19	2013-12-05	pm	f	Developpement filtres individuels
57	131	19	2013-12-06	am	f	Developpement filtres individuels
57	131	19	2013-12-06	pm	f	Developpement filtres individuels
57	131	19	2013-12-09	am	f	Ajout des Sqlbuilder pour la gestion des modes de recherche (criteria, cone-search, list...)
57	131	19	2013-12-09	pm	f	Ajout des Sqlbuilder pour la gestion des modes de recherche (criteria, cone-search, list...)
57	131	19	2013-12-10	am	f	Ajout des Sqlbuilder pour la gestion des modes de recherche (criteria, cone-search, list...)
55	67	14	2014-01-16	pm	f	Systematique avec Pascal Guterman
57	131	19	2013-12-10	pm	f	Ajout des Sqlbuilder pour la gestion des modes de recherche (criteria, cone-search, list...)
57	131	19	2013-12-11	am	f	Ajout des Sqlbuilder pour la gestion des modes de recherche (criteria, cone-search, list...)
57	131	19	2013-12-11	pm	f	Ajout des Sqlbuilder pour la gestion des modes de recherche (criteria, cone-search, list...)
57	131	19	2013-12-12	am	f	Ajout des Sqlbuilder pour la gestion des modes de recherche (criteria, cone-search, list...)
57	131	19	2013-12-12	pm	f	Ajout des Sqlbuilder pour la gestion des modes de recherche (criteria, cone-search, list...)
57	131	19	2013-12-13	am	f	Ajout des Sqlbuilder pour la gestion des modes de recherche (criteria, cone-search, list...)
57	131	19	2013-12-13	pm	f	Ajout des Sqlbuilder pour la gestion des modes de recherche (criteria, cone-search, list...)
57	131	19	2013-12-16	am	f	Ajout des Sqlbuilder pour la gestion des modes de recherche (criteria, cone-search, list...)
57	131	19	2013-12-16	pm	f	Ajout des Sqlbuilder pour la gestion des modes de recherche (criteria, cone-search, list...)
57	131	19	2013-12-17	am	f	Ajout des Sqlbuilder pour la gestion des modes de recherche (criteria, cone-search, list...)
57	131	19	2013-12-17	pm	f	Ajout des Sqlbuilder pour la gestion des modes de recherche (criteria, cone-search, list...)
57	131	19	2013-12-18	am	f	Ajout des Sqlbuilder pour la gestion des modes de recherche (criteria, cone-search, list...)
57	131	19	2013-12-18	pm	f	Ajout des Sqlbuilder pour la gestion des modes de recherche (criteria, cone-search, list...)
\N	\N	19	2013-12-19	am	t	
\N	\N	19	2013-12-19	pm	t	
\N	\N	19	2013-12-20	am	t	
\N	\N	19	2013-12-20	pm	t	
\N	\N	19	2013-12-23	am	t	
\N	\N	19	2013-12-23	pm	t	
\N	\N	19	2013-12-24	am	t	
\N	\N	19	2013-12-24	pm	t	
\N	\N	19	2013-12-25	am	t	
\N	\N	19	2013-12-25	pm	t	
\N	\N	19	2013-12-26	am	t	
\N	\N	19	2013-12-26	pm	t	
\N	\N	19	2013-12-27	am	t	
\N	\N	19	2013-12-27	pm	t	
\N	\N	19	2013-12-30	am	t	
\N	\N	19	2013-12-30	pm	t	
\N	\N	19	2013-12-31	am	t	
\N	\N	19	2013-12-31	pm	t	
\N	\N	19	2014-01-01	am	t	
\N	\N	19	2014-01-01	pm	t	
\N	\N	19	2014-01-02	am	t	
\N	\N	19	2014-01-02	pm	t	
\N	\N	19	2014-01-03	am	t	
\N	\N	19	2014-01-03	pm	t	
57	131	19	2014-01-06	am	f	Ajout des Sqlbuilder pour la gestion des modes de recherche (criteria, cone-search, list...)
57	131	19	2014-01-06	pm	f	Ajout des Sqlbuilder pour la gestion des modes de recherche (criteria, cone-search, list...)
57	131	19	2014-01-07	am	f	Ajout des Sqlbuilder pour la gestion des modes de recherche (criteria, cone-search, list...)
57	131	19	2014-01-07	pm	f	Ajout des Sqlbuilder pour la gestion des modes de recherche (criteria, cone-search, list...)
57	131	19	2014-01-08	am	f	Ajout des Sqlbuilder pour la gestion des modes de recherche (criteria, cone-search, list...)
67	89	19	2014-01-08	pm	f	Reunion CeSAM
57	131	19	2014-01-09	am	f	Ajout des Sqlbuilder pour la gestion des modes de recherche (criteria, cone-search, list...)
57	131	19	2014-01-09	pm	f	Ajout des Sqlbuilder pour la gestion des modes de recherche (criteria, cone-search, list...)
57	131	19	2014-01-10	am	f	Ajout des Sqlbuilder pour la gestion des modes de recherche (criteria, cone-search, list...)
57	131	19	2014-01-10	pm	f	Ajout des Sqlbuilder pour la gestion des modes de recherche (criteria, cone-search, list...)
57	131	19	2014-01-13	am	f	Ajout des Sqlbuilder pour la gestion des modes de recherche (criteria, cone-search, list...)
57	131	19	2014-01-13	pm	f	Ajout des Sqlbuilder pour la gestion des modes de recherche (criteria, cone-search, list...)
57	131	19	2014-01-14	am	f	Ajout des Sqlbuilder pour la gestion des modes de recherche (criteria, cone-search, list...)
57	131	19	2014-01-14	pm	f	Ajout des Sqlbuilder pour la gestion des modes de recherche (criteria, cone-search, list...)
57	131	19	2014-01-15	am	f	Ajout des Sqlbuilder pour la gestion des modes de recherche (criteria, cone-search, list...)
57	131	19	2014-01-15	pm	f	Ajout des Sqlbuilder pour la gestion des modes de recherche (criteria, cone-search, list...)
57	131	19	2014-01-16	am	f	Ajout des Sqlbuilder pour la gestion des modes de recherche (criteria, cone-search, list...)
57	131	19	2014-01-16	pm	f	Ajout des Sqlbuilder pour la gestion des modes de recherche (criteria, cone-search, list...)
57	131	19	2014-01-17	am	f	Ajout des Sqlbuilder pour la gestion des modes de recherche (criteria, cone-search, list...)
57	131	19	2014-01-17	pm	f	Ajout des Sqlbuilder pour la gestion des modes de recherche (criteria, cone-search, list...)
57	131	19	2014-01-20	am	f	Ajout des Sqlbuilder pour la gestion des modes de recherche (criteria, cone-search, list...)
57	131	19	2014-01-20	pm	f	Ajout des Sqlbuilder pour la gestion des modes de recherche (criteria, cone-search, list...)
\N	\N	19	2014-01-21	am	t	
\N	\N	19	2014-01-21	pm	t	
57	131	19	2014-01-22	am	f	Ajout des Sqlbuilder pour la gestion des modes de recherche (criteria, cone-search, list...)
57	131	19	2014-01-22	pm	f	Ajout des Sqlbuilder pour la gestion des modes de recherche (criteria, cone-search, list...)
57	131	19	2014-01-23	am	f	Ajout des Sqlbuilder pour la gestion des modes de recherche (criteria, cone-search, list...)
57	131	19	2014-01-23	pm	f	Ajout des Sqlbuilder pour la gestion des modes de recherche (criteria, cone-search, list...)
57	131	19	2014-01-24	am	f	Ajout des Sqlbuilder pour la gestion des modes de recherche (criteria, cone-search, list...)
57	131	19	2014-01-24	pm	f	Ajout des Sqlbuilder pour la gestion des modes de recherche (criteria, cone-search, list...)
57	131	19	2014-01-27	am	f	Ajout des Sqlbuilder pour la gestion des modes de recherche (criteria, cone-search, list...)
57	131	19	2014-01-27	pm	f	Ajout des Sqlbuilder pour la gestion des modes de recherche (criteria, cone-search, list...)
57	131	19	2014-01-28	am	f	Ajout des Sqlbuilder pour la gestion des modes de recherche (criteria, cone-search, list...)
57	131	19	2014-01-28	pm	f	Ajout des Sqlbuilder pour la gestion des modes de recherche (criteria, cone-search, list...)
57	131	19	2014-01-29	am	f	Ajout des Sqlbuilder pour la gestion des modes de recherche (criteria, cone-search, list...)
57	131	19	2014-01-29	pm	f	Ajout des Sqlbuilder pour la gestion des modes de recherche (criteria, cone-search, list...)
57	131	19	2014-01-30	am	f	Ajout des Sqlbuilder pour la gestion des modes de recherche (criteria, cone-search, list...)
57	131	19	2014-01-30	pm	f	Ajout des Sqlbuilder pour la gestion des modes de recherche (criteria, cone-search, list...)
\N	\N	19	2014-01-31	am	t	
\N	\N	19	2014-01-31	pm	t	
59	125	19	2014-02-03	am	f	EPR n°912
59	125	19	2014-02-03	pm	f	EPR n°912
57	115	15	2014-02-03	am	f	KALMAN ARCH
57	115	15	2014-02-03	pm	f	KALMAN ARCH
55	110	15	2014-02-04	am	f	chemical
55	110	15	2014-02-04	pm	f	chemical
69	89	5	2013-11-26	am	f	cluster
\N	\N	5	2013-11-27	pm	t	
\N	\N	5	2013-11-29	am	t	
\N	\N	5	2013-11-29	pm	t	
\N	\N	5	2013-12-09	am	t	
\N	\N	5	2013-12-09	pm	t	
\N	\N	5	2013-12-10	am	t	
\N	\N	5	2013-12-10	pm	t	
\N	\N	5	2013-12-13	pm	t	
\N	\N	5	2013-12-17	am	t	
\N	\N	5	2013-12-17	pm	t	
\N	\N	5	2014-01-24	pm	t	
\N	\N	5	2014-01-31	am	t	
\N	\N	5	2014-01-31	pm	t	
63	89	5	2013-11-26	pm	f	
63	89	5	2013-11-27	am	f	
63	89	5	2013-11-28	am	f	
63	89	5	2013-11-28	pm	f	
63	89	5	2013-12-02	am	f	
63	89	5	2013-12-02	pm	f	
63	89	5	2013-12-03	am	f	
63	89	5	2013-12-03	pm	f	
63	89	5	2013-12-04	am	f	
63	89	5	2013-12-04	pm	f	
63	89	5	2013-12-05	am	f	
63	89	5	2013-12-05	pm	f	
63	89	5	2013-12-06	am	f	
63	89	5	2013-12-06	pm	f	
63	89	5	2013-12-11	am	f	
63	89	5	2013-12-11	pm	f	
63	89	5	2013-12-12	am	f	
63	89	5	2013-12-12	pm	f	
63	89	5	2013-12-13	am	f	
63	89	5	2013-12-16	am	f	
63	89	5	2013-12-16	pm	f	
63	89	5	2013-12-18	am	f	
63	89	5	2013-12-18	pm	f	
63	89	5	2013-12-19	am	f	
63	89	5	2013-12-19	pm	f	
69	89	5	2014-01-07	am	f	
69	89	5	2014-01-07	pm	f	
69	89	5	2014-01-08	am	f	
69	89	5	2014-01-08	pm	f	
69	89	5	2014-01-09	am	f	
69	89	5	2014-01-09	pm	f	
67	100	5	2014-01-10	am	f	
67	100	5	2014-01-10	pm	f	
69	89	5	2014-01-13	am	f	
69	89	5	2014-01-13	pm	f	
69	89	5	2014-01-14	am	f	
69	89	5	2014-01-14	pm	f	
69	89	5	2014-01-15	am	f	
69	89	5	2014-01-15	pm	f	
69	89	5	2014-01-16	am	f	
69	89	5	2014-01-16	pm	f	
69	89	5	2014-01-17	am	f	
69	89	5	2014-01-17	pm	f	
63	89	5	2014-01-20	am	f	
63	89	5	2014-01-20	pm	f	
63	89	5	2014-01-21	am	f	
63	89	5	2014-01-21	pm	f	
69	89	5	2014-01-22	am	f	
69	89	5	2014-01-22	pm	f	
69	89	5	2014-01-23	am	f	
69	89	5	2014-01-23	pm	f	
69	89	5	2014-01-24	am	f	
63	89	5	2014-01-27	am	f	
63	89	5	2014-01-27	pm	f	
69	100	5	2014-01-28	am	f	
69	100	5	2014-01-28	pm	f	
69	100	5	2014-01-29	am	f	
69	100	5	2014-01-29	pm	f	
63	89	5	2014-01-30	am	f	
63	89	5	2014-01-30	pm	f	
63	89	5	2014-02-03	am	f	
63	89	5	2014-02-03	pm	f	
63	89	5	2014-02-04	am	f	
63	89	5	2014-02-04	pm	f	
63	89	5	2014-02-05	am	f	
63	89	5	2014-02-05	pm	f	
58	89	5	2014-02-06	am	f	
69	85	5	2014-02-06	pm	f	
57	89	5	2014-02-07	am	f	
63	89	5	2014-02-07	pm	f	
67	85	5	2014-02-10	am	f	
63	89	5	2014-02-10	pm	f	
57	110	15	2014-02-05	am	f	chemical project
57	110	15	2014-02-05	pm	f	chemical project
57	115	15	2014-02-06	am	f	interface for KALMAN
57	115	15	2014-02-06	pm	f	interface for KALMAN
57	115	15	2014-02-07	am	f	interface for KALMAN
72	110	15	2014-02-07	pm	f	bar project
57	115	15	2014-02-10	am	f	KALMAN
72	110	15	2014-02-10	pm	f	bar project
72	110	15	2014-02-11	am	f	bar project
72	110	15	2014-02-11	pm	f	bar project
72	110	15	2014-02-12	am	f	bar project
\N	\N	15	2014-02-12	pm	t	
\N	\N	22	2014-01-17	pm	t	
70	102	22	2014-01-23	pm	f	
70	102	22	2014-01-23	am	f	add corrections tiger team
70	102	22	2014-01-24	pm	f	add corrections tiger team
70	102	22	2014-01-24	am	f	add corrections tiger team
70	102	22	2014-01-27	pm	f	add corrections tiger team
70	102	22	2014-01-27	am	f	add corrections tiger team
70	102	22	2014-01-28	pm	f	add corrections tiger team
70	102	22	2014-01-28	am	f	add corrections tiger team
\N	\N	22	2014-01-29	pm	t	
\N	\N	22	2014-01-29	am	t	
\N	\N	22	2014-01-30	pm	t	
\N	\N	22	2014-01-30	am	t	
\N	\N	22	2014-01-31	pm	t	
\N	\N	22	2014-01-31	am	t	
66	125	22	2014-02-03	pm	f	concours EPR 912
66	125	22	2014-02-03	am	f	concours EPR 912
66	125	22	2014-02-04	pm	f	concours EPR 912
66	125	22	2014-02-04	am	f	concours EPR 912
70	102	22	2014-02-05	pm	f	
\N	\N	22	2014-02-05	am	t	
56	102	22	2014-02-06	pm	f	
56	102	22	2014-02-06	am	f	
\N	\N	22	2014-02-07	pm	t	
70	101	22	2014-02-10	pm	f	anis metamodel
70	101	22	2014-02-10	am	f	anis metamodel
\N	\N	22	2014-02-11	pm	t	
67	98	22	2014-02-11	am	f	
57	98	22	2014-02-12	pm	f	
\N	\N	22	2014-02-12	am	t	
70	98	22	2014-01-14	pm	f	
70	98	22	2014-01-14	am	f	
57	102	22	2014-01-16	pm	f	
57	102	22	2014-01-16	am	f	
57	102	22	2014-01-17	am	f	
70	102	22	2014-02-07	am	f	
70	102	22	2014-01-13	pm	f	
55	81	14	2014-01-14	am	f	Pipeline
55	81	14	2014-01-14	pm	f	Pipeline
55	105	14	2014-01-15	am	f	Pipeline
55	105	14	2014-01-15	pm	f	Pipeline
56	67	14	2014-01-16	am	f	Exodat validation pré-prod
56	67	14	2014-01-17	am	f	Exodat validation pré-prod
67	84	14	2014-01-17	pm	f	Pyramide 3D avec Thierry Botti
66	67	14	2014-01-20	am	f	contamination
58	67	14	2014-01-20	pm	f	Indicateurs de qualite des courbes de lumiere
55	81	14	2014-01-21	am	f	Pipeline
55	81	14	2014-01-21	pm	f	Pipeline
58	67	14	2014-01-22	am	f	Indicateurs de qualite des courbes de lumiere
58	67	14	2014-01-22	pm	f	Indicateurs de qualite des courbes de lumiere
58	67	14	2014-01-23	am	f	Indicateurs de qualite des courbes de lumiere
58	67	14	2014-01-23	pm	f	Indicateurs de qualite des courbes de lumiere
55	105	14	2014-01-24	am	f	pipeline
55	105	14	2014-01-24	pm	f	pipeline
67	67	14	2014-01-27	am	f	Compte rendu CS du 24/01
59	84	14	2014-01-27	pm	f	Installation du poste stagiaire
59	84	14	2014-01-28	am	f	Installation du poste stagiaire
58	67	14	2014-01-28	pm	f	Guide pour l'implémentation de nouveaux algos dans le pipe N2
55	81	14	2014-01-29	am	f	Architecture proto
67	81	14	2014-01-29	pm	f	Architecture proto
55	81	14	2014-01-30	am	f	Architecture proto
58	67	14	2014-01-30	pm	f	Guide pour l'implémentation de nouveaux algos dans le pipe N2
66	67	14	2014-01-31	am	f	Suivi des actions
70	67	14	2014-01-31	pm	f	Validation de la contamination
59	84	14	2014-02-03	am	f	
55	67	14	2014-02-03	pm	f	Systématic avec Pascal Guterman
\N	\N	14	2014-02-04	am	t	
\N	\N	14	2014-02-04	pm	t	
\N	\N	14	2014-02-05	am	t	
55	81	14	2014-02-05	pm	f	Architecture proto
\N	\N	14	2014-02-06	am	t	
\N	\N	14	2014-02-06	pm	t	
67	67	14	2014-02-07	am	f	
55	81	14	2014-02-07	pm	f	Architecture proto
67	85	14	2014-02-10	am	f	Commission informatique
55	81	14	2014-02-10	pm	f	Pipeline
55	81	14	2014-02-11	am	f	Pipeline
67	89	14	2014-02-11	pm	f	Entretiens CDD
55	81	14	2014-02-12	am	f	Pipeline
70	67	14	2014-02-12	pm	f	
63	89	5	2014-02-11	am	f	
63	85	5	2014-02-11	pm	f	
63	85	5	2014-02-12	am	f	
63	85	5	2014-02-12	pm	f	
63	85	5	2014-02-13	am	f	
63	85	5	2014-02-13	pm	f	
\N	\N	5	2014-02-14	am	t	
\N	\N	5	2014-02-14	pm	t	
63	89	5	2014-02-17	am	f	
63	85	5	2014-02-17	pm	f	
57	115	15	2014-02-13	am	f	COMPASS
73	110	15	2014-02-13	pm	f	bar
73	110	15	2014-02-14	am	f	bar
\N	\N	15	2014-02-14	pm	t	
73	110	15	2014-02-17	am	f	bar
57	115	15	2014-02-17	pm	f	COMPASS
73	110	15	2014-02-18	am	f	bar
73	110	15	2014-02-18	pm	f	bar
57	115	15	2014-02-19	am	f	COMPASS
57	115	15	2014-02-19	pm	f	COMPASS
57	115	15	2014-02-20	am	f	COMPASS
73	110	15	2014-02-20	pm	f	bar
73	110	15	2014-02-21	am	f	bar
73	110	15	2014-02-21	pm	f	bar
73	110	15	2014-02-24	am	f	bar
73	110	15	2014-02-24	pm	f	bar
55	81	14	2014-02-13	am	f	Conception pipelin
55	81	14	2014-02-13	pm	f	Conception pipelin
55	81	14	2014-02-14	am	f	Conception pipelin
55	81	14	2014-02-14	pm	f	Conception pipelin
55	81	14	2014-02-17	am	f	Conception pipelin
55	81	14	2014-02-17	pm	f	Conception pipelin
55	81	14	2014-02-18	am	f	Conception pipelin
55	81	14	2014-02-18	pm	f	Conception pipelin
55	81	14	2014-02-19	am	f	Conception pipelin
59	89	14	2014-02-19	pm	f	Point projet + expertise LOOM
55	81	14	2014-02-20	am	f	Conception pipelin
58	133	14	2014-02-20	pm	f	Réflexion sur le document "on board algorithms"
55	81	14	2014-02-21	am	f	Pipeline
55	81	14	2014-02-21	pm	f	Pipeline
55	81	14	2014-02-24	am	f	Pipeline
55	81	14	2014-02-24	pm	f	Pipeline
71	67	14	2014-02-25	am	f	Tri SVN
69	81	14	2014-02-25	pm	f	API envoi / reception
67	67	14	2014-02-26	am	f	Avancement pixels chauds (Psacal Guterman & jose-Manuel)
67	81	14	2014-02-26	pm	f	Data Model
69	81	14	2014-02-27	am	f	API envoi / reception
67	67	14	2014-02-27	pm	f	Avancement pixels chauds (Psacal Guterman & jose-Manuel)
69	81	14	2014-02-28	am	f	API envoi / reception
69	81	14	2014-02-28	pm	f	API envoi / reception
57	92	31	2014-03-04	pm	f	
\N	\N	22	2014-02-24	pm	t	
\N	\N	22	2014-02-24	am	t	
\N	\N	22	2014-02-25	pm	t	
\N	\N	22	2014-02-25	am	t	
\N	\N	22	2014-02-26	pm	t	
\N	\N	22	2014-02-26	am	t	
\N	\N	22	2014-02-27	pm	t	
\N	\N	22	2014-02-27	am	t	
\N	\N	22	2014-02-28	pm	t	
\N	\N	22	2014-02-28	am	t	
55	98	22	2014-03-03	pm	f	
55	98	22	2014-03-03	am	f	
69	98	22	2014-03-04	pm	f	HELP : migration ANIS v2.0
69	98	22	2014-03-04	am	f	HRS: migration ANIS v2.0
69	98	22	2014-03-05	pm	f	HRS : migration ANIS v2.0
69	98	22	2014-03-05	am	f	HRS : migration ANIS v2.0
69	98	22	2014-03-06	pm	f	HerMES : migration ANIS v2.0
69	98	22	2014-03-06	am	f	HerMES : migration ANIS v2.0
\N	\N	22	2014-03-07	pm	t	
69	98	22	2014-03-07	am	f	HerMES : migration ANIS v2.0
70	98	22	2014-03-10	pm	f	correction catalogues DR2
55	98	22	2014-03-10	am	f	correction catalogues DR2
70	98	22	2014-03-11	pm	f	correction catalogues DR2
70	98	22	2014-03-11	am	f	correction catalogues DR2
57	92	31	2014-03-10	am	f	
57	92	31	2014-03-12	pm	f	
57	92	31	2014-03-13	pm	f	
57	92	31	2014-03-17	am	f	
\N	\N	15	2014-03-03	am	t	
\N	\N	15	2014-03-03	pm	t	
\N	\N	15	2014-03-04	am	t	
\N	\N	15	2014-03-04	pm	t	
\N	\N	15	2014-03-05	am	t	
\N	\N	15	2014-03-05	pm	t	
\N	\N	15	2014-03-06	am	t	
\N	\N	15	2014-03-06	pm	t	
\N	\N	15	2014-03-07	am	t	
\N	\N	15	2014-03-07	pm	t	
73	110	15	2014-03-10	am	f	accretion project
57	72	15	2014-03-10	pm	f	init scripts
57	115	15	2014-03-11	am	f	KALMAN
57	115	15	2014-03-11	pm	f	KALMAN
73	110	15	2014-03-12	am	f	accretion projects
73	110	15	2014-03-12	pm	f	accretion projects
73	110	15	2014-03-13	am	f	accretion projects
73	110	15	2014-03-13	pm	f	accretion projects
57	72	15	2014-03-14	am	f	init scripts
57	72	15	2014-03-14	pm	f	init scripts
57	72	15	2014-03-17	am	f	init scripts
57	72	15	2014-03-17	pm	f	init scripts
\N	\N	14	2014-03-03	am	t	
\N	\N	14	2014-03-03	pm	t	
\N	\N	14	2014-03-04	am	t	
\N	\N	14	2014-03-04	pm	t	
\N	\N	14	2014-03-05	am	t	
\N	\N	14	2014-03-05	pm	t	
\N	\N	14	2014-03-06	am	t	
\N	\N	14	2014-03-06	pm	t	
\N	\N	14	2014-03-07	am	t	
\N	\N	14	2014-03-07	pm	t	
59	84	14	2014-03-10	am	f	
67	133	14	2014-03-10	pm	f	Présentation nouveau post-doc
61	81	14	2014-03-11	am	f	Tests unitaires
61	81	14	2014-03-11	pm	f	Tests unitaires
56	81	14	2014-03-12	am	f	Config GIT + Jenkins
\N	\N	14	2014-03-12	pm	t	
56	81	14	2014-03-13	am	f	Config GIT + Jenkins
56	81	14	2014-03-13	pm	f	Config GIT + Jenkins
66	67	14	2014-03-14	am	f	Revue des actions
67	67	14	2014-03-14	pm	f	Exodat
66	67	14	2014-03-17	am	f	CR réunion + actions
63	89	5	2014-02-18	am	f	
63	89	5	2014-02-18	pm	f	
63	89	5	2014-02-19	am	f	
63	89	5	2014-02-19	pm	f	
63	89	5	2014-02-20	am	f	
63	89	5	2014-02-20	pm	f	
\N	\N	5	2014-02-21	am	t	
\N	\N	5	2014-02-21	pm	t	
63	89	5	2014-02-24	am	f	
63	89	5	2014-02-24	pm	f	
63	89	5	2014-02-25	am	f	
63	89	5	2014-02-25	pm	f	
63	89	5	2014-02-26	am	f	
63	89	5	2014-02-26	pm	f	
63	89	5	2014-02-27	am	f	
63	89	5	2014-02-27	pm	f	
\N	\N	5	2014-02-28	am	t	
\N	\N	5	2014-02-28	pm	t	
63	89	5	2014-03-03	am	f	
63	89	5	2014-03-03	pm	f	
63	89	5	2014-03-04	am	f	
63	89	5	2014-03-04	pm	f	
63	89	5	2014-03-05	am	f	
63	89	5	2014-03-05	pm	f	
63	89	5	2014-03-06	am	f	
63	89	5	2014-03-06	pm	f	
63	89	5	2014-03-07	am	f	
63	89	5	2014-03-07	pm	f	
63	89	5	2014-03-10	am	f	
63	89	5	2014-03-10	pm	f	
63	89	5	2014-03-11	am	f	
63	89	5	2014-03-11	pm	f	
63	89	5	2014-03-12	am	f	
63	89	5	2014-03-12	pm	f	
63	89	5	2014-03-13	am	f	
63	89	5	2014-03-13	pm	f	
63	89	5	2014-03-14	am	f	
63	89	5	2014-03-14	pm	f	
63	89	5	2014-03-17	am	f	
63	85	5	2014-03-17	pm	f	
63	89	5	2014-03-18	am	f	
63	89	5	2014-03-18	pm	f	
63	85	5	2014-03-19	am	f	
67	65	4	2014-02-04	am	f	Garage Days
67	65	4	2014-02-04	pm	f	Garage Days
55	65	4	2014-02-07	am	f	OUSPE analysis and links
55	65	4	2014-02-07	pm	f	OUSPE analysis and links
55	137	4	2014-02-10	am	f	Analyse PLATO man power
55	137	4	2014-02-10	pm	f	Analyse PLATO man power
66	89	4	2014-02-11	am	f	Recrutement CDD EUCLID
66	89	4	2014-02-11	pm	f	Recrutement CDD EUCLID
55	81	4	2014-02-12	am	f	Etat des lieux et futur
55	81	4	2014-02-12	pm	f	Etat des lieux et futur
\N	\N	4	2014-02-13	am	t	
\N	\N	4	2014-02-13	pm	t	
67	141	4	2014-02-14	am	f	
67	141	4	2014-02-14	pm	f	
66	85	4	2014-02-17	am	f	Gestion CDD et analyse jury
66	85	4	2014-02-17	pm	f	Gestion CDD et analyse jury
66	85	4	2014-02-18	am	f	Gestion CDD et analyse jury
66	85	4	2014-02-18	pm	f	Gestion CDD et analyse jury
55	65	4	2014-02-19	am	f	AGILE
55	105	4	2014-02-19	pm	f	Analyse prototype
\N	\N	4	2014-03-03	am	t	
\N	\N	4	2014-03-03	pm	t	
\N	\N	4	2014-03-04	am	t	
\N	\N	4	2014-03-04	pm	t	
\N	\N	4	2014-03-05	am	t	
\N	\N	4	2014-03-05	pm	t	
\N	\N	4	2014-03-06	am	t	
\N	\N	4	2014-03-06	pm	t	
\N	\N	4	2014-03-07	am	t	
\N	\N	4	2014-03-07	pm	t	
55	81	4	2014-02-20	am	f	Modification site web, analyze
55	81	4	2014-02-20	pm	f	Modification site web, analyze
\N	\N	4	2014-02-21	am	t	
55	81	4	2014-02-21	pm	f	Modification site web, analyze
55	81	4	2014-02-24	am	t	analyze
55	81	4	2014-02-24	pm	t	analyze
55	81	4	2014-02-25	am	f	analyze
55	81	4	2014-02-25	pm	f	analyze
55	81	4	2014-02-26	am	f	analyze
55	81	4	2014-02-26	pm	f	analyze Data Model
55	81	4	2014-02-27	am	f	analyze
55	72	4	2014-02-27	pm	f	Analyse besoins et préparation
55	81	4	2014-02-28	am	f	Analyse des flux
55	81	4	2014-02-28	pm	f	Analyse des flux
55	141	4	2014-03-10	am	f	Analyse data et besoins
55	81	4	2014-03-10	pm	f	Analyse des flux
55	81	4	2014-03-11	am	f	Analyse des flux
55	81	4	2014-03-11	pm	f	Analyse des flux
66	89	4	2014-03-12	am	f	Gestion CDDs
66	89	4	2014-03-12	pm	f	Gestion CDDs
55	134	4	2014-03-13	am	f	Analyse des besoins etestimation  man power
67	126	4	2014-03-13	pm	f	CS Pytheas
55	81	4	2014-03-14	am	f	Analyse des flux
66	89	4	2014-03-14	pm	f	reunion DIR-CeSAM
55	81	4	2014-03-17	am	f	Analyse des flux
55	81	4	2014-03-17	pm	f	Analyse des flux
58	81	4	2014-03-18	am	f	GEstion des livrables
58	81	4	2014-03-18	pm	f	GEstion des livrables
67	65	4	2014-03-19	am	f	IAL-Telecon
58	81	4	2014-03-19	pm	f	GEstion des livrables
55	68	14	2014-03-17	pm	f	Analyse UML
55	81	14	2014-03-18	am	f	Pipeline
55	81	14	2014-03-18	pm	f	Pipeline
67	81	14	2014-03-19	am	f	Telecon IAL
55	81	14	2014-03-19	pm	f	Pipeline
67	81	14	2014-03-20	am	f	Data model
55	68	14	2014-03-20	pm	f	Analyse UML
55	68	14	2014-03-21	am	f	Analyse UML
\N	\N	14	2014-03-21	pm	t	
57	110	15	2014-02-25	am	f	bulge
57	110	15	2014-02-25	pm	f	bulge
57	110	15	2014-02-26	am	f	bulge
57	110	15	2014-02-26	pm	f	bulge
57	110	15	2014-02-27	am	f	bulge
57	110	15	2014-02-27	pm	f	bulge
57	110	15	2014-02-28	am	f	bulge
57	110	15	2014-02-28	pm	f	bulge
57	115	15	2014-03-18	am	f	compass
57	115	15	2014-03-18	pm	f	compass
57	115	15	2014-03-19	am	f	compass
\N	\N	15	2014-03-19	pm	t	
57	115	15	2014-03-20	am	f	compass
57	115	15	2014-03-21	pm	f	compass
57	115	15	2014-03-24	am	f	compass
57	115	15	2014-03-24	pm	f	compass
57	115	15	2014-03-25	am	f	compass
57	115	15	2014-03-25	pm	f	compass
57	115	15	2014-03-26	am	f	compass
67	115	15	2014-04-01	pm	f	thomas + morgan discussions
72	110	15	2014-04-02	pm	f	accretion project
57	115	15	2014-04-03	am	f	performance studing
57	115	15	2014-04-03	pm	f	performance studing
55	65	4	2014-03-20	am	f	DAta Model
67	65	4	2014-03-20	pm	f	Meeting SGS
67	89	4	2014-03-21	am	f	SO5
66	89	4	2014-03-21	pm	f	Stagiaires CDDs
\N	\N	4	2014-03-24	am	t	
55	65	4	2014-03-24	pm	f	Analyse OUSPE
55	65	4	2014-03-25	am	f	Analyse OUSPE
55	65	4	2014-03-25	pm	f	Analyse OUSPE
55	65	4	2014-03-26	am	f	Analyse OUSPE
55	65	4	2014-03-26	pm	f	Analyse OUSPE
55	65	4	2014-03-27	am	f	Analyse OUSPE
59	84	4	2014-03-27	pm	f	GEstion passeport
55	65	4	2014-03-28	am	f	Analyse OUSPE
55	65	4	2014-03-28	pm	f	Analyse OUSPE
55	65	4	2014-03-31	am	f	Analyse OUSPE
55	65	4	2014-03-31	pm	f	Analyse OUSPE
66	89	4	2014-04-01	am	f	Stagiaires CDDs
55	65	4	2014-04-01	pm	f	Analyse OUSPE
55	65	4	2014-04-02	am	f	Analyse OUSPE
\N	\N	4	2014-04-02	pm	t	
66	89	4	2014-04-03	am	f	Stagiaires CDDs
55	65	4	2014-04-03	pm	f	Analyse OUSPE
55	65	4	2014-04-04	am	f	Analyse OUSPE
55	65	4	2014-04-04	pm	f	Analyse OUSPE
57	71	17	2014-01-23	am	f	
57	71	17	2014-01-23	pm	f	
57	71	17	2014-01-24	am	f	
57	71	17	2014-01-24	pm	f	
57	71	17	2014-01-27	am	f	
57	71	17	2014-01-27	pm	f	
57	71	17	2014-01-28	am	f	
57	71	17	2014-01-28	pm	f	
71	71	17	2014-01-29	am	f	
71	71	17	2014-01-29	pm	f	
57	71	17	2014-01-30	am	f	
57	71	17	2014-01-30	pm	f	
57	71	17	2014-01-31	am	f	
57	71	17	2014-01-31	pm	f	
57	71	17	2014-02-03	am	f	
57	71	17	2014-02-03	pm	f	
57	71	17	2014-02-04	am	f	
57	71	17	2014-02-04	pm	f	
57	71	17	2014-02-05	am	f	
57	71	17	2014-02-05	pm	f	
57	71	17	2014-02-06	am	f	
57	71	17	2014-02-06	pm	f	
57	71	17	2014-02-07	am	f	
57	71	17	2014-02-07	pm	f	
57	71	17	2014-02-10	am	f	
57	71	17	2014-02-10	pm	f	
57	71	17	2014-02-11	am	f	
57	71	17	2014-02-11	pm	f	
57	71	17	2014-02-12	am	f	
57	71	17	2014-02-12	pm	f	
57	71	17	2014-02-13	am	f	
57	71	17	2014-02-13	pm	f	
57	71	17	2014-02-14	am	f	
57	71	17	2014-02-14	pm	f	
57	71	17	2014-02-17	am	f	
57	71	17	2014-02-17	pm	f	
57	71	17	2014-02-18	am	f	
57	71	17	2014-02-18	pm	f	
57	71	17	2014-02-19	am	f	
57	71	17	2014-02-19	pm	f	
57	71	17	2014-02-20	am	f	
57	71	17	2014-02-20	pm	f	
57	71	17	2014-02-21	am	f	
63	71	17	2014-02-21	pm	f	
63	71	17	2014-02-24	am	f	
63	71	17	2014-02-24	pm	f	
63	71	17	2014-02-25	am	f	
57	71	17	2014-02-25	pm	f	
57	71	17	2014-02-26	am	f	
57	71	17	2014-02-26	pm	f	
57	71	17	2014-02-27	am	f	
57	71	17	2014-02-27	pm	f	
57	71	17	2014-02-28	am	f	
57	71	17	2014-02-28	pm	f	
57	71	17	2014-03-03	am	f	
57	71	17	2014-03-03	pm	f	
57	71	17	2014-03-04	am	f	
57	71	17	2014-03-04	pm	f	
57	71	17	2014-03-05	am	f	
57	71	17	2014-03-05	pm	f	
57	71	17	2014-03-06	am	f	
57	71	17	2014-03-06	pm	f	
57	71	17	2014-03-07	am	f	
57	71	17	2014-03-07	pm	f	
57	71	17	2014-03-10	am	f	
57	71	17	2014-03-10	pm	f	
57	71	17	2014-03-11	am	f	
57	71	17	2014-03-11	pm	f	
57	71	17	2014-03-12	am	f	
57	71	17	2014-03-12	pm	f	
71	71	17	2014-03-13	am	f	
71	71	17	2014-03-13	pm	f	
71	71	17	2014-03-14	am	f	
71	71	17	2014-03-14	pm	f	
57	71	17	2014-03-17	am	f	
57	71	17	2014-03-17	pm	f	
57	71	17	2014-03-18	am	f	
57	71	17	2014-03-18	pm	f	
57	72	15	2014-03-21	am	f	osiris scripts
57	72	15	2014-03-26	pm	f	osiris scripts
57	72	15	2014-03-27	am	f	osiris scripts
57	72	15	2014-03-28	am	f	osiris scripts
57	72	15	2014-03-28	pm	f	osiris scripts
57	72	15	2014-03-31	am	f	osiris scripts
57	72	15	2014-03-31	pm	f	osiris scripts
57	72	15	2014-04-01	am	f	scripts 
57	72	15	2014-04-02	am	f	rendering prototype
57	71	17	2014-03-19	am	f	
57	71	17	2014-03-19	pm	f	
57	71	17	2014-03-20	am	f	
57	71	17	2014-03-20	pm	f	
57	71	17	2014-03-21	am	f	
57	71	17	2014-03-21	pm	f	
57	71	17	2014-03-24	am	f	
57	71	17	2014-03-24	pm	f	
57	71	17	2014-03-25	am	f	
57	71	17	2014-03-25	pm	f	
63	71	17	2014-03-26	am	f	
63	71	17	2014-03-26	pm	f	
57	71	17	2014-03-27	am	f	
57	71	17	2014-03-27	pm	f	
57	71	17	2014-03-28	am	f	
57	71	17	2014-03-28	pm	f	
57	71	17	2014-03-31	am	f	
57	71	17	2014-03-31	pm	f	
57	71	17	2014-04-01	am	f	
57	71	17	2014-04-01	pm	f	
71	71	17	2014-04-02	am	f	
71	71	17	2014-04-02	pm	f	
71	71	17	2014-04-03	am	f	
71	71	17	2014-04-03	pm	f	
57	71	17	2014-04-04	am	f	
57	71	17	2014-04-04	pm	f	
56	102	20	2014-02-05	am	f	Deploiement VUDS
56	102	20	2014-02-05	pm	f	Deploiement VUDS
57	131	20	2014-02-06	am	f	Correction gestion images
57	131	20	2014-02-06	pm	f	Correction gestion images
57	131	20	2014-02-07	am	f	Affichage spectres jqplot
57	131	20	2014-02-07	pm	f	Affichage spectres jqplot
57	131	20	2014-02-10	am	f	Affichage spectres jqplot
57	131	20	2014-02-10	pm	f	Affichage spectres jqplot
57	131	20	2014-02-11	am	f	Gestion des spectres
57	131	20	2014-02-11	pm	f	Gestion des spectres
57	131	20	2014-02-12	am	f	Gestion des spectres
57	131	20	2014-02-12	pm	f	Gestion des spectres
57	131	20	2014-02-13	am	f	Gestion des spectres
57	131	20	2014-02-13	pm	f	Gestion des spectres
63	89	20	2014-02-14	am	f	Installation des serveurs virtuels des SI
63	89	20	2014-02-14	pm	f	Installation des serveurs virtuels des SI
63	89	20	2014-02-17	am	f	Installation des serveurs virtuels des SI
63	89	20	2014-02-17	pm	f	Installation des serveurs virtuels des SI
57	131	20	2014-02-18	am	f	Export
57	131	20	2014-02-18	pm	f	Export
57	131	20	2014-02-19	am	f	Export
57	131	20	2014-02-19	pm	f	Export
57	66	20	2014-02-20	am	f	hstcosmos ANIS
57	66	20	2014-02-20	pm	f	hstcosmos ANIS
70	66	20	2014-02-21	am	f	hstcosmos ANIS
56	66	20	2014-02-21	pm	f	hstcosmos ANIS
\N	\N	20	2014-02-24	am	t	
\N	\N	20	2014-02-24	pm	t	
\N	\N	20	2014-02-25	am	t	
\N	\N	20	2014-02-25	pm	t	
\N	\N	20	2014-02-26	am	t	
\N	\N	20	2014-02-26	pm	t	
\N	\N	20	2014-02-27	am	t	
\N	\N	20	2014-02-27	pm	t	
\N	\N	20	2014-02-28	am	t	
\N	\N	20	2014-02-28	pm	t	
57	102	20	2014-03-03	am	f	Correction des spectres
57	102	20	2014-03-03	pm	f	Correction des spectres
57	102	20	2014-03-04	am	f	Correction des spectres
57	102	20	2014-03-04	pm	f	Correction des spectres
57	102	20	2014-03-05	am	f	Correction des spectres
57	102	20	2014-03-05	pm	f	Correction des spectres
57	131	20	2014-03-06	am	f	FileController
57	131	20	2014-03-06	pm	f	FileController
57	131	20	2014-03-07	am	f	FileController
57	131	20	2014-03-07	pm	f	FileController
70	66	20	2014-03-10	am	f	XMM-LSS
70	66	20	2014-03-10	pm	f	XMM-LSS
70	66	20	2014-03-11	am	f	XMM-LSS
70	66	20	2014-03-11	pm	f	XMM-LSS
57	66	20	2014-03-12	am	f	XMM-LSS
57	66	20	2014-03-12	pm	f	XMM-LSS
71	66	20	2014-03-13	am	f	Transfert des SI de cosmo vers ANIS V2.0
71	66	20	2014-03-13	pm	f	Transfert des SI de cosmo vers ANIS V2.0
71	66	20	2014-03-14	am	f	Transfert des SI de cosmo vers ANIS V2.0
71	66	20	2014-03-14	pm	f	Transfert des SI de cosmo vers ANIS V2.0
56	66	20	2014-03-17	am	f	Déploiement XMM-LSS
56	66	20	2014-03-17	pm	f	Déploiement XMM-LSS
\N	\N	20	2014-03-18	am	t	
\N	\N	20	2014-03-18	pm	t	
59	84	20	2014-03-19	am	f	Dossier VAE
59	84	20	2014-03-19	pm	f	Dossier VAE
57	66	20	2014-03-20	am	f	Correction decoupage d'image
57	66	20	2014-03-20	pm	f	Correction decoupage d'image
59	84	20	2014-03-21	am	f	Dossier VAE
59	84	20	2014-03-21	pm	f	Dossier VAE
59	84	20	2014-03-24	am	f	Presentation VAE
59	84	20	2014-03-24	pm	f	Presentation VAE
59	84	20	2014-03-25	am	f	Presentation VAE
59	84	20	2014-03-25	pm	f	Presentation VAE
59	84	20	2014-03-26	am	f	Presentation VAE
59	84	20	2014-03-26	pm	f	Presentation VAE
59	84	20	2014-03-27	am	f	Presentation VAE
59	84	20	2014-03-27	pm	f	Presentation VAE
59	84	20	2014-03-28	am	f	VAE
59	84	20	2014-03-28	pm	f	VAE
59	84	20	2014-03-31	am	f	Dossiers concours
59	84	20	2014-03-31	pm	f	Dossiers concours
59	84	20	2014-04-01	am	f	Dossiers concours
59	84	20	2014-04-01	pm	f	Dossiers concours
59	84	20	2014-04-02	am	f	Dossiers concours
59	84	20	2014-04-02	pm	f	Dossiers concours
\N	\N	20	2014-04-03	am	t	
\N	\N	20	2014-04-03	pm	t	
59	84	20	2014-04-04	am	f	Dossiers concours
59	84	20	2014-04-04	pm	f	Dossiers concours
57	115	15	2014-04-04	am	f	performance tests
57	115	15	2014-04-04	pm	f	performance tests
57	105	33	2014-04-07	pm	f	
63	89	5	2014-03-19	pm	f	
63	89	5	2014-03-20	am	f	
63	89	5	2014-03-20	pm	f	
63	89	5	2014-03-21	am	f	
63	89	5	2014-03-21	pm	f	
\N	\N	5	2014-03-24	am	t	
\N	\N	5	2014-03-24	pm	t	
\N	\N	5	2014-03-25	am	t	
\N	\N	5	2014-03-25	pm	t	
\N	\N	5	2014-03-26	am	t	
\N	\N	5	2014-03-26	pm	t	
\N	\N	5	2014-03-27	am	t	
\N	\N	5	2014-03-27	pm	t	
\N	\N	5	2014-03-28	am	t	
\N	\N	5	2014-03-28	pm	t	
63	89	5	2014-03-31	am	f	
63	89	5	2014-03-31	pm	f	
63	89	5	2014-04-01	am	f	
63	89	5	2014-04-01	pm	f	
56	89	5	2014-04-02	am	f	
63	116	5	2014-04-02	pm	f	
63	66	5	2014-04-03	am	f	
63	89	5	2014-04-03	pm	f	
63	116	5	2014-04-04	am	f	
63	66	5	2014-04-04	pm	f	
63	116	5	2014-04-07	am	f	
63	89	5	2014-04-07	pm	f	
66	81	14	2014-03-24	am	f	Definition du TFE de Francois Gilbert
59	133	14	2014-03-24	pm	f	techniques d'extraction photometrique avec Olivier Demangeon
55	81	14	2014-03-25	am	f	Serialisation JSON
67	81	14	2014-03-25	pm	f	Preparation Teleconf SGS
67	81	14	2014-03-26	am	f	Preparation Teleconf SGS
67	81	14	2014-03-26	pm	f	Teleconf SGS
55	81	14	2014-03-27	am	f	Serialisation JSON
55	81	14	2014-03-27	pm	f	Specification TFE de Francois Gilbert
55	81	14	2014-03-28	am	f	Specification TFE de Francois Gilbert
55	81	14	2014-03-28	pm	f	Specification TFE de Francois Gilbert
66	81	14	2014-03-31	am	f	Preparation TFE Francois Gilbert
67	84	14	2014-03-31	pm	f	Fabry Perno
55	81	14	2014-04-01	am	f	pipeline
67	81	14	2014-04-01	pm	f	Sprint review
55	81	14	2014-04-02	am	f	pipeline
55	81	14	2014-04-02	pm	f	pipeline
55	81	14	2014-04-03	am	f	pipeline
55	81	14	2014-04-03	pm	f	pipeline
55	81	14	2014-04-04	am	f	pipeline
66	81	14	2014-04-04	pm	f	Encadrement stagiaire
57	70	34	2013-11-04	am	f	Premier briefing avec l'équipe (après midi) concernant l'objet du CDD
57	70	34	2013-11-04	pm	f	Lecture document sur Malt90, premier balayage des notations utilisées en astronomie.
57	70	34	2013-11-05	am	f	Rencontre avec Jérémy (cartes de densité), explication sur les formats utilisés (FITS).
57	70	34	2013-11-05	pm	f	Premières manipulations de fichiers FITS avec PyFits, lecture de documentation sur la librairie et premières manipulations sommaires.
57	70	34	2013-11-06	am	f	Finalisation d'un premier programme de test avec PyFits : lecture des données d'un fichier FITS pour générer une image PNG avec les valeurs prélevées.
57	70	34	2013-11-06	pm	f	Première lecture du code existant.
57	70	34	2013-11-07	am	f	Exécution des programmes existants, récupération des libraires manquantes (et utilisation d'Eclipse).
57	70	34	2013-11-07	pm	f	Récupération de données supplémentaires sur le compte de Guillaume.
57	70	34	2013-11-08	am	f	Réunion avec Delphine : explications plus précises sur le circuit de traitement des fichiers FITS, récupération des sources IDL.
57	70	34	2013-11-08	pm	f	Lecture de documents sur IDL, tentative de compréhension du code.
\N	\N	34	2013-11-11	am	t	
\N	\N	34	2013-11-11	pm	t	
57	70	34	2013-11-12	am	f	Lecture d'une introduction à IDL, tests et manipulations.
57	70	34	2013-11-12	pm	f	Retour sur le code existant, meilleur compréhension de leur finalité et de l'enchainement des traitements.
57	70	34	2013-11-13	am	f	Documentation du Wiki Herschel, explications concernant la chaine de traitement et les fichiers générés/utilisés.
57	70	34	2013-11-13	pm	f	Documentation du Wiki Herschel, explications concernant la chaine de traitement et les fichiers générés/utilisés.
57	70	34	2013-11-14	am	f	Récupération de fichiers de données pour tester le rebin des maps (éparpillées sur une autre machine).
57	70	34	2013-11-14	pm	f	Récupération de fichiers de données pour tester le rebin des maps (éparpillées sur une autre machine).
57	70	34	2013-11-15	am	f	Compilation et exécution du rebin réussies, mais besoin de modifier get_filenames.pro pour que les données renvoyées concernant les cartes soient juste.
57	70	34	2013-11-15	pm	f	Compilation et exécution du rebin réussies, mais besoin de modifier get_filenames.pro pour que les données renvoyées concernant les cartes soient juste.
57	70	34	2013-11-18	am	f	Rencontre avec Loren (qui a développé les programmes en IDL).
57	70	34	2013-11-18	pm	f	Ajout des informations sur les programmes IDL au wiki.
57	70	34	2013-11-19	am	f	Présentation de Hipe par Loren, explications supplémentaires concernant les spectres.
57	70	34	2013-11-19	pm	f	Rencontre avec Jérémy, mise au point sur les paramètres nécessaires à l'interprétation des fichiers FITS.
57	70	34	2013-11-20	am	f	Tentative d’exécution du pipeline avec Hipe : utilisation mémoire trop grande.
57	70	34	2013-11-20	pm	f	Installation de Hipe sur ma propre machine, et configuration d'IDL de façon à pouvoir se passer de la machine merlin. 
57	70	34	2013-11-21	am	f	Récupération de tempmap.pro : besoin d'une nouvelle version de sed_fit (err_norm) pas dans les arguments) désactivation de la génération de la carte d'erreur de colonne de densité pour l'instant, résolution des librairies manquantes.
57	70	34	2013-11-21	pm	f	Mise à jour des paramètres des sondes et exécution de script sur les données de Jeremy.
57	70	34	2013-11-22	am	f	Installation de Montage pour manipuler les images FITS avec bash (besoin pour script IDL).
57	70	34	2013-11-22	pm	f	Correction des paramètres des sondes : map de température générée plus cohérente.
57	70	34	2013-11-25	am	f	Mise à jour du Wiki Herschel concernant l'utilisation de tempmap.pro
57	70	34	2013-11-25	pm	f	Lecture de tempmap.pro plus en détail pour comprendre les étapes du traitement et la manipulation des différentes matrices.
57	70	34	2013-11-26	am	f	Utilisation de WebPy en vue de pouvoir appeler le calcul de cartes de température (et colonne de densité) via une interface web (formulaire).
57	70	34	2013-11-26	pm	f	Tentative d'installation de PyIDL, problème de résolution de certaines librairies lors du build.
57	70	34	2013-11-27	am	f	Résolution de certains appels de librairie pour PyIDL, mais libtermcap manquante. Récupération d'astropy (se substitue à PyFits). 
57	70	34	2013-11-27	pm	f	Schématisation de l'interface de l'outil web. XML envisagé pour stocker les quelques informations propres aux instruments.
57	70	34	2013-11-28	am	f	Ajout d'arguments optionnels supplémentaires dans les scripts IDL afin d'outrepasser au besoin les valeurs déterminées par get_filenames.
57	70	34	2013-11-28	pm	f	Ajout d'arguments optionnels supplémentaires dans les scripts IDL afin d'outrepasser au besoin les valeurs déterminées par get_filenames.
57	70	34	2013-11-29	am	f	Complétion du Wiki concernant les mises à jour de la veille.
57	70	34	2013-11-29	pm	f	Complétion du Wiki concernant les mises à jour de la veille.
57	70	34	2013-12-02	am	f	Travail sur l'interface web pour Tempmap.
57	70	34	2013-12-02	pm	f	Création du formulaire d'upload des fichiers et utilisation de JQuery.
57	70	34	2013-12-03	am	f	Récupération des fichiers FITS par upload.
57	70	34	2013-12-03	pm	f	Récupération des fichiers FITS par upload.
57	70	34	2013-12-04	am	f	Lecture et récupération des paramètres par parsing des noms de fichiers FITS et par lecture du header (puis affichage en HTML).
57	70	34	2013-12-04	pm	f	Récupération et affichage des paramètres relatifs aux sondes dans un fichier XML.
57	70	34	2013-12-05	am	f	Création d'un controller pour la réception des paramètres reçus par XML.
57	70	34	2013-12-05	pm	f	Création d'un controller pour la réception des paramètres reçus par XML.
57	70	34	2013-12-06	am	f	Traitement et parsing des paramètres reçus depuis le formulaire HTML, formatage vers les bons types numériques.
57	70	34	2013-12-06	pm	f	Traitement et parsing des paramètres reçus depuis le formulaire HTML, formatage vers les bons types numériques.
57	70	34	2013-12-09	am	f	Exécution des scripts IDL par python (avec pIDLy) à partir des valeurs récupérées du formulaire HTML.
57	70	34	2013-12-09	pm	f	Exécution des scripts IDL par python (avec pIDLy) à partir des valeurs récupérées du formulaire HTML.
57	70	34	2013-12-10	am	f	Début écriture fiche de style CSS pour Tempmap.
57	70	34	2013-12-10	pm	f	Gros briefing sur getsources par Jérémy.
57	70	34	2013-12-11	am	f	Continuation préparation getsources (fichiers cfg, masks etc...).
57	70	34	2013-12-11	pm	f	Continuation préparation getsources (fichiers cfg, masks etc...).
57	70	34	2013-12-12	am	f	Préparation getsources pour RCW79, commandes prepareobs et mask personnalisés.
57	70	34	2013-12-12	pm	f	Préparation getsources pour RCW79, commandes prepareobs et mask personnalisés.
57	70	34	2013-12-13	am	f	Récupération de meilleures cartes modifiées (161 et 151), plus d'erreur de la part de getsources, mais pixel size mauvaise de toute façon (attendre nouveau lot de cartes).
57	70	34	2013-12-13	pm	f	Récupération de meilleures cartes modifiées (161 et 151), plus d'erreur de la part de getsources, mais pixel size mauvaise de toute façon (attendre nouveau lot de cartes).
57	70	34	2013-12-16	am	f	Utilisation de sessions pour l'interface web Herschel (tempmap) : chaque traitement lancé a son propre répertoire (horodaté).
57	70	34	2013-12-16	pm	f	Utilisation d'un thread pour l’exécution d'IDL (non bloquant pour répondre à la requête http).
57	70	34	2013-12-17	am	f	Amélioration du controller : possibilité d'ajouter des fichiers pendant la même session, contrôle sur les fichiers envoyés.
57	70	34	2013-12-17	pm	f	Amélioration du controller : possibilité d'ajouter des fichiers pendant la même session, contrôle sur les fichiers envoyés.
57	70	34	2013-12-18	am	f	Écriture service de manipulation du fichier XML des instruments.
57	70	34	2013-12-18	pm	f	Création d'un controller pour gérer les instruments, ainsi que d'une vue associée.
57	70	34	2013-12-19	am	f	Enrichissement de la vue dédiée à la manipulation des instruments.
57	70	34	2013-12-19	pm	f	Implémentation plus complète du controller et du service : update de tous les paramètres des instruments.
57	70	34	2013-12-20	am	f	Possibilité d'enlever des instruments (et des longueurs d'ondes sur certains instruments). Création d'un dictionnaire pour les thread idl, afin de pouvoir y accéder après lancement.
57	70	34	2013-12-20	pm	f	Création d'une vue pour la récupération des fichiers de sortie.
57	70	34	2013-12-23	am	t	
57	70	34	2013-12-23	pm	t	
57	70	34	2013-12-24	am	t	
57	70	34	2013-12-24	pm	t	
57	70	34	2013-12-25	am	t	
57	70	34	2013-12-25	pm	t	
57	70	34	2013-12-26	am	t	
57	70	34	2013-12-26	pm	t	
57	70	34	2013-12-27	am	t	
57	70	34	2013-12-27	pm	t	
57	70	34	2013-12-30	am	t	
57	70	34	2013-12-30	pm	t	
57	70	34	2013-12-31	am	t	
57	70	34	2013-12-31	pm	t	
57	70	34	2014-01-01	am	t	
57	70	34	2014-01-01	pm	t	
57	70	34	2014-01-02	am	f	Listing des threads en cours d’exécution, utilisation du process tag comme lien vers le status du thread.
57	70	34	2014-01-02	pm	f	Listing des threads en cours d’exécution, utilisation du process tag comme lien vers le status du thread.
57	70	34	2014-01-03	am	f	Amélioration mise en forme CSS.
57	70	34	2014-01-03	pm	f	Amélioration mise en forme CSS.
57	70	34	2014-01-06	am	f	Récupération scripts Python de David, recherche du script pour le fitting de cube de spectres.
57	70	34	2014-01-06	pm	f	Récupération scripts Python de David, recherche du script pour le fitting de cube de spectres.
57	70	34	2014-01-07	am	f	Correction bug tempmap : un seul thread pouvait s’exécuter à la fois.
57	70	34	2014-01-07	pm	f	Suppression des fichiers inutiles pour getsources avec NGC6357.
57	70	34	2014-01-08	am	f	Réunion Herschel (Matin). Déplacement des résultats de fitting des cubes (David) d'Alcalin vers Herschel.
57	70	34	2014-01-08	pm	f	Réunion Césam (Après-midi) Début implémentation système de log pour tempmap.
57	70	34	2014-01-09	am	f	Implémentation système de log pour tempmap.
57	70	34	2014-01-09	pm	f	Implémentation système de log pour tempmap.
57	70	34	2014-01-10	am	f	Intégration des dépendances IDL dans l'application python tempmap.
57	70	34	2014-01-10	pm	f	Intégration des dépendances IDL dans l'application python tempmap.
57	70	34	2014-01-13	am	f	Récupération de cube explorer : application faite en HTML, Javascript et Java (applet).
57	70	34	2014-01-13	pm	f	Problème d'autorisation avec l'applet, en dépit de la création d'un .java.policy dans le home.
57	70	34	2014-01-14	am	f	Préparation getsources pour nouvelles cartes RCW79 (et tests NGC6357).
57	70	34	2014-01-14	pm	f	Traitements getsources sur RCW79 lancées pour 100, 160, 161, 250, 251.
57	70	34	2014-01-15	am	f	Packaging tempmap (Manifest).
57	70	34	2014-01-15	pm	f	Lecture partie du rapport de David (concernant MALT90 et le fitting de gaussiennes).
57	70	34	2014-01-16	am	f	Lecture plus complète du rapport de David.
57	70	34	2014-01-16	pm	f	Compréhension du workflow, mise en correspondance des étapes du workflow avec les scripts effectivement présents.
57	70	34	2014-01-17	am	f	Exécution de scripts du workflow plot de spectres.
57	70	34	2014-01-17	pm	f	Exécution de scripts du workflow plot de spectres.
57	70	34	2014-01-20	am	f	Identification des bons fichiers pour le fitting (toujours en relation avec le workflow). Fonction de fit complexe.
57	70	34	2014-01-20	pm	f	Identification des bons fichiers pour le fitting (toujours en relation avec le workflow). Fonction de fit complexe.
57	70	34	2014-01-21	am	f	Lecture et ajout de commentaires dans la fonction de fitting. Fonction assez lourde à lire.
57	70	34	2014-01-21	pm	f	Lecture et ajout de commentaires dans la fonction de fitting. Fonction assez lourde à lire.
57	70	34	2014-01-22	am	f	Fin lecture et ajout de commentaires fonction de fitting. Le formatage des données et les changements de mise en forme des conteneurs expliquent la lourdeur de la fonction (et ralentit surement le traitement).
57	70	34	2014-01-22	pm	f	Fin lecture et ajout de commentaires fonction de fitting. Le formatage des données et les changements de mise en forme des conteneurs expliquent la lourdeur de la fonction (et ralentit surement le traitement).
57	70	34	2014-01-23	am	f	Lecture documentation sur SciPy et Numpy.
57	70	34	2014-01-23	pm	f	Lecture documentation sur SciPy et Numpy.
57	70	34	2014-01-24	am	f	Récupération spectres NGC6334 pour test.
57	70	34	2014-01-24	pm	f	Expérimentation avec le plot de SciPy.
57	70	34	2014-01-27	am	f	Utilisation du plot et de numpy. Implémentation d'un filtre passe-bas (par moyenne).
57	70	34	2014-01-27	pm	f	Convolution d'un spectre marqué au 13co (region manash), en utilisant un profil type pour cette molécule.
57	70	34	2014-01-28	am	f	Récupération des données NGC6357.
57	70	34	2014-01-28	pm	f	Implémentation d'une création de gaussienne avec l'échantillonnage voulu.
57	70	34	2014-01-29	am	f	Implémentation d'une fonction de génération de profils multi-gaussiens.
57	70	34	2014-01-29	pm	f	Implémentation d'une fonction de génération de profils multi-gaussiens.
57	70	34	2014-01-30	am	f	getsources sur NGC6357 : Préparation du dossier Extract et correction header des masks.
57	70	34	2014-01-30	pm	f	getsources sur NGC6357 : Préparation du dossier Extract et correction header des masks.
57	70	34	2014-01-31	am	f	(matin) Manipulation getsources.
57	70	34	2014-01-31	pm	t	
57	70	34	2014-02-03	am	f	Discussion avec Delphine concernant l'analyse spectrale. Correction de bug sur la suppression d'instrument dans tempmap.
57	70	34	2014-02-03	pm	f	Manipulations prepareobs avec Jeremy (remplacement du script prepareobs par celui de sasha). Ajout de commentaires dans le script de cross corrélation.
57	70	34	2014-02-04	am	f	Manipulation getsources avec Jeremy.
57	70	34	2014-02-04	pm	f	Séparation des appels aux fonction des plot en  Analyse spectrale dans une fonction à part pour rendre la génération des graphiques facultative (et accélérer le traitement en la désactivant).
57	70	34	2014-02-05	am	f	Lancement tests getsources sur NGC6357 avec carte à 0850nm.
57	70	34	2014-02-05	pm	f	Implémentation création de cubes de vélocité et de température (fits) pour les raies trouvées.
57	70	34	2014-03-27	pm	f	Lecture documents algorithme de Hough.
57	70	34	2014-02-06	am	f	Lancement nouvelle session getsources sur NGC6357. Optimisation localisation de raies dans les spectres.
57	70	34	2014-02-06	pm	f	Utilisation de la cross-corrélation normalisée, seuillage en fonction du score. Ajout de commentaires docstring.
57	70	34	2014-02-07	am	f	Utilisation de sphinx dans spectrum_correlation et tempmap.
57	70	34	2014-02-07	pm	f	Ne prends pas en compte les docstrings intra module dans tempmap.
57	70	34	2014-02-10	am	f	Nettoyage Extract NGC6357 (getsources). Génération de documentation dans Tempmap fonctionnelle.
57	70	34	2014-02-10	pm	f	Ajout de commentaires docstring dans Tempmap. Premier commit de Tempmap dans le repository svn d'Herschel.
57	70	34	2014-02-11	am	f	Gestion des dépendances dans setuptools pour tempmap.
57	70	34	2014-02-11	pm	f	Cross-corrélation sur du hcop.
57	70	34	2014-02-12	am	f	Changement nomenclature figures svg.
57	70	34	2014-02-12	pm	f	Changement nomenclature figures svg.
57	70	34	2014-02-13	am	f	Test getsources sur ngc6357.
57	70	34	2014-02-13	pm	f	Test getsources sur ngc6357.
57	70	34	2014-02-14	am	f	Écriture vélocité des raies dans des fichiers texte plutôt que dans des fichiers fits.
57	70	34	2014-02-14	pm	f	Écriture vélocité des raies dans des fichiers texte plutôt que dans des fichiers fits.
57	70	34	2014-02-17	am	f	Corrections bugs sur tempmap (gestion des fichiers FITS).
57	70	34	2014-02-17	pm	f	Corrections bugs sur tempmap (gestion des fichiers FITS).
57	70	34	2014-02-18	am	f	Début implémentation fonctionnalité de récupération paramètres d'instruments en asynchrone.
57	70	34	2014-02-18	pm	f	Tests Prepareobs.
57	70	34	2014-02-19	am	f	Implémentation récupération de paramètres d'instruments en asynchrone.
57	70	34	2014-02-19	pm	f	Meilleur gestion des fichiers FITS dont on extrait moins de paramètres.
57	70	34	2014-02-20	am	f	Ajout réglage bg_percent dans tempmap.
57	70	34	2014-02-20	pm	f	Détection des maximum locaux dans correlate_spectrum sur le produit de corrélation. Édition de mask pour getsources sur NGC6334.
57	70	34	2014-02-21	am	f	Affinage détection des maximum locaux dans correlate_spectrum sur le produit de corrélation.
57	70	34	2014-02-21	pm	f	Préparation getsources NGC6334.
57	70	34	2014-02-24	am	f	Lecture introduction Django (python).
57	70	34	2014-02-24	pm	f	Lecture introduction Django (python).
57	70	34	2014-02-25	am	f	Partie 1 tutoriel Django
57	70	34	2014-02-25	pm	f	Manipulations getsources sur NGC6357.
57	70	34	2014-02-26	am	f	Partie 2 tutoriel Django.
57	70	34	2014-02-26	pm	f	Partie 2 tutoriel Django.
57	70	34	2014-02-27	am	f	Manipulations getsources sur NGC6357.
57	70	34	2014-02-27	pm	f	Manipulations getsources sur NGC6357.
57	70	34	2014-02-28	am	f	Manipulations getsources sur NGC6357.
57	70	34	2014-02-28	pm	f	Manipulations getsources sur NGC6357.
57	70	34	2014-03-03	am	f	Implémentation utilisation XML pour l'analyse spectrale.
57	70	34	2014-03-03	pm	f	Implémentation utilisation XML pour l'analyse spectrale.
57	70	34	2014-03-04	am	f	Implémentation utilisation XML pour l'analyse spectrale.
57	70	34	2014-03-04	pm	f	Implémentation utilisation XML pour l'analyse spectrale.
57	70	34	2014-03-05	am	f	Lancement tests getsources sur NGC6357 avec carte à 0850nm.
57	70	34	2014-03-05	pm	f	Compréhension processus de beaming des cubes.
57	71	23	2013-10-08	am	f	
57	70	34	2014-03-06	am	f	ppel beaming des cubes directement dans corrélation spectrum.
57	70	34	2014-03-06	pm	f	ppel beaming des cubes directement dans corrélation spectrum.
57	70	34	2014-03-07	am	f	Préparations Extract getsources sur NGC6357.
57	70	34	2014-03-07	pm	f	Reprise code beaming des cubes (analyse spectrale), fuite mémoire à l’exécution.
57	70	34	2014-03-10	am	f	Optimisation Beaming des cubes : utilisation appropriée de la fonction de convolution dans SciPy.
57	70	34	2014-03-10	pm	f	Optimisation Beaming des cubes : utilisation appropriée de la fonction de convolution dans SciPy.
57	70	34	2014-03-11	am	f	Manipulations getsources sur NGC6334.
57	70	34	2014-03-11	pm	f	Manipulations getsources sur NGC6334.
57	70	34	2014-03-12	am	f	Interfaçage du script de cross-corrélation pour être appelé en ligne de commande.
57	70	34	2014-03-12	pm	f	Interfaçage du script de cross-corrélation pour être appelé en ligne de commande.
57	70	34	2014-03-13	am	f	Ajout d'options pour le script de cross-corrélation : beaming facultatif, radius paramétrable et possibilité de forcer l'override de fichiers existants.
57	70	34	2014-03-13	pm	f	Ajout d'options pour le script de cross-corrélation : beaming facultatif, radius paramétrable et possibilité de forcer l'override de fichiers existants.
57	70	34	2014-03-14	am	f	Manipulations getsources avec RCW79.
57	70	34	2014-03-14	pm	f	Manipulations getsources avec RCW79.
57	70	34	2014-03-17	am	f	Manipulation getsources sur RCW79.
57	70	34	2014-03-17	pm	f	Manipulation getsources sur RCW79.
57	70	34	2014-03-18	am	f	Manipulation getsources sur RCW79.
57	70	34	2014-03-18	pm	f	Mise en forme spectrum_correlation.
57	70	34	2014-03-19	am	f	Manipulation getsources.
57	70	34	2014-03-19	pm	f	Réunion avec Annie et Christian.
57	70	34	2014-03-20	am	f	Implémentation fonction suppression de threads terminés dans Tempmap.
57	70	34	2014-03-20	pm	f	Ajout explications Utilisation et Exécution tempmap sur le wiki.
57	70	34	2014-03-21	am	f	Complétion du wiki d'explication concernant  Tempmap, test de lancement de l'application sur herschel, dépendances résolues.
57	70	34	2014-03-21	pm	f	Complétion du wiki d'explication concernant  Tempmap, test de lancement de l'application sur herschel, dépendances résolues.
57	70	34	2014-03-24	am	f	Manipulations getsources.
57	70	34	2014-03-24	pm	f	Lecture « The Milky Way Project First Data Release: a bubblier Galactic disc ».
57	70	34	2014-03-25	am	f	Installation modules manquants chez Delphine, tests spectrum_correlation.
57	70	34	2014-03-25	pm	f	Installation modules manquants chez Delphine, tests spectrum_correlation.
57	70	34	2014-03-26	am	f	Corrections erreurs spectrum_correlation, ajout des labels lors du plot.
57	70	34	2014-03-26	pm	f	Corrections erreurs spectrum_correlation, ajout des labels lors du plot.
57	70	34	2014-03-27	am	f	Lecture documents algorithme de Hough.
57	70	34	2014-03-28	am	f	Tests python scipy lecture d'images.
57	70	34	2014-03-28	pm	f	Tests python scipy lecture d'images.
57	70	34	2014-03-31	am	f	Déploiement Tempmap sur Herschel, modification du traitement XML pour être compatible en Python 2.6
57	70	34	2014-03-31	pm	f	Déploiement Tempmap sur Herschel, modification du traitement XML pour être compatible en Python 2.6
57	70	34	2014-04-01	am	f	Installation Cython et Scikit-Image.
57	70	34	2014-04-01	pm	f	Test Hough circulaire.
57	70	34	2014-04-02	am	f	Correction bug TempMap sur Herschel : librairies Montage v4 pas compilées contre la bonne version de glibc.
57	70	34	2014-04-02	pm	f	Correction bug TempMap sur Herschel : librairies Montage v4 pas compilées contre la bonne version de glibc.
57	70	34	2014-04-03	am	f	Tests filtrage sur sondage galactique G342@70m, sobel et hough, besoin de resserrer l'histogramme Manipulation getsources (NGC6334).
57	70	34	2014-04-03	pm	f	Tests filtrage sur sondage galactique G342@70m, sobel et hough, besoin de resserrer l'histogramme Manipulation getsources (NGC6334).
57	70	34	2014-04-04	am	f	Tests filtrage sur sondage galactique G342@70m
57	70	34	2014-04-04	pm	f	Tests filtrage sur sondage galactique G342@70m
57	131	19	2014-02-04	am	f	Developpement V2
57	131	19	2014-02-04	pm	f	Developpement V2
57	131	19	2014-02-05	am	f	Developpement V2
57	131	19	2014-02-05	pm	f	Developpement V2
57	131	19	2014-02-06	am	f	Developpement V2
57	131	19	2014-02-06	pm	f	Developpement V2
67	67	19	2014-02-07	am	f	Reunion avancement projet
57	131	19	2014-02-07	pm	f	Developpement V2
57	131	19	2014-02-10	am	f	Developpement V2
57	131	19	2014-02-10	pm	f	Developpement V2
63	89	19	2014-02-11	am	f	Install serveurs devsi et ppsi
70	89	19	2014-02-11	pm	f	Sauvegarde serveur castor fichier SQL
57	131	19	2014-02-12	am	f	Developpement V2
57	131	19	2014-02-12	pm	f	Developpement V2
57	131	19	2014-02-13	am	f	Developpement V2
57	131	19	2014-02-13	pm	f	Developpement V2
57	131	19	2014-02-14	am	f	Developpement V2
57	131	19	2014-02-14	pm	f	Developpement V2
57	131	19	2014-02-17	am	f	Developpement V2
57	131	19	2014-02-17	pm	f	Developpement V2
57	67	19	2014-02-18	am	f	Fixed bug footprint ExoDat
57	67	19	2014-02-18	pm	f	Fixed bug footprint ExoDat
57	131	19	2014-02-19	am	f	Developpement V2
57	131	19	2014-02-19	pm	f	Developpement V2
57	131	19	2014-02-20	am	f	Developpement V2
57	131	19	2014-02-20	pm	f	Developpement V2
57	131	19	2014-02-21	am	f	Developpement V2
57	131	19	2014-02-21	pm	f	Developpement V2
57	69	19	2014-02-24	am	f	Développement galex-emphot ANIS V2
57	69	19	2014-02-24	pm	f	Développement galex-emphot ANIS V2
57	69	19	2014-02-25	am	f	Développement galex-emphot ANIS V2
57	69	19	2014-02-25	pm	f	Développement galex-emphot ANIS V2
57	69	19	2014-02-26	am	f	Développement galex-emphot ANIS V2
57	69	19	2014-02-26	pm	f	Développement galex-emphot ANIS V2
57	69	19	2014-02-27	am	f	Développement galex-emphot ANIS V2
57	69	19	2014-02-27	pm	f	Développement galex-emphot ANIS V2
57	69	19	2014-02-28	am	f	Développement galex-emphot ANIS V2
57	69	19	2014-02-28	pm	f	Développement galex-emphot ANIS V2
\N	\N	19	2014-03-03	am	t	
\N	\N	19	2014-03-03	pm	t	
\N	\N	19	2014-03-04	am	t	
\N	\N	19	2014-03-04	pm	t	
\N	\N	19	2014-03-05	am	t	
\N	\N	19	2014-03-05	pm	t	
\N	\N	19	2014-03-06	am	t	
\N	\N	19	2014-03-06	pm	t	
\N	\N	19	2014-03-07	am	t	
\N	\N	19	2014-03-07	pm	t	
56	67	19	2014-03-10	am	f	Développement et déploiement Exodat ANIS v2
56	67	19	2014-03-10	pm	f	Développement et déploiement Exodat ANIS v2
56	67	19	2014-03-11	am	f	Développement et déploiement Exodat ANIS v2
56	67	19	2014-03-11	pm	f	Développement et déploiement Exodat ANIS v2
56	67	19	2014-03-12	am	f	Développement et déploiement Exodat ANIS v2
56	67	19	2014-03-12	pm	f	Développement et déploiement Exodat ANIS v2
56	67	19	2014-03-13	am	f	Développement et déploiement Exodat ANIS v2
56	67	19	2014-03-13	pm	f	Développement et déploiement Exodat ANIS v2
56	67	19	2014-03-14	am	f	Développement et déploiement Exodat ANIS v2
67	67	19	2014-03-14	pm	f	Reunion avancement projet
57	98	19	2014-03-17	am	f	
57	98	19	2014-03-17	pm	f	
57	98	19	2014-03-18	am	f	
57	98	19	2014-03-18	pm	f	
57	98	19	2014-03-19	am	f	
57	98	19	2014-03-19	pm	f	
57	98	19	2014-03-20	am	f	
57	98	19	2014-03-20	pm	f	
57	98	19	2014-03-21	am	f	
57	98	19	2014-03-21	pm	f	
57	98	19	2014-03-24	am	f	
67	125	19	2014-03-24	pm	f	Rendez-vous DR12
59	84	19	2014-03-25	am	f	Préparation dossier VAE
59	84	19	2014-03-25	pm	f	Préparation dossier VAE
59	84	19	2014-03-26	am	f	Préparation dossier VAE
59	84	19	2014-03-26	pm	f	Préparation dossier VAE
59	84	19	2014-03-27	am	f	Préparation dossier VAE
59	84	19	2014-03-27	pm	f	Préparation dossier VAE
67	84	19	2014-03-28	am	f	Examen VAE
67	84	19	2014-03-28	pm	f	Examen VAE
57	131	19	2014-03-31	am	f	Developpement FileController
57	131	19	2014-03-31	pm	f	Developpement FileController
57	131	19	2014-04-01	am	f	Developpement FileController
\N	\N	19	2014-04-01	pm	t	
57	131	19	2014-04-02	am	f	Developpement FileController
57	131	19	2014-04-02	pm	f	Developpement FileController
57	131	19	2014-04-03	am	f	Fixed bug SpectraController
57	131	19	2014-04-03	pm	f	Fixed bug SpectraController
57	131	19	2014-04-04	am	f	Fixed bug SpectraController
57	131	19	2014-04-04	pm	f	Fixed bug SpectraController
63	89	19	2014-04-07	am	f	Installation postgresql 9.3 devsi et ppsi
55	131	22	2014-02-13	am	f	
55	131	22	2014-02-13	pm	f	
55	131	22	2014-02-14	am	f	
\N	\N	22	2014-02-14	pm	t	
69	131	22	2014-02-17	am	f	
\N	\N	22	2014-02-17	pm	t	
69	131	22	2014-02-18	am	f	
\N	\N	22	2014-02-18	pm	t	
\N	\N	22	2014-02-19	am	t	
69	131	22	2014-02-19	pm	f	
69	131	22	2014-02-20	am	f	
\N	\N	22	2014-02-20	pm	t	
69	131	22	2014-02-21	am	f	
\N	\N	22	2014-02-21	pm	t	
\N	\N	22	2014-03-12	am	t	
67	85	22	2014-03-12	pm	f	RH
70	102	22	2014-03-13	am	f	
70	102	22	2014-03-13	pm	f	
70	102	22	2014-03-14	am	f	
70	102	22	2014-03-14	pm	f	
70	102	22	2014-03-17	am	f	
70	102	22	2014-03-17	pm	f	
70	102	22	2014-03-18	am	f	
70	102	22	2014-03-18	pm	f	
\N	\N	22	2014-03-19	am	t	
70	98	22	2014-03-19	pm	f	
70	98	22	2014-03-20	am	f	
70	98	22	2014-03-20	pm	f	
70	102	22	2014-03-21	am	f	
70	102	22	2014-03-21	pm	f	
70	102	22	2014-03-24	am	f	
70	102	22	2014-03-24	pm	f	
67	127	22	2014-03-25	am	f	
69	127	22	2014-03-25	pm	f	
70	102	22	2014-03-26	am	f	
\N	\N	22	2014-03-26	pm	t	
66	89	22	2014-03-27	am	f	vae
66	89	22	2014-03-27	pm	f	vae
69	127	22	2014-03-28	am	f	
\N	\N	22	2014-03-28	pm	t	
66	89	22	2014-03-31	am	f	
66	89	22	2014-03-31	pm	f	
66	89	22	2014-04-01	am	f	
\N	\N	22	2014-04-01	pm	t	
\N	\N	22	2014-04-02	am	t	
63	89	22	2014-04-02	pm	f	
67	85	22	2014-04-03	am	f	web lam
63	89	22	2014-04-03	pm	f	
66	89	22	2014-04-04	am	f	dossier concours Stef
66	89	22	2014-04-04	pm	f	dossier concours Stef
69	101	22	2014-04-07	am	f	
69	101	22	2014-04-07	pm	f	
67	127	22	2014-04-08	am	f	
70	102	22	2014-04-08	pm	f	
57	71	23	2013-09-13	pm	f	
57	71	23	2013-09-13	am	f	
57	71	23	2013-09-16	pm	f	
57	71	23	2013-09-16	am	f	
57	71	23	2013-09-17	pm	f	
57	71	23	2013-09-17	am	f	
57	71	23	2013-09-18	pm	f	
57	71	23	2013-09-18	am	f	
57	71	23	2013-09-19	pm	f	
57	71	23	2013-09-19	am	f	
57	71	23	2013-09-20	pm	f	
57	71	23	2013-09-20	am	f	
57	71	23	2013-09-23	pm	f	
57	71	23	2013-09-23	am	f	
57	71	23	2013-09-24	pm	f	
57	71	23	2013-09-24	am	f	
57	71	23	2013-09-25	pm	f	
57	71	23	2013-09-25	am	f	
57	71	23	2013-09-26	pm	f	
57	71	23	2013-09-26	am	f	
57	71	23	2013-09-27	pm	f	
57	71	23	2013-09-27	am	f	
57	71	23	2013-09-30	pm	f	
57	71	23	2013-09-30	am	f	
57	71	23	2013-10-01	pm	f	
57	71	23	2013-10-01	am	f	
57	71	23	2013-10-02	pm	f	
57	71	23	2013-10-02	am	f	
57	71	23	2013-10-03	pm	f	
57	71	23	2013-10-03	am	f	
57	71	23	2013-10-04	pm	f	
57	71	23	2013-10-04	am	f	
57	71	23	2013-10-07	pm	f	
57	71	23	2013-10-07	am	f	
57	71	23	2013-10-08	pm	f	
57	71	23	2013-10-09	pm	f	
57	71	23	2013-10-09	am	f	
57	71	23	2013-10-10	pm	f	
57	71	23	2013-10-10	am	f	
57	71	23	2013-10-11	pm	f	
57	71	23	2013-10-11	am	f	
57	71	23	2013-10-14	pm	f	
57	71	23	2013-10-14	am	f	
57	71	23	2013-10-15	pm	f	
57	71	23	2013-10-15	am	f	
57	71	23	2013-10-16	pm	f	
57	71	23	2013-10-16	am	f	
57	71	23	2013-10-17	pm	f	
57	71	23	2013-10-17	am	f	
57	71	23	2013-10-18	pm	f	
57	71	23	2013-10-18	am	f	
57	71	23	2013-10-21	pm	f	
57	71	23	2013-10-21	am	f	
57	71	23	2013-10-22	pm	f	
57	71	23	2013-10-22	am	f	
57	71	23	2013-10-23	pm	f	
57	71	23	2013-10-23	am	f	
57	71	23	2013-10-24	pm	f	
57	71	23	2013-10-24	am	f	
57	71	23	2013-10-25	pm	f	
57	71	23	2013-10-25	am	f	
57	71	23	2013-10-28	pm	f	
57	71	23	2013-10-28	am	f	
57	71	23	2013-10-29	pm	f	
57	71	23	2013-10-29	am	f	
57	71	23	2013-10-30	pm	f	
57	71	23	2013-10-30	am	f	
57	71	23	2013-10-31	pm	f	
57	71	23	2013-10-31	am	f	
57	71	23	2013-11-01	pm	f	
57	71	23	2013-11-01	am	f	
57	71	23	2013-11-04	pm	f	
57	71	23	2013-11-04	am	f	
57	71	23	2013-11-05	pm	f	
57	71	23	2013-11-05	am	f	
57	71	23	2013-11-06	pm	f	
57	71	23	2013-11-06	am	f	
57	71	23	2013-11-07	pm	f	
57	71	23	2013-11-07	am	f	
57	71	23	2013-11-08	pm	f	
57	71	23	2013-11-08	am	f	
57	71	23	2013-11-11	pm	f	
57	71	23	2013-11-11	am	f	
57	71	23	2013-11-12	pm	f	
57	71	23	2013-11-12	am	f	
57	71	23	2013-11-13	pm	f	
57	71	23	2013-11-13	am	f	
57	71	23	2013-11-14	pm	f	
57	71	23	2013-11-14	am	f	
57	71	23	2013-11-15	pm	f	
57	71	23	2013-11-15	am	f	
57	71	23	2013-11-18	pm	f	
57	71	23	2013-11-18	am	f	
57	71	23	2013-11-19	pm	f	
57	71	23	2013-11-19	am	f	
57	71	23	2013-11-20	pm	f	
57	71	23	2013-11-20	am	f	
57	71	23	2013-11-21	pm	f	
57	71	23	2013-11-21	am	f	
57	71	23	2013-11-22	pm	f	
57	71	23	2013-11-22	am	f	
57	71	23	2013-11-25	pm	f	
57	71	23	2013-11-25	am	f	
57	71	23	2013-11-26	pm	f	
57	71	23	2013-11-26	am	f	
57	71	23	2013-11-27	pm	f	
57	71	23	2013-11-27	am	f	
57	71	23	2013-11-28	pm	f	
57	71	23	2013-11-28	am	f	
57	71	23	2013-11-29	pm	f	
57	71	23	2013-11-29	am	f	
57	71	23	2013-12-02	pm	f	
57	71	23	2013-12-02	am	f	
57	71	23	2013-12-03	pm	f	
57	71	23	2013-12-03	am	f	
57	71	23	2013-12-04	pm	f	
57	71	23	2013-12-04	am	f	
57	71	23	2013-12-05	pm	f	
57	71	23	2013-12-05	am	f	
57	71	23	2013-12-06	pm	f	
57	71	23	2013-12-06	am	f	
57	71	23	2013-12-09	pm	f	
57	71	23	2013-12-09	am	f	
57	71	23	2013-12-10	pm	f	
57	71	23	2013-12-10	am	f	
57	71	23	2013-12-11	pm	f	
57	71	23	2013-12-11	am	f	
57	71	23	2013-12-12	pm	f	
57	71	23	2013-12-12	am	f	
57	71	23	2013-12-13	pm	f	
57	71	23	2013-12-13	am	f	
57	71	23	2013-12-16	pm	f	
57	71	23	2013-12-16	am	f	
57	71	23	2013-12-17	pm	f	
57	71	23	2013-12-17	am	f	
57	71	23	2013-12-18	pm	f	
57	71	23	2013-12-18	am	f	
57	71	23	2013-12-19	pm	f	
57	71	23	2013-12-19	am	f	
57	71	23	2013-12-20	pm	f	
57	71	23	2013-12-20	am	f	
57	71	23	2013-12-23	pm	f	
57	71	23	2013-12-23	am	f	
57	71	23	2013-12-24	pm	f	
57	71	23	2013-12-24	am	f	
57	71	23	2013-12-25	pm	f	
57	71	23	2013-12-25	am	f	
57	71	23	2013-12-26	pm	f	
57	71	23	2013-12-26	am	f	
57	71	23	2013-12-27	pm	f	
57	71	23	2013-12-27	am	f	
57	71	23	2013-12-30	pm	f	
57	71	23	2013-12-30	am	f	
57	71	23	2013-12-31	pm	f	
57	71	23	2013-12-31	am	f	
57	71	23	2014-01-01	pm	f	
57	71	23	2014-01-01	am	f	
57	71	23	2014-01-02	pm	f	
57	71	23	2014-01-02	am	f	
57	71	23	2014-01-03	pm	f	
57	71	23	2014-01-03	am	f	
57	71	23	2014-01-06	pm	f	
57	71	23	2014-01-06	am	f	
57	71	23	2014-01-07	pm	f	
57	71	23	2014-01-07	am	f	
57	71	23	2014-01-08	pm	f	
57	71	23	2014-01-08	am	f	
57	71	23	2014-01-09	pm	f	
57	71	23	2014-01-09	am	f	
57	71	23	2014-01-10	pm	f	
57	71	23	2014-01-10	am	f	
57	71	23	2014-01-13	pm	f	
57	71	23	2014-01-13	am	f	
57	71	23	2014-01-14	pm	f	
57	71	23	2014-01-14	am	f	
57	71	23	2014-01-15	pm	f	
57	71	23	2014-01-15	am	f	
57	71	23	2014-01-16	pm	f	
57	71	23	2014-01-16	am	f	
57	71	23	2014-01-17	pm	f	
57	71	23	2014-01-17	am	f	
57	71	23	2014-01-20	pm	f	
57	71	23	2014-01-20	am	f	
57	71	23	2014-01-21	pm	f	
57	71	23	2014-01-21	am	f	
57	71	23	2014-01-22	pm	f	
57	71	23	2014-01-22	am	f	
57	71	23	2014-01-23	pm	f	
57	71	23	2014-01-23	am	f	
57	71	23	2014-01-24	pm	f	
57	71	23	2014-01-24	am	f	
57	71	23	2014-01-27	pm	f	
57	71	23	2014-01-27	am	f	
57	71	23	2014-01-28	pm	f	
57	71	23	2014-01-28	am	f	
57	71	23	2014-01-29	pm	f	
57	71	23	2014-01-29	am	f	
57	71	23	2014-01-30	pm	f	
57	71	23	2014-01-30	am	f	
57	71	23	2014-01-31	pm	f	
57	71	23	2014-01-31	am	f	
57	71	23	2014-02-03	pm	f	
57	71	23	2014-02-03	am	f	
57	71	23	2014-02-04	pm	f	
57	71	23	2014-02-04	am	f	
57	71	23	2014-02-05	pm	f	
57	71	23	2014-02-05	am	f	
57	71	23	2014-02-06	pm	f	
57	71	23	2014-02-06	am	f	
57	71	23	2014-02-07	pm	f	
57	71	23	2014-02-07	am	f	
57	71	23	2014-02-10	pm	f	
57	71	23	2014-02-10	am	f	
57	71	23	2014-02-11	pm	f	
57	71	23	2014-02-11	am	f	
57	71	23	2014-02-12	pm	f	
57	71	23	2014-02-12	am	f	
57	71	23	2014-02-13	pm	f	
57	71	23	2014-02-13	am	f	
57	71	23	2014-02-14	pm	f	
57	71	23	2014-02-14	am	f	
57	71	23	2014-02-17	pm	f	
57	71	23	2014-02-17	am	f	
57	71	23	2014-02-18	pm	f	
57	71	23	2014-02-18	am	f	
57	71	23	2014-02-19	pm	f	
57	71	23	2014-02-19	am	f	
57	71	23	2014-02-20	pm	f	
57	71	23	2014-02-20	am	f	
57	71	23	2014-02-21	pm	f	
57	71	23	2014-02-21	am	f	
57	71	23	2014-02-24	pm	f	
57	71	23	2014-02-24	am	f	
57	71	23	2014-02-25	pm	f	
57	71	23	2014-02-25	am	f	
57	71	23	2014-02-26	pm	f	
57	71	23	2014-02-26	am	f	
57	71	23	2014-02-27	pm	f	
57	71	23	2014-02-27	am	f	
57	71	23	2014-02-28	pm	f	
57	71	23	2014-02-28	am	f	
57	71	23	2014-03-03	pm	f	
57	71	23	2014-03-03	am	f	
57	71	23	2014-03-04	pm	f	
57	71	23	2014-03-04	am	f	
57	71	23	2014-03-05	pm	f	
57	71	23	2014-03-05	am	f	
57	71	23	2014-03-06	pm	f	
57	71	23	2014-03-06	am	f	
57	71	23	2014-03-07	pm	f	
57	71	23	2014-03-07	am	f	
57	71	23	2014-03-10	pm	f	
57	71	23	2014-03-10	am	f	
57	71	23	2014-03-11	pm	f	
57	71	23	2014-03-11	am	f	
57	71	23	2014-03-12	pm	f	
57	71	23	2014-03-12	am	f	
57	71	23	2014-03-13	pm	f	
57	71	23	2014-03-13	am	f	
57	71	23	2014-03-14	pm	f	
57	71	23	2014-03-14	am	f	
57	71	23	2014-03-17	pm	f	
57	71	23	2014-03-17	am	f	
57	71	23	2014-03-18	pm	f	
57	71	23	2014-03-18	am	f	
57	71	23	2014-03-19	pm	f	
57	71	23	2014-03-19	am	f	
57	71	23	2014-03-20	pm	f	
57	71	23	2014-03-20	am	f	
57	71	23	2014-03-21	pm	f	
57	71	23	2014-03-21	am	f	
57	71	23	2014-03-24	pm	f	
57	71	23	2014-03-24	am	f	
57	71	23	2014-03-25	pm	f	
57	71	23	2014-03-25	am	f	
57	71	23	2014-03-26	pm	f	
57	71	23	2014-03-26	am	f	
57	71	23	2014-03-27	pm	f	
57	71	23	2014-03-27	am	f	
57	71	23	2014-03-28	pm	f	
57	71	23	2014-03-28	am	f	
57	71	23	2014-03-31	pm	f	
57	71	23	2014-03-31	am	f	
57	71	23	2014-04-01	pm	f	
57	71	23	2014-04-01	am	f	
57	71	23	2014-04-02	pm	f	
57	71	23	2014-04-02	am	f	
57	71	23	2014-04-03	pm	f	
57	71	23	2014-04-03	am	f	
57	71	23	2014-04-04	pm	f	
57	71	23	2014-04-04	am	f	
57	71	23	2014-04-07	pm	f	
57	71	23	2014-04-07	am	f	
57	71	23	2014-04-08	pm	f	
57	71	23	2014-04-08	am	f	
72	125	31	2014-04-03	am	f	zSURVEY
72	125	31	2014-04-03	pm	f	FF Johan's paper + WL arclet redshifts
72	125	31	2014-04-04	pm	f	FF Mathilde Proposal g+
67	92	31	2014-04-08	pm	f	Actions sur le DM OUSIM
57	64	35	2014-04-09	am	f	
57	64	35	2014-04-09	pm	f	
73	110	15	2014-04-08	am	f	accretion project
73	110	15	2014-04-09	am	f	accretion project
57	64	35	2014-04-10	am	f	import db script from server (iRIs data)
57	64	35	2014-04-10	pm	f	import db script from server (iRIs data)
57	64	35	2014-04-11	am	f	import db script from server (iRIs data)
57	64	35	2014-04-11	pm	f	import db script from server (iRIs data)
57	64	35	2014-04-14	am	f	fix tooltip for Hub button and Graph button in result
57	64	35	2014-04-14	pm	f	fix the cache bug
67	89	5	2014-04-08	am	f	DELL Tour
67	89	5	2014-04-08	pm	f	DELL Tour
62	89	5	2014-04-09	am	f	
62	89	5	2014-04-09	pm	f	
63	89	5	2014-04-10	am	f	
62	89	5	2014-04-10	pm	f	
59	89	5	2014-04-11	am	f	
63	85	5	2014-04-11	pm	f	
59	89	5	2014-04-14	am	f	
66	81	14	2014-04-07	am	f	Encadrement stagiaire
55	81	14	2014-04-07	pm	f	Encadrement stagiaire
55	81	14	2014-04-08	am	f	Forwarder
57	81	14	2014-04-08	pm	f	Forwarder
57	81	14	2014-04-09	am	f	Forwarder
55	81	14	2014-04-09	pm	f	Specification messenger
55	81	14	2014-04-10	am	f	Specification messenger
55	81	14	2014-04-10	pm	f	Specification messenger
66	67	14	2014-04-11	am	f	Preparation vision
67	67	14	2014-04-11	pm	f	Vision LESIA
73	110	15	2014-04-09	pm	f	accretion
57	72	15	2014-04-07	pm	f	tripixel
57	72	15	2014-04-08	pm	f	tripixel
57	72	15	2014-04-10	am	f	tripixel
57	72	15	2014-04-11	am	f	Claire nimage problem
57	72	15	2014-04-11	pm	f	Claire nimage problem
57	110	15	2014-04-15	am	f	SPHS
57	92	31	2014-04-17	pm	f	
57	92	31	2014-04-18	am	f	
57	92	31	2014-04-18	pm	f	
66	81	14	2014-04-14	am	f	Encadrement stagiaire
55	81	14	2014-04-14	pm	f	Specification Messenger
70	67	14	2014-04-15	am	f	Mise a jour des données N2
70	67	14	2014-04-15	pm	f	Mise a jour des données N2
70	67	14	2014-04-16	am	f	Mise a jour des données N2
70	67	14	2014-04-16	pm	f	Mise a jour des données N2
70	67	14	2014-04-17	am	f	Mise a jour des données N2
70	133	14	2014-04-17	pm	f	Data Model
55	81	14	2014-04-18	am	f	Specification Messenger
70	133	14	2014-04-18	pm	f	Data Model
\N	\N	14	2014-04-21	am	t	
\N	\N	14	2014-04-21	pm	t	
57	115	15	2014-04-17	am	f	compass
67	115	15	2014-04-17	pm	f	compass
73	110	15	2014-04-18	am	f	accretion project
73	110	15	2014-04-18	pm	f	accretion project
\N	\N	15	2014-04-21	am	t	
\N	\N	15	2014-04-21	pm	t	
57	115	15	2014-04-23	am	f	writing article
57	115	15	2014-04-23	pm	f	writing article
67	92	31	2014-04-22	am	f	
67	92	31	2014-04-22	pm	f	
67	92	31	2014-04-23	am	f	
67	92	31	2014-04-23	pm	f	
59	84	20	2014-04-07	am	f	Dossiers concours
59	84	20	2014-04-07	pm	f	Dossiers concours
70	84	20	2014-04-08	am	f	XMMLSS
70	84	20	2014-04-08	pm	f	XMMLSS
70	84	20	2014-04-09	am	f	XMMLSS
70	84	20	2014-04-09	pm	f	XMMLSS
57	128	20	2014-04-10	am	f	
56	128	20	2014-04-10	pm	f	
59	84	20	2014-04-11	am	f	Dossiers concours
59	84	20	2014-04-11	pm	f	Dossiers concours
70	136	20	2014-04-14	am	f	
56	98	20	2014-04-14	pm	f	
70	136	20	2014-04-15	am	f	
70	136	20	2014-04-15	pm	f	
\N	\N	20	2014-04-16	am	t	
\N	\N	20	2014-04-16	pm	t	
\N	\N	20	2014-04-17	am	t	
\N	\N	20	2014-04-17	pm	t	
\N	\N	20	2014-04-18	am	t	
\N	\N	20	2014-04-18	pm	t	
\N	\N	20	2014-04-21	am	t	
\N	\N	20	2014-04-21	pm	t	
\N	\N	20	2014-04-22	am	t	
\N	\N	20	2014-04-22	pm	t	
\N	\N	20	2014-04-23	am	t	
\N	\N	20	2014-04-23	pm	t	
\N	\N	20	2014-04-24	am	t	
\N	\N	20	2014-04-24	pm	t	
\N	\N	20	2014-04-25	am	t	
\N	\N	20	2014-04-25	pm	t	
70	67	14	2014-04-22	am	f	Mise a jour de données N2
70	133	14	2014-04-22	pm	f	Data model
66	81	14	2014-04-23	am	f	Encadrement stagiaire
70	133	14	2014-04-23	pm	f	Data model
55	81	14	2014-04-24	am	f	Demonstrateur
55	81	14	2014-04-24	pm	f	Demonstrateur
55	81	14	2014-04-25	am	f	Demonstrateur
55	81	14	2014-04-25	pm	f	Demonstrateur
\N	\N	5	2014-04-21	am	t	
\N	\N	5	2014-04-21	pm	t	
\N	\N	5	2014-04-23	am	t	
\N	\N	5	2014-04-23	pm	t	
\N	\N	5	2014-04-24	am	t	
\N	\N	5	2014-04-24	pm	t	
\N	\N	5	2014-04-25	am	t	
\N	\N	5	2014-04-25	pm	t	
\N	\N	5	2014-04-28	am	t	
\N	\N	5	2014-04-28	pm	t	
\N	\N	5	2014-04-29	am	t	
\N	\N	5	2014-04-29	pm	t	
\N	\N	5	2014-04-30	am	t	
\N	\N	5	2014-04-30	pm	t	
\N	\N	5	2014-05-01	am	t	
\N	\N	5	2014-05-01	pm	t	
\N	\N	5	2014-05-02	am	t	
\N	\N	5	2014-05-02	pm	t	
63	85	5	2014-04-14	pm	f	Cluster MIB
63	85	5	2014-04-15	am	f	Cluster MIB
63	85	5	2014-04-15	pm	f	Cluster MIB
59	85	5	2014-04-16	am	f	
59	85	5	2014-04-16	pm	f	
59	85	5	2014-04-17	am	f	
59	85	5	2014-04-17	pm	f	
63	85	5	2014-04-18	am	f	
63	85	5	2014-04-18	pm	f	
59	85	5	2014-04-22	am	f	
59	85	5	2014-04-22	pm	f	
63	85	5	2014-05-05	am	f	
63	85	5	2014-05-05	pm	f	Cluster
71	89	5	2014-05-06	am	f	
63	85	5	2014-05-06	pm	f	Cluster
63	85	5	2014-05-07	am	f	Cluster
63	85	5	2014-05-07	pm	f	Cluster
\N	\N	5	2014-05-08	am	t	
\N	\N	5	2014-05-08	pm	t	
\N	\N	5	2014-05-09	am	t	
\N	\N	5	2014-05-09	pm	t	
57	115	15	2014-04-24	am	f	local ETKF
57	115	15	2014-04-24	pm	f	local ETKF
73	110	15	2014-04-29	am	f	accretion project
73	110	15	2014-04-29	pm	f	accretion project
73	110	15	2014-04-30	am	f	accretion project
73	110	15	2014-04-30	pm	f	accretion project
\N	\N	15	2014-05-01	am	t	
\N	\N	15	2014-05-01	pm	t	
\N	\N	15	2014-05-02	am	t	
\N	\N	15	2014-05-02	pm	t	
\N	\N	15	2014-05-05	am	t	
\N	\N	15	2014-05-05	pm	t	
\N	\N	15	2014-05-06	am	t	
\N	\N	15	2014-05-06	pm	t	
\N	\N	15	2014-05-07	am	t	
\N	\N	15	2014-05-07	pm	t	
\N	\N	15	2014-05-08	am	t	
\N	\N	15	2014-05-08	pm	t	
\N	\N	15	2014-05-09	am	t	
\N	\N	15	2014-05-09	pm	t	
57	72	15	2014-04-14	pm	f	tripixel in fortran
57	72	15	2014-04-15	pm	f	tripixel in fortran
57	72	15	2014-04-16	am	f	scripts
57	72	15	2014-04-16	pm	f	scripts
57	72	15	2014-04-22	am	f	oasis + tripixel
57	72	15	2014-04-22	pm	f	oasis + tripixel
57	72	15	2014-04-25	am	f	scripts for rosetta
57	72	15	2014-04-25	pm	f	scripts for rosetta
57	72	15	2014-04-28	am	f	scripts for rosetta
57	72	15	2014-04-28	pm	f	scripts for rosetta
57	72	15	2014-05-12	am	f	scripts for rosetta
57	72	15	2014-05-12	pm	f	scripts for rosetta
57	72	15	2014-05-13	pm	f	scripts for rosetta
57	72	15	2014-05-14	am	f	TRIPIXEL for oasis
57	72	15	2014-05-14	pm	f	TRIPIXEL for oasis
57	72	15	2014-05-15	am	f	TRIPIXEL for oasis
57	72	15	2014-05-15	pm	f	TRIPIXEL for oasis
57	72	15	2014-05-16	am	f	TRIPIXEL for oasis
57	72	15	2014-05-16	pm	f	TRIPIXEL for oasis
57	110	15	2014-05-19	am	f	external potential to Gadget
73	110	15	2014-05-19	pm	f	MESO cluster testing
67	92	31	2014-05-19	pm	f	
57	92	31	2014-05-20	am	f	
67	92	31	2014-05-22	pm	f	
67	92	31	2014-05-23	am	f	icescrum
73	110	15	2014-05-20	am	f	cluster testing
73	110	15	2014-05-20	pm	f	cluster testing
73	110	15	2014-05-21	am	f	bar reconstruction
73	110	15	2014-05-21	pm	f	bar reconstruction
57	115	15	2014-05-22	am	f	COMPASS
57	115	15	2014-05-22	pm	f	COMPASS
73	110	15	2014-05-23	am	f	bar reconstruction
57	115	15	2014-05-23	pm	f	COMPASS
57	115	15	2014-05-26	am	f	COMPASS
57	115	15	2014-05-26	pm	f	COMPASS
73	110	15	2014-05-27	am	f	bar
73	110	15	2014-05-27	pm	f	bar
57	111	15	2014-05-28	am	f	help to Cecilia Pinto
57	111	15	2014-05-28	pm	f	help to Cecilia Pinto
66	81	14	2014-05-05	am	f	Encadrement stagiaire
57	81	14	2014-05-05	pm	f	Demonstrateur EPIC
57	81	14	2014-05-06	am	f	Demonstrateur EPIC
57	81	14	2014-05-06	pm	f	Demonstrateur EPIC
57	81	14	2014-05-07	am	f	Demonstrateur EPIC
67	81	14	2014-05-07	pm	f	Conférence Marseille
\N	\N	14	2014-05-08	am	t	
67	81	14	2014-05-08	pm	f	Conférence Marseille
\N	\N	14	2014-05-09	am	t	
\N	\N	14	2014-05-09	pm	t	
66	81	14	2014-05-12	am	f	Encadrement stagiaire
59	81	14	2014-05-26	am	f	Revue du stage de Francois Gilbert
59	81	14	2014-05-26	pm	f	Revue du stage de Francois Gilbert
59	84	14	2014-05-27	am	f	Depart de Francois Gilbert
59	67	14	2014-05-27	pm	f	Prépa maquette
67	67	14	2014-05-28	am	f	Prépa Revex
59	84	14	2014-05-28	pm	f	Anglais
\N	\N	14	2014-05-29	am	t	
\N	\N	14	2014-05-29	pm	t	
\N	\N	14	2014-05-30	am	t	
\N	\N	14	2014-05-30	pm	t	
66	89	14	2014-06-02	am	f	Planning hebdomadaire
59	84	14	2014-06-02	pm	f	Anglais
57	64	35	2014-04-15	am	f	Fix the cache bug
57	64	35	2014-04-15	pm	f	Fix the cache bug
57	64	35	2014-04-16	am	f	Fix the cache bug
57	64	35	2014-04-16	pm	f	Fix the cache bug
57	64	35	2014-04-17	am	f	Fix the cache bug
57	64	35	2014-04-17	pm	f	Fix the cache bug
57	64	35	2014-04-18	am	f	Fix the cache bug
57	64	35	2014-04-18	pm	f	Fix the cache bug
57	64	35	2014-04-21	am	f	Fix the cache bug
57	64	35	2014-04-21	pm	f	Fix the cache bug
57	64	35	2014-04-22	am	f	Fix the cache bug
57	64	35	2014-04-22	pm	f	Fix the cache bug
57	64	35	2014-04-23	am	f	Fix the cache bug
57	64	35	2014-04-23	pm	f	Fix the cache bug
57	64	35	2014-04-24	am	f	Fix the cache bug
57	64	35	2014-04-24	pm	f	Fix the cache bug
57	64	35	2014-04-25	am	f	Fix the cache bug
57	64	35	2014-04-25	pm	f	Fix the cache bug
57	64	35	2014-04-28	am	f	Fix the cache bug
57	64	35	2014-04-28	pm	f	Fix the cache bug
57	64	35	2014-04-29	am	f	Fix the cache bug
57	64	35	2014-04-29	pm	f	Fix the cache bug
57	64	35	2014-04-30	am	f	Fix the cache bug
57	64	35	2014-04-30	pm	f	Fix the cache bug
57	64	35	2014-05-01	am	f	Fix the cache bug
57	64	35	2014-05-01	pm	f	Fix the cache bug
57	64	35	2014-05-02	am	f	Fix the cache bug
57	64	35	2014-05-02	pm	f	Fix the cache bug
57	64	35	2014-05-05	am	f	Fix the cache bug
57	64	35	2014-05-05	pm	f	Fix the cache bug
57	64	35	2014-05-06	am	f	Fix the cache bug
57	64	35	2014-05-06	pm	f	Fix the cache bug
57	64	35	2014-05-07	am	f	Fix the cache bug
57	64	35	2014-05-07	pm	f	Fix the cache bug
57	64	35	2014-05-08	am	f	Fix the cache bug
57	64	35	2014-05-08	pm	f	Fix the cache bug
57	64	35	2014-05-09	am	f	Fix the cache bug
57	64	35	2014-05-09	pm	f	Fix the cache bug
57	64	35	2014-05-12	am	f	Fix the cache bug
57	64	35	2014-05-12	pm	f	Fix the cache bug
57	64	35	2014-05-13	am	f	Fix the cache bug
57	64	35	2014-05-13	pm	f	Fix the cache bug
57	64	35	2014-05-14	am	f	Fix the cache bug
57	64	35	2014-05-14	pm	f	Fix the cache bug
57	64	35	2014-05-15	am	f	Fix the cache bug
57	64	35	2014-05-15	pm	f	Fix the cache bug
57	64	35	2014-05-16	am	f	Fix the cache bug
57	64	35	2014-05-16	pm	f	Fix the cache bug
57	64	35	2014-05-19	am	f	Fix the cache bug
57	64	35	2014-05-19	pm	f	Fix the cache bug
57	64	35	2014-05-20	am	f	Fix the cache bug
57	64	35	2014-05-20	pm	f	Fix the cache bug
57	64	35	2014-05-21	am	f	Fix the cache bug
57	64	35	2014-05-21	pm	f	Fix the cache bug
57	64	35	2014-05-22	am	f	Fix the cache bug
57	64	35	2014-05-22	pm	f	Fix the cache bug
57	64	35	2014-05-23	am	f	Fix the cache bug
57	64	35	2014-05-23	pm	f	Fix the cache bug
57	64	35	2014-05-26	am	f	Fix the cache bug
57	64	35	2014-05-26	pm	f	Fix the cache bug
57	64	35	2014-05-27	am	f	Fix the cache bug
57	64	35	2014-05-27	pm	f	Fix the cache bug
57	64	35	2014-05-28	am	f	Fix the cache bug
57	64	35	2014-05-28	pm	f	Cache bug fixed
57	64	35	2014-05-29	am	f	Fix the low performance
57	64	35	2014-05-29	pm	f	Fix the low performance
57	64	35	2014-05-30	am	f	Fix the low performance
57	64	35	2014-05-30	pm	f	Fix the low performance
57	64	35	2014-06-02	am	f	Fix the low performance
57	64	35	2014-06-02	pm	f	Fix the low performance
57	64	35	2014-06-03	am	f	Fix the low performance
57	64	35	2014-06-03	pm	f	Fix the low performance
67	92	31	2014-06-03	am	f	
57	98	20	2014-04-28	am	f	Migration ANIS
57	98	20	2014-04-28	pm	f	Migration ANIS
56	98	20	2014-04-29	am	f	Migration ANIS
56	98	20	2014-04-29	pm	f	Migration ANIS
57	98	20	2014-04-30	am	f	Migration ANIS
57	98	20	2014-04-30	pm	f	Migration ANIS
\N	\N	20	2014-05-01	am	t	
\N	\N	20	2014-05-01	pm	t	
\N	\N	20	2014-05-02	am	t	
\N	\N	20	2014-05-02	pm	t	
71	66	20	2014-05-05	am	f	
71	102	20	2014-05-05	pm	f	
71	132	20	2014-05-06	am	f	
71	128	20	2014-05-06	pm	f	
71	136	20	2014-05-07	am	f	
71	98	20	2014-05-07	pm	f	
\N	\N	20	2014-05-08	am	t	
\N	\N	20	2014-05-08	pm	t	
\N	\N	20	2014-05-09	am	t	
\N	\N	20	2014-05-09	pm	t	
62	89	20	2014-05-12	am	f	Zend Framework
62	89	20	2014-05-12	pm	f	Zend Framework
62	89	20	2014-05-13	am	f	Zend Framework
62	89	20	2014-05-13	pm	f	Zend Framework
62	89	20	2014-05-14	am	f	Zend Framework
62	89	20	2014-05-14	pm	f	Zend Framework
62	89	20	2014-05-15	am	f	Zend Framework
62	89	20	2014-05-15	pm	f	Zend Framework
62	89	20	2014-05-16	am	f	Zend Framework
62	89	20	2014-05-16	pm	f	Zend Framework
63	89	20	2014-05-19	am	f	Installation du serveur virtuel hedam
63	89	20	2014-05-19	pm	f	Installation du serveur virtuel hedam
57	98	20	2014-05-20	am	f	
57	98	20	2014-05-20	pm	f	
57	98	20	2014-05-21	am	f	
57	98	20	2014-05-21	pm	f	
\N	\N	20	2014-05-22	am	t	
\N	\N	20	2014-05-22	pm	t	
\N	\N	20	2014-05-23	am	t	
\N	\N	20	2014-05-23	pm	t	
56	66	20	2014-05-26	am	f	
56	132	20	2014-05-26	pm	f	
56	101	20	2014-05-27	am	f	
57	131	20	2014-05-27	pm	f	
57	131	20	2014-05-28	am	f	
57	131	20	2014-05-28	pm	f	
\N	\N	20	2014-05-29	am	t	
\N	\N	20	2014-05-29	pm	t	
\N	\N	20	2014-05-30	am	t	
\N	\N	20	2014-05-30	pm	t	
57	131	20	2014-06-02	am	f	Outils fits
57	131	20	2014-06-02	pm	f	Outils fits
57	131	20	2014-06-03	am	f	Outils fits
57	131	20	2014-06-03	pm	f	Outils fits
57	131	20	2014-06-04	am	f	Outils fits
57	131	20	2014-06-04	pm	f	Outils fits
57	102	20	2014-06-05	am	f	
57	102	20	2014-06-05	pm	f	
\N	\N	15	2014-05-29	am	t	
\N	\N	15	2014-05-29	pm	t	
\N	\N	15	2014-05-30	am	t	
\N	\N	15	2014-05-30	pm	t	
67	110	15	2014-06-02	am	f	DAGAL school
67	110	15	2014-06-02	pm	f	DAGAL school
67	110	15	2014-06-04	am	f	DAGAL school
67	110	15	2014-06-04	pm	f	DAGAL school
67	110	15	2014-06-05	am	f	DAGAL school
67	110	15	2014-06-05	pm	f	DAGAL school
67	110	15	2014-06-06	am	f	DAGAL school
67	110	15	2014-06-06	pm	f	DAGAL school
\N	\N	15	2014-06-09	am	t	
\N	\N	15	2014-06-09	pm	t	
57	64	35	2014-06-04	am	f	Fix the low performance
57	64	35	2014-06-04	pm	f	Fix the low performance
57	64	35	2014-06-05	am	f	Fix the low performance
57	64	35	2014-06-05	pm	f	Meeting 
57	64	35	2014-06-06	am	f	Fix the low performance
57	110	15	2014-07-17	am	f	accretion project
57	64	35	2014-06-06	pm	f	Fix the low performance
57	64	35	2014-06-09	am	f	Fix the low performance
57	64	35	2014-06-09	pm	f	Fix the low performance
57	64	35	2014-06-10	am	f	Design ResultPanel
57	64	35	2014-06-10	pm	f	Design ResultPanel
57	64	35	2014-06-11	am	f	Design ResultPanel
57	64	35	2014-06-11	pm	f	Design ResultPanel
57	64	35	2014-06-12	am	f	Fix the low performance
57	64	35	2014-06-12	pm	f	
63	89	5	2014-05-12	am	f	
63	89	5	2014-05-12	pm	f	
63	89	5	2014-05-13	am	f	
63	89	5	2014-05-13	pm	f	
63	89	5	2014-05-14	am	f	
63	89	5	2014-05-14	pm	f	
63	89	5	2014-05-15	am	t	
63	89	5	2014-05-15	pm	t	
63	89	5	2014-05-16	am	f	
63	89	5	2014-05-16	pm	f	
63	89	5	2014-05-19	am	f	
63	89	5	2014-05-19	pm	f	
63	89	5	2014-05-20	am	f	
63	89	5	2014-05-20	pm	f	
63	89	5	2014-05-21	am	f	
63	89	5	2014-05-21	pm	f	
63	89	5	2014-05-22	am	f	
63	89	5	2014-05-22	pm	f	
63	89	5	2014-05-23	am	f	
63	89	5	2014-05-23	pm	f	
63	89	5	2014-05-26	am	f	
63	89	5	2014-05-26	pm	f	
63	89	5	2014-05-27	am	f	
63	89	5	2014-05-27	pm	f	
63	89	5	2014-05-28	am	f	
63	89	5	2014-05-28	pm	f	
63	89	5	2014-05-29	am	t	
63	89	5	2014-05-29	pm	t	
63	89	5	2014-05-30	am	t	
63	89	5	2014-05-30	pm	t	
67	89	5	2014-06-02	am	f	
63	89	5	2014-06-02	pm	f	
63	89	5	2014-06-03	am	f	
63	89	5	2014-06-03	pm	f	
63	89	5	2014-06-04	am	f	
63	89	5	2014-06-04	pm	f	
63	89	5	2014-06-05	am	f	
63	89	5	2014-06-05	pm	f	
63	89	5	2014-06-06	am	f	
63	89	5	2014-06-06	pm	f	
63	89	5	2014-06-09	am	t	
63	89	5	2014-06-09	pm	t	
63	89	5	2014-06-10	am	f	
63	89	5	2014-06-10	pm	f	
63	89	5	2014-06-11	am	f	
63	89	5	2014-06-11	pm	t	
63	89	5	2014-06-12	am	f	
63	89	5	2014-06-12	pm	f	
63	89	5	2014-06-13	am	f	
63	89	5	2014-06-13	pm	f	
63	89	5	2014-06-16	am	f	
57	92	31	2014-06-23	am	f	
57	92	31	2014-06-24	am	f	
57	92	31	2014-06-25	am	f	
57	72	15	2014-03-20	pm	f	osiris scripts
57	72	15	2014-06-03	pm	f	TRIPIXEL oasis
57	72	15	2014-06-10	am	f	TRIPIXEL oasis
57	72	15	2014-06-10	pm	f	TRIPIXEL oasis
57	72	15	2014-03-27	pm	f	osiris scripts
57	72	15	2014-04-07	am	f	tripixel
57	72	15	2014-04-10	pm	f	Claire nimage problem
57	72	15	2014-04-14	am	f	tripixel in fortran
57	72	15	2014-05-13	am	f	scripts for rosetta
57	72	15	2014-06-03	am	f	TRIPIXEL oasis
57	115	15	2014-06-11	am	f	local ETKF
57	115	15	2014-06-11	pm	f	local ETKF
57	115	15	2014-06-12	am	f	local ETKF
57	115	15	2014-06-12	pm	f	local ETKF
57	110	15	2014-06-13	am	f	hot cone
73	110	15	2014-06-13	pm	f	hot cone
73	110	15	2014-06-16	am	f	hot cone
57	110	15	2014-06-16	pm	f	hot cone
57	110	15	2014-06-17	am	f	hot cone
57	110	15	2014-06-17	pm	f	hot cone
57	72	15	2014-06-18	am	f	Claire bug
57	72	15	2014-06-18	pm	f	Claire bug
72	110	15	2014-06-19	am	f	hot cone
72	110	15	2014-06-19	pm	f	hot cone
72	110	15	2014-06-20	am	f	hot cone
72	110	15	2014-06-20	pm	f	hot cone
57	72	15	2014-06-23	am	f	TRIPIXEL claire
57	72	15	2014-06-23	pm	f	TRIPIXEL claire
57	72	15	2014-06-24	am	f	TRIPIXEL claire
57	72	15	2014-06-24	pm	f	TRIPIXEL claire
57	72	15	2014-06-25	am	f	TRIPIXEL claire
57	72	15	2014-06-25	pm	f	TRIPIXEL claire
72	72	15	2014-06-26	am	f	hot cone
72	110	15	2014-06-26	pm	f	hot cone
57	110	15	2014-06-27	am	f	sphs problem
57	92	31	2014-06-26	pm	f	
57	92	31	2014-06-27	am	f	
57	92	31	2014-06-27	pm	f	
67	92	31	2014-06-10	am	f	
57	92	31	2014-06-11	pm	f	
67	92	31	2014-06-13	pm	f	
57	92	31	2014-06-18	pm	f	
67	85	4	2014-07-01	am	f	SO5
67	85	4	2014-07-01	pm	f	SO5
67	85	4	2014-06-24	am	f	Comité de revue
67	85	4	2014-06-24	pm	f	Comité de revue
67	85	4	2014-06-25	am	f	Comité de revue
67	85	4	2014-06-25	pm	f	Comité de revue
67	96	4	2014-06-26	am	f	Petasky Paris
67	96	4	2014-06-26	pm	f	Petasky Paris
67	96	4	2014-06-27	am	f	Petasky Paris
67	96	4	2014-06-27	pm	f	Petasky Paris
55	85	4	2014-06-30	am	f	prepration SO5
55	85	4	2014-06-30	pm	f	prepration SO5
66	89	4	2014-06-16	am	f	Dossiers de carriere
66	89	4	2014-06-16	pm	f	Dossiers de carriere
66	89	4	2014-06-17	am	f	Dossiers de carriere
66	89	4	2014-06-17	pm	f	Dossiers de carriere
66	89	4	2014-06-18	am	f	Dossiers de carriere
66	89	4	2014-06-18	pm	f	Dossiers de carriere
67	89	4	2014-06-19	am	f	preparation SO5
55	81	4	2014-06-19	pm	f	Analyse
66	89	4	2014-06-20	am	f	Réunion CeSAM
66	89	4	2014-06-20	pm	f	Dossiers de carriere
55	81	4	2014-06-23	am	f	Analyse
55	81	4	2014-06-23	pm	f	Analyse
55	81	4	2014-06-02	am	f	Analyse SRR
55	81	4	2014-06-02	pm	f	Analyse SRR
66	89	4	2014-06-03	am	f	Dossier Carriere
66	89	4	2014-06-03	pm	f	Dossier Carriere
55	89	4	2014-06-04	am	f	interoperabilité des données astro
55	89	4	2014-06-04	pm	f	interoperabilité des données astro
55	81	4	2014-06-05	am	f	Analyse SRR
67	89	4	2014-06-05	pm	f	interoperabilité des données astro
55	81	4	2014-06-06	am	f	Analyse SRR
55	81	4	2014-06-06	pm	f	Analyse SRR
\N	\N	4	2014-06-09	am	t	
\N	\N	4	2014-06-09	pm	t	
66	89	4	2014-06-10	am	f	Dossier Carriere
66	89	4	2014-06-10	pm	f	Dossier Carriere
66	89	4	2014-06-11	am	f	SO5
67	67	4	2014-06-11	pm	f	Analyse fin CoRoT
66	89	4	2014-06-12	am	f	Dossier Carriere
66	89	4	2014-06-12	pm	f	Dossier Carriere
66	89	4	2014-06-13	am	f	Dossier Carriere
66	89	4	2014-06-13	pm	f	Dossier Carriere
67	65	4	2014-07-02	am	f	OG#7
67	65	4	2014-07-02	pm	f	OG#7
57	96	4	2014-05-19	am	f	Venue  invité Sabine McConnell
57	96	4	2014-05-19	pm	f	Venue  invité Sabine McConnell
57	96	4	2014-05-20	am	f	Venue  invité Sabine McConnell
57	96	4	2014-05-20	pm	f	Venue  invité Sabine McConnell
57	96	4	2014-05-21	am	f	Venue  invité Sabine McConnell
57	96	4	2014-05-21	pm	f	Venue  invité Sabine McConnell
57	96	4	2014-05-22	am	f	Venue  invité Sabine McConnell
57	96	4	2014-05-22	pm	f	Venue  invité Sabine McConnell
55	81	4	2014-05-23	am	f	
55	81	4	2014-05-23	pm	f	
55	81	4	2014-05-26	am	f	
55	81	4	2014-05-26	pm	f	
55	81	4	2014-05-27	am	f	
55	81	4	2014-05-27	pm	f	
55	81	4	2014-05-28	am	f	
55	81	4	2014-05-28	pm	f	
\N	\N	4	2014-05-29	am	t	
\N	\N	4	2014-05-29	pm	t	
\N	\N	4	2014-05-30	am	t	
\N	\N	4	2014-05-30	pm	t	
55	88	4	2014-04-07	am	f	Analyse des programmes 
55	88	4	2014-04-07	pm	f	Analyse des programmes 
55	88	4	2014-04-08	am	f	Analyse des programmes 
55	88	4	2014-04-08	pm	f	Analyse des programmes 
67	141	4	2014-04-09	am	f	visit of people from Catania
67	141	4	2014-04-09	pm	f	visit of people from Catania
67	141	4	2014-04-10	am	f	visit of people from Catania
67	141	4	2014-04-10	pm	f	visit of people from Catania
67	141	4	2014-04-11	am	f	visit of people from Catania
67	141	4	2014-04-11	pm	f	visit of people from Catania
67	96	4	2014-04-14	am	f	
67	96	4	2014-04-14	pm	f	
67	96	4	2014-04-15	am	f	
67	96	4	2014-04-15	pm	f	
55	81	4	2014-04-16	am	f	simulation cube
55	81	4	2014-04-16	pm	f	simulation cube
55	81	4	2014-04-21	am	f	simulation cube
55	81	4	2014-04-21	pm	f	
55	81	4	2014-04-22	am	f	
55	81	4	2014-04-22	pm	f	
55	81	4	2014-04-23	am	f	
55	81	4	2014-04-23	pm	f	
55	65	4	2014-04-24	am	f	telecon Poncet/Scodeggio/Molinari
55	80	4	2014-04-24	pm	f	telecon Marco Scodeggio
55	81	4	2014-04-25	am	f	preparation sprint
55	81	4	2014-04-25	pm	f	preparation sprint
67	96	4	2014-05-14	am	f	PREDON
67	96	4	2014-05-14	pm	f	PREDON
66	89	4	2014-05-15	am	f	GEstion equipe
66	89	4	2014-05-15	pm	f	GEstion equipe
66	133	4	2014-05-16	am	f	plan de charge
66	133	4	2014-05-16	pm	f	plan de charge
\N	\N	4	2014-05-01	am	t	
\N	\N	4	2014-05-01	pm	t	
\N	\N	4	2014-05-02	am	t	
\N	\N	4	2014-05-02	pm	t	
67	65	4	2014-05-05	am	f	EUCLID Science - Marseille
67	65	4	2014-05-05	pm	f	EUCLID Science - Marseille
67	65	4	2014-05-06	am	f	EUCLID Science - Marseille
67	65	4	2014-05-06	pm	f	EUCLID Science - Marseille
67	65	4	2014-05-07	am	f	EUCLID Science - Marseille
67	65	4	2014-05-07	pm	f	EUCLID Science - Marseille
67	65	4	2014-05-08	am	f	EUCLID Science - Marseille
67	65	4	2014-05-08	pm	f	EUCLID Science - Marseille
67	65	4	2014-05-09	am	f	EUCLID Science - Marseille
67	65	4	2014-05-09	pm	f	EUCLID Science - Marseille
66	89	4	2014-05-12	am	f	Gestion personnel
66	89	4	2014-05-12	pm	f	Gestion personnel
67	96	4	2014-05-13	am	f	Reunion PREDON - Paris
67	96	4	2014-05-13	pm	f	Reunion PREDON - Paris
57	92	31	2014-06-30	pm	f	
57	92	31	2014-07-02	am	f	
57	92	31	2014-07-03	pm	f	
57	92	31	2014-07-04	am	f	
57	110	15	2014-06-27	pm	f	sphs problem
\N	\N	15	2014-06-30	am	t	
\N	\N	15	2014-06-30	pm	t	
\N	\N	15	2014-07-01	am	t	
\N	\N	15	2014-07-01	pm	t	
\N	\N	15	2014-07-02	am	t	
\N	\N	15	2014-07-02	pm	t	
\N	\N	15	2014-07-03	am	t	
\N	\N	15	2014-07-03	pm	t	
\N	\N	15	2014-07-04	am	t	
\N	\N	15	2014-07-04	pm	t	
57	110	15	2014-07-07	am	f	formation analysis
57	110	15	2014-07-07	pm	f	formation analysis
57	110	15	2014-07-08	am	f	formation analysis
57	110	15	2014-07-08	pm	f	formation analysis
57	92	31	2014-07-07	pm	f	
57	92	31	2014-07-08	am	f	
57	92	31	2014-07-08	pm	f	
57	92	31	2014-07-09	am	f	
57	92	31	2014-07-09	pm	f	
57	92	31	2014-07-10	am	f	
57	92	31	2014-07-10	pm	f	
57	92	31	2014-07-11	am	f	
57	92	31	2014-07-11	pm	f	
67	92	31	2014-07-15	am	f	
57	92	31	2014-07-16	pm	f	
57	92	31	2014-07-17	am	f	
57	92	31	2014-07-17	pm	f	
57	92	31	2014-07-18	am	f	
55	110	15	2014-07-09	am	f	accretion project
57	110	15	2014-07-09	pm	f	accretion project
55	110	15	2014-07-10	am	f	accretion project
57	110	15	2014-07-10	pm	f	accretion project
55	110	15	2014-07-11	am	f	accretion project
57	110	15	2014-07-11	pm	f	accretion project
55	110	15	2014-07-14	am	f	accretion project
55	110	15	2014-07-14	pm	f	accretion project
57	110	15	2014-07-15	am	f	accretion project
57	110	15	2014-07-15	pm	f	accretion project
55	110	15	2014-07-16	am	f	accretion project
57	110	15	2014-07-16	pm	f	accretion project
55	110	15	2014-07-17	pm	f	accretion project
\N	\N	15	2014-07-18	am	t	
\N	\N	15	2014-07-18	pm	t	
57	92	31	2014-07-21	pm	f	
57	92	31	2014-07-22	pm	f	
63	89	5	2014-06-16	pm	f	maintenance
63	85	5	2014-06-17	am	f	cluster
63	85	5	2014-06-17	pm	f	cluster
63	85	5	2014-06-18	am	f	cluster
63	85	5	2014-06-18	pm	f	cluster
63	85	5	2014-06-19	am	f	cluster
63	85	5	2014-06-19	pm	f	cluster
63	85	5	2014-06-20	am	f	cluster
63	85	5	2014-06-20	pm	f	cluster
55	103	5	2014-06-23	am	f	
69	103	5	2014-06-23	pm	f	
67	100	5	2014-06-24	am	f	
67	100	5	2014-06-24	pm	f	
63	85	5	2014-06-25	am	f	cluster
63	85	5	2014-06-25	pm	f	cluster
63	85	5	2014-06-26	am	f	cluster
63	85	5	2014-06-26	pm	f	cluster
63	85	5	2014-06-27	am	f	cluster
63	85	5	2014-06-27	pm	f	cluster
63	85	5	2014-06-30	am	f	cluster
63	85	5	2014-06-30	pm	f	cluster
63	85	5	2014-07-01	am	f	cluster
63	85	5	2014-07-01	pm	f	cluster
63	85	5	2014-07-02	am	f	cluster
63	85	5	2014-07-02	pm	f	cluster
63	85	5	2014-07-03	am	f	cluster
63	85	5	2014-07-03	pm	f	cluster
63	85	5	2014-07-04	am	f	cluster
63	85	5	2014-07-04	pm	f	cluster
63	85	5	2014-07-07	am	f	cluster
63	85	5	2014-07-07	pm	f	cluster
63	85	5	2014-07-08	am	f	cluster
63	85	5	2014-07-08	pm	f	cluster
63	85	5	2014-07-09	am	f	cluster
63	85	5	2014-07-09	pm	f	cluster
\N	\N	5	2014-07-10	am	t	
\N	\N	5	2014-07-10	pm	t	
\N	\N	5	2014-07-11	am	t	
\N	\N	5	2014-07-11	pm	t	
\N	\N	5	2014-07-14	am	t	
\N	\N	5	2014-07-14	pm	t	
\N	\N	5	2014-07-15	am	t	
\N	\N	5	2014-07-15	pm	t	
\N	\N	5	2014-07-16	am	t	
\N	\N	5	2014-07-16	pm	t	
\N	\N	5	2014-07-17	am	t	
\N	\N	5	2014-07-17	pm	t	
\N	\N	5	2014-07-18	am	t	
\N	\N	5	2014-07-18	pm	t	
55	84	5	2014-07-21	am	f	Rosetta
55	84	5	2014-07-21	pm	f	Rosetta
55	84	5	2014-07-22	am	f	Rosetta
55	84	5	2014-07-22	pm	f	Rosetta
55	84	5	2014-07-23	am	f	Rosetta
55	84	5	2014-07-23	pm	f	Rosetta
55	84	5	2014-07-24	am	f	Rosetta
55	84	5	2014-07-24	pm	f	Rosetta
55	89	5	2014-07-25	am	f	fitscut2png
55	84	5	2014-07-25	pm	f	fitscut2png
71	89	5	2014-07-28	am	f	
73	110	15	2014-07-21	am	f	accretion project
73	110	15	2014-07-21	pm	f	accretion project
72	110	15	2014-07-23	am	f	bar project
72	110	15	2014-07-23	pm	f	bar project
72	110	15	2014-07-24	am	f	bar project
72	110	15	2014-07-24	pm	f	bar project
72	110	15	2014-07-25	am	f	bar project
72	110	15	2014-07-25	pm	f	bar project
73	110	15	2014-07-28	am	f	accretion project
73	110	15	2014-07-28	pm	f	accretion project
57	72	15	2014-07-22	am	f	/tmp issue
57	72	15	2014-07-22	pm	f	/tmp issue
73	110	15	2014-07-29	am	f	accretion project
57	72	15	2014-07-29	pm	f	rosetta
57	72	15	2014-07-30	am	f	rosetta
55	110	15	2014-07-30	pm	f	accretion project
55	110	15	2014-07-31	am	f	accretion project
72	110	15	2014-07-31	pm	f	accretion project
72	110	15	2014-08-01	am	f	accretion project
72	110	15	2014-08-01	pm	f	accretion project
72	110	15	2014-08-04	am	f	accretion project
72	110	15	2014-08-04	pm	f	accretion project
72	110	15	2014-08-05	am	f	accretion project
55	110	15	2014-08-05	pm	f	accretion project
55	110	15	2014-08-06	am	f	accretion project
55	110	15	2014-08-06	pm	f	accretion project
57	72	15	2014-08-07	am	f	rosetta
57	72	15	2014-08-07	pm	f	rosetta
57	72	15	2014-08-08	am	f	rosetta
55	110	15	2014-08-08	pm	f	accretion project
55	110	15	2014-08-11	am	f	accretion project
55	110	15	2014-08-11	pm	f	accretion project
55	110	15	2014-08-12	am	f	accretion project
55	110	15	2014-08-12	pm	f	accretion project
57	72	15	2014-08-13	am	f	rosetta
57	72	15	2014-08-13	pm	f	rosetta
57	72	15	2014-08-14	am	f	rosetta
55	110	15	2014-08-14	pm	f	accretion project
\N	\N	14	2014-07-11	am	t	
\N	\N	14	2014-07-11	pm	t	
\N	\N	14	2014-07-14	am	t	
\N	\N	14	2014-07-14	pm	t	
\N	\N	14	2014-07-15	am	t	
\N	\N	14	2014-07-15	pm	t	
\N	\N	14	2014-07-16	am	t	
\N	\N	14	2014-07-16	pm	t	
\N	\N	14	2014-07-17	am	t	
\N	\N	14	2014-07-17	pm	t	
\N	\N	14	2014-07-18	am	t	
\N	\N	14	2014-07-18	pm	t	
\N	\N	14	2014-08-04	am	t	
\N	\N	14	2014-08-04	pm	t	
\N	\N	14	2014-08-05	am	t	
\N	\N	14	2014-08-05	pm	t	
\N	\N	14	2014-08-06	am	t	
\N	\N	14	2014-08-06	pm	t	
\N	\N	14	2014-08-07	am	t	
\N	\N	14	2014-08-07	pm	t	
\N	\N	14	2014-08-08	am	t	
\N	\N	14	2014-08-08	pm	t	
\N	\N	14	2014-08-11	am	t	
\N	\N	14	2014-08-11	pm	t	
\N	\N	14	2014-08-12	am	t	
\N	\N	14	2014-08-12	pm	t	
\N	\N	14	2014-08-13	am	t	
\N	\N	14	2014-08-13	pm	t	
\N	\N	14	2014-08-14	am	t	
\N	\N	14	2014-08-14	pm	t	
\N	\N	14	2014-08-15	am	t	
\N	\N	14	2014-08-15	pm	t	
57	64	35	2014-06-13	am	f	Fix bugs : import fixtures
57	64	35	2014-06-13	pm	f	Fix bugs : import fixtures
57	64	35	2014-06-16	am	f	Fix bugs : import fixtures
57	64	35	2014-06-16	pm	f	Fix bugs : import fixtures
57	64	35	2014-06-17	am	f	Fix bugs : import fixtures
57	64	35	2014-06-17	pm	f	Fix bugs : import fixtures
57	64	35	2014-06-18	am	f	Fix bugs : import fixtures
57	64	35	2014-06-18	pm	f	Fix bugs : import fixtures
57	64	35	2014-06-19	am	f	Fix bugs : import fixtures
57	64	35	2014-06-19	pm	f	Fix bugs : import fixtures
57	64	35	2014-06-20	am	f	Fix bugs : import fixtures
57	64	35	2014-06-20	pm	f	Fix bugs : import fixtures
\N	\N	35	2014-08-11	am	t	
\N	\N	35	2014-08-11	pm	t	
\N	\N	35	2014-08-12	am	t	
\N	\N	35	2014-08-12	pm	t	
\N	\N	35	2014-08-13	am	t	
\N	\N	35	2014-08-13	pm	t	
\N	\N	35	2014-08-14	am	t	
\N	\N	35	2014-08-14	pm	t	
\N	\N	35	2014-08-15	am	t	
\N	\N	35	2014-08-15	pm	t	
\N	\N	35	2014-08-18	am	t	
\N	\N	35	2014-08-18	pm	t	
\N	\N	35	2014-08-19	am	t	
\N	\N	35	2014-08-19	pm	t	
\N	\N	35	2014-08-20	am	t	
\N	\N	35	2014-08-20	pm	t	
\N	\N	35	2014-08-21	am	t	
\N	\N	35	2014-08-21	pm	t	
\N	\N	35	2014-08-22	am	t	
\N	\N	35	2014-08-22	pm	t	
55	74	35	2014-06-24	am	f	
55	74	35	2014-06-24	pm	f	
55	74	35	2014-06-25	am	f	
55	74	35	2014-06-25	pm	f	
55	74	35	2014-06-26	am	f	
55	74	35	2014-06-26	pm	f	
55	74	35	2014-06-27	am	f	
55	74	35	2014-06-27	pm	f	
55	74	35	2014-06-30	am	f	
55	74	35	2014-06-30	pm	f	
55	74	35	2014-07-01	am	f	
55	74	35	2014-07-01	pm	f	
55	74	35	2014-07-02	am	f	
55	74	35	2014-07-02	pm	f	
55	74	35	2014-07-03	am	f	
55	74	35	2014-07-03	pm	f	
55	74	35	2014-07-04	am	f	
55	74	35	2014-07-04	pm	f	
55	74	35	2014-07-07	am	f	
55	74	35	2014-07-07	pm	f	
55	74	35	2014-07-08	am	f	
55	74	35	2014-07-08	pm	f	
55	74	35	2014-07-09	am	f	
55	74	35	2014-07-09	pm	f	
55	74	35	2014-07-10	am	f	
55	74	35	2014-07-10	pm	f	
55	74	35	2014-07-11	am	f	
55	74	35	2014-07-11	pm	f	
55	74	35	2014-07-14	am	f	
55	74	35	2014-07-14	pm	f	
55	74	35	2014-07-15	am	f	
55	74	35	2014-07-15	pm	f	
55	74	35	2014-07-16	am	f	
55	74	35	2014-07-16	pm	f	
55	74	35	2014-07-17	am	f	
55	74	35	2014-07-17	pm	f	
55	74	35	2014-07-18	am	f	
55	74	35	2014-07-18	pm	f	
55	74	35	2014-07-21	am	f	
55	74	35	2014-07-21	pm	f	
55	74	35	2014-07-22	am	f	
55	74	35	2014-07-22	pm	f	
55	74	35	2014-07-23	am	f	
55	74	35	2014-07-23	pm	f	
55	74	35	2014-07-24	am	f	
55	74	35	2014-07-24	pm	f	
55	74	35	2014-07-25	am	f	
55	74	35	2014-07-25	pm	f	
55	74	35	2014-07-28	am	f	
55	74	35	2014-07-28	pm	f	
55	74	35	2014-07-29	am	f	
55	74	35	2014-07-29	pm	f	
55	74	35	2014-07-30	am	f	
55	74	35	2014-07-30	pm	f	
55	74	35	2014-07-31	am	f	
55	74	35	2014-07-31	pm	f	
55	74	35	2014-08-01	am	f	
55	74	35	2014-08-01	pm	f	
55	74	35	2014-08-04	am	f	
55	74	35	2014-08-04	pm	f	
55	74	35	2014-08-05	am	f	
55	74	35	2014-08-05	pm	f	
55	74	35	2014-08-06	am	f	
55	74	35	2014-08-06	pm	f	
55	74	35	2014-08-07	am	f	
55	74	35	2014-08-07	pm	f	
55	74	35	2014-08-08	am	f	
55	74	35	2014-08-08	pm	f	
55	74	35	2014-08-25	am	f	
55	74	35	2014-08-25	pm	f	
55	74	35	2014-08-26	am	f	
55	74	35	2014-08-26	pm	f	
55	74	35	2014-08-27	am	f	
55	74	35	2014-08-27	pm	f	
55	74	35	2014-08-28	am	f	
55	74	35	2014-08-28	pm	f	
55	74	35	2014-08-29	am	f	
55	74	35	2014-08-29	pm	f	
71	64	35	2014-06-23	am	f	RDV Laurence Stresse : PFS fixtures
71	64	35	2014-06-23	pm	f	RDV Laurence Stresse : PFS fixtures
\N	\N	15	2014-08-15	am	t	
\N	\N	15	2014-08-15	pm	t	
57	72	15	2014-08-18	am	f	meshpc_dist
57	72	15	2014-08-18	pm	f	meshpc_dist
57	72	15	2014-08-19	am	f	meshpc_dist
57	72	15	2014-08-19	pm	f	meshpc_dist
57	72	15	2014-08-20	am	f	meshpc_dist
72	110	15	2014-08-20	pm	f	bar project
55	110	15	2014-08-21	am	f	galaxy formation project
55	110	15	2014-08-21	pm	f	galaxy formation project
72	110	15	2014-08-22	am	f	bar project
\N	\N	15	2014-08-22	pm	t	
\N	\N	15	2014-08-25	am	t	
72	110	15	2014-08-25	pm	f	bar project
72	110	15	2014-08-26	am	f	bar project
72	110	15	2014-08-26	pm	f	bar project
72	110	15	2014-08-27	am	f	bar project
72	110	15	2014-08-27	pm	f	bar project
55	110	15	2014-08-28	am	f	galaxy formation project
55	110	15	2014-08-28	pm	f	galaxy formation project
55	110	15	2014-08-29	am	f	galaxy formation project
57	115	15	2014-08-29	pm	f	some small stuff + discussion + arxiv
\N	\N	15	2014-09-01	am	t	
\N	\N	15	2014-09-01	pm	t	
\N	\N	15	2014-09-02	am	t	
\N	\N	15	2014-09-02	pm	t	
\N	\N	15	2014-09-03	am	t	
\N	\N	15	2014-09-03	pm	t	
\N	\N	15	2014-09-04	am	t	
\N	\N	15	2014-09-04	pm	t	
\N	\N	15	2014-09-05	am	t	
\N	\N	15	2014-09-05	pm	t	
55	110	15	2014-09-08	am	f	accretion project
62	89	15	2014-09-08	pm	f	formation Anglais
55	110	15	2014-09-09	am	f	accretion project
55	110	15	2014-09-09	pm	f	accretion project
67	92	31	2014-09-15	pm	f	
67	92	31	2014-09-16	am	f	
67	92	31	2014-09-16	pm	f	
57	92	31	2014-09-19	pm	f	
57	92	31	2014-09-24	pm	f	
67	92	31	2014-09-25	am	f	
59	92	31	2014-09-26	pm	f	
\N	\N	5	2014-08-08	am	t	
\N	\N	5	2014-08-08	pm	t	
\N	\N	5	2014-08-11	am	t	
\N	\N	5	2014-08-11	pm	t	
\N	\N	5	2014-08-12	am	t	
\N	\N	5	2014-08-12	pm	t	
\N	\N	5	2014-08-13	am	t	
\N	\N	5	2014-08-13	pm	t	
\N	\N	5	2014-08-14	am	t	
\N	\N	5	2014-08-14	pm	t	
\N	\N	5	2014-08-15	am	t	
\N	\N	5	2014-08-15	pm	t	
\N	\N	5	2014-08-18	am	t	
\N	\N	5	2014-08-18	pm	t	
\N	\N	5	2014-08-19	am	t	
\N	\N	5	2014-08-19	pm	t	
\N	\N	5	2014-08-20	am	t	
\N	\N	5	2014-08-20	pm	t	
\N	\N	5	2014-08-21	am	t	
\N	\N	5	2014-08-21	pm	t	
\N	\N	5	2014-08-22	am	t	
\N	\N	5	2014-08-22	pm	t	
\N	\N	5	2014-09-19	am	t	
\N	\N	5	2014-09-19	pm	t	
\N	\N	5	2014-09-26	pm	t	
63	89	5	2014-07-28	pm	f	
57	84	5	2014-07-29	am	f	OSIRIS retrieve data 
57	84	5	2014-07-29	pm	f	OSIRIS retrieve data 
57	84	5	2014-07-30	am	f	OSIRIS retrieve data 
57	84	5	2014-07-30	pm	f	OSIRIS retrieve data 
57	84	5	2014-07-31	am	f	OSIRIS retrieve data 
57	84	5	2014-07-31	pm	f	OSIRIS retrieve data 
57	84	5	2014-08-01	am	f	OSIRIS retrieve data 
57	84	5	2014-08-01	pm	f	OSIRIS retrieve data 
63	89	5	2014-08-04	am	f	
63	89	5	2014-08-04	pm	f	
63	89	5	2014-08-05	am	f	
63	89	5	2014-08-05	pm	f	
63	89	5	2014-08-06	am	f	
63	89	5	2014-08-06	pm	f	
63	89	5	2014-08-07	am	f	
63	89	5	2014-08-07	pm	f	
63	89	5	2014-08-25	am	f	
63	89	5	2014-08-25	pm	f	
63	89	5	2014-08-26	am	f	
63	89	5	2014-08-26	pm	f	
63	89	5	2014-08-27	am	f	
63	89	5	2014-08-27	pm	f	
63	89	5	2014-08-28	am	f	
63	89	5	2014-08-28	pm	f	
63	89	5	2014-08-29	am	f	
63	89	5	2014-08-29	pm	f	
63	89	5	2014-09-01	am	f	
63	89	5	2014-09-01	pm	f	
63	89	5	2014-09-02	am	f	
63	89	5	2014-09-02	pm	f	
63	89	5	2014-09-03	am	f	
63	89	5	2014-09-03	pm	f	
63	89	5	2014-09-04	am	f	
63	89	5	2014-09-04	pm	f	
63	89	5	2014-09-05	am	f	
63	89	5	2014-09-05	pm	f	
63	89	5	2014-09-08	am	f	
63	89	5	2014-09-08	pm	f	
63	89	5	2014-09-09	am	f	
63	89	5	2014-09-09	pm	f	
63	89	5	2014-09-10	am	f	
63	89	5	2014-09-10	pm	f	
63	89	5	2014-09-11	am	f	
63	89	5	2014-09-11	pm	f	
63	89	5	2014-09-12	am	f	
63	89	5	2014-09-12	pm	f	
63	89	5	2014-09-15	am	f	
61	89	5	2014-09-15	pm	f	
61	89	5	2014-09-16	am	f	
61	89	5	2014-09-16	pm	f	
61	89	5	2014-09-17	am	f	
61	89	5	2014-09-17	pm	f	
61	89	5	2014-09-18	am	f	
61	89	5	2014-09-18	pm	f	
63	89	5	2014-09-22	am	f	
61	89	5	2014-09-22	pm	f	
61	89	5	2014-09-23	am	f	
61	89	5	2014-09-23	pm	f	
61	89	5	2014-09-24	am	f	
61	89	5	2014-09-24	pm	f	
61	89	5	2014-09-25	am	f	
61	89	5	2014-09-25	pm	f	
61	89	5	2014-09-26	am	f	
63	89	5	2014-09-29	am	f	
57	92	31	2014-09-29	am	f	
67	92	31	2014-10-09	pm	f	
55	110	15	2014-09-10	am	f	Galaxy formation project
55	110	15	2014-09-10	pm	f	Galaxy formation project
55	110	15	2014-09-11	am	f	Galaxy formation project
55	110	15	2014-09-11	pm	f	Galaxy formation project
55	110	15	2014-09-12	am	f	Galaxy formation project
55	110	15	2014-09-12	pm	f	Galaxy formation project
55	110	15	2014-09-15	am	f	Galaxy formation project
62	85	15	2014-09-15	pm	f	English course
55	110	15	2014-09-16	am	f	Galaxy formation project
55	110	15	2014-09-16	pm	f	Galaxy formation project
55	110	15	2014-09-17	am	f	Galaxy formation project
55	110	15	2014-09-17	pm	f	Galaxy formation project
55	110	15	2014-09-18	am	f	Galaxy formation project
55	110	15	2014-09-18	pm	f	Galaxy formation project
55	110	15	2014-09-19	am	f	Galaxy formation project
55	110	15	2014-09-19	pm	f	Galaxy formation project
55	110	15	2014-09-22	am	f	Galaxy formation project
62	85	15	2014-09-22	pm	f	English course
55	110	15	2014-09-23	am	f	Galaxy formation project
55	110	15	2014-09-23	pm	f	Galaxy formation project
55	110	15	2014-09-24	am	f	Galaxy formation project
55	110	15	2014-09-24	pm	f	Galaxy formation project
55	110	15	2014-09-25	am	f	Galaxy formation project
55	110	15	2014-09-25	pm	f	Galaxy formation project
55	110	15	2014-09-26	am	f	Galaxy formation project
55	110	15	2014-09-26	pm	f	Galaxy formation project
55	110	15	2014-09-29	am	f	Galaxy formation project
62	85	15	2014-09-29	pm	f	English course
55	110	15	2014-09-30	am	f	Galaxy formation project
55	110	15	2014-09-30	pm	f	Galaxy formation project
55	110	15	2014-10-01	am	f	Galaxy formation project
55	110	15	2014-10-01	pm	f	Galaxy formation project
55	110	15	2014-10-02	am	f	Galaxy formation project
55	110	15	2014-10-02	pm	f	Galaxy formation project
55	110	15	2014-10-03	am	f	Galaxy formation project
62	85	15	2014-10-06	pm	f	English course
\N	\N	15	2014-10-09	pm	t	
57	72	15	2014-10-10	pm	f	mesh 2 point clound distance
57	72	15	2014-10-13	am	f	mesh 2 mesh distance minimization
62	85	15	2014-10-13	pm	f	english course
57	72	15	2014-10-14	am	f	mesh 2 mesh distance minimization
57	72	15	2014-10-14	pm	f	mesh 2 mesh distance minimization
57	72	15	2014-10-15	am	f	mesh 2 mesh distance minimization
\N	\N	15	2014-10-15	pm	t	
73	110	15	2014-10-16	am	f	make 2M isolated initial conditions
57	72	15	2014-10-16	pm	f	mesh 2 mesh distance minimization
67	92	31	2014-10-16	am	f	
55	85	5	2014-09-29	pm	f	
55	85	5	2014-09-30	am	f	
55	85	5	2014-09-30	pm	f	
55	85	5	2014-10-01	am	f	
55	85	5	2014-10-01	pm	f	
55	85	5	2014-10-02	am	f	
55	85	5	2014-10-02	pm	f	
55	85	5	2014-10-03	am	f	
55	85	5	2014-10-03	pm	f	
63	85	5	2014-10-06	am	f	
57	114	15	2014-10-06	am	f	ROSSBI mpi parallelisation
57	114	15	2014-10-07	am	f	ROSSBI mpi parallelisation
57	114	15	2014-10-08	am	f	ROSSBI mpi parallelisation
57	114	15	2014-10-08	pm	f	ROSSBI mpi parallelisation
57	114	15	2014-10-09	am	f	ROSSBI mpi parallelisation
57	114	15	2014-10-10	am	f	ROSSBI mpi parallelisation
57	85	5	2014-10-06	pm	f	
57	85	5	2014-10-07	am	f	
57	85	5	2014-10-07	pm	f	
57	85	5	2014-10-08	am	f	
57	85	5	2014-10-08	pm	f	
57	85	5	2014-10-09	am	f	
71	85	5	2014-10-09	pm	f	
71	85	5	2014-10-10	am	f	
71	85	5	2014-10-10	pm	f	
63	89	5	2014-10-13	am	f	
71	85	5	2014-10-13	pm	f	
71	85	5	2014-10-14	am	f	
71	85	5	2014-10-14	pm	f	
71	85	5	2014-10-15	am	f	
71	85	5	2014-10-15	pm	f	
71	85	5	2014-10-16	am	f	
71	85	5	2014-10-16	pm	f	
71	85	5	2014-10-17	am	f	
71	85	5	2014-10-17	pm	f	
63	89	5	2014-10-20	am	f	
57	114	15	2014-10-03	pm	f	ROSSBI mpi parallelisation
57	114	15	2014-10-07	pm	f	ROSSBI mpi parallelisation
57	114	15	2014-10-17	am	f	ROSSBI mpi parallelisation
57	114	15	2014-10-17	pm	f	ROSSBI mpi parallelisation
57	114	15	2014-10-20	am	f	ROSSBI mpi parallelisation
57	114	15	2014-10-20	pm	f	ROSSBI mpi parallelisation
57	114	15	2014-10-21	am	f	ROSSBI mpi parallelisation
57	114	15	2014-10-21	pm	f	ROSSBI mpi parallelisation
57	114	15	2014-10-22	am	f	ROSSBI mpi parallelisation
57	114	15	2014-10-22	pm	f	ROSSBI mpi parallelisation
\N	\N	15	2014-10-23	am	t	
\N	\N	15	2014-10-23	pm	t	
57	114	15	2014-10-24	am	f	ROSSBI mpi parallelisation
57	114	15	2014-10-24	pm	f	ROSSBI mpi parallelisation
57	114	15	2014-10-27	am	f	ROSSBI mpi parallelisation
57	114	15	2014-10-27	pm	f	ROSSBI mpi parallelisation
57	114	15	2014-10-28	am	f	ROSSBI mpi parallelisation
57	114	15	2014-10-28	pm	f	ROSSBI mpi parallelisation
57	114	15	2014-10-29	am	f	ROSSBI mpi parallelisation
57	72	15	2014-10-29	pm	f	small stuff for mesh to pc distance
73	110	15	2014-10-30	am	f	IDF 2M
57	114	15	2014-10-30	pm	f	ROSSBI mpi parallelisation
\N	\N	4	2014-08-04	am	t	
\N	\N	4	2014-08-04	pm	t	
\N	\N	4	2014-08-05	am	t	
\N	\N	4	2014-08-05	pm	t	
\N	\N	4	2014-08-06	am	t	
\N	\N	4	2014-08-06	pm	t	
\N	\N	4	2014-08-07	am	t	
\N	\N	4	2014-08-07	pm	t	
\N	\N	4	2014-08-08	am	t	
\N	\N	4	2014-08-08	pm	t	
\N	\N	4	2014-08-11	am	t	
\N	\N	4	2014-08-11	pm	t	
\N	\N	4	2014-08-12	am	t	
\N	\N	4	2014-08-12	pm	t	
\N	\N	4	2014-08-13	am	t	
\N	\N	4	2014-08-13	pm	t	
\N	\N	4	2014-08-14	am	t	
\N	\N	4	2014-08-14	pm	t	
\N	\N	4	2014-08-15	am	t	
\N	\N	4	2014-08-15	pm	t	
\N	\N	4	2014-08-18	am	t	
\N	\N	4	2014-08-18	pm	t	
\N	\N	4	2014-08-19	am	t	
\N	\N	4	2014-08-19	pm	t	
\N	\N	4	2014-08-20	am	t	
\N	\N	4	2014-08-20	pm	t	
\N	\N	4	2014-08-21	am	t	
\N	\N	4	2014-08-21	pm	t	
\N	\N	4	2014-08-22	am	t	
\N	\N	4	2014-08-22	pm	t	
\N	\N	4	2014-08-25	am	t	
\N	\N	4	2014-08-25	pm	t	
\N	\N	4	2014-08-26	am	t	
\N	\N	4	2014-08-26	pm	t	
\N	\N	4	2014-08-27	am	t	
\N	\N	4	2014-08-27	pm	t	
\N	\N	4	2014-08-28	am	t	
\N	\N	4	2014-08-28	pm	t	
\N	\N	4	2014-08-29	am	t	
\N	\N	4	2014-08-29	pm	t	
57	92	31	2014-11-04	am	f	
67	92	31	2014-11-06	am	f	
57	92	31	2014-11-06	pm	f	
72	115	15	2014-10-31	am	f	preparing workshop
72	115	15	2014-10-31	pm	f	preparing workshop
\N	\N	15	2014-11-03	am	t	
\N	\N	15	2014-11-03	pm	t	
\N	\N	15	2014-11-04	am	t	
\N	\N	15	2014-11-04	pm	t	
\N	\N	15	2014-11-05	am	t	
\N	\N	15	2014-11-05	pm	t	
\N	\N	15	2014-11-06	am	t	
\N	\N	15	2014-11-06	pm	t	
\N	\N	15	2014-11-07	am	t	
\N	\N	15	2014-11-07	pm	t	
\N	\N	15	2014-11-10	am	t	
\N	\N	15	2014-11-10	pm	t	
\N	\N	15	2014-11-11	am	t	
\N	\N	15	2014-11-11	pm	t	
72	115	15	2014-11-12	am	f	preparing workshop
72	115	15	2014-11-12	pm	f	preparing workshop
67	115	15	2014-11-13	am	f	workshop local ETKF
67	115	15	2014-11-13	pm	f	workshop local ETKF
67	115	15	2014-11-14	am	f	workshop local ETKF
67	115	15	2014-11-14	pm	f	workshop local ETKF
72	115	15	2014-11-17	am	f	post workshop  work
62	85	15	2014-11-17	pm	f	english course
57	114	15	2014-11-18	am	f	Rossbi (hdf5 paralllel study)
57	114	15	2014-11-18	pm	f	Rossbi (hdf5 parallel study)
55	115	15	2014-11-19	am	f	discussions with Thomas (templates) and Morgan(MCAO)
57	114	15	2014-11-19	pm	f	hdf5 for output
57	114	15	2014-11-20	am	f	hdf5 for output
73	110	15	2014-11-20	pm	f	discussion + run DCC tests for 97
57	114	15	2014-11-21	am	f	Rossbi MPI
73	110	15	2014-11-21	pm	f	density cut cooling
57	114	15	2014-11-24	am	f	Rossbi MPI
57	114	15	2014-11-24	pm	f	Rossbi MPI
57	114	15	2014-11-25	am	f	Rossbi MPI
57	114	15	2014-11-25	pm	f	Rossbi MPI
73	110	15	2014-11-26	am	f	density cut cooling
57	114	15	2014-11-26	pm	f	Rossbi MPI
67	115	15	2014-11-27	am	f	discussion with Thomas
57	114	15	2014-11-27	pm	f	Rossbi MPI
73	110	15	2014-11-28	am	f	density cut cooling
73	110	15	2014-11-28	pm	f	density cut cooling
\N	\N	15	2014-12-01	am	t	
62	85	15	2014-12-01	pm	f	english course
\N	\N	15	2014-12-02	am	t	
\N	\N	15	2014-12-02	pm	t	
73	110	15	2014-12-03	am	f	density cut cooling
73	110	15	2014-12-03	pm	f	density cut cooling
67	115	15	2014-12-04	am	f	discussion with Thomas
73	110	15	2014-12-04	pm	f	density cut cooling
57	114	15	2014-12-05	am	f	Rossbi MPI
57	114	15	2014-12-05	pm	f	Rossbi MPI
57	114	15	2014-12-08	am	f	Rossbi MPI
57	114	15	2014-12-08	pm	f	Rossbi MPI
73	110	15	2014-12-09	am	f	density cut cooling
73	110	15	2014-12-09	pm	f	density cut cooling
73	110	15	2014-12-10	am	f	galaxy formation project
57	114	15	2014-12-10	pm	f	Rossbi MPI
57	114	15	2014-12-11	am	f	Rossbi MPI
57	114	15	2014-12-11	pm	f	Rossbi MPI
57	114	15	2014-12-12	am	f	Rossbi MPI
57	114	15	2014-12-12	pm	f	Rossbi MPI
57	114	15	2014-12-15	am	f	Rossbi MPI
57	115	15	2014-12-15	pm	f	COMPASS Kalman (discussion with Thomas and Morgan)
57	115	15	2014-12-16	am	f	COMPASS local ETKF (discussion with Thomas and Morgan)
\N	\N	15	2014-12-16	pm	t	
73	110	15	2014-12-17	am	f	galaxy formation project
73	110	15	2014-12-17	pm	f	galaxy formation project
73	110	15	2014-12-18	am	f	galaxy formation project
73	110	15	2014-12-18	pm	f	galaxy formation project
73	110	15	2014-12-19	am	f	galaxy formation project
73	110	15	2014-12-19	pm	f	galaxy formation project
73	110	15	2014-12-22	am	f	galaxy formation project
73	110	15	2014-12-22	pm	f	galaxy formation project
73	110	15	2014-12-23	am	f	galaxy formation project
73	110	15	2014-12-23	pm	f	galaxy formation project
\N	\N	5	2014-12-15	am	t	
\N	\N	5	2014-12-15	pm	t	
\N	\N	5	2014-12-16	am	t	
\N	\N	5	2014-12-16	pm	t	
\N	\N	5	2014-12-17	am	t	
\N	\N	5	2014-12-17	pm	t	
\N	\N	5	2014-12-18	am	t	
\N	\N	5	2014-12-18	pm	t	
\N	\N	5	2014-12-19	am	t	
\N	\N	5	2014-12-19	pm	t	
\N	\N	5	2014-12-22	am	t	
\N	\N	5	2014-12-22	pm	t	
\N	\N	5	2014-12-23	am	t	
\N	\N	5	2014-12-23	pm	t	
\N	\N	5	2014-12-24	am	t	
\N	\N	5	2014-12-24	pm	t	
\N	\N	5	2014-12-25	am	t	
\N	\N	5	2014-12-25	pm	t	
\N	\N	5	2014-12-26	am	t	
\N	\N	5	2014-12-26	pm	t	
\N	\N	5	2014-12-29	am	t	
\N	\N	5	2014-12-29	pm	t	
\N	\N	5	2014-12-30	am	t	
\N	\N	5	2014-12-30	pm	t	
\N	\N	5	2014-12-31	am	t	
\N	\N	5	2014-12-31	pm	t	
\N	\N	5	2015-01-01	am	t	
\N	\N	5	2015-01-01	pm	t	
\N	\N	5	2015-01-02	am	t	
\N	\N	5	2015-01-02	pm	t	
\N	\N	5	2014-11-11	am	t	
\N	\N	5	2014-11-11	pm	t	
63	89	5	2014-10-20	pm	f	Cluster Method
63	89	5	2014-10-21	am	f	Cluster Method
63	89	5	2014-10-21	pm	f	Cluster Method
63	89	5	2014-10-22	am	f	Cluster Method
63	89	5	2014-10-22	pm	f	Cluster Method
63	89	5	2014-10-23	am	f	Cluster Method
63	89	5	2014-10-23	pm	f	Cluster Method
63	89	5	2014-10-24	am	f	Cluster Method
63	89	5	2014-10-24	pm	f	Cluster Method
63	89	5	2014-10-27	am	f	Cluster Method
63	89	5	2014-10-27	pm	f	Cluster Method
63	89	5	2014-10-28	am	f	Cluster Method
63	89	5	2014-10-28	pm	f	Cluster Method
63	89	5	2014-10-29	am	f	Cluster Method
63	89	5	2014-10-29	pm	f	Cluster Method
63	89	5	2014-10-30	am	f	Cluster Method
63	89	5	2014-10-30	pm	f	Cluster Method
63	89	5	2014-10-31	am	f	Cluster Method
63	89	5	2014-10-31	pm	f	Cluster Method
63	89	5	2014-11-03	am	f	Cluster Method
63	89	5	2014-11-03	pm	f	Cluster Method
63	89	5	2014-11-04	am	f	Cluster Method
63	89	5	2014-11-04	pm	f	Cluster Method
63	89	5	2014-11-05	am	f	Cluster Method
63	89	5	2014-11-05	pm	f	Cluster Method
63	89	5	2014-11-06	am	f	Cluster Method
63	89	5	2014-11-06	pm	f	Cluster Method
63	89	5	2014-11-07	am	f	Cluster Method
63	89	5	2014-11-07	pm	f	Cluster Method
63	89	5	2014-11-10	am	f	Cluster Method
63	89	5	2014-11-10	pm	f	Cluster Method
63	89	5	2014-11-12	am	f	Cluster Method
63	89	5	2014-11-12	pm	f	Cluster Method
63	89	5	2014-11-13	am	f	Cluster Method
63	89	5	2014-11-13	pm	f	Cluster Method
63	89	5	2014-11-14	am	f	Cluster Method
63	89	5	2014-11-14	pm	f	Cluster Method
63	89	5	2014-11-17	am	f	Cluster Method
63	89	5	2014-11-17	pm	f	Cluster Method
63	89	5	2014-11-18	am	f	Cluster Method
63	89	5	2014-11-18	pm	f	Cluster Method
63	89	5	2014-11-19	am	f	Cluster Method
63	89	5	2014-11-19	pm	f	Cluster Method
63	89	5	2014-11-20	am	f	Cluster Method
63	89	5	2014-11-20	pm	f	Cluster Method
63	89	5	2014-11-21	am	f	Cluster Method
63	89	5	2014-11-21	pm	f	Cluster Method
63	89	5	2014-11-24	am	f	Cluster Method
63	89	5	2014-11-24	pm	f	Cluster Method
63	89	5	2014-11-25	am	f	Cluster Method
63	89	5	2014-11-25	pm	f	Cluster Method
63	89	5	2014-11-26	am	f	Cluster Method
63	89	5	2014-11-26	pm	f	Cluster Method
63	89	5	2014-11-27	am	f	Cluster Method
63	89	5	2014-11-27	pm	f	Cluster Method
63	89	5	2014-11-28	am	f	Cluster Method
63	89	5	2014-11-28	pm	f	Cluster Method
63	89	5	2014-12-01	am	f	Cluster Method
63	89	5	2014-12-01	pm	f	Cluster Method
63	89	5	2014-12-02	am	f	Cluster Method
63	89	5	2014-12-02	pm	f	Cluster Method
63	89	5	2014-12-03	am	f	Cluster Method
63	89	5	2014-12-03	pm	f	Cluster Method
63	89	5	2014-12-04	am	f	Cluster Method
63	89	5	2014-12-04	pm	f	Cluster Method
63	89	5	2014-12-05	am	f	Cluster Method
63	89	5	2014-12-05	pm	f	Cluster Method
63	89	5	2014-12-08	am	f	Cluster Method
63	89	5	2014-12-08	pm	f	Cluster Method
63	89	5	2014-12-09	am	f	Cluster Method
63	89	5	2014-12-09	pm	f	Cluster Method
63	89	5	2014-12-10	am	f	Cluster Method
63	89	5	2014-12-10	pm	f	Cluster Method
63	89	5	2014-12-11	am	f	Cluster Method
63	89	5	2014-12-11	pm	f	Cluster Method
63	89	5	2014-12-12	am	f	Cluster Method
63	89	5	2014-12-12	pm	f	Cluster Method
57	92	31	2014-12-08	am	f	
57	92	31	2014-12-09	am	f	
57	92	31	2014-12-10	am	f	
57	92	31	2014-12-11	am	f	
57	92	31	2014-12-12	am	f	
57	92	31	2014-12-15	am	f	
57	92	31	2014-12-16	pm	f	
57	92	31	2015-01-06	am	f	
\N	\N	8	2013-10-01	am	t	
\N	\N	8	2013-10-01	pm	t	
\N	\N	8	2013-10-02	am	t	
\N	\N	8	2013-10-02	pm	t	
\N	\N	8	2013-10-03	am	t	
\N	\N	8	2013-10-03	pm	t	
\N	\N	8	2013-10-04	am	t	
\N	\N	8	2013-10-04	pm	t	
\N	\N	8	2013-10-07	am	t	
\N	\N	8	2013-10-07	pm	t	
\N	\N	8	2013-10-08	am	t	
\N	\N	8	2013-10-08	pm	t	
\N	\N	8	2013-10-09	am	t	
\N	\N	8	2013-10-09	pm	t	
\N	\N	8	2013-10-10	am	t	
\N	\N	8	2013-10-10	pm	t	
\N	\N	8	2013-10-11	am	t	
\N	\N	8	2013-10-11	pm	t	
\N	\N	8	2013-10-14	am	t	
\N	\N	8	2013-10-14	pm	t	
\N	\N	8	2013-10-15	am	t	
\N	\N	8	2013-10-15	pm	t	
\N	\N	8	2013-10-16	am	t	
\N	\N	8	2013-10-16	pm	t	
\N	\N	8	2013-10-17	am	t	
\N	\N	8	2013-10-17	pm	t	
\N	\N	8	2013-10-18	am	t	
\N	\N	8	2013-10-18	pm	t	
\N	\N	8	2013-10-21	am	t	
\N	\N	8	2013-10-21	pm	t	
\N	\N	8	2013-10-22	am	t	
\N	\N	8	2013-10-22	pm	t	
\N	\N	8	2013-10-23	am	t	
\N	\N	8	2013-10-23	pm	t	
\N	\N	8	2013-10-24	am	t	
\N	\N	8	2013-10-24	pm	t	
\N	\N	8	2013-10-25	am	t	
\N	\N	8	2013-10-25	pm	t	
\N	\N	8	2013-10-28	am	t	
\N	\N	8	2013-10-28	pm	t	
\N	\N	8	2013-10-29	am	t	
\N	\N	8	2013-10-29	pm	t	
\N	\N	8	2013-10-30	am	t	
\N	\N	8	2013-10-30	pm	t	
\N	\N	8	2013-10-31	am	t	
\N	\N	8	2013-10-31	pm	t	
\N	\N	8	2013-11-01	am	t	
\N	\N	8	2013-11-01	pm	t	
\N	\N	8	2013-11-04	am	t	
\N	\N	8	2013-11-04	pm	t	
\N	\N	8	2013-11-05	am	t	
\N	\N	8	2013-11-05	pm	t	
\N	\N	8	2013-11-06	am	t	
\N	\N	8	2013-11-06	pm	t	
\N	\N	8	2013-11-07	am	t	
\N	\N	8	2013-11-07	pm	t	
\N	\N	8	2013-11-08	am	t	
\N	\N	8	2013-11-08	pm	t	
\N	\N	8	2013-11-11	am	t	
\N	\N	8	2013-11-11	pm	t	
\N	\N	8	2013-11-12	am	t	
\N	\N	8	2013-11-12	pm	t	
\N	\N	8	2013-11-13	am	t	
\N	\N	8	2013-11-13	pm	t	
\N	\N	8	2013-11-14	am	t	
\N	\N	8	2013-11-14	pm	t	
\N	\N	8	2013-11-15	am	t	
\N	\N	8	2013-11-15	pm	t	
\N	\N	8	2013-11-18	am	t	
\N	\N	8	2013-11-18	pm	t	
\N	\N	8	2013-11-19	am	t	
\N	\N	8	2013-11-19	pm	t	
\N	\N	8	2013-11-20	am	t	
\N	\N	8	2013-11-20	pm	t	
\N	\N	8	2013-11-21	am	t	
\N	\N	8	2013-11-21	pm	t	
\N	\N	8	2013-11-22	am	t	
\N	\N	8	2013-11-22	pm	t	
\N	\N	8	2013-11-25	am	t	
\N	\N	8	2013-11-25	pm	t	
\N	\N	8	2013-11-26	am	t	
\N	\N	8	2013-11-26	pm	t	
\N	\N	8	2013-11-27	am	t	
\N	\N	8	2013-11-27	pm	t	
\N	\N	8	2013-11-28	am	t	
\N	\N	8	2013-11-28	pm	t	
\N	\N	8	2013-11-29	am	t	
\N	\N	8	2013-11-29	pm	t	
\N	\N	8	2013-12-02	am	t	
\N	\N	8	2013-12-02	pm	t	
\N	\N	8	2013-12-03	am	t	
\N	\N	8	2013-12-03	pm	t	
\N	\N	8	2013-12-04	am	t	
\N	\N	8	2013-12-04	pm	t	
\N	\N	8	2013-12-05	am	t	
\N	\N	8	2013-12-05	pm	t	
\N	\N	8	2013-12-06	am	t	
\N	\N	8	2013-12-06	pm	t	
\N	\N	8	2013-12-09	am	t	
\N	\N	8	2013-12-09	pm	t	
\N	\N	8	2013-12-10	am	t	
\N	\N	8	2013-12-10	pm	t	
\N	\N	8	2013-12-11	am	t	
\N	\N	8	2013-12-11	pm	t	
\N	\N	8	2013-12-12	am	t	
\N	\N	8	2013-12-12	pm	t	
\N	\N	8	2013-12-13	am	t	
\N	\N	8	2013-12-13	pm	t	
\N	\N	8	2013-12-16	am	t	
\N	\N	8	2013-12-16	pm	t	
\N	\N	8	2013-12-17	am	t	
\N	\N	8	2013-12-17	pm	t	
\N	\N	8	2013-12-18	am	t	
\N	\N	8	2013-12-18	pm	t	
\N	\N	8	2013-12-19	am	t	
\N	\N	8	2013-12-19	pm	t	
\N	\N	8	2013-12-20	am	t	
\N	\N	8	2013-12-20	pm	t	
\N	\N	8	2013-12-23	am	t	
\N	\N	8	2013-12-23	pm	t	
\N	\N	8	2013-12-24	am	t	
\N	\N	8	2013-12-24	pm	t	
\N	\N	8	2013-12-25	am	t	
\N	\N	8	2013-12-25	pm	t	
\N	\N	8	2013-12-26	am	t	
\N	\N	8	2013-12-26	pm	t	
\N	\N	8	2013-12-27	am	t	
\N	\N	8	2013-12-27	pm	t	
\N	\N	8	2013-12-30	am	t	
\N	\N	8	2013-12-30	pm	t	
\N	\N	8	2013-12-31	am	t	
\N	\N	8	2013-12-31	pm	t	
\N	\N	8	2014-01-01	am	t	
\N	\N	8	2014-01-01	pm	t	
\N	\N	8	2014-01-02	am	t	
\N	\N	8	2014-01-02	pm	t	
\N	\N	8	2014-01-03	am	t	
\N	\N	8	2014-01-03	pm	t	
\N	\N	8	2014-01-06	am	t	
\N	\N	8	2014-01-06	pm	t	
\N	\N	8	2014-01-07	am	t	
\N	\N	8	2014-01-07	pm	t	
\N	\N	8	2014-01-08	am	t	
\N	\N	8	2014-01-08	pm	t	
\N	\N	8	2014-01-09	am	t	
\N	\N	8	2014-01-09	pm	t	
\N	\N	8	2014-01-10	am	t	
\N	\N	8	2014-01-10	pm	t	
\N	\N	8	2014-01-13	am	t	
\N	\N	8	2014-01-13	pm	t	
\N	\N	8	2014-01-14	am	t	
\N	\N	8	2014-01-14	pm	t	
\N	\N	8	2014-01-15	am	t	
\N	\N	8	2014-01-15	pm	t	
\N	\N	8	2014-01-16	am	t	
\N	\N	8	2014-01-16	pm	t	
\N	\N	8	2014-01-17	am	t	
\N	\N	8	2014-01-17	pm	t	
\N	\N	8	2014-01-20	am	t	
\N	\N	8	2014-01-20	pm	t	
\N	\N	8	2014-01-21	am	t	
\N	\N	8	2014-01-21	pm	t	
\N	\N	8	2014-01-22	am	t	
\N	\N	8	2014-01-22	pm	t	
\N	\N	8	2014-01-23	am	t	
\N	\N	8	2014-01-23	pm	t	
\N	\N	8	2014-01-24	am	t	
\N	\N	8	2014-01-24	pm	t	
\N	\N	8	2014-01-27	am	t	
\N	\N	8	2014-01-27	pm	t	
\N	\N	8	2014-01-28	am	t	
\N	\N	8	2014-01-28	pm	t	
\N	\N	8	2014-01-29	am	t	
\N	\N	8	2014-01-29	pm	t	
\N	\N	8	2014-01-30	am	t	
\N	\N	8	2014-01-30	pm	t	
\N	\N	8	2014-01-31	am	t	
\N	\N	8	2014-01-31	pm	t	
\N	\N	8	2014-02-03	am	t	
\N	\N	8	2014-02-03	pm	t	
\N	\N	8	2014-02-04	am	t	
\N	\N	8	2014-02-04	pm	t	
\N	\N	8	2014-02-05	am	t	
\N	\N	8	2014-02-05	pm	t	
\N	\N	8	2014-02-06	am	t	
\N	\N	8	2014-02-06	pm	t	
\N	\N	8	2014-02-07	am	t	
\N	\N	8	2014-02-07	pm	t	
\N	\N	8	2014-02-10	am	t	
\N	\N	8	2014-02-10	pm	t	
\N	\N	8	2014-02-11	am	t	
\N	\N	8	2014-02-11	pm	t	
\N	\N	8	2014-02-12	am	t	
\N	\N	8	2014-02-12	pm	t	
\N	\N	8	2014-02-13	am	t	
\N	\N	8	2014-02-13	pm	t	
\N	\N	8	2014-02-14	am	t	
\N	\N	8	2014-02-14	pm	t	
\N	\N	8	2014-02-17	am	t	
\N	\N	8	2014-02-17	pm	t	
\N	\N	8	2014-02-18	am	t	
\N	\N	8	2014-02-18	pm	t	
\N	\N	8	2014-02-19	am	t	
\N	\N	8	2014-02-19	pm	t	
\N	\N	8	2014-02-20	am	t	
\N	\N	8	2014-02-20	pm	t	
\N	\N	8	2014-02-21	am	t	
\N	\N	8	2014-02-21	pm	t	
\N	\N	8	2014-02-24	am	t	
\N	\N	8	2014-02-24	pm	t	
\N	\N	8	2014-02-25	am	t	
\N	\N	8	2014-02-25	pm	t	
\N	\N	8	2014-02-26	am	t	
\N	\N	8	2014-02-26	pm	t	
\N	\N	8	2014-02-27	am	t	
\N	\N	8	2014-02-27	pm	t	
\N	\N	8	2014-02-28	am	t	
\N	\N	8	2014-02-28	pm	t	
\N	\N	8	2014-03-03	am	t	
\N	\N	8	2014-03-03	pm	t	
\N	\N	8	2014-03-04	am	t	
\N	\N	8	2014-03-04	pm	t	
\N	\N	8	2014-03-05	am	t	
\N	\N	8	2014-03-05	pm	t	
\N	\N	8	2014-03-06	am	t	
\N	\N	8	2014-03-06	pm	t	
\N	\N	8	2014-03-07	am	t	
\N	\N	8	2014-03-07	pm	t	
\N	\N	8	2014-03-10	am	t	
\N	\N	8	2014-03-10	pm	t	
\N	\N	8	2014-03-11	am	t	
\N	\N	8	2014-03-11	pm	t	
\N	\N	8	2014-03-12	am	t	
\N	\N	8	2014-03-12	pm	t	
\N	\N	8	2014-03-13	am	t	
\N	\N	8	2014-03-13	pm	t	
\N	\N	8	2014-03-14	am	t	
\N	\N	8	2014-03-14	pm	t	
\N	\N	8	2014-03-17	am	t	
\N	\N	8	2014-03-17	pm	t	
\N	\N	8	2014-03-18	am	t	
\N	\N	8	2014-03-18	pm	t	
\N	\N	8	2014-03-19	am	t	
\N	\N	8	2014-03-19	pm	t	
\N	\N	8	2014-03-20	am	t	
\N	\N	8	2014-03-20	pm	t	
\N	\N	8	2014-03-21	am	t	
\N	\N	8	2014-03-21	pm	t	
\N	\N	8	2014-03-24	am	t	
\N	\N	8	2014-03-24	pm	t	
\N	\N	8	2014-03-25	am	t	
\N	\N	8	2014-03-25	pm	t	
\N	\N	8	2014-03-26	am	t	
\N	\N	8	2014-03-26	pm	t	
\N	\N	8	2014-03-27	am	t	
\N	\N	8	2014-03-27	pm	t	
\N	\N	8	2014-03-28	am	t	
\N	\N	8	2014-03-28	pm	t	
\N	\N	8	2014-03-31	am	t	
\N	\N	8	2014-03-31	pm	t	
\N	\N	8	2014-04-01	am	t	
\N	\N	8	2014-04-01	pm	t	
\N	\N	8	2014-04-02	am	t	
\N	\N	8	2014-04-02	pm	t	
\N	\N	8	2014-04-03	am	t	
\N	\N	8	2014-04-03	pm	t	
\N	\N	8	2014-04-04	am	t	
\N	\N	8	2014-04-04	pm	t	
\N	\N	8	2014-04-07	am	t	
\N	\N	8	2014-04-07	pm	t	
\N	\N	8	2014-04-08	am	t	
\N	\N	8	2014-04-08	pm	t	
\N	\N	8	2014-04-09	am	t	
\N	\N	8	2014-04-09	pm	t	
\N	\N	8	2014-04-10	am	t	
\N	\N	8	2014-04-10	pm	t	
\N	\N	8	2014-04-11	am	t	
\N	\N	8	2014-04-11	pm	t	
\N	\N	8	2014-04-14	am	t	
\N	\N	8	2014-04-14	pm	t	
\N	\N	8	2014-04-15	am	t	
\N	\N	8	2014-04-15	pm	t	
\N	\N	8	2014-04-16	am	t	
\N	\N	8	2014-04-16	pm	t	
\N	\N	8	2014-04-17	am	t	
\N	\N	8	2014-04-17	pm	t	
\N	\N	8	2014-04-18	am	t	
\N	\N	8	2014-04-18	pm	t	
\N	\N	8	2014-04-21	am	t	
\N	\N	8	2014-04-21	pm	t	
\N	\N	8	2014-04-22	am	t	
\N	\N	8	2014-04-22	pm	t	
\N	\N	8	2014-04-23	am	t	
\N	\N	8	2014-04-23	pm	t	
\N	\N	8	2014-04-24	am	t	
\N	\N	8	2014-04-24	pm	t	
\N	\N	8	2014-04-25	am	t	
\N	\N	8	2014-04-25	pm	t	
\N	\N	8	2014-04-28	am	t	
\N	\N	8	2014-04-28	pm	t	
\N	\N	8	2014-04-29	am	t	
\N	\N	8	2014-04-29	pm	t	
\N	\N	8	2014-04-30	am	t	
\N	\N	8	2014-04-30	pm	t	
\N	\N	8	2014-05-01	am	t	
\N	\N	8	2014-05-01	pm	t	
\N	\N	8	2014-05-02	am	t	
\N	\N	8	2014-05-02	pm	t	
\N	\N	8	2014-05-05	am	t	
\N	\N	8	2014-05-05	pm	t	
\N	\N	8	2014-05-06	am	t	
\N	\N	8	2014-05-06	pm	t	
\N	\N	8	2014-05-07	am	t	
\N	\N	8	2014-05-07	pm	t	
\N	\N	8	2014-05-08	am	t	
\N	\N	8	2014-05-08	pm	t	
\N	\N	8	2014-05-09	am	t	
\N	\N	8	2014-05-09	pm	t	
\N	\N	8	2014-05-12	am	t	
\N	\N	8	2014-05-12	pm	t	
\N	\N	8	2014-05-13	am	t	
\N	\N	8	2014-05-13	pm	t	
\N	\N	8	2014-05-14	am	t	
\N	\N	8	2014-05-14	pm	t	
\N	\N	8	2014-05-15	am	t	
\N	\N	8	2014-05-15	pm	t	
\N	\N	8	2014-05-16	am	t	
\N	\N	8	2014-05-16	pm	t	
\N	\N	8	2014-05-19	am	t	
\N	\N	8	2014-05-19	pm	t	
\N	\N	8	2014-05-20	am	t	
\N	\N	8	2014-05-20	pm	t	
\N	\N	8	2014-05-21	am	t	
\N	\N	8	2014-05-21	pm	t	
\N	\N	8	2014-05-22	am	t	
\N	\N	8	2014-05-22	pm	t	
\N	\N	8	2014-05-23	am	t	
\N	\N	8	2014-05-23	pm	t	
\N	\N	8	2014-05-26	am	t	
\N	\N	8	2014-05-26	pm	t	
\N	\N	8	2014-05-27	am	t	
\N	\N	8	2014-05-27	pm	t	
\N	\N	8	2014-05-28	am	t	
\N	\N	8	2014-05-28	pm	t	
\N	\N	8	2014-05-29	am	t	
\N	\N	8	2014-05-29	pm	t	
\N	\N	8	2014-05-30	am	t	
\N	\N	8	2014-05-30	pm	t	
\N	\N	8	2014-06-02	am	t	
\N	\N	8	2014-06-02	pm	t	
\N	\N	8	2014-06-03	am	t	
\N	\N	8	2014-06-03	pm	t	
\N	\N	8	2014-06-04	am	t	
\N	\N	8	2014-06-04	pm	t	
\N	\N	8	2014-06-05	am	t	
\N	\N	8	2014-06-05	pm	t	
\N	\N	8	2014-06-06	am	t	
\N	\N	8	2014-06-06	pm	t	
\N	\N	8	2014-06-09	am	t	
\N	\N	8	2014-06-09	pm	t	
\N	\N	8	2014-06-10	am	t	
\N	\N	8	2014-06-10	pm	t	
\N	\N	8	2014-06-11	am	t	
\N	\N	8	2014-06-11	pm	t	
\N	\N	8	2014-06-12	am	t	
\N	\N	8	2014-06-12	pm	t	
\N	\N	8	2014-06-13	am	t	
\N	\N	8	2014-06-13	pm	t	
\N	\N	8	2014-06-16	am	t	
\N	\N	8	2014-06-16	pm	t	
\N	\N	8	2014-06-17	am	t	
\N	\N	8	2014-06-17	pm	t	
\N	\N	8	2014-06-18	am	t	
\N	\N	8	2014-06-18	pm	t	
\N	\N	8	2014-06-19	am	t	
\N	\N	8	2014-06-19	pm	t	
\N	\N	8	2014-06-20	am	t	
\N	\N	8	2014-06-20	pm	t	
\N	\N	8	2014-06-23	am	t	
\N	\N	8	2014-06-23	pm	t	
\N	\N	8	2014-06-24	am	t	
\N	\N	8	2014-06-24	pm	t	
\N	\N	8	2014-06-25	am	t	
\N	\N	8	2014-06-25	pm	t	
\N	\N	8	2014-06-26	am	t	
\N	\N	8	2014-06-26	pm	t	
\N	\N	8	2014-06-27	am	t	
\N	\N	8	2014-06-27	pm	t	
\N	\N	8	2014-06-30	am	t	
\N	\N	8	2014-06-30	pm	t	
\N	\N	8	2014-07-01	am	t	
\N	\N	8	2014-07-01	pm	t	
\N	\N	8	2014-07-02	am	t	
\N	\N	8	2014-07-02	pm	t	
\N	\N	8	2014-07-03	am	t	
\N	\N	8	2014-07-03	pm	t	
\N	\N	8	2014-07-04	am	t	
\N	\N	8	2014-07-04	pm	t	
\N	\N	8	2014-07-07	am	t	
\N	\N	8	2014-07-07	pm	t	
\N	\N	8	2014-07-08	am	t	
\N	\N	8	2014-07-08	pm	t	
\N	\N	8	2014-07-09	am	t	
\N	\N	8	2014-07-09	pm	t	
\N	\N	8	2014-07-10	am	t	
\N	\N	8	2014-07-10	pm	t	
\N	\N	8	2014-07-11	am	t	
\N	\N	8	2014-07-11	pm	t	
\N	\N	8	2014-07-14	am	t	
\N	\N	8	2014-07-14	pm	t	
\N	\N	8	2014-07-15	am	t	
\N	\N	8	2014-07-15	pm	t	
\N	\N	8	2014-07-16	am	t	
\N	\N	8	2014-07-16	pm	t	
\N	\N	8	2014-07-17	am	t	
\N	\N	8	2014-07-17	pm	t	
\N	\N	8	2014-07-18	am	t	
\N	\N	8	2014-07-18	pm	t	
\N	\N	8	2014-07-21	am	t	
\N	\N	8	2014-07-21	pm	t	
\N	\N	8	2014-07-22	am	t	
\N	\N	8	2014-07-22	pm	t	
\N	\N	8	2014-07-23	am	t	
\N	\N	8	2014-07-23	pm	t	
\N	\N	8	2014-07-24	am	t	
\N	\N	8	2014-07-24	pm	t	
\N	\N	8	2014-07-25	am	t	
\N	\N	8	2014-07-25	pm	t	
\N	\N	8	2014-07-28	am	t	
\N	\N	8	2014-07-28	pm	t	
\N	\N	8	2014-07-29	am	t	
\N	\N	8	2014-07-29	pm	t	
\N	\N	8	2014-07-30	am	t	
\N	\N	8	2014-07-30	pm	t	
\N	\N	8	2014-07-31	am	t	
\N	\N	8	2014-07-31	pm	t	
\N	\N	8	2014-08-01	am	t	
\N	\N	8	2014-08-01	pm	t	
\N	\N	8	2014-08-04	am	t	
\N	\N	8	2014-08-04	pm	t	
\N	\N	8	2014-08-05	am	t	
\N	\N	8	2014-08-05	pm	t	
\N	\N	8	2014-08-06	am	t	
\N	\N	8	2014-08-06	pm	t	
\N	\N	8	2014-08-07	am	t	
\N	\N	8	2014-08-07	pm	t	
\N	\N	8	2014-08-08	am	t	
\N	\N	8	2014-08-08	pm	t	
\N	\N	8	2014-08-11	am	t	
\N	\N	8	2014-08-11	pm	t	
\N	\N	8	2014-08-12	am	t	
\N	\N	8	2014-08-12	pm	t	
\N	\N	8	2014-08-13	am	t	
\N	\N	8	2014-08-13	pm	t	
\N	\N	8	2014-08-14	am	t	
\N	\N	8	2014-08-14	pm	t	
\N	\N	8	2014-08-15	am	t	
\N	\N	8	2014-08-15	pm	t	
\N	\N	8	2014-08-18	am	t	
\N	\N	8	2014-08-18	pm	t	
\N	\N	8	2014-08-19	am	t	
\N	\N	8	2014-08-19	pm	t	
\N	\N	8	2014-08-20	am	t	
\N	\N	8	2014-08-20	pm	t	
\N	\N	8	2014-08-21	am	t	
\N	\N	8	2014-08-21	pm	t	
\N	\N	8	2014-08-22	am	t	
\N	\N	8	2014-08-22	pm	t	
\N	\N	8	2014-08-25	am	t	
\N	\N	8	2014-08-25	pm	t	
\N	\N	8	2014-08-26	am	t	
\N	\N	8	2014-08-26	pm	t	
\N	\N	8	2014-08-27	am	t	
\N	\N	8	2014-08-27	pm	t	
\N	\N	8	2014-08-28	am	t	
\N	\N	8	2014-08-28	pm	t	
\N	\N	8	2014-08-29	am	t	
\N	\N	8	2014-08-29	pm	t	
\N	\N	8	2014-09-01	am	t	
\N	\N	8	2014-09-01	pm	t	
\N	\N	8	2014-09-02	am	t	
\N	\N	8	2014-09-02	pm	t	
\N	\N	8	2014-09-03	am	t	
\N	\N	8	2014-09-03	pm	t	
\N	\N	8	2014-09-04	am	t	
\N	\N	8	2014-09-04	pm	t	
\N	\N	8	2014-09-05	am	t	
\N	\N	8	2014-09-05	pm	t	
\N	\N	8	2014-09-08	am	t	
\N	\N	8	2014-09-08	pm	t	
\N	\N	8	2014-09-09	am	t	
\N	\N	8	2014-09-09	pm	t	
\N	\N	8	2014-09-10	am	t	
\N	\N	8	2014-09-10	pm	t	
\N	\N	8	2014-09-11	am	t	
\N	\N	8	2014-09-11	pm	t	
\N	\N	8	2014-09-12	am	t	
\N	\N	8	2014-09-12	pm	t	
\N	\N	8	2014-09-15	am	t	
\N	\N	8	2014-09-15	pm	t	
\N	\N	8	2014-09-16	am	t	
\N	\N	8	2014-09-16	pm	t	
\N	\N	8	2014-09-17	am	t	
\N	\N	8	2014-09-17	pm	t	
\N	\N	8	2014-09-18	am	t	
\N	\N	8	2014-09-18	pm	t	
\N	\N	8	2014-09-19	am	t	
\N	\N	8	2014-09-19	pm	t	
\N	\N	8	2014-09-22	am	t	
\N	\N	8	2014-09-22	pm	t	
\N	\N	8	2014-09-23	am	t	
\N	\N	8	2014-09-23	pm	t	
\N	\N	8	2014-09-24	am	t	
\N	\N	8	2014-09-24	pm	t	
\N	\N	8	2014-09-25	am	t	
\N	\N	8	2014-09-25	pm	t	
\N	\N	8	2014-09-26	am	t	
\N	\N	8	2014-09-26	pm	t	
\N	\N	8	2014-09-29	am	t	
\N	\N	8	2014-09-29	pm	t	
\N	\N	8	2014-09-30	am	t	
\N	\N	8	2014-09-30	pm	t	
\N	\N	8	2014-10-01	am	t	
\N	\N	8	2014-10-01	pm	t	
\N	\N	8	2014-10-02	am	t	
\N	\N	8	2014-10-02	pm	t	
\N	\N	8	2014-10-03	am	t	
\N	\N	8	2014-10-03	pm	t	
\N	\N	8	2014-10-06	am	t	
\N	\N	8	2014-10-06	pm	t	
\N	\N	8	2014-10-07	am	t	
\N	\N	8	2014-10-07	pm	t	
\N	\N	8	2014-10-08	am	t	
\N	\N	8	2014-10-08	pm	t	
\N	\N	8	2014-10-09	am	t	
\N	\N	8	2014-10-09	pm	t	
\N	\N	8	2014-10-10	am	t	
\N	\N	8	2014-10-10	pm	t	
\N	\N	8	2014-10-13	am	t	
\N	\N	8	2014-10-13	pm	t	
\N	\N	8	2014-10-14	am	t	
\N	\N	8	2014-10-14	pm	t	
\N	\N	8	2014-10-15	am	t	
\N	\N	8	2014-10-15	pm	t	
\N	\N	8	2014-10-16	am	t	
\N	\N	8	2014-10-16	pm	t	
\N	\N	8	2014-10-17	am	t	
\N	\N	8	2014-10-17	pm	t	
\N	\N	8	2014-10-20	am	t	
\N	\N	8	2014-10-20	pm	t	
\N	\N	8	2014-10-21	am	t	
\N	\N	8	2014-10-21	pm	t	
\N	\N	8	2014-10-22	am	t	
\N	\N	8	2014-10-22	pm	t	
\N	\N	8	2014-10-23	am	t	
\N	\N	8	2014-10-23	pm	t	
\N	\N	8	2014-10-24	am	t	
\N	\N	8	2014-10-24	pm	t	
\N	\N	8	2014-10-27	am	t	
\N	\N	8	2014-10-27	pm	t	
\N	\N	8	2014-10-28	am	t	
\N	\N	8	2014-10-28	pm	t	
\N	\N	8	2014-10-29	am	t	
\N	\N	8	2014-10-29	pm	t	
\N	\N	8	2014-10-30	am	t	
\N	\N	8	2014-10-30	pm	t	
\N	\N	8	2014-10-31	am	t	
\N	\N	8	2014-10-31	pm	t	
\N	\N	8	2014-11-03	am	t	
\N	\N	8	2014-11-03	pm	t	
\N	\N	8	2014-11-04	am	t	
\N	\N	8	2014-11-04	pm	t	
\N	\N	8	2014-11-05	am	t	
\N	\N	8	2014-11-05	pm	t	
\N	\N	8	2014-11-06	am	t	
\N	\N	8	2014-11-06	pm	t	
\N	\N	8	2014-11-07	am	t	
\N	\N	8	2014-11-07	pm	t	
\N	\N	8	2014-11-10	am	t	
\N	\N	8	2014-11-10	pm	t	
\N	\N	8	2014-11-11	am	t	
\N	\N	8	2014-11-11	pm	t	
\N	\N	8	2014-11-12	am	t	
\N	\N	8	2014-11-12	pm	t	
\N	\N	8	2014-11-13	am	t	
\N	\N	8	2014-11-13	pm	t	
\N	\N	8	2014-11-14	am	t	
\N	\N	8	2014-11-14	pm	t	
\N	\N	8	2014-11-17	am	t	
\N	\N	8	2014-11-17	pm	t	
\N	\N	8	2014-11-18	am	t	
\N	\N	8	2014-11-18	pm	t	
\N	\N	8	2014-11-19	am	t	
\N	\N	8	2014-11-19	pm	t	
\N	\N	8	2014-11-20	am	t	
\N	\N	8	2014-11-20	pm	t	
\N	\N	8	2014-11-21	am	t	
\N	\N	8	2014-11-21	pm	t	
\N	\N	8	2014-11-24	am	t	
\N	\N	8	2014-11-24	pm	t	
\N	\N	8	2014-11-25	am	t	
\N	\N	8	2014-11-25	pm	t	
\N	\N	8	2014-11-26	am	t	
\N	\N	8	2014-11-26	pm	t	
\N	\N	8	2014-11-27	am	t	
\N	\N	8	2014-11-27	pm	t	
\N	\N	8	2014-11-28	am	t	
\N	\N	8	2014-11-28	pm	t	
\N	\N	8	2014-12-01	am	t	
\N	\N	8	2014-12-01	pm	t	
\N	\N	8	2014-12-02	am	t	
\N	\N	8	2014-12-02	pm	t	
\N	\N	8	2014-12-03	am	t	
\N	\N	8	2014-12-03	pm	t	
\N	\N	8	2014-12-04	am	t	
\N	\N	8	2014-12-04	pm	t	
\N	\N	8	2014-12-05	am	t	
\N	\N	8	2014-12-05	pm	t	
\N	\N	8	2014-12-08	am	t	
\N	\N	8	2014-12-08	pm	t	
\N	\N	8	2014-12-09	am	t	
\N	\N	8	2014-12-09	pm	t	
\N	\N	8	2014-12-10	am	t	
\N	\N	8	2014-12-10	pm	t	
\N	\N	8	2014-12-11	am	t	
\N	\N	8	2014-12-11	pm	t	
\N	\N	8	2014-12-12	am	t	
\N	\N	8	2014-12-12	pm	t	
\N	\N	8	2014-12-15	am	t	
\N	\N	8	2014-12-15	pm	t	
\N	\N	8	2014-12-16	am	t	
\N	\N	8	2014-12-16	pm	t	
\N	\N	8	2014-12-17	am	t	
\N	\N	8	2014-12-17	pm	t	
\N	\N	8	2014-12-18	am	t	
\N	\N	8	2014-12-18	pm	t	
\N	\N	8	2014-12-19	am	t	
\N	\N	8	2014-12-19	pm	t	
\N	\N	8	2014-12-22	am	t	
\N	\N	8	2014-12-22	pm	t	
\N	\N	8	2014-12-23	am	t	
\N	\N	8	2014-12-23	pm	t	
\N	\N	8	2014-12-24	am	t	
\N	\N	8	2014-12-24	pm	t	
\N	\N	8	2014-12-25	am	t	
\N	\N	8	2014-12-25	pm	t	
\N	\N	8	2014-12-26	am	t	
\N	\N	8	2014-12-26	pm	t	
\N	\N	8	2014-12-29	am	t	
\N	\N	8	2014-12-29	pm	t	
\N	\N	8	2014-12-30	am	t	
\N	\N	8	2014-12-30	pm	t	
\N	\N	8	2014-12-31	am	t	
\N	\N	8	2014-12-31	pm	t	
\N	\N	8	2015-01-01	am	t	
\N	\N	8	2015-01-01	pm	t	
\N	\N	8	2015-01-02	am	t	
\N	\N	8	2015-01-02	pm	t	
70	139	8	2015-01-05	am	f	
70	139	8	2015-01-05	pm	f	
70	139	8	2015-01-06	am	f	
70	139	8	2015-01-06	pm	f	
70	139	8	2015-01-07	am	f	
70	139	8	2015-01-07	pm	f	
70	139	8	2015-01-08	am	f	
70	139	8	2015-01-08	pm	f	
70	139	8	2015-01-09	am	f	
70	139	8	2015-01-09	pm	f	
\N	\N	11	2015-01-01	pm	t	
\N	\N	11	2015-01-02	am	t	
\N	\N	11	2015-01-02	pm	t	
\N	\N	11	2015-01-07	pm	t	
58	133	11	2015-01-14	am	f	
56	63	11	2015-01-14	pm	f	
58	133	11	2015-01-13	pm	f	
57	92	31	2015-01-15	am	f	Challenge1b datamodel
71	89	5	2015-01-05	am	f	
71	89	5	2015-01-05	pm	f	
63	89	5	2015-01-06	am	f	
63	89	5	2015-01-06	pm	f	
71	89	5	2015-01-07	am	f	
63	89	5	2015-01-07	pm	f	
63	89	5	2015-01-08	am	f	
58	89	5	2015-01-08	pm	f	
63	89	5	2015-01-09	am	f	
58	89	5	2015-01-09	pm	f	
67	89	5	2015-01-12	am	f	
57	85	5	2015-01-12	pm	f	SPIP
\N	\N	5	2015-01-13	am	t	
\N	\N	5	2015-01-13	pm	t	
57	85	5	2015-01-14	am	f	SPIP
57	85	5	2015-01-14	pm	f	SPIP
57	85	5	2015-01-15	am	f	website
67	89	8	2015-01-12	am	f	
70	139	8	2015-01-12	pm	f	
70	139	8	2015-01-13	am	f	
70	139	8	2015-01-13	pm	f	
\N	\N	8	2015-01-14	am	t	
\N	\N	8	2015-01-14	pm	t	
70	139	8	2015-01-15	am	f	
70	139	8	2015-01-15	pm	f	
70	139	8	2015-01-16	am	f	
70	139	8	2015-01-16	pm	f	
\N	\N	11	2015-01-19	am	t	
67	133	11	2015-01-19	pm	f	
57	74	11	2015-01-20	am	f	
56	63	11	2015-01-20	pm	f	
67	89	11	2015-01-12	am	f	SOC scrum org meeting preparation
57	74	11	2015-01-13	am	f	sphereis_user
57	92	31	2015-01-20	pm	f	challenge1b
57	92	31	2015-01-21	am	f	smoke vis bug
58	133	11	2015-01-08	pm	f	
58	133	11	2015-01-08	am	f	
58	84	11	2015-01-09	am	f	
67	84	11	2015-01-09	pm	f	
57	92	31	2015-01-21	pm	f	ch1 sim_planner smoke
63	89	5	2015-01-15	pm	f	cluster
67	85	5	2015-01-16	am	f	SIP Meeting
69	89	5	2015-01-16	pm	f	cluster glusterfs
71	89	5	2015-01-19	am	f	
71	85	5	2015-01-19	pm	f	
61	89	5	2015-01-20	am	f	
61	89	5	2015-01-20	pm	f	
63	89	5	2015-01-21	am	f	
61	89	5	2015-01-21	pm	f	
63	89	5	2015-01-22	am	f	virtual hosting
61	89	5	2015-01-22	pm	f	
67	85	5	2015-01-23	am	f	SIP
63	89	5	2015-01-23	pm	f	cluster
\N	\N	15	2014-12-24	am	t	
\N	\N	15	2014-12-24	pm	t	
\N	\N	15	2014-12-25	am	t	
\N	\N	15	2014-12-25	pm	t	
\N	\N	15	2014-12-26	am	t	
\N	\N	15	2014-12-26	pm	t	
\N	\N	15	2014-12-29	am	t	
\N	\N	15	2014-12-29	pm	t	
\N	\N	15	2014-12-30	am	t	
\N	\N	15	2014-12-30	pm	t	
\N	\N	15	2014-12-31	am	t	
\N	\N	15	2014-12-31	pm	t	
\N	\N	15	2015-01-01	am	t	
\N	\N	15	2015-01-01	pm	t	
\N	\N	15	2015-01-02	am	t	
\N	\N	15	2015-01-02	pm	t	
\N	\N	15	2015-01-05	am	t	
\N	\N	15	2015-01-05	pm	t	
\N	\N	15	2015-01-06	am	t	
\N	\N	15	2015-01-06	pm	t	
\N	\N	15	2015-01-07	am	t	
\N	\N	15	2015-01-07	pm	t	
73	110	15	2015-01-08	am	f	galaxy formation project
73	110	15	2015-01-08	pm	f	galaxy formation project
\N	\N	15	2015-01-22	am	t	
\N	\N	15	2015-01-22	pm	t	
73	110	15	2015-01-09	am	f	galaxy formation project
73	110	15	2015-01-09	pm	f	galaxy formation project
67	89	15	2015-01-12	am	f	reunion CESAM
73	110	15	2015-01-12	pm	f	galaxy formation project
73	110	15	2015-01-13	am	f	galaxy formation project
73	110	15	2015-01-13	pm	f	galaxy formation project
73	110	15	2015-01-14	am	f	galaxy formation project
73	110	15	2015-01-14	pm	f	galaxy formation project
73	110	15	2015-01-15	am	f	galaxy formation project
73	110	15	2015-01-15	pm	f	galaxy formation project
73	110	15	2015-01-16	am	f	galaxy formation project
57	115	15	2015-01-16	pm	f	COMPASS
57	115	15	2015-01-19	am	f	COMPASS
57	115	15	2015-01-19	pm	f	COMPASS
57	115	15	2015-01-20	am	f	COMPASS
57	115	15	2015-01-20	pm	f	COMPASS
73	110	15	2015-01-21	am	f	galaxy formation project
73	110	15	2015-01-21	pm	f	galaxy formation project
73	110	15	2015-01-23	am	f	galaxy formation project
73	110	15	2015-01-23	pm	f	galaxy formation project
73	110	15	2015-01-26	am	f	galaxy formation project
73	110	15	2015-01-26	pm	f	galaxy formation project
70	139	8	2015-01-19	am	f	
70	139	8	2015-01-19	pm	f	
70	139	8	2015-01-20	am	f	
70	139	8	2015-01-20	pm	f	
70	139	8	2015-01-21	am	f	
70	139	8	2015-01-21	pm	f	
70	139	8	2015-01-22	am	f	
70	139	8	2015-01-22	pm	f	
70	139	8	2015-01-23	am	f	
67	139	8	2015-01-23	pm	f	
70	139	8	2015-01-26	am	f	
70	139	8	2015-01-26	pm	f	
70	139	8	2015-01-27	am	f	
70	139	8	2015-01-27	pm	f	
67	139	8	2015-01-28	am	f	
70	139	8	2015-01-28	pm	f	
70	139	8	2015-01-29	am	f	
70	139	8	2015-01-29	pm	f	
70	139	8	2015-01-30	am	f	
70	139	8	2015-01-30	pm	f	
71	89	5	2015-01-26	am	f	
69	89	5	2015-01-26	pm	f	
59	\N	5	2015-01-27	am	t	
71	89	5	2015-01-27	pm	f	
71	89	5	2015-01-28	am	f	
71	89	5	2015-01-28	pm	f	
69	89	5	2015-01-29	am	f	
57	89	5	2015-01-29	pm	f	
\N	\N	5	2015-01-30	am	t	
71	89	5	2015-01-30	pm	f	
71	89	5	2015-02-02	am	f	
71	89	5	2015-02-02	pm	f	
69	89	5	2015-02-03	am	f	
69	89	5	2015-02-03	pm	f	
56	89	5	2015-02-04	am	f	
57	89	5	2015-02-04	pm	f	
56	89	5	2015-02-05	am	f	
57	89	5	2015-02-05	pm	f	
57	92	31	2015-01-22	pm	f	sim_planner fix
72	125	31	2015-01-26	pm	f	lensing mocks
57	92	31	2015-01-27	pm	f	challenge 1b
67	92	31	2015-01-28	am	f	Meeting@LAM + Doc DataModel
67	92	31	2015-01-28	pm	f	Prepare E2E with Dida, Sylvain, Anne & William
57	92	31	2015-01-29	pm	f	Data model to bindings
60	125	31	2015-02-02	pm	f	preparation d'exams
57	92	31	2015-02-03	pm	f	update branch newNames
72	125	31	2015-02-04	am	f	multidark
72	125	31	2015-02-04	pm	f	multidark
57	92	31	2015-02-05	am	f	challenge1b newNames
57	92	31	2015-02-05	pm	f	challenge1b newNames
57	92	31	2015-02-06	am	f	challenge1b newNames
72	125	31	2015-02-06	pm	f	multidark
72	125	31	2015-02-09	am	f	Multidark + Correction copies
56	139	8	2015-02-02	am	f	
56	139	8	2015-02-02	pm	f	
\N	\N	8	2015-02-03	am	t	
\N	\N	8	2015-02-03	pm	t	
56	139	8	2015-02-04	am	f	
56	139	8	2015-02-04	pm	f	
70	139	8	2015-02-05	am	f	
70	139	8	2015-02-05	pm	f	
70	139	8	2015-02-06	am	f	
70	139	8	2015-02-06	pm	f	
70	139	8	2015-02-09	am	f	
70	139	8	2015-02-09	pm	f	
70	139	8	2015-02-10	am	f	
70	139	8	2015-02-10	pm	f	
70	139	8	2015-02-11	am	f	
70	139	8	2015-02-11	pm	f	
70	139	8	2015-02-12	am	f	
70	139	8	2015-02-12	pm	f	
70	139	8	2015-02-13	am	f	
70	139	8	2015-02-13	pm	f	
\N	\N	8	2015-05-01	am	t	
60	125	31	2015-02-09	pm	f	Corrections copies  CIS TP/Exam
72	125	31	2015-02-10	am	f	Biblio thèse Anna + Visite Timothée
60	125	31	2015-02-10	pm	f	Réunion Enseignants référents St Charles
72	125	31	2015-02-11	am	f	multidark
72	125	31	2015-02-11	pm	f	multidark
72	125	31	2015-02-12	am	f	multidark
72	125	31	2015-02-12	pm	f	multidark
72	125	31	2015-02-13	am	f	multidark
72	125	31	2015-02-13	pm	f	multidark
72	125	31	2015-02-16	am	f	multidark halo model
72	125	31	2015-02-16	pm	f	multidark halo model
67	92	31	2015-02-17	am	f	SGS meeting @ CPPM
72	125	31	2015-02-17	pm	f	multidark
57	92	31	2015-02-18	am	f	RIDs of OUSIM PF
72	125	31	2015-02-19	am	f	multidark
72	125	31	2015-02-19	pm	f	multidark
72	125	31	2015-02-20	am	f	multidark
72	125	31	2015-02-20	pm	f	
70	139	8	2015-02-16	am	f	
70	139	8	2015-02-16	pm	f	
70	139	8	2015-02-17	am	f	
70	139	8	2015-02-17	pm	f	
70	139	8	2015-02-18	am	f	
70	139	8	2015-02-18	pm	f	
70	139	8	2015-02-19	am	f	
70	139	8	2015-02-19	pm	f	
70	139	8	2015-02-20	am	f	
70	139	8	2015-02-20	pm	f	
72	125	31	2015-02-23	am	f	multidark
72	125	31	2015-02-23	pm	f	multidark
72	125	31	2015-02-24	am	f	multidark
67	92	31	2015-02-24	pm	f	telecon Spain+Nicolas
72	125	31	2015-02-25	am	f	multidark stacking s82
57	92	31	2015-02-25	pm	f	euclidsim write_nip_catalog
70	139	8	2015-02-23	am	f	
70	139	8	2015-02-23	pm	f	
\N	\N	8	2015-02-24	am	t	
\N	\N	8	2015-02-24	pm	t	
\N	\N	8	2015-02-25	am	t	
\N	\N	8	2015-02-25	pm	t	
70	139	8	2015-02-26	am	f	
70	139	8	2015-02-26	pm	f	
\N	\N	8	2015-02-27	am	t	
\N	\N	8	2015-02-27	pm	t	
59	84	8	2015-03-02	am	f	Visite medicale
70	139	8	2015-03-02	pm	f	
70	139	8	2015-03-03	am	f	
70	139	8	2015-03-03	pm	f	
70	139	8	2015-03-04	am	f	
70	139	8	2015-03-04	pm	f	
70	139	8	2015-03-05	am	f	
70	139	8	2015-03-05	pm	f	
70	139	8	2015-03-06	am	f	
67	139	8	2015-03-06	pm	f	
57	92	31	2015-03-09	am	f	challenge1b
67	92	31	2015-03-09	pm	f	telecon challenge1b
67	125	31	2015-03-10	am	f	Lenstool+Présentation Aurélie
57	92	31	2015-03-10	pm	f	galaxyCatalog, challenge1b
72	125	31	2015-03-11	am	f	paper ELG with Johan
57	92	31	2015-03-11	pm	f	OUSIM challenge1b GalaxyCatalog
57	92	31	2015-03-12	am	f	galaxyCatalog challenge1b
57	92	31	2015-03-12	pm	f	galaxyCatalog challenge1b
67	125	31	2015-03-13	am	f	groupe cosmo
67	125	31	2015-03-13	pm	f	groupe lensing
59	125	31	2015-03-16	am	f	Mail+Lettre CNES Ballon+Multidark
72	125	31	2015-03-16	pm	f	Multidark, Modèle HOD Exclusion Q
63	89	5	2015-02-06	am	f	
63	89	5	2015-02-06	pm	f	
63	89	5	2015-02-09	am	f	
63	89	5	2015-02-09	pm	f	
63	89	5	2015-02-10	am	f	
63	89	5	2015-02-10	pm	f	
63	89	5	2015-02-11	am	f	
63	89	5	2015-02-11	pm	f	
\N	\N	5	2015-02-12	am	t	
\N	\N	5	2015-02-12	pm	t	
63	89	5	2015-02-13	am	f	
63	89	5	2015-02-13	pm	f	
\N	\N	5	2015-02-16	am	t	
\N	\N	5	2015-02-16	pm	t	
\N	\N	5	2015-02-17	am	t	
\N	\N	5	2015-02-17	pm	t	
\N	\N	5	2015-02-18	am	t	
\N	\N	5	2015-02-18	pm	t	
\N	\N	5	2015-02-19	am	t	
\N	\N	5	2015-02-19	pm	t	
\N	\N	5	2015-02-20	am	t	
\N	\N	5	2015-02-20	pm	t	
63	89	5	2015-02-23	am	f	
63	89	5	2015-02-23	pm	f	
63	89	5	2015-02-24	am	f	
63	89	5	2015-02-24	pm	f	
63	89	5	2015-02-25	am	f	
63	89	5	2015-02-25	pm	f	
63	89	5	2015-02-26	am	f	
63	89	5	2015-02-26	pm	f	
63	89	5	2015-02-27	am	f	
63	89	5	2015-02-27	pm	f	
\N	\N	5	2015-03-02	am	t	
\N	\N	5	2015-03-02	pm	t	
\N	\N	5	2015-03-03	am	t	
\N	\N	5	2015-03-03	pm	t	
\N	\N	5	2015-03-04	am	t	
\N	\N	5	2015-03-04	pm	t	
\N	\N	5	2015-03-05	am	t	
\N	\N	5	2015-03-05	pm	t	
\N	\N	5	2015-03-06	am	t	
\N	\N	5	2015-03-06	pm	t	
\N	\N	5	2015-03-09	am	t	
\N	\N	5	2015-03-09	pm	t	
\N	\N	5	2015-03-10	am	t	
\N	\N	5	2015-03-10	pm	t	
\N	\N	5	2015-03-11	am	t	
\N	\N	5	2015-03-11	pm	t	
\N	\N	5	2015-03-12	am	t	
\N	\N	5	2015-03-12	pm	t	
\N	\N	5	2015-03-13	am	t	
\N	\N	5	2015-03-13	pm	t	
63	89	5	2015-03-16	am	f	
71	85	5	2015-03-16	pm	f	
61	89	5	2015-03-17	am	f	
72	125	31	2015-03-17	am	f	Meeting w/ CPPM, BOSS
57	92	31	2015-03-17	pm	f	challenge1b galaxyCatalog
57	92	31	2015-03-18	am	f	challenge1b galaxyCatalog
57	92	31	2015-03-18	pm	f	challenge1b galaxyCatalog
57	92	31	2015-03-19	am	f	challenge1b galaxyCatalog
57	92	31	2015-03-19	pm	f	challenge1b + meeting Anne
70	139	8	2015-03-09	am	f	
70	139	8	2015-03-09	pm	f	
70	139	8	2015-03-10	am	f	
70	139	8	2015-03-10	pm	f	
70	139	8	2015-03-11	am	f	
70	139	8	2015-03-11	pm	f	
70	139	8	2015-03-12	am	f	
70	139	8	2015-03-12	pm	f	
70	139	8	2015-03-13	am	f	
70	139	8	2015-03-13	pm	f	
70	139	8	2015-03-16	am	f	
70	139	8	2015-03-16	pm	f	
70	139	8	2015-03-17	am	f	
70	139	8	2015-03-17	pm	f	
70	139	8	2015-03-18	am	f	
70	139	8	2015-03-18	pm	f	
70	139	8	2015-03-19	am	t	
70	139	8	2015-03-19	pm	f	
70	139	8	2015-03-20	am	f	
70	139	8	2015-03-20	pm	f	
72	125	31	2015-03-20	am	f	multidark hod exclusion + eclipse
72	125	31	2015-03-23	am	f	multidark hod
72	125	31	2015-03-23	pm	f	multidark hod
72	125	31	2015-03-24	am	f	multidark exclusion hod
72	125	31	2015-03-24	pm	f	multidark exclusion hod
72	125	31	2015-03-25	am	f	subhalos marceau + debug mathilde meso
72	125	31	2015-03-25	pm	f	multidark hod+subhalos 0717 + OUSIM telecon avec Nico
72	125	31	2015-03-26	am	f	marceau 0717+OUSIM Santi+Andrey
70	139	8	2015-03-23	am	f	
70	139	8	2015-03-23	pm	f	
70	139	8	2015-03-24	am	f	
70	139	8	2015-03-24	pm	f	
70	139	8	2015-03-25	am	f	
70	139	8	2015-03-25	pm	f	
70	139	8	2015-03-26	am	f	
70	139	8	2015-03-26	pm	f	
70	139	8	2015-03-27	am	f	
67	139	8	2015-03-27	pm	f	
57	92	31	2015-03-26	pm	f	OUSIM challenge1b nip wrapper
57	92	31	2015-03-27	am	f	OUSIM Challenge1b + telecon Nico
67	125	31	2015-03-27	pm	f	Lensing Meeting+Multidark Exclusion
72	125	31	2015-03-30	am	f	bayesM200 correction
72	125	31	2015-03-30	pm	f	WLSWG telecon + Doc Ballons Celine
57	92	31	2015-03-31	am	f	nip and TU wrappers, empty galaxy Catalog
\N	\N	11	2015-02-23	am	t	
\N	\N	11	2015-03-02	am	t	
\N	\N	11	2015-03-16	am	t	
\N	\N	11	2015-03-20	pm	t	
\N	\N	11	2015-03-30	am	t	
67	85	11	2015-03-30	pm	f	AG
58	133	11	2015-03-31	am	f	
71	74	11	2015-03-31	pm	f	Target view ALL vs. P.Obs
55	84	11	2015-04-01	am	f	SO5: GAZPAR
56	63	11	2015-04-01	pm	f	passage sur cram.lam.fr
61	63	1	2015-04-03	pm	f	
70	139	8	2015-03-30	am	f	
70	139	8	2015-03-30	pm	f	
70	139	8	2015-03-31	am	f	
70	139	8	2015-03-31	pm	f	
70	139	8	2015-04-01	am	f	
70	139	8	2015-04-01	pm	f	
70	139	8	2015-04-02	am	f	
67	139	8	2015-04-02	pm	f	PyData Paris 2015
67	139	8	2015-04-03	am	f	PyData Paris 2015
67	139	8	2015-04-03	pm	f	PyData Paris 2015
\N	\N	8	2015-04-06	am	t	
\N	\N	8	2015-04-06	pm	t	
70	139	8	2015-04-07	am	f	
70	139	8	2015-04-07	pm	f	
70	139	8	2015-04-08	am	f	
70	139	8	2015-04-08	pm	f	
70	139	8	2015-04-09	am	f	
70	139	8	2015-04-09	pm	f	
70	139	8	2015-04-10	am	f	
70	139	8	2015-04-10	pm	f	
67	139	8	2015-04-13	am	f	HELP Data Workshop
67	139	8	2015-04-13	pm	f	HELP Data Workshop
67	139	8	2015-04-14	am	f	HELP Data Workshop
67	139	8	2015-04-14	pm	f	HELP Data Workshop
67	139	8	2015-04-15	am	f	HELP Data Workshop
67	139	8	2015-04-15	pm	f	HELP Data Workshop
67	139	8	2015-04-16	am	f	HELP Data Workshop
67	139	8	2015-04-16	pm	f	HELP Data Workshop
67	139	8	2015-04-17	am	f	HELP Data Workshop
67	139	8	2015-04-17	pm	f	HELP Data Workshop
72	125	31	2015-04-15	am	f	mock vipers + hod Johan C + these Anna
72	125	31	2015-04-15	pm	f	multidark figure2
67	92	31	2015-04-16	am	f	Barcelona
67	92	31	2015-04-16	pm	f	Barcelona
67	92	31	2015-04-17	am	f	Barcelona
67	92	31	2015-04-17	pm	f	Barcelona
72	125	31	2015-04-20	am	f	Mail eBOSS
72	125	31	2015-04-20	pm	f	Multidark sigma prof + lensing noise
72	125	31	2015-04-21	am	f	Multidark Delta_Sigma W1, W4 noise cov matrix
67	92	31	2015-04-21	pm	f	these Ana + telecon Nadia+Santi, datamodel GRED180
72	125	31	2015-04-22	am	f	Reunion Segey Lenstool + Multidark radial prof
72	125	31	2015-04-22	pm	f	Multidark radial_prof Sigma C code
72	125	31	2015-04-23	am	f	Multidark radial_prof
72	125	31	2015-04-23	pm	f	Multidark delta_sigma + sigma_prof
57	92	31	2015-04-24	am	f	Install tips trunk + Fix galaxy renormalization
57	92	31	2015-04-24	pm	f	fix install tips 
72	125	31	2015-04-27	am	f	DeltaSigma+Stack CMASS W3
57	92	31	2015-04-27	pm	f	Fix NIPvsNIS detector angle + réponse Andrey EAS
57	92	31	2015-04-28	am	f	Mesure flux dans spectre NIS étoiles
67	125	31	2015-04-28	pm	f	Reunion Admin eBOSS
70	139	8	2015-04-20	am	f	
70	139	8	2015-04-20	pm	f	
70	139	8	2015-04-21	am	f	
70	139	8	2015-04-21	pm	f	
70	139	8	2015-04-22	am	f	
70	139	8	2015-04-22	pm	f	
70	139	8	2015-04-23	am	f	
70	139	8	2015-04-23	pm	f	
70	139	8	2015-04-24	am	f	
70	139	8	2015-04-24	pm	f	
\N	\N	8	2015-04-27	am	t	
\N	\N	8	2015-04-27	pm	t	
67	139	8	2015-04-28	am	f	
70	139	8	2015-04-28	pm	f	
70	139	8	2015-04-29	am	f	
70	139	8	2015-04-29	pm	f	
70	139	8	2015-04-30	am	f	
70	139	8	2015-04-30	pm	f	
59	125	31	2015-04-29	am	f	Reunion Benoit PSF AO + Calcul rho_crit Anna
59	125	31	2015-04-29	pm	f	Etudiant L1 + Telecon Multidark + Calcul rho_crit Anna
\N	\N	31	2015-04-30	am	t	
\N	\N	31	2015-04-30	pm	t	
\N	\N	31	2015-05-01	am	t	
\N	\N	31	2015-05-01	pm	t	
\N	\N	31	2015-05-04	am	t	
\N	\N	31	2015-05-04	pm	t	
\N	\N	31	2015-05-05	am	t	
67	125	31	2015-05-05	pm	f	Déplacement à l'observatoire de l'EPFL
67	125	31	2015-05-06	am	f	Déplacement à l'observatoire de l'EPFL
67	125	31	2015-05-06	pm	f	Déplacement à l'observatoire de l'EPFL
67	125	31	2015-05-07	am	f	Déplacement à l'observatoire de l'EPFL
67	125	31	2015-05-07	pm	f	Déplacement à l'observatoire de l'EPFL
\N	\N	31	2015-05-08	am	t	
\N	\N	31	2015-05-08	pm	t	
67	125	31	2015-05-11	am	f	Euclid SLSWG à Jodrell Bank
67	125	31	2015-05-11	pm	f	Euclid SLSWG à Jodrell Bank
67	125	31	2015-05-12	am	f	Euclid SLSWG à Jodrell Bank
67	125	31	2015-05-12	pm	f	Euclid SLSWG à Jodrell Bank
57	92	31	2015-05-13	am	f	Fix bug : flux dans les étoiles trueUniverse
57	92	31	2015-05-13	pm	f	Fix bug : flux dans les étoiles trueUniverse
\N	\N	8	2015-05-01	pm	t	
70	139	8	2015-05-04	am	f	
70	139	8	2015-05-04	pm	f	
70	139	8	2015-05-05	am	f	
70	139	8	2015-05-05	pm	f	
70	139	8	2015-05-06	am	f	
70	139	8	2015-05-06	pm	f	
70	139	8	2015-05-07	am	f	
70	139	8	2015-05-07	pm	f	
\N	\N	8	2015-05-08	am	t	
\N	\N	8	2015-05-08	pm	t	
70	139	8	2015-05-11	am	f	
70	139	8	2015-05-11	pm	f	
70	139	8	2015-05-12	am	f	
70	139	8	2015-05-12	pm	f	
70	139	8	2015-05-13	am	f	
70	139	8	2015-05-13	pm	f	
\N	\N	8	2015-05-14	am	t	
\N	\N	8	2015-05-14	pm	t	
\N	\N	8	2015-05-15	am	t	
\N	\N	8	2015-05-15	pm	t	
70	139	8	2015-05-18	am	f	
70	139	8	2015-05-18	pm	f	
70	139	8	2015-05-19	am	f	
70	139	8	2015-05-19	pm	f	
70	139	8	2015-05-20	am	f	
70	139	8	2015-05-20	pm	f	
\N	\N	31	2015-05-14	am	t	
\N	\N	31	2015-05-14	pm	t	
57	92	31	2015-05-15	am	f	fix bug on star and galaxy fluxes
57	92	31	2015-05-15	pm	f	fix bug on star and galaxy fluxes
57	92	31	2015-05-18	am	f	fix bug on star and galaxy fluxes
57	92	31	2015-05-18	pm	f	fix bug on star and galaxy fluxes
72	125	31	2015-05-19	am	f	Multidark BDM catalogs
57	92	31	2015-05-19	pm	f	Tests for NIS and OUSIM telecon
67	125	31	2015-05-20	am	f	Reunion eBOSS CPPM
57	92	31	2015-05-20	pm	f	LE1 VIS, NISP format XML
59	125	31	2015-05-21	am	f	Retour de mission + Mail
72	125	31	2015-05-21	pm	f	Strong Lensing A2744
72	125	31	2015-05-22	am	f	Juan cosmo + Ana draft + eBOSS tickets
\N	\N	31	2015-05-22	pm	t	
\N	\N	31	2015-05-25	am	t	
\N	\N	31	2015-05-25	pm	t	
72	125	31	2015-05-26	am	f	Papier Marceau 
67	125	31	2015-05-26	pm	f	OCEVU meeting @CPPM
72	125	31	2015-05-27	am	f	Code Tidal Radius + RMS/AMP Mathilde A2744
67	125	31	2015-05-27	pm	f	OCEVU meeting CPPM
\N	\N	4	2015-05-04	pm	t	
66	89	4	2015-05-13	am	f	entretiens
66	89	4	2015-05-13	pm	f	entretiens
67	81	4	2015-05-15	pm	f	SIR-SPE
\N	\N	4	2015-05-18	am	t	
\N	\N	4	2015-05-18	pm	t	
66	89	4	2015-05-19	am	f	entretiens
66	89	4	2015-05-19	pm	f	entretiens
66	89	4	2015-05-20	am	f	entretiens
66	89	4	2015-05-20	pm	f	entretiens
66	89	4	2015-05-21	am	f	entretiens
66	89	4	2015-05-27	am	f	entretiens
66	89	4	2015-05-28	pm	f	entretiens
66	65	4	2015-04-20	am	f	OUSPE-KOM
66	65	4	2015-04-20	pm	f	OUSPE-KOM
66	65	4	2015-04-21	am	f	OUSPE-KOM
66	65	4	2015-04-21	pm	f	OUSPE-KOM
66	65	4	2015-04-22	am	f	
66	65	4	2015-04-22	pm	f	
66	65	4	2015-04-23	am	f	
66	65	4	2015-04-23	pm	f	
66	65	4	2015-04-24	am	f	KOM B2C1
66	65	4	2015-04-24	pm	f	KOM B2C1
\N	\N	4	2015-04-27	am	t	
\N	\N	4	2015-04-27	pm	t	
\N	\N	4	2015-04-28	am	t	
\N	\N	4	2015-04-28	pm	t	
66	65	4	2015-04-29	am	f	KOM B2C1
\N	\N	4	2015-04-29	pm	t	
\N	\N	4	2015-04-30	am	t	
\N	\N	4	2015-04-30	pm	t	
55	96	4	2015-01-14	pm	f	
67	144	4	2015-03-23	am	f	ASOVF
67	144	4	2015-03-23	pm	f	ASOVF
67	144	4	2015-03-24	am	f	Observatoire Virtuel
67	144	4	2015-03-24	pm	f	Observatoire Virtuel
67	144	4	2015-03-25	am	f	Observatoire Virtuel
66	89	4	2015-03-25	pm	f	Entretien CDD
60	89	4	2015-03-26	pm	f	communication - Lycee
67	85	4	2015-03-30	am	f	Qualité-processus
67	85	4	2015-03-30	pm	f	prospective
67	89	4	2015-03-31	am	f	prospective
66	89	4	2015-03-31	pm	f	CDD
66	89	4	2015-04-01	am	f	Cesam-Poles
66	65	4	2015-04-01	pm	f	preparation 
67	85	4	2015-04-02	am	f	prospective
\N	\N	4	2015-02-23	am	t	
\N	\N	4	2015-02-23	pm	t	
\N	\N	4	2015-02-24	am	t	
\N	\N	4	2015-02-24	pm	t	
\N	\N	4	2015-02-25	am	t	
\N	\N	4	2015-02-25	pm	t	
\N	\N	4	2015-02-26	am	t	
\N	\N	4	2015-02-26	pm	t	
\N	\N	4	2015-02-27	am	t	
\N	\N	4	2015-02-27	pm	t	
55	63	4	2015-01-05	am	f	
67	89	4	2015-01-05	pm	f	DIR
55	63	4	2015-01-06	am	f	
55	63	4	2015-01-06	pm	f	
55	63	4	2015-01-07	am	f	
66	89	4	2015-01-07	pm	f	recrutement CDD
55	63	4	2015-01-08	am	f	
66	89	4	2015-01-08	pm	f	recrutement CDD
55	63	4	2015-01-09	am	f	
66	89	4	2015-01-09	pm	f	recrutement CDD
55	63	4	2015-01-12	am	f	
55	63	4	2015-01-12	pm	f	
55	63	4	2015-01-13	am	f	
55	133	4	2015-01-13	pm	f	
55	133	4	2015-01-14	am	f	
67	145	4	2015-01-15	am	f	reunion PetaSky
67	145	4	2015-01-15	pm	f	reunion PetaSky
67	145	4	2015-01-16	am	f	reunion PetaSky
67	145	4	2015-01-16	pm	f	reunion PetaSky
55	84	4	2015-01-19	am	f	Revue TARANIS
55	84	4	2015-01-19	pm	f	Revue TARANIS
55	84	4	2015-01-20	am	f	Revue TARANIS
55	84	4	2015-01-20	pm	f	Revue TARANIS
67	81	4	2015-01-21	am	f	Toulouse
67	81	4	2015-01-21	pm	f	Toulouse
67	96	4	2015-01-22	am	f	Mastodons
67	96	4	2015-01-22	pm	f	Mastodons
67	96	4	2015-01-23	am	f	Mastodons
67	96	4	2015-01-23	pm	f	Mastodons
67	81	4	2015-01-26	am	f	OUSIR-OUSPE
67	81	4	2015-01-26	pm	f	OUSIR-OUSPE
67	81	4	2015-01-27	am	f	OUSIR-OUSPE
67	134	4	2015-01-27	pm	f	SVOM meeting
67	134	4	2015-01-28	am	f	SVOM meeting
67	134	4	2015-01-28	pm	f	SVOM meeting
67	65	4	2015-02-11	am	f	Garage Days
67	65	4	2015-02-11	pm	f	Garage Days
67	65	4	2015-02-12	am	f	Garage Days
67	65	4	2015-02-12	pm	f	Garage Days
67	65	4	2015-02-13	am	f	Garage Days
67	65	4	2015-02-13	pm	f	Garage Days
67	85	4	2014-07-03	am	f	CPCS
55	65	4	2014-07-03	pm	f	
55	65	4	2014-07-04	am	f	
55	65	4	2014-07-04	pm	f	
55	65	4	2014-07-07	am	f	
55	65	4	2014-07-07	pm	f	
55	65	4	2014-07-08	am	f	
55	65	4	2014-07-08	pm	f	
55	65	4	2014-07-09	am	f	
55	65	4	2014-07-09	pm	f	
67	85	4	2014-07-10	am	f	reunion R&D
67	85	4	2014-07-10	pm	f	reunion R&D
55	65	4	2014-07-11	am	f	
55	65	4	2014-07-11	pm	f	
\N	\N	4	2014-07-14	am	t	
\N	\N	4	2014-07-14	pm	t	
55	65	4	2014-07-15	am	f	
55	65	4	2014-07-15	pm	f	
55	65	4	2014-07-16	am	f	
55	65	4	2014-07-16	pm	f	
67	126	4	2014-07-17	am	f	CS
55	65	4	2014-07-17	pm	f	
55	65	4	2014-07-18	am	f	
55	65	4	2014-07-18	pm	f	
55	65	4	2014-07-21	am	f	
55	65	4	2014-07-21	pm	f	
55	81	4	2014-07-22	am	f	
55	84	4	2014-07-22	pm	f	fabry perot
55	81	4	2014-07-23	am	f	
55	81	4	2014-07-23	pm	f	
55	81	4	2014-07-24	am	f	
55	80	4	2014-07-24	pm	f	
55	80	4	2014-07-25	am	f	
55	80	4	2014-07-25	pm	f	
55	81	4	2014-07-28	am	f	
55	81	4	2014-07-28	pm	f	
55	81	4	2014-07-29	am	f	
55	81	4	2014-07-29	pm	f	
55	81	4	2014-07-30	am	f	
55	81	4	2014-07-30	pm	f	
55	81	4	2014-07-31	am	f	
66	65	4	2014-07-31	pm	f	telecon
66	89	4	2014-09-01	am	f	
66	89	4	2014-09-01	pm	f	
66	89	4	2014-09-02	am	f	
66	89	4	2014-09-02	pm	f	
66	89	4	2014-09-03	am	f	
66	89	4	2014-09-03	pm	f	
67	85	4	2014-09-04	am	f	CPCS
66	89	4	2014-09-04	pm	f	
55	80	4	2014-09-05	am	f	
55	80	4	2014-09-05	pm	f	
67	134	4	2014-09-08	am	f	KO
67	134	4	2014-09-08	pm	f	KO
67	125	4	2014-09-09	am	f	Journée imagerie
55	81	4	2014-09-09	pm	f	
55	81	4	2014-09-10	am	f	
55	81	4	2014-09-10	pm	f	
55	81	4	2014-09-11	am	f	
66	65	4	2014-09-11	pm	f	telecon
55	105	4	2014-09-12	am	f	preparation
55	105	4	2014-09-12	pm	f	preparation
67	105	4	2014-09-15	am	f	marseille
67	105	4	2014-09-15	pm	f	marseille
67	145	4	2014-09-16	am	f	lyon
67	145	4	2014-09-16	pm	f	lyon
55	81	4	2014-09-17	am	f	Validation plan
55	81	4	2014-09-17	pm	f	Validation plan
55	81	4	2014-09-18	am	f	Validation plan
55	81	4	2014-09-18	pm	f	Validation plan
55	81	4	2014-09-19	am	f	Validation plan
55	81	4	2014-09-19	pm	f	Validation plan
67	84	4	2014-09-22	am	f	Wish
67	84	4	2014-09-22	pm	f	Wish
67	65	4	2014-09-23	am	f	OG #8
67	65	4	2014-09-23	pm	f	OG #8
67	65	4	2014-09-24	am	f	OG #8
67	65	4	2014-09-24	pm	f	OG #8
67	65	4	2014-09-25	am	f	OG #8
66	65	4	2014-09-25	pm	f	telecon
55	81	4	2014-09-26	am	f	Validation plan
55	81	4	2014-09-26	pm	f	Validation plan
67	145	4	2014-09-29	am	f	PREDON
66	89	4	2014-09-29	pm	f	CDD
66	89	4	2014-09-30	am	f	
66	89	4	2014-09-30	pm	f	
66	89	4	2014-10-01	am	f	
66	89	4	2014-10-01	pm	f	
67	145	4	2014-10-02	am	f	PREDON
67	145	4	2014-10-02	pm	f	PETASKY
55	145	4	2014-10-03	am	f	
55	145	4	2014-10-03	pm	f	PETASKY
67	90	4	2014-10-06	am	f	ADASS Calgary
67	90	4	2014-10-06	pm	f	ADASS Calgary
67	90	4	2014-10-07	am	f	ADASS Calgary
67	90	4	2014-10-07	pm	f	ADASS Calgary
67	90	4	2014-10-08	am	f	ADASS Calgary
67	90	4	2014-10-08	pm	f	ADASS Calgary
67	90	4	2014-10-09	am	f	ADASS Calgary
67	90	4	2014-10-09	pm	f	ADASS Calgary
67	90	4	2014-10-10	am	f	ADASS Calgary
67	90	4	2014-10-10	pm	f	ADASS Calgary
67	145	4	2014-10-13	am	f	PETASKY
67	145	4	2014-10-13	pm	f	PETASKY
67	65	4	2014-10-14	am	f	GArage Days preparation
67	65	4	2014-10-14	pm	f	GArage Days preparation
67	65	4	2014-10-15	am	f	GArage Days
67	65	4	2014-10-15	pm	f	GArage Days
67	65	4	2014-10-16	am	f	GArage Days
67	65	4	2014-10-16	pm	f	GArage Days
67	65	4	2014-10-17	am	f	GArage Days
67	65	4	2014-10-17	pm	f	GArage Days
\N	\N	4	2014-12-22	am	t	
\N	\N	4	2014-12-22	pm	t	
\N	\N	4	2014-12-23	am	t	
\N	\N	4	2014-12-23	pm	t	
\N	\N	4	2014-12-24	am	t	
\N	\N	4	2014-12-24	pm	t	
\N	\N	4	2014-12-25	am	t	
\N	\N	4	2014-12-25	pm	t	
\N	\N	4	2014-12-26	am	t	
\N	\N	4	2014-12-26	pm	t	
\N	\N	4	2014-12-29	am	t	
\N	\N	4	2014-12-29	pm	t	
\N	\N	4	2014-12-30	am	t	
\N	\N	4	2014-12-30	pm	t	
\N	\N	4	2014-12-31	am	t	
\N	\N	4	2014-12-31	pm	t	
\N	\N	4	2015-01-01	am	t	
\N	\N	4	2015-01-01	pm	t	
\N	\N	4	2015-01-02	am	t	
\N	\N	4	2015-01-02	pm	t	
67	105	4	2014-10-20	am	f	reunion LAM
67	105	4	2014-10-20	pm	f	reunion LAM
67	105	4	2014-10-21	am	f	reunion LAM
67	105	4	2014-10-21	pm	f	reunion LAM
67	137	4	2014-10-22	am	f	Atelier Plato - Marseille
67	137	4	2014-10-22	pm	f	Atelier Plato - Marseille
67	137	4	2014-10-23	am	f	Atelier Plato - Marseille
67	137	4	2014-10-23	pm	f	Atelier Plato - Marseille
67	137	4	2014-10-24	am	f	Atelier Plato - Marseille
67	137	4	2014-10-24	pm	f	Atelier Plato - Marseille
\N	\N	4	2014-10-27	am	t	
\N	\N	4	2014-10-27	pm	t	
\N	\N	4	2014-10-28	am	t	
\N	\N	4	2014-10-28	pm	t	
\N	\N	4	2014-10-29	am	t	
\N	\N	4	2014-10-29	pm	t	
\N	\N	4	2014-10-30	am	t	
\N	\N	4	2014-10-30	pm	t	
\N	\N	4	2014-10-31	am	t	
\N	\N	4	2014-10-31	pm	t	
55	145	4	2014-11-03	am	f	Preparation PREDON
55	145	4	2014-11-03	pm	f	preparation PREDON
67	145	4	2014-11-04	am	f	PREDON
67	145	4	2014-11-04	pm	f	PREDON
67	145	4	2014-11-05	am	f	PREDON
67	145	4	2014-11-05	pm	f	PREDON
67	145	4	2014-11-06	am	f	PREDON
67	145	4	2014-11-06	pm	f	PREDON
67	65	4	2014-11-07	am	f	OG Telecon
67	65	4	2014-11-07	pm	f	OG Telecon
67	90	4	2014-11-10	am	f	ESA/ESRIN BigData
67	90	4	2014-11-10	pm	f	ESA/ESRIN BigData
67	90	4	2014-11-11	am	f	ESA/ESRIN BigData
67	90	4	2014-11-11	pm	f	ESA/ESRIN BigData
67	90	4	2014-11-12	am	f	ESA/ESRIN BigData
67	90	4	2014-11-12	pm	f	ESA/ESRIN BigData
67	90	4	2014-11-13	am	f	ESA/ESRIN BigData
67	90	4	2014-11-13	pm	f	ESA/ESRIN BigData
67	90	4	2014-11-14	am	f	ESA/ESRIN BigData
67	90	4	2014-11-14	pm	f	ESA/ESRIN BigData
55	145	4	2014-11-17	am	f	IndexMed
55	145	4	2014-11-17	pm	f	IndexMed
55	145	4	2014-11-18	am	f	IndexMed
55	145	4	2014-11-18	pm	f	IndexMed
55	145	4	2014-11-19	am	f	IndexMed
59	84	4	2014-11-19	pm	f	preparation IRHC
59	84	4	2014-11-20	am	f	preparation IRHC
59	84	4	2014-11-20	pm	f	preparation IRHC
55	145	4	2014-11-21	am	f	PR2I
55	145	4	2014-11-21	pm	f	PR2I
55	145	4	2014-11-24	am	f	PR2I
55	145	4	2014-11-24	pm	f	PR2I
59	84	4	2014-11-25	am	f	preparation IRHC
59	84	4	2014-11-25	pm	f	preparation IRHC
62	65	4	2014-11-26	am	f	developper workshop
62	65	4	2014-11-26	pm	f	developper workshop
62	65	4	2014-11-27	am	f	developper workshop
62	65	4	2014-11-27	pm	f	developper workshop
62	65	4	2014-11-28	am	f	developper workshop
62	65	4	2014-11-28	pm	f	developper workshop
55	145	4	2014-12-01	am	f	PR2I
66	89	4	2014-12-01	pm	f	
55	145	4	2014-12-02	am	f	PR2I
66	89	4	2014-12-02	pm	f	
66	89	4	2014-12-03	am	f	
55	134	4	2014-12-03	pm	f	preparation CIO SVOM
67	65	4	2014-12-04	am	f	EUCLID-France - Lyon
67	65	4	2014-12-04	pm	f	EUCLID-France - Lyon
67	65	4	2014-12-05	am	f	EUCLID-France - Lyon
67	65	4	2014-12-05	pm	f	EUCLID-France - Lyon
66	89	4	2014-12-08	am	f	
66	89	4	2014-12-08	pm	f	
67	90	4	2014-12-09	am	f	PRODEV
67	90	4	2014-12-09	pm	f	PRODEV
55	134	4	2014-12-10	am	f	preparation CIO SVOM
55	134	4	2014-12-10	pm	f	preparation CIO SVOM
55	134	4	2014-12-11	am	f	preparation SVOM
55	134	4	2014-12-11	pm	f	presentation SVOM
55	134	4	2014-12-12	am	f	preparation  SVOM
55	134	4	2014-12-12	pm	f	preparation  SVOM
55	134	4	2014-12-15	am	f	preparation  SVOM
55	134	4	2014-12-15	pm	f	preparation  SVOM
55	134	4	2014-12-16	am	f	preparation  SVOM
55	134	4	2014-12-16	pm	f	preparation  SVOM
55	134	4	2014-12-17	am	f	preparation  SVOM
55	134	4	2014-12-17	pm	f	preparation  SVOM
67	81	4	2014-12-18	am	f	SDC FR telecon
67	81	4	2014-12-18	pm	f	SDC FR telecon
55	134	4	2014-12-19	am	f	 CIO SVOM
55	134	4	2014-12-19	pm	f	 CIO SVOM
67	134	4	2015-01-29	am	f	Paris
67	81	4	2015-01-29	pm	f	SDC FR telecon
55	81	4	2015-01-30	am	f	PK SRR
55	81	4	2015-01-30	pm	f	PK SRR
55	81	4	2015-02-02	am	f	PK SRR
55	81	4	2015-02-02	pm	f	PK SRR
55	84	4	2015-02-03	am	f	TARANIS
55	84	4	2015-02-03	pm	f	TARANIS
55	88	4	2015-02-04	am	f	
66	89	4	2015-02-04	pm	f	
67	85	4	2015-02-05	am	f	CPCS
67	145	4	2015-02-05	pm	f	AMIDEX
63	85	5	2015-04-29	am	f	cluster
63	85	5	2015-04-29	pm	f	cluster
63	85	5	2015-04-30	am	f	cluster
63	85	5	2015-04-30	pm	f	cluster
\N	\N	5	2015-05-01	am	t	
\N	\N	5	2015-05-01	pm	t	
63	85	5	2015-05-04	am	f	cluster
63	85	5	2015-05-04	pm	f	cluster
63	85	5	2015-05-05	am	f	cluster
63	85	5	2015-05-05	pm	f	cluster
\N	\N	5	2015-05-06	am	t	
63	85	5	2015-05-06	pm	f	cluster
63	85	5	2015-05-07	am	f	cluster
63	85	5	2015-05-07	pm	f	cluster
\N	\N	5	2015-05-08	am	t	
\N	\N	5	2015-05-08	pm	t	
\N	\N	5	2015-05-11	am	t	
\N	\N	5	2015-05-11	pm	t	
\N	\N	5	2015-05-12	am	t	
\N	\N	5	2015-05-12	pm	t	
\N	\N	5	2015-05-13	am	t	
\N	\N	5	2015-05-13	pm	t	
\N	\N	5	2015-05-14	am	t	
\N	\N	5	2015-05-14	pm	t	
\N	\N	5	2015-05-15	am	t	
\N	\N	5	2015-05-15	pm	t	
\N	\N	5	2015-05-18	am	t	
\N	\N	5	2015-05-18	pm	t	
\N	\N	5	2015-05-19	am	t	
\N	\N	5	2015-05-19	pm	t	
\N	\N	5	2015-05-20	am	t	
\N	\N	5	2015-05-20	pm	t	
\N	\N	5	2015-05-21	am	t	
\N	\N	5	2015-05-21	pm	t	
\N	\N	5	2015-05-22	am	t	
\N	\N	5	2015-05-22	pm	t	
\N	\N	5	2015-05-25	am	t	
\N	\N	5	2015-05-25	pm	t	
71	85	5	2015-05-26	am	f	
72	125	31	2015-05-28	am	f	DeltaSigma BDM distinct
67	125	31	2015-05-28	pm	f	OCEVU Meeting  @CPPM
72	125	31	2015-05-29	am	f	Code Tidal Radius
72	125	31	2015-05-29	pm	f	Code Tidal Radius
60	125	31	2015-06-01	am	f	Etudiants L1, Lentilles
72	125	31	2015-06-01	pm	f	Mesocentre Proposal + BATMAN + Etudiants 
63	85	5	2015-05-26	pm	f	preparation coupure
63	85	5	2015-05-27	am	f	preparation coupure
63	85	5	2015-05-27	pm	f	preparation coupure
62	85	5	2015-05-28	am	f	lephare git training
63	85	5	2015-05-28	pm	f	preparation coupure
63	85	5	2015-05-29	am	f	preparation coupure
63	85	5	2015-05-29	pm	f	preparation coupure
63	85	5	2015-06-01	am	f	recuperation coupure
63	85	5	2015-06-01	pm	f	recuperation coupure
63	85	5	2015-06-02	am	f	recuperation coupure
60	125	31	2015-06-02	am	f	Etudiants L1, Lentilles+Tickets eBOSS/Patrick
72	125	31	2015-06-02	pm	f	CC+Meeting Projet Michele+OUSIM catalog_lib/get_mags
72	125	31	2015-06-03	am	f	Millenium Dsig + Visite MOEMS
72	125	31	2015-06-04	am	f	Millenium Dsig HOD + Etudiants L1
72	125	31	2015-06-03	pm	f	Millenium Dsig + L1 Students
72	125	31	2015-06-04	pm	f	Ana Images ARES/HERA + Telecon Juan Chile A1689
72	125	31	2015-06-05	am	f	A2744 SL
67	92	31	2015-06-05	pm	f	EC Annual Meeting Lausanne
67	92	31	2015-06-08	am	f	EC Annual Meeting Lausanne
67	92	31	2015-06-08	pm	f	EC Annual Meeting Lausanne
67	92	31	2015-06-09	am	f	EC Annual Meeting Lausanne
67	92	31	2015-06-09	pm	f	EC Annual Meeting Lausanne
67	92	31	2015-06-10	am	f	EC Annual Meeting Lausanne
67	92	31	2015-06-10	pm	f	EC Annual Meeting Lausanne
67	92	31	2015-06-11	am	f	EC Annual Meeting Lausanne
67	92	31	2015-06-11	pm	f	EC Annual Meeting Lausanne
72	125	31	2015-06-12	am	f	Exam Math SNTE + A2744 cosmo
70	139	8	2015-05-21	am	f	
70	139	8	2015-05-21	pm	f	
70	139	8	2015-05-22	am	f	
70	139	8	2015-05-22	pm	f	
70	139	8	2015-05-25	am	f	
70	139	8	2015-05-25	pm	f	
70	139	8	2015-05-26	am	f	
70	139	8	2015-05-26	pm	f	
70	139	8	2015-05-27	am	f	
70	139	8	2015-05-27	pm	f	
70	139	8	2015-05-28	am	f	
70	139	8	2015-05-28	pm	f	
70	139	8	2015-05-29	am	f	
70	139	8	2015-05-29	pm	f	
70	139	8	2015-06-08	am	f	
70	139	8	2015-06-08	pm	f	
70	139	8	2015-06-09	am	f	
70	139	8	2015-06-09	pm	f	
\N	\N	8	2015-06-10	am	t	
\N	\N	8	2015-06-10	pm	t	
70	139	8	2015-06-11	am	f	
70	139	8	2015-06-11	pm	f	
70	139	8	2015-06-12	am	f	
67	139	8	2015-06-12	pm	f	
62	139	8	2015-06-01	am	f	École d'été Basmati
62	139	8	2015-06-01	pm	f	École d'été Basmati
62	139	8	2015-06-02	am	f	École d'été Basmati
62	139	8	2015-06-02	pm	f	École d'été Basmati
62	139	8	2015-06-03	am	f	École d'été Basmati
62	139	8	2015-06-03	pm	f	École d'été Basmati
62	139	8	2015-06-04	am	f	École d'été Basmati
62	139	8	2015-06-04	pm	f	École d'été Basmati
62	139	8	2015-06-05	am	f	École d'été Basmati
62	139	8	2015-06-05	pm	f	École d'été Basmati
72	125	31	2015-06-12	pm	f	A2744 Cosmo + Lensing Meeting
72	125	31	2015-06-15	am	f	Paper Favole + MultidarkLens Large scale
67	125	31	2015-06-15	pm	f	AG Pole de recherche + Figures MultidarkLens paper
72	125	31	2015-06-16	am	f	Fig MultidarkLens + L1 Etudiants + Paper Magaña 
72	125	31	2015-06-16	pm	f	Cafeclub+AG CeSAM+Anna Thèse+Telecon OUSIM+Papier Magaña
57	92	31	2015-06-17	am	f	Debug @PIC + TrueUniverse Gal Dev
57	92	31	2015-06-17	pm	f	Debug @PIC + TrueUniverse Gal Dev
57	92	31	2015-06-18	am	f	Debug @PIC + TrueUniverse Gal Dev
57	92	31	2015-06-18	pm	f	Debug @PIC + TrueUniverse Gal Dev
57	92	31	2015-06-19	am	f	Debug @PIC + TrueUniverse Gal Dev
67	125	31	2015-06-19	pm	f	Réunion avec les thésardes
60	126	31	2015-06-22	am	f	Préparation M1 Space
67	125	31	2015-06-22	pm	f	Reunion SPACE+Reunion zSURVEY+Students Thèse
72	125	31	2015-06-23	am	f	BDM Mock catalogs
67	125	31	2015-06-23	pm	f	Telecon OUSIM+Telecon Dabin
72	125	31	2015-06-24	am	f	Read Comparat paper+Tidal Radius MAC0717
70	139	8	2015-06-15	am	f	
70	139	8	2015-06-15	pm	f	
70	139	8	2015-06-16	am	f	
70	139	8	2015-06-16	pm	f	
70	139	8	2015-06-17	am	f	
70	139	8	2015-06-17	pm	f	
70	139	8	2015-06-18	am	f	
70	139	8	2015-06-18	pm	f	
70	139	8	2015-06-19	am	f	
70	139	8	2015-06-19	pm	f	
70	139	8	2015-06-22	am	f	
70	139	8	2015-06-22	pm	f	
70	139	8	2015-06-23	am	f	
70	139	8	2015-06-23	pm	f	
70	139	8	2015-06-24	am	f	
70	139	8	2015-06-24	pm	f	
72	125	31	2015-06-24	pm	f	Debug ESO FORS2 Ana
72	125	31	2015-06-25	am	f	Etudiants L1+A2744 Cosmo+0717 subhalos Carlo+Reunion avec Anna Thèse
67	125	31	2015-06-25	pm	f	Issa Soutenance+Etudiants L1+Evan
72	125	31	2015-06-26	am	f	Etudiants L1
67	125	31	2015-06-26	pm	f	Reunion Grp Lentilles
72	125	31	2015-06-29	am	f	Etudiants L1
67	125	31	2015-06-29	pm	f	Meeting avec Marceau+Meeting avec Ana
72	125	31	2015-06-30	am	f	Code Ana fitEllipse.py+Papier Aurélie
72	125	31	2015-06-30	pm	f	
72	125	31	2015-07-01	am	f	
72	125	31	2015-07-01	pm	f	
72	125	31	2015-07-02	am	f	
57	92	31	2015-07-02	pm	f	Telecon CCB+SC2 Data model
57	92	31	2015-07-03	am	f	SC2 Data model
57	92	31	2015-07-03	pm	f	SC2 Data model
\N	\N	5	2015-06-26	am	t	
\N	\N	5	2015-06-26	pm	t	
\N	\N	5	2015-06-29	am	t	
\N	\N	5	2015-06-29	pm	t	
\N	\N	5	2015-06-30	am	t	
\N	\N	5	2015-06-30	pm	t	
\N	\N	5	2015-07-01	am	t	
\N	\N	5	2015-07-01	pm	t	
\N	\N	5	2015-07-02	am	t	
\N	\N	5	2015-07-02	pm	t	
\N	\N	5	2015-07-03	am	t	
\N	\N	5	2015-07-03	pm	t	
58	100	5	2015-06-09	am	f	
58	100	5	2015-06-09	pm	f	
57	89	5	2015-06-10	am	f	mib usage
57	89	5	2015-06-10	pm	f	mib usage
57	89	5	2015-06-11	am	f	mib usage
57	89	5	2015-06-11	pm	f	mib usage
57	89	5	2015-06-12	am	f	mib usage
57	89	5	2015-06-12	pm	f	mib usage
57	89	5	2015-06-15	am	f	mib usage
63	89	5	2015-06-15	pm	f	update
57	89	5	2015-06-16	am	f	mib usage
57	89	5	2015-06-16	pm	f	mib usage
57	89	5	2015-06-17	am	f	mib usage
57	89	5	2015-06-17	pm	f	mib usage
57	89	5	2015-06-18	am	f	mib usage
57	89	5	2015-06-18	pm	f	mib usage
57	89	5	2015-06-19	am	f	mib usage
57	89	5	2015-06-19	pm	f	mib usage
63	89	5	2015-06-22	am	f	update
57	89	5	2015-06-22	pm	f	mib usage
57	89	5	2015-06-23	am	f	mib usage
57	89	5	2015-06-23	pm	f	mib usage
57	89	5	2015-06-24	am	f	mib usage
57	89	5	2015-06-24	pm	f	mib usage
57	89	5	2015-06-25	am	f	mib usage
57	89	5	2015-06-25	pm	f	mib usage
63	89	5	2015-07-06	am	f	update
\N	\N	5	2015-07-06	pm	t	
57	89	5	2015-07-07	am	f	mib usage
57	89	5	2015-07-07	pm	f	mib usage
57	89	5	2015-07-08	am	f	mib usage
70	139	8	2015-06-25	am	f	
70	139	8	2015-06-25	pm	f	
70	139	8	2015-06-26	am	f	
70	139	8	2015-06-26	pm	f	
70	139	8	2015-06-29	am	f	
70	139	8	2015-06-29	pm	f	
70	139	8	2015-06-30	am	f	
70	139	8	2015-06-30	pm	f	
\N	\N	8	2015-07-01	am	t	
\N	\N	8	2015-07-01	pm	t	
\N	\N	8	2015-07-02	am	t	
\N	\N	8	2015-07-02	pm	t	
\N	\N	8	2015-07-03	am	t	
\N	\N	8	2015-07-03	pm	t	
\N	\N	8	2015-07-06	am	t	
\N	\N	8	2015-07-06	pm	t	
70	139	8	2015-07-07	am	f	
70	139	8	2015-07-07	pm	f	
70	139	8	2015-07-08	am	f	
70	139	8	2015-07-08	pm	f	
70	139	8	2015-07-09	am	f	
70	139	8	2015-07-09	pm	f	
70	139	8	2015-07-10	am	f	
70	139	8	2015-07-10	pm	f	
\N	\N	8	2015-07-13	am	t	
\N	\N	8	2015-07-13	pm	t	
\N	\N	8	2015-07-14	am	t	
\N	\N	8	2015-07-14	pm	t	
70	139	8	2015-07-15	am	f	
70	139	8	2015-07-15	pm	f	
70	139	8	2015-07-16	am	f	
70	139	8	2015-07-16	pm	f	
70	139	8	2015-07-17	am	f	
70	139	8	2015-07-17	pm	f	
61	63	11	2015-07-24	am	f	
57	133	11	2015-07-23	pm	f	
57	133	11	2015-07-23	am	f	
71	74	11	2015-07-22	pm	f	
71	74	11	2015-07-22	am	f	
57	133	11	2015-07-21	pm	f	
57	133	11	2015-07-21	am	f	
66	84	11	2015-07-20	am	f	
69	89	11	2015-07-20	pm	f	
\N	\N	11	2015-07-13	am	t	
\N	\N	11	2015-07-13	pm	t	
\N	\N	11	2015-07-14	am	t	
\N	\N	11	2015-07-14	pm	t	
61	143	11	2015-07-15	am	f	test prod
61	143	11	2015-07-15	pm	f	test prod
61	143	11	2015-07-16	am	f	
61	143	11	2015-07-16	pm	f	
57	133	11	2015-07-17	am	f	
57	133	11	2015-07-17	pm	f	
61	63	11	2015-07-24	pm	f	
57	133	11	2015-07-06	am	f	
57	133	11	2015-07-06	pm	f	
57	133	11	2015-07-07	am	f	
57	133	11	2015-07-07	pm	f	
57	133	11	2015-07-08	am	f	
57	133	11	2015-07-08	pm	f	
58	145	11	2015-07-09	am	f	
58	145	11	2015-07-09	pm	f	
57	139	8	2015-07-20	am	f	
57	139	8	2015-07-20	pm	f	
57	139	8	2015-07-21	am	f	
57	139	8	2015-07-21	pm	f	
57	139	8	2015-07-22	am	f	
57	139	8	2015-07-22	pm	f	
57	139	8	2015-07-23	am	f	
57	139	8	2015-07-23	pm	f	
57	139	8	2015-07-24	am	f	
57	139	8	2015-07-24	pm	f	
\N	\N	19	2015-07-20	am	t	
\N	\N	19	2015-07-20	pm	t	
63	89	10	2015-07-01	am	f	upgrade centos7
63	89	10	2015-07-01	pm	f	upgrade centos7
70	139	8	2015-07-27	am	f	
70	139	8	2015-07-27	pm	f	
70	139	8	2015-07-28	am	f	
70	139	8	2015-07-28	pm	f	
\N	\N	8	2015-07-29	am	t	
\N	\N	8	2015-07-29	pm	t	
70	139	8	2015-07-30	am	f	
70	139	8	2015-07-30	pm	f	
57	89	5	2015-07-08	pm	f	cluster
57	89	5	2015-07-09	am	f	cluster
57	89	5	2015-07-09	pm	f	cluster
57	89	5	2015-07-10	am	f	cluster
57	89	5	2015-07-10	pm	f	cluster
\N	\N	5	2015-07-13	am	t	
\N	\N	5	2015-07-13	pm	t	
\N	\N	5	2015-07-14	am	t	
\N	\N	5	2015-07-14	pm	t	
57	89	5	2015-07-15	am	f	cluster
57	89	5	2015-07-15	pm	f	cluster
57	89	5	2015-07-16	am	f	cluster
57	89	5	2015-07-16	pm	f	cluster
57	89	5	2015-07-17	am	f	cluster
57	89	5	2015-07-17	pm	f	cluster
57	89	5	2015-07-20	am	f	cluster
57	89	5	2015-07-20	pm	f	cluster
63	89	5	2015-07-21	am	f	cluster
63	89	5	2015-07-21	pm	f	cluster
63	89	5	2015-07-22	am	f	cluster
63	89	5	2015-07-22	pm	f	cluster
63	89	5	2015-07-23	am	f	cluster
63	89	5	2015-07-23	pm	f	cluster
63	89	5	2015-07-24	am	f	cluster
63	89	5	2015-07-24	pm	f	cluster
63	89	5	2015-07-27	am	f	cluster
63	89	5	2015-07-27	pm	f	cluster
63	89	5	2015-07-28	am	f	cluster
63	89	5	2015-07-28	pm	f	cluster
63	89	5	2015-07-29	am	f	cluster
63	89	5	2015-07-29	pm	f	cluster
63	89	5	2015-07-30	am	f	cluster
63	89	5	2015-07-30	pm	f	cluster
63	89	5	2015-07-31	am	f	cluster
63	89	5	2015-07-31	pm	f	cluster
63	89	5	2015-08-03	am	f	MAJ
63	89	5	2015-08-03	pm	f	cluster
63	89	5	2015-08-04	am	f	cluster
63	89	5	2015-08-04	pm	f	cluster
63	89	5	2015-08-05	am	f	cluster
63	89	5	2015-08-05	pm	f	cluster
63	89	5	2015-08-06	am	f	cluster
63	89	5	2015-08-06	pm	f	cluster
\N	\N	5	2015-08-07	am	t	
\N	\N	5	2015-08-07	pm	t	
\N	\N	5	2015-08-10	am	t	
\N	\N	5	2015-08-10	pm	t	
63	89	5	2015-08-11	am	f	cluster
63	89	5	2015-08-11	pm	f	cluster
63	89	5	2015-08-12	am	f	cluster
63	89	5	2015-08-12	pm	f	cluster
63	89	5	2015-08-13	am	f	cluster
63	89	5	2015-08-13	pm	f	cluster
63	89	5	2015-08-14	am	f	cluster
63	89	5	2015-08-14	pm	f	cluster
63	89	5	2015-08-17	am	f	redmine
63	89	5	2015-08-17	pm	f	redmine
63	89	5	2015-08-18	am	f	redmine
63	89	5	2015-08-18	pm	f	redmine
57	131	19	2015-08-18	am	f	
57	131	19	2015-08-18	pm	f	
\N	\N	19	2015-07-21	am	t	
\N	\N	19	2015-07-21	pm	t	
\N	\N	19	2015-07-22	am	t	
\N	\N	19	2015-07-22	pm	t	
\N	\N	19	2015-07-23	am	t	
\N	\N	19	2015-07-23	pm	t	
\N	\N	19	2015-07-24	am	t	
\N	\N	19	2015-07-24	pm	t	
\N	\N	19	2015-07-25	am	t	
\N	\N	19	2015-07-25	pm	t	
\N	\N	19	2015-07-26	am	t	
\N	\N	19	2015-07-26	pm	t	
\N	\N	19	2015-07-27	am	t	
\N	\N	19	2015-07-27	pm	t	
\N	\N	19	2015-07-28	am	t	
\N	\N	19	2015-07-28	pm	t	
\N	\N	19	2015-07-29	am	t	
\N	\N	19	2015-07-29	pm	t	
\N	\N	19	2015-07-30	am	t	
\N	\N	19	2015-07-30	pm	t	
\N	\N	19	2015-07-31	am	t	
\N	\N	19	2015-07-31	pm	t	
\N	\N	19	2015-08-03	am	t	
\N	\N	19	2015-08-03	pm	t	
\N	\N	19	2015-08-04	am	t	
\N	\N	19	2015-08-04	pm	t	
\N	\N	19	2015-08-05	am	t	
\N	\N	19	2015-08-05	pm	t	
\N	\N	19	2015-08-06	am	t	
\N	\N	19	2015-08-06	pm	t	
\N	\N	19	2015-08-07	am	t	
\N	\N	19	2015-08-07	pm	t	
\N	\N	19	2015-08-08	am	t	
\N	\N	19	2015-08-08	pm	t	
\N	\N	19	2015-08-09	am	t	
\N	\N	19	2015-08-09	pm	t	
\N	\N	19	2015-08-10	am	t	
\N	\N	19	2015-08-10	pm	t	
\N	\N	19	2015-08-11	am	t	
\N	\N	19	2015-08-11	pm	t	
\N	\N	19	2015-08-12	am	t	
\N	\N	19	2015-08-12	pm	t	
\N	\N	19	2015-08-13	am	t	
\N	\N	19	2015-08-13	pm	t	
\N	\N	19	2015-08-14	am	t	
\N	\N	19	2015-08-14	pm	t	
60	89	19	2015-08-17	am	f	Arrivée du stagiaire AFPA sur Transtar (présentation projet, présentation angular...)
60	89	19	2015-08-17	pm	f	Arrivée du stagiaire AFPA sur Transtar (présentation projet, présentation angular...)
\N	\N	14	2015-08-03	pm	t	
\N	\N	14	2015-08-03	am	t	
\N	\N	14	2015-08-04	am	t	
\N	\N	14	2015-08-04	pm	t	
\N	\N	14	2015-08-05	am	t	
\N	\N	14	2015-08-05	pm	t	
\N	\N	14	2015-08-06	am	t	
\N	\N	14	2015-08-06	pm	t	
\N	\N	14	2015-08-07	am	t	
\N	\N	14	2015-08-07	pm	t	
\N	\N	14	2015-08-08	am	t	
\N	\N	14	2015-08-08	pm	t	
\N	\N	14	2015-08-09	am	t	
\N	\N	14	2015-08-09	pm	t	
\N	\N	14	2015-08-10	am	t	
\N	\N	14	2015-08-10	pm	t	
\N	\N	14	2015-08-11	am	t	
\N	\N	14	2015-08-11	pm	t	
\N	\N	14	2015-08-12	am	t	
\N	\N	14	2015-08-12	pm	t	
\N	\N	14	2015-08-13	am	t	
\N	\N	14	2015-08-13	pm	t	
\N	\N	14	2015-08-14	am	t	
\N	\N	14	2015-08-14	pm	t	
\N	\N	14	2015-08-15	am	t	
\N	\N	14	2015-08-15	pm	t	
\N	\N	14	2015-08-16	am	t	
\N	\N	14	2015-08-16	pm	t	
66	89	14	2015-08-17	am	f	Accueil stagiaire FL
66	89	14	2015-08-17	pm	f	Encadrement stagiaire
66	89	14	2015-08-18	am	f	Encadrement stagiaire
59	84	14	2015-08-18	pm	f	Anglais
57	131	19	2015-08-19	am	f	
57	131	19	2015-08-19	pm	f	
57	131	19	2015-08-20	am	f	
57	131	19	2015-08-20	pm	f	
57	131	19	2015-08-21	am	f	
57	131	19	2015-08-21	pm	f	
60	89	19	2015-08-24	am	f	Stagiaire Transtar
57	131	19	2015-08-24	pm	f	
57	131	19	2015-08-25	am	f	
57	131	19	2015-08-25	pm	f	
\.


--
-- Data for Name: team; Type: TABLE DATA; Schema: public; Owner: cram
--

COPY team (teamid, leader, label) FROM stdin;
43	25	Service Mécanique
44	4	CeSAM
45	26	Direction Technique
46	11	
\.


--
-- Name: team_teamid_seq; Type: SEQUENCE SET; Schema: public; Owner: cram
--

SELECT pg_catalog.setval('team_teamid_seq', 46, true);


--
-- Data for Name: teamuser; Type: TABLE DATA; Schema: public; Owner: cram
--

COPY teamuser (teamid, userrid) FROM stdin;
43	25
43	27
44	17
44	22
44	4
44	24
44	19
44	10
44	11
44	14
44	13
44	15
44	5
44	7
44	8
45	25
45	4
45	24
45	27
45	10
45	11
45	14
45	15
45	5
46	8
\.


--
-- Data for Name: userversion; Type: TABLE DATA; Schema: public; Owner: cram
--

COPY userversion (userrid, centralversion) FROM stdin;
7	1
28	3
25	2
17	60
9	14
13	10
33	2
10	14
34	1
19	64
22	62
18	3
23	5
2	4
32	2
30	8
29	1
24	8
6	36
15	122
16	9
26	2
21	0
27	2
20	27
14	23
35	13
1	3
4	75
31	78
11	48
8	168
5	70
\.


--
-- Data for Name: version; Type: TABLE DATA; Schema: public; Owner: cram
--

COPY version (tablename, centralversion) FROM stdin;
project	84
activity	84
\.


--
-- Data for Name: versionappli; Type: TABLE DATA; Schema: public; Owner: cram
--

COPY versionappli (numversion, dateversion, compatible, message, version) FROM stdin;
3	2012-11-27	f	\N	0.3
5	2013-03-27	f	New version available at http://projets.lam.fr/projects/cram/files/cram-0.5.zip	0.5
6	2013-05-23	f	New version running without JCE (Java Cryptography Extension), may now running on all JVM and platforms available at http://projets.lam.fr/projects/cram/files/cram-0.5.1.zip	0.5.1
7	2013-10-03	f	New version running without JCE (Java Cryptography Extension), may now running on all JVM and p latforms available at http://projets.lam.fr/projects/cram/files/cram-0.5.2.zip	0.5.2
8	2015-04-02	t	The new version should be installed, it is available at http://projets.lam.fr/projects/cram/files/cram-0.5.3	0.5.3
\.


--
-- Name: pk_activity; Type: CONSTRAINT; Schema: public; Owner: cram; Tablespace: 
--

ALTER TABLE ONLY activity
    ADD CONSTRAINT pk_activity PRIMARY KEY (activityid);


--
-- Name: pk_activityuser; Type: CONSTRAINT; Schema: public; Owner: cram; Tablespace: 
--

ALTER TABLE ONLY activityuser
    ADD CONSTRAINT pk_activityuser PRIMARY KEY (userrid, activityid);


--
-- Name: pk_cramuser; Type: CONSTRAINT; Schema: public; Owner: cram; Tablespace: 
--

ALTER TABLE ONLY cramuser
    ADD CONSTRAINT pk_cramuser PRIMARY KEY (userrid);


--
-- Name: pk_manager; Type: CONSTRAINT; Schema: public; Owner: cram; Tablespace: 
--

ALTER TABLE ONLY manager
    ADD CONSTRAINT pk_manager PRIMARY KEY (userrid, projectid);


--
-- Name: pk_project; Type: CONSTRAINT; Schema: public; Owner: cram; Tablespace: 
--

ALTER TABLE ONLY project
    ADD CONSTRAINT pk_project PRIMARY KEY (projectid);


--
-- Name: pk_projectuser; Type: CONSTRAINT; Schema: public; Owner: cram; Tablespace: 
--

ALTER TABLE ONLY projectuser
    ADD CONSTRAINT pk_projectuser PRIMARY KEY (userrid, projectid);


--
-- Name: pk_task; Type: CONSTRAINT; Schema: public; Owner: cram; Tablespace: 
--

ALTER TABLE ONLY task
    ADD CONSTRAINT pk_task PRIMARY KEY (userrid, taskdate, taskam);


--
-- Name: pk_team; Type: CONSTRAINT; Schema: public; Owner: cram; Tablespace: 
--

ALTER TABLE ONLY team
    ADD CONSTRAINT pk_team PRIMARY KEY (teamid);


--
-- Name: pk_teamuser; Type: CONSTRAINT; Schema: public; Owner: cram; Tablespace: 
--

ALTER TABLE ONLY teamuser
    ADD CONSTRAINT pk_teamuser PRIMARY KEY (teamid, userrid);


--
-- Name: pk_userversion; Type: CONSTRAINT; Schema: public; Owner: cram; Tablespace: 
--

ALTER TABLE ONLY userversion
    ADD CONSTRAINT pk_userversion PRIMARY KEY (userrid);


--
-- Name: pk_version; Type: CONSTRAINT; Schema: public; Owner: cram; Tablespace: 
--

ALTER TABLE ONLY version
    ADD CONSTRAINT pk_version PRIMARY KEY (tablename);


--
-- Name: pk_versionappli; Type: CONSTRAINT; Schema: public; Owner: cram; Tablespace: 
--

ALTER TABLE ONLY versionappli
    ADD CONSTRAINT pk_versionappli PRIMARY KEY (numversion);


--
-- Name: i_fk_manager_cramuser; Type: INDEX; Schema: public; Owner: cram; Tablespace: 
--

CREATE INDEX i_fk_manager_cramuser ON manager USING btree (userrid);


--
-- Name: i_fk_manager_project; Type: INDEX; Schema: public; Owner: cram; Tablespace: 
--

CREATE INDEX i_fk_manager_project ON manager USING btree (projectid);


--
-- Name: i_fk_task_activity; Type: INDEX; Schema: public; Owner: cram; Tablespace: 
--

CREATE INDEX i_fk_task_activity ON task USING btree (activityid);


--
-- Name: i_fk_task_cramuser; Type: INDEX; Schema: public; Owner: cram; Tablespace: 
--

CREATE INDEX i_fk_task_cramuser ON task USING btree (userrid);


--
-- Name: i_fk_task_project; Type: INDEX; Schema: public; Owner: cram; Tablespace: 
--

CREATE INDEX i_fk_task_project ON task USING btree (projectid);


--
-- Name: createuserversion; Type: TRIGGER; Schema: public; Owner: cram
--

CREATE TRIGGER createuserversion AFTER INSERT ON cramuser FOR EACH ROW EXECUTE PROCEDURE createuserversion();


--
-- Name: removemanagerproject; Type: TRIGGER; Schema: public; Owner: cram
--

CREATE TRIGGER removemanagerproject BEFORE DELETE ON project FOR EACH ROW EXECUTE PROCEDURE removemanagerproject();


--
-- Name: fk_activityuser_activity; Type: FK CONSTRAINT; Schema: public; Owner: cram
--

ALTER TABLE ONLY activityuser
    ADD CONSTRAINT fk_activityuser_activity FOREIGN KEY (activityid) REFERENCES activity(activityid);


--
-- Name: fk_activityuser_cramuser; Type: FK CONSTRAINT; Schema: public; Owner: cram
--

ALTER TABLE ONLY activityuser
    ADD CONSTRAINT fk_activityuser_cramuser FOREIGN KEY (userrid) REFERENCES cramuser(userrid);


--
-- Name: fk_manager_cramuser; Type: FK CONSTRAINT; Schema: public; Owner: cram
--

ALTER TABLE ONLY manager
    ADD CONSTRAINT fk_manager_cramuser FOREIGN KEY (userrid) REFERENCES cramuser(userrid);


--
-- Name: fk_manager_project; Type: FK CONSTRAINT; Schema: public; Owner: cram
--

ALTER TABLE ONLY manager
    ADD CONSTRAINT fk_manager_project FOREIGN KEY (projectid) REFERENCES project(projectid);


--
-- Name: fk_project_project; Type: FK CONSTRAINT; Schema: public; Owner: cram
--

ALTER TABLE ONLY project
    ADD CONSTRAINT fk_project_project FOREIGN KEY (projectparentid) REFERENCES project(projectid);


--
-- Name: fk_projectuser_cramuser; Type: FK CONSTRAINT; Schema: public; Owner: cram
--

ALTER TABLE ONLY projectuser
    ADD CONSTRAINT fk_projectuser_cramuser FOREIGN KEY (userrid) REFERENCES cramuser(userrid);


--
-- Name: fk_projectuser_project; Type: FK CONSTRAINT; Schema: public; Owner: cram
--

ALTER TABLE ONLY projectuser
    ADD CONSTRAINT fk_projectuser_project FOREIGN KEY (projectid) REFERENCES project(projectid);


--
-- Name: fk_task_activity; Type: FK CONSTRAINT; Schema: public; Owner: cram
--

ALTER TABLE ONLY task
    ADD CONSTRAINT fk_task_activity FOREIGN KEY (activityid) REFERENCES activity(activityid);


--
-- Name: fk_task_cramuser; Type: FK CONSTRAINT; Schema: public; Owner: cram
--

ALTER TABLE ONLY task
    ADD CONSTRAINT fk_task_cramuser FOREIGN KEY (userrid) REFERENCES cramuser(userrid);


--
-- Name: fk_task_project; Type: FK CONSTRAINT; Schema: public; Owner: cram
--

ALTER TABLE ONLY task
    ADD CONSTRAINT fk_task_project FOREIGN KEY (projectid) REFERENCES project(projectid);


--
-- Name: fk_team_leader; Type: FK CONSTRAINT; Schema: public; Owner: cram
--

ALTER TABLE ONLY team
    ADD CONSTRAINT fk_team_leader FOREIGN KEY (leader) REFERENCES cramuser(userrid);


--
-- Name: fk_teamuser_cramuser; Type: FK CONSTRAINT; Schema: public; Owner: cram
--

ALTER TABLE ONLY teamuser
    ADD CONSTRAINT fk_teamuser_cramuser FOREIGN KEY (userrid) REFERENCES cramuser(userrid);


--
-- Name: fk_teamuser_team; Type: FK CONSTRAINT; Schema: public; Owner: cram
--

ALTER TABLE ONLY teamuser
    ADD CONSTRAINT fk_teamuser_team FOREIGN KEY (teamid) REFERENCES team(teamid);


--
-- Name: fk_userversion_cramuser; Type: FK CONSTRAINT; Schema: public; Owner: cram
--

ALTER TABLE ONLY userversion
    ADD CONSTRAINT fk_userversion_cramuser FOREIGN KEY (userrid) REFERENCES cramuser(userrid);


--
-- Name: public; Type: ACL; Schema: -; Owner: postgres
--

REVOKE ALL ON SCHEMA public FROM PUBLIC;
REVOKE ALL ON SCHEMA public FROM postgres;
GRANT ALL ON SCHEMA public TO postgres;
GRANT ALL ON SCHEMA public TO PUBLIC;


--
-- PostgreSQL database dump complete
--


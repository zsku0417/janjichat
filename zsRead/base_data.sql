--
-- PostgreSQL database dump
--

\restrict S2NUqlvEG73rr6VcWhCACcLfjFffGWt0ffmoPw4vcgtRJWc9FHQdKu7Iduaihdk

-- Dumped from database version 16.11 (Debian 16.11-1.pgdg12+1)
-- Dumped by pg_dump version 18.0

-- Started on 2025-12-22 00:09:27

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- TOC entry 2 (class 3079 OID 16385)
-- Name: vector; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS vector WITH SCHEMA public;


--
-- TOC entry 3894 (class 0 OID 0)
-- Dependencies: 2
-- Name: EXTENSION vector; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION vector IS 'vector data type and ivfflat and hnsw access methods';


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- TOC entry 242 (class 1259 OID 44333)
-- Name: bookings; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.bookings (
    id bigint NOT NULL,
    user_id bigint NOT NULL,
    conversation_id bigint,
    table_id bigint,
    customer_name character varying(255) NOT NULL,
    customer_phone character varying(255) NOT NULL,
    booking_date date NOT NULL,
    booking_time time(0) without time zone NOT NULL,
    pax integer NOT NULL,
    special_request text,
    status character varying(255) DEFAULT 'confirmed'::character varying NOT NULL,
    created_at timestamp(0) without time zone,
    updated_at timestamp(0) without time zone,
    end_time time(0) without time zone,
    created_by character varying(255) DEFAULT 'customer'::character varying NOT NULL,
    reminder_sent boolean DEFAULT false NOT NULL,
    CONSTRAINT bookings_status_check CHECK (((status)::text = ANY ((ARRAY['pending'::character varying, 'confirmed'::character varying, 'cancelled'::character varying, 'completed'::character varying])::text[])))
);


ALTER TABLE public.bookings OWNER TO postgres;

--
-- TOC entry 241 (class 1259 OID 44332)
-- Name: bookings_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.bookings_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.bookings_id_seq OWNER TO postgres;

--
-- TOC entry 3895 (class 0 OID 0)
-- Dependencies: 241
-- Name: bookings_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.bookings_id_seq OWNED BY public.bookings.id;


--
-- TOC entry 222 (class 1259 OID 44185)
-- Name: cache; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.cache (
    key character varying(255) NOT NULL,
    value text NOT NULL,
    expiration integer NOT NULL
);


ALTER TABLE public.cache OWNER TO postgres;

--
-- TOC entry 223 (class 1259 OID 44192)
-- Name: cache_locks; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.cache_locks (
    key character varying(255) NOT NULL,
    owner character varying(255) NOT NULL,
    expiration integer NOT NULL
);


ALTER TABLE public.cache_locks OWNER TO postgres;

--
-- TOC entry 230 (class 1259 OID 44229)
-- Name: conversations; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.conversations (
    id bigint NOT NULL,
    user_id bigint,
    whatsapp_id character varying(255) NOT NULL,
    phone_number character varying(255) NOT NULL,
    customer_name character varying(255),
    mode character varying(255) DEFAULT 'ai'::character varying NOT NULL,
    status character varying(255) DEFAULT 'active'::character varying NOT NULL,
    needs_reply boolean DEFAULT false NOT NULL,
    escalation_reason text,
    last_message_at timestamp(0) without time zone,
    context_type character varying(255),
    context_data json,
    context_expires_at timestamp(0) without time zone,
    created_at timestamp(0) without time zone,
    updated_at timestamp(0) without time zone,
    CONSTRAINT conversations_mode_check CHECK (((mode)::text = ANY ((ARRAY['ai'::character varying, 'admin'::character varying])::text[]))),
    CONSTRAINT conversations_status_check CHECK (((status)::text = ANY ((ARRAY['active'::character varying, 'closed'::character varying])::text[])))
);


ALTER TABLE public.conversations OWNER TO postgres;

--
-- TOC entry 229 (class 1259 OID 44228)
-- Name: conversations_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.conversations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.conversations_id_seq OWNER TO postgres;

--
-- TOC entry 3896 (class 0 OID 0)
-- Dependencies: 229
-- Name: conversations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.conversations_id_seq OWNED BY public.conversations.id;


--
-- TOC entry 252 (class 1259 OID 44441)
-- Name: document_chunks; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.document_chunks (
    id bigint NOT NULL,
    document_id bigint NOT NULL,
    content text NOT NULL,
    chunk_index integer NOT NULL,
    created_at timestamp(0) without time zone,
    updated_at timestamp(0) without time zone,
    embedding public.vector(1536),
    tokens_count integer DEFAULT 0 NOT NULL
);


ALTER TABLE public.document_chunks OWNER TO postgres;

--
-- TOC entry 251 (class 1259 OID 44440)
-- Name: document_chunks_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.document_chunks_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.document_chunks_id_seq OWNER TO postgres;

--
-- TOC entry 3897 (class 0 OID 0)
-- Dependencies: 251
-- Name: document_chunks_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.document_chunks_id_seq OWNED BY public.document_chunks.id;


--
-- TOC entry 250 (class 1259 OID 44423)
-- Name: documents; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.documents (
    id bigint NOT NULL,
    user_id bigint,
    original_name character varying(255) NOT NULL,
    status character varying(255) DEFAULT 'pending'::character varying NOT NULL,
    chunks_count integer DEFAULT 0 NOT NULL,
    error_message text,
    created_at timestamp(0) without time zone,
    updated_at timestamp(0) without time zone,
    media_id bigint,
    CONSTRAINT documents_status_check CHECK (((status)::text = ANY ((ARRAY['pending'::character varying, 'processing'::character varying, 'completed'::character varying, 'failed'::character varying])::text[])))
);


ALTER TABLE public.documents OWNER TO postgres;

--
-- TOC entry 249 (class 1259 OID 44422)
-- Name: documents_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.documents_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.documents_id_seq OWNER TO postgres;

--
-- TOC entry 3898 (class 0 OID 0)
-- Dependencies: 249
-- Name: documents_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.documents_id_seq OWNED BY public.documents.id;


--
-- TOC entry 254 (class 1259 OID 44456)
-- Name: email_verifications; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.email_verifications (
    id bigint NOT NULL,
    email character varying(255) NOT NULL,
    code character varying(6) NOT NULL,
    business_type character varying(255) DEFAULT 'restaurant'::character varying NOT NULL,
    expires_at timestamp(0) without time zone NOT NULL,
    created_at timestamp(0) without time zone,
    updated_at timestamp(0) without time zone
);


ALTER TABLE public.email_verifications OWNER TO postgres;

--
-- TOC entry 253 (class 1259 OID 44455)
-- Name: email_verifications_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.email_verifications_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.email_verifications_id_seq OWNER TO postgres;

--
-- TOC entry 3899 (class 0 OID 0)
-- Dependencies: 253
-- Name: email_verifications_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.email_verifications_id_seq OWNED BY public.email_verifications.id;


--
-- TOC entry 228 (class 1259 OID 44217)
-- Name: failed_jobs; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.failed_jobs (
    id bigint NOT NULL,
    uuid character varying(255) NOT NULL,
    connection text NOT NULL,
    queue text NOT NULL,
    payload text NOT NULL,
    exception text NOT NULL,
    failed_at timestamp(0) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


ALTER TABLE public.failed_jobs OWNER TO postgres;

--
-- TOC entry 227 (class 1259 OID 44216)
-- Name: failed_jobs_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.failed_jobs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.failed_jobs_id_seq OWNER TO postgres;

--
-- TOC entry 3900 (class 0 OID 0)
-- Dependencies: 227
-- Name: failed_jobs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.failed_jobs_id_seq OWNED BY public.failed_jobs.id;


--
-- TOC entry 226 (class 1259 OID 44209)
-- Name: job_batches; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.job_batches (
    id character varying(255) NOT NULL,
    name character varying(255) NOT NULL,
    total_jobs integer NOT NULL,
    pending_jobs integer NOT NULL,
    failed_jobs integer NOT NULL,
    failed_job_ids text NOT NULL,
    options text,
    cancelled_at integer,
    created_at integer NOT NULL,
    finished_at integer
);


ALTER TABLE public.job_batches OWNER TO postgres;

--
-- TOC entry 225 (class 1259 OID 44200)
-- Name: jobs; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.jobs (
    id bigint NOT NULL,
    queue character varying(255) NOT NULL,
    payload text NOT NULL,
    attempts smallint NOT NULL,
    reserved_at integer,
    available_at integer NOT NULL,
    created_at integer NOT NULL
);


ALTER TABLE public.jobs OWNER TO postgres;

--
-- TOC entry 224 (class 1259 OID 44199)
-- Name: jobs_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.jobs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.jobs_id_seq OWNER TO postgres;

--
-- TOC entry 3901 (class 0 OID 0)
-- Dependencies: 224
-- Name: jobs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.jobs_id_seq OWNED BY public.jobs.id;


--
-- TOC entry 256 (class 1259 OID 44477)
-- Name: media; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.media (
    id bigint NOT NULL,
    user_id bigint,
    disk character varying(255) DEFAULT 'cloudinary'::character varying NOT NULL,
    path character varying(255) NOT NULL,
    original_name character varying(255) NOT NULL,
    file_type character varying(255) NOT NULL,
    mime_type character varying(255),
    file_size bigint NOT NULL,
    cloudinary_public_id character varying(255),
    metadata json,
    created_at timestamp(0) without time zone,
    updated_at timestamp(0) without time zone,
    mediable_type character varying(255),
    mediable_id bigint
);


ALTER TABLE public.media OWNER TO postgres;

--
-- TOC entry 255 (class 1259 OID 44476)
-- Name: media_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.media_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.media_id_seq OWNER TO postgres;

--
-- TOC entry 3902 (class 0 OID 0)
-- Dependencies: 255
-- Name: media_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.media_id_seq OWNED BY public.media.id;


--
-- TOC entry 234 (class 1259 OID 44268)
-- Name: merchant_settings; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.merchant_settings (
    id bigint NOT NULL,
    user_id bigint NOT NULL,
    business_name character varying(255) NOT NULL,
    greeting_message text,
    ai_tone text,
    booking_form_template text,
    confirmation_template text,
    reminder_template text,
    reminder_hours_before integer DEFAULT 24 NOT NULL,
    created_at timestamp(0) without time zone,
    updated_at timestamp(0) without time zone,
    email_on_escalation boolean DEFAULT true NOT NULL,
    notification_email character varying(255)
);


ALTER TABLE public.merchant_settings OWNER TO postgres;

--
-- TOC entry 233 (class 1259 OID 44267)
-- Name: merchant_settings_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.merchant_settings_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.merchant_settings_id_seq OWNER TO postgres;

--
-- TOC entry 3903 (class 0 OID 0)
-- Dependencies: 233
-- Name: merchant_settings_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.merchant_settings_id_seq OWNED BY public.merchant_settings.id;


--
-- TOC entry 232 (class 1259 OID 44248)
-- Name: messages; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.messages (
    id bigint NOT NULL,
    conversation_id bigint NOT NULL,
    direction character varying(255) NOT NULL,
    sender_type character varying(255) NOT NULL,
    message_type character varying(255) NOT NULL,
    content text,
    whatsapp_message_id character varying(255),
    status character varying(255) DEFAULT 'pending'::character varying NOT NULL,
    metadata json,
    created_at timestamp(0) without time zone,
    updated_at timestamp(0) without time zone,
    CONSTRAINT messages_direction_check CHECK (((direction)::text = ANY ((ARRAY['inbound'::character varying, 'outbound'::character varying])::text[]))),
    CONSTRAINT messages_message_type_check CHECK (((message_type)::text = ANY ((ARRAY['text'::character varying, 'image'::character varying, 'audio'::character varying, 'video'::character varying, 'document'::character varying, 'location'::character varying, 'contact'::character varying, 'sticker'::character varying, 'interactive'::character varying])::text[]))),
    CONSTRAINT messages_sender_type_check CHECK (((sender_type)::text = ANY ((ARRAY['customer'::character varying, 'ai'::character varying, 'admin'::character varying])::text[])))
);


ALTER TABLE public.messages OWNER TO postgres;

--
-- TOC entry 231 (class 1259 OID 44247)
-- Name: messages_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.messages_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.messages_id_seq OWNER TO postgres;

--
-- TOC entry 3904 (class 0 OID 0)
-- Dependencies: 231
-- Name: messages_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.messages_id_seq OWNED BY public.messages.id;


--
-- TOC entry 217 (class 1259 OID 44148)
-- Name: migrations; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.migrations (
    id integer NOT NULL,
    migration character varying(255) NOT NULL,
    batch integer NOT NULL
);


ALTER TABLE public.migrations OWNER TO postgres;

--
-- TOC entry 216 (class 1259 OID 44147)
-- Name: migrations_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.migrations_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.migrations_id_seq OWNER TO postgres;

--
-- TOC entry 3905 (class 0 OID 0)
-- Dependencies: 216
-- Name: migrations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.migrations_id_seq OWNED BY public.migrations.id;


--
-- TOC entry 248 (class 1259 OID 44406)
-- Name: order_items; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.order_items (
    id bigint NOT NULL,
    order_id bigint NOT NULL,
    product_id bigint,
    product_name character varying(255) NOT NULL,
    unit_price numeric(10,2) NOT NULL,
    quantity integer NOT NULL,
    subtotal numeric(10,2) NOT NULL,
    created_at timestamp(0) without time zone,
    updated_at timestamp(0) without time zone
);


ALTER TABLE public.order_items OWNER TO postgres;

--
-- TOC entry 247 (class 1259 OID 44405)
-- Name: order_items_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.order_items_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.order_items_id_seq OWNER TO postgres;

--
-- TOC entry 3906 (class 0 OID 0)
-- Dependencies: 247
-- Name: order_items_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.order_items_id_seq OWNED BY public.order_items.id;


--
-- TOC entry 238 (class 1259 OID 44302)
-- Name: order_tracking_settings; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.order_tracking_settings (
    id bigint NOT NULL,
    user_id bigint NOT NULL,
    pickup_address text,
    order_prefix character varying(255) DEFAULT 'ORD-'::character varying NOT NULL,
    created_at timestamp(0) without time zone,
    updated_at timestamp(0) without time zone
);


ALTER TABLE public.order_tracking_settings OWNER TO postgres;

--
-- TOC entry 237 (class 1259 OID 44301)
-- Name: order_tracking_settings_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.order_tracking_settings_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.order_tracking_settings_id_seq OWNER TO postgres;

--
-- TOC entry 3907 (class 0 OID 0)
-- Dependencies: 237
-- Name: order_tracking_settings_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.order_tracking_settings_id_seq OWNED BY public.order_tracking_settings.id;


--
-- TOC entry 246 (class 1259 OID 44378)
-- Name: orders; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.orders (
    id bigint NOT NULL,
    user_id bigint NOT NULL,
    conversation_id bigint,
    code character varying(255) NOT NULL,
    customer_name character varying(255) NOT NULL,
    customer_phone character varying(255) NOT NULL,
    fulfillment_type character varying(255) DEFAULT 'pickup'::character varying NOT NULL,
    delivery_address text,
    requested_datetime timestamp(0) without time zone,
    total_amount numeric(10,2) DEFAULT '0'::numeric NOT NULL,
    status character varying(255) DEFAULT 'pending_payment'::character varying NOT NULL,
    notes text,
    created_at timestamp(0) without time zone,
    updated_at timestamp(0) without time zone,
    CONSTRAINT orders_fulfillment_type_check CHECK (((fulfillment_type)::text = ANY ((ARRAY['pickup'::character varying, 'delivery'::character varying])::text[]))),
    CONSTRAINT orders_status_check CHECK (((status)::text = ANY ((ARRAY['pending_payment'::character varying, 'processing'::character varying, 'completed'::character varying, 'cancelled'::character varying])::text[])))
);


ALTER TABLE public.orders OWNER TO postgres;

--
-- TOC entry 245 (class 1259 OID 44377)
-- Name: orders_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.orders_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.orders_id_seq OWNER TO postgres;

--
-- TOC entry 3908 (class 0 OID 0)
-- Dependencies: 245
-- Name: orders_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.orders_id_seq OWNED BY public.orders.id;


--
-- TOC entry 220 (class 1259 OID 44169)
-- Name: password_reset_tokens; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.password_reset_tokens (
    email character varying(255) NOT NULL,
    token character varying(255) NOT NULL,
    created_at timestamp(0) without time zone
);


ALTER TABLE public.password_reset_tokens OWNER TO postgres;

--
-- TOC entry 244 (class 1259 OID 44362)
-- Name: products; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.products (
    id bigint NOT NULL,
    user_id bigint NOT NULL,
    name character varying(255) NOT NULL,
    description text,
    price numeric(10,2) NOT NULL,
    sku character varying(255),
    is_active boolean DEFAULT true NOT NULL,
    created_at timestamp(0) without time zone,
    updated_at timestamp(0) without time zone
);


ALTER TABLE public.products OWNER TO postgres;

--
-- TOC entry 243 (class 1259 OID 44361)
-- Name: products_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.products_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.products_id_seq OWNER TO postgres;

--
-- TOC entry 3909 (class 0 OID 0)
-- Dependencies: 243
-- Name: products_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.products_id_seq OWNED BY public.products.id;


--
-- TOC entry 236 (class 1259 OID 44285)
-- Name: restaurant_settings; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.restaurant_settings (
    id bigint NOT NULL,
    user_id bigint NOT NULL,
    opening_time time(0) without time zone DEFAULT '10:00:00'::time without time zone NOT NULL,
    closing_time time(0) without time zone DEFAULT '22:00:00'::time without time zone NOT NULL,
    slot_duration_minutes integer DEFAULT 120 NOT NULL,
    created_at timestamp(0) without time zone,
    updated_at timestamp(0) without time zone
);


ALTER TABLE public.restaurant_settings OWNER TO postgres;

--
-- TOC entry 235 (class 1259 OID 44284)
-- Name: restaurant_settings_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.restaurant_settings_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.restaurant_settings_id_seq OWNER TO postgres;

--
-- TOC entry 3910 (class 0 OID 0)
-- Dependencies: 235
-- Name: restaurant_settings_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.restaurant_settings_id_seq OWNED BY public.restaurant_settings.id;


--
-- TOC entry 221 (class 1259 OID 44176)
-- Name: sessions; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.sessions (
    id character varying(255) NOT NULL,
    user_id bigint,
    ip_address character varying(45),
    user_agent text,
    payload text NOT NULL,
    last_activity integer NOT NULL
);


ALTER TABLE public.sessions OWNER TO postgres;

--
-- TOC entry 240 (class 1259 OID 44319)
-- Name: tables; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.tables (
    id bigint NOT NULL,
    user_id bigint NOT NULL,
    name character varying(255) NOT NULL,
    capacity integer NOT NULL,
    is_active boolean DEFAULT true NOT NULL,
    created_at timestamp(0) without time zone,
    updated_at timestamp(0) without time zone
);


ALTER TABLE public.tables OWNER TO postgres;

--
-- TOC entry 239 (class 1259 OID 44318)
-- Name: tables_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.tables_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.tables_id_seq OWNER TO postgres;

--
-- TOC entry 3911 (class 0 OID 0)
-- Dependencies: 239
-- Name: tables_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.tables_id_seq OWNED BY public.tables.id;


--
-- TOC entry 219 (class 1259 OID 44155)
-- Name: users; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.users (
    id bigint NOT NULL,
    name character varying(255) NOT NULL,
    email character varying(255) NOT NULL,
    email_verified_at timestamp(0) without time zone,
    password character varying(255) NOT NULL,
    role character varying(255) DEFAULT 'merchant'::character varying NOT NULL,
    business_type character varying(255) DEFAULT 'restaurant'::character varying NOT NULL,
    email_verified boolean DEFAULT false NOT NULL,
    whatsapp_phone_number_id text,
    whatsapp_access_token text,
    remember_token character varying(100),
    created_at timestamp(0) without time zone,
    updated_at timestamp(0) without time zone,
    is_active boolean DEFAULT true NOT NULL,
    CONSTRAINT users_role_check CHECK (((role)::text = ANY ((ARRAY['admin'::character varying, 'merchant'::character varying])::text[])))
);


ALTER TABLE public.users OWNER TO postgres;

--
-- TOC entry 218 (class 1259 OID 44154)
-- Name: users_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.users_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.users_id_seq OWNER TO postgres;

--
-- TOC entry 3912 (class 0 OID 0)
-- Dependencies: 218
-- Name: users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.users_id_seq OWNED BY public.users.id;


--
-- TOC entry 3575 (class 2604 OID 44336)
-- Name: bookings id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.bookings ALTER COLUMN id SET DEFAULT nextval('public.bookings_id_seq'::regclass);


--
-- TOC entry 3558 (class 2604 OID 44232)
-- Name: conversations id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.conversations ALTER COLUMN id SET DEFAULT nextval('public.conversations_id_seq'::regclass);


--
-- TOC entry 3589 (class 2604 OID 44444)
-- Name: document_chunks id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.document_chunks ALTER COLUMN id SET DEFAULT nextval('public.document_chunks_id_seq'::regclass);


--
-- TOC entry 3586 (class 2604 OID 44426)
-- Name: documents id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.documents ALTER COLUMN id SET DEFAULT nextval('public.documents_id_seq'::regclass);


--
-- TOC entry 3591 (class 2604 OID 44459)
-- Name: email_verifications id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.email_verifications ALTER COLUMN id SET DEFAULT nextval('public.email_verifications_id_seq'::regclass);


--
-- TOC entry 3556 (class 2604 OID 44220)
-- Name: failed_jobs id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.failed_jobs ALTER COLUMN id SET DEFAULT nextval('public.failed_jobs_id_seq'::regclass);


--
-- TOC entry 3555 (class 2604 OID 44203)
-- Name: jobs id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.jobs ALTER COLUMN id SET DEFAULT nextval('public.jobs_id_seq'::regclass);


--
-- TOC entry 3593 (class 2604 OID 44480)
-- Name: media id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.media ALTER COLUMN id SET DEFAULT nextval('public.media_id_seq'::regclass);


--
-- TOC entry 3564 (class 2604 OID 44271)
-- Name: merchant_settings id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.merchant_settings ALTER COLUMN id SET DEFAULT nextval('public.merchant_settings_id_seq'::regclass);


--
-- TOC entry 3562 (class 2604 OID 44251)
-- Name: messages id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.messages ALTER COLUMN id SET DEFAULT nextval('public.messages_id_seq'::regclass);


--
-- TOC entry 3549 (class 2604 OID 44151)
-- Name: migrations id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.migrations ALTER COLUMN id SET DEFAULT nextval('public.migrations_id_seq'::regclass);


--
-- TOC entry 3585 (class 2604 OID 44409)
-- Name: order_items id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.order_items ALTER COLUMN id SET DEFAULT nextval('public.order_items_id_seq'::regclass);


--
-- TOC entry 3571 (class 2604 OID 44305)
-- Name: order_tracking_settings id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.order_tracking_settings ALTER COLUMN id SET DEFAULT nextval('public.order_tracking_settings_id_seq'::regclass);


--
-- TOC entry 3581 (class 2604 OID 44381)
-- Name: orders id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.orders ALTER COLUMN id SET DEFAULT nextval('public.orders_id_seq'::regclass);


--
-- TOC entry 3579 (class 2604 OID 44365)
-- Name: products id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.products ALTER COLUMN id SET DEFAULT nextval('public.products_id_seq'::regclass);


--
-- TOC entry 3567 (class 2604 OID 44288)
-- Name: restaurant_settings id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.restaurant_settings ALTER COLUMN id SET DEFAULT nextval('public.restaurant_settings_id_seq'::regclass);


--
-- TOC entry 3573 (class 2604 OID 44322)
-- Name: tables id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tables ALTER COLUMN id SET DEFAULT nextval('public.tables_id_seq'::regclass);


--
-- TOC entry 3550 (class 2604 OID 44158)
-- Name: users id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users ALTER COLUMN id SET DEFAULT nextval('public.users_id_seq'::regclass);


--
-- TOC entry 3874 (class 0 OID 44333)
-- Dependencies: 242
-- Data for Name: bookings; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.bookings (id, user_id, conversation_id, table_id, customer_name, customer_phone, booking_date, booking_time, pax, special_request, status, created_at, updated_at, end_time, created_by, reminder_sent) FROM stdin;
1	2	1	3	John Tan	60123456789	2025-12-21	19:00:00	4	Window seat preferred	confirmed	2025-12-21 23:51:09	2025-12-21 23:51:09	21:00:00	ai	f
2	2	\N	1	Emily Wong	60111222333	2025-12-22	12:30:00	2	Anniversary celebration - please prepare a small cake	confirmed	2025-12-21 23:51:09	2025-12-21 23:51:09	14:30:00	admin	f
3	2	\N	6	Ahmad Yusof	60144455566	2025-12-27	18:00:00	6	Need halal options	pending	2025-12-21 23:51:09	2025-12-21 23:51:09	20:00:00	ai	f
4	2	\N	4	Lee Wei Ming	60177788899	2025-12-20	20:00:00	4	\N	cancelled	2025-12-21 23:51:09	2025-12-21 23:51:09	22:00:00	ai	f
5	2	\N	3	Siti Aminah	60188899900	2025-12-14	19:30:00	3	Birthday dinner	completed	2025-12-21 23:51:09	2025-12-21 23:51:09	21:30:00	admin	t
6	2	\N	1	David Chen	60199900011	2025-12-28	13:00:00	2	Business lunch	confirmed	2025-12-21 23:51:09	2025-12-21 23:51:09	15:00:00	ai	f
\.


--
-- TOC entry 3854 (class 0 OID 44185)
-- Dependencies: 222
-- Data for Name: cache; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.cache (key, value, expiration) FROM stdin;
\.


--
-- TOC entry 3855 (class 0 OID 44192)
-- Dependencies: 223
-- Data for Name: cache_locks; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.cache_locks (key, owner, expiration) FROM stdin;
\.


--
-- TOC entry 3862 (class 0 OID 44229)
-- Dependencies: 230
-- Data for Name: conversations; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.conversations (id, user_id, whatsapp_id, phone_number, customer_name, mode, status, needs_reply, escalation_reason, last_message_at, context_type, context_data, context_expires_at, created_at, updated_at) FROM stdin;
1	2	60123456789	60123456789	John Tan	ai	active	f	\N	2025-12-21 21:51:09	\N	\N	\N	2025-12-21 23:51:09	2025-12-21 23:51:09
2	2	60198765432	60198765432	Sarah Lee	admin	active	t	Customer requested to talk to a human	2025-12-21 23:21:09	\N	\N	\N	2025-12-21 23:51:09	2025-12-21 23:51:09
3	2	60112223344	60112223344	Ahmad bin Ali	ai	active	f	\N	2025-12-20 23:51:09	\N	\N	\N	2025-12-21 23:51:09	2025-12-21 23:51:09
4	3	60177778888	60177778888	Michelle Tan	ai	active	f	\N	2025-12-21 18:51:09	\N	\N	\N	2025-12-21 23:51:09	2025-12-21 23:51:09
5	3	60133334444	60133334444	Ahmad Rizal	ai	active	f	\N	2025-12-21 22:51:09	\N	\N	\N	2025-12-21 23:51:09	2025-12-21 23:51:09
6	3	60155556666	60155556666	Siti Nurhaliza	admin	active	t	Corporate bulk order inquiry - needs custom quotation	2025-12-21 23:36:09	\N	\N	\N	2025-12-21 23:51:09	2025-12-21 23:51:09
7	3	60199887766	60199887766	Jenny Lim	ai	active	f	\N	2025-12-21 20:51:09	\N	\N	\N	2025-12-21 23:51:09	2025-12-21 23:51:09
\.


--
-- TOC entry 3884 (class 0 OID 44441)
-- Dependencies: 252
-- Data for Name: document_chunks; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.document_chunks (id, document_id, content, chunk_index, created_at, updated_at, embedding, tokens_count) FROM stdin;
1	1	BONNE BOUCHE CAFÉ Business Profile &amp; Services Kluang, Johor, Malaysia Company Overview Business Name: Bonne Bouche Café Established: 2019 Business Type: Food &amp; Beverage (Café &amp; Restaurant) Registration No: 202001012345 (001234567-K) Location: Kluang, Johor, Malaysia Mission &amp; Vision Our Mission To deliver an exceptional dining experience that combines quality Western cuisine with authentic Malaysian flavours, served in a warm and welcoming environment that makes every guest feel at home. Our Vision To become the premier café destination in Kluang and the greater Johor region, recognized for culinary excellence, community engagement, and sustainable business practices. Our Services 1. Dine-In Experience Full-service restaurant dining with indoor air-conditioned seating (50 pax) and outdoor patio area (20 pax). Professional wait staff, comfortable ambiance, and attention to detail. 2. Takeaway &amp; Delivery Convenient takeaway packaging for all menu items. Partner with GrabFood, FoodPanda, and ShopeeFood for delivery within Kluang area. Self-pickup orders receive 10% discount. 3. Private Events &amp; Functions Full venue rental available for private events including birthday parties, corporate meetings, product launches, and family gatherings. Customizable packages from 20-70 pax. 4. Catering Services Off-site catering for corporate events, weddings, seminars, and private functions. Menu customization available. Minimum order of 30 pax. Advance booking of 1 week required. 5. Corporate Packages Special rates for corporate clients including meeting room setup, business lunch packages, and monthly billing arrangements. Contact us for corporate account setup. Facilities &amp; Amenities Operating Information Business Hours Note: Kitchen closes 30 minutes before closing. Extended hours during festive seasons. Contact Information Address: No.	0	2025-12-21 23:51:55	2025-12-21 23:51:55	[-0.066806324,0.0033613243,0.040265866,-0.03368327,-0.007037773,-0.04012581,0.010259042,0.02298072,0.012745021,0.009296163,0.0053133434,-0.06153091,0.002300698,0.011239428,-0.04962622,0.10336072,-0.0151376305,0.026517114,0.010299891,0.063631736,0.014659109,0.0095529305,0.004286272,0.008770956,0.008420818,0.029808411,-0.05546185,-0.042390034,-0.014285629,-0.023926092,0.003953641,-0.031559102,0.001103664,0.029971808,-0.014752479,-0.013363599,0.030742113,0.019771123,0.01254661,-0.010679208,-0.029294875,-0.022257103,0.07418256,0.030391974,0.0003924463,0.0019067929,-0.058262955,0.029364903,-0.013760421,0.04528451,-0.007452103,-0.0003818692,-0.0164098,-0.015406069,0.01909419,-0.021790251,0.017296815,-0.0328196,0.069140576,0.08104526,0.02527996,-0.028291145,0.0095179165,0.015896263,0.0021869033,-0.013620366,-0.012885077,0.022245431,0.0077730627,0.04227332,-0.004639328,-0.021930307,-0.042249978,0.0036589415,0.01596629,-0.0016485662,0.030018494,0.0052112197,-0.0041724774,-0.032049295,-0.010439946,0.011402826,-0.0032504473,0.054201353,0.016479826,-0.024089491,-0.05886986,0.03146573,-0.048272353,0.04656835,0.047198597,0.014822506,0.01107603,-0.025186589,0.082445815,0.016036319,-0.025723469,0.0038690243,0.0028448708,0.054574836,0.022572227,-0.079598024,0.013772093,-0.031232305,0.020261316,0.0058998247,0.025233274,-0.010416604,-0.01143784,-0.05289417,-0.061484225,-0.021078305,-0.0038194214,0.042226635,-0.015452755,-0.017460212,0.048692517,-0.028034378,0.007638843,-0.017868707,0.024789767,0.03914542,-0.010200686,-0.033076365,-0.06293146,-0.0052666585,-0.051960472,0.009955589,-0.014017189,-0.056722347,0.011858005,-0.022385485,-0.0096054515,-0.04477097,-0.018242188,-0.022583898,-0.011840498,0.020774852,-0.039635617,-0.016946677,0.043160338,-0.02379771,-0.0055059195,-0.015849577,-0.06942068,-0.03466366,-0.047385335,-0.022572227,-0.038795285,0.056955773,-0.033193078,-0.006156592,-0.018160488,-0.052520692,-0.004572218,-0.018183831,0.029038107,0.054388095,-0.070587814,0.0013742915,0.021113317,0.010527481,-0.0030111864,-0.028197777,-0.0051557813,-0.0082807625,-0.006220784,0.03018189,-0.045354534,-0.028267805,0.022222089,0.018475613,0.026003579,0.042133268,-0.034080092,0.050046384,0.039285477,-0.03190924,0.01254661,-0.0010139411,0.018849093,0.050933402,0.020704824,-0.013235214,-0.020132933,0.036204264,0.0042746007,-0.024509657,0.0117588,0.0075338017,-0.025116563,-0.028174434,-0.022840666,0.012208143,0.03996241,-0.027637556,0.02684391,0.0057889475,-0.01521933,0.029551642,-0.031955924,-0.03912208,0.054761574,-0.027077334,0.045354534,0.0027573362,0.032889623,-0.0007892693,0.014017189,-0.0014180586,0.052847486,0.037581474,0.012441568,0.027053991,0.00927282,-0.016223058,-0.035107166,0.01411056,0.026610484,-0.022082033,0.0054884125,0.0052491515,0.042296663,-0.00057918654,0.003399256,0.03849183,-0.010130658,-0.01079592,0.031862553,-0.06321157,-0.0048698355,0.00599903,-0.033333134,0.0066409498,-0.009039395,-0.009698821,-0.014052203,3.3760047e-05,-0.00959378,-0.016444812,-0.0102065215,0.038538516,-0.010148165,0.010299891,0.053034227,0.018989148,-0.004362135,-0.03730136,-0.041666415,-0.023645982,0.00876512,-0.03599418,-0.005917331,-0.030111864,0.038305093,-0.015371056,-0.0132818995,-0.041176222,0.029411588,-0.018148817,0.019946191,0.024066148,0.028267805,-0.006996923,0.009372026,-0.03384667,0.01402886,-0.017962078,0.0005098884,0.039612275,-0.053827874,-0.06372511,-0.003717298,0.05471489,-0.011472854,-0.018405585,0.0017900802,-0.034733683,0.009617122,-0.0038836135,-0.02167354,-0.00412871,0.0038515173,-0.069140576,0.00320668,-0.009191121,0.067319855,-0.01761194,-0.023004062,0.056722347,0.012861734,-0.028804682,-0.002014752,-0.011233592,0.026633827,0.011671265,0.03793161,-0.046545006,0.045051083,0.005047822,-0.012523267,0.04465426,-0.025443358,0.025956893,-0.007592158,0.041853156,-0.00030454708,0.041526362,0.028757997,0.0052287267,-0.035900813,-0.0033613243,0.03690454,-0.06853367,0.009237806,0.015802892,0.055788647,0.004980712,-0.0145890815,0.007930624,0.03330979,0.0037931611,-0.016899992,-0.013293571,-0.016643224,-0.056722347,0.039168764,0.029411588,-0.03674114,0.0012320479,0.024976507,-0.040545974,-0.025816837,-0.014215601,-0.01568618,0.022257103,-0.0036093388,0.025443358,0.023214146,-0.0044992724,0.002432,-0.037184652,-0.00018199878,-0.040919457,0.030275261,0.0012043286,0.04768879,0.046171524,0.035107166,0.039915726,-0.030695427,0.0011554552,-0.013725407,0.024486315,0.011006003,-0.016829964,0.02380938,0.080298305,-0.023902752,0.03837512,-0.025186589,-0.020308001,0.002493274,0.0062441267,0.010031452,-0.011607073,-0.055275112,-0.007965638,-0.016188044,0.01957271,0.02609695,0.062231183,-0.003507215,-0.034943767,-0.059523452,0.011682936,0.0023284173,0.030672085,0.018860765,-0.004624739,0.07147483,-0.042600118,0.031419046,-0.005634303,0.0042541763,-0.011017675,0.04631158,-0.02123003,0.040616002,-0.036764484,-0.009599616,0.006576758,0.027077334,-0.016258072,0.03653106,0.0162464,0.005447563,-0.023832723,0.0047531226,-0.040242523,0.005873564,-0.010550823,0.00022102457,-0.0059465095,-0.0010299891,-0.007171992,-0.020763181,-0.010113151,-0.022840666,0.020891564,-0.012745021,-0.045611303,-0.014612424,0.028197777,-0.008940189,-0.0114611825,0.0011853628,0.023295844,0.016759936,0.021171674,-0.011181071,-0.0044584232,-0.06181102,0.012184801,-0.025209932,0.027007308,0.034570288,-0.030018494,-0.018230516,0.012651651,-0.028641284,0.0057510156,-0.06475218,0.031862553,-0.03809501,0.018685695,-0.025326645,-0.02768424,-0.045564618,0.018860765,-0.0019505601,0.021486798,-0.0017098403,-0.023179132,-0.029598327,0.021615183,0.0028025624,0.03118562,0.007638843,-0.034103435,-0.04486434,-0.000984763,0.015779551,0.0029761726,-0.04841241,0.027567528,0.022257103,-0.032025952,-0.012534939,-0.06577925,0.00040411754,-0.020272987,-0.007446267,-0.01467078,0.01587292,0.03237609,-0.04533119,-0.005479659,0.019946191,-0.037604816,-0.014880863,0.010924304,0.010813427,-0.012581624,-0.039332163,-0.010439946,-0.025233274,-0.024696397,0.0059085777,0.073669024,-0.018405585,0.00034174923,-0.06876709,-0.03090551,0.028547915,-0.046288237,0.04789887,0.027847638,-0.029201506,0.00014981163,-0.048505776,0.02759087,0.06045715,-0.00987389,-0.023214146,-0.01687665,0.011723786,-0.0387486,0.0032241868,0.017145088,-0.012068088,-0.010848441,0.02260724,0.008718435,0.0071661565,0.015919605,-0.0060865646,0.00168358,-0.036624428,-0.032049295,-0.062137816,0.011472854,-0.020319672,0.006553415,0.0048202323,0.015452755,-0.016561525,0.022163732,-0.041036166,0.019712767,-0.011262771,0.026423743,0.005975688,-0.018242188,-0.011595402,0.015149302,0.016106345,-0.075909905,-0.0057101664,-0.05289417,0.053734504,-0.0005109826,0.0409428,-0.015464426,-0.029691698,-0.015744537,-0.000991328,0.009768849,-0.011169401,-0.02427623,-0.023015734,0.009640465,0.004303779,-0.028851368,-0.017506897,-0.033146393,0.017133417,-0.028804682,0.00040557646,0.016678238,0.010078138,0.019701095,0.00789561,-0.0063141542,-0.01365538,-0.01310683,0.012429897,-0.009529588,0.011577895,-0.01668991,-0.00054453744,0.023774367,0.0015070521,0.017308487,0.019047504,-0.009202792,0.0015522783,0.02443963,-0.012686665,0.0017521486,-0.030205233,0.023879409,0.030742113,-0.011309456,0.002172314,0.016631553,0.0054913303,-0.014892534,-0.009529588,-0.041759785,-0.038141694,-0.0054854946,-0.027824296,0.00025385,-0.008064844,0.028641284,0.036297634,0.030415317,0.03811835,0.043930642,0.035387274,-0.03471034,-0.014974233,-0.005459234,0.006716813,-0.0010029994,-0.021965321,0.018020432,-0.001984115,-0.018510627,-0.009401204,0.04049929,-0.024789767,-0.00936619,-0.025303302,0.00083887216,0.011011839,-0.013421955,0.0043154503,-0.019269258,0.028968079,0.039425533,0.021556826,0.002254013,-0.022805652,0.0101364935,-0.009786355,-0.008356626,0.002175232,0.0024538834,-0.003267954,0.0047268625,0.01807879,0.018954134,0.026003579,0.021976992,-0.0023634313,-0.0011729621,-0.019584382,-0.016491497,0.042646803,0.008642572,0.01809046,-0.012569953,0.029785069,0.0061857705,0.034570288,-0.012523267,0.009372026,-0.060036987,-0.0073645683,0.022677267,0.051073454,-0.055228427,0.01088929,0.027847638,0.00733539,-0.0010081055,0.0102357,-0.035667386,0.007808076,-0.012885077,-0.00991474,-0.016561525,0.023214146,0.060410466,-0.010404932,0.015511111,0.041689757,0.05396793,-0.012173129,0.033006337,-0.0145190535,-0.0067576626,0.016188044,0.05322097,-0.022828994,0.0021241703,0.011262771,-0.031815868,0.023926092,0.011128551,0.047945555,-0.005666399,0.0030432823,0.011122716,0.024859793,-0.009395368,0.04799224,0.0054067136,-0.018113803,-0.013176858,-0.0058823177,0.017285144,-0.007271198,-0.002493274,0.0072478554,-0.014659109,0.018008761,0.009850548,0.006763498,0.0132818995,0.050699975,-0.013153516,0.0009008758,0.033263106,0.0021212525,0.05368782,-0.011198578,-0.107282266,0.011186907,-0.036367662,0.018137146,0.034173463,-0.012569953,0.038701914,0.012114773,0.003413845,0.01679495,-0.005500084,-0.009051066,0.0066467854,-0.013410283,0.068346925,-0.0041578882,0.009016052,-0.037044596,-0.009255313,0.032352746,-0.010311563,-0.0053250147,0.011869676,0.008169886,-0.03809501,0.0011007462,0.060410466,0.0028346584,0.0072945408,0.034827054,0.027194047,0.015837906,0.04624155,0.0010453076,-0.03190924,-0.05980356,0.041923184,-0.016666567,0.013760421,-0.017098403,-0.048225667,-0.0020220466,-0.019152546,-0.013433626,-0.008940189,-0.008029831,0.008000652,0.013760421,-0.008449996,-0.04558796,0.0153127,-0.0038165036,0.007837255,0.0051090964,0.00793646,-0.03127899,-0.034360204,0.02195365,0.010784249,0.009652136,0.021790251,-0.013223543,0.028968079,-0.021346744,-0.0022277527,-0.014075546,-0.01817216,0.01596629,-0.013223543,-0.0069677453,0.0056634815,0.015266014,-0.047361992,0.009039395,0.03302968,0.011484525,0.008940189,-0.022805652,0.023284175,-0.0050857537,-0.025466701,0.04799224,-0.0072186776,0.052940857,-0.011274442,-0.01587292,-0.022537213,0.007002759,0.02094992,-0.029925123,-0.004954452,0.011776307,-0.0013662674,0.01056833,-0.011087702,0.0040936964,0.013818778,-0.011933869,-0.031792525,0.007224513,0.011280278,-0.024533,-0.004525533,-0.0042191623,-0.017051717,0.024883136,0.04309031,0.00088263943,0.046078153,0.030578714,-0.00599903,-0.008210734,-0.030648742,0.0056284675,-0.005114932,0.015989633,-0.006839361,0.03709128,-0.011070195,-0.026283689,-0.011052688,0.0712414,0.0059669344,-0.011140223,0.030672085,-0.044164065,0.0026406236,-0.018183831,-0.0009337012,-0.007066951,-0.059056602,0.0043708887,-0.019304272,-0.011256935,-0.010947647,-0.026563799,0.0024670137,-0.027730925,0.023762695,-0.023050748,0.014810835,0.0067401556,0.0075513083,0.002318205,0.009815534,-0.0060865646,0.047642104,0.003667695,-0.0224205,-0.028687969,0.056162126,-0.0016471073,-0.03218935,0.035644043,0.015896263,0.010031452,0.008992709,-0.020237973,0.0013932573,0.043533817,-0.013702065,-0.028477887,-0.0083332835,-0.0042483406,-0.040826086,0.009243642,0.013235214,-0.0017988337,-0.0071078003,0.01826553,0.013200201,0.014402341,-0.012453239,-0.01982948,-0.022910694,0.03730136,0.024229545,-0.006337497,-0.0023109105,-0.012780035,-0.034757026,0.06493892,-0.0018761558,0.010340741,0.0049165203,-0.005380453,0.04140965,-0.03200261,0.028524572,-0.0069152247,-0.007171992,-0.006716813,0.014437355,0.02223376,-0.017646953,-0.012791706,0.0064833877,0.0040557645,-0.010813427,0.027614214,-0.01771698,0.0045196973,0.036134236,-0.03158244,-0.0076621855,0.0337533,-0.02205869,-0.038001638,0.00613325,-0.0019097107,0.004303779,0.0016368949,-0.021708554,-0.03183921,0.018709037,0.023657653,-0.037488103,0.001970985,0.021556826,-0.005666399,0.009488738,0.011227757,0.00036053266,-0.06652621,0.015231001,-0.027707582,-0.019409314,0.012534939,-0.021358415,0.011011839,-0.011723786,0.02924819,0.00091473537,-0.002159184,-0.01083677,0.03471034,-0.020132933,-0.0028828024,0.01292009,0.0020745674,0.00885849,-0.02260724,0.02712402,-0.013328585,-0.045704674,0.04344045,0.018230516,0.0038631887,0.029645013,0.018498955,-0.041106194,0.03090551,-0.018113803,-0.022537213,-0.019444328,-0.015639495,0.0068627037,-0.0077205417,-0.0046772594,0.006973581,0.007492952,-0.012149787,0.046988513,0.013363599,-0.020366358,0.030812139,0.027240733,0.020809865,0.0012247533,-0.011239428,0.02612029,0.019724438,0.013923819,-0.03433686,-0.011986389,-0.01688832,-0.007930624,-0.021685211,0.012710008,0.005222891,-0.014647437,-0.025536727,0.04243672,-0.0008877456,-0.0052287267,-0.011268606,0.01985282,0.024579683,0.041292936,-0.0034838726,-0.00025385,0.019841151,0.0076155006,-0.031045565,0.0015041343,-0.0082457485,-0.011011839,-0.012791706,0.030555371,0.03772153,-0.0072653624,0.004023669,-0.0053308504,0.0008840983,-0.04161973,0.0054679876,-0.007942296,0.017868707,-0.007475445,-0.038982026,-0.08762786,0.029084792,0.0075513083,0.009582109,0.016188044,-0.018884107,-0.020926578,0.006559251,-0.011484525,-0.028431201,-0.009138601,0.027567528,0.008152379,-0.00035907375,0.034943767,-0.03571407,0.0026858498,0.06615273,0.0065475795,0.023144118,0.024462972,-0.019969534,0.02443963,-9.5923206e-05,-0.01825386,0.013421955,-0.025396673,-0.011963046,-0.0052783294,0.013421955,-0.008006488,-0.02612029,-0.014192258,0.004481766,-0.020518083,0.016526511,-0.014192258,-0.009231971,0.0030053507,0.011198578,0.02999515,-0.016829964,-0.03394004,0.03127899,0.009132765,-0.0008986874,0.03387001,-0.012348198,-0.013923819,0.016001305,-0.012581624,-0.022828994,0.016713252,0.024486315,-0.015055932,0.0005532909,0.0028959326,0.0026172812,-0.00555844,-0.0072653624,-0.016071333,-0.010200686,0.004840657,-0.04911268,0.035574015,0.0033233927,-0.0038719422,0.022175403,-0.0044234092,0.008269091,-0.009523752,0.03793161,0.048178982,-0.009331176,0.00026515656,-0.0034488589,-0.0006017996,-0.012511596,-0.0050886716,0.030041836,-0.038795285,0.023050748,-0.019712767,-0.0037581474,0.029084792,-0.014834178,0.00012200119,0.022362143,0.026960623,-0.008199064,0.013585352,0.019596053,-0.011513703,0.024696397,-0.007370404,0.005202466,-0.03368327,0.008064844,-0.014962561,0.006115743,0.012394884,-0.004980712,-0.007860597,0.03818838,0.0023050748,0.01024737,0.01587292,-0.023132447,0.038865313,-0.03716131,0.03415012,0.0064425385,-0.020984935,-0.0016310593,0.003988655,0.012955104,-0.01956104,-0.022723952,0.026307032,-0.02139343,0.009768849,-0.010439946,-0.04105951,0.0013480311,-0.021241702,0.02878134,-0.049066,-0.0051499456,0.0028871791,0.03286628,0.0039565586,-0.016339771,0.019596053,0.0010846981,0.025163248,0.006080729,-0.013305242,-0.011023509,0.07231516,0.0035334756,0.0069268956,-0.0082982695,-0.0038340106,-0.0062324554,-0.031395704,-0.018277202,-0.013923819,0.023774367,0.012464911,-0.017471883,-0.0075162947,-0.031489074,0.04334708,0.018674023,-0.019969534,0.0057276734,0.018989148,-0.039192107,0.009774684,0.014414012,0.038982026,0.02693728,0.0050273975,0.009080244,-0.020249644,-0.012604966,0.014530725,0.019619396,-0.0069444026,0.03753479,-0.001245178,-0.034010068,0.008811805,-0.0108426055,0.0031220634,0.026727198,0.017751994,-0.012149787,0.013632038,-0.013526996,0.023319187,0.025490042,0.025606755,-0.018382242,-0.013340256,-0.03190924,-0.017133417,-0.029458273,0.018055446,-0.008636736,-0.0041141207,0.023447571,0.0016368949,-0.02131173,-0.027287418,-0.01761194,-0.036367662,0.015616152,-0.008543366,0.011881348,0.02298072,-0.009103587,-0.005683906,-0.003982819,-0.055741962,0.0069677453,0.029458273,0.040452603,0.0082807625,0.04131628,0.0046889307,0.020588111,0.00059924653,0.02721739,-0.033659928,0.0022846502,0.005316261,-0.022257103,-0.014215601,0.028734654,0.024042806,-0.006973581,0.030251918,-0.045144454,0.0036647771,-0.0074871164,0.00024345529,0.023202475,-0.0054504806,0.037394732,-0.003189173,-0.025186589,0.020074576,0.04421075,-0.0074696094,-0.004125792,-0.0048494106,-0.020833207,-0.022525541,-0.023004062,0.01083677,0.00024345529,-0.004843575,-0.0016704499,-0.0088993395,-0.005826879,-0.028711312,-0.02565344,-0.0043767244,-0.008794298,-0.003288379,-0.027240733,0.015417741,-0.020891564,0.0144840395,0.0058823177,0.022338802,0.012780035,0.035083823,0.04855246,0.02962167,-0.003606421,-0.00387486,-0.021708554,0.027474158,0.021335073,-0.0077555557,-0.016304757,-0.0031483236,0.048038926,-0.012616637,-0.03599418,0.00038077502,0.018288871,-0.048319038,-0.0032271047,-0.01993452,0.009488738,-0.02334253,0.035480645,-0.0029557478,-0.005937756,0.0018469776,-0.02712402,-0.02380938,0.011455347,0.023926092,0.013445297,0.00018819915,0.010743399,0.017880378,0.009191121,-0.033076365,0.026633827,0.03118562,0.014052203,0.0050682467,-0.0063258256,0.011099373,-0.014682451,-0.013958833,-0.013223543,0.003507215,0.00042198919,0.0285946,-0.028244462,0.010749235,0.003416763,-0.017145088,-0.009301998,-0.0071253073,-0.014285629,-0.012324856,-0.013632038,-0.026260346,0.006191606,-0.018242188,0.005981523,-0.015417741,0.006856868,-0.008438325,0.0003778572,0.016304757,-0.0224205,-0.024019463,0.014927547,0.014087217,3.9071383e-05,-0.004245423,-0.020074576,0.042226635,0.060597207,-0.0040761894,-0.021054963,0.040732715,0.031325676,-0.0037348047,0.015382728,-0.02565344,-0.03608755,-0.01024737,0.016071333,0.033636585,-0.015266014,-0.024416286,-0.032889623,-0.014098888,0.011175237,0.013783764,0.005523426,-0.0439073,-0.026633827,0.012033074,0.029271532,0.011297785,0.044887684,0.004697684,0.0021037455,0.017238459,0.01130362,-0.02584018,-0.0020453893,0.019992877,0.037884925,0.014098888,-0.017798679,-0.016923334,-0.029855095,0.01881408,0.020529754,0.03867857,0.009074409,0.04752539,0.012780035,-0.032702886,-0.00079145766,0.00039974082,0.015324371,0.004379642,-0.0008366838,-0.012803378,0.025420016,-0.00479689,-0.011560388,0.014985904,0.0053250147,-0.047852185,-0.002003081,-0.009698821,0.0009096292,0.04649832,0.016526511,0.028431201,-0.03865523,0.021825265,-0.015452755,0.0012167294,-0.03302968,-0.048225667,0.0013721031,-0.00067510974,-0.0046334923,0.011671265,0.0023269583,0.04227332,0.033449844,-0.0023065337,0.0071661565,0.01282672,0.0016500251,0.027240733,-0.0040732715,-0.0021460538,0.010463289,-0.0026070687,0.041923184,0.022023678,-0.013363599,0.028851368,0.002906145,0.019479342,-0.053594448,-0.03349653,-0.005858975,0.0089343535,0.00498363,-0.016398128,-0.0042921077,0.0028127749,0.005082836,-0.006699306,-0.01725013,0.006775169,0.018802408,-0.018195502,0.008455832,-0.0101014795,0.012161458,0.022957379,-0.004443834,0.012873406,0.017927064,0.03218935,0.024766425,0.013305242,0.030952195,0.026470428,0.0032329403,-0.03415012,0.006833526,-0.015837906,0.010959318,0.0095879445,-0.01799709,0.030485343,0.0021037455,-0.032912966,0.0101890145,0.03118562,-0.0022496362,0.032446116,-0.02379771,-0.015616152,-0.013118502,-0.018487284,-0.023575956,0.011239428,-0.011402826,-0.032702886,-0.017016705,0.030695427,-0.036834512,-0.018697366,0.018043775,-0.027637556,-0.0063900175,0.0193743,-0.00571892,0.026867252,-0.02971504,0.037114624,-0.016666567,-0.0010423899,0.014273957,-0.02990178,0.0059669344,0.012838392,0.0011802567,0.0058035366,0.0002888638,-0.00079364603,0.054481465,-0.014787492,0.008012324,-0.02593355,-0.016771607,0.0075221304,0.035760757,-0.049486164,-0.018779065,-0.0151026165,0.011863841,0.03221269,0.00438256,-0.029201506,0.0026785552,0.020739838,-0.049953014,-0.033426505,-0.027287418,0.013818778,-0.019677753,-0.0038982024,0.012861734,0.021358415,0.02141677,0.0069327313,0.025910208,-0.027754268,0.005844386,0.002064355,0.0037231336,0.0152076585,0.035083823,0.02999515,0.01430897,-0.019245915]	472
2	1	Operating Information Business Hours Note: Kitchen closes 30 minutes before closing. Extended hours during festive seasons. Contact Information Address: No. 15, Jalan Delima 2/3, Taman Kluang Utama, 86000 Kluang, Johor, Malaysia Phone: +60 7-772 8899 WhatsApp: +60 12-772 8899 Email: hello@bonnebouchecafe.com.my Website: www.bonnebouchecafe.com.my Social Media Facebook: facebook.com/bonnebouchekluang Instagram: @bonnebouche.kluang TikTok: @bonnebouche.kluang — For partnership and business inquiries, please contact management —	1	2025-12-21 23:51:56	2025-12-21 23:51:56	[-0.042856798,0.039356403,0.005155597,-0.045159686,0.018273437,-0.043985214,0.022245925,0.012642871,0.019666687,0.0029261105,-0.0080255745,-0.05522332,-0.01058754,0.013610085,-0.016949276,0.077469245,-0.04743955,0.025838435,2.6919533e-05,0.048544936,0.01897582,0.0027418793,0.00044150735,0.0029620933,-0.0007714684,0.054578513,-0.048544936,-0.04617296,0.012930731,0.022936791,0.012458639,-0.02117508,0.04027756,0.03686928,-0.018549785,-0.03376038,0.044399735,-0.00042423565,0.021359311,-0.02781892,-0.036592934,-0.026229925,0.02422641,0.01993152,-0.022211382,0.005518302,-0.056558996,0.024917278,-0.008848858,0.04955821,0.036431734,0.0013932489,-0.04785407,-0.01422035,0.023950065,-0.039517604,-0.006620811,-0.016189322,0.078943096,0.05646688,0.048360705,-0.031089025,0.01401309,-0.028878251,0.006897158,-0.022188352,-0.004228683,0.024710018,0.014934246,0.036754135,-0.039586693,-0.016223865,-0.04087631,-0.033645235,0.015302709,-0.00020474139,0.020104237,-0.008877644,0.018803103,-0.050341193,-0.022199867,0.0381589,0.011243864,0.058263138,0.037030485,-0.023719775,-0.100037575,0.040392704,-0.05526938,0.027496515,0.05628265,0.022096237,0.021912005,0.0023331163,0.046771713,-0.0009182777,-0.030398158,0.011681413,-0.012090176,0.042419247,0.020023635,-0.05526938,0.0072483486,-0.049373977,0.019413369,0.006845343,0.031135082,-0.012677413,-0.01866493,-0.04872917,-0.05987516,-0.016684443,-0.01897582,0.026483243,0.008486153,-0.029154597,0.058032848,-0.038872797,0.009729713,-0.041014485,-0.008347979,0.040139385,-0.020012122,-0.032631963,-0.069915764,-0.019217623,-0.039356403,0.02632204,-0.027081996,-0.03431307,-0.020541785,-0.036823224,0.017663172,-0.04808436,-0.009257621,-0.011882916,0.0072138053,0.021474456,-0.033576146,-0.016200837,0.056420825,-0.011002061,-0.017778317,0.0014608963,-0.07668626,-0.01677656,-0.06710624,-0.023005879,-0.010161505,0.030444216,-0.022499243,0.010057876,-0.013679171,-0.09110236,-0.018964306,-0.0034572147,0.032977395,0.077653475,-0.03452033,0.030213926,0.01833101,0.0120671475,0.005607539,-0.02225744,-0.015153022,0.021313254,-0.0018236017,0.018400097,-0.023374341,-0.026391128,0.04488334,0.019148536,0.04064602,0.042741653,-0.04423853,0.056190535,0.023144051,-0.01791649,-0.0012025408,0.0065862676,0.025101509,0.01704139,0.009061875,-0.0035320588,-0.022268953,0.017421369,-0.008106176,-0.019839404,0.005259227,0.03673111,-0.054532453,0.0039235502,0.00016192201,-0.009090661,0.04909763,-0.011618084,0.040001214,-0.02267196,-0.02593055,0.038849767,-0.028279498,-0.008480395,0.046311133,-0.03350706,0.04679474,-0.00025817566,0.010708442,0.008198291,0.0036097814,0.0020898734,0.052828316,0.044791225,0.019781832,0.028302528,0.0002925391,-0.020023635,-0.012262893,0.006615054,-0.0023028909,-0.0037853767,-0.0033247985,-0.011940489,0.024825163,-0.00479577,0.009919702,0.04368584,0.019355796,-0.0092748925,0.031825952,-0.029453972,-0.016661415,-0.012493182,-0.04614993,0.012401067,-0.0042718626,0.01422035,-0.01654627,-0.015233623,-0.0056420825,-0.01106539,0.017904976,0.048176475,-0.028786134,0.030536331,0.03371432,0.027703775,6.9896334e-05,-0.04069208,-0.052137446,-0.029384887,0.030421186,-0.0107545,0.0017847404,-0.056835346,0.024686988,-0.011243864,-0.026713533,0.009027332,1.4291866e-05,0.0004890045,0.027911035,-0.0065344526,0.019113993,-0.014830616,0.017237138,-0.01123235,0.009228835,0.021520514,0.0023921279,0.0086243255,-0.05038725,-0.03290831,-0.009660627,0.04951215,-0.014819102,0.0015199078,0.011998061,0.0039811223,0.009873644,0.0017257287,-0.02950003,-0.015866917,0.0028411916,-0.04808436,-0.009441853,-0.02044967,0.033391915,0.008952488,0.009119447,0.08387128,0.0124240955,7.2370145e-05,-0.0136215985,-0.022395613,0.018342525,0.0037421975,0.03836616,-0.0332998,0.029062482,-0.0055442094,-0.021624144,0.03714563,-0.062085934,-0.0053599784,0.015129993,0.00643658,-0.024963336,0.04087631,0.035717838,-0.009603054,-0.0568814,0.01825041,0.015256652,-0.05522332,0.06217805,0.007150476,0.048222534,0.02381189,0.0055010305,-0.001496879,0.058769774,-0.001355827,-0.03458942,0.008336465,-0.0026727926,-0.04195867,0.048821285,0.009804557,-0.04115266,-0.032770135,0.014531241,-0.0657245,-0.019781832,-0.012447124,-0.0129077025,0.033829466,0.017628629,0.018526757,0.028509788,-0.0047266833,0.00643658,-0.05080177,-0.013955518,-0.038227987,0.059322465,-0.018860675,0.047808014,0.023305254,0.042073816,-0.0011183413,-0.07548876,-0.024203382,-0.023178596,0.020253925,-0.015889946,0.0057744985,0.031756863,0.05549967,-0.03120417,0.024779106,-0.038803708,-0.013633113,0.0015040755,-0.012838616,0.020610873,-0.026275983,-0.021255681,-0.026206898,-0.039149143,0.012262893,0.004885007,0.056144476,-0.012136234,-0.015187564,-0.070652686,0.0029275499,-0.00073980365,0.017755289,0.02026544,-0.011871402,0.06724441,-0.031388402,0.00040624433,0.0106393555,0.008417066,-0.02655233,0.016074177,-0.0031348101,0.036201444,-0.030674504,0.004053088,-0.0046345675,0.037375916,-0.015970547,0.024364585,0.008031332,0.028532816,0.0062523484,-0.001947382,-0.03270105,0.0411066,-0.031457487,-0.022407128,0.023489486,0.0117101995,0.009827586,-0.009770014,-0.017640144,-0.019758802,0.0112381065,-0.036178414,-0.048821285,-0.012804072,0.022084722,0.008422823,-0.034888797,-0.011071147,0.020910248,0.021359311,0.027749835,-0.009263379,-0.013483426,-0.030306043,0.007219563,-0.049788497,0.0019387462,-0.004571238,-0.03749106,0.008750985,0.01359857,-0.02096782,-0.0019315496,-0.026621418,0.017179566,-0.01907945,0.0046144174,-0.022637416,0.008733713,-0.020484213,-0.00654021,-0.010973275,0.024525786,-0.022729533,-0.015268166,-0.029131569,0.025562087,0.039724864,0.035026968,0.035142113,-0.04216593,-0.016269924,-0.0133797955,-0.0003330196,0.018066177,-0.06936307,0.028993394,-0.012412582,-0.042902853,-0.016085692,-0.0038746137,0.00066675886,0.00548088,-0.01916005,-0.0133797955,0.015383311,0.02611478,-0.033414945,0.022556815,0.0205533,-0.0023388735,-0.009977275,0.010288165,0.029453972,0.00077506667,-0.014623356,-0.009890916,0.0037882554,0.004706533,-0.013483426,0.05232168,-0.04066905,-0.030720564,-0.06678383,-0.031710807,0.035303317,-0.07640991,0.0683498,0.04423853,-0.03921823,-0.02223441,-0.04594267,0.01928671,0.028072238,-0.009626083,-0.05508515,0.0023431913,-0.01646567,-0.021693232,0.0050922674,0.006390522,0.020023635,-0.014473668,-0.007835586,0.018192837,0.014277923,0.009061875,-0.0332998,0.013656142,-0.027519545,-0.012792558,-0.012216835,-0.014024605,0.0040243017,0.017340768,-0.00753621,-0.0012680292,-0.03756015,0.023328284,-0.021831404,0.01295376,-0.026437186,0.011019332,0.009061875,-0.041590206,0.0014004455,0.025585117,0.020288467,-0.07949579,-0.0073519787,-0.027058966,0.046564452,-0.015889946,0.016615357,-0.006592025,-0.006240834,-0.020691473,0.0054866374,-0.007720441,-0.012136234,-0.031572632,0.013506454,0.030029695,0.03224047,0.0023187231,-0.036984425,-0.035971154,0.025469972,-0.030190898,-0.0073174355,0.006258106,0.013103449,0.0048159203,0.0037508334,0.004340949,-0.007973759,-0.02117508,-0.0151645355,0.0031693534,0.012470153,-0.004231562,-0.022844676,0.009499424,-0.0063387067,0.008584025,0.011773529,-0.012631356,-0.011422338,0.021255681,-0.02424944,0.0017904976,-0.02802618,0.032378644,0.03353009,-0.019989092,0.012631356,0.01876856,-0.011192049,-0.009902431,0.016845645,-0.055776015,-0.035188172,0.0074037937,-0.015463912,0.021900492,-0.0018307981,0.040991455,0.03288528,0.035326343,0.0006735955,0.039033998,0.0044042785,-0.019148536,0.01739834,-0.012700442,0.002505833,0.005026059,-0.050939944,0.021670202,-0.0011507258,-0.02950003,-0.0007095782,0.043064058,-0.02181989,0.0145657845,-0.0076225684,0.008837343,0.0054923943,0.0004073238,0.002694382,-0.01918308,0.009683656,0.03265499,0.031250227,0.015602085,-0.035902068,0.017571056,-0.015901461,0.0026094632,-0.0076571116,-0.020299982,0.01714502,0.021693232,0.023305254,0.0331386,0.019632144,0.02024241,0.002373417,-0.022741046,-0.01644264,-0.0049022785,0.027772862,0.023316769,0.013425853,0.004015666,0.030513303,-0.0085609965,0.021117508,-0.021485971,0.008296164,-0.051768985,-0.019447913,0.021232653,0.047808014,-0.027703775,0.0009261939,0.04387007,-0.015003334,-0.021601116,-0.00921732,-0.025493002,0.021198109,-0.013967033,-0.02117508,-0.004801527,0.008152233,0.050663598,-0.00917702,0.032793164,0.047301378,0.03500394,0.011249621,0.030927824,-0.005100903,0.0144506395,0.00059263455,0.02823344,0.006217805,-0.012723471,0.019804861,-0.041198716,0.042281076,0.0025187868,0.05628265,-0.0035838739,0.007006545,0.008618569,0.0054319436,-0.02613781,0.040024243,0.0053081634,0.0033132841,-0.008883401,0.015014848,0.025032423,-0.017052906,-0.0090964185,-0.004533816,-0.008290406,0.02202715,0.011203564,0.024571845,-0.0033132841,0.07617962,-0.033783406,0.035971154,0.037583176,0.03438216,0.036339615,-0.020357555,-0.10418278,0.038734622,-0.035441488,-0.00907339,0.023765832,-0.0067877704,0.049696382,0.0332998,-0.0015414975,0.015348767,0.0026641567,-0.011422338,0.0047180476,-0.018284952,0.028486758,0.019194594,0.0053455853,-0.054025818,-0.024686988,0.01636204,0.01096176,0.002271226,0.008474638,0.0136215985,0.0013759772,0.018261924,0.050110903,-0.010610569,0.012412582,0.042488333,0.03735289,0.014945761,0.030582389,0.019908492,-0.034474276,-0.06199382,0.03452033,-0.02295982,0.011952003,0.0020351796,-0.032977395,-0.012930731,-0.017571056,-0.016005091,-0.006396279,-0.00074052333,0.004179747,0.0062350766,-0.009873644,-0.030190898,0.024617903,0.00054441777,0.0063559785,-0.009781528,0.013828859,-0.033414945,-0.045413006,0.023466457,0.019712744,-0.001388931,0.025446942,0.0030743591,0.03967881,0.014335495,0.009223077,0.010017575,-0.033437975,-0.016385067,-0.019666687,-0.0050519668,0.0049483366,0.027473487,-0.060888432,0.010570269,-0.0032816194,0.025792377,-0.016177807,-0.009643355,0.023950065,0.032816194,-0.016765045,0.043547664,-0.010489668,0.02466396,-0.006724441,0.009626083,-0.01685716,0.02761166,0.014381553,-0.013667657,0.008198291,0.005780256,-0.0205533,0.005509666,-0.02487122,0.010547239,0.01411672,-0.014773044,-0.044008244,-0.0024813649,-0.0023690988,-0.022925278,-0.03730683,0.018676445,-0.018054664,0.026598388,0.00807739,-0.019551544,0.04743955,0.017674686,-0.022925278,-0.010506939,-0.03101994,0.02424944,0.03668505,0.042810738,0.008111932,0.025838435,-0.008883401,-0.0036126599,0.0027044574,0.053242836,0.004231562,-0.010731471,0.032585904,-0.03332283,-0.00853221,-0.026252955,0.015486941,-0.016788073,-0.019137023,-0.017317738,-0.03371432,-0.0130228475,-0.018284952,-0.015371796,-0.0068165567,-0.0480383,0.004245955,-0.029269742,0.010489668,-0.0019243531,0.0079104295,0.027012909,-0.0004274741,-0.023996122,0.016005091,-0.011387795,-0.03562572,-0.011399309,0.045459066,-0.010080905,-0.055545725,0.039080057,0.019206109,0.035925098,0.0033708564,-0.03475062,0.014231865,0.016638385,-0.018008607,-0.0459657,-0.026782619,-0.0117505,-0.041843526,-0.0041020242,0.019401854,0.016212352,-0.018446155,0.007305921,0.04638022,0.0020337405,-0.011641113,-0.050986003,-0.01476153,0.030582389,0.025999637,0.01876856,0.0032154112,-0.008555239,-0.035694808,0.0674747,-0.0061429613,0.008123447,-0.015129993,0.0015285438,0.046702623,-0.04032362,0.0449294,-0.008929459,-0.0022064573,-0.0006919467,0.050525423,0.00421429,-0.02781892,-0.019217623,0.003805527,0.0078471005,-0.007887401,0.021094479,-0.021509,0.0036759893,0.025631174,-0.009908187,-0.039724864,0.0063732504,-0.0036155386,-0.017893462,-0.01123235,0.03942549,0.0111747775,0.014911218,-0.023431914,-0.02722017,0.023501,0.008797043,-0.031687777,-0.00176459,0.0109963035,-0.01876856,-0.021796862,-0.012113205,0.00055881083,-0.060151506,0.033806436,0.0064308224,-0.008520695,0.017870432,-0.02763469,-0.015648143,-0.0048994003,0.047140174,-0.0031405673,-0.0068914006,0.007023817,0.032401673,-0.0062523484,0.0063041635,0.0152796805,0.008871887,-0.0034025211,0.0015227866,0.0077031697,-0.0046892613,-0.028578874,0.04071511,0.013011333,0.021221139,0.0341749,0.021543544,-0.043064058,0.02161263,-0.0012291679,-0.01853827,-0.033461004,-0.017029878,0.0037882554,0.004004151,0.0022510758,-0.0034082783,0.02117508,-0.021301739,0.04009333,4.6918026e-06,-0.016903218,0.009752742,0.013402824,0.030098783,0.014508212,0.007956488,0.027726805,0.019563057,0.0038227986,-0.03767529,0.00853221,0.005829192,-0.012861645,-0.007541967,0.0040473305,0.01002909,-0.012262893,0.010437853,0.023788862,0.01127265,-0.007824072,-0.0004368296,0.05084783,0.028118296,0.04131386,0.0019027635,0.018618872,-0.013460397,0.015383311,0.0123089515,0.0020337405,-0.0063790074,0.006045088,-0.00508651,0.011255379,0.031457487,-0.028947337,0.0047698626,-0.0046719895,0.009493668,-0.044583965,-0.010184535,-0.022015635,0.05227562,-0.0067820135,-0.04382401,-0.06494152,0.0017775438,0.0036356887,0.01685716,0.0059990305,-0.0036961397,-0.022407128,0.005207412,-0.005316799,-0.016350525,0.005509666,0.0028555845,0.020507243,0.01995455,-0.0061832615,-0.020668445,-0.01411672,0.033852495,0.014957275,0.014519726,0.001459457,-0.002163278,0.033230714,-0.0024698502,0.0059990305,0.008060117,-0.01833101,0.0067071696,0.0018739774,0.012608327,-0.0004839669,-0.01349494,-0.0038688565,-0.004035816,-0.0019243531,0.01918308,-0.0037306831,0.003618417,-0.009954246,0.009372765,0.032102298,0.004107781,-0.026252955,0.021992607,0.0017991334,-0.0050807525,0.008641598,-0.014842131,0.005406036,0.02595358,-0.002312966,-0.0005598903,0.007962245,0.015786316,-0.038642507,0.01793952,0.03753712,0.005696776,0.015463912,-0.0035032725,-0.026506273,-0.0073001636,0.005860857,-0.029776378,0.017974062,-0.011940489,-0.0058637355,-0.007835586,-0.02171626,-0.0050893887,-0.0035579663,0.01688019,0.02267196,-0.015026363,0.021555057,0.004715169,0.00047497122,-0.02202715,0.0043697353,0.020127265,-0.008578268,0.018895218,-0.012781044,0.003627053,0.025216654,-0.009499424,0.0028555845,0.02381189,0.047808014,0.031434458,0.024295498,0.027749835,-0.014439126,0.025677232,0.0113532515,0.0014954397,-0.005466487,-0.010230592,-0.025884492,0.0058579785,0.0049022785,0.027588632,0.0156136,0.04428459,-0.005987516,-0.013241622,0.022418642,-0.02593055,0.05669717,-0.02593055,0.019701231,0.0061429613,-0.0069432156,0.0016149022,0.0018941277,0.010311194,-0.035096057,-0.048176475,-0.0017070178,-0.02846373,0.009188534,0.00083119964,-0.034428217,-0.0040646023,-0.015187564,0.018158294,-0.041613236,0.021244166,0.0019862433,0.03205624,0.0031520817,-0.009551239,0.03709957,0.0018408733,0.021094479,0.013794316,-0.005906915,-0.019862432,0.0893061,-0.017559541,0.015959034,-0.014174293,0.0031348101,0.0013169657,-0.010386038,-0.0074440944,-0.023581602,0.013149506,0.03101994,-0.008981274,-0.027151082,-0.017674686,0.029154597,0.014473668,-0.03274711,0.0037047756,0.03392158,0.0042200475,0.018883705,0.010650869,0.007029574,0.006972002,-0.0011133037,0.0006113455,-0.028878251,-0.020668445,-0.004499273,0.018998848,0.0076916553,0.041037515,0.0035579663,-0.020392098,-0.018031634,-0.018584328,0.013195564,0.016327495,0.00014528002,-0.008457366,-0.00070310134,-0.014634871,-0.0053052846,0.027358342,0.03141143,0.0017372433,-0.03290831,-0.031388402,-0.031964123,-0.0063214353,0.049880613,-0.021509,0.011658384,0.014819102,-0.00832495,0.002125856,-0.02295982,-0.004467608,-0.037007455,0.0014126796,-0.008658869,-0.006384765,0.038274046,-0.0010391795,-0.0037105328,-0.00917702,-0.078758866,0.005457851,0.0024856827,0.012585298,0.032816194,0.03631659,-0.006085389,0.0028642204,0.0056708683,-0.003917793,-0.03797467,-0.004073238,-0.0044589723,-0.04743955,-0.00255333,0.027565602,0.00863584,-0.0028570239,0.018066177,-0.057526212,-0.006701412,-0.016304467,0.008779771,0.018204352,0.0057082903,0.025170596,-0.028901279,-0.03790558,0.012251379,0.038757652,-0.0033046482,0.00521029,-0.012251379,-0.016592328,-0.014024605,-0.0019963183,0.00647688,0.016431125,0.0076398402,-0.0013695003,0.0020567693,-0.020184837,-0.03253985,-0.058355253,-0.0020510121,0.0021949427,0.0054549724,-0.023362827,0.0018034513,-0.016005091,0.020484213,0.01907945,0.023178596,-0.007467123,0.025631174,0.038757652,0.012458639,-0.014024605,-0.0045107873,-0.023742804,0.05084783,0.020518757,-0.0002723888,0.011151749,0.009292164,0.05623659,-0.0006750349,0.0030283013,0.009700927,0.027151082,-0.0362475,-0.004286255,-0.046702623,0.0068511,-0.017663172,0.042211987,-0.034704562,-0.016212352,7.551863e-05,-0.004936822,-0.024364585,-0.00074484124,0.033161625,0.010052118,-0.00085854647,0.0030542088,-0.01233198,-0.016914733,-0.0312272,0.0142088365,0.024963336,0.00014626955,0.021589601,0.014312466,0.030213926,-0.01675353,-0.03078965,-0.018699473,-0.01602812,-0.003932186,0.0014443443,-0.023224654,-0.0026353707,0.0069835163,-0.012009575,0.015590571,0.0038602205,0.0008830147,-0.00046453625,-0.0073001636,-0.021359311,0.01781286,-0.022176838,-0.010265135,-0.021670202,0.002252515,-0.007835586,0.02094479,0.009983031,-0.023880977,-0.026483243,0.003247076,0.02424944,0.008376765,0.020887218,0.0041164174,0.008048603,0.031549603,-0.016419612,-0.028417673,0.026252955,0.048959456,-0.01845767,0.014300952,-0.007541967,-0.024387613,-0.010253621,-0.00012072185,0.037030485,0.010466639,-0.004824556,-0.032010183,-0.0061084176,0.012101691,0.0032585904,0.01646567,-0.03673111,-0.01688019,-0.016074177,0.031618692,0.00907339,0.05144658,0.0038630993,0.010000303,0.0004490637,-0.006171747,-0.030743591,0.0053570997,0.042764682,0.012850131,0.023132538,-0.006799285,-0.0101672625,-0.022315012,0.01633901,0.019689716,0.029822435,0.0013543876,0.037421975,0.016615357,-0.032102298,-0.01550997,0.016223865,0.022867706,-0.0077837706,0.011186291,-0.017974062,-0.0004397082,-0.010852372,-0.0077780136,0.0077837706,0.0075477245,-0.05444034,0.021255681,-0.01843464,0.017594086,0.03306951,0.011220835,0.027957095,-0.007864372,0.00890643,-0.004640325,0.011048119,-0.026275983,-0.0263681,0.015602085,-0.0051671113,-0.02466396,-0.012654385,0.0066035395,0.044146415,0.017743774,0.010973275,0.0021186594,0.013114963,-0.000132866,0.03857342,-0.0061602327,0.0015141506,0.0016480063,-0.012861645,0.033207685,0.023328284,-0.025377857,0.05038725,0.015060905,0.011859887,-0.03792861,-0.032401673,-0.016350525,0.01613175,-0.0008002545,-0.010967517,-0.004004151,-0.002163278,0.0077492273,0.024917278,-0.021900492,0.023420399,0.025400884,0.0011118645,0.01058754,-0.016350525,0.019010363,0.003894764,-0.014347009,0.0166499,-0.0062811347,0.014726986,0.02443367,0.011859887,0.022522273,0.021048421,0.033576146,-0.032355614,-0.0120671475,-0.018480698,0.02466396,-0.0035205442,-5.132028e-05,0.019655172,0.0059760017,-0.015751773,0.020806618,0.03986304,0.0075649964,0.007023817,-0.04725532,-0.029039452,-0.017962549,-0.024594873,-0.020875705,0.031779893,0.0054146717,-0.043386463,-0.002069723,0.017697716,-0.05227562,-0.0023388735,0.019920005,-0.030651476,-0.009827586,0.01233198,-0.0029405036,-0.01737531,-0.039057028,0.030444216,-0.013886431,-0.011301436,0.025354827,-0.036961395,0.012262893,0.016765045,0.012999819,0.026022665,-0.00818102,0.012378038,0.036224473,-0.009551239,0.01123235,-0.01633901,-0.02171626,0.0036500818,0.051124174,-0.032010183,-0.023097994,0.0031031454,0.008342221,0.04193564,0.016603842,-0.04905157,-0.008394036,0.017582571,-0.06415854,-0.012205321,-0.037652265,-0.00031178983,-0.0044186716,0.012205321,0.010979032,0.023339799,0.019447913,-0.0053427066,-0.00015949318,-0.014473668,-0.005852221,0.0066438396,0.009816072,0.0062868916,0.0244567,0.00616599,-0.0068338285,-0.0028541451]	134
3	2	BONNE BOUCHE CAFÉ Customer Guide & Frequently Asked Questions Welcome! Thank you for choosing Bonne Bouche Café! This guide answers common questions to help you enjoy your visit. "Bonne Bouche" means "A Good Mouthful" in French — and that's exactly what we promise with every dish. General Questions Q: Where is Bonne Bouche Café located? A: We are located at No. 15, Jalan Delima 2/3, Taman Kluang Utama, 86000 Kluang, Johor, Malaysia. We're opposite Kluang Mall, next to CIMB Bank. Kluang is approximately 110 km from Johor Bahru and easily accessible via the North-South Expressway. Q: What are your operating hours? A: Monday to Thursday: 9:00 AM - 10:00 PM | Friday: 9:00 AM - 11:00 PM | Saturday: 8:00 AM - 11:00 PM | Sunday: 8:00 AM - 10:00 PM. Kitchen closes 30 minutes before closing time. Q: Do I need to make a reservation? A: Reservations are not required for regular dining, but we recommend booking for groups of 6 or more, especially on weekends. For private events, please book at least 1 week in advance. Call us at +60 7-772 8899 or WhatsApp +60 12-772 8899. Q: Is parking available? A: Yes! Street parking is available in front of our café, and there's a public parking lot within 2 minutes walking distance behind Kluang Mall. Menu & Food Questions Q: What type of cuisine do you serve? A: We specialize in Western cuisine with Malaysian fusion influences. Our menu includes all-day breakfast, burgers, pasta, steaks, local favourites like Nasi Lemak and Curry Laksa, and freshly baked desserts. Q: Do you serve halal food? A: We offer halal-friendly options! While we are not fully halal-certified, we have pork-free alternatives for most dishes. Please inform our staff of your dietary requirements. Q: Are vegetarian/vegan options available? A: Yes! We have several vegetarian options including salads, pasta, and our mushroom risotto. Vegan modifications can be made upon request — just ask our staff. Q: Can you accommodate food allergies?	0	2025-12-21 23:52:55	2025-12-21 23:52:55	[-0.043921668,0.005976794,0.009737572,-0.035339,-0.006337336,-0.045821108,-0.0030162437,0.023590602,0.017704677,0.01892407,-0.02633424,-0.08076146,-0.0035467977,0.009391686,-0.0704435,0.07058421,-0.019733092,0.029007528,0.0051355287,0.061344944,0.031188369,0.017423278,-0.01089248,0.016450107,0.0012589666,0.034635507,-0.040075883,-0.05473207,-0.029781375,0.0015506247,0.013671293,-0.02064764,-0.00015013434,0.041787725,-0.027483284,-0.025278995,0.040075883,0.010288645,0.015476936,-0.014046491,-0.039184786,0.023789926,0.05684256,-0.0025868174,-0.0037080157,0.0047515365,-0.051355284,0.013425069,-0.036089398,0.040873177,0.0105934935,0.005279159,-0.015148637,0.031704266,0.0054227896,-0.010482106,0.0012098684,-0.016497007,0.06467483,0.055670068,0.03899719,-0.03132907,0.0024812927,-0.0005298212,-0.011537352,-0.008565077,-0.010030695,0.0066539096,-0.0005437446,0.055857666,-0.0120884245,-0.014796888,-0.023543702,-0.0013769489,0.00077531236,-0.01562936,0.042186372,0.017024629,0.009098562,-0.016414931,-0.027108086,0.004080283,-0.01300297,0.058343355,0.016309407,-0.019099945,-0.056045264,0.039231688,-0.06012555,0.038598537,0.048822697,-0.0054755523,-0.0014311768,-0.005129666,0.07006831,0.034471355,-0.030414524,0.025466593,-0.006436998,0.03334576,0.015430035,-0.073351294,0.025865242,-0.02879648,0.053887874,-0.02057729,0.02842128,0.013507144,0.005167772,-0.056608062,-0.058812354,-0.029711025,-0.012885721,0.048306797,0.019182019,-0.01191255,0.048212998,-0.034471355,-0.0019522044,-0.04300712,0.0069646207,0.036277,-0.005756951,-0.03822334,-0.05309058,-0.010687293,-0.028913729,0.019299269,-0.0055195205,-0.04026348,-0.002784676,-0.036839794,-0.0074687935,-0.06556593,-0.022441557,-0.002903391,-0.009538247,0.013425069,-0.033814758,-0.014925863,0.03841094,-0.008711639,-0.023872001,-0.017388102,-0.04059178,-0.04542246,-0.05088629,-0.040404182,-0.035808,0.043405768,-0.008242641,0.006313886,-0.024223749,-0.06176704,-0.044507913,-0.017036354,0.011408377,0.064721726,-0.04321817,0.007357407,-0.0031481492,0.041224927,0.016133532,-0.02659219,-0.0075684558,-0.023145054,-0.016731504,0.013448519,-0.018384723,-0.016321132,0.023215404,0.046125956,0.012815371,0.015828684,-0.023062978,0.041670475,0.034752756,-0.040028982,0.027905384,-0.018959247,0.010358994,0.033322312,0.041623577,0.0025736268,-0.003095387,0.037801243,-0.009256849,-0.0359956,-0.025654193,0.022054633,-0.025513493,-0.0053846836,-0.023555426,-0.0042854697,0.01932272,-0.032829862,0.032478113,-0.0032947112,-0.02842128,0.023156779,-0.029218579,-0.012393273,0.061907742,-0.051214587,0.03606595,0.02408305,0.018337823,0.0010120098,0.014069941,-0.0024461178,0.037027396,0.032900214,0.014245816,0.039020635,0.006554248,0.0058243694,-0.029546877,0.005830232,0.0068356465,-0.011924275,0.0038545777,0.010874892,0.04535211,0.007251882,0.001880389,0.0069646207,0.0100248335,-0.004153564,0.040028982,-0.058953054,-0.0069059962,0.009690672,-0.0075039687,0.0034119608,-0.0002879941,-0.011525627,-0.0028169195,-0.0047573987,-0.0127332965,-0.03154012,-0.002072385,0.04575076,-0.0041154576,0.050933186,0.044883113,0.010018971,-0.009010625,-0.05276228,0.00085811986,-0.018525422,0.0076974304,-0.039606884,0.018443348,-0.044062365,0.023637502,-0.0029576188,-0.042350523,-0.048212998,0.014081666,-0.016485281,0.018490247,0.03822334,0.032407764,-0.014890688,0.0026747545,-0.007902617,0.0032947112,-0.018537147,-0.03097732,0.0118891,-0.05318438,-0.05271538,0.0071698073,0.03086007,-0.0051062163,-0.011261815,-0.00094166014,-0.030508323,0.018091599,-0.009057525,-0.04230362,-0.023297478,0.020166915,-0.048822697,0.0009160118,-0.019170295,0.054497574,-0.033791307,-0.02631079,0.056139067,0.0046987743,-0.02881993,-0.0038809588,-0.0020474696,0.012287749,0.021140087,0.027694333,-0.008113666,0.03397891,0.009292023,-0.0077150175,0.050933186,-0.029382728,0.018947521,-0.021468386,0.036581848,-0.014292715,0.03857509,0.011619426,0.011050766,-0.03559695,-0.008817163,0.05496657,-0.055716965,0.024809996,0.010423481,0.05796816,0.018713022,0.015218986,-0.00023981188,0.053278178,0.000984163,-0.0035702477,0.0027480354,-0.023449901,-0.07757228,0.064018235,0.007421894,-0.06631632,-0.03315816,0.036722545,-0.039278585,-0.004376338,-0.014878963,-0.047392253,0.025232095,0.012287749,0.022183606,0.016262507,0.015101736,-0.010570044,-0.02013174,-0.014691364,-0.035737652,0.013272645,0.004059764,0.05271538,0.035104502,0.04359337,0.042491224,-0.037426043,0.039583433,-0.022629155,0.019604119,0.017235678,-0.0070173834,-0.0064194105,0.05440377,-0.019686192,0.0114259645,-0.008781988,-0.04092008,-0.0044466876,0.034729306,0.021996008,-0.004868786,-0.040028982,-0.027248787,-0.029711025,0.001392338,0.0016107152,0.040193133,0.009262711,-0.03114147,-0.05796816,0.043827865,-0.004986035,0.016203882,-0.0036904283,0.023180228,0.058906153,-0.044859663,0.0005693929,-0.043874767,0.031774618,-0.0089989,0.036652196,-0.04129528,0.061298043,-0.024364447,-0.004332369,-0.009948621,0.029124778,-0.02361405,0.027342586,0.03855164,0.034518257,-0.007240157,-0.0032712612,-0.05065179,0.04286642,-0.019510318,-0.010013108,-0.0027407072,0.008823026,-0.0021207505,-0.03343956,-0.0004180678,-0.04530521,0.018032975,-0.03397891,-0.037238445,-0.009180636,0.039114438,-0.008576802,0.0025179333,0.014081666,0.02053039,0.03829369,-0.0037812968,-0.01681358,-0.006706672,-0.07700948,0.01579351,-0.04059178,0.021691158,0.008477139,-0.027201885,-0.012170499,-0.03348646,0.0034324795,-0.009878271,-0.053700276,0.034377556,-0.021374585,0.003921996,-0.008653014,-0.008653014,-0.035081055,0.0046929116,-0.017517077,-0.010265195,0.023168502,-0.012053249,-0.0355735,0.046196308,0.014585839,0.045938358,0.026732888,-0.039020635,-0.055763867,0.009145462,0.019182019,0.0020591945,-0.029195128,0.041529775,0.0053583025,-0.03784814,-0.008600252,-0.06678532,0.0046020434,0.0001397834,-0.01911167,-0.028092982,0.001903839,0.021140087,-0.036910146,0.0058712694,0.023074703,-0.027717784,-0.027623985,0.00097243814,0.0035761101,-0.027412936,-0.016989455,-0.02166771,-0.013718192,-0.021996008,-0.00509156,0.06598803,-0.011261815,-0.011085941,-0.071240805,-0.036534946,0.04082628,-0.035385903,0.061438743,0.0354328,-0.042139474,-0.004203395,-0.066457026,0.021210436,0.039864834,-0.009555835,-0.04976069,-0.015934208,-0.0024505148,-0.041858073,0.030156573,0.01899442,-0.013870617,0.0015916621,0.028046083,0.03156357,0.031610467,0.026662538,-0.005030004,0.030531771,-0.011091803,-0.013436793,-0.049432393,-0.004364613,-0.0002566665,0.01018312,0.0060324874,0.022746405,-0.011906688,0.020471765,-0.035151403,0.01759915,-0.016274232,0.019357894,0.014034767,-0.04277262,-0.013940967,0.017481903,0.015078287,-0.04767365,0.00897545,-0.037050843,0.043288518,-4.275485e-05,0.038364038,-0.00054044696,-0.013647843,-0.032407764,0.0028330414,0.0048424047,0.003737328,-0.041951876,-0.020237265,0.014878963,0.011818751,0.0017777957,-0.0123346485,-0.03395546,-0.0072636073,-0.049666893,-0.012545697,0.006929446,0.009802059,0.024809996,0.001138053,0.009925171,-0.009057525,-0.0071346327,-0.004534625,-0.012041525,0.019299269,-0.029148228,-0.022324307,0.0037431906,-0.010628668,0.027905384,0.016332857,-0.022558806,-0.0038252652,0.018267473,0.000605667,-0.005979725,-0.025583843,0.00016717215,0.04577421,-0.03749639,0.017188778,0.0049713794,0.0038018154,0.003775434,-0.01321402,-0.020424865,-0.03156357,-0.021996008,-0.023625776,0.015125187,-0.0010918861,0.02162081,0.017165327,0.024974145,0.02877303,0.040028982,0.028491631,-0.04314782,-0.0073867193,-0.020284165,-0.0067652967,0.0020943694,-0.010482106,0.0020122947,-0.0014003988,-0.019475143,-0.006114562,0.0480254,-0.010470381,-0.0024944833,-0.028374381,0.0026513045,-0.006261124,-0.022453282,0.027483284,-0.020882137,0.017563976,0.018548872,0.016121808,0.024036149,-0.034330655,0.01664943,-0.01323747,0.004903961,-0.02053039,-0.014339615,0.01316712,0.01013622,0.011513902,0.011871513,0.006993933,0.0038897526,0.007990554,-0.009333061,-0.028280582,-0.016391482,0.014632739,0.019064771,0.027037736,0.0019947074,0.018431623,0.020717988,0.027412936,-0.0018891827,0.0067008096,-0.044132717,-0.016907379,0.001880389,0.06575353,-0.044015467,-0.013296095,0.002434393,0.004094939,0.005586939,0.002334731,-0.0357611,0.011754263,-0.0021398035,-0.009766884,-0.032313965,0.008488865,0.06186084,-0.014656189,0.013964416,0.022218782,0.04286642,-0.007545006,0.016321132,-0.018771647,-0.011384928,-0.012000487,0.052433982,-0.02133941,0.0039864834,0.029218579,-0.03587835,0.035104502,-0.0043822005,0.030391073,0.006184912,-0.0010750315,0.0125808725,0.008107804,-0.01927582,0.034471355,0.009954483,-0.03625355,-0.011701501,-0.024763096,0.024552047,-0.00026051374,0.016098358,0.018396448,0.0011864185,0.016180431,0.0014758782,0.010259332,0.001868664,0.034401007,-0.024153398,0.0138119925,0.034565154,0.004947929,0.051636685,0.007972967,-0.111058734,0.02126906,-0.052105684,0.023989249,0.022300856,0.0033591983,0.02136286,0.029077878,0.006753572,0.027975732,-0.015617635,-0.0132257445,0.022980904,-0.011900825,0.05440377,0.00032170335,0.01314367,-0.052902978,-0.027975732,0.01013622,0.022418106,-0.0096085975,0.037168093,0.0048599923,-0.041975323,0.015066562,0.051402185,-0.030437972,0.0021368724,0.041389078,0.02863233,0.015031387,0.04356992,0.0047896425,-0.031844966,-0.06387753,0.029640676,-0.0060500745,0.003549729,-0.022547081,-0.052433982,-0.011613564,0.0015638153,-0.02126906,-0.014972762,-0.010570044,-0.0043616816,0.0072694696,-0.021210436,-0.06368993,0.022488456,-0.005560558,0.008465415,0.025114845,0.014269265,-0.027530184,-0.04994829,0.01437479,0.0034002357,0.014116841,0.03583145,-0.014550664,0.03808264,-0.02612319,0.0021104913,-0.01089248,-0.01662598,0.03121182,-0.01435134,0.01579351,-0.016086632,-0.0010127426,-0.048916496,0.04035728,0.034588605,0.025701093,-0.0006587957,-0.03102422,0.020671088,0.0033298861,-0.03852819,0.041576676,0.00074270234,0.0481661,-0.032501563,-0.009884134,-0.005698326,0.00852404,0.015547285,-0.03135252,0.010265195,0.0027480354,-0.010910067,0.021245612,-0.020073116,-0.0057540196,0.022910554,-0.010253469,-0.02642804,0.015969383,0.009866546,-0.01079868,-0.011977037,0.010722468,-0.00084786053,0.028092982,0.04054488,-0.0006738183,0.04786125,0.03369751,-0.008711639,-0.006237674,-0.023191953,0.0026014736,0.025794892,0.035268653,0.00023028537,0.0151369115,-0.022218782,-0.015828684,-0.023274027,0.05984415,0.029030979,-0.01077523,0.032313965,-0.044343766,-0.013026421,-0.011220778,-0.027741235,-0.0057979883,-0.04795505,0.0037519843,-0.020424865,-0.026826687,0.0011314577,-0.036089398,-0.0052674343,-0.027764684,0.007345682,-0.009884134,0.011484589,-0.009889996,0.013952692,-0.013389894,0.016215608,-0.015910758,0.025677642,0.00025758252,-0.035151403,-0.019182019,0.041389078,0.015699709,-0.03761364,0.023274027,0.0077091553,0.011402515,0.016121808,-0.016602531,0.0064897602,0.025818342,-0.03852819,-0.049150996,-0.0010647721,-0.012850546,-0.02029589,-0.00017404224,0.004138908,0.0044672065,-0.005938688,0.010640393,0.0040363143,0.019217195,0.001968326,-0.018478522,-0.0033914421,0.018361272,0.039466184,-0.0017367584,0.0048130923,-0.014656189,-0.058577854,0.07081871,-0.0059738625,0.0023449901,0.016016282,-0.0049831043,0.032595363,-0.02162081,0.030226924,-0.0060735247,-0.0022336033,0.0073398193,0.012709847,0.018044699,-0.011906688,-0.021210436,0.011396652,-0.0077853673,0.003095387,0.02412995,-0.006079387,-0.00030466553,0.018935796,-0.013131945,-0.013694743,0.045563158,-0.01020657,-0.026216991,0.029968975,0.029382728,-0.001638562,0.008711639,-0.011754263,-0.024856895,0.019826893,0.01015967,-0.0075039687,-0.0012120669,0.0359956,0.0030133124,0.0069001336,0.011836338,0.017012903,-0.052902978,0.027811583,-0.024669297,-0.01880682,0.017411552,-0.022465006,0.013882342,-0.020987662,0.01994414,0.0064135483,0.0043939254,-0.0011431827,0.053794075,-0.017692951,0.0034823103,0.00852404,0.003672841,0.03158702,-0.0041418388,0.015160361,-0.0125808725,-0.023332652,0.04720465,0.023743026,0.0056426325,0.010429344,-0.009796197,-0.027670885,0.04493001,0.016133532,-0.01899442,-0.026146641,-0.012440173,0.0063900985,-0.010716605,0.015981108,-0.013577493,0.028608881,-0.018572323,0.03838749,0.0049889665,-0.01783365,0.039817933,0.004986035,0.046337005,-0.0016825305,-0.0071698073,0.02635769,0.010482106,0.021491835,-0.025161745,0.010587631,-0.011736676,-0.0013095305,-0.008805438,0.010106908,0.023649227,-0.023508526,-0.015336236,0.03292366,0.003429548,0.0024006837,-0.015183811,0.026756339,0.02659219,0.04938549,-0.016872205,0.0178571,0.024481697,-0.00094312575,-0.0045580748,0.0046284245,0.01421064,-0.0048424047,-0.023016078,0.011056629,0.06514383,-0.021925658,0.0016781336,-0.032267064,-0.014773439,-0.05051109,-0.008746813,0.0054667583,0.037168093,-0.024809996,-0.034846555,-0.08184016,0.015570735,0.03334576,0.011121116,0.009338924,-0.029781375,-0.009491348,-0.0070701456,-0.008588526,-0.027694333,0.013964416,0.0036640472,0.015922483,0.015969383,0.011080079,-0.031375967,-0.0007049627,0.06223604,0.013483694,0.039747585,0.017435001,0.0042327074,0.019955866,-0.0060207625,-0.020202091,0.016754955,-0.008817163,-0.020307615,-0.011021454,-0.0063959607,-0.001257501,-0.02027244,-0.00359956,0.007052558,-0.019182019,0.014316165,-0.007521556,-0.006384236,-0.0010178724,0.008735089,0.027506735,-0.013683017,-0.02889028,0.028210232,0.02041314,0.022113258,0.0060149,-0.007445344,-0.020284165,-0.0025780236,-0.013788543,-0.02394235,0.016051458,0.01927582,-0.03824679,0.0011834872,-0.0026088017,0.0012252574,-0.0043206443,0.004534625,-0.021351136,-0.0049274107,-0.002849163,-0.04380442,0.017294303,-0.0029414971,0.0016224401,0.008629564,-0.00087863853,-0.0053055403,-0.004218051,0.01572316,0.026943937,-0.0014509627,0.025255544,-0.013987866,-0.0004198998,-0.018830271,0.0054579647,0.029382728,-0.028960628,0.017059803,-0.004660668,-0.02268778,0.038012292,-0.013108496,0.0019009077,0.006988071,0.04265537,-0.0005657289,0.023180228,0.011261815,0.0009489882,0.017094979,0.0041975323,-0.001107275,-0.007445344,-0.00021269794,0.010769367,0.024294099,0.01899442,0.008125391,0.014937587,0.02171461,-0.01653218,0.026990836,0.0016473556,-0.014738264,0.03569075,-0.03824679,0.041647024,0.018830271,-0.004833611,-0.0041740825,-0.0003740992,0.005018279,-0.022160158,-0.015043112,0.0032859175,-0.02631079,0.0044789314,-0.01693083,-0.029945524,-0.0181854,-0.022429831,0.03292366,-0.044249967,0.00658356,-0.0013593615,0.03318161,0.013495418,-0.0019566012,0.036863245,0.0076270807,0.043523017,0.0033474735,-0.0017587426,-0.011906688,0.069740005,0.0057804007,0.018537147,-0.0064780354,-0.0056133205,-0.022910554,-0.02835093,-0.012346373,-0.014632739,0.023285752,0.009333061,-0.010652118,-0.011261815,-0.00090501964,0.035127953,0.014163741,0.0004510442,0.008934413,0.021304237,-0.025044495,0.00724602,0.020260716,0.02366095,0.015617635,-0.0038780274,-0.0042708134,-0.024176849,-0.010822129,0.0022892966,0.03341611,-0.01567626,0.02361405,-0.00095118664,-0.038364038,-0.011508039,-0.025278995,-0.0067008096,0.008752676,0.01572316,-0.0056778076,0.008676464,-0.009884134,0.010540731,0.023649227,0.020084841,-0.0048277485,0.011044904,-0.022148432,-0.015054837,-0.010857305,0.04024003,-0.021949109,0.0049772416,0.010992141,-0.00044371613,-0.02029589,-0.030320723,-0.010558318,-0.05215258,0.0017543458,-0.007545006,0.034518257,0.024153398,-0.028304031,0.0043880627,-0.015899034,-0.046876352,-0.00050930254,0.018032975,0.034612056,0.0027319135,0.032829862,-0.006507348,0.027412936,0.0047368803,0.027436385,-0.021163536,4.67395e-05,0.002299556,-0.018642671,-0.0017646052,0.02126906,0.010558318,-0.023191953,0.04267882,-0.03773089,-0.010757643,-0.024575498,-0.024106499,0.034189958,0.0034207543,0.034752756,-0.005768676,-0.012311199,-0.00047192926,0.041435976,-0.0177633,0.0052205343,0.009755159,-0.017435001,-0.011666326,-0.0048160236,0.005276228,0.0020284166,-0.007486381,0.006132149,-0.004563937,-0.014867238,-0.028022632,-0.046548054,0.012322923,-0.012205674,-0.012158774,-0.013683017,0.0074687935,-0.019451695,0.008582664,0.017259128,0.028186781,-0.004291332,0.042608473,0.033322312,0.007163945,0.001038391,-0.005053454,-0.03803574,0.03144632,0.034307208,-0.025583843,-0.0351983,0.0070935953,0.042327072,0.0067008096,-0.020940762,-0.019615844,0.027084637,-0.058624756,-0.005622114,-0.018666122,0.019357894,-0.0076270807,0.04596181,-0.037777793,-0.0022966247,0.004288401,-0.022722956,-0.035034154,0.015019662,0.01788055,0.021609085,-0.003957171,0.001887717,0.027154986,-0.018584047,-0.032102916,0.0054902085,0.03887994,0.009309611,0.011549077,-0.013178845,0.017294303,-0.01065798,-0.017024629,0.003156943,-0.002872613,-0.0060500745,0.024809996,-0.030180024,0.009262711,0.0057510883,-0.026779788,-0.0056309076,-0.0056367703,-0.004921548,-0.007603631,0.014527215,-0.041693926,0.010312094,-0.029593777,-0.004417375,-0.00066209334,0.0040714894,-0.0057862634,-0.003045556,0.012686397,-0.029429628,-0.019826893,-0.00210756,0.022218782,0.013342994,-0.010757643,-0.03097732,0.038364038,0.046243206,0.0024080118,-0.0033504048,0.032267064,0.050370388,0.0023449901,0.00023413262,-0.020952487,-0.02877303,-0.016180431,0.008441965,0.006114562,0.003968896,-0.031938765,-0.010294507,-0.015301061,0.01634458,-0.008688189,-0.00014647028,-0.056373563,-0.0012362495,0.013307819,0.04312437,0.02361405,0.01920547,-0.002907788,0.020952487,0.010259332,0.010669705,-0.02038969,-0.002372837,0.029312378,0.0240596,0.0046079056,-0.0071404953,-0.013612668,-0.030180024,0.034635507,0.005056385,0.013378169,0.025114845,0.034002356,0.014644464,-0.035081055,-0.0028594225,0.011900825,0.027999183,0.005194153,0.02126906,-0.028139882,0.021128362,-0.0051648407,-0.009110287,0.014621014,-0.010417619,-0.04106078,-0.008541627,-0.027928833,-0.015195536,0.028139882,0.0037695717,0.034823105,-0.046524607,0.023602325,-0.011988763,0.01555901,-0.02017864,-0.051355284,0.0006972682,-0.00504466,-0.00085665425,0.003798884,0.0042766756,0.040286932,0.0062962985,-0.0041213203,0.012662947,0.0025897485,-0.0021442005,0.027272236,-0.0052674343,0.0061497367,0.0056690136,-0.011115254,0.037402593,0.027108086,0.008653014,0.027483284,0.02652184,0.032384314,-0.043992016,-0.043827865,-0.007556731,0.025372794,0.003130562,-0.017739851,0.004833611,0.0012765541,0.0090223495,0.0070232456,-0.0057276385,-0.003241949,0.009632047,0.0034705854,0.0097786095,-0.0123346485,0.023473352,-0.0067770216,0.0020005698,0.018595772,0.00997207,0.03522175,0.023602325,0.007779505,0.041764274,0.03887994,0.015254161,-0.021444935,-0.008184016,-0.011695638,0.007826405,0.014925863,-0.014925863,0.022371206,0.005938688,-0.012721572,0.03805919,0.032900214,-0.008518177,0.018935796,-0.033674058,-0.029593777,-0.013765092,-0.024880346,-0.025161745,-0.0023024871,-0.019522043,-0.024575498,-0.014527215,0.02022554,-0.03146977,-0.0138119925,0.014105116,-0.016989455,0.0032331552,0.011150428,0.0017851238,0.022171883,-0.02842128,0.018525422,-0.022418106,-0.020436589,0.021257335,-0.008137116,-0.0077736424,0.0044847936,0.0004667996,0.011760126,0.01892407,-0.0058859256,0.051730484,-0.0025868174,0.0024856897,-0.001119,-0.024481697,0.0030103812,0.04265537,-0.029499976,-0.027975732,-0.018150223,0.026873587,0.049338594,0.021984283,-0.042209823,-0.0072929193,0.021925658,-0.05266848,-0.02863233,-0.013776817,0.007843992,-0.0019448763,0.0029605501,0.016520455,0.034049258,0.0055136583,0.026052842,0.017528802,-0.025630742,0.004080283,-0.0053084716,-0.022769855,0.018701296,0.010552456,0.04056833,0.014011316,-0.020671088]	493
4	2	mushroom risotto. Vegan modifications can be made upon request — just ask our staff. Q: Can you accommodate food allergies? A: Absolutely. Please inform our staff about any allergies (nuts, gluten, dairy, seafood, etc.) when ordering. We'll do our best to accommodate your needs and advise on suitable dishes. Q: Do you offer all-day breakfast? A: Yes! Our full breakfast menu is available from opening until closing time. Enjoy pancakes, eggs benedict, or our Big Breakfast any time of day! Q: What's your signature dish? A: Our customers love our Bonne Bouche Signature Burger (RM28.90) and the Burnt Cheesecake (RM16.90)! For drinks, try our Gula Melaka Latte — it's a local favourite. Services & Facilities Q: Do you have Wi-Fi? A: Yes, free high-speed Wi-Fi is available for all customers. Ask our staff for the password: BonneBouche2024 Q: Is the café wheelchair accessible? A: Yes! We have step-free access and a disabled-friendly restroom. Q: Can I work or study at your café? A: Of course! We welcome students and remote workers. We have power outlets available and a comfortable environment. During peak hours (12-2 PM, 6-8 PM), we kindly ask that you order periodically if staying long. Q: Do you offer takeaway? A: Yes! All menu items are available for takeaway. Self-pickup orders get 10% off. We also partner with GrabFood, FoodPanda, and ShopeeFood for delivery within Kluang. Q: Can I book the café for private events? A: Yes! We offer full venue rental for private events (20-70 pax) including birthdays, corporate meetings, and family gatherings. Contact us at +60 7-772 8899 for customized packages. Q: Do you provide catering services? A: Yes, we offer off-site catering for events. Minimum 30 pax with at least 1 week advance booking required. Menu can be customized to your needs. Payment & Pricing Q: What payment methods do you accept?	1	2025-12-21 23:52:56	2025-12-21 23:52:56	[-0.009801485,-0.0056621484,0.03964472,-0.049194552,-0.0035682826,-0.028133295,-0.021267738,0.031720936,0.017873676,-0.026158802,0.006665526,-0.025616784,-0.012247017,-0.004271615,-0.054976072,0.058641143,-0.030791761,0.025578069,-0.014853863,0.048084706,0.060809214,0.038844597,0.00096062943,0.023319662,-0.017421994,0.028701123,-0.042819392,-0.033708334,0.02204205,0.0098724635,0.007381764,-0.02104835,0.010975856,-0.0009332059,-0.03285659,-0.021358075,0.019370677,-0.025087671,0.02994002,-0.012369616,-0.04909131,0.007891518,0.033837385,-0.010988762,0.004326462,0.021603273,-0.03551506,0.028159104,-0.0239133,0.04849767,0.016789641,0.014699001,-0.023293853,0.0030585278,-0.005749258,-0.010149925,-0.024971526,0.007704393,0.04914293,0.043154925,0.060860835,-0.0032488795,0.0231648,-0.001858346,-0.020157892,-0.012363164,-0.005910573,0.032521058,-0.011834051,0.03572154,0.014363467,-0.03468913,-0.019719116,-0.031333778,0.008749713,-0.0013010036,0.052524086,-0.006607453,-0.017447805,-0.02284217,-0.01085971,-0.03502466,-0.0011404954,0.03001745,0.030094882,-0.006391291,-0.07268198,0.03468913,-0.07474681,0.029991642,0.035979643,0.0020438582,0.018841565,-0.0034069677,0.07619219,-0.025991036,-0.023758437,-0.0061654504,-0.020067556,0.06204811,0.022726024,-0.09353675,-0.020557953,-0.041735355,0.057970073,-0.023203516,0.04410991,0.0058073313,-0.00976277,-0.029630296,-0.09271082,0.0068139355,-0.017602667,0.024003636,-0.0041425633,-0.01788658,0.047620118,-0.025152197,-0.023332568,-0.057453867,0.012776129,0.049039688,0.001551848,-0.0075108153,-0.038715545,-0.053995278,-0.045039084,0.00347472,-0.026739536,-0.06617777,0.007407574,-0.042303182,0.022287248,-0.04617474,-0.013060044,-0.028830174,0.005452439,0.021229023,-0.039954443,-0.009330446,0.0455811,-0.013756923,-0.008665829,0.0015889504,-0.049323604,-0.033372797,-0.042277373,-0.034508456,-0.035411816,0.030404607,-0.008407725,0.00978858,-0.032417815,-0.027694518,-0.014002121,-0.01352463,0.01853184,0.072578736,-0.052498277,0.026842777,-0.015950805,0.0313854,-0.027901001,-0.057557106,0.010827447,0.0009848266,-0.028959226,0.034663316,-0.035540868,-0.01920291,0.02421012,0.04269034,0.020080462,0.03858649,-0.034405213,0.0044619665,0.038870405,-0.022971222,0.026507242,-0.0075882464,-0.0036586188,0.04410991,0.053892035,-0.018918995,-0.004952363,0.029552864,-0.036289368,-0.050820604,-0.025668405,0.02921733,-0.013292337,0.0095756445,-0.026145898,-0.0041490155,0.01982236,-0.06364835,0.02841721,-0.026249139,-0.037450835,0.016531536,-0.026687915,-0.012563194,0.04774917,-0.038121905,0.03912851,-0.014079552,-5.5149485e-05,-0.010440292,0.033192124,0.0035779614,0.024364982,0.032624297,0.013847259,0.008814239,-0.0060944716,0.007936686,-0.054356623,0.00060976984,0.044445444,0.021358075,0.004326462,0.023280947,0.03414711,0.015731417,0.0120921545,0.030249745,0.0008477091,0.0014445737,0.018570555,-0.041554682,0.022377584,0.0070204185,-0.045916636,-0.0005520998,0.004045774,-0.00694944,-0.008614209,0.0051072254,-0.027926812,-0.04405829,0.019151289,0.03414711,-0.017989822,0.021603273,0.05187883,-0.0025003788,0.0039167223,-0.05575038,0.017292943,-0.028313966,0.021061255,-0.054563105,-0.008865859,-0.07097849,0.01018864,-0.024945715,-0.026533052,-0.04542624,0.049504276,-0.022119481,0.023422904,0.014479613,0.012034081,-0.0055363225,0.016750924,-0.0012477697,0.0065977736,-0.010504818,-0.007749561,0.032624297,-0.067158565,-0.060344625,0.0012058278,0.0328824,-0.0038263863,-0.010633869,-0.00059000874,-0.020157892,0.0022826039,0.008788428,-0.037992854,-0.017718814,0.024726328,-0.0630289,-0.0062557864,-0.00088561804,0.07779243,-0.0061719026,-0.024119783,0.046871617,0.014324751,-0.03205647,-0.012763225,-0.013382673,0.050872225,-0.0045200395,0.030378796,-0.009795032,0.049194552,-0.012795487,-0.018647987,0.030456228,-0.009607907,0.017176796,-0.0057653897,0.015047441,-0.020932203,0.07072039,0.037115302,-0.002163231,-0.018970616,-0.00039844748,0.023448713,-0.040935233,0.0004561175,0.03427616,0.05915735,0.010207999,-0.0012630946,-0.011330749,0.063132145,0.031178918,-0.014144079,0.0027649351,-0.026287854,-0.07732785,0.058279797,0.0010904878,-0.035850592,0.002218078,0.045064893,-0.048291188,0.01497001,0.010104757,-0.026558863,0.012589004,0.002227757,0.035411816,0.01780915,-0.011717904,-0.024068162,-0.049814,-0.030998245,-0.045193944,-0.005594396,-0.019073857,0.059931662,0.043825995,0.009407877,0.055440657,-0.03267592,0.019512635,-0.016299244,0.005568586,0.0321339,-0.01392469,0.045865014,0.023100274,-0.037270162,0.02552645,-0.016002424,-0.009807938,-0.0008565814,0.029423812,0.03339861,0.029862588,-0.02852045,0.024816664,0.00028230084,0.010524175,0.0075753415,0.054614726,0.0051298095,-0.020080462,-0.06292567,0.03275335,0.024416603,0.030533658,0.026842777,0.0094272345,0.072423875,-0.02919152,0.026210424,-0.004610376,-0.0014453803,-0.01173081,0.05154329,-0.030094882,0.03693463,-0.04697486,-0.004871706,-0.017228417,0.015189398,0.006207392,0.028391398,0.019938504,-0.0043522725,-0.023603575,-0.00031496707,-0.029501244,0.038199335,0.005778295,-0.018738324,0.00087432604,0.01922872,-0.004368404,0.007246259,-0.0075559835,-0.042225752,0.026558863,-0.037631508,-0.04150306,0.0037231448,0.0035650562,-0.0066719786,-0.03352766,0.010246714,-0.008498061,0.011504969,-0.0069236294,-0.0376057,-0.03850906,-0.07474681,0.014557044,-0.029036658,0.012530931,-0.007936686,-0.038147714,-0.05425338,-0.025913604,-0.036082886,-0.029656107,-0.030172313,0.02279055,-0.0027649351,0.043180738,-0.020351471,-0.00364894,-0.022119481,0.012589004,0.017602667,0.0047587855,0.022132386,-0.015666889,-0.029991642,0.015757225,0.041709546,0.06122218,0.038018662,-0.051233567,-0.053995278,0.020738626,0.04914293,-0.01786077,-0.06638425,0.03510209,0.01491839,-0.028184915,0.008633566,-0.07087526,0.0149441995,0.011053287,-0.01700903,-0.013124569,0.014828053,0.009207847,-0.043129116,0.007904423,0.009136869,-0.026662104,-0.036676526,-0.014518329,0.009123963,-0.01422151,-0.010814542,-0.014634475,-0.056731176,0.0040683583,-0.018041443,0.037941232,-0.024197215,-0.014169889,-0.056731176,-0.035979643,0.028572071,-0.024945715,0.073043324,0.014544139,-0.010614512,0.009046532,-0.04718134,0.03355347,0.033889007,-0.013182643,-0.008710997,-0.010530627,0.0031391853,-0.055337418,-0.012989065,0.026662104,0.0010743564,-0.015163587,0.0020438582,0.0029988415,0.017318754,0.009059438,-0.023422904,-0.0067042415,-0.019138383,-0.007517268,-0.061583523,-0.025371587,0.0012098608,0.031798366,0.009369162,0.008717449,0.00049402646,0.02702345,-0.046768375,0.0060880193,-0.021358075,0.023952017,0.02131936,-0.029991642,-0.009336898,-0.0074462895,-0.0018809302,-0.046019875,-0.010433839,-0.07175281,0.025552258,-0.010053136,0.019293245,0.0064396854,-0.03435359,-0.0028923738,-0.0023906848,0.01295035,0.006826841,-0.026236232,-0.018673796,0.004316783,0.019977221,-0.007781824,-0.014518329,-0.03430197,-0.0019148062,-0.041657925,-0.011717904,-0.024855379,-0.006936535,0.006455817,0.024442414,-0.00070413895,-0.0028230085,0.009956347,0.009930537,-0.030223934,0.017705908,-0.016828356,0.0012671275,0.0054169497,-0.010446744,0.027488036,0.008523872,0.006239655,0.005516965,0.0056911847,-0.017654289,0.004413572,-0.041090097,0.030895004,0.02774614,-0.053840414,0.028236536,0.009446593,0.0070849443,0.0013994055,-0.019422298,-0.016028235,-0.04475517,-0.03468913,-0.025023146,-0.0015066799,-0.013143927,0.049117118,0.028933415,0.05636983,0.028572071,0.05273057,0.027488036,-0.04622636,-0.0023326115,-0.0046200547,-0.014479613,0.004665223,-0.01783496,0.03902527,-0.013253621,-0.009007816,0.0054685706,0.026455622,-0.022455014,-0.013627871,-0.038250957,0.0032408135,0.011504969,-0.013395578,0.008233505,-0.018635081,0.03334699,0.027229931,-0.0010057975,0.003266624,-0.04127077,0.004762012,-0.01673802,-0.004368404,-0.011150076,0.0036650714,0.007388216,0.004029643,0.023964921,0.036753956,0.007433384,0.010820994,-7.1129725e-05,-0.0052072406,-0.014363467,0.010382218,0.018841565,0.020493427,0.0119824605,0.0101305675,0.029604485,8.015327e-05,0.015757225,-0.010117662,0.003519888,-0.03920594,-0.0060138144,0.014686096,0.041090097,-0.045168135,-0.017576857,-6.326564e-05,0.017654289,0.016286338,0.012860013,-0.02321642,0.0026745987,-0.0031843535,0.021151591,-0.030998245,0.008678734,0.03623775,-0.024635991,-0.0066139055,0.0007509202,0.040702943,-0.022958318,0.017473616,-0.018944805,-0.00035186784,0.0066203577,0.058021694,-0.03068852,0.02177104,0.0239133,-0.03419873,0.05559552,0.012769677,0.05195626,0.00084286963,-0.025823267,0.0199256,0.0033843836,-0.04767174,0.055389035,0.0140924575,-0.020144988,-0.017331658,-0.011775978,0.022080764,0.005297577,-0.0016034688,0.009407877,-0.013356863,0.024042353,-0.033114694,-0.006210618,-0.0012219594,0.020661196,-0.015821751,-0.0036553924,0.035127904,-0.0082786735,0.043206546,-0.006262239,-0.095085375,0.01387307,-0.026816966,0.024661802,-0.0010759694,-0.011092003,0.028907606,-0.00040429513,-0.015963709,0.018544745,-0.01103393,-0.030223934,-0.0028794685,-0.024726328,0.058692764,-0.008801334,0.014156983,-0.044006668,-0.033785764,0.020532142,-0.015783036,-0.0058847624,0.01813178,-0.01424732,-0.04139982,0.00926592,0.051104516,-0.017602667,0.015486217,0.012311542,0.04127077,0.006717147,0.032959834,0.018996427,-0.0034940778,-0.05487283,0.034327783,-0.0027697745,0.010395124,-0.02177104,-0.05260152,-0.012518026,-0.010111209,-0.006500985,-0.021293549,-0.02495862,-0.0043038777,0.010156377,0.007839898,-0.038534872,0.030791761,-0.007988307,0.011363012,0.0015776583,0.011014572,-0.027591277,-0.051233567,0.029062469,0.021087065,0.0021874283,0.022274343,-0.0070204185,0.022726024,-0.021229023,-0.007885066,-0.021074161,0.012924539,0.020493427,-0.0199256,-0.016350865,-0.00222937,-0.0017889807,-0.07025581,0.025436113,0.042509668,0.031617694,-0.009394972,-0.009388519,0.002206786,0.0057105427,-0.022222722,0.05791845,-0.005365329,0.043955047,-0.01989979,-0.00926592,-0.00524273,0.023268042,-0.0049684946,-0.025203818,-0.01786077,-0.003145638,-0.020854773,0.017873676,-0.038715545,0.007659225,0.014156983,-0.013447199,-0.041167527,0.01636377,0.019499728,-0.030972434,-0.010691943,0.010911331,-0.0024503712,-0.0006065435,0.045219753,0.0016728342,0.054821208,0.025694216,0.0047265226,-0.0038876857,-0.042871013,0.024765043,0.013756923,0.017357469,0.0010082172,0.030740142,-0.0091691315,-0.012408332,-0.015821751,0.061428662,0.0009154613,-0.0082786735,0.033166315,-0.036908817,0.0019502955,-0.025991036,0.006271918,0.011066193,-0.042380616,0.007768919,-0.00964017,0.0011050061,0.0041586948,-0.015473312,0.006794578,-0.037528265,0.020364376,0.012350258,0.020157892,-0.0071623754,-0.0023229327,0.007110755,0.0036682978,-0.004874932,0.031953227,-0.0061106035,-0.025461921,-0.019383581,0.021551652,0.0043877615,-0.030172313,0.024739232,-0.0004107477,-0.0103886705,0.018105969,-0.005487928,0.010827447,0.040212546,-0.028726934,-0.044574495,0.01850603,-0.0054814755,-0.009943442,0.023280947,-0.005116904,0.02852045,0.0005113678,-0.0049814,0.012847108,0.010156377,-0.008123811,-0.018712513,-0.013331052,0.024042353,0.017641382,-0.0044619665,0.024158498,-0.006852651,-0.051156137,0.052111123,0.015370071,0.0066397157,0.004055453,-0.01681545,0.04976238,-0.010401576,0.02351324,-0.00043192029,0.009988611,-0.011111361,0.028313966,0.028159104,-0.02493281,-0.008601303,0.011859861,-0.0055556805,0.00958855,0.0030585278,-0.004903969,0.0053717815,0.041657925,-0.03964472,-0.0013397192,0.02777195,-0.025216725,-0.035386007,-0.0010824221,0.004816859,0.0067558624,0.0043587247,-0.021151591,-0.0069429874,-0.0076398673,0.031772558,-0.0042038625,-0.00869164,0.022480825,-0.01778334,0.014737717,0.019112574,0.030378796,-0.056937657,0.017267132,-0.021151591,-0.019086763,0.016867071,-0.025745837,0.018647987,-0.014995821,0.045271374,0.009111058,-0.001987398,-0.010608058,0.053066105,-0.014002121,0.014144079,-0.00480718,-0.0138343545,-0.006962345,-0.00633967,-0.012963254,-0.0052362774,-0.015202303,0.031798366,0.013963406,-0.0016857393,-0.017267132,0.018841565,-0.041451443,0.02774614,-0.017989822,0.0031811271,-0.0077624666,-0.013614966,-0.0091691315,-0.012821297,0.030482037,0.0036005455,0.0072914273,-0.018441504,0.029630296,0.004339367,-0.028365588,0.019125478,0.01065968,0.034508456,0.031153107,-0.0028536583,0.025874889,0.012027629,0.027591277,-0.030378796,-0.00034077745,0.0038586492,0.0021777493,-0.004591018,0.007059134,0.00819479,-0.025513543,-0.0070784916,0.037270162,-0.004019964,-0.013343957,-0.011840504,0.007485005,0.042432234,0.042612907,0.016867071,0.0018986748,0.015744321,0.0045200395,-0.008878765,0.0062202974,0.0129826125,-0.014931294,-0.032211334,0.031669315,0.047310393,-0.009369162,-0.021990428,-0.01850603,0.019164193,-0.047155533,0.016686399,-0.0041167527,0.021125782,-0.0061719026,-0.04047065,-0.08032185,0.034482643,0.0104273865,0.01820921,-0.00065534125,-0.011124266,-0.02458437,-0.0063816123,-0.01751233,-0.016931597,0.016931597,0.029139899,-0.004413572,-0.0068010306,0.03577316,-0.01786077,-0.003519888,0.061428662,0.02313899,0.010737111,0.017847866,0.00889167,0.013937595,-0.01738328,-0.018054347,0.023822965,-0.019125478,-0.0082206,-0.007562436,0.0072269016,0.0065493793,-0.021990428,-0.016208908,0.0014518328,-0.020841867,0.008994911,-0.008665829,-0.0021116103,0.0019857849,0.037708938,0.029759347,-0.018467315,-0.04127077,0.01965459,0.0060331724,0.020351471,0.016931597,0.011808241,-0.011059741,-0.017976917,-0.0057202214,-0.017602667,0.019538444,0.018441504,-0.031049866,0.0005512932,0.0076011517,0.0115824,0.011614663,0.007117207,-0.028236536,0.0028568844,0.006229976,-0.022945412,0.01491839,0.005913799,-0.0037650866,0.019022238,-0.02983678,-0.005433081,-0.009369162,0.0026810514,0.033088885,-0.021822661,0.01018864,-0.026094276,-0.0019970767,-0.008498061,0.004129658,0.021758135,-0.028572071,0.022493731,-0.010562891,-0.015086156,0.04196765,-0.015705606,-0.010620964,0.059931662,0.035953835,0.004032869,0.03355347,-0.00029964218,-0.0031069224,0.012711603,0.008014117,0.008820691,-0.02994002,0.00489429,-0.011266223,0.022429205,-0.011021025,0.0005408077,0.01013702,0.030404607,0.0031601563,0.004710391,0.013847259,0.00020577715,0.038663924,-0.02919152,0.03435359,0.015537838,-0.025294155,0.0004738621,-0.006710694,-0.0032392005,-0.033063073,-0.005813784,0.022648593,-0.03135959,0.0032408135,-0.01606695,-0.031591885,-0.00013217729,-0.021629084,0.018015632,-0.040238354,0.018738324,0.0026149123,0.026455622,0.012776129,-0.003626356,0.03334699,0.0066139055,0.011775978,0.004523266,-0.0259007,-0.0024939263,0.07614057,0.011569495,0.035953835,-0.011627568,-0.0006222717,-0.026197517,-0.038767163,-0.032443624,-0.031127296,0.034327783,0.010440292,-0.028055863,-0.017189702,-0.01265353,0.029810969,0.02027404,-0.030352985,-0.0036134508,-0.003726371,-0.02032566,-0.007949592,0.020454712,0.03843163,0.038147714,0.0024406924,0.009343351,-0.022196911,-0.0060267197,0.024274645,0.024868283,-0.011014572,0.0443422,0.0072398065,-0.043800186,-0.00059000874,-0.031849988,0.010259619,0.016905786,0.015486217,-0.0020341792,0.002130968,0.008072191,-0.009433688,0.037579887,0.013705302,-0.009311088,-0.013111664,-0.02032566,-0.00631386,-0.023397094,0.053169347,-0.005003984,0.019538444,0.019861074,0.002611686,-0.012737414,-0.0071817334,-0.026507242,-0.048213758,-0.0023229327,-0.012582552,0.010775826,0.033889007,-0.021190308,0.010214451,-0.005249182,-0.07552112,0.010066041,0.00454585,0.024416603,0.024494033,0.028391398,-0.010917783,0.01606695,0.0034553623,0.020119177,-0.021448411,0.009511119,0.009472403,-0.021951713,0.0024084295,0.029423812,0.011543685,-0.0004407926,0.00842063,-0.01285356,-0.011704999,-0.006742957,-0.010111209,0.024016542,0.0119824605,0.028262347,0.0103886705,-0.023448713,0.004642639,0.0443422,-0.0010057975,-0.0056298855,0.009891821,-0.026507242,-0.0070978496,0.0027520298,-0.0055040596,-0.0036586188,0.004503908,-0.0015921767,-0.0030956303,-0.026713725,-0.0376057,-0.018222116,0.0021358074,-0.029527055,-0.009207847,-0.016854167,-0.0076334146,-0.016002424,0.005113678,0.015099062,0.027591277,-0.020893488,0.043955047,0.048910636,-0.0064396854,0.018015632,0.0008614208,-0.024803758,0.0076076044,0.029552864,-0.011117813,-0.02075153,0.018454408,0.03783799,0.0008102034,0.003397289,-0.013821449,0.01786077,-0.03494723,-0.009627265,-0.020157892,0.01282775,-0.03930918,0.035205334,-0.020119177,-0.015408786,0.013705302,-0.033785764,-0.032237142,0.013189095,0.02916571,0.02560388,-0.038276765,-0.0018857695,0.009369162,-0.005081415,-0.033269558,0.006075114,0.027978433,0.009136869,0.0041232053,-0.009524024,-0.009846653,-0.032392006,-0.017654289,0.0077431086,0.003035944,-0.0022164648,0.032443624,-0.017873676,0.0011800175,0.0046232813,-0.017073555,0.007343048,-0.02209367,-0.033011455,-0.018376978,0.0016236331,-0.034611695,0.010814542,-0.038896214,-0.0038521965,-0.02244211,0.018105969,-0.014557044,-0.008362558,0.015189398,-0.032314572,-0.01491839,0.0050007575,0.01028543,-0.0071494705,-0.008117359,-0.03347604,0.024158498,0.031566072,-0.007168828,0.008478704,0.019732023,0.027358985,-0.000683168,-0.0073495004,-0.041812785,-0.019448107,-0.012569646,0.021977523,0.0072591645,-0.007678583,-0.04854929,-0.022196911,-0.00056339183,0.020119177,0.0131697375,-0.004871706,-0.023242231,-0.0059718727,0.025939414,0.020261135,0.024597276,0.016544443,0.02351324,0.009801485,0.0103176925,0.015899183,-0.018544745,-0.003771539,-6.8710004e-05,0.011195244,0.032417815,-0.02029985,-0.0135762505,-0.016944503,0.033940624,0.028804364,0.020532142,0.030094882,0.02493281,-0.0074785524,0.004958816,-0.01230509,0.010117662,0.015512028,0.0019728795,0.010911331,-0.011653379,0.014931294,-0.018751228,-0.009246563,0.014673191,-0.0039393064,-0.051775586,-0.0055234176,-0.040496457,-0.011872767,0.030740142,-0.009194941,0.03277916,-0.033243746,-0.0022229175,-0.026997639,0.02704926,-0.02702345,-0.022080764,0.0075043626,0.013408483,-0.004510361,0.007897971,0.0058524995,0.013744018,0.024700517,-0.009801485,0.0074011213,9.28064e-05,-0.018041443,0.012053439,-0.023280947,-0.0051878826,0.0090917,-0.007736656,0.028159104,0.02533287,0.013434294,0.00894329,0.012666435,-0.0062686917,-0.037295975,-0.034121297,0.0047039385,0.026055561,0.01265353,-0.021538747,0.013485914,0.010827447,0.0074204793,0.0006121895,-0.0021600046,0.011363012,0.0042877463,-0.01178243,0.0050104368,-0.010956499,-0.005113678,0.02423593,0.00894329,0.018596366,0.0045393975,0.022764739,0.018518934,0.0059525147,0.03796704,0.020596668,0.0062751444,-0.011014572,0.003235974,-0.0043006516,0.024223024,0.0040393216,-0.026842777,0.020106273,0.019306151,-0.03505047,0.035824783,0.01925453,-0.0028149427,0.016054045,-0.021138687,-0.048988067,-0.010453196,-0.025758741,-0.020725721,-0.0138343545,-0.0129826125,-0.029475434,-0.027436415,0.017873676,-0.0199256,-0.014686096,0.00784635,-0.014002121,0.019744927,0.01033705,-0.003900591,0.012769677,-0.01783496,0.011769525,-0.009207847,0.008104454,0.015821751,-0.016054045,-0.010601606,-0.002251954,0.006981703,0.0104273865,0.029423812,0.014324751,0.028752744,-0.008749713,0.0149441995,-0.01890609,-0.01711227,0.014931294,0.050278585,-0.035902213,-0.03342442,-0.021409696,0.0054782494,0.019886885,0.004958816,-0.02926895,-0.0029456075,0.004684581,-0.035386007,-0.02244211,-0.028468829,0.009569191,-0.020157892,-0.009420782,-0.006020267,0.02784938,0.0048329905,0.01123396,0.014569949,-0.03123054,-0.0057621635,0.0006646168,-0.004820085,0.020286944,0.007562436,0.034456834,0.009369162,-0.014724812]	467
5	2	advance booking required. Menu can be customized to your needs. Payment & Pricing Q: What payment methods do you accept? A: We accept Cash, Credit/Debit Cards (Visa, Mastercard), Touch 'n Go eWallet, GrabPay, DuitNow QR, and bank transfers. Q: What is the average price per person? A: Budget RM25-50 per person for a main dish and drink. Our set meals offer the best value starting from RM28.90. Q: Do you have any ongoing promotions? A: Yes! Follow us on Instagram @bonnebouche.kluang for daily specials and seasonal promotions. We also offer a loyalty card — collect 10 stamps and get a free main course! Q: Is service charge included? A: No service charge is added. All menu prices include SST. Tips are appreciated but not expected! Other Questions Q: Are children welcome? A: Absolutely! We're family-friendly and have a kids menu available. High chairs are provided upon request. Q: Can I bring my pet? A: Pets are welcome at our outdoor patio area only. Please keep them leashed and well-behaved. Water bowls available upon request! Q: How can I provide feedback? A: We love hearing from you! Leave a Google review, message us on Instagram @bonnebouche.kluang, email hello@bonnebouchecafe.com.my, or speak directly to our manager. Q: Do you sell gift cards? A: Yes! Gift cards are available in RM50, RM100, and custom amounts. Perfect for birthdays and special occasions! Contact Us Address No. 15, Jalan Delima 2/3, Taman Kluang Utama, 86000 Kluang, Johor Phone +60 7-772 8899 WhatsApp +60 12-772 8899 Email hello@bonnebouchecafe.com.my Website www.bonnebouchecafe.com.my Facebook facebook.com/bonnebouchekluang Instagram @bonnebouche.kluang Thank you for visiting Bonne Bouche Café! We look forward to serving you again.	2	2025-12-21 23:52:58	2025-12-21 23:52:58	[-0.0427396,-0.003289029,0.020611249,-0.069028124,0.005938031,-0.045821212,-0.007004743,0.016534038,0.0086166635,0.004518711,-0.027639696,-0.06556724,0.005511346,-0.0031882839,-0.028635293,0.084009506,-0.020706067,0.018169662,-0.0029867939,0.047954634,0.044019654,0.025316633,0.0015363618,-0.013962076,-0.01594142,0.029536072,-0.034419242,-0.05807655,0.002537886,0.004717238,0.0038460898,-0.014791741,0.016937017,0.02726042,-0.0528141,-0.013203525,0.030152395,0.030413147,0.035865232,-0.028967159,-0.030484261,0.012836102,0.057602454,0.011028618,-0.008551476,0.0062343394,-0.028848637,0.017991878,-0.02560109,0.028824931,0.009653744,0.024652902,-0.04340333,0.0072417897,0.01403319,-0.020658657,-0.002967534,-0.0223891,0.06713175,0.02650187,0.053430423,-0.032309525,0.008995939,0.011259739,-0.013405016,-0.016225876,-0.03690824,0.013262787,0.012255337,0.03731122,-0.0010222658,-0.027213011,-0.029536072,-0.015728077,0.024700312,-0.005618017,0.022697262,-0.0029127167,0.013179821,-0.046816807,0.00019556389,0.0013185747,-0.0049957684,0.04631901,0.031195402,-0.023929909,-0.07888929,0.032807324,-0.050111763,0.055042345,0.032191,0.015751783,0.0057335775,-0.0032386566,0.06774807,0.0044150027,-0.02243651,0.012433122,-0.023325438,0.053620063,0.026170004,-0.06447682,0.0023615821,-0.03366069,0.043972243,-0.0038668313,0.04439893,0.003490519,-0.012646465,-0.030247213,-0.07021336,0.0013845034,-0.03534373,0.013416868,0.022958014,-0.015917715,0.029156797,-0.04859466,-0.024961064,-0.029986462,-0.0071528973,0.037358627,-0.023100244,-0.034679994,-0.0653776,-0.027141897,-0.04546564,0.013215378,-0.0067202863,-0.07305793,0.0019274895,-0.039563168,0.0127886925,-0.05200814,-0.012682022,0.0035705224,-1.8611903e-05,0.030365737,-0.029678302,-0.040179487,0.05044363,-0.009072979,-0.01600068,-0.007887743,-0.047480542,-0.032380637,-0.05712836,-0.025909252,-0.041601773,0.052671872,-0.0049039125,0.02011345,-0.014092452,-0.08239758,-0.036078572,-0.02937014,0.012954626,0.0588351,-0.06732138,0.029346434,-0.0025689984,0.025482567,0.018940065,-0.03524891,-0.00078670017,0.010833054,-0.026075184,0.0008763336,-0.010655269,-0.01936675,0.044541158,0.02972571,0.03325771,0.009298174,-0.039966147,0.016261434,0.035628185,-0.04254996,0.020433463,0.007941079,0.04098545,0.04686422,0.04198105,0.007472911,-0.009807825,0.041459545,-0.0168422,-0.04465968,-0.022045383,0.036600076,-0.001811929,-0.015016936,-0.01403319,-0.021843893,0.01669997,-0.028232314,0.041672885,-0.0072654947,-0.028279724,0.056274988,-0.005220963,-0.012059773,0.037832722,-0.04179141,0.069597036,-0.0059795137,0.003460888,-0.029749416,0.022341693,-0.00651287,0.055990532,0.044493746,0.00068558473,0.03057908,-0.021251276,-0.008314428,-0.03788013,0.011550122,-0.00050002127,0.005345413,0.001577845,0.0070640044,0.03408738,-0.0041957344,0.007212159,0.02771081,0.016273286,0.0025793691,0.01825263,-0.05698613,-0.005182443,0.03252287,-0.018880805,0.001151901,-0.026810031,0.02202168,-0.03707417,-0.010779718,-0.0001631551,-0.029844234,0.028469361,0.045157477,-0.02977312,0.012148665,0.03550966,0.0015674742,-0.0071825283,-0.04048765,0.013085002,-0.015479178,0.023811385,-0.04254996,0.030910946,-0.060067743,0.03465629,-0.024321036,-0.029488664,-0.015775487,0.029204207,-0.0256485,0.023752123,-0.0041690664,0.026644098,-0.0048742816,0.0054313424,-0.016913313,0.02986794,0.02077718,-0.0052120737,0.026620394,-0.04345074,-0.05475789,-0.015728077,0.047456834,-0.010892316,-0.009973758,-0.0035053345,-0.027971562,0.022294283,0.010086356,-0.043189988,-0.018548938,0.013713176,-0.056843903,-0.01327464,-0.010868611,0.06964445,-0.011170846,-0.0030460556,0.06281749,-0.0060624806,-0.0027956746,-0.001912674,-0.0072358637,0.019260079,0.013890962,0.007378092,-0.019508978,0.041364726,0.012314599,-0.04188623,0.05452084,-0.031290222,0.032831028,0.0061276685,0.023645451,0.00083559117,0.054331202,0.010222658,0.01679479,-0.02232984,0.022140203,0.029393844,-0.0683644,0.022649854,0.015550292,0.0482865,0.017588897,-0.010471557,-0.008818153,0.07964784,0.011976806,0.0048061307,0.029109389,-0.014258385,-0.03750086,0.050917726,0.0013052408,-0.031574678,-0.014993231,0.019023033,-0.04228921,0.002595666,-0.002794193,-0.023064686,0.032807324,0.018714871,0.020706067,0.03242805,0.02887234,-0.005078735,-0.03641044,-0.01363021,-0.03958687,0.015384359,-0.013914667,0.058123957,0.038686093,0.04501525,0.046556056,-0.043995947,0.03252287,0.0026697433,0.027473763,0.02006604,-0.011295296,0.022306135,0.035983756,-0.025411453,0.012480532,-0.018845247,-0.028682703,-0.005049104,-0.011200477,0.005010584,0.014898412,-0.04108027,-0.022958014,-0.049448032,-0.00078003324,0.0069691855,0.042573664,-0.0086285155,-0.03484593,-0.046484943,0.010216732,0.025672205,0.04138843,0.0020578655,-0.0066669504,0.04560787,-0.03927871,0.036031164,-0.0111589935,0.021606846,-0.020137154,0.03252287,-0.011336779,0.050301403,-0.03053167,-0.004222402,0.007941079,0.0211209,-0.02856418,0.01986455,0.024818836,0.030745013,0.0076151392,-0.0052446676,-0.035533365,0.026975963,0.012859807,-0.011976806,-0.015467325,0.016960723,0.00031408746,-0.03415849,-0.017671864,-0.029583482,0.0015822896,-0.029488664,-0.028706407,-0.017624455,0.013535392,-0.006613615,-0.027331535,0.009221134,0.035438545,0.016237728,0.023040982,0.001727481,-0.016154762,-0.04631901,0.0012644983,-0.045750096,0.02690485,0.0051320703,-0.029085683,0.00970708,-0.0055557922,-0.02378768,-0.022460217,-0.059925515,0.006542501,-0.023906203,0.0076981056,-0.011597531,0.0135828005,-0.020765329,-0.013487982,-0.009766342,0.00872926,-0.0038846098,-0.020350497,-0.031906545,0.03887573,0.024961064,0.035936344,0.046911627,-0.017944468,-0.055706076,-0.008847784,0.013310197,-0.0015000639,-0.046887923,0.021796484,0.027331535,-0.0066313935,-0.013784291,-0.045347117,0.023064686,-0.006850662,-0.011976806,-0.03354217,0.004459449,0.026312232,-0.025529977,0.018679313,0.014305795,-0.032451753,-0.0010467112,-0.013902814,0.009541147,-0.024605492,-0.020220121,-0.01322723,-0.025885547,0.008990012,-0.025885547,0.049163576,-0.031195402,0.005594312,-0.053525243,-0.054094154,0.024510674,-0.051012542,0.06442941,0.031290222,-0.061347798,-0.0012304228,-0.05613276,0.03788013,0.042312913,-0.010370812,-0.03676601,-0.01775483,0.019544536,-0.0048090937,0.0041038785,0.0068921456,-0.029251616,-0.021986121,0.00784626,0.020848295,0.034016263,-0.011787169,0.0055291243,-0.0041423985,-0.03349476,0.0024208438,-0.06623097,-0.032214705,0.008788522,0.028753817,-0.0062224874,0.014187271,-0.019544536,0.022602445,-0.04155436,0.017494079,-0.009475959,0.028042676,0.018442268,-0.06371827,-0.008154421,0.023218766,-0.0018534123,-0.083867274,0.0033690324,-0.047693882,0.020006778,-0.006572132,0.027805628,0.0026178893,-0.037334923,-0.023906203,0.003454962,-0.0066017625,-0.009950054,-0.024012875,-0.002108238,0.016818494,0.012634613,-0.0075855083,-0.0045305635,-0.022341693,0.019331194,-0.041933637,-0.009381141,-0.0031675424,0.0063173063,0.024321036,-0.012966478,0.010187101,0.0064950916,-0.008782596,0.012492384,0.0011407894,0.021263128,0.0021200904,-0.00051705906,0.004829835,0.0055587552,0.012480532,0.008788522,-0.013013887,0.00206231,0.021298684,-0.011247886,-0.006092111,-0.029749416,0.03524891,0.018596347,-0.015562144,-0.0065899105,0.011526417,0.00065225,-0.007075857,-0.01197088,-0.047480542,-0.04902135,-0.027189307,-0.007917374,0.014791741,-0.0076388437,0.043261103,0.042976644,0.032214705,0.018548938,0.046508648,0.023728417,-0.022756524,-0.0057987655,-0.0068388097,-0.010044872,0.009167798,-0.045157477,0.033328827,0.016984427,-0.025435157,0.0002859381,0.036244508,-0.03133763,0.014376909,-0.013037592,-0.003422368,0.01363021,-0.0067499173,0.025103291,-0.022709114,0.030697605,0.023254324,0.004252033,0.023396552,-0.026810031,0.010187101,-0.018371154,-0.0020504578,-0.0042312914,-0.018560791,0.0127768405,0.006483239,0.0041364725,0.0135709485,0.018311892,0.02016086,0.008521845,-0.02972571,-0.015348802,0.00824924,0.012397565,0.018916361,0.03430072,-0.011538269,0.023870647,0.018963771,0.0316932,-0.02202168,0.00055187533,-0.03555707,-0.022187611,0.03278362,0.04430411,-0.026667802,-0.014068747,0.029038275,-0.0048120567,-0.0028771595,0.0020045298,-0.03093465,0.0075499513,-0.016273286,-0.012385713,-0.03434813,0.018975623,0.0462716,-0.022235021,0.0050253994,0.02212835,0.024463264,-0.029796824,0.024558082,-0.015502882,6.750288e-05,0.014542841,0.045038957,-0.027023373,3.287177e-05,0.0015763635,-0.036434144,0.050917726,0.023171358,0.0538097,-0.008794448,-0.0070284475,9.954128e-05,-0.0025334412,-0.03394515,0.030958356,0.01217237,-0.03560448,-0.022602445,0.012456827,0.015704373,-0.0046253824,0.0026297416,-0.0022593555,-0.0010837498,0.016735528,0.0135590965,0.0026475203,-0.006216561,0.04636642,-0.021535732,0.025624795,0.043592967,-0.016071796,0.036884535,-0.0064654606,-0.09112092,0.029061979,-0.042170685,0.020172711,-0.0008607774,0.0028771595,0.023692861,0.016605152,-0.002875678,0.0057276515,-0.017446669,0.0017689642,0.015384359,-0.000122783,0.05878769,-0.0016148835,0.034134787,-0.050965134,-0.023657303,0.014009486,0.0119590275,-0.017612603,0.021547584,0.014104305,-0.018311892,0.005111329,0.04451745,-0.020255677,0.022152055,0.031053174,0.035888936,0.008077381,0.017731126,0.01267017,-0.008184052,-0.05523198,0.03700306,-0.020883853,0.021014228,-0.027165601,-0.030816127,-0.0024667718,-0.007247716,-0.004518711,0.002611963,-0.0054994933,-0.008800375,0.005022436,-0.0064950916,-0.049732488,0.03022351,0.0044031506,0.008456657,0.025529977,-0.0029808676,-0.031669497,-0.037548266,0.02419066,0.009967832,0.013250935,0.038354225,0.008231462,0.042478845,-0.0051587382,-0.02771081,0.0024504748,-0.0213698,-0.0015526587,-0.020658657,-0.02347952,-0.01189384,0.010607859,-0.042881828,0.0382357,0.022946162,0.021749074,-0.010027094,-0.008984086,0.024558082,0.018465972,-0.020231973,0.032191,0.009422624,0.04245514,-0.032404345,-0.015953273,-0.010098208,0.0127531355,-0.0025423304,-0.03299696,0.014092452,-0.012551646,-0.041909933,0.028848637,-0.025008472,-0.004160177,0.024961064,-0.02006604,-0.021298684,0.021263128,0.015384359,-0.021606846,-0.027568582,0.01579919,-0.027094487,0.019639354,0.023835089,-0.0009970795,0.040274307,0.025767023,-0.015656963,0.009641892,-0.037927542,0.0003148282,0.02479513,0.028256018,0.02107349,0.029583482,-0.01760075,-0.02650187,-0.016771086,0.07538099,0.013061297,-0.003549781,0.030010168,-0.032119885,0.0040772106,-0.042976644,-7.8799654e-05,-0.006412125,-0.03425331,-0.0028712335,-0.02595666,-0.020872,-0.02147647,-0.027118193,0.020540135,-0.048499845,0.006175078,-0.009333731,0.02690485,0.015016936,0.0046935333,-0.01342872,-0.011236034,-0.0144480225,0.021701666,0.0038816468,-0.011763464,-0.022566887,0.035272613,-0.004157214,-0.03998985,0.017517783,0.021251276,0.016332548,-0.001743778,-0.011793095,0.008800375,0.034727406,-0.010998987,-0.059119556,-0.026264822,-0.0030460556,-0.031503566,0.022116497,-0.0050550303,0.0071232663,-0.0014615437,0.0025838139,0.027473763,-0.005040215,-0.002475661,-0.029654596,-0.0008792967,0.024652902,0.03200136,0.0021630551,0.011401967,-0.020587543,-0.0412462,0.04394854,-0.009754489,0.014590251,-0.02243651,0.011804948,0.034371834,-0.03560448,0.016581448,-0.0094522545,0.002736413,-0.01221978,0.03354217,0.0073010516,-0.031053174,-0.009078905,0.029630892,-0.00030056835,0.0007748478,0.004989842,0.0094522545,0.0094641065,0.035367433,-0.019734174,-0.008782596,0.01880969,-0.003952761,-0.04506266,0.0040327646,0.02982053,0.009410772,0.03385033,-0.030650195,-0.00088744523,-0.010062651,-0.0021674996,-0.03133763,-0.013689472,0.023669157,-0.020326791,-0.0067558433,0.0020252715,0.004388335,-0.038946845,0.007680327,-0.029536072,-0.012871659,0.03249916,-0.017719273,0.00731883,-0.011822726,0.038140886,0.011976806,-0.008024045,-0.0040060966,0.04591603,0.0050550303,0.016261434,0.0059202523,0.0069573335,0.020812739,-0.014779889,0.023929909,-0.010696752,-0.001414875,0.0397291,0.03259398,0.03309178,0.027947856,0.021701666,-0.033518463,0.04520489,-0.008450731,-0.022223169,-0.036291916,-0.023550633,-0.029986462,-0.0076981056,0.008806301,-0.012196075,0.002056384,-0.018963771,0.044090766,0.0102996975,-0.0052772616,0.0055498662,0.020599395,0.031645793,0.011372336,0.0031112437,0.030721309,0.016913313,0.013594653,-0.038520157,-0.007449206,-0.010862685,0.010631564,-0.011976806,-0.004755758,0.024001023,-0.009108536,-0.019141557,0.025411453,0.0072003067,-0.0051409598,-0.015621406,0.036552668,0.044825613,0.045987144,-0.0019097109,-0.01108788,0.00671436,0.015147312,-0.0023334327,-0.0073603136,0.0022800972,-0.011455303,-0.021393504,-0.006909924,0.045844916,-0.030792423,0.0070640044,-0.022744672,0.012302746,-0.05456825,-0.0061572995,-0.01003302,0.057270586,-0.0072951256,-0.044754498,-0.07400612,0.01845412,0.0094937375,0.013167968,0.016676266,-0.019591946,-0.024724016,0.0003633488,-0.030910946,-0.029939054,-0.016688118,0.0069632595,0.016427366,0.0010481928,0.025553681,-0.019378603,0.004856503,0.0553268,0.013855405,0.03273621,0.00028667887,-0.010050799,0.01750593,0.015656963,-0.016605152,0.0040742476,0.003786828,-0.0136065055,0.0037483077,0.026335936,0.011467155,-0.022578739,-0.0014882116,0.011372336,-0.003932019,0.026525574,-0.015573997,-0.009914496,0.006678803,0.016664414,0.03501186,-0.0014696922,-0.035391137,0.02036235,-0.007751441,0.0051705907,0.0070225215,-0.017126655,-0.016534038,0.010104134,-0.0034460728,-0.027141897,0.008018119,0.027402649,-0.026264822,0.00043483335,0.021903155,-0.012338303,0.0035142237,-0.013393163,-0.02595666,-0.0051646642,0.0075855083,-0.013464278,0.032617684,-0.008806301,0.0010000425,0.01604809,-0.020089744,-0.009861161,-0.008563328,0.001675627,0.02690485,-0.0026815957,0.026027774,-0.007384018,0.0018948956,-0.010975283,0.010056725,0.026833735,-0.015028789,0.026762621,-0.022163907,-0.0071469713,0.037192695,-0.015739929,-0.018145958,0.027497467,0.054283794,0.014530989,0.031076878,0.031147994,-0.004761684,0.015562144,-0.0014933969,0.0067617693,-0.015822897,0.013179821,-0.0021200904,0.023657303,-0.0012807953,0.029891644,0.0003290881,0.049448032,-0.009238912,0.011437524,0.008515919,-0.0151947215,0.03882832,-0.03863868,0.022827638,0.011342705,-0.0049098385,0.006341011,-0.00072966074,0.0016282175,-0.03541484,-0.019023033,0.010518966,-0.01624958,-0.0065602795,-0.009760416,-0.0301761,0.0062224874,-0.027331535,0.023562485,-0.046745695,-0.006572132,0.004640198,0.031716906,0.009671523,-0.008527771,0.033968855,-0.0048150197,0.036291916,0.019603798,-0.027355239,-0.014839151,0.07557063,0.012018289,0.028137494,-0.013096854,-0.020350497,-0.015099903,-0.01549103,-0.01549103,-0.007306978,0.023254324,0.0027541914,-0.009564851,-0.0152421305,-0.011484934,0.0397291,0.016617004,-0.017019983,-0.003582375,0.019236375,-0.0042046234,0.0046313084,0.025767023,0.027544877,0.028682703,0.0032356933,0.018548938,-0.023716565,-0.0043320362,-0.0006981779,0.026810031,-0.01262276,0.033802923,0.0034490358,-0.03532002,-0.018181516,-0.026383346,-0.006086185,0.016676266,0.0045009325,-0.00020611989,0.0066017625,0.005286151,0.010258215,0.041815113,0.037737902,0.0023156542,0.0016889608,-0.024866244,-0.019058589,-0.026217412,0.049353212,-0.025909252,0.009730785,0.019295637,0.010821202,0.0002326025,-0.013523539,-0.033779215,-0.0377142,0.007947005,-0.0019586019,0.010507114,0.042265505,-0.022827638,0.022400955,-0.011384188,-0.072536424,0.009997463,-0.011324927,0.032214705,0.019983074,0.039847624,-0.0072003067,0.014851003,0.012065699,-0.010198953,-0.01363021,0.010459704,0.003422368,-0.022638,-0.0030727235,0.03223841,0.020338643,-0.0050313254,0.017031837,-0.06618356,-0.0010452297,-0.010951578,-0.009244838,0.027426353,0.008907046,0.024012875,0.0071469713,-0.038449045,0.023372848,0.051771093,-0.01508805,0.0138317,0.008883341,-0.025411453,-0.02273282,-0.01051304,-0.0009970795,-0.015514735,0.0029023457,0.006080259,0.009049274,-0.028730113,-0.03740604,-0.030507967,0.0027127082,-0.013049445,-0.006554353,-0.016083648,0.004243144,-0.010607859,-0.0032653243,0.017897058,0.03581782,-0.0143650565,0.054378614,0.040866926,0.001711184,0.00023815829,-0.007105488,-0.028587885,0.040961746,0.040345423,-0.01463766,-0.012539794,0.009926349,0.04842873,0.005081698,0.0076921796,-0.003724603,0.01513546,-0.04622419,-0.026193708,-0.02228243,0.019983074,-0.015016936,0.03932612,-0.033802923,-0.009315953,-0.0016637746,-0.009114462,-0.026170004,-0.0028327133,0.0281612,0.015656963,0.0042698113,0.003783865,0.022673558,-0.014471727,-0.028398247,0.011182698,0.019781584,-0.008782596,0.0061691515,-0.006986964,0.015408063,-0.03797495,-0.024771426,0.0066313935,-0.00744328,-0.011455303,0.024581788,-0.016723676,0.0028416025,0.009541147,-0.019023033,0.010495262,-0.0077692196,0.0057276515,-0.022412807,0.016830346,-0.036078572,0.01790891,-0.01865561,-0.011704202,-0.018228924,-0.0023675081,-0.009843382,-0.014851003,0.0043320362,-0.028848637,-0.025814433,-0.0011726426,0.0168422,-0.0012770914,-0.00040483207,-0.02016086,0.030365737,0.034419242,-0.0029156797,-0.020386053,0.024119547,0.04506266,-0.01569252,0.02404843,-0.01805114,-0.03524891,0.003223841,0.021654256,0.031076878,0.00060780364,-0.036339324,-0.034277014,-0.025269225,0.04148325,0.011520491,0.014341352,-0.027402649,-0.012907216,0.017885206,0.014495432,0.015040641,0.037192695,0.011550122,0.010507114,0.022590593,0.0009452254,-0.01815781,0.013191673,0.032807324,0.018797837,0.04354556,0.008071455,0.0011504194,-0.027094487,0.042218093,0.010957504,0.02806638,0.02318321,0.039942443,0.0106849,-0.021203866,-0.009600409,0.015929567,0.013203525,0.0071825283,0.018181516,-0.025980366,0.006975112,-0.009932275,0.0025023287,0.016534038,-0.0017615565,-0.063528635,-0.005383933,-0.008705556,-0.0060002557,0.041815113,0.008332207,0.02293431,-0.030910946,0.010803423,-0.009221134,0.009760416,-0.033518463,-0.04703015,0.0061276685,-0.0144480225,-0.0021008302,0.006059517,-0.0014726553,0.026975963,0.011384188,0.0067262123,0.01679479,0.004610567,0.021097194,0.004240181,-0.0022400955,0.0024771425,0.009138167,-0.015965125,0.03641044,0.03031833,0.011206403,0.04833391,0.0094937375,0.0030816128,-0.04264478,-0.0377142,-0.0025023287,0.029512368,0.013594653,-0.025719615,-0.0023171357,0.012385713,-0.0028904935,0.0065247226,-0.013239082,0.0086107375,0.028659,0.0047468687,0.014874708,-0.010667121,0.01051304,0.02006604,-0.0021600921,0.027213011,-0.00031686533,0.016854052,0.012196075,0.021417208,0.042123277,0.010833054,0.022958014,-0.018288186,-0.013073149,0.007715884,0.02982053,-0.0012704245,-0.02273282,0.029583482,0.024534378,-0.029512368,0.02368101,0.034537766,-0.016202172,0.017245179,-0.033826627,-0.048642073,-0.0027304867,-0.027284125,-0.015905863,-0.008533697,-0.016439218,-0.03501186,0.010459704,0.014993231,-0.042431436,-0.007911448,0.017517783,-0.013938371,-0.0152302785,0.017790386,-0.0052357786,0.0014178382,-0.03636303,0.006743991,0.006678803,-0.0054372684,0.009280396,-0.018785985,0.0068625147,0.018620051,0.00064076803,0.015656963,0.027829334,0.009067053,0.01038859,-0.0013126485,0.01387911,-0.019698616,-0.023669157,-0.005911363,0.031550974,-0.049732488,-0.03731122,-0.010430074,0.020883853,0.028137494,0.017742978,-0.041815113,-0.01443617,0.018951919,-0.05466307,-0.020457167,-0.016368104,-0.004160177,-0.02046902,0.0018948956,0.009630039,0.028137494,-0.0045276005,0.011822726,0.016557742,-0.018228924,-0.004112768,0.005446158,-0.0060980376,0.007745515,0.034585178,0.015182869,0.001376355,-0.017731126]	433
6	3	# Bonne Bouche Café — Menu & Cuisine Guide *"A Good Taste in Every Bite"* 📍 No. 15, Jalan Delima 2/3, Taman Kluang Utama, 86000 Kluang, Johor 📞 +60 7-772 8899 | 📱 +60 12-772 8899 📸 @bonnebouche.kluang --- ## Our Culinary Philosophy At Bonne Bouche Café, we believe great food brings people together. Our kitchen blends Western culinary techniques with the vibrant flavours of Malaysia, creating dishes that are both familiar and excitingly new. Every ingredient is carefully selected, and every dish is prepared with passion.	0	2025-12-21 23:53:05	2025-12-21 23:53:05	[-0.029081829,0.009897597,-0.015074118,-0.04490021,0.025193883,-0.040923398,0.009986464,0.038635064,0.0030770306,-0.00527372,-0.022905549,-0.06558408,0.0014913046,0.005070991,-0.038923882,0.07949181,-0.032281052,0.006176278,0.01617385,0.054120194,0.038635064,0.0119526535,-0.0076259263,0.014785299,0.02899296,0.028881876,-0.048565987,-0.013119037,-0.01415212,0.02450516,-0.009908705,-0.025616003,0.033325244,0.04287848,-0.032125533,-0.038812798,0.04776618,0.02788212,0.007220469,-0.021528106,-0.03823516,0.0070094094,0.05203181,0.04825495,0.002979832,-0.0056153033,-0.061940517,0.025105016,-0.038923882,0.032725386,0.022816682,0.028215371,-0.013985493,0.03117021,0.03299199,-0.017684596,-0.0072871195,0.006620615,0.076959096,0.061451748,0.042745177,-0.018673245,0.013841084,0.012197038,-0.014940817,-0.03263652,-0.013141254,0.0011205613,0.033591844,0.044367004,-0.017595727,0.007698131,-0.028059853,0.0046599796,0.014074361,-0.046610907,0.0015482352,-0.01421877,0.015185202,-0.056963947,-0.037013236,0.026060339,-0.0131745795,0.045855533,0.0032825363,-0.026060339,-0.051320873,0.047099676,-0.045544498,0.055630937,0.05034333,-0.0001129934,0.027415566,-0.007553722,0.055497635,0.025793737,-0.021716949,0.031103559,-0.013085712,0.033436324,0.021039337,-0.048299383,0.015240744,-0.02381644,0.042834044,-0.023083284,0.04838825,-0.011125077,-0.0039545954,-0.029370647,-0.060029868,-0.0026104774,-0.014574239,0.033925097,0.022905549,-0.007992504,0.053275954,-0.04041241,-0.0018898189,-0.022350129,0.005209846,0.04327838,-0.027748818,-0.043411683,-0.05540877,-0.013252338,-0.029615032,0.014141011,0.0031186873,-0.05883016,0.0048599313,-0.038568415,0.0001236679,-0.062162686,0.00071440986,0.02045059,-0.0041434383,0.010864029,-0.018651027,-0.03845733,0.04418927,-0.036679983,-0.00781477,-0.0040629026,-0.026949013,-0.057541586,-0.08651233,-0.021194855,0.007848094,0.045077946,-0.0149186,0.016918115,-0.03874615,-0.06660605,-0.029592816,-0.030481488,0.018106716,0.05380916,-0.059407797,0.0061040735,0.012685809,0.030237103,0.0142520955,-0.029859416,0.0025660438,0.034280565,-0.02928178,0.02233902,-0.022650056,-0.035413623,0.017306909,0.044322573,0.035191454,0.025616003,-0.005021003,0.054386795,0.021605866,-0.05447566,0.0027035102,-0.01141945,0.023305453,0.040034723,0.034458302,0.029726116,-0.0018912075,0.02941508,-0.004135107,-0.0056736222,-0.00037560324,0.02186136,-0.030503705,-0.02023953,-0.0023841434,-0.0016787591,0.01639602,-0.011052872,0.030836957,0.016118309,-0.009930922,0.050965402,-0.030281536,-0.0020064572,0.043611635,-0.04125665,0.037235405,0.0034297227,0.014951926,-0.012685809,-0.0032964218,0.0044405884,0.030459272,0.037146535,0.0077647814,0.031570114,-0.016695946,-0.014674215,-0.016940331,0.015596214,0.0023744234,0.005012672,-0.0032742051,-0.023616489,0.038479548,-0.00815913,-0.010036452,0.027126746,-0.011030655,-0.01836221,0.009331068,-0.03501372,0.013096821,-0.00035321285,-0.021739166,-0.009214429,-0.022994418,0.019795194,-0.012408098,-0.02450516,-0.00033099603,-0.017751245,-0.0012753848,0.050121166,-0.014685323,0.033880662,0.03914605,0.01708474,0.0060540857,-0.018751003,-0.02374979,-0.008675671,0.022883333,-0.00032561537,-0.0034019519,-0.031992234,0.038190726,-0.0026896247,-0.057052813,-0.02857084,0.018240016,-0.007509288,0.0034519397,0.026415808,0.039457086,-0.0020800505,-0.020928252,-0.00955879,0.010358596,-0.023660922,0.004618323,-0.009292188,-0.03930157,-0.049276926,-0.00079772295,0.048565987,-0.007620372,-0.036324512,-0.011641618,-0.019839628,0.024616245,-0.005448677,-0.0437005,-0.034013964,-0.014052143,-0.057186116,-0.005662514,-0.04230084,0.043789368,-0.040523496,-0.001827334,0.058163658,-0.00022234186,-0.01589614,-0.011441667,-0.003754644,-0.00073593244,0.022039093,0.02570487,-0.06051864,0.02668241,0.014718649,0.025527135,0.049143624,0.0029437297,0.0060707484,0.012552508,0.019728543,-0.017973414,0.03621343,0.017895656,0.014385397,-0.04176764,0.006998301,0.027748818,-0.071982525,0.060563073,0.007492625,0.05167634,0.016618187,-0.013385639,0.0011406953,0.042678528,0.0137522165,0.012852435,0.010147536,-0.01877322,-0.039679255,0.040878963,0.020039579,-0.04994343,-0.010436355,0.020372832,-0.03214775,-0.015685081,0.007542613,-0.0410567,0.011563859,0.007620372,0.019717434,0.029703898,0.017673487,0.008431287,-0.045544498,0.0052154004,-0.035569143,0.0415899,-0.004801612,0.06011874,0.034924854,0.06331796,0.032747604,-0.05723055,0.021472564,-0.011674943,0.020917144,0.010003127,-0.018473292,-0.022794466,0.077625595,-0.027393349,0.017806787,-0.03852398,-0.05847469,0.0153296115,0.022883333,0.023416536,-0.010119765,-0.03283647,-0.034658253,-0.043433897,-0.0014246542,-0.020572783,0.059985436,-0.01926199,-0.010119765,-0.035524707,0.022750031,0.010752945,0.011319474,-0.008914502,-0.0039212704,0.0386795,-0.023460971,0.006204049,-0.022450104,0.041989803,-0.014074361,0.05576424,-0.032614302,0.048921455,-0.032303266,-0.0017579065,0.0052181776,0.046477605,-0.012585833,0.04812165,0.024993932,0.035035938,-0.025016148,0.01116951,-0.016773704,0.047677312,-0.019028714,-0.017262476,-0.014041035,-0.00055160216,0.023149936,-0.020495024,-0.005693062,-0.023016633,0.011352799,-0.030703656,-0.018051174,-0.012485857,0.043411683,-0.018028956,-0.0052959365,0.0047877263,0.02710453,0.0054625627,0.01947305,-0.02570487,0.011752702,-0.040812314,0.01618496,-0.01127504,0.02626029,0.027748818,-0.012974627,0.028948527,0.0035824636,-0.023905307,-0.016473778,-0.072737895,0.023460971,-0.0069372044,0.024549594,-0.027171182,-0.016751489,-0.019395292,-0.018228907,-0.020139555,0.009747634,-0.011297257,-0.016662622,-0.035324756,0.051365305,0.03368071,0.022505647,0.011286149,-0.0504322,-0.051942945,0.0027173958,0.0030686993,0.010158645,-0.02101712,0.0550533,-0.019739652,-0.025349401,0.0055153277,-0.051809642,0.007642589,-0.0021203186,-0.028481973,-0.027615517,0.010897354,0.031325728,-0.029303996,0.004996009,0.025260534,-0.04223419,-0.005448677,-0.005579201,0.013019062,-0.033125293,-0.027704384,-0.02857084,0.0139632765,-0.0010337768,0.0072871195,0.067005955,-0.017284691,-0.024549594,-0.05443123,-0.04138995,0.004393378,-0.040990047,0.054964434,-0.005265388,-0.015662864,-0.035258107,-0.029481731,0.014540914,0.023616489,-0.0076259263,-0.057630453,-0.008770093,0.013474506,-0.027060097,0.034569383,0.016862573,0.005412575,0.022672273,-0.004990455,0.032925338,0.037368704,0.015496237,9.627654e-07,0.02143924,-0.027060097,-0.0009615721,-0.044566955,-0.023261018,-0.0054625627,-0.00714271,0.0046322085,0.011630509,-0.01806228,0.029059611,-0.03850176,0.019795194,-0.008247998,0.012585833,0.0010691849,-0.043456115,-0.0012705248,0.0122414725,0.032725386,-0.050210033,0.008947828,-0.042745177,0.06687265,-0.004423926,0.037746392,-0.00021262199,-0.017740138,-0.01442983,0.008847852,-0.006431772,-0.015229636,-0.01785122,-0.030126018,0.017329127,0.008142468,0.00020342284,-0.031547897,-0.0410567,0.014163228,-0.053187087,0.00024976576,0.024105258,-0.010764053,0.009225538,-0.009336622,0.016096093,-0.022394562,-0.0036130117,0.011375016,-0.016207175,0.025882605,0.00042593825,-0.03039262,-0.0016065544,-0.015985008,0.00955879,0.036102347,-0.023772007,-0.006509531,0.009719863,0.0043572756,0.0032325485,-0.032236617,0.0017870661,0.033991747,0.0010087829,-0.00514875,0.011652727,-0.00033689736,-0.0037435356,0.00040268002,-0.04994343,-0.022861116,-0.0045905523,-0.01981741,-0.0035630239,0.0055625383,0.030881392,0.029792767,0.009219984,0.03767974,0.04490021,0.021605866,-0.024282994,-0.008770093,-0.022816682,0.008136913,0.001119867,-0.02374979,0.0106640775,0.012208147,-0.011397233,0.014907491,0.047677312,-0.014529806,-0.0070094094,0.0066428315,0.013874409,-0.014363179,-0.0119526535,0.02857084,-0.026793495,0.0094032725,0.022461213,0.022949984,0.01345229,-0.02583817,0.022861116,0.0032547654,0.0107029565,-0.016962549,-0.014685323,-0.0007782833,0.0044072634,0.0130301695,-0.0097309705,0.0018800991,0.014074361,0.00095462933,-0.02156143,0.00840907,-0.013685566,0.037279837,0.013641132,0.024216343,-0.00021887047,0.02207242,0.03439165,0.03488042,-0.027704384,0.0074370834,-0.055231035,-0.008559033,0.017018091,0.044322573,-0.021539215,-0.0073426617,0.0024924504,0.011180619,-0.0070427344,0.0018759334,-0.032303266,0.0086479,0.004615546,-0.02381644,-0.023727572,-0.00018016458,0.065850675,-0.0095865615,0.016551537,0.022883333,0.0229722,0.007781444,0.022516755,-0.0113472445,-0.0018342768,0.023438754,0.03628008,-0.02185025,-0.008947828,0.0122414725,-0.021839142,0.047810614,0.0047544013,0.047544014,-0.012041521,0.014607565,0.0082202265,0.015162985,-0.012074846,0.034702685,-0.009925368,-0.03005937,-0.01604055,-0.017973414,0.034191698,-0.0061485074,6.192073e-05,-0.006626169,0.004662757,0.016918115,-0.013074603,0.012974627,0.01933975,0.041145567,-0.03845733,0.026460242,0.022650056,0.004423926,0.026993446,0.0073648784,-0.075270616,0.03103691,-0.03781304,-0.010147536,0.034902636,0.012585833,0.019106472,0.031081343,-0.008997816,0.020339506,-0.008203564,0.0021925233,0.025393834,-0.01960635,0.048565987,0.016540429,0.014940817,-0.055853106,-0.012796893,0.0007525951,0.010369704,-0.00714271,0.034658253,0.03454717,-0.0273267,0.017473536,0.05092097,-0.009014478,-0.0092422,0.02808207,0.03536919,-0.0036296742,0.04656647,0.015851706,-0.036457814,-0.061451748,0.044078186,0.00372965,0.010886245,-0.016518211,-0.041278865,-0.001985629,-0.0013281498,-0.021605866,-0.0049265814,0.009908705,-0.0008317425,0.0047016363,-0.03734649,-0.061585046,0.008070263,0.00038462883,0.0068816626,0.03761309,-0.0005196655,-0.037302054,-0.043611635,-0.004321173,-0.00281876,0.025504919,0.015796164,-0.0045905523,0.050210033,-0.0158406,0.00794807,-0.005290382,-0.022949984,0.016196068,-0.0049210275,0.012085955,-0.0009324125,-0.0028743022,-0.03236992,0.030836957,0.020395048,0.009803175,-0.006709482,-0.01211928,0.043678284,0.0067316988,-0.026104772,0.03936822,-0.00028847164,0.031392377,-0.0316812,-0.01695144,-0.014274312,0.022561189,-0.004290625,-0.024616245,0.0056153033,0.012985736,-0.0074093123,0.020250639,-0.014452047,-0.011552751,0.035413623,-0.010969559,-0.03676885,0.011358353,-0.0048710397,-0.0068261204,-0.02654911,0.022283478,-0.022994418,0.023994174,0.018451076,-0.016229393,0.046744205,0.04096783,-0.008275769,-0.017695704,-0.027571084,0.015607322,0.015951682,0.023927525,-0.010858474,0.02528275,-0.02857084,-0.014318746,-0.020183988,0.033080857,0.011225052,0.00033533524,0.015207419,-0.036902152,-0.0034158374,-0.021928009,-0.009636549,-0.012941303,-0.047144108,0.0021480895,-0.023172151,-0.02388309,-0.0048404913,-0.043900453,0.017229151,-0.034036182,0.019850736,-0.01464089,-0.0054347916,-0.0010698792,0.016584862,-0.015585105,0.025482701,-0.01849551,0.017840113,0.009514357,-0.043056212,-0.03436943,0.04043463,-0.029792767,-0.03452495,0.009075575,0.035124805,0.03201445,0.027082313,-0.024060825,0.025260534,0.033436324,-0.028126504,-0.027970986,-0.0074093123,-0.009525465,-0.013474506,0.0003082585,0.011652727,0.005629189,-0.0050043403,-0.0017287469,0.034302782,-0.008081371,-0.010119765,-0.025060583,-0.0038490654,0.024816196,0.036679983,0.007587047,-0.01103621,-0.02661576,-0.049054757,0.0641622,-0.021328155,0.011058426,-0.027815469,0.007842541,0.052698318,-0.03374736,0.01794009,0.010714065,-0.00798695,0.0054875566,-0.00584858,-0.002431354,-0.009164441,-0.0075592757,0.015029685,0.008392407,0.0077592274,0.038790584,-0.024549594,-0.0056430744,0.0022911103,-0.024105258,-0.035746876,0.024127476,-0.013974384,-0.0058319173,0.0087589845,0.045988835,-0.020350615,0.019906279,-0.013985493,-0.024127476,0.03628008,0.020461699,-0.027704384,-0.004454474,0.033591844,-0.029681683,0.023616489,0.010780715,0.0028007089,-0.036946584,0.018462185,-0.02332767,-0.006354013,0.004993232,-0.022694489,-0.0034130602,-0.007325999,0.038923882,0.021328155,-0.010902909,0.012430315,0.03712432,-0.021605866,0.009081128,0.008270214,0.022361238,0.034702685,-0.0058097006,0.0088645145,-0.006092965,-0.018873196,0.038857233,0.026415808,0.021550324,0.022116853,0.004221197,-0.006831675,0.061362877,-0.0011337525,-0.0034297227,-0.0154740205,-0.0065484103,-0.001570452,-0.0026438024,0.0065373015,-0.014374288,0.031814497,-0.026704628,0.056119706,0.011108414,-0.005418129,0.006037423,0.005709725,0.041878723,-0.0059707724,-0.011441667,0.010419692,0.030881392,-6.93408e-05,-0.029814983,-0.00101156,-0.0041656555,-0.0034213916,-0.020906035,0.01197487,0.03263652,-0.028837442,-0.00534037,-0.0016315483,-0.016429344,0.010652969,-0.017429102,0.029148478,0.034858204,0.0592745,-0.0076536974,-0.013207904,0.015685081,-0.00955879,-0.026171423,-0.012596942,0.014296529,-0.0016579308,0.0011295868,0.0086534545,0.037701957,-0.031547897,-0.0075203963,-0.016140526,-0.0092588635,-0.048210517,-0.015274069,0.0028173716,0.04629987,-0.01464089,-0.029459514,-0.08984485,0.02220572,0.020417266,0.0028354228,0.024083043,-0.0036157889,-0.014507589,-0.0006599092,-0.009742079,-0.03719097,-0.008570141,0.010069777,0.0119526535,0.01260805,0.02723783,-0.0390794,0.0006633806,0.049410224,0.013418964,0.06105184,0.0076536974,-0.0031714523,0.020372832,0.0016662622,-0.023505405,0.008098034,-0.013718891,-0.013585591,-0.012285906,0.010075332,-0.0060874107,-0.034835987,-0.014963034,-0.0144631555,-0.031636763,0.047232978,-0.015007467,-0.020084012,0.006170724,0.0032297713,0.02339432,-0.0319478,-0.029748334,0.03005937,-0.0010844589,0.011652727,0.019728543,-0.0103363795,-0.0052987137,0.010253066,-0.012708026,-0.022661164,0.01498525,0.009303297,-0.03999029,0.01330788,0.016096093,-0.004510016,0.0040156916,-0.015340719,-0.023172151,-0.02031729,0.0037157645,-0.04292291,0.028237589,-0.025371619,-0.0002768425,0.005987435,0.0025882605,-0.011297257,-0.0040878966,0.025971472,0.007892529,0.0012024859,0.0017551294,0.005440346,-0.004668311,-0.01519631,-0.018617703,0.01176381,-0.039701473,0.013007953,-0.02570487,-0.020261748,0.012485857,0.005534767,0.0012802447,9.242548e-05,0.039523736,0.025949255,0.02220572,0.027437782,-0.014785299,0.026393592,0.0070260717,0.0072537945,-0.026038123,-0.0142520955,0.00046342914,0.024349643,0.031703413,0.015518455,0.017029198,0.041078914,-0.008031383,0.011052872,0.0054070204,-0.025260534,0.06207382,-0.035569143,0.019639676,0.0275933,-0.008331311,0.026060339,0.01814004,0.0046516485,-0.025593786,-0.03588018,0.0013545322,-0.02843754,-0.0028354228,-0.022638949,-0.016940331,-0.0012455309,-0.016162742,0.03061479,-0.040123593,-0.0034019519,-0.006576181,0.02626029,0.0072815656,0.009581007,0.03074809,0.007892529,0.04918806,0.01068074,-0.0011656892,-0.011191728,0.062873624,0.002428577,0.0134633975,0.01836221,0.00976985,-0.0018009517,-0.046388738,-0.010869583,-0.008842298,0.011152848,0.00056444627,-0.016729271,-0.0004585692,-0.0154740205,0.045144595,0.030548139,-0.0028826334,-0.008231334,0.032658737,-0.032258835,0.0074593,0.0367022,0.010958451,0.006170724,0.0074426373,0.011819352,-0.020717192,-0.019884061,0.0008831189,0.007781444,-0.0033075302,0.0074204206,0.0026646308,-0.025793737,-0.008936719,-0.018173365,-0.012552508,-0.00907002,0.012485857,-0.010264175,0.00442948,-0.028037637,0.0031464582,0.034413867,0.027682168,-0.011375016,-0.015673973,-0.030370403,-0.012974627,-0.008203564,0.03481377,-0.0040767877,0.019350857,0.03383623,0.0025146673,-0.032036666,-0.037768606,-0.021472564,-0.05167634,0.0036602225,-0.01806228,0.019417508,0.022694489,-0.023572054,-0.0031186873,4.3153585e-05,-0.04972126,-0.0044072634,-0.006404001,0.0316812,0.015540672,0.025527135,-0.0074370834,0.01955081,0.011080643,0.014763082,-0.007992504,0.0016843133,0.00809248,-0.03761309,-0.010564102,0.042700745,0.0072593484,-0.012919085,0.038901664,-0.05723055,-0.002893742,-0.020117339,-0.024282994,0.010564102,0.0123858815,0.026082557,-0.020694975,-0.019095363,0.02038394,0.043611635,-8.596003e-05,0.00240636,0.003165898,-0.012141497,-0.014618672,-0.020550566,0.015562888,0.0092977425,-0.015362937,0.004051794,0.0016662622,-0.014118794,-0.04785505,-0.046522036,0.0066594942,-0.00095532363,-0.008314648,-0.036391165,0.004273962,-0.014307638,0.004126776,0.012830218,0.025882605,-0.0002186969,0.03474712,0.033369675,0.0094421515,-0.007325999,0.0042850706,-0.023638705,0.04994343,0.034213915,-0.024571812,-0.021061553,-0.007614818,0.050832104,-0.0019231442,-0.018395534,-0.018517727,0.028970744,-0.04972126,-0.013552265,-0.04447809,0.040456843,-0.0047321846,0.03103691,-0.038923882,0.003701879,-0.0029826092,-0.033880662,-0.021105986,0.012496966,0.0035852406,0.008825635,-0.005362587,0.00949214,0.009431044,-0.02843754,-0.03390288,0.009097791,0.022105744,0.0031464582,0.015096335,0.01218593,0.03019267,0.0046294318,-0.022794466,-0.0034213916,0.002902073,0.011225052,0.019184232,-0.0368355,0.0054347916,0.013618915,-0.0072593484,0.003299199,0.012685809,0.008842298,-0.0065595186,0.0049015875,-0.029303996,0.0012142885,0.0029381756,0.003593572,-0.028726358,0.005037666,-0.008825635,-0.015951682,-0.0037963004,-0.021716949,-0.03321416,0.0019634122,0.0026174202,-0.007598155,0.008286877,-0.018528834,0.025438268,0.026104772,-0.024816196,0.018451076,0.021128204,0.04181207,-0.008692334,0.021761384,-0.038368464,-0.035746876,-0.0059152306,0.033880662,0.02472733,-0.004479468,-0.027126746,-0.015351828,-0.016473778,-0.00027892532,0.0069038793,0.013674458,-0.029126262,-0.038346246,0.009481031,0.041434385,0.00826466,0.022261262,0.011091751,0.015918357,0.004543341,-0.007387095,-0.024971714,-0.0031520126,0.03241435,0.032614302,0.028637491,0.0006297082,-0.023660922,-0.035813525,0.017840113,0.022094635,0.016829247,0.016518211,0.050121166,0.022750031,-0.024882847,-0.0063151335,0.027993204,0.015996117,0.0020717192,0.009564345,-0.026949013,0.013918843,-0.018306667,0.0041989805,0.0029326214,-0.014107686,-0.044522524,0.011297257,-0.0035047047,-0.010691849,0.02430521,0.009575453,0.042367492,-0.046255436,0.016851464,0.01660708,0.0034658252,-0.029459514,-0.02752665,0.0063928925,-0.010964004,-0.0046211,0.0158406,0.0009129728,0.03494707,0.014685323,0.0008768704,-0.0057041706,-0.0005030029,-0.0048877024,0.023794223,-0.0073926495,0.011919328,0.013130145,0.0075592757,0.042100888,0.013296772,-0.014507589,0.028393107,-0.0019439724,0.01744021,-0.033325244,-0.02374979,-0.018817654,0.019139796,0.011574968,-0.025793737,0.0075592757,0.010514114,-0.01400771,0.0060707484,-0.023860874,0.031214643,0.007992504,0.0048515997,-6.556568e-05,-0.019917386,0.023971958,-0.0011170899,-0.019073147,0.01068074,-0.006626169,0.04412262,0.018584376,0.008486829,0.026149206,0.030126018,0.027548866,-0.02332767,0.017184716,-0.0117415935,0.026571326,0.01681814,-0.019206448,0.011019547,0.014751974,-0.021139313,0.016551537,0.019206448,-0.010258621,0.03588018,-0.041501034,-0.048299383,-0.008547924,-0.03299199,-0.01631826,0.027615517,-0.01785122,-0.036857717,0.03019267,0.005612526,-0.028659709,-0.013141254,0.021261504,-0.03536919,0.0071926983,0.01324123,0.010764053,0.028637491,-0.027726602,0.021128204,-0.014718649,-0.027682168,0.025793737,-0.013718891,0.026015906,0.011997087,0.017284691,0.0148963835,-0.01870657,0.00332697,0.03796856,0.008459058,0.0012587222,-0.01638491,-0.02557157,0.012696917,0.03608013,-0.0413233,-0.031636763,-0.0017245812,0.007264903,0.03672442,0.027726602,-0.03781304,0.0041739866,0.033436324,-0.047099676,-0.031970017,-0.012141497,-0.00039296015,0.00252161,-0.0013705005,0.039323784,0.030503705,-0.004457251,-0.00843684,0.022927767,-0.024038607,0.0056791767,-0.00724824,-0.01604055,0.013763325,0.023038851,0.044722475,-0.0033491869,-0.042256407]	136
7	3	dishes that are both familiar and excitingly new. Every ingredient is carefully selected, and every dish is prepared with passion. --- ## Breakfast & Brunch *Served all day because great mornings shouldn't have a deadline* | Item | Description | Price (RM) | |------|-------------|------------| | **Classic Big Breakfast** | Eggs, bacon, sausage, toast, beans, hash browns | 25.90 | | **Eggs Benedict** | Poached eggs, hollandaise, English muffin | 22.90 | | **French Toast Deluxe** | Brioche, maple syrup, fresh berries, cream | 18.90 | | **Avocado Toast** | Smashed avocado, poached egg, sourdough | 19.90 | | **Nasi Lemak Breakfast** | Coconut rice, sambal, egg, anchovies, peanuts | 14.90 | | **Pancake Stack** | Fluffy pancakes, butter, choice of toppings | 16.90 | --- ## Mains — Western Selection ### Burgers & Sandwiches | Item | Description | Price (RM) | |------|-------------|------------| | **Bonne Bouche Signature Burger** | Double beef patty, cheese, special sauce, brioche bun | 28.90 | | **Grilled Chicken Burger** | Marinated chicken breast, lettuce, tomato, aioli | 24.90 | | **Classic Club Sandwich** | Triple-decker, chicken, bacon, egg, fries | 23.90 | | **Pulled Pork Sandwich** | Slow-cooked pork, coleslaw, BBQ sauce | 26.90 | ### Pasta & Risotto | Item | Description | Price (RM) | |------|-------------|------------| | **Spaghetti Carbonara** | Creamy egg sauce, pancetta, parmesan | 24.90 | | **Aglio Olio Prawns** | Garlic, chilli, olive oil, tiger prawns | 28.90 | | **Mushroom Risotto** | Arborio rice, mixed mushrooms, truffle oil | 26.90 | | **Beef Bolognese** | Slow-cooked meat sauce, spaghetti, parmesan | 25.90 | ### Grilled & Steaks | Item | Description | Price (RM) | |------|-------------|------------| | **Grilled Chicken Chop** | Marinated chicken, black pepper sauce, sides | 26.90 | | **Fish & Chips** | Beer-battered fish, fries, tartar sauce | 28.90 | | **Lamb Chop** | New Zealand lamb, rosemary jus, vegetables | 45.90 | | **Ribeye Steak (200g)** | Australian beef, choice of sauce | 55.90 | --- ## Mains — Malaysian Fusion | Item | Description | Price (RM) | |------|-------------|------------| | **Rendang Beef Pie** | Slow-cooked rendang in flaky pastry | 22.90 | | **Satay Chicken Pasta** | Peanut sauce pasta with grilled chicken | 24.90 | | **Sambal Prawn Spaghetti** | Spicy sambal, tiger prawns, local herbs | 28.90 | | **Curry Laksa** | Rich coconut curry, noodles, prawns, chicken | 18.90 | | **Kampung Fried Rice** | Wok-fried rice, anchovies, egg, sambal | 16.90 | --- ## Light Bites & Sides | Item | Price (RM) | |------|------------| | Crispy Fries | 9.90 | | Truffle Fries | 15.90 | | Chicken Wings (6 pcs) | 18.90 | | Nachos with Cheese | 16.90 | | Garlic Bread | 8.90 | | Garden Salad | 12.90 | | Caesar Salad | 18.90 | | Soup of the Day | 10.90 | --- ## Cakes & Desserts *Freshly baked in-house daily* | Item | Description | Price (RM) | |------|-------------|------------| | **Burnt Cheesecake** | Our signature!	1	2025-12-21 23:53:07	2025-12-21 23:53:07	[-0.0010339983,-0.0013686436,-0.012468105,-0.055036876,0.026657695,-3.270801e-05,0.01399972,0.038277715,0.0033227184,-0.02112616,-0.007094795,-0.0634924,-0.006044183,-0.0034113242,0.002697731,0.059796274,-0.071340345,0.0276197,-0.04450544,0.023290673,0.09108679,-0.014759199,-0.009797272,0.006702398,0.023328647,0.033493,-0.03615118,0.0013757637,0.0068732803,-0.010208657,0.031543672,-0.026910855,0.015898416,-0.0059872223,-0.008847925,-0.03663218,-0.0010996616,0.018607223,0.006461896,0.027923493,0.0050093937,0.006955557,0.012246591,-0.013569349,0.016100945,0.019543914,-0.07235298,-0.0072340327,-0.049745843,0.01431617,0.001076719,0.03374616,-0.0154553875,-0.007385928,0.042682692,0.024138758,-0.044429492,0.060100064,0.06318861,0.021164134,0.046581347,-0.0068859383,0.014151616,0.0069935312,-0.018379379,-0.030024717,-0.0167465,0.034024637,-0.025948849,0.023670413,0.012670633,-0.0026961486,-0.0447586,-0.034353744,0.034303114,0.0004639939,0.035594225,-0.029163975,0.018240143,-0.01606297,-0.03615118,0.0026138718,-0.006376455,-0.0009904866,0.03731571,-0.053214125,-0.0812642,0.028277917,-0.034227163,0.05493561,0.021543873,-0.013392137,-0.00328158,-0.04318901,0.027341226,-0.0096706925,-0.04263206,0.0145566715,-0.037113182,0.043290276,0.10592193,-0.051290113,-0.017771797,-0.0052340725,0.061163336,-0.0028701958,0.04931547,0.010341565,0.0010403274,-0.02163248,-0.06688474,0.0018955318,-0.0649101,-0.0051043285,0.011525086,0.04493581,0.0411131,-0.04136626,-0.035062592,-0.042581428,0.010582067,0.0013354163,-0.00095963274,-0.021290714,-0.048353463,-0.01049979,-0.051847067,0.024632419,-0.035214487,-0.029341185,0.031670254,-0.019392017,0.036404338,-0.019227464,0.0077909837,0.02744249,-0.013683271,0.030252561,-0.04787246,0.002897094,0.052859705,0.0062910137,-0.018328749,-0.00812642,-0.015468045,-0.017518638,-0.06369493,-0.023303332,-0.03787266,0.06263166,0.0005197681,-0.007968196,-0.07235298,-0.032480363,-0.020543894,-0.031391777,0.040606786,0.05807479,-0.032986682,0.03425248,-0.026733642,0.024012178,-0.04351812,-0.0026328587,0.014012379,-0.020543894,-0.020328708,0.029163975,-0.05994817,-0.04480923,0.010923833,0.04177132,0.06136586,-0.008822609,-0.0051676184,-0.006569489,0.020518577,-0.0552394,0.018999621,-0.021240082,0.005395462,0.042480163,0.029163975,0.023733703,0.016164234,0.014670593,0.0034556272,-0.049897738,0.017898377,0.048100304,0.0029635483,0.03194873,-0.013113662,-0.024290655,0.019708468,-0.06739106,0.040454887,0.025353923,-0.03326516,0.06799864,-0.016442709,0.011271927,0.034910694,-0.014809831,0.045163654,-0.02944245,-0.015480704,0.018328749,0.022138799,-0.044302914,0.05964438,0.011714956,-0.015518677,0.0069492282,-0.049112942,0.016214866,-0.025771637,-0.04088526,0.017012319,0.039467566,0.008164394,0.03420185,0.038353663,-0.014455408,0.0152781755,-0.017113581,0.029037395,-0.009778285,-0.01406301,-0.01168964,0.0020142002,-0.008525146,-0.041037153,0.024961527,-0.033163894,0.030531036,-0.030986723,-0.0122782355,0.039290354,-0.042935852,-0.03075888,0.025391897,-0.009765628,0.048049673,0.051416695,-0.020569209,0.023607124,-0.047467407,0.010468145,-0.01075295,0.046530716,-0.019024936,0.0027467806,-0.035417013,0.003724609,-0.019227464,-0.029872822,-0.023961546,0.02231601,-0.0015015523,-0.008588436,0.04055615,0.005376475,-0.05032811,-0.009923852,0.014632619,-0.0015608865,0.036986604,0.01725282,-0.045973767,-0.04594845,-0.0027768433,0.03956883,0.028353864,0.029923452,-0.06334051,-0.006955557,0.012487092,0.030606983,0.022151457,-0.016316129,-0.05544193,0.02068313,-0.057669733,-0.010158025,-0.02482229,0.050530635,-0.040910576,0.008658055,0.0039018209,0.0014390536,-0.022240061,-0.00793655,-0.0138984565,0.023834966,0.012911134,-0.0038163795,-0.011347875,0.03901188,0.0056644436,0.02744249,0.002275271,-0.011822549,0.008923872,0.03599928,0.011176992,-0.027088067,0.041239683,-0.012423802,-0.01431617,-0.026277956,-0.018417353,0.021860322,-0.060910176,0.009316269,0.012860503,0.043340907,0.038201768,0.019999601,-0.028201967,0.06207471,0.0042783953,0.03394869,0.009037795,0.017885718,-0.050859742,0.05488498,0.01955657,-0.0012855756,-0.039265037,0.04225232,-0.047163613,-0.01599968,-0.0052973623,-0.031290513,-0.004202448,-0.010056761,-0.0034271467,0.009879549,0.015987022,0.0012760821,-0.05351792,-0.05463182,0.0002015387,0.008322619,-0.041897897,0.039037194,0.034328427,-0.0024667229,0.025708348,-0.027138699,0.046961088,0.015100964,0.029493082,-0.0057403916,0.0067467005,0.03425248,-0.0017468005,-0.056910254,0.008702358,-0.009588416,-0.018670512,0.011385849,0.009341585,0.029214606,0.012746581,-0.004531555,-0.03326516,0.0089048855,-0.012493421,0.016721185,0.045113023,0.009885878,-0.016581947,-0.0512648,-0.002306916,0.0012760821,0.03564486,0.005192934,-0.005876465,0.036277756,-0.009392218,0.033391736,0.0365056,0.05812542,-0.0306323,0.0306323,-0.029720925,0.035467647,-0.044100385,-0.011683311,-0.016683212,0.03493601,0.01262633,0.00812642,0.014341486,0.036708128,-0.00899982,-0.010455487,0.033594266,0.018113563,0.011170663,-0.041492842,-0.04564466,0.014240222,0.023543833,-0.014455408,0.003968275,-0.026986802,-0.0055346997,-0.014721225,0.019392017,0.009917524,-0.018543933,-0.007170743,-0.022050193,0.025847584,0.02093629,0.022771697,0.0015521842,-0.027974125,-0.025872901,-0.08789698,0.005977729,-0.050454687,0.03374616,-0.03688534,-0.030429771,-0.04769525,0.0029777887,-0.0107656075,-0.030531036,-0.004927117,0.0406321,0.025151396,-0.009164374,-0.041670054,0.017050292,-0.0020110358,-0.019126201,0.039037194,0.021923613,-0.01574652,-0.023796992,-0.053973604,0.00012222856,0.06359366,0.0021613492,0.024202049,-0.046100345,0.0039967555,0.016278155,-0.013518717,-0.033214528,-0.08409958,0.021202108,0.02506279,-0.0058479845,0.002749945,-0.039467566,0.029898137,-0.006145447,-0.02906271,-0.027214646,0.021328688,-0.02625264,-0.052201487,0.011607363,0.019632518,-0.0011320977,-0.024581788,0.0009580505,-0.020898316,0.030100664,0.010177012,-0.038353663,-0.03832835,-0.008734003,-0.019240122,0.02199956,-0.015974365,0.022341326,-0.021214766,-0.015822468,-0.0393663,-0.03969541,-0.001275291,-0.0017214846,-0.009620061,-0.007847944,-0.021151476,0.009613732,0.003004687,-0.011778246,-0.0076390877,0.0039334656,0.02212614,-0.012290894,0.010354224,0.0037214446,0.0010972882,-0.046176292,-0.0036296744,0.055087507,0.030556351,0.00086628017,-0.044657335,-0.029847505,0.007904906,0.012221275,-0.03637902,-0.015797153,0.014619961,-0.005743556,0.007961866,0.033467688,-0.0068416353,0.02337928,-0.024037495,0.004987242,-0.003876505,0.008398566,0.030784195,-0.04612566,0.016898397,-0.031163935,0.030151296,-0.035619542,-0.010164354,-0.049214207,0.028151337,-0.048758518,0.025404556,0.033543635,-0.0058163395,0.001537944,-0.0033258828,0.00020727434,-0.0054429295,-0.010866871,0.012601014,0.045821868,-0.0078036417,-0.008968175,-0.00693657,-0.032024678,0.014417433,-0.017683191,0.006544173,-0.017670533,0.0004865409,0.009018807,0.041290313,-0.015721206,0.027974125,0.01393643,0.013075688,-0.030024717,0.035315752,0.0031787339,0.0037720765,-0.009082097,-0.04450544,0.035619542,0.014138958,-0.020138837,-0.009227664,0.02006289,0.010309921,0.0077593387,-0.024151416,0.017164214,0.021050213,-0.043416854,0.025050132,0.0018860382,0.053467285,0.017214846,-0.038556192,-0.004351179,-0.02556911,-0.014987042,-0.010120051,0.031391777,-0.018227484,0.067239165,0.05356855,0.007151756,0.01050612,0.01431617,0.012790884,-0.0045600357,-0.010183341,-0.001204881,0.013012398,-0.02075908,-0.02787286,0.0406321,0.0033923374,-0.045619342,0.009012478,0.007677062,-0.020278076,-0.010708647,-0.025050132,0.0023670413,-0.022214746,-0.012613672,-0.00035798334,-0.030100664,-0.014657935,0.0019414169,0.032682892,-0.0064777187,-0.027138699,0.008797293,-0.013822509,0.0019414169,-0.0061359536,-0.02550582,-0.010170683,0.010980793,0.04106247,0.0045790225,0.0025679867,0.039214406,-0.014784515,-0.016771818,0.025796954,0.01162635,0.013708587,0.011651666,0.040708046,0.0022863466,0.020202128,0.04080931,-0.0074049155,-0.027720965,0.0033701858,-0.02688554,0.022936251,0.006120131,0.010822569,-0.035214487,-0.0023148272,-0.030986723,0.022227405,-0.007658075,-0.0114238225,-0.02218943,0.04351812,-0.0060726637,0.032910734,-0.009974484,-0.0014833565,0.022290694,0.007385928,0.016341446,0.00058108015,0.0057055824,0.017911034,0.024885578,-0.01661992,5.83948e-05,0.0051486315,0.041973844,-0.010069419,-0.0015672155,0.008658055,-0.030151296,0.022024877,0.00022705243,0.08521349,0.027569069,0.0015616777,0.022164114,0.012214946,0.003601194,0.005556851,0.028910816,0.005607483,-0.029088026,-0.024885578,0.005917603,-0.016860424,-0.029366503,0.018885698,0.0023306496,0.02675896,-0.0020933126,-0.0038733403,0.025265317,-0.0022056522,-0.02637922,0.015695889,0.0104365,-0.00075512734,0.050935693,0.02331599,-0.11928876,0.007613772,0.0029334857,-0.01012638,0.017138898,-0.033214528,0.04463202,-0.010233973,0.021429952,-0.0017040799,-0.007132769,-0.04369533,0.0033037316,-0.003531575,0.05493561,0.0013322518,0.029113343,-0.04437886,-0.035062592,0.012873161,-0.0004659717,-0.00018284841,0.031239882,0.0128478445,-0.038530875,0.0060157026,0.039290354,0.013012398,0.018050272,-0.018290773,0.05136606,-0.0142275635,0.0097592985,0.031391777,0.021581847,-0.034784116,-0.020708447,0.00020312094,-0.002680326,-0.01006309,-0.034404375,0.012132669,-0.04842941,-0.01712624,-0.01687308,8.430409e-05,0.0016945864,-0.0020806547,-0.0060188673,-0.0452396,0.016176892,-0.01318961,0.011417493,0.026227323,0.038606822,0.009202348,-0.0393663,-0.014885779,-0.0030268382,0.03169557,0.019910995,-0.0032198725,0.028151337,-0.004079032,-0.0074871923,-0.03306263,-0.0066201207,0.015936391,-0.05812542,-0.026834907,0.0088162795,-0.018885698,-0.022303352,0.01868317,0.012468105,0.02187298,-0.016138919,0.007493521,0.011930142,0.00073020696,-0.01599968,0.052150857,-0.00830996,0.03498664,-0.033493,0.009797272,0.018771777,0.02469571,-0.06855559,-0.023885598,-0.03204999,0.034809433,0.0018243307,0.022037534,-0.035214487,-0.0054366,-0.017037634,-0.010968136,-0.051036954,0.029113343,0.04496113,-0.004139158,-0.004775221,0.01406301,0.00023397476,0.0032230369,-0.005224579,0.0013077271,0.054226764,0.04080931,-0.009208676,0.004139158,-0.038049873,0.0007005398,0.041847266,0.035290435,-0.0041486514,-0.009240322,0.0059049455,0.019885678,-0.013455427,0.034303114,0.019050252,-0.018999621,0.012702278,-0.0012476017,0.01782243,-0.039594147,0.002897094,-0.006461896,-0.034100585,0.006677082,-0.0050030644,-0.0067846747,0.014176932,-0.027467806,0.020771736,-0.0025664044,0.02099958,0.004825853,0.030303191,0.023619782,-0.0045537064,-0.013594666,0.007518837,0.01106307,0.034075268,0.010354224,-0.014506039,-0.002493621,0.006237217,0.016442709,-0.025594426,0.015949048,-0.020050233,-0.032986682,0.00699986,0.009968155,0.051492643,0.019164175,-0.04437886,-0.040834628,0.022391958,0.011885839,0.0038923272,-0.011113702,0.005395462,0.018240143,0.024594445,-0.0016502835,-0.0047214245,-0.027670333,-0.053669814,-0.0032467705,-0.030708248,0.021581847,-0.003172405,-0.016366761,0.026531115,-0.011303572,-0.042530797,0.024455208,-0.002672415,0.027569069,-0.014151616,-0.010221315,0.033163894,-0.009322599,0.04764462,-0.010974464,0.020518577,0.009366902,-0.0029477258,0.019012278,0.005294198,0.011727613,0.027695648,-0.017430032,-0.0029920288,0.017240161,-0.012366842,0.016683212,0.017911034,-0.012740252,-0.01893633,0.030075349,-0.018708486,0.02318941,-0.0077973125,0.02406281,0.004987242,0.04007515,-0.03212594,0.00830996,-0.004651806,0.019037595,-0.0066834106,-0.014771856,0.0073985863,-0.0058479845,0.028986763,0.014594645,-0.010575738,-0.03255631,0.0037973926,-0.022518538,0.013860483,-0.0038891628,-0.04944205,-0.00856312,-0.024012178,0.0008504577,0.017024977,0.03331579,0.022594485,0.0068416353,-0.0306323,0.019303411,-0.017075608,0.01162635,-0.014531355,-0.009158045,-0.011113702,0.02344257,-0.05032811,-0.0026376056,0.022265378,-0.024379259,0.009588416,0.023240043,-0.023176752,0.021138819,-0.011221295,0.012828858,-0.014695909,-0.028404497,-0.009790944,-0.021910954,0.017328767,-0.0017420538,0.031619623,-0.017024977,0.01844267,-0.009847905,-0.024240023,0.003537904,-0.0061106374,-0.006968215,0.034784116,0.012733923,0.017708506,0.015062991,0.06870749,-0.004404975,0.02299954,0.004088526,0.008582107,0.0046897796,0.013240241,0.030834828,0.020543894,-0.012664304,0.02456913,-0.017581927,-0.017088266,-0.023290673,0.02787286,0.03807519,0.016113602,-0.008879569,0.023556491,-0.015569309,-0.045163654,-0.0043606726,0.031290513,0.0063859485,0.011354203,-0.0030837993,0.068656854,0.03961946,0.016911054,-0.020138837,-0.0256324,0.009828918,-0.05136606,-0.017771797,0.039037194,0.03488538,-0.011898496,-0.03199936,-0.016227525,0.011506099,-0.028100705,0.044277597,0.035037275,0.005192934,-0.04177132,0.005870136,-0.034910694,-0.033138577,0.0047056023,0.016341446,-0.000248215,-0.013582007,0.008885899,0.022721065,-0.013607323,0.025467847,-0.011639008,0.040961206,-0.017100925,0.025619742,0.015809812,-0.004531555,-0.0016708527,0.044302914,0.012398487,0.0050093937,-0.006765688,-0.017113581,-0.01344277,-0.023657756,-0.022138799,0.0036296744,-0.02318941,0.042429533,0.019645177,-3.7405305e-05,0.00062380085,0.023480544,0.038480245,-0.020100864,-0.061669655,0.03908783,-0.009993471,0.004664464,-0.003249935,0.0044113044,0.011544073,0.027974125,0.014581988,-0.023708386,-0.007835287,-0.015949048,-0.022075508,-0.00057593785,0.016113602,0.033113264,-0.007601114,0.010221315,-0.005762543,-0.0034524626,0.012765568,-0.010677001,-0.012138998,-0.017075608,0.003787899,0.002865449,-0.033644896,-0.027796913,0.023632439,-0.014025036,0.0027404516,-0.05012558,-0.02187298,-0.0317462,-0.01056308,0.006363797,-0.011828878,-0.002147109,-0.032860104,0.0003864638,0.009613732,0.005088506,0.018581908,0.0042594085,-0.037290394,0.039214406,0.031974044,0.019366702,0.035619542,0.01606297,0.0031692404,-0.026429852,-0.016885739,0.001954075,-0.0018860382,-0.007556811,0.017721165,0.0006961886,0.014328828,-0.011145347,0.0030489897,0.026429852,0.026050113,0.010461817,0.0018986963,-0.010822569,0.04250548,-0.005749885,0.040429574,-0.0025600754,0.013657955,0.03369553,0.029923452,-0.009683351,-0.030252561,-0.002071161,-0.004215106,-0.050783794,-0.010892187,-0.0103289075,0.0021265398,0.004275231,-0.012727594,0.007139098,-0.0341259,0.012638988,-0.0062213945,-0.0023480544,-0.0011582047,0.030860143,0.004569529,-0.012398487,0.02663238,0.0037435961,-0.038049873,0.008265657,0.076504804,-0.0069175833,0.031594306,0.018986963,0.024974184,-0.029974084,-0.031974044,-0.019328728,-0.017657876,-0.033138577,0.033822108,-0.03344237,-0.0052119214,0.022100825,0.032227203,0.013518717,-0.022885619,-0.01075295,0.02787286,0.011094715,-0.007632759,0.02382231,0.014151616,0.010145367,-0.01750598,-0.01018967,-0.036733445,-0.031366464,0.007847944,0.017430032,0.0027546918,0.01774648,0.003313225,-0.011278256,-0.0013116826,-0.021429952,0.0068226485,-0.0032214546,0.012227604,-0.01162635,-0.028961446,0.029290555,-0.016556632,0.003756254,0.012860503,0.013366821,0.01537944,-0.015113622,-0.013164294,-0.020303393,0.015961707,0.0095631005,0.00393663,0.017024977,-0.027518438,-0.013759219,-0.008784635,-0.02893613,-0.043214325,0.027974125,-0.034834746,0.015911074,0.017531296,-0.013531376,-0.0045948448,0.00087260915,-0.03207531,-0.006632779,-0.0013551945,0.02837918,-0.0025046968,0.024657736,-0.009506139,0.022366641,-0.0017610408,0.027898178,-0.018670512,0.002256284,-0.0031407601,-0.028733604,-0.002743616,0.010987123,-0.0025695688,0.0041233352,0.015822468,-0.024176732,0.002069579,0.02369573,-0.023176752,0.0358727,-0.009835247,0.03637902,0.008677042,0.005224579,0.027569069,0.017341426,-0.005531535,0.02506279,0.030050032,-0.027822228,0.03473348,0.009639048,-0.022847645,-0.009177032,-0.014012379,0.0089491885,0.008790963,-0.029746242,-0.026328588,-0.019290755,0.0031581647,0.0071897297,0.00083779974,-0.019619862,-0.024012178,0.008037814,-0.020240102,0.0029936112,0.010430171,-0.034176532,0.0063479743,0.004044223,0.007620101,-0.01799964,0.020695789,-0.038708087,0.037973925,0.059492484,-0.041037153,-0.011961786,0.007569469,0.026986802,0.015354124,0.0057910234,0.0038227085,0.018999621,-0.016164234,-0.005484068,-0.011721285,-0.0061707627,-0.029594345,0.033290476,-0.038986564,0.017657876,-0.0031027861,-0.041290313,-0.026733642,0.0107656075,0.009987142,0.0023607123,-0.011145347,-0.018176852,0.015328808,0.006582147,-0.0021455267,0.016328787,0.009885878,-0.008847925,0.028809551,-0.02356915,-0.015417414,-0.025796954,-0.013784534,-0.00042325104,-0.0077973125,0.012385828,-0.0022372971,-0.0048923073,-0.025607083,-0.013721245,-0.009354243,-0.014025036,-0.026733642,-0.0038733403,-0.005018887,0.019012278,-0.015923733,-0.008284644,-0.031214567,-0.025024816,-0.028024757,0.0063859485,-0.0024952034,-0.024366602,0.023759019,-0.024366602,-0.0054714098,-0.010993451,-0.0009794108,-0.025796954,0.006272027,-0.022151457,0.01399972,0.03756887,0.007740352,0.021835007,0.0029825354,-0.0053163497,-0.019619862,0.024493182,-0.036404338,-0.020354023,0.00017028932,0.019986942,0.006427087,0.046480086,-0.01750598,-0.0061612693,0.020607183,0.02468305,0.013265558,-0.01574652,-0.025126081,-0.031113302,0.041239683,0.039973885,0.02556911,0.009784615,0.020455288,0.016176892,0.005094835,0.02774628,-0.00856312,-0.0011771916,-0.0104365,0.013860483,0.002071161,-0.0010877948,0.00021716338,-0.011892168,0.03706255,0.035467647,-0.007259349,0.036328387,0.02101224,-0.021176793,0.007512508,-0.013392137,0.016316129,-0.0057372274,-0.036834706,-0.0019050252,-0.010309921,0.0013702258,-0.019797074,-0.00328158,0.010221315,-0.013050372,-0.057669733,-0.0020600855,-0.015303492,-0.016847765,0.048049673,-0.014923752,0.007582127,-0.039340988,-0.0127149355,-0.024493182,-0.004050552,-0.027695648,-0.0256324,0.0054935613,0.014784515,0.022429932,-0.0014643695,0.0043480145,0.009442849,0.0035568909,0.005806846,0.00022032787,-0.023240043,-0.0077276938,0.015822468,-0.023050172,0.0068732803,0.0046897796,-0.01544273,-0.0029065874,-0.02637922,0.002044263,0.0041296645,0.03883467,0.0029129165,-0.036834706,0.004069539,-0.013493401,0.015202228,0.01937936,-0.01744269,0.012347855,0.007158085,0.005094835,-0.042100426,0.011569389,0.004743576,0.02369573,0.014354143,-0.0061549405,-0.026733642,-0.011518757,0.012018748,-0.005639128,0.0053479946,0.006145447,0.0035980295,0.014366802,0.01799964,0.030100664,0.015923733,-0.016771818,0.01531615,0.019113543,-0.0060726637,0.018037613,0.01787306,-0.010214986,-0.01156306,0.03399932,-0.015847785,0.023176752,-0.002134451,-0.0056106476,0.00206325,-0.018455328,-0.05574572,-0.001903443,-0.028480444,-0.0073922575,-0.021885639,-0.048150938,-0.007480863,-0.019417334,0.023480544,0.016898397,0.012271907,0.024531156,-0.023607124,0.02637922,0.042176373,-0.006287849,0.0035189171,-0.017392058,0.031341147,-0.017354084,0.011170663,0.027796913,4.9667717e-05,-0.019138858,0.02493621,-0.009177032,0.0021186285,-0.015341465,0.030075349,0.0027277935,0.005173947,0.009202348,0.0068796095,-0.0027800077,0.012708607,0.020594526,-0.025050132,-0.038277715,0.01831609,0.009385888,0.026834907,0.027214646,-0.018531276,-0.009949168,0.02380965,-0.04463202,-0.00017750832,-0.010480803,-0.006101144,-0.017797112,0.014138958,0.023088146,-0.036075227,0.005332172,0.031163935,-0.008480843,-0.0052783755,-0.03544233,0.027771598,0.01625284,-0.0095187975,-0.0089048855,0.025480503,-0.005882794,-0.011898496]	746
8	3	Desserts *Freshly baked in-house daily* | Item | Description | Price (RM) | |------|-------------|------------| | **Burnt Cheesecake** | Our signature! Creamy, caramelized top | 16.90 | | **Chocolate Lava Cake** | Warm, gooey centre, vanilla ice cream | 18.90 | | **Tiramisu** | Classic Italian, coffee-soaked ladyfingers | 15.90 | | **Waffles with Ice Cream** | Crispy waffle, 2 scoops, toppings | 19.90 | | **Pandan Layer Cake** | Local favourite, coconut pandan | 12.90 | | **Cendol Parfait** | Malaysian dessert reimagined | 14.90 | --- ## Coffee & Beverages ### Specialty Coffee *Locally roasted beans from Johor* | Item | Hot (RM) | Iced (RM) | |------|----------|-----------| | Espresso | 7.90 | - | | Americano | 9.90 | 11.90 | | Latte | 12.90 | 14.90 | | Cappuccino | 12.90 | 14.90 | | Mocha | 14.90 | 16.90 | | Caramel Macchiato | 15.90 | 17.90 | | Affogato | 16.90 | - | ### Tea & Non-Coffee | Item | Hot (RM) | Iced (RM) | |------|----------|-----------| | English Breakfast Tea | 8.90 | 10.90 | | Earl Grey | 8.90 | 10.90 | | Green Tea | 8.90 | 10.90 | | Teh Tarik | 6.90 | 7.90 | | Hot Chocolate | 12.90 | 14.90 | | Matcha Latte | 14.90 | 16.90 | ### Fresh & Blended | Item | Price (RM) | |------|------------| | Fresh Orange Juice | 12.90 | | Mango Smoothie | 14.90 | | Mixed Berries Smoothie | 15.90 | | Banana Peanut Butter Shake | 14.90 | | Soft Drinks | 5.90 | | Mineral Water | 3.90 | --- ## Signature Drinks *Bonne Bouche Exclusives* | Item | Description | Price (RM) | |------|-------------|------------| | **Kluang Sunset** | Butterfly pea, lychee, soda, citrus | 14.90 | | **Gula Melaka Latte** | Palm sugar infused coffee | 15.90 | | **Pandan Coconut Shake** | Creamy coconut, pandan, gula melaka | 13.90 | | **Rose Bandung Float** | Rose syrup, milk, ice cream | 12.90 | --- ## Set Meals & Combos *Best value!* | Set | Includes | Price (RM) | |-----|----------|------------| | **Breakfast Set A** | Big Breakfast + Coffee/Tea | 32.90 | | **Breakfast Set B** | French Toast + Fresh Juice | 28.90 | | **Lunch Set** | Any Main + Drink + Dessert of the day | 38.90 | | **Couple Set** | 2 Mains + 2 Drinks + 1 Dessert to share | 75.90 | --- ## Dietary Information 🥬 **Vegetarian options available** — Ask our staff 🌶️ **Spice level adjustable** — Mild / Medium / Spicy 🥜 **Allergen info** — Please inform staff of any allergies 🕌 **Halal-friendly options** — Pork-free alternatives available --- *Menu prices are subject to change.	2	2025-12-21 23:53:08	2025-12-21 23:53:08	[-0.03805596,-0.021425646,0.0035337678,-0.058993712,0.024743345,0.012413492,0.017006693,0.048845455,0.010120377,0.0026433559,0.0007157274,-0.04625263,-0.023697851,-0.011563158,0.0090539735,0.029692015,-0.053835943,0.020352272,-0.037470486,0.038279,0.058937952,0.020087413,-0.0042621284,0.031532083,-0.0002992725,0.011040411,-0.015668461,-0.006973441,0.024436668,-0.0093536815,0.0039380253,-0.012064994,0.013598384,-0.028604701,-0.012991998,-0.025997937,0.01743883,0.030361129,0.0072836042,0.006339175,-0.01127739,0.0074020936,0.0015325191,0.0031974674,0.0049695787,0.023642091,-0.03819536,-0.0037812013,-0.049932767,0.01605878,0.014121132,0.037582006,-0.03518434,-0.0078272605,0.0096046,0.022861456,-0.052218914,0.045332596,0.063342966,0.012887449,0.03376247,-0.01766187,0.025830658,0.004624566,-0.032312717,-0.022708118,-0.003972875,0.029915053,-0.020547431,0.026834331,-0.000919163,-0.002479562,-0.027461627,-0.031309042,0.0159612,-0.018080067,0.011381939,-0.052804388,0.0039310553,-0.004603656,-0.0346825,-0.013688995,-0.021300187,0.036829248,0.06049922,-0.03379035,-0.10811796,0.023739671,-0.023042675,0.030026572,0.0035337678,-0.026806451,-0.010601304,-0.022624478,0.016713955,-0.0021537165,-0.048259977,0.014915707,-0.0148738865,0.047507223,0.089549996,-0.07304514,0.0014384247,0.00639842,0.068305574,-0.002967459,0.033372153,0.014204771,-0.014330231,-0.0028472273,-0.0410391,-0.0039136303,-0.029942932,0.0058338535,0.021244427,-0.0015621415,0.04784178,-0.029496856,-0.009771879,-0.059885863,0.017201852,0.015459363,0.020421972,-0.028939258,-0.04441256,-0.034041267,-0.06551759,0.018177645,-0.014016583,-0.05135464,0.039115395,-0.021788083,0.0159612,-0.030026572,0.0076042223,-0.01587756,0.01110314,0.045304716,-0.040258467,-0.018052187,0.037777163,0.018163707,-0.008217579,-0.01598908,-0.016588496,-0.03981239,-0.042488854,-0.029775653,-0.037805043,0.045834433,-0.03186664,0.0075345226,-0.062785365,-0.047200546,0.0064472095,-0.059941623,0.043046452,0.056623925,-0.012176514,0.008928514,-0.030807206,0.02074259,-0.0148878265,-0.0127410805,0.03830688,-0.024924563,-0.029050779,0.048427258,-0.06378904,-0.049877007,0.022080822,0.026471894,0.066521265,-0.007855141,0.00560733,-0.020171054,0.04803694,-0.04276765,-0.0002777092,0.04455196,0.018804941,0.046615068,0.010914952,0.0022913732,-0.0075414926,0.045444116,0.016950933,-0.033372153,0.012629561,0.025816718,-0.0014183861,0.031420562,-0.018749183,-0.029245937,-0.001250236,-0.05888219,0.05115948,0.015710281,-0.026862212,0.034515224,-0.010406145,0.0031870126,0.06680006,-0.044078004,0.029608374,-0.013932942,-0.0066005485,0.018512204,0.06551759,-0.021578984,0.065015756,0.026234915,-0.047312062,0.048594534,-0.015626643,0.027851945,-0.039672993,-0.038641438,0.0044921366,0.03351155,-0.0012641759,0.055006895,0.05584329,-0.011402848,0.012894419,-0.028548941,0.010824342,-0.0005044506,-0.033372153,0.004161064,-0.0043422827,-0.02709919,-0.026611293,0.02397665,-0.02735011,0.031086005,-0.03306547,-0.014999346,0.02075653,-0.0446356,-0.0070013213,0.042126417,-0.0029413216,0.05079704,0.047200546,-0.028632581,-0.0019062831,-0.07784047,-0.0136680845,-0.018024307,0.025147602,-0.004791845,0.004154094,-0.048538774,0.013702935,-0.006098712,-0.010636154,-0.04678235,0.035797697,-0.008280308,0.007889991,0.037972324,-0.00024721565,-0.05743244,-0.019446177,0.01756429,-0.010831312,0.011646797,-0.016184239,-0.020310452,-0.048873335,-0.022972977,0.045834433,0.02047773,0.004460772,-0.038000204,-0.008245458,0.016867295,-0.0027618452,0.031197524,-0.02702949,-0.052246794,0.00476048,-0.065071516,-0.0133474665,-0.032256957,0.032786675,-0.018944342,-0.012037114,0.0072975443,0.028995018,-0.008503347,-0.02233174,-0.02532882,0.0099879475,0.016086658,0.026736753,0.007806351,0.033372153,0.00955581,0.018191585,0.0021397765,-0.063566,0.015431483,0.020240754,0.027531328,-0.04619687,0.039672993,-0.009716119,0.010949802,-0.039338432,-0.021523226,0.057153642,-0.04789754,0.010698883,0.002155459,0.059551306,0.04315797,0.005234437,-3.7463516e-05,0.07817503,-0.009409441,0.010315536,0.00043126606,-0.0031939824,-0.05759972,0.045750793,-0.03027749,-0.023098435,-0.027838005,0.020171054,-0.037470486,-0.008600926,-0.012406522,-0.02074259,-0.013919002,-0.0159612,-0.006032497,0.00046872956,0.008252428,0.0079806,-0.0609453,-0.04614111,-0.061279856,-0.015668461,-0.053557143,0.05255347,0.024143929,-0.0036069525,0.031476323,-0.04271189,0.041206382,-0.008949424,0.009095793,0.018567964,-0.0074160337,0.03055629,0.00011402413,-0.07482945,-0.001193605,0.0048336647,-0.010440995,0.018247345,0.016504856,0.027684666,0.02541246,-0.026346436,0.029413216,0.0036174073,-0.035518896,0.007060566,0.037609883,0.007889991,-0.024715465,-0.045890193,-0.0007954463,0.016379397,0.026694933,0.024506366,-0.010873131,0.04457984,-0.003045871,0.017104274,0.032619394,0.0543099,-0.020352272,0.03802808,-0.020073473,0.0574882,-0.0609453,0.00032148923,-0.009834608,-0.006199776,0.029915053,0.025844598,0.028967138,0.058157317,-0.013863243,-0.0130477585,-0.008057269,0.048817575,-0.01940436,-0.024436668,-0.027865885,-0.01915344,0.027754366,-0.014455689,-0.0016004762,-0.02879986,-0.008970334,-0.018763123,-0.004171519,0.010217956,0.0048266947,-0.017215792,-0.01911162,0.021927483,0.032926075,0.011674677,0.005401716,-0.03997967,-0.035630416,-0.060220424,-0.0074717933,-0.055592373,0.0349613,-0.022094762,-0.0287441,-0.062673844,-0.015459363,0.010029767,-0.018526144,-0.02562156,0.036048613,0.013877183,-0.019460117,-0.046642948,0.0016309698,0.01905586,0.0032601971,0.019724976,0.0074717933,-0.016267879,-0.027935585,-0.053696543,-0.0076390724,0.07488521,0.028339842,0.045611393,-0.03663409,-0.030835086,0.026430074,0.0031364805,-0.031559963,-0.063287206,0.03671773,-0.0037602915,-0.0148738865,-0.0022652359,-0.064959995,0.03306547,0.01121466,-0.031532083,-0.04006331,-0.006196291,-0.015403603,-0.03512858,0.019669216,0.020672891,0.016964873,-0.01768975,-0.022917217,-0.038864475,-0.01739701,0.023182075,-0.03549102,-0.013131398,-0.023335414,0.0022809182,0.035853457,0.0072836042,0.014971466,-0.039533593,-0.027824067,-0.007862111,-0.020421972,0.04335313,-0.02566338,-0.024882745,-0.016978813,-0.048510898,0.015738161,0.026848271,-0.014846007,0.002233871,0.0005575965,0.008224549,-0.021258367,-0.0071651153,0.0048057847,-0.0002500472,-0.04148518,0.021983242,0.029608374,0.02403241,0.0030301886,-0.024116049,0.0027844976,-0.009137613,0.013075638,-0.04485864,-0.0024046348,2.8342674e-05,0.0029692014,0.018665543,0.011625887,-0.0076111923,0.026193095,-0.024882745,-0.0016614633,-0.016504856,0.008113029,0.012155604,-0.050211564,0.02400453,-0.027838005,0.029970812,-0.053640783,-0.013912033,-0.04329737,0.01269926,-0.048650295,0.018372806,0.019641336,-0.01764793,-0.02387907,0.00796666,0.0039240853,0.003127768,-0.03471038,-0.006879347,0.03978451,-0.003993785,0.0032270898,0.00018873335,-0.029887173,0.012037114,0.004464257,-0.024924563,-0.041150622,0.016156359,0.008189699,0.027684666,-0.0036940768,0.029245937,0.002660781,0.030082332,-0.019948015,0.037442606,-0.012211364,0.00016945707,-0.0058129434,-0.024046348,0.02709919,0.0034135361,-0.013863243,-0.01423962,0.045695033,-0.0093606515,-0.005147313,-0.019278899,-0.005481871,0.006231141,-0.011598008,0.015543003,0.011611947,0.0768368,0.025161542,-0.047535103,0.0072278446,-0.042628255,-0.02256872,-0.021286247,0.022945097,-0.012943209,0.07036868,0.018623723,0.040871825,9.861399e-05,0.0077715013,0.031783,-0.0034117936,0.005248377,-0.011549218,0.0021502315,0.0015421029,-0.023363294,0.03484978,0.019334659,-0.025733078,-0.00140706,0.021495346,-0.013096548,-0.007513613,-0.030946607,0.004129699,0.020658951,-0.0009705664,-0.0021728838,-0.018707363,-0.006049922,0.021425646,0.031336922,-0.0077575613,-0.03019385,0.007057081,-0.029441096,0.013298676,-0.0065970635,-0.022945097,-0.006879347,0.020923808,0.02553792,0.0045339568,0.020449853,0.025830658,0.004314403,-0.026555534,0.013563535,-0.019585578,0.00059723813,0.0048336647,0.037916563,0.013702935,0.010210986,0.015849682,0.0047500255,-0.010001888,-0.013326556,-0.04148518,0.013458986,-0.013235947,0.02569126,-0.05575965,0.0011866351,-0.027517388,0.006252051,-0.02531488,-0.01284563,-0.0348219,0.029998692,-0.024924563,0.015333904,0.0020038625,-0.003017991,0.013138368,0.018567964,0.015710281,-0.010664033,0.0012345535,-0.001449751,0.019529818,-0.011939535,0.0058373385,-0.0077924114,0.04778602,-0.041819736,-0.00010324248,0.010190076,-0.0319224,0.022986917,-0.00477442,0.048176337,0.016170299,-0.004290008,0.020324392,0.031169645,-0.030751448,-0.011618917,0.023767551,-0.016435158,-0.028367722,-0.021091089,0.00796666,-0.0043771327,-0.018317046,0.01768975,0.010698883,0.00051185617,0.0056874845,-0.005307622,0.042126417,0.021774143,-0.027252529,0.0035076304,0.018665543,0.008851845,0.048678175,0.018512204,-0.08631594,-0.003045871,-0.020463793,0.0040983343,0.0093606515,-0.0450538,0.046698708,-0.012922299,-0.0048092697,0.025774898,0.002629416,-0.035017062,0.01434417,-0.02708525,0.048427258,0.006513424,0.02708525,-0.031169645,-0.034041267,0.017118212,0.008301218,0.004307433,0.040174827,0.00281412,-0.015347844,-0.004920789,0.016170299,-0.0090679135,0.016658196,-0.01755035,0.037470486,-0.010482814,0.01759217,0.013633234,0.016449098,-0.042321574,0.004784875,0.0044328924,0.00062293984,-0.0072487546,-0.03643893,0.032452118,-0.034626745,-0.027949525,-0.012190454,0.0026991155,0.003035416,0.0048929094,-0.015431483,-0.0476745,0.03340003,-0.0049660937,0.0139747625,0.0127829,0.024534246,0.002775785,-0.04003543,0.020617131,-0.018693423,0.015529063,0.027587088,-0.0063078105,0.04006331,-0.012929269,-0.009047003,-0.038864475,0.0115073975,0.0064332695,-0.037414726,-0.02397665,0.007353304,-0.0042133387,-0.020909868,0.030082332,0.01753641,0.026360374,-0.018540084,-0.005011399,0.017146092,-0.01276199,-0.0014096737,0.057320923,-0.0095349,0.03208968,-0.04000755,0.017187912,0.03013809,-0.0015421029,-0.05294379,-0.031643603,-0.029496856,0.027266469,-0.0015543003,0.040537264,-0.0256355,-0.0055236905,0.002946549,0.0017302916,-0.04625263,0.03340003,0.043827087,-0.028047103,0.002742678,-0.0038892357,-0.002533579,0.0071442053,0.019320719,-0.009402471,0.040565144,0.04970973,-0.012950179,0.0016858582,-0.031615723,0.020143174,0.007883021,0.03802808,0.014176891,-0.0071581453,-0.0063078105,0.008914574,-0.016463038,0.04510956,0.02081229,-0.021244427,0.014595089,-0.027991345,0.0036104373,-0.028423483,-0.008670625,-0.0142675005,-0.03203392,0.009311861,-0.018818881,0.015626643,-0.00044520595,-0.017898848,-0.0018087036,-0.018818881,0.01909768,-0.011667707,0.03546314,0.053557143,-0.00800151,0.008712445,0.012615621,0.0064646346,0.010977681,-0.015055106,0.0053389864,0.0048754844,0.013723844,0.0053320164,-0.037526246,0.02393483,-0.014009613,-0.018107947,-0.008301218,0.00086906645,0.039477833,0.04170822,-0.02555186,-0.05299955,0.030612048,0.014511449,-0.03529586,0.00199515,0.016644256,0.013019878,0.010057647,-0.009876428,0.010008858,-0.007513613,-0.046949625,0.004959124,-0.031587843,0.023628151,0.01912556,-0.011862866,0.03183876,-0.01125648,-0.040146947,0.04494228,0.0020038625,0.027642846,-0.011967415,-0.024436668,0.025983997,-0.024325147,0.03981239,0.0035355103,0.008830935,-0.006060377,0.006029012,0.00081156427,-0.008775175,0.0255658,0.02538458,-0.0019324204,-0.012964119,0.016895175,0.00959066,0.008036359,0.027935585,-0.0015865363,-0.008266368,0.04784178,-0.0065308493,0.018219465,0.002974429,0.016337577,-0.012427432,0.050992202,-0.037944444,0.0078272605,0.0045932014,0.037554126,-0.0049695787,-0.013012908,0.0045722914,-0.018428564,0.023809372,-0.006360085,-0.0063566,-0.02047773,0.012274093,-0.022861456,0.012169544,0.013340496,-0.024060288,-0.0012197423,-0.03030537,0.038697198,0.013333526,0.030862967,0.017201852,-0.0017154805,-0.037721403,0.023363294,-0.02562156,0.015013286,0.0037045318,-0.010475844,-0.009346711,0.018930402,-0.032563634,0.0013025106,0.040732425,-0.0055062654,0.0075972523,0.024269387,-0.035881337,0.040565144,0.005307622,0.014706608,-0.0059941625,-0.032563634,0.014985406,-0.012078934,0.019278899,-0.010503724,0.044747118,-0.021676565,0.026276736,-0.019292839,-0.0139538525,-0.01108223,0.0017668839,0.0071511753,0.019251019,0.0027479052,0.009876428,0.007186025,0.039310552,0.005610815,0.012608651,-0.0040599997,0.033149112,0.0015168367,-0.012615621,0.031141765,0.011897716,-0.028005285,0.06233929,-0.006175381,-0.0151945045,-0.016881235,0.018986162,0.027935585,0.02383725,-0.0011944763,0.010998591,-0.0070048063,-0.016337577,-0.025133662,-0.0023297078,0.002476077,-0.008356977,-0.026248856,0.04510956,0.027656786,0.032507878,-0.013026848,-0.01774551,0.0056561194,-0.05478386,-0.00956278,0.021704445,0.048566654,-0.04009119,-0.032284837,-0.023642091,0.006213716,-0.02871622,0.014016583,0.014183861,-0.013479896,-0.018958282,-0.03052841,-0.020449853,-0.043520406,-0.0044050124,0.005433081,-0.012971088,-0.007896961,0.010127347,0.032814555,-0.0020979568,0.029468976,-0.012288033,0.022694178,-0.0047047203,0.011388909,0.01918132,-0.020631071,-0.024297267,0.06518303,0.0033124718,-0.01272714,-0.006049922,-0.011946505,-0.022066882,-0.025217302,-0.007116325,-0.0050601885,-0.0224572,0.038725078,0.0133614065,-0.014316291,0.010608274,0.019237079,0.019543758,-0.022108702,-0.06406784,0.055118416,0.0047465404,0.012385612,-0.012288033,-0.0077296817,-0.0048023,0.015640583,0.01108223,-0.027712546,-0.034041267,0.002871622,-0.03716381,-0.013723844,0.012155604,0.021941423,0.011061321,0.02737799,0.005861733,0.005729304,0.0015621415,-0.004161064,0.0061196215,0.0063217506,-0.0011892488,0.00015769526,-0.019711036,-0.018888582,0.028576821,0.013486866,0.031392682,-0.035602536,-0.02081229,-0.036104374,0.015278145,0.015807861,-0.027447687,0.014720548,-0.026653113,0.00014822048,-0.024785165,0.01760611,0.04326949,-0.012629561,-0.024715465,0.029134417,0.039422072,0.01604484,0.039031755,0.005464446,0.0042028837,0.006900257,0.015431483,0.00046480895,0.017494591,0.0047116904,0.010503724,0.011695587,0.0192092,-0.0014340685,0.010099467,0.012078934,0.003288077,0.018261285,-0.001439296,-0.00562127,0.025175482,-0.01278987,0.04176398,-0.026569473,0.014776307,0.018512204,0.018400684,-0.029915053,-0.0136680845,0.007032686,0.003195725,-0.041178502,0.0022077337,-0.010622214,0.009263072,-0.01434417,-0.01732731,0.012643501,-0.031615723,0.009764909,-0.01591938,-0.0043980423,-0.018888582,0.016769715,0.0099879475,9.115396e-05,0.011472548,0.021509286,-0.026304616,0.012002265,0.096798755,-0.00478836,0.018247345,0.021481406,0.03708017,-0.021648685,-0.03055629,-0.027433747,-0.026262796,-0.018163707,0.0351007,-0.039589353,0.009785819,0.0050567035,0.025872478,0.0055027804,-0.009123673,-0.016811535,0.023154195,-0.003965905,-0.018094007,0.00037311047,0.018763123,-0.0011918625,0.0055341455,-0.012971088,-0.025802778,-0.040899705,-0.002885562,0.035602536,-0.0005453991,0.03880872,0.038697198,-0.01760611,0.0045130467,-0.01738307,-0.0023436479,-0.015584823,0.021244427,-0.012260153,-0.0020578797,0.021620804,-0.024297267,0.020603191,0.00797363,0.031002365,0.020421972,-0.012364702,-0.007325424,-0.0059837075,0.021425646,-0.0105873635,0.0127829,0.013131398,-0.007206935,-0.032814555,0.0022826607,-0.015612702,-0.035937093,0.011291329,-0.032340597,0.03022173,0.026639173,0.0007902188,-0.011061321,0.013389286,-0.042405214,0.004147124,-0.018163707,0.010873131,-0.020087413,0.021634744,-0.018623723,0.013981733,-0.0044921366,0.021202607,-0.034543104,-0.0006464634,0.010552514,-0.018094007,0.015152685,0.01766187,0.017884908,-0.0133474665,-0.0011047381,-0.014330231,-0.008872755,0.009486111,-0.033873986,0.008140909,-0.011604977,0.01437205,0.01114496,-0.006893287,0.0346825,0.020993508,-0.018679483,0.018972222,0.0256355,0.0030319311,0.015027226,-0.00636357,-0.003519828,0.0035964975,-0.0035146005,0.0142675005,0.0035668751,-0.003321184,-0.023516633,-0.03529586,-0.0069281366,-0.010935862,-0.004485167,-0.02850712,-0.009088823,0.016588496,-0.00089738186,0.009270042,0.019306779,-0.027726486,0.013417166,0.032284837,0.02557974,-0.005084583,0.028298022,-0.023014795,0.021620804,0.057990037,-0.03671773,-0.010726763,0.021369886,0.013800514,0.011040411,0.01281775,0.015069045,0.034013387,-0.013082608,-0.0026886608,-0.027726486,-0.018038247,-0.00564218,0.06233929,-0.02707131,0.022052942,0.0015194505,-0.018205525,-0.042544615,0.011918625,0.017146092,0.0011753088,-0.0075624026,0.007883021,0.029636255,-0.00086122524,-0.019585578,0.0077018016,0.006872377,-0.011416788,0.022722058,-0.021523226,-0.01121466,-0.018414624,-0.035686176,0.0062834155,-0.01593332,0.001346944,0.014121132,-0.0013608839,-0.011521338,-0.0076948316,-0.015375724,-0.0026311586,-0.011667707,-0.006265991,0.00562824,0.01764793,-0.033929747,0.016086658,-0.04338101,-0.016323637,-0.030974487,0.006245081,-0.011869836,0.0011483004,0.02389301,-0.016895175,-0.0115004275,-0.010698883,0.028604701,-0.023642091,-0.009806729,-0.021927483,0.014790247,0.03808384,0.0025997937,0.04343677,0.018386744,0.028381662,-0.0074369432,0.01764793,-0.035741936,-0.006091742,-0.011549218,0.013751724,0.0077436217,0.051884353,-0.008642746,-0.01111708,0.019850435,0.017494591,0.00798757,0.006088257,-0.015668461,-0.023056615,0.04628051,0.04170822,0.03808384,0.020979568,0.025900358,0.013326556,0.024924563,0.021383826,-0.015710281,-0.013912033,0.016323637,0.019000102,0.01281775,0.0015447165,0.011402848,-0.0034501285,0.03348367,0.05433778,0.014999346,0.026360374,0.0051891324,-0.0045269867,-0.0008276823,-0.0069072265,0.0033682315,0.02075653,-0.023600273,-0.0045444113,-0.0037254416,0.008203639,-0.034598865,-0.009444291,0.009207312,-0.0054435357,-0.048148457,0.0007684377,-0.027963465,-0.015069045,0.039031755,-0.021244427,0.010845252,-0.021704445,-0.0025300942,-0.02850712,0.006499484,-0.0142675005,-0.043799207,-0.005485356,0.018972222,0.013068669,-0.021300187,-0.006569184,-0.0010472359,0.006809647,-0.0124344025,0.006495999,0.005893098,-0.011988325,0.020589251,-0.021049269,0.023432992,0.019711036,-0.01753641,0.007492703,0.0021920511,0.01940436,0.009932187,0.069365,0.0045792614,-0.031559963,-0.048510898,-0.028270142,0.018804941,0.013842333,-0.0044259224,0.008921544,0.0062938705,-0.01276199,-0.012078934,-0.00044041412,0.007339364,0.041150622,0.028939258,-0.011786196,-0.022959037,-0.010008858,0.007325424,-0.011883776,0.011834986,0.015752101,0.0010420085,0.00015932885,0.024729405,0.02397665,0.01746671,0.0032514846,0.019264959,0.028660461,-0.000539736,0.02399059,0.009283982,0.0011169355,-0.0045827464,0.037414726,-0.004927759,0.029831413,0.017201852,0.0010968968,0.011807106,-0.02850712,-0.042349454,-0.007213905,-0.043687686,0.004910334,-0.020268632,-0.019948015,-0.02256872,-0.02714101,0.0048998795,0.0024969869,0.01117284,0.0031364805,-0.008489407,0.037609883,0.020268632,-0.009095793,-0.0025266092,-0.006572669,0.024171809,-0.0016414247,0.015668461,0.030389009,0.0005440922,-0.01738307,0.011465578,0.017299432,-0.009242162,0.00632872,0.0054923254,0.0076111923,-0.0023663002,0.01124951,0.02562156,-0.0053703515,0.0139677925,0.015779981,-0.023753611,-0.027419807,-0.0010550772,0.034320064,0.020923808,0.019641336,0.004917304,-0.030639928,0.0052832267,-0.036271654,-0.0021537165,-0.003099888,-0.008628806,-0.018289166,0.0320618,0.02562156,-0.014497509,-0.008991243,0.027308289,0.0027531327,-0.009388532,-0.02401847,0.02074259,0.023600273,0.010970712,0.004300463,0.027280409,-0.008280308,-0.0011779226]	619
9	3	Please inform staff of any allergies 🕌 **Halal-friendly options** — Pork-free alternatives available --- *Menu prices are subject to change. All prices are in Malaysian Ringgit (RM) and inclusive of SST.* **Follow us @bonnebouche.kluang for daily specials and promotions!**	3	2025-12-21 23:53:08	2025-12-21 23:53:08	[-0.042857945,-0.00026887975,0.0136263715,-0.014866271,-0.0071826507,-0.024685275,0.005025351,0.04012766,-0.0028790093,0.018961698,-0.03196186,-0.038624752,0.0051725106,0.03391564,-0.0142525835,0.04067873,-0.015029087,0.013989575,-0.01604355,0.047767445,0.04834356,0.023971394,-0.0011115262,0.033690203,-0.004436712,0.029381864,-0.0034191173,-0.042682607,0.03476729,0.023069648,0.041931152,-0.041204747,0.03353991,0.0092115775,-0.048068028,-0.021266157,0.010263613,-0.0073705143,0.04000242,-0.019024318,-0.037071746,0.02715255,0.039726887,0.014553165,0.0013181762,0.022556154,-0.04541289,-0.0038981694,-0.0145656895,0.009067548,0.012837345,-0.0011303126,-0.029732542,-0.020276742,0.028004197,0.0032312537,0.0012899966,0.010745797,0.06257109,0.038098734,0.024622653,-0.02248101,0.0052163457,-0.03306399,-0.009712547,-0.029006137,-0.01702044,0.045287646,-0.01988849,0.052902386,0.019963637,-0.03571913,-0.034466706,0.016669761,0.0025126755,-0.014240059,0.016820053,0.01114031,0.044987068,-0.0026942769,-0.02945701,0.030383803,-0.011954386,0.02271897,0.056860045,-0.015893258,-0.09232869,0.014290157,-0.017245878,0.04027795,0.0037009125,-0.018360535,-0.010407642,-0.0032782196,0.023495471,0.005923965,-0.044511143,0.018961698,-0.042908043,0.05230122,0.03389059,-0.08291046,-0.0067881374,-0.03389059,0.037948444,-0.012787248,0.03574418,0.011829143,0.0005902047,-0.012887442,-0.03293875,-0.024046538,-0.027428083,0.064725265,-0.0023983917,-0.0012641654,0.02319489,-0.026025368,0.026200708,-0.055507425,0.009963032,0.018498302,0.033013895,-0.050597925,-0.07369262,-0.019036843,-0.056008395,0.02682692,0.0091552185,-0.086818025,0.01636918,-0.034116026,0.028505167,-0.026376046,0.016344132,0.014816174,0.013250644,0.03832417,-0.040303,-0.012862394,0.04884453,0.006431197,-0.018197719,-0.013889381,-0.05380413,-0.04801793,-0.045638327,-0.008723132,-0.019813346,0.0624709,-0.04506221,0.019450143,-0.0011083952,-0.042882994,-0.02567469,-0.044285707,0.036921456,0.029156428,-0.0329137,0.020214122,-0.009086335,0.04982142,0.0016171923,-0.047817543,0.030784579,-0.018185195,-0.0022105281,0.023207415,-0.025336536,-0.04694085,0.053253062,0.029907882,0.03769796,0.005244525,-0.0053822915,-0.0039013005,0.07584679,-0.03243778,-0.021904893,0.0067943996,0.05670975,0.040052515,0.040578533,0.019111989,-0.008522744,0.026025368,-0.022443436,-0.04148028,-0.008147017,0.040227856,0.010407642,-0.002803864,0.021090819,-0.04704104,0.013551227,-0.039952323,0.0030339968,-0.01908694,-0.009180267,0.032011956,0.0019960506,-0.017333547,0.04739172,-0.017571507,0.017045489,-0.013638896,-0.00029764636,0.020690043,0.056960236,-0.037547667,0.07213961,0.046640266,0.00069313834,0.045813665,0.028279731,0.040703777,-0.028004197,-0.0060617314,0.015918307,-0.023182366,0.029181477,-0.0074769706,0.06362313,0.020126453,-0.012699578,-0.021917418,0.010777107,0.037547667,0.0001998986,-0.03569408,-0.008034299,-0.0069509526,-0.02030179,0.050948605,-0.015229475,0.0106957,-0.025248865,-0.036570776,-0.016356656,-0.06823205,0.038249027,0.0085290065,0.0044241874,0.061118286,0.040403195,-0.0036946505,-0.0033815445,-0.04901987,0.0048374874,-0.015442386,0.0145656895,-0.006806924,0.020439558,-0.055908203,0.025574496,-0.02978264,-0.049470745,-0.0160185,0.031836614,-0.022368291,-0.024084112,0.021529166,0.036270194,-0.032237392,0.01702044,-0.019011794,0.020765187,0.032988846,0.0012508583,-0.0023889986,-0.026250804,-0.032838553,0.015530056,-0.017596556,-0.028430022,-0.00797794,-0.016569568,0.01628151,0.008190853,0.0189116,-0.06723011,-0.06968486,0.0054198643,-0.090274714,-0.019926064,-0.0011263987,0.06106819,-0.018059952,0.010601768,0.029181477,0.025774883,-0.030609239,-0.029256621,0.0108084185,-0.00056085107,0.034191173,-0.0047372933,-0.029757591,0.029907882,0.036119904,-0.021366352,0.013751614,-0.052501608,-0.0176717,0.025749834,0.0012516411,-0.04178086,0.04689075,-0.002904058,0.010006866,-0.06267129,-0.022706445,0.025950223,-0.06848254,0.022581203,0.039451353,0.042832896,0.046189394,0.00800925,0.0036602088,0.07749999,0.0032844816,0.021904893,-0.006196367,0.012223657,-0.05134938,0.07053652,-0.001168668,-0.049971715,-0.011015068,0.0148787955,-0.0041298675,0.0094683245,0.0024312679,-0.051549766,0.035067867,-0.0035788012,0.01563025,0.022731494,0.020013733,-0.017233353,-0.04937055,-0.022706445,0.0035788012,0.02030179,-0.026626531,0.04739172,0.022593727,0.023595667,0.054355197,-0.013889381,0.03421622,-0.019099465,-0.011102738,-0.02112839,-0.012123463,0.039701838,0.047216382,-0.03045895,0.032813504,-0.011152835,-0.04067873,0.006982263,0.0151919015,0.055808008,0.0008140755,-0.018899076,-0.0054793544,0.006600274,0.00049862126,-0.013375887,0.044636387,-0.0071826507,-0.02541168,-0.031686325,0.026726726,0.011710163,-0.0023811709,0.021441497,-0.01965053,0.00066613295,-0.013989575,0.04263251,-0.009562257,0.014916369,-0.015317144,0.021353828,-0.018022379,0.059164505,-0.043784738,0.037422426,0.00217139,0.03489253,0.016056074,-0.031510986,-0.0050691855,0.017095586,0.01430268,-0.0155926775,0.0042363238,0.008303571,0.02452246,-0.039075624,0.02682692,-0.010338759,0.02476042,-0.048268415,0.029431961,-0.0312605,0.021817224,-0.027027307,-0.023032075,-0.0034911316,0.001142054,0.018686164,-0.03977698,0.004032805,0.002827347,0.018560922,-0.030784579,0.004721638,0.0030809627,-0.043734644,0.02517372,-0.03917582,0.03045895,-0.047692303,-0.036295243,-0.018711213,-0.015993454,-0.01950024,-0.03143584,-0.100594684,0.0015999716,-0.028104391,-0.042006295,-0.048769385,0.0246978,0.0076147374,0.011685114,0.010720748,0.029056234,0.021929942,-0.036170002,-0.023507996,0.014290157,0.044486098,0.043283768,0.016682286,-0.052050736,-0.049470745,0.012693316,0.01752141,-0.004039067,-0.0014661187,0.019061891,0.0130001595,0.010720748,0.015517532,-0.04849385,0.03326438,0.029081283,0.0097250715,-0.034792334,-0.021103343,-0.02301955,-0.039401256,0.014352778,0.01861102,-0.0068945936,-0.005451175,0.004471153,-0.01678248,-0.0028711818,0.0024531854,-0.032487877,-0.009192791,-0.054555584,-0.012029531,0.028354876,-0.015016562,-0.009318033,-0.018147621,-0.057811886,-0.008591628,-0.016594617,0.07950387,-0.0013377452,-0.022293145,-0.0001885485,-0.068382345,0.029632349,-0.0071576023,-0.012580598,-0.006468769,-0.011653804,0.0136263715,-7.172084e-05,0.010745797,0.004239455,0.0031107077,-0.029431961,-0.017333547,0.046765506,0.01007575,0.039075624,-0.02177965,-0.031360693,-0.039125722,0.036144953,-0.050597925,-0.033339523,-0.0056421696,-0.009167743,0.030784579,-0.015467435,-0.013225596,0.0050535304,-0.042732704,0.019337425,0.005723577,0.019988686,0.028404973,-0.05164996,-0.021353828,-0.011353223,0.014177438,-0.052501608,0.013926954,-0.048969775,0.03045895,-0.03965174,0.025875077,0.011428368,-0.019550337,-0.026075466,-0.013901905,-0.03421622,-0.011453416,-0.039401256,-0.0043083383,0.020013733,-0.009330558,-0.007082457,0.008034299,-0.039025526,-0.020026257,-0.0044868086,-0.012737151,-0.007295369,0.020264218,-0.010432691,0.0042175376,-0.0018191456,0.027603423,-0.007195175,-0.001088826,-0.02065247,0.029056234,0.023883723,-0.002168259,0.006625322,-0.025273914,0.010827204,0.0041110814,-0.017358596,0.0052664424,0.015730444,-0.06332255,-0.029381864,-0.011904289,0.03421622,0.01760908,-0.0304339,0.023244986,0.00018571097,0.010476526,-0.00060977385,-0.008128231,-0.008591628,-0.022894308,0.0090425005,-0.0092115775,0.009224102,-0.011334436,0.052601803,0.0460391,0.048769385,-0.019187134,0.020727616,0.02156674,-0.008078134,0.024785468,0.0033658892,0.005817509,0.0017142552,-0.025511874,0.04060358,0.0065940116,-0.019550337,-0.032963797,0.034116026,-0.004906371,-0.0069321664,-0.028354876,0.026300902,0.007702407,0.00930551,0.032863602,-0.011152835,-0.005817509,0.038374268,0.02321994,0.018235292,-0.046690363,-0.0022919357,-0.0460892,0.012862394,-0.03504282,-0.00070879364,0.017220829,0.032462828,0.015818113,-0.020164024,-0.027252743,0.015943356,0.003356496,0.0052758357,0.026977211,-0.018135097,-0.01982587,-0.004145523,0.017258402,0.0062057604,0.012129725,0.012950063,0.022656348,-0.0068319724,0.006118091,-0.027904004,-0.017596556,-0.0056171212,0.031385742,-0.07935358,-0.0028743127,-0.01663219,0.023157317,-0.033640105,0.009023714,-0.033013895,0.029256621,0.0025831242,-0.0095246835,-0.008222163,-0.001778442,0.031636227,0.0025580758,0.016644713,0.003353365,0.01841063,-0.013112878,0.029932931,-0.0051631173,0.0046496238,0.019162085,0.062170323,-0.016168792,0.0031592392,0.03571913,-0.05575791,0.030984966,0.035643984,0.064224295,-0.005335326,0.02508605,-0.002724022,0.012449093,-0.020477131,-0.008572841,0.013300742,-0.02245596,0.007952891,0.0070574083,-0.015241998,-0.015517532,-0.017308498,-0.0010903915,0.0024766682,-0.00070292293,-0.004189358,-0.0047435556,0.003888776,0.042657558,-0.03885019,0.0066816816,0.048594046,0.027453132,0.044861823,-0.0034942627,-0.060266636,0.040403195,-0.034642044,0.03243778,-0.0126870535,-0.013012684,0.01578054,0.018310437,0.009004927,0.011747736,0.00189116,-0.0084162885,0.021015672,-0.0038856452,0.04546299,-0.0021432103,0.0056985286,-0.03424127,-0.039526496,0.01669481,-0.013137926,0.011885502,0.028254682,0.017095586,-0.018723737,-0.0035975876,0.039952323,0.007013574,0.004045329,0.036295243,-0.00034950455,-0.0019083809,0.00871687,-0.0144529715,0.009787693,-0.021454021,-0.000865738,0.007489495,0.0008837416,-0.0193249,-0.052000638,0.010507836,-0.011960648,-0.02417178,-0.010983758,-0.0209781,0.011685114,-0.001535002,-0.00789027,-0.040102612,0.033665154,-0.014089769,0.009687499,0.032112148,0.034141075,-0.0015858817,-0.044310756,-0.0029353686,-0.005942751,0.0067505646,0.044786677,0.0051412,0.055056553,-0.019099465,-0.017533934,-0.0031310597,-0.0008078134,0.00599911,-0.035944566,-0.022756541,0.0037854512,0.02038946,-0.039751936,0.011065165,0.02682692,0.031611178,-0.0037009125,-0.027202647,0.01671986,0.021028196,-0.0044241874,0.03719699,0.0071576023,0.044385903,-0.030684385,-0.010532885,0.02928167,0.010269876,-0.021191012,0.002697408,0.016531995,0.011566134,-0.004032805,0.018473253,-0.046114247,-0.018122574,0.038223978,-0.018460728,-0.03817388,0.003509918,0.028254682,-0.022919357,0.0023248119,0.02730284,-0.008203376,0.059665475,0.03877504,0.00883585,0.056008395,0.051148992,-0.0071450784,0.004086033,-0.008535269,0.012060842,0.030709434,0.04163057,0.005707922,0.015993454,-0.016481899,0.010357546,0.003459821,0.06637847,0.011584921,0.005410471,0.0006367793,-0.027503228,0.0022762804,-0.04799288,-0.035117965,-0.019575385,-0.03717194,-0.017584031,-0.021015672,-0.00091740047,-0.0027146288,0.0058456883,-0.014828699,-0.017947234,0.022092758,0.019374998,0.0045494298,0.0039044314,0.00022152247,-0.018861504,0.024271974,-0.01861102,0.032713313,-0.012987636,-0.009048763,-0.016594617,0.04145523,-0.0052163457,-0.02730284,-0.0015623987,0.008190853,0.015041611,-0.0052069523,-0.00089156925,0.026000319,0.011221718,-0.035919517,-0.045838714,0.006331003,0.011033854,-0.024297023,-0.0038104996,-0.018398106,0.014440447,0.0011310953,0.0070574083,0.03421622,0.024534984,-0.0009964597,-0.021892369,0.0050691855,0.011735212,0.028404973,-0.008798278,0.031060113,-0.010307449,-0.04506221,0.049170163,0.007088719,0.03672107,0.01934995,-0.0062245466,0.049746275,-0.022631299,0.043809786,-0.004718507,-0.0141398655,0.018398106,0.010795894,-0.0089861415,-0.0038981694,0.022443436,-0.005294622,-0.016669761,0.004092295,0.0021948728,-0.018949173,-0.011829143,0.037898347,-0.013062781,-0.01547996,0.044811726,-0.000865738,0.0030778316,0.01687015,0.027653519,-0.005491879,0.049796373,-0.010939922,-0.013501129,-0.024572557,0.0106957,-0.02023917,-0.006863283,0.0054824855,-0.01702044,0.014240059,0.0075709024,0.011991959,-0.047441818,0.015555104,0.0296073,-0.0069947876,0.032037,-0.011472203,0.0039795768,-0.02278159,0.0160185,0.017621605,0.020752663,0.03732223,0.0111215245,-0.018661115,0.030659337,-0.0040077562,0.010332497,0.0022199214,0.013338314,0.009756382,0.016882675,-0.033514865,0.047266476,0.03476729,-0.020702567,0.010257351,0.017947234,-0.015993454,0.009950507,-0.0024876269,0.023232464,-0.023971394,0.00051897316,-0.005144331,0.0057893293,0.0020351887,0.011553611,0.012975112,0.004928288,0.006334134,0.018498302,-0.011766522,0.021403924,0.017508887,0.04310843,0.01102133,-0.0045494298,0.0002610521,0.005357243,0.021203537,-0.0052476563,0.022005087,-0.016582092,0.010964971,0.023733433,0.000706054,0.016306559,0.017972283,-0.03404088,0.05034744,0.019838395,-0.0053697675,-0.02198004,0.04097931,0.026075466,0.03028361,-0.017170731,0.0091552185,0.0070010494,-0.0013541833,-0.006024159,0.019199658,0.0017627866,-0.013225596,-0.02410916,0.04754201,0.044511143,-0.012424045,0.0023655156,-0.025925174,0.0032375157,-0.045838714,-0.016882675,-0.007195175,0.048594046,-0.024585081,-0.03536845,-0.046840653,0.0023827364,0.0092115775,0.02517372,0.025749834,-0.030383803,-0.013263169,0.0019021188,-0.011785309,-0.015342193,0.012987636,0.0049157636,0.00508171,-0.0077525037,0.009718809,0.0063278717,-0.011052641,0.028154489,-0.014039672,0.040528435,0.009180267,0.0060711247,0.019061891,0.012743413,-0.016469374,0.023507996,-0.008647987,-0.0089861415,-0.018009854,-0.011622493,0.010363808,-0.0493455,0.004749818,-0.008121969,-0.013225596,0.009731334,-0.0106080305,-0.034642044,0.01365142,-0.0073141553,-0.009975556,0.006700468,-0.035819322,0.014265108,0.014127341,0.024960808,0.013638896,-0.029682446,-0.03075953,-0.024509935,-0.005300884,0.006021028,-0.009174005,0.011065165,-0.025148671,0.009656188,0.0046965894,0.0058362954,0.00913017,0.007602213,-0.021817224,-0.0017440002,-0.00270367,-0.013989575,0.019024318,-0.0077525037,0.022105282,0.0033314475,-0.0017518279,-0.034667093,0.016118696,0.022831688,0.02732789,-0.006443721,0.034441657,-0.03028361,0.001991354,0.03819893,0.0048594046,-0.016807528,-0.0029619825,-0.0035224422,-0.0050942344,0.003932611,0.033189233,-0.009718809,-0.049545888,0.02352052,0.049570937,0.011534824,0.030058173,0.014703456,0.0029572858,-0.016644713,-0.00032426036,0.03338962,-0.03424127,0.003888776,0.009505897,0.02665158,0.014640835,-0.0076710964,0.022681396,0.026125561,-0.013350839,0.009080073,0.011591183,-0.0008038996,0.03950145,-0.030483996,0.030834677,0.010457739,0.009048763,0.020777712,-0.033990785,0.0042864205,-0.033815444,-0.016569568,0.02271897,-0.02682692,-0.03504282,-0.009430752,-0.015818113,-0.010777107,-0.013839284,-0.0024891924,-0.020351889,0.019863443,-0.011290601,0.039927274,0.0015475262,0.013288218,0.028329829,-0.007896532,0.023082172,0.026075466,-0.016181316,0.012067104,0.08160794,0.014352778,0.010908612,-0.008497696,-0.0046621477,-0.022268096,-0.016394228,-0.00039647042,-0.004565085,0.007345466,0.012405259,-0.015166854,-0.012874917,0.013162975,0.012092153,0.028505167,-0.023583142,0.005413602,0.019988686,-0.011991959,-0.00732668,0.018836455,0.015029087,-0.017408691,0.002337336,-0.008428813,-0.020589849,0.014928892,-0.012712102,0.015843162,0.018686164,0.037096795,0.028855845,-0.036645923,-0.017120635,-0.030884773,-0.02089043,0.009318033,0.00773998,-0.014778602,-0.005401078,0.0040202807,-0.013701517,0.03191176,0.029131379,0.02541168,0.010526623,-0.016419277,0.00540734,-0.0106080305,0.048118126,-0.03010827,0.005078579,0.02434712,0.0059897173,0.017145682,-0.026751773,-0.025900126,-0.04441095,-0.008140755,-0.0050159576,0.012017007,0.058964115,-0.013851808,0.011215456,0.022756541,-0.06497575,-0.00014989948,0.0053885537,0.028455071,-0.01048905,0.032863602,-0.020815285,0.02895604,0.015918307,0.013501129,-0.03421622,0.017233353,-0.008353667,-0.011960648,0.0023764742,0.016481899,0.02301955,-0.017471313,-0.008247212,-0.014515593,-0.029757591,0.0034379035,-0.035493694,0.0045963954,-0.012724627,0.035443597,-0.017621605,-0.029081283,0.008616677,0.026050417,-0.0139394775,0.018185195,0.012630695,-0.0047372933,0.009255412,-0.019299852,0.008885947,0.0031874187,-0.030834677,0.0033439717,0.01196691,0.0008485172,-0.0151919015,-0.05811247,0.0065251286,-0.026877016,0.0047779973,0.0017565244,-0.0046590166,0.016807528,-0.017533934,0.0042112754,0.03243778,0.010883563,0.020865383,0.030509045,0.0073204176,0.017083062,0.00526018,-0.009274199,0.025549447,0.06758079,0.01917461,-0.0051725106,0.018573446,0.011472203,0.008760705,0.0035349664,-0.0033690203,0.034566898,-0.019838395,-0.002650442,-0.052100834,0.0083849775,-0.012023269,0.032162245,-0.019287327,0.011403319,-0.01373909,-0.012730889,-0.020877905,0.019713152,0.010708224,-0.004630837,-0.02484809,0.014991513,-0.011991959,-0.010683176,0.0077900765,0.022668872,0.025186244,-0.007345466,0.018936649,0.010445215,-0.01102133,-0.013062781,-0.026451193,-0.0016594616,-0.010482788,-0.0077337176,-0.0074581844,0.0014034975,0.0102385655,-0.0058582127,-0.035669032,0.004574478,-0.016970344,-0.017508887,-0.009148956,0.011941861,-0.040553484,0.04295814,-0.011246767,-0.011046379,-0.04067873,-0.012142249,0.021328779,0.007896532,0.0047529484,-0.014402875,-0.0031827223,-0.0058519505,0.028179538,-0.009775168,-0.009756382,-0.026225757,0.026952162,0.036395438,-0.0064750314,0.0131755,-0.0040735085,0.02585003,0.00025107185,0.0108647775,-0.028505167,0.015354717,0.011797833,0.0010903915,0.0009518422,0.0141398655,-0.01125929,-0.029907882,-0.021115867,0.011209194,0.039726887,0.0080155125,-0.006725516,-0.024422266,0.014402875,0.042732704,0.004790521,0.05415481,-0.012730889,0.0005823771,0.044310756,0.03028361,0.003519311,-0.012937538,0.022418387,0.010207254,-0.008873424,0.017408691,0.003948266,-0.019299852,0.053603742,-0.0045807404,0.024484888,0.0027913398,0.036420487,0.016143743,-0.01663219,0.0053290636,0.0017940972,-0.0042206687,-0.012624432,-0.012693316,-0.00851022,0.027377985,-0.0054793544,-0.0085290065,0.012267492,-0.008735657,-0.05906431,-0.02860536,-0.0140521955,0.0012242444,0.021378875,0.009449538,0.018723737,-0.037397377,-0.0021698244,-0.026300902,0.018836455,-0.02928167,-0.015893258,-0.017308498,0.0427828,0.011985697,-0.00658775,-0.0018144491,0.029907882,-0.016381705,0.010708224,0.0057955915,0.017321022,0.007971678,0.027277792,-0.036170002,0.0013580972,0.021691982,-0.025211293,0.024810517,0.013400936,0.027678568,0.018949173,0.016444325,0.013162975,-0.03672107,-0.036946505,-0.01858597,0.025875077,0.00608678,-0.013901905,-0.00066691573,-0.012818558,-0.012129725,0.018335486,-0.0141398655,0.017659176,0.0033471028,0.025061002,-0.0028398712,-0.01858597,0.0070511466,0.011240505,-0.026701678,0.045287646,0.015467435,0.021165963,0.027929053,0.016845101,0.027753713,0.016557043,0.017659176,0.03303894,0.0054856166,-0.0053760293,0.020452082,0.0095246835,-0.015241998,0.020452082,0.021328779,-0.013701517,0.043534253,0.04390998,-0.0038605966,0.014753553,-0.02632595,-0.022030136,-0.024447314,-0.026125561,-0.02213033,0.019638006,-0.021491595,-0.01595588,-0.012849869,0.036470585,0.0036508157,0.005335326,-0.00056633045,-0.008779491,-0.012480404,0.006186974,-0.008973617,0.007188913,-0.015454911,0.013901905,-0.008503959,0.010946184,0.018160146,-0.022631299,0.0021901762,0.01160997,0.0049032397,-0.001734607,0.016005978,0.020126453,0.0031294941,-0.011785309,0.011146572,0.005473092,0.0003101706,0.0057955915,0.017796943,-0.0209781,-0.031836614,-0.021554215,0.03814883,0.03687136,0.022894308,-0.04393503,0.014215011,0.020702567,-0.033013895,-0.0126870535,-0.006255857,-0.012618171,-0.012305065,0.028830798,0.011065165,0.001754959,0.0035255733,0.012273754,0.005783067,-0.027528277,0.017496362,0.000955756,-0.0017565244,0.007170127,-0.0006590881,0.019951113,-0.0142525835,0.007351728]	70
10	4	================================================================================ BONNE BOUCHE CAFÉ - QUICK REFERENCE CARD ================================================================================ LOCATION -------- Bonne Bouche Café No. 15, Jalan Delima 2/3 Taman Kluang Utama 86000 Kluang, Johor Malaysia OPERATING HOURS --------------- Monday - Thursday : 9:00 AM - 10:00 PM Friday : 9:00 AM - 11:00 PM Saturday : 8:00 AM - 11:00 PM Sunday : 8:00 AM - 10:00 PM * Kitchen closes 30 minutes before closing time CONTACT ------- Phone : +60 7-772 8899 WhatsApp : +60 12-772 8899 Email : hello@bonnebouchecafe.com.my Facebook : facebook.com/bonnebouchekluang Instagram : @bonnebouche.kluang QUICK FACTS ----------- > Cuisine : Western & Malaysian Fusion > Price Range : RM15 - RM50 per person > Seating : 50 pax (indoor) + 20 pax (outdoor) > Parking : Available nearby > Payment : Cash, Credit/Debit Cards, E-Wallets (TnG, GrabPay, DuitNow) HIGHLIGHTS ---------- [✓] Free Wi-Fi [✓] Air-Conditioned [✓] Halal-Friendly Options [✓] All-Day Breakfast [✓] Takeaway Available [✓] Private Events Welcome DIRECTIONS ---------- From Johor Bahru : ~110 km via North-South Expressway From Batu Pahat : ~50 km via Federal Route 50 Landmark : Opposite Kluang Mall, next to CIMB Bank ================================================================================ Save this card for easy reference! ================================================================================	0	2025-12-21 23:53:14	2025-12-21 23:53:14	[-0.04567936,-0.0032537482,0.0048549427,-0.035190027,-0.01639865,-0.05776385,0.0009493875,0.025764126,0.005507505,0.0039516273,-0.010646434,-0.06975166,-0.0044773025,-0.0007443289,-0.01812673,0.07511717,-0.05776385,0.024918213,0.014876003,0.06849487,0.028978601,0.028205194,0.0029894,0.0113412915,0.004613253,0.017329155,-0.04596939,-0.022984695,0.017014958,-0.011963642,0.0059788,-0.027600968,0.035141688,0.018114647,-0.02992119,-0.029002769,0.019057237,0.030090373,-0.013558795,-0.037824444,-0.020712811,-0.022066273,0.056362048,0.028350206,0.004909323,0.00047809252,-0.056652077,-0.002259799,-0.022356302,0.049594734,0.00996366,0.0074259173,-0.063902766,-0.005531674,0.01650741,-0.0356009,-0.011812586,-0.004516577,0.09522576,0.05612036,0.033570707,-0.0282777,0.0181509,0.005555843,-0.026102493,-0.03864619,-0.0074319597,0.022078358,0.014839751,0.04072472,-0.007770325,0.013462119,-0.01389716,-0.014948511,0.03775194,-0.034513295,0.018549688,-0.021123683,0.0042084227,-0.014453047,-0.034005746,0.0003804725,0.0050241253,0.014489301,0.038066134,-0.01952853,-0.12654875,0.023129709,-0.043020774,0.053365096,0.05394515,0.0069848336,0.02119619,-0.016628254,0.04410838,0.014090512,-0.042803254,0.018549688,-0.006851904,0.041884832,0.03717188,-0.059697367,0.03228975,-0.030573752,0.040023822,-0.015613157,0.016338227,0.0031389454,-0.024217313,-0.031661358,-0.07898421,-0.019733967,-0.010011998,0.053316757,0.05017479,-0.013691724,0.051963296,-0.024326073,-0.015903186,-0.0254741,-0.0006246169,0.018972645,0.0130875,-0.02948615,-0.06225928,-0.027190097,-0.025401592,0.023190131,-0.0024365347,-0.037341066,0.041836496,-0.033498198,0.01694245,-0.06622299,0.0069123264,-0.04053137,-0.004090599,0.01230805,-0.019069321,-0.05278504,0.036712673,-0.029631162,0.0018746061,0.0014191719,-0.021667486,-0.023383483,-0.061534207,-0.023286806,-0.022767173,0.055201937,-0.016604085,-0.0038066134,-0.0020014932,-0.100446254,-0.0268759,-0.045099307,0.009166083,0.063757755,-0.039782133,0.029606994,0.0135829635,0.019540615,0.0027839637,-0.022948442,-0.0034561632,0.0443259,-0.02130495,0.021341205,-0.049836427,-0.017643351,0.019721882,0.025643282,0.03013871,0.036591828,-0.019673545,0.036857687,0.04737119,-0.03557673,-0.009268802,-0.009474238,0.036229294,0.033135664,0.04551018,0.014428877,0.0072929882,0.026803393,0.019564785,-0.01850135,-0.0035498182,0.023359314,-0.035890926,0.003037738,-0.032893974,0.0070331716,0.0052718576,-0.005700857,0.038066134,-0.0051751817,-0.000561551,0.039177906,-0.019806474,-0.01543189,0.06491786,-0.006725017,0.035625067,0.01160715,0.013969667,0.0030634175,0.024459003,-0.01389716,0.04882133,0.041667312,0.0031570722,0.009141915,-0.0056948145,0.0049485974,-0.015758172,0.014235526,0.019782305,-0.034996673,0.00048677824,-0.0094198575,0.047951244,0.008797507,-0.0073715374,0.017848788,-0.0074863397,-0.003048312,-0.0010324684,-0.036495153,-0.0016404692,0.0049727666,-0.032410596,0.008688746,-0.0040513244,0.01543189,0.0028534494,-0.0069244113,-0.011691742,-0.033449862,0.0023594962,0.043697506,-0.0062476797,0.039878808,0.032386426,-0.002184271,0.0033081283,-0.043528322,-0.0150451865,-0.03204806,0.038718697,-0.008018057,-0.000542669,-0.03535921,0.0042023803,0.014295949,-0.05418684,0.0005460678,0.014815581,-0.011975727,-0.0034078255,0.0370027,0.035625067,-0.019806474,-0.0009131341,-0.00719027,0.005477294,-0.001052861,-0.02520824,0.022066273,-0.040047992,-0.025159903,0.0092808865,0.024894044,-0.04599356,0.01898473,-0.008749168,-0.030090373,0.003990902,0.012579951,-0.019153912,-0.026005816,0.016036114,-0.060905814,-0.012930402,-0.04766122,0.0478304,-0.007462171,-0.014876003,0.055443626,-0.011854882,-0.013570879,-0.0022582884,-0.023504328,-0.010024082,0.007347368,0.028906094,-0.017280817,0.045872714,0.03221724,0.0067854393,0.032869805,-0.041763987,0.00015218901,-0.01626572,0.025256578,0.0074561285,0.029244458,0.01801797,0.022634244,-0.06752811,0.0063081025,0.03963712,-0.06221094,0.02943781,0.0077461563,0.067479774,0.010241603,-0.0015128268,-0.016676592,0.073183656,0.029969528,0.0058972295,-0.008229536,0.001123102,-0.05587867,0.044857617,0.012616205,-0.035310872,-0.046936147,0.016386565,-0.041884832,0.00043995085,-0.035480056,-0.044615928,0.006271849,-0.018295914,0.01403009,0.017002873,0.022791343,0.01354671,-0.033353183,0.0005645721,-0.03492417,0.032410596,-0.035020843,0.058150552,0.03320817,0.051576592,-0.002903298,-0.07656731,0.033570707,-0.028857755,-0.001685786,-0.004431986,-0.014308033,0.01858594,0.048869666,-0.052978393,0.024313988,-0.005552822,-0.04263407,0.00032042773,0.020422783,0.031854708,0.007093594,-0.042585734,-0.015178116,-0.031516343,-0.008749168,-0.017860873,0.07067008,-0.011178151,-0.015758172,-0.059745703,-0.0021721865,0.0008413824,0.024313988,0.025039058,0.0041540423,0.042295706,-0.036809348,-0.006694806,-0.013643386,0.043334972,-0.020084418,0.036205124,-0.03393324,0.046621952,-0.04546184,-0.022827595,-0.0024848727,0.043624997,-0.019214334,0.049594734,0.026610041,0.054573543,0.0246161,0.0051449705,-0.017462084,0.036881857,-0.03557673,-0.0050482946,-0.0037764022,-0.014489301,0.035238363,-0.030235387,-0.01109356,-0.019588953,-0.010894165,-0.014271779,-0.050223127,0.0024742987,0.017510422,-0.0028640234,-0.011818629,0.00043617445,0.034730814,0.004513556,0.0010891145,-0.001047574,0.004166127,-0.073377006,0.013389612,-0.034561634,0.02345599,0.003048312,-0.035020843,-0.005256752,-0.034851663,0.0022658412,-0.016362395,-0.057860523,0.053848475,0.0003247706,0.012652458,0.0036072193,0.014344286,-0.015033102,0.010163054,-0.032096397,-0.00046185398,0.005232583,-0.019999826,-0.05017479,0.033594873,0.019214334,0.036833517,0.016797436,-0.023552665,-0.056652077,0.028446883,-0.0028670446,0.024338158,-0.039202075,0.038984556,-0.0050301678,-0.04406004,-0.010320152,-0.053365096,-0.0046585696,-0.0006767313,-0.020241516,-0.026102493,0.0061993417,0.024567762,-0.036906023,0.03086378,0.028229361,-0.027866827,-0.0052778996,0.003993923,0.0146826515,-0.028301869,-0.0047461824,-0.03697853,0.004812647,-0.018513434,0.0071600587,0.06670637,-0.023141792,-0.013039161,-0.06293601,-0.041788157,0.037316896,-0.008694788,0.06863989,0.017389577,-0.024313988,-0.013727978,-0.05467022,0.017365407,0.045316827,-0.010984799,-0.060664125,-0.041183934,0.0057129413,-0.025643282,0.054815233,0.00069938967,0.0059425468,0.008308085,-0.001861011,0.053075068,0.022440894,0.013160006,-0.031468004,0.028591897,-0.027359279,-0.0032869806,-0.043020774,0.0041872747,0.002690309,-0.00062423927,-0.014743075,0.011915305,-0.01755876,0.017510422,-0.031443834,0.009166083,-0.02143788,0.0038368248,0.0043111406,-0.024869874,-0.0089606475,0.0088760555,0.012640374,-0.083963014,0.006592088,-0.031927217,0.04500263,-0.002187292,0.028253531,0.011486305,0.004265824,-0.036640164,0.011492347,-0.013027078,-0.015770257,-0.056362048,-0.0061933,0.033135664,0.013486288,-0.013075415,-0.037800275,-0.028567728,-0.017740028,-0.03161302,-0.0118005015,-0.006900242,-0.025425762,-0.005265815,0.0032326004,0.014005921,-0.00996366,-0.033425692,0.010996884,-0.027045082,0.0110210525,-0.03255561,-0.027721813,0.0148639195,-0.011298995,0.022791343,0.0246161,-0.008465183,0.0031963468,0.014066343,0.021389542,-0.002607228,-0.037026867,-0.0046041897,0.027600968,0.015178116,0.007993888,0.0036464941,0.018791378,-0.0012424364,-0.013691724,-0.0015498354,-0.03792112,-0.0045075137,-0.02229588,0.008543733,0.010942503,0.02919612,0.0303804,0.015516481,0.015117694,0.024495255,0.026320012,0.004483345,-0.02270675,0.0002637817,-0.022948442,0.008718957,-0.013740062,0.041401453,0.0027884955,-0.028954431,0.014537638,0.030597921,-0.01966146,0.0153231295,-0.024628185,0.019504363,-0.0011737058,-0.004897238,0.016918283,-0.020084418,0.0026344182,0.011444009,0.014066343,0.029026939,-0.019866897,0.025546607,-0.026054155,-0.0010981777,-0.02027777,-0.029945359,0.010731025,0.010392659,0.034948338,-0.0011835245,-0.006845862,0.025981648,-0.0024863833,-0.02119619,-0.0071298475,-0.020881994,0.026755055,0.013377528,0.002246204,-0.009679674,0.014525553,0.03134716,0.025014888,-0.024676522,0.016809521,-0.053606786,-0.0246161,0.026706716,0.03765526,-0.036446813,0.017244563,0.012507444,0.0007367761,-0.0005033944,-0.005752216,-0.03112964,0.017437914,-0.001960708,0.008235578,-0.015649412,0.0072265235,0.05259169,-0.00021638785,0.012869979,0.021824583,0.03765526,-0.009401731,0.030887948,-0.032362256,-0.0043020775,0.0026948405,0.044954292,-0.02448317,-0.015987776,-0.0075346776,-0.04715367,0.03141967,-0.002294542,0.029752007,-0.0042718663,0.008060353,0.001351952,0.029292798,-0.012543698,0.0135829635,-0.0015279324,-0.015891101,-0.01979439,-0.013220429,0.021341205,0.0029591888,0.008356423,0.011353375,-0.010737067,0.00996366,-0.0051933085,0.024036044,0.0067914817,0.077340715,-0.006147983,-0.00050566025,0.03112964,0.025401592,0.038356163,-0.0064410316,-0.12374515,0.023359314,-0.023262639,-0.005534695,0.02073698,-0.018223407,0.027310941,0.029679501,-0.006178194,0.024144806,-0.016857859,-0.0048760907,0.022513399,-0.03799363,0.037776105,0.0009259738,0.029945359,-0.0310813,-0.016289888,0.013280852,0.005555843,-0.0010649455,0.029631162,0.0133050205,-0.032362256,0.030791273,0.04072472,-0.017945463,-0.013776315,0.02948615,0.021715824,0.006700848,0.039226245,0.0030573753,-0.023407651,-0.06269432,0.03888788,-0.0026011858,-0.005256752,-0.012531613,-0.054766897,0.008211409,-0.021824583,-0.023153877,0.0008957626,-0.003126861,0.012749134,0.0055951173,-0.032652285,-0.060229085,0.010193265,-0.009389646,0.008990859,0.034005746,-0.0003077768,-0.021715824,-0.032628115,0.0039063105,0.002356475,0.0035075224,0.039177906,0.00057401316,0.03366738,-0.0055981386,0.006990876,-0.0051902873,-0.031298824,0.010036167,-0.015129778,-0.0044803238,0.010253687,0.022090442,-0.032893974,0.053365096,0.011317122,0.034078255,-0.0197098,-0.018380504,0.039008725,-0.012187205,0.010821658,0.016217383,0.007045256,0.03864619,-0.011909262,0.008579986,-0.015939439,0.017014958,0.00983073,-0.020785319,0.00058798585,-0.0029591888,-0.014573892,0.029389473,-0.01438054,0.0060603702,0.026247507,-0.033159833,-0.07110512,0.039782133,0.015685664,-0.018996814,-0.014114681,0.01931101,-0.01413885,0.02466444,0.03465831,-0.016181128,0.04896634,0.02205419,-0.028229361,-0.01020535,-0.010827701,0.021655401,0.044205055,0.031782202,0.015576904,0.008700831,-0.007516551,-0.024604015,-0.011975727,0.05418684,0.0010898696,-0.019842727,0.015842762,-0.03460997,-0.00659813,-0.021486219,-0.0045286617,0.00020732448,-0.019504363,-0.0015022528,-0.015298961,-0.004519598,-0.022984695,-0.033377353,-0.0013051246,-0.0341991,0.01141984,-0.022682583,0.024652354,-0.0010135864,0.03963712,-0.0056434553,0.018271744,-0.020205263,0.018948477,0.007993888,-0.032603946,-0.009250675,0.04594522,-0.014610145,-0.019407686,0.015746087,0.0356009,0.030452907,0.0050090197,-0.015794424,0.016326142,0.031878877,-0.016096536,-0.042319875,0.0036585785,0.003619304,-0.02283968,0.0012303519,0.022743005,0.0018232471,-0.0023534538,0.01036849,0.01389716,-0.0042356127,-0.009178168,-0.011450051,-0.011141897,0.014634314,0.031975552,-0.0070875515,-0.0020543628,-0.009836772,-0.05607202,0.030815443,0.00065218465,-0.0038791203,-0.0075830156,-0.008694788,0.03985464,-0.027721813,0.011812586,0.0034108465,-0.007607185,0.018368421,0.0017567823,0.00014973435,-0.0006616257,-0.016749099,0.014912257,0.005232583,0.0013511967,0.0313955,-0.019601038,0.016761184,0.0153231295,-0.0075951,-0.014416793,0.03018705,0.0014750627,-0.020011911,0.02544993,0.041836496,0.0031057133,0.016011946,-0.0066827214,-0.03415076,0.023866862,0.0204107,-0.037365235,-0.00447126,0.004734098,-0.019915234,0.024918213,-0.01101501,-0.010851869,-0.048047923,0.030670429,0.0022749046,-0.017389577,0.006918369,-0.015262707,0.024410665,-0.0077763675,0.030283725,0.02119619,0.016036114,0.00038179426,0.058537256,-0.033377353,0.016652424,-0.0071600587,0.030066203,0.022537569,-0.010676645,0.005534695,0.008120775,-0.035915095,0.04500263,0.028640235,0.01225367,0.02178833,0.006743144,-0.030452907,0.030912118,0.006051307,-0.006688764,-0.020338193,-0.0075044665,-0.0055195894,0.017220395,0.009365478,0.007468213,0.02356475,-0.023746017,0.042005677,0.013812569,-0.02755263,0.043165788,0.010906249,0.026610041,0.0021933345,0.01825966,0.019214334,0.036833517,0.010640391,-0.028712742,0.004809626,0.003821719,0.014658483,-0.019045152,0.01343795,0.021244528,0.0021178063,0.00046638568,0.019105574,0.024845706,-0.003344382,-0.02733511,0.032869805,0.017159972,0.054863572,0.013691724,-0.017196225,-0.007347368,-0.005507505,-0.012567867,0.0036072193,0.0021389541,0.00015511572,-0.013981752,0.0025528478,0.0247732,0.004422922,0.00447126,-0.00309665,-0.0139454985,-0.045075137,-0.0202536,-0.003625346,0.036881857,-0.029316965,-0.035214197,-0.06511122,0.000694858,0.007927423,0.010688729,-0.014537638,-0.012295966,-0.012579951,-0.015250623,0.003323234,-0.050029777,-0.020434868,0.026972575,0.008157029,0.020845741,0.01941977,-0.030501246,-0.002521126,0.046839472,0.007063383,0.05370346,0.009462154,-0.001308901,0.006277891,-0.004368542,-0.023975622,0.028640235,0.0024002814,-0.014295949,-0.008797507,0.0047099288,0.018332167,-0.006368525,0.0047250343,0.0019410708,-0.012519529,0.012519529,-0.0052023716,0.0071358895,-0.0062658065,0.009619252,0.03272479,-0.022283794,-0.03775194,0.028906094,-0.011909262,-0.010586011,0.005558864,-0.0074500865,-0.008610197,0.009377562,0.0030060161,-0.03042874,0.0123866,0.0039848597,-0.036132615,0.003546797,0.014743075,0.008610197,0.025353255,0.017752111,-0.009728013,-0.01020535,0.005537716,-0.027504293,0.026658379,-0.003939543,-0.0068579465,0.009764265,0.012434937,-0.02383061,-0.0011125281,0.0137884,0.032120567,-0.018223407,-0.007721987,-0.008930436,0.0005849647,-0.008803549,-0.0049697454,0.0153231295,-0.0072265235,-0.0045044925,-0.019153912,-0.010483293,0.0349,-0.0024138764,-0.01155277,-0.012422853,0.043407477,0.008386634,0.048337948,-0.0006359461,0.005845871,0.031951383,0.02393937,0.0007870022,-0.009752181,-0.00778241,-0.007492382,-0.0025165945,0.008948563,0.013570879,0.020591967,0.023310976,-0.0061510038,0.0034561632,0.00067824183,-0.029075276,0.027745983,-0.053171743,0.029244458,0.016845776,-0.007365495,0.01114794,0.025353255,-0.0040875776,-0.018465096,-0.018839715,-0.01101501,-0.03141967,0.00172355,-0.025111564,-0.023045117,-0.02520824,-0.009576956,0.031758033,-0.03816281,0.0137884,-0.006845862,0.0440117,0.015419805,-0.011081475,0.03141967,0.0040090284,0.036132615,0.018247576,-0.009069407,0.0007194046,0.08405969,-0.010453082,0.016084453,0.0076978183,0.0017839724,-0.0002734115,-0.030066203,-0.009589041,-0.026344182,0.024108551,0.008428929,-0.0098790685,0.004247697,-0.027262604,0.04311745,0.020132756,-0.009975744,0.01160715,0.038742866,-0.0024788305,0.0232143,0.029002769,0.01018118,0.018114647,0.01602403,-0.0012303519,-0.023758102,-0.017063295,0.0030755019,0.018223407,-0.00081268174,0.018670533,0.010773321,-0.021643316,-0.004519598,-0.039540444,-0.0013708341,0.010453082,0.020942416,-0.012229501,-0.012531613,-0.021135768,0.009184211,0.037872784,0.009981787,-0.0055135475,0.008018057,-0.04077306,-0.031516343,-0.01613279,0.04809626,-0.006990876,-0.0065074963,0.0041298736,0.007365495,-0.022235457,-0.027286772,-0.025981648,-0.027504293,0.01071894,-0.014199273,0.024700692,0.042779084,-0.023286806,0.0006495412,-0.013353358,-0.04219903,-0.0042446763,-0.009703843,0.013885076,-0.0044863657,0.019359348,-0.012857894,0.025715789,0.0060150535,0.002170676,-0.024338158,0.007691776,0.011407756,-0.012048233,-0.00094032416,0.020398615,0.017860873,-0.0030936287,0.026803393,-0.049643073,-0.01720831,-0.026634209,-0.009927406,0.022235457,-0.0049697454,0.029268628,-0.03042874,-0.034005746,0.0056102234,0.033135664,-0.033111494,0.0011842798,0.00247732,-0.004957661,0.0014486279,0.007715945,0.020845741,0.005217477,-0.01141984,0.004441049,0.017546676,-0.039202075,-0.028543558,-0.017872956,-0.0010105652,-0.002394239,0.0047733723,-0.03719605,-0.009437985,-0.004616274,0.01705121,0.021184105,0.04403587,-0.012519529,0.028881924,0.04212652,0.027987672,-0.010706856,0.008525605,-0.032869805,0.032603946,0.036954362,-0.02851939,-0.014199273,-0.00023810216,0.03110547,0.0042809295,0.006108708,-0.0002730339,0.04454342,-0.036156785,0.004643464,-0.028326038,-0.00296221,-0.0062899757,0.03250727,-0.02641669,-0.011359418,0.007879086,0.0020785318,-0.021824583,0.008694788,0.008144944,0.019335179,-0.0040543457,0.0046766964,-0.0062114266,-0.017462084,-0.037075207,-0.0057129413,0.014211357,0.005341343,0.019431856,-0.014320117,0.007021087,-0.004431986,-0.026271675,0.0044591757,-0.0071781855,-0.0077280295,0.009885111,-0.013172091,0.0327973,-0.00011886226,-0.014271779,0.0033866775,-0.0070512984,-0.0014282353,-0.010561842,0.0037915078,-0.028011842,0.0058911876,-0.011329207,0.0008851887,-0.013244598,0.018005885,0.02051946,-0.001117815,0.017123718,-0.031661358,-0.030525414,-0.00430812,0.036712673,-0.00089802843,-0.005806596,-0.029800346,0.029002769,0.042585734,-0.013232513,0.0036344095,0.030501246,0.04785457,-0.0078065787,0.0065860455,-0.0015279324,-0.019999826,-0.020108586,0.020712811,0.019214334,0.006096624,-0.02641669,-0.011292953,-0.020930331,0.009268802,-0.007510509,0.0071842275,-0.03112964,-0.017486254,0.014839751,0.03040457,0.0041480004,0.015709834,0.005280921,0.01979439,0.012990824,-0.010761236,-0.038259488,-0.00867062,0.017655436,0.027745983,0.006350398,0.0059636943,-0.026924238,-0.024845706,0.0313955,0.012616205,0.011220447,0.028640235,0.033860732,0.007915339,-0.027238434,0.008519564,0.01171591,0.016060283,-0.004413859,0.006108708,-0.01613279,0.011667572,-0.023020947,0.0060936026,0.00877938,-0.008688746,-0.038477007,0.01683369,-0.02919612,0.001648022,0.03533504,-0.0047250343,0.021885006,-0.016857859,0.02051946,-0.026948407,-0.0009879068,-0.020181093,-0.016422817,-0.011576938,-0.018066308,-0.009746139,-0.012640374,-0.008851887,0.032628115,0.017570844,-0.022924272,-0.001381408,0.010712898,-0.009377562,0.04026551,-0.015311046,0.004141958,0.025498267,-0.010483293,0.038066134,0.0076253116,-0.0056434553,0.040434696,0.022368386,0.03934709,-0.04947389,-0.059649028,-0.012809556,0.0085981125,0.017486254,-0.019286841,0.007734072,-0.003061907,0.008604155,0.007788452,-0.03245893,0.0029259564,0.027625138,-0.008060353,-0.0011125281,-0.033135664,0.027359279,0.016011946,-0.005785448,0.012217416,0.0073413257,0.015866932,-0.009703843,0.01624155,0.047008656,0.03765526,0.006501454,-0.01874304,-0.018344251,-0.022875935,0.016628254,0.019081404,0.008012015,0.031782202,0.017619181,-0.025860803,0.023383483,0.032386426,-0.0022884998,0.029727839,-0.029002769,0.003918395,-0.023492243,-0.025570774,-0.006374567,0.021981683,-1.9578285e-05,-0.03574591,0.0036132617,0.01225367,-0.033474028,0.01053163,0.021486219,-0.0324831,0.0060241167,0.03320817,0.006277891,0.020096501,-0.026368352,0.016652424,-0.017147887,-0.010972714,0.020833656,-0.017027043,0.0038126558,-0.0036464941,-0.0050694426,0.006477285,-0.00085573277,-0.009631337,0.031782202,0.0028051117,0.02038653,-0.00031400783,-0.0070573404,0.005528653,0.033329017,-0.043721676,-0.010011998,-0.022960525,0.019081404,0.0370027,0.029316965,-0.04454342,-0.023093455,0.0014357881,-0.07105678,-0.016338227,-0.008815633,0.0035196068,0.010797489,0.0065195807,0.024156889,0.018948477,0.0061933,0.0010037677,0.023878947,-0.02310554,-0.012495359,0.0032205158,0.007589058,0.014851835,0.017353324,0.027987672,-0.0070875515,-0.0145859765]	371
11	5	J.Q Patisserie Artisan French Pastries, Handcrafted with Love Kluang, Johor, Malaysia About Us J.Q Patisserie is a boutique pastry shop dedicated to the art of French baking. Founded with a passion for authentic patisserie, we bring the elegance and craftsmanship of traditional French techniques to the heart of Kluang, Johor. Every pastry that leaves our kitchen is handcrafted using premium ingredients sourced for quality — from imported French butter to Belgian chocolate. We believe that exceptional pastries are created through patience, precision, and an unwavering commitment to excellence. Whether you&#039;re celebrating a special milestone, treating yourself to an afternoon indulgence, or looking for the perfect gift, J.Q Patisserie promises an unforgettable experience in every bite. Our Philosophy Quality Without Compromise We use only the finest ingredients: French butter for our croissants, Valrhona chocolate for our ganaches, and fresh seasonal fruits for our tarts. No shortcuts, no compromises. Artisan Craftsmanship Every pastry is handmade in small batches. Our croissant dough is laminated over 48 hours, our cakes are assembled with meticulous care, and our decorations are crafted by hand. Freshness Guaranteed We bake fresh daily. What you see in our display is made that morning, ensuring you always enjoy our pastries at their absolute best. Our Specialties Signature Croissants — Our butter croissants are crafted using a traditional 48-hour lamination process, resulting in perfectly flaky, golden layers with a buttery aroma. Burnt Basque Cheesecake — A customer favourite! Creamy, caramelized, and utterly indulgent. Available in whole cakes and slices. French Tarts — From classic Tarte au Citron to seasonal fruit tarts, each features a crisp, buttery shell and luscious fillings. Custom Celebration Cakes — Bespoke cakes designed for birthdays, weddings, anniversaries, and corporate events. Every creation is unique.	0	2025-12-21 23:53:33	2025-12-21 23:53:33	[0.011778491,0.011165294,0.018408682,-0.046347465,0.026124744,-0.023416458,-0.011484667,0.026290817,-0.037021764,-0.032857135,0.020567646,-0.05155964,-0.014192954,0.03009775,-0.05493222,0.073174834,-0.005895633,-0.007383913,0.024400126,0.014422902,0.04126304,-0.024195729,-0.009657851,0.003554626,0.04200399,-0.0024320283,-0.04154409,-0.011248331,0.0031857495,0.0010108168,0.016786266,-0.0036632128,0.0049822247,0.01801266,-0.0011689066,-0.016083645,-0.0014922721,-0.020899795,-0.017361138,0.045785367,-0.009887801,-0.0033821643,0.027977109,0.032550536,0.021385241,-0.0011273881,0.00045271177,0.026265267,-0.039065752,0.046551865,0.026597416,0.06453898,-0.016581867,0.01798711,0.008335645,-0.028155958,-0.005605003,0.024157403,0.05385913,0.03932125,0.008067372,-0.051048644,0.0013493525,-0.02083592,-0.0054197665,-0.010539322,-0.039091304,0.016351918,0.0013238027,0.040649846,0.00048345147,0.00943429,-0.025715945,-0.019405127,-0.009574814,-0.0069176275,0.036383018,0.04606642,0.023237608,-0.038580306,0.0029797538,0.018600306,0.0150361,0.026444117,0.00991335,-0.05406353,-0.07700731,0.010264661,-0.03804376,0.04205509,0.06688956,0.012615249,-0.010015549,-0.013119859,0.0984181,-0.010098587,-0.017092863,0.024515102,-0.022087863,0.020874245,0.048059307,-0.04581092,-0.0003549037,0.00024511907,0.056005318,-0.0028935228,0.0128962975,-0.021231944,-0.020107748,-0.032652736,-0.03783936,-0.017948784,-0.003912324,0.013183733,-0.0150616495,0.032243937,0.018076533,-0.07240833,0.060246598,-0.0028344388,0.0049151564,0.04151854,0.003289546,-0.02373583,0.017233388,-0.020107748,-0.067860454,-0.03334258,0.021053094,-0.025996994,0.015930345,-0.034339026,0.035207722,-0.042693835,0.020848695,-0.014039654,0.029382352,0.012851586,-0.050077748,0.007824648,0.027977109,-0.044201277,-0.018536432,0.0067260037,-0.0010906601,-0.018740831,-0.05178959,-0.019890575,-0.002329829,0.08722726,-0.023633631,-0.0296123,-0.026214167,-0.027363911,-0.022075089,0.0025821337,0.03543767,0.046756264,-0.046807364,-0.0019785182,0.0013014466,-0.0010938538,0.016581867,-0.027363911,0.023774154,-0.031170843,0.0023314257,0.02187069,-0.028641406,-0.046424117,-0.03819706,-0.011733779,0.029407902,0.039244603,-0.028692504,0.026035318,0.019328477,-0.01182959,0.0126216365,-0.018561982,-0.02383803,0.068933554,0.032524984,-0.020644296,-0.014371802,0.022036765,0.014346252,-0.04767606,0.020209948,0.007633024,0.01594312,-0.027261712,0.0027466111,-0.032806035,0.047957107,-0.03967895,0.044712275,0.03211619,-0.03781381,0.078131504,-0.062137287,0.009811151,0.018459782,0.008910517,0.018485332,0.01205954,0.04358808,-0.020261047,-0.01092257,-0.044201277,0.0598378,0.049387902,0.001560139,0.058918003,0.024131853,0.030966444,-0.0028823449,0.023173733,0.010584034,0.022087863,-0.017092863,0.017974334,0.02078482,-0.007856585,-0.028922454,0.013515882,0.013234833,0.0024288346,0.025307147,-0.034287926,-0.00090781885,0.01801266,-0.034492325,0.018779155,-0.039755598,0.026048094,-0.02153854,-0.035258822,0.044431224,-0.050793145,-0.012321426,0.04141634,-0.032448336,0.009964449,0.040803146,0.004212535,-0.0024176566,-0.020529322,0.013036822,-0.043051533,0.01796156,-0.03193734,-0.031170843,0.009811151,0.031170843,0.001692679,0.0001430194,-0.050742045,0.030889794,-0.02772161,0.040854245,0.02267551,0.02290546,-0.017143963,0.02391468,0.026801815,-0.00398578,-0.008865805,0.00425086,0.02197289,-0.04555542,-0.026239717,0.0396534,0.056925114,0.0069176275,-0.024425676,-0.013145409,-0.0077990983,0.01884303,0.007984335,-0.023263158,-0.023505881,-0.027440561,-0.040470995,-0.009159629,0.012110639,0.03789046,-0.024732275,-0.04394578,0.014895575,-0.002508678,-0.03592312,-0.011216394,-0.0068090404,0.01672239,0.014614526,-0.042412788,-0.015355472,0.0247195,-0.0012351766,-0.009670626,0.028411457,-0.008999942,-0.006553542,-0.038554754,0.03587202,-0.016709616,0.04307708,0.03993445,0.024208503,0.013036822,0.009140466,0.021295818,-0.05370583,0.006320399,-0.0011369693,-4.269124e-05,0.0018986748,0.014691176,-0.042412788,0.050971992,-0.010469059,-0.0298167,0.029561201,-0.03188624,-0.031298593,0.017744385,-0.0021749327,-0.010903408,-0.0010323745,0.02259886,-0.03576982,-0.016505217,-0.0026843334,-0.017182289,0.0049694497,0.0040975604,-0.017693285,-0.00057327526,0.008776381,-0.04159519,-0.04818706,0.004119917,-0.03750721,0.046449665,0.0030532095,0.04545322,0.046245266,0.009038267,0.035028875,-0.026393017,0.00542296,-0.02767051,0.012557762,0.03809486,-0.052428335,0.064079076,0.033623632,-0.06372138,0.034645624,-0.03720061,-0.018127633,0.0044712275,0.005895633,0.003227268,-0.0068920776,-0.009063817,-0.019315703,0.026214167,-0.02181959,-0.015598197,0.038452554,0.019111304,-0.014742276,-0.05498332,-0.022228388,-0.00945984,0.023646405,0.03932125,0.013298708,0.051712938,-0.009389577,0.07363473,0.020439897,0.058713604,-0.021334141,0.032729384,-0.006502442,0.01395023,-0.017412238,-0.011459117,-0.012583312,0.028564757,0.0150361,-0.009293766,0.021155294,0.038273707,-0.055954218,-0.0071922885,-0.017041763,0.0016351917,-0.0060457382,0.011689066,-0.034390125,0.004835313,0.0101816235,-0.071692936,-0.0015960685,-0.030174397,0.015559872,-0.05528992,0.003407714,-0.01084592,0.022994883,0.0066685164,-0.034850024,0.05539212,0.011031156,0.008584756,-0.017591087,-0.04172294,-0.019366803,-0.020720946,0.008706119,-0.016109195,0.04386913,0.021001995,-0.08313928,-0.013273158,-0.020248273,0.01672239,-0.0045542647,-0.04169739,-0.06331258,-0.038861353,-0.00040460617,-0.03372583,-0.017220613,-0.036255267,-0.024310702,-0.0009549264,0.017974334,0.013285933,0.017425012,-0.042566087,0.011369693,0.032141738,0.002075927,0.024451226,-0.050333247,-0.016121969,0.009932512,0.017974334,-0.0498989,-0.038120408,0.052530535,0.048698053,0.009191566,-0.002039199,-0.07716061,0.023212058,-0.004052848,-0.015444897,0.03622972,0.025958668,-0.005097199,0.0020088586,-0.0013884758,0.035028875,-0.018076533,-0.013886355,-0.034441225,-0.0123533625,0.015329923,-0.04972005,-0.004803376,-0.049924448,0.029152403,-0.012883523,-0.014410127,-0.03009775,-0.025038874,-0.050231047,-0.016479667,-0.06285268,-0.0042700223,-0.0022388075,0.024195729,-0.028948003,0.008731669,-0.046960663,0.011414405,0.010813983,-0.012538599,0.021998439,0.013835255,0.012736611,-0.01798711,-0.021627966,0.024004104,0.028104858,-0.034313478,0.011484667,0.066838466,-0.0034620075,0.052198388,0.025077198,0.04131414,0.018076533,-0.007933235,0.025805369,0.015393797,0.006636579,-0.034926675,-0.020388797,0.0080034975,-0.03597422,0.04915795,-0.017386688,-0.006489667,-0.026469667,-0.029510101,-0.0053654728,-0.024080753,0.002797711,-0.001836397,0.0005481246,-0.022841584,-0.010079424,-0.07159074,0.040394347,-0.022994883,-0.0298167,0.004394578,-0.017667735,-0.0041422728,-0.010386023,0.013630856,-0.015291598,0.004436096,-0.010954508,0.01662019,-0.03349588,-0.0006036157,0.0069942772,0.011158906,0.0495412,-0.028769154,-0.029177953,0.03216729,-0.0034396513,0.010577647,-0.0145251015,-0.008795544,0.02769606,-0.01803821,-0.013835255,-0.005426154,0.034185726,0.015802596,0.05163629,0.034441225,-0.022867134,0.009715338,0.021359691,0.0148317,0.017169513,0.012423625,-0.01203399,0.0023601693,-0.0042891847,0.068422556,0.013477557,-0.03755831,0.0077863233,-0.0071795136,0.017143963,-0.006413018,0.000104994004,0.024221279,-0.040777594,-0.012602474,-0.04606642,0.013835255,-0.01374583,0.017565537,-0.011701841,-0.031349692,0.026929565,0.047906008,-0.020120524,0.029126853,-0.026699616,-0.03804376,0.023454782,-0.021781266,-0.05564762,0.013860805,0.005991445,-0.011618804,-0.014474002,0.04215729,-0.025319923,-0.051048644,-0.042285036,-0.0007185901,0.025511546,-0.008686956,-0.015879245,-0.0494901,0.023671955,-0.0028152764,0.002363363,-0.030327696,-0.025843695,-0.0018970779,-0.04402243,-0.022816034,0.005735946,0.0025022905,0.025166623,-0.014921125,0.039857797,0.015163848,-0.013049597,0.03796711,0.009530102,0.002665171,-0.021257494,0.01667129,0.012148963,0.01687569,0.00425086,0.010909795,0.015828146,-0.0012830826,0.032959335,-0.009466227,0.011650741,-0.03183514,-0.011752941,0.026597416,0.03165629,-0.017182289,0.00012615249,0.00940874,0.011650741,0.012053152,0.02264996,-0.022087863,-0.0072625508,0.034875575,0.030429896,-0.014282378,0.022292262,0.027006214,0.008035434,0.016339142,0.0023537818,0.05518772,-0.02792601,-0.0011265896,0.00470437,-0.02293101,0.018676955,0.02295656,0.009875026,-0.026699616,0.020963669,-0.025077198,0.054421224,0.03760941,0.04210619,0.004129498,-0.025064424,0.013656406,-0.004094367,-0.014397352,0.010641522,0.008776381,-0.010073037,-0.012040377,-0.031221943,0.018395906,-0.024387352,-0.019264603,0.023365358,0.004608558,0.014103529,-0.017016213,0.014921125,0.0066557415,0.011158906,-0.0137202805,0.0014076382,-0.011305818,0.011835977,0.024412902,-0.019379577,-0.07414573,-0.016428567,-0.040470995,-0.0042316974,0.012174513,-0.021474667,0.015457672,-0.04606642,-0.0010842726,0.016109195,0.0150361,-0.0043402845,0.014716726,-0.017897684,0.024170179,-0.023825254,-0.009159629,-0.022892684,0.005065262,0.009708951,-0.018651405,0.009204341,0.036740717,0.0031601996,-0.054267928,0.041237492,0.012659961,-0.034696724,-0.009683401,0.0056113903,0.014818925,-0.028769154,0.0058253706,0.037123963,0.026341917,-0.034824476,0.01382248,-0.028794704,0.0039314865,-0.017207839,-0.016326368,0.020184398,-0.010960895,-0.017603861,-0.016760716,0.014729501,0.014307928,0.0198267,0.001062715,-0.015483222,-0.010654297,0.017271712,0.011063094,0.003921905,0.0044424837,-0.028896904,-0.050052196,0.012136188,-0.0046660453,0.0016048513,-0.016173068,-0.013413683,0.0297145,-0.019813925,0.023429232,-0.008884967,0.0041837916,0.03796711,-0.007403075,-0.0041454667,-0.057998206,-0.020465447,-0.03232059,0.00390913,0.03367473,0.012155351,0.00014162213,0.013758605,0.013132634,-0.0072178384,0.015381022,0.050077748,-0.024004104,0.005914795,-0.038120408,-0.014716726,-0.040241048,0.024234053,-0.01985225,-0.045325473,-0.018293709,0.03778826,-0.0008918502,0.008923292,0.008693344,0.010788433,-0.032831583,0.009178791,-0.035131074,0.0073136506,-0.0085528195,0.00026647717,0.00091021415,-0.025626522,-0.034287926,0.00014531489,0.038069308,-0.027159514,0.074963324,0.014972225,0.006071288,0.02749166,-0.024681175,-0.011612416,-0.021602416,0.021053094,-0.01803821,-0.0057072025,-0.008488945,0.025281597,-0.0057998206,0.042591635,0.00746695,-0.00033474324,0.005113168,-0.020669846,-0.017616637,-0.015547097,0.013477557,-0.047906008,-0.021180844,0.005595422,-0.04956675,0.0040847855,0.016543541,0.006361918,0.03004665,-0.03188624,-0.0024384158,-0.03921905,0.026124744,0.0034300701,0.0032081057,-0.0015633327,0.007901298,-0.0074477876,0.004052848,0.0019960837,0.0039921673,-0.010692621,0.023595305,-0.0033406457,-0.004119917,0.009593977,-0.01708009,-0.039602302,0.018689731,-0.024208503,-0.03628082,0.0148317,-0.010258273,-0.023160959,0.0077990983,0.010584034,-0.018664181,0.015955895,0.0056018094,-0.02751721,-0.003337452,0.0013437635,0.033981327,-0.009332091,-0.02489835,-0.019060204,-0.02373583,-0.00081160764,0.018217059,-0.023927454,0.0029238635,-0.015189398,-0.03152854,0.05194289,-0.0016543542,0.0027881297,-0.003925099,-0.022522211,0.07087534,0.02401688,0.020158848,-0.002449594,-0.0074222377,-0.010149687,0.03226949,0.005317567,-0.015048875,-0.040266596,-0.003759025,0.009619527,0.015304373,0.013388133,-0.015074424,-0.041978437,-0.0029573976,-0.013592532,-0.002784936,0.0042891847,-0.008169571,-0.015483222,0.009332091,-0.009274603,-0.020043874,0.034620076,-0.008137634,0.00089664076,-0.0005189818,0.036485218,0.012155351,0.0067132288,0.050333247,-0.036255267,-0.0061958437,-0.0049151564,0.0046404954,-0.06361918,0.019839475,-0.0006251734,0.010705396,0.007096477,-0.0046756263,0.021270268,-0.028462557,0.008655019,0.021627966,-0.021461891,0.0042572473,0.022432787,-0.030378796,-0.01811486,0.027261712,0.011944565,0.026150294,0.02181959,-0.010021937,-0.0014108319,0.005413379,0.03183514,0.026009768,-0.02060597,0.023058759,0.044891123,-0.005892439,0.0494901,-0.02184514,-0.008974392,-0.030634295,-0.0054197665,0.014588976,0.0073264255,0.0074222377,0.0036568253,0.030506546,-0.0010491416,0.042872682,-0.025843695,-0.0013844837,-0.000453111,0.00046388985,0.027440561,0.021078644,-0.023020433,0.03755831,-0.010571259,-0.004605364,0.010168849,0.01288991,-0.006840978,-0.03221839,0.039806698,0.020669846,0.025345473,-0.014946675,-0.019302927,0.030225497,-0.02300766,0.004739501,-0.039142404,0.017795485,0.03957675,0.020350473,-0.018280933,0.022075089,-0.01778271,0.0062118126,0.014039654,0.0015497594,-0.008686956,-0.027312811,-0.0029350414,0.045427673,0.034824476,0.0028232608,-0.011612416,0.02409353,0.010328535,-0.029561201,-0.022918234,0.002831245,0.040470995,0.006553542,-0.03755831,-0.04729281,0.028104858,0.000116471485,-0.004305153,-0.010782045,0.019328477,-0.01791046,0.0005952322,-0.024451226,-0.015674846,-0.02169184,0.00041997602,-0.010705396,-0.009051042,-0.0034172952,-0.00847617,-0.0048257317,0.030506546,-0.013784155,0.028002659,0.020950895,-0.011695454,-0.006502442,-0.008635856,-0.0075308247,-0.011095031,-0.0050237435,0.0043275096,-0.03771161,0.014065204,0.010699009,-0.016760716,-0.0011361708,-0.017667735,-0.010520159,0.041876238,0.014282378,0.014780601,-0.019596752,0.011216394,0.014486777,-0.0049630627,-0.030966444,-0.016313592,-0.004273216,-0.0017294069,-0.013132634,-0.017565537,-0.01571317,0.026393017,0.03354698,-0.02169184,-0.009389577,-0.020720946,-0.0058764704,0.040215496,-0.03216729,0.026048094,0.007824648,-0.014039654,0.013311483,0.0051514925,0.032090638,-0.031451892,-0.0017613443,0.010756495,0.009389577,-0.039116852,-0.062494986,-0.0027769515,-0.025051648,0.044507876,0.028002659,-0.012787711,-0.020567646,0.019928899,0.021193618,-0.029433452,0.009798376,-0.007358363,-0.042285036,-0.015278823,-0.00691124,0.0118104275,0.021500217,-0.011970115,0.0120787015,-0.007019827,0.06510107,0.041186392,0.019596752,0.068831354,0.013784155,-0.015904795,-0.024502326,0.00081400294,0.019928899,-0.022483887,0.00074613607,-0.0059563136,0.017974334,0.004394578,0.019571202,0.04900465,0.0017837004,-0.009427902,-0.0048768315,0.0010211964,0.030864244,-0.035207722,0.023071533,-0.03720061,-0.036101967,0.0070006647,-0.0019465808,-0.0067771035,-0.004461646,0.005700815,-0.0051898174,-0.05406353,0.021423567,0.0002838431,0.011899852,0.03385358,-0.042642735,-0.013490332,-0.019124078,-0.0093640275,0.0020184398,-0.006266106,0.0091021415,-0.011139744,0.013860805,-0.0005313575,0.03564207,-0.0059722825,-0.019379577,-0.0109992195,0.072306134,0.010673459,0.028028209,-0.01374583,0.0046884012,-0.0129026845,-0.019775601,-0.022790486,0.014103529,-0.0032544148,0.028590307,0.011024769,0.028002659,0.008999942,0.05334813,-0.017769935,-0.044482324,-0.0019721307,-0.013707506,-0.02984225,-0.006122388,-0.0011697051,0.036485218,-0.004659658,-0.03354698,0.02169184,-0.010526547,-0.020414347,-0.014499552,0.022407237,-0.012168126,0.034722276,-0.01811486,-0.0050588744,0.016965114,0.0006088055,0.0064832796,0.0006682888,0.019750051,0.027006214,0.0296634,0.027389461,-0.0134392325,0.029561201,0.02060597,0.0039187116,-0.0297656,-0.008757219,-0.014269603,-0.032627184,0.011784878,0.0052856295,0.03354698,0.018434232,-0.01695234,0.00050979975,-0.02761941,0.013337033,-0.018383132,0.023582531,-0.034211278,0.01796156,-0.0031138905,-0.009312928,-0.0005165865,-0.015930345,-0.044150177,0.0065471544,-0.016543541,0.030276597,0.025639296,0.036740717,-0.0088338675,0.015777046,-0.0006515217,0.026073644,-0.020197174,0.04225949,0.0075116623,-0.015725946,-0.01879193,0.03155409,0.012315038,0.0029015073,0.016032545,-0.028948003,-0.01591757,0.016990663,-0.0019210309,0.044252377,-0.012915459,0.016173068,-0.008201509,-0.021781266,-0.013963005,0.012909072,-0.020120524,-0.02376138,-0.0031825558,0.014652851,-0.024412902,-0.0011529379,-0.011567704,0.01679904,0.0073008756,-0.0057678833,-0.03771161,0.009772826,-0.03569317,-0.00842507,-0.008642244,0.022445561,-0.008776381,-0.005109974,0.02257331,-0.032984883,0.0006914434,0.018498106,-0.0019641463,-0.006700454,0.008150409,0.012742998,0.019162403,0.009217116,0.00084713794,-0.016300818,0.023646405,0.0044456776,0.0030580002,-0.017169513,-0.019085754,0.058662504,-0.021998439,0.0030053037,-0.012097864,-0.015291598,-0.052198388,0.022662736,-0.00011078265,0.024630075,-0.024693951,0.01775716,-0.02275216,-0.0067643286,0.010104974,-0.009728113,-0.013707506,0.00037805826,0.018421456,0.017182289,0.005461285,0.014780601,0.045887567,-0.04169739,-0.018498106,0.028922454,0.008144021,0.0040400736,0.020299373,-0.036894012,0.00041438697,0.008699731,-0.008495332,-0.00055411283,0.017565537,0.012915459,0.008054597,-0.005138718,-0.025422122,-0.02282881,-0.0020934925,-0.030480996,0.033930227,-0.0035003324,0.003707925,-0.0074733375,-0.04353698,0.023148183,-0.02171739,0.002015246,0.002652396,-0.0058413395,0.013630856,0.0050940057,0.020542096,-0.018268159,-0.0001216613,0.002230823,-0.0297656,-0.0065375734,-0.015725946,-0.018932454,0.040138848,0.036306366,-0.011606029,0.024962224,0.0124364,-0.0045446833,-0.0075499867,0.044099078,-0.019698951,-0.017067313,-0.021500217,0.012685511,0.03962785,-0.0050365184,-0.0040464606,-0.028718054,-0.0025118717,0.013260383,0.010271048,0.011446342,-0.043409232,0.0012695092,-0.002016843,-0.006540767,0.01904743,0.025243273,0.0032352523,-0.017118413,-0.00039742026,0.02293101,0.00064233976,0.021283044,0.040854245,-0.015381022,-0.00046588594,0.004423321,-0.0005245708,-0.06530547,-0.0126216365,0.03809486,0.020273823,-0.024055203,0.030557645,-0.0060201883,-0.019622302,-0.00083595986,-0.008144021,0.012085089,0.009402352,0.001884303,0.023403682,0.026316367,-0.026725166,-0.016709616,-0.0037238938,0.0104498975,-0.045121074,-0.012174513,-0.0077735484,0.0021924984,0.01695234,0.0118232025,0.044405676,-0.021334141,0.03198844,-0.014844475,0.029433452,-0.046143066,-0.026776265,-0.030251047,0.048646953,0.036970664,0.005569872,0.00011607227,0.012519437,0.022943784,-0.016351918,-0.0024448032,-0.004739501,-0.017118413,0.034926675,-0.00018693323,0.03160519,-0.011663516,-0.0012806873,0.036638517,0.005266467,-0.024272377,-0.023365358,0.0015050471,0.015202173,-0.046168618,-0.0019098528,0.006687679,0.015138298,-0.016505217,-0.019520102,0.017322812,0.004033686,-0.0007704883,-0.02779826,0.0014850863,0.027977109,0.020452673,0.03147744,0.024004104,-0.005400604,-0.015828146,0.013566982,0.007556374,0.016403018,0.016326368,0.04156964,0.03367473,0.040470995,-0.013630856,0.012404462,0.005569872,-0.010009162,0.015470447,0.03232059,-0.005726365,0.028028209,0.00038903672,0.012979334,-0.012589699,-0.01190624,0.028002659,0.016390242,-0.0044967774,0.04121194,-0.018549206,-0.040752046,0.00032635967,-0.052479435,-0.013886355,-0.016364692,-0.056056418,0.00022994884,-0.029407902,0.013145409,-0.025575422,-0.011657129,0.035948668,-0.03344478,0.020899795,-0.030480996,0.015534322,0.013049597,0.0051035867,0.06310818,-0.00786936,0.014997775,0.0030292566,-0.030404346,0.0096450765,0.02275216,0.026137518,-0.009223503,0.019762825,-0.0063427556,0.057180613,0.0026603804,-0.036485218,-0.009862251,-0.023390908,-0.039244603,0.028973553,-0.031017544,-0.024527876,0.0134264575,0.0071156393,0.04920905,-0.013222058,-0.04133969,0.0054197665,-0.001241564,-0.03543767,-0.018485332,-0.0073136506,0.017552761,-0.026648516,-0.028666956,0.0067771035,0.0020631521,0.013081534,0.0142440535,0.014141854,-0.010545709,-0.014818925,0.0072050635,-0.02790046,0.0033342582,0.01034131,-0.0038612243,0.025281597,-0.018293709]	492
12	5	luscious fillings. Custom Celebration Cakes — Bespoke cakes designed for birthdays, weddings, anniversaries, and corporate events. Every creation is unique. Macarons — Delicate French macarons in rotating flavours, perfect for gifting or personal indulgence. Our Services 1. Walk-In &amp; Daily Selection Visit our shop to browse our freshly baked selection. Our display features croissants, tarts, cakes slices, cookies, and seasonal specialties. First come, first served — popular items sell out quickly! 2. Pre-Orders Want to guarantee your favourites? Pre-order via WhatsApp at least 1 day in advance for pastries, or 3 days for custom cakes. Pre-orders ensure we set aside exactly what you need. 3. Custom Cakes &amp; Celebration Orders From minimalist buttercream designs to elaborate fondant creations, we craft custom cakes for all occasions. Share your vision with us, and we&#039;ll bring it to life. Wedding cakes, corporate events, and large orders are welcome. 4. Local Delivery We deliver within the Kluang area. Delivery fees range from RM8-RM15 depending on distance. Orders above RM150 enjoy free delivery. Cakes are carefully transported to ensure they arrive in perfect condition. 5. Gift Boxes &amp; Corporate Gifting Looking for the perfect gift? Our curated gift boxes include assorted pastries, macarons, and cookies in beautiful packaging. Corporate bulk orders and festive hampers available upon request. Operating Hours *Hours may vary during public holidays. Follow our Instagram for updates. Contact Us Address: No. 23, Jalan Mawar 3, Taman Bunga Raya, 86000 Kluang, Johor, Malaysia Phone / WhatsApp: +60 12-345 6789 Email: hello@jqpatisserie.com Instagram: @j.q_patisserie Facebook: J.Q Patisserie — Every bite, a moment of joy —	1	2025-12-21 23:53:34	2025-12-21 23:53:34	[0.047119744,0.006445855,0.013985258,-0.02578342,0.018553855,-0.052538883,-0.004595937,0.019404393,-0.039003193,-0.006464081,0.0021491246,-0.06930661,0.0049938667,0.012466441,-0.012150528,0.06848037,-0.008140854,-0.0022053209,0.024981484,0.017618265,0.044349425,0.012186979,0.009131121,0.015977943,0.012180904,0.0068711233,-0.0321746,0.0018195416,0.0276303,-0.009532088,0.016075147,-0.0041797813,0.0037119861,0.008414241,0.0033808842,-0.0006842266,0.0018089098,0.005774538,-0.027508795,0.051275227,-0.04289136,-0.0028189225,0.036062766,0.036791798,0.007958596,0.009173648,-0.028407933,0.013146871,-0.029307073,0.044300824,0.015722783,0.06240511,-0.025127292,-1.2020005e-05,9.226807e-05,0.003921583,-0.0391976,0.011549076,0.03776384,0.02026708,-0.014860095,-0.03154277,-0.013778699,-0.0322232,0.008444617,-0.02098396,-0.028650943,0.028942557,-0.03198019,0.045904692,-0.002023063,-0.009313379,-0.033073734,-0.032782122,-0.012193054,-0.030109007,0.033924274,0.033511154,0.0086147245,-0.023559872,-0.011555152,0.0057563125,-0.009343755,0.037690938,0.027338687,-0.054482967,-0.045272864,0.027508795,-0.04911243,0.062162098,0.05739909,-0.013402032,-0.010504131,-0.0090946695,0.050837807,0.011956119,-0.023620626,0.017776221,-0.020789552,0.046901036,0.051323827,-0.06357156,-0.0055163396,-0.045418672,0.051032215,-0.007861392,0.016998587,-0.017363103,-0.03266062,-0.016524717,-0.07280596,-0.00817123,-0.011293915,0.011348593,0.004185857,0.023815034,0.026196538,-0.06386317,0.020643746,-0.018104287,-0.011445797,0.007673058,-0.004702254,-0.02166439,-0.0148722455,-0.03266062,-0.048116088,-0.027338687,0.010151766,-0.0120837,-0.020242779,-0.018602457,0.05414275,-0.02806772,-0.0027277935,-0.035358034,0.043693297,0.024823528,-0.05739909,0.025661914,0.055212,-0.028893955,-0.016512567,0.027654601,-0.008262359,-0.0013995889,-0.073534995,-0.03499352,-0.020789552,0.07236854,-0.040485557,-0.0087909065,-0.045442972,-0.031469867,-0.03499352,-0.0040005613,0.01612375,0.053122107,-0.03982943,0.005397872,0.0014345216,0.013073968,0.004228384,-0.019963317,0.011166335,-0.021226972,0.012114076,0.054920383,-0.023426218,-0.050303183,0.018796867,-0.023596324,0.022271916,0.02670686,-0.027970515,-0.00020257208,0.013960957,-0.0012963094,-0.014058161,0.013535688,0.011050905,0.052393075,0.022539228,-0.020182027,-0.0049209637,0.029865997,0.030230513,-0.03266062,-0.0008961014,0.02507869,0.0022493664,-0.026075032,0.004225346,-0.009805475,0.020546542,-0.019052027,0.028237825,0.051712647,-0.01912493,0.04954985,-0.06775134,-0.010042411,0.039756525,0.034215886,0.029404277,-0.016148051,0.0025014898,0.009677895,0.0369133,-0.017192997,0.074604236,0.0044167168,0.0045442972,0.026075032,-0.0015734934,0.0033656962,-0.044616736,0.011992571,-0.0005505708,0.026876967,-0.0144226765,0.038565774,0.046415016,0.0068468223,-0.016184503,0.0072660153,0.012235581,-0.014532031,-0.018286545,-0.035746854,0.0020762214,0.012673,-0.0068893493,-0.002458963,-0.04242964,0.010139615,-0.015406869,-0.038371366,0.047630068,-0.041530505,0.009319454,0.01936794,-0.0253217,0.025856324,0.037253518,-0.014021709,0.0068528973,-0.036743194,0.013292677,-0.01797063,0.054531567,-0.03244191,-0.04510276,-0.015333965,0.035576746,-0.010498056,-0.00013156743,-0.012478592,0.05555221,-0.029452879,0.018019233,0.0004928558,-0.010212518,-0.01426472,0.017083641,-0.003945884,-0.03735072,0.0054981136,-0.0033656962,0.007770262,-0.04626921,-0.061190058,0.040364053,0.048116088,0.028893955,-0.018784715,0.007180962,-0.012721603,0.028164923,0.014860095,-0.024932882,-0.02806772,-0.0024118798,-0.07494445,-0.0043833028,0.011792087,0.036062766,-0.04026685,-0.040607065,0.013851602,-0.004684028,-0.035455238,-0.021226972,-0.00052551035,0.019161383,0.011160259,-0.035115026,-0.028140621,0.020473639,0.013936655,-0.027533095,0.0019380092,-0.03615997,0.001241632,-0.03618427,0.046415016,0.0022873369,0.047605768,0.02648815,0.01059526,0.0016539906,0.020327833,0.0003290135,-0.04427652,0.021287724,0.0036026314,0.03433739,0.015783535,0.033948574,-0.0483834,0.07659692,-0.008092252,-0.041554805,0.009143272,-0.025224496,-0.052636087,0.05477458,0.007673058,0.01654902,-0.026196538,0.04102018,-0.047532864,-0.01889407,0.005956796,-0.003930696,0.01196827,0.032077394,-0.03521223,0.0088577345,0.021627938,-0.007770262,-0.046828132,0.010868647,-0.06940381,0.02624514,-0.015394718,0.049865764,0.06969543,0.0012545419,0.028723847,-0.048407704,0.0031652125,-0.01984181,0.013499236,0.006099565,-0.029307073,0.06745973,0.0063486504,-0.058468338,0.029258471,-0.0042466093,-0.023061702,0.03407008,-0.015795685,-0.02049794,0.0038091904,-0.010139615,0.005163974,-0.0023222696,-0.0046384637,-0.019076329,0.030327717,0.0042162333,-0.04882082,-0.06104425,-0.0230131,-0.019270737,0.045467272,0.06493242,0.0003519856,0.0828666,-0.014240419,0.059294574,0.04281846,0.04196792,-0.0146049345,0.025467506,0.012685151,0.041554805,-0.055114795,0.020595144,-0.02074095,0.026099334,0.0160873,0.013985258,0.0016251331,0.04561308,-0.030011803,-0.0053249686,-0.01106913,-0.027970515,-0.020777402,-0.0053340816,0.005677334,0.009756873,0.0038152656,-0.02877245,-0.026658257,-0.0086633265,0.034434594,-0.026536752,-0.0072660153,-0.027800407,-0.0086147245,-0.002056477,-0.048869424,0.035989862,0.016743427,-0.015005901,-0.0043833028,-0.043839104,-0.05414275,-0.036305778,-0.004766044,-0.015115256,0.0073875207,0.0145806335,-0.06332855,-0.0369133,-0.0219074,-0.03355976,-0.018371597,-0.030230513,-0.038079754,-0.013061817,-0.005716823,-0.020534392,-0.05112942,-0.0026427398,-0.029477179,0.015103105,0.049015228,0.030546427,0.034167282,-0.011348593,0.011925743,-0.0013107382,-0.007180962,0.019282887,-0.021627938,-0.04053416,0.0020610332,0.020194177,-0.027533095,-0.058176726,0.04908813,0.019793209,-0.041117385,-0.020388585,-0.07402101,0.041287493,0.005403947,0.007442198,0.034726206,0.033292446,-0.011105582,-0.035868358,0.0022508851,0.05501759,0.022077508,-0.012879559,-0.0070351553,0.025418904,0.01358429,-0.028869653,0.026318043,-0.040436957,-0.00838994,-0.022442024,-0.010668163,-0.026220838,0.02347482,-0.04442233,-0.006108678,-0.047168348,-0.028213525,0.024386108,0.017630415,-0.015844287,0.0072477898,-0.07654832,0.036524486,0.00863295,-0.010947625,0.005774538,-0.008377789,0.028893955,-0.024106646,-0.026342344,0.006950102,0.013134721,-0.04913673,0.03336535,0.036961906,0.013450634,0.036232874,0.018274393,0.005716823,0.0065248334,0.007624456,-0.006725317,0.03171288,-0.02165224,-0.0043468513,0.00039337334,0.026099334,-0.027557397,0.029768793,-0.03336535,-0.019064177,-0.015710631,-0.006050963,0.0073085423,-0.046172004,-0.0017800523,-0.016755577,0.005619619,-0.040679965,0.015576976,-0.061141454,0.011105582,-0.026609655,-0.007557628,0.0018119474,-0.032150295,0.015005901,-0.02026708,0.005081958,-0.016427513,-0.0042860988,-0.006858973,0.042502545,-0.012029022,-0.0003998283,-0.013377731,-0.0013077005,0.037423626,-0.027265783,-0.009167573,0.019926865,0.025686216,0.020680198,0.0024559253,0.008675477,0.03202879,-0.0002855374,-0.00022801224,0.009173648,0.03961072,0.03290363,0.023657078,0.0195988,-0.015589127,0.017861275,0.01381515,0.008201607,0.018796867,0.042672653,-0.020595144,-0.011354668,-0.016658373,0.075430475,0.02670686,-0.021081164,0.0012856777,0.0088395085,-0.008359563,-0.0034385994,-0.019161383,0.018699663,-0.017375255,-0.0088455845,-0.050060175,-0.003417336,-0.0071202093,0.015261062,0.0036876851,-0.0046566897,0.011142034,0.0391733,0.018699663,0.008493219,-0.0077095097,0.003037632,-0.0029404277,-0.011725259,-0.046682328,0.004504808,0.009331605,-0.021069014,-0.021239122,0.0460748,-0.046633724,-0.026585354,-0.047775876,-0.010820045,0.009598916,0.0027156428,0.011239238,-0.027460191,0.029671589,-0.00575935,0.015759233,-0.02670686,-0.021567186,-0.012004721,-0.040023837,-0.006372952,0.005719861,-0.0015750121,0.015297514,0.02488428,0.033535454,0.021931702,-0.0036087066,0.03314664,0.021810196,-0.028213525,-0.02787331,-0.0013859195,0.022442024,0.023596324,-0.005197388,-0.0075029507,0.03737502,-0.021688692,0.022186864,-0.004109916,0.00073700544,-0.020376435,-0.00645193,0.014908697,0.032733522,-0.04629351,0.00804365,0.006148167,0.01242999,-0.017557513,0.025054388,-0.017861275,0.029112665,0.0046718777,0.006132979,-0.03482341,2.6294501e-05,0.027241483,0.035795454,-0.0028690433,0.014386225,0.03783674,-0.0017724582,0.0149451485,0.011725259,0.0033717714,0.018079985,0.030327717,0.015795685,-0.04882082,0.02071665,-0.011123808,0.027022773,0.037447926,0.07256295,0.0035509916,-0.028796751,0.006518758,-0.0008300329,-0.013948806,0.010388701,-0.012053323,0.0044622812,-0.022077508,-0.038079754,0.005725936,-0.013960957,-0.004094728,0.037618034,0.024544066,0.01612375,0.010473755,0.0064397794,-0.01163413,0.027314385,-0.023584174,0.017739771,0.0065005324,0.017107943,0.015309664,-0.023887938,-0.10410572,0.003465938,-0.026731161,-0.012770205,0.023596324,-0.0010396296,0.036524486,-0.04976856,-0.028723847,0.01654902,-0.0044410178,0.0068954243,0.012193054,-0.008772681,0.03611137,-0.011895367,-0.014434827,-0.02258783,-0.039440613,0.022599982,0.0029404277,-0.006421554,0.030595029,0.0063365,-0.040193945,0.028675245,0.02140923,-0.0086207995,1.5283085e-05,0.028189223,0.018796867,-0.015905041,0.008566122,0.030060405,0.0219074,-0.016306007,-0.0035631421,-0.016658373,0.013511387,-0.02349912,-0.01701074,0.0047144047,0.0027961403,-0.016038697,0.00015131204,0.0019774984,0.012770205,0.026974171,-0.009459185,-0.03263632,0.01634246,0.023183206,0.009355906,0.012964613,-0.002961691,-0.03312234,-0.04532147,0.023985142,0.011585528,0.011129883,-0.002903976,0.0087787565,0.029622987,0.0076609077,0.007964671,0.012241657,-0.0045503727,0.03803115,-0.012047248,-0.015176009,-0.029647287,-0.009155422,-0.034264486,0.022466326,0.014094612,0.010036335,-0.0076852087,0.018335147,0.021530734,-0.0046749157,0.002574393,0.06303693,-0.010716765,0.040436957,-0.038395666,-0.019185683,-0.045394372,0.03659739,-0.04119029,-0.020558693,-0.04235674,0.027484493,-0.0041645933,0.011901442,-0.019550199,-0.0067617684,-0.00781279,0.018371597,-0.032782122,-0.0025424978,-0.012029022,0.006038812,-0.019440845,-0.03594126,-0.03246621,-0.0074057467,0.035625346,-0.012721603,0.08155434,0.0148722455,0.0016327271,0.01982966,-0.01185284,-0.018517405,-0.016719125,-0.0044197543,-0.02258783,0.009926981,0.02049794,-0.006676715,0.003259379,0.07125069,0.023462668,-0.032830726,0.022842992,-0.013632892,-0.010753217,-0.018031383,-0.002170388,-0.031810082,-0.009762949,-0.010327948,-0.028407933,-0.01024897,-0.00040324562,0.004513921,-0.016220955,-0.031931587,0.0042891363,-0.017132243,0.02600213,-0.0068528973,-0.020133425,-0.00020162281,0.012770205,-0.0014527475,0.005091071,0.0090703685,0.0040157493,0.0017846087,0.04284276,-0.0020792591,-0.013171172,0.034142982,0.0015674181,-0.0065491344,0.02648815,0.0066402634,-0.024799226,-0.0047478187,-0.016415363,-0.027581697,0.018578157,0.001922821,0.001485402,0.010297572,0.009987733,-0.0086390255,0.012010797,-0.0059142695,0.033948574,-0.0011072168,-0.03385137,-0.0044197543,-0.02211396,0.009319454,0.026536752,-0.015346116,-0.0147750415,-0.014167516,-0.044786844,0.048869424,0.008541821,0.01231456,0.0092100995,-0.027703203,0.047557164,0.014410526,0.015734933,-0.011397195,-0.012685151,-0.002276705,0.027946213,0.014167516,-0.03477481,-0.0146656865,0.012393538,0.035746854,0.030011803,0.0089913905,-0.001617539,-0.024750624,-0.006047925,-0.018614609,0.0019759797,-0.012843108,-0.00062043633,0.010242894,0.0030102932,-0.001085194,-0.0077095097,0.03266062,-0.016403213,-0.017642567,-0.011555152,0.05642705,0.010188217,-0.01426472,0.046390716,-0.038590077,-0.0007525733,0.017715469,-0.005595318,-0.051518235,0.02348697,-0.01196827,0.00804365,0.009696121,-0.00840209,0.025175894,-0.023754282,0.032587714,0.015990095,-0.013134721,-0.011962194,0.027192881,-0.03844427,0.013244075,0.011743485,-0.007873542,0.042065125,0.008201607,-0.005340157,-4.729688e-05,-0.0046992167,0.056086835,0.045442972,-0.012114076,0.011640205,0.026342344,-0.016293857,0.025929226,-0.047071144,-0.0043468513,-0.025661914,-0.0276303,0.037739538,0.0015378011,0.016731277,0.005388759,0.042696953,-0.007654832,0.011202786,-0.013207624,-0.000437419,0.025516108,-0.005461662,0.027362987,0.023341164,-0.0012522638,0.028845353,0.0017572701,0.010273271,-0.015224611,0.0047235177,-0.026099334,-0.035115026,0.016366761,0.0087180035,0.04352319,-0.005835291,0.0050880336,0.057253286,-0.022988798,0.0012484667,-0.027338687,0.009854078,0.051518235,0.00043134374,0.006767844,-0.00054563466,-0.008153004,-0.010741066,0.017059341,-0.005273329,-0.013875903,-0.027533095,-0.0061998065,0.054725975,0.01958665,0.023985142,-0.010291497,-0.0063851024,0.03205309,-0.025953528,-0.007867467,-0.009957357,0.03822556,-0.004984754,-0.021591488,-0.050692,0.024082346,-0.01049198,-0.003532766,-0.004769082,0.012180904,-0.011257464,-0.013134721,-0.023608476,-0.022636432,-0.01543117,0.0020944471,-0.0074543487,-0.025491808,-0.00838994,-0.004301287,-0.030789437,0.026998471,0.0025561673,0.025370302,0.01631816,-0.012648699,0.011998646,-0.01426472,-0.0031500242,-0.0071870373,-0.0033322822,0.010188217,-0.033316746,0.0038213409,0.010929399,-0.01562558,-0.004243572,0.0004480507,-0.024143098,0.022903744,0.018092135,0.018942673,-0.022369122,0.013499236,0.02831073,-0.009149347,-0.03309804,-0.0056560705,-0.0016312083,-0.0027156428,-0.017083641,-0.022320518,0.0087301545,0.016901383,0.015139557,-0.02281869,0.006096527,-0.008195531,-0.0017192997,0.04262405,-0.005461662,-0.0048389477,-0.013377731,0.00062233483,0.010613486,-0.010813969,0.034847714,-0.03890599,0.014216118,0.012278108,0.019939017,-0.039732225,-0.0759165,0.0043438138,-0.009283003,0.018152889,0.046366412,-0.021810196,-0.017083641,-0.0013023847,0.015990095,-0.01935579,0.0022994874,0.0077338107,-0.048966628,0.020182027,0.013171172,0.0045928992,0.038104054,-0.018833317,-0.0027824708,0.024762776,0.054968987,0.004398491,0.01635461,0.05783651,0.013450634,-0.014993751,-0.021056864,-0.001972942,0.017350953,-0.016172351,0.0016038696,-0.010279346,0.017095793,0.009945207,0.021348476,0.051323827,-0.0054646996,0.009611067,-0.0013388363,0.009374132,0.052247267,-0.0460505,0.0321989,-0.037423626,-0.011378969,-0.00055740547,-0.0030892717,-0.0017724582,-0.007630531,-0.015613428,0.023900088,-0.054725975,0.009149347,-0.0067982203,-0.006877199,0.024471162,-0.03343825,-0.02302525,-0.017472459,-0.0048055337,0.027362987,-0.0025759118,-0.0018058722,0.0086207995,0.016451815,-0.009240476,0.0299389,-0.03066793,-0.021773746,0.015127406,0.07693714,0.02556471,0.016646223,-0.008153004,-0.008420316,-0.015127406,-0.018262243,-0.026998471,0.001848399,-0.011834614,0.021469982,-0.030522125,0.017229449,0.0060691885,0.0529277,-0.019756759,-0.03477481,-0.01426472,0.016245255,-0.02901546,-0.006181581,0.013523537,0.04281846,-0.0005615822,-0.014325472,0.016220955,-0.014908697,-0.036961906,-0.046390716,0.036475882,-0.016889233,0.03778814,-0.020923208,0.0039398083,0.008772681,-0.03871158,0.011196711,-0.006354726,0.02257568,0.008705853,-0.0031621747,0.027921913,-0.014167516,0.044179317,0.016062997,-0.009884454,-0.02741159,-0.037885346,0.0036299701,-0.026561053,0.017666867,-0.004085615,0.010346174,0.007946445,-0.02212611,-0.029841695,-0.0023936538,0.0090399925,-0.028164923,-0.0090399925,-0.025977828,0.041749213,0.0052247266,-0.010510206,0.0012628954,0.01450773,-0.056329846,0.012709452,-0.018286545,0.03846857,0.012016872,0.023887938,-0.013110419,0.025759118,-0.01982966,0.0048541357,-0.024216002,0.031955887,0.013049667,-0.023851486,-0.009823701,0.03205309,0.01496945,-0.0006975162,-0.004735668,-0.050254583,-0.01562558,0.02901546,-0.016257405,0.039513517,-0.023644926,0.028286427,-0.020461489,-0.021141918,-0.021773746,0.02371783,-0.031469867,-0.013183323,-0.004890587,-0.0052915546,-0.0011459467,-0.0054920386,0.0030680082,0.012648699,0.013924505,3.673636e-05,-0.036889,0.003885131,-0.06945241,-0.030838039,-0.023183206,0.0025865436,-0.0002559205,-0.00077421643,0.014143214,-0.014094612,-0.022442024,0.034969218,0.0016220955,-0.019477297,0.02325611,0.030716533,0.009191874,0.026512451,0.010601335,-0.010528432,0.053510923,0.01566203,-0.0032077392,-0.012454291,-0.009550314,0.051712647,-0.0036269324,-0.010929399,-0.020582994,-0.016609771,-0.034191586,0.016391061,0.0072417143,0.0149208475,-0.032879326,0.04743566,-0.022539228,-0.007843166,-0.024033744,-0.0042466093,-0.01403386,0.011585528,0.02281869,-0.010911174,0.0146170845,-0.010990152,0.02094751,-0.008298811,-0.022405572,0.03249051,0.0068285963,0.016451815,0.023863636,-0.03800685,0.0007525733,-0.0055801296,-0.012272033,0.0013745284,-0.0042162333,-0.015564825,0.0077824127,-0.010880797,-0.043085773,0.009744723,-0.005774538,-0.02347482,0.030327717,-0.008365639,0.008031499,-0.014131064,-0.04396061,0.018784715,-0.028650943,0.0014428751,-0.023329012,-0.0020747026,-0.0054312856,-0.0053766086,0.0031834382,-0.022952346,-0.03389997,-0.0064762314,-0.01656117,-0.008104402,-0.0033322822,-0.013073968,0.0145441815,0.01586859,0.020303532,0.0071019833,0.0063608014,0.019088479,-0.012940312,0.01703504,-0.017095793,-0.017751921,-0.034556102,-0.00990268,0.024325356,-0.00945311,0.012673,-0.034556102,-0.003268492,0.021287724,0.017180845,0.007885693,-0.046755232,-0.007515101,0.012016872,0.014155365,0.01914923,0.035017822,0.006032737,-0.0368647,0.023766432,0.020133425,-0.02554041,0.010115314,0.011919668,-0.0077945637,-0.00011780316,-0.006536984,0.011609829,-0.018566007,0.017958479,0.033802766,0.012843108,-0.0017268937,0.015564825,0.006057038,-0.008165155,0.00055740547,-0.00054715347,0.0040005613,-0.004325588,-0.0012036617,0.0073753702,-0.0009963432,-0.03132406,-0.0017952404,0.016500417,0.016706975,-0.04437373,-0.04026685,-0.024726324,-0.017776221,0.036451582,0.0033687337,0.022842992,-0.021555036,0.039950933,-0.0014018671,0.04165201,-0.0415062,-0.04420362,0.0027171618,0.032393306,0.018055685,-0.00067967013,0.006658489,0.0042466093,0.03341395,0.016925685,0.018031383,-0.025175894,-0.01701074,0.020996112,-0.0048541357,0.009143272,-0.008262359,-0.004775157,0.0018635872,0.027265783,-0.015759233,-0.002276705,0.022842992,-0.009872303,-0.02580772,-0.027047073,-0.00407954,0.018942673,-0.0076609077,-0.009216175,0.009483486,0.016148051,-0.0013449115,-0.03428879,0.012563646,0.016427513,0.021919552,0.019902565,0.012144452,0.0022356971,-0.0041220663,0.02462912,0.0023480894,0.008420316,0.023171056,0.05278189,0.03936771,0.039319105,0.027047073,0.0005126004,0.0055163396,-0.019926865,-0.0044926577,0.013171172,-0.0010259602,-0.00096596696,-0.0058383285,0.010862571,0.0032472285,0.006518758,0.037472226,0.017654717,0.02351127,0.028748149,0.0057046725,-0.054239955,0.0028492988,-0.050108775,-0.022089658,-0.0005741124,-0.0506434,-0.012399613,-0.015905041,-0.003301906,-0.01083827,-0.014301171,0.038079754,-0.044568136,0.031931587,-0.002483264,-0.006470156,0.005835291,-0.007180962,0.019307189,-0.010643862,0.0160873,0.019939017,-0.011214937,0.0087180035,0.016901383,0.012029022,-0.024216002,0.022004606,0.019197833,0.048407704,-0.009544239,-0.03888169,-0.008335262,-0.02600213,-0.040874373,0.028335031,-0.037447926,-0.03020621,0.021506434,0.011081281,0.055600815,-0.02464127,-0.029793093,-0.0017815711,0.01585644,-0.031931587,-0.00065385026,0.0033808842,0.03309804,-0.01980536,-0.02507869,0.0011907517,0.0006944786,-0.0023572023,0.005941608,0.013365581,-0.008560047,-0.014811493,0.011451872,-0.0064094034,-0.0026670408,0.011111657,-0.001998762,-0.005750237,-0.005801877]	442
13	6	J.Q PATISSERIE Customer Guide & Frequently Asked Questions Welcome to J.Q Patisserie! This guide answers our most commonly asked questions to help you with ordering, custom cakes, and more. General Questions Q: Where is J.Q Patisserie located? A: We're located at No. 23, Jalan Mawar 3, Taman Bunga Raya, 86000 Kluang, Johor, Malaysia. Look for the cream-coloured shophouse with our signature brown logo! Q: What are your operating hours? A: Tuesday to Friday: 10:00 AM - 7:00 PM | Saturday & Sunday: 9:00 AM - 8:00 PM | Monday: CLOSED. Hours may vary on public holidays — check our Instagram for updates. Q: Do I need to make a reservation to visit? A: No reservation needed for walk-ins! However, popular items sell out quickly, especially on weekends. For guaranteed availability, we recommend pre-ordering. Q: Is parking available? A: Yes, free street parking is available directly in front of our shop and along Jalan Mawar. Ordering & Pre-Orders Q: How do I place a pre-order? A: WhatsApp us at +60 12-345 6789 with your order details. For regular pastries, order at least 1 day in advance. For custom cakes, minimum 3 days advance notice is required. Q: What payment methods do you accept? A: We accept Cash, Credit/Debit Cards, Touch 'n Go eWallet, GrabPay, and DuitNow QR. Bank transfer is also available for pre-orders. Q: Do you require a deposit for custom cakes? A: Yes, we require a 50% deposit to confirm your custom cake order. The remaining balance is payable upon collection. Q: Can I cancel or modify my order? A: Orders can be modified up to 48 hours before the collection date. Cancellations made less than 48 hours in advance may forfeit the deposit as ingredients would have been purchased. Products & Menu Q: What is your specialty? A: We're known for our Burnt Basque Cheesecake, handcrafted croissants (48-hour laminated dough!), and French tarts. Our macarons and custom celebration cakes are also customer favourites. Q: Are your products halal?	0	2025-12-21 23:53:40	2025-12-21 23:53:40	[0.0102506755,0.016000133,0.014297991,-0.0490469,-0.0010977238,-0.027007315,-0.019555718,0.01716011,-0.035429765,-0.020287007,-0.007817243,-0.07030476,-0.008271148,0.029075103,-0.05371203,0.039994027,-0.0035997145,0.0060299947,0.024863878,0.02582212,0.042112246,0.0060835807,-0.010364152,0.01262737,0.0038518838,0.036438443,-0.040498365,-0.02434693,0.010238067,-0.0049677324,0.024460407,0.0069913897,-0.026679495,0.015861439,-3.1422638e-05,-0.0353289,-0.016201867,-0.008012675,-0.014613202,0.034648042,-0.052602485,0.00711117,0.015621878,0.011303482,-0.0015067107,0.037623636,-0.012898452,0.01197173,-0.030613335,0.0491982,0.048239958,0.05295552,-0.036741044,0.028142076,0.014537551,-0.008699835,-0.021787414,0.0058597806,0.047433015,0.022531314,0.016907942,-0.040977485,-0.008189193,-0.031117672,0.012022164,-0.0031647228,-0.0070985616,0.035101946,-0.019480066,0.043095708,-0.010502845,0.000179178,-0.0023987591,-0.032555036,-0.011492609,0.0025500604,0.03293329,0.020955255,0.02705775,-0.024586491,-0.0032309173,-0.004356222,-0.0021245251,0.042213116,0.030915938,-0.026326459,-0.07338122,0.007470511,-0.052098148,0.038960133,0.052753784,0.010553279,-0.029201187,0.012148249,0.08084543,-0.022190886,-0.019770062,0.02190089,-0.015508402,-0.018118354,0.022745658,-0.07590292,-0.012217595,-0.020967865,0.06621962,-0.0023451732,-0.020665262,0.010263285,-0.02264479,-0.037094083,-0.048189525,-0.030386383,-0.0023435971,0.014411467,0.007817243,0.027587304,0.033639364,-0.06415183,0.020211358,-0.04488611,-0.02231697,0.009954377,0.013705393,-0.016781857,-0.015974915,-0.0271334,-0.055174608,-0.03227765,0.0011662823,0.0056170677,-0.011593477,-0.0442809,0.028671632,-0.04470959,0.0049488195,-0.03336198,0.037094083,0.0403975,-0.059965823,-0.00606782,0.038934916,-0.013818869,-0.036514092,0.0048038224,-0.024132587,-0.018446174,-0.041507043,-0.037623636,-0.030184647,0.05214858,0.013944954,-0.024409974,-0.026376892,-0.048164308,-0.039893158,0.015268842,0.0038140584,0.056031983,-0.035001077,0.007779418,-0.02786469,0.01528145,0.031596795,-0.041002702,-0.0009290857,-0.048315607,0.024006503,0.026023855,-0.025141263,-0.014777112,-0.010313719,-0.008863745,0.030335948,0.0094248215,-0.027889907,0.04299484,0.022102626,-0.017639231,-0.00347363,-0.009248303,-0.02091743,0.0608232,0.04945037,-0.037043646,-0.0032750468,0.011152181,-0.019795278,-0.030310731,-0.032075915,0.01462581,0.025544735,-0.014852763,-0.013541483,-0.020778738,0.032302868,-0.061075367,0.042818323,0.0023278364,-0.044028733,0.050484262,-0.04160791,0.010836969,0.030108996,0.024157804,0.01577318,-0.014449292,0.029453356,-0.025116047,0.02124525,-0.045718268,0.07373426,0.03729582,0.008252235,0.06521094,0.017588798,0.037976675,-0.05116512,0.02500257,-0.011719561,0.011139572,-0.010187633,0.012677804,0.025368216,0.009897639,-0.024019111,0.009966985,0.025948206,0.016807074,0.038354926,-0.039136652,-0.020236574,0.02166133,0.006676178,0.018597474,-0.022001758,-0.0014019029,-0.034194138,-0.040851403,0.018773993,-0.061983176,0.01635317,0.063496195,-0.013970171,0.04887038,0.057091095,-0.016479254,-0.010704581,-0.053964198,0.027612522,-0.021396551,0.027990775,-0.050030358,-0.015155366,-0.0089330925,0.025443867,0.0049109943,-0.008372015,-0.027032532,0.027309919,-0.027335135,0.026452543,0.03686713,0.017235762,-0.015886657,0.020740913,0.008895267,-0.0120662935,-0.027436003,-0.028293379,0.020223966,-0.03457239,-0.026351675,0.042137463,0.04332266,-0.007281384,-0.001902301,-0.018370522,-0.0050749043,0.0063231415,0.010036332,-0.04773562,-0.032479387,-0.00084003847,-0.03996881,-0.002619407,0.015155366,0.039767075,-0.022581747,-0.04423047,0.039716642,0.004078836,-0.036009755,-0.021510027,0.011278265,0.037648853,0.007003998,-0.00055280206,-0.018748777,0.043751348,0.03157158,-0.027436003,0.016466646,-0.031193323,0.0034421089,-0.038203627,0.0442809,-0.013087579,0.074339464,8.9589e-05,-0.0048258873,0.0057715215,0.010023723,0.032378517,-0.041330524,-0.014688853,0.007079649,0.011549347,0.017172718,0.009607645,-0.030865503,0.07151517,-0.0037447119,-0.029680308,0.02975596,-0.046046086,-0.046146955,0.037749723,-0.0013183719,-0.01478972,-0.011347611,0.031596795,-0.048239958,-0.027335135,-0.019265722,-0.04733215,0.04470959,0.0106352335,-0.0003999245,-0.035177596,0.0078361565,-0.009954377,-0.036614962,0.0020189292,-0.05850324,-0.0029866283,-0.022922175,0.036514092,0.03981751,-0.0031899398,0.019997014,-0.055779815,0.0439783,-0.02819251,-0.0014121472,0.04544088,-0.013806261,0.056183286,0.016655773,-0.060520597,0.01978267,-0.031193323,-0.01462581,-0.00071001373,0.021068731,0.008264843,0.01987093,-0.018395739,-0.016479254,0.016819682,-0.030134212,-0.03777494,0.025355607,0.008264843,-0.037220165,-0.07948372,-0.031596795,-0.027965559,0.035278462,0.057242397,0.02975596,0.069296084,-0.032479387,0.05704066,0.015155366,0.05035818,-0.021371335,0.028822934,-0.017588798,0.03008378,-0.027612522,0.015974915,0.010219155,0.022178277,0.007911807,-0.014512334,0.012406722,0.032202,-0.024876487,-0.02279609,-0.028419463,-0.0015461121,-0.009803075,0.012318463,0.0039748163,-0.0029204339,0.00042553543,-0.07383513,-0.007918111,-0.029478574,0.0122869415,-0.03908622,-0.018219221,-0.017803142,0.022695223,0.0010567463,-0.047962572,0.048113875,-0.0039464473,0.0055351127,-0.03449674,-0.020034838,-0.035959322,-0.048340827,0.02019875,-0.055628512,0.018181395,0.008737661,-0.0682874,-0.028595982,-0.038682748,0.01578579,-0.0066068317,-0.0647066,-0.033286326,-0.019353982,-0.00034042835,-0.024876487,-0.03724538,-0.027284702,0.0018707799,0.00021414677,0.007136387,0.045390446,0.020715695,-0.028318595,0.009443735,0.011763691,0.01912703,0.040372282,-0.04879473,-0.047962572,0.018673126,0.017550973,-0.040826187,-0.043020055,0.0304116,0.039918374,-0.008813311,-0.026301242,-0.07050649,0.023224778,0.0064618345,0.01659273,0.035429765,0.0069346516,0.005484679,-0.028722066,0.0050118617,0.02582212,0.0069598686,-0.025494302,-0.007300297,-0.0066068317,-0.021409161,-0.04362526,-0.022455662,-0.045642614,0.013327139,-0.0323533,-0.026629062,-0.016075782,-0.0076533337,-0.029680308,-0.008296365,-0.0003282139,-0.0045106756,0.021913499,0.036312357,-0.047357365,-0.0029819002,-0.07277602,0.027612522,0.04274267,-0.011883471,-0.02076613,0.02052657,0.021018298,-0.042238332,-0.0025138112,0.043045275,0.014499726,-0.020476134,0.016403602,0.028822934,0.013415399,0.056031983,-0.0018234982,0.054468535,0.04062445,-0.008088325,0.0034830864,-0.007741593,-0.008781791,-0.021346118,-0.006036299,0.035253245,-0.02574647,0.03278199,-0.018937903,-0.0049488195,-0.017891401,-0.011870863,0.0064050965,-0.040195763,-0.006288468,-0.010578495,-0.0013900824,-0.0021008842,0.025342999,-0.0639501,0.02157307,-0.029075103,-0.025456475,0.013982779,-0.02035005,-0.01471407,-0.012690412,0.030966371,-0.0044224164,-0.01405843,-0.022115234,0.012400418,-0.007659638,-0.0012175041,-0.0013593493,0.009626557,0.026301242,-0.0052356618,-0.021459594,0.012268029,0.018395739,0.03638801,-0.014764504,0.022052191,0.037547987,-0.026603846,-0.009008743,-0.024813443,0.043650478,-0.023237387,0.032252435,0.020539178,-0.045213927,0.017941834,0.022241319,0.009708513,0.00033530616,0.0068022627,-0.015483186,0.0012561176,0.0037982978,0.05061035,0.009960681,-0.057191964,0.01602535,-0.0025264197,-0.0050465353,0.0046273037,-0.0053995717,0.021346118,-0.030108996,-0.021913499,-0.017361846,0.0017620319,-0.0018030094,0.02394346,-0.006310533,-0.0040000333,0.007905503,0.04004446,0.0042427457,-0.009513081,-0.007464207,-0.02353999,-0.0012742422,-0.019971797,-0.0475591,0.0057147834,0.0057147834,-0.0039905766,-0.01560927,0.035303682,-0.038354926,-0.009292433,-0.041557476,-0.009273521,0.0047187153,-0.007873981,0.018282263,-0.030134212,0.032655906,-0.0012151401,-0.0043467656,-0.025544735,-0.040094893,-0.0126147615,-0.043700915,-0.014941022,-0.02207741,0.0075083366,0.023275211,0.01487798,0.04612174,0.03366458,-0.010490237,0.032681122,0.027511654,-0.009531993,-0.028469896,-0.015130149,-0.00041135092,0.015987525,-0.012129336,0.013718002,0.043020055,0.0049456675,0.021774806,-0.0086052725,0.008535925,-0.032428954,-0.015911873,0.0057967384,0.036337573,-0.024624318,-0.0053144647,0.0051631634,0.0052135973,0.02279609,0.0019590391,-0.019353982,0.011719561,-0.0029850523,0.022052191,-0.040094893,0.014134081,0.02917597,0.014121472,0.0060047777,0.0050591435,0.060268424,-0.03227765,0.0030985284,0.009519385,-0.024183022,0.011839341,0.043045275,-0.0038455795,-0.01871095,0.036085404,-0.025267348,0.0064019444,0.022216102,0.023981286,0.012570632,-0.031773314,0.017462714,-0.020942647,-0.036060188,-0.0061151017,0.007331818,-0.0072624716,-0.013528875,-0.026376892,0.024309106,-0.019669194,-0.020299617,0.03227765,0.0046336083,0.0050969687,-0.0060299947,0.019492675,-0.008372015,0.035505418,-0.03121854,0.0035114554,0.023855202,0.013692785,0.023552598,-0.020274399,-0.0951182,-0.0128354095,-0.057191964,0.0371193,0.006480747,-0.0019417024,0.026704712,-0.03865753,-0.010244371,0.02672993,0.00069307117,-0.01577318,0.007937024,-0.015004064,0.019341374,-0.0042206813,-0.0038392753,-0.04463394,-0.0271334,0.036236707,0.009298737,0.0008447666,0.0490469,-0.0050843605,-0.04193573,0.012192378,0.022808699,-0.06445444,0.0067707417,0.01471407,-0.0024113674,-0.022266535,0.019744845,0.045920003,0.021409161,-0.026502978,0.0057557607,-0.040674884,0.0031458102,-0.0304116,-0.020930039,0.0030102693,0.00031245334,-0.01993397,-0.007665942,0.0038518838,0.00083846244,0.020375267,0.0052482705,-0.034042835,0.012312159,0.02565821,0.010685667,0.009147435,-0.0002866454,-0.015571445,-0.049399935,0.025784295,-0.0044350247,0.009033959,0.00788659,0.0021954477,0.027360352,-0.0008699836,0.017387062,-0.009475255,0.025721254,0.030663768,-0.007697463,-0.0007892106,-0.023678683,-0.008983525,-0.043826997,0.026654279,0.024510842,0.013718002,0.0070166066,0.0014933142,0.018837035,-0.009941769,-0.012318463,0.037396684,-0.022241319,0.028394246,-0.035480198,-0.0098093795,-0.024082154,0.008466579,-0.02124525,-0.021623505,-0.017134894,0.0025453323,-0.008296365,0.012646283,-0.0051505547,0.006370423,-0.027915124,0.0138819115,-0.020375267,-0.00034259542,0.006833784,0.00089283637,0.012822801,-0.022026975,0.006228578,0.0033223284,0.03686713,-0.026427327,0.061075367,0.023527382,0.008063109,0.023136519,-0.023552598,-0.016996201,-0.0016375234,0.028343812,0.00067652256,0.0048605604,0.022934783,0.010408281,-0.010628929,0.048920814,0.02852033,-0.029604658,0.029150754,-0.033210676,-0.0040693795,-0.026881231,-0.017752709,-0.041658342,-0.0024696817,0.025595168,-0.027335135,-0.008945701,0.0033759144,0.0055445693,0.013428007,-0.0356315,-0.010755014,-0.02435954,0.020740913,0.0060835807,-0.0005098545,0.003227765,0.0062380345,-0.016012741,-0.0030244538,-0.011984339,-0.009097002,-0.0052987044,0.019253114,-0.0046682814,0.005733696,0.013087579,-0.013516266,-0.016617946,0.010534366,-0.016517079,-0.031924613,-0.00678335,-0.03588367,-0.039414037,0.008838529,0.012513894,-0.0032687425,0.008510709,0.01389452,0.0095950365,-0.010988271,0.013364965,0.038481012,0.011807821,-0.031168107,-0.023476947,-0.025595168,-0.011051313,0.027688172,-0.02386781,-0.0061529274,-0.0057242396,-0.053812895,0.042793103,0.015319276,0.009254607,0.02207741,-0.036438443,0.071716905,0.0052955523,0.02517909,-0.0020236573,-0.019795278,-0.0006371211,0.038707964,0.012387809,-0.028066427,-0.036186274,0.009254607,0.0042900275,0.018118354,-0.0030402143,0.0052293576,-0.03467326,0.0022411533,0.009084393,-0.0063830316,0.016050566,-0.012034773,-0.016441429,0.022783482,0.0040441626,-0.015483186,0.018433565,0.0005461038,0.0005591063,0.006922043,0.03883405,0.018004877,0.000909385,0.053308558,-0.026654279,-0.00711117,-0.006474443,0.012488677,-0.055477213,0.033815883,0.0037541683,0.0019101813,0.02043831,-0.011202615,0.049475588,-0.023754334,0.013995388,0.011410654,-0.0052167494,-0.0055098957,0.044104382,-0.032328084,-0.0019590391,0.019492675,0.016126217,0.016605338,0.031268973,-0.0023183802,-0.003114289,0.010395673,0.028318595,0.044104382,-0.021043515,0.029604658,0.01969441,0.0025532127,0.03873318,-0.006701395,-0.013049753,-0.023729118,-0.017172718,0.022127843,-0.0016233389,-0.011480001,-0.01168804,0.036009755,-0.011921297,0.031596795,-0.014449292,0.0006694303,0.03252982,-0.0067076995,0.0421879,0.011801516,0.01855965,0.05174511,-0.017601406,0.027486438,-0.009676991,0.013957562,0.010105679,-0.030335948,0.028343812,0.0012584816,0.037623636,-0.01197173,-0.022707831,0.04077575,-0.016466646,-0.009071785,-0.041002702,0.025292566,0.02410737,0.022342186,-0.025897771,0.027688172,0.003141082,0.027108183,0.04266702,0.021938715,-0.015911873,-0.017046634,-0.033815883,0.035429765,0.03260547,0.012539111,-5.9397655e-05,0.007161604,0.013478441,-0.031647228,-0.018042702,0.0069094347,0.038052324,-0.008233323,-0.045819134,-0.046777375,0.026830798,-0.0021733828,-0.009437431,-0.029402923,0.006121406,0.0069094347,0.00029373766,-0.027587304,-0.011410654,-0.021673938,0.00018784631,0.011057617,0.0001267741,-0.010269589,-0.006701395,-0.023729118,0.033740234,-0.0058660847,0.029302055,0.012848018,-0.022808699,0.005954344,-0.011026096,-0.010067853,0.0053144647,0.013516266,0.014600594,-0.028822934,0.0018581714,0.010994575,-0.0076029,-0.0018329545,-0.015521011,-0.0050276225,0.03147071,0.008958309,0.0039937287,-0.010011115,0.00044444812,0.011114355,-0.0066320486,-0.02844468,0.007823547,0.0066887867,0.007829852,-0.03139506,-0.0058913017,-0.003914926,0.010660451,0.016227085,-0.021774806,-0.007502032,0.0005847172,-0.012097815,0.03653931,-0.029125536,-0.00066115597,-0.015949698,-0.0028605438,0.0066572656,0.0032183088,0.019341374,-0.045819134,-0.0022742506,0.0041860077,0.030588118,-0.045869567,-0.061579704,-0.007823547,-0.025456475,0.02640211,0.035127163,-0.0011497337,-0.0052009886,0.0047786054,0.015911873,-0.020955255,0.03300894,0.0028495113,-0.0237039,0.0032057003,0.010383065,-0.0003473236,0.025922988,-0.02304826,0.013024537,0.0011142724,0.056536324,0.016882725,0.010156113,0.051215556,0.013503658,-0.017689666,-0.01674403,-0.0030213017,0.026830798,0.0028321748,0.009796771,0.009248303,-0.009204173,0.011177397,0.03194983,0.047054764,-0.023842594,0.0044665462,0.0008691955,0.01642882,0.03283242,-0.047584318,0.049551237,-0.023817375,-0.027360352,-0.021926107,-0.018433565,-0.0061939047,-0.005762065,0.017916618,-0.013415399,-0.033084594,0.019114422,0.00091884134,-0.007420077,-0.0019747997,-0.049652103,-0.00045035835,-0.007476815,-0.008466579,0.01700881,-0.0038771005,0.00039105918,-0.013364965,0.021144383,-0.009746337,0.05126599,0.0052545746,-0.011599781,-0.01438625,0.08064369,0.006178144,0.022758266,-0.027915124,0.008315277,-0.022090018,0.0060173864,-0.030058563,0.0040882924,-0.000910173,0.031722877,-0.014348424,0.0065122684,0.0044633937,0.040246196,-0.021774806,-0.046878245,0.011026096,0.0050339266,0.0015421719,-0.011921297,0.0021434377,0.040069677,0.012022164,-0.02640211,0.0112404395,-0.03573237,-0.034698475,-0.032983724,0.039918374,-0.020400483,0.03653931,-0.0011182126,-0.018547041,-0.013314531,-0.0055792425,0.017450105,0.019719627,0.013680176,0.010906315,0.024384756,0.015457969,-0.017298803,0.036337573,0.01707185,0.0023735422,-0.02026179,-0.034345437,-0.013579309,-0.024372147,0.036438443,0.0009117491,0.034648042,0.012444547,-0.01642882,-0.010048941,-0.0075461618,0.026225591,-0.020980474,0.00029058554,-0.027183834,0.023287822,0.01478972,0.00013918555,-0.009891335,-0.0064019444,-0.04362526,0.014436684,0.0010906316,0.011940209,0.008851137,0.045264363,0.001900725,0.009103307,-0.0021544702,0.028999452,-0.045138277,0.012576936,0.017626623,-0.022064801,0.0024744098,0.026755147,0.008056805,0.0068716095,0.02148481,-0.03522803,-0.020312225,0.0006174204,-0.0037856894,0.038279276,-0.018257046,0.0155840535,-0.009689599,-0.006777046,-0.011996947,0.02337608,-0.027562087,-0.032681122,0.0045232843,0.0066635697,-0.013667568,0.0069409558,-0.021358727,0.018269654,0.008353103,0.01608839,-0.0125075895,-0.021043515,-0.026427327,-0.028217727,-0.0037100385,0.0023041957,0.009626557,-0.012413026,-0.0054437015,-0.010603713,-0.008517013,0.034925427,0.021673938,-0.0062790117,0.01593709,0.021409161,-2.2175616e-05,0.010811753,0.0040157936,-0.016277518,0.025998639,0.01832009,-0.013654959,-0.015155366,-0.0104145855,0.044356555,-0.0019180615,0.0146510275,-0.02084178,-0.011492609,-0.046550423,0.020148315,0.0016186107,0.016554905,-0.025279958,0.03686713,-0.03391675,-0.015243625,0.0043971995,0.0019716476,-0.021194817,0.013541483,0.030209864,0.02124525,-0.0060709724,0.028142076,0.039338388,-0.035833236,-0.02565821,0.012759759,0.012293246,-0.00028763042,0.010042637,-0.04488611,-0.023186954,-0.013150621,-0.039237518,0.009204173,0.0066005276,-0.0057652174,0.019328766,0.00088101596,-0.012520198,-0.010540671,-0.016050566,-0.010130895,0.009292433,-0.009626557,0.011618693,0.0014468204,-0.051593807,0.022241319,-0.036967997,0.009279825,-0.015167974,0.0122869415,0.008422449,-0.011769995,0.017866185,-0.006146623,-0.0072372546,0.0013948106,0.0053113126,0.01739967,-0.023439122,-0.012072598,0.036488876,0.026301242,-0.0025153873,0.017626623,0.016101,0.011007183,-0.020072663,0.02076613,-0.015155366,0.0037384075,-0.03588367,-0.0062664035,0.022871742,0.013806261,-0.008258539,-0.026956882,0.0049488195,0.03283242,0.009582427,-0.007716376,-0.052905086,0.022455662,0.007691159,0.00014381521,0.017929226,0.023098694,0.0019448545,-0.0027644043,0.017172718,0.028142076,-0.01921529,0.008838529,0.03777494,-0.0014956782,0.0033443933,0.0015453241,0.016693598,-0.048492126,-0.006751829,0.012476069,-0.007716376,-0.002012625,0.013844086,0.0019811038,-0.012854322,-0.0019905602,-0.015911873,0.027587304,-0.00094405824,0.00032604684,0.010540671,0.009582427,-0.016390994,-0.027612522,0.0023168041,0.007363339,-0.044180036,-0.024334323,-0.028495114,-0.0049834927,0.019833103,0.0012584816,0.040372282,-0.0037005823,0.035757586,-0.0093743885,0.048189525,-0.016870117,-0.044558287,-0.03391675,0.025015179,0.043020055,-0.006285316,0.008327886,0.016895333,0.0058030426,0.010080461,0.006531181,-0.0056454367,-0.032958508,0.042440068,-0.009538298,0.046928678,-0.0054657664,0.0016233389,0.043675695,0.029024668,0.0076218126,-0.00010894495,0.022291753,0.019946579,-0.050761648,-0.032479387,0.009803075,0.008945701,-0.010616321,0.012583241,0.0053932676,0.013478441,0.01611361,-0.01641621,0.007520945,0.0052987044,0.012646283,0.031445492,-0.0026004943,-0.009954377,-0.0051883804,0.0010598984,-0.0054216366,0.0122302035,0.0050528394,0.036161054,0.033336762,0.031773314,-0.011227831,0.023161735,0.0066824825,-0.0028715762,0.010521757,0.016769249,-0.017349238,0.0050843605,-0.0052262056,0.009084393,0.009336563,0.0021544702,0.05572938,0.027511654,0.00083688635,0.016807074,-0.012690412,-0.033967186,-0.014234948,-0.03515238,-0.0040504667,-0.022670006,-0.06279012,0.0011260929,-0.03719495,0.010717189,-0.020753521,-0.009576123,0.01478972,-0.029781176,0.014840154,-0.044180036,0.0017683362,0.011788907,-0.0010401977,0.041254874,-0.01805531,0.0050307745,0.013125404,-0.039136652,0.0006587919,0.017803142,-0.003501999,-0.012936277,0.026452543,-0.000496064,0.055931117,-0.0082207145,-0.03139506,-0.009506777,-0.02052657,-0.01829487,0.0021182208,-0.025166482,-0.014184515,0.013516266,-0.007810939,0.05956235,-0.018206613,-0.049979925,-0.015987525,-0.007363339,-0.049929492,-0.018357914,0.008794399,0.03916187,-0.0047439323,-0.019202681,0.018963119,0.012797584,0.004078836,0.011221527,-0.0004905478,0.009002439,-0.011990643,0.00089126034,-0.018685734,0.0025232676,-0.016063174,0.00694726,0.0105848,-0.0094311265]	494
14	6	laminated dough!), and French tarts. Our macarons and custom celebration cakes are also customer favourites. Q: Are your products halal? A: We use halal-certified ingredients and do not use pork or lard in any of our products. However, we are not officially halal-certified. Some items contain alcohol-based flavourings (e.g., rum in canelés). Q: Do you have vegetarian options? A: Yes! Most of our pastries, cakes, and tarts are vegetarian. Please let us know if you have specific dietary requirements. Q: Do you cater to food allergies? A: Many of our products contain common allergens including gluten, dairy, eggs, and nuts. Please inform us of any allergies when ordering, and we'll advise on suitable options. Q: How long do your pastries stay fresh? A: Croissants & pastries: Best enjoyed same day, can be kept 1-2 days at room temperature. Cakes: Keep refrigerated, consume within 3-4 days. Cookies: Up to 2 weeks in airtight container. Custom Cakes Q: How far in advance should I order a custom cake? A: Minimum 3 days for simple designs, 5-7 days for elaborate designs, and 2 weeks or more for wedding cakes. During festive seasons, we recommend ordering earlier. Q: What cake flavours are available? A: Popular flavours include Chocolate, Vanilla, Red Velvet, Pandan, Ondeh-Ondeh, Mango, Strawberry, and Durian. Custom flavour requests can be accommodated — just ask! Q: Can I provide my own design reference? A: Absolutely! Send us photos or Pinterest links via WhatsApp. We'll discuss feasibility and provide a quote based on your design. Q: Do you provide cake toppers and candles? A: Basic candles are included free. Customized acrylic toppers, fondant figurines, or fresh flower decorations can be added for an additional fee. Q: What sizes are available for custom cakes? A: Standard sizes: 6" (serves 6-8), 8" (serves 10-12), 10" (serves 14-18). Multi-tier cakes and larger sizes available for weddings and events.	1	2025-12-21 23:53:41	2025-12-21 23:53:41	[0.034456797,0.010416415,0.053220656,-0.022329254,-0.0026057302,-0.00804816,-0.021769721,0.020533545,0.0045673475,0.034066424,-0.024450272,-0.086662486,-0.017866006,-0.010546538,-0.05465202,0.053819228,0.0028610984,0.01603126,-0.01020171,0.004242038,0.07016278,0.017774919,-0.02503583,0.028887495,0.008926497,-0.003946006,-0.001807095,0.01603126,0.05082638,-0.0014679597,0.011476924,-0.010761243,-0.023448318,-0.015237504,-0.024502322,-0.0010320449,0.020078111,-0.035055365,0.0012955456,0.020754755,-0.05938853,0.04080684,0.039349455,0.0037638326,-0.009954475,0.025231015,-0.0038972094,0.0038028697,-0.048249926,0.02645418,0.03539369,0.06776851,-0.014912194,0.005227726,-0.0030465247,0.00081164757,-0.044268135,0.028002653,0.035784062,0.03375413,0.0034645477,-0.044059936,0.024814619,-0.036044307,-0.023643505,-0.021080066,-0.028991595,0.047469184,-0.03653878,0.06615497,0.010357859,-0.013051422,0.0063240193,-0.054964315,-0.0047169896,-0.022121055,0.05439177,0.024072913,0.010852329,-0.0007299135,-0.037423622,-0.020520533,0.010631119,0.028184827,0.029225819,-0.039401505,-0.043617517,0.022589501,-0.07557593,0.04291485,0.036668904,-0.022680588,-0.025530301,0.008009124,0.043044973,-0.016772965,-0.018737836,0.012882262,-0.0140273515,0.02732601,0.04070274,-0.055016365,-0.03180227,-0.01478207,0.071932465,-0.016538743,0.017306473,-0.00402408,-0.017605757,-0.027976628,-0.04897862,-0.033884253,-0.010292797,0.025048843,-0.0078269495,0.026987687,0.017918054,-0.039401505,-0.010422921,-0.048354026,-0.017592745,0.0010003272,0.024892693,0.020247271,-0.0015688058,-0.0424464,-0.036408655,-0.0046942183,0.028158803,-0.024632446,-0.021132113,-0.023435306,0.046376143,-0.012869249,-0.005403393,-0.02688359,0.028679298,0.025491264,-0.034222573,0.02716986,0.054131523,-0.060897965,0.010670156,0.011138602,-0.027117811,0.0027212151,-0.047104836,-0.017033212,-0.037163373,0.041587584,-0.030839354,-0.00722838,-0.029824387,-0.030084636,-0.0148211075,0.005130133,0.02956414,0.024658471,-0.024723532,0.0031636362,-0.0030302594,0.027846506,-0.0026707922,-0.035575863,0.0055530355,-0.050592154,0.01811324,0.05803524,-0.01821734,-0.024203038,0.009895919,-0.00084499177,0.036356606,0.0074040475,-0.0031294788,-0.022160092,0.030396933,-0.009863388,0.025048843,0.012888768,-0.03489922,0.05923238,0.01756672,-0.027820481,-0.029225819,0.03692915,5.1897052e-05,-0.049160793,-0.02312301,0.028028678,0.0369812,-0.0119713945,0.002459341,-0.049238868,0.005936901,-0.038907032,0.0683931,0.0028041692,-0.047911603,-0.006554989,-0.049342968,-0.011711147,0.0022885534,0.0047169896,0.043565467,-0.010793773,0.021314288,0.009284337,0.068809494,0.007078738,0.04489273,-0.0046096374,0.00039789436,0.068757445,-0.013018892,0.01903712,-0.062719695,-0.019245319,-0.0054977327,0.039739825,-0.005406646,0.046662416,0.04523105,-0.0066428226,-0.024944743,-0.014144463,0.01336372,-0.005227726,-0.0030758027,-0.04150951,-0.016161382,-0.028887495,0.01746262,0.008269371,-0.052622087,-0.015718961,-0.009629166,-0.021886833,0.0071437997,-0.08296697,0.004290834,0.010793773,-0.02443726,0.04117119,0.021132113,-0.013266127,-0.005777499,-0.060481567,0.01821734,-0.046063844,0.026337069,-0.056421705,0.0124398405,-0.029876437,0.03523754,-0.02727396,-0.0051463987,-0.044059936,0.052986436,-0.035784062,0.0017599252,0.019934975,-0.0077749,0.0016208553,0.02346133,0.010780761,-0.060897965,0.03669493,0.0018656508,0.010507502,-0.01341577,-0.06709186,0.022979872,0.019297367,0.02743011,-0.038490638,0.0004981304,0.000585964,-0.015276541,-0.019466529,-0.034769095,-0.028757373,-0.007944061,-0.06615497,0.0072153676,0.016629828,0.05319463,-0.02018221,-0.016005235,-0.02961619,0.03380618,-0.055797108,-0.030006561,-0.010917392,0.0045380695,0.006187389,-0.042082056,0.038516663,-0.006616798,-0.01821734,-0.022615526,0.0013126244,-0.0038679317,-0.010240748,-0.043227144,-0.00043428838,-0.011685122,0.09722854,0.045777574,0.010741725,0.028835446,0.016486693,0.0063565504,-0.030813329,-0.024463285,0.0014085907,0.038048215,0.040416468,0.015731974,-0.056577854,0.07651283,-0.024137976,-0.025829585,0.01336372,-0.033415806,-0.07604438,0.030579107,-0.008972039,-0.00540014,-0.034066424,0.011652592,-0.0060247346,0.019961,-0.0041314326,-0.02072873,0.033467855,0.028731348,-0.030110661,0.020234259,0.020897891,-0.0001355118,-0.06688366,0.0021324046,-0.036148407,0.014365674,-0.0056896657,0.02187382,0.065582424,0.00832142,0.05280426,-0.068601295,0.01175669,-0.017085262,0.010286291,0.022823725,-0.02737806,0.04733906,-0.0041249264,-0.058503684,-0.0032482168,-0.038750883,-0.013064435,0.008223828,0.010741725,-0.015458714,0.019987024,-0.012648039,0.013194559,0.03838654,-0.010468464,-0.0032465903,0.028783398,-0.004085889,-0.033519905,-0.0427587,-0.020195222,-0.008197803,0.02356543,0.058659833,0.0069290954,0.096135505,-0.0016306145,0.07614848,0.011027996,0.04007815,0.0055790604,0.015640888,0.0041054077,0.049212843,-0.047755454,-0.008158766,-0.038646784,0.0022625285,0.055484813,-0.014443748,0.029954512,0.037267473,-0.037241448,-0.03489922,-0.027143836,-0.021028016,-0.0022088524,-0.010540033,0.013220584,0.0019843888,0.0090631265,-0.012752138,0.0096486835,-0.044372234,0.038854983,-0.05938853,-0.031281777,-0.015315577,-0.005806777,0.007768394,-0.042628575,0.03945355,0.0001360201,0.011639579,-0.05150302,-0.023201084,-0.05329873,-0.060533617,-0.022511426,-0.026961664,-0.024619434,-0.0056278566,-0.03911523,-0.06506193,-0.04070274,-0.03817834,-0.0043331245,0.011080046,-0.028523149,-0.0424464,-0.027508182,-0.0341445,0.0021437905,-0.017280448,0.0033734608,-0.0015720589,0.027299985,0.051320847,-0.0049479594,-0.011041009,0.024580397,0.02100199,-0.025113905,0.041275285,-0.04156156,-0.035471763,0.0107677495,-0.0018933021,-0.02493173,-0.0398179,0.048093777,0.0074040475,-0.0036206963,0.008705286,-0.08452845,0.049368992,0.006141846,-0.001789203,-4.158499e-06,0.015315577,-0.020702705,-0.046011794,0.020117149,0.036356606,0.014547847,-0.00832142,-0.02411195,-0.010930404,-0.013767104,0.000910867,0.00910867,-0.011242701,0.018139265,0.017553708,-0.0018981817,-0.012179593,0.024372198,-0.05486022,0.016499706,-0.021886833,-0.022121055,0.00070063566,0.0018298667,-0.0023503623,0.0400261,-0.07083943,0.01744961,0.02351338,-0.013480832,0.013441795,-0.031620096,-0.012114531,-0.014222537,-0.027586257,0.020923916,0.0005038233,-0.04122324,0.049577188,0.03375413,0.008822397,0.030006561,0.019518578,0.009251806,0.004690965,-0.0019177003,-0.040416468,0.009746277,0.0024691,0.0035556343,0.017488645,-0.010579069,-0.028731348,0.018920008,-0.055484813,-0.017866006,-0.02722191,-0.004398186,0.010962935,-0.022875775,0.025686448,-0.015081354,0.0019128206,-0.038776908,0.0055530355,-0.059544675,0.016890077,-0.05371513,-0.020533545,0.020312333,-0.015484739,-0.014482785,-0.0183865,0.02219913,0.015471727,-0.014274587,0.013793129,0.010949923,0.016044272,-0.0104424395,-0.009486029,0.0005469268,0.011379331,0.0013305164,-0.016720915,-0.011444394,0.011691628,0.030214759,0.0028139283,0.023903752,0.020533545,-0.0099805,-0.006167871,-0.014131451,0.01761877,0.0018933021,0.020325346,0.031385873,-0.0045380695,0.027820481,0.0027423603,0.021717671,0.007462603,0.01903712,-0.052439913,-0.013884216,-0.017683832,0.056109406,0.021886833,-0.061938956,0.052882336,0.012622014,0.006522458,0.007020182,-0.015029306,0.03539369,-0.03955765,-0.030475007,-0.033207607,-0.015406664,-0.01690309,0.017488645,0.02891352,0.012719607,0.020715717,0.034170523,-0.0009076139,0.0013329562,0.002275541,0.004687712,-0.013389745,0.010045562,-0.03664288,0.014573872,0.0037247953,-0.0067274035,-0.029928487,0.028679298,-0.045621425,-0.027586257,-0.049785387,-0.0015265155,0.045100927,0.0108848605,-0.0050097685,-0.025335114,0.015992222,0.012713101,0.0036890113,-0.03070923,-0.020845842,-0.012504903,-0.02645418,-0.005975938,-0.022055993,0.01888097,0.04749521,0.019843888,0.020325346,0.007859481,0.00048023835,-0.001533835,0.038542684,0.0060247346,-0.02214708,-0.0068770456,-0.0016802243,0.0069681327,0.002966824,0.006948614,0.015705949,-0.021704659,0.0035361159,0.009987006,-0.016655853,-0.013519868,0.0057579805,-0.0043786676,0.022238167,-0.061991006,-0.0151724415,-0.021717671,0.00398179,0.01647368,0.0010613227,-0.002264155,0.034248598,0.004814583,-0.0013199438,-0.019961,0.0019453516,0.0028562187,0.0053903805,0.008061172,-0.006138593,0.014638933,-0.02160056,0.02230323,0.027482158,-0.011750184,0.014014339,0.023630492,0.008399495,-0.003926487,0.047521234,-0.0073975413,0.00728043,0.038048215,0.022108043,0.015966197,-0.043539442,0.008139247,0.00044079457,-0.025556326,-0.01734551,0.00016580625,-0.0048503666,-0.00068396353,-0.023448318,0.004004562,-0.018972058,-0.010448946,0.03164612,-0.0017599252,0.014534835,0.001020659,0.0053708623,-0.018867958,0.00040440055,-0.018308427,0.0154977515,0.007150306,0.028106753,0.036018282,-0.0039362465,-0.067872606,-0.017839981,-0.026610328,-0.013428782,0.011678616,0.0023991587,0.026610328,-0.050930478,-0.01483412,0.021418387,0.025842598,-0.012010432,0.017879019,-0.039948024,0.019323392,-0.009538079,-0.016135357,0.0028464594,-0.024268098,-0.003326291,7.6701916e-05,-0.0040370924,0.040728766,-0.033780154,-0.013025398,0.05459997,0.031932395,-0.038516663,0.023786642,0.025387164,0.011659098,-0.014144463,0.023227109,0.017033212,0.04325317,-0.04598577,-0.0038028697,-0.015484739,0.014300612,-0.037683867,-0.012667557,-0.012973349,0.004056611,-0.03328568,-0.037840016,0.0010743351,-0.00026960036,0.01729346,-0.0015167561,-0.018334452,0.035003316,0.02127525,0.011502949,-0.01968774,0.0056864126,-0.030917428,-0.039011132,0.019544603,0.020039074,-0.013077447,-0.005663641,0.028314952,0.017007187,-0.028002653,0.019440504,-0.01025376,0.001890049,0.033780154,-0.014118439,-0.007176331,-0.028705323,-0.010702687,-0.04489273,-0.007325973,0.023968814,0.017787931,-0.005094349,0.009590128,0.023916764,0.015940173,0.008074185,0.056109406,-0.029251842,0.05017576,-0.010572563,-0.00016173988,-0.041795783,0.0077488758,-0.047469184,-0.015367627,-0.03255699,-0.008926497,0.010754737,-0.011112577,-0.012420322,-0.04668844,-0.01659079,0.025061855,-0.007989605,0.004323365,0.0063240193,0.007618752,-0.017280448,-0.028184827,-0.008536125,0.00017048258,0.04707881,-0.0077749,0.08874447,0.021587547,0.01093691,0.017436597,-0.009310362,0.00049243745,-0.0045901192,0.020910904,0.005982444,0.012856237,0.013285645,0.025296077,0.021197176,0.060065173,0.018815909,-0.016018247,0.010455452,-0.018555662,0.005325319,-0.013253115,-0.00992845,-0.018178303,-0.031073576,-0.0055823135,-0.022342267,0.00021795745,0.028132778,-0.0053415843,-0.013923253,-0.02356543,0.018191315,-0.0037996166,0.010910885,-0.011515961,-0.013897228,-0.019440504,-0.0035523812,-0.009095658,-0.023279158,0.0005290348,-0.017748894,-0.0051138676,0.012706595,0.0092973495,-0.010793773,0.013506856,-0.010514008,-0.035732012,0.003236831,0.012257667,-0.015953185,-0.0010393643,-0.04419006,-0.05077433,0.016213432,-0.019024108,-0.015432689,0.008523112,-0.011964888,-0.0037605795,-0.005510745,0.01592716,0.019258332,0.012329236,-0.03294736,0.010787267,-0.03370208,-0.011190652,0.004518551,-0.007957074,-0.016226444,-0.022628538,-0.05171122,0.045907695,0.027690357,0.004495779,-0.0036174431,-0.022029968,0.04200398,0.029980537,0.0139102405,0.0013459687,-0.02154851,0.0016029632,0.014690983,0.029850412,-0.031568047,-0.006187389,0.023526393,-0.0034124982,0.01587511,0.0025536807,-0.015992222,-0.02428111,0.014391699,-0.009004571,0.0019323393,-0.0139102405,-0.0042713154,-1.9620238e-05,0.016278494,-0.018841933,-0.0031636362,0.027013712,-0.010826305,0.022394316,-0.01221863,0.031489972,0.04314907,-0.012687076,0.030969478,-0.024164,-0.0035686467,0.023864714,0.017996129,-0.013376732,0.011411862,-0.009499041,0.018906996,0.032765187,-0.007156812,0.017280448,-0.014703996,0.030553082,0.011197158,0.013402757,-0.004577107,0.01767082,-0.029824387,0.0023503623,-0.0030758027,-0.02428111,0.015810048,-0.02677949,0.0045022853,0.004027333,-0.019128207,0.0428628,0.03867281,-0.03076128,-0.009947969,0.03633058,-0.014417723,0.033077486,-0.024619434,0.0013134377,-0.01577101,-0.004596625,0.038854983,0.0048698853,0.01052702,-0.007430072,0.032322764,-0.0042062537,0.017033212,-0.0021665622,0.011450899,0.030891404,0.00063720025,0.040676717,0.0038744379,0.0008718298,1.3584219e-05,-0.024528347,0.015016293,-0.002797663,0.022472389,-0.011990913,-0.028132778,0.0482239,0.0041737226,0.011899827,0.010845823,-0.011964888,0.04668844,-0.014769058,0.008933003,0.0063370317,0.006138593,0.040260322,0.012290198,-0.0030774293,0.038360514,-0.012446347,0.0034873192,0.02961619,0.004050105,-0.0142615745,-0.0198569,-0.030735254,0.04439826,0.021522487,0.0063825753,0.005611591,-0.028340975,0.02650623,-0.03612238,-0.021678634,-0.011288244,0.0428628,0.001987642,-0.00025536807,-0.04445031,0.004365655,-0.0068705394,-0.004681206,0.01112559,0.011587529,-0.035862133,-0.013858191,-0.029147744,-0.013975302,-0.0009084272,0.0018591445,-0.0018851693,0.0004993503,0.0070722317,0.01597921,-0.00810021,0.03549779,0.005328572,0.015003281,0.027039737,0.0017810703,0.022394316,-0.027950604,0.0025797053,0.0030205,0.004150951,-0.005770993,-0.0011873802,-0.0015858845,-0.00416071,-0.011685122,-0.012960336,0.006714391,-0.033077486,0.018152278,0.011541986,0.011340294,-0.021639597,0.008334433,0.042836774,-0.0022446364,-0.016785977,0.008620705,0.009030595,0.02612887,-0.020585595,-0.027534207,-0.009668202,0.008614199,0.020871866,-0.04450236,-0.011607048,0.011366319,-0.0014500677,-0.0049447063,-0.034612946,0.0072413925,-0.01221863,0.008614199,0.022277204,0.008523112,0.041535534,-0.02291481,-0.009284337,0.006987651,-0.007560196,-0.02961619,-0.060429517,0.0109434165,-0.01674694,0.011841271,0.049551163,-0.034821145,0.002275541,-0.017137311,0.009388437,-0.0031522503,0.014417723,-0.015224491,-0.018074203,-0.0018184809,0.021028016,0.026909614,0.050540105,-0.012068988,-0.008516606,0.03323363,0.061678708,-0.020091124,0.031489972,0.017358523,0.022888787,-0.005071577,-0.012316223,-0.013532881,0.011919345,0.0030286328,0.0034612946,0.008275877,0.011698134,-0.0051821824,0.02307096,0.014144463,-0.0019892685,0.0016753447,-0.011112577,0.023096984,0.04091094,-0.035367664,0.04325317,-0.048041727,-0.0070397006,-0.018373488,0.002199093,0.009089151,-0.0012337368,0.0019811357,0.013858191,-0.03797014,-0.010162673,0.010136648,-0.0041444446,0.009785314,-0.02688359,-0.025738498,0.005487974,0.015185454,0.01914122,0.005309053,-0.0073975413,0.023812665,0.018646749,-0.008516606,0.02513993,-0.0073389853,-0.018100228,0.027560232,0.06948614,0.016460668,0.016395606,-0.0023373498,0.0057905116,-0.0227977,-0.022602513,-0.012114531,0.003201047,0.0042680623,0.00938193,-0.025335114,-0.0034320166,0.0068249963,-0.00045380695,-0.0081522595,-0.036070332,-0.01603126,-0.008880953,-0.014482785,-0.0148211075,-0.002513017,0.04091094,0.013728066,-0.0058653327,-0.0005928768,-0.023578443,-0.039193306,-0.024957756,0.06646726,-0.01582306,0.06834105,-0.007521159,0.0123812845,0.027039737,-0.02182177,0.027352035,0.012530928,0.02595971,0.04130131,-0.0032953867,0.030553082,-0.0051463987,0.0074430844,-0.002044571,-0.0050162748,-0.017150324,-0.022212142,0.023005897,-0.025074868,0.018373488,0.012192605,-0.0034482821,-0.0004048072,0.006994157,0.009011077,0.014274587,0.007046207,-0.030370908,0.0060442532,0.0024934984,0.01532859,-0.0075862207,-0.0056766532,-0.008406001,0.023656517,-0.03692915,-0.009427473,-0.012843224,-0.016343556,-0.0033962326,0.027664332,-0.02411195,0.016291507,-0.01652573,0.028653273,-0.03692915,0.023955802,0.0018461322,-0.01180874,-0.022823725,0.008184791,0.0018510119,-0.0042680623,-0.0012443094,-0.022394316,-0.005738462,0.015966197,-0.017124299,0.03812629,0.0010174059,0.0085621495,-0.015354615,-0.015836073,-0.029147744,0.021028016,-0.011359813,-0.019974012,0.02296686,0.0025146436,-7.1517294e-05,-0.0054229116,-0.0019388455,0.018972058,0.009674708,-0.0003556041,-0.03299941,0.0028708575,-0.03781399,-0.03115165,-0.017007187,0.0015216358,0.0045673475,0.009603141,0.011027996,0.009310362,-0.013441795,0.03911523,-0.010416415,-0.0049056695,0.02618092,0.03240084,0.0017810703,0.030292833,0.010579069,0.021808758,0.022108043,0.017189361,0.0025211498,-0.03219264,0.008666249,0.044840682,-0.003041645,0.012374778,-0.0072934423,-0.0020348118,-0.0034808132,0.002976583,0.000993821,0.0026610328,-0.049759362,0.05439177,-0.049395017,0.0071112686,-0.01690309,0.011620061,-0.02296686,0.022108043,0.048848495,0.005722197,0.00769032,-0.01953159,0.034352697,-0.02618092,-0.029876437,0.01148343,0.0014077774,-0.00883541,0.027117811,-0.04588167,-0.01968774,-0.006506193,0.0010019537,0.009954475,-0.0030139938,-0.037397597,0.00549448,-0.0027797709,-0.025178965,-0.0028415797,-0.008874447,-0.019219294,0.028236877,0.007488628,0.0051073614,0.016512718,-0.059596725,0.052335814,-0.03682505,-0.025400177,-0.021119101,-0.007957074,-0.010696181,0.027768431,0.022055993,-0.024905706,-0.0061190743,-0.0024268099,-0.019232307,-0.0020852347,-0.02137935,-0.008334433,0.011203664,0.012622014,0.0132921515,0.033077486,0.013519868,0.031411897,0.004655181,0.011698134,-0.011821752,0.0066623413,-0.026701415,-0.024098938,-0.002631755,-0.010631119,0.0035523812,-0.023591455,-0.0074040475,0.026857564,0.041483484,0.0062947413,-0.03932343,-0.004765786,0.041821808,-0.025439214,0.022134067,0.03219264,0.0040696235,-0.03076128,0.0032156857,0.044372234,0.012127544,-0.0041672164,-0.011730665,-0.030475007,0.014014339,-0.009941462,0.02438521,0.015120392,0.027143836,0.009271325,0.009420967,0.009069633,0.01336372,-0.025283065,-0.0018314932,0.004316859,-0.016226444,0.0131164845,-0.0076447767,0.008770348,0.0030302594,0.009707239,-0.048093777,0.003376714,0.02312301,0.007918037,-0.049603213,-0.035601888,-0.06667546,-0.017215386,0.031828295,-0.013754091,0.02607682,-0.024502322,0.027950604,-0.0312037,0.05470407,-0.033832204,-0.015810048,-0.011190652,0.007618752,0.03469102,-0.012674063,0.006785959,0.008516606,-0.0036337087,-0.009531572,0.019414479,0.0067729466,0.010234241,0.034248598,-0.017137311,0.016018247,-0.019284355,-0.0096226595,-0.0092973495,0.030396933,0.011216677,-0.0061938954,0.036304556,0.0028367,-0.011997419,-0.034066424,-0.00046153305,0.023929777,-0.006607039,-0.0067339097,0.006164618,0.0015834447,0.005878345,-0.0028562187,0.020468483,0.012804188,0.021249225,0.01175669,0.03185432,0.019622678,-0.012036457,0.0021389108,0.029329916,0.025478251,0.009336387,0.042186152,0.026753465,0.03175022,0.008301902,0.00066485157,-0.007833456,0.014196512,0.0075276652,0.03164612,-0.0088874595,0.011086552,-0.0032498434,-0.008516606,0.006138593,0.016981164,0.043279193,0.020195222,0.021860808,0.01931038,0.003682505,-0.052674137,0.00585232,-0.029486066,-0.0060670245,-0.03333773,-0.022901798,0.012348754,-0.051581096,0.008256359,-0.014092414,0.006447637,-0.008854928,-0.0055205044,0.027117811,-0.013571918,0.0014199766,-0.0024934984,0.0074430844,0.03125575,0.0048828977,0.006216667,0.0068575274,0.0054131523,-0.01440471,-0.0064378777,0.028054703,-0.017879019,0.040546592,0.022472389,0.03065718,-0.0057937647,-0.027768431,-0.015614863,-0.036512755,-0.030527057,0.036512755,-0.0150553305,-0.018594699,-0.005065071,0.034222573,0.03528959,-0.004495779,-0.01690309,0.0003698364,0.014352662,-0.0053936336,-0.017358523,0.011203664,0.018724823,-0.02001305,-0.022316242,-0.019011095,-0.014443748,0.007703332,-0.006655835,0.008497088,-0.01227068,-0.011678616,-0.005930395,-0.0310996,0.01695514,-0.0017615517,0.010169179,0.003287254,0.0052407384]	484
15	6	sizes: 6" (serves 6-8), 8" (serves 10-12), 10" (serves 14-18). Multi-tier cakes and larger sizes available for weddings and events. Delivery & Collection Q: Do you offer delivery? A: Yes! We deliver within Kluang. Delivery fees: RM8-15 depending on distance. Orders above RM150 enjoy FREE delivery within Kluang town. Q: Do you deliver outside Kluang? A: We can arrange delivery to nearby areas (Simpang Renggam, Paloh) for an additional fee. Please WhatsApp us to discuss. For farther locations, self-pickup is recommended. Q: What are your collection hours? A: Collection is available during operating hours. Please arrive within your scheduled collection time. Late pickups may affect cake freshness. Q: How should I transport my cake? A: Keep the cake box flat and avoid tilting. Place it on a flat surface in your car (floor is best). For longer journeys, an insulated cooler bag helps maintain temperature. Other Questions Q: Do you offer gift packaging? A: Yes! We have beautiful gift boxes for pastries, macarons, and cookies. Premium packaging with ribbons is available for an additional RM5-15. Q: Can I order for corporate events? A: Absolutely! We provide pastry platters, macaron boxes, and custom cakes for corporate events, meetings, and gifts. Contact us for bulk pricing and corporate packages. Q: Do you do wedding cakes? A: Yes! We create custom wedding cakes ranging from elegant minimalist designs to elaborate multi-tier creations. Book a consultation at least 1 month in advance. Q: How can I stay updated on new products and promotions? A: Follow us on Instagram @j.q_patisserie! We post daily specials, new creations, and seasonal promotions. Contact Us Address No. 23, Jalan Mawar 3, Taman Bunga Raya, 86000 Kluang, Johor Phone / WhatsApp +60 12-345 6789 Email hello@jqpatisserie.com Instagram @j.q_patisserie Facebook J.Q Patisserie Thank you for choosing J.Q Patisserie! Every bite, a moment of joy. n	2	2025-12-21 23:53:43	2025-12-21 23:53:43	[-0.002855402,0.025650222,0.030320497,-0.048445042,0.017059816,-0.022395547,-0.010078601,0.011845078,-0.043073013,0.01455529,-0.013442168,-0.08116117,0.0010004494,0.035111766,-0.027731277,0.06402876,0.004888061,0.009697477,0.0008779454,0.035256956,0.020834755,0.0012076475,0.018850492,-0.0037537648,0.018487519,0.0018133618,0.00085072225,-0.032256365,0.010514171,0.0013263705,-0.0005531585,-0.0051542427,-0.024307214,0.0027631458,-0.015644215,-0.00504535,0.0016711967,0.0187416,-0.015257042,0.028723408,-0.025650222,-0.0028024681,0.035426345,0.02494847,-0.0018980559,0.039540056,-0.022298753,0.021705894,-0.026908534,0.047501307,0.039999828,0.031965982,-0.01744699,-0.00041401817,0.027731277,0.013369573,0.012861408,0.0011917674,0.06228648,-0.0027056749,0.0056624073,-0.049945336,0.0013603994,-0.016176578,0.008039893,-0.026158387,-0.022625431,0.014361704,-0.014833571,0.03632168,-0.0011032922,-0.04166951,-0.021367118,-0.045783225,-0.008681148,0.027610285,0.05289753,-0.0113248145,0.015341736,-0.014301208,-0.010538369,-0.006218969,0.006890472,0.045638036,0.039588455,-0.0374832,-0.06828766,0.017084016,-0.06664218,0.06702935,0.039854635,0.010780352,-0.0069872653,-0.010979989,0.028457226,0.010435526,0.005148193,0.0230731,-0.0088989325,0.043339193,0.031215835,-0.05754361,-0.011790632,-0.014107621,0.036370076,0.010181444,0.019709533,0.0040441444,-0.015329637,-0.021209829,-0.071869016,-0.021258226,0.0050967718,0.0475739,0.008923131,0.025577627,0.021294523,-0.04934038,-0.0013150276,-0.02250444,-0.0101935435,0.00994551,-0.018390724,-0.029933324,-0.027368302,-0.031844992,-0.042782634,-0.035426345,0.0187416,0.022129366,-0.006648489,-0.015862,0.04195989,-0.032256365,0.008166933,-0.038910903,0.04672696,0.048541833,-0.054736603,0.013684151,0.06320602,-0.02089525,-0.039854635,0.0036932689,-0.045299258,-0.0051088706,-0.043363392,-0.021463912,-0.032667734,0.062092893,-0.027731277,0.0013301515,-0.040266007,-0.040459596,-0.050526097,0.02249234,0.0044313176,0.051784407,-0.029618746,0.015656315,-0.0056351842,-0.0051844902,0.02567442,-0.015305439,-0.03242575,-0.04684795,-0.0074651823,0.03242575,-0.005006028,-0.021209829,0.025190454,-0.015390133,0.058753524,0.034700394,-0.042564847,0.030804465,0.025722817,-0.011197774,0.0086509,-0.0030580629,0.032546744,0.05754361,0.036999233,-0.039031893,-0.0015865025,0.028191045,0.0058801924,-0.039152883,-0.027223112,0.033345286,-0.0015207133,-0.00850571,-0.02333928,-0.0086509,0.028166847,-0.02727151,0.04859023,0.024996867,-0.012322996,0.06707775,-0.056140106,0.02913478,0.04094356,0.01658795,0.022577034,-0.041766305,0.017035618,0.005983035,0.023557067,-0.022117266,0.07583754,0.028965391,0.009358701,0.058463145,0.0024228569,0.012093111,-0.055268966,0.013067094,-0.0026013197,-0.0073320917,-0.022419745,0.021258226,0.024996867,0.0035087566,-0.0084452145,0.008590404,0.01833023,-0.007701116,0.04338759,-0.04210508,-0.020387087,0.022141464,-0.011512351,0.010568617,-0.033829253,-0.0011494203,-0.054591414,-0.025698617,0.029207375,-0.042298667,0.02724731,0.021560704,-0.025843808,0.042564847,0.041427527,-0.010834798,-0.0015176885,-0.05555935,0.01931026,-0.031699803,0.017059816,-0.06654538,-0.013381672,-0.026303576,0.028602416,-0.018209238,-0.01615238,-0.01686623,0.046920545,-0.030828662,0.018644808,-0.007126406,-0.008989677,-0.01932236,0.009413147,-0.025311444,-0.0030172283,0.013284879,-0.008711396,0.017773667,-0.028868599,-0.04655757,0.028481426,0.04108875,0.014627886,-0.012813011,0.01600719,-0.030514084,0.0049848543,0.003974574,-0.019443352,-0.037241217,0.0027147492,-0.056333695,0.01398663,0.011076782,0.05439783,-0.010405279,-0.050816476,0.023145694,-0.016539553,-0.026472963,-0.008463363,0.001917717,0.019225568,-0.004425268,-0.023472372,-0.018076146,0.023992635,0.029328367,-0.03644267,0.031724,-0.027900666,-0.02175429,-0.04917099,0.051639218,0.0065879934,0.04283103,0.0051542427,-0.00012675762,0.0072111,0.028457226,-0.016987221,-0.051300444,0.0099697085,-0.0026769394,0.02828784,0.019237665,0.010048353,-0.04829985,0.08716235,-0.027223112,-0.027634483,-0.0076103723,-0.02436771,-0.045759026,0.06088298,0.01096184,0.015789405,0.0052994327,0.032522544,-0.023387678,-0.018862592,-0.014676282,0.0025287247,0.035087567,0.016527453,-0.027900666,-0.006678737,-0.004095566,-0.024246719,-0.03661206,0.029570349,-0.050574493,0.029304167,-0.029013788,0.03995143,0.06335121,0.0129703,0.01774947,-0.047622297,0.024549197,-0.010852947,0.041403327,0.037096027,-0.028021656,0.04285523,0.007628521,-0.057446815,0.016999321,-0.007755562,3.1027732e-05,0.0008673586,-0.0077616116,-0.013115491,0.016781537,-0.025843808,-0.021234028,-0.008989677,-0.012813011,-0.005163317,0.041451726,0.008820288,-0.031554613,-0.06659378,-0.032353155,0.0037598142,0.04718673,0.055704538,0.011300616,0.07046551,-0.009062272,0.06707775,0.0036085749,0.033998642,-0.03881411,0.031796593,0.03242575,0.043266598,-0.04137913,0.0033091204,0.015111852,0.039394867,0.0016757338,0.007126406,0.0049273833,0.024319313,-0.038233347,-0.037555795,-0.008663,-0.015414331,0.00053992507,-0.00030796145,0.009594634,-0.009243759,-0.014579489,-0.042782634,-0.027586088,-0.008723495,0.01891099,-0.057495214,-0.028626615,-0.011687789,0.00209013,0.0044373674,-0.05522057,0.030078514,0.016273372,-0.02031449,-0.012994499,-0.03257094,-0.03862052,-0.034119632,0.011403459,-0.030320497,0.011379261,0.016321769,-0.048638627,-0.033805057,-0.027586088,0.014216514,-0.0049364576,-0.05420424,-0.047065735,-0.017773667,-0.00836052,0.0019857748,-0.029400961,-0.011119129,-0.008300024,0.026376171,0.04989694,0.009981807,0.014289109,-0.016055586,0.025214652,0.016914627,0.019685335,0.022722224,-0.030756067,-0.05207479,-0.008590404,0.0012378955,-0.014192316,-0.06088298,0.0027389475,0.034821384,-0.03445841,-0.017132413,-0.06475471,0.038281746,-0.010417378,-0.005710804,0.012534731,-0.005692655,0.017071916,-0.02233505,0.016515356,0.04701734,0.0013838415,0.014918266,-0.0044040945,0.012994499,0.0042770533,-0.02753769,0.025480833,-0.04266164,-0.001175131,-0.027150517,-0.016418561,-0.041451726,0.007749513,-0.03213537,-0.04164531,-0.031627208,-0.027368302,0.033877652,0.036418475,-0.027077923,0.007011464,-0.09776122,0.05304272,0.04921939,-0.010792452,-0.012298797,0.022964207,0.011470005,-0.024331413,-0.0054869694,0.009860816,-0.021221928,-0.03782198,0.038983498,0.009068321,0.0061433488,0.020616971,0.0038898801,0.015837802,-0.010973939,0.0048941104,-0.0051693665,0.007882603,0.015039257,-0.0024954518,-0.0015986017,0.018269733,-0.007295794,0.02669075,-0.014095522,0.0039050041,-0.00936475,0.0021838986,-0.011766434,-0.05923749,0.019273963,0.002575609,0.008136686,-0.031772397,0.021100936,-0.04817886,0.008874735,-0.042927824,0.008669049,0.0064065056,-0.02292791,-0.0067331833,-0.011845078,0.01817294,-0.008814239,-0.010810601,-0.007041712,0.04312141,-0.014301208,0.013236482,-0.0049697305,0.01572891,0.036394276,-0.03794297,-0.011863227,0.024283016,0.03211117,0.035014972,-0.0074651823,0.009643031,0.03632168,-0.021076739,-0.016031388,0.015583719,0.022443943,0.02004831,0.031748198,0.0375074,-0.0061403243,0.008154835,0.017846262,-0.00029718564,0.0054990686,0.0259406,-0.016660545,-0.0048184907,-0.02625518,0.058317956,-0.0023185017,-0.060640994,0.016793635,0.025480833,-0.0028115425,-0.0045250864,-0.005623085,-0.013442168,-0.044089343,0.0023200142,-0.02669075,-0.022419745,7.349295e-05,0.014627886,0.025601825,-0.001488953,0.0100907,0.053865466,0.018584311,0.0011229534,-0.015970893,-0.010810601,-0.002974881,-0.007628521,-0.06431914,0.007773711,0.0072292485,-0.035982903,-0.011984219,0.060060237,-0.03591031,-0.012921904,-0.0346278,-0.0037749382,0.015317538,-0.0036539466,0.016055586,-0.030780265,0.041185543,-0.025577627,0.0009255858,-0.0061917454,-0.011863227,-0.012316946,-0.00908647,-0.019080376,0.0021793614,-0.014930365,0.016817834,-0.0032395504,0.038112357,0.0129703,0.005741052,0.04111295,0.02032659,-0.022419745,-0.020883152,-0.008542008,0.016648445,0.01312759,0.00923166,-0.015511124,0.036563665,-0.009104619,0.028675012,-0.016091883,-0.004413169,-0.02048388,-0.022093069,0.019140873,0.046605967,-0.033224296,-0.0022958159,0.033901848,0.0022716175,0.006721084,0.011451856,-0.031917587,0.018608509,-0.0150513565,-0.028820202,-0.029642945,0.010175394,0.019830525,0.018814195,0.01484567,0.0012643624,0.03416803,-0.003433137,0.025480833,-0.013139688,-0.014361704,0.016249172,0.013526862,0.01485777,-0.018209238,0.0259648,-0.019951517,0.03852373,0.03966105,0.050671287,0.004150012,-0.026206782,0.005423449,-0.018789997,-0.0030142034,0.0063520595,0.013381672,-0.0059043905,-0.029812332,-0.029183175,0.030925455,-0.02336348,-0.005099796,-0.018197138,0.016406462,0.007682967,0.002002411,0.012093111,-0.021681696,0.039419066,-0.021947877,0.0112703685,0.042274468,0.0026285427,0.03157881,-0.022722224,-0.07138505,0.0035995003,-0.02712632,-0.00057660067,0.016103983,0.0026935758,0.028626615,-0.046267193,-0.012008417,0.02465809,-0.0013573746,-0.005825746,0.010919493,-0.0038656818,0.0201935,-0.014688381,-0.0027192864,-0.012776714,-0.05018732,0.040241808,0.003257699,0.008481512,0.012595227,-0.0008779454,-0.022226159,0.011349013,0.048106264,-0.055607744,0.016200777,0.03300651,0.02492427,-0.0015774281,0.015402232,0.0063762576,0.011342963,-0.031094844,0.0096309325,-0.031119041,0.015753107,-0.010417378,-0.015184447,0.011724087,-0.000589456,-0.025311444,0.009618833,0.0092921555,0.006448853,0.03148202,-0.016345967,-0.031724,0.019358657,0.022250356,0.009038073,0.008995726,0.016273372,-0.041403327,-0.045783225,0.027658682,0.014083424,0.023557067,0.010060452,-0.0007985446,0.038378537,0.01024194,0.00569568,0.01716871,-0.005205664,0.0101935435,-0.0059195147,-0.022673829,-0.029521953,-0.0030792365,-0.034095436,0.030635076,0.02913478,0.0036569715,0.005777349,-0.0052570854,0.024331413,-0.0101935435,0.00403507,0.04169371,-0.015220745,0.03934647,-0.037434805,0.0061342744,-0.0129703,0.0016167504,-0.010399229,-0.03157881,-0.015353835,0.0018133618,-0.020653268,0.021597002,-0.014639985,-0.011730136,-0.01254683,-0.0028508648,-0.009679329,0.00598606,-0.017640576,0.0018935187,0.0055172173,-0.02695693,-0.044912085,-0.009588585,0.02608579,0.0049092346,0.08319383,0.027198914,-0.00010917602,0.051155254,-0.01933446,-0.00041288388,0.008100389,0.017108213,0.007156654,0.011482104,0.004267979,-0.02105254,0.019588541,0.07748303,0.028796002,-0.019491749,0.022722224,-0.045396052,-0.010163295,-0.041911494,0.0008643338,-0.029086383,-0.0034059137,0.007713215,-0.040266007,-0.033950247,-0.018003551,0.0024077331,-0.0015910397,-0.033103306,0.01413182,-0.016345967,0.032062776,-0.002710212,-0.006010258,0.008287925,0.007459133,-0.015886199,0.012813011,-0.02410153,0.007682967,-0.020629069,0.020145103,-0.0034785087,0.009866865,0.03261934,0.01528124,-0.0044192187,0.0062371176,-0.010447625,-0.02869921,0.0074954303,-0.032207966,-0.03866892,0.013091292,0.016515356,-0.021415515,0.01714451,0.02927997,-0.014083424,0.019782128,0.0034089386,0.029497754,0.009897114,-0.026860137,-0.0039019794,-0.007368389,0.0012885607,0.0075498763,-0.036370076,-0.008100389,-0.00046884248,-0.05870513,0.03852373,0.0044494662,0.02410153,0.022976307,-0.033780858,0.059963442,-0.0066121914,0.02567442,-0.017362297,-0.011754335,-0.0055020936,0.014615786,0.015523223,-0.02134292,-0.0039594504,0.037241217,0.0056321593,0.013611556,0.014906166,-0.0068299766,-0.008814239,-0.019673236,-0.028094253,0.023194091,-0.0061524236,0.0058892667,-0.026593955,0.0031669554,0.0026285427,-0.004210508,0.041863095,0.0027691955,-0.002905311,-0.017967254,0.029884927,-0.0055293166,-0.015232843,0.05696285,-0.022577034,-0.0062976135,-0.0012394078,0.01240164,-0.026206782,0.008977577,-0.00562611,0.0076648183,0.039177082,0.00706591,0.03126423,-0.02205677,0.019225568,0.0004370822,-0.011687789,0.0038868554,0.02436771,-0.027803872,0.0030852861,0.013514763,-0.0014753414,0.052123185,-0.00085450325,0.025021065,0.00015662741,0.007555926,0.042734236,0.06499669,-0.025021065,0.03445841,0.0019494774,-0.024996867,0.03835434,-0.034942377,-0.015862,-0.036708854,-0.021076739,0.022105167,0.010538369,0.019431252,-0.0064972495,0.030102713,-0.0115486495,0.011790632,-0.007005414,-0.0023351382,0.020641169,-0.022734324,0.03852373,0.015329637,0.015970893,0.020677466,0.011730136,0.010865047,-0.021100936,0.0098003205,-0.008427066,-0.0029446334,0.02407733,0.0027540715,0.035886113,0.004915284,-0.013333275,0.048130464,-0.01686623,0.01744699,-0.03736221,0.014095522,0.042879425,0.010979989,-0.004440392,0.008560156,-0.010211692,0.019068278,0.021306623,-0.0075196284,0.0010034741,7.268949e-05,-0.013345375,0.04099196,0.01355106,0.007918901,0.00339079,-0.012208054,0.013672052,-0.032788727,-0.001052627,0.008003595,0.03361147,0.0022897662,-0.0138656385,-0.048977405,0.011506302,0.0024863775,-0.003200228,-0.018293932,-0.012462135,-0.007096158,-0.02986073,-0.027150517,-0.022456042,-0.038136557,0.010943691,-0.007918901,-0.018765798,0.0040138965,-0.03663626,-0.011742236,0.043944154,0.009612784,0.010405279,0.007604323,-0.023290886,0.012189904,-0.0074349344,-0.016539553,0.0026890384,0.003835434,-0.007035662,-0.023593364,0.00274046,0.009128817,-0.0057924734,0.002120378,0.0013203209,-0.008209281,0.030949654,-0.0006106295,0.010108849,-0.008354471,-0.009715626,0.019782128,0.0021566753,-0.028021656,-0.011004187,-0.004972755,-0.0005009809,-0.0021717993,-0.012129409,-0.0029869804,0.007041712,0.024996867,-0.03629748,-0.0037446902,-0.0053841267,-0.0036388226,0.012347193,-0.010689609,4.915284e-05,-0.024585495,0.00012798644,-0.0103629315,-0.020278193,0.0098003205,-0.029376762,0.02378695,0.040048223,0.009286106,-0.026835939,-0.067997284,-0.015075554,-0.011863227,0.01528124,0.043314997,-0.017688973,-0.008136686,0.0009966684,0.025722817,-0.019394955,0.037725184,0.014095522,-0.052316774,0.03274033,0.001221259,0.008820288,0.024621792,-0.02971554,0.0066968855,0.016067686,0.07303054,-0.013054995,0.02193578,0.045299258,0.0058227214,0.0035390046,-0.028626615,0.012788814,0.0006575138,-0.0068481253,0.0012575565,-0.010163295,0.002637617,-0.002637617,0.010635163,0.049558163,-0.014918266,-0.008832388,-2.2922239e-05,-0.011397409,0.041911494,-0.04583162,0.04658177,-0.030973852,-0.01484567,-0.0037930869,-0.012044715,0.014676282,-0.0022156588,0.0021264276,0.006690836,-0.031675603,-0.009721676,-0.003345418,-0.011718038,0.02378695,-0.019370757,0.007513579,-0.027513493,0.0027086996,0.027489293,-0.00027393256,-0.003200228,-0.017132413,0.040411197,-0.013067094,0.05304272,0.0013611556,-0.026642352,0.011107029,0.078208975,0.014216514,0.030417291,-0.014458497,-0.020278193,-0.009842668,-0.014337506,-0.041040353,-0.006394407,0.011433708,0.027949061,-0.0142649105,-0.00014348849,-2.675049e-05,0.044742696,-0.009195362,-0.05391386,0.005895316,0.023762751,-0.015898297,-0.0038142605,0.018136643,0.03518436,0.020145103,-0.024694387,0.009782172,-0.030054316,-0.029981721,-0.03215957,0.04297622,-0.0129703,0.029909126,0.004516012,0.0064367536,-0.0013157837,-0.024149925,0.005795498,-0.002912873,0.013248581,-0.012189904,0.0059195147,0.019552244,-0.012752515,0.03428902,0.011802731,-0.01789466,0.0031518314,-0.0518812,0.006418605,-0.03211117,0.044428118,-0.021270325,0.0048668873,0.017035618,0.008765842,-0.02048388,-0.012558929,0.011584947,-0.034797188,-0.0026119063,-0.026932733,0.026642352,0.017785767,-0.009776122,0.0069570174,0.010514171,-0.04803367,0.012111261,-0.013248581,0.02235925,0.009679329,0.0446943,-0.0059921094,0.012123359,-0.028094253,0.0061735967,-0.028675012,0.037096027,0.027223112,-0.016914627,-0.0122504,0.027731277,0.029909126,-0.0016711967,0.010199592,-0.053575084,0.0022489314,0.014518993,-0.00439502,0.044476517,-0.018777898,0.0122866975,-0.0006159229,-0.03131263,-0.0024682288,0.035934508,-0.030223705,-0.015063455,0.021826886,0.001997874,-0.024851676,-0.00051308004,0.00039965042,0.011330864,0.02669075,-0.0072594965,-0.008771892,0.006950968,-0.03617649,-0.038063962,-0.013309077,-8.97512e-05,0.018548014,-0.008602504,0.03186919,-0.0074349344,-0.0067936787,0.029812332,0.016212875,-0.024149925,0.037071828,0.044912085,0.014398001,0.02480328,0.0016999322,-0.024633892,0.044331327,0.002990005,0.002170287,-0.0048759617,-0.0011456393,0.058801923,0.009618833,-2.9066343e-05,0.0013422506,-0.012667822,-0.06320602,-0.003917103,0.0051421435,0.010683559,-0.015244943,0.04832405,-0.023254588,-0.012764615,-0.017652676,0.002710212,-0.017483288,0.007912851,0.049291983,-0.0049334327,-0.006600092,0.008959428,0.0302963,-0.015801504,-0.027392501,0.025601825,0.006575894,0.019407054,0.0145431915,-0.039757844,0.0030293274,-0.01759218,-0.01326068,-0.0038959298,0.004295202,-0.0060768034,0.024137827,-0.020350788,-0.022020472,-0.015111852,-0.016128182,0.00051459245,0.024149925,0.0017135437,-0.0028796003,0.0017543783,-0.042056683,0.044089343,-0.023883743,0.013466367,-0.023738554,-0.01168174,-0.006364159,0.009885014,0.00012713572,-0.007011464,-0.0049546063,0.00076565,0.0049001602,0.003287947,-0.030005919,-0.002522675,0.020374987,0.009068321,0.008154835,-0.017386494,0.025650222,0.0245129,-0.0019963617,0.03375666,-0.007574075,-0.020653268,-0.014627886,-0.0041742106,0.0288444,0.016479056,0.00461583,-0.025432436,-0.01600719,0.02710212,0.010175394,0.007126406,-0.0576888,0.0066242907,0.007453083,0.020423384,0.024452405,0.018983584,0.0005255573,-0.008529908,0.010036254,0.024270916,-0.020883152,0.0024394933,0.030659273,0.019685335,0.033563074,0.018064048,0.019044079,-0.02782807,0.02927997,0.020967847,-0.00029227036,-0.018354427,0.0065819435,0.011482104,-0.015257042,0.00022440162,-0.0012507507,0.00076300337,0.018656906,0.02049598,0.03186919,0.0039322274,-0.01974583,-0.015353835,0.01990312,0.025408238,-0.04914679,-0.034531005,-0.014821473,-0.0052298624,0.045759026,0.0053115315,0.022952108,-0.0040441444,0.052945927,-0.0101935435,0.042056683,-0.03968525,-0.057495214,-0.002935559,0.029497754,0.017362297,-0.0014692919,0.005783399,0.017688973,0.03951586,0.013478465,0.01917717,0.0027162617,0.0077918596,0.021863183,-0.0020613945,0.010598865,-0.0061735967,-0.014821473,0.035692524,0.032982312,-0.0037144425,0.023254588,0.024525,-0.0102540385,-0.028892796,-0.04975175,0.0004597681,0.015123951,-0.0028448151,-0.027344104,0.009195362,0.032183766,0.0077313636,-0.007973347,0.0023109398,0.018354427,0.020350788,0.02075006,-0.0015449116,-0.026642352,0.004863863,0.018281832,-0.0013029284,0.0230731,0.011379261,0.048130464,0.049654957,0.041354932,0.004500888,0.011693839,0.011935823,-0.03303071,-0.017096115,0.018523816,0.017967254,-0.0006635634,-0.012147558,0.022008374,0.012643623,-0.0075619756,0.042903624,0.031965982,0.022286655,0.014168117,-0.009183263,-0.045517042,-0.029086383,-0.039152883,-0.005680556,-0.022613332,-0.03056248,-0.013599457,-0.01846332,0.018995682,-0.028045855,-0.0071203564,0.015063455,-0.019237665,0.0041016154,-0.00706591,-0.014785174,0.0023321132,-0.010314534,0.01024799,-0.008348421,0.0113248145,0.008172983,-0.030199505,0.0028538895,0.015305439,-0.0063762576,-0.016515356,0.026037395,0.023278786,0.06088298,-0.0017362296,-0.010834798,-0.015874099,-0.02855402,-0.035087567,0.017483288,-0.045589637,-0.036708854,0.008130636,0.0069872653,0.052461963,-0.03545054,-0.03433742,-0.014785174,0.012619425,-0.06277045,-0.009528089,0.0009686891,0.0062068696,-0.022431845,-0.03274033,-0.012111261,0.0015486926,0.010617014,-0.0023865595,0.019854723,-0.023629662,-0.019830525,0.012934003,0.0023260636,-0.0065516955,0.02365386,0.009709577,-0.0030338645,0.0062976135]	483
16	7	================================================================================ J.Q PATISSERIE - QUICK REFERENCE Artisan French Pastries ================================================================================ LOCATION -------- J.Q Patisserie No. 23, Jalan Mawar 3 Taman Bunga Raya 86000 Kluang, Johor Malaysia OPERATING HOURS --------------- Tuesday - Friday : 10:00 AM - 7:00 PM Saturday - Sunday : 9:00 AM - 8:00 PM Monday : CLOSED * Pre-orders recommended for custom cakes (min. 3 days advance) CONTACT ------- Phone : +60 12-345 6789 WhatsApp : +60 12-345 6789 Email : hello@jqpatisserie.com Instagram : @j.q_patisserie QUICK FACTS ----------- > Specialty : French-style pastries & artisan cakes > Price Range : RM8 - RM180 > Best For : Celebrations, gifts, afternoon tea > Payment : Cash, Cards, TnG, GrabPay, DuitNow SIGNATURE ITEMS --------------- [★] Burnt Basque Cheesecake [★] Croissants (Plain, Almond, Chocolate) [★] Mille-Feuille [★] Fruit Tarts [★] Custom Birthday Cakes SERVICES -------- [✓] Walk-in purchases [✓] Pre-orders & custom cakes [✓] Self-pickup [✓] Local delivery (Kluang area) [✓] Event & wedding cakes [✓] Corporate gifting HOW TO ORDER CUSTOM CAKES ------------------------- 1. WhatsApp us with your design/idea 2. Confirm flavour, size & budget 3. Pay 50% deposit to secure booking 4. Collect on scheduled date ================================================================================ Follow us @j.q_patisserie for daily specials! ================================================================================	0	2025-12-21 23:53:50	2025-12-21 23:53:50	[0.0054776366,0.022737112,0.003998347,-0.07557171,-0.010725672,-0.033482466,-0.008331256,0.010929033,-0.039911307,-0.009800706,0.0002218115,-0.0649182,-0.009387423,0.030779727,-0.008272216,0.057570945,-0.018709246,-0.006822446,0.0013997494,0.030517325,0.05051234,0.002081174,0.014838819,-0.0060188402,-0.0003728975,-0.006979887,-0.027316023,-0.011421037,0.04497566,0.0044214698,0.024587044,-0.011375116,-0.011237356,-0.017121715,-0.018840447,-0.029284038,-0.010620711,0.0076227714,-0.03303638,0.017161075,-0.02681746,-0.015757225,0.010273029,0.051719386,0.015678504,0.027998269,-0.011637518,0.0011283276,-0.01657067,0.050459858,0.05248035,0.062399138,-0.059932563,-0.0126936855,0.009426784,0.00596308,-0.028208189,0.008127894,0.08748475,0.0411446,0.020178696,-0.058725514,0.0020729739,-0.021976147,0.006737165,-0.020887181,-0.021569425,0.04649759,-0.014694499,0.04347997,-0.00085772574,0.013277529,-0.019706372,-0.03875674,0.014523937,-0.013100408,0.037759613,0.012162322,0.006376363,-0.012595285,-0.013100408,0.0012710085,0.023288157,-0.0044050696,0.029179076,-0.055891577,-0.12311891,0.021831827,-0.053844843,0.037523452,0.028155709,-0.0059434,0.0011652278,0.021241423,0.08533306,-0.023065114,-0.036736246,0.024652645,-0.012286963,0.02525617,0.063763626,-0.04783584,0.003899946,-0.019981895,0.05552421,-0.0036965848,0.0058777994,-0.027316023,-0.042141724,-0.02226479,-0.06911662,-0.032957662,0.013684252,0.02233039,0.023117594,0.02980884,0.02983508,-0.08197431,0.026043374,-0.039438985,-0.0043427492,0.007629331,0.0051496346,-0.015298023,-0.010856873,-0.017134836,-0.045028143,-0.021228302,0.00048298325,-0.0016957714,0.03854682,-0.043611173,0.05625894,-0.03290518,0.024652645,-0.027211063,0.04759968,0.032957662,-0.06979887,-0.009518624,0.041197076,-0.04571039,-0.008062294,0.022973275,-0.012975767,-0.011283276,-0.0625041,-0.03421719,0.0030832207,0.05673126,0.0034145028,-0.036263924,-0.012490324,-0.071583204,-0.013697372,-0.020664139,0.034532074,0.052532833,-0.030281164,0.023471838,0.003247222,0.0063370024,0.00898726,-0.036972407,0.0058777994,-0.002212375,-0.005333316,0.029913802,-0.04004251,-0.02379984,-0.005231635,-0.0130610475,0.05095842,0.04148572,-0.025741613,0.018617405,0.057413507,-0.008219736,0.004139388,-0.013028247,-0.008462457,0.043716133,0.028444352,-0.02679122,0.001052067,0.012916727,0.018643646,-0.024928167,-0.006507564,0.027289784,0.011197995,-0.013749853,-0.050669782,-0.019011008,0.026581299,-0.039097864,0.05169315,0.020139335,-0.02973012,0.052900195,-0.037575934,-0.004339469,0.009603905,0.034059748,0.029493958,-0.0069142864,0.0057531586,-0.0050184336,0.024849446,-0.036290165,0.07935029,0.0384681,-0.0065042838,0.05809575,0.0036047443,0.03983259,-0.04471326,0.032196697,0.00902006,0.020126216,-0.020336136,-0.009098781,0.03290518,0.010574791,-0.028103229,0.024036001,0.022172948,0.009853186,-0.0035260236,-0.04468702,-0.012437844,-0.012647765,-0.013854813,0.037313532,-0.050249938,0.0134021705,-0.009643265,-0.033823587,0.0056252377,-0.070061274,0.0062418818,0.041328277,-0.005654758,0.01333001,0.03140949,-0.016649392,-0.009525184,-0.06344875,0.037654653,-0.016098348,0.07368241,-0.020637898,-0.02255343,-0.011020874,0.017292276,-0.0036145842,-0.0070192474,-0.0009881066,0.03852058,-0.04613023,0.024311524,0.026568178,0.009931907,-0.010797832,0.020716619,-0.0028486992,-0.0050053135,0.015639145,-0.03154069,0.010935593,-0.043821093,-0.04628767,0.05788583,0.038966663,-0.0088691795,-0.00591716,-0.0062025217,0.013920413,0.005677718,0.02807699,-0.022723993,-0.017712118,0.007898293,-0.05615398,-0.004323069,-0.0063206023,0.03852058,-0.030045003,-0.027053623,0.015245543,-0.021110222,-0.03558168,-0.016714992,-0.008567418,0.018486204,0.0036342645,-0.014274656,0.006146761,0.028759234,0.01929965,-0.00024108162,0.0022812553,-0.017161075,-0.0014333696,-0.0389929,0.020454217,-0.024259044,0.06497068,0.014720739,0.013047928,-0.021346383,0.03723481,0.022802712,-0.057151105,0.015914667,0.0069339667,0.042640287,0.005362836,0.010535431,-0.050800983,0.07803828,0.022671513,-0.007773652,0.018984767,-0.018486204,-0.042010523,0.03563416,-0.0064878836,0.0012751085,-0.018958528,0.00063263427,-0.048465606,-0.0030537006,-0.025518572,-0.024849446,0.026043374,-0.0073734894,-0.014956901,-0.0028470592,0.01628203,-0.024088481,-0.052664034,0.005228355,-0.057308543,0.024744486,-0.041774362,0.08606778,0.044004776,-0.0118868,0.022619031,-0.04912161,0.015061861,-0.0383369,0.0059926,0.035135597,-0.037654653,0.072422884,0.004585471,-0.07467954,0.024928167,-0.029572679,-0.013579291,0.0043755495,-0.0022025348,-0.0026240177,0.019115968,-0.018879807,0.0076490114,0.011342316,-0.010922474,-0.029441478,0.057833347,-0.015875306,-0.022067988,-0.06344875,-0.041406997,-0.013867933,0.038363136,0.073105134,-0.019050367,0.05814823,-0.012149202,0.06428843,0.027289784,0.046340153,-0.040672272,0.041065875,-0.017042994,0.032380376,-0.05552421,0.0048380326,0.0020729739,0.051010903,0.023537438,0.03749721,0.036526326,0.04906913,-0.018381244,-0.021766227,-0.014117215,-0.001189008,-0.0061369212,-0.007944213,-0.016531311,-0.015179942,0.038231935,-0.05339876,0.0018548524,-0.011342316,0.0013948294,-0.037838336,-0.023091355,-0.010122148,-0.021700626,0.0124050435,-0.049830094,0.046655033,0.027106103,-0.012208242,-0.030149963,-0.02841811,-0.02831315,-0.03413847,0.037995774,-0.04571039,-0.0014989701,0.0018302524,-0.060877208,-0.04896417,-0.039596427,-0.0059827603,-0.019483332,-0.05234915,-0.023550559,-0.018210683,-0.0074194097,-0.018997887,-0.014209055,-0.021149581,0.0074062897,-0.00749813,0.027237304,0.009243102,0.0063534025,-0.022802712,0.0043165092,0.027683387,0.022933913,0.043978535,-0.054369647,-0.030412365,0.04620895,0.014379617,-0.030753486,-0.038179457,0.05552421,0.011381676,-0.013723612,-0.01336281,-0.058987916,0.033167582,0.023707999,0.011466957,0.028890435,0.022474712,-0.015652265,-0.017069235,0.029520199,0.021188943,0.018486204,0.0018646925,-0.0089741405,0.013684252,0.00889542,-0.030648526,-0.0042476286,-0.05082722,0.014668259,-0.050354898,-0.01638699,-0.026108975,0.006245162,-0.021556305,-0.025662892,-0.018945407,0.009781025,0.030884687,0.01939149,-0.030071242,-0.0055497973,-0.04022619,0.027919548,0.025505451,-0.013894173,0.0017072514,-0.020218056,0.017069235,-0.017344756,-0.011243915,0.025216809,0.0010463271,-0.0356604,-0.00739973,0.06071977,0.007734292,0.035161838,-0.028969154,0.051142104,0.007839252,0.018669885,0.008416536,0.006999567,-0.007983574,-0.027630907,-0.036106482,0.009085661,-0.038284417,0.043899816,-0.015402984,-0.01043047,-0.014642019,-0.0019696532,0.017134836,-0.033456225,0.015166822,-0.019614533,0.002827379,-0.05389732,0.0064288434,-0.054579567,0.03301014,-0.02988756,-0.012962647,0.0120114405,-0.010856873,-0.0045198705,-0.0011529278,0.03584408,-0.019601412,0.002820819,-0.00042558287,0.03112085,-0.014261536,0.0023140556,-0.021687506,-0.0046969918,0.019916294,-0.021346383,-0.016058987,0.0022107349,-0.006432123,0.0030635407,0.0072619687,0.0015104502,0.052926436,-0.028864194,-0.013736732,-0.018263163,0.039202824,-0.0032078614,0.02831315,0.029074116,-0.027447224,0.030018762,0.03571288,0.013231609,0.01486506,-0.009597344,-0.007911413,0.004887233,-0.011742479,0.0535562,0.011525998,-0.031566933,0.006881486,-0.0009889266,0.023931041,-0.006350123,-0.009866307,0.031042129,-0.033849828,-0.0052742753,-0.04174812,0.0036506646,-0.009380863,0.029546438,0.005402196,0.013539931,0.021779347,0.03421719,-0.0035063436,0.024665765,-0.0125362445,-0.0056973984,0.005822039,0.0018778127,-0.062923945,0.022527192,0.021188943,-0.031593174,-0.010049988,0.01645259,-0.043794855,-0.018446844,-0.033666145,0.015914667,0.009938466,-0.00026506677,0.007760532,-0.02681746,0.034164708,-0.0023944161,2.215296e-05,-0.038363136,-0.019024128,-0.024875687,-0.0356604,-0.004155788,-0.018328764,-0.0037851455,0.028155709,0.008055734,0.052296672,0.0008774059,-0.0055957176,0.041879322,0.0121951215,-0.009990947,-0.0066453246,-0.0022533752,0.012542805,0.011788399,-0.015193062,0.0036309843,0.02970388,0.0045362706,0.012444404,-0.04358493,0.014497697,-0.04744224,-0.025466092,0.021057742,0.021110222,-0.023996642,0.010555111,0.013343129,-0.0045198705,0.011598158,0.0019565332,-0.02508561,0.020152455,0.003565384,0.016596911,-0.01804012,0.004162348,0.011617838,0.014445217,0.0058384393,-0.015665386,0.032511577,-0.027683387,0.0064255632,0.0039425865,-0.0065272436,0.01944397,0.029546438,-0.020546058,-0.041065875,0.020270536,-0.038074497,0.03301014,0.017449718,0.034741994,0.0015842506,-0.04040987,0.004037707,-4.515155e-05,-0.033771105,0.00029130696,0.0021533344,7.82849e-06,-0.027184824,-0.012647765,0.01335625,-0.017213555,-0.005789239,0.013644892,0.005822039,-0.0049921935,-0.018433724,0.0124575235,-0.00890198,0.04145948,-0.01344809,-0.007268529,0.008055734,0.01479946,0.018289402,-0.02368176,-0.09315263,-0.00038376258,-0.028811714,-0.010253349,0.016478831,-0.021726865,0.036027763,-0.043847334,0.0024796966,0.035345517,-0.010601032,-0.009938466,0.002405896,-0.03972763,0.0051922747,-0.011099595,0.021398865,-0.026279537,-0.031855576,0.0388617,-0.0014751899,0.00748501,0.04216796,0.0041065877,-0.03434839,0.029047875,0.021503825,-0.026292657,-0.005257875,0.002230415,0.012424723,-0.020388616,0.0060057202,0.04615647,0.032013014,-0.037733372,0.00296842,-0.02221231,0.009361183,-0.008508377,-0.032301657,0.012575605,-0.011296396,-0.021293903,-0.0042377883,0.007760532,0.02087406,0.015534184,0.015232422,-0.040960915,0.023183195,0.02236975,0.011289836,0.00077408523,0.0059269997,-0.011276715,-0.03424343,0.012516564,0.010568231,-0.009006941,0.011578478,0.0057793986,0.016006507,-0.0125362445,0.028785473,-0.019588292,-0.0025944975,0.019627651,-0.006192682,-0.018092602,-0.021411983,-0.0026896182,-0.023589918,0.021228302,0.015809705,0.016203308,-0.025689133,0.01334969,0.0075506107,-0.021097101,0.014983141,0.058620553,-0.024219682,0.02530865,-0.021739986,-0.00445755,-0.027132342,-0.0010635471,-0.056783743,-0.033456225,-0.023550559,0.015796587,0.00042271285,0.031461973,0.0016227909,0.0042574685,-0.018197563,-0.0051365145,-0.050328657,0.015849067,0.003719545,-0.024416484,-0.0018581325,-0.015219302,-0.022907674,0.0012915087,0.011663758,-0.017436597,0.08622522,0.0297826,0.0018581325,0.025571052,-0.024403363,0.019089729,0.012418163,0.034873195,-0.003296422,-0.0076949317,-0.011401356,0.006979887,0.004018027,0.051561948,0.0025797372,-0.027263543,0.0128773665,-0.015193062,-0.0065108435,-0.026541939,0.016977394,-0.031094609,0.010535431,0.007891733,-0.009164382,0.011493198,-0.0035358637,-0.0042443485,0.022763353,-0.036027763,-0.014327136,-0.032642778,0.03442711,0.014733859,0.0094202235,-0.0026371377,0.012470644,-0.019575171,0.011053674,-4.320404e-05,0.003266902,-0.0039885067,0.022855194,-0.024364004,0.017082354,0.01923405,0.011447277,-0.028654272,0.007301329,-0.01922093,-0.0132972095,0.006796206,-0.016911794,-0.021792466,0.005516997,0.011053674,-0.012063921,0.014418977,-0.001936853,0.0040442673,0.022881433,0.0021992547,0.04054107,-0.017318517,-0.029966282,-0.020178696,-0.027552186,-0.01929965,0.015468584,-0.02225167,-0.004654351,-0.006986447,-0.06827694,0.034374632,0.01344809,-0.007983574,-0.007714612,-0.033403743,0.06103465,0.013762972,0.014366496,-0.019798214,0.0025387371,0.0013005288,0.024298403,-0.0049725133,-0.025885934,-0.014563298,0.018118842,0.01190648,0.019142209,-0.0036605047,-0.015678504,-0.015586665,0.00028761695,-0.0064124432,0.0043952297,0.001782692,0.009721985,0.002701098,0.0071766884,-0.009065981,0.00043952296,0.045579188,-0.006881486,-0.0024288562,0.010732232,0.046864957,-0.011716239,0.0013120088,0.050144978,-0.029467719,0.008469017,-0.017384117,-0.007963894,-0.02970388,0.028837955,0.0034702632,0.009459584,0.0036244243,-0.012733046,0.030858448,-0.023445597,0.018341884,0.020532938,0.008278776,-0.02075598,0.024403363,-0.026555058,0.01343497,0.009321823,0.0074784504,0.023353757,0.029021636,-0.004182028,0.016990514,-0.012569045,0.011079915,0.036158964,-0.021556305,0.039438985,0.044004776,-0.02374736,0.042377885,-0.016859313,-0.0049790735,-0.016846193,0.0060122805,0.027473465,0.025990894,0.0057105185,0.01347433,0.042141724,-0.011079915,0.03387607,-0.009269342,0.00083558564,0.027840827,0.0073210094,0.029677639,0.014169695,0.022907674,0.038074497,0.009229982,0.009813826,-0.0055366773,0.016780593,-0.0037884254,-0.025767853,0.021477584,0.003899946,0.041039634,-0.00030381203,-0.004139388,0.030281164,-0.008560858,-0.014615778,-0.040593553,0.01650507,0.030386124,0.012450963,-0.013972894,0.00890198,-0.033325024,0.012739605,0.024521444,0.0081344545,-0.020257415,-0.029231556,-0.020126216,0.050118737,0.0074194097,0.0062025217,-0.0082394155,-0.0030684606,0.014655138,-0.053241316,-0.025439851,0.004785552,0.036263924,-0.0031553812,-0.03261654,-0.028103229,0.0125887245,-0.031750612,0.0005662138,-0.029520199,0.01641323,-0.021648146,0.0058646793,-0.023603039,-0.036473844,-0.037812095,0.028732993,0.0058581196,-0.007596531,0.0011381677,-0.001189008,-0.008469017,0.02225167,-0.011735919,0.0447395,0.008803579,-0.034873195,0.011414477,-0.022947034,-0.0025780974,0.021162702,0.008154135,0.006100841,-0.030412365,0.0027224184,0.019785093,-0.009853186,0.0045231506,-0.0041295476,0.0021074142,0.050354898,0.02386544,0.021411983,-0.016964274,0.0069602067,0.019929415,-0.005543237,-0.034269672,0.01491754,-0.00034050728,0.0044214698,-0.022067988,-0.013592412,0.010942154,0.003886826,0.030071242,-0.028759234,-0.019955654,-0.024639526,-0.0045395503,0.02999252,-0.011998321,0.0132709695,-0.0006588744,0.0005371036,0.0022632151,-0.0012168882,0.016780593,-0.028811714,0.025977775,0.018643646,0.017042994,-0.033534944,-0.05767591,-0.0039360262,-0.01926029,0.029467719,0.018145083,-0.016163949,-0.018473085,0.01045671,0.026082736,-0.0131397685,0.0014555098,0.006861806,-0.030989649,-0.025046248,-0.007911413,0.007963894,0.032065496,-0.01637387,-0.024875687,0.0084493365,0.06843438,0.020165576,0.039071623,0.033849828,0.010732232,-0.0134021705,-0.005615398,0.0046904315,0.010948714,-0.0014620698,-0.00023739159,-0.0036014642,0.0026387777,0.00887574,0.036447603,0.045028143,-0.0062156417,-0.017252916,-0.0044214698,-0.012680565,0.032249175,-0.04033115,0.040750995,-0.04626143,-0.012470644,0.0062156417,0.0054218764,0.0071898084,-0.027263543,0.011020874,-0.0091053415,-0.034269672,0.012733046,-0.0005219335,-0.00045018303,0.004267309,-0.021044621,0.0040672272,-0.01028615,0.012050801,-0.0040147468,-0.0008220555,-0.010266469,-0.0020434537,0.005762999,-0.007143888,0.028916674,0.015547304,-0.020034375,0.0122738425,0.093310066,0.003280022,0.018066362,-0.024062242,0.013776093,-0.005359556,-0.0325903,-0.033849828,-0.011434156,-0.0057498785,0.029467719,-0.015416103,0.030045003,0.0026272978,0.047967043,-0.00072283484,-0.050984662,0.00086838583,0.012352563,0.001633451,-0.018879807,0.008114775,0.028995395,0.010817513,-0.009361183,0.0124050435,-0.014733859,-0.049698893,-0.021989267,0.017187316,-0.0024796966,0.04864929,0.0020942942,0.00020254136,0.003117661,-0.018289402,0.013841693,0.0034768234,0.018827327,0.008042614,-0.022120468,0.023091355,-0.01189992,0.03760217,0.013146329,0.011788399,-0.01804012,-0.033193823,-0.033351265,-0.016203308,0.045080625,0.0060418006,0.01785644,0.0058843596,-0.011112715,-0.017384117,-0.01928653,-0.0015243902,-0.009748225,0.01792204,-0.031829335,0.01336281,0.025466092,-0.007596531,-0.0045461105,-0.00076916517,-0.03996379,0.009302142,-0.018407485,0.0087379785,0.011007754,0.033771105,-0.014117215,0.016255789,0.000108445725,0.016583791,-0.028732993,0.007898293,0.000601474,-0.016163949,-0.0089479005,0.031593174,0.030018762,0.008724859,0.000894626,-0.0479408,-0.02675186,-0.0064288434,-0.0022582952,0.038126975,-0.012595285,0.025728492,-0.026030255,-0.029205317,-0.0056678783,0.023931041,-0.052191712,-0.02373424,-0.015022501,0.023327516,0.019995015,0.0082918955,-0.0044149095,0.015389863,-0.0013038088,0.005543237,0.004208268,-0.020532938,-0.02667314,-0.023563677,-0.018683005,-0.0006420643,0.017423477,-0.013074168,-0.0057105185,-0.0006822446,-0.018722367,0.025741613,0.037654653,-0.014274656,0.011611278,0.01479946,0.023051996,0.006520684,0.02244847,-0.010325509,0.03256406,0.03143573,-0.005352996,0.009170942,-0.0016826513,0.03411223,-0.01343497,0.027499706,0.0026289376,0.02660754,-0.038940422,0.018250043,0.0014161495,0.006993007,-0.027473465,0.026200816,-0.027473465,-0.025899054,-0.010738792,0.0032045816,-0.013854813,-0.0010807673,0.02222543,0.003699865,-0.0036309843,0.02221231,0.018079482,-0.027657146,-0.029913802,0.013789212,-0.0005387436,0.007589971,0.020323016,-0.042404126,-0.015757225,-0.0049626734,-0.024954408,0.010023748,-0.008186935,-0.006409163,0.014458337,0.013080728,-0.014773219,-0.0267125,-0.014340256,-0.010187749,0.011184875,-0.015927788,0.003555544,0.0057433187,-0.038179457,0.025820334,-0.026856821,0.009695745,-0.017003635,0.0016219709,0.018315643,0.003598184,0.014182815,-0.040567312,-0.01191304,-0.010017187,0.005628518,0.009544864,-0.011571918,-0.021136463,0.039412744,0.032983903,-0.0042640287,0.027158583,0.028890435,0.017699,-0.017554678,0.030805968,0.005087314,-0.0049954737,-0.0325903,0.010266469,0.03248534,0.0239048,-0.018381244,-0.018027002,-0.010837193,0.014287776,0.011257036,-0.010502631,-0.028523073,0.0008179555,0.0066551645,-0.0022435351,0.01637387,0.02986132,0.011788399,-0.004785552,0.013854813,0.017357877,-0.026463218,0.015114342,0.02373424,-0.014274656,0.008560858,0.0078064525,0.007819572,-0.030307403,0.0067765256,0.023589918,0.011191435,0.006277962,-0.0011709678,0.00079663534,-0.00042722287,-0.008154135,-0.0039885067,0.005015154,-0.0075046904,0.0034505832,0.0034538633,-0.0030422204,-0.052900195,-0.020598538,0.006130361,-0.0047199517,-0.048072003,-0.014104094,-0.033429984,-0.00745877,0.03715609,-0.0045756306,0.019732613,-0.011696558,0.024731366,-0.016964274,0.03576536,-0.019863814,-0.021608785,-0.033482466,0.019942533,0.037707135,-0.023196315,0.002235335,0.013487451,0.011847439,-0.0019844132,-0.0010364869,-0.0017679319,-0.035450477,0.049567692,-0.012555924,0.018643646,0.01634763,-0.007767092,0.03442711,0.015219302,0.010174628,0.011440717,0.019798214,0.009426784,-0.045159344,-0.040357392,-0.0076621315,0.0013841693,-0.006842126,-0.005684278,0.024875687,0.008409977,0.010607591,-0.017738359,0.0012619885,0.0239704,0.024993768,0.012149202,0.00023021655,-0.019575171,-0.006218922,0.0239048,-0.008206615,0.023642398,-0.007891733,0.03841562,0.028155709,0.046655033,0.006100841,-6.0577906e-05,0.002507577,-0.02812947,-0.0018892927,-8.338431e-05,0.003998347,0.02382608,0.0052841157,0.005061074,-0.0046182713,-0.011132395,0.036683768,0.011033994,0.007589971,0.016833073,-0.023117594,-0.014314016,-0.018184442,-0.054264683,0.0024829768,-0.00595324,-0.03999003,-0.006717485,-0.030071242,0.006986447,-0.025216809,-0.004182028,0.0046740314,-0.045684148,0.03841562,-0.012136081,0.005674438,0.018879807,-0.007944213,0.03844186,0.0029339797,0.020336136,0.014104094,-0.022645272,0.017384117,0.022041747,-0.007163568,0.004122988,0.01195896,0.0055957176,0.04334877,-0.0082394155,-0.0033423426,-0.015442343,-0.014064735,-0.0088166995,0.02215983,-0.043742374,-0.0025994175,0.02831315,0.0009151262,0.05195555,-0.015009381,-0.037917055,-0.021674385,-0.019706372,-0.029205317,-0.004637951,0.01634763,0.01339561,-0.013526811,-0.027919548,0.016531311,-0.01790892,0.0052381954,-0.004614991,0.007157008,0.0059073195,-0.029493958,-0.008331256,-0.009289023,0.0008470657,0.0048052324,0.012306643,-0.009925347,-0.0054415567]	395
\.


--
-- TOC entry 3882 (class 0 OID 44423)
-- Dependencies: 250
-- Data for Name: documents; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.documents (id, user_id, original_name, status, chunks_count, error_message, created_at, updated_at, media_id) FROM stdin;
1	2	Bonne_Bouche_Business_Profile.docx	completed	2	\N	2025-12-21 23:51:51	2025-12-21 23:51:56	1
2	2	Bonne_Bouche_Customer_Guide_FAQ.pdf	completed	3	\N	2025-12-21 23:52:54	2025-12-21 23:52:58	2
3	2	Bonne_Bouche_Menu_Guide.md	completed	4	\N	2025-12-21 23:53:04	2025-12-21 23:53:08	3
4	2	Bonne_Bouche_Quick_Reference.txt	completed	1	\N	2025-12-21 23:53:13	2025-12-21 23:53:14	4
5	3	JQ_Patisserie_About_Services.docx	completed	2	\N	2025-12-21 23:53:31	2025-12-21 23:53:34	5
6	3	JQ_Patisserie_Customer_FAQ.pdf	completed	3	\N	2025-12-21 23:53:39	2025-12-21 23:53:43	6
7	3	JQ_Patisserie_Quick_Reference.txt	completed	1	\N	2025-12-21 23:53:48	2025-12-21 23:53:50	7
\.


--
-- TOC entry 3886 (class 0 OID 44456)
-- Dependencies: 254
-- Data for Name: email_verifications; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.email_verifications (id, email, code, business_type, expires_at, created_at, updated_at) FROM stdin;
\.


--
-- TOC entry 3860 (class 0 OID 44217)
-- Dependencies: 228
-- Data for Name: failed_jobs; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.failed_jobs (id, uuid, connection, queue, payload, exception, failed_at) FROM stdin;
\.


--
-- TOC entry 3858 (class 0 OID 44209)
-- Dependencies: 226
-- Data for Name: job_batches; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.job_batches (id, name, total_jobs, pending_jobs, failed_jobs, failed_job_ids, options, cancelled_at, created_at, finished_at) FROM stdin;
\.


--
-- TOC entry 3857 (class 0 OID 44200)
-- Dependencies: 225
-- Data for Name: jobs; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.jobs (id, queue, payload, attempts, reserved_at, available_at, created_at) FROM stdin;
\.


--
-- TOC entry 3888 (class 0 OID 44477)
-- Dependencies: 256
-- Data for Name: media; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.media (id, user_id, disk, path, original_name, file_type, mime_type, file_size, cloudinary_public_id, metadata, created_at, updated_at, mediable_type, mediable_id) FROM stdin;
5	3	cloudinary	documents/files/3/1766332410_JQ_Patisserie_About_Services.docx	JQ_Patisserie_About_Services.docx	docx	application/vnd.openxmlformats-officedocument.wordprocessingml.document	11986	documents/files/3/1766332410_JQ_Patisserie_About_Services.docx	{"resource_type":"raw","folder":"documents\\/files\\/3","secure_url":"https:\\/\\/res.cloudinary.com\\/dbpnviwkw\\/raw\\/upload\\/v1766332411\\/documents\\/files\\/3\\/1766332410_JQ_Patisserie_About_Services.docx","format":"docx","width":null,"height":null}	2025-12-21 23:53:31	2025-12-21 23:53:34	\N	\N
1	2	cloudinary	documents/files/2/1766332307_Bonne_Bouche_Business_Profile.docx	Bonne_Bouche_Business_Profile.docx	docx	application/vnd.openxmlformats-officedocument.wordprocessingml.document	11636	documents/files/2/1766332307_Bonne_Bouche_Business_Profile.docx	{"resource_type":"raw","folder":"documents\\/files\\/2","secure_url":"https:\\/\\/res.cloudinary.com\\/dbpnviwkw\\/raw\\/upload\\/v1766332311\\/documents\\/files\\/2\\/1766332307_Bonne_Bouche_Business_Profile.docx","format":"docx","width":null,"height":null}	2025-12-21 23:51:51	2025-12-21 23:51:56	\N	\N
2	2	cloudinary	documents/files/2/1766332372_Bonne_Bouche_Customer_Guide_FAQ.pdf	Bonne_Bouche_Customer_Guide_FAQ.pdf	pdf	application/pdf	7441	documents/files/2/1766332372_Bonne_Bouche_Customer_Guide_FAQ.pdf	{"resource_type":"raw","folder":"documents\\/files\\/2","secure_url":"https:\\/\\/res.cloudinary.com\\/dbpnviwkw\\/raw\\/upload\\/v1766332374\\/documents\\/files\\/2\\/1766332372_Bonne_Bouche_Customer_Guide_FAQ.pdf","format":"pdf","width":null,"height":null}	2025-12-21 23:52:54	2025-12-21 23:52:58	\N	\N
9	3	cloudinary	products/3/1766332653_hq720	hq720.jpg	jpg	image/jpeg	66710	products/3/1766332653_hq720	{"resource_type":"image","folder":"products\\/3","secure_url":"https:\\/\\/res.cloudinary.com\\/dbpnviwkw\\/image\\/upload\\/v1766332655\\/products\\/3\\/1766332653_hq720.jpg","format":"jpg","width":686,"height":386}	2025-12-21 23:57:35	2025-12-21 23:57:35	App\\Models\\Product	1
3	2	cloudinary	documents/files/2/1766332382_Bonne_Bouche_Menu_Guide.md	Bonne_Bouche_Menu_Guide.md	md	text/plain	5906	documents/files/2/1766332382_Bonne_Bouche_Menu_Guide.md	{"resource_type":"raw","folder":"documents\\/files\\/2","secure_url":"https:\\/\\/res.cloudinary.com\\/dbpnviwkw\\/raw\\/upload\\/v1766332384\\/documents\\/files\\/2\\/1766332382_Bonne_Bouche_Menu_Guide.md","format":"md","width":null,"height":null}	2025-12-21 23:53:04	2025-12-21 23:53:08	\N	\N
6	3	cloudinary	documents/files/3/1766332418_JQ_Patisserie_Customer_FAQ.pdf	JQ_Patisserie_Customer_FAQ.pdf	pdf	application/pdf	7637	documents/files/3/1766332418_JQ_Patisserie_Customer_FAQ.pdf	{"resource_type":"raw","folder":"documents\\/files\\/3","secure_url":"https:\\/\\/res.cloudinary.com\\/dbpnviwkw\\/raw\\/upload\\/v1766332419\\/documents\\/files\\/3\\/1766332418_JQ_Patisserie_Customer_FAQ.pdf","format":"pdf","width":null,"height":null}	2025-12-21 23:53:39	2025-12-21 23:53:43	\N	\N
4	2	cloudinary	documents/files/2/1766332392_Bonne_Bouche_Quick_Reference.txt	Bonne_Bouche_Quick_Reference.txt	txt	text/plain	1594	documents/files/2/1766332392_Bonne_Bouche_Quick_Reference.txt	{"resource_type":"raw","folder":"documents\\/files\\/2","secure_url":"https:\\/\\/res.cloudinary.com\\/dbpnviwkw\\/raw\\/upload\\/v1766332393\\/documents\\/files\\/2\\/1766332392_Bonne_Bouche_Quick_Reference.txt","format":"txt","width":null,"height":null}	2025-12-21 23:53:13	2025-12-21 23:53:14	\N	\N
10	3	cloudinary	products/3/1766332655_images	images.jpg	jpg	image/jpeg	6315	products/3/1766332655_images	{"resource_type":"image","folder":"products\\/3","secure_url":"https:\\/\\/res.cloudinary.com\\/dbpnviwkw\\/image\\/upload\\/v1766332657\\/products\\/3\\/1766332655_images.jpg","format":"jpg","width":192,"height":143}	2025-12-21 23:57:36	2025-12-21 23:57:36	App\\Models\\Product	1
7	3	cloudinary	documents/files/3/1766332427_JQ_Patisserie_Quick_Reference.txt	JQ_Patisserie_Quick_Reference.txt	txt	text/plain	1676	documents/files/3/1766332427_JQ_Patisserie_Quick_Reference.txt	{"resource_type":"raw","folder":"documents\\/files\\/3","secure_url":"https:\\/\\/res.cloudinary.com\\/dbpnviwkw\\/raw\\/upload\\/v1766332429\\/documents\\/files\\/3\\/1766332427_JQ_Patisserie_Quick_Reference.txt","format":"txt","width":null,"height":null}	2025-12-21 23:53:48	2025-12-21 23:53:50	\N	\N
8	3	cloudinary	products/3/1766332649_Screenshot_2025-12-21_234521	Screenshot 2025-12-21 234521.png	png	image/png	627464	products/3/1766332649_Screenshot_2025-12-21_234521	{"resource_type":"image","folder":"products\\/3","secure_url":"https:\\/\\/res.cloudinary.com\\/dbpnviwkw\\/image\\/upload\\/v1766332653\\/products\\/3\\/1766332649_Screenshot_2025-12-21_234521.png","format":"png","width":743,"height":459}	2025-12-21 23:57:33	2025-12-21 23:57:33	App\\Models\\Product	1
11	3	cloudinary	products/3/1766332719_Screenshot_2025-12-21_235818	Screenshot 2025-12-21 235818.png	png	image/png	690217	products/3/1766332719_Screenshot_2025-12-21_235818	{"resource_type":"image","folder":"products\\/3","secure_url":"https:\\/\\/res.cloudinary.com\\/dbpnviwkw\\/image\\/upload\\/v1766332723\\/products\\/3\\/1766332719_Screenshot_2025-12-21_235818.png","format":"png","width":713,"height":667}	2025-12-21 23:58:43	2025-12-21 23:58:43	App\\Models\\Product	2
12	3	cloudinary	products/3/1766332723_french-chocolate-eclairs-recipe	french-chocolate-eclairs-recipe.jpg	jpg	image/jpeg	46975	products/3/1766332723_french-chocolate-eclairs-recipe	{"resource_type":"image","folder":"products\\/3","secure_url":"https:\\/\\/res.cloudinary.com\\/dbpnviwkw\\/image\\/upload\\/v1766332725\\/products\\/3\\/1766332723_french-chocolate-eclairs-recipe.jpg","format":"jpg","width":1200,"height":1200}	2025-12-21 23:58:45	2025-12-21 23:58:45	App\\Models\\Product	2
13	3	cloudinary	products/3/1766332768_b590eda7-c75c-4393-820f-af909bf026a7_3024x3024	b590eda7-c75c-4393-820f-af909bf026a7_3024x3024.jpg	jpg	image/jpeg	776475	products/3/1766332768_b590eda7-c75c-4393-820f-af909bf026a7_3024x3024	{"resource_type":"image","folder":"products\\/3","secure_url":"https:\\/\\/res.cloudinary.com\\/dbpnviwkw\\/image\\/upload\\/v1766332772\\/products\\/3\\/1766332768_b590eda7-c75c-4393-820f-af909bf026a7_3024x3024.jpg","format":"jpg","width":3024,"height":3024}	2025-12-21 23:59:32	2025-12-21 23:59:32	App\\Models\\Product	3
14	3	cloudinary	products/3/1766332778_images	images.jpg	jpg	image/jpeg	11485	products/3/1766332778_images	{"resource_type":"image","folder":"products\\/3","secure_url":"https:\\/\\/res.cloudinary.com\\/dbpnviwkw\\/image\\/upload\\/v1766332780\\/products\\/3\\/1766332778_images.jpg","format":"jpg","width":183,"height":275}	2025-12-21 23:59:40	2025-12-21 23:59:40	App\\Models\\Product	4
15	3	cloudinary	products/3/1766332867_images	images.jpg	jpg	image/jpeg	6637	products/3/1766332867_images	{"resource_type":"image","folder":"products\\/3","secure_url":"https:\\/\\/res.cloudinary.com\\/dbpnviwkw\\/image\\/upload\\/v1766332869\\/products\\/3\\/1766332867_images.jpg","format":"jpg","width":183,"height":275}	2025-12-22 00:01:08	2025-12-22 00:01:08	App\\Models\\Product	5
16	3	cloudinary	products/3/1766332874_62f83e07c05a47f9951a2dfbd32db73f	62f83e07c05a47f9951a2dfbd32db73f.jpg	jpg	image/jpeg	1267983	products/3/1766332874_62f83e07c05a47f9951a2dfbd32db73f	{"resource_type":"image","folder":"products\\/3","secure_url":"https:\\/\\/res.cloudinary.com\\/dbpnviwkw\\/image\\/upload\\/v1766332879\\/products\\/3\\/1766332874_62f83e07c05a47f9951a2dfbd32db73f.jpg","format":"jpg","width":3000,"height":1962}	2025-12-22 00:01:18	2025-12-22 00:01:18	App\\Models\\Product	6
17	3	cloudinary	products/3/1766332884_images_1_	images (1).jpg	jpg	image/jpeg	8819	products/3/1766332884_images_1_	{"resource_type":"image","folder":"products\\/3","secure_url":"https:\\/\\/res.cloudinary.com\\/dbpnviwkw\\/image\\/upload\\/v1766332885\\/products\\/3\\/1766332884_images_1_.jpg","format":"jpg","width":183,"height":275}	2025-12-22 00:01:25	2025-12-22 00:01:25	App\\Models\\Product	7
18	3	cloudinary	products/3/1766332891_images_2_	images (2).jpg	jpg	image/jpeg	11905	products/3/1766332891_images_2_	{"resource_type":"image","folder":"products\\/3","secure_url":"https:\\/\\/res.cloudinary.com\\/dbpnviwkw\\/image\\/upload\\/v1766332893\\/products\\/3\\/1766332891_images_2_.jpg","format":"jpg","width":247,"height":204}	2025-12-22 00:01:33	2025-12-22 00:01:33	App\\Models\\Product	8
19	3	cloudinary	products/3/1766332898_croissants-768x960	croissants-768x960.jpg	jpg	image/jpeg	192261	products/3/1766332898_croissants-768x960	{"resource_type":"image","folder":"products\\/3","secure_url":"https:\\/\\/res.cloudinary.com\\/dbpnviwkw\\/image\\/upload\\/v1766332901\\/products\\/3\\/1766332898_croissants-768x960.jpg","format":"jpg","width":768,"height":960}	2025-12-22 00:01:42	2025-12-22 00:01:42	App\\Models\\Product	9
20	3	cloudinary	products/3/1766332907_images_3_	images (3).jpg	jpg	image/jpeg	12552	products/3/1766332907_images_3_	{"resource_type":"image","folder":"products\\/3","secure_url":"https:\\/\\/res.cloudinary.com\\/dbpnviwkw\\/image\\/upload\\/v1766332909\\/products\\/3\\/1766332907_images_3_.jpg","format":"jpg","width":225,"height":225}	2025-12-22 00:01:49	2025-12-22 00:01:49	App\\Models\\Product	10
21	3	cloudinary	products/3/1766332967_images_4_	images (4).jpg	jpg	image/jpeg	9126	products/3/1766332967_images_4_	{"resource_type":"image","folder":"products\\/3","secure_url":"https:\\/\\/res.cloudinary.com\\/dbpnviwkw\\/image\\/upload\\/v1766332969\\/products\\/3\\/1766332967_images_4_.jpg","format":"jpg","width":275,"height":183}	2025-12-22 00:02:49	2025-12-22 00:02:49	App\\Models\\Product	11
22	3	cloudinary	products/3/1766332977_japanese-strawberry-shortcake_01_IMG_0066	japanese-strawberry-shortcake_01_IMG_0066.jpg	jpg	image/jpeg	78153	products/3/1766332977_japanese-strawberry-shortcake_01_IMG_0066	{"resource_type":"image","folder":"products\\/3","secure_url":"https:\\/\\/res.cloudinary.com\\/dbpnviwkw\\/image\\/upload\\/v1766332979\\/products\\/3\\/1766332977_japanese-strawberry-shortcake_01_IMG_0066.jpg","format":"jpg","width":741,"height":1112}	2025-12-22 00:02:59	2025-12-22 00:02:59	App\\Models\\Product	12
23	3	cloudinary	products/3/1766332986_add-on-6-pieces-of-french-macarons-macarons-luxe-florist-eat-cake-today-birthday-cake-delivery-klpjmalaysia-937034_large	add-on-6-pieces-of-french-macarons-macarons-luxe-florist-eat-cake-today-birthday-cake-delivery-klpjmalaysia-937034_large.jpg	jpg	image/jpeg	53229	products/3/1766332986_add-on-6-pieces-of-french-macarons-macarons-luxe-florist-eat-cake-today-birthday-cake-delivery-klpjmalaysia-937034_large	{"resource_type":"image","folder":"products\\/3","secure_url":"https:\\/\\/res.cloudinary.com\\/dbpnviwkw\\/image\\/upload\\/v1766332988\\/products\\/3\\/1766332986_add-on-6-pieces-of-french-macarons-macarons-luxe-florist-eat-cake-today-birthday-cake-delivery-klpjmalaysia-937034_large.jpg","format":"jpg","width":480,"height":480}	2025-12-22 00:03:08	2025-12-22 00:03:08	App\\Models\\Product	13
\.


--
-- TOC entry 3866 (class 0 OID 44268)
-- Dependencies: 234
-- Data for Name: merchant_settings; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.merchant_settings (id, user_id, business_name, greeting_message, ai_tone, booking_form_template, confirmation_template, reminder_template, reminder_hours_before, created_at, updated_at, email_on_escalation, notification_email) FROM stdin;
1	2	Bonne Bouche Café	Hi there! Welcome to Bonne Bouche Café 🍽️😊\n\nI'm a 24/7 auto-reply chatbot 🤖—always here to help, anytime!\n\nWhat would you like to do today?\n• Make a reservation 📅 (just send your date, time, number of guests, name & phone number)\n• Check your booking 🔍 (just ask!)\n\nIf you'd like to talk to a real person, just type "human", "admin", or "staff" and we'll assist you as soon as possible 💬	You are a friendly and always-available café chatbot. Communicate in a warm, casual, and helpful tone, use simple language and light emojis, and make customers feel welcome at any time of the day.	📅 Please provide your booking details:\n• Date: \n• Time: \n• Number of guests:\n• Name:\n• Phone:	✅ Your booking is confirmed!\n\n📅 Date: {date}\n⏰ Time: {time}\n👥 Guests: {pax}\n\nSee you soon! 🎉	⏰ Reminder: Your reservation is tomorrow!\n\n📅 {date} at {time}\n👥 {pax} guests\n\nWe look forward to seeing you!	24	2025-12-21 23:51:09	2025-12-21 23:51:09	t	\N
2	3	J.Q Patisserie	Hi there! Welcome to J.Q Patisserie😊\n\nI'm a 24/7 auto-reply chatbot 🤖—always here to help, anytime!\nWhat would you like to do today?\n- Place an order 📦 (just send what you want to buy with quantity!)\n- Check your order status 🔍 (just ask!)\n- Browse our products 📋 (just ask what we have!)\n\nIf you'd like to talk to a real person, just type "human", "admin", or "staff" and we'll assist you as soon as possible 💬	You are a friendly and always-available shop assistant chatbot. Communicate in a warm, helpful, and efficient tone. Use simple language and light emojis to make customers feel welcome. Be clear about order details, pricing, and delivery/pickup options. Always confirm orders accurately and provide helpful suggestions.	Great! Let's place your order 📦\n\nPlease fill in the details below:\n\n📦 *Products you want to order:*\n(e.g.:\nProduct A x2\nProduct B x3)\n\n📅 *When do you need it?* (e.g. 25-12-2024, 3:00pm):\n\n📍 *Delivery Address:*\n(Leave blank for self-pickup)\n\n📝 *Special Notes:* (optional)\n\n---\nJust copy, fill in, and send it back to me! 😊	✅ *Order Confirmed!* Thank you, {name}! 🎉\n\nYour order details:\n📦 Order #{order_code}\n\n*Items:*\n{items}\n\n💰 *Total: {total}*\n\n📅 *Scheduled: {datetime}*\n{fulfillment}\n{notes}\n\n---\nWe'll notify you once your order is ready. Thank you for choosing us! 🙏	⏰ *Friendly Reminder!*\n\nHi {name}! 👋\n\nYour order #{order_code} is scheduled for *{datetime}*.\n\n{fulfillment}\n\n💰 *Total: {total}*\n\nSee you soon! 😊🙏	24	2025-12-21 23:51:09	2025-12-21 23:51:09	t	hello@jqpatisserie.com
\.


--
-- TOC entry 3864 (class 0 OID 44248)
-- Dependencies: 232
-- Data for Name: messages; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.messages (id, conversation_id, direction, sender_type, message_type, content, whatsapp_message_id, status, metadata, created_at, updated_at) FROM stdin;
1	1	inbound	customer	text	Hi, I want to make a booking for tonight	\N	delivered	\N	2025-12-21 23:21:09	2025-12-21 23:21:09
2	1	outbound	ai	text	Welcome to Fine Dining Restaurant! 🍽️\n\nI'd be happy to help you with a reservation!\n\n📅 Please share:\n• Time: What time would you like?\n• Guests: How many people?	\N	delivered	\N	2025-12-21 23:23:09	2025-12-21 23:23:09
3	1	inbound	customer	text	7pm for 4 people please	\N	delivered	\N	2025-12-21 23:25:09	2025-12-21 23:25:09
4	1	outbound	ai	text	Perfect! Let me confirm:\n\n📅 Date: Today\n⏰ Time: 7:00 PM\n👥 Guests: 4\n\nShould I confirm this booking?	\N	delivered	\N	2025-12-21 23:27:09	2025-12-21 23:27:09
5	1	inbound	customer	text	Yes please	\N	delivered	\N	2025-12-21 23:29:09	2025-12-21 23:29:09
6	1	outbound	ai	text	✅ Your booking is confirmed!\n\n📅 Date: Today\n⏰ Time: 7:00 PM\n👥 Guests: 4\n🪑 Table: Table B1\n\nSee you tonight! 🎉	\N	delivered	\N	2025-12-21 23:31:09	2025-12-21 23:31:09
7	2	inbound	customer	text	Hello, do you have any special menu for vegetarians?	\N	delivered	\N	2025-12-21 23:31:09	2025-12-21 23:31:09
8	2	outbound	ai	text	Yes! We have a lovely vegetarian menu with various options including:\n• Garden Fresh Salad\n• Mushroom Risotto\n• Veggie Pasta\n\nWould you like to make a reservation?	\N	delivered	\N	2025-12-21 23:33:09	2025-12-21 23:33:09
9	2	inbound	customer	text	I want to talk to someone about allergies	\N	delivered	\N	2025-12-21 23:35:09	2025-12-21 23:35:09
10	2	outbound	ai	text	I'll connect you with our team. Someone will be with you shortly.	\N	delivered	\N	2025-12-21 23:37:09	2025-12-21 23:37:09
11	3	inbound	customer	text	What are your opening hours?	\N	delivered	\N	2025-12-21 23:31:09	2025-12-21 23:31:09
12	3	outbound	ai	text	We're open daily from 11:00 AM to 10:00 PM! 🕐\n\nWould you like to make a reservation?	\N	delivered	\N	2025-12-21 23:33:09	2025-12-21 23:33:09
13	3	inbound	customer	text	Thank you, I will come tomorrow	\N	delivered	\N	2025-12-21 23:35:09	2025-12-21 23:35:09
14	3	outbound	ai	text	You're welcome! Looking forward to seeing you. 😊	\N	delivered	\N	2025-12-21 23:37:09	2025-12-21 23:37:09
15	4	inbound	customer	text	Hi, do you have any cheesecake available?	\N	delivered	\N	2025-12-21 23:21:09	2025-12-21 23:21:09
16	4	outbound	ai	text	Hi! Yes, we do! 🧀\n\nOur signature Burnt Basque Cheesecake is available:\n\n• 6" (serves 6-8) - RM85\n• 8" (serves 10-12) - RM120\n• Slice - RM15.90\n\nIt's creamy with a beautiful caramelized top! Would you like to order?	\N	delivered	\N	2025-12-21 23:23:09	2025-12-21 23:23:09
17	4	inbound	customer	text	What other cakes do you have?	\N	delivered	\N	2025-12-21 23:25:09	2025-12-21 23:25:09
18	4	outbound	ai	text	We have a lovely selection! 🎂\n\n• Chocolate Ganache Cake (6") - RM95\n• Strawberry Shortcake (6") - RM110\n• Tiramisu Cake (6") - RM98\n• Ondeh-Ondeh Cake (6") - RM100\n• Durian Crepe Cake (6") - RM130\n\nAll whole cakes require 3 days advance order. Slices are available daily while stocks last!\n\nWhich one catches your eye? 😊	\N	delivered	\N	2025-12-21 23:27:09	2025-12-21 23:27:09
19	4	inbound	customer	text	I will come by this weekend to try some slices first, thanks!	\N	delivered	\N	2025-12-21 23:29:09	2025-12-21 23:29:09
20	4	outbound	ai	text	Sounds great! 🥐\n\nWe're open:\n• Saturday: 9am - 8pm\n• Sunday: 9am - 8pm\n\n📍 173, Jalan Paya 3/1, Kampung Paya, 86000 Kluang\n\nSee you this weekend! Our slices sell out fast, so come early for the best selection 😊	\N	delivered	\N	2025-12-21 23:31:09	2025-12-21 23:31:09
21	5	inbound	customer	text	Hi, I want to order a birthday cake for my wife this Saturday	\N	delivered	\N	2025-12-21 23:21:09	2025-12-21 23:21:09
22	5	outbound	ai	text	Happy to help with that! 🎂\n\nFor custom birthday cakes, please share:\n• Preferred cake flavour\n• Size (6" or 8")\n• Any design/message you'd like\n• Collection date & time\n\nWhat flavour does your wife like?	\N	delivered	\N	2025-12-21 23:23:09	2025-12-21 23:23:09
23	5	inbound	customer	text	She loves strawberry. 6 inch is fine. Can you write \\"Happy Birthday Aishah\\" on it?	\N	delivered	\N	2025-12-21 23:25:09	2025-12-21 23:25:09
24	5	outbound	ai	text	Lovely choice! 🍓\n\nHere's your order summary:\n\n🎂 Strawberry Shortcake 6"\n✍️ Message: "Happy Birthday Aishah"\n📅 Collection: Saturday\n💰 Total: RM110\n\nWe'll need a 50% deposit (RM55) to confirm. What time would you like to collect on Saturday?	\N	delivered	\N	2025-12-21 23:27:09	2025-12-21 23:27:09
25	5	inbound	customer	text	Around 2pm. I can bank transfer the deposit now	\N	delivered	\N	2025-12-21 23:29:09	2025-12-21 23:29:09
26	5	outbound	ai	text	✅ Order confirmed!\n\n🧁 Order ID: JQP-00001\n🎂 Strawberry Shortcake 6" with "Happy Birthday Aishah"\n💰 Total: RM110 (RM55 deposit received)\n📅 Collection: Saturday, 2:00 PM\n📍 173, Jalan Paya 3/1, Kampung Paya, 86000 Kluang\n\nWe'll send a reminder on Saturday morning! Thank you for choosing J.Q Patisserie 🥐🎉	\N	delivered	\N	2025-12-21 23:31:09	2025-12-21 23:31:09
27	6	inbound	customer	text	Hi, I'm from ABC Company. We need pastries for our company event next month - around 100 pax	\N	delivered	\N	2025-12-21 23:31:09	2025-12-21 23:31:09
28	6	outbound	ai	text	Thank you for considering J.Q Patisserie for your corporate event! 🏢\n\nFor bulk orders of 100 pax, we can offer:\n• Assorted croissants\n• Mini tarts\n• Macarons\n• Cookie boxes\n\nCould you share:\n• Event date\n• Budget per pax\n• Any dietary restrictions?	\N	delivered	\N	2025-12-21 23:33:09	2025-12-21 23:33:09
29	6	inbound	customer	text	It's on 15th January. Budget around RM15-20 per pax. Some staff are vegetarian. Can we get a formal quotation?	\N	delivered	\N	2025-12-21 23:35:09	2025-12-21 23:35:09
30	6	outbound	ai	text	Absolutely! For a formal quotation and corporate bulk orders, let me connect you with our team who can provide:\n\n• Customized package options\n• Corporate pricing\n• Invoice & receipt\n\nSomeone will get back to you shortly! 😊	\N	delivered	\N	2025-12-21 23:37:09	2025-12-21 23:37:09
31	7	inbound	customer	text	Can I order 2 boxes of macarons and 6 croissants for delivery tomorrow?	\N	delivered	\N	2025-12-21 23:31:09	2025-12-21 23:31:09
32	7	outbound	ai	text	Of course! 🥐\n\nLet me confirm your order:\n\n• 2x Assorted Macarons (6 pcs) - RM64\n• 6x Classic Butter Croissant - RM53.40\n\n💰 Subtotal: RM117.40\n🚚 Delivery fee: RM10 (within Kluang)\n💰 Total: RM127.40\n\nPlease share your delivery address and preferred time tomorrow!	\N	delivered	\N	2025-12-21 23:33:09	2025-12-21 23:33:09
33	7	inbound	customer	text	25 Jalan Melor, Taman Kluang Baru. Anytime before 12pm is fine	\N	delivered	\N	2025-12-21 23:35:09	2025-12-21 23:35:09
34	7	outbound	ai	text	✅ Order confirmed!\n\n🧁 Order ID: JQP-00002\n📦 Items:\n  • 2x Assorted Macarons (6 pcs)\n  • 6x Classic Butter Croissant\n💰 Total: RM127.40\n🚚 Delivery: Tomorrow before 12pm\n📍 25 Jalan Melor, Taman Kluang Baru\n\nPayment upon delivery (cash/e-wallet accepted).\n\nThank you for your order! 🎉	\N	delivered	\N	2025-12-21 23:37:09	2025-12-21 23:37:09
\.


--
-- TOC entry 3849 (class 0 OID 44148)
-- Dependencies: 217
-- Data for Name: migrations; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.migrations (id, migration, batch) FROM stdin;
1	0001_01_01_000000_create_users_table	1
2	0001_01_01_000001_create_cache_table	1
3	0001_01_01_000002_create_jobs_table	1
4	2024_01_01_000001_create_conversations_table	1
5	2024_01_01_000002_create_messages_table	1
6	2024_01_01_000003_create_merchant_settings_table	1
7	2024_01_01_000004_create_restaurant_settings_table	1
8	2024_01_01_000005_create_order_tracking_settings_table	1
9	2024_01_01_000006_create_tables_table	1
10	2024_01_01_000007_create_bookings_table	1
11	2024_01_01_000008_create_products_table	1
12	2024_01_01_000009_create_orders_table	1
13	2024_01_01_000010_create_order_items_table	1
14	2024_01_01_000011_create_documents_table	1
15	2024_01_01_000012_create_document_chunks_table	1
16	2024_01_01_000013_create_email_verifications_table	1
17	2024_12_15_000001_add_is_active_to_users_table	1
18	2024_12_16_000001_fix_document_chunks_embedding_type	1
19	2024_12_16_000002_add_tokens_count_to_document_chunks	1
20	2024_12_16_000004_add_end_time_to_bookings	1
21	2024_12_16_000005_add_created_by_to_bookings	1
22	2025_12_17_091519_add_email_on_escalation_to_merchant_settings_table	1
23	2025_12_17_104928_add_user_id_to_conversations_table	1
24	2025_12_17_172532_add_cloudinary_fields_to_documents_table	1
25	2025_12_17_173704_create_media_table	1
26	2025_12_17_173843_refactor_documents_to_use_media	1
27	2025_12_20_120000_add_mediable_to_media_table	1
\.


--
-- TOC entry 3880 (class 0 OID 44406)
-- Dependencies: 248
-- Data for Name: order_items; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.order_items (id, order_id, product_id, product_name, unit_price, quantity, subtotal, created_at, updated_at) FROM stdin;
1	1	12	Strawberry Shortcake 6"	110.00	1	110.00	2025-12-21 23:51:09	2025-12-21 23:51:09
2	2	13	Assorted Macarons (6 pcs)	32.00	2	64.00	2025-12-21 23:51:09	2025-12-21 23:51:09
3	2	9	Classic Butter Croissant	8.90	6	53.40	2025-12-21 23:51:09	2025-12-21 23:51:09
4	3	2	Chocolate Éclair	12.90	4	51.60	2025-12-21 23:51:09	2025-12-21 23:51:09
5	3	7	Financier	6.90	6	41.40	2025-12-21 23:51:09	2025-12-21 23:51:09
6	5	4	Tarte aux Fruits	15.90	2	31.80	2025-12-21 23:51:09	2025-12-21 23:51:09
7	5	1	Mille-Feuille	18.90	4	75.60	2025-12-21 23:51:09	2025-12-21 23:51:09
8	5	6	Canelé	8.90	8	71.20	2025-12-21 23:51:09	2025-12-21 23:51:09
9	6	4	Tarte aux Fruits	15.90	4	63.60	2025-12-21 23:51:09	2025-12-21 23:51:09
10	6	2	Chocolate Éclair	12.90	6	77.40	2025-12-21 23:51:09	2025-12-21 23:51:09
11	6	6	Canelé	8.90	10	89.00	2025-12-21 23:51:09	2025-12-21 23:51:09
12	6	7	Financier	6.90	8	55.20	2025-12-21 23:51:09	2025-12-21 23:51:09
\.


--
-- TOC entry 3870 (class 0 OID 44302)
-- Dependencies: 238
-- Data for Name: order_tracking_settings; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.order_tracking_settings (id, user_id, pickup_address, order_prefix, created_at, updated_at) FROM stdin;
1	3	173, Jalan Paya 3/1, Kampung Paya, 86000 Kluang, Johor, Malaysia	JQP	2025-12-21 23:51:09	2025-12-21 23:51:09
\.


--
-- TOC entry 3878 (class 0 OID 44378)
-- Dependencies: 246
-- Data for Name: orders; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.orders (id, user_id, conversation_id, code, customer_name, customer_phone, fulfillment_type, delivery_address, requested_datetime, total_amount, status, notes, created_at, updated_at) FROM stdin;
1	3	5	JQP-00001	Ahmad Rizal	60133334444	pickup	\N	2025-12-27 14:00:00	110.00	processing	Strawberry Shortcake 6" with "Happy Birthday Aishah". Deposit RM55 paid.	2025-12-21 23:51:09	2025-12-21 23:51:09
2	3	7	JQP-00002	Jenny Lim	60199887766	delivery	25 Jalan Melor, Taman Kluang Baru	2025-12-20 11:00:09	127.40	completed	Deliver before 12pm. COD.	2025-12-21 23:51:09	2025-12-21 23:51:09
3	3	\N	JQP-00003	Kevin Ong	60166677788	pickup	\N	2025-12-23 10:00:09	89.60	pending_payment	For office meeting	2025-12-21 23:51:09	2025-12-21 23:51:09
4	3	\N	JQP-00004	Sarah Tan	60177788899	delivery	88 Jalan Bunga, Kluang	2025-12-18 15:00:09	65.70	cancelled	Cancelled due to change of plans	2025-12-21 23:51:09	2025-12-21 23:51:09
5	3	\N	JQP-00005	Lisa Chen	60188899911	pickup	\N	2025-12-14 16:30:09	156.40	completed	Regular customer - birthday treats	2025-12-21 23:51:09	2025-12-21 23:51:09
6	3	\N	JQP-00006	Alex Yap	60199900022	delivery	15 Lorong Mawar, Simpang Renggam	2025-12-27 11:00:00	245.60	processing	Party order - call before delivery	2025-12-21 23:51:09	2025-12-21 23:51:09
\.


--
-- TOC entry 3852 (class 0 OID 44169)
-- Dependencies: 220
-- Data for Name: password_reset_tokens; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.password_reset_tokens (email, token, created_at) FROM stdin;
\.


--
-- TOC entry 3876 (class 0 OID 44362)
-- Dependencies: 244
-- Data for Name: products; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.products (id, user_id, name, description, price, sku, is_active, created_at, updated_at) FROM stdin;
1	3	Mille-Feuille	Classic Napoleon with crispy puff pastry layers and vanilla diplomat cream.	18.90	\N	t	2025-12-21 23:51:09	2025-12-21 23:51:09
2	3	Chocolate Éclair	Choux pastry filled with chocolate cream, topped with dark chocolate glaze.	12.90	\N	t	2025-12-21 23:51:09	2025-12-21 23:51:09
3	3	Coffee Éclair	Choux pastry filled with coffee cream, topped with coffee glaze.	12.90	\N	t	2025-12-21 23:51:09	2025-12-21 23:51:09
4	3	Tarte aux Fruits	Buttery tart shell with vanilla custard and fresh seasonal fruits.	15.90	\N	t	2025-12-21 23:51:09	2025-12-21 23:51:09
5	3	Tarte au Citron	Tangy lemon curd tart with torched Italian meringue.	13.90	\N	t	2025-12-21 23:51:09	2025-12-21 23:51:09
6	3	Canelé	Bordeaux specialty with rum and vanilla, caramelized crust.	8.90	\N	t	2025-12-21 23:51:09	2025-12-21 23:51:09
7	3	Financier	Traditional French almond tea cake with brown butter.	6.90	\N	t	2025-12-21 23:51:09	2025-12-21 23:51:09
8	3	Madeleines (3 pcs)	Classic shell-shaped French butter cakes.	9.90	\N	t	2025-12-21 23:51:09	2025-12-21 23:51:09
9	3	Classic Butter Croissant	Flaky, buttery croissant made with 48-hour laminated dough.	8.90	\N	t	2025-12-21 23:51:09	2025-12-21 23:51:09
10	3	Almond Croissant	Butter croissant filled with almond frangipane, topped with sliced almonds.	12.90	\N	t	2025-12-21 23:51:09	2025-12-21 23:51:09
11	3	Burnt Basque Cheesecake 6"	Creamy Basque-style cheesecake with caramelized top. Serves 6-8 pax.	85.00	\N	t	2025-12-21 23:51:09	2025-12-21 23:51:09
12	3	Strawberry Shortcake 6"	Light vanilla sponge with fresh strawberries and Chantilly cream. Serves 6-8 pax.	110.00	\N	t	2025-12-21 23:51:09	2025-12-21 23:51:09
13	3	Assorted Macarons (6 pcs)	Box of 6 French macarons in assorted flavours.	32.00	\N	t	2025-12-21 23:51:09	2025-12-21 23:51:09
\.


--
-- TOC entry 3868 (class 0 OID 44285)
-- Dependencies: 236
-- Data for Name: restaurant_settings; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.restaurant_settings (id, user_id, opening_time, closing_time, slot_duration_minutes, created_at, updated_at) FROM stdin;
1	2	11:00:00	22:00:00	120	2025-12-21 23:51:09	2025-12-21 23:51:09
\.


--
-- TOC entry 3853 (class 0 OID 44176)
-- Dependencies: 221
-- Data for Name: sessions; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.sessions (id, user_id, ip_address, user_agent, payload, last_activity) FROM stdin;
x2enSc9XxNPeE3cd4KgvBEn8rEvF3tyqUWJM7Su2	3	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/143.0.0.0 Safari/537.36	YTozOntzOjY6Il90b2tlbiI7czo0MDoiR1paMHdmSmM4cUZHdk1YdlNTTzdiUzJ0dFJOeWhjY3hncFpMenI5USI7czo2OiJfZmxhc2giO2E6Mjp7czozOiJvbGQiO2E6MDp7fXM6MzoibmV3IjthOjA6e319czo1MDoibG9naW5fd2ViXzU5YmEzNmFkZGMyYjJmOTQwMTU4MGYwMTRjN2Y1OGVhNGUzMDk4OWQiO2k6Mzt9	1766333366
\.


--
-- TOC entry 3872 (class 0 OID 44319)
-- Dependencies: 240
-- Data for Name: tables; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.tables (id, user_id, name, capacity, is_active, created_at, updated_at) FROM stdin;
1	2	Table A1	2	t	2025-12-21 23:51:09	2025-12-21 23:51:09
2	2	Table A2	2	t	2025-12-21 23:51:09	2025-12-21 23:51:09
3	2	Table B1	4	t	2025-12-21 23:51:09	2025-12-21 23:51:09
4	2	Table B2	4	t	2025-12-21 23:51:09	2025-12-21 23:51:09
5	2	Table B3	4	t	2025-12-21 23:51:09	2025-12-21 23:51:09
6	2	Table C1	6	t	2025-12-21 23:51:09	2025-12-21 23:51:09
7	2	Table C2	8	t	2025-12-21 23:51:09	2025-12-21 23:51:09
8	2	Table D1	10	t	2025-12-21 23:51:09	2025-12-21 23:51:09
\.


--
-- TOC entry 3851 (class 0 OID 44155)
-- Dependencies: 219
-- Data for Name: users; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.users (id, name, email, email_verified_at, password, role, business_type, email_verified, whatsapp_phone_number_id, whatsapp_access_token, remember_token, created_at, updated_at, is_active) FROM stdin;
1	Super Admin	admin@example.com	2025-12-21 23:51:08	$2y$12$m8xu5HIf20ntro23wrqnieH2vWR29gjWwMOa4MOwEXV909NnU9g5S	admin	restaurant	t	\N	\N	\N	2025-12-21 23:51:08	2025-12-21 23:51:08	t
2	Bonne Bouche Café	restaurant@example.com	2025-12-21 23:51:09	$2y$12$gBKAT.of3vwb7qyyYPsOzuGwjJ/17I24MUEhZ3SxcSgVib2Y4ddga	merchant	restaurant	t	eyJpdiI6IkorcUNmODkrWGZyVUkyOXFKRlJ4d2c9PSIsInZhbHVlIjoibmJQQkNab29pMFFTM093dVgvUXZUQT09IiwibWFjIjoiMjc3MjE3NDQ4MmVjOTUxMWQzYjM0MjBmNzhmYWY2YjU5NjIyZmIwNTg1OWQ3YTkzN2M0NGE1MTc2ZTBjMDBlYiIsInRhZyI6IiJ9	eyJpdiI6ImlXRW9OOUtNNStURDJWMmJxVWFnTEE9PSIsInZhbHVlIjoiTTVibWJ0S1F0Z09mM1RaSVEzSWhrL0pxY3lRUDZpTTc4d1dOMEN3VVhlbWxsMWIzcmxrY01FcFFvL3daUjhEV21DSDIxMlJtTHZHQmZwaXMrMmdRYnR5WlkzbUhlYWdUVVg0RWNyWGhDWEZRcWZBS2lQTVoxbFlycmg5YzEwc2p4Z1R4djlOWTZRYW1WZkFmKzF4UGdGN1JURzY4QW55Qlg5Y1NOUXNST293M0dOejg5OXNVMVYveUNzajRNd2ZOZCtlSW9BNHNadlMxQVQ3VFFydDlic0tIMjJENzlPZ2ZKclAzUW9iZnU3UHNHbUh5MmdzemZBU240ZGNSck95L0NXWG9HUVkySEw0QmtXTGhTRzdDZHc9PSIsIm1hYyI6ImExN2Q1MGQxYmUwNDdmYTc5M2RmMmI1ODk2OTRjMDViYzY0YmIxMWM0OGY1ODU0MTgyZmZkMzQwNDdjNWQ4ZDYiLCJ0YWciOiIifQ==	\N	2025-12-21 23:51:09	2025-12-21 23:51:09	t
3	J.Q Patisserie	shop@example.com	2025-12-21 23:51:09	$2y$12$Bt/4xRj6Lwo3lDyaKXggnemdW9t7P.s/Qzh8/pXkDpK2Mnq9VwQq.	merchant	order_tracking	t	eyJpdiI6IkF3dlViSkV2VlF6R1lMdFd2NWhwTXc9PSIsInZhbHVlIjoiTlg4OHlIMm9YaTNnUTFleG8rYlVYSkt0K3R6UWRzS0ZqbGdBb25mWXFmST0iLCJtYWMiOiJmZDMyMDJkYzEyMDVkNzRkYjAxMGUxMzczODAxZDFkMzlmMWZiNjg3OWIxMzMyOWU0ZjFmYzJiNGMyODhjZjAwIiwidGFnIjoiIn0=	eyJpdiI6IjhidE44dmFPOFNlUFh2bUoxak8yeFE9PSIsInZhbHVlIjoiRVVsNTNtbEpFdndleWE4b0UwUDlMaDBLSnM2TVc5azR0LzdmdkgwSlY1N1gwcFdDT2ZJWnp0WFBjMTliUjBXQVhhNHpEa3VJaUFwa2ZMTWxlcnNaelpxM0pRQWRsYS8zeW1yd2FieldNQ1B6dzV6NVd2UEkzaFVHWm84TUhOaE9wREVHdm5sa2lPeERMeG01Z2F2VnJOL3dMUkRPMk9hRmRVaWpiaEJoUW1UUnNPaFpUTDVRc0Jzenh2UmY3K3RGN0tuV3RENnFlS3owRFlqSGd4VG9hdVVkNUdMTzViSjFvMFQ3UzFoMk1TNCtVaWRqN01CUWw5RnNBaS96WUpBQTdwUVV2WEVLdmpWYUZSVUdQTXBGQnc9PSIsIm1hYyI6IjU4OTQ5MDEwM2ExODI4YmIxYTcwNzNhODcxN2Y5NzFkYmFjN2IyNWYzNjY3YzZjZWIzYjRhZGI3NmYyNzY5YzIiLCJ0YWciOiIifQ==	\N	2025-12-21 23:51:09	2025-12-21 23:51:09	t
\.


--
-- TOC entry 3913 (class 0 OID 0)
-- Dependencies: 241
-- Name: bookings_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.bookings_id_seq', 6, true);


--
-- TOC entry 3914 (class 0 OID 0)
-- Dependencies: 229
-- Name: conversations_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.conversations_id_seq', 7, true);


--
-- TOC entry 3915 (class 0 OID 0)
-- Dependencies: 251
-- Name: document_chunks_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.document_chunks_id_seq', 16, true);


--
-- TOC entry 3916 (class 0 OID 0)
-- Dependencies: 249
-- Name: documents_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.documents_id_seq', 7, true);


--
-- TOC entry 3917 (class 0 OID 0)
-- Dependencies: 253
-- Name: email_verifications_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.email_verifications_id_seq', 1, false);


--
-- TOC entry 3918 (class 0 OID 0)
-- Dependencies: 227
-- Name: failed_jobs_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.failed_jobs_id_seq', 1, false);


--
-- TOC entry 3919 (class 0 OID 0)
-- Dependencies: 224
-- Name: jobs_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.jobs_id_seq', 1, false);


--
-- TOC entry 3920 (class 0 OID 0)
-- Dependencies: 255
-- Name: media_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.media_id_seq', 23, true);


--
-- TOC entry 3921 (class 0 OID 0)
-- Dependencies: 233
-- Name: merchant_settings_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.merchant_settings_id_seq', 2, true);


--
-- TOC entry 3922 (class 0 OID 0)
-- Dependencies: 231
-- Name: messages_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.messages_id_seq', 34, true);


--
-- TOC entry 3923 (class 0 OID 0)
-- Dependencies: 216
-- Name: migrations_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.migrations_id_seq', 27, true);


--
-- TOC entry 3924 (class 0 OID 0)
-- Dependencies: 247
-- Name: order_items_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.order_items_id_seq', 12, true);


--
-- TOC entry 3925 (class 0 OID 0)
-- Dependencies: 237
-- Name: order_tracking_settings_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.order_tracking_settings_id_seq', 1, true);


--
-- TOC entry 3926 (class 0 OID 0)
-- Dependencies: 245
-- Name: orders_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.orders_id_seq', 6, true);


--
-- TOC entry 3927 (class 0 OID 0)
-- Dependencies: 243
-- Name: products_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.products_id_seq', 13, true);


--
-- TOC entry 3928 (class 0 OID 0)
-- Dependencies: 235
-- Name: restaurant_settings_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.restaurant_settings_id_seq', 1, true);


--
-- TOC entry 3929 (class 0 OID 0)
-- Dependencies: 239
-- Name: tables_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.tables_id_seq', 8, true);


--
-- TOC entry 3930 (class 0 OID 0)
-- Dependencies: 218
-- Name: users_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.users_id_seq', 3, true);


--
-- TOC entry 3658 (class 2606 OID 44342)
-- Name: bookings bookings_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.bookings
    ADD CONSTRAINT bookings_pkey PRIMARY KEY (id);


--
-- TOC entry 3620 (class 2606 OID 44198)
-- Name: cache_locks cache_locks_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.cache_locks
    ADD CONSTRAINT cache_locks_pkey PRIMARY KEY (key);


--
-- TOC entry 3618 (class 2606 OID 44191)
-- Name: cache cache_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.cache
    ADD CONSTRAINT cache_pkey PRIMARY KEY (key);


--
-- TOC entry 3631 (class 2606 OID 44241)
-- Name: conversations conversations_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.conversations
    ADD CONSTRAINT conversations_pkey PRIMARY KEY (id);


--
-- TOC entry 3636 (class 2606 OID 44246)
-- Name: conversations conversations_whatsapp_id_unique; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.conversations
    ADD CONSTRAINT conversations_whatsapp_id_unique UNIQUE (whatsapp_id);


--
-- TOC entry 3677 (class 2606 OID 44448)
-- Name: document_chunks document_chunks_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.document_chunks
    ADD CONSTRAINT document_chunks_pkey PRIMARY KEY (id);


--
-- TOC entry 3673 (class 2606 OID 44433)
-- Name: documents documents_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.documents
    ADD CONSTRAINT documents_pkey PRIMARY KEY (id);


--
-- TOC entry 3680 (class 2606 OID 44464)
-- Name: email_verifications email_verifications_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.email_verifications
    ADD CONSTRAINT email_verifications_pkey PRIMARY KEY (id);


--
-- TOC entry 3627 (class 2606 OID 44225)
-- Name: failed_jobs failed_jobs_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.failed_jobs
    ADD CONSTRAINT failed_jobs_pkey PRIMARY KEY (id);


--
-- TOC entry 3629 (class 2606 OID 44227)
-- Name: failed_jobs failed_jobs_uuid_unique; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.failed_jobs
    ADD CONSTRAINT failed_jobs_uuid_unique UNIQUE (uuid);


--
-- TOC entry 3625 (class 2606 OID 44215)
-- Name: job_batches job_batches_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.job_batches
    ADD CONSTRAINT job_batches_pkey PRIMARY KEY (id);


--
-- TOC entry 3622 (class 2606 OID 44207)
-- Name: jobs jobs_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.jobs
    ADD CONSTRAINT jobs_pkey PRIMARY KEY (id);


--
-- TOC entry 3685 (class 2606 OID 44485)
-- Name: media media_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.media
    ADD CONSTRAINT media_pkey PRIMARY KEY (id);


--
-- TOC entry 3642 (class 2606 OID 44276)
-- Name: merchant_settings merchant_settings_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.merchant_settings
    ADD CONSTRAINT merchant_settings_pkey PRIMARY KEY (id);


--
-- TOC entry 3644 (class 2606 OID 44283)
-- Name: merchant_settings merchant_settings_user_id_unique; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.merchant_settings
    ADD CONSTRAINT merchant_settings_user_id_unique UNIQUE (user_id);


--
-- TOC entry 3639 (class 2606 OID 44259)
-- Name: messages messages_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.messages
    ADD CONSTRAINT messages_pkey PRIMARY KEY (id);


--
-- TOC entry 3606 (class 2606 OID 44153)
-- Name: migrations migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.migrations
    ADD CONSTRAINT migrations_pkey PRIMARY KEY (id);


--
-- TOC entry 3671 (class 2606 OID 44411)
-- Name: order_items order_items_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.order_items
    ADD CONSTRAINT order_items_pkey PRIMARY KEY (id);


--
-- TOC entry 3650 (class 2606 OID 44310)
-- Name: order_tracking_settings order_tracking_settings_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.order_tracking_settings
    ADD CONSTRAINT order_tracking_settings_pkey PRIMARY KEY (id);


--
-- TOC entry 3652 (class 2606 OID 44317)
-- Name: order_tracking_settings order_tracking_settings_user_id_unique; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.order_tracking_settings
    ADD CONSTRAINT order_tracking_settings_user_id_unique UNIQUE (user_id);


--
-- TOC entry 3665 (class 2606 OID 44390)
-- Name: orders orders_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.orders
    ADD CONSTRAINT orders_pkey PRIMARY KEY (id);


--
-- TOC entry 3667 (class 2606 OID 44404)
-- Name: orders orders_user_id_code_unique; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.orders
    ADD CONSTRAINT orders_user_id_code_unique UNIQUE (user_id, code);


--
-- TOC entry 3612 (class 2606 OID 44175)
-- Name: password_reset_tokens password_reset_tokens_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.password_reset_tokens
    ADD CONSTRAINT password_reset_tokens_pkey PRIMARY KEY (email);


--
-- TOC entry 3662 (class 2606 OID 44370)
-- Name: products products_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.products
    ADD CONSTRAINT products_pkey PRIMARY KEY (id);


--
-- TOC entry 3646 (class 2606 OID 44293)
-- Name: restaurant_settings restaurant_settings_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.restaurant_settings
    ADD CONSTRAINT restaurant_settings_pkey PRIMARY KEY (id);


--
-- TOC entry 3648 (class 2606 OID 44300)
-- Name: restaurant_settings restaurant_settings_user_id_unique; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.restaurant_settings
    ADD CONSTRAINT restaurant_settings_user_id_unique UNIQUE (user_id);


--
-- TOC entry 3615 (class 2606 OID 44182)
-- Name: sessions sessions_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.sessions
    ADD CONSTRAINT sessions_pkey PRIMARY KEY (id);


--
-- TOC entry 3654 (class 2606 OID 44325)
-- Name: tables tables_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tables
    ADD CONSTRAINT tables_pkey PRIMARY KEY (id);


--
-- TOC entry 3608 (class 2606 OID 44168)
-- Name: users users_email_unique; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_email_unique UNIQUE (email);


--
-- TOC entry 3610 (class 2606 OID 44166)
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- TOC entry 3656 (class 1259 OID 44360)
-- Name: bookings_customer_phone_index; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX bookings_customer_phone_index ON public.bookings USING btree (customer_phone);


--
-- TOC entry 3659 (class 1259 OID 44358)
-- Name: bookings_user_id_booking_date_index; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX bookings_user_id_booking_date_index ON public.bookings USING btree (user_id, booking_date);


--
-- TOC entry 3660 (class 1259 OID 44359)
-- Name: bookings_user_id_status_index; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX bookings_user_id_status_index ON public.bookings USING btree (user_id, status);


--
-- TOC entry 3632 (class 1259 OID 44244)
-- Name: conversations_user_id_index; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX conversations_user_id_index ON public.conversations USING btree (user_id);


--
-- TOC entry 3633 (class 1259 OID 44243)
-- Name: conversations_user_id_needs_reply_index; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX conversations_user_id_needs_reply_index ON public.conversations USING btree (user_id, needs_reply);


--
-- TOC entry 3634 (class 1259 OID 44242)
-- Name: conversations_user_id_status_index; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX conversations_user_id_status_index ON public.conversations USING btree (user_id, status);


--
-- TOC entry 3675 (class 1259 OID 44454)
-- Name: document_chunks_document_id_index; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX document_chunks_document_id_index ON public.document_chunks USING btree (document_id);


--
-- TOC entry 3674 (class 1259 OID 44439)
-- Name: documents_user_id_index; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX documents_user_id_index ON public.documents USING btree (user_id);


--
-- TOC entry 3678 (class 1259 OID 44465)
-- Name: email_verifications_email_index; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX email_verifications_email_index ON public.email_verifications USING btree (email);


--
-- TOC entry 3623 (class 1259 OID 44208)
-- Name: jobs_queue_index; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX jobs_queue_index ON public.jobs USING btree (queue);


--
-- TOC entry 3681 (class 1259 OID 44492)
-- Name: media_disk_index; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX media_disk_index ON public.media USING btree (disk);


--
-- TOC entry 3682 (class 1259 OID 44493)
-- Name: media_file_type_index; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX media_file_type_index ON public.media USING btree (file_type);


--
-- TOC entry 3683 (class 1259 OID 44499)
-- Name: media_mediable_type_mediable_id_index; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX media_mediable_type_mediable_id_index ON public.media USING btree (mediable_type, mediable_id);


--
-- TOC entry 3686 (class 1259 OID 44491)
-- Name: media_user_id_index; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX media_user_id_index ON public.media USING btree (user_id);


--
-- TOC entry 3637 (class 1259 OID 44265)
-- Name: messages_conversation_id_created_at_index; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX messages_conversation_id_created_at_index ON public.messages USING btree (conversation_id, created_at);


--
-- TOC entry 3640 (class 1259 OID 44266)
-- Name: messages_whatsapp_message_id_index; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX messages_whatsapp_message_id_index ON public.messages USING btree (whatsapp_message_id);


--
-- TOC entry 3668 (class 1259 OID 44402)
-- Name: orders_user_id_created_at_index; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX orders_user_id_created_at_index ON public.orders USING btree (user_id, created_at);


--
-- TOC entry 3669 (class 1259 OID 44401)
-- Name: orders_user_id_status_index; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX orders_user_id_status_index ON public.orders USING btree (user_id, status);


--
-- TOC entry 3663 (class 1259 OID 44376)
-- Name: products_user_id_is_active_index; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX products_user_id_is_active_index ON public.products USING btree (user_id, is_active);


--
-- TOC entry 3613 (class 1259 OID 44184)
-- Name: sessions_last_activity_index; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX sessions_last_activity_index ON public.sessions USING btree (last_activity);


--
-- TOC entry 3616 (class 1259 OID 44183)
-- Name: sessions_user_id_index; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX sessions_user_id_index ON public.sessions USING btree (user_id);


--
-- TOC entry 3655 (class 1259 OID 44331)
-- Name: tables_user_id_is_active_index; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX tables_user_id_is_active_index ON public.tables USING btree (user_id, is_active);


--
-- TOC entry 3693 (class 2606 OID 44348)
-- Name: bookings bookings_conversation_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.bookings
    ADD CONSTRAINT bookings_conversation_id_foreign FOREIGN KEY (conversation_id) REFERENCES public.conversations(id) ON DELETE SET NULL;


--
-- TOC entry 3694 (class 2606 OID 44353)
-- Name: bookings bookings_table_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.bookings
    ADD CONSTRAINT bookings_table_id_foreign FOREIGN KEY (table_id) REFERENCES public.tables(id) ON DELETE SET NULL;


--
-- TOC entry 3695 (class 2606 OID 44343)
-- Name: bookings bookings_user_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.bookings
    ADD CONSTRAINT bookings_user_id_foreign FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- TOC entry 3687 (class 2606 OID 44471)
-- Name: conversations conversations_user_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.conversations
    ADD CONSTRAINT conversations_user_id_foreign FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- TOC entry 3703 (class 2606 OID 44449)
-- Name: document_chunks document_chunks_document_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.document_chunks
    ADD CONSTRAINT document_chunks_document_id_foreign FOREIGN KEY (document_id) REFERENCES public.documents(id) ON DELETE CASCADE;


--
-- TOC entry 3701 (class 2606 OID 44494)
-- Name: documents documents_media_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.documents
    ADD CONSTRAINT documents_media_id_foreign FOREIGN KEY (media_id) REFERENCES public.media(id) ON DELETE SET NULL;


--
-- TOC entry 3702 (class 2606 OID 44434)
-- Name: documents documents_user_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.documents
    ADD CONSTRAINT documents_user_id_foreign FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- TOC entry 3704 (class 2606 OID 44486)
-- Name: media media_user_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.media
    ADD CONSTRAINT media_user_id_foreign FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- TOC entry 3689 (class 2606 OID 44277)
-- Name: merchant_settings merchant_settings_user_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.merchant_settings
    ADD CONSTRAINT merchant_settings_user_id_foreign FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- TOC entry 3688 (class 2606 OID 44260)
-- Name: messages messages_conversation_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.messages
    ADD CONSTRAINT messages_conversation_id_foreign FOREIGN KEY (conversation_id) REFERENCES public.conversations(id) ON DELETE CASCADE;


--
-- TOC entry 3699 (class 2606 OID 44412)
-- Name: order_items order_items_order_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.order_items
    ADD CONSTRAINT order_items_order_id_foreign FOREIGN KEY (order_id) REFERENCES public.orders(id) ON DELETE CASCADE;


--
-- TOC entry 3700 (class 2606 OID 44417)
-- Name: order_items order_items_product_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.order_items
    ADD CONSTRAINT order_items_product_id_foreign FOREIGN KEY (product_id) REFERENCES public.products(id) ON DELETE SET NULL;


--
-- TOC entry 3691 (class 2606 OID 44311)
-- Name: order_tracking_settings order_tracking_settings_user_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.order_tracking_settings
    ADD CONSTRAINT order_tracking_settings_user_id_foreign FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- TOC entry 3697 (class 2606 OID 44396)
-- Name: orders orders_conversation_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.orders
    ADD CONSTRAINT orders_conversation_id_foreign FOREIGN KEY (conversation_id) REFERENCES public.conversations(id) ON DELETE SET NULL;


--
-- TOC entry 3698 (class 2606 OID 44391)
-- Name: orders orders_user_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.orders
    ADD CONSTRAINT orders_user_id_foreign FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- TOC entry 3696 (class 2606 OID 44371)
-- Name: products products_user_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.products
    ADD CONSTRAINT products_user_id_foreign FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- TOC entry 3690 (class 2606 OID 44294)
-- Name: restaurant_settings restaurant_settings_user_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.restaurant_settings
    ADD CONSTRAINT restaurant_settings_user_id_foreign FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- TOC entry 3692 (class 2606 OID 44326)
-- Name: tables tables_user_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tables
    ADD CONSTRAINT tables_user_id_foreign FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


-- Completed on 2025-12-22 00:09:27

--
-- PostgreSQL database dump complete
--

\unrestrict S2NUqlvEG73rr6VcWhCACcLfjFffGWt0ffmoPw4vcgtRJWc9FHQdKu7Iduaihdk


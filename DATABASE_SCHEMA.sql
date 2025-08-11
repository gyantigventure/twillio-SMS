-- 10DLC SMS Platform Database Schema
-- PostgreSQL 15+ Compatible
-- Version: 1.0
-- Last Updated: December 2024

-- =============================================================================
-- EXTENSIONS AND CONFIGURATION
-- =============================================================================

-- Enable necessary extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";
CREATE EXTENSION IF NOT EXISTS "btree_gin";

-- =============================================================================
-- CUSTOM TYPES AND ENUMS
-- =============================================================================

-- User and organization related enums
CREATE TYPE user_role AS ENUM ('super_admin', 'admin', 'user');
CREATE TYPE organization_type AS ENUM ('corporation', 'llc', 'partnership', 'sole_proprietorship', 'non_profit', 'government');
CREATE TYPE organization_role AS ENUM ('owner', 'admin', 'manager', 'member');
CREATE TYPE verification_status AS ENUM ('pending', 'in_progress', 'verified', 'rejected');

-- Brand and campaign related enums
CREATE TYPE brand_entity_type AS ENUM ('private_profit', 'public_profit', 'non_profit', 'government');
CREATE TYPE identity_status AS ENUM ('unverified', 'pending', 'verified', 'failed');
CREATE TYPE brand_status AS ENUM ('draft', 'pending', 'approved', 'suspended', 'rejected');
CREATE TYPE brand_relationship AS ENUM ('basic_t', 'standard_t', 'premium_t');

-- Campaign use cases as defined by TCR
CREATE TYPE campaign_use_case AS ENUM (
    'marketing', 'mixed', 'account_notification', 'customer_care', 
    'delivery_notification', 'fraud_alert', 'higher_education',
    'low_volume', 'emergency', 'charity', 'political',
    'public_service_announcement', 'social_media'
);
CREATE TYPE campaign_status AS ENUM ('draft', 'pending', 'approved', 'suspended', 'rejected');

-- Message related enums
CREATE TYPE message_direction AS ENUM ('inbound', 'outbound');
CREATE TYPE message_status AS ENUM (
    'queued', 'sending', 'sent', 'delivered', 'undelivered', 
    'failed', 'received', 'read'
);

-- Phone number types and statuses
CREATE TYPE phone_number_type AS ENUM ('local', 'toll_free', '10dlc');
CREATE TYPE phone_number_status AS ENUM ('active', 'inactive', 'pending', 'suspended');

-- Compliance related enums
CREATE TYPE consent_type AS ENUM ('sms_marketing', 'sms_transactional', 'sms_service', 'email_marketing');
CREATE TYPE consent_status AS ENUM ('granted', 'withdrawn', 'expired');
CREATE TYPE audit_action AS ENUM (
    'create', 'read', 'update', 'delete', 'login', 'logout',
    'export', 'import', 'send_message', 'approve', 'reject'
);
CREATE TYPE violation_type AS ENUM (
    'unauthorized_message', 'missing_consent', 'content_violation',
    'rate_limit_exceeded', 'invalid_opt_out', 'data_breach'
);
CREATE TYPE violation_severity AS ENUM ('low', 'medium', 'high', 'critical');
CREATE TYPE violation_status AS ENUM ('open', 'investigating', 'resolved', 'closed');

-- =============================================================================
-- CORE USER AND ORGANIZATION TABLES
-- =============================================================================

-- Users table - Core user authentication and profile information
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    phone_number VARCHAR(20),
    role user_role NOT NULL DEFAULT 'user',
    email_verified BOOLEAN DEFAULT FALSE,
    email_verification_token VARCHAR(255),
    email_verification_expires TIMESTAMP,
    phone_verified BOOLEAN DEFAULT FALSE,
    phone_verification_token VARCHAR(10),
    phone_verification_expires TIMESTAMP,
    mfa_enabled BOOLEAN DEFAULT FALSE,
    mfa_secret VARCHAR(255),
    mfa_backup_codes TEXT[],
    password_reset_token VARCHAR(255),
    password_reset_expires TIMESTAMP,
    last_login_at TIMESTAMP,
    login_attempts INTEGER DEFAULT 0,
    locked_until TIMESTAMP,
    timezone VARCHAR(50) DEFAULT 'UTC',
    locale VARCHAR(10) DEFAULT 'en',
    avatar_url VARCHAR(500),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP
);

-- Organizations table - Business entities that use the platform
CREATE TABLE organizations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    legal_name VARCHAR(255) NOT NULL,
    display_name VARCHAR(255),
    ein VARCHAR(20) UNIQUE,
    business_type organization_type NOT NULL,
    industry VARCHAR(100),
    website_url VARCHAR(500),
    phone_number VARCHAR(20),
    email VARCHAR(255),
    address_line1 VARCHAR(255),
    address_line2 VARCHAR(255),
    city VARCHAR(100),
    state VARCHAR(50),
    postal_code VARCHAR(20),
    country VARCHAR(50) DEFAULT 'US',
    verification_status verification_status DEFAULT 'pending',
    verification_notes TEXT,
    verified_at TIMESTAMP,
    verified_by UUID REFERENCES users(id),
    billing_address_line1 VARCHAR(255),
    billing_address_line2 VARCHAR(255),
    billing_city VARCHAR(100),
    billing_state VARCHAR(50),
    billing_postal_code VARCHAR(20),
    billing_country VARCHAR(50) DEFAULT 'US',
    tax_id VARCHAR(50),
    annual_revenue BIGINT,
    employee_count INTEGER,
    founded_year INTEGER,
    logo_url VARCHAR(500),
    description TEXT,
    settings JSONB DEFAULT '{}',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP
);

-- User organization relationships - Many-to-many with roles
CREATE TABLE user_organizations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    role organization_role NOT NULL DEFAULT 'member',
    permissions JSONB DEFAULT '{}',
    invited_by UUID REFERENCES users(id),
    invited_at TIMESTAMP,
    invitation_token VARCHAR(255),
    invitation_expires TIMESTAMP,
    joined_at TIMESTAMP,
    status VARCHAR(20) DEFAULT 'active',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(user_id, organization_id)
);

-- =============================================================================
-- BRAND AND CAMPAIGN MANAGEMENT TABLES
-- =============================================================================

-- Brands table - TCR Brand Registration entities
CREATE TABLE brands (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    tcr_brand_id VARCHAR(100) UNIQUE,
    brand_name VARCHAR(255) NOT NULL,
    entity_type brand_entity_type NOT NULL,
    industry VARCHAR(100) NOT NULL,
    website VARCHAR(500) NOT NULL,
    stock_symbol VARCHAR(10),
    stock_exchange VARCHAR(50),
    business_registration_number VARCHAR(100),
    tax_id VARCHAR(50),
    ein VARCHAR(20),
    phone_number VARCHAR(20),
    email VARCHAR(255),
    
    -- Address stored as JSONB for flexibility
    address JSONB NOT NULL, -- {line1, line2, city, state, postal_code, country}
    
    -- TCR specific fields
    identity_status identity_status DEFAULT 'unverified',
    registration_status brand_status DEFAULT 'draft',
    trust_score INTEGER,
    compliance_score INTEGER,
    brand_relationship brand_relationship DEFAULT 'basic_t',
    
    -- Additional brand information
    company_description TEXT,
    customer_support_phone VARCHAR(20),
    customer_support_email VARCHAR(255),
    help_center_url VARCHAR(500),
    terms_and_conditions_url VARCHAR(500),
    privacy_policy_url VARCHAR(500),
    
    -- Social media and verification
    social_media_urls JSONB DEFAULT '{}', -- {facebook, twitter, linkedin, etc}
    verification_documents JSONB DEFAULT '[]', -- Array of document references
    
    -- Status and timestamps
    mock BOOLEAN DEFAULT FALSE,
    submitted_at TIMESTAMP,
    approved_at TIMESTAMP,
    rejection_reason TEXT,
    next_review_date TIMESTAMP,
    
    created_by UUID NOT NULL REFERENCES users(id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP
);

-- Campaigns table - TCR Campaign Registration entities
CREATE TABLE campaigns (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    brand_id UUID NOT NULL REFERENCES brands(id) ON DELETE CASCADE,
    tcr_campaign_id VARCHAR(100) UNIQUE,
    campaign_name VARCHAR(255) NOT NULL,
    use_case campaign_use_case NOT NULL,
    sub_use_cases TEXT[], -- Additional sub-classifications
    description TEXT NOT NULL,
    
    -- Sample messages (required by TCR)
    sample_message1 TEXT NOT NULL,
    sample_message2 TEXT,
    sample_message3 TEXT,
    sample_message4 TEXT,
    sample_message5 TEXT,
    
    -- Message flow and automation
    message_flow TEXT,
    auto_responder_enabled BOOLEAN DEFAULT FALSE,
    
    -- Keyword management
    help_keywords TEXT[] DEFAULT ARRAY['HELP'],
    help_message TEXT DEFAULT 'For help, contact customer support.',
    stop_keywords TEXT[] DEFAULT ARRAY['STOP', 'STOPALL', 'UNSUBSCRIBE', 'CANCEL', 'END', 'QUIT'],
    opt_in_keywords TEXT[],
    opt_in_message TEXT,
    opt_out_message TEXT DEFAULT 'You have been unsubscribed. Reply START to resubscribe.',
    
    -- Campaign characteristics (for TCR)
    affiliate_marketing BOOLEAN DEFAULT FALSE,
    number_pool BOOLEAN DEFAULT FALSE,
    direct_lending BOOLEAN DEFAULT FALSE,
    subscriber_optin BOOLEAN DEFAULT TRUE,
    subscriber_optout BOOLEAN DEFAULT TRUE,
    subscriber_help BOOLEAN DEFAULT TRUE,
    age_gated BOOLEAN DEFAULT FALSE,
    
    -- Monthly message volume estimates
    estimated_monthly_volume INTEGER,
    peak_daily_volume INTEGER,
    peak_hourly_volume INTEGER,
    
    -- Campaign settings
    rate_limit_per_minute INTEGER DEFAULT 10,
    rate_limit_per_hour INTEGER DEFAULT 100,
    rate_limit_per_day INTEGER DEFAULT 1000,
    time_zone VARCHAR(50) DEFAULT 'UTC',
    send_window_start TIME DEFAULT '08:00:00',
    send_window_end TIME DEFAULT '21:00:00',
    
    -- Status and approval
    registration_status campaign_status DEFAULT 'draft',
    mock BOOLEAN DEFAULT FALSE,
    submitted_at TIMESTAMP,
    approved_at TIMESTAMP,
    rejection_reason TEXT,
    
    created_by UUID NOT NULL REFERENCES users(id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP
);

-- =============================================================================
-- PHONE NUMBER MANAGEMENT
-- =============================================================================

-- Phone numbers table - Manage phone numbers and their assignments
CREATE TABLE phone_numbers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    phone_number VARCHAR(20) NOT NULL UNIQUE,
    friendly_name VARCHAR(100),
    phone_number_sid VARCHAR(100) UNIQUE, -- Twilio SID
    phone_number_type phone_number_type NOT NULL,
    status phone_number_status DEFAULT 'pending',
    
    -- Assignment and capabilities
    assigned_to_campaign_id UUID REFERENCES campaigns(id),
    sms_enabled BOOLEAN DEFAULT TRUE,
    voice_enabled BOOLEAN DEFAULT FALSE,
    mms_enabled BOOLEAN DEFAULT FALSE,
    
    -- Carrier and routing information
    carrier_name VARCHAR(100),
    carrier_type VARCHAR(50),
    region VARCHAR(50),
    country_code VARCHAR(10) DEFAULT '+1',
    
    -- Monthly costs and limits
    monthly_cost DECIMAL(10,4),
    setup_cost DECIMAL(10,4),
    per_message_cost DECIMAL(10,4),
    monthly_message_limit INTEGER,
    
    -- Purchase and assignment dates
    purchased_at TIMESTAMP,
    assigned_at TIMESTAMP,
    released_at TIMESTAMP,
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- =============================================================================
-- CONTACT MANAGEMENT TABLES
-- =============================================================================

-- Contact lists table - Organize contacts into lists
CREATE TABLE contact_lists (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    tags TEXT[],
    total_contacts INTEGER DEFAULT 0,
    active_contacts INTEGER DEFAULT 0,
    opted_in_contacts INTEGER DEFAULT 0,
    
    -- List settings
    double_opt_in_required BOOLEAN DEFAULT FALSE,
    welcome_message TEXT,
    unsubscribe_message TEXT,
    
    -- Custom fields definition
    custom_fields JSONB DEFAULT '{}', -- {field_name: {type, required, options}}
    
    created_by UUID NOT NULL REFERENCES users(id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP
);

-- Contacts table - Individual contact records
CREATE TABLE contacts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    phone_number VARCHAR(20) NOT NULL,
    email VARCHAR(255),
    first_name VARCHAR(100),
    last_name VARCHAR(100),
    
    -- Custom fields data
    custom_fields JSONB DEFAULT '{}',
    
    -- Consent and preferences
    opted_in BOOLEAN DEFAULT FALSE,
    opted_in_at TIMESTAMP,
    opted_in_source VARCHAR(100), -- 'web_form', 'api', 'import', 'sms'
    opted_in_ip INET,
    opted_in_user_agent TEXT,
    double_opt_in_confirmed BOOLEAN DEFAULT FALSE,
    double_opt_in_confirmed_at TIMESTAMP,
    
    opted_out BOOLEAN DEFAULT FALSE,
    opted_out_at TIMESTAMP,
    opted_out_source VARCHAR(100),
    opt_out_reason VARCHAR(255),
    
    -- Suppression and blocking
    suppressed BOOLEAN DEFAULT FALSE,
    suppressed_reason VARCHAR(255),
    suppressed_at TIMESTAMP,
    suppressed_by UUID REFERENCES users(id),
    
    -- Delivery tracking
    bounce_count INTEGER DEFAULT 0,
    last_bounce_at TIMESTAMP,
    complaint_count INTEGER DEFAULT 0,
    last_complaint_at TIMESTAMP,
    
    -- Engagement metrics
    total_messages_sent INTEGER DEFAULT 0,
    total_messages_delivered INTEGER DEFAULT 0,
    total_messages_failed INTEGER DEFAULT 0,
    last_message_sent_at TIMESTAMP,
    last_message_delivered_at TIMESTAMP,
    last_response_at TIMESTAMP,
    
    -- Location and timezone
    timezone VARCHAR(50),
    country VARCHAR(50),
    region VARCHAR(100),
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP,
    
    UNIQUE(organization_id, phone_number)
);

-- Contact list memberships - Many-to-many relationship
CREATE TABLE contact_list_memberships (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    contact_list_id UUID NOT NULL REFERENCES contact_lists(id) ON DELETE CASCADE,
    contact_id UUID NOT NULL REFERENCES contacts(id) ON DELETE CASCADE,
    status VARCHAR(20) DEFAULT 'active', -- 'active', 'unsubscribed', 'bounced'
    added_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    added_by UUID REFERENCES users(id),
    removed_at TIMESTAMP,
    removed_by UUID REFERENCES users(id),
    UNIQUE(contact_list_id, contact_id)
);

-- =============================================================================
-- MESSAGE MANAGEMENT TABLES
-- =============================================================================

-- Messages table - All sent and received messages
CREATE TABLE messages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    campaign_id UUID REFERENCES campaigns(id),
    contact_id UUID REFERENCES contacts(id),
    phone_number_id UUID REFERENCES phone_numbers(id),
    
    -- Twilio integration
    message_sid VARCHAR(100) UNIQUE,
    account_sid VARCHAR(100),
    messaging_service_sid VARCHAR(100),
    
    -- Message details
    direction message_direction NOT NULL,
    from_number VARCHAR(20) NOT NULL,
    to_number VARCHAR(20) NOT NULL,
    body TEXT,
    num_segments INTEGER DEFAULT 1,
    
    -- Media attachments (MMS)
    media_urls TEXT[],
    num_media INTEGER DEFAULT 0,
    
    -- Status and delivery
    status message_status DEFAULT 'queued',
    error_code VARCHAR(20),
    error_message TEXT,
    
    -- Cost tracking
    price DECIMAL(10,4),
    price_unit VARCHAR(10) DEFAULT 'USD',
    
    -- Message metadata
    template_id UUID, -- Reference to message template if used
    variables JSONB DEFAULT '{}', -- Template variables used
    tags TEXT[],
    
    -- Scheduling
    scheduled_at TIMESTAMP,
    sent_at TIMESTAMP,
    delivered_at TIMESTAMP,
    failed_at TIMESTAMP,
    
    -- Analytics
    clicked_links TEXT[], -- URLs clicked in message
    link_clicks_count INTEGER DEFAULT 0,
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Message templates table - Reusable message templates
CREATE TABLE message_templates (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    campaign_id UUID REFERENCES campaigns(id),
    name VARCHAR(255) NOT NULL,
    description TEXT,
    
    -- Template content
    body TEXT NOT NULL,
    variables JSONB DEFAULT '{}', -- Variable definitions and defaults
    
    -- Template settings
    category VARCHAR(100), -- 'welcome', 'promotional', 'transactional', etc.
    is_approved BOOLEAN DEFAULT FALSE,
    approved_by UUID REFERENCES users(id),
    approved_at TIMESTAMP,
    
    -- Usage statistics
    usage_count INTEGER DEFAULT 0,
    last_used_at TIMESTAMP,
    
    created_by UUID NOT NULL REFERENCES users(id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP
);

-- =============================================================================
-- COMPLIANCE AND AUDIT TABLES
-- =============================================================================

-- Consent records table - Track consent for communications
CREATE TABLE consent_records (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    contact_id UUID NOT NULL REFERENCES contacts(id) ON DELETE CASCADE,
    organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    campaign_id UUID REFERENCES campaigns(id),
    
    -- Consent details
    consent_type consent_type NOT NULL,
    consent_status consent_status NOT NULL,
    consent_source VARCHAR(100) NOT NULL, -- 'web_form', 'sms', 'phone', 'email'
    consent_text TEXT, -- The actual consent language shown
    
    -- Technical details
    ip_address INET,
    user_agent TEXT,
    location JSONB, -- {country, region, city, lat, lng}
    
    -- Double opt-in details
    double_opt_in BOOLEAN DEFAULT FALSE,
    verification_method VARCHAR(100), -- 'email', 'sms', 'phone'
    verification_sent_at TIMESTAMP,
    verification_confirmed_at TIMESTAMP,
    verification_token VARCHAR(255),
    
    -- Withdrawal details
    withdrawal_timestamp TIMESTAMP,
    withdrawal_reason VARCHAR(255),
    withdrawal_method VARCHAR(100),
    
    -- Legal and compliance
    consent_version VARCHAR(50), -- Version of consent form/process
    legal_basis VARCHAR(100), -- GDPR legal basis
    retention_period INTEGER, -- Days to retain consent record
    
    -- Additional metadata
    metadata JSONB DEFAULT '{}',
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Audit logs table - Comprehensive audit trail
CREATE TABLE audit_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_id UUID REFERENCES organizations(id) ON DELETE SET NULL,
    user_id UUID REFERENCES users(id) ON DELETE SET NULL,
    
    -- Action details
    entity_type VARCHAR(100) NOT NULL, -- 'user', 'brand', 'campaign', 'message'
    entity_id UUID,
    action audit_action NOT NULL,
    
    -- Change tracking
    old_values JSONB,
    new_values JSONB,
    
    -- Request details
    ip_address INET,
    user_agent TEXT,
    session_id VARCHAR(255),
    request_id VARCHAR(255),
    
    -- Additional context
    description TEXT,
    metadata JSONB DEFAULT '{}',
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Compliance violations table - Track and manage violations
CREATE TABLE compliance_violations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    
    -- Violation details
    violation_type violation_type NOT NULL,
    severity violation_severity NOT NULL,
    entity_type VARCHAR(100), -- What entity is involved
    entity_id UUID, -- ID of the involved entity
    
    -- Description and evidence
    title VARCHAR(255) NOT NULL,
    description TEXT NOT NULL,
    evidence JSONB DEFAULT '{}', -- Supporting evidence/data
    
    -- Detection and reporting
    detected_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    detected_by VARCHAR(100), -- 'system', 'user', 'external'
    detection_method VARCHAR(100), -- 'automated_scan', 'user_report', 'audit'
    reporter_id UUID REFERENCES users(id),
    
    -- Resolution tracking
    status violation_status DEFAULT 'open',
    assigned_to UUID REFERENCES users(id),
    resolved_at TIMESTAMP,
    resolved_by UUID REFERENCES users(id),
    resolution_notes TEXT,
    
    -- Follow-up and prevention
    corrective_action TEXT,
    prevention_measures TEXT,
    next_review_date TIMESTAMP,
    
    -- External reporting
    reported_to_authorities BOOLEAN DEFAULT FALSE,
    authority_reference VARCHAR(255),
    reported_at TIMESTAMP,
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- =============================================================================
-- API AND INTEGRATION TABLES
-- =============================================================================

-- API keys table - Manage API access
CREATE TABLE api_keys (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    
    -- Key details
    name VARCHAR(255) NOT NULL,
    key_prefix VARCHAR(20) NOT NULL, -- First few characters for identification
    key_hash VARCHAR(255) NOT NULL, -- Hashed full key
    
    -- Permissions and limits
    permissions JSONB DEFAULT '{}', -- API endpoint permissions
    rate_limit_per_minute INTEGER DEFAULT 100,
    rate_limit_per_hour INTEGER DEFAULT 1000,
    rate_limit_per_day INTEGER DEFAULT 10000,
    
    -- IP restrictions
    allowed_ips INET[],
    allowed_domains TEXT[],
    
    -- Status and expiry
    is_active BOOLEAN DEFAULT TRUE,
    expires_at TIMESTAMP,
    last_used_at TIMESTAMP,
    usage_count INTEGER DEFAULT 0,
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Webhooks table - Manage webhook endpoints
CREATE TABLE webhooks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    
    -- Webhook details
    name VARCHAR(255) NOT NULL,
    url VARCHAR(500) NOT NULL,
    secret VARCHAR(255), -- For signature verification
    
    -- Event subscriptions
    events TEXT[] NOT NULL, -- Array of event types to subscribe to
    
    -- Configuration
    is_active BOOLEAN DEFAULT TRUE,
    retry_attempts INTEGER DEFAULT 3,
    timeout_seconds INTEGER DEFAULT 30,
    
    -- Headers and authentication
    headers JSONB DEFAULT '{}',
    
    -- Status tracking
    last_triggered_at TIMESTAMP,
    last_success_at TIMESTAMP,
    last_failure_at TIMESTAMP,
    consecutive_failures INTEGER DEFAULT 0,
    total_deliveries INTEGER DEFAULT 0,
    successful_deliveries INTEGER DEFAULT 0,
    
    created_by UUID NOT NULL REFERENCES users(id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Webhook deliveries table - Track webhook delivery attempts
CREATE TABLE webhook_deliveries (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    webhook_id UUID NOT NULL REFERENCES webhooks(id) ON DELETE CASCADE,
    
    -- Event details
    event_type VARCHAR(100) NOT NULL,
    event_id UUID NOT NULL,
    payload JSONB NOT NULL,
    
    -- Delivery details
    attempt_number INTEGER NOT NULL DEFAULT 1,
    http_status_code INTEGER,
    response_headers JSONB,
    response_body TEXT,
    
    -- Timing
    triggered_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    delivered_at TIMESTAMP,
    duration_ms INTEGER,
    
    -- Status
    success BOOLEAN DEFAULT FALSE,
    error_message TEXT,
    
    -- Retry information
    retry_at TIMESTAMP,
    final_attempt BOOLEAN DEFAULT FALSE
);

-- =============================================================================
-- BILLING AND USAGE TRACKING TABLES
-- =============================================================================

-- Billing accounts table - Manage billing information
CREATE TABLE billing_accounts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    
    -- Stripe integration
    stripe_customer_id VARCHAR(255) UNIQUE,
    stripe_subscription_id VARCHAR(255),
    
    -- Billing details
    billing_email VARCHAR(255),
    billing_name VARCHAR(255),
    payment_method_id VARCHAR(255),
    
    -- Plan information
    plan_name VARCHAR(100),
    plan_price DECIMAL(10,2),
    billing_cycle VARCHAR(20), -- 'monthly', 'yearly'
    
    -- Usage limits
    monthly_message_limit INTEGER,
    monthly_contact_limit INTEGER,
    team_member_limit INTEGER,
    
    -- Status
    status VARCHAR(20) DEFAULT 'active', -- 'active', 'suspended', 'cancelled'
    trial_ends_at TIMESTAMP,
    current_period_start TIMESTAMP,
    current_period_end TIMESTAMP,
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Usage tracking table - Track usage for billing
CREATE TABLE usage_records (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    billing_account_id UUID REFERENCES billing_accounts(id),
    
    -- Usage period
    period_start TIMESTAMP NOT NULL,
    period_end TIMESTAMP NOT NULL,
    
    -- Usage metrics
    messages_sent INTEGER DEFAULT 0,
    messages_delivered INTEGER DEFAULT 0,
    messages_failed INTEGER DEFAULT 0,
    total_message_cost DECIMAL(10,4) DEFAULT 0,
    
    contacts_added INTEGER DEFAULT 0,
    contacts_active INTEGER DEFAULT 0,
    
    phone_numbers_active INTEGER DEFAULT 0,
    phone_number_costs DECIMAL(10,4) DEFAULT 0,
    
    api_calls INTEGER DEFAULT 0,
    webhook_deliveries INTEGER DEFAULT 0,
    
    -- Additional charges
    overages JSONB DEFAULT '{}',
    additional_charges DECIMAL(10,2) DEFAULT 0,
    
    -- Status
    billed BOOLEAN DEFAULT FALSE,
    invoice_id VARCHAR(255),
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    UNIQUE(organization_id, period_start, period_end)
);

-- =============================================================================
-- INDEXES FOR PERFORMANCE
-- =============================================================================

-- User and organization indexes
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_role ON users(role);
CREATE INDEX idx_users_deleted_at ON users(deleted_at);
CREATE INDEX idx_organizations_ein ON organizations(ein);
CREATE INDEX idx_organizations_verification_status ON organizations(verification_status);
CREATE INDEX idx_user_organizations_user_id ON user_organizations(user_id);
CREATE INDEX idx_user_organizations_org_id ON user_organizations(organization_id);
CREATE INDEX idx_user_organizations_role ON user_organizations(role);

-- Brand and campaign indexes
CREATE INDEX idx_brands_org_id ON brands(organization_id);
CREATE INDEX idx_brands_tcr_id ON brands(tcr_brand_id);
CREATE INDEX idx_brands_status ON brands(registration_status);
CREATE INDEX idx_brands_created_by ON brands(created_by);
CREATE INDEX idx_campaigns_brand_id ON campaigns(brand_id);
CREATE INDEX idx_campaigns_tcr_id ON campaigns(tcr_campaign_id);
CREATE INDEX idx_campaigns_use_case ON campaigns(use_case);
CREATE INDEX idx_campaigns_status ON campaigns(registration_status);

-- Phone number indexes
CREATE INDEX idx_phone_numbers_org_id ON phone_numbers(organization_id);
CREATE INDEX idx_phone_numbers_campaign_id ON phone_numbers(assigned_to_campaign_id);
CREATE INDEX idx_phone_numbers_status ON phone_numbers(status);
CREATE INDEX idx_phone_numbers_type ON phone_numbers(phone_number_type);

-- Contact and list indexes
CREATE INDEX idx_contact_lists_org_id ON contact_lists(organization_id);
CREATE INDEX idx_contact_lists_created_by ON contact_lists(created_by);
CREATE INDEX idx_contacts_org_id ON contacts(organization_id);
CREATE INDEX idx_contacts_phone ON contacts(phone_number);
CREATE INDEX idx_contacts_email ON contacts(email);
CREATE INDEX idx_contacts_opted_in ON contacts(opted_in);
CREATE INDEX idx_contacts_opted_out ON contacts(opted_out);
CREATE INDEX idx_contacts_suppressed ON contacts(suppressed);
CREATE INDEX idx_contact_list_memberships_list_id ON contact_list_memberships(contact_list_id);
CREATE INDEX idx_contact_list_memberships_contact_id ON contact_list_memberships(contact_id);

-- Message indexes
CREATE INDEX idx_messages_org_id ON messages(organization_id);
CREATE INDEX idx_messages_campaign_id ON messages(campaign_id);
CREATE INDEX idx_messages_contact_id ON messages(contact_id);
CREATE INDEX idx_messages_phone_number_id ON messages(phone_number_id);
CREATE INDEX idx_messages_message_sid ON messages(message_sid);
CREATE INDEX idx_messages_direction ON messages(direction);
CREATE INDEX idx_messages_status ON messages(status);
CREATE INDEX idx_messages_created_at ON messages(created_at);
CREATE INDEX idx_messages_sent_at ON messages(sent_at);
CREATE INDEX idx_messages_from_number ON messages(from_number);
CREATE INDEX idx_messages_to_number ON messages(to_number);

-- Template indexes
CREATE INDEX idx_message_templates_org_id ON message_templates(organization_id);
CREATE INDEX idx_message_templates_campaign_id ON message_templates(campaign_id);
CREATE INDEX idx_message_templates_category ON message_templates(category);
CREATE INDEX idx_message_templates_created_by ON message_templates(created_by);

-- Compliance and audit indexes
CREATE INDEX idx_consent_records_contact_id ON consent_records(contact_id);
CREATE INDEX idx_consent_records_org_id ON consent_records(organization_id);
CREATE INDEX idx_consent_records_campaign_id ON consent_records(campaign_id);
CREATE INDEX idx_consent_records_status ON consent_records(consent_status);
CREATE INDEX idx_consent_records_type ON consent_records(consent_type);
CREATE INDEX idx_audit_logs_org_id ON audit_logs(organization_id);
CREATE INDEX idx_audit_logs_user_id ON audit_logs(user_id);
CREATE INDEX idx_audit_logs_entity ON audit_logs(entity_type, entity_id);
CREATE INDEX idx_audit_logs_action ON audit_logs(action);
CREATE INDEX idx_audit_logs_created_at ON audit_logs(created_at);
CREATE INDEX idx_compliance_violations_org_id ON compliance_violations(organization_id);
CREATE INDEX idx_compliance_violations_status ON compliance_violations(status);
CREATE INDEX idx_compliance_violations_severity ON compliance_violations(severity);
CREATE INDEX idx_compliance_violations_type ON compliance_violations(violation_type);

-- API and integration indexes
CREATE INDEX idx_api_keys_org_id ON api_keys(organization_id);
CREATE INDEX idx_api_keys_user_id ON api_keys(user_id);
CREATE INDEX idx_api_keys_prefix ON api_keys(key_prefix);
CREATE INDEX idx_api_keys_active ON api_keys(is_active);
CREATE INDEX idx_webhooks_org_id ON webhooks(organization_id);
CREATE INDEX idx_webhooks_active ON webhooks(is_active);
CREATE INDEX idx_webhook_deliveries_webhook_id ON webhook_deliveries(webhook_id);
CREATE INDEX idx_webhook_deliveries_event_type ON webhook_deliveries(event_type);
CREATE INDEX idx_webhook_deliveries_triggered_at ON webhook_deliveries(triggered_at);

-- Billing indexes
CREATE INDEX idx_billing_accounts_org_id ON billing_accounts(organization_id);
CREATE INDEX idx_billing_accounts_stripe_customer ON billing_accounts(stripe_customer_id);
CREATE INDEX idx_usage_records_org_id ON usage_records(organization_id);
CREATE INDEX idx_usage_records_billing_account ON usage_records(billing_account_id);
CREATE INDEX idx_usage_records_period ON usage_records(period_start, period_end);

-- =============================================================================
-- COMPOSITE INDEXES FOR COMPLEX QUERIES
-- =============================================================================

-- Message analytics indexes
CREATE INDEX idx_messages_org_created ON messages(organization_id, created_at);
CREATE INDEX idx_messages_campaign_created ON messages(campaign_id, created_at);
CREATE INDEX idx_messages_status_created ON messages(status, created_at);
CREATE INDEX idx_messages_org_status_created ON messages(organization_id, status, created_at);

-- Contact engagement indexes
CREATE INDEX idx_contacts_org_opted_in ON contacts(organization_id, opted_in);
CREATE INDEX idx_contacts_org_created ON contacts(organization_id, created_at);
CREATE INDEX idx_contacts_org_last_message ON contacts(organization_id, last_message_sent_at);

-- Audit and compliance indexes
CREATE INDEX idx_audit_logs_org_created ON audit_logs(organization_id, created_at);
CREATE INDEX idx_violations_org_status ON compliance_violations(organization_id, status);

-- =============================================================================
-- TRIGGERS FOR AUTOMATIC UPDATES
-- =============================================================================

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Apply update triggers to relevant tables
CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_organizations_updated_at BEFORE UPDATE ON organizations FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_user_organizations_updated_at BEFORE UPDATE ON user_organizations FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_brands_updated_at BEFORE UPDATE ON brands FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_campaigns_updated_at BEFORE UPDATE ON campaigns FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_phone_numbers_updated_at BEFORE UPDATE ON phone_numbers FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_contact_lists_updated_at BEFORE UPDATE ON contact_lists FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_contacts_updated_at BEFORE UPDATE ON contacts FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_messages_updated_at BEFORE UPDATE ON messages FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_message_templates_updated_at BEFORE UPDATE ON message_templates FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_consent_records_updated_at BEFORE UPDATE ON consent_records FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_compliance_violations_updated_at BEFORE UPDATE ON compliance_violations FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_api_keys_updated_at BEFORE UPDATE ON api_keys FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_webhooks_updated_at BEFORE UPDATE ON webhooks FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_billing_accounts_updated_at BEFORE UPDATE ON billing_accounts FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_usage_records_updated_at BEFORE UPDATE ON usage_records FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- =============================================================================
-- VIEWS FOR COMMON QUERIES
-- =============================================================================

-- View for organization members with user details
CREATE VIEW organization_members AS
SELECT 
    uo.organization_id,
    uo.user_id,
    uo.role,
    uo.joined_at,
    u.email,
    u.first_name,
    u.last_name,
    u.last_login_at,
    o.legal_name as organization_name
FROM user_organizations uo
JOIN users u ON uo.user_id = u.id
JOIN organizations o ON uo.organization_id = o.id
WHERE u.deleted_at IS NULL;

-- View for campaign summary with brand information
CREATE VIEW campaign_summary AS
SELECT 
    c.id,
    c.campaign_name,
    c.use_case,
    c.registration_status,
    c.created_at,
    b.brand_name,
    b.registration_status as brand_status,
    o.legal_name as organization_name,
    COUNT(m.id) as total_messages
FROM campaigns c
JOIN brands b ON c.brand_id = b.id
JOIN organizations o ON b.organization_id = o.id
LEFT JOIN messages m ON c.id = m.campaign_id
WHERE c.deleted_at IS NULL
GROUP BY c.id, b.id, o.id;

-- View for contact engagement metrics
CREATE VIEW contact_engagement AS
SELECT 
    c.id,
    c.phone_number,
    c.first_name,
    c.last_name,
    c.opted_in,
    c.opted_in_at,
    c.total_messages_sent,
    c.total_messages_delivered,
    c.last_message_sent_at,
    c.last_response_at,
    o.legal_name as organization_name,
    CASE 
        WHEN c.last_response_at > c.last_message_sent_at - INTERVAL '7 days' THEN 'active'
        WHEN c.last_message_sent_at > CURRENT_TIMESTAMP - INTERVAL '30 days' THEN 'inactive'
        ELSE 'dormant'
    END as engagement_status
FROM contacts c
JOIN organizations o ON c.organization_id = o.id
WHERE c.deleted_at IS NULL;

-- View for message analytics
CREATE VIEW message_analytics AS
SELECT 
    DATE_TRUNC('day', created_at) as date,
    organization_id,
    campaign_id,
    COUNT(*) as total_messages,
    COUNT(CASE WHEN status = 'delivered' THEN 1 END) as delivered_messages,
    COUNT(CASE WHEN status = 'failed' THEN 1 END) as failed_messages,
    COUNT(CASE WHEN direction = 'inbound' THEN 1 END) as inbound_messages,
    COUNT(CASE WHEN direction = 'outbound' THEN 1 END) as outbound_messages,
    SUM(price) as total_cost
FROM messages
GROUP BY DATE_TRUNC('day', created_at), organization_id, campaign_id;

-- =============================================================================
-- SECURITY POLICIES (ROW LEVEL SECURITY)
-- =============================================================================

-- Enable RLS on sensitive tables
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE organizations ENABLE ROW LEVEL SECURITY;
ALTER TABLE brands ENABLE ROW LEVEL SECURITY;
ALTER TABLE campaigns ENABLE ROW LEVEL SECURITY;
ALTER TABLE contacts ENABLE ROW LEVEL SECURITY;
ALTER TABLE messages ENABLE ROW LEVEL SECURITY;

-- Example RLS policies (to be customized based on application requirements)
-- Users can only see their own data
CREATE POLICY users_self_access ON users
    FOR ALL
    USING (id = current_setting('app.current_user_id')::uuid);

-- Organization data access based on membership
CREATE POLICY organizations_member_access ON organizations
    FOR ALL
    USING (id IN (
        SELECT organization_id 
        FROM user_organizations 
        WHERE user_id = current_setting('app.current_user_id')::uuid
    ));

-- =============================================================================
-- INITIAL DATA AND CONFIGURATION
-- =============================================================================

-- Insert initial configuration data
INSERT INTO organizations (id, legal_name, display_name, business_type, industry, website_url, verification_status) 
VALUES (
    gen_random_uuid(),
    'Platform Administrator',
    'Admin Organization',
    'corporation',
    'Technology',
    'https://admin.smsplatform.com',
    'verified'
) ON CONFLICT DO NOTHING;

-- =============================================================================
-- SCHEMA VALIDATION AND CONSTRAINTS
-- =============================================================================

-- Add check constraints for data validation
ALTER TABLE users ADD CONSTRAINT users_email_format CHECK (email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$');
ALTER TABLE users ADD CONSTRAINT users_phone_format CHECK (phone_number IS NULL OR phone_number ~ '^\+?[1-9]\d{1,14}$');
ALTER TABLE contacts ADD CONSTRAINT contacts_phone_format CHECK (phone_number ~ '^\+?[1-9]\d{1,14}$');
ALTER TABLE messages ADD CONSTRAINT messages_price_positive CHECK (price IS NULL OR price >= 0);
ALTER TABLE brands ADD CONSTRAINT brands_website_format CHECK (website ~* '^https?://');
ALTER TABLE usage_records ADD CONSTRAINT usage_records_period_valid CHECK (period_end > period_start);

-- =============================================================================
-- COMMENTS AND DOCUMENTATION
-- =============================================================================

-- Add table comments for documentation
COMMENT ON TABLE users IS 'Core user authentication and profile information';
COMMENT ON TABLE organizations IS 'Business entities that use the platform';
COMMENT ON TABLE brands IS 'TCR Brand Registration entities for 10DLC compliance';
COMMENT ON TABLE campaigns IS 'TCR Campaign Registration entities for message use cases';
COMMENT ON TABLE contacts IS 'Individual contact records with consent and engagement tracking';
COMMENT ON TABLE messages IS 'All sent and received SMS/MMS messages with delivery tracking';
COMMENT ON TABLE consent_records IS 'Comprehensive consent tracking for compliance';
COMMENT ON TABLE audit_logs IS 'Complete audit trail for all system actions';
COMMENT ON TABLE compliance_violations IS 'Track and manage compliance violations';

-- Add column comments for important fields
COMMENT ON COLUMN brands.tcr_brand_id IS 'Unique identifier from The Campaign Registry';
COMMENT ON COLUMN campaigns.tcr_campaign_id IS 'Unique identifier from The Campaign Registry';
COMMENT ON COLUMN messages.message_sid IS 'Twilio unique message identifier';
COMMENT ON COLUMN contacts.opted_in_source IS 'Source of opt-in: web_form, api, import, sms';
COMMENT ON COLUMN consent_records.legal_basis IS 'GDPR legal basis for processing';

-- =============================================================================
-- END OF SCHEMA
-- =============================================================================

-- Schema version tracking
CREATE TABLE schema_migrations (
    version VARCHAR(255) PRIMARY KEY,
    applied_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO schema_migrations (version) VALUES ('1.0.0_initial_schema');

-- Performance analysis helper
-- Run this to analyze table sizes and index usage
/*
SELECT 
    schemaname,
    tablename,
    attname,
    n_distinct,
    correlation,
    most_common_vals,
    most_common_freqs
FROM pg_stats 
WHERE schemaname = 'public' 
ORDER BY tablename, attname;
*/

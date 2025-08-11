-- 10DLC SMS Platform Database Schema
-- MySQL 8.0+ Compatible
-- Version: 1.0 (Updated for MySQL)
-- Last Updated: December 2024

-- =============================================================================
-- DATABASE CREATION AND CONFIGURATION
-- =============================================================================

-- Create database (run this first)
-- CREATE DATABASE sms_platform CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
-- USE sms_platform;

-- Set MySQL specific settings
SET sql_mode = 'STRICT_TRANS_TABLES,NO_ZERO_DATE,NO_ZERO_IN_DATE,ERROR_FOR_DIVISION_BY_ZERO';
SET FOREIGN_KEY_CHECKS = 1;

-- =============================================================================
-- CUSTOM TYPES AND ENUMS (MySQL ENUM equivalent)
-- =============================================================================

-- Note: MySQL uses ENUM types directly in column definitions
-- These are documented here for reference

-- User and organization related enums
-- user_role: 'super_admin', 'admin', 'user'
-- organization_type: 'corporation', 'llc', 'partnership', 'sole_proprietorship', 'non_profit', 'government'
-- organization_role: 'owner', 'admin', 'manager', 'member'
-- verification_status: 'pending', 'in_progress', 'verified', 'rejected'

-- Brand and campaign related enums
-- brand_entity_type: 'private_profit', 'public_profit', 'non_profit', 'government'
-- identity_status: 'unverified', 'pending', 'verified', 'failed'
-- brand_status: 'draft', 'pending', 'approved', 'suspended', 'rejected'
-- brand_relationship: 'basic_t', 'standard_t', 'premium_t'

-- Campaign use cases as defined by TCR
-- campaign_use_case: 'marketing', 'mixed', 'account_notification', 'customer_care', 'delivery_notification', 'fraud_alert', 'higher_education', 'low_volume', 'emergency', 'charity', 'political', 'public_service_announcement', 'social_media'
-- campaign_status: 'draft', 'pending', 'approved', 'suspended', 'rejected'

-- Message related enums
-- message_direction: 'inbound', 'outbound'
-- message_status: 'queued', 'sending', 'sent', 'delivered', 'undelivered', 'failed', 'received', 'read'

-- Phone number types and statuses
-- phone_number_type: 'local', 'toll_free', '10dlc'
-- phone_number_status: 'active', 'inactive', 'pending', 'suspended'

-- Compliance related enums
-- consent_type: 'sms_marketing', 'sms_transactional', 'sms_service', 'email_marketing'
-- consent_status: 'granted', 'withdrawn', 'expired'
-- audit_action: 'create', 'read', 'update', 'delete', 'login', 'logout', 'export', 'import', 'send_message', 'approve', 'reject'
-- violation_type: 'unauthorized_message', 'missing_consent', 'content_violation', 'rate_limit_exceeded', 'invalid_opt_out', 'data_breach'
-- violation_severity: 'low', 'medium', 'high', 'critical'
-- violation_status: 'open', 'investigating', 'resolved', 'closed'

-- =============================================================================
-- CORE USER AND ORGANIZATION TABLES
-- =============================================================================

-- Users table - Core user authentication and profile information
CREATE TABLE users (
    id CHAR(36) PRIMARY KEY DEFAULT (UUID()),
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    phone_number VARCHAR(20),
    role ENUM('super_admin', 'admin', 'user') NOT NULL DEFAULT 'user',
    email_verified BOOLEAN DEFAULT FALSE,
    email_verification_token VARCHAR(255),
    email_verification_expires DATETIME,
    phone_verified BOOLEAN DEFAULT FALSE,
    phone_verification_token VARCHAR(10),
    phone_verification_expires DATETIME,
    mfa_enabled BOOLEAN DEFAULT FALSE,
    mfa_secret VARCHAR(255),
    mfa_backup_codes JSON,
    password_reset_token VARCHAR(255),
    password_reset_expires DATETIME,
    last_login_at DATETIME,
    login_attempts INT DEFAULT 0,
    locked_until DATETIME,
    timezone VARCHAR(50) DEFAULT 'UTC',
    locale VARCHAR(10) DEFAULT 'en',
    avatar_url VARCHAR(500),
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    deleted_at DATETIME,
    
    INDEX idx_users_email (email),
    INDEX idx_users_role (role),
    INDEX idx_users_deleted_at (deleted_at)
);

-- Organizations table - Business entities that use the platform
CREATE TABLE organizations (
    id CHAR(36) PRIMARY KEY DEFAULT (UUID()),
    legal_name VARCHAR(255) NOT NULL,
    display_name VARCHAR(255),
    ein VARCHAR(20) UNIQUE,
    business_type ENUM('corporation', 'llc', 'partnership', 'sole_proprietorship', 'non_profit', 'government') NOT NULL,
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
    verification_status ENUM('pending', 'in_progress', 'verified', 'rejected') DEFAULT 'pending',
    verification_notes TEXT,
    verified_at DATETIME,
    verified_by CHAR(36),
    billing_address_line1 VARCHAR(255),
    billing_address_line2 VARCHAR(255),
    billing_city VARCHAR(100),
    billing_state VARCHAR(50),
    billing_postal_code VARCHAR(20),
    billing_country VARCHAR(50) DEFAULT 'US',
    tax_id VARCHAR(50),
    annual_revenue BIGINT,
    employee_count INT,
    founded_year INT,
    logo_url VARCHAR(500),
    description TEXT,
    settings JSON,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    deleted_at DATETIME,
    
    INDEX idx_organizations_ein (ein),
    INDEX idx_organizations_verification_status (verification_status),
    FOREIGN KEY (verified_by) REFERENCES users(id) ON DELETE SET NULL
);

-- User organization relationships - Many-to-many with roles
CREATE TABLE user_organizations (
    id CHAR(36) PRIMARY KEY DEFAULT (UUID()),
    user_id CHAR(36) NOT NULL,
    organization_id CHAR(36) NOT NULL,
    role ENUM('owner', 'admin', 'manager', 'member') NOT NULL DEFAULT 'member',
    permissions JSON,
    invited_by CHAR(36),
    invited_at DATETIME,
    invitation_token VARCHAR(255),
    invitation_expires DATETIME,
    joined_at DATETIME,
    status VARCHAR(20) DEFAULT 'active',
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    UNIQUE KEY uk_user_org (user_id, organization_id),
    INDEX idx_user_organizations_user_id (user_id),
    INDEX idx_user_organizations_org_id (organization_id),
    INDEX idx_user_organizations_role (role),
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (organization_id) REFERENCES organizations(id) ON DELETE CASCADE,
    FOREIGN KEY (invited_by) REFERENCES users(id) ON DELETE SET NULL
);

-- =============================================================================
-- BRAND AND CAMPAIGN MANAGEMENT TABLES
-- =============================================================================

-- Brands table - TCR Brand Registration entities
CREATE TABLE brands (
    id CHAR(36) PRIMARY KEY DEFAULT (UUID()),
    organization_id CHAR(36) NOT NULL,
    tcr_brand_id VARCHAR(100) UNIQUE,
    brand_name VARCHAR(255) NOT NULL,
    entity_type ENUM('private_profit', 'public_profit', 'non_profit', 'government') NOT NULL,
    industry VARCHAR(100) NOT NULL,
    website VARCHAR(500) NOT NULL,
    stock_symbol VARCHAR(10),
    stock_exchange VARCHAR(50),
    business_registration_number VARCHAR(100),
    tax_id VARCHAR(50),
    ein VARCHAR(20),
    phone_number VARCHAR(20),
    email VARCHAR(255),
    
    -- Address stored as JSON for flexibility
    address JSON NOT NULL,
    
    -- TCR specific fields
    identity_status ENUM('unverified', 'pending', 'verified', 'failed') DEFAULT 'unverified',
    registration_status ENUM('draft', 'pending', 'approved', 'suspended', 'rejected') DEFAULT 'draft',
    trust_score INT,
    compliance_score INT,
    brand_relationship ENUM('basic_t', 'standard_t', 'premium_t') DEFAULT 'basic_t',
    
    -- Additional brand information
    company_description TEXT,
    customer_support_phone VARCHAR(20),
    customer_support_email VARCHAR(255),
    help_center_url VARCHAR(500),
    terms_and_conditions_url VARCHAR(500),
    privacy_policy_url VARCHAR(500),
    
    -- Social media and verification
    social_media_urls JSON,
    verification_documents JSON,
    
    -- Status and timestamps
    mock BOOLEAN DEFAULT FALSE,
    submitted_at DATETIME,
    approved_at DATETIME,
    rejection_reason TEXT,
    next_review_date DATETIME,
    
    created_by CHAR(36) NOT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    deleted_at DATETIME,
    
    INDEX idx_brands_org_id (organization_id),
    INDEX idx_brands_tcr_id (tcr_brand_id),
    INDEX idx_brands_status (registration_status),
    INDEX idx_brands_created_by (created_by),
    FOREIGN KEY (organization_id) REFERENCES organizations(id) ON DELETE CASCADE,
    FOREIGN KEY (created_by) REFERENCES users(id)
);

-- Campaigns table - TCR Campaign Registration entities
CREATE TABLE campaigns (
    id CHAR(36) PRIMARY KEY DEFAULT (UUID()),
    brand_id CHAR(36) NOT NULL,
    tcr_campaign_id VARCHAR(100) UNIQUE,
    campaign_name VARCHAR(255) NOT NULL,
    use_case ENUM('marketing', 'mixed', 'account_notification', 'customer_care', 'delivery_notification', 'fraud_alert', 'higher_education', 'low_volume', 'emergency', 'charity', 'political', 'public_service_announcement', 'social_media') NOT NULL,
    sub_use_cases JSON,
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
    help_keywords JSON,
    help_message TEXT DEFAULT 'For help, contact customer support.',
    stop_keywords JSON,
    opt_in_keywords JSON,
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
    estimated_monthly_volume INT,
    peak_daily_volume INT,
    peak_hourly_volume INT,
    
    -- Campaign settings
    rate_limit_per_minute INT DEFAULT 10,
    rate_limit_per_hour INT DEFAULT 100,
    rate_limit_per_day INT DEFAULT 1000,
    time_zone VARCHAR(50) DEFAULT 'UTC',
    send_window_start TIME DEFAULT '08:00:00',
    send_window_end TIME DEFAULT '21:00:00',
    
    -- Status and approval
    registration_status ENUM('draft', 'pending', 'approved', 'suspended', 'rejected') DEFAULT 'draft',
    mock BOOLEAN DEFAULT FALSE,
    submitted_at DATETIME,
    approved_at DATETIME,
    rejection_reason TEXT,
    
    created_by CHAR(36) NOT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    deleted_at DATETIME,
    
    INDEX idx_campaigns_brand_id (brand_id),
    INDEX idx_campaigns_tcr_id (tcr_campaign_id),
    INDEX idx_campaigns_use_case (use_case),
    INDEX idx_campaigns_status (registration_status),
    FOREIGN KEY (brand_id) REFERENCES brands(id) ON DELETE CASCADE,
    FOREIGN KEY (created_by) REFERENCES users(id)
);

-- =============================================================================
-- PHONE NUMBER MANAGEMENT
-- =============================================================================

-- Phone numbers table - Manage phone numbers and their assignments
CREATE TABLE phone_numbers (
    id CHAR(36) PRIMARY KEY DEFAULT (UUID()),
    organization_id CHAR(36) NOT NULL,
    phone_number VARCHAR(20) NOT NULL UNIQUE,
    friendly_name VARCHAR(100),
    phone_number_sid VARCHAR(100) UNIQUE,
    phone_number_type ENUM('local', 'toll_free', '10dlc') NOT NULL,
    status ENUM('active', 'inactive', 'pending', 'suspended') DEFAULT 'pending',
    
    -- Assignment and capabilities
    assigned_to_campaign_id CHAR(36),
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
    monthly_message_limit INT,
    
    -- Purchase and assignment dates
    purchased_at DATETIME,
    assigned_at DATETIME,
    released_at DATETIME,
    
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    INDEX idx_phone_numbers_org_id (organization_id),
    INDEX idx_phone_numbers_campaign_id (assigned_to_campaign_id),
    INDEX idx_phone_numbers_status (status),
    INDEX idx_phone_numbers_type (phone_number_type),
    FOREIGN KEY (organization_id) REFERENCES organizations(id) ON DELETE CASCADE,
    FOREIGN KEY (assigned_to_campaign_id) REFERENCES campaigns(id) ON DELETE SET NULL
);

-- =============================================================================
-- CONTACT MANAGEMENT TABLES
-- =============================================================================

-- Contact lists table - Organize contacts into lists
CREATE TABLE contact_lists (
    id CHAR(36) PRIMARY KEY DEFAULT (UUID()),
    organization_id CHAR(36) NOT NULL,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    tags JSON,
    total_contacts INT DEFAULT 0,
    active_contacts INT DEFAULT 0,
    opted_in_contacts INT DEFAULT 0,
    
    -- List settings
    double_opt_in_required BOOLEAN DEFAULT FALSE,
    welcome_message TEXT,
    unsubscribe_message TEXT,
    
    -- Custom fields definition
    custom_fields JSON,
    
    created_by CHAR(36) NOT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    deleted_at DATETIME,
    
    INDEX idx_contact_lists_org_id (organization_id),
    INDEX idx_contact_lists_created_by (created_by),
    FOREIGN KEY (organization_id) REFERENCES organizations(id) ON DELETE CASCADE,
    FOREIGN KEY (created_by) REFERENCES users(id)
);

-- Contacts table - Individual contact records
CREATE TABLE contacts (
    id CHAR(36) PRIMARY KEY DEFAULT (UUID()),
    organization_id CHAR(36) NOT NULL,
    phone_number VARCHAR(20) NOT NULL,
    email VARCHAR(255),
    first_name VARCHAR(100),
    last_name VARCHAR(100),
    
    -- Custom fields data
    custom_fields JSON,
    
    -- Consent and preferences
    opted_in BOOLEAN DEFAULT FALSE,
    opted_in_at DATETIME,
    opted_in_source VARCHAR(100),
    opted_in_ip VARCHAR(45),
    opted_in_user_agent TEXT,
    double_opt_in_confirmed BOOLEAN DEFAULT FALSE,
    double_opt_in_confirmed_at DATETIME,
    
    opted_out BOOLEAN DEFAULT FALSE,
    opted_out_at DATETIME,
    opted_out_source VARCHAR(100),
    opt_out_reason VARCHAR(255),
    
    -- Suppression and blocking
    suppressed BOOLEAN DEFAULT FALSE,
    suppressed_reason VARCHAR(255),
    suppressed_at DATETIME,
    suppressed_by CHAR(36),
    
    -- Delivery tracking
    bounce_count INT DEFAULT 0,
    last_bounce_at DATETIME,
    complaint_count INT DEFAULT 0,
    last_complaint_at DATETIME,
    
    -- Engagement metrics
    total_messages_sent INT DEFAULT 0,
    total_messages_delivered INT DEFAULT 0,
    total_messages_failed INT DEFAULT 0,
    last_message_sent_at DATETIME,
    last_message_delivered_at DATETIME,
    last_response_at DATETIME,
    
    -- Location and timezone
    timezone VARCHAR(50),
    country VARCHAR(50),
    region VARCHAR(100),
    
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    deleted_at DATETIME,
    
    UNIQUE KEY uk_org_phone (organization_id, phone_number),
    INDEX idx_contacts_org_id (organization_id),
    INDEX idx_contacts_phone (phone_number),
    INDEX idx_contacts_email (email),
    INDEX idx_contacts_opted_in (opted_in),
    INDEX idx_contacts_opted_out (opted_out),
    INDEX idx_contacts_suppressed (suppressed),
    INDEX idx_contacts_org_opted_in (organization_id, opted_in),
    INDEX idx_contacts_org_created (organization_id, created_at),
    INDEX idx_contacts_org_last_message (organization_id, last_message_sent_at),
    FOREIGN KEY (organization_id) REFERENCES organizations(id) ON DELETE CASCADE,
    FOREIGN KEY (suppressed_by) REFERENCES users(id) ON DELETE SET NULL
);

-- Contact list memberships - Many-to-many relationship
CREATE TABLE contact_list_memberships (
    id CHAR(36) PRIMARY KEY DEFAULT (UUID()),
    contact_list_id CHAR(36) NOT NULL,
    contact_id CHAR(36) NOT NULL,
    status VARCHAR(20) DEFAULT 'active',
    added_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    added_by CHAR(36),
    removed_at DATETIME,
    removed_by CHAR(36),
    
    UNIQUE KEY uk_list_contact (contact_list_id, contact_id),
    INDEX idx_contact_list_memberships_list_id (contact_list_id),
    INDEX idx_contact_list_memberships_contact_id (contact_id),
    FOREIGN KEY (contact_list_id) REFERENCES contact_lists(id) ON DELETE CASCADE,
    FOREIGN KEY (contact_id) REFERENCES contacts(id) ON DELETE CASCADE,
    FOREIGN KEY (added_by) REFERENCES users(id) ON DELETE SET NULL,
    FOREIGN KEY (removed_by) REFERENCES users(id) ON DELETE SET NULL
);

-- =============================================================================
-- MESSAGE MANAGEMENT TABLES
-- =============================================================================

-- Messages table - All sent and received messages
CREATE TABLE messages (
    id CHAR(36) PRIMARY KEY DEFAULT (UUID()),
    organization_id CHAR(36) NOT NULL,
    campaign_id CHAR(36),
    contact_id CHAR(36),
    phone_number_id CHAR(36),
    
    -- Twilio integration
    message_sid VARCHAR(100) UNIQUE,
    account_sid VARCHAR(100),
    messaging_service_sid VARCHAR(100),
    
    -- Message details
    direction ENUM('inbound', 'outbound') NOT NULL,
    from_number VARCHAR(20) NOT NULL,
    to_number VARCHAR(20) NOT NULL,
    body TEXT,
    num_segments INT DEFAULT 1,
    
    -- Media attachments (MMS)
    media_urls JSON,
    num_media INT DEFAULT 0,
    
    -- Status and delivery
    status ENUM('queued', 'sending', 'sent', 'delivered', 'undelivered', 'failed', 'received', 'read') DEFAULT 'queued',
    error_code VARCHAR(20),
    error_message TEXT,
    
    -- Cost tracking
    price DECIMAL(10,4),
    price_unit VARCHAR(10) DEFAULT 'USD',
    
    -- Message metadata
    template_id CHAR(36),
    variables JSON,
    tags JSON,
    
    -- Scheduling
    scheduled_at DATETIME,
    sent_at DATETIME,
    delivered_at DATETIME,
    failed_at DATETIME,
    
    -- Analytics
    clicked_links JSON,
    link_clicks_count INT DEFAULT 0,
    
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    INDEX idx_messages_org_id (organization_id),
    INDEX idx_messages_campaign_id (campaign_id),
    INDEX idx_messages_contact_id (contact_id),
    INDEX idx_messages_phone_number_id (phone_number_id),
    INDEX idx_messages_message_sid (message_sid),
    INDEX idx_messages_direction (direction),
    INDEX idx_messages_status (status),
    INDEX idx_messages_created_at (created_at),
    INDEX idx_messages_sent_at (sent_at),
    INDEX idx_messages_from_number (from_number),
    INDEX idx_messages_to_number (to_number),
    INDEX idx_messages_org_created (organization_id, created_at),
    INDEX idx_messages_campaign_created (campaign_id, created_at),
    INDEX idx_messages_status_created (status, created_at),
    INDEX idx_messages_org_status_created (organization_id, status, created_at),
    FOREIGN KEY (organization_id) REFERENCES organizations(id) ON DELETE CASCADE,
    FOREIGN KEY (campaign_id) REFERENCES campaigns(id) ON DELETE SET NULL,
    FOREIGN KEY (contact_id) REFERENCES contacts(id) ON DELETE SET NULL,
    FOREIGN KEY (phone_number_id) REFERENCES phone_numbers(id) ON DELETE SET NULL
);

-- Message templates table - Reusable message templates
CREATE TABLE message_templates (
    id CHAR(36) PRIMARY KEY DEFAULT (UUID()),
    organization_id CHAR(36) NOT NULL,
    campaign_id CHAR(36),
    name VARCHAR(255) NOT NULL,
    description TEXT,
    
    -- Template content
    body TEXT NOT NULL,
    variables JSON,
    
    -- Template settings
    category VARCHAR(100),
    is_approved BOOLEAN DEFAULT FALSE,
    approved_by CHAR(36),
    approved_at DATETIME,
    
    -- Usage statistics
    usage_count INT DEFAULT 0,
    last_used_at DATETIME,
    
    created_by CHAR(36) NOT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    deleted_at DATETIME,
    
    INDEX idx_message_templates_org_id (organization_id),
    INDEX idx_message_templates_campaign_id (campaign_id),
    INDEX idx_message_templates_category (category),
    INDEX idx_message_templates_created_by (created_by),
    FOREIGN KEY (organization_id) REFERENCES organizations(id) ON DELETE CASCADE,
    FOREIGN KEY (campaign_id) REFERENCES campaigns(id) ON DELETE SET NULL,
    FOREIGN KEY (created_by) REFERENCES users(id),
    FOREIGN KEY (approved_by) REFERENCES users(id) ON DELETE SET NULL
);

-- =============================================================================
-- COMPLIANCE AND AUDIT TABLES
-- =============================================================================

-- Consent records table - Track consent for communications
CREATE TABLE consent_records (
    id CHAR(36) PRIMARY KEY DEFAULT (UUID()),
    contact_id CHAR(36) NOT NULL,
    organization_id CHAR(36) NOT NULL,
    campaign_id CHAR(36),
    
    -- Consent details
    consent_type ENUM('sms_marketing', 'sms_transactional', 'sms_service', 'email_marketing') NOT NULL,
    consent_status ENUM('granted', 'withdrawn', 'expired') NOT NULL,
    consent_source VARCHAR(100) NOT NULL,
    consent_text TEXT,
    
    -- Technical details
    ip_address VARCHAR(45),
    user_agent TEXT,
    location JSON,
    
    -- Double opt-in details
    double_opt_in BOOLEAN DEFAULT FALSE,
    verification_method VARCHAR(100),
    verification_sent_at DATETIME,
    verification_confirmed_at DATETIME,
    verification_token VARCHAR(255),
    
    -- Withdrawal details
    withdrawal_timestamp DATETIME,
    withdrawal_reason VARCHAR(255),
    withdrawal_method VARCHAR(100),
    
    -- Legal and compliance
    consent_version VARCHAR(50),
    legal_basis VARCHAR(100),
    retention_period INT,
    
    -- Additional metadata
    metadata JSON,
    
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    INDEX idx_consent_records_contact_id (contact_id),
    INDEX idx_consent_records_org_id (organization_id),
    INDEX idx_consent_records_campaign_id (campaign_id),
    INDEX idx_consent_records_status (consent_status),
    INDEX idx_consent_records_type (consent_type),
    FOREIGN KEY (contact_id) REFERENCES contacts(id) ON DELETE CASCADE,
    FOREIGN KEY (organization_id) REFERENCES organizations(id) ON DELETE CASCADE,
    FOREIGN KEY (campaign_id) REFERENCES campaigns(id) ON DELETE SET NULL
);

-- Audit logs table - Comprehensive audit trail
CREATE TABLE audit_logs (
    id CHAR(36) PRIMARY KEY DEFAULT (UUID()),
    organization_id CHAR(36),
    user_id CHAR(36),
    
    -- Action details
    entity_type VARCHAR(100) NOT NULL,
    entity_id CHAR(36),
    action ENUM('create', 'read', 'update', 'delete', 'login', 'logout', 'export', 'import', 'send_message', 'approve', 'reject') NOT NULL,
    
    -- Change tracking
    old_values JSON,
    new_values JSON,
    
    -- Request details
    ip_address VARCHAR(45),
    user_agent TEXT,
    session_id VARCHAR(255),
    request_id VARCHAR(255),
    
    -- Additional context
    description TEXT,
    metadata JSON,
    
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    
    INDEX idx_audit_logs_org_id (organization_id),
    INDEX idx_audit_logs_user_id (user_id),
    INDEX idx_audit_logs_entity (entity_type, entity_id),
    INDEX idx_audit_logs_action (action),
    INDEX idx_audit_logs_created_at (created_at),
    INDEX idx_audit_logs_org_created (organization_id, created_at),
    FOREIGN KEY (organization_id) REFERENCES organizations(id) ON DELETE SET NULL,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL
);

-- Compliance violations table - Track and manage violations
CREATE TABLE compliance_violations (
    id CHAR(36) PRIMARY KEY DEFAULT (UUID()),
    organization_id CHAR(36) NOT NULL,
    
    -- Violation details
    violation_type ENUM('unauthorized_message', 'missing_consent', 'content_violation', 'rate_limit_exceeded', 'invalid_opt_out', 'data_breach') NOT NULL,
    severity ENUM('low', 'medium', 'high', 'critical') NOT NULL,
    entity_type VARCHAR(100),
    entity_id CHAR(36),
    
    -- Description and evidence
    title VARCHAR(255) NOT NULL,
    description TEXT NOT NULL,
    evidence JSON,
    
    -- Detection and reporting
    detected_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    detected_by VARCHAR(100),
    detection_method VARCHAR(100),
    reporter_id CHAR(36),
    
    -- Resolution tracking
    status ENUM('open', 'investigating', 'resolved', 'closed') DEFAULT 'open',
    assigned_to CHAR(36),
    resolved_at DATETIME,
    resolved_by CHAR(36),
    resolution_notes TEXT,
    
    -- Follow-up and prevention
    corrective_action TEXT,
    prevention_measures TEXT,
    next_review_date DATETIME,
    
    -- External reporting
    reported_to_authorities BOOLEAN DEFAULT FALSE,
    authority_reference VARCHAR(255),
    reported_at DATETIME,
    
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    INDEX idx_compliance_violations_org_id (organization_id),
    INDEX idx_compliance_violations_status (status),
    INDEX idx_compliance_violations_severity (severity),
    INDEX idx_compliance_violations_type (violation_type),
    INDEX idx_violations_org_status (organization_id, status),
    FOREIGN KEY (organization_id) REFERENCES organizations(id) ON DELETE CASCADE,
    FOREIGN KEY (reporter_id) REFERENCES users(id) ON DELETE SET NULL,
    FOREIGN KEY (assigned_to) REFERENCES users(id) ON DELETE SET NULL,
    FOREIGN KEY (resolved_by) REFERENCES users(id) ON DELETE SET NULL
);

-- =============================================================================
-- API AND INTEGRATION TABLES
-- =============================================================================

-- API keys table - Manage API access
CREATE TABLE api_keys (
    id CHAR(36) PRIMARY KEY DEFAULT (UUID()),
    organization_id CHAR(36) NOT NULL,
    user_id CHAR(36) NOT NULL,
    
    -- Key details
    name VARCHAR(255) NOT NULL,
    key_prefix VARCHAR(20) NOT NULL,
    key_hash VARCHAR(255) NOT NULL,
    
    -- Permissions and limits
    permissions JSON,
    rate_limit_per_minute INT DEFAULT 100,
    rate_limit_per_hour INT DEFAULT 1000,
    rate_limit_per_day INT DEFAULT 10000,
    
    -- IP restrictions
    allowed_ips JSON,
    allowed_domains JSON,
    
    -- Status and expiry
    is_active BOOLEAN DEFAULT TRUE,
    expires_at DATETIME,
    last_used_at DATETIME,
    usage_count INT DEFAULT 0,
    
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    INDEX idx_api_keys_org_id (organization_id),
    INDEX idx_api_keys_user_id (user_id),
    INDEX idx_api_keys_prefix (key_prefix),
    INDEX idx_api_keys_active (is_active),
    FOREIGN KEY (organization_id) REFERENCES organizations(id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

-- Webhooks table - Manage webhook endpoints
CREATE TABLE webhooks (
    id CHAR(36) PRIMARY KEY DEFAULT (UUID()),
    organization_id CHAR(36) NOT NULL,
    
    -- Webhook details
    name VARCHAR(255) NOT NULL,
    url VARCHAR(500) NOT NULL,
    secret VARCHAR(255),
    
    -- Event subscriptions
    events JSON NOT NULL,
    
    -- Configuration
    is_active BOOLEAN DEFAULT TRUE,
    retry_attempts INT DEFAULT 3,
    timeout_seconds INT DEFAULT 30,
    
    -- Headers and authentication
    headers JSON,
    
    -- Status tracking
    last_triggered_at DATETIME,
    last_success_at DATETIME,
    last_failure_at DATETIME,
    consecutive_failures INT DEFAULT 0,
    total_deliveries INT DEFAULT 0,
    successful_deliveries INT DEFAULT 0,
    
    created_by CHAR(36) NOT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    INDEX idx_webhooks_org_id (organization_id),
    INDEX idx_webhooks_active (is_active),
    FOREIGN KEY (organization_id) REFERENCES organizations(id) ON DELETE CASCADE,
    FOREIGN KEY (created_by) REFERENCES users(id)
);

-- Webhook deliveries table - Track webhook delivery attempts
CREATE TABLE webhook_deliveries (
    id CHAR(36) PRIMARY KEY DEFAULT (UUID()),
    webhook_id CHAR(36) NOT NULL,
    
    -- Event details
    event_type VARCHAR(100) NOT NULL,
    event_id CHAR(36) NOT NULL,
    payload JSON NOT NULL,
    
    -- Delivery details
    attempt_number INT NOT NULL DEFAULT 1,
    http_status_code INT,
    response_headers JSON,
    response_body TEXT,
    
    -- Timing
    triggered_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    delivered_at DATETIME,
    duration_ms INT,
    
    -- Status
    success BOOLEAN DEFAULT FALSE,
    error_message TEXT,
    
    -- Retry information
    retry_at DATETIME,
    final_attempt BOOLEAN DEFAULT FALSE,
    
    INDEX idx_webhook_deliveries_webhook_id (webhook_id),
    INDEX idx_webhook_deliveries_event_type (event_type),
    INDEX idx_webhook_deliveries_triggered_at (triggered_at),
    FOREIGN KEY (webhook_id) REFERENCES webhooks(id) ON DELETE CASCADE
);

-- =============================================================================
-- BILLING AND USAGE TRACKING TABLES
-- =============================================================================

-- Billing accounts table - Manage billing information
CREATE TABLE billing_accounts (
    id CHAR(36) PRIMARY KEY DEFAULT (UUID()),
    organization_id CHAR(36) NOT NULL,
    
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
    billing_cycle VARCHAR(20),
    
    -- Usage limits
    monthly_message_limit INT,
    monthly_contact_limit INT,
    team_member_limit INT,
    
    -- Status
    status VARCHAR(20) DEFAULT 'active',
    trial_ends_at DATETIME,
    current_period_start DATETIME,
    current_period_end DATETIME,
    
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    INDEX idx_billing_accounts_org_id (organization_id),
    INDEX idx_billing_accounts_stripe_customer (stripe_customer_id),
    FOREIGN KEY (organization_id) REFERENCES organizations(id) ON DELETE CASCADE
);

-- Usage tracking table - Track usage for billing
CREATE TABLE usage_records (
    id CHAR(36) PRIMARY KEY DEFAULT (UUID()),
    organization_id CHAR(36) NOT NULL,
    billing_account_id CHAR(36),
    
    -- Usage period
    period_start DATETIME NOT NULL,
    period_end DATETIME NOT NULL,
    
    -- Usage metrics
    messages_sent INT DEFAULT 0,
    messages_delivered INT DEFAULT 0,
    messages_failed INT DEFAULT 0,
    total_message_cost DECIMAL(10,4) DEFAULT 0,
    
    contacts_added INT DEFAULT 0,
    contacts_active INT DEFAULT 0,
    
    phone_numbers_active INT DEFAULT 0,
    phone_number_costs DECIMAL(10,4) DEFAULT 0,
    
    api_calls INT DEFAULT 0,
    webhook_deliveries INT DEFAULT 0,
    
    -- Additional charges
    overages JSON,
    additional_charges DECIMAL(10,2) DEFAULT 0,
    
    -- Status
    billed BOOLEAN DEFAULT FALSE,
    invoice_id VARCHAR(255),
    
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    UNIQUE KEY uk_org_period (organization_id, period_start, period_end),
    INDEX idx_usage_records_org_id (organization_id),
    INDEX idx_usage_records_billing_account (billing_account_id),
    INDEX idx_usage_records_period (period_start, period_end),
    FOREIGN KEY (organization_id) REFERENCES organizations(id) ON DELETE CASCADE,
    FOREIGN KEY (billing_account_id) REFERENCES billing_accounts(id) ON DELETE SET NULL
);

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
        WHEN c.last_response_at > DATE_SUB(c.last_message_sent_at, INTERVAL 7 DAY) THEN 'active'
        WHEN c.last_message_sent_at > DATE_SUB(NOW(), INTERVAL 30 DAY) THEN 'inactive'
        ELSE 'dormant'
    END as engagement_status
FROM contacts c
JOIN organizations o ON c.organization_id = o.id
WHERE c.deleted_at IS NULL;

-- View for message analytics
CREATE VIEW message_analytics AS
SELECT 
    DATE(created_at) as date,
    organization_id,
    campaign_id,
    COUNT(*) as total_messages,
    COUNT(CASE WHEN status = 'delivered' THEN 1 END) as delivered_messages,
    COUNT(CASE WHEN status = 'failed' THEN 1 END) as failed_messages,
    COUNT(CASE WHEN direction = 'inbound' THEN 1 END) as inbound_messages,
    COUNT(CASE WHEN direction = 'outbound' THEN 1 END) as outbound_messages,
    SUM(price) as total_cost
FROM messages
GROUP BY DATE(created_at), organization_id, campaign_id;

-- =============================================================================
-- STORED PROCEDURES FOR COMMON OPERATIONS
-- =============================================================================

DELIMITER //

-- Procedure to update contact engagement metrics
CREATE PROCEDURE UpdateContactEngagement(IN contact_id_param CHAR(36))
BEGIN
    DECLARE total_sent INT DEFAULT 0;
    DECLARE total_delivered INT DEFAULT 0;
    DECLARE total_failed INT DEFAULT 0;
    DECLARE last_sent DATETIME;
    DECLARE last_delivered DATETIME;
    
    -- Calculate message statistics
    SELECT 
        COUNT(*),
        COUNT(CASE WHEN status = 'delivered' THEN 1 END),
        COUNT(CASE WHEN status = 'failed' THEN 1 END),
        MAX(sent_at),
        MAX(delivered_at)
    INTO total_sent, total_delivered, total_failed, last_sent, last_delivered
    FROM messages 
    WHERE contact_id = contact_id_param;
    
    -- Update contact record
    UPDATE contacts 
    SET 
        total_messages_sent = total_sent,
        total_messages_delivered = total_delivered,
        total_messages_failed = total_failed,
        last_message_sent_at = last_sent,
        last_message_delivered_at = last_delivered,
        updated_at = CURRENT_TIMESTAMP
    WHERE id = contact_id_param;
END//

-- Procedure to update contact list counts
CREATE PROCEDURE UpdateContactListCounts(IN list_id_param CHAR(36))
BEGIN
    DECLARE total_count INT DEFAULT 0;
    DECLARE active_count INT DEFAULT 0;
    DECLARE opted_in_count INT DEFAULT 0;
    
    -- Calculate counts
    SELECT 
        COUNT(*),
        COUNT(CASE WHEN c.deleted_at IS NULL THEN 1 END),
        COUNT(CASE WHEN c.opted_in = TRUE AND c.deleted_at IS NULL THEN 1 END)
    INTO total_count, active_count, opted_in_count
    FROM contact_list_memberships clm
    JOIN contacts c ON clm.contact_id = c.id
    WHERE clm.contact_list_id = list_id_param
    AND clm.status = 'active';
    
    -- Update contact list
    UPDATE contact_lists 
    SET 
        total_contacts = total_count,
        active_contacts = active_count,
        opted_in_contacts = opted_in_count,
        updated_at = CURRENT_TIMESTAMP
    WHERE id = list_id_param;
END//

DELIMITER ;

-- =============================================================================
-- TRIGGERS FOR AUTOMATIC UPDATES
-- =============================================================================

DELIMITER //

-- Trigger to update contact engagement when messages are inserted/updated
CREATE TRIGGER tr_messages_after_insert 
AFTER INSERT ON messages
FOR EACH ROW
BEGIN
    IF NEW.contact_id IS NOT NULL THEN
        CALL UpdateContactEngagement(NEW.contact_id);
    END IF;
END//

CREATE TRIGGER tr_messages_after_update 
AFTER UPDATE ON messages
FOR EACH ROW
BEGIN
    IF NEW.contact_id IS NOT NULL THEN
        CALL UpdateContactEngagement(NEW.contact_id);
    END IF;
END//

-- Trigger to update contact list counts when memberships change
CREATE TRIGGER tr_contact_list_memberships_after_insert 
AFTER INSERT ON contact_list_memberships
FOR EACH ROW
BEGIN
    CALL UpdateContactListCounts(NEW.contact_list_id);
END//

CREATE TRIGGER tr_contact_list_memberships_after_delete 
AFTER DELETE ON contact_list_memberships
FOR EACH ROW
BEGIN
    CALL UpdateContactListCounts(OLD.contact_list_id);
END//

-- Trigger to update contact list counts when contact opt-in status changes
CREATE TRIGGER tr_contacts_after_update 
AFTER UPDATE ON contacts
FOR EACH ROW
BEGIN
    IF OLD.opted_in != NEW.opted_in THEN
        -- Update all lists this contact belongs to
        UPDATE contact_lists cl
        SET 
            opted_in_contacts = (
                SELECT COUNT(*)
                FROM contact_list_memberships clm
                JOIN contacts c ON clm.contact_id = c.id
                WHERE clm.contact_list_id = cl.id
                AND c.opted_in = TRUE
                AND c.deleted_at IS NULL
                AND clm.status = 'active'
            ),
            updated_at = CURRENT_TIMESTAMP
        WHERE cl.id IN (
            SELECT contact_list_id 
            FROM contact_list_memberships 
            WHERE contact_id = NEW.id AND status = 'active'
        );
    END IF;
END//

DELIMITER ;

-- =============================================================================
-- INITIAL DATA AND CONFIGURATION
-- =============================================================================

-- Insert initial configuration data
INSERT INTO organizations (id, legal_name, display_name, business_type, industry, website_url, verification_status) 
VALUES (
    UUID(),
    'Platform Administrator',
    'Admin Organization',
    'corporation',
    'Technology',
    'https://admin.smsplatform.com',
    'verified'
);

-- =============================================================================
-- SCHEMA VALIDATION AND CONSTRAINTS
-- =============================================================================

-- Add check constraints for data validation where MySQL supports them
-- Note: MySQL 8.0+ supports CHECK constraints

-- Email format validation
ALTER TABLE users ADD CONSTRAINT chk_users_email_format 
CHECK (email REGEXP '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$');

-- Phone format validation
ALTER TABLE users ADD CONSTRAINT chk_users_phone_format 
CHECK (phone_number IS NULL OR phone_number REGEXP '^\\+?[1-9][0-9]{1,14}$');

ALTER TABLE contacts ADD CONSTRAINT chk_contacts_phone_format 
CHECK (phone_number REGEXP '^\\+?[1-9][0-9]{1,14}$');

-- Price validation
ALTER TABLE messages ADD CONSTRAINT chk_messages_price_positive 
CHECK (price IS NULL OR price >= 0);

-- Website URL validation
ALTER TABLE brands ADD CONSTRAINT chk_brands_website_format 
CHECK (website REGEXP '^https?://');

-- Usage period validation
ALTER TABLE usage_records ADD CONSTRAINT chk_usage_records_period_valid 
CHECK (period_end > period_start);

-- =============================================================================
-- SCHEMA METADATA
-- =============================================================================

-- Schema version tracking
CREATE TABLE schema_migrations (
    version VARCHAR(255) PRIMARY KEY,
    applied_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO schema_migrations (version) VALUES ('1.0.0_mysql_initial_schema');

-- =============================================================================
-- PERFORMANCE ANALYSIS QUERIES
-- =============================================================================

-- Table sizes and index usage analysis
/*
SELECT 
    TABLE_NAME,
    TABLE_ROWS,
    DATA_LENGTH,
    INDEX_LENGTH,
    (DATA_LENGTH + INDEX_LENGTH) as TOTAL_SIZE
FROM information_schema.TABLES 
WHERE TABLE_SCHEMA = 'sms_platform'
ORDER BY (DATA_LENGTH + INDEX_LENGTH) DESC;

-- Index usage statistics
SELECT 
    TABLE_SCHEMA,
    TABLE_NAME,
    INDEX_NAME,
    SEQ_IN_INDEX,
    COLUMN_NAME,
    CARDINALITY
FROM information_schema.STATISTICS 
WHERE TABLE_SCHEMA = 'sms_platform'
ORDER BY TABLE_NAME, INDEX_NAME, SEQ_IN_INDEX;
*/

-- =============================================================================
-- END OF MYSQL SCHEMA
-- =============================================================================
# 10DLC SMS Platform - System Architecture

## Architecture Overview

This document details the technical architecture for the 10DLC SMS platform, providing a comprehensive view of system components, data flow, and integration patterns.

## Table of Contents

1. [High-Level Architecture](#high-level-architecture)
2. [Component Architecture](#component-architecture)
3. [Data Architecture](#data-architecture)
4. [Integration Architecture](#integration-architecture)
5. [Security Architecture](#security-architecture)
6. [Deployment Architecture](#deployment-architecture)
7. [Scalability Considerations](#scalability-considerations)

## High-Level Architecture

### System Overview Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                        Internet/CDN                            │
│                    (Cloudflare/AWS CloudFront)                 │
└─────────────────────────┬───────────────────────────────────────┘
                          │
┌─────────────────────────▼───────────────────────────────────────┐
│                    Load Balancer                               │
│              (AWS ALB/NGINX/HAProxy)                           │
└─────────┬───────────────────────────────────────┬───────────────┘
          │                                       │
┌─────────▼─────────┐                   ┌─────────▼─────────┐
│   Web Frontend    │                   │   API Gateway     │
│     (Angular)     │                   │   (Express.js)    │
│                   │                   │                   │
│ ┌───────────────┐ │                   │ ┌───────────────┐ │
│ │   Dashboard   │ │                   │ │ Rate Limiting │ │
│ │   Campaign    │ │                   │ │ Authentication│ │
│ │   Analytics   │ │                   │ │ Request Routing│ │
│ │   Admin Panel │ │                   │ │ Error Handling│ │
│ └───────────────┘ │                   │ └───────────────┘ │
└───────────────────┘                   └─────────┬─────────┘
                                                  │
┌─────────────────────────────────────────────────▼─────────────────────────────────────────────┐
│                                Microservices Layer                                              │
│                                                                                                 │
│  ┌─────────────┐ ┌─────────────┐ ┌─────────────┐ ┌─────────────┐ ┌─────────────┐              │
│  │    Auth     │ │   User      │ │   Brand     │ │  Campaign   │ │     SMS     │              │
│  │   Service   │ │  Service    │ │  Service    │ │   Service   │ │   Service   │              │
│  │             │ │             │ │             │ │             │ │             │              │
│  │ • JWT Auth  │ │ • Profile   │ │ • TCR API   │ │ • Creation  │ │ • Twilio    │              │
│  │ • MFA       │ │ • Org Mgmt  │ │ • Branding  │ │ • Approval  │ │ • Delivery  │              │
│  │ • RBAC      │ │ • Teams     │ │ • Verify    │ │ • Templates │ │ • Webhooks  │              │
│  └─────────────┘ └─────────────┘ └─────────────┘ └─────────────┘ └─────────────┘              │
│                                                                                                 │
│  ┌─────────────┐ ┌─────────────┐ ┌─────────────┐ ┌─────────────┐ ┌─────────────┐              │
│  │  Contact    │ │ Compliance  │ │  Analytics  │ │Notification │ │   Billing   │              │
│  │   Service   │ │   Service   │ │   Service   │ │   Service   │ │   Service   │              │
│  │             │ │             │ │             │ │             │ │             │              │
│  │ • Lists     │ │ • Consent   │ │ • Reports   │ │ • Email     │ │ • Stripe    │              │
│  │ • Import    │ │ • Audit     │ │ • Metrics   │ │ • SMS       │ │ • Usage     │              │
│  │ • Opt-in/out│ │ • Violations│ │ • Real-time │ │ • Alerts    │ │ • Invoicing │              │
│  └─────────────┘ └─────────────┘ └─────────────┘ └─────────────┘ └─────────────┘              │
└─────────────────────────────────────────────────┬───────────────────────────────────────────────┘
                                                  │
┌─────────────────────────────────────────────────▼─────────────────────────────────────────────┐
│                                  Message Queue Layer                                            │
│                                                                                                 │
│  ┌─────────────┐ ┌─────────────┐ ┌─────────────┐ ┌─────────────┐ ┌─────────────┐              │
│  │    Redis    │ │   Apache    │ │   RabbitMQ  │ │    Bull     │ │  WebSocket  │              │
│  │   Pub/Sub   │ │    Kafka    │ │             │ │   Queue     │ │   Service   │              │
│  │             │ │             │ │             │ │             │ │             │              │
│  │ • Real-time │ │ • Event     │ │ • Reliable  │ │ • Job       │ │ • Live      │              │
│  │ • Caching   │ │   Streaming │ │   Delivery  │ │   Queue     │ │   Updates   │              │
│  │ • Sessions  │ │ • Analytics │ │ • Routing   │ │ • Retry     │ │ • Alerts    │              │
│  └─────────────┘ └─────────────┘ └─────────────┘ └─────────────┘ └─────────────┘              │
└─────────────────────────────────────────────────┬───────────────────────────────────────────────┘
                                                  │
┌─────────────────────────────────────────────────▼─────────────────────────────────────────────┐
│                                    Data Layer                                                   │
│                                                                                                 │
│  ┌─────────────┐ ┌─────────────┐ ┌─────────────┐ ┌─────────────┐ ┌─────────────┐              │
│  │    MySQL    │ │    Redis    │ │ Elasticsearch│ │   AWS S3    │ │   MongoDB   │              │
│  │  (Primary)  │ │   (Cache)   │ │   (Search)  │ │ (Files/CDN) │ │   (Logs)    │              │
│  │             │ │             │ │             │ │             │ │             │              │
│  │ • Users     │ │ • Sessions  │ │ • Messages  │ │ • Documents │ │ • Audit     │              │
│  │ • Brands    │ │ • API Cache │ │ • Analytics │ │ • Media     │ │ • Events    │              │
│  │ • Campaigns │ │ • Rate      │ │ • Full Text │ │ • Backups   │ │ • Metrics   │              │
│  │ • Messages  │ │   Limiting  │ │   Search    │ │ • Reports   │ │ • App Logs  │              │
│  │ • Contacts  │ │ • Job Queue │ │ • Dashboards│ │ • Static    │ │ • Error     │              │
│  └─────────────┘ └─────────────┘ └─────────────┘ └─────────────┘ └─────────────┘              │
└─────────────────────────────────────────────────────────────────────────────────────────────────┘
```

### External Integration Layer

```
┌─────────────────────────────────────────────────────────────────┐
│                    External Services                           │
│                                                                 │
│  ┌─────────────┐ ┌─────────────┐ ┌─────────────┐               │
│  │   Twilio    │ │     TCR     │ │   Stripe    │               │
│  │   SMS API   │ │   Registry  │ │   Payment   │               │
│  │             │ │             │ │             │               │
│  │ • Messages  │ │ • Brand Reg │ │ • Billing   │               │
│  │ • Numbers   │ │ • Campaigns │ │ • Usage     │               │
│  │ • Webhooks  │ │ • Approvals │ │ • Invoices  │               │
│  └─────────────┘ └─────────────┘ └─────────────┘               │
│                                                                 │
│  ┌─────────────┐ ┌─────────────┐ ┌─────────────┐               │
│  │  SendGrid   │ │   AWS SES   │ │  Analytics  │               │
│  │    Email    │ │    Email    │ │   Services  │               │
│  │             │ │             │ │             │               │
│  │ • Transact  │ │ • Bulk Mail │ │ • Segment   │               │
│  │ • Marketing │ │ • Templates │ │ • Mixpanel  │               │
│  │ • Templates │ │ • Delivery  │ │ • Amplitude │               │
│  └─────────────┘ └─────────────┘ └─────────────┘               │
└─────────────────────────────────────────────────────────────────┘
```

## Component Architecture

### Frontend Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                    Frontend Architecture                       │
│                        (Angular)                              │
└─────────────────────────┬───────────────────────────────────────┘
                          │
┌─────────────────────────▼───────────────────────────────────────┐
│                     App Shell                                  │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │                Navigation & Layout                      │   │
│  │  • Header with user menu                               │   │
│  │  • Sidebar navigation                                  │   │
│  │  • Breadcrumb navigation                               │   │
│  │  • Footer with links                                   │   │
│  └─────────────────────────────────────────────────────────┘   │
└─────────────────────────┬───────────────────────────────────────┘
                          │
┌─────────────────────────▼───────────────────────────────────────┐
│                     Angular Components                         │
│                                                                 │
│  ┌─────────────┐ ┌─────────────┐ ┌─────────────┐               │
│  │ Dashboard   │ │    Users    │ │    Brands   │               │
│  │ Component   │ │  Component  │ │  Component  │               │
│  │             │ │             │ │             │               │
│  │ • Metrics   │ │ • Profile   │ │ • Register  │               │
│  │ • Charts    │ │ • Teams     │ │ • Manage    │               │
│  │ • Recent    │ │ • Settings  │ │ • Verify    │               │
│  └─────────────┘ └─────────────┘ └─────────────┘               │
│                                                                 │
│  ┌─────────────┐ ┌─────────────┐ ┌─────────────┐               │
│  │ Campaigns   │ │  Messages   │ │  Contacts   │               │
│  │ Component   │ │  Component  │ │  Component  │               │
│  │             │ │             │ │             │               │
│  │ • Create    │ │ • Compose   │ │ • Lists     │               │
│  │ • Manage    │ │ • Schedule  │ │ • Import    │               │
│  │ • Analytics │ │ • Track     │ │ • Segments  │               │
│  └─────────────┘ └─────────────┘ └─────────────┘               │
└─────────────────────────┬───────────────────────────────────────┘
                          │
┌─────────────────────────▼───────────────────────────────────────┐
│                    Shared Components                           │
│                                                                 │
│  ┌─────────────┐ ┌─────────────┐ ┌─────────────┐               │
│  │  UI Kit     │ │   Forms     │ │   Charts    │               │
│  │ Components  │ │ Components  │ │ Components  │               │
│  │             │ │             │ │             │               │
│  │ • Buttons   │ │ • Inputs    │ │ • Line      │               │
│  │ • Cards     │ │ • Validation│ │ • Bar       │               │
│  │ • Modals    │ │ • Upload    │ │ • Pie       │               │
│  │ • Tables    │ │ • Multi-step│ │ • Real-time │               │
│  └─────────────┘ └─────────────┘ └─────────────┘               │
└─────────────────────────┬───────────────────────────────────────┘
                          │
┌─────────────────────────▼───────────────────────────────────────┐
│                    State Management                            │
│                                                                 │
│  ┌─────────────┐ ┌─────────────┐ ┌─────────────┐               │
│  │    NgRx     │ │ HTTP Client │ │  Reactive   │               │
│  │    Store    │ │   Service   │ │    Forms    │               │
│  │             │ │             │ │             │               │
│  │ • Auth      │ │ • API Data  │ │ • Form      │               │
│  │ • User      │ │ • Caching   │ │   State     │               │
│  │ • UI State  │ │ • HTTP Ops  │ │ • Validation│               │
│  └─────────────┘ └─────────────┘ └─────────────┘               │
└─────────────────────────────────────────────────────────────────┘
```

### Backend Microservices Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                   Authentication Service                       │
│                                                                 │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │                     Auth Controller                     │   │
│  │  • Login/Logout endpoints                              │   │
│  │  • Registration endpoints                              │   │
│  │  • Password reset endpoints                            │   │
│  │  • MFA endpoints                                       │   │
│  └─────────────────────────────────────────────────────────┘   │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │                     Auth Service                        │   │
│  │  • JWT token generation/validation                     │   │
│  │  • Password hashing/verification                       │   │
│  │  • MFA setup and verification                          │   │
│  │  • Session management                                  │   │
│  └─────────────────────────────────────────────────────────┘   │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │                     Auth Repository                     │   │
│  │  • User data access                                    │   │
│  │  • Session storage                                     │   │
│  │  • Security logs                                       │   │
│  └─────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│                      User Service                              │
│                                                                 │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │                     User Controller                     │   │
│  │  • Profile management endpoints                        │   │
│  │  • Organization management endpoints                   │   │
│  │  • Team management endpoints                           │   │
│  │  • Permission management endpoints                     │   │
│  └─────────────────────────────────────────────────────────┘   │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │                     User Service                        │   │
│  │  • Profile operations                                  │   │
│  │  • Organization operations                             │   │
│  │  • Role-based access control                           │   │
│  │  • Invitation management                               │   │
│  └─────────────────────────────────────────────────────────┘   │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │                     User Repository                     │   │
│  │  • User CRUD operations                                │   │
│  │  • Organization CRUD operations                        │   │
│  │  • Permission queries                                  │   │
│  └─────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│                      Brand Service                             │
│                                                                 │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │                     Brand Controller                    │   │
│  │  • Brand registration endpoints                        │   │
│  │  • Brand verification endpoints                        │   │
│  │  • Brand status endpoints                              │   │
│  │  • TCR integration endpoints                           │   │
│  └─────────────────────────────────────────────────────────┘   │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │                     Brand Service                       │   │
│  │  • Brand lifecycle management                          │   │
│  │  • TCR API integration                                 │   │
│  │  • Verification workflows                              │   │
│  │  • Compliance tracking                                 │   │
│  └─────────────────────────────────────────────────────────┘   │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │                  TCR Integration                        │   │
│  │  • Brand registration API calls                        │   │
│  │  • Status polling                                      │   │
│  │  • Webhook handling                                    │   │
│  │  • Error handling and retry                            │   │
│  └─────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│                    Campaign Service                            │
│                                                                 │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │                  Campaign Controller                    │   │
│  │  • Campaign creation endpoints                         │   │
│  │  • Campaign management endpoints                       │   │
│  │  • Template management endpoints                       │   │
│  │  • Approval workflow endpoints                         │   │
│  └─────────────────────────────────────────────────────────┘   │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │                   Campaign Service                      │   │
│  │  • Campaign lifecycle management                       │   │
│  │  • Template management                                 │   │
│  │  • Use case validation                                 │   │
│  │  • Approval workflows                                  │   │
│  └─────────────────────────────────────────────────────────┘   │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │                Template Engine                          │   │
│  │  • Message template processing                         │   │
│  │  • Variable substitution                               │   │
│  │  • Content validation                                  │   │
│  │  • A/B testing support                                 │   │
│  └─────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│                      SMS Service                               │
│                                                                 │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │                    SMS Controller                       │   │
│  │  • Message sending endpoints                           │   │
│  │  • Message status endpoints                            │   │
│  │  • Webhook endpoints                                   │   │
│  │  • Bulk sending endpoints                              │   │
│  └─────────────────────────────────────────────────────────┘   │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │                    SMS Service                          │   │
│  │  • Message processing                                  │   │
│  │  • Queue management                                    │   │
│  │  • Delivery tracking                                   │   │
│  │  • Rate limiting                                       │   │
│  └─────────────────────────────────────────────────────────┘   │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │                 Twilio Integration                      │   │
│  │  • Message sending API                                 │   │
│  │  • Webhook processing                                  │   │
│  │  • Number management                                   │   │
│  │  • Error handling                                      │   │
│  └─────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────┘
```

## Data Architecture

### Database Schema Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                    Primary Database (PostgreSQL)               │
│                                                                 │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │                   Core Entities                         │   │
│  │                                                         │   │
│  │  users ──────────── user_organizations                 │   │
│  │    │                       │                           │   │
│  │    └────── organizations ───┘                           │   │
│  │                 │                                       │   │
│  │                 └─── brands                             │   │
│  │                        │                               │   │
│  │                        └─── campaigns                   │   │
│  │                                                         │   │
│  │  contacts ────── contact_lists ─── contact_list_memberships │
│  │      │                                                 │   │
│  │      └────── messages ──────── phone_numbers           │   │
│  └─────────────────────────────────────────────────────────┘   │
│                                                                 │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │                 Compliance & Audit                      │   │
│  │                                                         │   │
│  │  consent_records ─── contacts                           │   │
│  │                                                         │   │
│  │  audit_logs ──────── users                              │   │
│  │                                                         │   │
│  │  compliance_violations ── organizations                 │   │
│  │                                                         │   │
│  │  api_keys ────────── users                              │   │
│  └─────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│                     Cache Layer (Redis)                        │
│                                                                 │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │                   Session Store                         │   │
│  │  • User sessions                                        │   │
│  │  • JWT blacklist                                       │   │
│  │  • MFA tokens                                          │   │
│  │  • Password reset tokens                               │   │
│  └─────────────────────────────────────────────────────────┘   │
│                                                                 │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │                 Application Cache                       │   │
│  │  • API response cache                                  │   │
│  │  • Database query cache                                │   │
│  │  • Computed metrics                                    │   │
│  │  • Configuration cache                                 │   │
│  └─────────────────────────────────────────────────────────┘   │
│                                                                 │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │                    Job Queue                           │   │
│  │  • Message sending queue                               │   │
│  │  • Email notifications                                 │   │
│  │  • Report generation                                   │   │
│  │  • Data import/export                                  │   │
│  └─────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│                 Search Engine (Elasticsearch)                  │
│                                                                 │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │                 Message Search                          │   │
│  │  • Full-text message search                            │   │
│  │  • Content filtering                                   │   │
│  │  • Advanced queries                                    │   │
│  │  • Real-time indexing                                  │   │
│  └─────────────────────────────────────────────────────────┘   │
│                                                                 │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │                Analytics Data                           │   │
│  │  • Time-series metrics                                 │   │
│  │  • Aggregated statistics                               │   │
│  │  • Custom dashboards                                   │   │
│  │  • Real-time analytics                                 │   │
│  └─────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────┘
```

### Data Flow Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                       Data Flow Diagram                        │
│                                                                 │
│  User Input ──┐                                                │
│               │                                                │
│  External ────┼──► API Gateway ──► Service Layer               │
│  APIs         │                         │                      │
│               │                         ▼                      │
│  Webhooks ────┘                    Message Queue               │
│                                          │                      │
│                                          ▼                      │
│                                   Background Jobs               │
│                                          │                      │
│                    ┌─────────────────────┼─────────────────────┐│
│                    │                     ▼                     ││
│                    │              Database Layer               ││
│                    │                     │                     ││
│                    │          ┌──────────┼──────────┐          ││
│                    │          │          ▼          │          ││
│                    │          │    Cache Layer      │          ││
│                    │          │          │          │          ││
│                    │          │          ▼          │          ││
│                    │          │   Search Engine     │          ││
│                    │          └─────────────────────┘          ││
│                    └─────────────────────────────────────────────┘│
│                                          │                      │
│                                          ▼                      │
│                                   Analytics ──► Reports         │
│                                          │                      │
│                                          ▼                      │
│                               Real-time Notifications           │
└─────────────────────────────────────────────────────────────────┘
```

## Integration Architecture

### External API Integration Patterns

```
┌─────────────────────────────────────────────────────────────────┐
│                    TCR (The Campaign Registry)                 │
│                                                                 │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │                 Brand Registration                      │   │
│  │                                                         │   │
│  │  Application ──┐                                        │   │
│  │                │                                        │   │
│  │                ▼                                        │   │
│  │  Brand Service ──► TCR API ──► Brand Registry           │   │
│  │                ▲                        │               │   │
│  │                │                        ▼               │   │
│  │                └──── Webhook ←──── Status Updates      │   │
│  └─────────────────────────────────────────────────────────┘   │
│                                                                 │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │                Campaign Registration                    │   │
│  │                                                         │   │
│  │  Application ──┐                                        │   │
│  │                │                                        │   │
│  │                ▼                                        │   │
│  │  Campaign Service ──► TCR API ──► Campaign Registry     │   │
│  │                ▲                        │               │   │
│  │                │                        ▼               │   │
│  │                └──── Webhook ←──── Approval Status     │   │
│  └─────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│                        Twilio Integration                      │
│                                                                 │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │                 Message Sending                         │   │
│  │                                                         │   │
│  │  SMS Service ──► Message Queue ──► Twilio API           │   │
│  │       │                                  │              │   │
│  │       ▼                                  ▼              │   │
│  │  Database ◄───── Status Updates ◄──── Webhooks        │   │
│  └─────────────────────────────────────────────────────────┘   │
│                                                                 │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │                Number Management                        │   │
│  │                                                         │   │
│  │  Phone Service ──► Twilio API ──► Number Provisioning   │   │
│  │       │                                  │              │   │
│  │       ▼                                  ▼              │   │
│  │  Database ◄────── Webhooks ◄──── Number Events         │   │
│  └─────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│                     Payment Integration                        │
│                                                                 │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │                   Stripe Integration                    │   │
│  │                                                         │   │
│  │  Billing Service ──► Stripe API ──► Payment Processing │   │
│  │        │                                │               │   │
│  │        ▼                                ▼               │   │
│  │  Database ◄────── Webhooks ◄──── Payment Events        │   │
│  │        │                                                │   │
│  │        ▼                                                │   │
│  │  Invoice Generation                                     │   │
│  └─────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────┘
```

### Event-Driven Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                     Event Streaming (Kafka)                    │
│                                                                 │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │                    Event Topics                         │   │
│  │                                                         │   │
│  │  • user.created                                         │   │
│  │  • user.updated                                         │   │
│  │  • brand.registered                                     │   │
│  │  • brand.approved                                       │   │
│  │  • campaign.created                                     │   │
│  │  • campaign.approved                                    │   │
│  │  • message.sent                                         │   │
│  │  • message.delivered                                    │   │
│  │  • message.failed                                       │   │
│  │  • contact.opted_in                                     │   │
│  │  • contact.opted_out                                    │   │
│  │  • compliance.violation                                 │   │
│  └─────────────────────────────────────────────────────────┘   │
│                                                                 │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │                 Event Consumers                         │   │
│  │                                                         │   │
│  │  Analytics Service ──► Real-time Metrics               │   │
│  │  Notification Service ──► Email/SMS Alerts             │   │
│  │  Audit Service ──► Compliance Tracking                 │   │
│  │  Billing Service ──► Usage Tracking                    │   │
│  │  Reporting Service ──► Data Aggregation                │   │
│  └─────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────┘
```

## Security Architecture

### Authentication & Authorization Flow

```
┌─────────────────────────────────────────────────────────────────┐
│                   Authentication Flow                          │
│                                                                 │
│  Client ──► Login Request ──► API Gateway                      │
│             (credentials)           │                           │
│                                     ▼                           │
│                            Auth Service                         │
│                                     │                           │
│                            ┌────────▼────────┐                 │
│                            │ Password Verify │                 │
│                            │ MFA Validation  │                 │
│                            │ Rate Limiting   │                 │
│                            └────────┬────────┘                 │
│                                     │                           │
│                                     ▼                           │
│                            JWT Token Generation                 │
│                                     │                           │
│  Client ◄── JWT Token ◄────────────┘                           │
│             (+ Refresh Token)                                   │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│                   Authorization Flow                           │
│                                                                 │
│  Client ──► API Request ──► API Gateway                        │
│             (+ JWT Token)           │                           │
│                                     ▼                           │
│                            Token Validation                     │
│                                     │                           │
│                            ┌────────▼────────┐                 │
│                            │ JWT Verify      │                 │
│                            │ Token Blacklist │                 │
│                            │ User Status     │                 │
│                            └────────┬────────┘                 │
│                                     │                           │
│                                     ▼                           │
│                            RBAC Authorization                   │
│                                     │                           │
│                            ┌────────▼────────┐                 │
│                            │ Role Check      │                 │
│                            │ Permission Check│                 │
│                            │ Resource Access │                 │
│                            └────────┬────────┘                 │
│                                     │                           │
│  Client ◄── Response ◄──────────────┘                          │
│             (Success/Deny)                                      │
└─────────────────────────────────────────────────────────────────┘
```

### Data Security Layers

```
┌─────────────────────────────────────────────────────────────────┐
│                     Security Layers                            │
│                                                                 │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │                Network Security                         │   │
│  │  • VPC with private subnets                            │   │
│  │  • Security groups and NACLs                           │   │
│  │  • WAF protection                                      │   │
│  │  • DDoS protection                                     │   │
│  └─────────────────────────────────────────────────────────┘   │
│                                 │                               │
│  ┌─────────────────────────────▼───────────────────────────┐   │
│  │                Application Security                     │   │
│  │  • HTTPS/TLS 1.3 enforcement                          │   │
│  │  • API rate limiting                                   │   │
│  │  • Input validation and sanitization                   │   │
│  │  • CORS configuration                                  │   │
│  └─────────────────────────────────────────────────────────┘   │
│                                 │                               │
│  ┌─────────────────────────────▼───────────────────────────┐   │
│  │                  Data Security                          │   │
│  │  • AES-256 encryption at rest                          │   │
│  │  • Column-level encryption for PII                     │   │
│  │  • Encrypted database connections                      │   │
│  │  • Key rotation policies                               │   │
│  └─────────────────────────────────────────────────────────┘   │
│                                 │                               │
│  ┌─────────────────────────────▼───────────────────────────┐   │
│  │                Monitoring & Compliance                 │   │
│  │  • Real-time security monitoring                       │   │
│  │  • Audit logging                                       │   │
│  │  • Compliance reporting                                │   │
│  │  • Incident response                                   │   │
│  └─────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────┘
```

## Deployment Architecture

### Kubernetes Deployment Structure

```
┌─────────────────────────────────────────────────────────────────┐
│                    Kubernetes Cluster                          │
│                                                                 │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │                   Ingress Layer                         │   │
│  │                                                         │   │
│  │  ┌─────────────┐ ┌─────────────┐ ┌─────────────┐       │   │
│  │  │   Ingress   │ │   Ingress   │ │   Ingress   │       │   │
│  │  │ Controller  │ │    TLS      │ │   Rules     │       │   │
│  │  │   (Nginx)   │ │   Certs     │ │  (Routes)   │       │   │
│  │  └─────────────┘ └─────────────┘ └─────────────┘       │   │
│  └─────────────────────────────────────────────────────────┘   │
│                                │                                │
│  ┌─────────────────────────────▼───────────────────────────┐   │
│  │                   Service Layer                         │   │
│  │                                                         │   │
│  │  ┌─────────────┐ ┌─────────────┐ ┌─────────────┐       │   │
│  │  │    API      │ │   Frontend  │ │    Admin    │       │   │
│  │  │  Gateway    │ │   Service   │ │   Service   │       │   │
│  │  │ LoadBalancer│ │ ClusterIP   │ │ ClusterIP   │       │   │
│  │  └─────────────┘ └─────────────┘ └─────────────┘       │   │
│  └─────────────────────────────────────────────────────────┘   │
│                                │                                │
│  ┌─────────────────────────────▼───────────────────────────┐   │
│  │                 Application Pods                        │   │
│  │                                                         │   │
│  │  ┌─────────────┐ ┌─────────────┐ ┌─────────────┐       │   │
│  │  │    Auth     │ │    User     │ │    Brand    │       │   │
│  │  │   Service   │ │   Service   │ │   Service   │       │   │
│  │  │   Pods      │ │    Pods     │ │    Pods     │       │   │
│  │  └─────────────┘ └─────────────┘ └─────────────┘       │   │
│  │                                                         │   │
│  │  ┌─────────────┐ ┌─────────────┐ ┌─────────────┐       │   │
│  │  │  Campaign   │ │     SMS     │ │  Contact    │       │   │
│  │  │   Service   │ │   Service   │ │   Service   │       │   │
│  │  │    Pods     │ │    Pods     │ │    Pods     │       │   │
│  │  └─────────────┘ └─────────────┘ └─────────────┘       │   │
│  └─────────────────────────────────────────────────────────┘   │
│                                │                                │
│  ┌─────────────────────────────▼───────────────────────────┐   │
│  │                  Data Layer                             │   │
│  │                                                         │   │
│  │  ┌─────────────┐ ┌─────────────┐ ┌─────────────┐       │   │
│  │  │ PostgreSQL  │ │    Redis    │ │Elasticsearch│       │   │
│  │  │ StatefulSet │ │ StatefulSet │ │ StatefulSet │       │   │
│  │  │ + PVC       │ │    + PVC    │ │    + PVC    │       │   │
│  │  └─────────────┘ └─────────────┘ └─────────────┘       │   │
│  └─────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────┘
```

### Multi-Environment Strategy

```
┌─────────────────────────────────────────────────────────────────┐
│                   Development Environment                      │
│                                                                 │
│  • Single cluster, minimal resources                           │
│  • In-memory databases for testing                             │
│  • Mock external services                                      │
│  • Detailed logging and debugging                              │
│  • Automatic deployments from feature branches                 │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│                    Staging Environment                         │
│                                                                 │
│  • Production-like configuration                               │
│  • Full database instances                                     │
│  • External service integrations                               │
│  • Performance and load testing                                │
│  • Manual deployment approval                                  │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│                   Production Environment                       │
│                                                                 │
│  • Multi-AZ deployment                                         │
│  • High availability configuration                             │
│  • Auto-scaling enabled                                        │
│  • Comprehensive monitoring                                    │
│  • Blue-green deployment strategy                              │
└─────────────────────────────────────────────────────────────────┘
```

## Scalability Considerations

### Horizontal Scaling Strategy

```
┌─────────────────────────────────────────────────────────────────┐
│                      Auto-scaling Policies                     │
│                                                                 │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │                  Application Layer                      │   │
│  │                                                         │   │
│  │  • CPU-based scaling (target: 70%)                     │   │
│  │  • Memory-based scaling (target: 80%)                  │   │
│  │  • Custom metrics scaling (API response time)          │   │
│  │  • Scheduled scaling for peak hours                    │   │
│  │  • Min replicas: 2, Max replicas: 50                   │   │
│  └─────────────────────────────────────────────────────────┘   │
│                                                                 │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │                   Database Layer                        │   │
│  │                                                         │   │
│  │  • Read replicas for read-heavy workloads              │   │
│  │  • Connection pooling and optimization                 │   │
│  │  • Partitioning for large tables                       │   │
│  │  • Caching layer for frequently accessed data          │   │
│  └─────────────────────────────────────────────────────────┘   │
│                                                                 │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │                   Message Queue                         │   │
│  │                                                         │   │
│  │  • Multiple consumer groups                             │   │
│  │  • Partition-based scaling                              │   │
│  │  • Dead letter queues for error handling               │   │
│  │  • Rate limiting and backpressure                      │   │
│  └─────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────┘
```

### Performance Optimization

```
┌─────────────────────────────────────────────────────────────────┐
│                   Performance Optimizations                    │
│                                                                 │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │                   Frontend Layer                        │   │
│  │                                                         │   │
│  │  • Code splitting and lazy loading                     │   │
│  │  • CDN for static assets                               │   │
│  │  • Browser caching strategies                          │   │
│  │  • Image optimization and compression                  │   │
│  │  • Service workers for offline support                 │   │
│  └─────────────────────────────────────────────────────────┘   │
│                                                                 │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │                   Backend Layer                         │   │
│  │                                                         │   │
│  │  • API response caching                                │   │
│  │  • Database query optimization                         │   │
│  │  • Connection pooling                                  │   │
│  │  • Asynchronous processing                             │   │
│  │  • Compression for API responses                       │   │
│  └─────────────────────────────────────────────────────────┘   │
│                                                                 │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │                    Data Layer                           │   │
│  │                                                         │   │
│  │  • Indexing strategies                                 │   │
│  │  • Query result caching                                │   │
│  │  • Data archiving for old records                      │   │
│  │  • Batch processing for bulk operations                │   │
│  └─────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────┘
```

---

**Document Version**: 1.0  
**Last Updated**: December 2024  
**Status**: Technical Architecture Specification  
**Next Review Date**: January 2025

This system architecture document provides the technical foundation for implementing the 10DLC SMS platform, ensuring scalability, security, and maintainability throughout the development lifecycle.

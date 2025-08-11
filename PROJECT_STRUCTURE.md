# 10DLC SMS Platform - Project Structure

## Directory Structure

This document outlines the recommended project structure for the 10DLC SMS platform, organizing code, documentation, and configuration files for optimal development workflow.

```
twillio-SMS/
│
├── README.md
├── PROJECT_PROPOSAL.md
├── SYSTEM_ARCHITECTURE.md
├── CONTRIBUTING.md
├── LICENSE
├── .gitignore
├── .env.example
├── docker-compose.yml
├── docker-compose.prod.yml
├── Dockerfile
├── package.json
└── package-lock.json
│
├── docs/                          # Documentation
│   ├── api/                       # API documentation
│   │   ├── authentication.md
│   │   ├── users.md
│   │   ├── brands.md
│   │   ├── campaigns.md
│   │   ├── messages.md
│   │   └── webhooks.md
│   ├── deployment/                # Deployment guides
│   │   ├── local-setup.md
│   │   ├── staging.md
│   │   ├── production.md
│   │   └── kubernetes.md
│   ├── compliance/                # Compliance documentation
│   │   ├── 10dlc-requirements.md
│   │   ├── tcpa-compliance.md
│   │   ├── gdpr-compliance.md
│   │   └── audit-procedures.md
│   └── architecture/              # Technical documentation
│       ├── database-design.md
│       ├── security.md
│       ├── performance.md
│       └── monitoring.md
│
├── frontend/                      # React/Next.js Frontend
│   ├── public/
│   │   ├── favicon.ico
│   │   ├── manifest.json
│   │   └── icons/
│   ├── src/
│   │   ├── components/            # Reusable UI components
│   │   │   ├── ui/                # Basic UI components
│   │   │   │   ├── Button.tsx
│   │   │   │   ├── Input.tsx
│   │   │   │   ├── Modal.tsx
│   │   │   │   ├── Table.tsx
│   │   │   │   └── index.ts
│   │   │   ├── forms/             # Form components
│   │   │   │   ├── LoginForm.tsx
│   │   │   │   ├── RegisterForm.tsx
│   │   │   │   ├── BrandForm.tsx
│   │   │   │   └── CampaignForm.tsx
│   │   │   ├── layout/            # Layout components
│   │   │   │   ├── Header.tsx
│   │   │   │   ├── Sidebar.tsx
│   │   │   │   ├── Footer.tsx
│   │   │   │   └── Layout.tsx
│   │   │   └── charts/            # Chart components
│   │   │       ├── LineChart.tsx
│   │   │       ├── BarChart.tsx
│   │   │       └── PieChart.tsx
│   │   ├── pages/                 # Next.js pages
│   │   │   ├── _app.tsx
│   │   │   ├── _document.tsx
│   │   │   ├── index.tsx
│   │   │   ├── login.tsx
│   │   │   ├── register.tsx
│   │   │   ├── dashboard/
│   │   │   │   ├── index.tsx
│   │   │   │   └── analytics.tsx
│   │   │   ├── brands/
│   │   │   │   ├── index.tsx
│   │   │   │   ├── create.tsx
│   │   │   │   └── [id].tsx
│   │   │   ├── campaigns/
│   │   │   │   ├── index.tsx
│   │   │   │   ├── create.tsx
│   │   │   │   └── [id].tsx
│   │   │   ├── messages/
│   │   │   │   ├── index.tsx
│   │   │   │   ├── compose.tsx
│   │   │   │   └── history.tsx
│   │   │   ├── contacts/
│   │   │   │   ├── index.tsx
│   │   │   │   ├── lists.tsx
│   │   │   │   └── import.tsx
│   │   │   └── admin/
│   │   │       ├── users.tsx
│   │   │       ├── organizations.tsx
│   │   │       └── compliance.tsx
│   │   ├── hooks/                 # Custom React hooks
│   │   │   ├── useAuth.ts
│   │   │   ├── useApi.ts
│   │   │   ├── useLocalStorage.ts
│   │   │   └── useWebSocket.ts
│   │   ├── store/                 # State management
│   │   │   ├── authStore.ts
│   │   │   ├── userStore.ts
│   │   │   ├── brandStore.ts
│   │   │   └── index.ts
│   │   ├── services/              # API services
│   │   │   ├── api.ts
│   │   │   ├── auth.ts
│   │   │   ├── users.ts
│   │   │   ├── brands.ts
│   │   │   ├── campaigns.ts
│   │   │   ├── messages.ts
│   │   │   └── contacts.ts
│   │   ├── utils/                 # Utility functions
│   │   │   ├── validation.ts
│   │   │   ├── formatting.ts
│   │   │   ├── constants.ts
│   │   │   └── helpers.ts
│   │   ├── types/                 # TypeScript type definitions
│   │   │   ├── auth.ts
│   │   │   ├── user.ts
│   │   │   ├── brand.ts
│   │   │   ├── campaign.ts
│   │   │   ├── message.ts
│   │   │   └── api.ts
│   │   └── styles/                # Styling files
│   │       ├── globals.css
│   │       ├── components.css
│   │       └── tailwind.config.js
│   ├── next.config.js
│   ├── tailwind.config.js
│   ├── tsconfig.json
│   ├── package.json
│   └── .env.local.example
│
├── backend/                       # Node.js Backend
│   ├── src/
│   │   ├── config/                # Configuration files
│   │   │   ├── database.ts
│   │   │   ├── redis.ts
│   │   │   ├── kafka.ts
│   │   │   ├── twilio.ts
│   │   │   ├── stripe.ts
│   │   │   └── index.ts
│   │   ├── controllers/           # Route controllers
│   │   │   ├── auth.controller.ts
│   │   │   ├── user.controller.ts
│   │   │   ├── organization.controller.ts
│   │   │   ├── brand.controller.ts
│   │   │   ├── campaign.controller.ts
│   │   │   ├── message.controller.ts
│   │   │   ├── contact.controller.ts
│   │   │   ├── webhook.controller.ts
│   │   │   └── analytics.controller.ts
│   │   ├── services/              # Business logic services
│   │   │   ├── auth.service.ts
│   │   │   ├── user.service.ts
│   │   │   ├── organization.service.ts
│   │   │   ├── brand.service.ts
│   │   │   ├── campaign.service.ts
│   │   │   ├── message.service.ts
│   │   │   ├── contact.service.ts
│   │   │   ├── compliance.service.ts
│   │   │   ├── analytics.service.ts
│   │   │   └── notification.service.ts
│   │   ├── repositories/          # Data access layer
│   │   │   ├── base.repository.ts
│   │   │   ├── user.repository.ts
│   │   │   ├── organization.repository.ts
│   │   │   ├── brand.repository.ts
│   │   │   ├── campaign.repository.ts
│   │   │   ├── message.repository.ts
│   │   │   ├── contact.repository.ts
│   │   │   └── audit.repository.ts
│   │   ├── models/                # Database models
│   │   │   ├── User.ts
│   │   │   ├── Organization.ts
│   │   │   ├── Brand.ts
│   │   │   ├── Campaign.ts
│   │   │   ├── Message.ts
│   │   │   ├── Contact.ts
│   │   │   ├── ContactList.ts
│   │   │   ├── ConsentRecord.ts
│   │   │   └── AuditLog.ts
│   │   ├── middleware/            # Express middleware
│   │   │   ├── auth.middleware.ts
│   │   │   ├── validation.middleware.ts
│   │   │   ├── rateLimit.middleware.ts
│   │   │   ├── cors.middleware.ts
│   │   │   ├── error.middleware.ts
│   │   │   └── logging.middleware.ts
│   │   ├── routes/                # Route definitions
│   │   │   ├── auth.routes.ts
│   │   │   ├── user.routes.ts
│   │   │   ├── organization.routes.ts
│   │   │   ├── brand.routes.ts
│   │   │   ├── campaign.routes.ts
│   │   │   ├── message.routes.ts
│   │   │   ├── contact.routes.ts
│   │   │   ├── webhook.routes.ts
│   │   │   ├── analytics.routes.ts
│   │   │   └── index.ts
│   │   ├── integrations/          # External service integrations
│   │   │   ├── twilio/
│   │   │   │   ├── client.ts
│   │   │   │   ├── sms.service.ts
│   │   │   │   ├── webhook.handler.ts
│   │   │   │   └── types.ts
│   │   │   ├── tcr/
│   │   │   │   ├── client.ts
│   │   │   │   ├── brand.service.ts
│   │   │   │   ├── campaign.service.ts
│   │   │   │   └── types.ts
│   │   │   ├── stripe/
│   │   │   │   ├── client.ts
│   │   │   │   ├── billing.service.ts
│   │   │   │   ├── webhook.handler.ts
│   │   │   │   └── types.ts
│   │   │   └── sendgrid/
│   │   │       ├── client.ts
│   │   │       ├── email.service.ts
│   │   │       └── templates.ts
│   │   ├── utils/                 # Utility functions
│   │   │   ├── validation.ts
│   │   │   ├── encryption.ts
│   │   │   ├── jwt.ts
│   │   │   ├── logger.ts
│   │   │   ├── errors.ts
│   │   │   ├── constants.ts
│   │   │   └── helpers.ts
│   │   ├── types/                 # TypeScript type definitions
│   │   │   ├── auth.types.ts
│   │   │   ├── user.types.ts
│   │   │   ├── brand.types.ts
│   │   │   ├── campaign.types.ts
│   │   │   ├── message.types.ts
│   │   │   ├── api.types.ts
│   │   │   └── common.types.ts
│   │   ├── jobs/                  # Background jobs
│   │   │   ├── message.jobs.ts
│   │   │   ├── email.jobs.ts
│   │   │   ├── compliance.jobs.ts
│   │   │   ├── analytics.jobs.ts
│   │   │   └── cleanup.jobs.ts
│   │   ├── validators/            # Input validation schemas
│   │   │   ├── auth.validator.ts
│   │   │   ├── user.validator.ts
│   │   │   ├── brand.validator.ts
│   │   │   ├── campaign.validator.ts
│   │   │   ├── message.validator.ts
│   │   │   └── contact.validator.ts
│   │   └── app.ts                 # Express app setup
│   ├── tests/                     # Test files
│   │   ├── unit/
│   │   │   ├── services/
│   │   │   ├── controllers/
│   │   │   ├── utils/
│   │   │   └── validators/
│   │   ├── integration/
│   │   │   ├── auth.test.ts
│   │   │   ├── brands.test.ts
│   │   │   ├── campaigns.test.ts
│   │   │   └── messages.test.ts
│   │   ├── e2e/
│   │   │   ├── auth.e2e.test.ts
│   │   │   ├── brand-registration.e2e.test.ts
│   │   │   └── message-sending.e2e.test.ts
│   │   ├── fixtures/
│   │   │   ├── users.json
│   │   │   ├── brands.json
│   │   │   └── campaigns.json
│   │   └── setup.ts
│   ├── migrations/                # Database migrations
│   │   ├── 001_create_users.sql
│   │   ├── 002_create_organizations.sql
│   │   ├── 003_create_brands.sql
│   │   ├── 004_create_campaigns.sql
│   │   ├── 005_create_contacts.sql
│   │   ├── 006_create_messages.sql
│   │   ├── 007_create_audit_logs.sql
│   │   └── 008_create_indexes.sql
│   ├── seeds/                     # Database seeds
│   │   ├── development/
│   │   │   ├── users.sql
│   │   │   ├── organizations.sql
│   │   │   └── test-data.sql
│   │   └── production/
│   │       └── initial-data.sql
│   ├── server.ts                  # Server entry point
│   ├── package.json
│   ├── tsconfig.json
│   ├── jest.config.js
│   └── .env.example
│
├── mobile/                        # React Native Mobile App (Optional)
│   ├── src/
│   │   ├── components/
│   │   ├── screens/
│   │   ├── navigation/
│   │   ├── services/
│   │   ├── hooks/
│   │   ├── utils/
│   │   └── types/
│   ├── android/
│   ├── ios/
│   ├── package.json
│   └── metro.config.js
│
├── infrastructure/                # Infrastructure as Code
│   ├── terraform/
│   │   ├── environments/
│   │   │   ├── development/
│   │   │   │   ├── main.tf
│   │   │   │   ├── variables.tf
│   │   │   │   └── outputs.tf
│   │   │   ├── staging/
│   │   │   └── production/
│   │   ├── modules/
│   │   │   ├── vpc/
│   │   │   ├── rds/
│   │   │   ├── redis/
│   │   │   ├── eks/
│   │   │   └── s3/
│   │   └── shared/
│   ├── kubernetes/
│   │   ├── base/
│   │   │   ├── namespace.yaml
│   │   │   ├── configmap.yaml
│   │   │   ├── secrets.yaml
│   │   │   └── rbac.yaml
│   │   ├── applications/
│   │   │   ├── frontend/
│   │   │   │   ├── deployment.yaml
│   │   │   │   ├── service.yaml
│   │   │   │   └── ingress.yaml
│   │   │   ├── backend/
│   │   │   │   ├── deployment.yaml
│   │   │   │   ├── service.yaml
│   │   │   │   └── hpa.yaml
│   │   │   └── databases/
│   │   │       ├── postgresql.yaml
│   │   │       ├── redis.yaml
│   │   │       └── elasticsearch.yaml
│   │   ├── overlays/
│   │   │   ├── development/
│   │   │   ├── staging/
│   │   │   └── production/
│   │   └── kustomization.yaml
│   ├── helm/
│   │   ├── charts/
│   │   │   ├── sms-platform/
│   │   │   │   ├── Chart.yaml
│   │   │   │   ├── values.yaml
│   │   │   │   └── templates/
│   │   │   └── monitoring/
│   │   └── values/
│   │       ├── development.yaml
│   │       ├── staging.yaml
│   │       └── production.yaml
│   └── ansible/
│       ├── playbooks/
│       ├── roles/
│       └── inventory/
│
├── monitoring/                    # Monitoring and observability
│   ├── prometheus/
│   │   ├── prometheus.yml
│   │   ├── alerts.yml
│   │   └── rules.yml
│   ├── grafana/
│   │   ├── dashboards/
│   │   │   ├── application.json
│   │   │   ├── infrastructure.json
│   │   │   └── business-metrics.json
│   │   └── provisioning/
│   ├── elk/
│   │   ├── elasticsearch.yml
│   │   ├── logstash.conf
│   │   └── kibana.yml
│   └── alertmanager/
│       └── alertmanager.yml
│
├── scripts/                       # Utility scripts
│   ├── setup/
│   │   ├── install-dependencies.sh
│   │   ├── setup-dev-env.sh
│   │   ├── create-certificates.sh
│   │   └── init-database.sh
│   ├── deployment/
│   │   ├── deploy-staging.sh
│   │   ├── deploy-production.sh
│   │   ├── rollback.sh
│   │   └── health-check.sh
│   ├── maintenance/
│   │   ├── backup-database.sh
│   │   ├── cleanup-logs.sh
│   │   ├── update-dependencies.sh
│   │   └── security-scan.sh
│   └── development/
│       ├── generate-types.sh
│       ├── lint-fix.sh
│       ├── test-coverage.sh
│       └── build-docker.sh
│
├── .github/                       # GitHub workflows
│   ├── workflows/
│   │   ├── ci.yml
│   │   ├── cd-staging.yml
│   │   ├── cd-production.yml
│   │   ├── security-scan.yml
│   │   ├── dependency-update.yml
│   │   └── performance-test.yml
│   ├── ISSUE_TEMPLATE/
│   │   ├── bug_report.md
│   │   ├── feature_request.md
│   │   └── security_report.md
│   └── pull_request_template.md
│
└── tools/                         # Development tools
    ├── generators/
    │   ├── component-generator.js
    │   ├── api-generator.js
    │   └── migration-generator.js
    ├── validators/
    │   ├── schema-validator.js
    │   └── api-validator.js
    └── utilities/
        ├── data-faker.js
        ├── test-helper.js
        └── performance-monitor.js
```

## Key Directory Explanations

### Frontend Structure (`/frontend`)
- **Components**: Organized by functionality (ui, forms, layout, charts)
- **Pages**: Next.js page components with nested routing
- **Services**: API communication layer
- **Store**: State management using Zustand
- **Types**: TypeScript type definitions for type safety

### Backend Structure (`/backend`)
- **Controllers**: Handle HTTP requests and responses
- **Services**: Business logic and application services
- **Repositories**: Data access layer with database operations
- **Models**: Database entity definitions
- **Integrations**: External service integrations (Twilio, TCR, Stripe)
- **Jobs**: Background job processing

### Infrastructure (`/infrastructure`)
- **Terraform**: Infrastructure as Code for cloud resources
- **Kubernetes**: Container orchestration manifests
- **Helm**: Package manager for Kubernetes applications
- **Ansible**: Configuration management (if needed)

### Monitoring (`/monitoring`)
- **Prometheus**: Metrics collection and alerting
- **Grafana**: Visualization dashboards
- **ELK Stack**: Logging and log analysis
- **AlertManager**: Alert routing and notification

## Configuration Files

### Root Level Configuration

```yaml
# docker-compose.yml
version: '3.8'
services:
  frontend:
    build: ./frontend
    ports:
      - "3000:3000"
    environment:
      - NEXT_PUBLIC_API_URL=http://backend:5000
    depends_on:
      - backend

  backend:
    build: ./backend
    ports:
      - "5000:5000"
    environment:
      - DATABASE_URL=postgresql://user:pass@postgres:5432/sms_platform
      - REDIS_URL=redis://redis:6379
    depends_on:
      - postgres
      - redis

  postgres:
    image: postgres:15
    environment:
      - POSTGRES_DB=sms_platform
      - POSTGRES_USER=user
      - POSTGRES_PASSWORD=password
    volumes:
      - postgres_data:/var/lib/postgresql/data
      - ./backend/migrations:/docker-entrypoint-initdb.d

  redis:
    image: redis:7-alpine
    ports:
      - "6379:6379"

  elasticsearch:
    image: elasticsearch:8.11.0
    environment:
      - discovery.type=single-node
      - ES_JAVA_OPTS=-Xms1g -Xmx1g
    volumes:
      - es_data:/usr/share/elasticsearch/data

volumes:
  postgres_data:
  es_data:
```

### Environment Variables

```bash
# .env.example
# Application
NODE_ENV=development
PORT=5000
API_VERSION=v1

# Database
DATABASE_URL=postgresql://username:password@localhost:5432/sms_platform
REDIS_URL=redis://localhost:6379

# Authentication
JWT_SECRET=your-super-secret-jwt-key
JWT_EXPIRES_IN=24h
REFRESH_TOKEN_EXPIRES_IN=7d

# Twilio
TWILIO_ACCOUNT_SID=your-twilio-account-sid
TWILIO_AUTH_TOKEN=your-twilio-auth-token
TWILIO_WEBHOOK_SECRET=your-twilio-webhook-secret

# TCR (The Campaign Registry)
TCR_API_URL=https://csp-api.campaignregistry.com
TCR_API_KEY=your-tcr-api-key
TCR_WEBHOOK_SECRET=your-tcr-webhook-secret

# Stripe
STRIPE_SECRET_KEY=sk_test_your-stripe-secret-key
STRIPE_WEBHOOK_SECRET=whsec_your-stripe-webhook-secret

# Email
SENDGRID_API_KEY=your-sendgrid-api-key
FROM_EMAIL=noreply@yourcompany.com

# AWS (for S3, SES)
AWS_ACCESS_KEY_ID=your-aws-access-key
AWS_SECRET_ACCESS_KEY=your-aws-secret-key
AWS_REGION=us-east-1
AWS_S3_BUCKET=your-s3-bucket

# Monitoring
SENTRY_DSN=your-sentry-dsn
NEW_RELIC_LICENSE_KEY=your-new-relic-key
```

### Package.json Scripts

```json
{
  "scripts": {
    "dev": "npm run dev:backend & npm run dev:frontend",
    "dev:backend": "cd backend && npm run dev",
    "dev:frontend": "cd frontend && npm run dev",
    "build": "npm run build:backend && npm run build:frontend",
    "build:backend": "cd backend && npm run build",
    "build:frontend": "cd frontend && npm run build",
    "test": "npm run test:backend && npm run test:frontend",
    "test:backend": "cd backend && npm run test",
    "test:frontend": "cd frontend && npm run test",
    "test:e2e": "npm run test:e2e:backend",
    "test:e2e:backend": "cd backend && npm run test:e2e",
    "lint": "npm run lint:backend && npm run lint:frontend",
    "lint:backend": "cd backend && npm run lint",
    "lint:frontend": "cd frontend && npm run lint",
    "lint:fix": "npm run lint:fix:backend && npm run lint:fix:frontend",
    "lint:fix:backend": "cd backend && npm run lint:fix",
    "lint:fix:frontend": "cd frontend && npm run lint:fix",
    "docker:build": "docker-compose build",
    "docker:up": "docker-compose up -d",
    "docker:down": "docker-compose down",
    "docker:logs": "docker-compose logs -f",
    "db:migrate": "cd backend && npm run db:migrate",
    "db:seed": "cd backend && npm run db:seed",
    "db:reset": "cd backend && npm run db:reset",
    "setup": "./scripts/setup/setup-dev-env.sh",
    "deploy:staging": "./scripts/deployment/deploy-staging.sh",
    "deploy:production": "./scripts/deployment/deploy-production.sh"
  }
}
```

## Development Workflow

### Getting Started

1. **Clone the repository**
   ```bash
   git clone https://github.com/your-org/twillio-SMS.git
   cd twillio-SMS
   ```

2. **Setup development environment**
   ```bash
   npm run setup
   ```

3. **Start development servers**
   ```bash
   npm run dev
   ```

### Development Commands

```bash
# Install dependencies
npm install

# Start development with hot reload
npm run dev

# Run tests
npm run test

# Run linting
npm run lint

# Fix linting issues
npm run lint:fix

# Build for production
npm run build

# Start with Docker
npm run docker:up

# Database operations
npm run db:migrate
npm run db:seed
```

### Git Workflow

- **Main Branch**: `main` - Production-ready code
- **Development Branch**: `develop` - Integration branch
- **Feature Branches**: `feature/feature-name` - New features
- **Bug Fix Branches**: `bugfix/bug-description` - Bug fixes
- **Release Branches**: `release/version-number` - Release preparation

### Code Quality Standards

- **TypeScript**: Strict mode enabled
- **ESLint**: Airbnb configuration with custom rules
- **Prettier**: Code formatting
- **Husky**: Git hooks for pre-commit checks
- **Jest**: Unit and integration testing
- **Cypress/Playwright**: End-to-end testing

---

This project structure provides a scalable foundation for the 10DLC SMS platform, ensuring code organization, maintainability, and development efficiency throughout the project lifecycle.

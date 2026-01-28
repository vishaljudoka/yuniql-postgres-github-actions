# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

## [1.0.0] - 2026-01-27

### Added

- Initial project structure
- Database migrations:
  - `v0.00`: Schema and initial tables (users, categories, products)
  - `v0.01`: Orders tables and sample data
  - `v0.02`: Audit logging and reporting views
- GitHub Actions workflow for automated migrations
- Local development scripts (bash and PowerShell)
- Docker support with pre-built Yuniql image
- Comprehensive documentation:
  - README.md with architecture diagrams
  - WALKTHROUGH.md for beginners
  - CONTRIBUTING.md for contributors

### Database Schema

Tables created:
- `app.users` - User accounts
- `app.categories` - Product categories (hierarchical)
- `app.products` - Product catalog
- `app.orders` - Customer orders
- `app.order_items` - Order line items
- `app.audit_log` - Change audit trail

Views created:
- `app.v_product_inventory` - Stock status view
- `app.v_order_summary` - Order summary view
- `app.v_dashboard_stats` - Dashboard statistics

### CI/CD

- GitHub Actions workflow with:
  - Push trigger on `main` branch (migrations path)
  - Manual trigger with debug option
  - .NET 6.0 and 8.0 SDK support
  - Yuniql CLI v1.3.15

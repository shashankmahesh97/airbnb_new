/* =============================================================================
   CI ENVIRONMENT SETUP — run once, as ACCOUNTADMIN
   -----------------------------------------------------------------------------
   Creates a separate database, warehouse, role and user for continuous
   integration. CI builds into its own database so a broken pull request can
   never touch production data.
   ============================================================================= */

use role accountadmin;

-- Separate database for CI builds. Disposable by design.
create database if not exists airbnb_ci
    comment = 'CI builds only. Every PR gets its own schema here. Safe to drop.';

-- Small dedicated warehouse so CI never competes with production runs
create warehouse if not exists ci_wh
    warehouse_size      = 'XSMALL'
    auto_suspend        = 60
    auto_resume         = true
    initially_suspended = true;

create role if not exists ci_role;

grant usage on warehouse ci_wh to role ci_role;
grant all on database airbnb_ci to role ci_role;
grant create schema on database airbnb_ci to role ci_role;

-- CI must READ production raw data to build against real inputs,
-- but must never WRITE to production. Read-only, and only on the raw layer.
grant usage on database airbnb to role ci_role;
grant usage on schema airbnb.raw to role ci_role;
grant select on all tables in schema airbnb.raw to role ci_role;
grant select on future tables in schema airbnb.raw to role ci_role;

-- Service user for GitHub Actions
create user if not exists ci_user
    password             = '<generate-a-strong-one>'
    default_role         = ci_role
    default_warehouse    = ci_wh
    must_change_password = false
    comment              = 'GitHub Actions service account. Not for human login.';

grant role ci_role to user ci_user;


/* -----------------------------------------------------------------------------
   Verify the boundary. This is the bit worth demoing.
   ----------------------------------------------------------------------------- */

-- as ci_role: reading raw works
use role ci_role;
select count(*) from airbnb.raw.bookings;

-- as ci_role: writing to production gold FAILS. That is the point.
-- create table airbnb.gold.hack as select 1;   -- insufficient privileges

use role accountadmin;

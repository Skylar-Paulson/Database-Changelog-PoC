-- Add tenant-specific settings column
-- PROJ-1237: Multi-tenant configuration

-- This change should be applied to ALL tenant schemas
-- Each tenant schema follows the same structure

CREATE TABLE IF NOT EXISTS tenant_data (
    id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(255)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

ALTER TABLE tenant_data
ADD COLUMN tenant_settings JSON DEFAULT NULL;

CREATE INDEX idx_tenant_settings ON tenant_data((CAST(tenant_settings AS CHAR(255)) COLLATE utf8mb4_bin));

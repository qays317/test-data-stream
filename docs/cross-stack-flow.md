# **Cross-Stack Dependency Map**
```
┌─────────────────────────────────────────────┐
│                 foundation                  │
│  OUTPUTS:                                   │
|   • vpc_id ─────────────────────────────────┼─────▶ used by producers, 
│   • ecs_subnets_ids ────────────────────────┼─────▶ used by producers,
|   • vpc_endpoint_sg_id ─────────────────────┼─────▶ used by producers,                      
└─────────────────────────────────────────────┘
┌─────────────────────────────────────────────┐
│                 data-streaming              │
|  INPUTS:                                    |
|   • s3_bucket_name                          |
│  OUTPUTS:                                   │
|   • kinesis_stream_arn ─────────────────────┼─────▶ used by producers, consumers
│   • kinesis_stream_name ────────────────────┼─────▶ used by producers,
│   • kinesis_s3_bucket_id ───────────────────┼─────▶ used by consumers
└─────────────────────────────────────────────┘
┌─────────────────────────────────────────────┐
│                 producers                   │
|  INPUTS:                                    |
|   • kinesis_stream_arn                      |
|   • ecr_image_uri                           |
|   • kinesis_stream_name                     |
|   • vpc_id                                  |
|   • ecs_subnets_ids                         |
|   • vpc_endpoint_sg_id                      |     
└─────────────────────────────────────────────┘
┌─────────────────────────────────────────────┐
│                 consumers                   │
|  INPUTS:                                    |
|   • kinesis_stream_arn                      |
|   • s3_bucket_id                            |
|   • s3_vpc_endpoint_id                      |
|   • ecs_task_role_arn                       |
│  OUTPUTS:                                   │
|   • bucket_name ────────────────────────────┼─────▶ used by dr/s3, primary/ecs
│   • bucket_regional_domain_name ────────────┼─────▶ used by global/cdn_dns
|   • bucket_arn ─────────────────────────────┼─────▶ used by dr/s3 
└─────────────────────────────────────────────┘








┌─────────────────────────────────────────────┐
│                 primary/alb                 │
|  INPUTS:                                    |
|   • vpc_id                                  |
|   • vpc_cidr                                |
|   • public_subnets_ids                      |
|   • primary_domain                          |
|   • hosted_zone_id                          |
|   • provided_ssl_certificate_arn            |
|   • certificate_sans                        |
│  OUTPUTS:                                   │
│   • alb_dns_name ───────────────────────────┼─────▶ used by global/cdn_dns
│   • alb_zone_id ────────────────────────────┼─────▶ used by global/cdn_dns (to create a Route 53 primary record for admin access)
│   • target_group_arn ───────────────────────┼─────▶ used by primary/ecs
|   • target_group_arn_suffix ────────────────┼─────▶ used by primary/ecs
|   • alb_arn_suffix ─────────────────────────┼─────▶ used by primary/ecs
└─────────────────────────────────────────────┘
┌─────────────────────────────────────────────┐
│                 dr/read_replica_rds         │
|  INPUTS:                                    |
|   • vpc_id                                  |
|   • vpc_cidr                                |
|   • private_subnets_ids                     |
|   • rds_identifier                          |
|   • wordpress_secret_id                     |
│  OUTPUTS:                                   │
│   • wordpress_secret_arn ───────────────────┼─────▶ used by dr/ecs 
└─────────────────────────────────────────────┘
┌─────────────────────────────────────────────┐
│                 dr/s3                       │
|  INPUTS:                                    |
|   • s3_bucket_name                          |
|   • cloudfront_distribution_arn             |
|   • s3_vpc_endpoint_id                      |
|   • ecs_task_role_arn                       |
|   • s3_replication_role_arn                 |
|   • bucket_name                             |
│  OUTPUTS:                                   │
|   • bucket_name ────────────────────────────┼─────▶ used by dr/ecs
│   • bucket_regional_domain_name ────────────┼─────▶ used by global/cdn_dns
└─────────────────────────────────────────────┘
┌─────────────────────────────────────────────┐
│                 dr/alb                      │
|  INPUTS:                                    |
|   • vpc_id                                  |
|   • vpc_cidr                                |
|   • public_subnets_ids                      |
|   • primary_domain                          |
|   • hosted_zone_id                          |
|   • provided_ssl_certificate_arn            |
|   • certificate_sans                        |
│  OUTPUTS:                                   │
│   • alb_dns_name ───────────────────────────┼─────▶ used by global/cdn_dns
│   • alb_zone_id ────────────────────────────┼─────▶ used by global/cdn_dns (to create a Route 53 secondary record for admin access)
│   • target_group_arn ───────────────────────┼─────▶ used by dr/ecs
|   • target_group_arn_suffix ────────────────┼─────▶ used by dr/ecs 
|   • alb_arn_suffix ─────────────────────────┼─────▶ used by dr/ecs
└─────────────────────────────────────────────┘
┌─────────────────────────────────────────────┐
│                 global/cdn_dns              │
|  INPUTS:                                    |
|   • oac_id                                  |
|   • primary_alb_dns_name                    |
|   • primary_alb_zone_id                     |
|   • dr_alb_dns_name                         |
|   • dr_alb_zone_id                          |
|   • primary_bucket_regional_domain_name     |
|   • dr_bucket_regional_domain_name          |
|   • primary_domain                          |
|   • hosted_zone_id                          |
|   • provided_ssl_certificate_arn            |
|   • certificate_sans                        |
│  OUTPUTS:                                   │
│   • cloudfront_distribution_arn ────────────┼─────▶ used by primary/s3, dr/s3
│   • cloudfront_distribution_domain ─────────┼─────▶ used by primary/ecs, dr/ecs
│   • cloudfront_distribution_id ─────────────┼─────▶ used by primary/ecs, dr/ecs
└─────────────────────────────────────────────┘
┌─────────────────────────────────────────────┐
│                 primary/ecs                 │
|  INPUTS:                                    |
|   • vpc_id                                  |
|   • private_subnets_ids                     |
|   • wordpress_secret_arn                    |
|   • target_group_arn                        |
|   • target_group_arn_suffix                 |
|   • alb_arn_suffix                          |
|   • primary_s3_bucket_name                  |
|   • primary_domain                          |
|   • cloudfront_distribution_domain          |
|   • cloudfront_distribution_id              |
|   • ecr_image_uri                           |
|   • ecs_execution_role_arn                  |
|   • ecs_task_role_arn                       |
│  OUTPUTS:                                   │
│   • s3_vpc_endpoint_id ─────────────────────┼─────▶ used by primary/s3
└─────────────────────────────────────────────┘
┌─────────────────────────────────────────────┐
│                 dr/ecs                      │
|  INPUTS:                                    |
|   • vpc_id                                  |
|   • private_subnets_ids                     |
|   • wordpress_secret_arn                    |
|   • target_group_arn                        |
|   • target_group_arn_suffix                 |
|   • alb_arn_suffix                          |
|   • dr_s3_bucket_name                       |
|   • primary_domain                          |
|   • cloudfront_distribution_id              |
|   • cloudfront_distribution_domain          |
|   • ecr_image_uri                           |
|   • ecs_execution_role_arn                  |
|   • ecs_task_role_arn                       |
│  OUTPUTS:                                   │
│   • s3_vpc_endpoint_id ─────────────────────┼─────▶ used by dr/s3
└─────────────────────────────────────────────┘

```